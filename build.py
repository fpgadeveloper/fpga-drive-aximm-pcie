# Copyright (C) 2025-2026, Opsero Electronic Design Inc.  All rights reserved.
#
# SPDX-License-Identifier: MIT

"""Cross-platform build runner for Opsero reference design repos.

Replaces the Makefile step-runner on hosts where GNU make is unavailable or
broken (Windows/git bash), and runs the identical flow on Linux. Reads targets
and per-design attributes straight from the repo's config/data.json.

Usage (the command names the artifact you want):
  ./build.sh list                              # all targets + attributes
  ./build.sh ip         --target <t>           # HLS IP (repos with an IP pre-stage)
  ./build.sh project    --target <t>           # Vivado project (.xpr)
  ./build.sh xsa        --target <t>           # Vivado XSA (synth+impl+export)
  ./build.sh standalone --target <t>           # Vitis workspace + app + boot file
  ./build.sh petalinux  --target <t>           # PetaLinux image (Linux only)
  ./build.sh yocto      --target <t>           # Yocto image (Linux only)
  ./build.sh package    --target <t>           # gather built artifacts -> bootimages/*.zip
  ./build.sh all        --target <t>           # everything the target supports + package
  ./build.sh status     --target <t>           # per-stage artifact state
  ./build.sh clean      --target <t> [--stage xsa]
  python build.py <command> ...                # same, without the shim

--target all loops over every target (continue-on-error, per-target summary).
Two terminals can both run './build.sh all --target all': per-target lock
files make them cooperate, exactly like the legacy concurrent 'make all'.

Each command builds what it depends on first (standalone builds the XSA if
missing) and skips stages whose outputs already exist. 'all' covers
xsa + standalone + petalinux + yocto + package as supported by the target
(this release builds both Linux flows; PetaLinux is dropped at the next
version update). On Windows the
petalinux/yocto stages are refused up front with the Linux hand-off
command; everything else, including HLS IP generation, runs on both hosts.
"""

import argparse
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
import textwrap
import zipfile
from pathlib import Path

IS_WINDOWS = os.name == "nt"

# data.json group label -> device family template token
FAMILY = {"fpga": "microblaze", "z7": "zynq", "zu": "zynqMP", "versal": "versal"}

# CRITICAL WARNING message IDs to ignore as known false positives. 12-1790 is
# Vivado's evaluation-license warning -- expected when building with an
# evaluation (rather than purchased) IP/edition license, not a real problem.
IGNORE_CRIT = [re.compile(r"12-1790")]


def _tick():
    """A check mark for the 'list' table, with an ASCII fallback for consoles
    whose encoding can't represent U+2713 (e.g. some Windows code pages, where
    printing it would raise UnicodeEncodeError)."""
    mark = "✓"  # checkmark
    try:
        mark.encode(sys.stdout.encoding or "ascii")
        return mark
    except (UnicodeEncodeError, LookupError):
        return "y"


class BuildError(Exception):
    pass


def fail(msg):
    raise BuildError(msg)


def _pid_alive(pid):
    if IS_WINDOWS:
        import ctypes
        PROCESS_QUERY_LIMITED_INFORMATION = 0x1000
        h = ctypes.windll.kernel32.OpenProcess(
            PROCESS_QUERY_LIMITED_INFORMATION, False, pid)
        if not h:
            # Access denied means the process exists but is protected.
            ERROR_ACCESS_DENIED = 5
            return ctypes.windll.kernel32.GetLastError() == ERROR_ACCESS_DENIED
        ctypes.windll.kernel32.CloseHandle(h)
        return True
    try:
        os.kill(pid, 0)
        return True
    except ProcessLookupError:
        return False
    except PermissionError:
        return True


class BuildLock:
    """Per-target lock, same role as the legacy Makefile .<target>.lock files:
    lets several 'build all targets' loops run concurrently without two of
    them building the same target. Improvement over the legacy touch-files:
    the lock records pid@host, and a lock whose process is dead (e.g. after a
    crash or reboot) is reclaimed automatically instead of wedging the target
    until someone deletes the file by hand."""

    def __init__(self, repo_root: Path, target: str):
        self.path = repo_root / f".{target}.lock"
        self.acquired = False

    def acquire(self):
        import socket
        me = f"{os.getpid()}@{socket.gethostname()}"
        if self.path.exists():
            try:
                pid_s, host = self.path.read_text().strip().split("@", 1)
                pid = int(pid_s)
            except (ValueError, OSError):
                pid, host = None, ""
            import socket as _s
            if host and host != _s.gethostname():
                print(f"{self.path.name}: locked by {pid}@{host} (another "
                      f"machine). Skipping...")
                return False
            if pid and _pid_alive(pid):
                print(f"{self.path.name}: locked by running pid {pid}. "
                      f"Skipping...")
                return False
            print(f"{self.path.name}: reclaiming stale lock "
                  f"(pid {pid} is gone).")
            self.path.unlink(missing_ok=True)
        self.path.write_text(me)
        self.acquired = True
        return True

    def release(self):
        if self.acquired:
            self.path.unlink(missing_ok=True)
            self.acquired = False


# --------------------------------------------------------------------------- #
# Repo manifest
# --------------------------------------------------------------------------- #

class Repo:
    def __init__(self, root: Path):
        # absolute(), not resolve(): resolve() would rewrite a subst'd short
        # drive (W:) back to the long physical path, defeating the MAX_PATH fix.
        self.root = root.absolute()
        data_file = self.root / "config" / "data.json"
        if not data_file.is_file():
            fail(f"{data_file} not found -- is {root} a reference design repo?")
        self.data = json.loads(data_file.read_text())
        self.bd_name = self.data["bd_name"]
        self.prj_name = self.data["prj_name"]
        args_file = self.root / "Vitis" / "py" / "args.json"
        self.vitis_args = json.loads(args_file.read_text()) if args_file.is_file() else {}
        self.app_name = self.vitis_args.get("app_name", "")
        self.combine_bit_elf = self.vitis_args.get("combine_bit_elf", False)

    def design(self, label):
        for d in self.data["designs"]:
            if d["label"] == label:
                return d
        return None

    def labels(self):
        return [d["label"] for d in self.data["designs"]]

    def required_vivado_version(self):
        """Parse 'set version_required "2025.2"' from Vivado/scripts/build.tcl."""
        tcl = self.root / "Vivado" / "scripts" / "build.tcl"
        m = re.search(r'set\s+version_required\s+"([^"]+)"', tcl.read_text())
        if not m:
            fail(f"could not parse version_required from {tcl}")
        return m.group(1)


# --------------------------------------------------------------------------- #
# Tool discovery
# --------------------------------------------------------------------------- #

def _candidate_roots():
    if IS_WINDOWS:
        for drive in "CDEFG":
            for name in ("Xilinx", "AMD", "AMDDesignTools"):
                p = Path(f"{drive}:/{name}")
                if p.is_dir():
                    yield p
    else:
        home = Path.home()
        for p in (home / "Xilinx", Path("/tools/Xilinx"), Path("/opt/Xilinx"),
                  Path("/usr/local/Xilinx"), Path("/opt/xilinx"),
                  home / "AMDDesignTools", Path("/tools/AMDDesignTools"),
                  Path("/opt/AMDDesignTools")):
            if p.is_dir():
                yield p


def find_tool(tool: str, version: str):
    """Find <tool> install dir for exactly <version>. Returns Path or None.

    Handles both layouts: <root>/<version>/<Tool> (2025.x default) and the
    older <root>/<Tool>/<version>.
    """
    exe = f"{tool.lower()}{'.bat' if IS_WINDOWS else ''}"
    env_dir = os.environ.get(f"XILINX_{tool.upper()}")
    candidates = []
    if env_dir:
        candidates.append(Path(env_dir))
    for root in _candidate_roots():
        candidates.append(root / version / tool)
        candidates.append(root / tool / version)
    for c in candidates:
        if (c / "bin" / exe).is_file() and version in c.as_posix().split("/"):
            return c
    return None


def run_tool(cmd, cwd, extra_env=None):
    """Run a tool streaming output; return exit code."""
    env = os.environ.copy()
    if extra_env:
        env.update(extra_env)
    print(f"+ {' '.join(str(c) for c in cmd)}  (cwd: {cwd})")
    return subprocess.run([str(c) for c in cmd], cwd=str(cwd), env=env).returncode


# --------------------------------------------------------------------------- #
# Stages
# --------------------------------------------------------------------------- #

class Context:
    """Resolved paths and settings shared by all stages."""

    def __init__(self, repo: Repo, target: str, jobs: int):
        self.repo = repo
        self.target = target
        self.jobs = jobs
        self.design = repo.design(target)
        self.family = FAMILY.get(self.design["group"], self.design["group"])
        self.viv_ver = repo.required_vivado_version()
        self.ver_tag = self.viv_ver.replace(".", "-")

        r = repo.root
        self.viv_dir = r / "Vivado"
        self.viv_prj = self.viv_dir / target
        self.xpr = self.viv_prj / f"{target}.xpr"
        self.xsa = self.viv_prj / f"{repo.bd_name}_wrapper.xsa"
        self.viv_logs = self.viv_dir / "logs"

        self.vit_dir = r / "Vitis"
        self.vit_ws = self.vit_dir / f"{target}_workspace"
        self.vit_boot = self.vit_dir / "boot" / target
        if self.family == "microblaze":
            name = f"{repo.bd_name}_boot.bit" if repo.combine_bit_elf else f"{repo.bd_name}.bit"
            self.boot_file = self.vit_boot / name
        else:
            self.boot_file = self.vit_boot / "BOOT.BIN"
        self.app_elf = self.vit_ws / repo.app_name / "build" / f"{repo.app_name}.elf"

        self.petl_img = r / "PetaLinux" / target / "images" / "linux"
        self.yocto_img = r / "Yocto" / target / "images" / "linux"
        self.bootimages = r / "bootimages"
        self.petl_zip = self.bootimages / f"{repo.prj_name}_{target}_petalinux-{self.ver_tag}.zip"
        self.bare_zip = self.bootimages / f"{repo.prj_name}_{target}_standalone-{self.ver_tag}.zip"
        self.yocto_zip = self.bootimages / f"{repo.prj_name}_{target}_yocto-{self.ver_tag}.zip"


def scan_critical_warnings(log: Path):
    """Return real CRITICAL WARNING lines (ignoring known false positives)."""
    if not log.is_file():
        return []
    hits = []
    for line in log.read_text(errors="replace").splitlines():
        if "CRITICAL WARNING:" in line and not any(p.search(line) for p in IGNORE_CRIT):
            hits.append(line.strip())
    return hits


# Observed on Windows: Versal PLM generation (write_device_image) builds a BSP
# ~185 chars below the project dir using tools (mb-ar) that cannot handle paths
# at the 260-char MAX_PATH limit. Check before spending an hour in synth/impl.
VERSAL_PLM_PATH_TAIL = 185


def check_versal_path(ctx: Context):
    if IS_WINDOWS and ctx.family == "versal":
        longest = len(ctx.viv_prj.as_posix()) + VERSAL_PLM_PATH_TAIL
        if longest >= 260:
            fail(f"project path is too long for Versal PLM generation on Windows\n"
                 f"  (would reach ~{longest} chars; the limit is 260, and the PLM\n"
                 f"  build tools do not support long paths). Map the repo to a\n"
                 f"  short drive and re-run the same command from there:\n"
                 f"    subst W: \"{ctx.repo.root}\"\n"
                 f"    cd /w/    (or W:\\ in Command Prompt)")


def vivado_exe(ctx: Context):
    vivado = find_tool("Vivado", ctx.viv_ver)
    if not vivado:
        fail(f"Vivado {ctx.viv_ver} not found (required by this repo). "
             f"Searched standard install roots and XILINX_VIVADO.")
    return vivado / "bin" / ("vivado.bat" if IS_WINDOWS else "vivado")


# --------------------------------------------------------------------------- #
# IP generation pre-stage
# --------------------------------------------------------------------------- #
# Some repos generate IP (today: Vitis HLS cores) before the Vivado project can
# be created. The device part is always resolved per target by running a
# get_part.tcl -- never hard-coded -- so IP is built for each target's real
# part. Two layouts exist; ip_flow() classifies them as 'board' or 'cores':
#   board   Vivado/ip/get_part.tcl + <core>/run_hls.tcl -- outputs land in
#           Vivado/ip/build/<target>/ (rpi-camera-fmc, zynqmp-hailo-ai)
#   cores   HLS/<core>/<core>.tcl + <core>/get_part.tcl -- each open_component
#           exports IP to HLS/<core>/<target>/component_*/hls/impl/ip/
#           (ethernet-fmc-max-throughput and several prod-test repos)
# A Vivado/ip directory holding only a checked-in component.xml is pre-packaged
# RTL IP: consumed directly via ip_repo_paths, nothing to generate, no flow
# reported here.


def hls_cores(hls_dir: Path):
    """Fixed-part HLS core dirs, each laid out as <core>/<core>.tcl."""
    return sorted(d for d in hls_dir.iterdir()
                  if d.is_dir() and (d / f"{d.name}.tcl").is_file())


def ip_flow(ctx: Context):
    """Return ('board', Vivado/ip) | ('cores', HLS) | (None, None)."""
    cand = ctx.viv_dir / "ip"
    if (cand / "get_part.tcl").is_file():
        return "board", cand
    cand = ctx.repo.root / "HLS"
    if cand.is_dir() and hls_cores(cand):
        return "cores", cand
    return None, None


def has_ip_flow(ctx: Context):
    return ip_flow(ctx)[0] is not None


def hls_tools(ctx: Context):
    """vitis-run executable + env (tool bins on PATH, XILINX_VIVADO set)."""
    vitis = find_tool("Vitis", ctx.viv_ver)
    if not vitis:
        fail(f"Vitis {ctx.viv_ver} not found (required for HLS IP generation).")
    exe = vitis / "bin" / ("vitis-run.bat" if IS_WINDOWS else "vitis-run")
    vivado = find_tool("Vivado", ctx.viv_ver)
    env = {}
    bins = [str(vitis / "bin")]
    if vivado:
        env["XILINX_VIVADO"] = str(vivado)
        bins.append(str(vivado / "bin"))
    env["PATH"] = os.pathsep.join(bins + [os.environ.get("PATH", "")])
    return exe, env


def core_built(tdir: Path):
    """A target's core IP is built when its per-target dir holds an exported
    component. Per-target layout (Vitis unified `open_component` flow): the
    core's Tcl builds the IP for the target's real part into
    HLS/<core>/<target>/component_*/hls/impl/ip/component.xml.
    Artifact check, not exit codes: the .bat tool wrappers exit 0 on failure
    on Windows."""
    return bool(list(tdir.glob("component_*/hls/impl/ip/component.xml")))


def stage_ip(ctx: Context):
    kind, ip_dir = ip_flow(ctx)
    if not kind:
        return "skipped (no IP generation step; bundled IP, if any, is pre-packaged)"
    exe, env = hls_tools(ctx)

    if kind == "cores":  # per-target HLS cores, built for the target's real part
        url, board = ctx.design["url"], ctx.design["boardname"]
        # A design may name the specific core(s) it uses via data.json 'hls_ip'
        # (a string or list) -- e.g. the aurora repos select the 7-series OR the
        # UltraScale+ core per target. When absent, build every core (the eth
        # repos ship a single core that all their targets use).
        sel = ctx.design.get("hls_ip")
        if sel is not None:
            sel = [sel] if isinstance(sel, str) else list(sel)
            cores = [c for c in hls_cores(ip_dir) if c.name in sel]
            if not cores:
                fail(f"data.json hls_ip={sel} names no HLS core under "
                     f"{rel_to_repo(ip_dir, ctx.repo.root)} "
                     f"(present: {[c.name for c in hls_cores(ip_dir)]})")
        else:
            cores = hls_cores(ip_dir)
        results = []
        for core in cores:
            tdir = core / ctx.target
            if core_built(tdir):
                results.append(f"{core.name}: exists")
                continue
            # 1. Resolve the target's actual device part -> <target>/settings.tcl
            #    (get_part.tcl runs before any Vivado project exists).
            ctx.viv_logs.mkdir(exist_ok=True)
            plog = ctx.viv_logs / f"{ctx.target}_ip_part.log"
            rc = run_tool([vivado_exe(ctx), "-mode", "batch", "-notrace",
                           "-source", "get_part.tcl",
                           "-log", plog.as_posix(), "-journal",
                           (ctx.viv_logs / f"{ctx.target}_ip_part.jou").as_posix(),
                           "-tclargs", url, board, ctx.target],
                          cwd=core)
            if rc != 0 or not (tdir / "settings.tcl").is_file():
                fail(f"device-part lookup for {core.name}/{ctx.target} failed "
                     f"(rc={rc}). See {rel_to_repo(plog, ctx.repo.root)}")
            # 2. Build the HLS IP for that part into the target's own dir.
            rc = run_tool([exe, "--mode", "hls", "--tcl", f"{core.name}.tcl"],
                          cwd=core, extra_env={**env, "IP_TARGET": ctx.target})
            if not core_built(tdir):
                fail(f"HLS build of {core.name} for {ctx.target} failed "
                     f"(rc={rc}). See logs in {rel_to_repo(tdir, ctx.repo.root)}")
            results.append(f"{core.name}: built")
        return "; ".join(results)

    # per-target board flow: resolve the target's real device and build the HLS
    # IP for it into ip/build/<target>/, so each target owns its generated IP
    # (board is still needed for the device lookup).
    board, url = ctx.design["boardname"], ctx.design["url"]
    build_dir = ip_dir / "build" / ctx.target
    done = build_dir / "ip_done.txt"
    if done.is_file():
        return f"skipped (IP for {ctx.target} exists)"
    run_tcls = sorted(ip_dir.glob("*/run_hls.tcl"))
    if not run_tcls:
        fail(f"{rel_to_repo(ip_dir, ctx.repo.root)} has get_part.tcl but no "
             f"<core>/run_hls.tcl")
    if not (build_dir / "settings.tcl").is_file():
        ctx.viv_logs.mkdir(exist_ok=True)
        log = ctx.viv_logs / f"{ctx.target}_ip_part.log"
        rc = run_tool([vivado_exe(ctx), "-mode", "batch", "-notrace",
                       "-source", "get_part.tcl",
                       "-log", log.as_posix(), "-journal",
                       (ctx.viv_logs / f"{ctx.target}_ip_part.jou").as_posix(),
                       "-tclargs", url, board, ctx.target],
                      cwd=ip_dir)
        if rc != 0 or not (build_dir / "settings.tcl").is_file():
            fail(f"device-part lookup for {ctx.target} failed (rc={rc}). "
                 f"See {rel_to_repo(log, ctx.repo.root)}")
    for t in run_tcls:
        rc = run_tool([exe, "--mode", "hls", "--tcl",
                       f"{t.parent.name}/run_hls.tcl"],
                      cwd=ip_dir,
                      extra_env={**env, "BOARD_NAME": board, "IP_TARGET": ctx.target})
        if not list(build_dir.glob(f"{t.parent.name}*/*/impl/ip/component.xml")):
            fail(f"HLS build of {t.parent.name} for {ctx.target} failed "
                 f"(rc={rc}). See logs in {rel_to_repo(build_dir, ctx.repo.root)}")
    done.write_text("IP generated by build.py\n")
    return f"built ({ctx.target})"


def stage_project(ctx: Context):
    if ctx.xpr.is_file():
        return "skipped (project exists)"
    if has_ip_flow(ctx):
        stage_ip(ctx)
    check_versal_path(ctx)
    exe = vivado_exe(ctx)
    ctx.viv_logs.mkdir(exist_ok=True)
    log = ctx.viv_logs / f"{ctx.target}_xpr.log"
    rc = run_tool([exe, "-mode", "batch", "-notrace",
                   "-source", "scripts/build.tcl",
                   "-log", log.as_posix(), "-journal",
                   (ctx.viv_logs / f"{ctx.target}_xpr.jou").as_posix(),
                   "-tclargs", ctx.target],
                  cwd=ctx.viv_dir)
    # build.tcl 'return's (exit 0) on its version check, so rc alone is
    # not enough -- the project file must actually exist.
    if rc != 0 or not ctx.xpr.is_file():
        fail(f"Vivado project creation failed (rc={rc}). "
             f"See {rel_to_repo(log, ctx.repo.root)}")
    return "built"


def stage_xsa(ctx: Context):
    if ctx.xsa.is_file():
        return "skipped (XSA exists)"
    check_versal_path(ctx)
    stage_project(ctx)
    vivado_bin = vivado_exe(ctx)
    ctx.viv_logs.mkdir(exist_ok=True)

    log = ctx.viv_logs / f"{ctx.target}_xsa.log"
    # Some repos' xsa.tcl takes a third synth_only arg (e.g. rpi-camera-fmc).
    tclargs = [ctx.target, str(ctx.jobs)]
    if "synth_only" in (ctx.viv_dir / "scripts" / "xsa.tcl").read_text(
            encoding="utf-8", errors="replace"):
        tclargs.append("false")
    rc = run_tool([vivado_bin, "-mode", "batch", "-notrace",
                   "-source", "scripts/xsa.tcl",
                   "-log", log.as_posix(), "-journal",
                   (ctx.viv_logs / f"{ctx.target}_xsa.jou").as_posix(),
                   "-tclargs"] + tclargs,
                  cwd=ctx.viv_dir)
    if rc != 0 or not ctx.xsa.is_file():
        fail(f"Vivado synthesis/implementation/XSA export failed (rc={rc}). "
             f"See {rel_to_repo(log, ctx.repo.root)}")
    crit = scan_critical_warnings(log)
    if crit:
        # The XSA was produced, so downstream stages (Vitis / PetaLinux / Yocto)
        # are allowed to proceed. We flag the critical warnings loudly -- and
        # carry the count into the summary -- so the user is aware, but we do
        # NOT block.
        print(f"\n!!! {len(crit)} CRITICAL WARNING(s) in "
              f"{rel_to_repo(log, ctx.repo.root)} "
              f"(the XSA was still produced -- review these):")
        print("\n".join(crit))
        return f"built ({len(crit)} CRITICAL WARNING(s) flagged -- see {log.name})"
    return "built"


# Observed on Windows: the Vitis platform BSP build nests object files
# ~203+len(target) chars below the workspace dir (deepest: standalone BSP
# dependency files under CMakeFiles/<lib>.dir/<32-char-hash>/).
VITIS_BSP_PATH_TAIL = 203


def vitis_tools(ctx: Context):
    """Locate Vitis and build the PATH env make-boot.py needs for bootgen."""
    vitis = find_tool("Vitis", ctx.viv_ver)
    if not vitis:
        fail(f"Vitis {ctx.viv_ver} not found (required by this repo).")
    vitis_exe = vitis / "bin" / ("vitis.bat" if IS_WINDOWS else "vitis")
    # make-boot.py invokes bootgen from PATH (the Makefile flow assumes a
    # sourced settings64.sh) -- provide the tool bin dirs explicitly.
    vivado = find_tool("Vivado", ctx.viv_ver)
    tool_bins = [str(vitis / "bin")] + ([str(vivado / "bin")] if vivado else [])
    tool_env = {"PATH": os.pathsep.join(tool_bins + [os.environ.get("PATH", "")])}
    return vitis_exe, tool_env


def has_vitis_flow(ctx: Context):
    return (ctx.vit_dir / "py").is_dir()


def stage_workspace(ctx: Context):
    if not ctx.design.get("baremetal", False):
        return "skipped (no baremetal app for this target)"
    if not has_vitis_flow(ctx):
        return ("skipped (data.json marks this target baremetal but the repo "
                "ships no Vitis flow -- upstream inconsistency)")
    vitis_exe, tool_env = vitis_tools(ctx)

    if IS_WINDOWS:
        longest = len(ctx.vit_ws.as_posix()) + VITIS_BSP_PATH_TAIL + len(ctx.target)
        if longest >= 260:
            fail(f"workspace path is too long for the Vitis BSP build on Windows\n"
                 f"  (would reach ~{longest} chars; the limit is 260). Map the repo\n"
                 f"  root to a short drive and re-run the same command from there:\n"
                 f"    subst U: \"{ctx.repo.root}\"\n"
                 f"    cd /u/    (or U:\\ in Command Prompt)")

    # vitis.bat exits 0 even on failure, so trust artifacts, not exit codes.
    xpfm = (ctx.vit_ws / f"{ctx.target}_platform" / "export"
            / f"{ctx.target}_platform" / f"{ctx.target}_platform.xpfm")
    if ctx.vit_ws.is_dir() and ctx.xsa.stat().st_mtime > ctx.vit_ws.stat().st_mtime:
        fail(f"Workspace {ctx.vit_ws.name} exists but is older than the XSA. "
             f"Delete it and re-run (same rule as the Makefile).")
    if not ctx.vit_ws.is_dir():
        rc = run_tool([vitis_exe, "-s", "py/build-vitis.py",
                       ctx.target, "py/args.json", "../config/data.json"],
                      cwd=ctx.vit_dir, extra_env=tool_env)
        if rc != 0 or not xpfm.is_file() or not ctx.app_elf.is_file():
            # Remove the workspace we just created so the next run starts clean.
            shutil.rmtree(ctx.vit_ws, ignore_errors=True)
            fail(f"Vitis workspace build failed (rc={rc}; "
                 f"xpfm={'ok' if xpfm.is_file() else 'MISSING'}, "
                 f"app elf={'ok' if ctx.app_elf.is_file() else 'MISSING'}). "
                 f"Workspace removed; check the output above.")
        return "built"
    elif not xpfm.is_file() or not ctx.app_elf.is_file():
        fail(f"Existing workspace {ctx.vit_ws} is incomplete (platform or app "
             f"missing). Delete it and re-run.")
    return "skipped (workspace exists)"


def stage_bootfile(ctx: Context):
    if not ctx.design.get("baremetal", False):
        return "skipped (no baremetal app for this target)"
    if not has_vitis_flow(ctx):
        return ("skipped (data.json marks this target baremetal but the repo "
                "ships no Vitis flow -- upstream inconsistency)")
    stage_workspace(ctx)
    vitis_exe, tool_env = vitis_tools(ctx)

    if (ctx.boot_file.is_file() and ctx.app_elf.is_file()
            and ctx.boot_file.stat().st_mtime >= ctx.app_elf.stat().st_mtime):
        return "skipped (boot file up to date)"
    rc = run_tool([vitis_exe, "-s", "py/make-boot.py",
                   ctx.target, "py/args.json", "../config/data.json"],
                  cwd=ctx.vit_dir, extra_env=tool_env)
    if rc != 0 or not ctx.boot_file.is_file():
        fail(f"Vitis boot file generation failed (rc={rc}); expected {ctx.boot_file}")
    return "built"


def find_petalinux_settings(ver):
    home = Path.home()
    roots = [home / "petalinux", home / "PetaLinux", Path("/tools/petalinux"),
             Path("/opt/petalinux"), Path("/opt/pkg/petalinux"),
             Path("/tools/Xilinx/PetaLinux")]
    for root in roots:
        for cand in (root / ver / "settings.sh", root / "settings.sh"):
            if cand.is_file():
                return cand
    return None


def stage_petalinux(ctx: Context):
    if not ctx.design.get("petalinux", False):
        return "skipped (target has no PetaLinux flow)"
    if IS_WINDOWS:
        # Capability boundary, not a tooling gap: PetaLinux runs on native Linux only.
        print(f"  PetaLinux cannot run on Windows. To finish this target, copy or")
        print(f"  clone this checkout to a Linux machine with PetaLinux Tools "
              f"{ctx.viv_ver} and run:")
        print(f"    ./build.sh all --target {ctx.target}")
        return "BLOCKED (Linux required)"
    if (ctx.petl_img / "BOOT.BIN").is_file() or (ctx.petl_img / "boot.mcs").is_file():
        return "skipped (images exist)"
    # Delegate to the tested Makefile flow -- make always exists on Linux.
    cmd = ["make", "-C", str(ctx.repo.root / "PetaLinux"),
           "petalinux", f"TARGET={ctx.target}", f"JOBS={ctx.jobs}"]
    if not os.environ.get("PETALINUX"):
        settings = find_petalinux_settings(ctx.viv_ver)
        if not settings:
            fail(f"PetaLinux {ctx.viv_ver} settings.sh not found -- install "
                 f"PetaLinux Tools or source settings.sh before running.")
        rc = run_tool(["bash", "-c",
                       f'source "{settings}" >/dev/null && ' + shlex.join(cmd)],
                      cwd=ctx.repo.root)
    else:
        rc = run_tool(cmd, cwd=ctx.repo.root)
    # The PetaLinux Makefile can exit 0 without producing images (e.g. bad
    # environment) -- verify like every other stage.
    boot_ok = (ctx.petl_img / "BOOT.BIN").is_file() or (ctx.petl_img / "boot.mcs").is_file()
    if rc != 0 or not boot_ok:
        fail(f"PetaLinux build failed (rc={rc}; boot artifact "
             f"{'ok' if boot_ok else 'MISSING in ' + str(ctx.petl_img)}).")
    return "built"


def yocto_port_cfg_dir(ctx: Context):
    """Optional per-target overlay layer (e.g. the Ethernet port-config
    layers), derived from data.json 'lanes' the same way update.py used to
    generate the Makefile target table. None when the repo ships no
    Yocto/bsp/port-configs/ or the derived layer does not exist."""
    root = ctx.repo.root / "Yocto" / "bsp" / "port-configs"
    lanes = ctx.design.get("lanes")
    if not root.is_dir() or not isinstance(lanes, list):
        return None
    length = 8 if len(lanes) > 4 else 4
    name = "ports-" + "".join(str(i) if i in lanes else "-"
                              for i in range(length))
    d = root / name
    return d if d.is_dir() else None


def stage_yocto(ctx: Context):
    """Drive the Yocto / EDF flow: the engine is the four shell scripts in
    Yocto/scripts/ (init-workspace, configure-build, build-image,
    package-output); this stage sequences them with the same done-markers and
    freshness rules the retired Yocto/Makefile used."""
    if not ctx.design.get("yocto", False):
        return "skipped (target has no Yocto flow)"
    ydir = ctx.repo.root / "Yocto"
    scripts = ydir / "scripts"
    if not (scripts / "build-image.sh").is_file():
        return ("skipped (data.json marks this target yocto but the repo "
                "ships no Yocto flow yet)")
    if IS_WINDOWS:
        print("  Yocto cannot run on Windows. Build this target on a Linux "
              "machine:")
        print(f"    ./build.sh yocto --target {ctx.target}")
        return "BLOCKED (Linux required)"
    work = ydir / ctx.target
    img = work / "images" / "linux"
    # Zynq-7000 produces a u-boot-wrapped uImage; ZynqMP/Versal a raw Image.
    kernel = "uImage" if ctx.family == "zynq" else "Image"
    products = [img / "BOOT.BIN", img / kernel,
                img / "rootfs.tar.gz", img / "rootfs.wic.xz"]
    if all(p.is_file() for p in products):
        return "skipped (images exist)"
    stage_xsa(ctx)
    # The scripts need the Vitis environment (xsct/sdtgen) and Google's
    # `repo` tool on PATH.
    vitis = find_tool("Vitis", ctx.viv_ver)
    if not vitis:
        fail(f"Vitis {ctx.viv_ver} not found (the Yocto flow needs xsct/sdtgen).")

    def sh(script, args, what):
        cmd = (f'source "{vitis / "settings64.sh"}" >/dev/null && '
               + shlex.join([str(scripts / script)] + [str(a) for a in args]))
        rc = run_tool(["bash", "-c", cmd], cwd=ydir)
        if rc != 0:
            fail(f"Yocto {what} failed (rc={rc}) for {ctx.target}.")

    # 1. Manifest workspace (repo init + sync, ~5 GB on first run). The EDF
    #    manifest drops edf-init-build-env at the workspace root when done.
    if not (work / "edf-init-build-env").is_file():
        sh("init-workspace.sh",
           [work, "https://github.com/Xilinx/yocto-manifests.git",
            f"rel-v{ctx.viv_ver}", "default-edf.xml"], "workspace init")
    # 2. Hardware handoff: the XSA is all the Yocto build consumes.
    hw_xsa = work / "hw" / ctx.xsa.name
    if not hw_xsa.is_file() or hw_xsa.stat().st_mtime < ctx.xsa.stat().st_mtime:
        hw_xsa.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(ctx.xsa, hw_xsa)
    # 3. Configure (sdtgen + gen-machineconf parse-sdt + BSP/overlay/sstate).
    #    Re-run when the XSA or the board conf is newer than the done-marker.
    board = ctx.target.split("_")[0]
    bsp = ydir / "bsp" / board
    conf_append = bsp / "conf" / "local.conf.append"
    done = work / "configdone.txt"
    offline = ydir / "offline.txt"
    sstate = ""
    if offline.is_file():
        sstate = offline.read_text(encoding="utf-8").splitlines()[0].strip()
    deps = [p for p in (hw_xsa, conf_append) if p.is_file()]
    if not done.is_file() or any(done.stat().st_mtime < p.stat().st_mtime
                                 for p in deps):
        sh("configure-build.sh",
           [work, ctx.target, bsp, hw_xsa, sstate, ctx.repo.bd_name,
            yocto_port_cfg_dir(ctx) or ""], "configure")
        done.write_text("configured by build.py\n")
    # 4. bitbake (always re-run while products are missing; it is incremental).
    sh("build-image.sh", [work, "edf-linux-disk-image", ctx.jobs],
       "bitbake build")
    # 5. Gather the deploy outputs into images/linux/.
    sh("package-output.sh", [work, img], "packaging")
    missing = [p.name for p in products if not p.is_file()]
    if missing:
        fail(f"Yocto build completed but products are missing in "
             f"{rel_to_repo(img, ctx.repo.root)}: {', '.join(missing)}")
    return "built"


def _zip_tree(zip_path: Path, entries):
    """entries: list of (src_file, arcname) or (text, arcname) for readmes."""
    zip_path.parent.mkdir(exist_ok=True)
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
        for src, arc in entries:
            if isinstance(src, Path):
                z.write(src, arc)
            else:
                z.writestr(arc, src)


def _tar_member_bytes(tgz: Path, member: str):
    """One member's bytes from a .tar.gz, or None if tarball/member is missing."""
    import tarfile
    if not tgz.is_file():
        return None
    try:
        with tarfile.open(tgz, "r:gz") as t:
            for name in ("./" + member, member):
                try:
                    f = t.extractfile(name)
                except KeyError:
                    continue
                if f:
                    return f.read()
    except (OSError, tarfile.TarError):
        pass
    return None


def stage_bootimage(ctx: Context):
    results = []

    if ctx.design.get("baremetal", False) and not has_vitis_flow(ctx):
        results.append("standalone zip skipped (repo has no Vitis flow)")
    elif ctx.design.get("baremetal", False):
        if ctx.bare_zip.is_file():
            results.append("standalone zip exists")
        elif ctx.boot_file.is_file():
            entries = [(p, p.relative_to(ctx.vit_boot).as_posix())
                       for p in sorted(ctx.vit_boot.rglob("*")) if p.is_file()]
            _zip_tree(ctx.bare_zip, entries)
            results.append(f"wrote {ctx.bare_zip.name}")
        else:
            fail(f"baremetal boot file missing: {ctx.boot_file}")

    if ctx.design.get("petalinux", False):
        img = ctx.petl_img
        if ctx.petl_zip.is_file():
            results.append("petalinux zip exists")
        else:
            boot_readme = "Copy these files to the boot (FAT32) partition of the SD card\n"
            root_readme = "Extract contents of rootfs.tar.gz to the root partition of the SD card\n"
            if ctx.family == "microblaze":
                wanted = ["boot.mcs", "boot.prm", "image.elf", "system.bit"]
                entries = [(img / "boot.mcs", "flash/boot.mcs"),
                           (img / "boot.prm", "flash/boot.prm"),
                           ("Program the flash with this MCS file to boot from flash\n",
                            "flash/readme.txt"),
                           (img / "image.elf", "jtag/image.elf"),
                           (img / "system.bit", "jtag/system.bit"),
                           ("Load these files via JTAG to boot PetaLinux from JTAG\n",
                            "jtag/readme.txt")]
            else:
                wanted = ["BOOT.BIN", "image.ub", "boot.scr", "rootfs.tar.gz"]
                entries = [(img / "BOOT.BIN", "boot/BOOT.BIN"),
                           (img / "image.ub", "boot/image.ub"),
                           (img / "boot.scr", "boot/boot.scr"),
                           (boot_readme, "boot/readme.txt"),
                           (img / "rootfs.tar.gz", "root/rootfs.tar.gz"),
                           (root_readme, "root/readme.txt")]
            missing = [w for w in wanted if not (img / w).is_file()]
            if missing:
                if IS_WINDOWS:
                    results.append(f"petalinux zip NOT gathered (artifacts missing: "
                                   f"{', '.join(missing)}; build them on Linux)")
                else:
                    fail(f"PetaLinux artifacts missing in "
                         f"{rel_to_repo(img, ctx.repo.root)}: {', '.join(missing)}")
            else:
                _zip_tree(ctx.petl_zip, entries)
                results.append(f"wrote {ctx.petl_zip.name}")

    if ctx.design.get("yocto", False):
        img = ctx.yocto_img
        if ctx.yocto_zip.is_file():
            results.append("yocto zip exists")
        else:
            # The EDF Yocto wic is a full SD-card image; bmaptool uses the .bmap
            # (xzcat|dd is the fallback). The wic's ESP does NOT carry BOOT.BIN on
            # any family (verified 2026-07 on vck190: bootimg-efi-amd populates
            # systemd-boot + kernel Image only, and the BootROM finds no boot image
            # -> dead board), so BOOT.BIN must be copied onto the first FAT32 (ESP)
            # partition after flashing -- ship it alongside the wic.
            wanted = ["rootfs.wic.xz", "rootfs.wic.bmap"]
            entries = [(img / "rootfs.wic.xz", "rootfs.wic.xz"),
                       (img / "rootfs.wic.bmap", "rootfs.wic.bmap")]
            flash = (
                "Flash rootfs.wic.xz to the SD card's RAW block device (e.g. /dev/sdX),\n"
                "not a partition.\n"
                "With bmaptool (faster, uses rootfs.wic.bmap):\n"
                "  bmaptool copy rootfs.wic.xz /dev/sdX\n"
                "Without bmaptool:\n"
                "  xzcat rootfs.wic.xz | sudo dd of=/dev/sdX bs=4M conv=fsync\n")
            wanted.append("BOOT.BIN")
            entries.append((img / "BOOT.BIN", "BOOT.BIN"))
            sd_readme = flash + (
                "\nThen copy BOOT.BIN onto the FIRST partition (p1, FAT32/ESP):\n"
                "the wic does not carry BOOT.BIN where the BootROM can read it,\n"
                "so the card will not boot until BOOT.BIN is on p1, e.g.:\n"
                "  sudo mount /dev/sdX1 /mnt && sudo cp BOOT.BIN /mnt/ && sudo umount /mnt\n")
            if ctx.family == "versal":
                # The versal wic's ESP also ships an EMPTY EFI/BOOT/ (no
                # systemd-boot binary), so u-boot's EFI boot manager has
                # nothing to load even once BOOT.BIN is in place (verified
                # 2026-07 on vck190). Ship systemd-boot from the image rootfs
                # so the user can install it alongside BOOT.BIN.
                efi = _tar_member_bytes(
                    img / "rootfs.tar.gz",
                    "usr/lib/systemd/boot/efi/systemd-bootaa64.efi")
                if efi is not None:
                    entries.append((efi, "BOOTAA64.EFI"))
                    sd_readme += (
                        "\nVersal: ALSO copy BOOTAA64.EFI to EFI/BOOT/ on p1\n"
                        "(the wic ships an empty EFI/BOOT/, so u-boot's EFI boot\n"
                        "manager otherwise stops at the u-boot prompt), e.g.:\n"
                        "  sudo mount /dev/sdX1 /mnt && sudo mkdir -p /mnt/EFI/BOOT \\\n"
                        "    && sudo cp BOOTAA64.EFI /mnt/EFI/BOOT/ && sudo umount /mnt\n")
            entries.append((sd_readme, "readme.txt"))
            missing = [w for w in wanted if not (img / w).is_file()]
            if missing:
                if IS_WINDOWS:
                    results.append(f"yocto zip NOT gathered (artifacts missing: "
                                   f"{', '.join(missing)}; build them on Linux)")
                else:
                    fail(f"Yocto artifacts missing in "
                         f"{rel_to_repo(img, ctx.repo.root)}: {', '.join(missing)}")
            else:
                _zip_tree(ctx.yocto_zip, entries)
                results.append(f"wrote {ctx.yocto_zip.name}")

    return "; ".join(results) if results else "nothing to gather"


STAGE_FUNCS = {"ip": stage_ip, "project": stage_project, "xsa": stage_xsa,
               "standalone": stage_bootfile,
               "petalinux": stage_petalinux, "yocto": stage_yocto,
               "package": stage_bootimage}


def fmt_artifact(p: Path):
    if p.is_file():
        import datetime
        mt = datetime.datetime.fromtimestamp(p.stat().st_mtime)
        return f"{mt:%Y-%m-%d %H:%M}"
    if p.is_dir():
        return "(directory)"
    return "NOT BUILT"


def status_tree():
    """Connector glyphs for the status tree: (only, first, middle, last).
    Box-drawing right angles where the console can render them; an ASCII
    fallback for code pages / redirects that can't encode them (e.g. a
    non-UTF-8 Windows console)."""
    pretty = ("──▸",   # ──▸  single output
              "┬─▸",   # ┬─▸  first of several
              "├─▸",   # ├─▸  middle
              "└─▸")   # └─▸  last
    try:
        "".join(pretty).encode(sys.stdout.encoding or "ascii")
        return pretty
    except (LookupError, UnicodeError):
        return ("-->", "+->", "+->", "\\->")


def _wrap_path(s, width):
    """Wrap a (whitespace-free) display path to `width` columns, breaking after
    a '/' separator when one fits so path segments stay intact, and hard-breaking
    an over-long segment. Returns a list of one or more line chunks."""
    lines = []
    while len(s) > width:
        cut = s.rfind("/", 0, width)
        cut = cut + 1 if cut > 0 else width   # keep '/' on this line, else hard break
        lines.append(s[:cut])
        s = s[cut:]
    lines.append(s)
    return lines


def print_status(ctx: Context):
    print(f"=== status: {ctx.target} ({ctx.family}) ===")
    # Artifacts grouped by the build subcommand that produces them, in build
    # order. The command name is the first column (so it's clear which command
    # makes which output); a command with several outputs branches to each with
    # a tree connector.
    groups = []  # list of (command, [artifact paths])
    kind, ip_dir = ip_flow(ctx)
    if kind == "cores":
        def _ip_artifact(c):
            td = c / ctx.target
            hits = sorted(td.glob("component_*/hls/impl/ip/component.xml"))
            return hits[0] if hits else (
                td / "component_*" / "hls" / "impl" / "ip" / "component.xml")
        groups.append(("ip", [_ip_artifact(c) for c in hls_cores(ip_dir)]))
    elif kind == "board":
        groups.append(("ip", [ip_dir / "build" / ctx.target / "ip_done.txt"]))
    groups.append(("project", [ctx.xpr]))
    groups.append(("xsa", [ctx.xsa]))
    # Only show artifact groups the target actually supports, so an unsupported
    # flow never reads as a "NOT BUILT" build that's waiting to be done.
    if ctx.design.get("baremetal", False):
        groups.append(("standalone", [ctx.vit_ws, ctx.boot_file]))
    if ctx.design.get("petalinux", False):
        if ctx.family == "microblaze":
            groups.append(("petalinux", [ctx.petl_img / "boot.mcs"]))
        else:
            groups.append(("petalinux", [ctx.petl_img / "BOOT.BIN",
                                          ctx.petl_img / "image.ub"]))
    if ctx.design.get("yocto", False):
        groups.append(("yocto", [ctx.yocto_img / "rootfs.wic.xz"]))
    pkg = []  # bootimage zips -- all produced by the 'package' command
    if ctx.design.get("baremetal", False):
        pkg.append(ctx.bare_zip)
    if ctx.design.get("petalinux", False):
        pkg.append(ctx.petl_zip)
    if ctx.design.get("yocto", False):
        pkg.append(ctx.yocto_zip)
    if pkg:
        groups.append(("package", pkg))

    prefix = f"{ctx.repo.prj_name}_"                    # redundant zip-name prefix

    def disp(p):
        s = rel_to_repo(p, ctx.repo.root)
        # Bootimage zips are named <prj>_<target>_<flow>-<ver>.zip; the project
        # name prefix is redundant in status and makes lines wrap, so elide it.
        if p.name.startswith(prefix):
            s = s[:-len(p.name)] + "..._" + p.name[len(prefix):]
        return s

    only, first, middle, last = status_tree()
    w = max(len(c) for c, _ in groups)
    state_w = 16
    indent = 2 + w + 1 + len(only) + 1 + state_w + 2    # where the path column starts
    text_w = max(shutil.get_terminal_size((80, 24)).columns - indent, 20)
    for cmd, paths in groups:
        n = len(paths)
        for i, p in enumerate(paths):
            if n == 1:
                branch = only
            elif i == 0:
                branch = first
            elif i == n - 1:
                branch = last
            else:
                branch = middle
            label = cmd if i == 0 else ""               # command name on row 1
            plines = _wrap_path(disp(p), text_w)
            print(f"  {label:<{w}} {branch} {fmt_artifact(p):<{state_w}}  {plines[0]}")
            for cont in plines[1:]:                      # continuation under the path
                print(f"{' ' * indent}{cont}")
    print()                                             # blank line between targets


def rel_to_repo(p: Path, root: Path):
    """Display path: relative to the repo root, with a trailing / for dirs."""
    try:
        s = p.relative_to(root).as_posix()
    except ValueError:
        s = p.name
    return s + "/" if p.is_dir() else s


def clean_paths(ctx: Context, scope):
    """Existing paths that `clean` removes for ctx.target at the given scope.

    Default scope (None) covers EVERYTHING for the target -- the Vivado project,
    the Vitis workspace + boot dir, the per-target generated IP, the PetaLinux
    and Yocto per-target projects, and the bootimage zips. Because the generated
    IP is now per-target, removing it is safe and never affects other targets.
    Explicit --stage limits removal to one stage:
      ip                     -> the target's generated HLS IP
      project | xsa          -> the Vivado project
      standalone             -> the Vitis workspace + boot dir
      petalinux              -> the PetaLinux per-target project
      yocto                  -> the Yocto per-target workspace (huge; hours to rebuild)
      package                -> the bootimage zips
    """
    paths = []
    if scope in (None, "ip"):
        kind, ip_dir = ip_flow(ctx)
        if kind == "cores":
            paths += [core / ctx.target for core in hls_cores(ip_dir)]
            paths += list(ip_dir.glob("*.log"))
        elif kind == "board":
            paths.append(ip_dir / "build" / ctx.target)
    if scope in (None, "petalinux"):
        paths.append(ctx.repo.root / "PetaLinux" / ctx.target)
    if scope in (None, "yocto"):
        paths.append(ctx.repo.root / "Yocto" / ctx.target)
    if scope in (None, "project", "xsa"):
        paths.append(ctx.viv_prj)
    if scope in (None, "standalone"):
        paths += [ctx.vit_ws, ctx.vit_boot]
    if scope in (None, "package"):
        paths += [ctx.petl_zip, ctx.bare_zip, ctx.yocto_zip]
    return [p for p in paths if p.exists()]


def remove_paths(paths, root: Path):
    """Delete each path, printing its repo-relative name."""
    for p in paths:
        disp = rel_to_repo(p, root)  # before deletion, while is_dir() is valid
        if p.is_dir():
            shutil.rmtree(p)
        else:
            p.unlink()
        print(f"  removed {disp}")


def stages_for(command, design):
    fixed = {"ip": ["ip"], "project": ["project"], "xsa": ["xsa"],
             "standalone": ["xsa", "standalone"],
             "petalinux": ["xsa", "petalinux"],
             "yocto": ["xsa", "yocto"],
             "package": ["package"]}
    if command in fixed:
        return fixed[command]
    # 'all': everything the target supports, then gather. Both Linux flows
    # are built when supported: this release supports PetaLinux and Yocto
    # side by side (PetaLinux is dropped at the next version update).
    order = ["xsa"]
    if design.get("baremetal", False):
        order.append("standalone")
    if design.get("petalinux", False):
        order.append("petalinux")
    if design.get("yocto", False):
        order.append("yocto")
    order.append("package")
    return order


# --------------------------------------------------------------------------- #

BUILD_COMMANDS = ["ip", "project", "xsa", "standalone",
                  "petalinux", "yocto", "package", "all"]

COMMAND_HELP = {
    "list": "list targets and attributes",
    "labels": "print one target label per line (for scripting)",
    "ip": "generate the design's HLS IP (only repos with an IP pre-stage)",
    "project": "create the Vivado project (.xpr)",
    "xsa": "build the Vivado XSA (synth + impl + export)",
    "standalone": "create the Vitis workspace, build the app, then the baremetal boot file (BOOT.BIN / .bit)",
    "petalinux": "build the PetaLinux image (Linux only)",
    "yocto": "build the Yocto image (Linux only)",
    "package": "gather built artifacts into bootimages/*.zip",
    "all": "build everything the target supports (incl. yocto), then package",
    "status": "show per-stage artifact state",
    "clean": "delete a target's generated outputs (default: all, with a y/N prompt; --stage to limit)",
}


def shim_name():
    """How the user invoked us, for example lines in help output."""
    return os.environ.get("BUILD_SHIM") or "python build.py"


# Commands that only make sense for targets with a given data.json flag.
COMMAND_CAPABILITY = {"standalone": "baremetal",
                      "petalinux": "petalinux", "yocto": "yocto"}


def capable_designs(repo, flag=None):
    return [d for d in repo.data["designs"] if not flag or d.get(flag)]


def example_target(repo, flag=None):
    designs = capable_designs(repo, flag) or repo.data["designs"]
    for d in designs:
        if d.get("publish", True) and not d.get("license"):
            return d["label"]
    for d in designs:
        if not d.get("license"):
            return d["label"]
    return designs[0]["label"]


def print_targets(repo, out=None, flag=None, cmd=None):
    out = out or sys.stdout
    labels = [d["label"] for d in capable_designs(repo, flag)]
    what = f"Valid targets for '{cmd}'" if flag and cmd else "Valid targets"
    print(f"{what} ({len(labels)}):", file=out)
    line = "  "
    for lab in labels:
        if len(line) + len(lab) > 78:
            print(line.rstrip(", "), file=out)
            line = "  "
        line += lab + ", "
    if line.strip():
        print(line.rstrip(", "), file=out)


RUNNER_TITLE = "Opsero reference design build runner"


def _title_banner():
    """The runner title followed by a '---' underline of the same width (ending
    in a newline). Printed above the usage line wherever the runner shows usage."""
    return f"{RUNNER_TITLE}\n{'-' * len(RUNNER_TITLE)}\n"


class BannerParser(argparse.ArgumentParser):
    """ArgumentParser that prints the runner title banner above its usage line
    -- on --help and on argument errors -- and capitalises the usage prefix."""

    def format_usage(self):
        return _title_banner() + super().format_usage().replace(
            "usage: ", "Usage: ", 1)

    def format_help(self):
        return _title_banner() + super().format_help().replace(
            "usage: ", "Usage: ", 1)


class FriendlyParser(BannerParser):
    """argparse parser whose missing/invalid-argument error also lists the
    valid targets and a worked example (the usage line comes first, as
    standard)."""
    repo = None

    def error(self, message):
        self.print_usage(sys.stderr)
        print(f"{self.prog}: error: {message}", file=sys.stderr)
        repo = FriendlyParser.repo
        if repo is not None and "--target" in message:
            cmd = self.prog.split()[-1]
            flag = COMMAND_CAPABILITY.get(cmd)
            if flag and not capable_designs(repo, flag):
                print(file=sys.stderr)
                print(f"This repo has no targets that support '{cmd}'.",
                      file=sys.stderr)
                sys.exit(2)
            if IS_WINDOWS and cmd in ("petalinux", "yocto"):
                ex = example_target(repo, flag)
                print(file=sys.stderr)
                print(f"Note: '{cmd}' requires a native Linux machine -- it "
                      f"cannot run on Windows.", file=sys.stderr)
                print(f"On this Windows machine you can build the supported "
                      f"parts instead:", file=sys.stderr)
                print(f"  {shim_name()} xsa --target <target>", file=sys.stderr)
                print(f"  {shim_name()} all --target <target>", file=sys.stderr)
                print(file=sys.stderr)
                print_targets(repo, out=sys.stderr, flag=flag, cmd=cmd)
                print(file=sys.stderr)
                print(f"Example (on Linux):  ./build.sh {cmd} --target {ex}",
                      file=sys.stderr)
                sys.exit(2)
            print(file=sys.stderr)
            print_targets(repo, out=sys.stderr, flag=flag, cmd=cmd)
            print(file=sys.stderr)
            print(f"Example:  {self.prog} --target "
                  f"{example_target(repo, flag)}", file=sys.stderr)
        sys.exit(2)


def print_overview(repo):
    shim = shim_name()
    print(_title_banner(), end="")
    print(f"Usage: {shim} <command> [--target <label>] [options]")
    print()
    print("Commands:")
    cmds = ["list", "labels"] + BUILD_COMMANDS + ["status", "clean"]
    label_w = max(len(c) for c in cmds) + 1   # widest command name + a gap
    indent = 2 + label_w + 1                   # left margin + label column + space
    text_w = max(shutil.get_terminal_size((80, 24)).columns - indent, 30)
    for cmd in cmds:
        wrapped = textwrap.wrap(COMMAND_HELP[cmd], width=text_w) or [""]
        print(f"  {cmd:<{label_w}} {wrapped[0]}")
        for cont in wrapped[1:]:
            print(f"{' ' * indent}{cont}")
    print()
    print_targets(repo)
    ex = example_target(repo)
    print()
    print("Examples:")
    print(f"  {shim} list")
    print(f"  {shim} xsa --target {ex}")
    print(f"  {shim} standalone --target {ex}")
    print(f"  {shim} all --target {ex}")
    print(f"  {shim} all --target all")
    print()
    print(f"Run '{shim} <command> --help' for command options.")


# Returned by run_target() when the target's lock is held by another build
# (same-target concurrency). Distinct from a normal summary so callers can tell
# "skipped" from "built": a run that only skipped (built nothing, no failures)
# exits 3, not 0. Exit codes: 0 built/up-to-date, 1 build failure, 2 usage /
# Linux-only-flow-on-Windows, 3 skipped (lock held by another build).
LOCKED_SKIP = object()


def run_target(repo, target, command, jobs):
    """Build one target. Returns a list of (stage, result), or LOCKED_SKIP when
    the per-target lock is held by another build, or raises BuildError."""
    design = repo.design(target)
    ctx = Context(repo, target, jobs)
    print(f"\n=== {repo.prj_name} / {target} ({ctx.family}) -> {command} ===")
    print(f"    host: {'Windows' if IS_WINDOWS else 'Linux'} | "
          f"Vivado required: {ctx.viv_ver} | jobs: {jobs}")
    if design.get("license", False):
        print("    NOTE: this target requires the Vivado Enterprise edition "
              "(paid license); it cannot be built with the free Standard "
              "edition.")
    if design.get("ip_license", False):
        print("    NOTE: this design uses separately-licensed IP core(s); "
              "bitstream generation requires the IP license (an evaluation "
              "license works for testing).")
    lock = BuildLock(repo.root, target)
    if not lock.acquire():
        return LOCKED_SKIP
    summary = []
    try:
        for name in stages_for(command, design):
            print(f"\n--- stage: {name} ---")
            result = STAGE_FUNCS[name](ctx)
            print(f"--- stage {name}: {result} ---")
            summary.append((name, result))
    finally:
        lock.release()
    return summary


def ensure_submodules(repo, auto=True):
    """Pre-flight: make sure every git submodule the repo declares is present.

    Many targets pull sources from submodules/ (board definitions, the shared
    production-test app, HLS libraries). A repo cloned without
    --recurse-submodules leaves those directories empty and the build fails
    late -- often after a full synthesis run. Detect that up front and, by
    default, initialise the missing submodules so the build never starts doomed.

    A single 'are all declared submodules present?' check (not target-aware):
    if any are missing we initialise them all.
    """
    gm = repo.root / ".gitmodules"
    if not gm.is_file():
        return
    missing = []
    for m in re.finditer(r"path\s*=\s*(\S+)", gm.read_text(encoding="utf-8")):
        sub = repo.root / m.group(1)
        if not sub.is_dir() or not any(sub.iterdir()):
            missing.append(m.group(1))
    if not missing:
        return
    names = ", ".join(missing)

    # Downloaded as a ZIP/tarball rather than cloned: there is no .git, so
    # 'git submodule' cannot help. Point the user at a complete checkout.
    if not (repo.root / ".git").exists():
        print(f"ERROR: this design needs git submodule(s) [{names}] but this is "
              f"not a git clone (no .git). A downloaded ZIP omits submodules -- "
              f"re-clone with:\n  git clone --recurse-submodules <repo-url>")
        sys.exit(1)

    if not auto:
        print(f"ERROR: git submodule(s) not initialised: {names}. Initialise "
              f"them, or omit --no-auto-submodules to let the build do it:\n"
              f"  git submodule update --init --recursive")
        sys.exit(1)

    print(f"Pre-flight: initialising missing git submodule(s): {names}")
    rc = run_tool(["git", "submodule", "update", "--init", "--recursive",
                   "--depth", "1", "--", *missing], cwd=repo.root)
    if rc != 0:
        print(f"ERROR: could not initialise submodule(s) [{names}] (git exit "
              f"{rc}). Common causes: no network access, or an authentication "
              f"prompt for a private submodule. Initialise manually and retry:\n"
              f"  git submodule update --init --recursive")
        sys.exit(1)

    still = [p for p in missing
             if not (repo.root / p).is_dir() or not any((repo.root / p).iterdir())]
    if still:
        print(f"ERROR: submodule(s) still empty after init: {', '.join(still)}. "
              f"Initialise manually:\n  git submodule update --init --recursive")
        sys.exit(1)
    print(f"Pre-flight: submodule(s) ready: {names}")


def main():
    ap = BannerParser(
        prog=shim_name(),
        epilog="Run '%(prog)s <command> --help' for command options.")
    repo = Repo(Path(__file__).absolute().parent)
    FriendlyParser.repo = repo
    sub = ap.add_subparsers(dest="command", required=False, metavar="command",
                            parser_class=FriendlyParser)

    targ = argparse.ArgumentParser(add_help=False)
    targ.add_argument("--target", required=True,
                      help="target label from 'list', or 'all' for every target")

    shim = shim_name()
    no_auto_help = ("don't auto-initialise missing git submodules; fail with "
                    "instructions instead")
    for cmd in BUILD_COMMANDS:
        sp = sub.add_parser(cmd, parents=[targ], prog=f"{shim} {cmd}",
                            help=COMMAND_HELP[cmd])
        sp.add_argument("--jobs", type=int, default=8, help="Vivado synthesis jobs")
        sp.add_argument("--no-auto-submodules", action="store_true",
                        help=no_auto_help)

    sub.add_parser("list", prog=f"{shim} list",
                   help="list targets and attributes")
    sub.add_parser("labels", prog=f"{shim} labels",
                   help="print one target label per line (for scripting)")
    sub.add_parser("status", parents=[targ], prog=f"{shim} status",
                   help="show per-stage artifact state")
    cp = sub.add_parser("clean", parents=[targ], prog=f"{shim} clean",
                        help="delete generated outputs for a target "
                             "(default: everything, with a confirmation prompt)")
    cp.add_argument("--stage", default=None,
                    choices=["ip", "project", "xsa", "standalone",
                             "petalinux", "yocto", "package"],
                    help="limit cleaning to one stage's outputs and skip the "
                         "confirmation prompt (default: clean everything for the "
                         "target after confirming)")
    cp.add_argument("--yes", "-y", action="store_true",
                    help="skip the default-clean confirmation prompt (for "
                         "scripts / 'clean --target all')")

    args = ap.parse_args()

    if args.command is None:
        print_overview(repo)
        return

    # Explicitly requested Linux-only flows are refused BEFORE any work is
    # done -- don't spend 40 minutes on an XSA when the requested artifact
    # cannot be produced on this host. (Inside 'all', the petalinux/yocto
    # stages report BLOCKED and the rest still builds -- that is the point
    # of 'all' on Windows.)
    if IS_WINDOWS and args.command in ("petalinux", "yocto"):
        shim = shim_name()
        print(f"'{args.command}' requires a native Linux machine -- nothing "
              f"was built.")
        print(f"On this Windows machine you can:")
        print(f"  {shim} xsa --target {args.target}         "
              f"# build the hardware half now")
        print(f"  {shim} all --target {args.target}         "
              f"# build everything Windows supports")
        print(f"Then on a Linux machine, in the same checkout:")
        print(f"  ./build.sh {args.command} --target {args.target}")
        sys.exit(2)

    if args.command == "labels":
        for d in repo.data["designs"]:
            print(d["label"])
        return
    if args.command == "list":
        designs = repo.data["designs"]
        # One column per capability/flag: a tick where it applies, blank where
        # not -- far easier to scan than the old comma-lists + [..] tags, and it
        # never wraps. (header, data.json key)
        cols = [("bare", "baremetal"), ("petl", "petalinux"),
                ("yocto", "yocto"), ("ent", "license"), ("ip", "ip_license")]
        tick = _tick()
        lab_w = max([len("target")] + [len(d["label"]) for d in designs])
        fam_w = max([len("family")]
                    + [len(FAMILY.get(d["group"], d["group"])) for d in designs])
        col_w = [max(len(h), 5) for h, _ in cols]

        def line(label, family, marks):
            cells = "  ".join(f"{m:^{w}}" for m, w in zip(marks, col_w))
            return f"  {label:<{lab_w}}  {family:<{fam_w}}  {cells}"

        print(f"{repo.prj_name} targets ({len(designs)}):")
        print()
        print(line("target", "family", [h for h, _ in cols]))
        print(f"  {'-'*lab_w}  {'-'*fam_w}  "
              + "  ".join("-"*w for w in col_w))
        for d in designs:
            fam = FAMILY.get(d["group"], d["group"])
            marks = [tick if d.get(key) else "" for _, key in cols]
            print(line(d["label"], fam, marks))
        print()
        print("  bare = baremetal app   petl = PetaLinux   yocto = Yocto image")
        print("  ent  = Vivado Enterprise (paid) edition required"
              "   ip = separately-licensed IP core")
        return

    if args.target == "all":
        targets = repo.labels()
    else:
        if not repo.design(args.target):
            print(f"ERROR: unknown target '{args.target}'. "
                  f"Valid: {', '.join(repo.labels())}")
            sys.exit(1)
        targets = [args.target]

    if args.command == "status":
        for t in targets:
            print_status(Context(repo, t, 8))
        return
    if args.command == "clean":
        # Gather what every target would remove, then (for the destructive
        # default clean) show ONE combined list and confirm ONCE -- so
        # 'clean --target all' asks a single question, not one per target.
        plan = [(t, clean_paths(Context(repo, t, 8), args.stage)) for t in targets]
        plan = [(t, ps) for t, ps in plan if ps]
        if not plan:
            print("nothing to remove")
            return
        if args.stage is None and not args.yes:
            print("This will delete:")
            for _, ps in plan:
                for p in ps:
                    print(f"  {rel_to_repo(p, repo.root)}")
            if not sys.stdin.isatty():
                print("Refusing to delete without confirmation (stdin is not a "
                      "TTY); re-run with --yes to proceed.")
                sys.exit(1)
            try:
                ans = input("Delete these? (y/N): ").strip().lower()
            except EOFError:
                ans = ""
            if ans not in ("y", "yes"):
                print("Aborted (nothing deleted).")
                return
        for t, ps in plan:
            print(f"=== clean: {t} (scope: {args.stage or 'all'}) ===")
            remove_paths(ps, repo.root)
        return

    ensure_submodules(repo, auto=not getattr(args, "no_auto_submodules", False))
    results = {}
    for t in targets:
        try:
            out = run_target(repo, t, args.command, args.jobs)
            if out is LOCKED_SKIP:
                results[t] = ("skipped", [("(all)", "locked -- skipped")])
            else:
                results[t] = ("ok", out)
        except BuildError as e:
            print(f"\nERROR: {e}")
            results[t] = ("failed", [("(failed)", str(e).splitlines()[0])])
            if len(targets) == 1:
                sys.exit(1)
            print(f"--- continuing with remaining targets ---")

    print(f"\n=== summary ({args.command}) ===")
    status_label = {"ok": "OK", "failed": "FAILED", "skipped": "SKIPPED (locked)"}
    failed = skipped = 0
    for t, (status, summary) in results.items():
        if len(targets) > 1:
            print(f"  {t}: {status_label[status]}")
        for name, result in summary:
            print(f"    {name:<10} {result}")
        failed += status == "failed"
        skipped += status == "skipped"
    if failed:
        print(f"\n{failed}/{len(targets)} target(s) failed")
        sys.exit(1)
    if skipped:
        print(f"\n{skipped}/{len(targets)} target(s) skipped -- lock held by "
              f"another build; nothing was built for them (exit 3)")
        sys.exit(3)


if __name__ == "__main__":
    try:
        main()
    except BuildError as e:
        print(f"\nERROR: {e}")
        sys.exit(1)

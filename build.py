#!/usr/bin/env python3
"""Cross-platform build runner for Opsero reference design repos (PROTOTYPE).

Replaces the Makefile step-runner on hosts where GNU make is unavailable or
broken (Windows/git bash), and runs the identical flow on Linux. Reads targets
and per-design attributes straight from the repo's config/data.json -- no
generated target lists.

Lives at the repo root. Usage:
  ./build.sh --target vck190_fmcp1 --to xsa     (shim finds a Python 3)
  python build.py --target <label> --to bootimage
  python build.py --list
  python build.py --repo <path> ...             (run against another checkout)

Stages (each skipped when its output already exists, like the Makefiles):
  xsa       Vivado: create project (build.tcl) + synth/impl/export (xsa.tcl)
  bootfile  Vitis:  workspace (build-vitis.py) + boot image (make-boot.py)
  petalinux PetaLinux build -- native Linux only; delegates to the tested
            PetaLinux/Makefile flow (make is always available on Linux)
  bootimage Gather boot artifacts into bootimages/*.zip

On Windows the petalinux stage is refused up front with a handoff command,
and bootimage gathers whatever exists (standalone zip; petalinux zip too if
its artifacts were copied over from a Linux build of the same checkout).

Known limitations of this prototype (vs the Makefiles): no lock files, no
*_all loops, Yocto stage not implemented.
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path

IS_WINDOWS = os.name == "nt"

# data.json group label -> device family template token
FAMILY = {"fpga": "microblaze", "z7": "zynq", "zu": "zynqMP", "versal": "versal"}

# CRITICAL WARNING patterns to ignore (known false positives, see CLAUDE.md)
IGNORE_CRIT = [re.compile(r"12-1790")]


def fail(msg):
    print(f"\nERROR: {msg}")
    sys.exit(1)


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
        self.bootimages = r / "bootimages"
        self.petl_zip = self.bootimages / f"{repo.prj_name}_{target}_petalinux-{self.ver_tag}.zip"
        self.bare_zip = self.bootimages / f"{repo.prj_name}_{target}_standalone-{self.ver_tag}.zip"


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
                 f"  build tools do not support long paths). Map a short drive:\n"
                 f"    subst W: \"{ctx.repo.root.parent}\"\n"
                 f"  then re-run with --repo W:/{ctx.repo.root.name}")


def vivado_exe(ctx: Context):
    vivado = find_tool("Vivado", ctx.viv_ver)
    if not vivado:
        fail(f"Vivado {ctx.viv_ver} not found (required by this repo). "
             f"Searched standard install roots and XILINX_VIVADO.")
    return vivado / "bin" / ("vivado.bat" if IS_WINDOWS else "vivado")


def ip_flow(ctx: Context):
    """Some repos generate HLS IP before the Vivado project can be created:
    rpi-camera-fmc / zynqmp-hailo-ai use Vivado/ip/Makefile (per-target),
    ethernet-fmc-max-throughput uses HLS/Makefile (all targets).
    Returns (dir, make_args) or (None, None)."""
    cand = ctx.viv_dir / "ip"
    if (cand / "Makefile").is_file():
        return cand, ["ip", f"TARGET={ctx.target}"]
    cand = ctx.repo.root / "HLS"
    if (cand / "Makefile").is_file():
        return cand, ["all"]
    return None, None


def has_ip_flow(ctx: Context):
    return ip_flow(ctx)[0] is not None


def stage_ip(ctx: Context):
    ip_dir, make_args = ip_flow(ctx)
    if not ip_dir:
        return "skipped (repo has no IP pre-stage)"
    if IS_WINDOWS:
        fail(f"this design generates HLS IP before the Vivado build "
             f"({ip_dir.name}/), a make-driven stage that currently requires "
             f"Linux. Build this target on a Linux machine.")
    vivado = find_tool("Vivado", ctx.viv_ver)
    vitis = find_tool("Vitis", ctx.viv_ver)
    env = {}
    bins = []
    if vivado:
        env["XILINX_VIVADO"] = str(vivado)
        bins.append(str(vivado / "bin"))
    if vitis:
        bins.append(str(vitis / "bin"))
    env["PATH"] = os.pathsep.join(bins + [os.environ.get("PATH", "")])
    # The ip/HLS Makefiles skip work themselves when their outputs exist.
    rc = run_tool(["make", "-C", str(ip_dir)] + make_args,
                  cwd=ctx.repo.root, extra_env=env)
    if rc != 0:
        fail(f"IP generation failed (rc={rc}). See {ip_dir.name}/ output above.")
    return "built"


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
        fail(f"Vivado project creation failed (rc={rc}). See {log}")
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
        fail(f"Vivado synthesis/implementation/XSA export failed (rc={rc}). See {log}")
    crit = scan_critical_warnings(log)
    if crit:
        print("\n".join(crit))
        fail(f"{len(crit)} CRITICAL WARNING(s) in {log} -- aborting like 'make check_warnings'.")
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
                 f"  root itself to a short drive:\n"
                 f"    subst U: \"{ctx.repo.root}\"\n"
                 f"  then re-run with --repo U:/")

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


def stage_petalinux(ctx: Context):
    if not ctx.design.get("petalinux", False):
        return "skipped (target has no PetaLinux flow)"
    if IS_WINDOWS:
        # Capability boundary, not a tooling gap: PetaLinux runs on native Linux only.
        print(f"  PetaLinux cannot run on Windows. To finish this target, copy or")
        print(f"  clone this checkout to a Linux machine with PetaLinux Tools "
              f"{ctx.viv_ver} and run:")
        print(f"    ./build.sh --target {ctx.target} --to bootimage")
        return "BLOCKED (Linux required)"
    if (ctx.petl_img / "BOOT.BIN").is_file() or (ctx.petl_img / "boot.mcs").is_file():
        return "skipped (images exist)"
    # Delegate to the tested Makefile flow -- make always exists on Linux.
    rc = run_tool(["make", "-C", str(ctx.repo.root / "PetaLinux"),
                   "petalinux", f"TARGET={ctx.target}", f"JOBS={ctx.jobs}"],
                  cwd=ctx.repo.root)
    if rc != 0:
        fail(f"PetaLinux build failed (rc={rc}). Is settings.sh sourced?")
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
                    fail(f"PetaLinux artifacts missing in {img}: {', '.join(missing)}")
            else:
                _zip_tree(ctx.petl_zip, entries)
                results.append(f"wrote {ctx.petl_zip.name}")

    return "; ".join(results) if results else "nothing to gather"


STAGE_FUNCS = {"ip": stage_ip, "project": stage_project, "xsa": stage_xsa,
               "workspace": stage_workspace, "bootfile": stage_bootfile,
               "petalinux": stage_petalinux, "bootimage": stage_bootimage}


def fmt_artifact(p: Path):
    if p.is_file():
        import datetime
        mt = datetime.datetime.fromtimestamp(p.stat().st_mtime)
        return f"OK      {p.stat().st_size:>12,} B  {mt:%Y-%m-%d %H:%M}"
    if p.is_dir():
        return "OK      (directory)"
    return "missing"


def print_status(ctx: Context):
    print(f"=== status: {ctx.target} ({ctx.family}) ===")
    rows = [
        ("project", ctx.xpr),
        ("xsa", ctx.xsa),
        ("vitis workspace", ctx.vit_ws),
        ("bootfile", ctx.boot_file),
    ]
    if ctx.family == "microblaze":
        rows.append(("petalinux mcs", ctx.petl_img / "boot.mcs"))
    else:
        rows.append(("petalinux boot", ctx.petl_img / "BOOT.BIN"))
        rows.append(("petalinux image", ctx.petl_img / "image.ub"))
    if ctx.design.get("baremetal", False):
        rows.append(("standalone zip", ctx.bare_zip))
    if ctx.design.get("petalinux", False):
        rows.append(("petalinux zip", ctx.petl_zip))
    width = max(len(n) for n, _ in rows)
    for name, p in rows:
        print(f"  {name:<{width}}  {fmt_artifact(p):<42}  {p}")


def do_clean(ctx: Context, scope):
    """scope None = everything; 'project'/'xsa' = Vivado project;
    'bootfile' = Vitis workspace + boot dir; 'bootimage' = the zips.
    The PetaLinux project dir is never touched (expensive to rebuild;
    clean it with make -C PetaLinux clean TARGET=... on Linux)."""
    removed = []

    def rm(p: Path):
        if p.is_dir():
            shutil.rmtree(p)
            removed.append(f"{p}{os.sep}")
        elif p.exists():
            p.unlink()
            removed.append(str(p))

    if scope in (None, "project", "xsa"):
        rm(ctx.viv_prj)
    if scope in (None, "workspace", "bootfile"):
        rm(ctx.vit_ws)
        rm(ctx.vit_boot)
    if scope in (None, "bootimage"):
        rm(ctx.petl_zip)
        rm(ctx.bare_zip)
    for r in removed:
        print(f"  removed {r}")
    if not removed:
        print("  nothing to remove")
    return removed


def stages_for(goal, design):
    if goal == "ip":
        return ["ip"]
    if goal == "project":
        return ["project"]
    if goal == "xsa":
        return ["xsa"]
    if goal == "workspace":
        return ["xsa", "workspace"]
    if goal == "bootfile":
        return ["xsa", "bootfile"]
    if goal == "petalinux":
        return ["xsa", "petalinux"]
    order = ["xsa"]
    if design.get("baremetal", False):
        order.append("bootfile")
    if design.get("petalinux", False):
        order.append("petalinux")
    order.append("bootimage")
    return order


# --------------------------------------------------------------------------- #

def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--repo", default=None,
                    help="path to the design repo (default: this script's directory)")
    ap.add_argument("--target", help="target label, e.g. vck190_fmcp1")
    ap.add_argument("--to", default=None,
                    choices=["ip", "project", "xsa", "workspace", "bootfile", "petalinux", "bootimage"],
                    help="final stage to build (default: bootimage); with "
                         "--clean, limits cleaning to that stage's outputs")
    ap.add_argument("--jobs", type=int, default=8, help="Vivado synthesis jobs")
    ap.add_argument("--list", action="store_true", help="list targets and exit")
    ap.add_argument("--labels", action="store_true",
                    help="print one target label per line (for scripting) and exit")
    ap.add_argument("--status", action="store_true",
                    help="show per-stage artifact state for --target and exit")
    ap.add_argument("--clean", action="store_true",
                    help="delete generated outputs for --target (scope with --to); "
                         "the PetaLinux project dir is never touched")
    args = ap.parse_args()

    repo = Repo(Path(args.repo) if args.repo else Path(__file__).absolute().parent)
    if args.labels:
        for d in repo.data["designs"]:
            print(d["label"])
        return
    if args.list:
        print(f"{repo.prj_name} targets:")
        for d in repo.data["designs"]:
            flags = [k for k in ("baremetal", "petalinux", "yocto") if d.get(k)]
            lic = "  [license required]" if d.get("license") else ""
            print(f"  {d['label']:<16} {FAMILY.get(d['group'], d['group']):<11} "
                  f"({', '.join(flags)}){lic}")
        return

    if not args.target:
        ap.error("--target is required (or use --list)")
    design = repo.design(args.target)
    if not design:
        fail(f"unknown target '{args.target}'. Valid: {', '.join(repo.labels())}")

    ctx = Context(repo, args.target, args.jobs)
    if args.status:
        print_status(ctx)
        return
    if args.clean:
        print(f"=== clean: {args.target} (scope: {args.to or 'all'}) ===")
        do_clean(ctx, args.to)
        return

    goal = args.to or "bootimage"
    print(f"=== {repo.prj_name} / {args.target} ({ctx.family}) -> {goal} ===")
    print(f"    host: {'Windows' if IS_WINDOWS else 'Linux'} | "
          f"Vivado required: {ctx.viv_ver} | jobs: {args.jobs}")
    if design.get("license", False):
        print("    NOTE: this target uses license-required IP -- bitstream "
              "generation needs a valid license.")

    summary = []
    for name in stages_for(goal, design):
        print(f"\n--- stage: {name} ---")
        result = STAGE_FUNCS[name](ctx)
        print(f"--- stage {name}: {result} ---")
        summary.append((name, result))

    print(f"\n=== summary: {args.target} ===")
    for name, result in summary:
        print(f"  {name:<10} {result}")


if __name__ == "__main__":
    main()

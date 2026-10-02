# Opsero Electronic Design Inc. (C) 2025

# Universal script to create Vitis workspace from XSA file and add an application.

# build-vitis.py — Vitis (Unified IDE) 2025.2+ batch script
# Usage:
#   vitis -source build-vitis.py <target> <path/to/args.json> [<path/to/data.json>]
#   vitis -source build-vitis.py <path/to/args.json> <path/to/data.json>    (interactive)
#
# If <target> is omitted AND data.json is provided, the script lists all
# "baremetal": true designs from data.json and prompts.
# If data.json is "none" or omitted, interactive mode is unavailable.
#
# args.json schema:
# {
#   "bd_name": "design_1",
#   "app_name": "app",
#   "app_template": "None",       # "None"/"" => no template; otherwise use exactly this template
#   "bsp_libs": [                  # optional: libraries to add to BSP before platform build
#     {"name": "lwip220", "config": {"lwip220_dhcp": "true"}},
#     "xiltimer"                   # simple string form (no config)
#   ],
#   "src": {
#     "all":   "common/src",           # string or list of strings/dicts
#     "mb":    "microblaze/src",
#     "zynq":  "zynq/src",
#     "zynqmp":"zynq/src",
#     "versal":"zynq/src"
#   },
#   "boardnames": {                # optional: board name map (used when no data.json)
#     "zedboard": "zedboard",
#     "uzev": "uzev"
#   },
#   "vivado_postfix": "",          # optional: appended to Vivado project dir name
#   "linker_script_mods": {        # optional: per-arch linker script modifications
#     "microblaze": "relocate_to_local_mem",   # or "relocate_to_ddr" / "code_local_bss_ddr"
#     "zynq": "relocate_to_ddr"    #   (see "Linker script modifications" below)
#   },
#   "compile_optimization": {      # optional: per-arch app optimisation level (the
#     "microblaze": "-O2"          #   app component's USER_COMPILE_OPTIMIZATION_LEVEL,
#   },                             #   default -O0); a plain string = every arch
#   "gc_sections": {               # optional: per-arch linker garbage collection
#     "microblaze": true           #   (-ffunction/-fdata-sections + --gc-sections),
#   },                             #   e.g. to fit a local-memory image
#   "stack_size": "0x10000",         # optional: override default stack size in linker script
#   "heap_size": "0x10000",          # optional: override default heap size in linker script
#                                    #   either a plain string (all architectures) or a
#                                    #   per-arch map, e.g. {"microblaze": "0x8000"} --
#                                    #   an arch that is not listed keeps the tool default
#   "combine_bit_elf": true,       # ignored here; used by make-boot.py later
#
#   # ---- optional: User DTS for the platform (see "User DTS" below) ---------
#   "user_dtsi": "common/dts/remote.dtsi",       # path relative to Vitis/
#   "user_dtsi_generator": "py/user_dts.py"      # module that WRITES that file
# }
#
# User DTS
# --------
# A design whose hardware is not fully described by its XSA can hand sdtgen an
# extra device tree source ("Create Platform Component -> Advanced Options ->
# User DTS" in the IDE). Both keys are optional and the whole feature is inert
# when neither is set -- no advanced_options are passed at all, exactly as before.
#
#   "user_dtsi"            path of the .dtsi, RELATIVE TO Vitis/ (the directory
#                          this script runs in). Checked-in file: used as is.
#
#   "user_dtsi_generator"  optional path (also relative to Vitis/) of a Python
#                          module that COMPOSES the .dtsi from the current XSA.
#                          It must expose:
#
#                              def compose(vitis_dir, xsa_path, out_dir, cfg):
#                                  ...
#                                  return "<absolute path>"   # or None
#
#                          It is called after the workspace is opened and BEFORE
#                          the platform is created (which is the only moment a
#                          User DTS can still be passed, and the earliest moment
#                          anything may be written under the workspace -- Vitis
#                          refuses a workspace holding files it did not create).
#                          out_dir is <target>_workspace/dts, so the generated
#                          file is build output and `build.sh clean --stage
#                          standalone` takes it with it. Returning None skips the
#                          User DTS for this target.
#
# The resolved path is passed to the platform as
#     advanced_options = client.create_advanced_options_dict(user_dtsi=<abs path>)
# which the Vitis client turns into the sdtgen hook VITIS_SDT_INCLUDE_DTS.
#
# NOTE: this is deliberately NOT the existing "pre_platform_build_script" hook.
# That one runs after create_platform_component() (it is handed the platform
# object), which is too late to influence the platform's own device tree.
#
# Other optional, per-repo behaviour (all inert unless its trigger is present)
# ---------------------------------------------------------------------------
# Hooks keyed off args.json:
#   "pre_platform_build_script"  module exposing pre_platform_build(platform=,
#                          domain_name=, arch=); run before platform.build().
#   "pre_build_script"     script run as `python <script> <app_src>` before the
#                          app is built (non-zero exit aborts the build).
#   "src_overrides"        {"<target>": <src entry>} replaces the arch-based
#                          "src" copy for that one target.
#   stack_size / heap_size / compile_optimization / gc_sections accept a plain
#                          value (every architecture) or a per-arch map; an
#                          architecture not in the map keeps the tool default.
#
# Linker script modifications ("linker_script_mods", per arch):
#   relocate_to_local_mem  every section -> the MicroBlaze local memory (LMB)
#   relocate_to_ddr        every section -> the first DDR region
#   code_local_bss_ddr     everything in the LMB except .bss/.heap, which go
#                          to DDR (MicroBlaze booting from the bitstream with
#                          a .bss too big for the LMB)
# relocate_to_* are applied BEFORE the stack/heap sizes are set; code_local_
# bss_ddr AFTER them (so the section rewrite is the last word on lscript.ld).
# For a MicroBlaze whose mod is code_local_bss_ddr, the LMB use of the built
# ELF is printed (informational; needs mb-size on PATH, silently skipped if not).
#
# Keyed off config/data.json (the target's design entry):
#   "linkspeed"            when set, board.h also gets
#                              #define LINE_RATE     <int>   (e.g. 100, 40, 25)
#                              #define LINE_RATE_25G <1 if linkspeed == 25 else 0>
#                          Each app uses the one it needs; nothing is written
#                          for a target without "linkspeed".
#
# Keyed off the repo tree:
#   EmbeddedSw/            patched embeddedsw drivers/libs: a LOCAL embeddedsw
#                          repo is assembled in <target>_workspace/embeddedsw
#                          (patched files + the rest of each patched component
#                          from the Vitis install) and registered with Vitis.
#   EmbeddedSw.<arch>/     optional per-arch overlay (e.g. EmbeddedSw.microblaze/)
#                          copied on top of EmbeddedSw/ for that architecture only.
#
# Keyed off the XSA:
#   axi_pcie / axi_pcie3   when the design has an AXI PCIe bridge AND the local
#                          embeddedsw repo carries a patched axipcie.yaml
#                          (EmbeddedSw/XilinxProcessorIPLib/drivers/axipcie_v*/
#                          data/axipcie.yaml), its root-port property entry is
#                          set to the one that core publishes (see
#                          PCIE_PORT_TYPE_PROPS). No patched yaml -> nothing done.
#   MicroBlaze selection   the application MicroBlaze is 'microblaze_0' (or
#                          'microblaze_<n>'); MIG calibration MicroBlaze-MCS
#                          cores are never chosen (see _select_app_microblaze).

import os, sys, re, glob, json, shutil, subprocess, zipfile, xml.etree.ElementTree as ET

# ---------------- utilities ----------------
def die(msg):
    print(f"ERROR: {msg}")
    sys.exit(1)

def info(msg):
    print(msg, flush=True)

def ensure_dir(p):
    os.makedirs(p, exist_ok=True); return p

def copy_tree(src_dir, dst_dir):
    if not src_dir: return 0
    src_dir = os.path.normpath(src_dir)
    if not os.path.isdir(src_dir):
        info(f"NOTE: source folder '{src_dir}' not found; skipping.")
        return 0
    count = 0
    for root, _, files in os.walk(src_dir):
        rel = os.path.relpath(root, src_dir)
        out_root = os.path.join(dst_dir, rel) if rel != "." else dst_dir
        os.makedirs(out_root, exist_ok=True)
        for f in files:
            shutil.copy2(os.path.join(root, f), os.path.join(out_root, f))
            count += 1
    return count

def _copy_single_src_entry(entry, cwd, dst_dir):
    """Copy source files specified by a single src entry (string or dict).
    String: copy entire directory.
    Dict: {"dir": "path", "files": ["a.c", "b.c"]} — copy only listed files.
    """
    if not entry:
        return 0
    if isinstance(entry, str):
        return copy_tree(os.path.join(cwd, entry), dst_dir)
    if isinstance(entry, dict):
        src_dir = os.path.join(cwd, entry.get("dir", ""))
        files = entry.get("files", [])
        if not os.path.isdir(src_dir):
            info(f"NOTE: source folder '{src_dir}' not found; skipping.")
            return 0
        ensure_dir(dst_dir)
        count = 0
        for fname in files:
            src = os.path.join(src_dir, fname)
            if os.path.isfile(src):
                shutil.copy2(src, os.path.join(dst_dir, fname))
                count += 1
            else:
                info(f"WARNING: source file '{src}' not found; skipping.")
        return count
    return 0

def copy_src_entry(entry, cwd, dst_dir):
    """Copy source files from a src entry: string, dict, or list of those."""
    if isinstance(entry, list):
        total = 0
        for item in entry:
            total += _copy_single_src_entry(item, cwd, dst_dir)
        return total
    return _copy_single_src_entry(entry, cwd, dst_dir)

def setup_embeddedsw(repo_root, workspace, arch=None):
    """Set up a local embeddedsw repo in the workspace from patched driver files.

    If <repo_root>/EmbeddedSw/ exists, creates <workspace>/embeddedsw/ containing:
      1. The patched files from the repo's EmbeddedSw/ folder
      2. The full 'src' and 'data' directories from the Vitis install for each
         driver/library that has patched files (without overwriting the patches)

    Two overlays are applied, in order, and later files win:
      EmbeddedSw/              every target (as before)
      EmbeddedSw.<arch>/       only that architecture, e.g. EmbeddedSw.microblaze/
    The per-arch one is optional and purely additive: a repo that does not have
    the directory behaves exactly as it always did. Use it for a patch that
    must NOT reach the other architectures' BSPs -- a BSP metadata change that
    is right for a MicroBlaze design, say, but would alter what the tools
    generate for a Zynq one.

    Returns the path to the local embeddedsw repo, or None if no EmbeddedSw/ folder.
    """
    overlays = [os.path.join(repo_root, "EmbeddedSw")]
    if arch:
        overlays.append(os.path.join(repo_root, f"EmbeddedSw.{arch}"))
    overlays = [d for d in overlays if os.path.isdir(d)]
    if not overlays:
        return None

    # Locate install's embeddedsw: XILINX_VITIS is e.g. /path/2025.2/Vitis
    vitis_root = os.environ.get("XILINX_VITIS", "")
    if not vitis_root:
        die("XILINX_VITIS not set — cannot locate install embeddedsw")
    install_esw = os.path.join(os.path.dirname(vitis_root), "data", "embeddedsw")
    if not os.path.isdir(install_esw):
        die(f"Install embeddedsw not found at: {install_esw}")

    local_esw = os.path.join(workspace, "embeddedsw")
    info(f"Setting up local embeddedsw repo in {local_esw}")

    # Step 1: Copy all patched files from the repo's overlay(s) into workspace
    for embeddedsw_src in overlays:
        for root, _, files in os.walk(embeddedsw_src):
            if not files:
                continue
            rel_dir = os.path.relpath(root, embeddedsw_src)
            if rel_dir == ".":
                continue  # skip root-level files (e.g. README.md)
            dst_dir = os.path.join(local_esw, rel_dir)
            os.makedirs(dst_dir, exist_ok=True)
            for f in files:
                shutil.copy2(os.path.join(root, f), os.path.join(dst_dir, f))
        info(f"  Copied patched files from {os.path.basename(embeddedsw_src)}/")

    # Step 2: Find all 'src' and 'data' directories that should be in the local copy.
    # Look at the install's counterpart for each patched directory's parent to find
    # sibling src/data dirs that may not have been patched but still need copying.
    local_dirs = set()
    for root, dirs, _ in os.walk(local_esw):
        for d in dirs:
            if d in ("src", "data"):
                local_dirs.add(os.path.join(root, d))
        # Also check the install for sibling src/data dirs
        rel = os.path.relpath(root, local_esw)
        install_counterpart = os.path.join(install_esw, rel) if rel != "." else install_esw
        if os.path.isdir(install_counterpart):
            for d in ("src", "data"):
                if os.path.isdir(os.path.join(install_counterpart, d)):
                    local_dirs.add(os.path.join(root, d))

    # Step 3: Copy full contents from install for each src/data dir (no overwrite)
    filled = 0
    for local_dir in local_dirs:
        rel_dir = os.path.relpath(local_dir, local_esw)
        install_dir = os.path.join(install_esw, rel_dir)
        if not os.path.isdir(install_dir):
            info(f"  WARNING: install dir not found: {install_dir}")
            continue
        info(f"  Filling from install: {rel_dir}")
        for src_root, _, src_files in os.walk(install_dir):
            src_rel = os.path.relpath(src_root, install_dir)
            dst_root = os.path.join(local_dir, src_rel) if src_rel != "." else local_dir
            os.makedirs(dst_root, exist_ok=True)
            for f in src_files:
                dst_file = os.path.join(dst_root, f)
                if not os.path.exists(dst_file):
                    shutil.copy2(os.path.join(src_root, f), dst_file)
                    filled += 1
    info(f"  Filled in {filled} file(s) from install")

    return local_esw

def sync_cmake_sources(app_src):
    """Ensure CMakeLists.txt includes all .c files present in app_src.
    Template-based apps generate CMakeLists.txt at creation time, so any
    source files copied later are missing from the build."""
    cmake_path = os.path.join(app_src, "CMakeLists.txt")
    if not os.path.isfile(cmake_path):
        return
    with open(cmake_path, "r") as f:
        content = f.read()
    # Find .c files already collected
    import re
    existing = set(re.findall(r'collect\s*\(\s*PROJECT_LIB_SOURCES\s+(\S+\.c)\s*\)', content))
    # Find all .c files in the src directory
    all_c = {f for f in os.listdir(app_src) if f.endswith('.c')}
    missing = sorted(all_c - existing)
    if not missing:
        return
    # Insert new collect() lines before collector_list
    new_lines = "\n".join(f"collect (PROJECT_LIB_SOURCES {f})" for f in missing)
    content = content.replace(
        "collector_list (_sources PROJECT_LIB_SOURCES)",
        new_lines + "\ncollector_list (_sources PROJECT_LIB_SOURCES)"
    )
    with open(cmake_path, "w") as f:
        f.write(content)
    info(f"CMakeLists.txt: added {len(missing)} source(s): {', '.join(missing)}")

# ---------------- board.h generator ----------------
def create_board_h(board_name, target_dir, linkspeed=None):
    vitis_root = os.environ.get("XILINX_VITIS", "")
    # XILINX_VITIS is e.g. /tools/Xilinx/2025.2/Vitis, so version is parent dir name
    vitis_ver = os.path.basename(os.path.dirname(vitis_root)) if vitis_root else "UNKNOWN"
    bn_up = str(board_name).upper()
    ensure_dir(target_dir)
    path = os.path.join(target_dir, "board.h")
    with open(path, "w", encoding="utf-8") as fd:
        fd.write("/* This file is automatically generated */\n")
        fd.write("#ifndef BOARD_H_\n#define BOARD_H_\n")
        fd.write(f"#define BOARD_NAME \"{bn_up}\"\n")
        fd.write(f"#define VITIS_VERSION \"{vitis_ver}\"\n")
        fd.write(f"#define BOARD_{bn_up} 1\n")
        if linkspeed is not None:
            # Per-port line rate of this target (data.json "linkspeed", e.g.
            # 100, 40, 25, 10). Two forms, each app uses the one it needs:
            #   LINE_RATE      the rate in Gb/s (2x-qsfp28-fmc: MAC bring-up
            #                  config and the Si5328 GT refclk plan)
            #   LINE_RATE_25G  1 for 25G, else 0 (sfp28-fmc-mrmac: MRMAC MODE)
            ls = str(linkspeed).strip()
            if ls.isdigit():
                fd.write(f"#define LINE_RATE {int(ls)}\n")
            else:
                info(f"WARNING: data.json linkspeed {linkspeed!r} is not an integer; "
                     f"LINE_RATE not defined")
            fd.write(f"#define LINE_RATE_25G {1 if str(linkspeed) == '25' else 0}\n")
        fd.write("#endif\n")
    info(f"Generated {path}")

# ---------------- detect arch/CPU from XSA (parse .hwh inside XSA zip) ----------------
CPU_VLNV_HINTS = {
    "microblaze":         "xilinx.com:ip:microblaze",
    "processing_system7": "xilinx.com:ip:processing_system7", # Zynq-7000
    "zynq_ultra_ps_e":    "xilinx.com:ip:zynq_ultra_ps_e",    # ZynqMP
    "versal_cips":        "xilinx.com:ip:versal_cips",        # Versal
}

def _find_modules(xml_bytes):
    try:
        root = ET.fromstring(xml_bytes)
    except ET.ParseError:
        return []
    out = []
    for mod in root.findall(".//MODULE"):
        vlnv = (mod.get("VLNV") or mod.get("VLNV_NAME") or "").lower()
        inst = (mod.get("INSTANCE") or mod.get("NAME") or "")
        if vlnv and inst:
            out.append((inst, vlnv))
    return out

def _select_app_microblaze(names):
    """Pick the *application* MicroBlaze out of the cores found in the top
    block-design .hwh. On UltraScale DDR4 boards the MIG instantiates a
    calibration MicroBlaze inside a MicroBlaze-MCS sub-block (normally in its
    own '*_microblaze_mcs.hwh', which this function never sees, but be
    defensive): drop anything that looks like an MCS sub-block and prefer the
    conventional 'microblaze_0' / 'microblaze_<n>' top-level name. Same rule
    as make-boot.py's _select_app_microblaze()."""
    if not names:
        return "microblaze_0"
    cands = [n for n in names if "_mcs" not in n.lower()] or list(names)
    cands.sort(key=lambda n: (
        n.split("/")[-1] != "microblaze_0",
        re.fullmatch(r"microblaze_\d+", n.split("/")[-1]) is None,
    ))
    return cands[0]

# ---------------- optional: AXI PCIe root-port property (axipcie.yaml) ----------------
# The system device tree names the AXI PCIe root-port flag differently
# depending on which bridge core the design instantiates:
#
#   axi_pcie  (Gen2) -> xlnx,port-type     = <0x1>  (added by the SDT generator
#                                                    from CONFIG.INCLUDE_RC)
#   axi_pcie3 (Gen3) -> xlnx,dev-port-type = <0x2>  (the core's DEV_PORT_TYPE
#                                                    parameter, PCIe port type)
#
# Both cores are served by the same axipcie driver, whose axipcie.yaml can name
# only one of the two in its "required" list -- and the field it does not name
# is simply absent from the node, so the BSP generator writes 0 into the
# IncludeRootComplex field of the config table. The application then aborts with
# "Failed to initialize...AXI PCIE is configured as endpoint" even though the
# core really is a root port. Point the yaml at the property this design's core
# actually publishes.
#
# Inert unless the repo patches axipcie.yaml under EmbeddedSw/ (only then does
# the local embeddedsw copy contain one) and the XSA has an axi_pcie/axi_pcie3.
PCIE_PORT_TYPE_PROPS = [
    ("xilinx.com:ip:axi_pcie:",  "xlnx,port-type"),
    ("xilinx.com:ip:axi_pcie3:", "xlnx,dev-port-type"),
]

def pcie_port_type_prop(xsa_path, bd_name):
    """SDT property carrying the root-port flag for this design's PCIe bridge.
    Returns None for designs with no AXI PCIe bridge (xdma/qdma designs use the
    xdmapcie driver, whose yaml is not patched)."""
    if not zipfile.is_zipfile(xsa_path):
        return None
    vlnvs = []
    with zipfile.ZipFile(xsa_path, "r") as z:
        for name in z.namelist():
            if name.lower() == bd_name + ".hwh":
                try:
                    vlnvs += [v for _, v in _find_modules(z.read(name))]
                except KeyError:
                    pass
    for vlnv_prefix, prop in PCIE_PORT_TYPE_PROPS:
        if any(v.startswith(vlnv_prefix) for v in vlnvs):
            return prop
    return None

def set_axipcie_port_type(local_esw, prop):
    """Rewrite the patched axipcie.yaml's port-type entry to `prop`. Silent
    no-op when the local embeddedsw copy has no axipcie.yaml."""
    pattern = os.path.join(local_esw, "XilinxProcessorIPLib", "drivers",
                           "axipcie_v*", "data", "axipcie.yaml")
    for yaml_path in glob.glob(pattern):
        with open(yaml_path, "r", encoding="utf-8") as f:
            text = f.read()
        new_text, n = re.subn(r"(?m)^([ \t]*-[ \t]*)xlnx,(?:dev-)?port-type[ \t]*$",
                              r"\g<1>" + prop, text)
        if not n:
            info(f"  WARNING: no port-type entry found in {yaml_path}")
            continue
        if new_text != text:
            with open(yaml_path, "w", encoding="utf-8") as f:
                f.write(new_text)
        info(f"  axipcie.yaml: root-port property set to {prop}")

def detect_arch_and_cpu_from_xsa(xsa_path, bd_name):
    """
    Returns:
      arch in {"microblaze","zynq","zynqmp","versal"}
      cpu_hint: instance name for MB ("microblaze_0") or core label for PS
    """
    if not zipfile.is_zipfile(xsa_path):
        return None, None
    modules = []
    with zipfile.ZipFile(xsa_path, "r") as z:
        for name in z.namelist():
            if name.lower() == bd_name + ".hwh":
                try:
                    modules += _find_modules(z.read(name))
                except KeyError:
                    pass
    vlnvs = [v for _, v in modules]
    has = {k: any(h in v for v in vlnvs) for k, h in CPU_VLNV_HINTS.items()}

    if has["microblaze"]:
        return "microblaze", _select_app_microblaze(
            [n for n, v in modules if "microblaze" in v])
    if has["versal_cips"]:
        return "versal", "psv_cortexa72_0"
    if has["zynq_ultra_ps_e"]:
        return "zynqmp", "psu_cortexa53_0"
    if has["processing_system7"]:
        return "zynq", "ps7_cortexa9_0"
    return None, None

# ---------------- linker script modifications ----------------
def resolve_size_option(value, arch):
    """args.json "stack_size"/"heap_size": a plain string applies to every
    architecture (the original behaviour); a dict selects per architecture,
    e.g. {"microblaze": "0x8000"}, and an architecture that is not listed
    keeps the size the tools generated."""
    if isinstance(value, dict):
        return value.get(arch)
    return value

# Sections that "code_local_bss_ddr" leaves in DDR: the zero-initialised,
# NOLOAD data that is too big for the LMB. Everything else -- code, read-only
# data, initialised data, small-data (.sdata/.sbss stay together: the r13
# small-data window), constructors, .drvcfg_sec and the stack -- goes to the
# local memory, which is all updatemem can embed in the bitstream.
CODE_LOCAL_DDR_SECTIONS = (".bss", ".heap")

# Linker mods applied AFTER the stack/heap sizes are set through the Vitis API
# (the others are applied before, as they always were).
LINKER_MODS_AFTER_SIZES = ("code_local_bss_ddr",)

# Linker mods after which the LMB use of the built MicroBlaze ELF is reported
# (log only). Kept to code_local_bss_ddr so the relocate_to_* repos' build logs
# stay as they were; adding "relocate_to_local_mem" here is safe.
LINKER_MODS_REPORT_LMB = ("code_local_bss_ddr",)

def _relocate_sections(text, names, target_mem):
    """Point the output sections in 'names' at target_mem."""
    for name in names:
        pat = re.compile(r'(^' + re.escape(name) + r'\b[^{\n]*\{.*?\}\s*>\s*)(\S+)',
                         re.MULTILINE | re.DOTALL)
        text, n = pat.subn(lambda m: m.group(1) + target_mem, text, count=1)
        if n == 0:
            info(f"WARNING: section {name} not found in lscript.ld; left as is.")
    return text

def modify_linker_script(lscript_path, mod_type):
    """Modify the auto-generated linker script.
    mod_type: "relocate_to_local_mem", "relocate_to_ddr" or
    "code_local_bss_ddr" (MicroBlaze booting from the bitstream with a big
    .bss: everything in the local memory except CODE_LOCAL_DDR_SECTIONS,
    which go to DDR; the start-up code zeroes .bss wherever it is)
    """
    if not os.path.isfile(lscript_path):
        info(f"WARNING: lscript.ld not found at {lscript_path}; skipping linker mods.")
        return
    with open(lscript_path, "r", encoding="utf-8") as f:
        text = f.read()

    # Parse MEMORY section to find memory names
    mem_pattern = re.compile(r'(\S+)\s*:\s*ORIGIN\s*=', re.MULTILINE)
    memories = mem_pattern.findall(text)
    if not memories:
        info("WARNING: No MEMORY entries found in lscript.ld; skipping.")
        return

    ddr_mem = None
    if mod_type in ("relocate_to_local_mem", "code_local_bss_ddr"):
        target_mem = next((m for m in memories if "local_memory" in m), None)
        if not target_mem:
            info("WARNING: No local_memory found in lscript.ld; skipping relocation.")
            return
        if mod_type == "code_local_bss_ddr":
            ddr_mem = next((m for m in memories if "ddr" in m.lower()), None)
            if not ddr_mem:
                info("WARNING: No DDR memory found in lscript.ld; skipping relocation.")
                return
    elif mod_type == "relocate_to_ddr":
        target_mem = next((m for m in memories if "ddr" in m.lower()), None)
        if not target_mem:
            info("WARNING: No DDR memory found in lscript.ld; skipping relocation.")
            return
    else:
        info(f"WARNING: Unknown linker mod type '{mod_type}'; skipping.")
        return

    for m in memories:
        if m != target_mem:
            text = re.sub(r'>\s*' + re.escape(m) + r'\b', f'> {target_mem}', text)
    if ddr_mem:
        text = _relocate_sections(text, CODE_LOCAL_DDR_SECTIONS, ddr_mem)

    with open(lscript_path, "w", encoding="utf-8") as f:
        f.write(text)
    if ddr_mem:
        info(f"Linker script: {', '.join(CODE_LOCAL_DDR_SECTIONS)} in {ddr_mem}, "
             f"everything else in {target_mem}")
    else:
        info(f"Linker script: relocated all sections to {target_mem}")

def report_local_mem_use(elf_path, lscript_path):
    """Print how much of the MicroBlaze local memory (LMB) the ELF occupies:
    the sections that updatemem embeds in the bitstream, plus the stack. The
    linker already fails on an overflow; this is the headroom figure."""
    try:
        with open(lscript_path, "r", encoding="utf-8") as f:
            text = f.read()
        m = re.search(r'(\S*local_memory\S*)\s*:\s*ORIGIN\s*=\s*(0x[0-9a-fA-F]+)\s*,'
                      r'\s*LENGTH\s*=\s*(0x[0-9a-fA-F]+)', text)
        if not m:
            return
        origin, length = int(m.group(2), 16), int(m.group(3), 16)
        out = subprocess.run(["mb-size", "-A", elf_path], stdout=subprocess.PIPE,
                             stderr=subprocess.STDOUT, text=True).stdout
    except (OSError, ValueError):
        return
    used, rows = 0, []
    for line in out.splitlines():
        parts = line.split()
        if len(parts) != 3 or not parts[1].isdigit() or not parts[2].isdigit():
            continue
        name, size, addr = parts[0], int(parts[1]), int(parts[2])
        if size and addr < origin + length and not name.startswith((".debug", ".comment")):
            used += size
            rows.append(f"{name} {size}")
    top = origin + length   # the vectors below ORIGIN are part of the LMB too
    info(f"Local memory (LMB) use: {used} of {top} bytes ({100.0 * used / top:.1f} %), "
         f"{top - used} free: " + ", ".join(rows))

def set_gc_sections(app_src):
    """Turn on section garbage collection in the app component's
    UserConfig.cmake: USER_COMPILE_GARBAGE (compile with -ffunction-sections
    -fdata-sections) and -Wl,--gc-sections in USER_LINK_OTHER_FLAGS. The
    generated linker script KEEPs the vectors, .init/.fini, constructors and
    .drvcfg_sec, so only unreferenced code and data are dropped."""
    path = os.path.join(app_src, "UserConfig.cmake")
    if not os.path.isfile(path):
        info(f"WARNING: {path} not found; no section garbage collection.")
        return
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()
    text, n1 = re.subn(r'set\(USER_COMPILE_GARBAGE[^)]*\)',
                       'set(USER_COMPILE_GARBAGE "-Wl,--gc-sections")', text, count=1)
    text, n2 = re.subn(r'set\(USER_LINK_OTHER_FLAGS\s*',
                       'set(USER_LINK_OTHER_FLAGS -Wl,--gc-sections\n', text, count=1)
    if n1 == 0 or n2 == 0:
        info("WARNING: USER_COMPILE_GARBAGE / USER_LINK_OTHER_FLAGS not found in UserConfig.cmake.")
        return
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
    info("UserConfig.cmake: section garbage collection (--gc-sections) on")

def set_compile_optimization(app_src, level):
    """Set the app component's USER_COMPILE_OPTIMIZATION_LEVEL (UserConfig.cmake)."""
    path = os.path.join(app_src, "UserConfig.cmake")
    if not os.path.isfile(path):
        info(f"WARNING: {path} not found; optimisation level left at the default.")
        return
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()
    text, n = re.subn(r'set\(USER_COMPILE_OPTIMIZATION_LEVEL[^)]*\)',
                      f'set(USER_COMPILE_OPTIMIZATION_LEVEL {level})', text, count=1)
    if n == 0:
        info("WARNING: USER_COMPILE_OPTIMIZATION_LEVEL not found in UserConfig.cmake.")
        return
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
    info(f"UserConfig.cmake: optimisation level {level}")

# ---------------- Vitis API (must run under `vitis -source`) ----------------
try:
    import vitis
except ImportError:
    die("Must be run with the Vitis CLI:  vitis -source build-vitis.py [<target>] <args.json> [<data.json>]")

# ---------------- CLI & data.json handling ----------------
# ---------------- optional User DTS for the platform ----------------
def resolve_user_dtsi(cfg, cwd, xsa_path, workspace):
    """Absolute path of the platform's User DTS, or None when not configured.

    Reads the two optional args.json keys documented at the top of this file:
    "user_dtsi" (a checked-in .dtsi, relative to Vitis/) and, when the file has
    to be derived from the current XSA, "user_dtsi_generator" (a repo-local
    module exposing compose(vitis_dir, xsa_path, out_dir, cfg)).

    Inert when neither key is set -- returns None and the caller passes no
    advanced_options at all, which is the behaviour every existing repo has.
    Must be called AFTER client.set_workspace() (Vitis rejects a workspace
    directory containing files it did not create itself) and BEFORE
    create_platform_component() (the only call that accepts a User DTS).
    """
    user_dtsi_gen = cfg.get("user_dtsi_generator")
    if not user_dtsi_gen:
        rel = cfg.get("user_dtsi")
        if not rel:
            return None
        path = os.path.normpath(os.path.join(cwd, rel))
        if not os.path.isfile(path):
            die(f'args.json "user_dtsi" not found: {path}')
        info(f"User DTS        : {path}")
        return path

    script_path = os.path.normpath(os.path.join(cwd, user_dtsi_gen))
    if not os.path.isfile(script_path):
        die(f'args.json "user_dtsi_generator" not found: {script_path}')
    info(f"Composing User DTS with: {script_path}")
    import importlib.util
    spec = importlib.util.spec_from_file_location("user_dtsi_generator", script_path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    if not hasattr(mod, "compose"):
        die(f"{script_path} has no compose(vitis_dir, xsa_path, out_dir, cfg)")
    out_dir = os.path.join(workspace, "dts")
    path = mod.compose(vitis_dir=cwd, xsa_path=xsa_path, out_dir=out_dir, cfg=cfg)
    if not path:
        info("User DTS        : generator returned nothing -- none for this target")
        return None
    if not os.path.isfile(path):
        die(f"user_dtsi_generator returned a path that does not exist: {path}")
    info(f"User DTS        : {path}")
    return path


def parse_cli(argv):
    args = argv[1:]
    if args and args[0] == "--":
        args = args[1:]
    if len(args) not in (2, 3):
        die("Usage: vitis -source build-vitis.py [<target>] <path/to/args.json> [<path/to/data.json>]")

    if len(args) == 2:
        # Could be: <args.json> <data.json> (interactive) OR <target> <args.json> (no data.json)
        if os.path.isfile(args[0]) and args[0].endswith(".json"):
            # First arg is a file — assume interactive mode: <args.json> <data.json>
            target = None
            args_json_path, data_json_path = args
        else:
            # First arg is target name: <target> <args.json>
            target = args[0]
            args_json_path = args[1]
            data_json_path = None
    else:
        target, args_json_path, data_json_path = args

    args_json_path = os.path.normpath(args_json_path)
    if not os.path.isfile(args_json_path):
        die(f"args.json not found: {args_json_path}")

    # data.json is optional — "none" or missing means no data.json
    if data_json_path and data_json_path.lower() != "none":
        data_json_path = os.path.normpath(data_json_path)
        if not os.path.isfile(data_json_path):
            die(f"data.json not found: {data_json_path}")
    else:
        data_json_path = None

    return target, args_json_path, data_json_path

def pick_target_interactively(data_json_path):
    with open(data_json_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    designs = data.get("designs", [])
    bare = [d for d in designs if d.get("baremetal", False)]
    if not bare:
        die("No bare-metal designs found in data.json")

    groups = {g.get("label"): g.get("name") for g in data.get("groups", [])}

    print("Select a target:")
    for i, d in enumerate(bare, start=1):
        grp_label = d.get("group")
        grp_name = groups.get(grp_label, grp_label or "")
        label = d.get("label", "?")
        board = d.get("board", d.get("boardname", ""))
        print(f"  {i:2d}) {label:<12}  {board:<20}  [{grp_name}]")

    while True:
        try:
            sel = input("Enter number: ").strip()
        except EOFError:
            die("No selection provided (EOF).")
        if not sel.isdigit():
            print("Please enter a number from the list.")
            continue
        idx = int(sel)
        if 1 <= idx <= len(bare):
            return bare[idx - 1].get("label")
        print("Out of range. Try again.")

def find_design_entry(data_json_path, target_label):
    """The target's baremetal design entry in data.json, or None."""
    with open(data_json_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    for d in data.get("designs", []):
        if d.get("label") == target_label and d.get("baremetal", False):
            return d
    return None

def load_design_entry(data_json_path, target_label):
    d = find_design_entry(data_json_path, target_label)
    if d is None:
        die(f"Target '{target_label}' not found (or not baremetal) in data.json")
    return d

# ---------------- main ----------------
def main():
    # Parse CLI
    maybe_target, args_json_path, data_json_path = parse_cli(sys.argv)

    # If no target supplied, prompt from bare-metal designs
    if not maybe_target:
        if not data_json_path:
            die("No target specified and no data.json available for interactive selection.")
        maybe_target = pick_target_interactively(data_json_path)
        info(f"Chosen target: {maybe_target}")

    # Load args.json
    with open(args_json_path, "r", encoding="utf-8") as f:
        cfg = json.load(f)

    bd_name = cfg.get("bd_name")
    if not bd_name:
        die('args.json must include "bd_name".')

    app_name     = cfg.get("app_name", "test_app")
    app_template = cfg.get("app_template")
    if app_template is not None and app_template.strip().lower() in ("none", ""):
        app_template = None

    bsp_libs  = cfg.get("bsp_libs", []) or []

    src_map        = cfg.get("src", {}) or {}
    src_overrides  = cfg.get("src_overrides", {}) or {}
    src_all    = src_map.get("all")
    src_mb     = src_map.get("mb")
    src_zynq   = src_map.get("zynq")
    src_zynqmp = src_map.get("zynqmp")
    src_versal = src_map.get("versal")

    pre_build_script = cfg.get("pre_build_script")
    pre_platform_build_script = cfg.get("pre_platform_build_script")
    user_dtsi = cfg.get("user_dtsi")
    user_dtsi_generator = cfg.get("user_dtsi_generator")
    stack_size = cfg.get("stack_size")
    heap_size = cfg.get("heap_size")
    compile_opt = cfg.get("compile_optimization")
    gc_sections = cfg.get("gc_sections")

    # Board name for board.h: prefer args.json's "boardnames" map — that's
    # the short ID used by fmc-prod-test-common's eeprom_fmc.c (e.g. "UZEV",
    # "ZCU102"). Only fall back to data.json's "boardname" / "board" (which
    # is the Vivado board-store vendor name, e.g. "ultrazed_7ev_cc") when
    # no args.json mapping exists for this target. This split lets Vivado
    # use the long vendor name for get_board_parts while board.h gets the
    # short ID iic_muxes[] expects.
    target = maybe_target
    boardnames = cfg.get("boardnames", {})
    if target in boardnames:
        board_name_for_header = boardnames[target]
    elif data_json_path:
        design = load_design_entry(data_json_path, target)
        board_name_for_header = design.get("boardname", design.get("board", target))
    else:
        board_name_for_header = target

    # Optional data.json "linkspeed" for board.h (LINE_RATE / LINE_RATE_25G).
    # Looked up without failing: a target that is not a baremetal entry in
    # data.json has already died above unless boardnames supplied its name.
    linkspeed_for_header = None
    if data_json_path:
        entry = find_design_entry(data_json_path, target)
        if entry:
            linkspeed_for_header = entry.get("linkspeed")

    # Vivado project path (with optional postfix)
    vivado_postfix = cfg.get("vivado_postfix", "")
    linker_mods = cfg.get("linker_script_mods", {})

    # Derived paths from target
    cwd         = os.getcwd()
    workspace   = os.path.normpath(os.path.join(cwd, f"{target}_workspace"))
    vivado_proj = os.path.normpath(os.path.join(cwd, "..", "Vivado", target + vivado_postfix))
    xsa_path    = os.path.normpath(os.path.join(vivado_proj, f"{bd_name}_wrapper.xsa"))

    # Banner
    info("== Vitis workspace build (menu/json-driven) ==")
    info(f"target          : {target}")
    info(f"workspace       : {workspace}")
    info(f"vivado_proj     : {vivado_proj}")
    info(f"xsa_path        : {xsa_path}")
    info(f"bd_name         : {bd_name}")
    info(f"app_name        : {app_name}")
    info(f"app_template    : {app_template if app_template else 'None (minimal app)'}")
    info(f"boardname       : {board_name_for_header}")
    info(f"src.all         : {src_all if src_all else '(none)'}")
    info(f"src.mb          : {src_mb if src_mb else '(none)'}")
    info(f"src.zynq        : {src_zynq if src_zynq else '(none)'}")
    info(f"src.zynqmp      : {src_zynqmp if src_zynqmp else '(none)'}")
    info(f"src.versal      : {src_versal if src_versal else '(none)'}")
    info(f"bsp_libs        : {bsp_libs if bsp_libs else '(none)'}")
    if linker_mods:
        info(f"linker_mods     : {linker_mods}")
    if pre_platform_build_script:
        info(f"pre_plat_script : {pre_platform_build_script}")
    if pre_build_script:
        info(f"pre_build_script: {pre_build_script}")
    if user_dtsi:
        info(f"user_dtsi       : {user_dtsi}")
    if user_dtsi_generator:
        info(f"user_dtsi_gen   : {user_dtsi_generator}")

    if not os.path.isfile(xsa_path):
        die(f"XSA not found at: {xsa_path}")
    ensure_dir(workspace)

    # Detect architecture / CPU hint from XSA
    arch, cpu_hint = detect_arch_and_cpu_from_xsa(xsa_path, bd_name)
    if not arch:
        die("Could not detect architecture from XSA (MicroBlaze/Zynq/ZynqMP/Versal).")
    info(f"Detected arch   : {arch} (cpu/core hint: {cpu_hint})")

    # stack_size/heap_size may be per-architecture maps -- resolve now that
    # the architecture is known.
    stack_size = resolve_size_option(stack_size, arch)
    heap_size  = resolve_size_option(heap_size, arch)
    compile_opt = resolve_size_option(compile_opt, arch)
    gc_sections = resolve_size_option(gc_sections, arch)

    # Create workspace, platform, domain, app
    client = vitis.create_client()
    try:
        client.set_workspace(workspace)

        # Set up local embeddedsw repo (patched BSP drivers) if present
        repo_root = os.path.normpath(os.path.join(cwd, ".."))
        local_esw = setup_embeddedsw(repo_root, workspace, arch)
        if local_esw:
            # Align a patched axipcie.yaml with the PCIe core in this design
            # (see PCIE_PORT_TYPE_PROPS); no-op for every other repo
            port_type_prop = pcie_port_type_prop(xsa_path, bd_name)
            if port_type_prop:
                set_axipcie_port_type(local_esw, port_type_prop)
            client.set_embedded_sw_repo(level='LOCAL', path=local_esw)
            info(f"Registered local embeddedsw repo: {local_esw}")

        # Optional User DTS: resolved (and, for a generated one, composed) here
        # -- after set_workspace, before the platform exists. No advanced_options
        # are passed when the args.json keys are absent, so nothing changes for
        # a repo that does not use the feature.
        plat_kwargs = {}
        user_dtsi_path = resolve_user_dtsi(cfg, cwd, xsa_path, workspace)
        if user_dtsi_path:
            plat_kwargs["advanced_options"] = client.create_advanced_options_dict(
                user_dtsi=user_dtsi_path)
            info(f"Platform advanced options: {plat_kwargs['advanced_options']}")

        plat_name = f"{target}_platform"
        info(f"Creating platform '{plat_name}' (cpu={cpu_hint}, os=standalone) ...")
        platform = client.create_platform_component(
            name=plat_name,
            hw_design=xsa_path,
            cpu=cpu_hint,
            os="standalone",
            **plat_kwargs
        )

        doms = platform.list_domains()
        if not doms:
            die("Platform has no domains after creation (unexpected).")
        # Pick the application domain (skip boot domains like zynqmp_fsbl, versal_plm, etc.)
        BOOT_DOMAIN_PREFIXES = ("zynq_fsbl", "zynqmp_fsbl", "zynqmp_pmufw", "versal_plm", "versal_psmfw")
        domain_name = None
        for d in doms:
            dname = d.get("domain_name", "")
            if dname.startswith(BOOT_DOMAIN_PREFIXES):
                continue
            if d.get("processor") == cpu_hint and d.get("os") == "standalone":
                domain_name = dname; break
        if not domain_name:
            # Fallback: pick the first non-boot domain
            for d in doms:
                if not d.get("domain_name", "").startswith(BOOT_DOMAIN_PREFIXES):
                    domain_name = d["domain_name"]; break
        if not domain_name:
            domain_name = doms[0]["domain_name"]
        info(f"Using domain    : {domain_name}")

        # Add BSP libraries (e.g. lwip220) and configure them before building
        if bsp_libs:
            domain = platform.get_domain(domain_name)
            for lib_entry in bsp_libs:
                if isinstance(lib_entry, str):
                    lib_name_str = lib_entry
                    lib_config = {}
                else:
                    lib_name_str = lib_entry["name"]
                    lib_config = lib_entry.get("config", {})
                info(f"Adding BSP library: {lib_name_str}")
                try:
                    domain.set_lib(lib_name=lib_name_str)
                except Exception as e:
                    info(f"  Note: set_lib({lib_name_str}) raised: {e}")
                    info(f"  (library may already be present -- continuing with config)")
                for param, value in lib_config.items():
                    info(f"  Setting {lib_name_str} param: {param} = {value}")
                    domain.set_config(option="lib", param=param, value=value, lib_name=lib_name_str)

        # Run pre-platform-build script (if configured)
        if pre_platform_build_script:
            script_path = os.path.normpath(os.path.join(cwd, pre_platform_build_script))
            info(f"Running pre-platform-build script: {script_path}")
            import importlib.util
            spec = importlib.util.spec_from_file_location("pre_platform_build", script_path)
            mod = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(mod)
            mod.pre_platform_build(platform=platform, domain_name=domain_name, arch=arch)

        info("Building platform ...")
        platform.build()

        xpfm = os.path.join(workspace, plat_name, "export", plat_name, f"{plat_name}.xpfm")
        if not os.path.isfile(xpfm):
            found = glob.glob(os.path.join(workspace, "**", f"{plat_name}.xpfm"), recursive=True)
            if found: xpfm = found[0]
        if not os.path.isfile(xpfm):
            die(f"Could not locate platform .xpfm after build (looked for {xpfm}).")

        info(f"Creating application '{app_name}' ...")
        if app_template:
            info(f"  -> using template: {app_template!r}")
            app = client.create_app_component(
                name=app_name,
                platform=xpfm,
                domain=domain_name,
                template=app_template,
            )
        else:
            info("  -> creating with NO template (minimal app)")
            app = client.create_app_component(
                name=app_name,
                platform=xpfm,
                domain=domain_name,
            )

        # Copy sources
        app_root = os.path.join(workspace, app_name)
        app_src  = os.path.join(app_root, "src")
        ensure_dir(app_src)

        copied = 0
        # Check for target-specific source override first
        if target in src_overrides:
            override = src_overrides[target]
            info(f"Using src_overrides for target '{target}'")
            copied += copy_src_entry(override, cwd, app_src)
        else:
            # Standard arch-based source copying
            if src_all:     copied += copy_src_entry(src_all, cwd, app_src)
            arch_src = {"microblaze": src_mb, "zynq": src_zynq,
                        "zynqmp": src_zynqmp, "versal": src_versal}.get(arch)
            if arch_src:    copied += copy_src_entry(arch_src, cwd, app_src)
        info(f"Copied files    : {copied} into {app_src}")

        # Ensure CMakeLists.txt includes all copied .c files
        if app_template and app_template.lower() != "none":
            sync_cmake_sources(app_src)

        # Create board.h in app src
        create_board_h(board_name_for_header, app_src, linkspeed_for_header)

        # Linker script modifications that go BEFORE the stack/heap sizes
        lscript_path = os.path.join(app_src, "lscript.ld")
        linker_mod = linker_mods.get(arch)
        if arch in linker_mods and linker_mod not in LINKER_MODS_AFTER_SIZES:
            info(f"Applying linker script mod: {linker_mod}")
            modify_linker_script(lscript_path, linker_mod)

        # Stack/heap size overrides (if configured)
        if stack_size or heap_size:
            ld = app.get_ld_script()
            if stack_size:
                ld.set_stack_size(size=stack_size)
                info(f"Linker script: stack size set to {stack_size}")
            if heap_size:
                ld.set_heap_size(size=heap_size)
                info(f"Linker script: heap size set to {heap_size}")

        # Linker script modifications that go AFTER the stack/heap sizes, so
        # that nothing rewrites the regions afterwards
        if arch in linker_mods and linker_mod in LINKER_MODS_AFTER_SIZES:
            info(f"Applying linker script mod: {linker_mod}")
            modify_linker_script(lscript_path, linker_mod)

        # App optimisation level (if configured for this arch)
        if compile_opt:
            set_compile_optimization(app_src, compile_opt)
        if gc_sections is True or str(gc_sections).lower() == "true":
            set_gc_sections(app_src)

        # Run pre-build script (if configured)
        if pre_build_script:
            script_path = os.path.normpath(os.path.join(cwd, pre_build_script))
            info(f"Running pre-build script: {script_path}")
            result = subprocess.run([sys.executable, script_path, app_src], cwd=cwd)
            if result.returncode != 0:
                die(f"Pre-build script failed with exit code {result.returncode}")

        # Build the app
        info("Building application ...")
        app.build()

        # Check if ELF was actually produced
        elf_path = os.path.join(workspace, app_name, "build", f"{app_name}.elf")
        build_ok = os.path.isfile(elf_path)
        if build_ok:
            info(f"{app_name} build succeeded: {elf_path}")
            if arch == "microblaze" and linker_mod in LINKER_MODS_REPORT_LMB:
                report_local_mem_use(elf_path, lscript_path)
        else:
            info(f"{app_name} build failed. ")

        info("\n== DONE ==")
        info(f"Workspace : {workspace}")
        info(f"Platform  : {plat_name}")
        info(f"Domain    : {domain_name}")
        info(f"App       : {app_name}")
        info(f"Open IDE  : vitis -w {workspace}")

        if not build_ok:
            sys.exit(1)

    finally:
        try:
            client.dispose()
        except Exception:
            pass

if __name__ == "__main__":
    main()

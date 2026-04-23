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
#     "microblaze": "relocate_to_local_mem",
#     "zynq": "relocate_to_ddr"
#   },
#   "stack_size": "0x10000",         # optional: override default stack size in linker script
#   "heap_size": "0x10000",          # optional: override default heap size in linker script
#   "combine_bit_elf": true        # ignored here; used by make-boot.py later
# }

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

def setup_embeddedsw(repo_root, workspace):
    """Set up a local embeddedsw repo in the workspace from patched driver files.

    If <repo_root>/EmbeddedSw/ exists, creates <workspace>/embeddedsw/ containing:
      1. The patched files from the repo's EmbeddedSw/ folder
      2. The full 'src' and 'data' directories from the Vitis install for each
         driver/library that has patched files (without overwriting the patches)

    Returns the path to the local embeddedsw repo, or None if no EmbeddedSw/ folder.
    """
    embeddedsw_src = os.path.join(repo_root, "EmbeddedSw")
    if not os.path.isdir(embeddedsw_src):
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

    # Step 1: Copy all patched files from repo's EmbeddedSw/ into workspace
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
    info(f"  Copied patched files from EmbeddedSw/")

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
def create_board_h(board_name, target_dir):
    vitis_root = os.environ.get("XILINX_VITIS", "")
    # XILINX_VITIS is e.g. /home/jeff/Xilinx/2025.2/Vitis, so version is parent dir name
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
        mb_inst = next((n for n, v in modules if "microblaze" in v), "microblaze_0")
        return "microblaze", mb_inst
    if has["versal_cips"]:
        return "versal", "psv_cortexa72_0"
    if has["zynq_ultra_ps_e"]:
        return "zynqmp", "psu_cortexa53_0"
    if has["processing_system7"]:
        return "zynq", "ps7_cortexa9_0"
    return None, None

# ---------------- linker script modifications ----------------
def modify_linker_script(lscript_path, mod_type):
    """Modify the auto-generated linker script.
    mod_type: "relocate_to_local_mem" or "relocate_to_ddr"
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

    if mod_type == "relocate_to_local_mem":
        target_mem = next((m for m in memories if "local_memory" in m), None)
        if not target_mem:
            info("WARNING: No local_memory found in lscript.ld; skipping relocation.")
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
            text = re.sub(r'>\s*' + re.escape(m), f'> {target_mem}', text)

    with open(lscript_path, "w", encoding="utf-8") as f:
        f.write(text)
    info(f"Linker script: relocated all sections to {target_mem}")

# ---------------- Vitis API (must run under `vitis -source`) ----------------
try:
    import vitis
except ImportError:
    die("Must be run with the Vitis CLI:  vitis -source build-vitis.py [<target>] <args.json> [<data.json>]")

# ---------------- CLI & data.json handling ----------------
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

def load_design_entry(data_json_path, target_label):
    with open(data_json_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    for d in data.get("designs", []):
        if d.get("label") == target_label and d.get("baremetal", False):
            return d
    die(f"Target '{target_label}' not found (or not baremetal) in data.json")

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
    stack_size = cfg.get("stack_size")
    heap_size = cfg.get("heap_size")

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

    if not os.path.isfile(xsa_path):
        die(f"XSA not found at: {xsa_path}")
    ensure_dir(workspace)

    # Detect architecture / CPU hint from XSA
    arch, cpu_hint = detect_arch_and_cpu_from_xsa(xsa_path, bd_name)
    if not arch:
        die("Could not detect architecture from XSA (MicroBlaze/Zynq/ZynqMP/Versal).")
    info(f"Detected arch   : {arch} (cpu/core hint: {cpu_hint})")

    # Create workspace, platform, domain, app
    client = vitis.create_client()
    try:
        client.set_workspace(workspace)

        # Set up local embeddedsw repo (patched BSP drivers) if present
        repo_root = os.path.normpath(os.path.join(cwd, ".."))
        local_esw = setup_embeddedsw(repo_root, workspace)
        if local_esw:
            client.set_embedded_sw_repo(level='LOCAL', path=local_esw)
            info(f"Registered local embeddedsw repo: {local_esw}")

        plat_name = f"{target}_platform"
        info(f"Creating platform '{plat_name}' (cpu={cpu_hint}, os=standalone) ...")
        platform = client.create_platform_component(
            name=plat_name,
            hw_design=xsa_path,
            cpu=cpu_hint,
            os="standalone"
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
        create_board_h(board_name_for_header, app_src)

        # Linker script modifications (if configured for this arch)
        lscript_path = os.path.join(app_src, "lscript.ld")
        if arch in linker_mods:
            info(f"Applying linker script mod: {linker_mods[arch]}")
            modify_linker_script(lscript_path, linker_mods[arch])

        # Stack/heap size overrides (if configured)
        if stack_size or heap_size:
            ld = app.get_ld_script()
            if stack_size:
                ld.set_stack_size(size=stack_size)
                info(f"Linker script: stack size set to {stack_size}")
            if heap_size:
                ld.set_heap_size(size=heap_size)
                info(f"Linker script: heap size set to {heap_size}")

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

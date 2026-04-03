# Opsero Electronic Design Inc. (C) 2025

# Script to open Vitis workspace and generate boot files.
# - Microblaze - a bitstream file (.bit)
# - Zynq, ZynqMP, Versal - a BOOT.bin file

# make-boot.py — Create bootfile for a Vitis (Unified) workspace
# Usage:
#   vitis -source make-boot.py <target> <path/to/args.json> [<path/to/data.json>]
#   python3 make-boot.py <target> <path/to/args.json> [<path/to/data.json>]
#
# Paths derived from <target>:
#   workspace   = ./<target>_workspace
#   vivado_proj = ./../Vivado/<target>
#   xsa_path    = ../Vivado/<target>/<bd_name>_wrapper.xsa
#   impl_dir    = ../Vivado/<target>/<bd_name>.runs/impl_1
#   out_dir     = ./boot/<target>/
#
# ELF path (Unified Vitis):
#   <workspace>/<app_name>/build/<app_name>.elf
#
# Device handling:
#   MicroBlaze:
#       combine_bit_elf=true  → updatemem => <bd_name>_boot.bit
#       combine_bit_elf=false → copy bit  => <bd_name>.bit
#   Zynq (ps7):
#       BIF (we generate): [bootloader] fsbl.elf, then bit, then app.elf → bootgen -arch zynq → BOOT.BIN
#   ZynqMP (a53):
#       BIF (we generate): bootloader@a53-0, [destination_device=pl] bit, app@EL3 → bootgen -arch zynqmp → BOOT.BIN
#   Versal:
#       BIF (we generate): first image with PDI (type=bootimage), second image with app.elf on detected core
#       PDI preference: <workspace>/<app>/_ide/bootimage/resources/<bd>_wrapper.pdi, fallback: Vivado impl PDI
#       → bootgen -arch versal → BOOT.BIN

import os, sys, re, json, glob, zipfile, subprocess, shutil, xml.etree.ElementTree as ET

# ---------------- utilities ----------------
def die(msg):
    print("ERROR:", msg)
    sys.exit(1)

def note(msg):
    print(msg, flush=True)

def ensure_dir(p):
    os.makedirs(p, exist_ok=True); return p

def pick_first_existing(*paths):
    for p in paths:
        if p and os.path.isfile(p):
            return p
    return None

def is_abs(p):
    return os.path.isabs(p) or re.match(r"^[A-Za-z]:[\\/]", p) is not None

# ---------------- CLI & menu ----------------
def parse_cli(argv):
    args = argv[1:]
    if args and args[0] == "--":
        args = args[1:]
    if len(args) not in (2, 3):
        die("Usage: make-boot.py <target> <path/to/args.json> [<path/to/data.json>]")
    if len(args) == 2:
        # Could be: <args.json> <data.json> (interactive) OR <target> <args.json> (no data.json)
        if os.path.isfile(args[0]) and args[0].endswith(".json"):
            target = None
            args_json, data_json = args
        else:
            target = args[0]
            args_json = args[1]
            data_json = None
    else:
        target, args_json, data_json = args
    args_json = os.path.normpath(args_json)
    if not os.path.isfile(args_json): die(f"args.json not found: {args_json}")
    # data.json is optional — "none" means no data.json
    if data_json and data_json.lower() != "none":
        data_json = os.path.normpath(data_json)
        if not os.path.isfile(data_json): die(f"data.json not found: {data_json}")
    else:
        data_json = None
    return target, args_json, data_json

def pick_target_interactively(data_json_path):
    if not data_json_path:
        die("No target specified and no data.json available for interactive selection.")
    with open(data_json_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    designs = [d for d in data.get("designs", []) if d.get("baremetal", False)]
    if not designs:
        die("No bare-metal designs in data.json")
    groups = {g.get("label"): g.get("name") for g in data.get("groups", [])}

    print("Select a target:")
    for i, d in enumerate(designs, start=1):
        label = d.get("label","?")
        board = d.get("board", d.get("boardname",""))
        grp   = groups.get(d.get("group"), d.get("group",""))
        print(f"  {i:2d}) {label:<12} {board:<20} [{grp}]")

    while True:
        s = input("Enter number: ").strip()
        if not s.isdigit():
            print("Please enter a valid number.")
            continue
        idx = int(s)
        if 1 <= idx <= len(designs):
            return designs[idx-1].get("label")
        print("Out of range. Try again.")

# ---------------- detect arch/CPU from XSA (parse .hwh inside XSA zip) ----------------
CPU_VLNV_HINTS = {
    "microblaze":       "xilinx.com:ip:microblaze",
    "ps7":              "xilinx.com:ip:processing_system7", # Zynq-7000
    "zynq_ultra_ps_e":  "xilinx.com:ip:zynq_ultra_ps_e",   # ZynqMP
    "versal_cips":      "xilinx.com:ip:versal_cips",       # Versal
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

def detect_arch_and_cpu_from_xsa(xsa_path):
    """
    Returns:
      arch in {"microblaze","zynq","zynqmp","versal"}
      cpu_hint: instance for MB ("microblaze_0") or core label for PS ("a9-0","a53-0","a72-0","r5-0")
    """
    if not zipfile.is_zipfile(xsa_path):
        return None, None
    modules = []
    with zipfile.ZipFile(xsa_path, "r") as z:
        for name in z.namelist():
            if name.lower().endswith(".hwh"):
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
        core = "a72-0" if any("a72" in v for _, v in modules) else ("r5-0" if any("r5" in v for _, v in modules) else "a72-0")
        return "versal", core
    if has["zynq_ultra_ps_e"]:
        core = "a53-0" if any("a53" in v for _, v in modules) else ("r5-0" if any("r5" in v for _, v in modules) else "a53-0")
        return "zynqmp", core
    if has["ps7"]:
        return "zynq", "a9-0"
    return None, None

# ---------------- MicroBlaze: embed or copy bit ----------------
def make_mb_bit(impl_dir, bd_name, elf_path, mb_proc_name, out_bit, combine):
    bit = pick_first_existing(
        os.path.join(impl_dir, f"{bd_name}_wrapper.bit"),
        os.path.join(impl_dir, f"{bd_name}.bit"),
    )
    mmi = pick_first_existing(
        os.path.join(impl_dir, f"{bd_name}_wrapper.mmi"),
        os.path.join(impl_dir, f"{bd_name}.mmi"),
    )
    if not bit:
        die(f"Could not find bit in '{impl_dir}' (expected {bd_name}_wrapper.bit or {bd_name}.bit)")
    if combine:
        if not mmi:
            die(f"Could not find MMI in '{impl_dir}' (expected {bd_name}_wrapper.mmi or {bd_name}.mmi)")
        if not os.path.isfile(elf_path):
            die(f"ELF not found: {elf_path}")
        cmd = ["updatemem", "-force", "-meminfo", mmi, "-data", elf_path, "-bit", bit, "-proc", f"{bd_name}_i/{mb_proc_name}", "-out", out_bit]
        note("Running: " + " ".join(cmd))
        try:
            subprocess.check_call(cmd)
        except FileNotFoundError:
            die("updatemem not found. Source Vivado/Vitis settings64.sh")
        except subprocess.CalledProcessError as e:
            die(f"updatemem failed with code {e.returncode}")
        note(f"Created bit with embedded ELF: {out_bit}")
    else:
        shutil.copy2(bit, out_bit)
        note(f"Copied bit without embedding ELF: {out_bit}")

# ---------------- PS BIF helpers / bootgen ----------------
BIF_FILE_RE = re.compile(r"^\s*file\s*=\s*(.+)$", re.IGNORECASE)

def normalize_bif_paths(text, base_dir):
    out_lines = []
    for line in text.splitlines():
        m = BIF_FILE_RE.match(line.strip())
        if m:
            path = m.group(1).strip().strip('"').strip("'")
            if not is_abs(path):
                path = os.path.normpath(os.path.join(base_dir, path))
            out_lines.append(f"  file = {path}")
        else:
            out_lines.append(line)
    return "\n".join(out_lines) + "\n"

def insert_after_outermost_brace_block(bif_text, insertion):
    idx = bif_text.rfind("}")
    if idx == -1:
        return bif_text + "\n" + insertion + "\n"
    return bif_text[:idx] + insertion + "\n" + bif_text[idx:]

def append_ps_app_partition(bif_text, arch, core_or_cpu, app_elf):
    if arch == "versal":
        block = f"""
 image
 {{
  name = user_app
  id = 0x1c000000
  partition
  {{
   core = {core_or_cpu}
   file = {app_elf}
  }}
 }}"""
        return insert_after_outermost_brace_block(bif_text, block)
    else:
        extra = f"  [destination_cpu={core_or_cpu}] {app_elf}\n"
        return insert_after_outermost_brace_block(bif_text, extra)

def bootgen_arch_token(arch):
    return {"zynq":"zynq", "zynqmp":"zynqmp", "versal":"versal"}[arch]

def run_bootgen(arch, bif_path, out_bin):
    cmd = ["bootgen", "-arch", bootgen_arch_token(arch), "-image", bif_path, "-o", out_bin, "-w", "on"]
    note("Running: " + " ".join(cmd))
    try:
        subprocess.check_call(cmd)
    except FileNotFoundError:
        die("bootgen not found. Source Vitis/Vivado settings64.sh")
    except subprocess.CalledProcessError as e:
        die(f"bootgen failed with code {e.returncode}")

# ---------------- Our OWN BIF generators for PS families ----------------
def zynqmp_bif_text(fsbl_elf, bit_path, app_elf, cpu="a53-0"):
    return f"""//arch = zynqmp; split = false; format = BIN
the_ROM_image:
{{
\t[bootloader, destination_cpu = {cpu}]{fsbl_elf}
\t[destination_device = pl]{bit_path}
\t[destination_cpu = {cpu}, exception_level = el-3]{app_elf}
}}
"""

def zynq_bif_text(fsbl_elf, bit_path, app_elf):
    return f"""//arch = zynq; split = false; format = BIN
the_ROM_image:
{{
\t[bootloader]{fsbl_elf}
\t{bit_path}
\t{app_elf}
}}
"""

def versal_bif_text(pdi_path, app_elf, core="a72-0"):
    # Matches your example with two images (bootimage PDI, then user ELF image)
    return f"""all: {{
image {{
partition {{
type = bootimage
file = {pdi_path}
}}
}}
image {{
name = user_elfs_subsystem
partition {{
core = {core}
file = {app_elf}
}}
}}
}}
"""

def write_text(path, text):
    ensure_dir(os.path.dirname(path))
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)
    return path

# ---------------- main ----------------
def main():
    target, args_json, data_json = parse_cli(sys.argv)
    if target is None:
        target = pick_target_interactively(data_json)
        note(f"Chosen target: {target}")

    with open(args_json, "r", encoding="utf-8") as f:
        cfg = json.load(f)

    bd_name   = cfg.get("bd_name")
    app_name  = cfg.get("app_name", "test_app")
    combine   = bool(cfg.get("combine_bit_elf", True))
    if not bd_name:
        die('args.json must include "bd_name".')

    vivado_postfix = cfg.get("vivado_postfix", "")

    cwd        = os.getcwd()
    workspace  = os.path.join(cwd, f"{target}_workspace")
    viv_proj   = os.path.normpath(os.path.join(cwd, "..", "Vivado", target + vivado_postfix))
    xsa_path   = os.path.normpath(os.path.join(viv_proj, f"{bd_name}_wrapper.xsa"))
    impl_dir   = os.path.join(viv_proj, f"{target}.runs", "impl_1")
    out_dir    = ensure_dir(os.path.join(cwd, "boot", target))
    app_elf    = os.path.join(workspace, app_name, "build", f"{app_name}.elf")

    note("== Bootfile generation ==")
    note(f"target        : {target}")
    note(f"bd_name       : {bd_name}")
    note(f"workspace     : {workspace}")
    note(f"vivado proj   : {viv_proj}")
    note(f"impl dir      : {impl_dir}")
    note(f"xsa           : {xsa_path}")
    note(f"app           : {app_name}")
    note(f"app.elf       : {app_elf}")
    note(f"out dir       : {out_dir}")
    note(f"combine_bit_elf (MB only): {combine}")

    if not os.path.isfile(xsa_path):
        die(f"XSA not found: {xsa_path}")
    if not os.path.isdir(impl_dir):
        die(f"Vivado impl dir not found: {impl_dir}")

    arch, core_hint = detect_arch_and_cpu_from_xsa(xsa_path)
    if not arch:
        die("Could not detect platform family from XSA (MicroBlaze/Zynq/ZynqMP/Versal).")
    note(f"Detected platform: {arch} (core hint: {core_hint})")

    # -------- MicroBlaze
    if arch == "microblaze":
        out_bit = os.path.join(out_dir, f"{bd_name}_boot.bit" if combine else f"{bd_name}.bit")
        make_mb_bit(impl_dir, bd_name, app_elf, core_hint or "microblaze_0", out_bit, combine)
        if not combine:
            if not os.path.isfile(app_elf):
                die(f"ELF not found: {app_elf}")
            out_elf = os.path.join(out_dir, f"{app_name}.elf")
            shutil.copy2(app_elf, out_elf)
            note(f"Copied app ELF: {out_elf}")
        note("\nSUCCESS (MicroBlaze):")
        note(f"  Output bit : {out_bit}")
        return

    # PS devices need app ELF
    if not os.path.isfile(app_elf):
        die("ELF not found at expected Unified path. Expected:\n  " + app_elf + "\nBuild the app first.")

    # -------- ZynqMP: generate own BIF and bootgen
    if arch == "zynqmp":
        plat = f"{target}_platform"
        plat_export = os.path.join(workspace, plat, "export", plat)
        fsbl_elf = os.path.join(plat_export, "sw", "boot", "fsbl.elf")

        app_bit = os.path.join(workspace, app_name, "_ide", "bitstream", f"{bd_name}_wrapper.bit")
        viv_bit = pick_first_existing(
            os.path.join(impl_dir, f"{bd_name}_wrapper.bit"),
            os.path.join(impl_dir, f"{bd_name}.bit"),
        )
        bit_path = app_bit if os.path.isfile(app_bit) else viv_bit

        if not os.path.isfile(fsbl_elf):
            die(f"FSBL not found at: {fsbl_elf}  (Did you build the platform?)")
        if not bit_path:
            die(f"Bitstream not found at:\n  {app_bit}\n  or in {impl_dir}")

        bif_path = os.path.join(out_dir, f"{target}.bif")
        bif_txt  = zynqmp_bif_text(fsbl_elf=fsbl_elf, bit_path=bit_path, app_elf=app_elf, cpu=core_hint or "a53-0")
        write_text(bif_path, bif_txt)

        out_bin = os.path.join(out_dir, "BOOT.BIN")
        run_bootgen("zynqmp", bif_path, out_bin)

        note("\nSUCCESS (ZynqMP):")
        note(f"  BIF      : {bif_path}")
        note(f"  BOOT.BIN : {out_bin}")
        return

    # -------- Zynq (ps7): generate own BIF and bootgen
    if arch == "zynq":
        plat = f"{target}_platform"
        plat_export = os.path.join(workspace, plat, "export", plat)
        fsbl_elf = os.path.join(plat_export, "sw", "boot", "fsbl.elf")

        app_bit = os.path.join(workspace, app_name, "_ide", "bitstream", f"{bd_name}_wrapper.bit")
        viv_bit = pick_first_existing(
            os.path.join(impl_dir, f"{bd_name}_wrapper.bit"),
            os.path.join(impl_dir, f"{bd_name}.bit"),
        )
        bit_path = app_bit if os.path.isfile(app_bit) else viv_bit

        if not os.path.isfile(fsbl_elf):
            die(f"FSBL not found at: {fsbl_elf}  (Did you build the platform?)")
        if not bit_path:
            die(f"Bitstream not found at:\n  {app_bit}\n  or in {impl_dir}")

        bif_path = os.path.join(out_dir, f"{target}.bif")
        bif_txt  = zynq_bif_text(fsbl_elf=fsbl_elf, bit_path=bit_path, app_elf=app_elf)
        write_text(bif_path, bif_txt)

        out_bin = os.path.join(out_dir, "BOOT.BIN")
        run_bootgen("zynq", bif_path, out_bin)

        note("\nSUCCESS (Zynq):")
        note(f"  BIF      : {bif_path}")
        note(f"  BOOT.BIN : {out_bin}")
        return

    # -------- Versal: generate own BIF and bootgen (PDI + user ELF image)
    if arch == "versal":
        # Prefer the PDI generated by the Vitis app build, fallback to Vivado impl PDI
        app_pdi = os.path.join(workspace, app_name, "_ide", "bootimage", "resources", f"{bd_name}_wrapper.pdi")
        viv_pdi = pick_first_existing(
            os.path.join(impl_dir, f"{bd_name}_wrapper.pdi"),
            os.path.join(impl_dir, f"{bd_name}.pdi"),
        )
        pdi_path = app_pdi if os.path.isfile(app_pdi) else viv_pdi
        if not pdi_path:
            die(f"PDI not found at:\n  {app_pdi}\n  or in {impl_dir}")

        core = core_hint or "a72-0"  # default to a72-0 if not detected
        bif_path = os.path.join(out_dir, f"{target}.bif")
        bif_txt  = versal_bif_text(pdi_path=pdi_path, app_elf=app_elf, core=core)
        write_text(bif_path, bif_txt)

        out_bin = os.path.join(out_dir, "BOOT.BIN")
        run_bootgen("versal", bif_path, out_bin)

        note("\nSUCCESS (Versal):")
        note(f"  BIF      : {bif_path}")
        note(f"  BOOT.BIN : {out_bin}")
        return

    # Should not reach here
    die(f"Unhandled architecture: {arch}")

if __name__ == "__main__":
    main()

# Advanced: project structure and customization

This section is intended for users who want to modify the reference
designs — adding IP to the block design, changing constraints, modifying
the standalone application, or adding packages or drivers to the embedded
Linux build (PetaLinux or Yocto). It describes how the repository is laid
out, how the Make-driven build flow works, how the Vitis, PetaLinux, and
Yocto / EDF sides are organised, and what modifications have been added on
top of the stock AMD BSPs.

The actual *build* instructions are in [build_instructions](build_instructions);
this section is about understanding the project well enough to modify
it.

## Repository layout

```
.
├── Makefile                   <- Top-level build entry point
├── README.md
├── config/                    <- Source-of-truth design metadata and auto-generation
│   ├── data.json
│   └── update.py
├── docs/                      <- This documentation (Sphinx + Read the Docs)
├── EmbeddedSw/                <- Vendored AMD BSP libraries used by the Vitis build
├── PetaLinux/
│   ├── Makefile               <- PetaLinux build orchestration
│   └── bsp/                   <- Per-board BSP fragments
│       └── pz/, uzev/, zc706/, zcu104/, vck190/, …
├── Yocto/
│   ├── Makefile               <- Yocto / EDF build orchestration
│   ├── scripts/               <- init-workspace / configure-build / build-image / package-output
│   └── bsp/                   <- Per-board meta-user layers
│       └── pz/, uzev/, zc706/, zcu104/, vck190/, …
├── submodules/                <- Vendor board definition files (BDFs)
├── Vivado/
│   ├── Makefile               <- Vivado build orchestration
│   ├── scripts/
│   │   ├── build.tcl          <- Project creation + block design assembly
│   │   └── xsa.tcl            <- Synthesis, implementation, XSA export
│   └── src/
│       ├── bd/
│       │   ├── bd_mb.tcl      <- Block design for MicroBlaze targets
│       │   ├── bd_zynq.tcl    <- Block design for Zynq-7000 targets
│       │   ├── bd_zynqmp.tcl  <- Block design for Zynq UltraScale+ targets
│       │   ├── bd_versal.tcl  <- Block design for Versal targets
│       │   └── gt_locs.tcl    <- Per-target GT-quad placement constants
│       └── constraints/
│           └── <target>.xdc   <- One XDC per target (pin assignments, timing)
└── Vitis/
    ├── Makefile               <- Vitis workspace + boot-image orchestration
    ├── py/
    │   ├── args.json          <- Repo-specific Vitis flow configuration
    │   ├── build-vitis.py     <- Universal Vitis Python build driver
    │   └── make-boot.py       <- BOOT.BIN / .mcs packaging
    ├── common/
    │   └── src/               <- Standalone application source (PCIe enumerate + VADJ)
    └── <target>_workspace/    <- Per-target Vitis workspace (generated)
```

Per-target build outputs are written to `Vivado/<target>/`,
`Vitis/<target>_workspace/`, `PetaLinux/<target>/`, and `Yocto/<target>/`;
packaged boot-image zips are written to `bootimages/`. None of these are
committed.

There is no port-config overlay in this repository — the FPGA Drive
FMC has a single PCIe / NVMe interface per design, so there is nothing
to factor out into a separate per-port-config fragment.

## Target naming

A `TARGET` is the canonical handle for a single design and is the only
parameter passed through the build flow. It encodes the board and, for
boards with multiple FMC connectors, the connector:

```
<board>[_<connector>]
```

Examples: `uzev`, `vck190_fmcp1`, `zcu106_hpc0`, `kc705_hpc`,
`zc706_lpc`. The first underscore-delimited token is taken as the
*target board* and is what `PetaLinux/Makefile` and `Yocto/Makefile` use
to select the BSP under `PetaLinux/bsp/<board>/` or `Yocto/bsp/<board>/`
respectively. Boards with multiple connectors therefore share a BSP — for
example `zcu106_hpc0` and `zcu106_hpc1` both use `…/bsp/zcu106/`.

The complete list of valid targets is in the `UPDATER START` block of
each Makefile and is generated from `config/data.json` (see below).

## `config/data.json` and `config/update.py`

`config/data.json` is the canonical source of truth for the set of
supported designs and their per-target metadata (board name, processor
family, FMC connector, baremetal-vs-PetaLinux support, etc.).
`config/update.py` reads `data.json` and regenerates the auto-managed
sections of the four Makefiles, the top-level `README.md`, and
`.gitignore` — the sections delimited by `UPDATER START` /
`UPDATER END` comment markers.

When adding or modifying a target, edit `data.json` and re-run
`update.py`. Do not hand-edit content between the `UPDATER START` /
`UPDATER END` markers; it will be overwritten on the next regeneration.

## Make-driven build flow

There are five Makefiles in the repository, each scoped to a stage of
the build:

| Makefile              | Scope                                                                                          |
|-----------------------|------------------------------------------------------------------------------------------------|
| `./Makefile`          | Top-level orchestration; assembles boot-image zips for one or all targets.                     |
| `./Vivado/Makefile`   | Creates the Vivado project, runs synthesis and implementation, exports the XSA.                |
| `./Vitis/Makefile`    | Creates the Vitis workspace and platform from the XSA, builds the standalone application, packages BOOT.BIN/.mcs. |
| `./PetaLinux/Makefile`| Creates the PetaLinux project from the XSA, applies BSP overlays, builds, packages.            |
| `./Yocto/Makefile`    | Creates the Yocto / EDF workspace, generates a custom MACHINE from the XSA (`gen-machineconf parse-sdt`), applies the meta-user BSP, builds with bitbake, packages. |

Each target is flagged in the top-level Makefile as either
`baremetal_only` (Vitis only — all the MicroBlaze targets, since
PetaLinux is not supported on these designs) or `both` (Vitis +
PetaLinux). A `make bootimage TARGET=<t>` invocation at the top level
cascades:

```
make bootimage TARGET=t
  -> Vitis side (always):
       Vitis/Makefile workspace TARGET=t -> bootfile TARGET=t
         -> ensures Vivado XSA exists
              Vivado/Makefile xsa TARGET=t
                -> vivado -mode batch -source scripts/build.tcl   (creates project)
                -> vivado -mode batch -source scripts/xsa.tcl     (synth, impl, XSA export)
         -> vitis -source py/build-vitis.py  ... (creates platform + app, builds)
         -> python3 py/make-boot.py          ... (packages BOOT.BIN / .mcs)
  -> PetaLinux side (if target is "both"):
       PetaLinux/Makefile petalinux TARGET=t
         -> petalinux-create --template <zynq|zynqMP|versal> --name t
         -> petalinux-config --get-hw-description <XSA>
         -> copy bsp/<board>/project-spec/* into the project
         -> petalinux-config --silentconfig
         -> petalinux-build
         -> petalinux-package boot ...
  -> zip the resulting boot files into bootimages/
```

The Yocto / EDF flow is driven independently of the top-level `bootimage`
cascade above, from `Yocto/Makefile`:

```
make -C Yocto yocto TARGET=t
  -> init-workspace.sh   : repo init + repo sync of the AMD yocto-manifests (rel-v2025.2)
  -> ensures the Vivado XSA exists (Vivado/Makefile xsa TARGET=t)
  -> configure-build.sh  : xsct/sdtgen generates a System Device Tree from the XSA,
                           then `gen-machineconf parse-sdt` produces a custom MACHINE
                           (fpgadrv-t) and adds the bsp/<board>/meta-user layer
  -> build-image.sh      : bitbake edf-linux-disk-image
  -> package-output.sh   : gather BOOT.BIN / kernel / boot.scr / system.dtb /
                           rootfs.wic.xz into Yocto/t/images/linux/
```

Per-target lock files (`.<target>.lock` in each Makefile's directory)
prevent two concurrent builds of the same target from clobbering each
other.

## Vivado side

### Block design

The block-design scripts live under `Vivado/src/bd/`, one per
processor family, plus a shared GT-placement helper:

* `bd_mb.tcl`     — MicroBlaze targets.
* `bd_zynq.tcl`   — Zynq-7000 targets.
* `bd_zynqmp.tcl` — Zynq UltraScale+ targets.
* `bd_versal.tcl` — Versal targets.
* `gt_locs.tcl`   — Tcl dictionary mapping each target to its PCIe GT
  coordinates, sourced by the family scripts.

Each script contains per-board conditional blocks where a target needs
to deviate from the family defaults — typically for clock-source
selection, PS configuration, or FMC connector routing.

After sourcing the BD script, `scripts/build.tcl` runs
`validate_bd_design -force`, which triggers parameter propagation and
fills in connection-automation rules. As a result the final
implemented design may contain nets that aren't visible in the BD TCL
source — to see the actual netlist as built, inspect the saved `.bd`
file under `Vivado/<target>/<target>.srcs/sources_1/bd/<bd_name>/` or
use `write_bd_tcl` to export a complete script from an open project.

### Constraints

`Vivado/src/constraints/<target>.xdc` contains pin assignments and any
target-specific timing constraints. Constraints common to all targets
of a given family are not factored out — each target's XDC is
self-contained.

### Build scripts

* `Vivado/scripts/build.tcl` creates the Vivado project, adds the
  target's XDC, sources the appropriate `bd_*.tcl`, and validates the
  block design. Invoked via `make project TARGET=<t>`.
* `Vivado/scripts/xsa.tcl` opens the existing project, runs synthesis
  and implementation, exports the XSA, and writes the bitstream into
  the implementation run directory. Invoked via `make xsa TARGET=<t>`.

Both scripts check `XILINX_VIVADO` to confirm the installed Vivado
version matches the `version_required` constant at the top of the
file. Bumping the project to a new Vivado release means changing those
constants and re-testing — the BD TCL APIs are not stable across major
releases.

### Modifying the block design

Edit the block-design script for the appropriate processor family
directly. If the change applies only to some targets in the family,
wrap the additions in the appropriate per-board conditional block.

Once the script is edited, delete any existing per-target Vivado
project directory (`rm -rf Vivado/<target>`) and re-run the Vivado
build through the Makefile:

```
make -C Vivado xsa TARGET=<target>
```

This re-creates the project, sources the modified BD script, runs
`validate_bd_design`, synthesises, implements, and re-exports the XSA.
Downstream Vitis / PetaLinux / boot-image steps will pick up the new
XSA on the next `make` at the top level.

### Adding or modifying constraints

Edit `Vivado/src/constraints/<target>.xdc` directly. If a constraint
applies to all targets in a family, it still needs to be replicated to
each target's XDC — there is no shared XDC.

## Vitis side

The standalone (baremetal) build runs an NVMe / PCIe enumeration test
on the target. The application source is shared but the *exact* set
of source files used depends on which PCIe bridge IP the target's BD
contains — Zynq-7000 and the older MicroBlaze targets use the
`axipcie` IP and its `xaxipcie_rc_enumerate_example.c`, while ZynqMP,
Versal, and a few specific MicroBlaze targets use the `xdmapcie` IP
and its `xdmapcie_rc_enumerate_example.c`.

### Layout

```
Vitis/
├── Makefile
├── py/
│   ├── args.json
│   ├── build-vitis.py        <- Universal Vitis Python build driver
│   └── make-boot.py          <- BOOT.BIN / .mcs packaging
├── common/
│   └── src/                  <- Application source (PCIe enumerate + VADJ)
├── boot/<target>/            <- Per-target packaged boot files
└── <target>_workspace/       <- Generated Vitis workspace per target
```

### `args.json`

`Vitis/py/args.json` is the repo-specific configuration that drives
the universal `build-vitis.py` driver. The key fields are:

* `bd_name` — block-design name (`fpgadrv`).
* `app_name` — name of the Vitis application (`ssd_test`).
* `app_template` — set to `"None"`, meaning the build driver creates
  the application as an empty project and adds source files
  explicitly rather than scaffolding from a Vitis template.
* `src` — per-processor-family source file list:

  ```
  "src": {
      "mb":     {"dir": "common/src", "files": ["xaxipcie_rc_enumerate_example.c"]},
      "zynq":   {"dir": "common/src", "files": ["xaxipcie_rc_enumerate_example.c"]},
      "zynqmp": {"dir": "common/src", "files": ["xdmapcie_rc_enumerate_example.c"]},
      "versal": {"dir": "common/src", "files": ["xdmapcie_rc_enumerate_example.c", "vadj.c", "vadj.h"]}
  }
  ```

  Versal targets additionally pull in `vadj.c` / `vadj.h` for VADJ
  programming.

* `src_overrides` — per-target overrides of the family default. The
  two MicroBlaze targets that have an `xdmapcie` IP rather than an
  `axipcie` IP are listed here:

  ```
  "src_overrides": {
      "auboard": {"dir": "common/src", "files": ["xdmapcie_rc_enumerate_example.c"]},
      "vcu118":  {"dir": "common/src", "files": ["xdmapcie_rc_enumerate_example.c"]}
  }
  ```

* `linker_script_mods` — `"microblaze": "relocate_to_local_mem"`
  relocates the linker sections to MicroBlaze local memory so the
  baremetal app fits without external memory.
* `combine_bit_elf` — `true`, so the build driver combines the bitstream
  and the ELF into a single download image (`<bd_name>_boot.bit`) for
  the MicroBlaze targets.

### Modifying the standalone application

Edit `Vitis/common/src/*.c` directly. The next `make -C Vitis bootfile
TARGET=<t>` rebuilds the application against the existing platform; if
you've changed the hardware (XSA) you'll need a fresh workspace
(`make -C Vitis clean TARGET=<t>` first).

If a new target uses a different PCIe IP than the family default, add
an entry to `src_overrides` in `args.json` rather than branching the
source.

## PetaLinux side

### BSP composition

The PetaLinux project for a given target is composed at build time
from a single BSP fragment copied into the target's project directory:
the **board BSP** at `PetaLinux/bsp/<board>/` (for example `uzev/`,
`zc706/`, `zcu104/`, `vck190/`). It provides board-specific kernel
and U-Boot configuration, the system device-tree fragment, and any
board-specific patches.

The mapping from target to board BSP is by first-token match: a target
`zcu106_hpc0` uses `PetaLinux/bsp/zcu106/`, a target `zc706_lpc` uses
`PetaLinux/bsp/zc706/`, and so on. The valid (target, board, template)
tuples are listed in `PetaLinux/Makefile`'s `UPDATER` block.

There is no port-config overlay in this repository.

### Layout of a board BSP

```
PetaLinux/bsp/<board>/project-spec/
├── configs/
│   ├── config                <- petalinux-config: bootargs, rootfs, hostname
│   ├── rootfs_config         <- petalinux-config -c rootfs: included packages
│   ├── init-ifupdown/
│   │   └── interfaces        <- /etc/network/interfaces
│   └── busybox/
│       └── inetd.conf
└── meta-user/
    ├── conf/
    │   ├── user-rootfsconfig <- declares additional rootfs config options
    │   ├── petalinuxbsp.conf
    │   └── layer.conf
    ├── recipes-bsp/
    │   ├── device-tree/
    │   │   ├── device-tree.bbappend
    │   │   └── files/
    │   │       └── system-user.dtsi    <- board-specific Linux DT additions
    │   ├── u-boot/
    │   │   ├── u-boot-xlnx_%.bbappend
    │   │   └── files/
    │   │       ├── bsp.cfg             <- U-Boot Kconfig additions
    │   │       ├── platform-top.h
    │   │       └── *.patch             <- U-Boot source patches
    │   └── embeddedsw/                 <- (zcu104 only)
    │       ├── fsbl-firmware_%.bbappend
    │       └── files/
    │           └── zcu104_vadj_fsbl.patch
    ├── meta-xilinx-tools/
    │   └── recipes-bsp/
    │       └── uboot-device-tree/
    │           ├── uboot-device-tree.bbappend
    │           └── files/
    │               └── system-user.dtsi    <- U-Boot DT overlay
    └── recipes-kernel/
        └── linux/
            ├── linux-xlnx_%.bbappend
            └── linux-xlnx/
                └── bsp.cfg             <- kernel Kconfig additions
```

### Adding a package to the root filesystem

1. Append the new option to `bsp/<board>/project-spec/configs/rootfs_config`:

   ```
   CONFIG_<package>=y
   ```

2. If the package is not in the default `petalinux-config -c rootfs`
   menu, also append a declaration line to
   `bsp/<board>/project-spec/meta-user/conf/user-rootfsconfig`.

3. If the package is not provided by an existing meta-layer, add a
   recipe under
   `bsp/<board>/project-spec/meta-user/recipes-apps/<package>/<package>.bb`.

### Adding a kernel config option

Append the option to
`bsp/<board>/project-spec/meta-user/recipes-kernel/linux/linux-xlnx/bsp.cfg`:

```
CONFIG_<name>=y
```

The corresponding bbappend at `recipes-kernel/linux/linux-xlnx_%.bbappend`
registers `bsp.cfg` as a kernel configuration fragment.

### Adding a device-tree fragment

Edit
`bsp/<board>/project-spec/meta-user/recipes-bsp/device-tree/files/system-user.dtsi`.
If you add new files, ensure they are listed in `SRC_URI:append` in
`device-tree.bbappend`.

### Adding a kernel patch or out-of-tree driver

1. Drop the patch file into
   `bsp/<board>/project-spec/meta-user/recipes-kernel/linux/linux-xlnx/`.
2. Add a line to `recipes-kernel/linux/linux-xlnx_%.bbappend`:

   ```
   SRC_URI:append = " file://<your-patch>.patch"
   ```

### Modifying U-Boot

The same pattern as the kernel, under
`bsp/<board>/project-spec/meta-user/recipes-bsp/u-boot/`. `bsp.cfg`
adds U-Boot Kconfig options; `platform-top.h` overrides the U-Boot
platform header; patches are listed in `SRC_URI:append` in
`u-boot-xlnx_%.bbappend`.

## Yocto side

The Yocto / EDF flow builds an embedded Linux image with AMD's Embedded
Development Framework — the announced successor to PetaLinux — using the
`gen-machineconf parse-sdt` flow. It is orchestrated by `Yocto/Makefile`
and four scripts under `Yocto/scripts/`:

| Script               | Role (rough PetaLinux analogue)                                          |
|----------------------|--------------------------------------------------------------------------|
| `init-workspace.sh`  | `repo init` + `repo sync` of the AMD yocto-manifests (≈ `petalinux-create`) |
| `configure-build.sh` | XSA → System Device Tree (sdtgen) → custom MACHINE via `gen-machineconf parse-sdt` (≈ importing the XSA + `petalinux-config`) |
| `build-image.sh`     | `bitbake edf-linux-disk-image` (≈ `petalinux-build`)                     |
| `package-output.sh`  | gather the flashable artifacts into `images/linux/` (≈ `petalinux-package`) |

The step-by-step build instructions are in
[build_instructions](build_instructions.md#build-yocto-project-in-linux)
and in `Yocto/README.md`; this section covers how the per-board
customization is organised.

Because the MACHINE is generated from the hardware (`parse-sdt` runs
lopper on the SDT, which carries both the PS config and the PL — the PCIe
Root Port IP — straight from the XSA), there is no hand-maintained machine
config and no pinned MACHINE. A PS change in Vivado flows through
XSA → SDT → machine.conf → device tree automatically.

### BSP composition

`configure-build.sh` adds the board's meta-user layer at
`Yocto/bsp/<board>/meta-user/` to `bblayers.conf`, so its bbappends and
recipes are applied on top of the generated MACHINE. The board is selected
by first-token match (the same rule as the PetaLinux side), so boards on
the same chip share a BSP (`vck190_fmcp1`/`vck190_fmcp2` → `bsp/vck190`,
`pz_7015`/`pz_7030` → `bsp/pz`); each target still gets its own
MACHINE / SDT / device tree from its own XSA.

### Layout of a Yocto board BSP

```
Yocto/bsp/<board>/
├── conf/
│   └── local.conf.append                     <- bootargs (APPEND), hostname, image tweaks
└── meta-user/
    ├── conf/
    │   ├── layer.conf
    │   └── petalinuxbsp.conf
    ├── recipes-bsp/
    │   ├── device-tree/
    │   │   ├── device-tree.bbappend          <- injects system-user.dtsi (Linux domain only)
    │   │   └── files/system-user.dtsi        <- board-specific Linux DT fixups
    │   └── u-boot/                            <- (Versal only) custom boot.scr + bootcmd override
    │       ├── u-boot-edf-scr_%.bbappend  +  files/fpgadrv-boot.cmd
    │       └── u-boot-xlnx_%.bbappend     +  files/fpgadrv-bootcmd.cfg
    ├── recipes-core/images/
    │   └── edf-linux-disk-image.bbappend      <- extra rootfs packages (IMAGE_INSTALL:append)
    └── recipes-kernel/linux/
        ├── linux-xlnx_%.bbappend
        └── linux-xlnx/bsp.cfg                 <- kernel Kconfig additions
```

### Adding a package to the root filesystem

Append to `IMAGE_INSTALL:append` in
`bsp/<board>/meta-user/recipes-core/images/edf-linux-disk-image.bbappend`:

```
IMAGE_INSTALL:append = " <package>"
```

### Adding a kernel config option

Append the option to
`bsp/<board>/meta-user/recipes-kernel/linux/linux-xlnx/bsp.cfg`; the
adjacent `linux-xlnx_%.bbappend` registers it as a kernel config fragment.

### Adding a device-tree fragment

Edit
`bsp/<board>/meta-user/recipes-bsp/device-tree/files/system-user.dtsi`.
It is `#include`d onto the generated Linux device tree via
`EXTRA_DT_INCLUDE_FILES`, **guarded to the Linux domain only** — applying
it to the FSBL/PMU/PLM domain device trees makes `dtc` fail because those
domains do not define the SoC peripheral labels the overrides reference.

### What the Yocto BSPs change

The Yocto equivalent of the PetaLinux *"what would I lose"* list below.
On top of the stock EDF flow, the Yocto BSPs layer:

* **All boards:** hostname (`local.conf.append`), the reference-design
  rootfs packages (`edf-linux-disk-image.bbappend`), and the kernel
  PCIe/NVMe configs (`bsp.cfg`).
* **Zynq-7000 (pz, zc706):** `system-user.dtsi` restores the root
  `compatible = "xlnx,zynq-7000"` (the parse-sdt board merge drops it,
  which otherwise boots a generic machine and panics in the clock driver),
  sets `/chosen/bootargs` (console + earlycon — the zynq DT carries no
  default bootargs), and disables PS `gem0`. `bsp.cfg` adds
  `CONFIG_PCIE_XILINX` + NVMe and the `CONFIG_VMSPLIT_2G` /
  `CONFIG_PAGE_OFFSET=0x80000000` relayout needed to `ioremap` the 256 MB
  AXI-PCIe config window.
* **Zynq UltraScale+:** `bsp.cfg` adds `CONFIG_PCIE_XDMA_PL` + NVMe;
  `system-user.dtsi` pins the UART `port-number`/serial aliases (so the
  console is deterministic) and, on `zcu104`/`uzev`, caps the SD controller
  at high-speed (the level shifter cannot sustain UHS).
* **Versal:** `system-user.dtsi` overrides the QDMA PCIe `ranges` to a 1:1
  identity map (the SDT sets the PCI base to 0x0, which faults NVMe BAR
  access). The U-Boot bbappends add a custom `boot.scr` (`fpgadrv-boot.cmd`
  — with the IR38164 VADJ-enable sequence on VCK190/VMK180/VPK120/VPK180
  and `earlycon=pl011,mmio32`) and override `CONFIG_BOOTCOMMAND`; the image
  bbappend places `BOOT.BIN` and `boot.scr` onto the FAT esp via
  `IMAGE_EFI_BOOT_FILES` so the card boots hands-free.

See the `Yocto/bsp/<board>/` sources and their in-file comments for the
exact values and the rationale behind each fixup.

## Modifications layered on the stock BSPs

This section describes the **PetaLinux** BSPs; the equivalent Yocto BSP
changes are summarised under [Yocto side](#yocto-side) above.

The board BSPs in this repository started as the corresponding stock
AMD reference BSPs and have been modified in the following ways. This
list is the answer to *"what would I lose if I overwrote the BSP with
the stock one?"* — it is what to re-apply if you ever do that.

### All BSPs

* **Hostname / product name** set in `configs/config` via
  `CONFIG_SUBSYSTEM_HOSTNAME` and `CONFIG_SUBSYSTEM_PRODUCT`.
* **Root filesystem additions** in `configs/rootfs_config`:
  `e2fsprogs` (mke2fs, badblocks), `mtd-utils`, `util-linux` (mount,
  mkfs, blkid, fdisk), `pciutils`, `bridge-utils`, `nvme-cli`,
  `coreutils` (for the full `dd` rather than the BusyBox stub).
  Some default packages (`canutils`, `openssh-sftp-server`,
  `packagegroup-core-ssh-dropbear`) are explicitly disabled to keep
  the image small.

### Zynq-7000 BSPs (pz, zc706)

* **SD-card root filesystem** configured in `configs/config`:
  `CONFIG_SUBSYSTEM_ROOTFS_EXT4`, `CONFIG_SUBSYSTEM_SDROOT_DEV`,
  `CONFIG_SUBSYSTEM_USER_CMDLINE` (with `cma=1536M` for the AXI DMA
  buffers).
* **Kernel configs** in `linux-xlnx/bsp.cfg`:
  * NVMe: `CONFIG_NVME_CORE`, `CONFIG_BLK_DEV_NVME`.
  * Address-space relayout to free VMALLOC space for the PCIe CTL
    interface: `CONFIG_ARCH_MMAP_RND_BITS_MAX=15`,
    `CONFIG_VMSPLIT_2G=y`, `CONFIG_PAGE_OFFSET=0x80000000`. Without
    these the kernel runs out of VMALLOC for the `axi_pcie` BAR
    mappings.

### ZynqMP and Versal BSPs

* **SD-card root filesystem** configured in `configs/config` (as
  above, ZynqMP only — Versal targets use the same template default).
* **Kernel configs** in `linux-xlnx/bsp.cfg`:
  `CONFIG_PCI_REALLOC_ENABLE_AUTO`, `CONFIG_PCIE_XDMA_PL`,
  `CONFIG_NVME_CORE`, `CONFIG_BLK_DEV_NVME`, `CONFIG_NVME_TARGET`.
* **U-Boot patch `0001-ubifs-distroboot-support.patch`** on ZynqMP
  boards, `0001-xilinx_versal.h-ubifs-distroboot-support.patch` on
  Versal boards.
* **`meta-xilinx-tools/recipes-bsp/uboot-device-tree/` overlay** in
  every BSP (Zynq-7000, ZynqMP, and Versal), each providing its own
  `system-user.dtsi`. It overrides the U-Boot device tree (required
  because the stock U-Boot device tree does not describe the FMC-side
  PCIe bridge).

### PicoZed FMC Carrier (pz) BSP

* **`CONFIG_SUBSYSTEM_SDROOT_DEV="/dev/mmcblk1p2"`** in
  `configs/config` and matching `CONFIG_SUBSYSTEM_USER_CMDLINE` —
  the PicoZed carrier wires the SD card through `mmcblk1`.
* **Custom U-Boot `bsp.cfg`** with EEPROM / I²C configuration so
  U-Boot can read the per-board MAC address from the carrier's
  on-board EEPROM (`CONFIG_CMD_EEPROM`, `CONFIG_I2C_EEPROM`,
  `CONFIG_ZYNQ_MAC_IN_EEPROM`, `CONFIG_ZYNQ_GEM_I2C_MAC_OFFSET=0xFA`).
* **Custom `system-user.dtsi`** and **kernel configs** for the
  USB ACM / I²C / USB serial peripherals exposed by the PicoZed
  carrier (`CONFIG_USB_ACM`, `CONFIG_USB_F_ACM`,
  `CONFIG_USB_U_SERIAL`, `CONFIG_USB_CDC_COMPOSITE`,
  `CONFIG_I2C_XILINX`).

### UltraZed-EV (uzev) BSP

* **`CONFIG_YOCTO_MACHINE_NAME="zynqmp-generic"`** in `configs/config`
  (the UZ-EV is not a stock Xilinx eval board).
* **SD-card device set to `/dev/mmcblk1p2`** rather than the ZynqMP
  default `mmcblk0p2`.
* **`PRIMARY_SD_PSU_SD_1_SELECT=y`** to route the boot SD interface
  through PSU SD1 instead of SD0.
* **Custom `system-user.dtsi`** with UZ-EV-specific peripheral
  configuration.
* **`recipes-core/sysvinit/sysvinit-inittab_%.bbappend`** sets
  `USE_VT = "0"` to suppress the BusyBox "respawning too fast"
  message on `tty1`.
* **`IMAGE_BOOT_FILES:zynqmp = "BOOT.BIN boot.scr Image system.dtb"`**
  in `petalinuxbsp.conf` so the image's boot partition contains the
  files the UZ-EV's U-Boot expects.

### ZCU104 BSP

* **FSBL patch `zcu104_vadj_fsbl.patch`** in
  `recipes-bsp/embeddedsw/files/`, registered via
  `fsbl-firmware_%.bbappend`. The ZCU104 FSBL is patched to program the
  on-board IRPS5401 PMBus regulator to 1.8V before the FMC PHYs
  come out of reset.
* Standard ZynqMP SD-root + PCIe / NVMe configs and U-Boot ubifs
  patch.

### ZCU106 BSP

* **`CONFIG_SUBSYSTEM_REMOVE_PL_DTB=n`** to preserve the PL device-tree
  nodes (the stock ZCU106 BSP removes them, but the FPGA Drive design
  needs them).
* **`CONFIG_SUBSYSTEM_FPGA_MANAGER=n`** to disable the FPGA manager
  (the bitstream is loaded via the standard boot flow rather than at
  runtime).

## Where build outputs land

| Path                                | Contents                                                                       |
|-------------------------------------|--------------------------------------------------------------------------------|
| `Vivado/<target>/`                  | Vivado project. `<bd_name>_wrapper.xsa` is the export.                          |
| `Vivado/<target>/<target>.runs/impl_1/<bd_name>_wrapper.bit` | Bitstream.                                              |
| `Vivado/logs/`                      | Per-target Vivado build logs (xpr + xsa).                                       |
| `Vitis/<target>_workspace/`         | Per-target Vitis workspace (platform + application + BSP).                      |
| `Vitis/boot/<target>/`              | Packaged Vitis boot files (`BOOT.BIN` for Zynq/ZynqMP/Versal, `.bit` with combined ELF for MicroBlaze). |
| `PetaLinux/<target>/`               | PetaLinux project. All its bitbake build state lives here.                      |
| `PetaLinux/<target>/images/linux/`  | `BOOT.BIN`, `image.ub`, `boot.scr`, `rootfs.tar.gz`, etc.                       |
| `PetaLinux/<target>/build/build.log`| PetaLinux build log.                                                            |
| `Yocto/<target>/`                   | Yocto / EDF workspace (`.repo`, `sources`, `build`, `images`).                  |
| `Yocto/<target>/images/linux/`      | `BOOT.BIN`, kernel (`Image` or `uImage`), `boot.scr`, `system.dtb`, `rootfs.wic.xz`, `rootfs.tar.gz`. |
| `Yocto/<target>/build/`             | bitbake build directory (`tmp/`, `sstate-cache/`, `downloads/`).                |
| `bootimages/`                       | Per-target zipped boot files (`<prj>_<target>_petalinux-<ver>.zip` and `<prj>_<target>_standalone-<ver>.zip`). |

None of these directories are committed to the repository.

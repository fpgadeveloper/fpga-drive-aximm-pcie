# Yocto / EDF builds

This folder builds Linux images for the FPGA Drive FMC reference designs
using the AMD Yocto / Embedded Development Framework (EDF) flow — the
announced successor to PetaLinux Tools.

> **Status**: `zcu106_hpc0` is the only target validated end-to-end on
> hardware (Linux boots, FPGA bitstream loads in BOOT.BIN, both
> xilinx_pcie_dma Root Ports come up, M.2 NVMe SSDs enumerate). Other
> targets — including `zcu106_hpc1` — still go through `PetaLinux/`
> until they're ported and tested here too.

## Prerequisites

Host packages on Ubuntu 22.04 / 24.04:

```
sudo apt-get install repo gawk wget git diffstat unzip texinfo gcc \
    build-essential chrpath socat cpio python3 python3-pip python3-pexpect \
    xz-utils debianutils iputils-ping python3-git python3-jinja2 \
    python3-subunit zstd liblz4-tool file locales libacl1 bmap-tools
```

Plus Vivado 2025.2 (already a project-wide dependency — used to produce
the XSA that this flow consumes). **Vitis 2025.2 must also be sourced**
in the shell that runs `make` because `xsct` (needed by some build
steps) ships with Vitis, not Vivado, in 2025.2:

```
source <xilinx-install>/2025.2/Vitis/settings64.sh
```

`configure-build.sh` falls back to a few default install paths
(`/tools/Xilinx`, `/opt/Xilinx`, `~/Xilinx`) if `xsct` is not on `PATH`.

## Build

```
cd Yocto
make yocto TARGET=zcu106_hpc0
```

The first build for a target:

1. Builds the Vivado project and exports the XSA (via `../Vivado/Makefile`)
   if one isn't already present.
2. Initializes a manifest workspace under `Yocto/<TARGET>/` with
   `repo init -u https://github.com/Xilinx/yocto-manifests.git -b rel-v2025.2 -m default-edf.xml`
   and `repo sync` (≈5 GB of git history).
3. Sources `edf-init-build-env` to set up the bitbake environment.
4. Layers `bsp/zcu106/conf/local.conf.append` (sets
   `MACHINE = "zynqmp-zcu106-sdt-full"`, `BIF_BITSTREAM_ATTR`, and
   `BITSTREAM_PATH` pointing at the Vivado-built `fpgadrv_wrapper.bit`)
   plus `bsp/zcu106/meta-user/` (kernel config, DT overlay, image
   bbappend) over the EDF default config.
5. Runs `bitbake edf-linux-disk-image`.
6. Gathers `BOOT.BIN` (with the PL bitstream embedded), `Image`,
   `system.dtb`, `boot.scr`, `u-boot.elf`, `rootfs.tar.gz`,
   `rootfs.wic.xz`, and `rootfs.wic.bmap` into
   `Yocto/<TARGET>/images/linux/`.

Subsequent builds skip the `repo sync` step. To force a re-config
(e.g. after editing `bsp/<board>/conf/local.conf.append`), remove
`Yocto/<TARGET>/configdone.txt`.

## Flashing to SD card

The build produces a full wic disk image (`rootfs.wic.xz`) with a
4-partition layout — `esp` (vfat, 512 MB), `boot` (ext4, 512 MB),
`root` (ext4, 6 GB), and `storage` (vfat, 1 GB). Flash the wic image
to the SD card's raw device; per-partition file copies do **not** work
because the EDF-generated `boot.scr` hard-codes partition numbers
(kernel on p2, rootfs on p3).

One extra step is needed after the flash: the EDF wks file for ZynqMP
leaves the `esp` partition empty (it was designed for Versal +
systemd-boot), but the ZynqMP BootROM reads `BOOT.BIN` from the first
FAT partition. So we flash the wic image, then drop `BOOT.BIN` onto
`esp` by hand.

### 1. Identify the SD card device — carefully

This is the step that will eat one of your hard drives if you get it
wrong. `dd`-style writes to a block device cannot be undone.

With the SD card **un**plugged, list the block devices on your machine
and note what's there:

```
lsblk -o NAME,SIZE,RM,TYPE,MOUNTPOINT
```

Now insert the SD card and re-run the same command. The new entry
(typically `/dev/sdX`, with `RM=1` for removable, and a size that
matches your card — 8–256 GB) is your target. Confirm with:

```
udevadm info --query=property --name=/dev/sdX | grep -E "ID_BUS|ID_MODEL"
```

`ID_BUS=usb` and a model like `SDXC/MMC` or your card-reader's name
is what you want to see. **Do not proceed until you are certain
`/dev/sdX` is your SD card and not an internal disk.**

Throughout the rest of this section, replace `sdX` with the actual
device letter.

### 2. Unmount any auto-mounted partitions

Most desktops auto-mount removable media. Before writing to the raw
device, unmount any partitions of the SD card:

```
for p in /dev/sdX?*; do sudo umount "$p" 2>/dev/null; done
```

### 3. Flash the wic image to the raw device

Preferred: `bmaptool` only writes the blocks that are actually used
(typically ~600 MB rather than the full 8 GB), so it finishes in a
minute or two on a fast card:

```
sudo bmaptool copy \
    --bmap Yocto/zcu106_hpc0/images/linux/rootfs.wic.bmap \
          Yocto/zcu106_hpc0/images/linux/rootfs.wic.xz \
          /dev/sdX
```

Fallback (slower, writes every block including unused ones):

```
xzcat Yocto/zcu106_hpc0/images/linux/rootfs.wic.xz \
    | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync
```

### 4. Install BOOT.BIN on the esp partition

After flashing, re-read the partition table and let the system
auto-mount the new partitions:

```
sudo partprobe /dev/sdX
```

Most desktops will now expose `/media/<you>/esp`, `/media/<you>/boot`,
`/media/<you>/root`, and `/media/<you>/storage`. Copy `BOOT.BIN` onto
`esp`:

```
cp Yocto/zcu106_hpc0/images/linux/BOOT.BIN /media/<you>/esp/BOOT.BIN
sync
```

If your desktop didn't auto-mount, mount `esp` manually:

```
sudo mkdir -p /mnt/sd_esp
sudo mount /dev/sdX1 /mnt/sd_esp
sudo cp Yocto/zcu106_hpc0/images/linux/BOOT.BIN /mnt/sd_esp/BOOT.BIN
sync
sudo umount /mnt/sd_esp
sudo rmdir /mnt/sd_esp
```

### 5. Eject and boot

Eject the card cleanly (the file manager's eject button, or
`sudo eject /dev/sdX`) so any pending writes flush. Insert it into the
ZCU106, ensure boot mode switches are set to SD, power-cycle, and
attach a UART terminal at 115200 8N1.

## Offline / faster builds

Place the absolute path to a directory containing an extracted AMD
sstate-cache mirror in `Yocto/offline.txt` — `configure-build.sh` will
wire it into `SSTATE_MIRRORS` and `SOURCE_MIRROR_URL`.

Expected layout under that path:

```
<sstate root>/
  aarch64/           (matches SSTATE_ARCH for the target)
  downloads/         (optional — the source-mirror tarballs)
```

The sstate-cache and downloads archives are available behind login at:
<https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/embedded-design-tools.html>
under "sstate-cache & Downloads - 2025.2". Only the architecture
matching your target is needed (e.g. `aarch64` for ZCU106).

A warm sstate-cache typically gives ~80% hit on the first build (~30 min
on a 16-core machine) versus several hours cold.

## Device-tree extraction (one-time per design)

`bsp/zcu106/meta-user/recipes-bsp/device-tree/files/system-user.dtsi`
contains hand-curated PL device-tree nodes (the two `xilinx_pcie_dma`
Root Ports for FPGA Drive). Those nodes were generated by `xsct` against
the project's XSA using `device-tree-xlnx`; the generator command is
documented in the header comment of `system-user.dtsi` itself, so when
the Vivado block design changes you can regenerate and update that one
file.

## Layout

```
Yocto/
  Makefile                  driver, mirrors PetaLinux/Makefile conventions
  README.md                 this file
  .gitignore                excludes per-target workspaces + local state
  offline.txt               (optional, gitignored) path to an extracted sstate mirror
  scripts/
    init-workspace.sh       repo init + sync
    configure-build.sh      source edf-init-build-env + apply BSP + wire bitstream
    build-image.sh          bitbake the image recipe
    package-output.sh       gather deploy artifacts into images/linux/
  bsp/
    zcu106/                 shared between zcu106_hpc0 and zcu106_hpc1
      conf/
        local.conf.append   board-level overrides (MACHINE, bitstream wiring, ...)
      meta-user/            standard Yocto layer (bbappends, DT, kernel cfg)
  <TARGET>/                 (gitignored) per-target workspace built by make
  tools/                    (gitignored) helper checkouts, e.g. device-tree-xlnx
  logs/                     (gitignored) build logs
```

## Architectural notes

* **`MACHINE = "zynqmp-zcu106-sdt-full"`** (an AMD-validated machine
  from `meta-amd-adaptive-socs-bsp`) is used rather than a custom
  machine generated by `gen-machineconf parse-xsa`. The 2025.2 EDF
  `parse-xsa` flow produces a thin `machine.conf` without the SDT
  files the `device-tree` recipe needs, leaving `virtual/dtb`
  unbuildable. Using the validated MACHINE keeps the SoC-side DT
  intact and our project-specific PL nodes are layered on via
  `system-user.dtsi`.

* **Bitstream lives in BOOT.BIN**, not loaded at runtime via FPGA
  manager. `BIF_BITSTREAM_ATTR = "bitstream"` + `BITSTREAM_PATH` pull
  in `meta-xilinx-core`'s `bitstream_1.0.bb` recipe, which deposits
  the `.bit` where `xilinx-bootbin` picks it up. FSBL programs the PL
  during boot so PCIe is live before Linux starts.

* **There's a bitbake WARNING** at do_rootfs time saying
  `edf-linux-disk-image` isn't "officially supported" on
  `zynqmp-zcu106-sdt-full` — AMD's intended EDF flow is to build the
  rootfs image with a CPU-tune MACHINE (e.g. `amd-cortexa53-mali-common`)
  and BOOT.BIN with the board MACHINE, then combine. We use a single
  MACHINE for simplicity; the resulting image works in practice but
  the warning is real and may bite us with a less stock board config.

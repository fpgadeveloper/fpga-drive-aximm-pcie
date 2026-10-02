# Yocto

The Yocto / EDF flow (AMD's Embedded Development Framework) is the announced successor to
PetaLinux. It can be built for these reference designs with the cross-platform `build.py`
runner at the root of the repository.

```{note}
For 2025.2 both the PetaLinux and Yocto flows are supported and produce an equivalent
image. From the next tool version onward, the PetaLinux flow for this repository will be retired
and Yocto will be the only supported flow — see [build instructions](build_instructions).
```

## Requirements

To build the Yocto projects you will need a physical or virtual machine running one of the
[supported Linux distributions], with Vivado and Vitis 2025.2 installed — the flow uses
`xsct`/`sdtgen` (which ship with Vitis) to generate a System Device Tree from the Vivado XSA. You
also need [Google's repo tool](https://gerrit.googlesource.com/git-repo/) on your `PATH`.

Plan for the disk space and time of a full Yocto build: the first build of a target
downloads several GB of sources and runs bitbake from scratch, and a Yocto workspace
typically occupies several tens of GB.

```{attention}
You cannot build the Yocto projects in the Windows operating system. Windows users
are advised to use a Linux virtual machine to build the Yocto projects.
```

To test the image you need:

* the target board, with its USB-UART cable and a micro-SD card (8 GB or larger),
* the [FPGA Drive FMC Gen4] or [M.2 M-key Stack FMC] and one or two M.2 NVMe SSDs,
* optionally, an Ethernet cable from the board's RJ45 port to your network (DHCP).

## How to build

The build runner locates and sources the Vivado and Vitis settings itself, so there is no
need to source them by hand.

1. From a command terminal, clone the Git repository (with its submodules) and `cd` into it:
   ```
   git clone --recurse-submodules https://github.com/fpgadeveloper/fpga-drive-aximm-pcie.git
   cd fpga-drive-aximm-pcie
   ```
2. Build the Yocto image for your target by running the following command, replacing
   `<target>` with one of the target design labels listed in the
   [build instructions](build_instructions.md#build-yocto):
   ```
   ./build.sh yocto --target <target>
   ```

This command launches the corresponding Vivado build if that project has not already been
built and its hardware exported. Subsequent builds are incremental. See
[build instructions](build_instructions.md#yocto-offline-build) to build against a local
sstate-cache mirror. The output products are gathered into `Yocto/<target>/images/linux/`:

| File | Description |
| --- | --- |
| `rootfs.wic.xz` + `rootfs.wic.bmap` | Full SD-card disk image — this is what you flash |
| `BOOT.BIN` | Boot image (FSBL/PLM + bitstream/PDI + U-Boot) |
| `boot.scr` | U-Boot boot script |
| `Image` / `uImage` | Linux kernel (`uImage` on Zynq-7000, `Image` on Zynq UltraScale+ and Versal) |
| `system.dtb` | Linux device tree |
| `rootfs.tar.gz` | Root filesystem tarball |

`./build.sh all --target <target>` (or `./build.sh package --target <target>`) also packs
the flashable files into `bootimages/fpga-drive-aximm-pcie_<target>_yocto-2025-2.zip`,
together with a `readme.txt` describing the SD-card steps below.

## Boot from SD card

Unlike the PetaLinux flow (which produces separate boot files for a hand-partitioned card), the
Yocto flow produces a **full SD-card disk image** (`rootfs.wic.xz`) that already contains all
partitions:

| Partition | Type | Contents |
|-----------|------|----------|
| p1 `esp` | FAT32 | Zynq-7000 / Zynq UltraScale+: empty — `BOOT.BIN` must be copied here (step 4 below). Versal: `BOOT.BIN`, `boot.scr` and the kernel `Image`. |
| p2 | ext4 / FAT32 | Zynq-7000 / Zynq UltraScale+: ext4 `boot` partition with `boot.scr`, kernel and device tree, read by U-Boot. Versal: FAT32 `storage` partition, not used for booting. |
| p3 `root` | ext4 | Root filesystem. |

### Prepare the SD card

```{warning}
Flashing writes directly to a raw block device and cannot be undone. Be absolutely
certain you have identified the SD card's device node before running the commands below — if you
use the wrong device you risk destroying data on one of your hard drives.
```

1. Identify the SD card device. With the card **un**plugged, run:
   ```
   lsblk -o NAME,SIZE,RM,TYPE,MOUNTPOINT
   ```
   Insert the card and run the same command again. The new entry — typically `/dev/sdX`, with
   `RM=1` (removable) and a size matching your card — is your target. Replace `sdX` with that
   device, and `<target>` with your target design, throughout the steps below.

2. Unmount any partitions the desktop auto-mounted:
   ```
   for p in /dev/sdX?*; do sudo umount "$p" 2>/dev/null; done
   ```

3. Flash the wic image to the raw device. With `bmaptool` (fast — only writes the blocks that are
   actually used):
   ```
   sudo bmaptool copy --bmap Yocto/<target>/images/linux/rootfs.wic.bmap \
                            Yocto/<target>/images/linux/rootfs.wic.xz \
                            /dev/sdX
   ```
   Or, as a fallback with `dd` (slower — writes every block):
   ```
   xzcat Yocto/<target>/images/linux/rootfs.wic.xz \
       | sudo dd of=/dev/sdX bs=4M status=progress conv=fsync
   ```

4. **Install `BOOT.BIN` on the `esp` partition (Zynq-7000 and Zynq UltraScale+ only).** The EDF
   wic leaves the first FAT partition (`esp`) empty, and the BootROM loads `BOOT.BIN` from the
   first FAT partition, so it must be copied there by hand:
   ```
   sudo partprobe /dev/sdX
   sudo mkdir -p /mnt/sd_esp
   sudo mount /dev/sdX1 /mnt/sd_esp
   sudo cp Yocto/<target>/images/linux/BOOT.BIN /mnt/sd_esp/BOOT.BIN
   sync
   sudo umount /mnt/sd_esp && sudo rmdir /mnt/sd_esp
   ```
   ```{note}
   On Versal you can skip this step: the Versal BSPs of this repository put `BOOT.BIN` and
   `boot.scr` onto the `esp` when the wic is built, so the flashed card boots as it is.
   Copying `BOOT.BIN` again does no harm. (The `readme.txt` in the Versal zip also mentions
   `BOOTAA64.EFI`; this design boots through `boot.scr` and does not need it.)
   ```

5. Eject the card cleanly so pending writes flush:
   ```
   sudo eject /dev/sdX
   ```

### Boot

1. Plug the SD card into the target board.
2. Set the board to boot from SD card. The boot-mode DIP-switch settings are the same regardless of
   the Linux flow — see the per-board switch settings under
   [Boot PetaLinux](petalinux.md#boot-petalinux). For the Versal boards, refer to the
   board's user guide for the SD boot-mode setting (U-Boot prints
   `Bootmode: LVL_SHFT_SD_MODE1` when the board has booted from the SD card).
3. Connect one or more M.2 NVMe SSDs to the mezzanine card, and connect the card to the
   FMC connector of your target design. Designs with one active slot use only the slot
   labelled "SSD1" / "SLOT 1".
4. Connect the USB-UART to your PC and open a terminal emulator at 115200 baud (8N1) — see
   [UART terminal](petalinux.md#uart-terminal). On the Zynq UltraScale+ and Versal boards
   the USB-UART exposes several ports; the Linux console is normally the first one.
5. Optionally connect the board's Ethernet port to your network.
6. Power up the board.

### What the boot looks like

On a Zynq UltraScale+ board (ZCU106 shown), the FSBL loads the bitstream and U-Boot, and
U-Boot runs `boot.scr` from the `boot` partition:

```none
Zynq MP First Stage Boot Loader
Release 2025.2   ...
U-Boot 2025.01-...
Bootmode: LVL_SHFT_SD_MODE1
Hit any key to stop autoboot:  2  1  0
switch to partitions #0, OK
mmc0 is current device
Scanning mmc 0:2...
Found U-Boot script /boot.scr
## Executing script at 20000000
Checking for kernel:Image
Loading Image at 0x200000
EFI stub: Booting Linux Kernel...
[    0.000000] Kernel command line: earlycon console=ttyPS0,115200 clk_ignore_unused init_fatal_sh=1 root=/dev/mmcblk0p3 ro rootwait uio_pdrv_genirq.of_id=generic-uio cma=1536M
...
[    1.494382] xilinx-xdma-pcie 400000000.axi-pcie: PCIe Link is UP
[    1.667218] xilinx-xdma-pcie 500000000.axi-pcie: PCIe Link is UP
[    2.242896]  nvme0n1: p1
[    2.352826]  nvme1n1: p1
...
[    3.311454] systemd[1]: Hostname set to <zcu106-fpgadrv-2025-2>.
...
zcu106-fpgadrv-2025-2 login:
```

On the Versal boards, the PLM loads the PDI and U-Boot, and U-Boot runs the design's own
`boot.scr` from the `esp` partition. On the VCK190, VMK180, VPK120 and VPK180, this script
first enables the FMC VADJ supply at 1.5 V, then boots the kernel with the device tree that
the PLM loaded:

```none
Xilinx Versal Platform Loader and Manager
Release 2025.2 ...
Loading PDI from SD1_LS
...
U-Boot 2025.01-...
Bootmode: LVL_SHFT_SD_MODE1
Hit any key to stop autoboot:  5  4  3  2  1  0
## Executing script at 20000000
FPGA Drive FMC: enabling VADJ (1.5V) via IR38164
Setting bus to 0
FPGA Drive FMC: loading Image from esp (mmc 0:1)
## Flattened Device Tree blob at 00001000
Starting kernel ...
[    0.000000] Kernel command line: earlycon=pl011,mmio32,0xff000000 console=ttyAMA0,115200 clk_ignore_unused root=/dev/mmcblk0p3 rw rootwait cma=1536M
...
[    2.065059] xilinx-xdma-pcie 84000000.axi-pcie: PCIe Link is UP
[    2.302044] xilinx-xdma-pcie 88000000.axi-pcie: PCIe Link is UP
...
vck190-fpgadrv-2025-2 login:
```

The Versal kernel log also contains
`pci 0000:00:00.0: BAR 0 [mem size 0x100000000000 64bit pref]: can't assign; no space`.
This refers to a BAR of the Root Port itself, which is not used, and can be ignored.

### Kernel command line

| Family | Console | Root file system | Extra arguments |
|--------|---------|------------------|-----------------|
| Zynq-7000 | `ttyPS0`, 115200 | `/dev/mmcblk0p3` | `cma=512M` |
| Zynq UltraScale+ | `ttyPS0`, 115200 | `/dev/mmcblk0p3` (`/dev/mmcblk1p3` on the UltraZed-EV) | `cma=1536M` (`cma=1000M` on the UltraZed-EV) |
| Versal | `ttyAMA0`, 115200 | `/dev/mmcblk0p3` | `cma=1536M` |

The large CMA pool is for the DMA buffers of large NVMe transfers. On Zynq-7000 and Zynq
UltraScale+, the command line is built by the EDF `boot.scr` and the board-specific
arguments are added to it from `BSP_EXTRA_BOOTARGS` in `Yocto/bsp/<board>/conf/local.conf.append`.
On Versal, they are set in the design's own boot script,
`Yocto/bsp/<board>/meta-user/recipes-bsp/u-boot/files/fpgadrv-boot.cmd`. The root file
system is mounted read-only first and remounted read-write by systemd.

## Log in

The console shows a login prompt with the design's hostname, `<board>-fpgadrv-2025-2`
(for example `zcu106-fpgadrv-2025-2`; `picozed-fpgadrv-2025-2` on the PicoZed).

1. Log in as **`amd-edf`**. On the first login you must choose a password (you are asked for
   it twice); it is required on every later login.
2. The `amd-edf` user can run commands as root with `sudo`.

```none
zcu106-fpgadrv-2025-2 login: amd-edf
You are required to change your password immediately (administrator enforced).
New password:
Retype new password:
zcu106-fpgadrv-2025-2:~$
```

### Board Ethernet port

The images bring up the board's Ethernet port (`end0`) with DHCP, and include an SSH
server, so once you have set the `amd-edf` password you can also log in over the network:

```
ip -br addr show end0          # on the board: find the IP address
ssh amd-edf@<board-ip>         # from your PC
```

The Yocto device trees of the ZCU104, ZCU106, ZCU111, ZCU208, ZCU216
and VCK190 set a fixed MAC address on that port (`local-mac-address` in
`Yocto/bsp/<board>/meta-user/recipes-bsp/device-tree/files/system-user.dtsi`) so that the
board gets the same DHCP lease on every boot. If you have more than one of the same board
on one network, give each image a different address there. On the other boards, the MAC
address is passed on by U-Boot or chosen at random at boot.

## Test the SSDs

Continue with [Test the SSDs in Linux](linux_test) for the `lspci`, `nvme list`,
partition/format and throughput steps.

## Patches and known issues

The per-board fixups applied in the Yocto flow live in `Yocto/bsp/<board>/` — chiefly the
`system-user.dtsi` device-tree overrides, the U-Boot script and the kernel `bsp.cfg`
fragments. The list of changes on top of the stock EDF flow is in
[advanced](advanced.md#what-the-yocto-bsps-change); the ones that change what you see on
the board are:

* **Board Ethernet port passes traffic.** The device tree generated by the SDT flow does not
  describe the board's Ethernet PHY (TI DP83867 on the ZCU10x/ZCU111/ZCU208/ZCU216 and the
  Versal boards), so Linux used the generic PHY driver without the RGMII delays: the link
  came up at 1 Gb/s but no packets passed. The BSPs now describe the PHY.
* **Zynq-7000 board Ethernet port enabled.** It was previously disabled because U-Boot
  crashed while probing it; the PHY is now described in the device tree (Marvell PHY at MDIO
  address 0 on the PicoZed, with the PicoZed LED configuration kept, and at address 7 on the
  ZC706) and the port is enabled again.
* **Kernel arguments and hostname are applied.** The CMA size and other board-specific
  kernel arguments were set in a variable that the EDF boot flow does not read, and the
  hostname was overridden by the distribution default (`amd-edf`). Both now take effect.
* **ZCU104 FMC VADJ.** The 2025.2 FSBL looks for the FMC's VADJ record in the wrong EEPROM
  and reads too few bytes, so it never enables VADJ and the FMC is unpowered. The ZCU104 BSP
  patches the FSBL (`zcu104_vadj_fsbl.patch`) so that VADJ is set from the FMC card's EEPROM.
* **Versal boots hands-free.** The stock EDF Versal image has neither `BOOT.BIN` nor a
  working EFI loader on the `esp`, so a freshly flashed card stops at the U-Boot prompt. The
  Versal BSPs add `BOOT.BIN` and a design-specific `boot.scr` to the `esp` and point U-Boot's
  boot command at it; the script also enables VADJ (see above).
* **nvme-cli** is included in all Yocto images, and the Versal images also include the
  `speed-tests` scripts.

[FPGA Drive FMC Gen4]: https://docs.opsero.com/op063/datasheet/overview/
[M.2 M-key Stack FMC]: https://docs.opsero.com/op073/datasheet/overview/
[supported Linux distributions]: https://docs.amd.com/r/en-US/ug1144-petalinux-tools-reference-guide/Setting-Up-Your-Environment

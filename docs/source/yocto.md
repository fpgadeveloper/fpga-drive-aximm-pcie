# Yocto

The Yocto / EDF flow (AMD's Embedded Development Framework) is the announced successor to
PetaLinux. It can be built for these reference designs using the Makefile in the `Yocto`
directory of the repository.

```{note} For 2025.2 both the PetaLinux and Yocto flows are supported and produce an equivalent
image. From the next tool version onward, the PetaLinux flow for this repository will be retired
and Yocto will be the only supported flow — see [build instructions](build_instructions).
```

## Requirements

To build the Yocto projects you will need a physical or virtual machine running one of the
[supported Linux distributions], with the Vitis Core Development Kit installed — the flow uses
`xsct`/`sdtgen` (which ship with Vitis) to generate a System Device Tree from the Vivado XSA. You
also need [Google's repo tool](https://gerrit.googlesource.com/git-repo/) on your `PATH`.

```{attention} You cannot build the Yocto projects in the Windows operating system. Windows users
are advised to use a Linux virtual machine to build the Yocto projects.
```

## How to build

1. From a command terminal, clone the Git repository and `cd` into it:
   ```
   git clone https://github.com/fpgadeveloper/fpga-drive-aximm-pcie.git
   cd fpga-drive-aximm-pcie
   ```
2. Source the Vivado and Vitis setup scripts:
   ```
   source <path-to-xilinx-tools>/2025.2/Vivado/settings64.sh
   source <path-to-xilinx-tools>/2025.2/Vitis/settings64.sh
   ```
3. Build the Yocto image for your target platform by running the following commands, replacing
   `<target>` with one of the target design labels listed in the
   [build instructions](build_instructions.md#build-yocto-project-in-linux):
   ```
   cd Yocto
   make yocto TARGET=<target>
   ```

The last command launches the corresponding Vivado build if that project has not already been
built and its hardware exported. The first build of a target downloads several GB of sources
(`repo sync`) and runs bitbake from scratch, so it takes a while; subsequent builds are
incremental. The output products are gathered into `Yocto/<target>/images/linux/`:

| File | Description |
| --- | --- |
| `BOOT.BIN` | Boot image (FSBL/PLM + bitstream/PDI + U-Boot) |
| `boot.scr` | U-Boot boot script |
| `Image` / `uImage` | Linux kernel (`uImage` on Zynq-7000, `Image` on Zynq UltraScale+ and Versal) |
| `system.dtb` | Linux device tree |
| `rootfs.wic.xz` | Full SD-card disk image — this is what you flash |
| `rootfs.tar.gz` | Root filesystem tarball |

## Boot from SD card

Unlike the PetaLinux flow (which produces separate boot files for a hand-partitioned card), the
Yocto flow produces a **full SD-card disk image** (`rootfs.wic.xz`) that already contains all
partitions. You flash that image to the SD card's raw device, then — on Zynq-7000 and Zynq
UltraScale+ — copy `BOOT.BIN` onto the first FAT partition.

### Prepare the SD card

```{warning} Flashing writes directly to a raw block device and cannot be undone. Be absolutely
certain you have identified the SD card's device node before running the commands below — if you
use the wrong device you risk destroying data on one of your hard drives.
```

1. Identify the SD card device. With the card **un**plugged, run:
   ```
   lsblk -o NAME,SIZE,RM,TYPE,MOUNTPOINT
   ```
   Insert the card and run the same command again. The new entry — typically `/dev/sdX`, with
   `RM=1` (removable) and a size matching your card — is your target. Replace `sdX` with that
   device, and `<target>` with your board, throughout the steps below.

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
   wic leaves the first FAT partition (`esp`) empty and installs `BOOT.BIN` onto the ext4 `boot`
   partition, which the BootROM cannot read. Since the BootROM loads `BOOT.BIN` from the first FAT
   partition, it must be copied onto `esp` by hand:
   ```
   sudo partprobe /dev/sdX
   cp Yocto/<target>/images/linux/BOOT.BIN /media/<you>/esp/BOOT.BIN
   sync
   ```
   If `esp` did not auto-mount, mount the first partition manually:
   ```
   sudo mkdir -p /mnt/sd_esp
   sudo mount /dev/sdX1 /mnt/sd_esp
   sudo cp Yocto/<target>/images/linux/BOOT.BIN /mnt/sd_esp/BOOT.BIN
   sync
   sudo umount /mnt/sd_esp && sudo rmdir /mnt/sd_esp
   ```
   ```{note} On Versal, skip this step. The Versal wic places `BOOT.BIN` (and `boot.scr`) onto the
   `esp` automatically, so the flashed card boots with no manual copy.
   ```

5. Eject the card cleanly so pending writes flush:
   ```
   sudo eject /dev/sdX
   ```

### Boot

1. Plug the SD card into the target board.
2. Set the board to boot from SD card. The boot-mode DIP-switch settings are the same regardless of
   the Linux flow — see the per-board switch settings under
   [Boot PetaLinux](petalinux.md#boot-petalinux). (For Versal boards, refer to the board's
   documentation for the SD boot-mode setting.)
3. Connect one or more M.2 NVMe PCIe SSDs to the [FPGA Drive FMC Gen4], and connect it to the
   target board's FMC connector.
4. Connect the USB-UART to your PC and open a terminal emulator at 115200 baud (8N1) — see
   [UART terminal](petalinux.md#uart-terminal).
5. Connect and power your hardware.

## Setup the NVMe SSD

Once Linux has booted and you have logged in at the console, checking and preparing the SSD is
identical to the PetaLinux flow — see
[Setup the NVMe SSD](petalinux.md#setup-the-nvme-ssd-in-petalinux) for the `lspci`, `lsblk`,
`fdisk` and `mkfs` walkthrough.

## Patches and known issues

The per-board fixups applied in the Yocto flow live in `Yocto/bsp/<board>/` — chiefly the
`system-user.dtsi` device-tree overrides and the kernel `bsp.cfg` fragments. These cover quirks
such as the Versal QDMA PCIe `ranges` identity-map and, on Zynq-7000, the larger `VMALLOC`
(`CONFIG_VMSPLIT_2G`) needed to map the AXI-PCIe config window. See the BSP sources and
[advanced](advanced) for details.

[FPGA Drive FMC Gen4]: https://docs.opsero.com/op063/datasheet/overview/
[supported Linux distributions]: https://docs.amd.com/r/en-US/ug1144-petalinux-tools-reference-guide/Setting-Up-Your-Environment

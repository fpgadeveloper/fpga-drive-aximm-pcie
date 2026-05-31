# Copyright (C) 2025-2026, Opsero Electronic Design Inc.  All rights reserved.
#
# SPDX-License-Identifier: MIT

# FPGA Drive FMC reference design U-Boot boot script (Versal, EDF flow).
#
# Why a boot.scr at all: the EDF Versal image is wired for systemd-boot/EFI,
# but the bootimg-efi-amd wic plugin's systemd-boot install is commented out in
# 2025.2, so no BOOTAA64.EFI lands on the esp and U-Boot's EFI boot manager
# finds nothing ("Cannot load any image"). U-Boot's distro scan tries scripts
# (boot.scr) before EFI, so dropping this boot.scr on the esp gives a clean,
# hands-free boot.
#
# What it does: load the kernel Image from the esp (FAT, mmc 0:1) and boot it
# with the Linux device tree the PLM already loaded to 0x1000 (the
# cortexa72-linux.dtb partition embedded in BOOT.BIN). No fdt patching is
# needed because the PCIe `ranges` fix lives in the device tree itself
# (system-user.dtsi).
#
# Console is the Versal CIPS PS UART0 (PL011 @ 0xff000000 -> ttyAMA0); earlycon
# needs mmio32 for the Versal PL011. clk_ignore_unused keeps the PL/QDMA clocks
# from being gated. cma sized for large NVMe DMA transfers.

setenv bootargs 'earlycon=pl011,mmio32,0xff000000 console=ttyAMA0,115200 clk_ignore_unused root=/dev/mmcblk0p3 rw rootwait cma=1536M'

# Enable the FMC VADJ rail before booting Linux. On the VCK190/VMK180/VPK120/VPK180 the IR38164
# buck regulator (I2C addr 0x1E, behind the 0x74 mux on I2C bus 0) supplies
# VADJ_FMC. Normally the system controller would enable it, but doing it here in
# U-Boot guarantees VADJ is up before Linux brings the PCIe/QDMA link out of reset
# and works even when the system controller is not used/configured. This mirrors
# the PetaLinux platform-top.h vadj_1v5_en sequence and sets VADJ to 1.5V.
echo "FPGA Drive FMC: enabling VADJ (1.5V) via IR38164"
i2c dev 0
i2c mw 0x74 0x00.0 0x01 0x1
i2c mw 0x1E 0x24.1 0x01 0x1
i2c mw 0x1E 0x25.1 0x80 0x1
i2c mw 0x1E 0x3A.1 0x01 0x1
i2c mw 0x1E 0x3B.1 0xF3 0x1
i2c mw 0x1E 0x3D.1 0x01 0x1
i2c mw 0x1E 0x3E.1 0xF3 0x1
i2c mw 0x1E 0x3F.1 0x00 0x1
i2c mw 0x1E 0x40.1 0x00 0x1
i2c mw 0x1E 0x41.1 0x00 0x1
i2c mw 0x1E 0x42.1 0x00 0x1
i2c mw 0x1E 0x22.1 0x80 0x1

echo "FPGA Drive FMC: loading Image from esp (mmc 0:1)"
if fatload mmc 0:1 ${kernel_addr_r} Image; then
	booti ${kernel_addr_r} - 0x1000
else
	echo "FPGA Drive FMC: Image not found on esp (mmc 0:1)"
fi

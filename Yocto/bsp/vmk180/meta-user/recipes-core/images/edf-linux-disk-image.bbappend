# FPGA Drive FMC reference-design packages
#
# edf-linux-disk-image uses IMAGE_INSTALL = "..." (assignment) and pulls in
# packagegroup-core-* + AMD-EDF_IMAGE_FULL_INSTALL — append our additions.

IMAGE_INSTALL:append = " \
    e2fsprogs-mke2fs \
    fpga-manager-script \
    dfx-mgr \
    mtd-utils \
    can-utils \
    nfs-utils \
    pciutils \
    libdfx \
"

# --- Hands-free boot for Versal ---------------------------------------------
# The Versal BootROM (SD mode) reads BOOT.BIN from the FAT esp, and U-Boot's
# distro scan runs a boot.scr from the esp (scripts are tried before the EFI
# path, which is incomplete in 2025.2). The stock EDF wic puts NEITHER on the
# esp -- only Image + a systemd-boot config with no loader binary -- so a
# freshly flashed card can't boot. Add both to the esp:
#   - BOOT.BIN   : so the BootROM boots cleanly from FAT (no slow raw scan)
#   - boot.scr   : our u-boot-edf-scr script (loads Image + boots dtb@0x1000)
# Sources are deploy-dir names; ";dst" is the path on the esp.
IMAGE_EFI_BOOT_FILES:append = " boot.bin;BOOT.BIN boot.scr;boot.scr"

# Make sure both artifacts are deployed before the wic is assembled.
do_image_wic[depends] += "virtual/boot-bin:do_deploy u-boot-edf-scr:do_deploy"


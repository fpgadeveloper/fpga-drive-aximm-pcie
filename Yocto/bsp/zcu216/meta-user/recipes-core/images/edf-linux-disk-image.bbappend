# FPGA Drive FMC reference-design packages (ported from
# PetaLinux/bsp/zcu208/project-spec/configs/rootfs_config — only the
# explicitly-enabled CONFIG_<pkg>=y entries are reproduced here).
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

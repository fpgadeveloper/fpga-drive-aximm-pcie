# Copyright (C) 2025-2026, Opsero Electronic Design Inc.  All rights reserved.
#
# SPDX-License-Identifier: MIT

# FPGA Drive FMC reference-design packages (ported from
# PetaLinux/bsp/pz/project-spec/configs/rootfs_config -- only the
# explicitly-enabled CONFIG_<pkg>=y entries are reproduced here).
#
# NOTE vs the zynqMP BSPs: dfx-mgr / libdfx are omitted (no DFX-manager support
# on Zynq-7000 / cortexa9, and the PetaLinux z7 rootfs does not include them);
# nvme-cli is added (present in the z7 rootfs).

IMAGE_INSTALL:append = " \
    e2fsprogs-mke2fs \
    fpga-manager-script \
    mtd-utils \
    can-utils \
    nfs-utils \
    pciutils \
    nvme-cli \
"

# Copyright (C) 2026, Opsero Electronic Design Inc.  All rights reserved.
#
# SPDX-License-Identifier: MIT

# ZCU104 FSBL VADJ patch - MANDATORY on this board or the FMC is unpowered.
#
# The 2025.2 zynqmp_fsbl reads the FMC VADJ record from the wrong EEPROM (the
# board's own at 0x54 rather than the FMC's at 0x50, on the wrong I2C mux
# channel) and reads too few bytes to reach the VADJ field, so it never turns
# on VADJ and the FMC card stays unpowered. See files/zcu104_vadj_fsbl.patch.
#
# NOTE: 2025.2's xlnx-embeddedsw.bbclass schedules do_copy_shared_src AFTER
# do_patch (do_patch runs on an empty workdir). That means SRC_URI-attached
# .patch files can't be applied the normal way. We stage the patch with
# apply=no and run it manually in a new shell task inserted between
# do_copy_shared_src and do_configure. Same fix as the PetaLinux 2025.2 BSPs.

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " file://zcu104_vadj_fsbl.patch;apply=no"

do_apply_vadj_patch() {
    cd ${S} && patch -p1 < ${WORKDIR}/zcu104_vadj_fsbl.patch
}
addtask apply_vadj_patch after do_copy_shared_src before do_configure

# Copyright (C) 2025-2026, Opsero Electronic Design Inc.  All rights reserved.
#
# SPDX-License-Identifier: MIT

# Override the EDF default U-Boot bootcmd so the board auto-boots our boot.scr
# off the esp instead of dropping into the (incomplete) EFI bootmenu. The
# override lives in a kconfig fragment; see files/fpgadrv-bootcmd.cfg. EDF's own
# u-boot-xlnx bbappend (meta-amd-edf, priority 5) adds bootcmd-bootefi.cfg /
# edf-env.cfg; this layer is priority 7 so our fragment merges afterwards and
# wins the CONFIG_BOOTCOMMAND symbol.
#
# := captures the bbappend dir at parse time (${THISDIR} is unreliable at task
# time inside a bbappend).
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://fpgadrv-bootcmd.cfg"

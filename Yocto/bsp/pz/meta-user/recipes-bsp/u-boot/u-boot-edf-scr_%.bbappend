# Copyright (C) 2025-2026, Opsero Electronic Design Inc.  All rights reserved.
#
# SPDX-License-Identifier: MIT

# Extra kernel command-line arguments for the Zynq-7000 / ZynqMP EDF SD boot.
#
# On these SoCs the kernel command line is built ONLY by the EDF U-Boot script
# (meta-amd-edf u-boot-edf-scr: edf-linux-mmc-boot.cmd / .cmd.zynq -> boot.scr):
#     fdt get value bootargs /chosen bootargs
#     setenv bootargs ${bootargs} root=/dev/mmcblk${devnum}p3 ro rootwait uio_pdrv_genirq.of_id=generic-uio
# i.e. the device tree's /chosen/bootargs (on ZynqMP sdtgen emits
# "earlycon console=ttyPS0,115200 clk_ignore_unused init_fatal_sh=1"; on
# Zynq-7000 it emits none) plus fixed root args. APPEND in local.conf is never
# read by this flow (it only feeds syslinux/grub/wic --append), so BSP-specific
# arguments must be injected into the script itself.
#
# BSP_EXTRA_BOOTARGS is set per board in conf/local.conf.append; it is appended
# to the script's `setenv bootargs` line right after unpack (both the ZynqMP
# .cmd and the Zynq-7000 .cmd.zynq, whichever the recipe compiles). The variable
# is part of do_unpack's signature, so changing it rebuilds boot.scr.
BSP_EXTRA_BOOTARGS ??= ""

do_unpack[postfuncs] += "bsp_add_bootargs"
bsp_add_bootargs[dirs] = "${WORKDIR}"
bsp_add_bootargs() {
    [ -n "${BSP_EXTRA_BOOTARGS}" ] || return 0
    for f in ${WORKDIR}/edf-linux-mmc-boot.cmd ${WORKDIR}/edf-linux-mmc-boot.cmd.zynq; do
        [ -f "$f" ] || continue
        sed -i -e '/^setenv bootargs /s|$| ${BSP_EXTRA_BOOTARGS}|' "$f"
        grep -qF -- " ${BSP_EXTRA_BOOTARGS}" "$f" || \
            bbfatal "BSP_EXTRA_BOOTARGS: no 'setenv bootargs' line patched in $f"
    done
}

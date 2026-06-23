# Copyright (C) 2025-2026, Opsero Electronic Design Inc.  All rights reserved.
#
# SPDX-License-Identifier: MIT

# Board-level device-tree fixups layered on top of the gen-machineconf /
# lopper-generated CONFIG_DTFILE (conf/dts/fpgadrv-<target>/<...>-linux.dts).
#
# The design-specific PL hardware (xilinx_qdma PCIe) already comes from the
# SDT's pl.dtsi, so this file does NOT touch the PL. It only carries SoC-side
# board quirks the XSA / sdtgen output doesn't encode. See system-user.dtsi.
#
# A fixed path is used (NOT ${FPGADRV_TARGET}) so the file always resolves at
# bitbake parse time, including while gen-machineconf is parsing recipes.
#
# IMPORTANT: only apply system-user.dtsi to the Linux (APU) device tree. The
# PLM/PSM/FSBL domain device-trees don't define the SoC peripheral labels the
# overrides reference, so #including it there makes dtc fail with
# "Label or path ... not found". Only the Linux-domain DTS basename contains
# "linux" (...-cortexaN-linux.dts); match on os.path.basename, NOT the full
# CONFIG_DTFILE path -- the path can itself contain "linux" (e.g. a parent dir
# like .../oa-win-linux-flow/...) and would wrongly pull these overrides into
# every domain (FSBL/PMU), breaking those baremetal builds.
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

EXTRA_DT_INCLUDE_FILES:append = "${@' system-user.dtsi' if 'linux' in os.path.basename(d.getVar('CONFIG_DTFILE') or '') else ''}"

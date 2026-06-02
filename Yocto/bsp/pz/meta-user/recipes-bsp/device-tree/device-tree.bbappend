# Copyright (C) 2025-2026, Opsero Electronic Design Inc.  All rights reserved.
#
# SPDX-License-Identifier: MIT

# Board-level device-tree fixups layered on top of the gen-machineconf /
# lopper-generated CONFIG_DTFILE (conf/dts/fpgadrv-<target>/cortexa9-linux.dts).
#
# The design-specific PL hardware (axi_pcie Gen2) already comes from the SDT's
# pl.dtsi, so this file does NOT touch the PL. It carries only SoC-side board
# quirks the XSA / sdtgen output doesn't encode (see system-user.dtsi).
#
# meta-xilinx's device-tree.bb consumes EXTRA_DT_INCLUDE_FILES by copying each
# file into the DT build dir and appending a `#include "<file>"` to the base
# DTS. A fixed path is used (NOT ${FPGADRV_TARGET}) so the file always resolves
# at bitbake parse time, including while gen-machineconf is parsing recipes.
#
# IMPORTANT: only apply system-user.dtsi to the Linux (APU) device tree. The
# FSBL domain device-tree (the -cortexa9-fsbl multiconfig) doesn't define the
# SoC peripheral labels the overrides reference, so #including it there makes
# dtc fail with "Label or path ... not found". The Linux domain DTS is the only
# CONFIG_DTFILE whose name contains "linux".
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

EXTRA_DT_INCLUDE_FILES:append = "${@' system-user.dtsi' if 'linux' in (d.getVar('CONFIG_DTFILE') or '') else ''}"

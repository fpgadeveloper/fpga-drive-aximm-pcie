# Copyright (C) 2025-2026, Opsero Electronic Design Inc.  All rights reserved.
#
# SPDX-License-Identifier: MIT

# Board-level device-tree fixups layered on top of the gen-machineconf /
# lopper-generated CONFIG_DTFILE (conf/dts/fpgadrv-<target>/cortexa53-linux.dts).
#
# The design-specific PL hardware (xilinx_xdma PCIe) already comes from the
# SDT's pl.dtsi, so this file does NOT touch the PL. It only carries SoC-side
# board quirks the XSA / sdtgen output doesn't encode (UART ttyPS mapping, and
# per-board SD-card / PHY-clock fixups). See system-user.dtsi for the specifics.
#
# meta-xilinx's device-tree.bb consumes EXTRA_DT_INCLUDE_FILES by copying each
# file into the DT build dir and appending a `#include "<file>"` to the base
# DTS, so the overrides are applied on top of the generated tree. A fixed path
# is used (NOT ${FPGADRV_TARGET}) so the file always resolves at bitbake parse
# time, including while gen-machineconf is parsing recipes.
#
# IMPORTANT: only apply system-user.dtsi to the Linux (APU) device tree. The
# FSBL and PMU domain device-trees (the -cortexa53-fsbl / -microblaze-pmu
# multiconfigs) don't define the SoC peripheral labels (uart0/1, sdhci1, ...)
# the overrides reference, so #including it there makes dtc fail with
# "Label or path ... not found". The Linux domain DTS is the only CONFIG_DTFILE
# whose name contains "linux".
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

EXTRA_DT_INCLUDE_FILES:append = "${@' system-user.dtsi' if 'linux' in (d.getVar('CONFIG_DTFILE') or '') else ''}"

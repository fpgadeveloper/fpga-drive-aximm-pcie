# Board-level device-tree fixups layered on top of the gen-machineconf /
# lopper-generated CONFIG_DTFILE (conf/dts/fpgadrv-zcu104/cortexa53-linux.dts).
#
# The design-specific PL hardware (xilinx_xdma PCIe) already comes from the
# SDT's pl.dtsi, so this file does NOT touch the PL. It only carries SoC-side
# board quirks the XSA / sdtgen output doesn't encode — currently the ZCU104
# SD-card level-shifter limitation (see system-user.dtsi).
#
# meta-xilinx's device-tree.bb consumes EXTRA_DT_INCLUDE_FILES by copying each
# file into the DT build dir and appending a `#include "<file>"` to the base
# DTS, so the &sdhci1 override below is applied on top of the generated tree.
# A fixed path is used (NOT ${FPGADRV_TARGET}) so the file always resolves at
# bitbake parse time, including while gen-machineconf is parsing recipes.

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

EXTRA_DT_INCLUDE_FILES:append = " system-user.dtsi"

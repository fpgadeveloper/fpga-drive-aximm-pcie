# The per-board BSP is shared across multiple targets (e.g. zcu106_hpc0 and
# zcu106_hpc1). The board PS DT is identical between targets, but the PL
# overlay (xdma PCIe nodes, lane counts) differs because each target is a
# distinct Vivado block design. We therefore key the system-user.dtsi lookup
# off FPGADRV_TARGET, which Yocto/scripts/configure-build.sh writes into
# local.conf at workspace setup time.

FILESEXTRAPATHS:prepend := "${THISDIR}/files/${FPGADRV_TARGET}:"

SRC_URI:append = " file://system-user.dtsi"

require ${@'device-tree-sdt.inc' if d.getVar('SYSTEM_DTFILE') != '' else ''}

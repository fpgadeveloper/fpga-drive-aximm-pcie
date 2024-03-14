FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://bsp.cfg"
SRC_URI:append = " file://AR_76647_QDMA_Bridge_Support_Fixes_for_RC_Linux_Driver_2023_2.patch"
KERNEL_FEATURES:append = " bsp.cfg"

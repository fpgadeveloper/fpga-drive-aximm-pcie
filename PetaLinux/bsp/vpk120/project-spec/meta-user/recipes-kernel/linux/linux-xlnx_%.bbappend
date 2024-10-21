FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://bsp.cfg"
SRC_URI:append = " file://Opsero_QDMA_Bridge_Support_Fixes_for_RC_Linux_Driver_2024_1_32_n_64.patch"
KERNEL_FEATURES:append = " bsp.cfg"

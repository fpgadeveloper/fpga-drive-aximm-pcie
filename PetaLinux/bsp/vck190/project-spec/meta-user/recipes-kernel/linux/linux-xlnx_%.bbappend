FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://bsp.cfg"
SRC_URI:append = " file://AR_76647_QDMA_Bridge_Fixes_for_RC_Linux_Driver_2021_2_2022_1_2022_2.patch"
KERNEL_FEATURES:append = " bsp.cfg"

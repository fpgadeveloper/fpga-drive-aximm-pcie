FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = " file://bsp.cfg"
SRC_URI:append = " file://Opsero_QDMA_Bridge_Support_Fixes_for_RC_Linux_Driver_2024_1_32_n_64.patch"
SRC_URI:append = " file://Fidus_Versal_QDMA_2GB_Limit_NVMe_Driver_2024_1.patch"
KERNEL_FEATURES:append = " bsp.cfg"

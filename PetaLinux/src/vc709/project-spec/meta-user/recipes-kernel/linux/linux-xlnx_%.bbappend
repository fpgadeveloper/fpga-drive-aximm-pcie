SRC_URI += "file://proc.cfg \
            file://kernel-options.cfg \
            file://bsp.cfg \
            "
KERNEL_FEATURES_append = " bsp.cfg"

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"


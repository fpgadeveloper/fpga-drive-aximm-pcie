FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append = "file://proc.cfg \
            file://kernel-options.cfg \
            file://bsp.cfg \
            "
KERNEL_FEATURES:append = " bsp.cfg"

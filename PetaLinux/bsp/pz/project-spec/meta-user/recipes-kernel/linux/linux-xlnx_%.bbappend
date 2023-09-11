SRC_URI += "file://proc.cfg \
            file://kernel-options.cfg \
            file://bsp.cfg \
            "

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"


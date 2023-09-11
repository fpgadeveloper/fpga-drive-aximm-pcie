FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://main.conf \
"

do_install:append () {
    install -d ${D}${sysconfdir}/connman
    install -m 0755 ${WORKDIR}/main.conf ${D}${sysconfdir}/connman/
}

FILES:${PN} += "${sysconfdir}/main.conf"

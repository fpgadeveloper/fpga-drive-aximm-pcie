#
# This file is the gpio-utils-init recipe.
#

SUMMARY = "Initializes the gpio map"
SECTION = "PETALINUX/utils"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://gpio-utils-init"

S = "${WORKDIR}"

inherit update-rc.d

INITSCRIPT_NAME = "gpio-utils-init"
INITSCRIPT_PARAMS = "start 90 S ."

do_install() {
    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${S}/gpio-utils-init ${D}${sysconfdir}/init.d
}

FILES:${PN} += "${sysconfdir}/init.d/gpio-utils-init"

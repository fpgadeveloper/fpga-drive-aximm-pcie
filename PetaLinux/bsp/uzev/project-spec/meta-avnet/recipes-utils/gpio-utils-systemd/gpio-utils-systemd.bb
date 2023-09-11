#
# This file is the gpio-utils-systemd recipe.
#

SUMMARY = "systemd service which initializes the gpio map"
SECTION = "PETALINUX/utils"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://gpio-utils.service"

inherit systemd

RDEPENDS:${PN} += "gpio-utils"

do_install() {
	install -d ${D}/${systemd_system_unitdir}
	install -m 0644 ${WORKDIR}/gpio-utils.service ${D}${systemd_system_unitdir}/gpio-utils.service
}

SYSTEMD_SERVICE:${PN} = "gpio-utils.service"

FILES:${PN} += "${systemd_system_unitdir}/gpio-utils.service"

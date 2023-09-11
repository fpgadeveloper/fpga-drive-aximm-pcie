#
# This file is the python-webserver-systemd recipe.
#

SUMMARY = "Simple python-webserver-systemd application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://python-webserver.service"

RDEPENDS:${PN} += "bash python3-core python-webserver gpio-utils-systemd"

inherit systemd

do_install() {
	install -d ${D}/${systemd_system_unitdir}
	install -m 0644 ${WORKDIR}/python-webserver.service ${D}${systemd_system_unitdir}/python-webserver.service
}

SYSTEMD_SERVICE:${PN} = "python-webserver.service"

FILES:${PN} += "${systemd_system_unitdir}/python-webserver.service"


#
# This file is the ultra96-wpa recipe.
#

SUMMARY = "Simple ultra96-wpa application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://ultra96-wpa.service"

S = "${WORKDIR}"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

inherit systemd

do_install() {
	install -d ${D}/${systemd_system_unitdir}
	install -m 0644 ${WORKDIR}/ultra96-wpa.service ${D}${systemd_system_unitdir}/ultra96-wpa.service
}

SYSTEMD_SERVICE:${PN} = "ultra96-wpa.service"

FILES:${PN} += "${systemd_system_unitdir}/ultra96-wpa.service"

#
# This file is the ultra96-radio-leds recipe.
#

SUMMARY = "Simple ultra96-radio-leds application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://ultra96-radio-leds.sh \
		   file://ultra96-radio-leds.service \
	"

S = "${WORKDIR}"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

RDEPENDS:${PN} += "gpio-utils"

inherit systemd

do_install() {
	install -d ${D}/${systemd_system_unitdir}
	install -m 0644 ${WORKDIR}/ultra96-radio-leds.service ${D}${systemd_system_unitdir}/ultra96-radio-leds.service

	install -d ${D}/${bindir_native}
	install -m 0755 ${S}/ultra96-radio-leds.sh ${D}${bindir_native}/ultra96-radio-leds.sh
}

SYSTEMD_SERVICE:${PN} = "ultra96-radio-leds.service"

FILES:${PN} += "${systemd_system_unitdir}/ultra96-radio-leds.service \
				${bindir_native}/ultra96-radio-leds.sh \
	"
#
# This file is the blinky-systemd recipe.
#

SUMMARY = "Systemd service unit file for sample blinky application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

COMPATIBLE_MACHINE = "uz"

SRC_URI = "file://blinky.service \
		   file://run-blinky.sh \
	"

inherit systemd

RDEPENDS:${PN} += "blinky gpio-utils-systemd"

do_install() {
	install -d ${D}/${systemd_system_unitdir}
	install -m 0644 ${WORKDIR}/blinky.service ${D}${systemd_system_unitdir}/blinky.service

	install -d ${D}/home/root/
	install -m 0755 ${WORKDIR}/run-blinky.sh ${D}/home/root/run-blinky.sh
}

SYSTEMD_SERVICE:${PN} = "blinky.service"

FILES:${PN} += "${systemd_system_unitdir}/blinky.service \
				/home/root/run-blinky.sh \"

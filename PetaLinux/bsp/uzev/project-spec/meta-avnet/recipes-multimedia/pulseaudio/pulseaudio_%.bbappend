DESCRIPTION = "Adds custom pulseaudio system.pa configuration file"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += "file://system.pa"


do_install:append() {
	install -d ${D}/etc/pulse
	install -m 0644 ${WORKDIR}/system.pa ${D}/etc/pulse/system.pa
}

#
# This file is the python-webserver-init recipe.
#

SUMMARY = "Simple python-webserver-init application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://python-webserver-init \
		  "

S = "${WORKDIR}"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

inherit update-rc.d

INITSCRIPT_NAME = "python-webserver-init"
INITSCRIPT_PARAMS = "start 95 S ."


do_install() {
    install -d ${D}${sysconfdir}/init.d
    install -m 0755 ${S}/python-webserver-init ${D}${sysconfdir}/init.d/python-webserver-init
}

FILES:${PN} += "${sysconfdir}/*"


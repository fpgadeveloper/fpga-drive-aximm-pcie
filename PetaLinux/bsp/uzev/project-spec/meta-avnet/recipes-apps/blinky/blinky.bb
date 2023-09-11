#
# This file is the blinky recipe.
#

SUMMARY = "Simple blinky application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://linux_ps_led_blink.c \
	   file://Makefile \
		  "

COMPATIBLE_MACHINE = "uz|pz"

S = "${WORKDIR}"

FILES:${PN} += "/home/root/*"

DEPENDS:append = "gpio-utils"

do_compile() {
	     oe_runmake
}

do_install() {
	     install -d ${D}/home/root
	     install -m 0755 blinky ${D}/home/root
}

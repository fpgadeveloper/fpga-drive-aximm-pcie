#
# This file is the user-switch-test recipe.
#

SUMMARY = "Simple user-switch-test application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

COMPATIBLE_MACHINE = "uz7ev-evcc"

SRC_URI = "file://linux_user_switch_test.c \
	   file://Makefile \
		  "

S = "${WORKDIR}"

FILES:${PN} += "/home/root/*"

DEPENDS:append = "gpio-utils"

do_compile() {
	     oe_runmake
}

do_install() {
	     install -d ${D}/home/root
	     install -m 0755 user-switch-test ${D}/home/root
}

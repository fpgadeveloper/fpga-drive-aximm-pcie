#
# This file is the performance-tests recipe.
#

SUMMARY = "Simple performance-tests application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://drive-test.sh \
      file://network-test.sh \
      file://sd-test.sh \
        "

S = "${WORKDIR}"

do_install() {
        install -d ${D}/home/root
        install -m 0755 ${S}/drive-test.sh ${D}/home/root
        install -m 0755 ${S}/network-test.sh ${D}/home/root
        install -m 0755 ${S}/sd-test.sh ${D}/home/root
}

FILES:${PN} += "/home/root/drive-test.sh \
           /home/root/network-test.sh \
           /home/root/sd-test.sh \
               "

FILESEXTRAPATHS:prepend := "${THISDIR}/u-boot-xlnx-scr:"

SRC_URI:append = " file://default-arm-versal"

do_deploy:append() {
    install -m 0644 ${WORKDIR}/default-arm-versal ${DEPLOYDIR}/pxeboot/${UBOOTPXE_CONFIG_NAME}/default-arm-versal
}

#
# Recipe to install common gpio util files
#

SUMMARY = "Installs common gpio utils"
SECTION = "gpio"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = " \
    file://gpio_map.sh \
    file://gpio_common.sh \
    file://gpio_common.py \
    file://gpio.cpp \
    file://gpio.h \
    file://Makefile \
	"

COMPATIBLE_MACHINE = "mz|pz|uz|u96v2-sbc"

S = "${WORKDIR}"

RDEPENDS:${PN}:zynq += "gpio-utils-init"
RDEPENDS:${PN}:zynqmp += "gpio-utils-systemd"

CXXFLAGS:aarch64 = "-fPIC"

do_install() {

    INSTALL_DIR=${D}${prefix}/local/bin/gpio
    install -d ${INSTALL_DIR}
    install -m 0755 ${S}/gpio_map.sh ${INSTALL_DIR}
    install -m 0755 ${S}/gpio_common.sh ${INSTALL_DIR}
    install -m 0755 ${S}/gpio_common.py ${INSTALL_DIR}

    LID_DIR=${D}${libdir}
    install -d ${LID_DIR}
    oe_libinstall -so libgpio ${LID_DIR}

    INC_DIR=${D}${includedir}/gpio
    install -d ${INC_DIR}
    install -m 0644 ${S}/gpio.h ${INC_DIR}
}

FILES:${PN} += " \
    ${prefix}/local/bin/gpio/gpio_map.sh \
    ${prefix}/local/bin/gpio/gpio_common.sh \
    ${prefix}/local/bin/gpio/gpio_common.py \
    ${libdir}/libgpio.so.* \
    ${includedir}/gpio/gpio.h \
"

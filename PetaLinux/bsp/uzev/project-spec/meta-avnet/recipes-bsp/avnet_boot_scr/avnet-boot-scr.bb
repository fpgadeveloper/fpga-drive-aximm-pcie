SUMMARY = "U-boot boot scripts for AVNET devices"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

DEPENDS = "u-boot-mkimage-native"

inherit deploy nopackages plnx-deploy

INHIBIT_DEFAULT_DEPS = "1"

COMPATIBLE_MACHINE = "mz|pz|u96v2-sbc|uz"

SRC_URI:mz = " \
            file://avnet_jtag.txt \
            file://avnet_jtag_tftp.txt \
            file://avnet_qspi.txt \
            "

SRC_URI:pz = " \
            file://avnet_jtag.txt \
            file://avnet_jtag_tftp.txt \
            file://avnet_mmc.txt \
            file://avnet_mmc_ext4.txt \
            file://avnet_prog_emmc.txt \
            file://avnet_qspi.txt \
            "

SRC_URI:u96v2-sbc = " \
            file://avnet_jtag.txt \
            "

SRC_URI:uz = " \
            file://avnet_jtag.txt \
            file://avnet_jtag_tftp.txt \
            file://avnet_mmc_ext4.txt \
            "

PACKAGE_ARCH = "${MACHINE_ARCH}"

do_configure[noexec] = "1"
do_install[noexec] = "1"

do_compile() {
    for file in ${WORKDIR}/avnet_*.txt; do
        [ -e "$file" ] || continue
        name=`basename $file .txt`
        mkimage -A arm -T script -C none -n "Boot script" -d "$file" ${WORKDIR}/$name.scr
    done
}

do_deploy() {
    install -d ${DEPLOYDIR}/avnet-boot/

    for file in ${WORKDIR}/avnet_*.scr; do
        [ -e "$file" ] || continue
        install -m 0644 $file ${DEPLOYDIR}/avnet-boot/
    done
}

addtask do_deploy after do_compile before do_build

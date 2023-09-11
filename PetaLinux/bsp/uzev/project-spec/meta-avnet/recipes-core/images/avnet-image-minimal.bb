DESCRIPTION = "OSL image definition for Avnet boards"
LICENSE = "MIT"

require avnet-image-minimal.inc

# remove unnecessary packages found in
# ${IMAGE_INSTALL:pn-petalinux-image-minimal} (build/conf/plnxtool.conf)
# that make the OS image too large to fit in QSPI
# Due to Yocto remove syntax having highest priority, removing within
# avnet-image-minimal.inc prevents these packages being included in avnet-image-full

IMAGE_INSTALL:remove:zynq = "\
        bridge-utils \
        can-utils \
        htop \
        meson \
        openssh-sftp-server \
        pciutils \
        u-boot-tools \
        tcf-agent \
        hwcodecs \
        nfs-utils \
        util-linux-sulogin \
        ncurses-terminfo-base \
        iperf3 \
"
require recipes-core/images/avnet-image-minimal.inc

IMAGE_INSTALL:append:zynq = "\
        bc \
        bonnie++ \
        bridge-utils \
        coreutils \
        ethtool \
        gpio-utils \
        hdparm \
        i2c-tools \
        i2c-tools-misc \
        iperf3 \
        iw \
        kernel-modules \
        nano \
        opencl-clhpp-dev \
        opencl-headers-dev \
        openssh \
        openssh-scp \
        openssh-sftp-server \
        openssh-sshd \
        python-webserver-init \
        python-webserver \
        python3 \
        python3-core \
        python3-dbus \
        python3-pygobject \
        sbc \
        usbutils \
        xrt \
        xrt-dev \
        zocl \
        u-boot-tools \
        tcf-agent \
        nfs-utils \
        util-linux-sulogin \
        ncurses-terminfo-base \
"

# Removed packagegroup-petalinux-vitisai-dev packagegroup-petalinux-vitisai from zynqmp image install due to
# the providing layer (meta-vitis-ai https://github.com/Xilinx/meta-vitis-ai) not being compatible with 2021.2 and
# Yocto honister yet.

IMAGE_INSTALL:append:zynqmp = "\
        bridge-utils \
        cmake \
        dnf \
        gpio-utils \
        json-c \
        libpython3 \
        lmsensors-sensorsdetect \
        mesa-megadriver \
        opencl-clhpp-dev \
        opencl-headers-dev \
        openssh \
        openssh-scp \
        openssh-sftp-server \
        openssh-sshd \
        packagegroup-petalinux-display-debug \
        packagegroup-petalinux-gstreamer \
        packagegroup-petalinux-matchbox \
        packagegroup-petalinux-opencv-dev \
        packagegroup-petalinux-opencv \
        packagegroup-petalinux-python-modules \
        packagegroup-petalinux-self-hosted \
        packagegroup-petalinux-v4lutils \
        packagegroup-petalinux-x11 \
        pciutils \
        python3-pyserial \
        python3 \
        python3-pip \
        xrt \
        xrt-dev \
        zocl \
"

IMAGE_INSTALL:remove:zynqmp = "\
        packagegroup-core-ssh-dropbear \
"

IMAGE_INSTALL:append:uz7ev-evcc = "\
        user-led-test \
        user-switch-test \
"

IMAGE_INSTALL:remove:uz7ev-evcc-hdmi = "\
        blinky \
        blinky-systemd \
        user-switch-test \
"

IMAGE_INSTALL:append:uz7ev-evcc-hdmi = "\
        hdmi-utils \
        kernel-module-hdmi \
"

IMAGE_INSTALL:append:pz = "\
        pciutils \
        performance-tests \
"

COMMON_FEATURES:remove:zynqmp = "\
        ssh-server-dropbear \
"

COMMON_FEATURES:remove:zynq = "\
        ssh-server-dropbear \
"

COMMON_FEATURES:append:zynqmp = "\
        ssh-server-openssh \
"

COMMON_FEATURES:append:zynq = "\
        ssh-server-openssh \
        hwcodecs \
"

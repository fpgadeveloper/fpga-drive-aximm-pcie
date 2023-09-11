require recipes-core/images/petalinux-image-common.inc

# append what is already defined by petalinux (build/conf/plnxtool.conf)
# this will include what the user adds or removes via "petalinux-config -c rootfs"
IMAGE_INSTALL:append= "\
        ${IMAGE_INSTALL:pn-petalinux-image-minimal} \
"

IMAGE_INSTALL:append:zynq = "\
        haveged \
        mtd-utils \
        packagegroup-core-boot \
        run-postinsts \
        udev-extraconf \
"

IMAGE_INSTALL:append:zynqmp = "\
        bc \
        bonnie++ \
        coreutils \
        e2fsprogs \
        e2fsprogs-badblocks \
        e2fsprogs-e2fsck \
        e2fsprogs-mke2fs \
        e2fsprogs-resize2fs \
        ethtool \
        fpga-manager-script \
        haveged \
        hdparm \
        hellopm \
        i2c-tools \
        i2c-tools-misc \
        iperf3 \
        kernel-modules \
        mtd-utils \
        nano \
        packagegroup-core-boot \
        packagegroup-core-ssh-dropbear \
        packagegroup-petalinux-lmsensors \
        parted \
        pciutils \
        pmic-prog \
        run-postinsts \
        tcf-agent \
        udev-extraconf \
        usbutils \
        util-linux \
        util-linux-blkid \
        util-linux-fdisk \
        util-linux-mount \
        util-linux-mkfs \
"

IMAGE_INSTALL:append:u96v2-sbc = "\
        bluez5 \
        connman-gtk \
        git \
        iw \
        libftdi \
        openamp-fw-echo-testd \
        openamp-fw-mat-muld \
        openamp-fw-rpc-demo \
        packagegroup-base-extended \
        packagegroup-petalinux \
        packagegroup-petalinux-96boards-sensors \
        packagegroup-petalinux-benchmarks \
        packagegroup-petalinux-openamp \
        packagegroup-petalinux-ultra96-webapp \
        packagegroup-petalinux-utils \
        ultra96-ap-setup \
        ultra96-misc \
        ultra96-radio-leds \
        ultra96-wpa \
        usb-gadget-ethernet \
        wilc3000-fw \
        wilc \
"

IMAGE_INSTALL:append:uz = "\
        blinky \
        blinky-systemd \
        libdrm \
        libdrm-kms \
        libdrm-tests \
        libstdc++ \
        libv4l \
        media-ctl \
        pciutils \
        performance-tests \
        python-webserver \
        python-webserver-systemd \
        python3 \
        python3-core \
        python3-dbus \
        python3-pygobject \
        yavta \
"

IMAGE_INSTALL:append:uz7ev-evcc = "\
        nvme-cli \
        user-led-test \
        user-switch-test \
"

IMAGE_INSTALL:remove:uz7ev-evcc-hdmi = "\
        python-webserver \
        python-webserver-systemd \
        user-led-test \
"

IMAGE_INSTALL:append:uz7ev-evcc-nvme = "\
        nvme-cli \
"

IMAGE_INSTALL:append:pz = "\
        blinky-init \
        blinky \
        e2fsprogs \
        e2fsprogs-resize2fs \
        e2fsprogs-e2fsck \
        e2fsprogs-mke2fs \
        i2c-tools \
        parted \
        util-linux-mkfs \
"

COMMON_FEATURES:append:zynqmp = "\
        debug-tweaks \
        hwcodecs \
        package-management \
        ssh-server-dropbear \
"

COMMON_FEATURES:append:zynq = "\
        debug-tweaks \
        ssh-server-dropbear \
"

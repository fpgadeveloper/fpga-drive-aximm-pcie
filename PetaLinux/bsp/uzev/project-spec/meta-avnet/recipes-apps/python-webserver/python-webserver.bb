#
# This file is the python-webserver recipe.
#

SUMMARY = "Simple python-webserver application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

COMPATIBLE_MACHINE = "uz|pz|mz"

# Packages
RDEPENDS:${PN} += "\
  python3-core \
    "

SRC_URI = "file://cgi.py \
     file://index.html \
     file://launch_server.sh \
     file://server.py \
     file://stop_server.sh \
     file://css/main.css \
     file://html/sata_results.html \
     file://html/usb3_results.html \
     file://images/Avnet_logo_tagline_rgb.png \
     file://images/favicon.ico \
     file://images/board.jpg \
     file://pdfs/Delkin_Devices_Product_Line.pdf \
      "

SRC_URI:append:uz = "\
     file://images/ultrazed.png \
      "

SRC_URI:append:uz3eg-iocc = "\
     file://pdfs/5043-PB-AES-ZU3EG-1-SOM-G-V3.pdf \
     file://pdfs/5080-PB-AES-ZU-IOCC-G-V2e.pdf \
      "

SRC_URI:append:uz3eg-pciec = "\
     file://pdfs/5043-PB-AES-ZU3EG-1-SOM-G-V3.pdf \
     file://pdfs/5081-PB-AES-ZU-PCIECC-G-V2d.pdf \
      "

SRC_URI:append:uz7ev-evcc = "\
     file://pdfs/5342-pb-ultrazed-ev-som-v1.pdf \
     file://pdfs/5342-pb-ultrazed-ev-starter-kit-v1.pdf \
      "

SRC_URI:append:pz = "\
     file://images/picozed.png \
     file://pdfs/5048-PB-PDP-AES-Z7PZ-SOM-G-V2.pdf \
     file://pdfs/PB-AES-PZCC-FMC-V2-G-V1.pdf \
      "
SRC_URI:append:mz = "\
     file://images/microzed.png \
     file://pdfs/PB-AES-MBCC-FMC-G-V2-Product-Brief.pdf \
     file://pdfs/PB-AES-MBCC-IO-G-V2-Product-Brief.pdf \
     file://pdfs/PB-AES-Z7MB-7Z010-G-V2.pdf \
     file://pdfs/PB-ARDUINO-CC-V2-Product-Brief.pdf \
      "

S = "${WORKDIR}"

do_install() {
       install -d ${D}/home/root/webserver
       install -d ${D}/home/root/webserver/css
       install -d ${D}/home/root/webserver/html
       install -d ${D}/home/root/webserver/images
       install -d ${D}/home/root/webserver/pdfs
       install -m 0755 ${S}/cgi.py ${D}/home/root/webserver
       install -m 0755 ${S}/index.html ${D}/home/root/webserver
       install -m 0755 ${S}/launch_server.sh ${D}/home/root/webserver
       install -m 0755 ${S}/server.py ${D}/home/root/webserver
       install -m 0755 ${S}/stop_server.sh ${D}/home/root/webserver
       install -m 0755 ${S}/css/main.css ${D}/home/root/webserver/css
       install -m 0755 ${S}/html/sata_results.html ${D}/home/root/webserver/html
       install -m 0755 ${S}/html/usb3_results.html ${D}/home/root/webserver/html
       install -m 0755 ${S}/images/Avnet_logo_tagline_rgb.png ${D}/home/root/webserver/images
       install -m 0755 ${S}/images/favicon.ico ${D}/home/root/webserver/images
       install -m 0755 ${S}/images/board.jpg ${D}/home/root/webserver/images
       install -m 0755 ${S}/pdfs/Delkin_Devices_Product_Line.pdf ${D}/home/root/webserver/pdfs
}

do_install:append:uz () {
       install -m 0755 ${S}/images/ultrazed.png ${D}/home/root/webserver/images
}

do_install:append:uz3eg-iocc () {
       install -m 0755 ${S}/pdfs/5043-PB-AES-ZU3EG-1-SOM-G-V3.pdf ${D}/home/root/webserver/pdfs
       install -m 0755 ${S}/pdfs/5080-PB-AES-ZU-IOCC-G-V2e.pdf ${D}/home/root/webserver/pdfs
}

do_install:append:uz3eg-pciec () {
       install -m 0755 ${S}/pdfs/5043-PB-AES-ZU3EG-1-SOM-G-V3.pdf ${D}/home/root/webserver/pdfs
       install -m 0755 ${S}/pdfs/5081-PB-AES-ZU-PCIECC-G-V2d.pdf ${D}/home/root/webserver/pdfs
}

do_install:append:uz7ev-evcc () {
       install -m 0755 ${S}/pdfs/5342-pb-ultrazed-ev-som-v1.pdf ${D}/home/root/webserver/pdfs
       install -m 0755 ${S}/pdfs/5342-pb-ultrazed-ev-starter-kit-v1.pdf ${D}/home/root/webserver/pdfs
}

do_install:append:pz () {
       install -m 0755 ${S}/images/picozed.png ${D}/home/root/webserver/images
       install -m 0755 ${S}/pdfs/5048-PB-PDP-AES-Z7PZ-SOM-G-V2.pdf ${D}/home/root/webserver/pdfs
       install -m 0755 ${S}/pdfs/PB-AES-PZCC-FMC-V2-G-V1.pdf ${D}/home/root/webserver/pdfs
}

do_install:append:mz () {
       install -m 0755 ${S}/images/microzed.png ${D}/home/root/webserver/images
       install -m 0755 ${S}/pdfs/PB-AES-MBCC-FMC-G-V2-Product-Brief.pdf ${D}/home/root/webserver/pdfs
       install -m 0755 ${S}/pdfs/PB-AES-MBCC-IO-G-V2-Product-Brief.pdf ${D}/home/root/webserver/pdfs
       install -m 0755 ${S}/pdfs/PB-AES-Z7MB-7Z010-G-V2.pdf ${D}/home/root/webserver/pdfs
       install -m 0755 ${S}/pdfs/PB-ARDUINO-CC-V2-Product-Brief.pdf ${D}/home/root/webserver/pdfs
}

FILES:${PN} += "/home/root/webserver/cgi.py \
           /home/root/webserver/index.html \
           /home/root/webserver/launch_server.sh \
           /home/root/webserver/server.py \
           /home/root/webserver/stop_server.sh \
           /home/root/webserver/css/main.css \
           /home/root/webserver/html/sata_results.html \
           /home/root/webserver/html/usb3_results.html \
           /home/root/webserver/images/Avnet_logo_tagline_rgb.png \
           /home/root/webserver/images/favicon.ico \
           /home/root/webserver/images/board.jpg \
           /home/root/webserver/pdfs/Delkin_Devices_Product_Line.pdf \
               "

FILES:${PN}:append:uz = "\
           /home/root/webserver/images/ultrazed.png \
               "

FILES:${PN}:append:uz3eg-iocc = "\
           /home/root/webserver/pdfs/5043-PB-AES-ZU3EG-1-SOM-G-V3.pdf \
           /home/root/webserver/pdfs/5080-PB-AES-ZU-IOCC-G-V2e.pdf \
               "

FILES:${PN}:append:uz3eg-pciec = "\
           /home/root/webserver/pdfs/5043-PB-AES-ZU3EG-1-SOM-G-V3.pdf \
           /home/root/webserver/pdfs/5081-PB-AES-ZU-PCIECC-G-V2d.pdf \
               "

FILES:${PN}:append:uz7ev-evcc = "\
           /home/root/webserver/pdfs/5342-pb-ultrazed-ev-som-v1.pdf \
           /home/root/webserver/pdfs/5342-pb-ultrazed-ev-starter-kit-v1.pdf \
               "

FILES:${PN}:append:pz = "\
           /home/root/webserver/images/picozed.png \
           /home/root/webserver/pdfs/5048-PB-PDP-AES-Z7PZ-SOM-G-V2.pdf \
           /home/root/webserver/pdfs/PB-AES-PZCC-FMC-V2-G-V1.pdf \
               "

FILES:${PN}:append:mz = "\
           /home/root/webserver/images/microzed.png \
           /home/root/webserver/pdfs/PB-AES-MBCC-FMC-G-V2-Product-Brief.pdf \
           /home/root/webserver/pdfs/PB-AES-MBCC-IO-G-V2-Product-Brief.pdf \
           /home/root/webserver/pdfs/PB-AES-Z7MB-7Z010-G-V2.pdf \
           /home/root/webserver/pdfs/PB-ARDUINO-CC-V2-Product-Brief.pdf \
               "

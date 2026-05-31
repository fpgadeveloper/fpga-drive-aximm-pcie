# Replace the stock EDF boot.cmd with our own. The stock edf-linux-mmc-boot.cmd
# ext4loads the kernel from partition 2 and boots with U-Boot's control FDT --
# neither matches our Versal layout (esp/storage/root) nor our need to use the
# cortexa72-linux.dtb the PLM loaded to 0x1000. We swap in fpgadrv-boot.cmd
# (loads Image from the esp FAT, boots with the dtb at 0x1000). The recipe's
# do_compile mkimages ${WORKDIR}/edf-linux-mmc-boot.cmd -> boot.scr, so we just
# overwrite that file before it runs (mirrors the recipe's own :zynq prepend).
#
# := captures the bbappend dir at parse time (${THISDIR} is unreliable at task
# time inside a bbappend).
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " file://fpgadrv-boot.cmd"

do_compile:prepend() {
    cp ${WORKDIR}/fpgadrv-boot.cmd ${WORKDIR}/edf-linux-mmc-boot.cmd
}

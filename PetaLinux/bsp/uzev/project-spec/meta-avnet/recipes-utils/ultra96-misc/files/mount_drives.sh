#Mount USB
mkdir /tempusb
mount /dev/sda1 /tempusb
ls -l /tempusb

#Mount eMMC/SD card on Pmod
mount /dev/mmcblk0p1 /mnt
ls -l /mnt



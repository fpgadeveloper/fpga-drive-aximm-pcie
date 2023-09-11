#!/bin/sh

DEV="/dev/"`ls /sys/devices/platform/axi/ff000000.serial/tty/`

# Remove wifi interfaces
ifconfig wlan0 down
ifconfig p2p0 down
rmmod wilc_sdio

sleep 2

modprobe wilc_sdio

echo BT_POWER_UP > /dev/wilc_bt
echo BT_DOWNLOAD_FW > /dev/wilc_bt

sleep 1

stty -F $DEV 115200
stty -F $DEV crtscts

# Initialize the device:
hciattach $DEV -t 10 any 115200 noflow nosleep
sleep 2

#Configure the right BT device:
hciconfig hci0 up

echo "you should now be able to use bluetoothctl to control the bluetooth adapter"

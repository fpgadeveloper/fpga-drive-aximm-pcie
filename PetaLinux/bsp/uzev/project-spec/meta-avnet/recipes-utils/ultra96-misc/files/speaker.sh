# Steps for BT speaker Demo
# Note: this uses Bluetooth Classic, not BLE

BD_ADDR=`cat /sys/class/net/wlan0/address`

#Turn echo of commands on:
set -v
# To turn on BT_REG_ON, which is on EMIO GPIO #0
echo 399 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio399/direction
echo 1 > /sys/class/gpio/gpio399/value
# Set uart0 = 16550 UART in PL = ttyS2 baudrate:
stty -F /dev/ttyS1 115200
stty -F /dev/ttyS1 crtscts
# Initialize the device (you should really pick an unique MAC):
hciattach /dev/ttyS1 -t 10 any 115200 noflow nosleep $BD_ADDR

#Configure the right BT device:
hciconfig hci0 up
pulseaudio --system -D

bluetoothctl
##scan on
##... copy BTMAC, e.g.  04:52:C7:12:87:36 Bose Mini II SoundLink
##scan off
##pair 04:52:C7:12:87:36
##connect 04:52:C7:12:87:36
##quit

#Now copy your .mp3 file to the MiniZed emmc at /mnt/emmc/audio
#Play your file with:
##mpg123 /mnt/emmc/audio/mysong.mp3
set +v
#Above turns echo off

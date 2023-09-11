# ----------------------------------------------------------------------------
#
#        ** **        **          **  ****      **  **********  **********
#       **   **        **        **   ** **     **  **              **
#      **     **        **      **    **  **    **  **              **
#     **       **        **    **     **   **   **  *********       **
#    **         **        **  **      **    **  **  **              **
#   **           **        ****       **     ** **  **              **
#  **  .........  **        **        **      ****  **********      **
#     ...........
#                                     Reach Further
#
# ----------------------------------------------------------------------------
# 
#  This design is the property of Avnet.  Publication of this
#  design is not authorized without written consent from Avnet.
# 
#  Please direct any questions to the UltraZed community support forum:
#     http://www.ultrazed.org/forum
# 
#  Product information is available at:
#     http://www.ultrazed.org/product/ultrazed-EG
# 
#  Disclaimer:
#     Avnet, Inc. makes no warranty for the use of this code or design.
#     This code is provided  "As Is". Avnet, Inc assumes no responsibility for
#     any errors, which may appear in this code, nor does it make a commitment
#     to update the information contained herein. Avnet, Inc specifically
#     disclaims any implied warranties of fitness for a particular purpose.
#                      Copyright(c) 2018 Avnet, Inc.
#                              All rights reserved.
# 
# ----------------------------------------------------------------------------
# 
#  Create Date:         Mar 07, 2018
#  Design Name:         Bring up USB gadget Ethernet interface
#  Module Name:         isb_gadget_ethernet.sh
#  Project Name:        USB gadget Ethernet Setup Script
#  Target Devices:      Xilinx Zynq and Zynq UltraScale+ MPSoC
#  Hardware Boards:     Ultra96-V2
# 
#  Tool versions:       Xilinx Vivado 2020.1
# 
#  Description:         Bring up USB gadget Ethernet interface
# 
#  Dependencies:        
#
#  Revision:            Sep 17, 2020: 1.0 Initial version
# 
# ----------------------------------------------------------------------------
#!/bin/sh

# Script Adapted from http://irq5.io/2016/12/22/raspberry-pi-zero-as-multiple-usb-gadgets/
# https://www.element14.com/community/message/295530/l/re-ultra96-v2-usb-otgdevice-port#295530

cd /sys/kernel/config/usb_gadget/
mkdir -p g
cd g

# Set the idVendor to Linux Foundation
echo 0x1d6b > idVendor  
# Set the idProduct to Multifunction Composite Gadget
echo 0x0104 > idProduct
# Set the bcdDevice to v1.0.0
echo 0x0100 > bcdDevice
# Set the bcdUSB to USB 2.0
echo 0x0200 > bcdUSB

# These settings allow the device to be recognized in Windows
echo 0xEF > bDeviceClass
echo 0x02 > bDeviceSubClass
echo 0x01 > bDeviceProtocol

mkdir -p strings/0x409
echo "0000" > strings/0x409/serialnumber
echo "Avnet"   > strings/0x409/manufacturer
echo "Ultra96-V2 Gadget Ethernet"   > strings/0x409/product

# Setup the OS Descriptors for our RNDIS device to be automatically installed
echo 1  > os_desc/use
echo 0xcd  > os_desc/b_vendor_code
echo MSFT100 > os_desc/qw_sign

# Allow the gadget to be used as a serial device
mkdir -p functions/acm.usb0

# Allow the gadget to be used as a network device
mkdir -p functions/rndis.usb0
echo RNDIS  > functions/rndis.usb0/os_desc/interface.rndis/compatible_id
echo 5162001 > functions/rndis.usb0/os_desc/interface.rndis/sub_compatible_id

# Allow the gadget to be used as a mass storage device
# (currently not enabled in the kernel configuration)
#mkdir -p functions/mass_storage.ms0
#echo /usr/local/share/fatfs > functions/mass_storage.ms0/lun.0/file
#echo 1 > functions/mass_storage.ms0/lun.0/removable

mkdir -p configs/c.1
echo 250 > configs/c.1/MaxPower
if [ ! -e os_desc/c.1 ]; then
ln -s configs/c.1 os_desc/
fi
if [ ! -e configs/c.1/rndis.usb0 ]; then
ln -s functions/rndis.usb0 configs/c.1/
fi
if [ ! -e configs/c.1/acm.usb0 ]; then
ln -s functions/acm.usb0 configs/c.1/
fi
#if [ ! -e configs/c.1/mass_storage.ms0 ]; then
#ln -s functions/mass_storage.ms0 configs/c.1/
#fi

udevadm settle -t 5 || :

# Clear the UDC file if we have been here before
# This avoids errors if we run this script twice 
# and allows us to essentially reset the interface if necessary
str=$(ls /sys/class/udc/)
if [[ $(< ./UDC) != "$str" ]]; then
  # We have not been here before (file does not match $str), so write the UDC file
  # For some unknown reason we need to write, clear, then write the file again
  ls /sys/class/udc/ > ./UDC
  sync
  echo "" > ./UDC
  sync
  ls /sys/class/udc/ > ./UDC
else
  # We have been here before, so clear the UDC file first
  echo "" > ./UDC
  sync
  ls /sys/class/udc/ > ./UDC
  sync
  echo "" > ./UDC
  sync
  ls /sys/class/udc/ > ./UDC
fi

ip=192.168.3.1
echo "**************************************"
echo "Assigned static IP $ip to usb0"
echo "**************************************"
ifconfig usb0 $ip

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
#                      Copyright(c) 2016 Avnet, Inc.
#                              All rights reserved.
# 
# ----------------------------------------------------------------------------
# 
#  Create Date:         Feb 22, 2018
#  Design Name:         Python Webserver Launch Script
#  Module Name:         launch_server.sh
#  Project Name:        Python Webserver Launch Script
#  Target Devices:      Xilinx Zynq and Zynq UltraScale+ MPSoC
#  Hardware Boards:     UltraZed-EG + I/O Carrier
#                       UltraZed-EV + EV Carrier
# 
#  Tool versions:       Xilinx Vivado 2017.3
# 
#  Description:         Python Webserver Launch Script
# 
#  Dependencies:        
#
#  Revision:            Feb 22, 2018: 1.0 Initial version
# 
# ----------------------------------------------------------------------------
#!/bin/sh

cd /home/root/webserver

echo "Export and initialize the GPIO"
source /usr/local/bin/gpio/gpio_common.sh
export_gpio_map

if [ -f ./server.py ]; then
    echo "Start the Python webserver in the background"
    python3 ./server.py &
else
    echo "Set web page location:"
    killall -9 httpd
    httpd -h /home/root/webserver
fi



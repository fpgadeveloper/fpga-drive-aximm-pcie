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
#  Please direct any questions to the community support forum:
#     http://www.ultrazed.org/forum
# 
#  Product information is available at:
#     http://www.ultrazed.org/
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
#  Create Date:         July 25, 2022
#  Design Name:         LED "Blinky" Application Daemon Launcher
#  Module Name:         run-blinky(.sh)
#  Project Name:        LED "Blinky" Application
#  Target Devices:      Xilinx Zynq and Zynq UltraScale+ MPSoC
#  Hardware Boards:     UltraZed-EV + EV Carrier
# 
#  Tool versions:       Xilinx PetaLinux 2022.1
# 
#  Description:         Script to launch "Blinky" LED App
# 
#  Dependencies:        
#
#  Revision:            July 25, 2022: 1.0 Initial version
# 
# ----------------------------------------------------------------------------
#!/bin/sh

DAEMON=/home/root/blinky
#This script launches the application that will blink an LED mapped to
#the Zynq or ZynqMP PS MIO
#In this case the PS LED is mapped to MIO26
source /usr/local/bin/gpio/gpio_common.sh
PS_LED1=$(get_gpio PS_LED1)
DAEMON_OPTS="-g $PS_LED1"

# Show the application banner.
echo " "
echo "*********************************************************************"
echo "***                                                               ***"
echo "***   Avnet UltraZed Out Of Box PetaLinux Build V1.2              ***"
echo "***   The PS LED is mapped to $PS_LED1                            ***"
echo "***                                                               ***"
echo "*********************************************************************"
echo " "

$DAEMON $DAEMON_OPTS

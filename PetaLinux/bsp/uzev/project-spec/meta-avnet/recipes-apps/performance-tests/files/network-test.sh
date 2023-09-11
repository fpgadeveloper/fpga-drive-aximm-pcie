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
#  Create Date:         Mar 04, 2018
#  Design Name:         Network Performance Tests
#  Module Name:         network-test.sh
#  Project Name:        UltraZed-EV EV Carrier SD Boot OOB
#  Target Devices:      Xilinx Zynq UltraScale+ EV MPSoC
#  Hardware Boards:     UltraZed-EV + EV Carrier
# 
#  Tool versions:       Xilinx Vivado 2017.4
# 
#  Description:         Script to run performance tests for 
#                       Ethernet network interface running iperf3
# 
#  Dependencies:        
#
#  Revision:            Mar 04, 2018: 1.0 Initial version
# 
# ----------------------------------------------------------------------------
#!/bin/sh

SLEEP_INTERVAL=5s


## The usual terse usage information:
##
function usage_error(){
	echo >&2
	echo "Performance test utility for Ethernet network interface." >&2
    echo "Usage:  $0 [OPTION]" >&2
    echo "-h      Display this help and exit" >&2
    echo "-i      Ethernet interface to use (usually eth0 or eth1)" >&2
    echo "-l      Local IP address (this device)" >&2
    echo "-m      Test mode <c (client) | s (server)>" >&2
    echo "-r      Remote IP address of network device running iperf3" >&2
    echo "        client or server" >&2
	echo " Eg:    $0 -i eth1 -r 192.168.1.105 -l 192.168.1.5 -m c" >&2
	echo >&2
	exit 1
}

function check_interface(){
    if [ "${ETH_INTERFACE}" != "eth1" ];
    then
        if [ "${ETH_INTERFACE}" != "eth0" ];
        then 
            echo "******************************************************************"
            echo "!!!                                                            !!!"
            echo "!!! No correct Ethernet interface was selected!                !!!"
            echo "!!!                                                            !!!"
            echo "******************************************************************"
            usage_error
        fi
    fi
}

function check_mode(){
    if [ "${TEST_MODE}" != "c" ];
    then
        if [ "${TEST_MODE}" != "s" ];
        then 
            echo "******************************************************************"
            echo "!!!                                                            !!!"
            echo "!!! No correct test mode was selected!                         !!!"
            echo "!!!                                                            !!!"
            echo "******************************************************************"
            usage_error
        fi
    fi
}

function init(){
    # Test if eth1 interface was selected 
    if [ ${ETH_INTERFACE} == "eth1" ];
    then
        # Start the eth1 interface
        echo "Start the ${ETH_INTERFACE} interface..."
        ifconfig ${ETH_INTERFACE} up
        sleep ${SLEEP_INTERVAL}
    fi
    
    # Set a static IP address for the interface
    echo "Set the static IP address for the device ${LOCAL_IP_ADDR}..."
    ifconfig ${ETH_INTERFACE} ${LOCAL_IP_ADDR}
}

function script_intro(){
echo " "
echo "******************************************************************"
echo "***                                                            ***"
echo "***      ****  **      **  ****    **  ********  **********    ***"
echo "***     **  **  **    **   ** **   **  **            **        ***"
echo "***    **    **  **  **    **  **  **  *******       **        ***"
echo "***   **      **  ****     **   ** **  **            **        ***"
echo "***  **  ....  **  **      **    ****  ********      **        ***"
echo "***     ......                                                 ***"
echo "***                                                            ***"
echo "*** This is a simple script to run the iperf3 test application ***"
echo "*** to determine the maximum achievable Ethernet               ***"
echo "*** network bandwidth.                                         ***"
echo "***                                                            ***"
echo "*** More information about iperf3 can be found at              ***"
echo "*** http://software.es.net/iperf/                              ***"
echo "***                                                            ***"
echo "*** Make sure the Ethernet cable is connected to only the      ***"
echo "*** selected interface before continuing!!!                    ***"
echo "*** eth0 == Carrier                                            ***"
echo "*** eth1 == PCIe NIC                                           ***"
echo "***                                                            ***"
echo "*** If running test in CLIENT mode make sure the iperf3 server ***"
echo "*** is started on a network host before continuing!!!          ***"
echo "*** $ iperf3 -s                                                ***"
echo "***                                                            ***"
echo "******************************************************************"
echo " "
}



# START HERE: Non-boilerplate code above should be contained within 
# functions so that at this point simple high level calls can be made to 
# the bigger blocks above.
# Check to see if the correct Ethernet interface was selected.
# If neither eth1 or eth0 were selected then print the usage statement 

while getopts "i:r:l:m:h" opt; 
do
    case ${opt} in
        h)
            usage_error
            ;;
        i)
            ETH_INTERFACE="$OPTARG"
            ;;
        r)
            REMOTE_IP_ADDR="$OPTARG"
            ;;
        l)
            LOCAL_IP_ADDR="$OPTARG"
            ;;
        m)
            TEST_MODE="$OPTARG"
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage_error
            ;;
    esac
done

check_interface

check_mode

script_intro

read -p "Press enter to continue..."

init

sleep ${SLEEP_INTERVAL}

if [ ${TEST_MODE} == "c" ];
then
    # Start the iperf3 test
    echo "Start the iperf3 test as a client connected to the server at IP address ${REMOTE_IP_ADDR}..."
    iperf3 -c ${REMOTE_IP_ADDR} -i 2 -t 30
    exit 0
    
elif [ ${TEST_MODE} == "s" ];
then
    # Start the iperf3 test
    echo "Start the iperf3 test server..."
    iperf3 -s
    exit 0
else
    echo "No such test mode as ${TEST_MODE} or no mode selected.  Exiting..."
    usage_error
fi

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
#  Design Name:         Disk Drive Performance Tests
#  Module Name:         drive-test.sh
#  Project Name:        UltraZed-EV EV Carrier SD Boot OOB
#  Target Devices:      Xilinx Zynq UltraScale+ EV MPSoC
#  Hardware Boards:     UltraZed-EV + EV Carrier
# 
#  Tool versions:       Xilinx Vivado 2017.3
# 
#  Description:         Script to run performance tests for 
#                       block device (/dev/sd<x>) storage media
# 
#  Dependencies:        
#
#  Revision:            Mar 04, 2018: 1.0 Initial version
# 
# ----------------------------------------------------------------------------
#!/bin/sh

SLEEP_INTERVAL=2s
IS_MOUNTED_TEST_RESULT=-1


function cleanup(){
    # Clean up before exiting
    # Cleanup the shrapnel the tests leave behind
    rm -rf /mnt/${BLOCK_DEVICE}/tmp
    rm -rf /mnt/${BLOCK_DEVICE}/test.tmp
    # Don't forget to unmount
    umount /mnt/${BLOCK_DEVICE}
    # Delete the mount point
    rm -rf /mnt/${BLOCK_DEVICE}
}

function init(){
    # Check to see if the device is mounted
    df | grep /dev/${BLOCK_DEVICE} > /dev/null
    IS_MOUNTED_TEST_RESULT=$?
    
    # If it is mounted
    if [ $IS_MOUNTED_TEST_RESULT == "0" ];
    then
        # Then unmount it
        umount /dev/${BLOCK_DEVICE}

    else
        # Device is not mounted.  Test if the mount point exists.
        if [ -e /mnt/${BLOCK_DEVICE} ];
        then
            # If it exists then do nothing
            echo " "
        else
            # It does not exist, so create it
            mkdir /mnt/${BLOCK_DEVICE}
        fi
    fi
    
    # Device has been unmounted or was not already mounted, so do that now
    mount /dev/${BLOCK_DEVICE} /mnt/${BLOCK_DEVICE}

    # Delete evidence of previous tests if it exists
    if [ -e /mnt/${BLOCK_DEVICE}/tmp ];
    then
        rm -rf /mnt/${BLOCK_DEVICE}/tmp
    fi
            
    if [ -e /mnt/${BLOCK_DEVICE}/test.tmp ];
    then
        rm -rf /mnt/${BLOCK_DEVICE}/test.tmp
    fi
}

## The usual terse usage information:
##
function usage_error(){
	echo >&2
	echo "Performance test utility for block device (eg /dev/sda1) storage media." >&2
    echo "Parse the 'dmesg' output to determine the system device the media" >&2
    echo "has been attached to." >&2
    echo "Usage:  $0 [OPTION]" >&2
    echo "-h      Display this help and exit" >&2
    echo "-d      Block device to use (usually sda1 or sdb1)" >&2
	echo "        if the drive is not partitioned this will be sans partition" >&2
    echo "        number (eg. sda or sdb)" >&2
    echo "-t      Test to run <bonnie++ | hdparm | dd>"
    echo "Eg:     $0 -d sda1 -t dd" >&2
	echo >&2
	exit 1
}

function script_intro(){
    echo " "
    echo "******************************************************************"
    echo "***      ****  **      **  ****    **  ********  **********    ***"
    echo "***     **  **  **    **   ** **   **  **            **        ***"
    echo "***    **    **  **  **    **  **  **  *******       **        ***"
    echo "***   **      **  ****     **   ** **  **            **        ***"
    echo "***  **  ....  **  **      **    ****  ********      **        ***"
    echo "***     ......                                                 ***"
    echo "***                                                            ***"
    echo "*** This is a simple script to run the dd, hdparm, and         ***"
    echo "*** bonnie++ test applications to determine the maximum        ***"
    echo "*** maximum achievable read and write performance for SATA     ***"
    echo "*** and USB SSDs and Flash drives.                             ***"
    echo "***                                                            ***"
    echo "*** More information about bonnie++ can be found at            ***"
    echo "*** http://www.coker.com.au/bonnie++/readme.html               ***"
    echo "***                                                            ***"
    echo "*** This test will unmount the drive if it is already mounted! ***"
    echo "***                                                            ***"
    echo "******************************************************************"
    echo " "
}

function dd_test() {
    echo "Use the 'dd'command to test how long it takes to write a 4GB file to the disk."
    echo "time sh -c dd if=/dev/zero of=/mnt/${BLOCK_DEVICE}/test.tmp bs=4k count=1000000 && sync"
    echo " "
    time sh -c "dd if=/dev/zero of=/mnt/${BLOCK_DEVICE}/test.tmp bs=4k count=1000000 && sync"
}

function hdparm_test() {
    echo " "
    echo "Use the 'hdparm' command to test the read times for the disk."
    echo "Run this test a few times and calculate the average."
    echo "hdparm -T -t /dev/${BLOCK_DEVICE}"
    hdparm -T -t /dev/${BLOCK_DEVICE}
    sleep ${SLEEP_INTERVAL}
    hdparm -T -t /dev/${BLOCK_DEVICE}
    sleep ${SLEEP_INTERVAL}
    hdparm -T -t /dev/${BLOCK_DEVICE}
    echo " "
}

function bonnie_test() {
    # Create the tmp folder for the bonnie++ test
    mkdir /mnt/${BLOCK_DEVICE}/tmp

    echo " "
    echo "Use the 'Bonnie++' command to test the time for sequential and random"
    echo "reads and writes for the disk."
    echo "NOTE: This test takes a few minutes, depending on the speed of the disk"
    echo "bonnie++ -d /mnt/${BLOCK_DEVICE}/tmp -r 4096 -n 16 -u root"
    echo " "
    time bonnie++ -d /mnt/${BLOCK_DEVICE}/tmp -r 4096 -n 16 -u root
}

# START HERE: Non-boilerplate code above should be contained within 
# functions so that at this point simple high level calls can be made to 
# the bigger blocks above.
# Check to see if the mass storage block device is enumerated.

while getopts "d:t:h" opt; 
do
    case ${opt} in
        h)
            usage_error
            ;;
        d)
            BLOCK_DEVICE="$OPTARG"
            ;;
        t)
            TEST_TO_RUN="$OPTARG"
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage_error
            ;;
    esac
done

if [ -b /dev/${BLOCK_DEVICE} ];
then

    script_intro
    
    read -p "Press enter to continue..."
    
    # Do some housekeeping
    init
    sleep ${SLEEP_INTERVAL}
    
    # Run the dd tests
    if [ $TEST_TO_RUN == "dd" ]
    then
        dd_test
        sleep ${SLEEP_INTERVAL}
    fi
    
    # Run the hdparm test
    if [ $TEST_TO_RUN == "hdparm" ]
    then
        hdparm_test
        sleep ${SLEEP_INTERVAL}
    fi
    
    # Run the bonnie++ test
    if [ $TEST_TO_RUN == "bonnie++" ]
    then
        bonnie_test
        sleep ${SLEEP_INTERVAL}
    fi
    
    # Clean up before exiting
    # Cleanup the shrapnel the tests leave behind
    cleanup
    
else
    echo "******************************************************************"
    echo " "
    echo "   No Mass Storage Block Device Enumerated!"
    echo "   Make sure the SATA or USB3 drive is connected to the board!"
    echo " "
    echo "******************************************************************"
    usage_error
fi


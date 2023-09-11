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
#  Create Date:         Sep 04, 2018
#  Design Name:         SD Card Performance Tests
#  Module Name:         sd-test.sh
#  Project Name:        PicoZed and UltraZed SD Boot OOB
#  Target Devices:      Xilinx Zynq and Zynq UltraScale+ MPSoC
#  Hardware Boards:     PicoZed and UltraZed SOMs and carriers
# 
#  Tool versions:       Xilinx Vivado 2018.2
# 
#  Description:         Script to run performance tests for 
#                       SD card (/dev/mmcblk<x>p<y>) storage media
# 
#  Dependencies:        
#
#  Revision:            Sep 04, 2018: 1.0 Initial version
# 
# ----------------------------------------------------------------------------


#!/bin/bash

SLEEP_INTERVAL=1s
IS_MOUNTED_TEST_RESULT=-1
#MMC_DEVICE=mmcblk0
#MMC_PART=p1

TEST_FILE=dd_testfile

PRINTF_FORMAT="%8s : %s\n"
CARD_FORMAT="*** Reported SD card size is %3s GB                            ***\n"

function cleanup(){
   # Clean up before exiting
   # Cleanup the shrapnel the tests leave behind
   if [ -e /mnt/${MMC_DEVICE}${MMC_PART}/tmp ];
   then
      rm -rf /mnt/${MMC_DEVICE}${MMC_PART}/tmp
   fi
   
   if [ -e /mnt/${MMC_DEVICE}${MMC_PART}/test.tmp ];
   then
      rm -f /mnt/${MMC_DEVICE}${MMC_PART}/test.tmp
   fi

   if [ -e /mnt/${MMC_DEVICE}${MMC_PART}/${TEST_FILE} ];
   then
      rm -f /mnt/${MMC_DEVICE}${MMC_PART}/${TEST_FILE}
   fi
    
   # Don't forget to unmount
   umount /mnt/${MMC_DEVICE}${MMC_PART}
   # Delete the mount point
   rm -rf /mnt/${MMC_DEVICE}${MMC_PART}
}

function init(){
   # Check to see if the device is mounted
   df | grep /dev/${MMC_DEVICE}${MMC_PART} > /dev/null
   IS_MOUNTED_TEST_RESULT=$?
   
   # If it is mounted
   if [ $IS_MOUNTED_TEST_RESULT == "0" ];
   then
      # Then unmount it
      umount /dev/${MMC_DEVICE}${MMC_PART}

   else
      # Device is not mounted.  Test if the mount point exists.
      if [ -e /mnt/${MMC_DEVICE}${MMC_PART} ];
      then
         # If it exists then do nothing
         echo " "
      else
         # It does not exist, so create it
         mkdir /mnt/${MMC_DEVICE}${MMC_PART}
      fi
   fi
    
   # Device has been unmounted or was not already mounted, so do that now
   mount /dev/${MMC_DEVICE}${MMC_PART} /mnt/${MMC_DEVICE}${MMC_PART} -o rw

   # Delete evidence of previous tests if it exists
   if [ -e /mnt/${MMC_DEVICE}${MMC_PART}/tmp ];
   then
      rm -rf /mnt/${MMC_DEVICE}${MMC_PART}/tmp
   fi
            
   if [ -e /mnt/${MMC_DEVICE}${MMC_PART}/test.tmp ];
   then
      rm -rf /mnt/${MMC_DEVICE}${MMC_PART}/test.tmp
   fi

   if [ -e /mnt/${BLOCK_DEVICE}/${TEST_FILE} ];
   then
      rm -rf /mnt/${BLOCK_DEVICE}/${TEST_FILE}
   fi

   if [ -e /mnt/${BLOCK_DEVICE}/clearcache.tmp ];
   then
      rm -rf /mnt/${BLOCK_DEVICE}/clearcache.tmp
   fi
}

## The usual terse usage information:
##
function usage_error(){
   echo >&2
   echo "Performance test utility for MMC device (eg /dev/mmcblk1p1) storage media." >&2
   echo "Parse the 'dmesg' output to determine the system device the media" >&2
   echo "has been attached to." >&2
   echo "Usage:  $0 [OPTION]" >&2
   echo "-h      Display this help and exit" >&2
   echo "-d      MMC device to use (usually mmcblk0 or mmcblk1)" >&2
   echo "-p      Device partition to use (usually p1 or p2)" >&2
   echo "-t      Test to run <hdparm | dd>"
   echo "Eg:     $0 -d mmcblk0 -p p1 -t dd" >&2
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
   echo "*** This is a simple script to run the dd and hdparm           ***"
   echo "*** test applications to determine the maximum                 ***"
   echo "*** maximum achievable read and write performance for          ***"
   echo "*** SD cards and eMMC devices.                                 ***"
   echo "***                                                            ***"
   echo "*** This test will unmount the drive if it is already mounted! ***"
   echo "***                                                            ***"
   echo "******************************************************************"
   echo " "
}

function get_mmc_size() {
   
   # Calculate the SD card or eMMC device size
   # Fetch the number of sectors on the card
   CARD_SECTORS=$(cat /sys/block/${MMC_DEVICE}/${MMC_DEVICE}${MMC_PART}/size)
   # Fetch the reported block size for the card
   CARD_BS=$(cat /sys/block/${MMC_DEVICE}/queue/logical_block_size)
   # Extract the partition size from the cat output
   # Divide down to get the size in GB
   CARD_SIZE=$(((((((( $CARD_SECTORS * $CARD_BS )) /1000)) /1000)) /1000))

   echo "******************************************************************"
   echo "***                                                            ***"
   printf "$CARD_FORMAT" "$CARD_SIZE"
   echo "***                                                            ***"
   echo "******************************************************************"

   #read -p "Pause here.  Press enter to continue."
}

function dd_test() {
   #echo "Use the 'dd'command to test how long it takes to write a 4GB file to the disk."
   #echo "time sh -c dd if=/dev/zero of=/mnt/${MMC_DEVICE}${MMC_PART}/test.tmp bs=4k count=1000000 && sync"
   #echo " "
   #time sh -c "dd if=/dev/zero of=/mnt/${MMC_DEVICE}${MMC_PART}/test.tmp bs=4k count=1000000 && sync"

   echo "******************************************************************"
   echo "***                                                            ***"
   echo "*** Perform dd WRITE tests using a 1MB and 8MB files           ***"
   #echo "*** Using a 1MB, 8MB, 64MB, 512MB, and 1GB file                ***"
   echo "***                                                            ***"
   echo "******************************************************************"

   # File sizes of       1MB     8MB     64MB     512MB     1GB
   #for TEST_FILE_SIZE in 1048576 8388608 67108864 536870912 1073741824
   for TEST_FILE_SIZE in 1048576 8388608
   do
      echo ""
      echo "***"
      echo "*** Create a ${TEST_FILE_SIZE} byte file"
      echo "***"
      printf "$PRINTF_FORMAT" 'block size' 'transfer rate'
   
      # Block sizes of  1K   2K   4K   8K   16K   32K   64K   128K   256K   512K   1M      2M      4M      8M      16M      32M      64M
      #for BLOCK_SIZE in 1024 2048 4096 8192 16384 32768 65536 131072 262144 524288 1048576 2097152 4194304 8388608 16777216 33554432 67108864
      for BLOCK_SIZE in 1024 2048 4096 8192 16384 32768 65536 131072 262144 524288 1048576
      do
         # Calculate number of segments required to copy
         COUNT=$(($TEST_FILE_SIZE / $BLOCK_SIZE))
      
         if [ $COUNT -le 0 ];
         then
            echo "Block size of $BLOCK_SIZE estimated to require $COUNT blocks, aborting further tests."
            break
         fi
      
         # Clear kernel cache to ensure more accurate test
         [ $EUID -eq 0 ] && [ -e /proc/sys/vm/drop_caches ] && echo 3 > /proc/sys/vm/drop_caches >/dev/null

      
         # Create a test file with the specified block size
         DD_RESULT=$(dd if=/dev/zero of=/mnt/${MMC_DEVICE}${MMC_PART}/${TEST_FILE} bs=$BLOCK_SIZE count=$COUNT conv=fsync 2>&1 1>/dev/null)
         #DD_RESULT=$(time sh -c "dd if=/dev/zero of=/mnt/${MMC_DEVICE}${MMC_PART}/${TEST_FILE} bs=$BLOCK_SIZE count=$COUNT &&sync")
   
         # Flush the kernel filesystem buffers
         sync
         
         # Extract the transfer rate from dd's STDERR output
         #TRANSFER_RATE=$(echo $DD_RESULT | \grep --only-matching -E '[0-9.]+ ([MGk]?B|bytes)/s(ec)?')
         TRANSFER_RATE=$(echo $DD_RESULT | \grep -o -E '[0-9.]+ ([MGk]?B|bytes)/s(ec)?')
         #TRANSFER_RATE=$(echo $DD_RESULT | \grep -o -E '([1-9][0-9]{0,2})+ ([MGk]?B|bytes)/s(ec)?')
   
         # Delete the test file 
         rm /mnt/${MMC_DEVICE}${MMC_PART}/${TEST_FILE}; 
         
         # Output the result
         printf "$PRINTF_FORMAT" "$BLOCK_SIZE" "$TRANSFER_RATE"

         sleep ${SLEEP_INTERVAL}
      done
   done

   # Delete the test file
   rm -f /mnt/${MMC_DEVICE}${MMC_PART}/${TEST_FILE}; 
    
   echo ""
   echo "******************************************************************"
   echo "***                                                            ***"
   echo "*** Perform dd READ tests using a 8MB file                     ***"
   echo "***                                                            ***"
   echo "******************************************************************"
   echo " "
   echo "This test uses the buffer cache."
   echo "The cache is filled and then the card is read."
   echo "Because the test first fills the cache and then does the read,"
   echo "This test best shows the MMC device's actual speed."
   echo " "
   echo "Before the read test for each block size a large file"
   echo "approximately the size of the system RAM will be written to"
   echo "the MMC device."
   echo " "
   echo "BE SURE THE MMC DEVICE PARTITION HAS AT LEAST 1GB OF FREE SPACE."
   echo " "
   echo "This large file is written because we need to flush the file cache."
   echo "If we don’t do this the 8MB test file will be partially in RAM"
   echo "and therefore the read test will not be completely read from disk."
   echo " "
   
   TEST_FILE_SIZE=8388608
   
   # Write a 8MB file for the read tests (131072 block size * 64 blocks = 8388608 bytes = 8MB)
   dd if=/dev/zero of=/mnt/${MMC_DEVICE}${MMC_PART}/${TEST_FILE} bs=131072 count=64 > /dev/null 2>&1
   sync
   
   printf "$PRINTF_FORMAT" 'block size' 'transfer rate'
   
   # Block sizes of  1K   2K   4K   8K   16K   32K   64K   128K   256K   512K   1M      2M      4M      8M
   for BLOCK_SIZE in 1024 2048 4096 8192 16384 32768 65536 131072 262144 524288 1048576 2097152 4194304 8388608 
   #for BLOCK_SIZE in 1024 2048 4096 8192 16384 32768 65536 131072
   do
      # Calculate number of segments required to copy
      COUNT=$(($TEST_FILE_SIZE / $BLOCK_SIZE))
   
      if [ $COUNT -le 0 ];
      then
         echo "Block size of $BLOCK_SIZE estimated to require $COUNT blocks, aborting further tests."
         break
      fi
   
      # Clear kernel cache to ensure more accurate test
      [ $EUID -eq 0 ] && [ -e /proc/sys/vm/drop_caches ] && echo 3 > /proc/sys/vm/drop_caches >/dev/null
   
      # Before we do the read test we need to flush the file cache by
      # writing another file which is about the size of the RAM
      # installed on the test system. If we don’t do this the 8MB test file
      # we just created will be partially in RAM and therefore
      # the read test will not be completely read from disk
      # Write a ~2GB file to use for the read tests
      dd if=/dev/zero of=/mnt/${MMC_DEVICE}${MMC_PART}/clearcache.tmp bs=131072 count=16372 > /dev/null 2>&1

      #DD_RESULT=$(dd if=/mnt/${MMC_DEVICE}${MMC_PART}/${TEST_FILE} of=/dev/null bs=$BLOCK_SIZE count=$COUNT iflag=direct 2>&1 1>/dev/null)
      DD_RESULT=$(dd if=/mnt/${MMC_DEVICE}${MMC_PART}/${TEST_FILE} of=/dev/null bs=$BLOCK_SIZE count=$COUNT 2>&1 1>/dev/null)
      TRANSFER_RATE=$(echo $DD_RESULT | \grep -o -E '[0-9.]+ ([MGk]?B|bytes)/s(ec)?')

      # Output the result
      printf "$PRINTF_FORMAT" "$BLOCK_SIZE" "$TRANSFER_RATE"
      
      sleep ${SLEEP_INTERVAL}

      # Delete the file we wrote to fill the RAM and force the test file read from the SD card
      rm -f /mnt/${MMC_DEVICE}${MMC_PART}/clearcache.tmp 
      
   done
    
   # Delete the test file
   rm -f /mnt/${MMC_DEVICE}${MMC_PART}/${TEST_FILE}; 
}

function hdparm_test() {
   echo ""
   echo "******************************************************************"
   echo "***                                                            ***"
   echo "*** Perform hdparm READ tests                                  ***"
   echo "***                                                            ***"
   echo "******************************************************************"
   echo " "
   echo "Use the 'hdparm' command to test the read times for the disk."
   echo "Run this test a few times and calculate the average."
   echo "hdparm -T -t /dev/${MMC_DEVICE}${MMC_PART}"
    
   hdparm -T -t /dev/${MMC_DEVICE}${MMC_PART}
   sleep ${SLEEP_INTERVAL}
   hdparm -T -t /dev/${MMC_DEVICE}${MMC_PART}
   sleep ${SLEEP_INTERVAL}
   hdparm -T -t /dev/${MMC_DEVICE}${MMC_PART}
   echo " "
}

# START HERE: Non-boilerplate code above should be contained within 
# functions so that at this point simple high level calls can be made to 
# the bigger blocks above.
# Check to see if the mass storage block device is enumerated.

while getopts "d:p:t:h" opt; 
do
   case ${opt} in
      h)
         usage_error
         ;;
      d)
         MMC_DEVICE="$OPTARG"
         ;;
      p)
         MMC_PART="$OPTARG"
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

if [ -b /dev/${MMC_DEVICE}${MMC_PART} ];
then

   script_intro

   get_mmc_size
    
   read -p "Press enter to continue..."
    
   # Do some housekeeping
   init
   sleep ${SLEEP_INTERVAL}
   #read -p "Pause here.  Press enter to continue."

   if [ $EUID -ne 0 ]; 
   then
      echo "NOTE: Kernel cache will not be cleared between tests without sudo."
      echo "This will likely cause inaccurate results." 1>&2
   fi


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
    
    # Clean up before exiting
    # Cleanup the shrapnel the tests leave behind
    cleanup
    
else
    echo "******************************************************************"
    echo " "
    echo "   No Mass Storage Block Device Enumerated!"
    echo "   Make sure the SD card or eMMC is connected to the board!"
    echo " "
    echo "******************************************************************"
    usage_error
fi


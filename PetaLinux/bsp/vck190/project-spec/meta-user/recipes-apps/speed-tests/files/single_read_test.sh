#!/bin/bash
# Opsero Electronic Design Inc.
# SSD read speed test script

# Check if the mount point argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <mount_point>"
    exit 1
fi

MOUNT_POINT1="${1%/}"

# Parameters
DATA_SIZE_MB=4000   # Total data size in MB (4 GB)
BLOCK_SIZE=4M       # Block size
COUNT=1000          # Number of blocks

# Test single SSD read speed
echo "Single SSD Read:"
echo "  - Data:  ${DATA_SIZE_MB} MBytes"

# Measure time using the 'time' command
readcmd1="dd if=$MOUNT_POINT1/test.img of=/dev/zero bs=$BLOCK_SIZE count=$COUNT iflag=direct > /dev/null"
delay=$( { time -p bash -c "$readcmd1; sync" 2>&1; } 2>&1 )

# Parse out the real time in seconds
real_time=$(echo "$delay" | grep "real" | awk '{print $2}')

# Calculate speed
speed=$(dc -e "$DATA_SIZE_MB $real_time / p")

# Display results
echo "  - Delay: ${real_time} seconds"
echo "  - Speed: ${speed} MBytes/s"

# Cleanup
rm -f "$MOUNT_POINT/test.img"


#!/bin/bash
# Opsero Electronic Design Inc.
# Dual SSD write speed test script

# Check if the mount point argument is provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <mount_point1> <mount_point2>"
    exit 1
fi

MOUNT_POINT1="${1%/}"
MOUNT_POINT2="${2%/}"

# Parameters
DATA_SIZE_MB=8000   # Total data size in MB
BLOCK_SIZE=4M       # Block size
COUNT=1000          # Number of blocks

# Test single SSD write speed
echo "Dual SSD Write:"
echo "  - Data:  ${DATA_SIZE_MB} MBytes"

# Measure time using the 'time' command
writecmd1="dd if=/dev/zero of=$MOUNT_POINT1/test.img bs=$BLOCK_SIZE count=$COUNT oflag=direct > /dev/null"
writecmd2="dd if=/dev/zero of=$MOUNT_POINT2/test.img bs=$BLOCK_SIZE count=$COUNT oflag=direct > /dev/null"
delay=$( { time -p bash -c "$writecmd1 & $writecmd2; wait; sync" 2>&1; } 2>&1 )

# Parse out the real time in seconds
real_time=$(echo "$delay" | grep "real" | awk '{print $2}')

# Calculate speed
speed=$(dc -e "$DATA_SIZE_MB $real_time / p")

# Display results
echo "  - Delay: ${real_time} seconds"
echo "  - Speed: ${speed} MBytes/s"


#!/bin/sh

source /etc/profile

FILE="/home/root/test.ts"

sleep 1

#gst-launch-1.0 uridecodebin uri="file://${FILE}" ! queue max-size-bytes=0 ! kmssink bus-id="b0050000.v_mix" plane-id=36
gst-launch-1.0 multifilesrc location=${FILE} loop=true ! decodebin ! queue max-size-bytes=0 ! kmssink bus-id="b0050000.v_mix" plane-id=36

#!/bin/sh

source /etc/profile

MEDIA_CTL_DEV="/dev/media1"
VIDEO_DEV="/dev/video4"

systemctl stop xserver-nodm

# Adjust alpha instead of killing x11
modetest-hdmi -w 42:alpha:0

media-ctl -d $MEDIA_CTL_DEV -V '"b0000000.v_proc_ss":0 [fmt:RBG888_1X24/3840x2160 field:none]'
media-ctl -d $MEDIA_CTL_DEV -V '"b0000000.v_proc_ss":1 [fmt:UYVY8_1X16/3840x2160 field:none]'

sleep 1

gst-launch-1.0 -v  v4l2src device="${VIDEO_DEV}" ! "video/x-raw, framerate=60/1" ! kmssink bus-id="b0050000.v_mix" plane-id=34 sync=false can-scale=false

modetest-hdmi -w 42:alpha:256

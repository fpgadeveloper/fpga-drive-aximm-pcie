#!/bin/sh

source /etc/profile

MEDIA_CTL_DEV="/dev/media1"
VIDEO_DEV="/dev/video4"

FILE="./test.ts"

media-ctl -d $MEDIA_CTL_DEV -V '"b0000000.v_proc_ss":0 [fmt:RBG888_1X24/3840x2160 field:none]'
media-ctl -d $MEDIA_CTL_DEV -V '"b0000000.v_proc_ss":1 [fmt:VYYUYY8_1X24/3840x2160 field:none]'

sleep 1

gst-launch-1.0 v4l2src device="${VIDEO_DEV}" io-mode=4 num-buffers=3600 ! video/x-raw, format=NV12,width=3840,height=2160,framerate=60/1 ! \
omxh265enc qp-mode=auto gop-mode=basic gop-length=60 b-frames=0 target-bitrate=60000 num-slices=8 control-rate=constant prefetch-buffer=true \
low-bandwidth=false filler-data=true cpb-size=1000 initial-delay=500 ! queue ! video/x-h265, profile=main, alignment=au ! \
mpegtsmux alignment=7 name=mux ! filesink location="${FILE}"

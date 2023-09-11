#! /bin/sh -e
WPA_DAEMON="/usr/sbin/wpa_supplicant"
CONF_FOLDER="/usr/share/wpa_ap"
WPA_OPTION="-c $CONF_FOLDER/wpa_ap_actual.conf  -ip2p0 "
WPA_PID="/var/run/wpa_p2p0.pid"
SSD_OPTIONS="--quiet --pidfile $WPA_PID --exec $WPA_DAEMON -- $WPA_OPTION"

do_start() {
  #Load the kernel module for the WILC3000 WiFi 
  modprobe wilc-sdio

  #The WILC3000 supports 2 interfaces
  #--p2p0 for use as an access point
  #--wlan0 for use as an WLAN node

  while ! ip a show wlan0 > /dev/null 2>&1
  do
      sleep 1
  done

  # get phyname
  phyname=`iw list | grep Wiphy | awk '{print $2}'`

  #Create a new managed mode interface p2p0 to run AP
  iw phy $phyname interface add p2p0 type managed

  # To retrieve the mac address, we have to turn the interface up
  ifconfig p2p0 up

  hid=$(ifconfig -a | grep p2p0 | sed "s,p2p0.*HWaddr \(.*\),\1," | tr -d ": ")

  ip=192.168.2.1

  sed "s,Ultra96,Ultra96-V2_$hid," $CONF_FOLDER/wpa_ap.conf > $CONF_FOLDER/wpa_ap_actual.conf

  ifconfig p2p0 down

  sleep 2
  
  start-stop-daemon --start --background --make-pidfile $SSD_OPTIONS
  sleep 1

  ifconfig p2p0 $ip

  ifup wlan0

  touch /var/lib/misc/udhcpd.leases
  udhcpd $CONF_FOLDER/udhcpd.conf
}

do_stop() {
  pkill udhcpd

  # keep leases
  #rm /var/lib/misc/udhcpd.leases

  start-stop-daemon --stop --quiet --pidfile $WPA_PID
  rm $CONF_FOLDER/wpa_ap_actual.conf
  rmmod wilc_sdio
}

case "$1" in
  start)
    echo -n "Starting Ultra96 AP setup daemon... "
    do_start
    echo "done."
    ;;
  stop)
    echo -n "Stopping Ultra96 AP setup daemon..."
    do_stop
    echo "done."
    ;;
  *)
    echo "Usage: /etc/init.d/ultra96-ap-setup.sh {start|stop}"
    exit 1
esac

exit 0


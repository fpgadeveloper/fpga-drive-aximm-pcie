# Stop Connman
/etc/init.d/connman stop

# Stop running wifi-related processes
ifdown wlan0
ifconfig p2p0 down
pkill wpa
pkill udhcp

sleep 1

# Copy configuration file
cp /home/root/wpa_supplicant.conf /etc/

# Restart wlan0
ifup wlan0

# Get IP address
sleep 1
udhcpc -i wlan0

# Setup DNS
echo "nameserver 8.8.8.8" > /etc/resolv.conf

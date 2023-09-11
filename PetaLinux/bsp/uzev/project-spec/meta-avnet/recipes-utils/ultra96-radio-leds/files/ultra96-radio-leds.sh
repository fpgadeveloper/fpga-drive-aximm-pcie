#!/bin/sh -e

LED_ON=1
LED_OFF=0

value_arg=$1
value=$LED_OFF
# Check whether on or off
if [ "$value_arg" == "On" ]; then
	value=$LED_ON

elif [ "$value_arg" == "Off" ]; then
	value=$LED_OFF
else 
	echo "Error: Invalid On/Off parameter. Usage 'ultra96-radio-leds.sh On' or 'ultra96-radio-leds.sh Off'"
	exit 1
fi

source /usr/local/bin/gpio/gpio_common.sh

BT_LED=$(get_gpio BT_LED)
WIFI_LED=$(get_gpio WIFI_LED)

echo "   WIFI LED GPIO = $WIFI_LED"
echo "   BT   LED GPIO = $BT_LED"

if [ -z "$BT_LED" ]; then
	echo "ERROR: /etc/init.d/ultra96-radio-leds.sh : Could not find axi gpio device with base address 0xa0050000 !"
	exit 1
fi

# Set their direction to output
# Turn each of the LEDs
export_gpio $WIFI_LED out $value
export_gpio $BT_LED out $value

# Release the sysfs GPIOs
unexport_gpio $WIFI_LED
unexport_gpio $BT_LED

exit 0

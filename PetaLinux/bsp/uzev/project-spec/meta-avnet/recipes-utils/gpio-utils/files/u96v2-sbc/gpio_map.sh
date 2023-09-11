#!/bin/sh

source /usr/local/bin/gpio/gpio_common.sh

BASE_A0050000=$(get_gpiochip_base a0050000)
BASE_ZYNQMP_GPIO=$(get_gpiochip_base zynqmp_gpio)

cat > $GPIO_CONF <<EOF
WIFI_LED:$((BASE_A0050000)):out:0
BT_LED:$((BASE_A0050000 + 1)):out:0
SW_4:$((BASE_ZYNQMP_GPIO + 23)):in
EOF

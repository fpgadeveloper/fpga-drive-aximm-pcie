#!/bin/sh

source /usr/local/bin/gpio/gpio_common.sh

BASE_ZYNQ_GPIO=$(get_gpiochip_base zynq_gpio)

cat > $GPIO_CONF <<EOF
PL_LED1:$((BASE_ZYNQ_GPIO + 47)):out:0
SW_1:$((BASE_ZYNQ_GPIO + 51)):in
EOF

#!/bin/sh

source /usr/local/bin/gpio/gpio_common.sh

BASE_41200000=$(get_gpiochip_base 41200000)
BASE_41210000=$(get_gpiochip_base 41210000)
BASE_ZYNQ_GPIO=$(get_gpiochip_base zynq_gpio)

cat > $GPIO_CONF <<EOF
PL_LED1:$((BASE_41200000)):out:1
PS_LED1:$((BASE_ZYNQ_GPIO + 47)):out:1
PS_LED2:$((BASE_ZYNQ_GPIO + 50)):out:1
SW1:$((BASE_41210000)):in
SW6:$((BASE_ZYNQ_GPIO + 51)):in
EOF

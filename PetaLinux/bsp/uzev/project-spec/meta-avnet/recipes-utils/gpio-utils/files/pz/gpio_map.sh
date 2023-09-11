#!/bin/sh

source /usr/local/bin/gpio/gpio_common.sh

BASE_41200000=$(get_gpiochip_base 41200000)
BASE_41210000=$(get_gpiochip_base 41210000)
BASE_ZYNQ_GPIO=$(get_gpiochip_base zynq_gpio)


cat > $GPIO_CONF <<EOF
SW1:$((BASE_41210000)):in
SW2:$((BASE_41210000 + 3)):in
SW3:$((BASE_41210000 + 2)):in
SW4:$((BASE_41210000 + 4)):in
SW5:$((BASE_41210000 + 1)):in
SW6:$((BASE_ZYNQ_GPIO + 51)):in
PS_LED1:$((BASE_ZYNQ_GPIO + 47)):out:1
PS_LED2:$((BASE_ZYNQ_GPIO + 50)):out:1
EOF

for i in $(seq 4); do
    echo PL_LED${i}:$((BASE_41200000 + i - 1)):out:1 >> $GPIO_CONF
done

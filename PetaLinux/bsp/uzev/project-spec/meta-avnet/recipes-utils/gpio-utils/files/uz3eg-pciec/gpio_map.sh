#!/bin/sh

source /usr/local/bin/gpio/gpio_common.sh

BASE_80000000=$(get_gpiochip_base 80000000)
BASE_80010000=$(get_gpiochip_base 80010000)
BASE_80020000=$(get_gpiochip_base 80020000)
BASE_ZYNQMP_GPIO=$(get_gpiochip_base zynqmp_gpio)

cat > $GPIO_CONF <<EOF
PS_LED1:$((BASE_ZYNQMP_GPIO + 26)):out:1
SW2:$((BASE_80020000 + 1)):in
SW3:$((BASE_80020000)):in
SW4:$((BASE_80020000 + 2)):in
EOF

for i in $(seq 8); do
    echo PL_LED$i:$((BASE_80010000 + i - 1)):out:1 >> $GPIO_CONF
done

for i in $(seq 8); do
    echo SW5_$i:$((BASE_80000000 + i - 1)):in >> $GPIO_CONF
done



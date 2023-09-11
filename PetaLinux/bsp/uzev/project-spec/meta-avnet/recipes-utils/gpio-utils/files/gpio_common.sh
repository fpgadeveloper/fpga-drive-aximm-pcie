#!/bin/sh

GPIO_PATH=/sys/class/gpio
GPIO_CONF=/etc/gpio.conf

get_gpiochip_base() {
    label=$1
    # find the gpio base
    for gpiochip in `ls $GPIO_PATH | grep gpiochip`; do
        if [[ "$(cat $GPIO_PATH/$gpiochip/label)" == *$label* ]]; then
            cat $GPIO_PATH/$gpiochip/base
            return
        fi
    done

    return 1
}

export_gpio() {
    gpio=$1
    direction=$2
    value=$3
    [ -d $GPIO_PATH/gpio$gpio ] || echo $gpio > $GPIO_PATH/export
    echo $direction > $GPIO_PATH/gpio$gpio/direction
    if [ "$direction" = "out" ]; then
        echo $value > $GPIO_PATH/gpio$gpio/value
    fi
}

unexport_gpio() {
    gpio=$1
    [ -d $GPIO_PATH/gpio$gpio ] && echo $gpio > $GPIO_PATH/unexport
}

export_gpio_map() {
    while IFS=: read -r label gpio direction value; do
        export_gpio $gpio $direction $value
    done < $GPIO_CONF
}

unexport_gpio_map() {
    while IFS=: read -r label gpio direction value; do
        unexport_gpio $gpio $direction $value
    done < $GPIO_CONF
}

get_gpio() {
    name=$1
    grep ^$name: $GPIO_CONF | awk -F: '{print $2}'
}

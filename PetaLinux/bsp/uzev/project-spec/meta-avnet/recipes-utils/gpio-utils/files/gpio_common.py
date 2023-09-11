from dataclasses import dataclass
from typing import Optional

GPIO_CONF = "/etc/gpio.conf"

@dataclass
class Gpio:
    gpio: int
    direction: int
    default_value: Optional[int] = None


gpio_map = {}
with open(GPIO_CONF) as f:
    for line in f.readlines():
        # gpios uses ':' as delimeter
        fields = line.split(':')
        name = fields[0]
        gpio = fields[1]
        direction = fields[2]
        default_value = fields[3] if direction == "out" else None
        gpio_map[name] = Gpio(gpio, direction, default_value)

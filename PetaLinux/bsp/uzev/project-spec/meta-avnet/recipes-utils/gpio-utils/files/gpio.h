#ifndef GPIO_FILE_H
#define GPIO_FILE_H

/* c++ api to get gpio number by name */
/* gpios are read from GPIO_CONF */
/* GPIO_CONF is generated on boot by reading gpio chip bases and applying gpio specific offsets */
int get_gpio_cpp(const char *gpio);

/* c api to get gpio number by name */
/* gpios are read from GPIO_CONF */
/* GPIO_CONF is generated on boot by reading gpio chip bases and applying gpio specific offsets */

int get_gpio_c(const char *gpio);
#endif

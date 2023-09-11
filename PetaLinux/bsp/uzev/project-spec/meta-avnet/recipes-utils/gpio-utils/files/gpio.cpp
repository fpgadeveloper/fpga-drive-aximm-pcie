// Expose c/c++ api to get gpios by name

#include <iostream>
#include <fstream>
#include <string>

#define GPIO_CONF "/etc/gpio.conf"
#define DELIMITER ":"

int get_gpio_cpp(const char *gpio) {
    std::ifstream file(GPIO_CONF);
    std::string line;
    while (std::getline(file, line)) {
        if (!line.substr(0, line.find(DELIMITER)).compare(gpio)) {
            line.erase(0, line.find(DELIMITER) + 1);
            try {
                return std::stoi(line.substr(0, line.find(DELIMITER)));
            } catch(const std::invalid_argument& ia) {
                return -1;
            }
        }
    }
    return -1;
}

extern "C" int get_gpio_c(const char *gpio) {
    return get_gpio_cpp(gpio);
}

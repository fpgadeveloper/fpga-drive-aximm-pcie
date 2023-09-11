//----------------------------------------------------------------------------
//      _____
//     *     *
//    *____   *____
//   * *===*   *==*
//  *___*===*___**  AVNET
//       *======*
//        *====*
//----------------------------------------------------------------------------
//
// This design is the property of Avnet.  Publication of this
// design is not authorized without written consent from Avnet.
//
// Please direct any questions to the UltraZed community support forum:
//    http://www.ultrazed.org/forum
//
// Product information is available at:
//    http://www.ultrazed.org/product/ultrazed-EG
//
// Disclaimer:
//    Avnet, Inc. makes no warranty for the use of this code or design.
//    This code is provided  "As Is". Avnet, Inc assumes no responsibility for
//    any errors, which may appear in this code, nor does it make a commitment
//    to update the information contained herein. Avnet, Inc specifically
//    disclaims any implied warranties of fitness for a particular purpose.
//                     Copyright(c) 2016 Avnet, Inc.
//                             All rights reserved.
//
//----------------------------------------------------------------------------
//
// Create Date:         Nov 03, 2016
// Design Name:         PS LED blink application for UltraZed-EG Carriers
// Module Name:         linux_ps_led_blink.c
// Project Name:        PS LED blink application for UltraZed-EG Carriers
// Target Devices:      Xilinx Zynq UltraScale MPSoC
// Hardware Boards:     UltraZed-EG, UltraZed-EG IO Carrier
//
// Tool versions:       Xilinx Vivado 2016.2
//
// Description:         Single PS LED blink application for Linux.
//
// Dependencies:
//
// Revision:            Nov 03, 2016: 1.00 Initial version
//                      Nov 01, 2019: 1.01 Update for PetaLinux 2019.1
//
//----------------------------------------------------------------------------


#include <fcntl.h>
#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <gpio/gpio.h>

/* Version information for this build. */
#define APP_MAJOR_VERSION              1
#define APP_MINOR_VERSION              1

/* String formats used to build the file name path to specific GPIO
 * instances. */
#define FILE_FORMAT_GPIO_PATH          "/sys/class/gpio"
#define FILE_FORMAT_GPIO_EXPORT        "/export"
#define FILE_FORMAT_GPIO_DIRECTION     "/direction"
#define FILE_FORMAT_GPIO_VALUE         "/value"

/* The GPIO_KERNEL_OFFSET is the offset that is used to reach the GPIOs
 * that are controlled by the GPIO controller on the device.  For a Zynq-7000
 * device, this usually is used for the GPIO controller to control user
 * controls connected via EMIO ports.  This has it's own separate definition
 * because sometimes it changes based upon the whims of the kernel
 * maintainers.  So far, it has changed on me at least twice and it more
 * likely than not bound to change someday after this code is released.
 */

static int blink_state = 1;
static int verbose = 0;

/* This application executable name. */
static const char* program_name;

/* Description of long options for getopt_long. */
static const struct option long_options[] = {
    { "debug",      0, NULL, 'd' },
    { "help",       0, NULL, 'h' },
    { "interval",   1, NULL, 'i' },
    { "gpio",       1, NULL, 'g' },
    { "version",    0, NULL, 'v' },
};

/* Description of the short options for getopt_long. */
static const char* const short_options = "dhi:g:v";

/* Usage summary test. */
static const char* const usage_template = 
"    Usage: %s [ options ]\n"
"        -d, --debug              Print verbose debug messages.\n"
"        -h, --help               Print this help information.\n"
"        -i, --interval <NUMBER>  Use <NUMBER> * 0.1 seconds for LED blink.\n"
"        -g, --gpio <NUMBER>      Use <NUMBER> for the LED blinking.\n"
"        -v, --version            Print appication version information.\n";

static void print_usage(int is_error)
{
    fprintf(is_error ? stderr : stdout, usage_template, program_name);
    exit(is_error ? 1 : 0);
}

static void print_version(void)
{
    printf("    %s - v%d.%d\n", program_name, APP_MAJOR_VERSION, APP_MINOR_VERSION);
    exit(0);
}

int set_next_blink_pattern(int user_led)
{
    const int char_buf_size = 80;
    char gpio_setting[5];
    int test_result = 0;
    char formatted_file_name[char_buf_size];

    FILE  *fp_led;

    // Open the gpio value properties so that they can be read/written.
    test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_VALUE, user_led);
    if ((test_result < 0) ||
        (test_result == (char_buf_size - 1)))
    {
        printf("Error formatting string, check the GPIO specified\r\n");
        printf("%s", formatted_file_name);
        return -1;
    }
    fp_led = fopen(formatted_file_name, "r+");

    // Write next blink pattern to LEDs.
    if (blink_state == 1)
    {
        // Now turn the specified LED ON.
        strcpy(gpio_setting, "1");

        // Next state will be OFF.		
        blink_state = 0;
    }
    else
    {
        // Now turn all LEDs OFF.
        strcpy(gpio_setting, "0");

        // Next state will be ON.
        blink_state = 1;
    }
    fwrite(&gpio_setting, sizeof(char), 1, fp_led);
    fflush(fp_led);

    // This test always passes since it requires user interaction.
    test_result = 0;

    // Close the GPIO value property files.
    fclose(fp_led);

    return test_result;
}

int main(int arg_count, char* arg_variables[])
{
    char gpio_setting[5];
    int next_option = 0;
    int test_result = 0;
    int user_interval = 1;
    int user_led = 0;
    const int char_buf_size = 80;
    char formatted_file_name[char_buf_size];

    FILE  *fp;

    /* Extract the command line arguments and options. */
    program_name = arg_variables[0];

    /* Don't print any extra messages. */
    verbose = 0;

    /* Parse options and arguments. */
    do
    {
        next_option = getopt_long(arg_count, arg_variables, short_options, long_options, NULL);

        switch (next_option)
        {
            case 'd':
            {
                /* User specified -d or --debug. */
                verbose = 1;
                break;
            }
            case 'h':
            {
                /* User specified -h or --help. */
                print_usage(0);
                break;
            }
            case 'i':
            {
                /* User specified -i or --interval. */
                sscanf(optarg, "%d", &user_interval);
                break;
            }
            case 'g':
            {
                /* User specified -g or --gpio. */
                sscanf(optarg, "%d", &user_led);
                break;
            }
            case 'v':
            {
                /* User specified -v or --version. */
                print_version();
                break;
            }
            case '?':
            {
                /* User specified an option that is not recognized. */
                print_usage(1);
                break;
            }
            case -1:
            {
                /* Done with options. */
                break;
            }
            default:
            {
                /* Something went wrong parsing command line options. */
                print_usage(1);
                abort();
            }
        }
    }
    while (next_option != -1);

    // Display the lab name in the application banner.
    if (verbose)
    {
        printf("*********************************************************\n");
        printf("*                                                       *\n");
        printf("*   UltraZed PS LED Blink Demo Application              *\n");
        printf("*                                                       *\n");
        printf("*********************************************************\n");
    }

    // Open the export file and write the PSGPIO number for each Pmod GPIO
    // signal to the Linux sysfs GPIO export property, then close the file.
    fp = fopen(FILE_FORMAT_GPIO_PATH FILE_FORMAT_GPIO_EXPORT, "w");
    if (fp == NULL)
    {
        printf("Error opening /sys/class/gpio/export node\n");
    }
    else
    {
        // Set the value property for the export to the GPIO number 
        // for the user specified LED.
        snprintf(gpio_setting, 4, "%d", user_led);
        fwrite(&gpio_setting, sizeof(char), 3, fp);
        fflush(fp);
        fclose(fp);
    }

    // Check the direction property of the PSGPIO number for the user 
    // specified LED.
    test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION, user_led);
    if ((test_result < 0) ||
        (test_result == (char_buf_size - 1)))
    {
        printf("Error formatting string, check the GPIO specified\r\n");
        printf("%s", formatted_file_name);
        return -1;
    }

    fp = fopen(formatted_file_name, "r+");
    if (fp == NULL)
    {
        printf("Error opening "FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION" node\n", user_led);
    }
    else
    {
        fscanf(fp, "%s", gpio_setting);
        
        if (verbose)
        {
            printf("gpio%d set as ", user_led);
        }

        // Display whether the GPIO is set as input or output.
        if (!strcmp(gpio_setting, "in"))
        {
            if (verbose)
            {
                printf("INPUT\n");
            }

            // Set the direction property to "out".
            strcpy(gpio_setting, "out");
            fwrite(&gpio_setting, sizeof(char), 3, fp);
            fflush(fp);
        }
        else
        {
            if (verbose)
            {
                printf("OUTPUT\n");
            }
        }
        fclose(fp);
    }

    // Perform LED blink operation.
    if (verbose)
    {
        printf("LED Blink Operation on UltraZed\n");
    }

    // This test always passes since it requires user interaction.
    test_result = 0;

    while (test_result == 0)
    {
        test_result = set_next_blink_pattern(user_led);
        usleep(user_interval * 100000);
    }

    if (verbose)
    {
        printf("LED Blink Operation complete...");
	
        if (test_result == 0)
        {
            printf("\033[32mPASSED\033[0m\r\n");
        }
        else
        {
            printf("\033[5mFAILED\033[0m\r\n");
        }
    }

    exit(test_result);
}

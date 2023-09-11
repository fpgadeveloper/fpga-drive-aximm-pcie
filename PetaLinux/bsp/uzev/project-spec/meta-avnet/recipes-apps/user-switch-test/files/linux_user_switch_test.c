// ----------------------------------------------------------------------------
//
//        ** **        **          **  ****      **  **********  **********
//       **   **        **        **   ** **     **  **              **
//      **     **        **      **    **  **    **  **              **
//     **       **        **    **     **   **   **  *********       **
//    **         **        **  **      **    **  **  **              **
//   **           **        ****       **     ** **  **              **
//  **  .........  **        **        **      ****  **********      **
//     ...........
//                                     Reach Further
//
// ----------------------------------------------------------------------------
//
//  This design is the property of Avnet.  Publication of this
//  design is not authorized without written consent from Avnet.
// 
//  Please direct any questions to the UltraZed community support forum:
//     http://www.ultrazed.org/forum
// 
//  Product information is available at:
//     http://www.ultrazed.org
// 
//  Disclaimer:
//     Avnet, Inc. makes no warranty for the use of this code or design.
//     This code is provided  "As Is". Avnet, Inc assumes no responsibility for
//     any errors, which may appear in this code, nor does it make a commitment
//     to update the information contained herein. Avnet, Inc specifically
//     disclaims any implied warranties of fitness for a particular purpose.
//                      Copyright(c) 2016 Avnet, Inc.
//                              All rights reserved.
//
//----------------------------------------------------------------------------
//
// Create Date:         Nov 16, 2016
// Design Name:         Switch test application
// Module Name:         linux_user_switch_test.c
// Project Name:        Switch test application
// Target Devices:      Xilinx Zynq UltraScale+ MPSoC
// Hardware Boards:     UltraZed-EG SOM and UltraZed IO Carrier
//                      UltraZed-EV SOM and EV Carrier
//
// Tool versions:       Xilinx Vivado 2017.2
//                      Petalinux 2017.2
//
// Description:         User Switch test application for Linux.
//
// Dependencies:
//
// Revision:            Nov 17, 2016: 1.00 Initial version
//                      Jan 04, 2018: 1.10 Updated for UltraZed-EV
//
//----------------------------------------------------------------------------

#include <stdio.h>
#include <fcntl.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <gpio/gpio.h>

/* String formats used to build the file name path to specific GPIO
 * instances. */
#define FILE_FORMAT_GPIO_PATH          "/sys/class/gpio"
#define FILE_FORMAT_GPIO_EXPORT        "/export"
#define FILE_FORMAT_GPIO_DIRECTION     "/direction"
#define FILE_FORMAT_GPIO_VALUE         "/value"

#define GPIO_SWITCH_OFFSET				504

/* The GPIO_OFFSET definitions are used to indicate
 * the relative offset from the base start of the EMIO GPIO user connections.
 * In a typical reference design, the User IO will be assigned all at once
 * to an EMIO connection and connected externally to via the
 * emio_user_tri_io[] bus in the XDC constraints file and so these offsets
 * here should match the offsets of the hardware constraints as well.
 *
 * Because gpios can shift without notice, use get_gpio to dynamically read value in assign_offsets
 *
 */
int SWITCH1_GPIO_OFFSET		 = 0;
int SWITCH2_GPIO_OFFSET		 = 0;
int SWITCH3_GPIO_OFFSET		 = 0;
int SWITCH4_GPIO_OFFSET		 = 0;
int SWITCH5_GPIO_OFFSET		 = 0;
int SWITCH6_GPIO_OFFSET		 = 0;
int SWITCH7_GPIO_OFFSET		 = 0;
int SWITCH8_GPIO_OFFSET		 = 0;

int switch_values(void)
{
	const int char_buf_size = 80;
	char gpio_setting[8];
	int test_result = 0;
	char formatted_file_name[char_buf_size];

	int sw1_value;
	int sw2_value;
	int sw3_value;
	int sw4_value;
	int sw5_value;
	int sw6_value;
	int sw7_value;
	int sw8_value;

	FILE  *fp_sw1;
	FILE  *fp_sw2;
	FILE  *fp_sw3;
	FILE  *fp_sw4;
	FILE  *fp_sw5;
	FILE  *fp_sw6;
	FILE  *fp_sw7;
	FILE  *fp_sw8;

	// Open the gpio value properties so that they can be read/written.

	// Open the value property file for SW1.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_VALUE, SWITCH1_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp_sw1 = fopen(formatted_file_name, "r+");

	// Open the value property file for SW2.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_VALUE, SWITCH2_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp_sw2 = fopen(formatted_file_name, "r+");

	// Open the value property file for SW3.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_VALUE, SWITCH3_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp_sw3 = fopen(formatted_file_name, "r+");

	// Open the value property file for SW4.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_VALUE, SWITCH4_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp_sw4 = fopen(formatted_file_name, "r+");

	// Open the value property file for SW5.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_VALUE, SWITCH5_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp_sw5 = fopen(formatted_file_name, "r+");

	// Open the value property file for SW6.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_VALUE, SWITCH6_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp_sw6 = fopen(formatted_file_name, "r+");

	// Open the value property file for SW7.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_VALUE, SWITCH7_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp_sw7 = fopen(formatted_file_name, "r+");

	// Open the value property file for SW8.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_VALUE, SWITCH8_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp_sw8 = fopen(formatted_file_name, "r+");

	// Read the current value of the SW1 GPIO input.
	fscanf(fp_sw1, "%s", gpio_setting);

	if (!strcmp(gpio_setting, "1"))
		sw1_value = 1;
	else if (!strcmp(gpio_setting, "0"))
		sw1_value = 0;

	// Read the current value of the SW2 GPIO input.
	fscanf(fp_sw2, "%s", gpio_setting);

	if (!strcmp(gpio_setting, "1"))
		sw2_value = 1;
	else if (!strcmp(gpio_setting, "0"))
		sw2_value = 0;

	// Read the current value of the SW3 GPIO input.
	fscanf(fp_sw3, "%s", gpio_setting);

	if (!strcmp(gpio_setting, "1"))
		sw3_value = 1;
	else if (!strcmp(gpio_setting, "0"))
		sw3_value = 0;

	// Read the current value of the SW4 GPIO input.
	fscanf(fp_sw4, "%s", gpio_setting);

	if (!strcmp(gpio_setting, "1"))
		sw4_value = 1;
	else if (!strcmp(gpio_setting, "0"))
		sw4_value = 0;

	// Read the current value of the SW5 GPIO input.
	fscanf(fp_sw5, "%s", gpio_setting);

	if (!strcmp(gpio_setting, "1"))
		sw5_value = 1;
	else if (!strcmp(gpio_setting, "0"))
		sw5_value = 0;

	// Read the current value of the SW6 GPIO input.
	fscanf(fp_sw6, "%s", gpio_setting);

	if (!strcmp(gpio_setting, "1"))
		sw6_value = 1;
	else if (!strcmp(gpio_setting, "0"))
		sw6_value = 0;

	// Read the current value of the SW7 GPIO input.
	fscanf(fp_sw7, "%s", gpio_setting);

	if (!strcmp(gpio_setting, "1"))
		sw7_value = 1;
	else if (!strcmp(gpio_setting, "0"))
		sw7_value = 0;

	// Read the current value of the SW8 GPIO input.
	fscanf(fp_sw8, "%s", gpio_setting);

	if (!strcmp(gpio_setting, "1"))
		sw8_value = 1;
	else if (!strcmp(gpio_setting, "0"))
		sw8_value = 0;

/*
 * 	printf(" \n");
	printf("Switch1 Value: %d\n", sw1_value);
	printf("Switch2 Value: %d\n", sw2_value);
	printf("Switch3 Value: %d\n", sw3_value);
	printf("Switch4 Value: %d\n", sw4_value);
	printf("Switch5 Value: %d\n", sw5_value);
	printf("Switch6 Value: %d\n", sw6_value);
	printf("Switch7 Value: %d\n", sw7_value);
	printf("Switch8 Value: %d\n", sw8_value);
	printf(" \n");
*/
	// Concatenate the individual switch readings into a hex value
    test_result = (sw8_value<<1) | sw7_value;
    test_result = (test_result<<1) | sw6_value;
    test_result = (test_result<<1) | sw5_value;
    test_result = (test_result<<1) | sw4_value;
    test_result = (test_result<<1) | sw3_value;
    test_result = (test_result<<1) | sw2_value;
    test_result = (test_result<<1) | sw1_value;
    
	// Close the GPIO value property files.
	fclose(fp_sw1);
	fclose(fp_sw2);
	fclose(fp_sw3);
	fclose(fp_sw4);
	fclose(fp_sw5);
	fclose(fp_sw6);
	fclose(fp_sw7);
	fclose(fp_sw8);
			
	return test_result;
}

void assign_offsets(void)
{
	SWITCH1_GPIO_OFFSET = get_gpio_c("SW5_1");
	SWITCH2_GPIO_OFFSET = get_gpio_c("SW5_2");
	SWITCH3_GPIO_OFFSET = get_gpio_c("SW5_3");
	SWITCH4_GPIO_OFFSET = get_gpio_c("SW5_4");
	SWITCH5_GPIO_OFFSET = get_gpio_c("SW5_5");
	SWITCH6_GPIO_OFFSET = get_gpio_c("SW5_6");
	SWITCH7_GPIO_OFFSET = get_gpio_c("SW5_7");
	SWITCH8_GPIO_OFFSET = get_gpio_c("SW5_8");
} //assign_offsets()

int main()
{
	char gpio_setting[8];
	int test_result = 0;
	const int char_buf_size = 80;
	char formatted_file_name[char_buf_size];
	FILE  *fp;

	// Display the lab name in the application banner.
	printf(" \n");
	printf("***********************************************************\n");
	printf("*                                                         *\n");
	printf("*      UltraZed-EV SOM + EV Carrier Card Switch Tests     *\n");
	printf("*                                                         *\n");
	printf("***********************************************************\n");
	printf(" \n");

	assign_offsets();

	// Open the export file and write the PSGPIO number for each Pmod GPIO
	// signal to the Linux sysfs GPIO export property, then close the file.
	fp = fopen(FILE_FORMAT_GPIO_PATH FILE_FORMAT_GPIO_EXPORT, "w");
	if (fp == NULL)
	{
		printf("Error opening /sys/class/gpio/export node\n");
	}
	else
	{
		// Set the value property for the export to the GPIO number for SWITCH1.
		snprintf(gpio_setting, 4, "%d", SWITCH1_GPIO_OFFSET);
		fwrite(&gpio_setting, sizeof(char), 3, fp);
		fflush(fp);

		// Set the value property for the export to the GPIO number for SWITCH2.
		snprintf(gpio_setting, 4, "%d", SWITCH2_GPIO_OFFSET);
		fwrite(&gpio_setting, sizeof(char), 3, fp);
		fflush(fp);

		// Set the value property for the export to the GPIO number for SWITCH3.
		snprintf(gpio_setting, 4, "%d", SWITCH3_GPIO_OFFSET);
		fwrite(&gpio_setting, sizeof(char), 3, fp);
		fflush(fp);

		// Set the value property for the export to the GPIO number for SWITCH4.
		snprintf(gpio_setting, 4, "%d", SWITCH4_GPIO_OFFSET);
		fwrite(&gpio_setting, sizeof(char), 3, fp);
		fflush(fp);

		// Set the value property for the export to the GPIO number for SWITCH5.
		snprintf(gpio_setting, 4, "%d", SWITCH5_GPIO_OFFSET);
		fwrite(&gpio_setting, sizeof(char), 3, fp);
		fflush(fp);

		// Set the value property for the export to the GPIO number for SWITCH6.
		snprintf(gpio_setting, 4, "%d", SWITCH6_GPIO_OFFSET);
		fwrite(&gpio_setting, sizeof(char), 3, fp);
		fflush(fp);

		// Set the value property for the export to the GPIO number for SWITCH7.
		snprintf(gpio_setting, 4, "%d", SWITCH7_GPIO_OFFSET);
		fwrite(&gpio_setting, sizeof(char), 3, fp);
		fflush(fp);

		// Set the value property for the export to the GPIO number for SWITCH8.
		snprintf(gpio_setting, 4, "%d", SWITCH8_GPIO_OFFSET);
		fwrite(&gpio_setting, sizeof(char), 3, fp);
		fflush(fp);

		fclose(fp);
	}

	// Check the direction property of the GPIO number for SW1.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION, SWITCH1_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp = fopen(formatted_file_name, "r+");
	if (fp == NULL)
	{
		printf("Error opening "FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION" node\n", SWITCH1_GPIO_OFFSET);
	}
	else
	{
		// Set the direction property to "in".
		strcpy(gpio_setting, "in");
		fwrite(&gpio_setting, sizeof(char), 2, fp);
		fflush(fp);

		fscanf(fp, "%s", gpio_setting);
		printf("gpio%d set as ", SWITCH1_GPIO_OFFSET);

		// Display whether the GPIO is set as input or output.
		if (!strcmp(gpio_setting, "out"))
		{
			printf("OUTPUT\n");
		}
		else
		{
			printf("INPUT\n");
		}
		fclose(fp);
	}

	// Check the direction property of the GPIO number for SW2.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION, SWITCH2_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp = fopen(formatted_file_name, "r+");
	if (fp == NULL)
	{
		printf("Error opening "FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION" node\n", SWITCH2_GPIO_OFFSET);
	}
	else
	{
		// Set the direction property to "in".
		strcpy(gpio_setting, "in");
		fwrite(&gpio_setting, sizeof(char), 2, fp);
		fflush(fp);

		fscanf(fp, "%s", gpio_setting);
		printf("gpio%d set as ", SWITCH2_GPIO_OFFSET);

		// Display whether the GPIO is set as input or output.
		if (!strcmp(gpio_setting, "out"))
		{
			printf("OUTPUT\n");
		}
		else
		{
			printf("INPUT\n");
		}
		fclose(fp);
	}

	// Check the direction property of the GPIO number for SW3.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION, SWITCH3_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp = fopen(formatted_file_name, "r+");
	if (fp == NULL)
	{
		printf("Error opening "FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION" node\n", SWITCH3_GPIO_OFFSET);
	}
	else
	{
		// Set the direction property to "in".
		strcpy(gpio_setting, "in");
		fwrite(&gpio_setting, sizeof(char), 2, fp);
		fflush(fp);

		fscanf(fp, "%s", gpio_setting);
		printf("gpio%d set as ", SWITCH3_GPIO_OFFSET);

		// Display whether the GPIO is set as input or output.
		if (!strcmp(gpio_setting, "out"))
		{
			printf("OUTPUT\n");
		}
		else
		{
			printf("INPUT\n");
		}
		fclose(fp);
	}

	// Check the direction property of the GPIO number for SW4.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION, SWITCH4_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp = fopen(formatted_file_name, "r+");
	if (fp == NULL)
	{
		printf("Error opening "FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION" node\n", SWITCH4_GPIO_OFFSET);
	}
	else
	{
		// Set the direction property to "in".
		strcpy(gpio_setting, "in");
		fwrite(&gpio_setting, sizeof(char), 2, fp);
		fflush(fp);

		fscanf(fp, "%s", gpio_setting);
		printf("gpio%d set as ", SWITCH4_GPIO_OFFSET);

		// Display whether the GPIO is set as input or output.
		if (!strcmp(gpio_setting, "out"))
		{
			printf("OUTPUT\n");
		}
		else
		{
			printf("INPUT\n");
		}
		fclose(fp);
	}

	// Check the direction property of the GPIO number for SW5.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION, SWITCH5_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp = fopen(formatted_file_name, "r+");
	if (fp == NULL)
	{
		printf("Error opening "FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION" node\n", SWITCH5_GPIO_OFFSET);
	}
	else
	{
		// Set the direction property to "in".
		strcpy(gpio_setting, "in");
		fwrite(&gpio_setting, sizeof(char), 2, fp);
		fflush(fp);

		fscanf(fp, "%s", gpio_setting);
		printf("gpio%d set as ", SWITCH5_GPIO_OFFSET);

		// Display whether the GPIO is set as input or output.
		if (!strcmp(gpio_setting, "out"))
		{
			printf("OUTPUT\n");
		}
		else
		{
			printf("INPUT\n");
		}
		fclose(fp);
	}

	// Check the direction property of the GPIO number for SW6.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION, SWITCH6_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp = fopen(formatted_file_name, "r+");
	if (fp == NULL)
	{
		printf("Error opening "FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION" node\n", SWITCH6_GPIO_OFFSET);
	}
	else
	{
		// Set the direction property to "in".
		strcpy(gpio_setting, "in");
		fwrite(&gpio_setting, sizeof(char), 2, fp);
		fflush(fp);

		fscanf(fp, "%s", gpio_setting);
		printf("gpio%d set as ", SWITCH6_GPIO_OFFSET);

		// Display whether the GPIO is set as input or output.
		if (!strcmp(gpio_setting, "out"))
		{
			printf("OUTPUT\n");
		}
		else
		{
			printf("INPUT\n");
		}
		fclose(fp);
	}

	// Check the direction property of the GPIO number for SW7.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION, SWITCH7_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp = fopen(formatted_file_name, "r+");
	if (fp == NULL)
	{
		printf("Error opening "FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION" node\n", SWITCH7_GPIO_OFFSET);
	}
	else
	{
		// Set the direction property to "in".
		strcpy(gpio_setting, "in");
		fwrite(&gpio_setting, sizeof(char), 2, fp);
		fflush(fp);

		fscanf(fp, "%s", gpio_setting);
		printf("gpio%d set as ", SWITCH7_GPIO_OFFSET);

		// Display whether the GPIO is set as input or output.
		if (!strcmp(gpio_setting, "out"))
		{
			printf("OUTPUT\n");
		}
		else
		{
			printf("INPUT\n");
		}
		fclose(fp);
	}

	// Check the direction property of the GPIO number for SW8.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION, SWITCH8_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp = fopen(formatted_file_name, "r+");
	if (fp == NULL)
	{
		printf("Error opening "FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION" node\n", SWITCH8_GPIO_OFFSET);
	}
	else
	{
		// Set the direction property to "in".
		strcpy(gpio_setting, "in");
		fwrite(&gpio_setting, sizeof(char), 2, fp);
		fflush(fp);

		fscanf(fp, "%s", gpio_setting);
		printf("gpio%d set as ", SWITCH8_GPIO_OFFSET);

		// Display whether the GPIO is set as input or output.
		if (!strcmp(gpio_setting, "out"))
		{
			printf("OUTPUT\n");
		}
		else
		{
			printf("INPUT\n");
		}
		fclose(fp);
	}

	// Perform switch tests to verify all switches toggle
	printf(" \n");
	printf("Switch Test on UltraZed-EV EV Carrier\n");
	printf("Make sure all switches are OFF (DOWN POSITION)\n");
	printf("Pause here up to 15 seconds to turn the switches OFF (if necessary)\n");
	printf(" \n");
	
    int i;
    int new_sw_value = 0;
    int old_sw_value = 0;
    int init_sw_value = 0;
    
    init_sw_value = switch_values();
        
    for(i=0;i<16;i++) {
        new_sw_value = switch_values();
        
        if (new_sw_value != old_sw_value)
        {
            printf("DIP switch value is set to %x \n",new_sw_value);
        }

        if (new_sw_value == 0x00)
        {
            printf(" \n");
            printf("All switches turned OFF\n");
            break;
        }
        
        if ((i == 15) && (init_sw_value == new_sw_value))
        {
            printf(" \n");
            printf("No switches changed state\n");
            printf(" \n");
            printf("Switch Test complete (or time expired)...\n");
            printf(" \n");
            printf("\033[5mFAILED\033[0m\n");
            test_result = -1;
            exit(test_result);
        }

        old_sw_value = new_sw_value;
		usleep(1000000);	
    }

    
	printf(" \n");
	printf("Toggle all switches ON (UP POSITION)!\n");
	printf("Look for switch that is stuck, ie - no toggle on switch!\n");
	printf("Pause here 15 seconds (or until all switches have toggled) to change the switches state\n");
	printf(" \n");

    for(i=0;i<16;i++) {
        new_sw_value = switch_values();
        
        if (new_sw_value != old_sw_value)
        {
            printf("DIP switch value has changed to %x \n",new_sw_value);
        }

        if (new_sw_value == 0xff)
        {
            printf(" \n");
            printf("All switches changed state\n");
            break;
        }
        
        old_sw_value = new_sw_value;
		usleep(1000000);	
    }
    
	printf(" \n");
	printf("Switch Test complete (or time expired)...\n");
	printf(" \n");
	
	if (new_sw_value == 0xff)
	{
		printf("\033[32mPASSED\033[0m\n");
        test_result = 0;
    	printf(" \n");
	}
	else
	{
		printf("\033[5mFAILED\033[0m\n");
        test_result = -1;
		printf(" \n");
	}
    exit(test_result);
}

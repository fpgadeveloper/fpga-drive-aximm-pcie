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
// This design is the property of Avnet.  Publication of this
// design is not authorized without written consent from Avnet.
//
// Please direct any questions to the PicoZed community support forum:
//    http://www.picozed.org/forum
//
// Product information is available at:
//    http://www.picozed.org/product/picozed
//
// Disclaimer:
//    Avnet, Inc. makes no warranty for the use of this code or design.
//    This code is provided  "As Is". Avnet, Inc assumes no responsibility for
//    any errors, which may appear in this code, nor does it make a commitment
//    to update the information contained herein. Avnet, Inc specifically
//    disclaims any implied warranties of fitness for a particular purpose.
//                     Copyright(c) 2013 Avnet, Inc.
//                             All rights reserved.
//
//----------------------------------------------------------------------------
//
// Create Date:         Nov 16, 2016
// Design Name:         LED and PB test application
// Module Name:         linux_user_led_test.c
// Project Name:        LED and PB test application
// Target Devices:      Xilinx Zynq and Zynq UltraScale+ MPSoC
// Hardware Boards:     UltraZed-EG SOM and UltraZed IO Carrier
//                      UltraZed-EV SOM and EV Carrier Card
//
// Tool versions:       Xilinx Vivado 2016.2
//						Petalinux 2016.2
//
// Description:         User LED test application for Linux.
//
// Dependencies:
//
// Revision:            Dec 04, 2013: 1.00 Initial version
//                      Apr 06, 2016: 1.01 Updated to run under 2015.2
//                                         PetaLinux tools
//						Nov 16, 2016: 1.02 Updated to UltraZed Platform
//                      Jan 04, 2018: 1.03 Updated for UltraZed-EV
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

/* The LEDx_GPIO_OFFSET and PBx_GPIO_OFFSET definitions are used to indicate
 * the relative offset from the base start of the EMIO GPIO user connections.
 * In a typical reference design, the User IO will be assigned all at once
 * to an EMIO connection and connected externally to via the
 * emio_user_tri_io[] bus in the XDC constraints file and so these offsets
 * here should match the offsets of the hardware constraints as well.
 *
 * Because gpios can shift without notice, use get_gpio to dynamically read value in assign_offsets
 *
 */
int LED1_GPIO_OFFSET = 0;
int LED2_GPIO_OFFSET = 0;
int LED3_GPIO_OFFSET = 0;
int LED4_GPIO_OFFSET = 0;
int LED5_GPIO_OFFSET = 0;
int LED6_GPIO_OFFSET = 0;
int LED7_GPIO_OFFSET = 0;
int LED8_GPIO_OFFSET = 0;

int PB1_GPIO_OFFSET  = 0;
int PB2_GPIO_OFFSET  = 0;
int PB3_GPIO_OFFSET  = 0;

static unsigned int direction = 1;

int set_next_count_pattern(void)
{
	const int char_buf_size = 80;
	static unsigned int count = 0;
	
	char gpio_setting[4];
	
	int test_result = 0;
	char formatted_file_name[char_buf_size];

    int check_led1_once = 0;
    int check_led2_once = 0;
    int check_led3_once = 0;
    int check_led4_once = 0;
    int check_led5_once = 0;
    int check_led6_once = 0;
    int check_led7_once = 0;
    int check_led8_once = 0;

    int led1_value = 0;
    int led2_value = 0;
    int led3_value = 0;
    int led4_value = 0;
    int led5_value = 0;
    int led6_value = 0;
    int led7_value = 0;
    int led8_value = 0;

	FILE  *fp_led1;
	FILE  *fp_led2;
	FILE  *fp_led3;
	FILE  *fp_led4;
	FILE  *fp_led5;
	FILE  *fp_led6;
	FILE  *fp_led7;
	FILE  *fp_led8;

	// Open the LED gpio value properties so that they can be read/written.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_VALUE, LED1_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp_led1 = fopen(formatted_file_name, "r+");

	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_VALUE, LED2_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp_led2 = fopen(formatted_file_name, "r+");

	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_VALUE, LED3_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp_led3 = fopen(formatted_file_name, "r+");

	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_VALUE, LED4_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp_led4 = fopen(formatted_file_name, "r+");

	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_VALUE, LED5_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp_led5 = fopen(formatted_file_name, "r+");

	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_VALUE, LED6_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp_led6 = fopen(formatted_file_name, "r+");

	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_VALUE, LED7_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp_led7 = fopen(formatted_file_name, "r+");

	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_VALUE, LED8_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp_led8 = fopen(formatted_file_name, "r+");
    
	// Read the current value of the led2 GPIO.
	fscanf(fp_led2, "%s", gpio_setting);

	if (!strcmp(gpio_setting, "1"))
		led2_value = 1;
	else if (!strcmp(gpio_setting, "0"))
		led2_value = 0;

	// Read the current value of the led3 GPIO.
	fscanf(fp_led3, "%s", gpio_setting);

	if (!strcmp(gpio_setting, "1"))
		led3_value = 1;
	else if (!strcmp(gpio_setting, "0"))
		led3_value = 0;

	// Read the current value of the led4 GPIO.
	fscanf(fp_led4, "%s", gpio_setting);

	if (!strcmp(gpio_setting, "1"))
		led4_value = 1;
	else if (!strcmp(gpio_setting, "0"))
		led4_value = 0;

	// Read the current value of the led5 GPIO.
	fscanf(fp_led5, "%s", gpio_setting);

	if (!strcmp(gpio_setting, "1"))
		led5_value = 1;
	else if (!strcmp(gpio_setting, "0"))
		led5_value = 0;

	// Read the current value of the led6 GPIO.
	fscanf(fp_led6, "%s", gpio_setting);

	if (!strcmp(gpio_setting, "1"))
		led6_value = 1;
	else if (!strcmp(gpio_setting, "0"))
		led6_value = 0;

	// Read the current value of the led7 GPIO.
	fscanf(fp_led7, "%s", gpio_setting);

	if (!strcmp(gpio_setting, "1"))
		led7_value = 1;
	else if (!strcmp(gpio_setting, "0"))
		led7_value = 0;

	// Read the current value of the led8 GPIO.
	fscanf(fp_led8, "%s", gpio_setting);

	if (!strcmp(gpio_setting, "1"))
		led8_value = 1;
	else if (!strcmp(gpio_setting, "0"))
		led8_value = 0;


	// Write test pattern to LEDs.
	if ((count == 0) && ((direction == 0) || (direction == 4) || (direction == 5)))
	{
		strcpy(gpio_setting, "1");
			if (direction == 0)
		{
			// Now begin sliding 'up'.
			direction = 1;
		}
	}
	else if (((count & 0x00000001) == 1) && ((direction == 2) || (direction == 3)))
	{
		strcpy(gpio_setting, "1");
	}
	else
	{
		strcpy(gpio_setting, "0");
	}

	fwrite(&gpio_setting, sizeof(char), 1, fp_led1);

    // Read the current value of the led1 GPIO.
	fscanf(fp_led1, "%s", gpio_setting);

	if (!strcmp(gpio_setting, "1") & check_led1_once == 0)
    {
		led1_value = 1;
        check_led1_once = 1;
    }

	fflush(fp_led1);


	if ((count == 1) && ((direction == 0) || (direction == 1) || (direction == 4) || (direction == 5)))
	{
		strcpy(gpio_setting, "1");
	}
	else if ((((count >> 1) & 0x00000001) == 1) && ((direction == 2) || (direction == 3)))
	{
		strcpy(gpio_setting, "1");
	}
	else
	{
		strcpy(gpio_setting, "0");
	}
	

	fwrite(&gpio_setting, sizeof(char), 1, fp_led2);

    // Read the current value of the led2 GPIO.
	fscanf(fp_led2, "%s", gpio_setting);

	if (!strcmp(gpio_setting, "1") & check_led2_once == 0)
    {
		led2_value = 1;
        check_led2_once = 1;
    }

	fflush(fp_led2);

	if ((count == 2) && ((direction == 0) || (direction == 1) || (direction == 4) || (direction == 5)))
	{
		strcpy(gpio_setting, "1");
	}
	else if ((((count >> 2) & 0x00000001) == 1) && ((direction == 2) || (direction == 3)))
	{
		strcpy(gpio_setting, "1");
	}
	else
	{
		strcpy(gpio_setting, "0");
	}
	
	fwrite(&gpio_setting, sizeof(char), 1, fp_led3);

    // Read the current value of the led3 GPIO.
	fscanf(fp_led3, "%s", gpio_setting);

	if (!strcmp(gpio_setting, "1") & check_led3_once == 0)
    {
		led3_value = 1;
        check_led3_once = 1;
    }

	fflush(fp_led3);

	if ((count == 3) && ((direction == 0) || (direction == 1) || (direction == 4) || (direction == 5)))
	{
		strcpy(gpio_setting, "1");
	}
	else if ((((count >> 3) & 0x00000001) == 1) && ((direction == 2) || (direction == 3)))
	{
		strcpy(gpio_setting, "1");
	}
	else
	{
		strcpy(gpio_setting, "0");
	}
	
	fwrite(&gpio_setting, sizeof(char), 1, fp_led4);

    // Read the current value of the led4 GPIO.
	fscanf(fp_led4, "%s", gpio_setting);

	if (!strcmp(gpio_setting, "1") & check_led4_once == 0)
    {
		led4_value = 1;
        check_led4_once = 1;
    }

	fflush(fp_led4);

	if ((count == 4) && ((direction == 0) || (direction == 1) || (direction == 4) || (direction == 5)))
	{
		strcpy(gpio_setting, "1");
	}
	else if ((((count >> 4) & 0x00000001) == 1) && ((direction == 2) || (direction == 3)))
	{
		strcpy(gpio_setting, "1");
	}
	else
	{
		strcpy(gpio_setting, "0");
	}
	
	fwrite(&gpio_setting, sizeof(char), 1, fp_led5);

    // Read the current value of the led5 GPIO.
	fscanf(fp_led5, "%s", gpio_setting);

	if (!strcmp(gpio_setting, "1") & check_led5_once == 0)
    {
		led5_value = 1;
        check_led5_once = 1;
    }

	fflush(fp_led5);

	if ((count == 5) && ((direction == 0) || (direction == 1) || (direction == 4) || (direction == 5)))
	{
		strcpy(gpio_setting, "1");
	}
	else if ((((count >> 5) & 0x00000001) == 1) && ((direction == 2) || (direction == 3)))
	{
		strcpy(gpio_setting, "1");
	}
	else
	{
		strcpy(gpio_setting, "0");
	}
	
	fwrite(&gpio_setting, sizeof(char), 1, fp_led6);

    // Read the current value of the led6 GPIO.
	fscanf(fp_led6, "%s", gpio_setting);

	if (!strcmp(gpio_setting, "1") & check_led6_once == 0)
    {
		led6_value = 1;
        check_led6_once = 1;
    }

	fflush(fp_led6);

	if ((count == 6) && ((direction == 0) || (direction == 1) || (direction == 4) || (direction == 5)))
	{
		strcpy(gpio_setting, "1");
	}
	else if ((((count >> 6) & 0x00000001) == 1) && ((direction == 2) || (direction == 3)))
	{
		strcpy(gpio_setting, "1");
	}
	else
	{
		strcpy(gpio_setting, "0");
	}
	
	fwrite(&gpio_setting, sizeof(char), 1, fp_led7);

    // Read the current value of the led7 GPIO.
	fscanf(fp_led7, "%s", gpio_setting);

	if (!strcmp(gpio_setting, "1") & check_led7_once == 0)
    {
		led7_value = 1;
        check_led7_once = 1;
    }

	fflush(fp_led7);

	if ((count == 7) && ((direction == 1) || (direction == 4) || (direction == 5)))
	{
		strcpy(gpio_setting, "1");

		if (direction == 1)
		{
			// Last LED in the set, begin sliding 'down'.
			direction = 0;
		}
	}
	else if ((((count >> 7) & 0x00000001) == 1) && ((direction == 2) || (direction == 3)))
	{
		strcpy(gpio_setting, "1");
	}
	else
	{
		strcpy(gpio_setting, "0");
	}
	
	fwrite(&gpio_setting, sizeof(char), 1, fp_led8);

    // Read the current value of the led8 GPIO.
	fscanf(fp_led8, "%s", gpio_setting);

	if (!strcmp(gpio_setting, "1") & check_led8_once == 0)
    {
		led8_value = 1;
        check_led8_once = 1;
    }

	fflush(fp_led8);

	if (((direction == 1) & (count < 8)) ||
		(direction == 2))
	{
		// Increment count for next time around.
		count = count + 1;
	}
	else if ((direction == 0) ||
	         (direction == 3))
	{
		// Decrement count for next time around.
		count = count - 1;
	}
	else if (direction == 4)
	{
		// Increment count for next time around.
		if (count == 7)
		{
			count = 0;
		}
		else
		{
			count = count + 1;
		}
	}
	else if (direction == 5)
	{
		// Decrement count for next time around.
		if (count == 0)
		{
			count = 7;
		}
		else
		{
			count = count - 1;
		}
	}
	else
	{
		/*
		 *  Something went wrong keeping track of direction, reset the
		 *  direction to 'up'.
		 */
		direction = 1;
		count = 0;
	}

	// Close the GPIO value property files.
	fclose(fp_led1);
	fclose(fp_led2);
	fclose(fp_led3);
	fclose(fp_led4);
	fclose(fp_led5);
	fclose(fp_led6);
	fclose(fp_led7);
	fclose(fp_led8);

	// Concatenate the individual LED readings into a hex value
/*
 *     test_result = (led8_value<<1) | led7_value;
    test_result = (test_result<<1) | led6_value;
    test_result = (test_result<<1) | led5_value;
    test_result = (test_result<<1) | led4_value;
    test_result = (test_result<<1) | led3_value;
    test_result = (test_result<<1) | led2_value;
    test_result = (test_result<<1) | led1_value;
*/
    test_result = (check_led8_once<<1) | check_led7_once;
    test_result = (test_result<<1) | check_led6_once;
    test_result = (test_result<<1) | check_led5_once;
    test_result = (test_result<<1) | check_led4_once;
    test_result = (test_result<<1) | check_led3_once;
    test_result = (test_result<<1) | check_led2_once;
    test_result = (test_result<<1) | check_led1_once;

	return test_result;
}

int set_next_input_pattern(void)
{
	const int char_buf_size = 80;
	char gpio_setting[4];
	int test_result = 0;
	char formatted_file_name[char_buf_size];
    
    int check_pb1_once = 0;
    int check_pb2_once = 0;
    int check_pb3_once = 0;

	FILE  *fp_led1;
	FILE  *fp_led2;
	FILE  *fp_led3;
	FILE  *fp_led4;
	FILE  *fp_led5;
	FILE  *fp_led6;
	FILE  *fp_led7;
	FILE  *fp_led8;
	
	FILE  *fp_pb1;
	FILE  *fp_pb2;
	FILE  *fp_pb3;
//TC	FILE  *fp_pb4;

	// Open the gpio value properties so that they can be read/written.

	// Open the value property file for LED1.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_VALUE, LED1_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp_led1 = fopen(formatted_file_name, "r+");

	// Open the value property file for LED2.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_VALUE, LED2_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp_led2 = fopen(formatted_file_name, "r+");

	// Open the value property file for LED3.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_VALUE, LED3_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp_led3 = fopen(formatted_file_name, "r+");

	// Open the value property file for LED4.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_VALUE, LED4_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp_led4 = fopen(formatted_file_name, "r+");

	// Open the value property file for LED5.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_VALUE, LED5_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp_led5 = fopen(formatted_file_name, "r+");

	// Open the value property file for LED6.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_VALUE, LED6_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp_led6 = fopen(formatted_file_name, "r+");

	// Open the value property file for LED7.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_VALUE, LED7_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp_led7 = fopen(formatted_file_name, "r+");

	// Open the value property file for LED8.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_VALUE, LED8_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp_led8 = fopen(formatted_file_name, "r+");

	// Open the value property file for PB1.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_VALUE, PB1_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp_pb1 = fopen(formatted_file_name, "r+");

	// Open the value property file for PB2.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_VALUE, PB2_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp_pb2 = fopen(formatted_file_name, "r+");

	// Open the value property file for PB3.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_VALUE, PB3_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp_pb3 = fopen(formatted_file_name, "r+");

	// Open the value property file for PB4.
/*TC
 * 	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_VALUE, PB4_GPIO_OFFSET);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);;
		return -1;
	}
	fp_pb4 = fopen(formatted_file_name, "r+");
*/

	// Read the current value of the PB1 GPIO input.
	fscanf(fp_pb1, "%s", gpio_setting);



	// Determine whether the PB1 push button is being depressed or not.
	if (!strcmp(gpio_setting, "1"))
	{
		check_pb1_once = 1;
        
        // Count LEDs up.
		direction = 2;

		fflush(fp_led1);
		fflush(fp_led2);
		fflush(fp_led3);
		fflush(fp_led4);
		fflush(fp_led5);
		fflush(fp_led6);
		fflush(fp_led7);
		fflush(fp_led8);
	}

	// Read the current value of the PB2 GPIO input.
	fscanf(fp_pb2, "%s", gpio_setting);

	// Determine whether the PB2 push button is being depressed or not.
	if (!strcmp(gpio_setting, "1"))
	{
		check_pb2_once = 1;

		// Count LEDs down.
		direction = 3;

		fflush(fp_led1);
		fflush(fp_led2);
		fflush(fp_led3);
		fflush(fp_led4);
		fflush(fp_led5);
		fflush(fp_led6);
		fflush(fp_led7);
		fflush(fp_led8);
	}

	// Read the current value of the PB3 GPIO input.
	fscanf(fp_pb3, "%s", gpio_setting);

	// Determine whether the PB3 push button is being depressed or not.
	if (!strcmp(gpio_setting, "1"))
	{
		check_pb3_once = 1;

		// Slide LED to the right.
		direction = 4;

		fflush(fp_led1);
		fflush(fp_led2);
		fflush(fp_led3);
		fflush(fp_led4);
		fflush(fp_led5);
		fflush(fp_led6);
		fflush(fp_led7);
		fflush(fp_led8);
	}

	// Read the current value of the PB4 GPIO input.
/*
 * 	fscanf(fp_pb4, "%s", gpio_setting);

	// Determine whether the PL push button is being depressed or not.
	if (!strcmp(gpio_setting, "1"))
	{
		// Slide LED to the left.
		direction = 5;

		fflush(fp_led1);
		fflush(fp_led2);
		fflush(fp_led3);
		fflush(fp_led4);
		fflush(fp_led5);
		fflush(fp_led6);
		fflush(fp_led7);
		fflush(fp_led8);		
	}
*/

	// This test always passes since it requires user interaction.
	test_result = 0;

	// Close the GPIO value property files.
	fclose(fp_led1);
	fclose(fp_led2);
	fclose(fp_led3);
	fclose(fp_led4);
	fclose(fp_led5);
	fclose(fp_led6);
	fclose(fp_led7);
	fclose(fp_led8);
	fclose(fp_pb1);
	fclose(fp_pb2);
	fclose(fp_pb3);
//TC	fclose(fp_pb4);

    test_result = (check_pb3_once<<1) | check_pb2_once;
    test_result = (test_result<<1) | check_pb1_once;

	return test_result;
}


void assign_offsets(void)
{
	LED1_GPIO_OFFSET = get_gpio_c("PL_LED1");
	LED2_GPIO_OFFSET = get_gpio_c("PL_LED2");
	LED3_GPIO_OFFSET = get_gpio_c("PL_LED3");
	LED4_GPIO_OFFSET = get_gpio_c("PL_LED4");
	LED5_GPIO_OFFSET = get_gpio_c("PL_LED5");
	LED6_GPIO_OFFSET = get_gpio_c("PL_LED6");
	LED7_GPIO_OFFSET = get_gpio_c("PL_LED7");
	LED8_GPIO_OFFSET = get_gpio_c("PL_LED8");

	PB1_GPIO_OFFSET = get_gpio_c("SW2");
	PB2_GPIO_OFFSET = get_gpio_c("SW3");
	PB3_GPIO_OFFSET = get_gpio_c("SW4");
} //assign_offsets()

int main()
{
	char gpio_setting[4];
	int test_result = 0;
	int led_test_result = 0;
	int pb_test_result = 0;
    int leds_on = 0;
    int pbs_pressed = 0;
	const int char_buf_size = 80;
	char formatted_file_name[char_buf_size];
	FILE  *fp;

	// Display the lab name in the application banner.
	printf(" \n");
	printf("***********************************************************\n");
	printf("*                                                         *\n");
	printf("*   UltraZed-EV EV Carrier Card LED and Push Button Tests *\n");
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
		// Set the value property for the export to the GPIO number for LED1.
		snprintf(gpio_setting, 4, "%d", LED1_GPIO_OFFSET);
		fwrite(&gpio_setting, sizeof(char), 3, fp);
		fflush(fp);

		// Set the value property for the export to the GPIO number for LED2.
		snprintf(gpio_setting, 4, "%d", LED2_GPIO_OFFSET);
		fwrite(&gpio_setting, sizeof(char), 3, fp);
		fflush(fp);
		
		// Set the value property for the export to the GPIO number for LED3.
		snprintf(gpio_setting, 4, "%d", LED3_GPIO_OFFSET);
		fwrite(&gpio_setting, sizeof(char), 3, fp);
		fflush(fp);
		
		// Set the value property for the export to the GPIO number for LED4.
		snprintf(gpio_setting, 4, "%d", LED4_GPIO_OFFSET);
		fwrite(&gpio_setting, sizeof(char), 3, fp);
		fflush(fp);

		// Set the value property for the export to the GPIO number for LED5.
		snprintf(gpio_setting, 4, "%d", LED5_GPIO_OFFSET);
		fwrite(&gpio_setting, sizeof(char), 3, fp);
		fflush(fp);

		// Set the value property for the export to the GPIO number for LED6.
		snprintf(gpio_setting, 4, "%d", LED6_GPIO_OFFSET);
		fwrite(&gpio_setting, sizeof(char), 3, fp);
		fflush(fp);

		// Set the value property for the export to the GPIO number for LED7.
		snprintf(gpio_setting, 4, "%d", LED7_GPIO_OFFSET);
		fwrite(&gpio_setting, sizeof(char), 3, fp);
		fflush(fp);

		// Set the value property for the export to the GPIO number for LED8.
		snprintf(gpio_setting, 4, "%d", LED8_GPIO_OFFSET);
		fwrite(&gpio_setting, sizeof(char), 3, fp);
		fflush(fp);
		
		// Set the value property for the export to the GPIO number for PB1.
		snprintf(gpio_setting, 4, "%d", PB1_GPIO_OFFSET);
		fwrite(&gpio_setting, sizeof(char), 3, fp);
		fflush(fp);

		// Set the value property for the export to the GPIO number for PB2.
		snprintf(gpio_setting, 4, "%d", PB2_GPIO_OFFSET);
		fwrite(&gpio_setting, sizeof(char), 3, fp);
		fflush(fp);

		// Set the value property for the export to the GPIO number for PB3.
		snprintf(gpio_setting, 4, "%d", PB3_GPIO_OFFSET);
		fwrite(&gpio_setting, sizeof(char), 3, fp);
		fflush(fp);

		// Set the value property for the export to the GPIO number for PB4.
/*TC
 * 		snprintf(gpio_setting, 4, "%d", PB4_GPIO_OFFSET);
		fwrite(&gpio_setting, sizeof(char), 3, fp);
		fflush(fp);
*/
		fclose(fp);
	}

	// Check the direction property of the PSGPIO number for PB1.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION, PB1_GPIO_OFFSET);
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
		printf("Error opening "FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION" node\n", PB1_GPIO_OFFSET);
	}
	else
	{
		// Set the direction property to "in".
		strcpy(gpio_setting, "in");
		fwrite(&gpio_setting, sizeof(char), 2, fp);
		fflush(fp);

		fscanf(fp, "%s", gpio_setting);
		printf("gpio%d set as ", PB1_GPIO_OFFSET);

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

	// Check the direction property of the PSGPIO number for PB2.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION, PB2_GPIO_OFFSET);
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
		printf("Error opening "FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION" node\n", PB2_GPIO_OFFSET);
	}
	else
	{
		// Set the direction property to "in".
		strcpy(gpio_setting, "in");
		fwrite(&gpio_setting, sizeof(char), 2, fp);
		fflush(fp);

        fscanf(fp, "%s", gpio_setting);
		printf("gpio%d set as ", PB2_GPIO_OFFSET);

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

	// Check the direction property of the PSGPIO number for PB3.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION, PB3_GPIO_OFFSET);
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
		printf("Error opening "FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION" node\n", PB3_GPIO_OFFSET);
	}
	else
	{
		// Set the direction property to "in".
		strcpy(gpio_setting, "in");
		fwrite(&gpio_setting, sizeof(char), 2, fp);
		fflush(fp);

		fscanf(fp, "%s", gpio_setting);
		printf("gpio%d set as ", PB3_GPIO_OFFSET);

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

	// Check the direction property of the PSGPIO number for PB4.
/*TC
 * 	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION, PB4_GPIO_OFFSET);
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
		printf("Error opening "FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION" node\n", PB4_GPIO_OFFSET);
	}
	else
	{
		fscanf(fp, "%s", gpio_setting);
		printf("gpio%d set as ", PB4_GPIO_OFFSET);

		// Display whether the GPIO is set as input or output.
		if (!strcmp(gpio_setting, "out"))
		{
			printf("OUTPUT\n");

			// Set the direction property to "in".
			strcpy(gpio_setting, "in");
			fwrite(&gpio_setting, sizeof(char), 2, fp);
			fflush(fp);
		}
		else
		{
			printf("INPUT\n");
		}
		fclose(fp);
	}
*/

	// Check the direction property of the PSGPIO number for LED1.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION, LED1_GPIO_OFFSET);
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
		printf("Error opening "FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION" node\n", LED1_GPIO_OFFSET);
	}
	else
	{
		// Set the direction property to "out".
		strcpy(gpio_setting, "out");
		fwrite(&gpio_setting, sizeof(char), 3, fp);
		fflush(fp);

		fscanf(fp, "%s", gpio_setting);
		printf("gpio%d set as ", LED1_GPIO_OFFSET);

		// Display whether the GPIO is set as input or output.
		if (!strcmp(gpio_setting, "in"))
		{
			printf("INPUT\n");
		}
		else
		{
			printf("OUTPUT\n");
		}
		fclose(fp);
	}
	
	// Check the direction property of the PSGPIO number for LED2.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION, LED2_GPIO_OFFSET);
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
		printf("Error opening "FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION" node\n", LED2_GPIO_OFFSET);
	}
	else
	{
		// Set the direction property to "out".
		strcpy(gpio_setting, "out");
		fwrite(&gpio_setting, sizeof(char), 3, fp);
		fflush(fp);

		fscanf(fp, "%s", gpio_setting);
		printf("gpio%d set as ", LED2_GPIO_OFFSET);

		// Display whether the GPIO is set as input or output.
		if (!strcmp(gpio_setting, "in"))
		{
			printf("INPUT\n");
					}
		else
		{
			printf("OUTPUT\n");
		}
		fclose(fp);
	}

	// Check the direction property of the PSGPIO number for LED3.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION, LED3_GPIO_OFFSET);
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
		printf("Error opening "FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION" node\n", LED3_GPIO_OFFSET);
	}
	else
	{
		// Set the direction property to "out".
		strcpy(gpio_setting, "out");
		fwrite(&gpio_setting, sizeof(char), 3, fp);
		fflush(fp);

		fscanf(fp, "%s", gpio_setting);
		printf("gpio%d set as ", LED3_GPIO_OFFSET);

		// Display whether the GPIO is set as input or output.
		if (!strcmp(gpio_setting, "in"))
		{
			printf("INPUT\n");
		}
		else
		{
			printf("OUTPUT\n");
		}
		fclose(fp);
	}

	// Check the direction property of the PSGPIO number for LED4.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION, LED4_GPIO_OFFSET);
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
		printf("Error opening "FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION" node\n", LED4_GPIO_OFFSET);
	}
	else
	{
		// Set the direction property to "out".
		strcpy(gpio_setting, "out");
		fwrite(&gpio_setting, sizeof(char), 3, fp);
		fflush(fp);

		fscanf(fp, "%s", gpio_setting);
		printf("gpio%d set as ", LED4_GPIO_OFFSET);

		// Display whether the GPIO is set as input or output.
		if (!strcmp(gpio_setting, "in"))
		{
			printf("INPUT\n");
		}
		else
		{
			printf("OUTPUT\n");
		}
		fclose(fp);
	}

	// Check the direction property of the PSGPIO number for LED5.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION, LED5_GPIO_OFFSET);
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
		printf("Error opening "FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION" node\n", LED5_GPIO_OFFSET);
	}
	else
	{
		// Set the direction property to "out".
		strcpy(gpio_setting, "out");
		fwrite(&gpio_setting, sizeof(char), 3, fp);
		fflush(fp);

		fscanf(fp, "%s", gpio_setting);
		printf("gpio%d set as ", LED5_GPIO_OFFSET);

		// Display whether the GPIO is set as input or output.
		if (!strcmp(gpio_setting, "in"))
		{
			printf("INPUT\n");
		}
		else
		{
			printf("OUTPUT\n");
		}
		fclose(fp);
	}

	// Check the direction property of the PSGPIO number for LED6.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION, LED6_GPIO_OFFSET);
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
		printf("Error opening "FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION" node\n", LED6_GPIO_OFFSET);
	}
	else
	{
		// Set the direction property to "out".
		strcpy(gpio_setting, "out");
		fwrite(&gpio_setting, sizeof(char), 3, fp);
		fflush(fp);

		fscanf(fp, "%s", gpio_setting);
		printf("gpio%d set as ", LED6_GPIO_OFFSET);

		// Display whether the GPIO is set as input or output.
		if (!strcmp(gpio_setting, "in"))
		{
			printf("INPUT\n");
		}
		else
		{
			printf("OUTPUT\n");
		}
		fclose(fp);
	}

	// Check the direction property of the PSGPIO number for LED7.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION, LED7_GPIO_OFFSET);
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
		printf("Error opening "FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION" node\n", LED7_GPIO_OFFSET);
	}
	else
	{
		// Set the direction property to "out".
		strcpy(gpio_setting, "out");
		fwrite(&gpio_setting, sizeof(char), 3, fp);
		fflush(fp);

		fscanf(fp, "%s", gpio_setting);
		printf("gpio%d set as ", LED7_GPIO_OFFSET);

		// Display whether the GPIO is set as input or output.
		if (!strcmp(gpio_setting, "in"))
		{
			printf("INPUT\n");
		}
		else
		{
			printf("OUTPUT\n");
		}
		fclose(fp);
	}

	// Check the direction property of the PSGPIO number for LED8.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION, LED8_GPIO_OFFSET);
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
		printf("Error opening "FILE_FORMAT_GPIO_PATH"/gpio%d"FILE_FORMAT_GPIO_DIRECTION" node\n", LED8_GPIO_OFFSET);
	}
	else
	{
		// Set the direction property to "out".
		strcpy(gpio_setting, "out");
		fwrite(&gpio_setting, sizeof(char), 3, fp);
		fflush(fp);

		fscanf(fp, "%s", gpio_setting);
		printf("gpio%d set as ", LED8_GPIO_OFFSET);

		// Display whether the GPIO is set as input or output.
		if (!strcmp(gpio_setting, "in"))
		{
			printf("INPUT\n");
		}
		else
		{
			printf("OUTPUT\n");
		}
		fclose(fp);
	}

	// Perform LED pattern generation.
	printf("LED Pattern Generation on UltraZed-EV EV Carrier Card\n");


	// Perform PB tests to verify all LEDs turn on/off
	printf(" \n");
	printf("LED and PB switch test on UltraZed-EV EV Carrier\n");
	printf("Press SW2, SW3, or SW4 to change the display pattern on the LEDs.\n");
	printf("Pause here for 15 seconds to view the LEDs turn ON/OFF and press the PB switches.\n");
	printf("All three PB switches must be pressed and all LEDs must turn on or the test will fail.\n");
	printf(" \n");
	
    int i;
    
    for(i=0;i<160;i++) 
    {
		leds_on = set_next_count_pattern();
        
        led_test_result = led_test_result | leds_on;

/*
        printf("The LEDs that have been turned on are %x\n", led_test_result);

        if (led_test_result == 0xff)
        {
            printf("All LEDs turn ON/OFF\n");
            printf(" \n");
        }
*/        
		pbs_pressed = set_next_input_pattern();

        pb_test_result = pb_test_result | pbs_pressed;
        
/*
        printf("The PBs that have been pressed are %x\n", pb_test_result);

        if (pb_test_result == 0x7)
        {
            printf("All PBs have been pressed\n");
            printf(" \n");
        }
*/        
        if ((pb_test_result == 0x7) && (led_test_result == 0xff))
        {
            printf("All LEDs turn ON/OFF and all PBs have been pressed\n");
            printf(" \n");
            // wait here another second to watch the last selected PED display pattern
            usleep(1000000);	
            break;
        }
 
		usleep(100000);	
    }

	printf("LED Pattern Generation and PB Test Complete...");
	
	if (led_test_result == 0xff & pb_test_result == 0x7)
	{
		printf("\033[32mPASSED\033[0m\n");
        test_result = 0;
	}
	else
	{
		printf("\033[5mFAILED\033[0m\n");
        test_result = -1;
	}

    exit(test_result);
}

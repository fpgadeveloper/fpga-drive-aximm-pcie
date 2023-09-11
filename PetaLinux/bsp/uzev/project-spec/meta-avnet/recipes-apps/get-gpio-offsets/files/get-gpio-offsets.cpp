//MiniZEd test code that discovers the Linux offsets for GPIO pins and writes them to a file

#include <stdio.h>
#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <string.h>
#include <termios.h>
#include <dirent.h>


#define u8	unsigned char
#define u16 unsigned short

/* String formats used to build the file name path to specific GPIO
 * instances. */
#define FILE_FORMAT_GPIO_PATH          "/sys/class/gpio"
#define FILE_FORMAT_GPIO_EXPORT        "/export"
#define FILE_FORMAT_GPIO_DIRECTION     "/direction"
#define FILE_FORMAT_GPIO_VALUE         "/value"
#define FILENAME_GPIO_OFFSETS          "/mnt/emmc/gpio_offsets.txt"

#define GPIO_DIRECTION_INPUT	0
#define GPIO_DIRECTION_OUTPUT	1

// The max # of GPIOs this release of Linux is configured to support is 1024.  For 2017.2 the logic was as follows:
// The ZYNQ PS GPIO block has 118 IOs (54 on MIO, 64 on EMIO).
// 1024-118 = 906, hence "gpiochip906".  In our design, we have BT_REG_ON tied to EMIO[0], which is the first GPIO after
// all of the MIO, or 906 + 54 = 960.
// For 2017.2 values were #defined as constants.  But for 2017.4 it appears that these values can shift when the PL configuration changes.
// Therefore these are now variables and they are assigned after inspecting the content of the Linux-assigned
// fields in /sys/glass/gpio/gpiochipN/label fields. N is the number assigned.
// For 2017.4 the default offsets were as below.

int GPIO_OFFSET						= 903;
int GPIO_PS_BUTTON_OFFSET			= 903; //MIO#0
int GPIO_PS_LED_R_OFFSET			= 955; //MIO#52 (MIO#0 + 52)
int GPIO_PS_LED_G_OFFSET			= 956; //MIO#53 (MIO#0 + 53)
int GPIO_PL_LED_G_OFFSET			= 1023; //pl_led_2bits(1)
int GPIO_PL_LED_R_OFFSET			= 1022; //pl_led_2bits(0)
int GPIO_PL_SWITCH_OFFSET			= 1021; //pl_sw_1bit
int GPIO_PL_MICROPHONE7_OFFSET		= 1020; //Bit 7 of AXI_GPIO to microphone
int GPIO_PL_MICROPHONE6_OFFSET		= 1019; //Bit 6 of AXI_GPIO to microphone
int GPIO_PL_MICROPHONE5_OFFSET		= 1018; //Bit 5 of AXI_GPIO to microphone
int GPIO_PL_MICROPHONE4_OFFSET		= 1017; //Bit 4 of AXI_GPIO to microphone
int GPIO_PL_MICROPHONE3_OFFSET		= 1016; //Bit 3 of AXI_GPIO to microphone
int GPIO_PL_MICROPHONE2_OFFSET		= 1015; //Bit 2 of AXI_GPIO to microphone
int GPIO_PL_MICROPHONE1_OFFSET		= 1014; //Bit 1 of AXI_GPIO to microphone
int GPIO_PL_MICROPHONE0_OFFSET		= 1013; //Bit 0 of AXI_GPIO to microphone

int iMIO0_Offset = 0;
int iAXI_MAX_Offset = 0;

int get_gpio_base(void)
{
    int test_result = 0;
	const int char_buf_size = 80;
	char formatted_file_name[char_buf_size];
    char gpio_setting[256];
    char chiplist[128][20];
    char OffsetString[5];
    int iOffset;
    int chipindex = 0;
    int index;
    int retval;
    FILE  *fp;

	//(1) Do a directory of /sys/class/gpio and put all the "gpiochip" entries into a list
	DIR * d = opendir(FILE_FORMAT_GPIO_PATH); // Open the path
	if(d==NULL) return(-1); // If was not able to, return
	struct dirent * dir; // For the directory entries
	chipindex = 0;
	while ((dir = readdir(d)) != NULL) // if we were able to read something from the directory
	{
		if(strcmp(dir->d_name,".")==0 || strcmp(dir->d_name,"..")==0 ) // if it is a directory
		{
			//printf("%s This is a directory\r\n", dir->d_name); // print its name in green
		}
		else
		{
			//printf("%s\n", dir->d_name);
			if(strstr(dir->d_name, "gpiochip") != NULL)
			{
				//printf("Found gpiochip\r\n");
				sprintf(chiplist[chipindex++], "%s%c", dir->d_name, '\0');
			}
		}
	}
	closedir(d); // finally close the directory

	//(2) Examine each /sys/class/gpio/gpiochipN/label field
	printf("Examining the fields in all /sys/class/gpio/gpiochipN/label locations:\r\n");
	iMIO0_Offset = 0;
	iAXI_MAX_Offset = 0;
	for (index=0;index<chipindex;index++)
	{
		//printf("%s\r\n", chiplist[index]);
		// Open the value property file for SW1.
		test_result = sprintf(formatted_file_name, "%s/%s/label", FILE_FORMAT_GPIO_PATH, chiplist[index]);
		if ((test_result < 0) ||
			(test_result == (char_buf_size - 1)))
		{
			printf("Error formatting string, check the GPIO specified\r\n");
			printf("%s", formatted_file_name);
			return -1;
		}
		fp = fopen(formatted_file_name, "r");
		retval=fscanf(fp, "%s", gpio_setting); //read "label" sub-directory
		printf("%s = %s\r\n", formatted_file_name, gpio_setting);
		strncpy(OffsetString, &chiplist[index][8],4); //Length of gpiochip=8
		OffsetString[4] = 0; //null terminate
		iOffset = atoi(OffsetString);
		//(3) Mark N for the gpiochipN label that reads "zynq_gpio" as the base for MIO#0
		if (!strcmp(gpio_setting, "zynq_gpio"))
		{
			iMIO0_Offset = iOffset;
			printf("Found the MIO[0] base = %d\r\n", iMIO0_Offset);
		}
		else
		{
			//(4) Look for the highest other N and assign that as the upper end of the AXI GPIO
			if (iOffset > iAXI_MAX_Offset)
			{
				iAXI_MAX_Offset = iOffset; //Keep track of the largest number that is not the MIO[0] base
			}
		}
		fclose(fp);
	}
	printf("Maximum AXI GPIO offset value = %d\r\n", iAXI_MAX_Offset);
	return(iMIO0_Offset);
} //get_gpio_base()

//Write the significant offset values to a file in the eMMC root so that scripts or other programs can pick them up there.
int write_offset_file(void)
{
    FILE  *fp;

	fp = fopen(FILENAME_GPIO_OFFSETS, "w");
	fprintf(fp, "MIO0_OFFSET=%d\n", iMIO0_Offset);
	fprintf(fp, "AXI_GPIO_MAX_OFFSET=%d\n", iAXI_MAX_Offset);
    fflush(fp);
    fclose(fp);
    printf("Offsets written to %s\r\n", FILENAME_GPIO_OFFSETS);
	return(0);
} //write_offset_file()

void assign_offsets(void)
{
	GPIO_OFFSET						= iMIO0_Offset;
	GPIO_PS_BUTTON_OFFSET			= iMIO0_Offset; //MIO#0
	GPIO_PS_LED_R_OFFSET			= iMIO0_Offset + 52; //MIO#52
	GPIO_PS_LED_G_OFFSET			= iMIO0_Offset + 53; //MIO#53
	GPIO_PL_LED_G_OFFSET			= iAXI_MAX_Offset; //pl_led_2bits(1)
	GPIO_PL_LED_R_OFFSET			= iAXI_MAX_Offset - 1; //pl_led_2bits(0)
	GPIO_PL_SWITCH_OFFSET			= iAXI_MAX_Offset - 2; //pl_sw_1bit
	GPIO_PL_MICROPHONE7_OFFSET		= iAXI_MAX_Offset - 3; //Bit 7 of AXI_GPIO to microphone
	GPIO_PL_MICROPHONE6_OFFSET		= iAXI_MAX_Offset - 4; //Bit 6 of AXI_GPIO to microphone
	GPIO_PL_MICROPHONE5_OFFSET		= iAXI_MAX_Offset - 5; //Bit 5 of AXI_GPIO to microphone
	GPIO_PL_MICROPHONE4_OFFSET		= iAXI_MAX_Offset - 6; //Bit 4 of AXI_GPIO to microphone
	GPIO_PL_MICROPHONE3_OFFSET		= iAXI_MAX_Offset - 7; //Bit 3 of AXI_GPIO to microphone
	GPIO_PL_MICROPHONE2_OFFSET		= iAXI_MAX_Offset - 8; //Bit 2 of AXI_GPIO to microphone
	GPIO_PL_MICROPHONE1_OFFSET		= iAXI_MAX_Offset - 9; //Bit 1 of AXI_GPIO to microphone
	GPIO_PL_MICROPHONE0_OFFSET		= iAXI_MAX_Offset - 10; //Bit 0 of AXI_GPIO to microphone
} //assign_offsets()


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
int main( int argc, char *argv[] )
{
	if (get_gpio_base())
	{
		write_offset_file();
		assign_offsets();
	}

	return 0;
} //main()


//Test code for the Dialog 9062 PMIC device on MiniZed that uses the I2C bus

#include <stdio.h>
#include <linux/i2c.h>
#include <linux/i2c-dev.h>
#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <string.h>
#include <termios.h>
#include <dirent.h>
#include <iostream>
#include <fstream>
#include <sstream>

#include <gpio/gpio.h>

int kbhit(void) {
    static bool initflag = false;
    static const int STDIN = 0;

    if (!initflag) {
        // Use termios to turn off line buffering
        struct termios term;
        tcgetattr(STDIN, &term);
        term.c_lflag &= ~ICANON;
        tcsetattr(STDIN, TCSANOW, &term);
        setbuf(stdin, NULL);
        initflag = true;
    }

    int nbbytes;
    ioctl(STDIN, FIONREAD, &nbbytes);  // 0 is STDIN
    return nbbytes;
}

#define u8	unsigned char
#define u16 unsigned short
#define I2C_DEVICE_NAME "xiic-i2c"

// The following constant defines the address of the IIC device on the IIC bus.  Note that since
// the address is only 7 bits, this  constant is the address divided by 2.
#define MAGNETOMETER_ADDRESS  0x1E /* LIS3MDL on Arduino shield */
#define MINIZED_MOTION_SENSOR_ADDRESS_SA0_LO  0x1E /* 0011110b for LIS2DS12 on MiniZed when SA0 is pulled low*/
#define MINIZED_MOTION_SENSOR_ADDRESS_SA0_HI  0x1D /* 0011101b for LIS2DS12 on MiniZed when SA0 is pulled high*/
#define DIALOG_PMIC_ADDRESS  0x58 /* 0xB0 >> 1 */

#define LIS2DS12_ACC_WHO_AM_I         0x43
/************** Device Register  *******************/
#define LIS2DS12_ACC_SENSORHUB_OUT1  	0X06
#define LIS2DS12_ACC_SENSORHUB_OUT2  	0X07
#define LIS2DS12_ACC_SENSORHUB_OUT3  	0X08
#define LIS2DS12_ACC_SENSORHUB_OUT4  	0X09
#define LIS2DS12_ACC_SENSORHUB_OUT5  	0X0A
#define LIS2DS12_ACC_SENSORHUB_OUT6  	0X0B
#define LIS2DS12_ACC_MODULE_8BIT  	0X0C
#define LIS2DS12_ACC_WHO_AM_I_REG  	0X0F
#define LIS2DS12_ACC_CTRL1  	0X20
#define LIS2DS12_ACC_CTRL2  	0X21
#define LIS2DS12_ACC_CTRL3  	0X22
#define LIS2DS12_ACC_CTRL4  	0X23
#define LIS2DS12_ACC_CTRL5  	0X24
#define LIS2DS12_ACC_FIFO_CTRL  	0X25
#define LIS2DS12_ACC_OUT_T  	0X26
#define LIS2DS12_ACC_STATUS  	0X27
#define LIS2DS12_ACC_OUT_X_L  	0X28
#define LIS2DS12_ACC_OUT_X_H  	0X29
#define LIS2DS12_ACC_OUT_Y_L  	0X2A
#define LIS2DS12_ACC_OUT_Y_H  	0X2B
#define LIS2DS12_ACC_OUT_Z_L  	0X2C
#define LIS2DS12_ACC_OUT_Z_H  	0X2D
#define LIS2DS12_ACC_FIFO_THS  	0X2E
#define LIS2DS12_ACC_FIFO_SRC  	0X2F
#define LIS2DS12_ACC_FIFO_SAMPLES  	0X30
#define LIS2DS12_ACC_TAP_6D_THS  	0X31
#define LIS2DS12_ACC_INT_DUR  	0X32
#define LIS2DS12_ACC_WAKE_UP_THS  	0X33
#define LIS2DS12_ACC_WAKE_UP_DUR  	0X34
#define LIS2DS12_ACC_FREE_FALL  	0X35
#define LIS2DS12_ACC_STATUS_DUP  	0X36
#define LIS2DS12_ACC_WAKE_UP_SRC  	0X37
#define LIS2DS12_ACC_TAP_SRC  	0X38
#define LIS2DS12_ACC_6D_SRC  	0X39
#define LIS2DS12_ACC_STEP_C_MINTHS  	0X3A
#define LIS2DS12_ACC_STEP_C_L  	0X3B
#define LIS2DS12_ACC_STEP_C_H  	0X3C
#define LIS2DS12_ACC_FUNC_CK_GATE  	0X3D
#define LIS2DS12_ACC_FUNC_SRC  	0X3E
#define LIS2DS12_ACC_FUNC_CTRL  	0X3F

u8 send_byte;
u8 write_data [256];
u8 read_data [256];

int i2c_file;
useconds_t delay = 2000; //2ms
u8 i2c_device_addr = MINIZED_MOTION_SENSOR_ADDRESS_SA0_HI; //by default

static int set_i2c_register(int file,
                            unsigned char addr,
                            unsigned char reg,
                            unsigned char value) {

    unsigned char outbuf[2];
    struct i2c_rdwr_ioctl_data packets;
    struct i2c_msg messages[1];

    messages[0].addr  = addr;
    messages[0].flags = 0;
    messages[0].len   = sizeof(outbuf);
    messages[0].buf   = outbuf;

    /* The first byte indicates which register we'll write */
    outbuf[0] = reg;

    /*
     * The second byte indicates the value to write.  Note that for many
     * devices, we can write multiple, sequential registers at once by
     * simply making outbuf bigger.
     */
    outbuf[1] = value;

    /* Transfer the i2c packets to the kernel and verify it worked */
    packets.msgs  = messages;
    packets.nmsgs = 1;
    if(ioctl(file, I2C_RDWR, &packets) < 0) {
        perror("Unable to send I2C data");
        return 1;
    }

    return 0;
}


static int get_i2c_register(int file,
                            unsigned char addr,
                            unsigned char reg,
                            unsigned char *val) {
    unsigned char inbuf, outbuf;
    struct i2c_rdwr_ioctl_data packets;
    struct i2c_msg messages[2];

    /*
     * In order to read a register, we first do a "dummy write" by writing
     * 0 bytes to the register we want to read from.  This is similar to
     * the packet in set_i2c_register, except it's 1 byte rather than 2.
     */
    outbuf = reg;
    messages[0].addr  = addr;
    messages[0].flags = 0;
    messages[0].len   = sizeof(outbuf);
    messages[0].buf   = &outbuf;

    /* The data will get returned in this structure */
    messages[1].addr  = addr;
    messages[1].flags = I2C_M_RD/* | I2C_M_NOSTART*/;
    messages[1].len   = sizeof(inbuf);
    messages[1].buf   = &inbuf;

    /* Send the request to the kernel and get the result back */
    packets.msgs      = messages;
    packets.nmsgs     = 2;
    if(ioctl(file, I2C_RDWR, &packets) < 0) {
        perror("Unable to send I2C data");
        return 1;
    }
    *val = inbuf;

    return 0;
}


u8 LIS2DS12_WriteReg(u8 Reg, u8 *Bufp, u16 len)
{
	if(set_i2c_register(i2c_file, i2c_device_addr, Reg, (u8)(Bufp[0])))
    {
        printf("Unable to set I2C register!\n");
        return (1);
    }
	return(0);
}

u8 Dialog_WriteReg(u8 Reg, u8 *Bufp, u16 len)
{
	if(set_i2c_register(i2c_file, i2c_device_addr, Reg, (u8)(Bufp[0])))
    {
        printf("Unable to set I2C register!\n");
        return (1);
    }
	return(0);
}

u8 LIS2DS12_ReadReg(u8 Reg, u8 *Bufp, u16 len)
{
    if(get_i2c_register(i2c_file, i2c_device_addr, Reg, &Bufp[0]))
    {
        printf("Unable to get I2C register!\n");
        return (1);
    }
	return(0);
}

u8 Dialog_ReadReg(u8 Reg, u8 *Bufp, u16 len)
{
    if(get_i2c_register(i2c_file, i2c_device_addr, Reg, &Bufp[0]))
    {
        printf("Unable to get I2C register!\n");
        return (1);
    }
	return(0);
}

#define DIALOG_RTC_COUNT_S_REG  	0X040
#define DIALOG_RTC_COUNT_MI_REG  	0X041
#define DIALOG_RTC_COUNT_H_REG  	0X042
#define DIALOG_RTC_COUNT_D_REG  	0X043
#define DIALOG_RTC_COUNT_MO_REG  	0X044
#define DIALOG_RTC_COUNT_Y_REG  	0X045
#define DIALOG_BUCK1_CFG_REG  	    0X09E
#define DIALOG_BUCK2_CFG_REG  	    0X09D
#define DIALOG_BUCK3_CFG_REG  	    0X0A0


int Dialog_modes_read(void)
{
	u8 dialog_value = 0;
	u8 dialog_buck1_cfg;
	u8 dialog_buck2_cfg;
	u8 dialog_buck3_cfg;

	i2c_device_addr = DIALOG_PMIC_ADDRESS;
	if (Dialog_ReadReg(DIALOG_BUCK1_CFG_REG, &dialog_value, 1) > 0)
	{
		return (1);
	}
	dialog_buck1_cfg = dialog_value;
	printf("With I2C device address 0x%02X and register address 0x%02X Dialog BUCK1_CFG = 0x%02X\r\n", i2c_device_addr, DIALOG_BUCK1_CFG_REG, dialog_buck1_cfg);
	Dialog_ReadReg(DIALOG_BUCK2_CFG_REG, &dialog_value, 1);
	dialog_buck2_cfg = dialog_value;
	printf("With I2C device address 0x%02X and register address 0x%02X Dialog BUCK2_CFG = 0x%02X\r\n", i2c_device_addr, DIALOG_BUCK2_CFG_REG, dialog_buck2_cfg);
	Dialog_ReadReg(DIALOG_BUCK3_CFG_REG, &dialog_value, 1);
	dialog_buck3_cfg = dialog_value;
	printf("With I2C device address 0x%02X and register address 0x%02X Dialog BUCK3_CFG = 0x%02X\r\n", i2c_device_addr, DIALOG_BUCK3_CFG_REG, dialog_buck3_cfg);

	fflush(stdout); // Prints to screen or whatever your standard out is
	return (0);
} //Dialog_modes_read()

void Dialog_modes_write(unsigned char ucmode)
{
	i2c_device_addr = DIALOG_PMIC_ADDRESS;
	//u8 send_byte = 0x80; //Synchronous (PWM mode)
	u8 send_byte = ucmode;
	Dialog_WriteReg(DIALOG_BUCK1_CFG_REG, &send_byte, 1);
	Dialog_WriteReg(DIALOG_BUCK2_CFG_REG, &send_byte, 1);
	Dialog_WriteReg(DIALOG_BUCK3_CFG_REG, &send_byte, 1);

	printf("With I2C device address 0x%02x BUCK registers set to 0x%02x\r\n", i2c_device_addr, send_byte);
	fflush(stdout); // Prints to screen or whatever your standard out is

} //Dialog_modes_write()

void Dialog_time_read(void)
{
	u8 dialog_value = 0;
	u8 dialog_seconds = 0;
	u8 dialog_minutes = 0;
	u8 dialog_hour = 0;
	u8 dialog_day = 0;
	u8 dialog_month = 0;
	u8 dialog_year = 0;

	i2c_device_addr = DIALOG_PMIC_ADDRESS;
	Dialog_ReadReg(DIALOG_RTC_COUNT_S_REG, &dialog_value, 1);
	dialog_seconds = dialog_value & 0x3F; //Only 6 bits are valid (MSB = 1 => READY)
	Dialog_ReadReg(DIALOG_RTC_COUNT_MI_REG, &dialog_value, 1);
	dialog_minutes = dialog_value & 0x3F; //Only 6 bits are valid
	Dialog_ReadReg(DIALOG_RTC_COUNT_H_REG, &dialog_value, 1);
	dialog_hour = dialog_value & 0x1F; //Only 5 bits are valid
	Dialog_ReadReg(DIALOG_RTC_COUNT_D_REG, &dialog_value, 1);
	dialog_day = dialog_value & 0x1F; //Only 5 bits are valid
	Dialog_ReadReg(DIALOG_RTC_COUNT_MO_REG, &dialog_value, 1);
	dialog_month = dialog_value & 0x0F; //Only 4 bits are valid
	Dialog_ReadReg(DIALOG_RTC_COUNT_Y_REG, &dialog_value, 1);
	dialog_year = dialog_value & 0x3F; //Only 6 bits are valid
	printf("With I2C device address 0x%02x Dialog date & time = 20%02d/%02d/%02d %02d:%02d:%02d\r", i2c_device_addr, dialog_year, dialog_month, dialog_day, dialog_hour, dialog_minutes, dialog_seconds);
	fflush(stdout); // Prints to screen or whatever your standard out is

} //Dialog_time_read()

void Dialog_time_reset(void)
{
	i2c_device_addr = DIALOG_PMIC_ADDRESS;
	u8 send_byte = 0x00; //reset to 0
	Dialog_WriteReg(DIALOG_RTC_COUNT_S_REG, &send_byte, 1);
	Dialog_WriteReg(DIALOG_RTC_COUNT_MI_REG, &send_byte, 1);
	Dialog_WriteReg(DIALOG_RTC_COUNT_H_REG, &send_byte, 1);

	send_byte = 0x01; //1st
	Dialog_WriteReg(DIALOG_RTC_COUNT_D_REG, &send_byte, 1);
	send_byte = 0x08; //August
	Dialog_WriteReg(DIALOG_RTC_COUNT_MO_REG, &send_byte, 1);
	send_byte = 17; //2017
	Dialog_WriteReg(DIALOG_RTC_COUNT_Y_REG, &send_byte, 1);

	printf("\nDialog RTC has been reset to midnight Aug 1st, 2017\r\n");
	fflush(stdout); // Prints to screen or whatever your standard out is

} //Dialog_time_reset()

void sensor_init(void)
{
	u8 who_am_i = 0;

	i2c_device_addr = MINIZED_MOTION_SENSOR_ADDRESS_SA0_HI; //default
	LIS2DS12_ReadReg(LIS2DS12_ACC_WHO_AM_I_REG, &who_am_i, 1);
	//printf("With I2C device address 0x%02x received WhoAmI = 0x%02x\r\n", i2c_device_addr, who_am_i);
	if (who_am_i != LIS2DS12_ACC_WHO_AM_I)
	{
		//maybe the address bit was changed, try the other one:
		i2c_device_addr = MINIZED_MOTION_SENSOR_ADDRESS_SA0_LO;
		LIS2DS12_ReadReg(LIS2DS12_ACC_WHO_AM_I_REG, &who_am_i, 1);
		//printf("With I2C device address 0x%02x received WhoAmI = 0x%02x\r\n", i2c_device_addr, who_am_i);
	}
	send_byte = 0x00; //No auto increment
	LIS2DS12_WriteReg(LIS2DS12_ACC_CTRL2, &send_byte, 1);


	//Write 60h in CTRL1	// Turn on the accelerometer.  14-bit mode, ODR = 400 Hz, FS = 2g
	send_byte = 0x60;
	LIS2DS12_WriteReg(LIS2DS12_ACC_CTRL1, &send_byte, 1);
	//printf("CTL1 = 0x60 written\r\n");

	//Enable interrupt
	send_byte = 0x01; //Acc data-ready interrupt on INT1
	LIS2DS12_WriteReg(LIS2DS12_ACC_CTRL4, &send_byte, 1);
	//printf("CTL4 = 0x01 written\r\n");

#if (0)
	write_data[0] = 0x0F; //WhoAmI
	ByteCount = XIic_Send(IIC_BASE_ADDRESS, MAGNETOMETER_ADDRESS, (u8*)&write_data, 1, XIIC_REPEATED_START);
	ByteCount = XIic_Recv(IIC_BASE_ADDRESS, MAGNETOMETER_ADDRESS, (u8*)&read_data[0], 1, XIIC_STOP);
	printf("Received 0x%02x\r\n",read_data[0]);
	printf("\r\n"); //Empty line
	//for (int n=0;n<1400;n++) //118 ms is too little
	for (int n=0;n<1500;n++) //128 ms
	{
		printf(".");
	};
	printf("\r\n");
#endif
} //sensor_init()

void read_temperature(void)
{
	int temp;
	u8 read_value;

	LIS2DS12_ReadReg(LIS2DS12_ACC_OUT_T, &read_value, 1);
	//Temperature is from -40 to +85 deg C.  So 125 range.  0 is 25 deg C.  +1 deg C/LSB.  So if value < 128 temp = 25 + value else temp = 25 - (256-value)
	if (read_value < 128)
	{
		temp = 25 + read_value;
	}
	else
	{
		temp = 25 - (256 - read_value);
	}
	printf(" OUT_T register = 0x%02x -> Temperature = %i degrees C.  ",read_value,temp);
	//printf("OUT_T register = 0x%02x -> Temperature = %i degrees C\r\n",read_value,temp);
} //read_temperature()

int u16_2s_complement_to_int(u16 word_to_convert)
{
	u16 result_16bit;
	int result_14bit;
	int sign;

	if (word_to_convert & 0x8000)
	{ //MSB is set, negative number
		//Invert and add 1
		sign = -1;
		result_16bit = (~word_to_convert) + 1;
	}
	else
	{ //Positive number
		//No change
		sign = 1;
		result_16bit = word_to_convert;
	}
	//We are using it in 14-bit mode
	//All data is left-aligned.  So convert 16-bit value to 14-but value
	result_14bit = sign * (int)(result_16bit >> 2);
	return(result_14bit);
} //u16_2s_complement_to_int()

void read_motion(void)
{
	int iacceleration_X;
	int iacceleration_Y;
	int iacceleration_Z;
	u8 read_value_LSB;
	u8 read_value_MSB;
	u16 accel_X;
	u16 accel_Y;
	u16 accel_Z;
	u8 accel_status;
	u8 data_ready;

	data_ready = 0;
	while (!data_ready)
	{ //wait for DRDY
		LIS2DS12_ReadReg(LIS2DS12_ACC_STATUS, &accel_status, 1);
		data_ready = accel_status & 0x01; //bit 0 = DRDY
        usleep(5); //micro seconds
	} //wait for DRDY


	//Read X:
	LIS2DS12_ReadReg(LIS2DS12_ACC_OUT_X_L, &read_value_LSB, 1);
	LIS2DS12_ReadReg(LIS2DS12_ACC_OUT_X_H, &read_value_MSB, 1);
	accel_X = (read_value_MSB << 8) + read_value_LSB;
	iacceleration_X = u16_2s_complement_to_int(accel_X);
	//Read Y:
	LIS2DS12_ReadReg(LIS2DS12_ACC_OUT_Y_L, &read_value_LSB, 1);
	LIS2DS12_ReadReg(LIS2DS12_ACC_OUT_Y_H, &read_value_MSB, 1);
	accel_Y = (read_value_MSB << 8) + read_value_LSB;
	iacceleration_Y = u16_2s_complement_to_int(accel_Y);
	//Read Z:
	LIS2DS12_ReadReg(LIS2DS12_ACC_OUT_Z_L, &read_value_LSB, 1);
	LIS2DS12_ReadReg(LIS2DS12_ACC_OUT_Z_H, &read_value_MSB, 1);
	accel_Z = (read_value_MSB << 8) + read_value_LSB;
	iacceleration_Z = u16_2s_complement_to_int(accel_Z);

//	printf("  Acceleration = X: %+5d, Y: %+5d, Z: %+5d\r\n",iacceleration_X, iacceleration_Y, iacceleration_Z);
	printf("  Acceleration = X: %+5d, Y: %+5d, Z: %+5d\r",iacceleration_X, iacceleration_Y, iacceleration_Z);
} //read_motion()

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
#define GPIO_PS_BUTTON			"PS_BUTTON"
#define GPIO_PS_LED_R			"PS_R"
#define GPIO_PS_LED_G			"PS_G"
#define GPIO_PL_LED_R			"PL_R"
#define GPIO_PL_LED_G			"PL_G"
#define GPIO_PL_SWITCH			"PL_SWITCH"
#define GPIO_PL_MICROPHONE7		"PL_MIC7"
#define GPIO_PL_MICROPHONE6		"PL_MIC6"
#define GPIO_PL_MICROPHONE5		"PL_MIC5"
#define GPIO_PL_MICROPHONE4		"PL_MIC4"
#define GPIO_PL_MICROPHONE3		"PL_MIC3"
#define GPIO_PL_MICROPHONE2		"PL_MIC2"
#define GPIO_PL_MICROPHONE1		"PL_MIC1"
#define GPIO_PL_MICROPHONE0		"PL_MIC0"

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

#define LED_COLOR_OFF	0
#define LED_COLOR_GREEN	1
#define LED_COLOR_RED	2
#define LED_COLOR_AMBER	3

int configure_gpio(int gpio_offset, unsigned char gpio_direction)
{
	char gpio_setting[8];
	int test_result = 0;
	const int char_buf_size = 80;
	char formatted_file_name[char_buf_size];
   int retval;
	FILE  *fp;

	// Open the export file and write the PSGPIO number for each Pmod GPIO
	// signal to the Linux sysfs GPIO export property, then close the file.
	fp = fopen(FILE_FORMAT_GPIO_PATH FILE_FORMAT_GPIO_EXPORT, "w");
	if (fp == NULL)
	{
		printf("Error opening /sys/class/gpio/export node\n");
		return -1;
	}
	else
	{
		// Set the value property for the export to the GPIO number.
		sprintf(gpio_setting, "%d", gpio_offset);
		fwrite(&gpio_setting, sizeof(char), strlen(gpio_setting), fp);
		fflush(fp);
		fclose(fp);
	}

	// Set the direction property of the GPIO number
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH "/gpio%d" FILE_FORMAT_GPIO_DIRECTION, gpio_offset);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);
		return -1;
	}
	fp = fopen(formatted_file_name, "w");
	if (fp == NULL)
	{
		printf("Error opening %s\n", formatted_file_name);
		return -1;
	}
	else
	{
		if (gpio_direction == GPIO_DIRECTION_INPUT)
		{
			fwrite("in", sizeof(char), 2, fp);
		}
		else
		{ //GPIO_DIRECTION_OUTPUT
			fwrite("out", sizeof(char), 3, fp);
		}
		fflush(fp);
		fclose(fp);
	}

	// Check the direction property of the GPIO number
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH "/gpio%d" FILE_FORMAT_GPIO_DIRECTION, gpio_offset);
	fp = fopen(formatted_file_name, "r+");
	if (fp == NULL)
	{
		printf("Error opening " FILE_FORMAT_GPIO_PATH "/gpio%d" FILE_FORMAT_GPIO_DIRECTION " node\n", gpio_offset);
		return -1;
	}
	else
	{
		retval=fscanf(fp, "%s", gpio_setting);
		printf("gpio%d set as %s\n", gpio_offset, gpio_setting);
		fflush(fp);
		fclose(fp);
	}
	return test_result;
} //configure_gpio()

int set_gpio_value(int gpio_offset, unsigned char gpio_value)
{
	const int char_buf_size = 80;
    char gpio_setting[5];
    int test_result = 0;
    char formatted_file_name[char_buf_size];

    FILE  *fp_led;

    // Open the gpio value properties so that they can be read/written.
    test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH "/gpio%d" FILE_FORMAT_GPIO_VALUE, gpio_offset);
    if ((test_result < 0) ||
        (test_result == (char_buf_size - 1)))
    {
        printf("Error formatting string, check the GPIO specified\r\n");
        printf("%s", formatted_file_name);
        return -1;
    }
    fp_led = fopen(formatted_file_name, "r+");
	// Now turn the specified LED ON.
    sprintf(gpio_setting, "%d", gpio_value);
	//strcpy(gpio_setting, "1");
    fwrite(&gpio_setting, sizeof(char), 1, fp_led);
    fflush(fp_led);
    // Close the GPIO value property files.
    fclose(fp_led);
    return test_result;
} //set_gpio_value()

void set_PS_LED_color(unsigned char led_color)
{
	switch(led_color)
	{
		case LED_COLOR_OFF :
			set_gpio_value(GPIO_PS_LED_R_OFFSET, 0); //Red LED off
			set_gpio_value(GPIO_PS_LED_G_OFFSET, 0); //Green LED off
			break;
		case LED_COLOR_GREEN :
			set_gpio_value(GPIO_PS_LED_R_OFFSET, 0); //Red LED off
			set_gpio_value(GPIO_PS_LED_G_OFFSET, 1); //Green LED on
			break;
		case LED_COLOR_RED :
			set_gpio_value(GPIO_PS_LED_R_OFFSET, 1); //Red LED on
			set_gpio_value(GPIO_PS_LED_G_OFFSET, 0); //Green LED off
			break;
		case LED_COLOR_AMBER :
			set_gpio_value(GPIO_PS_LED_R_OFFSET, 1); //Red LED on
			set_gpio_value(GPIO_PS_LED_G_OFFSET, 1); //Green LED on
			break;
		default : /* Error */
			//Do nothing
			break;
	} //switch(led_color)
} //set_PS_LED_color()

void set_PL_LED_color(unsigned char led_color)
{
	switch(led_color)
	{
		case LED_COLOR_OFF :
			set_gpio_value(GPIO_PL_LED_R_OFFSET, 0); //Red LED off
			set_gpio_value(GPIO_PL_LED_G_OFFSET, 0); //Green LED off
			break;
		case LED_COLOR_GREEN :
			set_gpio_value(GPIO_PL_LED_R_OFFSET, 0); //Red LED off
			set_gpio_value(GPIO_PL_LED_G_OFFSET, 1); //Green LED on
			break;
		case LED_COLOR_RED :
			set_gpio_value(GPIO_PL_LED_R_OFFSET, 1); //Red LED on
			set_gpio_value(GPIO_PL_LED_G_OFFSET, 0); //Green LED off
			break;
		case LED_COLOR_AMBER :
			set_gpio_value(GPIO_PL_LED_R_OFFSET, 1); //Red LED on
			set_gpio_value(GPIO_PL_LED_G_OFFSET, 1); //Green LED on
			break;
		default : /* Error */
			//Do nothing
			break;
	} //switch(led_color)
} //set_PL_LED_color()

int get_gpio_value(int gpio_offset)
{
	const int char_buf_size = 80;
    char gpio_setting[5];
    int test_result = 0;
    char formatted_file_name[char_buf_size];

	int sw1_value;
	FILE  *fp_sw1;

	// Open the gpio value properties so that they can be read/written.

	// Open the value property file for SW1.
	test_result = snprintf(formatted_file_name, (char_buf_size - 1), FILE_FORMAT_GPIO_PATH "/gpio%d" FILE_FORMAT_GPIO_VALUE, gpio_offset);
	if ((test_result < 0) ||
		(test_result == (char_buf_size - 1)))
	{
		printf("Error formatting string, check the GPIO specified\r\n");
		printf("%s", formatted_file_name);
		return -1;
	}
	fp_sw1 = fopen(formatted_file_name, "r+");

	// Read the current value of the SW1 GPIO input.
	fscanf(fp_sw1, "%s", gpio_setting);

	if (!strcmp(gpio_setting, "1"))
		sw1_value = 1;
	else if (!strcmp(gpio_setting, "0"))
		sw1_value = 0;

	// Close the GPIO value property files.
	fclose(fp_sw1);

	return sw1_value;
} //get_gpio_value()

unsigned char get_PS_button_value(void)
{
	unsigned char value;
	value = get_gpio_value(GPIO_PS_BUTTON_OFFSET);
	return(value);
} //get_PS_button_value()

unsigned char get_PL_switch_value(void)
{
	unsigned char value;
	value = get_gpio_value(GPIO_PL_SWITCH_OFFSET);
	return(value);
} //get_PL_switch_value()

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
		fscanf(fp, "%s", gpio_setting); //read "label" sub-directory
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
	GPIO_PS_BUTTON_OFFSET			= get_gpio_cpp(GPIO_PS_BUTTON); //ps_button_1bit
	GPIO_PS_LED_R_OFFSET			= get_gpio_cpp(GPIO_PS_LED_R); //ps_led_2bits(0)
	GPIO_PS_LED_G_OFFSET			= get_gpio_cpp(GPIO_PS_LED_G); //ps_led_2bits(1)
	GPIO_PL_LED_G_OFFSET			= get_gpio_cpp(GPIO_PL_LED_G); //pl_led_2bits(1)
	GPIO_PL_LED_R_OFFSET			= get_gpio_cpp(GPIO_PL_LED_R); //pl_led_2bits(0)
	GPIO_PL_SWITCH_OFFSET			= get_gpio_cpp(GPIO_PL_SWITCH); //pl_sw_1bit
	GPIO_PL_MICROPHONE7_OFFSET		= get_gpio_cpp(GPIO_PL_MICROPHONE7); //Bit 7 of AXI_GPIO to microphone
	GPIO_PL_MICROPHONE6_OFFSET		= get_gpio_cpp(GPIO_PL_MICROPHONE6); //Bit 6 of AXI_GPIO to microphone
	GPIO_PL_MICROPHONE5_OFFSET		= get_gpio_cpp(GPIO_PL_MICROPHONE5); //Bit 5 of AXI_GPIO to microphone
	GPIO_PL_MICROPHONE4_OFFSET		= get_gpio_cpp(GPIO_PL_MICROPHONE4); //Bit 4 of AXI_GPIO to microphone
	GPIO_PL_MICROPHONE3_OFFSET		= get_gpio_cpp(GPIO_PL_MICROPHONE3); //Bit 3 of AXI_GPIO to microphone
	GPIO_PL_MICROPHONE2_OFFSET		= get_gpio_cpp(GPIO_PL_MICROPHONE2); //Bit 2 of AXI_GPIO to microphone
	GPIO_PL_MICROPHONE1_OFFSET		= get_gpio_cpp(GPIO_PL_MICROPHONE1); //Bit 1 of AXI_GPIO to microphone
	GPIO_PL_MICROPHONE0_OFFSET		= get_gpio_cpp(GPIO_PL_MICROPHONE0); //Bit 0 of AXI_GPIO to microphone
} //assign_offsets()

int get_i2c_file_name(char * i2c_filename, size_t len)
{
       if(i2c_filename == NULL || len < 10)
               return -1;

       for(int i = 0; i < 2; i++) {
               std::ostringstream device_name_filename;
               device_name_filename << "/sys/bus/i2c/devices/i2c-" << i << "/name";

               std::ifstream device_name_file(device_name_filename.str());
               std::string device_name;
               std::getline(device_name_file, device_name);
               if(device_name.compare(I2C_DEVICE_NAME) == 0)
                       return sprintf(i2c_filename, "/dev/i2c-%d", i) < 0 ? -1 : 0;
       }
       return -1;
} //get_i2c_file_name()

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
int main( int argc, char *argv[] )
{
	#define LOOP_DELAY_MS 20
	int iTimeout_secs = 1;
	int iTime_remaining_ms = iTimeout_secs * 1000;
	bool bUserEnteredTimeout;
	bool bKeyPressed = false;
	char chkey;
    char i2c_file_name[11];

	assign_offsets();

	printf("################################################################################\n");
	printf("Ready to change the MiniZed Dialog DA9062 PMIC Buck Regulator mode\n");
	printf("--------------------------------------------------------------------------------\n");
	printf("The PS Button will reset the Dialog RTC time to midnight August 1st, 2017\n");
	printf("The P key will change the mode to PWM  (0x80) for BUCK1, BUCK2 & BUCK3\n");
	printf("The A key will change the mode to Auto (0xC0) for BUCK1, BUCK2 & BUCK3\n");
	printf("Any other key to exit without change\n");
	printf("################################################################################\n");
	//See if a timeout in seconds was specified as a command line argument:
	if(argc<=1)
	{
		//printf("No user arguments: Will loop forever.\n");
		bUserEnteredTimeout = false;
	}
	else
	{
		iTimeout_secs = atoi(argv[1]);  //argv[0] is the program name
		iTime_remaining_ms = iTimeout_secs * 1000;
		printf("User specified timeout = %i seconds.\n", iTimeout_secs);
		bUserEnteredTimeout = true;
	}

    if(get_i2c_file_name(i2c_file_name, sizeof(i2c_file_name)) < 0) {
        perror("Unable to get I2C control file name");
        exit(1);
    }

	// Open a connection to the I2C userspace control file.
    if ((i2c_file = open(i2c_file_name, O_RDWR)) < 0) {
        perror("Unable to open I2C control file");
        exit(1);
    }
	sensor_init();

	configure_gpio(GPIO_PL_SWITCH_OFFSET, GPIO_DIRECTION_INPUT);
	configure_gpio(GPIO_PS_BUTTON_OFFSET, GPIO_DIRECTION_INPUT);
	configure_gpio(GPIO_PS_LED_R_OFFSET, GPIO_DIRECTION_OUTPUT);
	configure_gpio(GPIO_PS_LED_G_OFFSET, GPIO_DIRECTION_OUTPUT);
	configure_gpio(GPIO_PL_LED_R_OFFSET, GPIO_DIRECTION_OUTPUT);
	configure_gpio(GPIO_PL_LED_G_OFFSET, GPIO_DIRECTION_OUTPUT);
	//configure_gpio(GPIO_PL_MICROPHONE0_OFFSET, GPIO_DIRECTION_OUTPUT);
	//configure_gpio(GPIO_PL_MICROPHONE1_OFFSET, GPIO_DIRECTION_OUTPUT);

	unsigned int free_count = 0;
	unsigned int led_count = 0;
	unsigned char led_counter_select = 0;
	unsigned char led_counter_select_history;
	//These are inverted, since we want the default switch position to select the microphone
	led_counter_select = get_PL_switch_value() ^ 1; //XOR
	//set_gpio_value(GPIO_PL_MICROPHONE1_OFFSET, led_counter_select);
	led_counter_select_history = led_counter_select;

	if (Dialog_modes_read() >0 )  //Display the BUCK modes
	{
		printf("Dialog device error or not present.\n");
		fflush(stdout); // Prints to screen or whatever your standard out is
		close(i2c_file);
		return 0;
	}
	//while (1) //forever
	while (iTime_remaining_ms > 0)
	{
		//Echo not switch on microphone GPIO bit 1:
		led_counter_select = get_PL_switch_value() ^ 1; //XOR
		if (led_counter_select_history != led_counter_select)
		{ //only update when there is a change:
			set_gpio_value(GPIO_PL_MICROPHONE1_OFFSET, led_counter_select);
			led_counter_select_history = led_counter_select;
		}
		//reset the count when the button is pushed:
		if (get_PS_button_value() == 1)
		{
			free_count = 0;
			while (get_PS_button_value() == 1)
			{} //wait for button release
			Dialog_time_reset();
		}
		led_count = (free_count & 0x0F0) >> 4;
		//Show a binary counter on the two LEDs:
		switch(led_count)
		{
			case 0x00 :
				set_PL_LED_color(LED_COLOR_OFF);
				set_PS_LED_color(LED_COLOR_OFF);
				break;
			case 0x01 :
				set_PL_LED_color(LED_COLOR_OFF);
				set_PS_LED_color(LED_COLOR_RED);
				break;
			case 0x02 :
				set_PL_LED_color(LED_COLOR_OFF);
				set_PS_LED_color(LED_COLOR_GREEN);
				break;
			case 0x03 :
				set_PL_LED_color(LED_COLOR_OFF);
				set_PS_LED_color(LED_COLOR_AMBER);
				break;
			case 0x04 :
				set_PL_LED_color(LED_COLOR_RED);
				set_PS_LED_color(LED_COLOR_OFF);
				break;
			case 0x05 :
				set_PL_LED_color(LED_COLOR_RED);
				set_PS_LED_color(LED_COLOR_RED);
				break;
			case 0x06 :
				set_PL_LED_color(LED_COLOR_RED);
				set_PS_LED_color(LED_COLOR_GREEN);
				break;
			case 0x07 :
				set_PL_LED_color(LED_COLOR_RED);
				set_PS_LED_color(LED_COLOR_AMBER);
				break;
			case 0x08 :
				set_PL_LED_color(LED_COLOR_GREEN);
				set_PS_LED_color(LED_COLOR_OFF);
				break;
			case 0x09 :
				set_PL_LED_color(LED_COLOR_GREEN);
				set_PS_LED_color(LED_COLOR_RED);
				break;
			case 0x0A :
				set_PL_LED_color(LED_COLOR_GREEN);
				set_PS_LED_color(LED_COLOR_GREEN);
				break;
			case 0x0B :
				set_PL_LED_color(LED_COLOR_GREEN);
				set_PS_LED_color(LED_COLOR_AMBER);
				break;
			case 0x0C :
				set_PL_LED_color(LED_COLOR_AMBER);
				set_PS_LED_color(LED_COLOR_OFF);
				break;
			case 0x0D :
				set_PL_LED_color(LED_COLOR_AMBER);
				set_PS_LED_color(LED_COLOR_RED);
				break;
			case 0x0E :
				set_PL_LED_color(LED_COLOR_AMBER);
				set_PS_LED_color(LED_COLOR_GREEN);
				break;
			case 0x0F :
				set_PL_LED_color(LED_COLOR_AMBER);
				set_PS_LED_color(LED_COLOR_AMBER);
				break;
			default : /* Error */
				//Do nothing
				break;
		} //switch(led_color)
		fflush(stdout); //you need to do this before you sleep
		usleep(20000); //20 ms
		free_count++;
		//if ((free_count & 0x1F) == 0x1F) //Every 31*20ms = 0.62 seconds
		if ((free_count & 0x0F) == 0x0F) //Every 15*20ms = 0.31 seconds
		{
			i2c_device_addr = MINIZED_MOTION_SENSOR_ADDRESS_SA0_HI; //default
			//read_temperature();
			//read_motion();
			Dialog_time_read();
		}
		if (bUserEnteredTimeout)
		{
			iTime_remaining_ms -= LOOP_DELAY_MS;
		}

	    if (kbhit())
		{
	    	bKeyPressed = true;
			chkey = getchar();
			//printf("\nChar received:%c\n", chkey);
			break;
		}

	} //while (timeout)
	printf("\n******************************************************************************\n");
	if (bKeyPressed)
	{
		int intkey = (int)chkey;
		if (chkey == ' ')
		{
			printf("Dialog control utility interrupted by the SPACE key.\n");
		}
		else if ((chkey == 'P') || (chkey == 'p'))
		{
			printf("Changing modes for PWM (0x80):\n");
			Dialog_modes_write(0x80);
			Dialog_modes_read();
			printf("Done.\n");
		}
		else if ((chkey == 'A') || (chkey == 'a'))
		{
			printf("Changing modes for Auto: (0xC0)\n");
			Dialog_modes_write(0xC0);
			Dialog_modes_read();
			printf("Done.\n");
		}
		else if ((intkey == 0x0A) || (intkey == 0x0D))
		{
			printf("Dialog control utility interrupted by the ENTER key.\n");
		}
		else if (intkey == 0x1B)
		{
			printf("Dialog control utility interrupted by the ESCAPE key.\n");
		}
		else if ((intkey >= 0x21) && (intkey <= 0x7E))
		{
			printf("Dialog control utility interrupted by the '%c' key.\n", chkey);
		}
		else
		{
			printf("Dialog control utility interrupted by key: 0x%02X.\n", intkey);
		}
	}
	else if (bUserEnteredTimeout)
	{
		printf("Dialog control utility done after %i seconds.\n", iTimeout_secs);
	}
	printf("\n");
	fflush(stdout); // Prints to screen or whatever your standard out is
	close(i2c_file);
	return 0;

} //main()

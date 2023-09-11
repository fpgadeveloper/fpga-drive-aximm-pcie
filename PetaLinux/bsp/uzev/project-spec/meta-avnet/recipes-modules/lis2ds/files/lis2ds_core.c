/******************** (C) COPYRIGHT 2016 STMicroelectronics ********************
*
* File Name          : lis2ds_core.c
* Authors            : AMS - VMU - Application Team
*		     : Giuseppe Barba <giuseppe.barba@st.com>
*		     : Mario Tesi <mario.tesi@st.com>
*		     : Lorenzo Bianconi <lorenzo.bianconi@st.com>
*		     : Author is willing to be considered the contact and update
*		     : point for the driver.
* Version            : V.1.1.1
* Date               : 2016/May/03
* Description        : LIS2DS driver
*
********************************************************************************
*
* This program is free software; you can redistribute it and/or modify
* it under the terms of the GNU General Public License version 2 as
* published by the Free Software Foundation.
*
* THE PRESENT SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES
* OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED, FOR THE SOLE
* PURPOSE TO SUPPORT YOUR APPLICATION DEVELOPMENT.
* AS A RESULT, STMICROELECTRONICS SHALL NOT BE HELD LIABLE FOR ANY DIRECT,
* INDIRECT OR CONSEQUENTIAL DAMAGES WITH RESPECT TO ANY CLAIMS ARISING FROM THE
* CONTENT OF SUCH SOFTWARE AND/OR THE USE MADE BY CUSTOMERS OF THE CODING
* INFORMATION CONTAINED HEREIN IN CONNECTION WITH THEIR PRODUCTS.
*
********************************************************************************/

#include <linux/module.h>
#include <linux/slab.h>
#include <linux/hrtimer.h>
#include <linux/input.h>
#include <linux/types.h>
#include <linux/delay.h>
#include <linux/irq.h>
#include <linux/mutex.h>
#include <linux/interrupt.h>
#include <linux/workqueue.h>

#ifdef CONFIG_OF
#include <linux/of.h>
#include <linux/of_device.h>
#include <linux/of_gpio.h>
#endif

#include "lis2ds_core.h"

#define LIS2DS_SENSORHUB_OUT1_ADDR		0x06
#define LIS2DS_SENSORHUB_OUT2_ADDR		0x07
#define LIS2DS_SENSORHUB_OUT3_ADDR		0x08
#define LIS2DS_SENSORHUB_OUT4_ADDR		0x09
#define LIS2DS_SENSORHUB_OUT5_ADDR		0x0a
#define LIS2DS_SENSORHUB_OUT6_ADDR		0x0b
#define LIS2DS_MODULE_8_ADDR			0x0c
#define LIS2DS_WHO_AM_I_ADDR			0x0f
#define LIS2DS_WHO_AM_I_DEF			0x43
#define LIS2DS_CTRL1_ADDR			0x20
#define LIS2DS_CTRL2_ADDR			0x21
#define LIS2DS_CTRL3_ADDR			0x22
#define LIS2DS_CTRL4_INT1_PAD_ADDR		0x23
#define LIS2DS_CTRL5_INT2_PAD_ADDR		0x24
#define LIS2DS_FIFO_CTRL_ADDR			0x25
#define LIS2DS_OUT_T_ADDR			0x26
#define LIS2DS_STATUS_ADDR			0x27
#define LIS2DS_OUTX_L_ADDR			0x28
#define LIS2DS_FIFO_THR_ADDR			0x2e
#define LIS2DS_FIFO_SRC_ADDR			0x2f
#define LIS2DS_FIFO_SAMPLE_ADDR			0x30
#define LIS2DS_TAP_THS_6D_ADDR			0x31
#define LIS2DS_INT_DUR_ADDR			0x32
#define LIS2DS_WAKE_UP_THS_ADDR			0x33
#define LIS2DS_WAKE_UP_DUR_ADDR			0x34
#define LIS2DS_FREE_FALL_ADDR			0x35
#define LIS2DS_STATUS_DUP_ADDR			0x36
#define LIS2DS_WAKE_UP_SRC_ADDR			0x37
#define LIS2DS_TAP_SRC_ADDR			0x38
#define LIS2DS_6D_SRC_ADDR			0x39
#define LIS2DS_STEP_C_MINTHS_ADDR		0x3a
#define LIS2DS_STEP_C_MINTHS_RST_NSTEP_MASK	0x80
#define LIS2DS_STEP_C_OUT_L_ADDR		0x3b
#define LIS2DS_STEP_C_OUT_SIZE			2

#define LIS2DS_FUNC_CK_GATE_ADDR		0x3d
#define LIS2DS_FUNC_CK_GATE_TILT_INT_MASK	0x80
#define LIS2DS_FUNC_CK_GATE_SIGN_M_DET_MASK	0x10
#define LIS2DS_FUNC_CK_GATE_RST_SIGN_M_MASK	0x08
#define LIS2DS_FUNC_CK_GATE_RST_PEDO_MASK	0x04
#define LIS2DS_FUNC_CK_GATE_STEP_D_MASK		0x02
#define LIS2DS_FUNC_CK_GATE_MASK		(LIS2DS_FUNC_CK_GATE_TILT_INT_MASK | \
						LIS2DS_FUNC_CK_GATE_SIGN_M_DET_MASK | \
						LIS2DS_FUNC_CK_GATE_STEP_D_MASK)

#define LIS2DS_FUNC_SRC_ADDR			0x3e

#define LIS2DS_FUNC_CTRL_ADDR			0x3f
#define LIS2DS_FUNC_CTRL_TILT_MASK		0x10
#define LIS2DS_FUNC_CTRL_SIGN_MOT_MASK		0x02
#define LIS2DS_FUNC_CTRL_STEP_CNT_MASK		0x01
#define LIS2DS_FUNC_CTRL_EV_MASK		(LIS2DS_FUNC_CTRL_TILT_MASK | \
						LIS2DS_FUNC_CTRL_SIGN_MOT_MASK | \
						LIS2DS_FUNC_CTRL_STEP_CNT_MASK)

#define LIS2DS_FIFO_THS_ADDR			LIS2DS_STATUS_ADDR
#define LIS2DS_FIFO_THS_MASK			0x80

#define LIS2DS_INT_STATUS_ADDR			LIS2DS_STATUS_ADDR
#define LIS2DS_WAKE_UP_IA_MASK			0x40
#define LIS2DS_DOUBLE_TAP_MASK			0x10
#define LIS2DS_SINGLE_TAP_MASK			0x08
#define LIS2DS_6D_IA_MASK			0x04
#define LIS2DS_FF_IA_MASK			0x02
#define LIS2DS_DRDY_MASK			0x01
#define LIS2DS_EVENT_MASK			(LIS2DS_WAKE_UP_IA_MASK | \
						LIS2DS_DOUBLE_TAP_MASK | \
						LIS2DS_SINGLE_TAP_MASK | \
						LIS2DS_6D_IA_MASK | \
						LIS2DS_FF_IA_MASK)

#define LIS2DS_ODR_ADDR				LIS2DS_CTRL1_ADDR
#define LIS2DS_ODR_MASK				0xf0
#define LIS2DS_ODR_POWER_OFF_VAL		0x00
#define LIS2DS_ODR_1HZ_LP_VAL			0x08
#define LIS2DS_ODR_12HZ_LP_VAL			0x09
#define LIS2DS_ODR_25HZ_LP_VAL			0x0a
#define LIS2DS_ODR_50HZ_LP_VAL			0x0b
#define LIS2DS_ODR_100HZ_LP_VAL			0x0c
#define LIS2DS_ODR_200HZ_LP_VAL			0x0d
#define LIS2DS_ODR_400HZ_LP_VAL			0x0e
#define LIS2DS_ODR_800HZ_LP_VAL			0x0f
#define LIS2DS_ODR_LP_LIST_NUM			9

#define LIS2DS_ODR_12_5HZ_HR_VAL		0x01
#define LIS2DS_ODR_25HZ_HR_VAL			0x02
#define LIS2DS_ODR_50HZ_HR_VAL			0x03
#define LIS2DS_ODR_100HZ_HR_VAL			0x04
#define LIS2DS_ODR_200HZ_HR_VAL			0x05
#define LIS2DS_ODR_400HZ_HR_VAL			0x06
#define LIS2DS_ODR_800HZ_HR_VAL			0x07
#define LIS2DS_ODR_HR_LIST_NUM			8

#define LIS2DS_FS_ADDR				LIS2DS_CTRL1_ADDR
#define LIS2DS_FS_MASK				0x0c
#define LIS2DS_FS_2G_VAL			0x00
#define LIS2DS_FS_4G_VAL			0x02
#define LIS2DS_FS_8G_VAL			0x03
#define LIS2DS_FS_16G_VAL			0x01

/*
 * Sensitivity sets in LP mode [ug]
 */
#define LIS2DS_FS_2G_GAIN_LP			3906
#define LIS2DS_FS_4G_GAIN_LP			7813
#define LIS2DS_FS_8G_GAIN_LP			15625
#define LIS2DS_FS_16G_GAIN_LP			31250

/*
 * Sensitivity sets in HR mode [ug]
 */
#define LIS2DS_FS_2G_GAIN_HR			244
#define LIS2DS_FS_4G_GAIN_HR			488
#define LIS2DS_FS_8G_GAIN_HR			976
#define LIS2DS_FS_16G_GAIN_HR			1952

#define LIS2DS_FS_LIST_NUM			4
enum {
	LIS2DS_LP_MODE = 0,
	LIS2DS_HR_MODE,
	LIS2DS_MODE_COUNT,
};
#define LIS2DS_MODE_DEFAULT			LIS2DS_LP_MODE	

#define LIS2DS_INT1_SHUB_DRDY_MASK		0x80
#define LIS2DS_INT1_S_TAP_MASK			0x40
#define LIS2DS_INT1_WAKEUP_MASK			0x20
#define LIS2DS_INT1_FREE_FALL_MASK		0x10
#define LIS2DS_INT1_TAP_MASK			0x08
#define LIS2DS_INT1_6D_MASK			0x04
#define LIS2DS_INT1_FTH_MASK			0x02
#define LIS2DS_INT1_DRDY_MASK			0x01
#define LIS2DS_INT1_EVENTS_MASK			(LIS2DS_INT1_S_TAP_MASK | \
						LIS2DS_INT1_WAKEUP_MASK | \
						LIS2DS_INT1_FREE_FALL_MASK | \
						LIS2DS_INT1_TAP_MASK | \
						LIS2DS_INT1_6D_MASK | \
						LIS2DS_INT1_FTH_MASK | \
						LIS2DS_INT1_DRDY_MASK)

#define LIS2DS_INT2_ON_INT1_MASK		0x20
#define LIS2DS_INT2_TILT_MASK			0x10
#define LIS2DS_INT2_SIG_MOT_DET_MASK		0x08
#define LIS2DS_INT2_STEP_DET_MASK		0x04
#define LIS2DS_INT2_EVENTS_MASK			(LIS2DS_INT2_TILT_MASK | \
						LIS2DS_INT2_SIG_MOT_DET_MASK | \
						LIS2DS_INT2_STEP_DET_MASK)

#define LIS2DS_INT_DUR_SHOCK_MASK		0x03
#define LIS2DS_INT_DUR_QUIET_MASK		0x0c
#define LIS2DS_INT_DUR_LAT_MASK			0xf0
#define LIS2DS_INT_DUR_MASK			(LIS2DS_INT_DUR_SHOCK_MASK | \
						LIS2DS_INT_DUR_QUIET_MASK | \
						LIS2DS_INT_DUR_LAT_MASK)
#define LIS2DS_INT_DUR_STAP_DEFAULT		0x06
#define LIS2DS_INT_DUR_DTAP_DEFAULT		0x7f

#define LIS2DS_WAKE_UP_THS_S_D_TAP_MASK		0x80
#define LIS2DS_WAKE_UP_THS_SLEEP_MASK		0x40
#define LIS2DS_WAKE_UP_THS_WU_MASK		0x3f
#define LIS2DS_WAKE_UP_THS_WU_DEFAULT		0x02

#define LIS2DS_FREE_FALL_THS_MASK		0x07
#define LIS2DS_FREE_FALL_DUR_MASK		0xF8
#define LIS2DS_FREE_FALL_THS_DEFAULT		0x01
#define LIS2DS_FREE_FALL_DUR_DEFAULT		0x01

#define LIS2DS_WAKE_UP_THS_MASK			0x3f
#define LIS2DS_WAKE_UP_SD_TAP_MASK		0x80

#define LIS2DS_HF_ODR_ADDR			LIS2DS_CTRL1_ADDR
#define LIS2DS_HF_ODR_MASK			0x02
#define LIS2DS_BDU_ADDR				LIS2DS_CTRL1_ADDR
#define LIS2DS_BDU_MASK				0x01

#define LIS2DS_SOFT_RESET_ADDR			LIS2DS_CTRL2_ADDR
#define LIS2DS_SOFT_RESET_MASK			0x40

#define LIS2DS_LIR_ADDR				LIS2DS_CTRL3_ADDR
#define LIS2DS_LIR_MASK				0x04

#define LIS2DS_TAP_AXIS_ADDR			LIS2DS_CTRL3_ADDR
#define LIS2DS_TAP_AXIS_MASK			0x38
#define LIS2DS_TAP_AXIS_ANABLE_ALL		0x07

#define LIS2DS_SELF_TEST_ADDR			LIS2DS_CTRL3_ADDR
#define LIS2DS_SELF_TEST_MASK			0xc0
#define LIS2DS_SELF_TEST_NORM_M			0
#define LIS2DS_SELF_TEST_POS_SIGN		1
#define LIS2DS_SELF_TEST_NEG_SIGN		2
#define LIS2DS_TT_AXIS_EN_ADDR			LIS2DS_CTRL3_ADDR
#define LIS2DS_TT_AXIS_EN_MASK			0x38
#define LIS2DS_TT_AXIS_EN_VAL			0x07
#define LIS2DS_TAP_THS_ADDR			LIS2DS_TAP_THS_6D_ADDR
#define LIS2DS_TAP_THS_MASK			0x1f
#define LIS2DS_TAP_THS_DEFAULT			0x09

#define LIS2DS_INT2_ON_INT1_ADDR		LIS2DS_CTRL5_INT2_PAD_ADDR
#define LIS2DS_INT2_ON_INT1_MASK		0x20

#define LIS2DS_FIFO_MODE_ADDR			LIS2DS_FIFO_CTRL_ADDR
#define LIS2DS_FIFO_MODE_MASK			0xe0
#define LIS2DS_FIFO_MODE_BYPASS			0x00
#define LIS2DS_FIFO_MODE_STOP_ON_FULL		0x01
#define LIS2DS_FIFO_MODE_CONTINUOS		0x06

#define LIS2DS_ACCEL_STD			1
#define LIS2DS_ACCEL_STD_FROM_PD		2
#define LIS2DS_OUT_XYZ_SIZE			8
#define LIS2DS_EN_BIT				0x01
#define LIS2DS_DIS_BIT				0x00

#define LIS2DS_ACCEL_BIT			(1 << LIS2DS_ACCEL)
#define LIS2DS_FF_BIT				(1 << LIS2DS_FF)
#define LIS2DS_TAP_BIT				(1 << LIS2DS_TAP)
#define LIS2DS_WAKEUP_BIT			(1 << LIS2DS_WAKEUP)
#define LIS2DS_ACTIVITY_BIT			(1 << LIS2DS_ACTIVITY)
#define LIS2DS_ALL_EVENT_BIT_MASK		(LIS2DS_FF_BIT | \
						LIS2DS_TAP_BIT | \
						LIS2DS_WAKEUP_BIT | \
						LIS2DS_ACTIVITY_BIT)

#define LIS2DS_EVENT_FF_CODE			(1 << LIS2DS_EVENT_FF)
#define LIS2DS_EVENT_TAP_CODE			(1 << LIS2DS_EVENT_TAP)
#define LIS2DS_EVENT_DOUBLE_TAP_CODE		(1 << LIS2DS_EVENT_DOUBLE_TAP)
#define LIS2DS_EVENT_STEP_D_CODE 		(1 << LIS2DS_EVENT_STEP_D)
#define LIS2DS_EVENT_TILT_CODE			(1 << LIS2DS_EVENT_TILT)
#define LIS2DS_EVENT_SIGN_M_CODE		(1 << LIS2DS_EVENT_SIGN_M)
#define LIS2DS_EVENT_WAKEUP_CODE		(1 << LIS2DS_EVENT_WAKEUP)
#define LIS2DS_EVENT_ACTIVITY_CODE		(1 << LIS2DS_EVENT_ACTIVITY)
#define LIS2DS_EVENT_ALL_CODE			(LIS2DS_EVENT_FF_CODE | \
						LIS2DS_EVENT_TAP_CODE | \
						LIS2DS_EVENT_DOUBLE_TAP_CODE | \
						LIS2DS_EVENT_STEP_D_CODE | \
						LIS2DS_EVENT_TILT_CODE | \
						LIS2DS_EVENT_SIGN_M_CODE | \
						LIS2DS_EVENT_WAKEUP_CODE | \
						LIS2DS_EVENT_ACTIVITY_CODE)

#define LIS2DS_ACCEL_ODR			1
#define LIS2DS_ACCEL_FS				2
#define LIS2DS_FF_ODR				25
#define LIS2DS_STEP_D_ODR			25
#define LIS2DS_TILT_ODR				25
#define LIS2DS_SIGN_M_ODR			25
#define LIS2DS_TAP_ODR				400
#define LIS2DS_WAKEUP_ODR			25
#define LIS2DS_ACTIVITY_ODR			12

#define LIS2DS_FIFO_ELEMENT_LEN_BYTE		2
#define LIS2DS_FIFO_BYTE_FOR_SAMPLE		6
#define LIS2DS_MAX_FIFO_LENGHT			256
#define LIS2DS_MAX_FIFO_SIZE			(LIS2DS_MAX_FIFO_LENGHT * \
						LIS2DS_FIFO_BYTE_FOR_SAMPLE)
#define LIS2DS_MIN_EVENT_ODR			25
#ifndef MAX
#define MAX(a, b)				(((a) > (b)) ? (a) : (b))
#endif

#ifndef MIN
#define MIN(a, b)				(((a) < (b)) ? (a) : (b))
#endif

#define CHECK_BIT(x,y)				(x & (1 << y))

static const struct lis2ds_sensor_name {
	const char *name;
	const char *description;
} lis2ds_sensor_name[LIS2DS_SENSORS_NUMB] = {
	[LIS2DS_ACCEL] = {
			.name = "accel",
			.description = "ST LIS2DS Accelerometer Sensor",
	},
	[LIS2DS_STEP_C] = {
			.name = "step_c",
			.description = "ST LIS2DS Step Counter Sensor",
	},
	[LIS2DS_FF] = {
			.name = "free_fall",
			.description = "ST LIS2DS Free Fall Sensor",
	},
	[LIS2DS_TAP] = {
			.name = "tap",
			.description = "ST LIS2DS Tap Sensor",
	},
	[LIS2DS_DOUBLE_TAP] = {
			.name = "double_tap",
			.description = "ST LIS2DS Double Tap Sensor",
	},
	[LIS2DS_STEP_D] = {
			.name = "step_d",
			.description = "ST LIS2DS Step Detector Sensor",
	},
	[LIS2DS_TILT] = {
			.name = "tilt",
			.description = "ST LIS2DS Tilt Sensor",
	},
	[LIS2DS_SIGN_M] = {
			.name = "sign_m",
			.description = "ST LIS2DS Significant Motion Sensor",
	},
	[LIS2DS_WAKEUP] = {
			.name = "wake_up",
			.description = "ST LIS2DS Wake Up Sensor",
	},
	[LIS2DS_ACTIVITY] = {
			.name = "act",
			.description = "ST LIS2DS Activity Sensor",
	},
};

struct lis2ds_odr_reg {
	u32 hz;
	u8 value;
};

static const struct lis2ds_odr_table_t {
	u8 addr;
	u8 mask;
	struct lis2ds_odr_reg odr_avl[LIS2DS_MODE_COUNT][LIS2DS_ODR_LP_LIST_NUM];
} lis2ds_odr_table = {
	.addr = LIS2DS_ODR_ADDR,
	.mask = LIS2DS_ODR_MASK,

	.odr_avl[LIS2DS_LP_MODE][0] = { .hz = 0,
					.value = LIS2DS_ODR_POWER_OFF_VAL },
	.odr_avl[LIS2DS_LP_MODE][1] = { .hz = 1,
					.value = LIS2DS_ODR_1HZ_LP_VAL },
	.odr_avl[LIS2DS_LP_MODE][2] = { .hz = 12,
					.value = LIS2DS_ODR_12HZ_LP_VAL },
	.odr_avl[LIS2DS_LP_MODE][3] = { .hz = 25,
					.value = LIS2DS_ODR_25HZ_LP_VAL },
	.odr_avl[LIS2DS_LP_MODE][4] = { .hz = 50,
					.value = LIS2DS_ODR_50HZ_LP_VAL },
	.odr_avl[LIS2DS_LP_MODE][5] = { .hz = 100,
					.value = LIS2DS_ODR_100HZ_LP_VAL },
	.odr_avl[LIS2DS_LP_MODE][6] = { .hz = 200,
					.value = LIS2DS_ODR_200HZ_LP_VAL },
	.odr_avl[LIS2DS_LP_MODE][7] = { .hz = 400,
					.value = LIS2DS_ODR_400HZ_LP_VAL },
	.odr_avl[LIS2DS_LP_MODE][8] = { .hz = 800,
					.value = LIS2DS_ODR_800HZ_LP_VAL },

	.odr_avl[LIS2DS_HR_MODE][0] = { .hz = 0,
					.value = LIS2DS_ODR_POWER_OFF_VAL },
	.odr_avl[LIS2DS_HR_MODE][1] = { .hz = 12,
					.value = LIS2DS_ODR_12_5HZ_HR_VAL },
	.odr_avl[LIS2DS_HR_MODE][2] = { .hz = 25,
					.value = LIS2DS_ODR_25HZ_HR_VAL },
	.odr_avl[LIS2DS_HR_MODE][3] = { .hz = 50,
					.value = LIS2DS_ODR_50HZ_HR_VAL },
	.odr_avl[LIS2DS_HR_MODE][4] = { .hz = 100,
					.value = LIS2DS_ODR_100HZ_HR_VAL },
	.odr_avl[LIS2DS_HR_MODE][5] = { .hz = 200,
					.value = LIS2DS_ODR_200HZ_HR_VAL },
	.odr_avl[LIS2DS_HR_MODE][6] = { .hz = 400,
					.value = LIS2DS_ODR_400HZ_HR_VAL },
	.odr_avl[LIS2DS_HR_MODE][7] = { .hz = 800,
					.value = LIS2DS_ODR_800HZ_HR_VAL },
};

struct lis2ds_fs_reg {
	unsigned int gain[LIS2DS_MODE_COUNT];
	u8 value;
	int urv;
};

static struct lis2ds_fs_table {
	u8 addr;
	u8 mask;
	struct lis2ds_fs_reg fs_avl[LIS2DS_FS_LIST_NUM];
} lis2ds_fs_table = {
	.addr = LIS2DS_FS_ADDR,
	.mask = LIS2DS_FS_MASK,
	.fs_avl[0] = { .gain = {LIS2DS_FS_2G_GAIN_LP, LIS2DS_FS_2G_GAIN_HR,},
			.value = LIS2DS_FS_2G_VAL,
			.urv = 2, },
	.fs_avl[1] = { .gain = {LIS2DS_FS_4G_GAIN_LP, LIS2DS_FS_4G_GAIN_HR,},
			.value = LIS2DS_FS_4G_VAL,
			.urv = 4, },
	.fs_avl[2] = { .gain = {LIS2DS_FS_8G_GAIN_LP, LIS2DS_FS_8G_GAIN_LP,},
			.value = LIS2DS_FS_8G_VAL,
			.urv = 8, },
	.fs_avl[3] = { .gain = {LIS2DS_FS_16G_GAIN_LP, LIS2DS_FS_16G_GAIN_HR,},
			.value = LIS2DS_FS_16G_VAL,
			.urv = 16, },
};

static inline s64 lis2ds_get_time_ns(void)
{
	return ktime_get_boottime_ns();
}

static int lis2ds_write_data_with_mask(struct lis2ds_data *cdata,
				       u8 reg_addr, u8 mask, u8 data,
				       bool b_lock)
{
	int err;
	u8 new_data = 0x00, old_data = 0x00;

	err = cdata->tf->read(cdata, reg_addr, 1, &old_data, b_lock);
	if (err < 0)
		return err;

	new_data = ((old_data & (~mask)) | ((data << __ffs(mask)) & mask));

	if (new_data == old_data)
		return 1;

	return cdata->tf->write(cdata, reg_addr, 1, &new_data, b_lock);
}

static int lis2ds_input_init(struct lis2ds_sensor_data *sdata, u16 bustype)
{
	int err = 0;

	sdata->input_dev = input_allocate_device();
	if (!sdata->input_dev) {
		dev_err(sdata->cdata->dev, "failed to allocate input device");
		return -ENOMEM;
	}

	sdata->input_dev->name = lis2ds_sensor_name[sdata->sindex].description;
	sdata->input_dev->id.bustype = bustype;
	sdata->input_dev->dev.parent = sdata->cdata->dev;
	input_set_drvdata(sdata->input_dev, sdata);

	__set_bit(INPUT_EVENT_TYPE, sdata->input_dev->evbit );
	__set_bit(INPUT_EVENT_TIME_MSB, sdata->input_dev->mscbit);
	__set_bit(INPUT_EVENT_TIME_LSB, sdata->input_dev->mscbit);
	__set_bit(INPUT_EVENT_X, sdata->input_dev->mscbit);

	if (sdata->sindex == LIS2DS_ACCEL) {
		__set_bit(INPUT_EVENT_Y, sdata->input_dev->mscbit);
		__set_bit(INPUT_EVENT_Z, sdata->input_dev->mscbit);
	}

	err = input_register_device(sdata->input_dev);
	if (err) {
		dev_err(sdata->cdata->dev, "unable to register sensor %s\n",
			sdata->name);
		input_free_device(sdata->input_dev);
	}

	return err;
}

static void lis2ds_input_cleanup(struct lis2ds_sensor_data *sdata)
{
	input_unregister_device(sdata->input_dev);
	input_free_device(sdata->input_dev);
}

static void lis2ds_report_3axes_event(struct lis2ds_sensor_data *sdata,
				      s32 *xyz, s64 timestamp)
{
	struct input_dev *input = sdata->input_dev;

	if (!sdata->enabled)
		return;

	input_event(input, INPUT_EVENT_TYPE, INPUT_EVENT_X, xyz[0]);
	input_event(input, INPUT_EVENT_TYPE, INPUT_EVENT_Y, xyz[1]);
	input_event(input, INPUT_EVENT_TYPE, INPUT_EVENT_Z, xyz[2]);
	input_event(input, INPUT_EVENT_TYPE, INPUT_EVENT_TIME_MSB,
		    timestamp >> 32);
	input_event(input, INPUT_EVENT_TYPE, INPUT_EVENT_TIME_LSB,
		    timestamp & 0xffffffff);
	input_sync(input);
}

static void lis2ds_report_single_event(struct lis2ds_sensor_data *sdata,
				       s32 data)
{
	struct input_dev  *input = sdata->input_dev;

	if (!sdata->enabled)
		return;

	input_event(input, INPUT_EVENT_TYPE, INPUT_EVENT_X, data);
	input_event(input, INPUT_EVENT_TYPE, INPUT_EVENT_TIME_MSB,
		    sdata->timestamp >> 32);
	input_event(input, INPUT_EVENT_TYPE, INPUT_EVENT_TIME_LSB,
		    sdata->timestamp & 0xffffffff);
	input_sync(input);
}

static int lis2ds_report_step_c_data(struct lis2ds_data *cdata)
{
	int err = 0;
	s32 steps = 0;
	u8 data[2];

	err = cdata->tf->read(cdata, LIS2DS_STEP_C_OUT_L_ADDR,
			      LIS2DS_STEP_C_OUT_SIZE, data, true);
	if (err < 0)
		return err;

	steps = (s32)((u16)(data[1] << 8) | data[0]);
	lis2ds_report_single_event(&cdata->sensors[LIS2DS_STEP_C], steps);

	return 0;
}

static inline s32 lis2ds_data_align_bit(u8 ms, u8 ls, u8 power_mode)
{
	if (power_mode == LIS2DS_LP_MODE)
		return (s32)(((s16)(ls | ms << 8)) >> 6);
	else
		return (s32)(((s16)(ls | ms << 8)) >> 2);
}

static void lis2ds_get_acc_data(struct lis2ds_data *cdata)
{
	u8 data[6];
	int err, xyz[3];
	struct lis2ds_sensor_data *sdata = &cdata->sensors[LIS2DS_ACCEL];

	err = cdata->tf->read(cdata, LIS2DS_OUTX_L_ADDR, LIS2DS_OUT_XYZ_SIZE,
			      data, true);
	if (err < 0) {
		dev_err(cdata->dev, "get acc data failed %d\n", err);
	} else {
		if (++sdata->skip_cnt < sdata->dec_cnt)
			return;

		sdata->skip_cnt = 0;

		xyz[0] = lis2ds_data_align_bit(data[1], data[0],
					       cdata->power_mode);
		xyz[1] = lis2ds_data_align_bit(data[3], data[2],
					       cdata->power_mode);
		xyz[2] = lis2ds_data_align_bit(data[5], data[4],
					       cdata->power_mode);

		xyz[0] *= sdata->c_gain;
		xyz[1] *= sdata->c_gain;
		xyz[2] *= sdata->c_gain;

		lis2ds_report_3axes_event(sdata, xyz, cdata->timestamp);
	}
}

static u8 lis2ds_event_irq1_value(struct lis2ds_data *cdata)
{
	u8 value = 0x0;

	if (cdata->sensors[LIS2DS_FF].enabled)
		value |= LIS2DS_INT1_FREE_FALL_MASK;

	if (cdata->sensors[LIS2DS_DOUBLE_TAP].enabled)
		value |= LIS2DS_INT1_TAP_MASK;

	if (cdata->sensors[LIS2DS_TAP].enabled)
		value |= LIS2DS_INT1_S_TAP_MASK | LIS2DS_INT1_TAP_MASK;

	if (cdata->sensors[LIS2DS_WAKEUP].enabled)
		value |= LIS2DS_INT1_WAKEUP_MASK;

	return value;
}

static u8 lis2ds_event_irq2_value(struct lis2ds_data *cdata)
{
	u8 value = 0x0;

	if (cdata->sensors[LIS2DS_TILT].enabled)
		value |= LIS2DS_INT2_TILT_MASK;

	if (cdata->sensors[LIS2DS_SIGN_M].enabled)
		value |= LIS2DS_INT2_SIG_MOT_DET_MASK;

	if ((cdata->sensors[LIS2DS_STEP_C].enabled) ||
	    (cdata->sensors[LIS2DS_STEP_D].enabled))
		value |= LIS2DS_INT2_STEP_DET_MASK;

	return value;
}

/*
static int lis2ds_set_enable_function(struct lis2ds_data *cdata, bool state,
			       u8 func_bit_mask)
{
	int err = 0;

	err = lis2ds_write_data_with_mask(cdata,
					  LIS2DS_FUNC_CTRL_ADDR,
					  func_bit_mask,
					  state >> __ffs(func_bit_mask),
					  true);
	if (err < 0)
		return err;

	return 0;
}
*/
static int lis2ds_update_drdy_irq(struct lis2ds_sensor_data *sdata)
{
	u8 reg_addr, reg_val, reg_mask;

	switch (sdata->sindex) {
	case LIS2DS_FF:
	case LIS2DS_TAP:
	case LIS2DS_DOUBLE_TAP:
	case LIS2DS_WAKEUP:
	case LIS2DS_ACTIVITY:
		reg_val = lis2ds_event_irq1_value(sdata->cdata);
		reg_addr = LIS2DS_CTRL4_INT1_PAD_ADDR;
		reg_mask = LIS2DS_INT1_EVENTS_MASK;
		break;
	case LIS2DS_SIGN_M:
	case LIS2DS_TILT:
	case LIS2DS_STEP_D:
	case LIS2DS_STEP_C:
		reg_val = lis2ds_event_irq2_value(sdata->cdata);
		reg_addr = LIS2DS_CTRL5_INT2_PAD_ADDR;
		reg_mask = LIS2DS_INT2_EVENTS_MASK;
		break;
	case LIS2DS_ACCEL:
		reg_val = (sdata->cdata->sensors[LIS2DS_ACCEL].enabled)
				? LIS2DS_INT1_DRDY_MASK : 0;
		reg_addr = LIS2DS_CTRL4_INT1_PAD_ADDR;
		reg_mask = LIS2DS_INT1_DRDY_MASK;
		break;
	default:
		return -EINVAL;
	}

	return lis2ds_write_data_with_mask(sdata->cdata, reg_addr, reg_mask,
					   reg_val >> __ffs(reg_mask),
					   true);
}

static int lis2ds_set_fs(struct lis2ds_sensor_data *sdata, unsigned int fs)
{
	int err, i;

	for (i = 0; i < LIS2DS_FS_LIST_NUM; i++) {
		if (lis2ds_fs_table.fs_avl[i].urv == fs)
			break;
	}

	if (i == LIS2DS_FS_LIST_NUM)
		return -EINVAL;

	err = lis2ds_write_data_with_mask(sdata->cdata,
					  lis2ds_fs_table.addr,
					  lis2ds_fs_table.mask,
					  lis2ds_fs_table.fs_avl[i].value,
					  true);
	if (err < 0)
		return err;

	sdata->c_gain = lis2ds_fs_table.fs_avl[i].gain[sdata->cdata->power_mode];

	return 0;
}

static irqreturn_t lis2ds_save_timestamp(int irq, void *private)
{
	struct lis2ds_data *cdata = private;

	cdata->timestamp = lis2ds_get_time_ns();

	disable_irq_nosync(irq);

	return IRQ_WAKE_THREAD;
}

static void lis2ds_event_management(struct lis2ds_data *cdata, u8 int_reg_val,
			     u8 ck_gate_val)
{
	if ((cdata->sensors[LIS2DS_TAP].enabled) &&
	    (int_reg_val & LIS2DS_SINGLE_TAP_MASK)) {
		cdata->sensors[LIS2DS_TAP].timestamp = cdata->timestamp;
		lis2ds_report_single_event(&cdata->sensors[LIS2DS_TAP], 1);
	}

	if ((cdata->sensors[LIS2DS_DOUBLE_TAP].enabled) &&
	    (int_reg_val & LIS2DS_DOUBLE_TAP_MASK)) {
		cdata->sensors[LIS2DS_DOUBLE_TAP].timestamp = cdata->timestamp;
		lis2ds_report_single_event(&cdata->sensors[LIS2DS_DOUBLE_TAP], 1);
	}

	if ((cdata->sensors[LIS2DS_FF].enabled) &&
	    (int_reg_val & LIS2DS_FF_IA_MASK)) {
		cdata->sensors[LIS2DS_FF].timestamp = cdata->timestamp;
		lis2ds_report_single_event(&cdata->sensors[LIS2DS_FF], 1);
	}

	if ((cdata->sensors[LIS2DS_WAKEUP].enabled) &&
	    (int_reg_val & LIS2DS_WAKE_UP_IA_MASK)) {
		cdata->sensors[LIS2DS_WAKEUP].timestamp = cdata->timestamp;
		lis2ds_report_single_event(&cdata->sensors[LIS2DS_WAKEUP], 1);
	}

	if ((cdata->sensors[LIS2DS_STEP_D].enabled) &&
	    (ck_gate_val & LIS2DS_FUNC_CK_GATE_STEP_D_MASK)) {
		cdata->sensors[LIS2DS_STEP_D].timestamp = cdata->timestamp;
		lis2ds_report_single_event(&cdata->sensors[LIS2DS_STEP_D], 1);
	}

	if ((cdata->sensors[LIS2DS_TILT].enabled) &&
	    (ck_gate_val & LIS2DS_FUNC_CK_GATE_TILT_INT_MASK)) {
		cdata->sensors[LIS2DS_TILT].timestamp = cdata->timestamp;
		lis2ds_report_single_event(&cdata->sensors[LIS2DS_TILT], 1);
	}

	if ((cdata->sensors[LIS2DS_SIGN_M].enabled) &&
	    (ck_gate_val & LIS2DS_FUNC_CK_GATE_SIGN_M_DET_MASK)) {
		cdata->sensors[LIS2DS_SIGN_M].timestamp = cdata->timestamp;
		lis2ds_report_single_event(&cdata->sensors[LIS2DS_SIGN_M], 1);
	}

	if ((cdata->sensors[LIS2DS_STEP_C].enabled) &&
	    (ck_gate_val & LIS2DS_FUNC_CK_GATE_STEP_D_MASK)) {
		cdata->sensors[LIS2DS_STEP_C].timestamp = cdata->timestamp;
		lis2ds_report_step_c_data(cdata);
	}
}

static irqreturn_t lis2ds_thread_fn(int irq, void *private)
{
	u8 status[4], func[2];
	struct lis2ds_data *cdata = (struct lis2ds_data *)private;

	cdata->tf->read(cdata, LIS2DS_STATUS_DUP_ADDR, 4, status, true);
	cdata->tf->read(cdata, LIS2DS_FUNC_CK_GATE_ADDR, 2, func, true);

	if ((status[0] & LIS2DS_EVENT_MASK) ||
	    (func[0] & LIS2DS_FUNC_CK_GATE_MASK))
		/* Detected an event! Decode and report it */
		lis2ds_event_management(cdata, status[0], func[0]);

	cdata->tf->read(cdata, LIS2DS_STATUS_ADDR, 1, status, true);
	if (status[0] & 0x01)
		lis2ds_get_acc_data(cdata);

	enable_irq(irq);

	return IRQ_HANDLED;
}

static int lis2ds_write_max_odr(struct lis2ds_sensor_data *sdata)
{
	int err, i;
	u32 max_odr = 0;
	struct lis2ds_data *cdata = sdata->cdata;

	for (i = 0; i < LIS2DS_SENSORS_NUMB; i++)
		if (sdata->cdata->sensors[i].enabled)
			if (cdata->sensors[i].c_odr > max_odr)
				max_odr = cdata->sensors[i].c_odr;

	if (max_odr != cdata->common_odr) {
		u16 real_odr;

		for (i = 0; i < LIS2DS_ODR_LP_LIST_NUM; i++) {
			if (lis2ds_odr_table.odr_avl[cdata->power_mode][i].hz >= max_odr)
				break;
		}
		if (i == LIS2DS_ODR_LP_LIST_NUM)
			return -EINVAL;

		real_odr = lis2ds_odr_table.odr_avl[cdata->power_mode][i].hz;
		err = lis2ds_write_data_with_mask(sdata->cdata,
						  lis2ds_odr_table.addr,
						  lis2ds_odr_table.mask,
						  lis2ds_odr_table.odr_avl[cdata->power_mode][i].value,
						  true);
		if (err < 0)
			return err;

		cdata->common_odr = max_odr;
		sdata->dec_cnt = real_odr / sdata->c_odr;
		sdata->skip_cnt = 0;
	}

	return 0;
}

/*
static int lis2ds_configure_tap_event(struct lis2ds_sensor_data *sdata,
			       bool single_tap)
{
	u8 err = 0;

	if (single_tap) {
		err = lis2ds_write_data_with_mask(sdata->cdata,
						  LIS2DS_INT_DUR_ADDR,
						  LIS2DS_INT_DUR_MASK,
						  LIS2DS_INT_DUR_STAP_DEFAULT,
						  true);
		if (err < 0)
			return err;

		err = lis2ds_write_data_with_mask(sdata->cdata,
						  LIS2DS_WAKE_UP_THS_ADDR,
						  LIS2DS_WAKE_UP_THS_S_D_TAP_MASK,
						  LIS2DS_DIS_BIT, true);
		if (err < 0)
			return err;
	} else {
		err = lis2ds_write_data_with_mask(sdata->cdata,
						  LIS2DS_INT_DUR_ADDR,
						  LIS2DS_INT_DUR_MASK,
						  LIS2DS_INT_DUR_DTAP_DEFAULT,
						  true);
		if (err < 0)
			return err;

		err = lis2ds_write_data_with_mask(sdata->cdata,
						  LIS2DS_WAKE_UP_THS_ADDR,
						  LIS2DS_WAKE_UP_THS_S_D_TAP_MASK,
						  LIS2DS_EN_BIT, true);
		if (err < 0)
			return err;
	}

	return err;
}
*/

static int lis2ds_update_event_functions(struct lis2ds_data *cdata)
{
	u8 reg_val = 0;

	if (cdata->sensors[LIS2DS_SIGN_M].enabled)
		reg_val |= LIS2DS_FUNC_CTRL_SIGN_MOT_MASK;

	if (cdata->sensors[LIS2DS_TILT].enabled)
		reg_val |= LIS2DS_FUNC_CTRL_TILT_MASK;

	if ((cdata->sensors[LIS2DS_STEP_D].enabled) ||
	    (cdata->sensors[LIS2DS_STEP_C].enabled))
		reg_val |= LIS2DS_FUNC_CTRL_STEP_CNT_MASK;

	return lis2ds_write_data_with_mask(cdata,
					   LIS2DS_FUNC_CTRL_ADDR,
					   LIS2DS_FUNC_CTRL_EV_MASK,
					   reg_val >> __ffs(LIS2DS_FUNC_CTRL_EV_MASK),
					   true);
}

static int _lis2ds_enable_sensors(struct lis2ds_sensor_data *sdata)
{
	int err = 0;

	switch (sdata->sindex) {
	case LIS2DS_TAP:
		if (sdata->cdata->sensors[LIS2DS_DOUBLE_TAP].enabled)
			return -EINVAL;
		break;
	case LIS2DS_DOUBLE_TAP:
		if (sdata->cdata->sensors[LIS2DS_TAP].enabled)
			return -EINVAL;
		break;
	case LIS2DS_FF:
	case LIS2DS_WAKEUP:
	case LIS2DS_ACTIVITY:
	case LIS2DS_ACCEL:
		break;
	case LIS2DS_TILT:
	case LIS2DS_SIGN_M:
	case LIS2DS_STEP_D:
	case LIS2DS_STEP_C:
		err = lis2ds_update_event_functions(sdata->cdata);
		if (err < 0)
			return err;
		break;
	default:
		return -EINVAL;
	}

	err = lis2ds_update_drdy_irq(sdata);
	if (err < 0)
		return err;

	err = lis2ds_write_max_odr(sdata);
	if (err < 0)
		return err;

	return 0;
}

static int lis2ds_enable_sensors(struct lis2ds_sensor_data *sdata)
{
	int err = 0;
	
	if (sdata->enabled)
		return 0;

	sdata->enabled = true;
	err = _lis2ds_enable_sensors(sdata);
	if (err < 0)
		sdata->enabled = false;

	return err;
}

static int _lis2ds_disable_sensors(struct lis2ds_sensor_data *sdata)
{
	int err;

	switch (sdata->sindex) {
	case LIS2DS_TILT:
	case LIS2DS_SIGN_M:
	case LIS2DS_STEP_D:
	case LIS2DS_STEP_C:
		err = lis2ds_update_event_functions(sdata->cdata);
		if (err < 0)
			return err;
	case LIS2DS_ACCEL:
	case LIS2DS_FF:
	case LIS2DS_TAP:
	case LIS2DS_DOUBLE_TAP:
	case LIS2DS_WAKEUP:
	case LIS2DS_ACTIVITY:
		break;
	default:
		return -EINVAL;
	}

	err = lis2ds_update_drdy_irq(sdata);
	if (err < 0)
		return err;

	err = lis2ds_write_max_odr(sdata);
	if (err < 0)
		return err;

	return 0;
}

static int lis2ds_disable_sensors(struct lis2ds_sensor_data *sdata)
{
	int err;

	if (!sdata->enabled)
		return 0;

	sdata->enabled = false;
	err = _lis2ds_disable_sensors(sdata);
	if (err < 0)
		sdata->enabled = true;

	return err;
}

static int lis2ds_init_sensors(struct lis2ds_data *cdata)
{
	int err, i;
	struct lis2ds_sensor_data *sdata;

	for (i = 0; i < LIS2DS_SENSORS_NUMB; i++) {
		sdata = &cdata->sensors[i];

		err = lis2ds_disable_sensors(sdata);
		if (err < 0)
			return err;

		if (sdata->sindex == LIS2DS_ACCEL) {
			err = lis2ds_set_fs(sdata, LIS2DS_ACCEL_FS);
			if (err < 0)
				return err;
		}
	}

	cdata->selftest_status = 0;

	/*
	 * Soft reset the device on power on.
	 */
	err = lis2ds_write_data_with_mask(cdata,
					  LIS2DS_SOFT_RESET_ADDR,
					  LIS2DS_SOFT_RESET_MASK,
					  LIS2DS_EN_BIT, true);
	if (err < 0)
		return err;

	/*
	 * Enable latched interrupt mode.
	 */
	err = lis2ds_write_data_with_mask(cdata,
					  LIS2DS_LIR_ADDR,
					  LIS2DS_LIR_MASK,
					  LIS2DS_EN_BIT, true);
	if (err < 0)
		return err;
	/*
	 * Enable block data update feature.
	 */
	err = lis2ds_write_data_with_mask(cdata,
					  LIS2DS_BDU_ADDR,
					  LIS2DS_BDU_MASK,
					  LIS2DS_EN_BIT, true);
	if (err < 0)
		return err;

	/*
	 * Route interrupt from INT2 to INT1 pin.
	 */
	err = lis2ds_write_data_with_mask(cdata,
					  LIS2DS_INT2_ON_INT1_ADDR,
					  LIS2DS_INT2_ON_INT1_MASK,
					  LIS2DS_EN_BIT, true);
	if (err < 0)
		return err;

	/*
	 * Configure default free fall event threshold.
	 */
	err = lis2ds_write_data_with_mask(sdata->cdata,
					  LIS2DS_FREE_FALL_ADDR,
					  LIS2DS_FREE_FALL_THS_MASK,
					  LIS2DS_FREE_FALL_THS_DEFAULT, true);
	if (err < 0)
		return err;

	/*
	 * Configure default free fall event duration.
	 */
	err = lis2ds_write_data_with_mask(sdata->cdata,
					  LIS2DS_FREE_FALL_ADDR,
					  LIS2DS_FREE_FALL_DUR_MASK,
					  LIS2DS_FREE_FALL_DUR_DEFAULT, true);
	if (err < 0)
		return err;

	/*
	 * Configure Tap event recognition on all direction (X, Y and Z axes).
	 */
	err = lis2ds_write_data_with_mask(sdata->cdata,
					  LIS2DS_TAP_AXIS_ADDR,
					  LIS2DS_TAP_AXIS_MASK,
					  LIS2DS_TAP_AXIS_ANABLE_ALL, true);
	if (err < 0)
		return err;

	/*
	 * Configure default threshold for Tap event recognition.
	 */
	err = lis2ds_write_data_with_mask(sdata->cdata,
					  LIS2DS_TAP_THS_ADDR,
					  LIS2DS_TAP_THS_MASK,
					  LIS2DS_TAP_THS_DEFAULT, true);
	if (err < 0)
		return err;

	/*
	 * Configure default threshold for Wake Up event recognition.
	 */
	err = lis2ds_write_data_with_mask(sdata->cdata,
					  LIS2DS_WAKE_UP_THS_ADDR,
					  LIS2DS_WAKE_UP_THS_WU_MASK,
					  LIS2DS_WAKE_UP_THS_WU_DEFAULT, true);
	if (err < 0)
		return err;

	return 0;
}

static ssize_t lis2ds_get_enable(struct device *dev, struct device_attribute *attr,
				 char *buf)
{
	struct lis2ds_sensor_data *sdata = dev_get_drvdata(dev);

	return sprintf(buf, "%u\n", sdata->enabled);
}

static ssize_t lis2ds_set_enable(struct device *dev, struct device_attribute *attr,
				 const char *buf, size_t count)
{
	int err;
	struct lis2ds_sensor_data *sdata = dev_get_drvdata(dev);
	unsigned long enable;

	/* if (strict_strtoul(buf, 10, &enable)) */
	if (kstrtoul(buf, 10, &enable))
		return -EINVAL;

	if (enable)
		err = lis2ds_enable_sensors(sdata);
	else
		err = lis2ds_disable_sensors(sdata);

	return count;
}

static ssize_t lis2ds_get_resolution_mode(struct device *dev,
					  struct device_attribute *attr,
					  char *buf)
{
	struct lis2ds_sensor_data *sdata = dev_get_drvdata(dev);

	return sprintf(buf, "%s\n", 
		(sdata->cdata->power_mode == LIS2DS_LP_MODE) ? "low" : "high");
}

static ssize_t lis2ds_set_resolution_mode(struct device *dev,
					  struct device_attribute *attr,
					  const char *buf, size_t count)
{
	int err, i;
	struct lis2ds_sensor_data *sdata = dev_get_drvdata(dev);

	for (i = 0; i < LIS2DS_FS_LIST_NUM; i++) {
		if (sdata->c_gain ==
			lis2ds_fs_table.fs_avl[i].gain[sdata->cdata->power_mode])
			break;
	}

	if (!strncmp(buf, "low", count - 1))
		sdata->cdata->power_mode = LIS2DS_LP_MODE;
	else if (!strncmp(buf, "high", count - 1))
		sdata->cdata->power_mode = LIS2DS_HR_MODE;
	else
		return -EINVAL;

	err = lis2ds_write_max_odr(sdata);
	if (err < 0)
		return err;

	sdata->c_gain = lis2ds_fs_table.fs_avl[i].gain[sdata->cdata->power_mode];

	return count;
}

static ssize_t lis2ds_get_polling_rate(struct device *dev,
				struct device_attribute *attr, char *buf)
{
	struct lis2ds_sensor_data *sdata = dev_get_drvdata(dev);

	return sprintf(buf, "%u\n", 1000 / sdata->c_odr);
}

static ssize_t lis2ds_set_polling_rate(struct device *dev,
				struct device_attribute *attr, const char *buf,
				size_t count)
{
	int err;
	unsigned int polling_rate;
	struct lis2ds_sensor_data *sdata = dev_get_drvdata(dev);

	err = kstrtoint(buf, 10, &polling_rate);
	if (err < 0)
		return err;

	mutex_lock(&sdata->input_dev->mutex);
	sdata->c_odr = 1000 / polling_rate;
	mutex_unlock(&sdata->input_dev->mutex);

	err = lis2ds_write_max_odr(sdata);
	if (err < 0)
		return err;

	return count;
}

static ssize_t lis2ds_get_scale_avail(struct device *dev,
			       struct device_attribute *attr, char *buf)
{
	int i, len = 0;

	for (i = 0; i < LIS2DS_FS_LIST_NUM; i++)
		len += scnprintf(buf + len, PAGE_SIZE - len, "%d ",
			lis2ds_fs_table.fs_avl[i].urv);

	buf[len - 1] = '\n';

	return len;
}

static ssize_t lis2ds_get_cur_scale(struct device *dev,
			     struct device_attribute *attr, char *buf)
{
	int i;
	struct lis2ds_sensor_data *sdata = dev_get_drvdata(dev);

	for (i = 0; i < LIS2DS_FS_LIST_NUM; i++)
		if (sdata->c_gain ==
			lis2ds_fs_table.fs_avl[i].gain[sdata->cdata->power_mode])
			break;

	return sprintf(buf, "%d\n", lis2ds_fs_table.fs_avl[i].urv);
}

static ssize_t lis2ds_set_cur_scale(struct device *dev, struct device_attribute *attr,
			     const char *buf, size_t count)
{
	int urv, err;
	struct lis2ds_sensor_data *sdata = dev_get_drvdata(dev);

	err = kstrtoint(buf, 10, &urv);
	if (err < 0)
		return err;

	err = lis2ds_set_fs(sdata, urv);
	if (err < 0)
		return err;

	return count;
}

static ssize_t lis2ds_reset_step_counter(struct device *dev, struct device_attribute *attr,
				  const char *buf, size_t count)
{
	int err;
	struct lis2ds_sensor_data *sdata = dev_get_drvdata(dev);

	err = lis2ds_write_data_with_mask(sdata->cdata,
					  LIS2DS_STEP_C_MINTHS_ADDR,
					  LIS2DS_STEP_C_MINTHS_RST_NSTEP_MASK,
					  LIS2DS_EN_BIT, true);
	if (err < 0)
		return err;

	return count;
}

static DEVICE_ATTR(enable,
		   S_IWUSR | S_IRUGO,
		   lis2ds_get_enable,
		   lis2ds_set_enable);

static DEVICE_ATTR(resolution,
		   S_IWUSR | S_IRUGO,
		   lis2ds_get_resolution_mode,
		   lis2ds_set_resolution_mode);

static DEVICE_ATTR(polling_rate,
		   S_IWUSR | S_IRUGO,
		   lis2ds_get_polling_rate,
		   lis2ds_set_polling_rate);

static DEVICE_ATTR(scale_avail,
		   S_IRUGO,
		   lis2ds_get_scale_avail,
		   NULL);

static DEVICE_ATTR(scale,
		   S_IWUSR | S_IRUGO,
		   lis2ds_get_cur_scale,
		   lis2ds_set_cur_scale);

static DEVICE_ATTR(reset_steps,
		   S_IWUSR,
		   NULL,
		   lis2ds_reset_step_counter);

static struct attribute *lis2ds_accel_attribute[] = {
	&dev_attr_enable.attr,
	&dev_attr_resolution.attr,
	&dev_attr_polling_rate.attr,
	&dev_attr_scale_avail.attr,
	&dev_attr_scale.attr,
	NULL,
};

static struct attribute *lis2ds_step_c_attribute[] = {
	&dev_attr_enable.attr,
	&dev_attr_reset_steps.attr,
	NULL,
};

static struct attribute *lis2ds_step_ff_attribute[] = {
	&dev_attr_enable.attr,
	NULL,
};

static struct attribute *lis2ds_tap_attribute[] = {
	&dev_attr_enable.attr,
	NULL,
};

static struct attribute *lis2ds_double_tap_attribute[] = {
	&dev_attr_enable.attr,
	NULL,
};

static struct attribute *lis2ds_step_d_attribute[] = {
	&dev_attr_enable.attr,
	NULL,
};

static struct attribute *lis2ds_tilt_attribute[] = {
	&dev_attr_enable.attr,
	NULL,
};

static struct attribute *lis2ds_sign_m_attribute[] = {
	&dev_attr_enable.attr,
	NULL,
};

static struct attribute *lis2ds_wakeup_attribute[] = {
	&dev_attr_enable.attr,
	NULL,
};

static struct attribute *lis2ds_act_attribute[] = {
	&dev_attr_enable.attr,
	NULL,
};

static const struct attribute_group lis2ds_attribute_groups[] = {
	[LIS2DS_ACCEL] = {
		.attrs = lis2ds_accel_attribute,
		.name = "accel",
	},
	[LIS2DS_STEP_C] = {
		.attrs = lis2ds_step_c_attribute,
		.name = "step_c",
	},
	[LIS2DS_FF] = {
		.attrs = lis2ds_step_ff_attribute,
		.name = "free_fall",
	},
	[LIS2DS_TAP] = {
		.name = "tap",
		.attrs = lis2ds_tap_attribute,
	},
	[LIS2DS_DOUBLE_TAP] = {
		.name = "double_tap",
		.attrs = lis2ds_double_tap_attribute,
	},
	[LIS2DS_STEP_D] = {
		.name = "step_d",
		.attrs = lis2ds_step_d_attribute,
	},
	[LIS2DS_TILT] = {
		.name = "tilt",
		.attrs = lis2ds_tilt_attribute,
	},
	[LIS2DS_SIGN_M] = {
		.name = "sign_m",
		.attrs = lis2ds_sign_m_attribute,
	},
	[LIS2DS_WAKEUP] = {
		.name = "wake_up",
		.attrs = lis2ds_wakeup_attribute,
	},
	[LIS2DS_ACTIVITY] = {
		.name = "act",
		.attrs = lis2ds_act_attribute,
	},
};

#ifdef CONFIG_OF
static u32 lis2ds_parse_dt(struct lis2ds_data *cdata)
{
	u32 val;
	struct device_node *np;

	np = cdata->dev->of_node;
	if (!np)
		return -EINVAL;

	if (!of_property_read_u32(np, "st,drdy-int-pin", &val) &&
	    (val <= 2) && (val > 0))
		cdata->drdy_int_pin = (u8)val;
	else
		cdata->drdy_int_pin = 1;

	return 0;
}
#endif

int lis2ds_common_probe(struct lis2ds_data *cdata, int irq, u16 bustype)
{
	/* TODO: add errors management */
	int32_t err, i;
	u8 wai = 0;
	struct lis2ds_sensor_data *sdata;

	mutex_init(&cdata->bank_registers_lock);
	mutex_init(&cdata->tb.buf_lock);

	err = cdata->tf->read(cdata, LIS2DS_WHO_AM_I_ADDR, 1, &wai, true);
	if (err < 0) {
		dev_err(cdata->dev, "failed to read Who-Am-I register.\n");
		return err;
	}
	if (wai != LIS2DS_WHO_AM_I_DEF) {
		dev_err(cdata->dev, "Who-Am-I value not valid.\n");
		return -ENODEV;
	}

	mutex_init(&cdata->lock);

	if (irq > 0) {
#ifdef CONFIG_OF
		err = lis2ds_parse_dt(cdata);
		if (err < 0)
			return err;
#else /* CONFIG_OF */
		if (cdata->dev->platform_data) {
			cdata->drdy_int_pin = ((struct lis2ds_platform_data *)
				cdata->dev->platform_data)->drdy_int_pin;

			if ((cdata->drdy_int_pin > 2) ||
			    (cdata->drdy_int_pin < 1))
				cdata->drdy_int_pin = 1;
		} else
			cdata->drdy_int_pin = 1;
#endif /* CONFIG_OF */

		dev_info(cdata->dev, "driver use DRDY int pin %d\n",
			 cdata->drdy_int_pin);
	}

	cdata->common_odr = 0;
	cdata->power_mode = LIS2DS_LP_MODE;

	for (i = 0; i < LIS2DS_SENSORS_NUMB; i++) {
		sdata = &cdata->sensors[i];
		sdata->enabled = false;
		sdata->cdata = cdata;
		sdata->sindex = i;
		sdata->name = lis2ds_sensor_name[i].name;
		switch(i) {
		case LIS2DS_ACCEL:
			sdata->c_odr = LIS2DS_ACCEL_ODR;

			break;
		case LIS2DS_STEP_C:
		case LIS2DS_STEP_D:
		case LIS2DS_SIGN_M:
			sdata->c_odr = LIS2DS_STEP_D_ODR;

			break;
		case LIS2DS_FF:
			sdata->c_odr = LIS2DS_FF_ODR;

			break;
		case LIS2DS_TAP:
		case LIS2DS_DOUBLE_TAP:
			sdata->c_odr = LIS2DS_TAP_ODR;

			break;
		case LIS2DS_TILT:
			sdata->c_odr = LIS2DS_TILT_ODR;

			break;
		case LIS2DS_WAKEUP:
			sdata->c_odr = LIS2DS_WAKEUP_ODR;

			break;
		case LIS2DS_ACTIVITY:
			sdata->c_odr = LIS2DS_ACTIVITY_ODR;

			break;
		}

		lis2ds_input_init(sdata, bustype);

		if (sysfs_create_group(&sdata->input_dev->dev.kobj,
				       &lis2ds_attribute_groups[i])) {
			dev_err(cdata->dev, "failed to create sysfs group for "
					"sensor %s", sdata->name);

			input_unregister_device(sdata->input_dev);
			sdata->input_dev = NULL;
		}
	}

	err = lis2ds_init_sensors(cdata);
	if (err < 0)
		return err;

	if (irq > 0) {
		cdata->irq = irq;

		err = request_threaded_irq(cdata->irq, lis2ds_save_timestamp,
					   lis2ds_thread_fn,
					   IRQF_TRIGGER_RISING,
					   cdata->name, cdata);
		if (err)
			return err;
	}

	dev_info(cdata->dev, "%s: probed\n", LIS2DS_DEV_NAME);

	return 0;
}
EXPORT_SYMBOL(lis2ds_common_probe);

void lis2ds_common_remove(struct lis2ds_data *cdata, int irq)
{
	u8 i;

	for (i = 0; i < LIS2DS_SENSORS_NUMB; i++) {
		lis2ds_disable_sensors(&cdata->sensors[i]);
		lis2ds_input_cleanup(&cdata->sensors[i]);
	}
}
EXPORT_SYMBOL(lis2ds_common_remove);

#ifdef CONFIG_PM
static int lis2ds_resume_sensors(struct lis2ds_sensor_data *sdata)
{
	if (!sdata->enabled)
		return 0;

	return _lis2ds_enable_sensors(sdata);
}

static int lis2ds_suspend_sensors(struct lis2ds_sensor_data *sdata)
{
	if (!sdata->enabled)
		return 0;

	return _lis2ds_disable_sensors(sdata);
}

int lis2ds_common_suspend(struct lis2ds_data *cdata)
{
	lis2ds_suspend_sensors(&cdata->sensors[LIS2DS_ACCEL]);

	return 0;
}
EXPORT_SYMBOL(lis2ds_common_suspend);

int lis2ds_common_resume(struct lis2ds_data *cdata)
{
	lis2ds_resume_sensors(&cdata->sensors[LIS2DS_ACCEL]);

	return 0;
}
EXPORT_SYMBOL(lis2ds_common_resume);

#endif /* CONFIG_PM */

MODULE_DESCRIPTION("STMicroelectronics lis2ds driver");
MODULE_AUTHOR("Giuseppe Barba");
MODULE_AUTHOR("Mario Tesi");
MODULE_LICENSE("GPL v2");

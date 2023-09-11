/******************** (C) COPYRIGHT 2015 STMicroelectronics ********************
*
* File Name          : lis2ds_i2c.c
* Authors            : AMS - VMU - Application Team
*		     : Giuseppe Barba <giuseppe.barba@st.com>
*		     : Author is willing to be considered the contact and update
*		     : point for the driver.
* Version            : V.1.1.0
* Date               : 2015/Apr/17
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
#include <linux/i2c.h>
#include <linux/hrtimer.h>
#include <linux/input.h>
#include <linux/types.h>

#include "lis2ds_core.h"

static int lis2ds_i2c_read(struct lis2ds_data *cdata, u8 reg_addr, int len,
			   u8 *data, bool b_lock)
{
	int err = 0;
	struct i2c_msg msg[2];
	struct i2c_client *client = to_i2c_client(cdata->dev);

	msg[0].addr = client->addr;
	msg[0].flags = client->flags;
	msg[0].len = 1;
	msg[0].buf = &reg_addr;

	msg[1].addr = client->addr;
	msg[1].flags = client->flags | I2C_M_RD;
	msg[1].len = len;
	msg[1].buf = data;

	if (b_lock) {
		mutex_lock(&cdata->bank_registers_lock);
		err = i2c_transfer(client->adapter, msg, 2);
		mutex_unlock(&cdata->bank_registers_lock);
	} else
		err = i2c_transfer(client->adapter, msg, 2);

	return err;
}

static int lis2ds_i2c_write(struct lis2ds_data *cdata, u8 reg_addr, int len,
			    u8 *data, bool b_lock)
{
	int err = 0;
	u8 send[len + 1];
	struct i2c_msg msg;
	struct i2c_client *client = to_i2c_client(cdata->dev);

	send[0] = reg_addr;
	memcpy(&send[1], data, len * sizeof(u8));
	len++;

	msg.addr = client->addr;
	msg.flags = client->flags;
	msg.len = len;
	msg.buf = send;

	if (b_lock) {
		mutex_lock(&cdata->bank_registers_lock);
		err = i2c_transfer(client->adapter, &msg, 1);
		mutex_unlock(&cdata->bank_registers_lock);
	} else
		err = i2c_transfer(client->adapter, &msg, 1);

	return err;
}


static const struct lis2ds_transfer_function lis2ds_tf_i2c = {
	.write = lis2ds_i2c_write,
	.read = lis2ds_i2c_read,
};

static int lis2ds_i2c_probe(struct i2c_client *client,
			    const struct i2c_device_id *id)
{
	int err;
	struct lis2ds_data *cdata;

	cdata = kmalloc(sizeof(*cdata), GFP_KERNEL);
	if (!cdata)
		return -ENOMEM;

	cdata->dev = &client->dev;
	cdata->name = client->name;
	cdata->tf = &lis2ds_tf_i2c;
	i2c_set_clientdata(client, cdata);

	err = lis2ds_common_probe(cdata, client->irq, BUS_I2C);
	if (err < 0)
		goto free_data;

	return 0;

free_data:
	kfree(cdata);
	return err;
}

static int lis2ds_i2c_remove(struct i2c_client *client)
{
	struct lis2ds_data *cdata = i2c_get_clientdata(client);

	lis2ds_common_remove(cdata, client->irq);
	dev_info(cdata->dev, "%s: removed\n", LIS2DS_DEV_NAME);
	kfree(cdata);
	return 0;
}

#ifdef CONFIG_PM
static int lis2ds_suspend(struct device *dev)
{
	struct lis2ds_data *cdata = i2c_get_clientdata(to_i2c_client(dev));

	return lis2ds_common_suspend(cdata);
}

static int lis2ds_resume(struct device *dev)
{
	struct lis2ds_data *cdata = i2c_get_clientdata(to_i2c_client(dev));

	return lis2ds_common_resume(cdata);
}

static const struct dev_pm_ops lis2ds_pm_ops = {
	SET_SYSTEM_SLEEP_PM_OPS(lis2ds_suspend, lis2ds_resume)
};

#define LIS2DS_PM_OPS	(&lis2ds_pm_ops)
#else /* CONFIG_PM */
#define LIS2DS_PM_OPS	NULL
#endif /* CONFIG_PM */


static const struct i2c_device_id lis2ds_ids[] = {
	{ LIS2DS_DEV_NAME, 0 },
	{ }
};
MODULE_DEVICE_TABLE(i2c, lis2ds_ids);

#ifdef CONFIG_OF
static const struct of_device_id lis2ds_id_table[] = {
	{ .compatible = "st,lis2ds", },
	{ .compatible = "st,lis2ds12", },
	{ },
};
MODULE_DEVICE_TABLE(of, lis2ds_id_table);
#endif

static struct i2c_driver lis2ds_i2c_driver = {
	.driver = {
		.owner = THIS_MODULE,
		.name = LIS2DS_DEV_NAME,
		.pm = LIS2DS_PM_OPS,
#ifdef CONFIG_OF
		.of_match_table = lis2ds_id_table,
#endif
	},
	.probe    = lis2ds_i2c_probe,
	.remove   = lis2ds_i2c_remove,
	.id_table = lis2ds_ids,
};

module_i2c_driver(lis2ds_i2c_driver);

MODULE_DESCRIPTION("STMicroelectronics lis2ds i2c driver");
MODULE_AUTHOR("Giuseppe Barba");
MODULE_LICENSE("GPL v2");

/*
 * drivers/pl/led-brightness.c - Xilinx PL LED brightness controller support
 *
 * Copyright (c) 2012 Avnet, Inc.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License v2 as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
 */

#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/of.h>
#include <linux/of_address.h>
#include <linux/errno.h>
#include <linux/slab.h>
#include <linux/cdev.h>
#include <linux/delay.h>
#include <linux/fs.h>
#include <linux/io.h>
#include <linux/types.h>
#include <asm/uaccess.h>

#define DRIVER_NAME "led-brightness"
#define MAX_LED_BRIGHTNESS_DEV_NUM	16
#define BRIGHTNESS_BUF_SZ	1
#define LED_BRIGHTNESS_FACTOR	11000
#define LED_BRIGHTNESS_MIN	0
#define LED_BRIGHTNESS_MAX	100

dev_t led_brightness_dev_id = 0;
static unsigned int device_num = 0;
static unsigned int cur_minor = 0;
static struct class *led_brightness_class = NULL;

struct led_brightness_device {
	const char *name;
	/* Defined memory region */
	struct resource *mem;
	/* Mapped IO region */
	void __iomem *iobase;
	/* LED Brightness Data Buffers */
	uint8_t *brightness_buf;
	/* platform device structures */
	struct platform_device *pdev;
	/* Char Device */
	struct cdev cdev;
	dev_t dev_id;
};

/**
 * buf_to_controller - Formats settings in buffer and writes to controller.
 * @brightness_buf - Buffer containing the brightness settings.
 * @dev - led_brightness_device instance
 *
 */
static int buf_to_controller(uint8_t *brightness_buf, struct led_brightness_device *dev)
{
	int index;
	int status = 0;
	uint8_t lower_bound_brightness = LED_BRIGHTNESS_MIN;
	uint8_t upper_bound_brightness = LED_BRIGHTNESS_MAX;
	uint32_t value;

	/* Iterate through the brightness buffer and write each value
	 * to the corresponding channel in the controller.
	 */
	for(index = 0; index < BRIGHTNESS_BUF_SZ; index++) {
		value = brightness_buf[index];

		/* Check to see that brightness value falls
		 * within allowed boundary values.
		 */
		if((value >= lower_bound_brightness) &&
		   (value <= upper_bound_brightness)) {
			writel((value * LED_BRIGHTNESS_FACTOR), dev->iobase + (2 * index));
		}
		else {
			writel(0, (dev->iobase + (2 * index)));
		}

	}

	if (index < 1){
		status = -1;
	}

	return status;
}

/**
 * A basic open function. It exists mainly to save the id of
 * the LED brightness device and some other basic information.
 */
static int led_brightness_open(struct inode *inode, struct file *fp)
{
	struct led_brightness_device *dev;

	dev = container_of(inode->i_cdev, struct led_brightness_device, cdev);
	fp->private_data = dev;

	return 0;
}

static int led_brightness_close(struct inode *inode, struct file *fp)
{
	return 0;
}

/**
 * Driver write function
 *
 * This function uses a generic memory write to send values to the LED
 * brightness controller device.  It takes a raw data array from the app
 * in the buffer, copied it into the LED brightness controller buffer, and
 * finally sends modified buffer contents memory writes.
 */
static ssize_t	led_brightness_write(struct file *fp, const char __user *buffer, size_t length, loff_t *offset)
{
	int status = 0;
	ssize_t retval = 0;
	struct led_brightness_device *dev;
	unsigned int minor_id;
	int cnt;

	dev = fp->private_data;
	minor_id = MINOR(dev->dev_id);

	if(buffer == NULL) {
		dev_err(&dev->pdev->dev, "led_brightness_write: ERROR: invalid buffer address: 0x%08x\n",
					(unsigned int) buffer);
		retval = -EINVAL;
		goto quit_write;
	}

	if(length > BRIGHTNESS_BUF_SZ) {
		cnt = BRIGHTNESS_BUF_SZ;
	}
	else {
		cnt = length;
	}

	if(copy_from_user(dev->brightness_buf, buffer, cnt)) {
		dev_err(&dev->pdev->dev, "led_brightness_write: copy_from_user failed\n");
		retval = -EFAULT;
		goto quit_write;
	}
	else {
		retval = cnt;
	}

	status = buf_to_controller(dev->brightness_buf, dev);
	if(status) {
		dev_err(&dev->pdev->dev, "led_brightness_write: Error sending brightness pattern to display\n");
		retval = -EFAULT;
		goto quit_write;
	}

quit_write:
	return retval;
}

/**
 * Driver Read Function
 *
 * This function does not actually read the LED brightness controller as it
 * is a write-only device. Instead it returns data in the brightness buffer
 * generated for the LED brightness controller that was used when the
 * controller was last programmed.
 */
static ssize_t led_brightness_read(struct file *fp, char __user *buffer, size_t length, loff_t *offset)
{
	ssize_t retval = 0;
	struct led_brightness_device *dev;
	unsigned int minor_id;
	int cnt;

	dev = fp->private_data;
	minor_id = MINOR(dev->dev_id);

	if(buffer == NULL) {
		dev_err(&dev->pdev->dev, "led_brightness_read: ERROR: invalid buffer "
				"address: 0x%08X\n", (unsigned int)buffer);
		retval = -EINVAL;
		goto quit_read;
	}

	if(length > BRIGHTNESS_BUF_SZ)
		cnt = BRIGHTNESS_BUF_SZ;
	else
		cnt = length;
	retval = copy_to_user((void *)buffer, dev->brightness_buf, cnt);
	if (!retval)
		retval = cnt; /* copy success, return amount in buffer */

quit_read:
	return(retval);
}

struct file_operations led_brightness_cdev_fops = {
	.owner = THIS_MODULE,
	.write = led_brightness_write,
	.read = led_brightness_read,
	.open = led_brightness_open,
	.release = led_brightness_close,
};

/**
 * led_brightness_setup_cdev - Setup Char Device for LED brightness device.
 * @dev: pointer to device tree node
 * @dev_id: pointer to device major and minor number
 * @spi: pointer to spi_device structure
 *
 * This function initializes char device for the LED brightness controller
 * device, and add it into kernel device structure.  It returns 0, if the
 * cdev is successfully initialized, or a negative value if there is an error.
 */
static int led_brightness_setup_cdev(struct led_brightness_device *dev, dev_t *dev_id)
{
	int status = 0;
	struct device *device;

	cdev_init(&dev->cdev, &led_brightness_cdev_fops);
	dev->cdev.owner = THIS_MODULE;
	dev->cdev.ops = &led_brightness_cdev_fops;

	*dev_id = MKDEV(MAJOR(led_brightness_dev_id), cur_minor++);
	status = cdev_add(&dev->cdev, *dev_id, 1);
	if(status < 0) {
		return status;
	}

	/* Add Device node in system */
	device = device_create(led_brightness_class, NULL,
					*dev_id, NULL,
					"%s", dev->name);
	if(IS_ERR(device)) {
		status = PTR_ERR(device);
		dev_err(&dev->pdev->dev, "led_brightness_setup_cdev: failed to create device node %s, err %d\n",
				dev->name, status);
		cdev_del(&dev->cdev);
	}

	return status;
}

/**
 * led_brightness_init - Initialize the brightness controller with defaults.
 * @dev:
 *
 */
static void led_brightness_init(struct led_brightness_device *dev)
{
	int index;

	/* Clear out the brightness value array */
	for(index = 0; index < BRIGHTNESS_BUF_SZ; index++){
		dev->brightness_buf[index] = 0;
	}

	writel(0x00000000, dev->iobase);

	return;
}

//static const struct of_device_id led_brightness_of_match[] __devinitconst = {
static const struct of_device_id led_brightness_of_match[] = {
	{ .compatible = "avnet,led-brightness", },
	{},
};
MODULE_DEVICE_TABLE(of, led_brightness_of_match);

/**
 * led_brightness_of_probe - Probe method for LED brightness controller.
 * @pdev: pointer to platform devices
 *
 * This function probes the LED brightness device in the device tree. It
 * initializes the LED brightness controller driver data structure. It
 * returns 0, if the driver is bound to the LED brightness device, or a
 * negative value if there is an error.
 */
//static int __devinit led_brightness_of_probe(struct platform_device *pdev)
static int led_brightness_of_probe(struct platform_device *pdev)
{
	int status = 0;
	struct led_brightness_device *led_brightness_dev;
	struct device_node *np = pdev->dev.of_node;

	/* Alloc Space for platform device structure */
	led_brightness_dev = (struct led_brightness_device*) kzalloc(sizeof(*led_brightness_dev), GFP_KERNEL);
	if(!led_brightness_dev) {
		status = -ENOMEM;
		goto dev_alloc_err;
	}

	/* Obtain the memory resource for this device */
	led_brightness_dev->mem = platform_get_resource(pdev, IORESOURCE_MEM, 0);
	if (!led_brightness_dev->mem) {
		status = -ENOENT;
		dev_err(&pdev->dev, "Failed to get platform IO resource\n");
		goto platform_get_resource_err;
	}

	printk(KERN_INFO DRIVER_NAME " : Found device memory resource at %08X %08X.\n",
		led_brightness_dev->mem->start, resource_size(led_brightness_dev->mem));

	led_brightness_dev->mem = request_mem_region(led_brightness_dev->mem->start,
			resource_size(led_brightness_dev->mem), pdev->name);
	if (!led_brightness_dev->mem) {
		status = -ENODEV;
		dev_err(&pdev->dev, "Failed to request memory region\n");
		goto request_mem_region_err;
	}

	led_brightness_dev->iobase = ioremap(led_brightness_dev->mem->start, resource_size(led_brightness_dev->mem));
	if (!led_brightness_dev->iobase) {
		status = -ENODEV;
		dev_err(&pdev->dev, "Failed to ioremap memory\n");
		goto ioremap_mem_err;
	}

	/* Alloc Graphic Buffer for device */
	led_brightness_dev->brightness_buf = (uint8_t*) kmalloc(BRIGHTNESS_BUF_SZ, GFP_KERNEL);
	if(!led_brightness_dev->brightness_buf) {
		status = -ENOMEM;
		dev_err(&pdev->dev, "LED brightness data buffer allocation failed: %d\n", status);
		goto brightness_buf_alloc_err;
	}

	/* Fill in the device info */
	led_brightness_dev->pdev = pdev;
	led_brightness_dev->name = np->name;

	/* Point device node data to led_brightness_device structure */
	if(np->data == NULL)
		np->data = led_brightness_dev;

	if(led_brightness_dev_id == 0) {
		/* Alloc Major & Minor number for char device */
		status = alloc_chrdev_region(&led_brightness_dev_id, 0, MAX_LED_BRIGHTNESS_DEV_NUM, DRIVER_NAME);
		if(status) {
			dev_err(&pdev->dev, "Character device region not allocated correctly: %d\n", status);
			goto err_alloc_chrdev_region;
		}

		printk(KERN_INFO DRIVER_NAME " : Char Device Region Registered, with Major: %d.\n",
						MAJOR(led_brightness_dev_id));

	}

	if(led_brightness_class == NULL) {
		/* Create LED Brightness Device Class */
		led_brightness_class = class_create(THIS_MODULE, DRIVER_NAME);
		if (IS_ERR(led_brightness_class)) {
			status = PTR_ERR(led_brightness_class);
			goto err_create_class;
		}

		printk(KERN_INFO DRIVER_NAME " : led_brightness device class registered.\n");
	}

	/* Setup char driver */
	status = led_brightness_setup_cdev(led_brightness_dev, &(led_brightness_dev->dev_id));
	if (status) {
		dev_err(&pdev->dev, "led_brightness: Error adding device: %d\n", status);
		goto cdev_add_err;
	}

	led_brightness_init(led_brightness_dev);

	device_num++;

	return status;

cdev_add_err:
	if(led_brightness_class) {
		class_destroy(led_brightness_class);
	}
	led_brightness_class = NULL;
err_create_class:
	unregister_chrdev_region(led_brightness_dev_id, MAX_LED_BRIGHTNESS_DEV_NUM);
	led_brightness_dev_id = 0;
err_alloc_chrdev_region:
	kfree(led_brightness_dev->brightness_buf);
	iounmap(led_brightness_dev->iobase);
ioremap_mem_err:
	release_mem_region(led_brightness_dev->mem->start, resource_size(led_brightness_dev->mem));
request_mem_region_err:
platform_get_resource_err:
brightness_buf_alloc_err:
	kfree(led_brightness_dev);
dev_alloc_err:
	return status;
}

/**
 * led_brightness_of_remove - Remove method for LED brightness device.
 * @np: pointer to device tree node
 *
 * This function removes the LED brightness device in the device tree. It
 * frees the LED brightness controller driver data structure. It returns 0,
 * if the driver is successfully removed, or a negative value if there is
 * an error.
 */
static int led_brightness_of_remove(struct platform_device *pdev)
{
	struct led_brightness_device *led_brightness_dev;
	struct device_node *np = pdev->dev.of_node;

	if(np->data == NULL) {
		dev_err(&pdev->dev, "led_brightness %s: ERROR: No led_brightness_device structure found!\n", np->name);
		return -ENOSYS;
	}
	led_brightness_dev = (struct led_brightness_device*) (np->data);

	printk(KERN_INFO DRIVER_NAME " %s : Free brightness data buffer.\n", np->name);

	if(led_brightness_dev->brightness_buf != NULL) {
		kfree(led_brightness_dev->brightness_buf);
	}

	if(led_brightness_dev->iobase) {
		iounmap(led_brightness_dev->iobase);
	}
	if(led_brightness_dev->mem->start) {
		release_mem_region(led_brightness_dev->mem->start, resource_size(led_brightness_dev->mem));
	}

	np->data = NULL;
	device_num--;

	/* Remove the device node from the file system. */
	if(&led_brightness_dev->cdev) {
		printk(KERN_INFO DRIVER_NAME " : Destroy Char Device\n");
		device_destroy(led_brightness_class, led_brightness_dev->dev_id);
		cdev_del(&led_brightness_dev->cdev);
	}

	cur_minor--;


	/* Destroy led_brightness class, Release device id Region after all
	 * led-brightness devices have been removed.
	 */
	if(device_num == 0) {
		printk(KERN_INFO DRIVER_NAME " : Destroy led_brightness Class.\n");

		if(led_brightness_class) {
			class_destroy(led_brightness_class);
		}
		led_brightness_class = NULL;

		printk(KERN_INFO DRIVER_NAME " : Release Char Device Region.\n");

		unregister_chrdev_region(led_brightness_dev_id, MAX_LED_BRIGHTNESS_DEV_NUM);
		led_brightness_dev_id = 0;
	}

	return 0;
}

static struct platform_driver led_brightness_driver = {
	.driver = {
		.name = DRIVER_NAME,
		.owner = THIS_MODULE,
		.of_match_table = led_brightness_of_match,
	},
	.probe = led_brightness_of_probe,
//	.remove = __devexit_p(led_brightness_of_remove),
	.remove = (led_brightness_of_remove),
};

module_platform_driver(led_brightness_driver);

MODULE_AUTHOR("Avnet, Inc.");
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION(DRIVER_NAME": LED Brightness Controller driver");
MODULE_ALIAS(DRIVER_NAME);

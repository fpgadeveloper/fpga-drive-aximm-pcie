#if defined(CONFIG_MICROBLAZE)
#include <configs/microblaze-generic.h>
#define CONFIG_SYS_BOOTM_LEN 0xF000000
#endif
#if defined(CONFIG_ARCH_ZYNQ)
#include <configs/zynq-common.h>
#endif
#if defined(CONFIG_ARCH_ZYNQMP)
#include <configs/xilinx_zynqmp.h>
#endif
#if defined(CONFIG_ARCH_VERSAL)
#include <configs/xilinx_versal.h>

/*
 * Opsero Inc. 2024 Jeff Johnson
 * 
 * The following adds two U-boot environment variables: vadj_1v2_en and vadj_1v5_en.
 * These variables contain a set of I2C commands that will configure the IR38164
 * buck regulator (U185, I2C addr 0x1E) to output 1.2V and 1.5V respectively.
 *
 * The boot command is overwritten such that it runs one of these environment variables 
 * (enabling the VADJ voltage), before running distro_bootcmd.
 *
 * This should only be used with the VCK190 and VMK180 boards. Normally, the system
 * controller would enable VADJ to the appropriate voltage, however this method has
 * two main advantages:
 *
 * (1) it guarantees that VADJ is enabled before PetaLinux boots on the Versal
 * (2) it will work when the system controller is not used/configured
 *
 */

#define IR38164_VADJ_SETTINGS \
	"vadj_1v2_en=" \
		"i2c dev 0;" \
		"i2c mw 0x74 0x00.0 0x01 0x1;" \
		"i2c mw 0x1E 0x24.1 0x01 0x1;" \
		"i2c mw 0x1E 0x25.1 0x33 0x1;" \
		"i2c mw 0x1E 0x3A.1 0x01 0x1;" \
		"i2c mw 0x1E 0x3B.1 0x8F 0x1;" \
		"i2c mw 0x1E 0x3D.1 0x01 0x1;" \
		"i2c mw 0x1E 0x3E.1 0x8F 0x1;" \
		"i2c mw 0x1E 0x3F.1 0x00 0x1;" \
		"i2c mw 0x1E 0x40.1 0x00 0x1;" \
		"i2c mw 0x1E 0x41.1 0x00 0x1;" \
		"i2c mw 0x1E 0x42.1 0x00 0x1;" \
		"i2c mw 0x1E 0x22.1 0x80 0x1\0" \
	"vadj_1v5_en=" \
		"i2c dev 0;" \
		"i2c mw 0x74 0x00.0 0x01 0x1;" \
		"i2c mw 0x1E 0x24.1 0x01 0x1;" \
		"i2c mw 0x1E 0x25.1 0x80 0x1;" \
		"i2c mw 0x1E 0x3A.1 0x01 0x1;" \
		"i2c mw 0x1E 0x3B.1 0xF3 0x1;" \
		"i2c mw 0x1E 0x3D.1 0x01 0x1;" \
		"i2c mw 0x1E 0x3E.1 0xF3 0x1;" \
		"i2c mw 0x1E 0x3F.1 0x00 0x1;" \
		"i2c mw 0x1E 0x40.1 0x00 0x1;" \
		"i2c mw 0x1E 0x41.1 0x00 0x1;" \
		"i2c mw 0x1E 0x42.1 0x00 0x1;" \
		"i2c mw 0x1E 0x22.1 0x80 0x1\0" \
	
#define CFG_EXTRA_ENV_SETTINGS \
	ENV_MEM_LAYOUT_SETTINGS \
	IR38164_VADJ_SETTINGS \
	BOOTENV

#define CONFIG_BOOTCOMMAND "run vadj_1v5_en; run distro_bootcmd"
#endif
#if defined(CONFIG_ARCH_VERSAL_NET)
#include <configs/xilinx_versal_net.h>
#endif

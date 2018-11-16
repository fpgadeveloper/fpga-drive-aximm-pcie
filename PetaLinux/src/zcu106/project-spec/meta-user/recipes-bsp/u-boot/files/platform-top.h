
#include <configs/platform-auto.h>


#define CONFIG_SYS_I2C_MAX_HOPS		1
#define CONFIG_SYS_NUM_I2C_BUSES	18
#define CONFIG_SYS_I2C_BUSES	{ \
				{0, {I2C_NULL_HOP} }, \
				{0, {{I2C_MUX_PCA9544, 0x75, 0} } }, \
				{0, {{I2C_MUX_PCA9544, 0x75, 1} } }, \
				{0, {{I2C_MUX_PCA9544, 0x75, 2} } }, \
				{1, {I2C_NULL_HOP} }, \
				{1, {{I2C_MUX_PCA9548, 0x74, 0} } }, \
				{1, {{I2C_MUX_PCA9548, 0x74, 1} } }, \
				{1, {{I2C_MUX_PCA9548, 0x74, 2} } }, \
				{1, {{I2C_MUX_PCA9548, 0x74, 3} } }, \
				{1, {{I2C_MUX_PCA9548, 0x74, 4} } }, \
				{1, {{I2C_MUX_PCA9548, 0x75, 0} } }, \
				{1, {{I2C_MUX_PCA9548, 0x75, 1} } }, \
				{1, {{I2C_MUX_PCA9548, 0x75, 2} } }, \
				{1, {{I2C_MUX_PCA9548, 0x75, 3} } }, \
				{1, {{I2C_MUX_PCA9548, 0x75, 4} } }, \
				{1, {{I2C_MUX_PCA9548, 0x75, 5} } }, \
				{1, {{I2C_MUX_PCA9548, 0x75, 6} } }, \
				{1, {{I2C_MUX_PCA9548, 0x75, 7} } }, \
				}

#define CONFIG_PCA953X

#define CONFIG_SYS_I2C_EEPROM_ADDR_LEN  1
#define CONFIG_ZYNQ_EEPROM_BUS          5
#define CONFIG_ZYNQ_GEM_EEPROM_ADDR     0x54
#define CONFIG_ZYNQ_GEM_I2C_MAC_OFFSET  0x20


#define DFU_ALT_INFO_RAM \
		"dfu_ram_info=" \
	"setenv dfu_alt_info " \
	"image.ub ram $netstart 0x1e00000\0" \
	"dfu_ram=run dfu_ram_info && dfu 0 ram 0\0" \
	"thor_ram=run dfu_ram_info && thordown 0 ram 0\0"

#define DFU_ALT_INFO_MMC \
        "dfu_mmc_info=" \
        "set dfu_alt_info " \
        "${kernel_image} fat 0 1\\\\;" \
        "dfu_mmc=run dfu_mmc_info && dfu 0 mmc 0\0" \
        "thor_mmc=run dfu_mmc_info && thordown 0 mmc 0\0"

#define CONFIG_SYS_BOOTM_LEN 0xF000000


#include <configs/platform-auto.h>

#define CONFIG_SYS_BOOTM_LEN 0xF000000

/* Extra U-Boot Env settings */
#define CONFIG_EXTRA_ENV_SETTINGS \
	SERIAL_MULTI \ 
	CONSOLE_ARG \ 
	ESERIAL0 \ 
	"autoload=no\0" \ 
	"sdbootdev=0\0" \ 
	"clobstart=0x80000000\0" \ 
	"netstart=0x80000000\0" \ 
	"dtbnetstart=0x81e00000\0" \ 
	"netstartaddr=0x81000000\0"  "bootcmd=run cp_kernel2ram && bootm ${netstartaddr}\0"  "loadaddr=0x80000000\0" \ 
	"initrd_high=0x0\0" \ 
	"bootsize=0x180000\0" \ 
	"bootstart=0x1000000\0" \ 
	"boot_img=u-boot-s.bin\0" \ 
	"install_boot=sf probe 0 && sf erase ${bootstart} ${bootsize} && " \ 
		"sf write ${clobstart} ${bootstart} ${filesize}\0" \ 
	"bootenvsize=0x40000\0" \ 
	"bootenvstart=0x1180000\0" \ 
	"eraseenv=sf probe 0 && sf erase ${bootenvstart} ${bootenvsize}\0" \ 
	"kernelsize=0xc00000\0" \ 
	"kernelstart=0x11c0000\0" \ 
	"kernel_img=image.ub\0" \ 
	"install_kernel=sf probe 0 && sf erase ${kernelstart} ${kernelsize} && " \ 
		"sf write ${clobstart} ${kernelstart} ${filesize}\0" \ 
	"cp_kernel2ram=sf probe 0 && sf read ${netstartaddr} ${kernelstart} ${kernelsize}\0" \ 
	"fpgasize=0x1000000\0" \ 
	"fpgastart=0x0\0" \ 
	"fpga_img=system.bit.bin\0" \ 
	"install_fpga=sf probe 0 && sf erase ${fpgastart} ${fpgasize} && " \ 
		"sf write ${clobstart} ${fpgastart} ${filesize}\0" \ 
	"fault=echo ${img} image size is greater than allocated place - partition ${img} is NOT UPDATED\0" \ 
	"test_crc=if imi ${clobstart}; then run test_img; else echo ${img} Bad CRC - ${img} is NOT UPDATED; fi\0" \ 
	"test_img=setenv var \"if test ${filesize} -gt ${psize}\\; then run fault\\; else run ${installcmd}\\; fi\"; run var; setenv var\0" \ 
	"default_bootcmd=bootcmd\0" \ 
""


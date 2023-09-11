
#include <configs/platform-auto.h>

#define CONFIG_SYS_BOOTM_LEN 0xF000000

// Boot from QSPI flash
#define CONFIG_USE_BOOTCOMMAND 1
#define CONFIG_BOOTCOMMAND	"sf probe 0 && sf read ${netstartaddr} ${kernelstart} ${kernelsize} && bootm ${netstartaddr}"

/* Extra U-Boot Env settings */
#define CONFIG_EXTRA_ENV_SETTINGS \
	SERIAL_MULTI \ 
	CONSOLE_ARG \ 
	ESERIAL0 \ 
	"nc=setenv stdout nc;setenv stdin nc;\0" \ 
	"ethaddr=00:0a:35:00:22:01\0" \
	"autoload=no\0" \ 
	"sdbootdev=0\0" \ 
	"clobstart=0x80000000\0" \ 
	"netstart=0x80000000\0" \ 
	"dtbnetstart=0x81e00000\0" \ 
	"netstartaddr=0x81000000\0"  "loadaddr=0x80000000\0" \ 
	"initrd_high=0x0\0" \ 
	"bootsize=0x180000\0" \ 
	"bootstart=0x2400000\0" \ 
	"boot_img=u-boot-s.bin\0" \ 
	"load_boot=tftpboot ${clobstart} ${boot_img}\0" \ 
	"update_boot=setenv img boot; setenv psize ${bootsize}; setenv installcmd \"install_boot\"; run load_boot test_img; setenv img; setenv psize; setenv installcmd\0" \ 
	"install_boot=sf probe 0 && sf erase ${bootstart} ${bootsize} && " \ 
		"sf write ${clobstart} ${bootstart} ${filesize}\0" \ 
	"bootenvsize=0x20000\0" \ 
	"bootenvstart=0x2580000\0" \ 
	"eraseenv=sf probe 0 && sf erase ${bootenvstart} ${bootenvsize}\0" \ 
	"kernelsize=0xc40000\0" \ 
	"kernelstart=0x25a0000\0" \ 
	"kernel_img=image.ub\0" \ 
	"load_kernel=tftpboot ${clobstart} ${kernel_img}\0" \ 
	"update_kernel=setenv img kernel; setenv psize ${kernelsize}; setenv installcmd \"install_kernel\"; run load_kernel test_crc; setenv img; setenv psize; setenv installcmd\0" \ 
	"install_kernel=sf probe 0 && sf erase ${kernelstart} ${kernelsize} && " \ 
		"sf write ${clobstart} ${kernelstart} ${filesize}\0" \ 
	"cp_kernel2ram=sf probe 0 && sf read ${netstart} ${kernelstart} ${kernelsize}\0" \ 
	"fpgasize=0x2400000\0" \ 
	"fpgastart=0x0\0" \ 
	"fpga_img=system.bit.bin\0" \ 
	"load_fpga=tftpboot ${clobstart} ${fpga_img}\0" \ 
	"update_fpga=setenv img fpga; setenv psize ${fpgasize}; setenv installcmd \"install_fpga\"; run load_fpga test_img; setenv img; setenv psize; setenv installcmd\0" \ 
	"install_fpga=sf probe 0 && sf erase ${fpgastart} ${fpgasize} && " \ 
		"sf write ${clobstart} ${fpgastart} ${filesize}\0" \ 
	"fault=echo ${img} image size is greater than allocated place - partition ${img} is NOT UPDATED\0" \ 
	"test_crc=if imi ${clobstart}; then run test_img; else echo ${img} Bad CRC - ${img} is NOT UPDATED; fi\0" \ 
	"test_img=setenv var \"if test ${filesize} -gt ${psize}\\; then run fault\\; else run ${installcmd}\\; fi\"; run var; setenv var\0" \ 
	"netboot=tftpboot ${netstartaddr} ${kernel_img} && bootm\0" \ 
	"default_bootcmd=bootcmd\0" \ 
""



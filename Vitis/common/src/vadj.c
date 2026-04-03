/*
 * vadj.c — Enable VADJ on Versal boards (vck190, vmk180, vpk120, vpk180)
 *
 * Configures the power controller via LPD I2C0 (MIO 46/47) to set VADJ
 * which powers the FMC+ I/Os.
 *
 * Note: vek280 enables VADJ by default and does not need these functions.
 */

#include "board.h"

#if defined(BOARD_VCK190) || defined(BOARD_VMK180) || defined(BOARD_VPK120) || \
    defined(BOARD_VHK158) || defined(BOARD_VPK180)

#include <stdio.h>
#include "xil_printf.h"
#include "xiicps.h"
#include "xparameters.h"
#include "vadj.h"

#if defined(BOARD_VCK190) || defined(BOARD_VMK180) || defined(BOARD_VPK120) || defined(BOARD_VPK180)

#define I2C_MUX_ADDR        0x74
#define I2C_MUX_CHANNEL     0x01

#define POWER_CTRL_ADDR     0x1E

#define IIC_SCLK_RATE       400000

typedef struct { u8 reg; u8 val; } reg_write_t;

static const reg_write_t vadj_1v5_writes[] = {
	{ 0x24, 0x01 },
	{ 0x25, 0x80 },
	{ 0x3A, 0x01 },
	{ 0x3B, 0xF3 },
	{ 0x3D, 0x01 },
	{ 0x3E, 0xF3 },
	{ 0x3F, 0x00 },
	{ 0x40, 0x00 },
	{ 0x41, 0x00 },
	{ 0x42, 0x00 },
	{ 0x22, 0x80 },
};

static const reg_write_t vadj_1v2_writes[] = {
	{ 0x24, 0x01 },
	{ 0x25, 0x33 },
	{ 0x3A, 0x01 },
	{ 0x3B, 0x8F },
	{ 0x3D, 0x01 },
	{ 0x3E, 0x8F },
	{ 0x3F, 0x00 },
	{ 0x40, 0x00 },
	{ 0x41, 0x00 },
	{ 0x42, 0x00 },
	{ 0x22, 0x80 },
};

static int iic_write(XIicPs *iic, u8 addr, u8 *buf, int len)
{
	int status;

	status = XIicPs_MasterSendPolled(iic, buf, len, addr);
	if (status != XST_SUCCESS)
		return status;

	while (XIicPs_BusIsBusy(iic))
		;

	return XST_SUCCESS;
}

static int iic_write_reg(XIicPs *iic, u8 addr, u8 reg, u8 val)
{
	u8 buf[2] = { reg, val };
	return iic_write(iic, addr, buf, 2);
}

int vadj_enable(vadj_voltage_t voltage)
{
	XIicPs iic;
	XIicPs_Config *cfg;
	int status;
	const reg_write_t *writes;
	int num_writes;
	const char *label;

	switch (voltage) {
	case VADJ_1V5:
		writes = vadj_1v5_writes;
		num_writes = sizeof(vadj_1v5_writes) / sizeof(vadj_1v5_writes[0]);
		label = "1.5V";
		break;
	case VADJ_1V2:
		writes = vadj_1v2_writes;
		num_writes = sizeof(vadj_1v2_writes) / sizeof(vadj_1v2_writes[0]);
		label = "1.2V";
		break;
	default:
		xil_printf("VADJ: unknown voltage setting\r\n");
		return XST_FAILURE;
	}

#if defined(SDT) && defined(XPAR_XIICPS_0_BASEADDR)
	cfg = XIicPs_LookupConfig(XPAR_XIICPS_0_BASEADDR);
#else
	cfg = XIicPs_LookupConfig(XPAR_XIICPS_0_DEVICE_ID);
#endif
	if (cfg == NULL) {
		xil_printf("VADJ: I2C0 config lookup failed\r\n");
		return XST_FAILURE;
	}

	status = XIicPs_CfgInitialize(&iic, cfg, cfg->BaseAddress);
	if (status != XST_SUCCESS) {
		xil_printf("VADJ: I2C0 init failed\r\n");
		return XST_FAILURE;
	}

	XIicPs_SetSClk(&iic, IIC_SCLK_RATE);

	/* Select I2C mux channel */
	u8 mux_ch = I2C_MUX_CHANNEL;
	status = iic_write(&iic, I2C_MUX_ADDR, &mux_ch, 1);
	if (status != XST_SUCCESS) {
		xil_printf("VADJ: I2C mux select failed\r\n");
		return XST_FAILURE;
	}

	/* Configure VADJ via power controller at 0x1E */
	for (int i = 0; i < num_writes; i++) {
		status = iic_write_reg(&iic, POWER_CTRL_ADDR,
				       writes[i].reg, writes[i].val);
		if (status != XST_SUCCESS) {
			xil_printf("VADJ: write to reg 0x%02x failed\r\n",
				   writes[i].reg);
			return XST_FAILURE;
		}
	}

	xil_printf("VADJ: %s enabled successfully\r\n", label);
	return XST_SUCCESS;
}

#else /* Other Versal boards (vhk158) — VADJ not yet supported */

int vadj_enable(vadj_voltage_t voltage)
{
	(void)voltage;
	xil_printf("WARNING: VADJ for this board has not been enabled!\r\n");
	return XST_SUCCESS;
}

#endif /* BOARD_VCK190 || BOARD_VMK180 || BOARD_VPK120 || BOARD_VPK180 */

#else /* Non-Versal boards and vek280 (VADJ enabled by default) */

#include "vadj.h"

int vadj_enable(vadj_voltage_t voltage)
{
	(void)voltage;
	return 0;
}

#endif

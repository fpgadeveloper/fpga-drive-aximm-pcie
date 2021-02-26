/******************************************************************************
*
* Copyright (C) 2011 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/
/****************************************************************************/
/**
* Opsero Electronic Design Inc. 2017
*
* This application is a modified version of the example provided in the 
* Xilinx SDK 2017.1 at this location:
*
* \Xilinx\SDK\2017.1\data\embeddedsw\XilinxProcessorIPLib\drivers\axipcie_v3_1\examples\xaxipcie_rc_enumerate_example.c
* 
* The code demonstrates how to:
*	- Initialize a AXI Memory Mapped to PCIe IP core OR
*     AXI Bridge for PCIe Gen3 IP core built as a root complex
*   - Determine link speed and width once a link is established
*	- Enumerate PCIe end points in the system
*
*
*****************************************************************************/

/***************************** Include Files ********************************/

#include "xparameters.h"	/* Defines for XPAR constants */
#include "xaxipcie.h"		/* XAxiPcie level 1 interface */
#include "stdio.h"
#include "xil_printf.h"

/************************** Constant Definitions ****************************/


#define AXIPCIE_DEVICE_ID 	XPAR_AXIPCIE_0_DEVICE_ID


/*
 * Command register offsets
 */
#define PCIE_CFG_CMD_IO_EN	0x00000001 /* I/O access enable */
#define PCIE_CFG_CMD_MEM_EN	0x00000002 /* Memory access enable */
#define PCIE_CFG_CMD_BUSM_EN	0x00000004 /* Bus master enable */
#define PCIE_CFG_CMD_PARITY	0x00000040 /* parity errors response */
#define PCIE_CFG_CMD_SERR_EN	0x00000100 /* SERR report enable */

/*
 * PCIe Configuration registers offsets
 */

#define PCIE_CFG_ID_REG			0x0000 /* Vendor ID/Device ID offset */
#define PCIE_CFG_CMD_STATUS_REG		0x0001 /*
						* Command/Status Register
						* Offset
						*/
#define PCIE_CFG_PRI_SEC_BUS_REG	0x0006 /*
						* Primary/Sec.Bus Register
						* Offset
						*/
#define PCIE_CFG_CAH_LAT_HD_REG		0x0003 /*
 						* Cache Line/Latency Timer/
 						* Header Type/
 						* BIST Register Offset
 						*/
#define PCIE_CFG_BAR_0_REG		0x0004 /* PCIe Base Addr 0 */

#define PCIE_CFG_FUN_NOT_IMP_MASK	0xFFFF
#define PCIE_CFG_HEADER_TYPE_MASK	0x00EF0000
#define PCIE_CFG_MUL_FUN_DEV_MASK	0x00800000


#define PCIE_CFG_MAX_NUM_OF_BUS		256
#define PCIE_CFG_MAX_NUM_OF_DEV		1
#define PCIE_CFG_MAX_NUM_OF_FUN		8

#define PCIE_CFG_PRIM_SEC_BUS		0x00070100

#define PCIE_CFG_HEADER_O_TYPE		0x0000

#define PCIE_CFG_BAR_0_ADDR		0x00001111

/*
* Macros for reading link speed and width from the core
*/

#define	 XAxiPcie_IsGen3(InstancePtr) 	\
	(XAxiPcie_ReadReg((InstancePtr)->Config.BaseAddress, 	\
	XAXIPCIE_PHYSC_OFFSET) & 0x00001000) ? 1 : 0

#define	 XAxiPcie_IsGen2(InstancePtr) 	\
	(XAxiPcie_ReadReg((InstancePtr)->Config.BaseAddress, 	\
	XAXIPCIE_PHYSC_OFFSET) & 0x00000001) ? 1 : 0

#define	 XAxiPcie_LinkWidth(InstancePtr) 	\
	((XAxiPcie_ReadReg((InstancePtr)->Config.BaseAddress, 	\
	XAXIPCIE_PHYSC_OFFSET) & XAXIPCIE_PHYSC_LINK_WIDTH_MASK) >> 1)


/**************************** Type Definitions ******************************/


/***************** Macros (Inline Functions) Definitions ********************/


/************************** Function Prototypes *****************************/

int PcieInitRootComplex(XAxiPcie *AxiPciePtr, u16 DeviceId);
void PCIeEnumerateFabric(XAxiPcie *AxiPciePtr);

static void __attribute__ ((noinline)) UtilDelay(unsigned int Seconds);

/************************** Variable Definitions ****************************/

/* Allocate PCIe Root Complex IP Instance */
XAxiPcie AxiPcieInstance;

/****************************************************************************/
/**
* This function is the entry point for PCIe Root Complex Enumeration Example
*
* @param 	None
*
* @return 	- XST_SUCCESS if successful
*		- XST_FAILURE if unsuccessful.
*
* @note 	None.
*
*****************************************************************************/
int main(void)
{

	int Status;

	// Allow time for link-up
	UtilDelay(1);

	xil_printf("=============================\r\n");
	xil_printf("PCIe Enumeration Example\r\n");
	xil_printf("=============================\r\n");
	
	/* Initialize Root Complex */
	Status = PcieInitRootComplex(&AxiPcieInstance, AXIPCIE_DEVICE_ID);

	if (Status != XST_SUCCESS) {
		xil_printf("Failed to initialize AXI PCIe Root port\r\n");
		return XST_FAILURE;
	}

	/* Scan PCIe Fabric */
	PCIeEnumerateFabric(&AxiPcieInstance);

	return XST_SUCCESS;
}


/****************************************************************************/
/**
* This function returns the negotiated PCIe link speed once link-up is achieved
*
* @param	AxiPciePtr is a pointer to an instance of XAxiPcie data
*		structure represents a root complex IP.
* @return	- 1 if Gen1
*           - 2 if Gen2
*           - 3 if Gen3
*		- 0 if unsuccessful.
*
* @note 	None.
*
*
******************************************************************************/

int get_pcie_link_speed(XAxiPcie *AxiPciePtr)
{
	int is_gen2;
	int is_gen3;
	
	is_gen2 = XAxiPcie_IsGen2(AxiPciePtr);
	is_gen3 = XAxiPcie_IsGen3(AxiPciePtr);
	
	if((is_gen2 == 0) && (is_gen3 == 1))
		return(3);
	if((is_gen2 == 1) && (is_gen3 == 0))
		return(2);
	if((is_gen2 == 0) && (is_gen3 == 0))
		return(1);
	return(0);
}

/****************************************************************************/
/**
* This function returns the negotiated PCIe link width once link-up is achieved
*
* @param	AxiPciePtr is a pointer to an instance of XAxiPcie data
*		structure represents a root complex IP.
* @return	- link width (1,2,4 or 8)
*
* @note 	None.
*
*
******************************************************************************/

int get_pcie_link_width(XAxiPcie *AxiPciePtr)
{
	int i;
	int link_width;
	int result;
	
	link_width = XAxiPcie_LinkWidth(AxiPciePtr);
	result = 1;
	for(i = 0; i < link_width; i++)
		result = result * 2;
	return(result);
}


/****************************************************************************/
/**
* This function initializes a AXI PCIe IP built as a root complex
*
* @param	AxiPciePtr is a pointer to an instance of XAxiPcie data
*		structure represents a root complex IP.
* @param 	DeviceId is AXI PCIe IP unique ID
*
* @return	- XST_SUCCESS if successful.
*		- XST_FAILURE if unsuccessful.
*
* @note 	None.
*
*
******************************************************************************/
int PcieInitRootComplex(XAxiPcie *AxiPciePtr, u16 DeviceId)
{
	int Status;
	u32 HeaderData;
	u32 InterruptMask;
	u8  BusNumber;
	u8  DeviceNumber;
	u8  FunNumber;
	u8  PortNumber;

	XAxiPcie_Config *ConfigPtr;

	ConfigPtr = XAxiPcie_LookupConfig(DeviceId);

	Status = XAxiPcie_CfgInitialize(AxiPciePtr, ConfigPtr,
						ConfigPtr->BaseAddress);

	if (Status != XST_SUCCESS) {
		xil_printf("Failed to initialize PCIe Root Complex"
							"IP Instance\r\n");
		return XST_FAILURE;
	}

	if(!AxiPciePtr->Config.IncludeRootComplex) {
		xil_printf("Failed to initialize...AXI PCIE is configured"
							" as endpoint\r\n");
		return XST_FAILURE;
	}

	/* Make sure link is up. */
	Status = XAxiPcie_IsLinkUp(AxiPciePtr);
	if (Status != TRUE ) {
		xil_printf("Link:\r\n  - LINK NOT UP!\r\n");
		return XST_FAILURE;
	}

	xil_printf("Link:\r\n  - LINK UP, Gen%d x%d lanes\r\n",
		get_pcie_link_speed(AxiPciePtr),get_pcie_link_width(AxiPciePtr));

	xil_printf("Interrupts:\r\n");

	/* See what interrupts are currently enabled */
	XAxiPcie_GetEnabledInterrupts(AxiPciePtr, &InterruptMask);
	xil_printf("  - currently enabled: %8X\r\n", InterruptMask);

	/* Make sure all interrupts disabled. */
	XAxiPcie_DisableInterrupts(AxiPciePtr, XAXIPCIE_IM_ENABLE_ALL_MASK);


	/* See what interrupts are currently pending */
	XAxiPcie_GetPendingInterrupts(AxiPciePtr, &InterruptMask);
	xil_printf("  - currently pending: %8X\r\n", InterruptMask);

	/* Just if there is any pending interrupt then clear it.*/
	XAxiPcie_ClearPendingInterrupts(AxiPciePtr,
						XAXIPCIE_ID_CLEAR_ALL_MASK);

	/*
	 * Read enabled interrupts and pending interrupts
	 * to verify the previous two operations and also
	 * to test those two API functions
	 */

	xil_printf("Cleared pending interrupts:\r\n");

	XAxiPcie_GetEnabledInterrupts(AxiPciePtr, &InterruptMask);
	xil_printf("  - currently enabled: %8X\r\n", InterruptMask);

	XAxiPcie_GetPendingInterrupts(AxiPciePtr, &InterruptMask);
	xil_printf("  - currently pending: %8X\r\n", InterruptMask);

	/*
	 * Read back requester ID.
	 */
	XAxiPcie_GetRequesterId(AxiPciePtr, &BusNumber,
				&DeviceNumber, &FunNumber, &PortNumber);

	xil_printf("Requester ID:\r\n");
	xil_printf("  - Bus Number: %02X\r\n"
			"  - Device Number: %02X\r\n"
	 			"  - Function Number: %02X\r\n"
	 				"  - Port Number: %02X\r\n",
	 		BusNumber, DeviceNumber, FunNumber, PortNumber);


	/* Set up the PCIe header of this Root Complex */
	XAxiPcie_ReadLocalConfigSpace(AxiPciePtr,
					PCIE_CFG_CMD_STATUS_REG, &HeaderData);

	HeaderData |= (PCIE_CFG_CMD_BUSM_EN | PCIE_CFG_CMD_MEM_EN |
				PCIE_CFG_CMD_IO_EN | PCIE_CFG_CMD_PARITY |
							PCIE_CFG_CMD_SERR_EN);

	XAxiPcie_WriteLocalConfigSpace(AxiPciePtr,
					PCIE_CFG_CMD_STATUS_REG, HeaderData);

	/*
	 * Read back local config reg.
	 * to verify the write.
	 */

	xil_printf("PCIe Local Config Space:\r\n");

	XAxiPcie_ReadLocalConfigSpace(AxiPciePtr,
					PCIE_CFG_CMD_STATUS_REG, &HeaderData);

	xil_printf("  - %8X at register CommandStatus\r\n", HeaderData);

	/*
	 * Set up Bus number
	 */

	HeaderData = PCIE_CFG_PRIM_SEC_BUS;

	XAxiPcie_WriteLocalConfigSpace(AxiPciePtr,
					PCIE_CFG_PRI_SEC_BUS_REG, HeaderData);

	/*
	 * Read back local config reg.
	 * to verify the write.
	 */
	XAxiPcie_ReadLocalConfigSpace(AxiPciePtr,
					PCIE_CFG_PRI_SEC_BUS_REG, &HeaderData);

	xil_printf("  - %8X at register Prim Sec. Bus\r\n", HeaderData);

	/* Now it is ready to function */

	return XST_SUCCESS;
}

/*****************************************************************************/
/**
* This function enumerates its PCIe system and figures out the nature of each
* component there like end points,bridges,...
*
* @param 	AxiPciePtr is a pointer to an instance of XAxiPcie
*		data structure represents a root complex IP.
*
* @return 	None.
*
* @note 	None.
*
******************************************************************************/
void PCIeEnumerateFabric(XAxiPcie *AxiPciePtr)
{

	u32 ConfigData;
	u32 PCIeHeaderType;
	u32 PCIeMultiFun;
	u32 PCIeBusNum;
	u32 PCIeDevNum;
	u32 PCIeFunNum;
	u16 PCIeVendorID;
	u32 RegVal;

	xil_printf("Enumeration of PCIe Fabric:\r\n");

	/* Scan PCIe Fabric */

	for (PCIeBusNum = 0; PCIeBusNum < PCIE_CFG_MAX_NUM_OF_BUS;
								PCIeBusNum++) {
		for (PCIeDevNum = 0; PCIeDevNum < PCIE_CFG_MAX_NUM_OF_DEV;
								PCIeDevNum++) {
			for (PCIeFunNum = 0;
				PCIeFunNum < PCIE_CFG_MAX_NUM_OF_FUN;
								PCIeFunNum++) {

				/* Vendor ID */
				XAxiPcie_ReadRemoteConfigSpace(
					AxiPciePtr,PCIeBusNum,
					PCIeDevNum, PCIeFunNum,
					PCIE_CFG_ID_REG, &ConfigData);

				PCIeVendorID = (u16) (ConfigData & 0xFFFF);

				if (PCIeVendorID ==
						PCIE_CFG_FUN_NOT_IMP_MASK) {
					if (PCIeFunNum == 0)
					/*
					 * We don't need to look
					 * any further on this device.
					 */
					break;
				}
				else {
					xil_printf("PCIeBus %02X:\r\n"
						"  - PCIeDev: %02X\r\n"
						"  - PCIeFunc: %02X\r\n",
						PCIeBusNum, PCIeDevNum,
								PCIeFunNum);

					xil_printf("  - Vendor ID: %04X \r\n",
								PCIeVendorID);

					/* Header Type */
					XAxiPcie_ReadRemoteConfigSpace(
						AxiPciePtr, PCIeBusNum,
						PCIeDevNum, PCIeFunNum,
						PCIE_CFG_CAH_LAT_HD_REG,
						&ConfigData);

					PCIeHeaderType = ConfigData &
						PCIE_CFG_HEADER_TYPE_MASK;

					PCIeMultiFun = ConfigData &
						PCIE_CFG_MUL_FUN_DEV_MASK;

					if (PCIeHeaderType ==
						PCIE_CFG_HEADER_O_TYPE) {
						/* This is an End Point */
						xil_printf("  - End Point\r\n");

						/*
						 * Initialize this end point
						 * and return.
						 */

						XAxiPcie_ReadRemoteConfigSpace(
							AxiPciePtr,
							PCIeBusNum, PCIeDevNum,
							PCIeFunNum,
						PCIE_CFG_CMD_STATUS_REG,
								&ConfigData);

						ConfigData |=
						(PCIE_CFG_CMD_BUSM_EN |
							PCIE_CFG_CMD_MEM_EN);

						XAxiPcie_WriteRemoteConfigSpace
							(AxiPciePtr,
							PCIeBusNum, PCIeDevNum,
							PCIeFunNum,
						PCIE_CFG_CMD_STATUS_REG,
								ConfigData);

						/*
						 * Write Address to
						 * PCIe BAR0
						 */
						ConfigData =
						(PCIE_CFG_BAR_0_ADDR |
							PCIeBusNum |
							PCIeDevNum |
							PCIeFunNum);

						XAxiPcie_WriteRemoteConfigSpace
						(AxiPciePtr,
						PCIeBusNum, PCIeDevNum,
						PCIeFunNum, PCIE_CFG_BAR_0_REG,
						ConfigData);

						xil_printf("  - End Point has been"
							" enabled\r\n");

					}
					else {
						/* This is a bridge */
						xil_printf("  - Bridge\r\n");
					}
				}

				if ((!PCIeFunNum) && (!PCIeMultiFun)) {
					/*
					 * If it is function 0 and it is not a
					 * multi function device, we don't need
					 * to look any further on this devie
					 */
					break;
				}
			}  /* Functions in one device */
		}  /* Devices on the same bus */
	}  /* Buses in the same system */

	xil_printf("End of Enumeration\r\n");

	/* Bridge enable */
	XAxiPcie_GetRootPortStatusCtrl(AxiPciePtr, &RegVal);
	RegVal |= XAXIPCIE_RPSC_BRIDGE_ENABLE_MASK;
	XAxiPcie_SetRootPortStatusCtrl(AxiPciePtr, RegVal);

	return;
}


static void __attribute__ ((noinline)) UtilDelay(unsigned int Seconds)
{
#if defined (__MICROBLAZE__) || defined(__PPC__)
	static int WarningFlag = 0;

	/* If MB caches are disabled or do not exist, this delay loop could
	 * take minutes instead of seconds (e.g., 30x longer).  Print a warning
	 * message for the user (once).  If only MB had a built-in timer!
	 */
	if (((mfmsr() & 0x20) == 0) && (!WarningFlag)) {
		WarningFlag = 1;
	}

#define ITERS_PER_SEC   (XPAR_CPU_CORE_CLOCK_FREQ_HZ / 6)
    asm volatile ("\n"
			"1:               \n\t"
			"addik r7, r0, %0 \n\t"
			"2:               \n\t"
			"addik r7, r7, -1 \n\t"
			"bneid  r7, 2b    \n\t"
			"or  r0, r0, r0   \n\t"
			"bneid %1, 1b     \n\t"
			"addik %1, %1, -1 \n\t"
			:: "i"(ITERS_PER_SEC), "d" (Seconds));
#else
    sleep(Seconds);
#endif
}



/*******************************************************************
*
* Opsero Electronic Design Inc.
* 
* This file contains a fixed configuration table for the QDMAs
* in the Versal designs. The values for BASEADDR and ECAMADDR
* must match those in the Vivado design for this to function
* correctly. The reason for using this file rather than the 
* auto-generated xdmapcie_g.c file is that in Vitis 2024.1 the
* auto-generated file does not contain the address of the CSR 
* interface (S_AXI_LITE_CSR). The ideal solution would be to
* patch the xdmapcie.tcl file so that the xdmapcie_g.c file
* was generated with the needed addresses.
*
*******************************************************************/

#include "xparameters.h"
#include "xdmapcie.h"

// Address of S_AXI_LITE_CSR interfaces (BaseAddress in XDmaPcie_Config)
#define OPSERO_QDMA_0_BASEADDR 0x80000000
#define OPSERO_QDMA_1_BASEADDR 0x90000000
// Address of S_AXI_LITE interfaces (ECam in XDmaPcie_Config)
#define OPSERO_QDMA_0_ECAMADDR XPAR_QDMA_0_BASEADDR
#define OPSERO_QDMA_1_ECAMADDR XPAR_QDMA_1_BASEADDR

/*
* The configuration table for devices
*/

#if XPAR_XDMAPCIE_NUM_INSTANCES == 1
XDmaPcie_Config XQdmaPcie_ConfigTable[XPAR_XDMAPCIE_NUM_INSTANCES] =
{
	{
		XPAR_QDMA_0_DEVICE_ID,
		OPSERO_QDMA_0_BASEADDR,
		XPAR_QDMA_0_AXIBAR_NUM,
		XPAR_QDMA_0_INCLUDE_BAROFFSET_REG,
		XPAR_QDMA_0_DEVICE_PORT_TYPE,
		OPSERO_QDMA_0_ECAMADDR,
		XPAR_QDMA_0_AXIBAR_0,
		XPAR_QDMA_0_AXIBAR_1,
		XPAR_QDMA_0_AXIBAR_HIGHADDR_0,
		XPAR_QDMA_0_AXIBAR_HIGHADDR_1
	}
};

#elif XPAR_XDMAPCIE_NUM_INSTANCES == 2
XDmaPcie_Config XQdmaPcie_ConfigTable[XPAR_XDMAPCIE_NUM_INSTANCES] =
{
	{
		XPAR_QDMA_0_DEVICE_ID,
		OPSERO_QDMA_0_BASEADDR,
		XPAR_QDMA_0_AXIBAR_NUM,
		XPAR_QDMA_0_INCLUDE_BAROFFSET_REG,
		XPAR_QDMA_0_DEVICE_PORT_TYPE,
		OPSERO_QDMA_0_ECAMADDR,
		XPAR_QDMA_0_AXIBAR_0,
		XPAR_QDMA_0_AXIBAR_1,
		XPAR_QDMA_0_AXIBAR_HIGHADDR_0,
		XPAR_QDMA_0_AXIBAR_HIGHADDR_1
	},
	{
		XPAR_QDMA_1_DEVICE_ID,
		OPSERO_QDMA_1_BASEADDR,
		XPAR_QDMA_1_AXIBAR_NUM,
		XPAR_QDMA_1_INCLUDE_BAROFFSET_REG,
		XPAR_QDMA_1_DEVICE_PORT_TYPE,
		OPSERO_QDMA_1_ECAMADDR,
		XPAR_QDMA_1_AXIBAR_0,
		XPAR_QDMA_1_AXIBAR_1,
		XPAR_QDMA_1_AXIBAR_HIGHADDR_0,
		XPAR_QDMA_1_AXIBAR_HIGHADDR_1
	}
};

#else
    #error "The design must have 1 or 2 QDMAs."
#endif

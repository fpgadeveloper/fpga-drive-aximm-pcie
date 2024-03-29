# These constraints apply to the VMK180 FMCP1 with FPGA Drive FMC Gen4 using 2x SSDs
# ----------------------------------------------------------------------------------

# SSD1 PCI Express reset LA00_P_CC (perst_0) - IOSTANDARD determined by VADJ
set_property PACKAGE_PIN BD23 [get_ports {perst_0[0]}]
set_property IOSTANDARD LVCMOS15 [get_ports {perst_0[0]}]

# SSD2 PCI Express reset LA04_P (perst_1) - IOSTANDARD determined by VADJ
set_property PACKAGE_PIN AU21 [get_ports {perst_1[0]}]
set_property IOSTANDARD LVCMOS15 [get_ports {perst_1[0]}]

# PEDET_0 - LA00_N_CC - F16 - IOSTANDARD determined by VADJ
# PEDET_1 - LA04_N - L16 - IOSTANDARD determined by VADJ

# Disable signal for 3.3V power supply for SSD2 - LA07_P (disable_ssd2_pwr)
set_property PACKAGE_PIN BC25 [get_ports disable_ssd2_pwr]
set_property IOSTANDARD LVCMOS15 [get_ports disable_ssd2_pwr]

# PCI Express reference clock 100MHz
# IOSTANDARD for GT reference clock does not need to be specified
# SSD1 ref clock connects to MGT bank 201, CLK1 input
set_property PACKAGE_PIN M15 [get_ports {ref_clk_0_clk_p[0]}]
set_property PACKAGE_PIN M14 [get_ports {ref_clk_0_clk_n[0]}]
create_clock -period 10.000 -name ref_clk_0_clk_p -waveform {0.000 5.000} [get_ports ref_clk_0_clk_p]
# SSD2 ref clock connects to MGT bank 202, CLK1 input
set_property PACKAGE_PIN K15 [get_ports {ref_clk_1_clk_p[0]}]
set_property PACKAGE_PIN K14 [get_ports {ref_clk_1_clk_n[0]}]
create_clock -period 10.000 -name ref_clk_1_clk_p -waveform {0.000 5.000} [get_ports ref_clk_1_clk_p]

# MGT locations
# SSD1 FMCP_DP0-3 (PCIe lanes 0-3) are connected to MGT bank 201 in this order: 0->0, 1->1, 2->2, 3->3
set_property PACKAGE_PIN AB7 [get_ports {pci_exp_0_gtx_p[0]}]
set_property PACKAGE_PIN AB6 [get_ports {pci_exp_0_gtx_n[0]}]
set_property PACKAGE_PIN AB2 [get_ports {pci_exp_0_grx_p[0]}]
set_property PACKAGE_PIN AB1 [get_ports {pci_exp_0_grx_n[0]}]
set_property PACKAGE_PIN AA9 [get_ports {pci_exp_0_gtx_p[1]}]
set_property PACKAGE_PIN AA8 [get_ports {pci_exp_0_gtx_n[1]}]
set_property PACKAGE_PIN AA4 [get_ports {pci_exp_0_grx_p[1]}]
set_property PACKAGE_PIN AA3 [get_ports {pci_exp_0_grx_n[1]}]
set_property PACKAGE_PIN Y7 [get_ports {pci_exp_0_gtx_p[2]}]
set_property PACKAGE_PIN Y6 [get_ports {pci_exp_0_gtx_n[2]}]
set_property PACKAGE_PIN Y2 [get_ports {pci_exp_0_grx_p[2]}]
set_property PACKAGE_PIN Y1 [get_ports {pci_exp_0_grx_n[2]}]
set_property PACKAGE_PIN W9 [get_ports {pci_exp_0_gtx_p[3]}]
set_property PACKAGE_PIN W8 [get_ports {pci_exp_0_gtx_n[3]}]
set_property PACKAGE_PIN W4 [get_ports {pci_exp_0_grx_p[3]}]
set_property PACKAGE_PIN W3 [get_ports {pci_exp_0_grx_n[3]}]

# SSD2 FMCP_DP4-7 (PCIe lanes 0-3) are connected to MGT bank 202 in this order: 0->0, 1->1, 2->2, 3->3
set_property PACKAGE_PIN V7 [get_ports {pci_exp_1_gtx_p[0]}]
set_property PACKAGE_PIN V6 [get_ports {pci_exp_1_gtx_n[0]}]
set_property PACKAGE_PIN V2 [get_ports {pci_exp_1_grx_p[0]}]
set_property PACKAGE_PIN V1 [get_ports {pci_exp_1_grx_n[0]}]
set_property PACKAGE_PIN U9 [get_ports {pci_exp_1_gtx_p[1]}]
set_property PACKAGE_PIN U8 [get_ports {pci_exp_1_gtx_n[1]}]
set_property PACKAGE_PIN U4 [get_ports {pci_exp_1_grx_p[1]}]
set_property PACKAGE_PIN U3 [get_ports {pci_exp_1_grx_n[1]}]
set_property PACKAGE_PIN T7 [get_ports {pci_exp_1_gtx_p[2]}]
set_property PACKAGE_PIN T6 [get_ports {pci_exp_1_gtx_n[2]}]
set_property PACKAGE_PIN T2 [get_ports {pci_exp_1_grx_p[2]}]
set_property PACKAGE_PIN T1 [get_ports {pci_exp_1_grx_n[2]}]
set_property PACKAGE_PIN R9 [get_ports {pci_exp_1_gtx_p[3]}]
set_property PACKAGE_PIN R8 [get_ports {pci_exp_1_gtx_n[3]}]
set_property PACKAGE_PIN R4 [get_ports {pci_exp_1_grx_p[3]}]
set_property PACKAGE_PIN R3 [get_ports {pci_exp_1_grx_n[3]}]


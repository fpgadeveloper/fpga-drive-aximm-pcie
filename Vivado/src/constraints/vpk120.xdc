# These constraints apply to the VPK120 FMCP with FPGA Drive FMC Gen4 using 2x SSDs
# ----------------------------------------------------------------------------------

# SSD1 PCI Express reset LA00_P_CC (perst_0) - IOSTANDARD determined by VADJ
set_property PACKAGE_PIN G26 [get_ports {perst_0[0]}]
set_property IOSTANDARD LVCMOS15 [get_ports {perst_0[0]}]

# SSD2 PCI Express reset LA04_P (perst_1) - IOSTANDARD determined by VADJ
set_property PACKAGE_PIN H27 [get_ports {perst_1[0]}]
set_property IOSTANDARD LVCMOS15 [get_ports {perst_1[0]}]

# PEDET_0 - LA00_N_CC - F26 - IOSTANDARD determined by VADJ
# PEDET_1 - LA04_N - G28 - IOSTANDARD determined by VADJ

# Disable signal for 3.3V power supply for SSD2 - LA07_P (disable_ssd2_pwr)
set_property PACKAGE_PIN F28 [get_ports disable_ssd2_pwr]
set_property IOSTANDARD LVCMOS15 [get_ports disable_ssd2_pwr]

# PCI Express reference clock 100MHz
# IOSTANDARD for GT reference clock does not need to be specified
# SSD1 ref clock connects to MGT bank 200, CLK1 input
set_property PACKAGE_PIN AU47 [get_ports {ref_clk_0_clk_p[0]}]
set_property PACKAGE_PIN AU48 [get_ports {ref_clk_0_clk_n[0]}]
create_clock -period 10.000 -name ref_clk_0_clk_p -waveform {0.000 5.000} [get_ports ref_clk_0_clk_p]
# SSD2 ref clock connects to MGT bank 201, CLK1 input
set_property PACKAGE_PIN AN47 [get_ports {ref_clk_1_clk_p[0]}]
set_property PACKAGE_PIN AN48 [get_ports {ref_clk_1_clk_n[0]}]
create_clock -period 10.000 -name ref_clk_1_clk_p -waveform {0.000 5.000} [get_ports ref_clk_1_clk_p]

# MGT locations
# SSD1 FMCP_DP0-3 (PCIe lanes 0-3) are connected to MGT bank 200 in this order: 0->0, 1->1, 2->2, 3->3
set_property PACKAGE_PIN BJ36 [get_ports {pci_exp_0_gtx_p[0]}]
set_property PACKAGE_PIN BK36 [get_ports {pci_exp_0_gtx_n[0]}]
set_property PACKAGE_PIN BM37 [get_ports {pci_exp_0_grx_p[0]}]
set_property PACKAGE_PIN BN37 [get_ports {pci_exp_0_grx_n[0]}]
set_property PACKAGE_PIN BG37 [get_ports {pci_exp_0_gtx_p[1]}]
set_property PACKAGE_PIN BH37 [get_ports {pci_exp_0_gtx_n[1]}]
set_property PACKAGE_PIN BM39 [get_ports {pci_exp_0_grx_p[1]}]
set_property PACKAGE_PIN BN39 [get_ports {pci_exp_0_grx_n[1]}]
set_property PACKAGE_PIN BJ38 [get_ports {pci_exp_0_gtx_p[2]}]
set_property PACKAGE_PIN BK38 [get_ports {pci_exp_0_gtx_n[2]}]
set_property PACKAGE_PIN BM41 [get_ports {pci_exp_0_grx_p[2]}]
set_property PACKAGE_PIN BN41 [get_ports {pci_exp_0_grx_n[2]}]
set_property PACKAGE_PIN BG39 [get_ports {pci_exp_0_gtx_p[3]}]
set_property PACKAGE_PIN BH39 [get_ports {pci_exp_0_gtx_n[3]}]
set_property PACKAGE_PIN BM43 [get_ports {pci_exp_0_grx_p[3]}]
set_property PACKAGE_PIN BN43 [get_ports {pci_exp_0_grx_n[3]}]

# SSD2 FMCP_DP4-7 (PCIe lanes 0-3) are connected to MGT bank 201 in this order: 0->0, 1->1, 2->2, 3->3
set_property PACKAGE_PIN BJ40 [get_ports {pci_exp_1_gtx_p[0]}]
set_property PACKAGE_PIN BK40 [get_ports {pci_exp_1_gtx_n[0]}]
set_property PACKAGE_PIN BK44 [get_ports {pci_exp_1_grx_p[0]}]
set_property PACKAGE_PIN BL44 [get_ports {pci_exp_1_grx_n[0]}]
set_property PACKAGE_PIN BG41 [get_ports {pci_exp_1_gtx_p[1]}]
set_property PACKAGE_PIN BH41 [get_ports {pci_exp_1_gtx_n[1]}]
set_property PACKAGE_PIN BM45 [get_ports {pci_exp_1_grx_p[1]}]
set_property PACKAGE_PIN BN45 [get_ports {pci_exp_1_grx_n[1]}]
set_property PACKAGE_PIN BJ42 [get_ports {pci_exp_1_gtx_p[2]}]
set_property PACKAGE_PIN BK42 [get_ports {pci_exp_1_gtx_n[2]}]
set_property PACKAGE_PIN BK46 [get_ports {pci_exp_1_grx_p[2]}]
set_property PACKAGE_PIN BL46 [get_ports {pci_exp_1_grx_n[2]}]
set_property PACKAGE_PIN BG43 [get_ports {pci_exp_1_gtx_p[3]}]
set_property PACKAGE_PIN BH43 [get_ports {pci_exp_1_gtx_n[3]}]
set_property PACKAGE_PIN BM47 [get_ports {pci_exp_1_grx_p[3]}]
set_property PACKAGE_PIN BN47 [get_ports {pci_exp_1_grx_n[3]}]


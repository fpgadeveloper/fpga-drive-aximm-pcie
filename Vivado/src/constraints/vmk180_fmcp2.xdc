# These constraints apply to the VMK180 FMCP2 with FPGA Drive FMC Gen4 using 2x SSDs
# ----------------------------------------------------------------------------------

# SSD1 PCI Express reset LA00_P_CC (perst_0) - IOSTANDARD determined by VADJ
set_property PACKAGE_PIN BC13 [get_ports {perst_0[0]}]
set_property IOSTANDARD LVCMOS15 [get_ports {perst_0[0]}]

# SSD2 PCI Express reset LA04_P (perst_1) - IOSTANDARD determined by VADJ
set_property PACKAGE_PIN BF11 [get_ports {perst_1[0]}]
set_property IOSTANDARD LVCMOS15 [get_ports {perst_1[0]}]

# PEDET_0 - LA00_N_CC - F16 - IOSTANDARD determined by VADJ
# PEDET_1 - LA04_N - L16 - IOSTANDARD determined by VADJ

# Disable signal for 3.3V power supply for SSD2 - LA07_P (disable_ssd2_pwr)
set_property PACKAGE_PIN BG15 [get_ports disable_ssd2_pwr]
set_property IOSTANDARD LVCMOS15 [get_ports disable_ssd2_pwr]

# PCI Express reference clock 100MHz
# IOSTANDARD for GT reference clock does not need to be specified
# SSD1 ref clock connects to MGT bank 204, CLK1 input
set_property PACKAGE_PIN F15 [get_ports {ref_clk_0_clk_p[0]}]
set_property PACKAGE_PIN F14 [get_ports {ref_clk_0_clk_n[0]}]
create_clock -period 10.000 -name ref_clk_0_clk_p -waveform {0.000 5.000} [get_ports ref_clk_0_clk_p]
# SSD2 ref clock connects to MGT bank 205, CLK1 input
set_property PACKAGE_PIN D15 [get_ports {ref_clk_1_clk_p[0]}]
set_property PACKAGE_PIN D14 [get_ports {ref_clk_1_clk_n[0]}]
create_clock -period 10.000 -name ref_clk_1_clk_p -waveform {0.000 5.000} [get_ports ref_clk_1_clk_p]

# MGT locations
# SSD1 FMCP_DP0-3 (PCIe lanes 0-3) are connected to MGT bank 204 in this order: 0->0, 1->1, 2->2, 3->3
set_property PACKAGE_PIN K7 [get_ports {pci_exp_0_gtx_p[0]}]
set_property PACKAGE_PIN K6 [get_ports {pci_exp_0_gtx_n[0]}]
set_property PACKAGE_PIN K2 [get_ports {pci_exp_0_grx_p[0]}]
set_property PACKAGE_PIN K1 [get_ports {pci_exp_0_grx_n[0]}]
set_property PACKAGE_PIN K11 [get_ports {pci_exp_0_gtx_p[1]}]
set_property PACKAGE_PIN K10 [get_ports {pci_exp_0_gtx_n[1]}]
set_property PACKAGE_PIN J4 [get_ports {pci_exp_0_grx_p[1]}]
set_property PACKAGE_PIN J3 [get_ports {pci_exp_0_grx_n[1]}]
set_property PACKAGE_PIN J9 [get_ports {pci_exp_0_gtx_p[2]}]
set_property PACKAGE_PIN J8 [get_ports {pci_exp_0_gtx_n[2]}]
set_property PACKAGE_PIN H2 [get_ports {pci_exp_0_grx_p[2]}]
set_property PACKAGE_PIN H1 [get_ports {pci_exp_0_grx_n[2]}]
set_property PACKAGE_PIN H11 [get_ports {pci_exp_0_gtx_p[3]}]
set_property PACKAGE_PIN H10 [get_ports {pci_exp_0_gtx_n[3]}]
set_property PACKAGE_PIN H6 [get_ports {pci_exp_0_grx_p[3]}]
set_property PACKAGE_PIN H5 [get_ports {pci_exp_0_grx_n[3]}]

# SSD2 FMCP_DP4-7 (PCIe lanes 0-3) are connected to MGT bank 205 in this order: 0->0, 1->1, 2->2, 3->3
set_property PACKAGE_PIN G9 [get_ports {pci_exp_1_gtx_p[0]}]
set_property PACKAGE_PIN G8 [get_ports {pci_exp_1_gtx_n[0]}]
set_property PACKAGE_PIN G4 [get_ports {pci_exp_1_grx_p[0]}]
set_property PACKAGE_PIN G3 [get_ports {pci_exp_1_grx_n[0]}]
set_property PACKAGE_PIN F11 [get_ports {pci_exp_1_gtx_p[1]}]
set_property PACKAGE_PIN F10 [get_ports {pci_exp_1_gtx_n[1]}]
set_property PACKAGE_PIN F2 [get_ports {pci_exp_1_grx_p[1]}]
set_property PACKAGE_PIN F1 [get_ports {pci_exp_1_grx_n[1]}]
set_property PACKAGE_PIN E9 [get_ports {pci_exp_1_gtx_p[2]}]
set_property PACKAGE_PIN E8 [get_ports {pci_exp_1_gtx_n[2]}]
set_property PACKAGE_PIN F6 [get_ports {pci_exp_1_grx_p[2]}]
set_property PACKAGE_PIN F5 [get_ports {pci_exp_1_grx_n[2]}]
set_property PACKAGE_PIN D11 [get_ports {pci_exp_1_gtx_p[3]}]
set_property PACKAGE_PIN D10 [get_ports {pci_exp_1_gtx_n[3]}]
set_property PACKAGE_PIN E4 [get_ports {pci_exp_1_grx_p[3]}]
set_property PACKAGE_PIN E3 [get_ports {pci_exp_1_grx_n[3]}]


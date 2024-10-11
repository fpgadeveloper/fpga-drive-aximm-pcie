#----------------------------------------------------------------------------------------
# Constraints for Opsero FPGA Drive FMC Gen4 ref design for VCK190-FMCP2 using 2x SSDs
#----------------------------------------------------------------------------------------

# SSD1 PCI Express reset (perst_0)
set_property PACKAGE_PIN BC13 [get_ports {perst_0[0]}]; # LA00_CC_P
set_property IOSTANDARD LVCMOS15 [get_ports {perst_0[0]}]

# SSD2 PCI Express reset (perst_1)
set_property PACKAGE_PIN BF11 [get_ports {perst_1[0]}]; # LA04_P
set_property IOSTANDARD LVCMOS15 [get_ports {perst_1[0]}]

# SSD1 PE Detect (pedet_0, not connected in the design)
# set_property PACKAGE_PIN BD13 [get_ports {pedet_0[0]}]; # LA00_CC_N
# set_property IOSTANDARD LVCMOS15 [get_ports {pedet_0[0]}]

# SSD2 PE Detect (pedet_1, not connected in the design)
# set_property PACKAGE_PIN BG11 [get_ports {pedet_1[0]}]; # LA04_N
# set_property IOSTANDARD LVCMOS15 [get_ports {pedet_1[0]}]

# Disable signal for 3.3V power supply for SSD2 (disable_ssd2_pwr)
set_property PACKAGE_PIN BG15 [get_ports disable_ssd2_pwr]; # LA07_P
set_property IOSTANDARD LVCMOS15 [get_ports disable_ssd2_pwr]

##############################
# PCIe reference clock 100MHz
##############################

# SSD1 ref clock
set_property PACKAGE_PIN F15 [get_ports {ref_clk_0_clk_p[0]}]; # GBTCLK0_M2C_P
set_property PACKAGE_PIN F14 [get_ports {ref_clk_0_clk_n[0]}]; # GBTCLK0_M2C_N
create_clock -period 10.000 -name ref_clk_0_clk_p -waveform {0.000 5.000} [get_ports ref_clk_0_clk_p]

# SSD2 ref clock
set_property PACKAGE_PIN D15 [get_ports {ref_clk_1_clk_p[0]}]; # GBTCLK1_M2C_P
set_property PACKAGE_PIN D14 [get_ports {ref_clk_1_clk_n[0]}]; # GBTCLK1_M2C_N
create_clock -period 10.000 -name ref_clk_1_clk_p -waveform {0.000 5.000} [get_ports ref_clk_1_clk_p]

############################
# SSD1 Gigabit transceivers
############################

set_property PACKAGE_PIN K7 [get_ports {pci_exp_0_gtx_p[0]}]; # DP0_C2M_P
set_property PACKAGE_PIN K6 [get_ports {pci_exp_0_gtx_n[0]}]; # DP0_C2M_N
set_property PACKAGE_PIN K2 [get_ports {pci_exp_0_grx_p[0]}]; # DP0_M2C_P
set_property PACKAGE_PIN K1 [get_ports {pci_exp_0_grx_n[0]}]; # DP0_M2C_N

set_property PACKAGE_PIN K11 [get_ports {pci_exp_0_gtx_p[1]}]; # DP1_C2M_P
set_property PACKAGE_PIN K10 [get_ports {pci_exp_0_gtx_n[1]}]; # DP1_C2M_N
set_property PACKAGE_PIN J4 [get_ports {pci_exp_0_grx_p[1]}]; # DP1_M2C_P
set_property PACKAGE_PIN J3 [get_ports {pci_exp_0_grx_n[1]}]; # DP1_M2C_N

set_property PACKAGE_PIN J9 [get_ports {pci_exp_0_gtx_p[2]}]; # DP2_C2M_P
set_property PACKAGE_PIN J8 [get_ports {pci_exp_0_gtx_n[2]}]; # DP2_C2M_N
set_property PACKAGE_PIN H2 [get_ports {pci_exp_0_grx_p[2]}]; # DP2_M2C_P
set_property PACKAGE_PIN H1 [get_ports {pci_exp_0_grx_n[2]}]; # DP2_M2C_N

set_property PACKAGE_PIN H11 [get_ports {pci_exp_0_gtx_p[3]}]; # DP3_C2M_P
set_property PACKAGE_PIN H10 [get_ports {pci_exp_0_gtx_n[3]}]; # DP3_C2M_N
set_property PACKAGE_PIN H6 [get_ports {pci_exp_0_grx_p[3]}]; # DP3_M2C_P
set_property PACKAGE_PIN H5 [get_ports {pci_exp_0_grx_n[3]}]; # DP3_M2C_N

############################
# SSD2 Gigabit transceivers
############################

set_property PACKAGE_PIN G9 [get_ports {pci_exp_1_gtx_p[0]}]; # DP4_C2M_P
set_property PACKAGE_PIN G8 [get_ports {pci_exp_1_gtx_n[0]}]; # DP4_C2M_N
set_property PACKAGE_PIN G4 [get_ports {pci_exp_1_grx_p[0]}]; # DP4_M2C_P
set_property PACKAGE_PIN G3 [get_ports {pci_exp_1_grx_n[0]}]; # DP4_M2C_N

set_property PACKAGE_PIN F11 [get_ports {pci_exp_1_gtx_p[1]}]; # DP5_C2M_P
set_property PACKAGE_PIN F10 [get_ports {pci_exp_1_gtx_n[1]}]; # DP5_C2M_N
set_property PACKAGE_PIN F2 [get_ports {pci_exp_1_grx_p[1]}]; # DP5_M2C_P
set_property PACKAGE_PIN F1 [get_ports {pci_exp_1_grx_n[1]}]; # DP5_M2C_N

set_property PACKAGE_PIN E9 [get_ports {pci_exp_1_gtx_p[2]}]; # DP6_C2M_P
set_property PACKAGE_PIN E8 [get_ports {pci_exp_1_gtx_n[2]}]; # DP6_C2M_N
set_property PACKAGE_PIN F6 [get_ports {pci_exp_1_grx_p[2]}]; # DP6_M2C_P
set_property PACKAGE_PIN F5 [get_ports {pci_exp_1_grx_n[2]}]; # DP6_M2C_N

set_property PACKAGE_PIN D11 [get_ports {pci_exp_1_gtx_p[3]}]; # DP7_C2M_P
set_property PACKAGE_PIN D10 [get_ports {pci_exp_1_gtx_n[3]}]; # DP7_C2M_N
set_property PACKAGE_PIN E4 [get_ports {pci_exp_1_grx_p[3]}]; # DP7_M2C_P
set_property PACKAGE_PIN E3 [get_ports {pci_exp_1_grx_n[3]}]; # DP7_M2C_N


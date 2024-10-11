#----------------------------------------------------------------------------------------
# Constraints for Opsero FPGA Drive FMC Gen4 ref design for VCK190-FMCP1 using 2x SSDs
#----------------------------------------------------------------------------------------

# SSD1 PCI Express reset (perst_0)
set_property PACKAGE_PIN BD23 [get_ports {perst_0[0]}]; # LA00_CC_P
set_property IOSTANDARD LVCMOS15 [get_ports {perst_0[0]}]

# SSD2 PCI Express reset (perst_1)
set_property PACKAGE_PIN AU21 [get_ports {perst_1[0]}]; # LA04_P
set_property IOSTANDARD LVCMOS15 [get_ports {perst_1[0]}]

# SSD1 PE Detect (pedet_0, not connected in the design)
# set_property PACKAGE_PIN BD24 [get_ports {pedet_0[0]}]; # LA00_CC_N
# set_property IOSTANDARD LVCMOS15 [get_ports {pedet_0[0]}]

# SSD2 PE Detect (pedet_1, not connected in the design)
# set_property PACKAGE_PIN AV21 [get_ports {pedet_1[0]}]; # LA04_N
# set_property IOSTANDARD LVCMOS15 [get_ports {pedet_1[0]}]

# Disable signal for 3.3V power supply for SSD2 (disable_ssd2_pwr)
set_property PACKAGE_PIN BC25 [get_ports disable_ssd2_pwr]; # LA07_P
set_property IOSTANDARD LVCMOS15 [get_ports disable_ssd2_pwr]

##############################
# PCIe reference clock 100MHz
##############################

# SSD1 ref clock
set_property PACKAGE_PIN M15 [get_ports {ref_clk_0_clk_p[0]}]; # GBTCLK0_M2C_P
set_property PACKAGE_PIN M14 [get_ports {ref_clk_0_clk_n[0]}]; # GBTCLK0_M2C_N
create_clock -period 10.000 -name ref_clk_0_clk_p -waveform {0.000 5.000} [get_ports ref_clk_0_clk_p]

# SSD2 ref clock
set_property PACKAGE_PIN K15 [get_ports {ref_clk_1_clk_p[0]}]; # GBTCLK1_M2C_P
set_property PACKAGE_PIN K14 [get_ports {ref_clk_1_clk_n[0]}]; # GBTCLK1_M2C_N
create_clock -period 10.000 -name ref_clk_1_clk_p -waveform {0.000 5.000} [get_ports ref_clk_1_clk_p]

############################
# SSD1 Gigabit transceivers
############################

set_property PACKAGE_PIN AB7 [get_ports {pci_exp_0_gtx_p[0]}]; # DP0_C2M_P
set_property PACKAGE_PIN AB6 [get_ports {pci_exp_0_gtx_n[0]}]; # DP0_C2M_N
set_property PACKAGE_PIN AB2 [get_ports {pci_exp_0_grx_p[0]}]; # DP0_M2C_P
set_property PACKAGE_PIN AB1 [get_ports {pci_exp_0_grx_n[0]}]; # DP0_M2C_N

set_property PACKAGE_PIN AA9 [get_ports {pci_exp_0_gtx_p[1]}]; # DP1_C2M_P
set_property PACKAGE_PIN AA8 [get_ports {pci_exp_0_gtx_n[1]}]; # DP1_C2M_N
set_property PACKAGE_PIN AA4 [get_ports {pci_exp_0_grx_p[1]}]; # DP1_M2C_P
set_property PACKAGE_PIN AA3 [get_ports {pci_exp_0_grx_n[1]}]; # DP1_M2C_N

set_property PACKAGE_PIN Y7 [get_ports {pci_exp_0_gtx_p[2]}]; # DP2_C2M_P
set_property PACKAGE_PIN Y6 [get_ports {pci_exp_0_gtx_n[2]}]; # DP2_C2M_N
set_property PACKAGE_PIN Y2 [get_ports {pci_exp_0_grx_p[2]}]; # DP2_M2C_P
set_property PACKAGE_PIN Y1 [get_ports {pci_exp_0_grx_n[2]}]; # DP2_M2C_N

set_property PACKAGE_PIN W9 [get_ports {pci_exp_0_gtx_p[3]}]; # DP3_C2M_P
set_property PACKAGE_PIN W8 [get_ports {pci_exp_0_gtx_n[3]}]; # DP3_C2M_N
set_property PACKAGE_PIN W4 [get_ports {pci_exp_0_grx_p[3]}]; # DP3_M2C_P
set_property PACKAGE_PIN W3 [get_ports {pci_exp_0_grx_n[3]}]; # DP3_M2C_N

############################
# SSD2 Gigabit transceivers
############################

set_property PACKAGE_PIN V7 [get_ports {pci_exp_1_gtx_p[0]}]; # DP4_C2M_P
set_property PACKAGE_PIN V6 [get_ports {pci_exp_1_gtx_n[0]}]; # DP4_C2M_N
set_property PACKAGE_PIN V2 [get_ports {pci_exp_1_grx_p[0]}]; # DP4_M2C_P
set_property PACKAGE_PIN V1 [get_ports {pci_exp_1_grx_n[0]}]; # DP4_M2C_N

set_property PACKAGE_PIN U9 [get_ports {pci_exp_1_gtx_p[1]}]; # DP5_C2M_P
set_property PACKAGE_PIN U8 [get_ports {pci_exp_1_gtx_n[1]}]; # DP5_C2M_N
set_property PACKAGE_PIN U4 [get_ports {pci_exp_1_grx_p[1]}]; # DP5_M2C_P
set_property PACKAGE_PIN U3 [get_ports {pci_exp_1_grx_n[1]}]; # DP5_M2C_N

set_property PACKAGE_PIN T7 [get_ports {pci_exp_1_gtx_p[2]}]; # DP6_C2M_P
set_property PACKAGE_PIN T6 [get_ports {pci_exp_1_gtx_n[2]}]; # DP6_C2M_N
set_property PACKAGE_PIN T2 [get_ports {pci_exp_1_grx_p[2]}]; # DP6_M2C_P
set_property PACKAGE_PIN T1 [get_ports {pci_exp_1_grx_n[2]}]; # DP6_M2C_N

set_property PACKAGE_PIN R9 [get_ports {pci_exp_1_gtx_p[3]}]; # DP7_C2M_P
set_property PACKAGE_PIN R8 [get_ports {pci_exp_1_gtx_n[3]}]; # DP7_C2M_N
set_property PACKAGE_PIN R4 [get_ports {pci_exp_1_grx_p[3]}]; # DP7_M2C_P
set_property PACKAGE_PIN R3 [get_ports {pci_exp_1_grx_n[3]}]; # DP7_M2C_N


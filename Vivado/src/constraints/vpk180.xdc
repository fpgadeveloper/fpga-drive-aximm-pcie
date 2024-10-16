#----------------------------------------------------------------------------------------
# Constraints for Opsero FPGA Drive FMC Gen4 ref design for VPK180 using 1x SSD
#----------------------------------------------------------------------------------------

# SSD1 PCI Express reset (perst_0)
set_property PACKAGE_PIN BV49 [get_ports {perst_0[0]}]; # LA00_CC_P
set_property IOSTANDARD LVCMOS15 [get_ports {perst_0[0]}]

# SSD1 PE Detect (pedet_0, not connected in the design)
# set_property PACKAGE_PIN BV50 [get_ports {pedet_0[0]}]; # LA00_CC_N
# set_property IOSTANDARD LVCMOS18 [get_ports {pedet_0[0]}]

# Disable signal for 3.3V power supply for SSD2 (disable_ssd2_pwr)
set_property PACKAGE_PIN CB49 [get_ports disable_ssd2_pwr]; # LA07_P
set_property IOSTANDARD LVCMOS15 [get_ports disable_ssd2_pwr]

##############################
# PCIe reference clock 100MHz
##############################

# SSD1 ref clock
set_property PACKAGE_PIN AT48 [get_ports {ref_clk_0_clk_p[0]}]; # GBTCLK0_M2C_P
set_property PACKAGE_PIN AT49 [get_ports {ref_clk_0_clk_n[0]}]; # GBTCLK0_M2C_N
create_clock -period 10.000 -name ref_clk_0_clk_p -waveform {0.000 5.000} [get_ports ref_clk_0_clk_p]

############################
# SSD1 Gigabit transceivers
############################

set_property PACKAGE_PIN CD54 [get_ports {pci_exp_0_gtx_p[0]}]; # DP0_C2M_P
set_property PACKAGE_PIN CD55 [get_ports {pci_exp_0_gtx_n[0]}]; # DP0_C2M_N
set_property PACKAGE_PIN CB61 [get_ports {pci_exp_0_grx_p[0]}]; # DP0_M2C_P
set_property PACKAGE_PIN CB62 [get_ports {pci_exp_0_grx_n[0]}]; # DP0_M2C_N

set_property PACKAGE_PIN CD58 [get_ports {pci_exp_0_gtx_p[1]}]; # DP1_C2M_P
set_property PACKAGE_PIN CD59 [get_ports {pci_exp_0_gtx_n[1]}]; # DP1_C2M_N
set_property PACKAGE_PIN BY61 [get_ports {pci_exp_0_grx_p[1]}]; # DP1_M2C_P
set_property PACKAGE_PIN BY62 [get_ports {pci_exp_0_grx_n[1]}]; # DP1_M2C_N

set_property PACKAGE_PIN CC56 [get_ports {pci_exp_0_gtx_p[2]}]; # DP2_C2M_P
set_property PACKAGE_PIN CC57 [get_ports {pci_exp_0_gtx_n[2]}]; # DP2_C2M_N
set_property PACKAGE_PIN BW63 [get_ports {pci_exp_0_grx_p[2]}]; # DP2_M2C_P
set_property PACKAGE_PIN BW64 [get_ports {pci_exp_0_grx_n[2]}]; # DP2_M2C_N

set_property PACKAGE_PIN CB58 [get_ports {pci_exp_0_gtx_p[3]}]; # DP3_C2M_P
set_property PACKAGE_PIN CB59 [get_ports {pci_exp_0_gtx_n[3]}]; # DP3_C2M_N
set_property PACKAGE_PIN BV61 [get_ports {pci_exp_0_grx_p[3]}]; # DP3_M2C_P
set_property PACKAGE_PIN BV62 [get_ports {pci_exp_0_grx_n[3]}]; # DP3_M2C_N


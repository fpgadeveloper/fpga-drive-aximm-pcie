#----------------------------------------------------------------------------------------
# Constraints for Opsero FPGA Drive FMC Gen4 ref design for ZC706-HPC using 1x SSD
#----------------------------------------------------------------------------------------

# SSD1 PCI Express reset (perst_0)
set_property PACKAGE_PIN AF20 [get_ports {perst_0[0]}]; # LA00_CC_P
set_property IOSTANDARD LVCMOS18 [get_ports {perst_0[0]}]

# SSD1 PE Detect (pedet_0, not connected in the design)
# set_property PACKAGE_PIN AG20 [get_ports {pedet_0[0]}]; # LA00_CC_N
# set_property IOSTANDARD LVCMOS18 [get_ports {pedet_0[0]}]

# Disable signal for 3.3V power supply for SSD2 (disable_ssd2_pwr)
set_property PACKAGE_PIN AJ23 [get_ports disable_ssd2_pwr]; # LA07_P
set_property IOSTANDARD LVCMOS18 [get_ports disable_ssd2_pwr]

##############################
# PCIe reference clock 100MHz
##############################

# SSD1 ref clock
set_property PACKAGE_PIN AD10 [get_ports {ref_clk_0_clk_p[0]}]; # GBTCLK0_M2C_P
set_property PACKAGE_PIN AD9 [get_ports {ref_clk_0_clk_n[0]}]; # GBTCLK0_M2C_N
create_clock -period 10.000 -name ref_clk_0_clk_p -waveform {0.000 5.000} [get_ports ref_clk_0_clk_p]

############################
# SSD1 Gigabit transceivers
############################

set_property PACKAGE_PIN AK10 [get_ports {pcie_7x_mgt_0_txp[0]}]; # DP0_C2M_P
set_property PACKAGE_PIN AK9 [get_ports {pcie_7x_mgt_0_txn[0]}]; # DP0_C2M_N
set_property PACKAGE_PIN AH10 [get_ports {pcie_7x_mgt_0_rxp[0]}]; # DP0_M2C_P
set_property PACKAGE_PIN AH9 [get_ports {pcie_7x_mgt_0_rxn[0]}]; # DP0_M2C_N

set_property PACKAGE_PIN AK6 [get_ports {pcie_7x_mgt_0_txp[1]}]; # DP1_C2M_P
set_property PACKAGE_PIN AK5 [get_ports {pcie_7x_mgt_0_txn[1]}]; # DP1_C2M_N
set_property PACKAGE_PIN AJ8 [get_ports {pcie_7x_mgt_0_rxp[1]}]; # DP1_M2C_P
set_property PACKAGE_PIN AJ7 [get_ports {pcie_7x_mgt_0_rxn[1]}]; # DP1_M2C_N

set_property PACKAGE_PIN AJ4 [get_ports {pcie_7x_mgt_0_txp[2]}]; # DP2_C2M_P
set_property PACKAGE_PIN AJ3 [get_ports {pcie_7x_mgt_0_txn[2]}]; # DP2_C2M_N
set_property PACKAGE_PIN AG8 [get_ports {pcie_7x_mgt_0_rxp[2]}]; # DP2_M2C_P
set_property PACKAGE_PIN AG7 [get_ports {pcie_7x_mgt_0_rxn[2]}]; # DP2_M2C_N

set_property PACKAGE_PIN AK2 [get_ports {pcie_7x_mgt_0_txp[3]}]; # DP3_C2M_P
set_property PACKAGE_PIN AK1 [get_ports {pcie_7x_mgt_0_txn[3]}]; # DP3_C2M_N
set_property PACKAGE_PIN AE8 [get_ports {pcie_7x_mgt_0_rxp[3]}]; # DP3_M2C_P
set_property PACKAGE_PIN AE7 [get_ports {pcie_7x_mgt_0_rxn[3]}]; # DP3_M2C_N

# GPIO LEDs
set_property PACKAGE_PIN A17 [get_ports mmcm_lock]
set_property IOSTANDARD LVCMOS18 [get_ports mmcm_lock]


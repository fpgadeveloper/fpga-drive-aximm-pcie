#----------------------------------------------------------------------------------------
# Constraints for Opsero FPGA Drive FMC Gen4 ref design for AUBoard using 1x SSD
#----------------------------------------------------------------------------------------

# SSD1 PCI Express reset (perst_0)
set_property PACKAGE_PIN F24 [get_ports {perst_0[0]}]; # LA00_CC_P
set_property IOSTANDARD LVCMOS18 [get_ports {perst_0[0]}]

# SSD1 PE Detect (pedet_0, not connected in the design)
# set_property PACKAGE_PIN F25 [get_ports {pedet_0[0]}]; # LA00_CC_N
# set_property IOSTANDARD LVCMOS18 [get_ports {pedet_0[0]}]

# Disable signal for 3.3V power supply for SSD2 (disable_ssd2_pwr)
set_property PACKAGE_PIN J12 [get_ports disable_ssd2_pwr]; # LA07_P
set_property IOSTANDARD LVCMOS18 [get_ports disable_ssd2_pwr]

##############################
# PCIe reference clock 100MHz
##############################

# SSD1 ref clock
set_property PACKAGE_PIN V7 [get_ports {ref_clk_0_clk_p[0]}]; # GBTCLK0_M2C_P
set_property PACKAGE_PIN V6 [get_ports {ref_clk_0_clk_n[0]}]; # GBTCLK0_M2C_N
create_clock -period 10.000 -name ref_clk_0_clk_p -waveform {0.000 5.000} [get_ports ref_clk_0_clk_p]

############################
# SSD1 Gigabit transceivers
############################

set_property LOC GTHE4_CHANNEL_X0Y4 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.GTHE4_CHANNEL && NAME =~ "*axi_pcie_0*channel_inst[0]*" }]
set_property LOC GTHE4_CHANNEL_X0Y5 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.GTHE4_CHANNEL && NAME =~ "*axi_pcie_0*channel_inst[1]*" }]
set_property LOC GTHE4_CHANNEL_X0Y6 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.GTHE4_CHANNEL && NAME =~ "*axi_pcie_0*channel_inst[2]*" }]
set_property LOC GTHE4_CHANNEL_X0Y7 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.GTHE4_CHANNEL && NAME =~ "*axi_pcie_0*channel_inst[3]*" }]

############################
# SSD1 PCIe block
############################

set_property LOC PCIE4CE4_X0Y0 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.PCIE.* && NAME =~ "*axi_pcie_0*" }]

# GPIO LEDs
set_property PACKAGE_PIN A10 [get_ports init_calib_complete]
set_property IOSTANDARD LVCMOS33 [get_ports init_calib_complete]
set_property PACKAGE_PIN B10 [get_ports user_link_up_0]
set_property IOSTANDARD LVCMOS33 [get_ports user_link_up_0]
#set_property PACKAGE_PIN B11 [get_ports user_led_3]
#set_property IOSTANDARD LVCMOS33 [get_ports user_led_3]
#set_property PACKAGE_PIN C11 [get_ports user_led_4]
#set_property IOSTANDARD LVCMOS33 [get_ports user_led_4]

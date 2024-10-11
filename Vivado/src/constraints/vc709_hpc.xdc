#----------------------------------------------------------------------------------------
# Constraints for Opsero FPGA Drive FMC Gen4 ref design for VC709 using 1x SSD
#----------------------------------------------------------------------------------------

# SSD1 PCI Express reset (perst_0)
set_property PACKAGE_PIN K39 [get_ports {perst_0[0]}]; # LA00_CC_P
set_property IOSTANDARD LVCMOS18 [get_ports {perst_0[0]}]

# SSD1 PE Detect (pedet_0, not connected in the design)
# set_property PACKAGE_PIN K40 [get_ports {pedet_0[0]}]; # LA00_CC_N
# set_property IOSTANDARD LVCMOS18 [get_ports {pedet_0[0]}]

# Disable signal for 3.3V power supply for SSD2 (disable_ssd2_pwr)
set_property PACKAGE_PIN G41 [get_ports disable_ssd2_pwr]; # LA07_P
set_property IOSTANDARD LVCMOS18 [get_ports disable_ssd2_pwr]

##############################
# PCIe reference clock 100MHz
##############################

# SSD1 ref clock
set_property PACKAGE_PIN G10 [get_ports {ref_clk_0_clk_p[0]}]; # GBTCLK0_M2C_P
set_property PACKAGE_PIN G9 [get_ports {ref_clk_0_clk_n[0]}]; # GBTCLK0_M2C_N
create_clock -period 10.000 -name ref_clk_0_clk_p -waveform {0.000 5.000} [get_ports ref_clk_0_clk_p]

############################
# SSD1 Gigabit transceivers
############################

set_property LOC GTHE2_CHANNEL_X1Y36 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ IO.GT.GTHE2_CHANNEL && NAME =~ "*axi_pcie_0*pipe_lane[0]*" }]
set_property LOC GTHE2_CHANNEL_X1Y37 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ IO.GT.GTHE2_CHANNEL && NAME =~ "*axi_pcie_0*pipe_lane[1]*" }]
set_property LOC GTHE2_CHANNEL_X1Y38 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ IO.GT.GTHE2_CHANNEL && NAME =~ "*axi_pcie_0*pipe_lane[2]*" }]
set_property LOC GTHE2_CHANNEL_X1Y39 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ IO.GT.GTHE2_CHANNEL && NAME =~ "*axi_pcie_0*pipe_lane[3]*" }]

############################
# SSD1 PCIe block
############################

set_property LOC PCIE3_X0Y2 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ HARD_IP.pcie.* && NAME =~ "*axi_pcie_0*" }]

# GPIO LEDs
set_property PACKAGE_PIN AM39 [get_ports mmcm_lock]
set_property IOSTANDARD LVCMOS18 [get_ports mmcm_lock]
set_property PACKAGE_PIN AN39 [get_ports init_calib_complete]
set_property IOSTANDARD LVCMOS18 [get_ports init_calib_complete]
set_property PACKAGE_PIN AR37 [get_ports user_link_up_0]
set_property IOSTANDARD LVCMOS18 [get_ports user_link_up_0]
#set_property PACKAGE_PIN AT37 [get_ports user_led_3]
#set_property IOSTANDARD LVCMOS18 [get_ports user_led_3]

# Configuration via BPI flash for VC709
set_property BITSTREAM.CONFIG.BPI_SYNC_MODE DISABLE [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN DISABLE [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN Pullup [current_design]
set_property CONFIG_MODE BPI16 [current_design]
set_property CFGBVS GND [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]


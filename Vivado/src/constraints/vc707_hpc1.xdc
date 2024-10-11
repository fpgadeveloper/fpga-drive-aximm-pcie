#----------------------------------------------------------------------------------------
# Constraints for Opsero FPGA Drive FMC Gen4 ref design for VC707-HPC1 using 1x SSD
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
set_property PACKAGE_PIN A10 [get_ports {ref_clk_0_clk_p[0]}]; # GBTCLK0_M2C_P
set_property PACKAGE_PIN A9 [get_ports {ref_clk_0_clk_n[0]}]; # GBTCLK0_M2C_N
create_clock -period 10.000 -name ref_clk_0_clk_p -waveform {0.000 5.000} [get_ports ref_clk_0_clk_p]

############################
# SSD1 Gigabit transceivers
############################

set_property LOC GTXE2_CHANNEL_X1Y24 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ IO.GT.GTXE2_CHANNEL && NAME =~ "*axi_pcie_0*pipe_lane[0]*" }]
set_property LOC GTXE2_CHANNEL_X1Y25 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ IO.GT.GTXE2_CHANNEL && NAME =~ "*axi_pcie_0*pipe_lane[1]*" }]
set_property LOC GTXE2_CHANNEL_X1Y26 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ IO.GT.GTXE2_CHANNEL && NAME =~ "*axi_pcie_0*pipe_lane[2]*" }]
set_property LOC GTXE2_CHANNEL_X1Y27 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ IO.GT.GTXE2_CHANNEL && NAME =~ "*axi_pcie_0*pipe_lane[3]*" }]

############################
# SSD1 PCIe block
############################

set_property LOC PCIE_X1Y1 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ HARD_IP.pcie.* && NAME =~ "*axi_pcie_0*" }]

# System reset (CPU_RESET)
set_property PACKAGE_PIN AV40 [get_ports reset]
set_property IOSTANDARD LVCMOS18 [get_ports reset]

# GPIO LEDs
set_property PACKAGE_PIN AM39 [get_ports mmcm_lock]
set_property IOSTANDARD LVCMOS18 [get_ports mmcm_lock]
set_property PACKAGE_PIN AN39 [get_ports init_calib_complete]
set_property IOSTANDARD LVCMOS18 [get_ports init_calib_complete]
set_property PACKAGE_PIN AR37 [get_ports user_link_up_0]
set_property IOSTANDARD LVCMOS18 [get_ports user_link_up_0]
#set_property PACKAGE_PIN AT37 [get_ports gpio_led_3_ls]
#set_property IOSTANDARD LVCMOS18 [get_ports gpio_led_3_ls]

# Configuration via BPI flash for VC707
set_property BITSTREAM.CONFIG.BPI_SYNC_MODE DISABLE [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN DISABLE [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN Pullup [current_design]
set_property CONFIG_MODE BPI16 [current_design]
set_property CFGBVS GND [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]


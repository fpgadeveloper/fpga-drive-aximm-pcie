#----------------------------------------------------------------------------------------
# Constraints for Opsero FPGA Drive FMC Gen4 ref design for VCU118-FMCP using 2x SSDs
#----------------------------------------------------------------------------------------

# SSD1 PCI Express reset (perst_0)
set_property PACKAGE_PIN AL35 [get_ports {perst_0[0]}]; # LA00_CC_P
set_property IOSTANDARD LVCMOS18 [get_ports {perst_0[0]}]

# SSD2 PCI Express reset (perst_1)
set_property PACKAGE_PIN AR37 [get_ports {perst_1[0]}]; # LA04_P
set_property IOSTANDARD LVCMOS18 [get_ports {perst_1[0]}]

# SSD1 PE Detect (pedet_0, not connected in the design)
# set_property PACKAGE_PIN AL36 [get_ports {pedet_0[0]}]; # LA00_CC_N
# set_property IOSTANDARD LVCMOS18 [get_ports {pedet_0[0]}]

# SSD2 PE Detect (pedet_1, not connected in the design)
# set_property PACKAGE_PIN AT37 [get_ports {pedet_1[0]}]; # LA04_N
# set_property IOSTANDARD LVCMOS18 [get_ports {pedet_1[0]}]

# Disable signal for 3.3V power supply for SSD2 (disable_ssd2_pwr)
set_property PACKAGE_PIN AP36 [get_ports disable_ssd2_pwr]; # LA07_P
set_property IOSTANDARD LVCMOS18 [get_ports disable_ssd2_pwr]

##############################
# PCIe reference clock 100MHz
##############################

# SSD1 ref clock
set_property PACKAGE_PIN AK38 [get_ports {ref_clk_0_clk_p[0]}]; # GBTCLK0_M2C_P
set_property PACKAGE_PIN AK39 [get_ports {ref_clk_0_clk_n[0]}]; # GBTCLK0_M2C_N
create_clock -period 10.000 -name ref_clk_0_clk_p -waveform {0.000 5.000} [get_ports ref_clk_0_clk_p]

# SSD2 ref clock
set_property PACKAGE_PIN T38 [get_ports {ref_clk_1_clk_p[0]}]; # GBTCLK1_M2C_P
set_property PACKAGE_PIN T39 [get_ports {ref_clk_1_clk_n[0]}]; # GBTCLK1_M2C_N
create_clock -period 10.000 -name ref_clk_1_clk_p -waveform {0.000 5.000} [get_ports ref_clk_1_clk_p]

############################
# SSD1 Gigabit transceivers
############################

set_property LOC GTYE4_CHANNEL_X0Y8 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.GTYE4_CHANNEL && NAME =~ "*axi_pcie_0*channel_inst[0]*" }]
set_property LOC GTYE4_CHANNEL_X0Y9 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.GTYE4_CHANNEL && NAME =~ "*axi_pcie_0*channel_inst[1]*" }]
set_property LOC GTYE4_CHANNEL_X0Y10 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.GTYE4_CHANNEL && NAME =~ "*axi_pcie_0*channel_inst[2]*" }]
set_property LOC GTYE4_CHANNEL_X0Y11 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.GTYE4_CHANNEL && NAME =~ "*axi_pcie_0*channel_inst[3]*" }]

############################
# SSD2 Gigabit transceivers
############################

set_property LOC GTYE4_CHANNEL_X0Y28 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.GTYE4_CHANNEL && NAME =~ "*axi_pcie_1*channel_inst[0]*" }]
set_property LOC GTYE4_CHANNEL_X0Y29 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.GTYE4_CHANNEL && NAME =~ "*axi_pcie_1*channel_inst[1]*" }]
set_property LOC GTYE4_CHANNEL_X0Y30 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.GTYE4_CHANNEL && NAME =~ "*axi_pcie_1*channel_inst[2]*" }]
set_property LOC GTYE4_CHANNEL_X0Y31 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.GTYE4_CHANNEL && NAME =~ "*axi_pcie_1*channel_inst[3]*" }]

############################
# SSD1 PCIe block
############################

set_property LOC PCIE40E4_X0Y1 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.PCIE.* && NAME =~ "*axi_pcie_0*" }]

############################
# SSD2 PCIe block
############################

set_property LOC PCIE40E4_X0Y3 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.PCIE.* && NAME =~ "*axi_pcie_1*" }]

# GPIO LEDs
set_property PACKAGE_PIN AT32 [get_ports init_calib_complete]
set_property IOSTANDARD LVCMOS12 [get_ports init_calib_complete]
set_property PACKAGE_PIN AV34 [get_ports user_link_up_0]
set_property IOSTANDARD LVCMOS12 [get_ports user_link_up_0]
#set_property PACKAGE_PIN AY30 [get_ports user_link_up_1]
#set_property IOSTANDARD LVCMOS12 [get_ports user_link_up_1]
#set_property PACKAGE_PIN BB32 [get_ports gpio_led_3]
#set_property IOSTANDARD LVCMOS12 [get_ports gpio_led_3]
#set_property PACKAGE_PIN BF32 [get_ports gpio_led_4]
#set_property IOSTANDARD LVCMOS12 [get_ports gpio_led_4]
#set_property PACKAGE_PIN AU37 [get_ports gpio_led_5]
#set_property IOSTANDARD LVCMOS12 [get_ports gpio_led_5]
#set_property PACKAGE_PIN AV36 [get_ports gpio_led_6]
#set_property IOSTANDARD LVCMOS12 [get_ports gpio_led_6]
#set_property PACKAGE_PIN BA37 [get_ports gpio_led_7]
#set_property IOSTANDARD LVCMOS12 [get_ports gpio_led_7]

# Configuration via Quad SPI flash for VCU118
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property CFGBVS GND [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

# Timing constraints taken from the BSP
set_property CLOCK_DELAY_GROUP ddr_clk_grp [get_nets -hier -filter {name =~ */addn_ui_clkout1}]
set_property CLOCK_DELAY_GROUP ddr_clk_grp [get_nets -hier -filter {name =~ */c0_ddr4_ui_clk}]


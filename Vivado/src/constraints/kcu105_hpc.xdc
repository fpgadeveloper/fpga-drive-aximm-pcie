#----------------------------------------------------------------------------------------
# Constraints for Opsero FPGA Drive FMC Gen4 ref design for KCU105-HPC using 2x SSDs
#----------------------------------------------------------------------------------------

# SSD1 PCI Express reset (perst_0)
set_property PACKAGE_PIN H11 [get_ports {perst_0[0]}]; # LA00_CC_P
set_property IOSTANDARD LVCMOS18 [get_ports {perst_0[0]}]

# SSD2 PCI Express reset (perst_1)
set_property PACKAGE_PIN L12 [get_ports {perst_1[0]}]; # LA04_P
set_property IOSTANDARD LVCMOS18 [get_ports {perst_1[0]}]

# SSD1 PE Detect (pedet_0, not connected in the design)
# set_property PACKAGE_PIN G11 [get_ports {pedet_0[0]}]; # LA00_CC_N
# set_property IOSTANDARD LVCMOS18 [get_ports {pedet_0[0]}]

# SSD2 PE Detect (pedet_1, not connected in the design)
# set_property PACKAGE_PIN K12 [get_ports {pedet_1[0]}]; # LA04_N
# set_property IOSTANDARD LVCMOS18 [get_ports {pedet_1[0]}]

# Disable signal for 3.3V power supply for SSD2 (disable_ssd2_pwr)
set_property PACKAGE_PIN F8 [get_ports disable_ssd2_pwr]; # LA07_P
set_property IOSTANDARD LVCMOS18 [get_ports disable_ssd2_pwr]

##############################
# PCIe reference clock 100MHz
##############################

# SSD1 ref clock
set_property PACKAGE_PIN K6 [get_ports {ref_clk_0_clk_p[0]}]; # GBTCLK0_M2C_P
set_property PACKAGE_PIN K5 [get_ports {ref_clk_0_clk_n[0]}]; # GBTCLK0_M2C_N
create_clock -period 10.000 -name ref_clk_0_clk_p -waveform {0.000 5.000} [get_ports ref_clk_0_clk_p]

# SSD2 ref clock
set_property PACKAGE_PIN H6 [get_ports {ref_clk_1_clk_p[0]}]; # GBTCLK1_M2C_P
set_property PACKAGE_PIN H5 [get_ports {ref_clk_1_clk_n[0]}]; # GBTCLK1_M2C_N
create_clock -period 10.000 -name ref_clk_1_clk_p -waveform {0.000 5.000} [get_ports ref_clk_1_clk_p]

############################
# SSD1 Gigabit transceivers
############################

set_property LOC GTHE3_CHANNEL_X0Y16 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.GTHE3_CHANNEL && NAME =~ "*axi_pcie_0*channel_inst[0]*" }]
set_property LOC GTHE3_CHANNEL_X0Y17 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.GTHE3_CHANNEL && NAME =~ "*axi_pcie_0*channel_inst[1]*" }]
set_property LOC GTHE3_CHANNEL_X0Y18 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.GTHE3_CHANNEL && NAME =~ "*axi_pcie_0*channel_inst[2]*" }]
set_property LOC GTHE3_CHANNEL_X0Y19 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.GTHE3_CHANNEL && NAME =~ "*axi_pcie_0*channel_inst[3]*" }]

############################
# SSD2 Gigabit transceivers
############################

# Reset the LOC on all of the GTs
set_property LOC "" [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.GTHE3_CHANNEL && NAME =~ "*axi_pcie_1*" }]

set_property LOC GTHE3_CHANNEL_X0Y12 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.GTHE3_CHANNEL && NAME =~ "*axi_pcie_1*channel_inst[0]*" }]
set_property LOC GTHE3_CHANNEL_X0Y14 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.GTHE3_CHANNEL && NAME =~ "*axi_pcie_1*channel_inst[1]*" }]
set_property LOC GTHE3_CHANNEL_X0Y13 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.GTHE3_CHANNEL && NAME =~ "*axi_pcie_1*channel_inst[2]*" }]
set_property LOC GTHE3_CHANNEL_X0Y15 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.GT.GTHE3_CHANNEL && NAME =~ "*axi_pcie_1*channel_inst[3]*" }]

############################
# SSD1 PCIe block
############################

set_property LOC PCIE_3_1_X0Y2 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.PCIE.* && NAME =~ "*axi_pcie_0*" }]

############################
# SSD2 PCIe block
############################

set_property LOC PCIE_3_1_X0Y1 [get_cells -hierarchical -filter { PRIMITIVE_TYPE =~ ADVANCED.PCIE.* && NAME =~ "*axi_pcie_1*" }]

# GPIO LEDs
set_property PACKAGE_PIN AP8 [get_ports init_calib_complete]
set_property IOSTANDARD LVCMOS18 [get_ports init_calib_complete]
set_property PACKAGE_PIN H23 [get_ports user_link_up_0]
set_property IOSTANDARD LVCMOS18 [get_ports user_link_up_0]
set_property PACKAGE_PIN P20 [get_ports user_link_up_1]
set_property IOSTANDARD LVCMOS18 [get_ports user_link_up_1]

# Configuration via Dual Quad SPI settings for KCU105
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]
set_property CFGBVS GND [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE YES [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]


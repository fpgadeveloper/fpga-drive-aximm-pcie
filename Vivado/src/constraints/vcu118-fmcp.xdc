#GPIO LEDs
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

# PCI Express reset (perst) - IOSTANDARD determined by VADJ which is fixed to 1.8V on VCU118
set_property PACKAGE_PIN AL35 [get_ports {perst_0[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {perst_0[0]}]

# PEDET - AL36 - IOSTANDARD determined by VADJ which is fixed to 1.8V on VCU118

# PCI Express reference clock 100MHz
# IOSTANDARD for GT reference clock does not need to be specified
set_property PACKAGE_PIN AK38 [get_ports {ref_clk_0_clk_p[0]}]
set_property PACKAGE_PIN AK39 [get_ports {ref_clk_0_clk_n[0]}]
create_clock -period 10.000 -name ref_clk_0_clk_p -waveform {0.000 5.000} [get_ports ref_clk_0_clk_p]

# MGT locations (SSD1: Bank 121 X0Y8-X0Y11, SSD2: Bank 126 X0Y28-X0Y31)
set_property LOC GTYE4_CHANNEL_X0Y8 [get_cells -hier -filter {NAME =~ *_i/axi_pcie_0/*/gtye4_channel_gen.gen_gtye4_channel_inst[0].GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y9 [get_cells -hier -filter {NAME =~ *_i/axi_pcie_0/*/gtye4_channel_gen.gen_gtye4_channel_inst[1].GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y10 [get_cells -hier -filter {NAME =~ *_i/axi_pcie_0/*/gtye4_channel_gen.gen_gtye4_channel_inst[2].GTYE4_CHANNEL_PRIM_INST}]
set_property LOC GTYE4_CHANNEL_X0Y11 [get_cells -hier -filter {NAME =~ *_i/axi_pcie_0/*/gtye4_channel_gen.gen_gtye4_channel_inst[3].GTYE4_CHANNEL_PRIM_INST}]

# VCU118 FMCP transceivers for SSD1 are best aligned with PCIE_X0Y1
set_property LOC PCIE40E4_X0Y1 [get_cells -hier -filter {NAME =~ *_i/axi_pcie_0/*/pcie_4_0_e4_inst}]

# Configuration via Quad SPI flash for VCU118
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property CLOCK_DELAY_GROUP ddr_clk_grp [get_nets -hier -filter {name =~ */addn_ui_clkout1}]
set_property CLOCK_DELAY_GROUP ddr_clk_grp [get_nets -hier -filter {name =~ */c0_ddr4_ui_clk}]

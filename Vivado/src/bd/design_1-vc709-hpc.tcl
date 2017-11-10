################################################################
# Block design build script for VC709 HPC FMC Connector
################################################################

# CHECKING IF PROJECT EXISTS
if { [get_projects -quiet] eq "" } {
   puts "ERROR: Please open or create a project!"
   return 1
}

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

create_bd_design $design_name

current_bd_design $design_name

set parentCell [get_bd_cells /]

# Get object for parentCell
set parentObj [get_bd_cells $parentCell]
if { $parentObj == "" } {
   puts "ERROR: Unable to find parent cell <$parentCell>!"
   return
}

# Make sure parentObj is hier blk
set parentType [get_property TYPE $parentObj]
if { $parentType ne "hier" } {
   puts "ERROR: Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."
   return
}

# Save current instance; Restore later
set oldCurInst [current_bd_instance .]

# Set parent object as current
current_bd_instance $parentObj

# Add the Memory controller (MIG) for the DDR3
create_bd_cell -type ip -vlnv xilinx.com:ip:mig_7series mig_7series_0
apply_bd_automation -rule xilinx.com:bd_rule:mig_7series -config {Board_Interface "ddr3_sdram_socket_j1" }  [get_bd_cells mig_7series_0]
apply_bd_automation -rule xilinx.com:bd_rule:board -config {Board_Interface "reset ( FPGA Reset ) " }  [get_bd_pins mig_7series_0/sys_rst]

# Create ports
set mmcm_lock [ create_bd_port -dir O mmcm_lock ]
set init_calib_complete [ create_bd_port -dir O init_calib_complete ]

# Add the MicroBlaze
create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze microblaze_0
apply_bd_automation -rule xilinx.com:bd_rule:microblaze -config {local_mem "128KB" \
ecc "None" \
cache "16KB" \
debug_module "Debug Only" \
axi_periph "Enabled" \
axi_intc "1" \
clk "/mig_7series_0/ui_addn_clk_0 (100 MHz)" }  [get_bd_cells microblaze_0]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Cached)" intc_ip "Auto" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins mig_7series_0/S_AXI]
apply_bd_automation -rule xilinx.com:bd_rule:board -config {Board_Interface "reset ( FPGA Reset ) " }  [get_bd_pins rst_mig_7series_0_100M/ext_reset_in]

# Configure Microblaze for Linux
set_property -dict [list CONFIG.G_TEMPLATE_LIST {4} \
CONFIG.G_USE_EXCEPTIONS {1} \
CONFIG.C_USE_MSR_INSTR {1} \
CONFIG.C_USE_PCMP_INSTR {1} \
CONFIG.C_USE_BARREL {1} \
CONFIG.C_USE_DIV {1} \
CONFIG.C_USE_HW_MUL {2} \
CONFIG.C_UNALIGNED_EXCEPTIONS {1} \
CONFIG.C_ILL_OPCODE_EXCEPTION {1} \
CONFIG.C_M_AXI_I_BUS_EXCEPTION {1} \
CONFIG.C_M_AXI_D_BUS_EXCEPTION {1} \
CONFIG.C_DIV_ZERO_EXCEPTION {1} \
CONFIG.C_PVR {2} \
CONFIG.C_OPCODE_0x0_ILLEGAL {1} \
CONFIG.C_ICACHE_LINE_LEN {8} \
CONFIG.C_ICACHE_VICTIMS {8} \
CONFIG.C_ICACHE_STREAMS {1} \
CONFIG.C_DCACHE_VICTIMS {8} \
CONFIG.C_USE_MMU {3} \
CONFIG.C_MMU_ZONES {2}] [get_bd_cells microblaze_0]

# Add the main IPs
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uart16550 axi_uart16550_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_timer axi_timer_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_pcie3 axi_pcie3_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_emc axi_emc_0

# Use Automation features
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" Clk "Auto" }  [get_bd_intf_pins axi_uart16550_0/S_AXI]
apply_bd_automation -rule xilinx.com:bd_rule:board -config {Board_Interface "rs232_uart ( UART ) " }  [get_bd_intf_pins axi_uart16550_0/UART]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" Clk "Auto" }  [get_bd_intf_pins axi_timer_0/S_AXI]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" intc_ip "/microblaze_0_axi_periph" Clk_xbar "/axi_pcie3_0/axi_aclk (62 MHz)" Clk_master "/axi_pcie3_0/axi_aclk (62 MHz)" Clk_slave "/axi_pcie3_0/axi_aclk (62 MHz)" }  [get_bd_intf_pins axi_pcie3_0/S_AXI_CTL]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Slave "/mig_7series_0/S_AXI" intc_ip "/axi_smc" Clk_xbar "/axi_pcie3_0/axi_aclk (62 MHz)" Clk_master "/axi_pcie3_0/axi_aclk (62 MHz)" Clk_slave "/axi_pcie3_0/axi_aclk (62 MHz)" }  [get_bd_intf_pins axi_pcie3_0/M_AXI]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" intc_ip "/microblaze_0_axi_periph" Clk_xbar "/axi_pcie3_0/axi_aclk (62 MHz)" Clk_master "/axi_pcie3_0/axi_aclk (62 MHz)" Clk_slave "/axi_pcie3_0/axi_aclk (62 MHz)" }  [get_bd_intf_pins axi_pcie3_0/S_AXI]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Cached)" intc_ip "Auto" Clk_xbar "/mig_7series_0/ui_addn_clk_0 (100 MHz)" Clk_master "/mig_7series_0/ui_addn_clk_0 (100 MHz)" Clk_slave "/mig_7series_0/ui_addn_clk_0 (100 MHz)" }  [get_bd_intf_pins axi_emc_0/S_AXI_MEM]
apply_bd_automation -rule xilinx.com:bd_rule:board -config {Board_Interface "linear_flash ( Linear flash ) " }  [get_bd_intf_pins axi_emc_0/EMC_INTF]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/mig_7series_0/ui_addn_clk_0 (100 MHz)" }  [get_bd_pins axi_emc_0/rdclk]

############################################################
# Configure AXI Bridge for PCIe Gen3 Subsystem IP
############################################################
# Notes:
# (1) For 4-lane Gen3, the default axi_pcie3 settings are:
#      - Core CLK frequency 250MHz
#      - AXI CLK frequency 125MHz
#      - AXI data width 256 bit
#    However, when these settings are used, the link doesn't
#    come up at Gen3 speed, rather Gen1. Instead, we found it
#    necessary to use the following settings for Gen3 to work
#    correctly:
#      - Core CLK frequency 500MHz
#      - AXI CLK frequency 250MHz
#      - AXI data width 128 bit
#    When these settings are used on the previous committed
#    design, Gen3 works fine but the timing does not pass.
#    For that reason, the current design has been simplified.
#    
set_property -dict [list CONFIG.mode_selection {Advanced} \
CONFIG.device_port_type {Root_Port_of_PCI_Express_Root_Complex} \
CONFIG.pcie_blk_locn {X0Y2} \
CONFIG.pl_link_cap_max_link_width {X4} \
CONFIG.pl_link_cap_max_link_speed {8.0_GT/s} \
CONFIG.axisten_freq {250} \
CONFIG.pf0_sub_class_interface_menu {InfiniBand_to_PCI_host_bridge} \
CONFIG.pf0_class_code_sub {04} \
CONFIG.pf0_bar0_size {1} \
CONFIG.pf0_bar0_scale {Gigabytes} \
CONFIG.pf0_bar0_64bit {true} \
CONFIG.axibar2pciebar_0 {0x0000000040000000} \
CONFIG.Shared_Logic_Both {true} \
CONFIG.axi_data_width {128_bit} \
CONFIG.plltype {QPLL1} \
CONFIG.dedicate_perst {false} \
CONFIG.pf0_device_id {7134} \
CONFIG.pf0_base_class_menu {Bridge_device} \
CONFIG.pf0_class_code_base {06} \
CONFIG.pf0_class_code {060400} \
CONFIG.BASEADDR {0x00000000} \
CONFIG.HIGHADDR {0x001FFFFF} \
CONFIG.pf0_msix_cap_table_bir {BAR_1:0} \
CONFIG.pf0_msix_cap_pba_bir {BAR_1:0}] [get_bd_cells axi_pcie3_0]

# Add MGT external port for PCIe
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pci_exp
connect_bd_intf_net [get_bd_intf_pins axi_pcie3_0/pcie_7x_mgt] [get_bd_intf_ports pci_exp]

# Add constant to tie off /axi_pcie3_0/intx_msi_Request
set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant xlconstant_0 ]
set_property -dict [list CONFIG.CONST_VAL {0}] $xlconstant_0
connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins axi_pcie3_0/intx_msi_Request]

# Add differential buffer for the 100MHz PCIe reference clock
set ref_clk_buf [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf ref_clk_buf ]
set_property -dict [list CONFIG.C_BUF_TYPE {IBUFDSGTE}] $ref_clk_buf
# refclk connected as per page 10 of AXI Bridge PCIe Gen3 Product guide
# http://www.xilinx.com/support/documentation/ip_documentation/axi_pcie3/v2_0/pg194-axi-bridge-pcie-gen3.pdf
connect_bd_net [get_bd_pins ref_clk_buf/IBUF_OUT] [get_bd_pins axi_pcie3_0/refclk]
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 ref_clk
connect_bd_intf_net [get_bd_intf_pins ref_clk_buf/CLK_IN_D] [get_bd_intf_ports ref_clk]

# Configure Microblaze for 4 interrupts and connect them
set_property -dict [list CONFIG.NUM_PORTS {3}] [get_bd_cells microblaze_0_xlconcat]
connect_bd_net [get_bd_pins axi_uart16550_0/ip2intc_irpt] [get_bd_pins microblaze_0_xlconcat/In0]
connect_bd_net [get_bd_pins axi_timer_0/interrupt] [get_bd_pins microblaze_0_xlconcat/In1]
connect_bd_net [get_bd_pins axi_pcie3_0/interrupt_out] [get_bd_pins microblaze_0_xlconcat/In2]

# Add proc system reset for axi_pcie3_0/axi_ctl_aresetn
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_pcie_axi_aclk
connect_bd_net [get_bd_pins axi_pcie3_0/axi_aclk] [get_bd_pins rst_pcie_axi_aclk/slowest_sync_clk]
connect_bd_net [get_bd_pins axi_pcie3_0/axi_ctl_aresetn] [get_bd_pins rst_pcie_axi_aclk/ext_reset_in]
disconnect_bd_net /axi_pcie3_0_axi_aresetn [get_bd_pins microblaze_0_axi_periph/M04_ARESETN]
connect_bd_net [get_bd_pins rst_pcie_axi_aclk/peripheral_aresetn] [get_bd_pins microblaze_0_axi_periph/M04_ARESETN]

# Create PERST port
create_bd_port -dir O -from 0 -to 0 -type rst perst
connect_bd_net [get_bd_pins /rst_pcie_axi_aclk/peripheral_reset] [get_bd_ports perst]

# Connect AXI PCIe reset
create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 rst_inverted
set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {not} CONFIG.LOGO_FILE {data/sym_notgate.png}] [get_bd_cells rst_inverted]
connect_bd_net [get_bd_ports reset] [get_bd_pins rst_inverted/Op1]
connect_bd_net [get_bd_pins rst_inverted/Res] [get_bd_pins axi_pcie3_0/sys_rst_n]

# Create external port connections
connect_bd_net [get_bd_ports mmcm_lock] [get_bd_pins mig_7series_0/mmcm_locked]
connect_bd_net [get_bd_ports init_calib_complete] [get_bd_pins mig_7series_0/init_calib_complete]

# Microblaze address segments
set_property range 64M [get_bd_addr_segs {microblaze_0/Data/SEG_axi_pcie3_0_CTL0}]

# BAR0 must be set to 512M (in Vivado 2017.1 the default is only 1M)
set_property offset 0x20000000 [get_bd_addr_segs {microblaze_0/Data/SEG_axi_pcie3_0_BAR0}]
set_property range 512M [get_bd_addr_segs {microblaze_0/Data/SEG_axi_pcie3_0_BAR0}]

# PCIe AXI CTRL interface base address needs to be manually set in Vivado 2017.1
# See https://forums.xilinx.com/t5/Embedded-Linux/Vivado-2017-1-not-setting-correct-BASEADDR-for-AXI-Bridge-for/m-p/769279#M19963
set_property CONFIG.BASEADDR 0x10000000 [get_bd_cells /axi_pcie3_0]
set_property CONFIG.HIGHADDR 0x13FFFFFF [get_bd_cells /axi_pcie3_0]

# Restore current instance
current_bd_instance $oldCurInst

save_bd_design

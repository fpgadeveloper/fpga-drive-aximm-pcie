################################################################
# Block design build script for KC705 LPC FMC connector
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
apply_bd_automation -rule xilinx.com:bd_rule:mig_7series -config {Board_Interface "ddr3_sdram" }  [get_bd_cells mig_7series_0]
apply_bd_automation -rule xilinx.com:bd_rule:board -config {Board_Interface "reset ( FPGA Reset ) " }  [get_bd_pins mig_7series_0/sys_rst]

# Create ports
set mmcm_lock [ create_bd_port -dir O mmcm_lock ]
set init_calib_complete [ create_bd_port -dir O init_calib_complete ]

# Add the MicroBlaze
create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze microblaze_0
apply_bd_automation -rule xilinx.com:bd_rule:microblaze -config {local_mem "128KB" ecc "None" cache "16KB" debug_module "Debug Only" axi_periph "Enabled" axi_intc "1" clk "/mig_7series_0/ui_addn_clk_0 (100 MHz)" }  [get_bd_cells microblaze_0]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Cached)" Clk "Auto" }  [get_bd_intf_pins mig_7series_0/S_AXI]
apply_bd_automation -rule xilinx.com:bd_rule:board -config {Board_Interface "reset ( FPGA Reset ) " }  [get_bd_pins rst_mig_7series_0_100M/ext_reset_in]

# Configure Microblaze for Linux
set_property -dict [list CONFIG.G_TEMPLATE_LIST {4} CONFIG.G_USE_EXCEPTIONS {1} CONFIG.C_USE_MSR_INSTR {1} CONFIG.C_USE_PCMP_INSTR {1} CONFIG.C_USE_BARREL {1} CONFIG.C_USE_DIV {1} CONFIG.C_USE_HW_MUL {2} CONFIG.C_UNALIGNED_EXCEPTIONS {1} CONFIG.C_ILL_OPCODE_EXCEPTION {1} CONFIG.C_M_AXI_I_BUS_EXCEPTION {1} CONFIG.C_M_AXI_D_BUS_EXCEPTION {1} CONFIG.C_DIV_ZERO_EXCEPTION {1} CONFIG.C_PVR {2} CONFIG.C_OPCODE_0x0_ILLEGAL {1} CONFIG.C_ICACHE_LINE_LEN {8} CONFIG.C_ICACHE_VICTIMS {8} CONFIG.C_ICACHE_STREAMS {1} CONFIG.C_DCACHE_VICTIMS {8} CONFIG.C_USE_MMU {3} CONFIG.C_MMU_ZONES {2}] [get_bd_cells microblaze_0]

# Add the main IPs
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uart16550 axi_uart16550_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_timer axi_timer_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_pcie axi_pcie_0
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_quad_spi axi_quad_spi_0

# Use automation feature
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" Clk "Auto" }  [get_bd_intf_pins axi_uart16550_0/S_AXI]
apply_bd_automation -rule xilinx.com:bd_rule:board -config {Board_Interface "rs232_uart ( UART ) " }  [get_bd_intf_pins axi_uart16550_0/UART]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" Clk "Auto" }  [get_bd_intf_pins axi_timer_0/S_AXI]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Slave "/mig_7series_0/S_AXI" Clk "/axi_pcie_0/axi_aclk_out (62 MHz)" }  [get_bd_intf_pins axi_pcie_0/M_AXI]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" Clk "/axi_pcie_0/axi_aclk_out (62 MHz)" }  [get_bd_intf_pins axi_pcie_0/S_AXI]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" Clk "/axi_pcie_0/axi_ctl_aclk_out (62 MHz)" }  [get_bd_intf_pins axi_pcie_0/S_AXI_CTL]
apply_bd_automation -rule xilinx.com:bd_rule:board -config {Board_Interface "spi_flash ( SPI flash ) " }  [get_bd_intf_pins axi_quad_spi_0/SPI_0]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config {Master "/microblaze_0 (Periph)" intc_ip "Auto" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto" }  [get_bd_intf_pins axi_quad_spi_0/AXI_LITE]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config {Clk "/mig_7series_0/ui_clk (100 MHz)" }  [get_bd_pins axi_quad_spi_0/ext_spi_clk]

# Add slices to the interconnects that connect to PCIe to help pass timing
set_property -dict [list CONFIG.S02_HAS_REGSLICE {4}] [get_bd_cells axi_mem_intercon]
set_property -dict [list CONFIG.M03_HAS_REGSLICE {4}] [get_bd_cells microblaze_0_axi_periph]

# Configure AXI Memory Mapped to PCIe
set_property -dict [list CONFIG.INCLUDE_RC {Root_Port_of_PCI_Express_Root_Complex} \
CONFIG.NO_OF_LANES {X1} \
CONFIG.MAX_LINK_SPEED {5.0_GT/s} \
CONFIG.DEVICE_ID {0x7014} \
CONFIG.BASE_CLASS_MENU {Bridge_device} \
CONFIG.SUB_CLASS_INTERFACE_MENU {InfiniBand_to_PCI_host_bridge} \
CONFIG.S_AXI_DATA_WIDTH {128} \
CONFIG.M_AXI_DATA_WIDTH {128} \
CONFIG.CLASS_CODE {0x060400} \
CONFIG.BAR_64BIT {true} \
CONFIG.BAR0_SCALE {Gigabytes} \
CONFIG.BAR0_SIZE {4} \
CONFIG.PCIEBAR2AXIBAR_0 {0x00000000} \
CONFIG.rp_bar_hide {true} \
CONFIG.XLNX_REF_BOARD {KC705_REVC}] [get_bd_cells axi_pcie_0]

# Add MGT external port for PCIe
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pci_exp
connect_bd_intf_net [get_bd_intf_pins axi_pcie_0/pcie_7x_mgt] [get_bd_intf_ports pci_exp]

# Reset for PCIe
create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 reset_invert
set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {not} CONFIG.LOGO_FILE {data/sym_notgate.png}] [get_bd_cells reset_invert]
connect_bd_net [get_bd_pins reset_invert/Res] [get_bd_pins axi_pcie_0/axi_aresetn]
connect_bd_net [get_bd_ports reset] [get_bd_pins reset_invert/Op1]

# Add differential buffer for the 100MHz PCIe reference clock
set ref_clk_buf [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf ref_clk_buf ]
set_property -dict [list CONFIG.C_BUF_TYPE {IBUFDSGTE}] $ref_clk_buf
connect_bd_net [get_bd_pins ref_clk_buf/IBUF_OUT] [get_bd_pins axi_pcie_0/REFCLK]
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 ref_clk
connect_bd_intf_net [get_bd_intf_pins ref_clk_buf/CLK_IN_D] [get_bd_intf_ports ref_clk]

# Configure Microblaze for 4 interrupts and connect them
set_property -dict [list CONFIG.NUM_PORTS {4}] [get_bd_cells microblaze_0_xlconcat]
connect_bd_net [get_bd_pins axi_uart16550_0/ip2intc_irpt] [get_bd_pins microblaze_0_xlconcat/In0]
connect_bd_net [get_bd_pins axi_timer_0/interrupt] [get_bd_pins microblaze_0_xlconcat/In1]
connect_bd_net [get_bd_pins axi_pcie_0/interrupt_out] [get_bd_pins microblaze_0_xlconcat/In2]
connect_bd_net [get_bd_pins axi_quad_spi_0/ip2intc_irpt] [get_bd_pins microblaze_0_xlconcat/In3]

# Complete wiring of the proc system reset for axi_pcie_0/axi_aclk_out
connect_bd_net [get_bd_pins axi_pcie_0/mmcm_lock] [get_bd_pins rst_axi_pcie_0_62M/dcm_locked]
connect_bd_net [get_bd_ports reset] [get_bd_pins rst_axi_pcie_0_62M/ext_reset_in]

# Add proc system reset for axi_pcie_0/axi_aclk_ctl_out
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_axi_pcie_ctl
connect_bd_net [get_bd_pins axi_pcie_0/axi_ctl_aclk_out] [get_bd_pins rst_axi_pcie_ctl/slowest_sync_clk]
connect_bd_net [get_bd_ports reset] [get_bd_pins rst_axi_pcie_ctl/ext_reset_in]
connect_bd_net [get_bd_pins axi_pcie_0/mmcm_lock] [get_bd_pins rst_axi_pcie_ctl/dcm_locked]
disconnect_bd_net /rst_axi_pcie_0_62M_peripheral_aresetn [get_bd_pins microblaze_0_axi_periph/M04_ARESETN]
connect_bd_net [get_bd_pins rst_axi_pcie_ctl/peripheral_aresetn] [get_bd_pins microblaze_0_axi_periph/M04_ARESETN]

# Create PERST port
create_bd_port -dir O -from 0 -to 0 -type rst perst
connect_bd_net [get_bd_pins /rst_axi_pcie_ctl/peripheral_reset] [get_bd_ports perst]

# Create external port connections
connect_bd_net -net axi_pcie_0_mmcm_lock [get_bd_ports mmcm_lock] [get_bd_pins axi_pcie_0/mmcm_lock]
connect_bd_net -net mig_7series_0_init_calib_complete [get_bd_ports init_calib_complete] [get_bd_pins mig_7series_1/init_calib_complete]

# Microblaze address segments
set_property range 64M [get_bd_addr_segs {microblaze_0/Data/SEG_axi_pcie_0_CTL0}]

# Restore current instance
current_bd_instance $oldCurInst

save_bd_design


################################################################
# Block design build script for Zynq boards
################################################################

# CHECKING IF PROJECT EXISTS
if { [get_projects -quiet] eq "" } {
   puts "ERROR: Please open or create a project!"
   return 1
}

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

create_bd_design $block_name

current_bd_design $block_name

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

# Add the Processor System and apply board preset
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7 processing_system7_0
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]

# Configure the PS: Generate 100MHz clock, Enable GP0, GP1, HP0, Enable interrupts
set_property -dict [list CONFIG.PCW_USE_M_AXI_GP0 {1} \
CONFIG.PCW_USE_M_AXI_GP1 {1} \
CONFIG.PCW_USE_S_AXI_HP0 {1} \
CONFIG.PCW_USE_FABRIC_INTERRUPT {1} \
CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100} \
CONFIG.PCW_EN_CLK0_PORT {1} \
CONFIG.PCW_IRQ_F2P_INTR {1} \
CONFIG.PCW_TTC0_PERIPHERAL_ENABLE {1}] [get_bd_cells processing_system7_0]

# Use the 100MHz fabric clock for GP0, GP1 and HP0 interfaces
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/M_AXI_GP1_ACLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/S_AXI_HP0_ACLK]

# AXI Memory Mapped to PCIe Bridge configurations
if {[lindex $num_lanes 0] == "X4"} {
  # 4-lane PCIe config
  set no_of_lanes X4
  set device_id 0x7124
  set data_width 128
} else {
  # 1-lane PCIe config
  set no_of_lanes X1
  set device_id 0x7012
  set data_width 64
}

# PicoZed 7015 supports PCIe Gen1
# PicoZed 7030 and ZC706 support PCIe Gen2
if {$board_name == "pz7z030" || $board_name == "zc706"} {
  set max_link_speed 5.0_GT/s
} else {
  set max_link_speed 2.5_GT/s
}

# Add the AXI Memory Mapped to PCIe Bridge IP
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_pcie axi_pcie_0
set_property -dict [list CONFIG.INCLUDE_RC {Root_Port_of_PCI_Express_Root_Complex} \
CONFIG.NO_OF_LANES $no_of_lanes \
CONFIG.MAX_LINK_SPEED $max_link_speed \
CONFIG.ENABLE_CLASS_CODE {false} \
CONFIG.SUB_CLASS_INTERFACE_MENU {PCI_to_PCI_bridge} \
CONFIG.BAR0_SCALE {Gigabytes} \
CONFIG.shared_logic_in_core {false} \
CONFIG.rp_bar_hide {true} \
CONFIG.DEVICE_ID $device_id \
CONFIG.CLASS_CODE {0x060400} \
CONFIG.BASE_CLASS_MENU {Bridge_device} \
CONFIG.BAR0_SIZE {1} \
CONFIG.BASEADDR {0x00000000} \
CONFIG.HIGHADDR {0x001FFFFF} \
CONFIG.AXIBAR2PCIEBAR_0 {0x80000000} \
CONFIG.S_AXI_DATA_WIDTH $data_width \
CONFIG.M_AXI_DATA_WIDTH $data_width] [get_bd_cells axi_pcie_0]

# Add port for PCIe bus
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pcie_7x_mgt_0
connect_bd_intf_net [get_bd_intf_pins axi_pcie_0/pcie_7x_mgt] [get_bd_intf_ports pcie_7x_mgt_0]

# Add differential buffer for the 100MHz PCIe reference clock
create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf ref_clk_buf
set_property -dict [list CONFIG.C_BUF_TYPE {IBUFDSGTE}] [get_bd_cells ref_clk_buf]
connect_bd_net [get_bd_pins ref_clk_buf/IBUF_OUT] [get_bd_pins axi_pcie_0/REFCLK]
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 ref_clk_0
connect_bd_intf_net [get_bd_intf_pins ref_clk_buf/CLK_IN_D] [get_bd_intf_ports ref_clk_0]

# Add interrupt concat and connect interrupts
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_0
set_property -dict [list CONFIG.NUM_PORTS {1}] [get_bd_cells xlconcat_0]
connect_bd_net [get_bd_pins xlconcat_0/dout] [get_bd_pins processing_system7_0/IRQ_F2P]
connect_bd_net [get_bd_pins axi_pcie_0/interrupt_out] [get_bd_pins xlconcat_0/In0]

# Add external port to connect MMCM_LOCK to LED
create_bd_port -dir O mmcm_lock
connect_bd_net [get_bd_pins /axi_pcie_0/mmcm_lock] [get_bd_ports mmcm_lock]

# Add proc system reset for the axi_pcie reset signal
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_0
connect_bd_net [get_bd_pins axi_pcie_0/axi_ctl_aclk_out] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
connect_bd_net [get_bd_pins axi_pcie_0/mmcm_lock] [get_bd_pins proc_sys_reset_0/dcm_locked]

# Create the perst port and connect it
# Active HIGH PERST output for FMC designs (FMC form factor)
create_bd_port -dir O -from 0 -to 0 -type rst perst_0
connect_bd_net [get_bd_pins processing_system7_0/FCLK_RESET0_N] [get_bd_pins proc_sys_reset_0/ext_reset_in]
connect_bd_net [get_bd_pins /proc_sys_reset_0/peripheral_reset] [get_bd_ports perst_0]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_pcie_0/axi_aresetn]

# Add two peripheral interconnects (for GP0 and GP1) and a mem interconnect (for HP0)
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect periph_intercon_0
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins periph_intercon_0/ACLK]
set_property -dict [list CONFIG.NUM_MI {1}] [get_bd_cells periph_intercon_0]
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect periph_intercon_1
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins periph_intercon_1/ACLK]
set_property -dict [list CONFIG.NUM_MI {1}] [get_bd_cells periph_intercon_1]
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect mem_intercon
set_property -dict [list CONFIG.NUM_MI {1}] [get_bd_cells mem_intercon]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins mem_intercon/ACLK]

# Connect axi_pcie S_AXI, S_AXI_CTL and M_AXI
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/axi_pcie_0/axi_aclk_out (125 MHz)} Clk_slave {/processing_system7_0/FCLK_CLK0 (100 MHz)} Clk_xbar {/processing_system7_0/FCLK_CLK0 (100 MHz)} Master {/axi_pcie_0/M_AXI} Slave {/processing_system7_0/S_AXI_HP0} intc_ip {/mem_intercon} master_apm {0}}  [get_bd_intf_pins processing_system7_0/S_AXI_HP0]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/processing_system7_0/FCLK_CLK0 (100 MHz)} Clk_slave {/axi_pcie_0/axi_ctl_aclk_out (125 MHz)} Clk_xbar {/processing_system7_0/FCLK_CLK0 (100 MHz)} Master {/processing_system7_0/M_AXI_GP0} Slave {/axi_pcie_0/S_AXI_CTL} intc_ip {/periph_intercon_0} master_apm {0}}  [get_bd_intf_pins axi_pcie_0/S_AXI_CTL]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/processing_system7_0/FCLK_CLK0 (100 MHz)} Clk_slave {/axi_pcie_0/axi_aclk_out (125 MHz)} Clk_xbar {/processing_system7_0/FCLK_CLK0 (100 MHz)} Master {/processing_system7_0/M_AXI_GP1} Slave {/axi_pcie_0/S_AXI} intc_ip {/periph_intercon_1} master_apm {0}}  [get_bd_intf_pins axi_pcie_0/S_AXI]

# Constant to enable/disable 3.3V power supply of SSD2 and clock source
set const_dis_ssd2_pwr [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_dis_ssd2_pwr ]
create_bd_port -dir O disable_ssd2_pwr
connect_bd_net [get_bd_pins const_dis_ssd2_pwr/dout] [get_bd_ports disable_ssd2_pwr]
# HIGH to disable SSD2
set_property -dict [list CONFIG.CONST_VAL {1}] $const_dis_ssd2_pwr

# Restore current instance
current_bd_instance $oldCurInst

save_bd_design

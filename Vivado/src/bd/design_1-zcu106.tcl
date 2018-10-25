################################################################
# Block design build script for ZCU106 HPC0 FMC connector
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

# Add the Processor System and apply board preset
create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e zynq_ultra_ps_e_0
apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1" }  [get_bd_cells zynq_ultra_ps_e_0]

# Configure the PS: Enable HP0 and HP1 (for dual designs) to DDR
if {$dual_design} {
  set_property -dict [list CONFIG.PSU__USE__S_AXI_GP2 {1} CONFIG.PSU__USE__S_AXI_GP3 {1}] [get_bd_cells zynq_ultra_ps_e_0]
} else {
  set_property -dict [list CONFIG.PSU__USE__S_AXI_GP2 {1}] [get_bd_cells zynq_ultra_ps_e_0]
}

# Connect the PS clocks
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins zynq_ultra_ps_e_0/maxihpm0_fpd_aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins zynq_ultra_ps_e_0/maxihpm1_fpd_aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins zynq_ultra_ps_e_0/saxihp0_fpd_aclk]
if {$dual_design} {
  connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins zynq_ultra_ps_e_0/saxihp1_fpd_aclk]
}

# Add the DMA/Bridge Subsystem for PCIe IPs
create_bd_cell -type ip -vlnv xilinx.com:ip:xdma xdma_0
if {$dual_design} {
  create_bd_cell -type ip -vlnv xilinx.com:ip:xdma xdma_1
}

# ZCU106 HPC0 has enough MGTs for all 4-lanes for SSD1 and SSD2
# ZCU106 HPC1 has only 1x MGT for SSD1 (cannot support SSD2)
if {$fmc_name eq "hpc0"} {
  # 4-lane PCIe config for HPC0
  set max_link_width X4
  set axi_data_width 128_bit
  set axisten_freq 250
  set pf_device_id 9134
} else {
  # 1-lane PCIe config for HPC1
  set max_link_width X1
  set axi_data_width 64_bit
  set axisten_freq 125
  set pf_device_id 9131
}

# ##########################################################
# Configure DMA/Bridge Subsystem for PCIe IP
# ##########################################################
# Notes:
# (1) The high speed PCIe traces on the FPGA Drive FMC are very
#    short, so there is very low signal loss between the FPGA
#    and the SSD. For this reason, it is best to use the
#    "Chip-to-Chip" loss profile in the "GT Settings" (the
#    default is "Add-on card"). Also, the "Chip-to-Chip"
#    profile is the only one that disables the DFE, a feature
#    that is better suited for longer and more lossy traces.
#    
set_property -dict [list CONFIG.functional_mode {AXI_Bridge} \
CONFIG.mode_selection {Advanced} \
CONFIG.device_port_type {Root_Port_of_PCI_Express_Root_Complex} \
CONFIG.pl_link_cap_max_link_width $max_link_width \
CONFIG.pl_link_cap_max_link_speed {8.0_GT/s} \
CONFIG.axi_addr_width {32} \
CONFIG.axi_data_width $axi_data_width \
CONFIG.axisten_freq $axisten_freq \
CONFIG.dedicate_perst {false} \
CONFIG.sys_reset_polarity {ACTIVE_LOW} \
CONFIG.pf0_device_id $pf_device_id \
CONFIG.pf0_base_class_menu {Bridge_device} \
CONFIG.pf0_class_code_base {06} \
CONFIG.pf0_sub_class_interface_menu {PCI_to_PCI_bridge} \
CONFIG.pf0_class_code_sub {04} \
CONFIG.pf0_class_code_interface {00} \
CONFIG.pf0_class_code {060400} \
CONFIG.xdma_axilite_slave {true} \
CONFIG.pcie_blk_locn {X0Y0} \
CONFIG.select_quad {GTH_Quad_226} \
CONFIG.INS_LOSS_NYQ {5} \
CONFIG.plltype {QPLL1} \
CONFIG.ins_loss_profile {Chip-to-Chip} \
CONFIG.type1_membase_memlimit_enable {Enabled} \
CONFIG.type1_prefetchable_membase_memlimit {64bit_Enabled} \
CONFIG.axibar2pciebar_0 {0x0000001000000000} \
CONFIG.BASEADDR {0x00000000} \
CONFIG.HIGHADDR {0x001FFFFF} \
CONFIG.pf0_bar0_enabled {false} \
CONFIG.pf1_class_code {060700} \
CONFIG.pf1_base_class_menu {Bridge_device} \
CONFIG.pf1_class_code_base {06} \
CONFIG.pf1_class_code_sub {07} \
CONFIG.pf1_sub_class_interface_menu {CardBus_bridge} \
CONFIG.pf1_class_code_interface {00} \
CONFIG.pf1_bar2_enabled {false} \
CONFIG.pf1_bar2_64bit {false} \
CONFIG.pf1_bar4_enabled {false} \
CONFIG.pf1_bar4_64bit {false} \
CONFIG.dma_reset_source_sel {Phy_Ready} \
CONFIG.pf0_bar0_type_mqdma {Memory} \
CONFIG.pf1_bar0_type_mqdma {Memory} \
CONFIG.pf2_bar0_type_mqdma {Memory} \
CONFIG.pf3_bar0_type_mqdma {Memory} \
CONFIG.pf0_sriov_bar0_type {Memory} \
CONFIG.pf1_sriov_bar0_type {Memory} \
CONFIG.pf2_sriov_bar0_type {Memory} \
CONFIG.pf3_sriov_bar0_type {Memory} \
CONFIG.PF0_DEVICE_ID_mqdma $pf_device_id \
CONFIG.PF2_DEVICE_ID_mqdma $pf_device_id \
CONFIG.PF3_DEVICE_ID_mqdma $pf_device_id \
CONFIG.pf0_base_class_menu_mqdma {Bridge_device} \
CONFIG.pf0_class_code_base_mqdma {06} \
CONFIG.pf0_class_code_mqdma {068000} \
CONFIG.pf1_base_class_menu_mqdma {Bridge_device} \
CONFIG.pf1_class_code_base_mqdma {06} \
CONFIG.pf1_class_code_mqdma {068000} \
CONFIG.pf2_base_class_menu_mqdma {Bridge_device} \
CONFIG.pf2_class_code_base_mqdma {06} \
CONFIG.pf2_class_code_mqdma {068000} \
CONFIG.pf3_base_class_menu_mqdma {Bridge_device} \
CONFIG.pf3_class_code_base_mqdma {06} \
CONFIG.pf3_class_code_mqdma {068000}] [get_bd_cells xdma_0]

if {$dual_design} {
  set_property -dict [list CONFIG.functional_mode {AXI_Bridge} \
  CONFIG.mode_selection {Advanced} \
  CONFIG.device_port_type {Root_Port_of_PCI_Express_Root_Complex} \
  CONFIG.pl_link_cap_max_link_width {X4} \
  CONFIG.pl_link_cap_max_link_speed {8.0_GT/s} \
  CONFIG.axi_addr_width {32} \
  CONFIG.axi_data_width {128_bit} \
  CONFIG.axisten_freq {250} \
  CONFIG.dedicate_perst {false} \
  CONFIG.sys_reset_polarity {ACTIVE_LOW} \
  CONFIG.pf0_device_id {9134} \
  CONFIG.pf0_base_class_menu {Bridge_device} \
  CONFIG.pf0_class_code_base {06} \
  CONFIG.pf0_sub_class_interface_menu {PCI_to_PCI_bridge} \
  CONFIG.pf0_class_code_sub {04} \
  CONFIG.pf0_class_code_interface {00} \
  CONFIG.pf0_class_code {060400} \
  CONFIG.xdma_axilite_slave {true} \
  CONFIG.pcie_blk_locn {X0Y1} \
  CONFIG.select_quad {GTH_Quad_227} \
  CONFIG.INS_LOSS_NYQ {5} \
  CONFIG.plltype {QPLL1} \
  CONFIG.ins_loss_profile {Chip-to-Chip} \
  CONFIG.type1_membase_memlimit_enable {Enabled} \
  CONFIG.type1_prefetchable_membase_memlimit {64bit_Enabled} \
  CONFIG.axibar2pciebar_0 {0x0000001010000000} \
  CONFIG.BASEADDR {0x00000000} \
  CONFIG.HIGHADDR {0x001FFFFF} \
  CONFIG.pf0_bar0_enabled {false} \
  CONFIG.pf1_class_code {060700} \
  CONFIG.pf1_base_class_menu {Bridge_device} \
  CONFIG.pf1_class_code_base {06} \
  CONFIG.pf1_class_code_sub {07} \
  CONFIG.pf1_sub_class_interface_menu {CardBus_bridge} \
  CONFIG.pf1_class_code_interface {00} \
  CONFIG.pf1_bar2_enabled {false} \
  CONFIG.pf1_bar2_64bit {false} \
  CONFIG.pf1_bar4_enabled {false} \
  CONFIG.pf1_bar4_64bit {false} \
  CONFIG.dma_reset_source_sel {Phy_Ready} \
  CONFIG.pf0_bar0_type_mqdma {Memory} \
  CONFIG.pf1_bar0_type_mqdma {Memory} \
  CONFIG.pf2_bar0_type_mqdma {Memory} \
  CONFIG.pf3_bar0_type_mqdma {Memory} \
  CONFIG.pf0_sriov_bar0_type {Memory} \
  CONFIG.pf1_sriov_bar0_type {Memory} \
  CONFIG.pf2_sriov_bar0_type {Memory} \
  CONFIG.pf3_sriov_bar0_type {Memory} \
  CONFIG.PF0_DEVICE_ID_mqdma {9134} \
  CONFIG.PF2_DEVICE_ID_mqdma {9134} \
  CONFIG.PF3_DEVICE_ID_mqdma {9134} \
  CONFIG.pf0_base_class_menu_mqdma {Bridge_device} \
  CONFIG.pf0_class_code_base_mqdma {06} \
  CONFIG.pf0_class_code_mqdma {068000} \
  CONFIG.pf1_base_class_menu_mqdma {Bridge_device} \
  CONFIG.pf1_class_code_base_mqdma {06} \
  CONFIG.pf1_class_code_mqdma {068000} \
  CONFIG.pf2_base_class_menu_mqdma {Bridge_device} \
  CONFIG.pf2_class_code_base_mqdma {06} \
  CONFIG.pf2_class_code_mqdma {068000} \
  CONFIG.pf3_base_class_menu_mqdma {Bridge_device} \
  CONFIG.pf3_class_code_base_mqdma {06} \
  CONFIG.pf3_class_code_mqdma {068000}] [get_bd_cells xdma_1]
}

# Create AXI Interconnect for the XDMA slave interfaces
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect periph_intercon

# Use connection automation after configuration of the PCIe block - so it will assign 512MB to the S_AXI_CTL interfaces
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/xdma_0/axi_aclk (250 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {Auto} Master {/xdma_0/M_AXI_B} Slave {/zynq_ultra_ps_e_0/S_AXI_HP0_FPD} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP0_FPD]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/xdma_0/axi_aclk (250 MHz)} Clk_xbar {Auto} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/xdma_0/S_AXI_B} intc_ip {periph_intercon} master_apm {0}}  [get_bd_intf_pins xdma_0/S_AXI_B]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/xdma_0/axi_aclk (250 MHz)} Clk_xbar {Auto} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/xdma_0/S_AXI_LITE} intc_ip {periph_intercon} master_apm {0}}  [get_bd_intf_pins xdma_0/S_AXI_LITE]
if {$dual_design} {
  apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/xdma_1/axi_aclk (250 MHz)} Clk_slave {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_xbar {Auto} Master {/xdma_1/M_AXI_B} Slave {/zynq_ultra_ps_e_0/S_AXI_HP1_FPD} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP1_FPD]
  apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/xdma_1/axi_aclk (250 MHz)} Clk_xbar {Auto} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/xdma_1/S_AXI_B} intc_ip {periph_intercon} master_apm {0}}  [get_bd_intf_pins xdma_1/S_AXI_B]
  apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/zynq_ultra_ps_e_0/pl_clk0 (99 MHz)} Clk_slave {/xdma_1/axi_aclk (250 MHz)} Clk_xbar {Auto} Master {/zynq_ultra_ps_e_0/M_AXI_HPM0_FPD} Slave {/xdma_1/S_AXI_LITE} intc_ip {periph_intercon} master_apm {0}}  [get_bd_intf_pins xdma_1/S_AXI_LITE]
}

# Set the BAR0 offsets and sizes
set_property offset 0x1000000000 [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_xdma_0_BAR0}]
set_property range 256M [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_xdma_0_BAR0}]
if {$dual_design} {
  set_property offset 0x1010000000 [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_xdma_1_BAR0}]
  set_property range 256M [get_bd_addr_segs {zynq_ultra_ps_e_0/Data/SEG_xdma_1_BAR0}]
}

# Add MGT external port for PCIe (SSD1)
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pci_exp_0
connect_bd_intf_net [get_bd_intf_pins xdma_0/pcie_mgt] [get_bd_intf_ports pci_exp_0]

# Add MGT external port for PCIe (SSD2)
if {$dual_design} {
  create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pci_exp_1
  connect_bd_intf_net [get_bd_intf_pins xdma_1/pcie_mgt] [get_bd_intf_ports pci_exp_1]
}

# Add differential buffer for the 100MHz PCIe reference clock (SSD1)
create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf ref_clk_0_buf
set_property -dict [list CONFIG.C_BUF_TYPE {IBUFDSGTE}] [get_bd_cells ref_clk_0_buf]
# sys_clk and sys_clk_gt connected as per DMA/Bridge Subsystem for PCIe Product guide PG195
# https://www.xilinx.com/support/documentation/ip_documentation/xdma/v2_0/pg195-pcie-dma.pdf
connect_bd_net [get_bd_pins ref_clk_0_buf/IBUF_DS_ODIV2] [get_bd_pins xdma_0/sys_clk]
connect_bd_net [get_bd_pins ref_clk_0_buf/IBUF_OUT] [get_bd_pins xdma_0/sys_clk_gt]
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 ref_clk_0
connect_bd_intf_net [get_bd_intf_pins ref_clk_0_buf/CLK_IN_D] [get_bd_intf_ports ref_clk_0]

# Add differential buffer for the 100MHz PCIe reference clock (SSD2)
if {$dual_design} {
  create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf ref_clk_1_buf
  set_property -dict [list CONFIG.C_BUF_TYPE {IBUFDSGTE}] [get_bd_cells ref_clk_1_buf]
  # sys_clk and sys_clk_gt connected as per DMA/Bridge Subsystem for PCIe Product guide PG195
  # https://www.xilinx.com/support/documentation/ip_documentation/xdma/v2_0/pg195-pcie-dma.pdf
  connect_bd_net [get_bd_pins ref_clk_1_buf/IBUF_DS_ODIV2] [get_bd_pins xdma_1/sys_clk]
  connect_bd_net [get_bd_pins ref_clk_1_buf/IBUF_OUT] [get_bd_pins xdma_1/sys_clk_gt]
  create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 ref_clk_1
  connect_bd_intf_net [get_bd_intf_pins ref_clk_1_buf/CLK_IN_D] [get_bd_intf_ports ref_clk_1]
}

# Create concat for the interrupts and connect them
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 concat_interrupts
connect_bd_net [get_bd_pins concat_interrupts/dout] [get_bd_pins zynq_ultra_ps_e_0/pl_ps_irq0]
if {$dual_design} {
  set_property -dict [list CONFIG.NUM_PORTS {2}] [get_bd_cells concat_interrupts]
  connect_bd_net [get_bd_pins xdma_0/interrupt_out] [get_bd_pins concat_interrupts/In0]
  connect_bd_net [get_bd_pins xdma_1/interrupt_out] [get_bd_pins concat_interrupts/In1]
} else {
  set_property -dict [list CONFIG.NUM_PORTS {1}] [get_bd_cells concat_interrupts]
  connect_bd_net [get_bd_pins xdma_0/interrupt_out] [get_bd_pins concat_interrupts/In0]
}

# Add proc system reset for xdma_0/axi_ctl_aresetn
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_pcie_0_axi_aclk
connect_bd_net [get_bd_pins xdma_0/axi_aclk] [get_bd_pins rst_pcie_0_axi_aclk/slowest_sync_clk]
connect_bd_net [get_bd_pins xdma_0/axi_ctl_aresetn] [get_bd_pins rst_pcie_0_axi_aclk/ext_reset_in]
disconnect_bd_net /xdma_0_axi_aresetn [get_bd_pins periph_intercon/M01_ARESETN]
connect_bd_net [get_bd_pins xdma_0/axi_ctl_aresetn] [get_bd_pins periph_intercon/M01_ARESETN]

# Add proc system reset for xdma_1/axi_ctl_aresetn
if {$dual_design} {
  create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_pcie_1_axi_aclk
  connect_bd_net [get_bd_pins xdma_1/axi_aclk] [get_bd_pins rst_pcie_1_axi_aclk/slowest_sync_clk]
  connect_bd_net [get_bd_pins xdma_1/axi_ctl_aresetn] [get_bd_pins rst_pcie_1_axi_aclk/ext_reset_in]
  disconnect_bd_net /xdma_1_axi_aresetn [get_bd_pins periph_intercon/M03_ARESETN]
  connect_bd_net [get_bd_pins xdma_1/axi_ctl_aresetn] [get_bd_pins periph_intercon/M03_ARESETN]
}

# Create PERST ports
create_bd_port -dir O -from 0 -to 0 -type rst perst_0
connect_bd_net [get_bd_pins /rst_pcie_0_axi_aclk/peripheral_reset] [get_bd_ports perst_0]
if {$dual_design} {
  create_bd_port -dir O -from 0 -to 0 -type rst perst_1
  connect_bd_net [get_bd_pins /rst_pcie_1_axi_aclk/peripheral_reset] [get_bd_ports perst_1]
}

# Connect AXI PCIe reset
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0] [get_bd_pins xdma_0/sys_rst_n]
if {$dual_design} {
  connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0] [get_bd_pins xdma_1/sys_rst_n]
}

# Constant to enable/disable 3.3V power supply of SSD2 and clock source
set const_dis_ssd2_pwr [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_dis_ssd2_pwr ]
create_bd_port -dir O disable_ssd2_pwr
connect_bd_net [get_bd_pins const_dis_ssd2_pwr/dout] [get_bd_ports disable_ssd2_pwr]
if {$dual_design} {
  # LOW to enable SSD2
  set_property -dict [list CONFIG.CONST_VAL {0}] $const_dis_ssd2_pwr
} else {
  # HIGH to disable SSD2
  set_property -dict [list CONFIG.CONST_VAL {1}] $const_dis_ssd2_pwr
}

# Restore current instance
current_bd_instance $oldCurInst

save_bd_design

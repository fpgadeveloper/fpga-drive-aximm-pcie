################################################################
# Block design build script for KC705 HPC FMC connector
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

# Board specific parameters, PCIe and GT LOCs
if {$board_name == "kc705"} {
  set ddr_name "ddr3_sdram"
  set xlnx_ref_board "KC705_REVC"
  set pcie_ip "axi_pcie"
  set baddr {0x10000000}
  set haddr {0x13FFFFFF}
  set axi2pci {0x0000000070000000}
  set barsize {256M}
} elseif {$board_name == "vc707"} {
  set ddr_name "ddr3_sdram"
  set xlnx_ref_board "VC707"
  set pcie_ip "axi_pcie"
  set baddr {0x10000000}
  set haddr {0x13FFFFFF}
  set axi2pci {0x0000000070000000}
  set barsize {256M}
} elseif {$board_name == "vc709"} {
  set ddr_name "ddr3_sdram_socket_j1"
  set pcie_ip "axi_pcie3"
  set pcie_loc {X0Y2}
  set baddr {0x10000000}
  set haddr {0x1FFFFFFF}
  set axi2pci {0x0000000070000000}
  set barsize {256M}
} elseif {$target == "kcu105_hpc"} {
  set pcie_ip "axi_pcie3"
  set pcie_loc {X0Y2}
  set baddr {0x10000000}
  set haddr {0x1FFFFFFF}
  set axi2pci {0x0000000060000000}
  set barsize {512M}
} elseif {$target == "kcu105_hpc_dual"} {
  set pcie_ip "axi_pcie3"
  set pcie_loc {X0Y2 X0Y1}
  set baddr {0x10000000 0x20000000}
  set haddr {0x1FFFFFFF 0x2FFFFFFF}
  set axi2pci {0x0000000060000000 0x0000000070000000}
  set barsize {256M 256M}
} elseif {$target == "kcu105_lpc"} {
  set pcie_ip "axi_pcie3"
  set pcie_loc {X0Y1}
  set baddr {0x10000000}
  set haddr {0x1FFFFFFF}
  set axi2pci {0x0000000060000000}
  set barsize {512M}
} elseif {$target == "vcu118_dual"} {
  set pcie_ip "xdma"
  set pcie_loc {X0Y1 X0Y3}
  set select_quad {"GTY_Quad_121" "GTY_Quad_126"}
  set baddr {0x10000000 0x20000000}
  set haddr {0x1FFFFFFF 0x2FFFFFFF}
  set axi2pci {0x0000000060000000 0x0000000070000000}
  set barsize {256M 256M}
} elseif {$target == "vcu118"} {
  set pcie_ip "xdma"
  set pcie_loc {X0Y1}
  set select_quad "GTY_Quad_121"
  set baddr {0x10000000}
  set haddr {0x1FFFFFFF}
  set axi2pci {0x0000000060000000}
  set barsize {512M}
}

# Create the list of interrupts
set ints {}

# KCU105 board MIG setup
if {$board_name == "kcu105"} {
  set mig_name "ddr4_0"
  set mig_slave_interface "/ddr4_0/C0_DDR4_S_AXI"
  set mig_ui_clk "/ddr4_0/c0_ddr4_ui_clk"
  create_bd_cell -type ip -vlnv xilinx.com:ip:ddr4 $mig_name
  apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {default_sysclk_300 ( 300 MHz System differential clock ) } Manual_Source {Auto}}  [get_bd_intf_pins ddr4_0/C0_SYS_CLK]
  apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {ddr4_sdram_062 ( DDR4 SDRAM ) } Manual_Source {Auto}}  [get_bd_intf_pins ddr4_0/C0_DDR4]
  apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {reset ( FPGA Reset ) } Manual_Source {New External Port (ACTIVE_HIGH)}}  [get_bd_pins ddr4_0/sys_rst]
  # Add the 50MHz additional clock output for Quad SPI clock
  set_property -dict [list CONFIG.ADDN_UI_CLKOUT2_FREQ_HZ {50}] [get_bd_cells ddr4_0]
# VCU118 board MIG setup
} elseif {$board_name == "vcu118"} {
  set mig_name "ddr4_0"
  set mig_slave_interface "/ddr4_0/C0_DDR4_S_AXI"
  set mig_ui_clk "/ddr4_0/c0_ddr4_ui_clk"
  create_bd_cell -type ip -vlnv xilinx.com:ip:ddr4 $mig_name
  apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {default_250mhz_clk1 ( 250 MHz System differential clock1 ) } Manual_Source {Auto}}  [get_bd_intf_pins ddr4_0/C0_SYS_CLK]
  apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {ddr4_sdram_c1_062 ( DDR4 SDRAM C1 ) } Manual_Source {Auto}}  [get_bd_intf_pins ddr4_0/C0_DDR4]
  apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {reset ( FPGA Reset ) } Manual_Source {New External Port (ACTIVE_HIGH)}}  [get_bd_pins ddr4_0/sys_rst]
  # 50MHz additional clock required by AXI Quad SPI
  set_property -dict [list CONFIG.ADDN_UI_CLKOUT2_FREQ_HZ {50}] [get_bd_cells ddr4_0]
# Series-7 boards MIG setup
} else {
  set mig_name "mig_0"
  set mig_slave_interface "/mig_0/S_AXI"
  set mig_ui_clk "/mig_0/ui_clk"
  create_bd_cell -type ip -vlnv xilinx.com:ip:mig_7series $mig_name
  apply_bd_automation -rule xilinx.com:bd_rule:mig_7series -config "Board_Interface $ddr_name "  [get_bd_cells mig_0]
  apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {reset ( FPGA Reset ) } Manual_Source {New External Port (ACTIVE_HIGH)}}  [get_bd_pins mig_0/sys_rst]
}

# Add the MicroBlaze
create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze microblaze_0
if {$board_name == "kcu105"} {
  apply_bd_automation -rule xilinx.com:bd_rule:microblaze -config { axi_intc {1} axi_periph {Enabled} cache {16KB} clk {/ddr4_0/addn_ui_clkout1 (100 MHz)} debug_module {Debug Only} ecc {None} local_mem {128KB} preset {None}}  [get_bd_cells microblaze_0]
  apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/ddr4_0/addn_ui_clkout1 (100 MHz)} Clk_slave {/ddr4_0/c0_ddr4_ui_clk (300 MHz)} Clk_xbar {/ddr4_0/addn_ui_clkout1 (100 MHz)} Master {/microblaze_0 (Cached)} Slave {/ddr4_0/C0_DDR4_S_AXI} intc_ip {New AXI SmartConnect} master_apm {0}}  [get_bd_intf_pins ddr4_0/C0_DDR4_S_AXI]
  apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {reset ( FPGA Reset ) } Manual_Source {New External Port (ACTIVE_LOW)}}  [get_bd_pins rst_ddr4_0_100M/ext_reset_in]
  # Create ports
  create_bd_port -dir O init_calib_complete
  connect_bd_net [get_bd_ports init_calib_complete] [get_bd_pins ddr4_0/c0_init_calib_complete]
} elseif {$board_name == "vcu118"} {
  apply_bd_automation -rule xilinx.com:bd_rule:microblaze -config { axi_intc {1} axi_periph {Enabled} cache {16KB} clk {/ddr4_0/addn_ui_clkout1 (100 MHz)} debug_module {Debug Only} ecc {None} local_mem {128KB} preset {None}}  [get_bd_cells microblaze_0]
  apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/ddr4_0/addn_ui_clkout1 (100 MHz)} Clk_slave {/ddr4_0/c0_ddr4_ui_clk (300 MHz)} Clk_xbar {/ddr4_0/addn_ui_clkout1 (100 MHz)} Master {/microblaze_0 (Cached)} Slave {/ddr4_0/C0_DDR4_S_AXI} intc_ip {New AXI SmartConnect} master_apm {0}}  [get_bd_intf_pins ddr4_0/C0_DDR4_S_AXI]
  apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {Custom} Manual_Source {/ddr4_0/c0_ddr4_ui_clk_sync_rst (ACTIVE_HIGH)}}  [get_bd_pins rst_ddr4_0_100M/ext_reset_in]
  # Create ports
  create_bd_port -dir O init_calib_complete
  connect_bd_net [get_bd_ports init_calib_complete] [get_bd_pins ddr4_0/c0_init_calib_complete]
} else {
  apply_bd_automation -rule xilinx.com:bd_rule:microblaze -config { axi_intc {1} axi_periph {Enabled} cache {16KB} clk {/mig_0/ui_addn_clk_0 (100 MHz)} cores {1} debug_module {Debug Only} ecc {None} local_mem {128KB} preset {None}}  [get_bd_cells microblaze_0]
  apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/mig_0/ui_addn_clk_0 (100 MHz)} Clk_slave {/mig_0/ui_clk (200 MHz)} Clk_xbar {Auto} Master {/microblaze_0 (Cached)} Slave {/mig_0/S_AXI} ddr_seg {Auto} intc_ip {New AXI SmartConnect} master_apm {0}}  [get_bd_intf_pins mig_0/S_AXI]
  apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {reset ( FPGA Reset ) } Manual_Source {Auto}}  [get_bd_pins rst_mig_0_100M/ext_reset_in]
  # Create ports
  create_bd_port -dir O mmcm_lock
  create_bd_port -dir O init_calib_complete
  connect_bd_net [get_bd_ports mmcm_lock] [get_bd_pins mig_0/mmcm_locked]
  connect_bd_net [get_bd_ports init_calib_complete] [get_bd_pins mig_0/init_calib_complete]
}

# Configure Microblaze for Linux
set_property -dict [list CONFIG.G_TEMPLATE_LIST {4} CONFIG.G_USE_EXCEPTIONS {1} CONFIG.C_USE_MSR_INSTR {1} CONFIG.C_USE_PCMP_INSTR {1} CONFIG.C_USE_BARREL {1} CONFIG.C_USE_DIV {1} CONFIG.C_USE_HW_MUL {2} CONFIG.C_UNALIGNED_EXCEPTIONS {1} CONFIG.C_ILL_OPCODE_EXCEPTION {1} CONFIG.C_M_AXI_I_BUS_EXCEPTION {1} CONFIG.C_M_AXI_D_BUS_EXCEPTION {1} CONFIG.C_DIV_ZERO_EXCEPTION {1} CONFIG.C_PVR {2} CONFIG.C_OPCODE_0x0_ILLEGAL {1} CONFIG.C_ICACHE_LINE_LEN {8} CONFIG.C_ICACHE_VICTIMS {8} CONFIG.C_ICACHE_STREAMS {1} CONFIG.C_DCACHE_VICTIMS {8} CONFIG.C_USE_MMU {3} CONFIG.C_MMU_ZONES {2}] [get_bd_cells microblaze_0]

# Reset for AXI PCIe blocks (IP reset is active low, but board reset is active high, so we use an inverter)
create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic reset_invert
set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {not} CONFIG.LOGO_FILE {data/sym_notgate.png}] [get_bd_cells reset_invert]
connect_bd_net [get_bd_ports reset] [get_bd_pins reset_invert/Op1]
set system_rst [get_bd_pins reset_invert/Res]

# For each SSD (maximum of 2)
set reset_index 0
for {set i 0} {$i < [llength $num_lanes]} {incr i} {
  # Name of the AXI PCIe IP
  set ip_name "axi_pcie_$i"
  # Index of the M0?_ARESETN input of the microblaze_0_axi_periph for the AXI PCIe S_AXI_CTL interface
  incr reset_index 2
  
  # Create the AXI PCIe IP
  create_bd_cell -type ip -vlnv xilinx.com:ip:${pcie_ip} $ip_name
  
  # Add the AXI PCIe interrupt to the list of interrupts
  append ints "$ip_name/interrupt_out "
  
  # Configure AXI PCIe IP
  if {$pcie_ip == "axi_pcie"} {
    set_property -dict [list CONFIG.INCLUDE_RC {Root_Port_of_PCI_Express_Root_Complex} \
    CONFIG.NO_OF_LANES [lindex $num_lanes $i] \
    CONFIG.MAX_LINK_SPEED {5.0_GT/s} \
    CONFIG.DEVICE_ID {0x7014} \
    CONFIG.CLASS_CODE {0x060400} \
    CONFIG.BAR0_SCALE {Gigabytes} \
    CONFIG.BAR_64BIT {true} \
    CONFIG.BAR0_SIZE {4} \
    CONFIG.XLNX_REF_BOARD $xlnx_ref_board \
    CONFIG.rp_bar_hide {true} \
    CONFIG.BASE_CLASS_MENU {Bridge_device} \
    CONFIG.SUB_CLASS_INTERFACE_MENU {InfiniBand_to_PCI_host_bridge} \
    CONFIG.BASEADDR [lindex $baddr $i] \
    CONFIG.HIGHADDR [lindex $haddr $i] \
    CONFIG.S_AXI_DATA_WIDTH {128} \
    CONFIG.M_AXI_DATA_WIDTH {128}] [get_bd_cells $ip_name]

    apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master "/$ip_name/axi_aclk_out (62 MHz)" Clk_slave {/mig_0/ui_clk (200 MHz)} Clk_xbar {/mig_0/ui_clk (200 MHz)} Master "/$ip_name/M_AXI" Slave {/mig_0/S_AXI} ddr_seg {Auto} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins $ip_name/M_AXI]
    apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/mig_0/ui_addn_clk_0 (100 MHz)} Clk_slave "/$ip_name/axi_aclk_out (62 MHz)" Clk_xbar {/mig_0/ui_clk (200 MHz)} Master {/microblaze_0 (Periph)} Slave "/$ip_name/S_AXI" ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins $ip_name/S_AXI]
    apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/mig_0/ui_addn_clk_0 (100 MHz)} Clk_slave "/$ip_name/axi_ctl_aclk_out (62 MHz)" Clk_xbar {/mig_0/ui_clk (200 MHz)} Master {/microblaze_0 (Periph)} Slave "/$ip_name/S_AXI_CTL" ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins $ip_name/S_AXI_CTL]

  } elseif {$board_name == "kcu105"} {
    ############################################################
    # Configure AXI Bridge for PCIe Gen3 Subsystem IP
    ############################################################
    # Notes:
    # (1) The high speed PCIe traces on the FPGA Drive FMC are very
    #    short, so there is very low signal loss between the FPGA
    #    and the SSD. For this reason, it is best to use the
    #    "Chip-to-Chip" loss profile in the "GT Settings" (the
    #    default is "Add-on card"). Also, the "Chip-to-Chip"
    #    profile is the only one that disables the DFE, a feature
    #    that is better suited for longer and more lossy traces.
    #    
    # PCIe AXI CTRL interface base address (BASEADDR and HIGHADDR) needs to be manually set since Vivado 2017.1
    # See https://forums.xilinx.com/t5/Embedded-Linux/Vivado-2017-1-not-setting-correct-BASEADDR-for-AXI-Bridge-for/m-p/769279#M19963
    set_property -dict [list CONFIG.AXIBAR_NUM {1} \
    CONFIG.BASEADDR [lindex $baddr $i] \
    CONFIG.HIGHADDR [lindex $haddr $i] \
    CONFIG.device_port_type {Root_Port_of_PCI_Express_Root_Complex} \
    CONFIG.mode_selection {Advanced} \
    CONFIG.pcie_blk_locn [lindex $pcie_loc $i] \
    CONFIG.pl_link_cap_max_link_width [lindex $num_lanes $i] \
    CONFIG.sys_reset_polarity {ACTIVE_LOW} \
    CONFIG.pf0_link_status_slot_clock_config {true} \
    CONFIG.ins_loss_profile {Chip-to-Chip} \
    CONFIG.pl_link_cap_max_link_speed {8.0_GT/s} \
    CONFIG.coreclk_freq {250} \
    CONFIG.plltype {QPLL1} \
    CONFIG.axisten_freq {125} \
    CONFIG.dedicate_perst {false} \
    CONFIG.pf0_device_id {8134} \
    CONFIG.INS_LOSS_NYQ {5} \
    CONFIG.pf0_base_class_menu {Bridge_device} \
    CONFIG.pf0_class_code_base {06} \
    CONFIG.pf0_Use_Class_Code_Lookup_Assistant {false} \
    CONFIG.pf0_sub_class_interface_menu {PCI_to_PCI_bridge} \
    CONFIG.pf0_class_code_sub {04} \
    CONFIG.pf0_bar0_enabled {false} \
    CONFIG.pf0_bar0_64bit {false} \
    CONFIG.axibar2pciebar_0 [lindex $axi2pci $i] \
    CONFIG.pf0_class_code {060400}] [get_bd_cells $ip_name]

    # Use connection automation after configuration of the PCIe block - so it will assign 256MB to the S_AXI_CTL interface
    apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master "/$ip_name/axi_aclk (125 MHz)" Clk_slave {/ddr4_0/c0_ddr4_ui_clk (300 MHz)} Clk_xbar {/ddr4_0/addn_ui_clkout1 (100 MHz)} Master "/$ip_name/M_AXI" Slave {/ddr4_0/C0_DDR4_S_AXI} ddr_seg {Auto} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins $ip_name/M_AXI]
    apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/ddr4_0/addn_ui_clkout1 (100 MHz)} Clk_slave "/$ip_name/axi_aclk (125 MHz)" Clk_xbar {/ddr4_0/addn_ui_clkout1 (100 MHz)} Master {/microblaze_0 (Periph)} Slave "/$ip_name/S_AXI" ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins $ip_name/S_AXI]
    apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/ddr4_0/addn_ui_clkout1 (100 MHz)} Clk_slave "/$ip_name/axi_aclk (125 MHz)" Clk_xbar {/ddr4_0/addn_ui_clkout1 (100 MHz)} Master {/microblaze_0 (Periph)} Slave "/$ip_name/S_AXI_CTL" ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins $ip_name/S_AXI_CTL]
    
  } elseif {$pcie_ip == "xdma"} {
    set_property -dict [list CONFIG.functional_mode {AXI_Bridge} \
    CONFIG.mode_selection {Advanced} \
    CONFIG.device_port_type {Root_Port_of_PCI_Express_Root_Complex} \
    CONFIG.pl_link_cap_max_link_width {X4} \
    CONFIG.pl_link_cap_max_link_speed {8.0_GT/s} \
    CONFIG.axi_addr_width {49} \
    CONFIG.axi_data_width {256_bit} \
    CONFIG.axisten_freq {125} \
    CONFIG.dedicate_perst {false} \
    CONFIG.sys_reset_polarity {ACTIVE_LOW} \
    CONFIG.pf0_base_class_menu {Bridge_device} \
    CONFIG.pf0_class_code_base {06} \
    CONFIG.pf0_sub_class_interface_menu {PCI_to_PCI_bridge} \
    CONFIG.pf0_class_code_sub {04} \
    CONFIG.pf0_class_code_interface {00} \
    CONFIG.pf0_class_code {060400} \
    CONFIG.xdma_axilite_slave {true} \
    CONFIG.pcie_blk_locn [lindex $pcie_loc $i] \
    CONFIG.en_gt_selection {true} \
    CONFIG.select_quad [lindex $select_quad $i] \
    CONFIG.INS_LOSS_NYQ {5} \
    CONFIG.plltype {QPLL1} \
    CONFIG.ins_loss_profile {Chip-to-Chip} \
    CONFIG.type1_membase_memlimit_enable {Enabled} \
    CONFIG.type1_prefetchable_membase_memlimit {64bit_Enabled} \
    CONFIG.axibar_num {1} \
    CONFIG.axibar2pciebar_0 [lindex $axi2pci $i] \
    CONFIG.BASEADDR [lindex $baddr $i] \
    CONFIG.HIGHADDR [lindex $haddr $i] \
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
    CONFIG.pf3_class_code_mqdma {068000}] [get_bd_cells $ip_name]
    
    # Answer record 71106: Zynq Ultrascale+ MPSoC - PL PCIe Root Port Bridge (Vivado 2018.1)
    # - MSI Interrupt handling causes downstream devices to time out
    # https://www.xilinx.com/support/answers/71106.html
    set_property -dict [list CONFIG.msi_rx_pin_en {true}] [get_bd_cells $ip_name]

    # Use connection automation after configuration of the PCIe block - so it will assign 512MB to the S_AXI_CTL interfaces
    apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/$ip_name/axi_aclk (250 MHz)} Clk_slave {/ddr4_0/c0_ddr4_ui_clk (300 MHz)} Clk_xbar {/ddr4_0/addn_ui_clkout1 (100 MHz)} Master {/$ip_name/M_AXI_B} Slave {/ddr4_0/C0_DDR4_S_AXI} ddr_seg {Auto} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins $ip_name/M_AXI_B]
    apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/ddr4_0/addn_ui_clkout1 (100 MHz)} Clk_slave {/$ip_name/axi_aclk (250 MHz)} Clk_xbar {/ddr4_0/addn_ui_clkout1 (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/$ip_name/S_AXI_B} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins $ip_name/S_AXI_B]
    apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/ddr4_0/addn_ui_clkout1 (100 MHz)} Clk_slave {/$ip_name/axi_aclk (250 MHz)} Clk_xbar {/ddr4_0/addn_ui_clkout1 (100 MHz)} Master {/microblaze_0 (Periph)} Slave {/$ip_name/S_AXI_LITE} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins $ip_name/S_AXI_LITE]
    
    # Interrupts MSI
    append ints "$ip_name/interrupt_out_msi_vec0to31 "
    append ints "$ip_name/interrupt_out_msi_vec32to63 "
  } else {
    ################################################################################################
    # Notes on 2020.2 update:
    ################################################################################################
    # * The following properties of the AXI PCIe3 block are not found in the "recustomize IP" wizard,
    #   but can still set them in Tcl:
    #     - CONFIG.pf0_link_status_slot_clock_config {true}
    #     - CONFIG.ins_loss_profile {Chip-to-Chip}
    #     - CONFIG.pf0_bar0_64bit {false}
    # * The default coreclk_freq is 500MHz and the AXI PCIe3 wizard doesn't allow you to change it
    #     - CONFIG.coreclk_freq {250}
    # * The CONFIG.axi_data_width is 256_bit for 4 lane designs, and 64_bit for 1 lane designs
    #   but the tools are selecting the right value depending on the number of lanes, so we don't 
    #   set it again here.
    
    set_property -dict [list CONFIG.AXIBAR_NUM {1} \
    CONFIG.BASEADDR [lindex $baddr $i] \
    CONFIG.HIGHADDR [lindex $haddr $i] \
    CONFIG.device_port_type {Root_Port_of_PCI_Express_Root_Complex} \
    CONFIG.mode_selection {Advanced} \
    CONFIG.pcie_blk_locn [lindex $pcie_loc $i] \
    CONFIG.pl_link_cap_max_link_width [lindex $num_lanes $i] \
    CONFIG.pf0_link_status_slot_clock_config {true} \
    CONFIG.ins_loss_profile {Chip-to-Chip} \
    CONFIG.pl_link_cap_max_link_speed {8.0_GT/s} \
    CONFIG.Shared_Logic_Both {true} \
    CONFIG.coreclk_freq {250} \
    CONFIG.plltype {QPLL1} \
    CONFIG.axisten_freq {125} \
    CONFIG.dedicate_perst {false} \
    CONFIG.pf0_device_id {7134} \
    CONFIG.pf0_base_class_menu {Bridge_device} \
    CONFIG.pf0_class_code_base {06} \
    CONFIG.pf0_Use_Class_Code_Lookup_Assistant {false} \
    CONFIG.pf0_sub_class_interface_menu {PCI_to_PCI_bridge} \
    CONFIG.pf0_class_code_sub {04} \
    CONFIG.pf0_bar0_enabled {false} \
    CONFIG.pf0_bar0_64bit {false} \
    CONFIG.axibar2pciebar_0 [lindex $axi2pci $i] \
    CONFIG.pf0_class_code {060400}] [get_bd_cells $ip_name]

    apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master "/$ip_name/axi_aclk (125 MHz)" Clk_slave {/mig_0/ui_clk (200 MHz)} Clk_xbar {/mig_0/ui_clk (200 MHz)} Master "/$ip_name/M_AXI" Slave {/mig_0/S_AXI} ddr_seg {Auto} intc_ip {/axi_smc} master_apm {0}}  [get_bd_intf_pins $ip_name/M_AXI]
    apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/mig_0/ui_addn_clk_0 (100 MHz)} Clk_slave "/$ip_name/axi_aclk (125 MHz)" Clk_xbar {/mig_0/ui_clk (200 MHz)} Master {/microblaze_0 (Periph)} Slave "/$ip_name/S_AXI" ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins $ip_name/S_AXI]
    apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/mig_0/ui_addn_clk_0 (100 MHz)} Clk_slave "/$ip_name/axi_aclk (125 MHz)" Clk_xbar {/mig_0/ui_clk (200 MHz)} Master {/microblaze_0 (Periph)} Slave "/$ip_name/S_AXI_CTL" ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins $ip_name/S_AXI_CTL]
  }
  
  # Set BAR0 offset and size - we first set it to a small size to ensure that we can change the offset without
  # causing any conflict in the memory map, then once it's placed we set the size that we need
  set_property range 1M [get_bd_addr_segs "microblaze_0/Data/SEG_${ip_name}_BAR0"]
  set_property offset [lindex $axi2pci $i] [get_bd_addr_segs "microblaze_0/Data/SEG_${ip_name}_BAR0"]
  set_property range [lindex $barsize $i] [get_bd_addr_segs "microblaze_0/Data/SEG_${ip_name}_BAR0"]
  
  # Add MGT external port for PCIe
  create_bd_intf_port -mode Master -vlnv xilinx.com:interface:pcie_7x_mgt_rtl:1.0 pci_exp_$i
  if {$board_name == "vcu118"} {
    connect_bd_intf_net [get_bd_intf_pins axi_pcie_$i/pcie_mgt] [get_bd_intf_ports pci_exp_$i]
  } else {
    connect_bd_intf_net [get_bd_intf_pins axi_pcie_$i/pcie_7x_mgt] [get_bd_intf_ports pci_exp_$i]
  }

  # Add Link up output port
  create_bd_port -dir O user_link_up_$i
  if {$board_name == "vcu118"} {
    connect_bd_net [get_bd_ports user_link_up_$i] [get_bd_pins axi_pcie_$i/user_lnk_up]
  } else {
    connect_bd_net [get_bd_ports user_link_up_$i] [get_bd_pins axi_pcie_$i/user_link_up]
  }

  # Add differential buffer for the 100MHz PCIe reference clock
  create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf ref_clk_buf_$i
  set_property -dict [list CONFIG.C_BUF_TYPE {IBUFDSGTE}] [get_bd_cells ref_clk_buf_$i]
  create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 ref_clk_$i
  connect_bd_intf_net [get_bd_intf_pins ref_clk_buf_$i/CLK_IN_D] [get_bd_intf_ports ref_clk_$i]
  if {$pcie_ip == "axi_pcie"} {
    connect_bd_net [get_bd_pins ref_clk_buf_$i/IBUF_OUT] [get_bd_pins axi_pcie_$i/REFCLK]
  # Ultrascale designs
  # refclk and sys_clk_gt connected as per page 10 of AXI Bridge PCIe Gen3 Product guide
  # http://www.xilinx.com/support/documentation/ip_documentation/axi_pcie3/v2_0/pg194-axi-bridge-pcie-gen3.pdf
  } elseif {$board_name == "kcu105"} {
    connect_bd_net [get_bd_pins ref_clk_buf_$i/IBUF_DS_ODIV2] [get_bd_pins axi_pcie_$i/refclk]
    connect_bd_net [get_bd_pins ref_clk_buf_$i/IBUF_OUT] [get_bd_pins axi_pcie_$i/sys_clk_gt]
  } elseif {$board_name == "vcu118"} {
    connect_bd_net [get_bd_pins ref_clk_buf_$i/IBUF_DS_ODIV2] [get_bd_pins axi_pcie_$i/sys_clk]
    connect_bd_net [get_bd_pins ref_clk_buf_$i/IBUF_OUT] [get_bd_pins axi_pcie_$i/sys_clk_gt]
  } else {
    connect_bd_net [get_bd_pins ref_clk_buf_$i/IBUF_OUT] [get_bd_pins axi_pcie_$i/refclk]
  }

  # Connect PCIe core resets
  if {$pcie_ip == "axi_pcie"} {
    connect_bd_net $system_rst [get_bd_pins axi_pcie_$i/axi_aresetn]
    # Automation will create proc system reset rst_axi_pcie_0_125M and use the peripheral_aresetn to drive
    # axi_mem_intercon and microblaze_0_axi_periph ARESETN for all 3 AXI PCIe interfaces: M_AXI, S_AXI and S_AXI_CTL
    # We created another proc system reset for the axi_ctl_aclk_out clock and use its output to drive the ARESETN 
    # of the S_AXI_CTL interface
    connect_bd_net $system_rst [get_bd_pins rst_axi_pcie_${i}_125M/ext_reset_in]
    connect_bd_net [get_bd_pins axi_pcie_$i/mmcm_lock] [get_bd_pins rst_axi_pcie_${i}_125M/dcm_locked]
    # Add proc system reset to drive M0X_ARESETN
    create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_pcie_axi_ctl_aclk_$i
    connect_bd_net [get_bd_pins axi_pcie_$i/axi_ctl_aclk_out] [get_bd_pins rst_pcie_axi_ctl_aclk_$i/slowest_sync_clk]
    connect_bd_net $system_rst [get_bd_pins rst_pcie_axi_ctl_aclk_$i/ext_reset_in]
    connect_bd_net [get_bd_pins axi_pcie_$i/mmcm_lock] [get_bd_pins rst_pcie_axi_ctl_aclk_$i/dcm_locked]
    # Disconnect M0X_ARESETN and connect the correct one
    disconnect_bd_net /rst_axi_pcie_${i}_125M_peripheral_aresetn [get_bd_pins microblaze_0_axi_periph/M0${reset_index}_ARESETN]
    connect_bd_net [get_bd_pins rst_pcie_axi_ctl_aclk_$i/peripheral_aresetn] [get_bd_pins microblaze_0_axi_periph/M0${reset_index}_ARESETN]
    
  } else {
    connect_bd_net $system_rst [get_bd_pins axi_pcie_$i/sys_rst_n]
    # Automation will connect ARESETN of the S_AXI_CTL interface to the wrong reset signal (axi_aresetn)
    # so we need to disconnect it and connect it to the correct one: axi_ctl_aresetn
    disconnect_bd_net /axi_pcie_${i}_axi_aresetn [get_bd_pins microblaze_0_axi_periph/M0${reset_index}_ARESETN]
    connect_bd_net [get_bd_pins axi_pcie_$i/axi_ctl_aresetn] [get_bd_pins microblaze_0_axi_periph/M0${reset_index}_ARESETN]
  }

  # Create PERST output port
  create_bd_port -dir O -from 0 -to 0 -type rst perst_$i
  if {$pcie_ip == "axi_pcie"} {
    # Use proc system reset we created earlier to drive PERST
    connect_bd_net [get_bd_pins /rst_pcie_axi_ctl_aclk_$i/peripheral_reset] [get_bd_ports perst_$i]
  } else {
    # Add proc system reset to drive PERST
    create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_pcie_axi_aclk_$i
    connect_bd_net [get_bd_pins axi_pcie_$i/axi_aclk] [get_bd_pins rst_pcie_axi_aclk_$i/slowest_sync_clk]
    connect_bd_net [get_bd_pins axi_pcie_$i/axi_ctl_aresetn] [get_bd_pins rst_pcie_axi_aclk_$i/ext_reset_in]
    connect_bd_net [get_bd_pins /rst_pcie_axi_aclk_$i/peripheral_reset] [get_bd_ports perst_$i]
  }
}

# Constant LOW to enable 3.3V power supply of SSD2 and clock source (dual designs only)
if {[llength $num_lanes] > 1} {
  set const_dis_ssd2_pwr [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_dis_ssd2_pwr ]
  set_property -dict [list CONFIG.CONST_VAL {0}] $const_dis_ssd2_pwr
  create_bd_port -dir O disable_ssd2_pwr
  connect_bd_net [get_bd_pins const_dis_ssd2_pwr/dout] [get_bd_ports disable_ssd2_pwr]
}

# Add UART
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uart16550 axi_uart16550_0
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/microblaze_0 (Periph)} Slave {/axi_uart16550_0/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_uart16550_0/S_AXI]
apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {rs232_uart ( UART ) } Manual_Source {Auto}}  [get_bd_intf_pins axi_uart16550_0/UART]
append ints "axi_uart16550_0/ip2intc_irpt "

# Add Timer
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_timer axi_timer_0
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/microblaze_0 (Periph)} Slave {/axi_timer_0/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_timer_0/S_AXI]
append ints "axi_timer_0/interrupt "

# Add IIC
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic iic_main
apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {iic_main ( IIC ) } Manual_Source {Auto}}  [get_bd_intf_pins iic_main/IIC]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/microblaze_0 (Periph)} Slave {/iic_main/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins iic_main/S_AXI]
append ints "iic_main/iic2intc_irpt "

# Ethernet for VC707, VC709 and KCU105 boards use AXI Ethernet SGMII
# We are not adding Ethernet to these designs because AXI Ethernet Subsystem requires a licence,
# but if you would like to use Ethernet, just uncomment the following code block
if 0 {
  if {$board_name == "vc707" || $board_name == "vc709" || $board_name == "kcu105"} {
    create_bd_cell -type ip -vlnv xilinx.com:ip:axi_ethernet axi_ethernet_0
    if {$board_name == "kcu105"} {
      create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma axi_ethernet_0_dma
      connect_bd_intf_net [get_bd_intf_pins axi_ethernet_0_dma/M_AXIS_MM2S] [get_bd_intf_pins axi_ethernet_0/s_axis_txd]
      connect_bd_intf_net [get_bd_intf_pins axi_ethernet_0_dma/M_AXIS_CNTRL] [get_bd_intf_pins axi_ethernet_0/s_axis_txc]
      connect_bd_intf_net [get_bd_intf_pins axi_ethernet_0/m_axis_rxd] [get_bd_intf_pins axi_ethernet_0_dma/S_AXIS_S2MM]
      connect_bd_intf_net [get_bd_intf_pins axi_ethernet_0/m_axis_rxs] [get_bd_intf_pins axi_ethernet_0_dma/S_AXIS_STS]
      connect_bd_net [get_bd_pins axi_ethernet_0_dma/mm2s_prmry_reset_out_n] [get_bd_pins axi_ethernet_0/axi_txd_arstn]
      connect_bd_net [get_bd_pins axi_ethernet_0_dma/mm2s_cntrl_reset_out_n] [get_bd_pins axi_ethernet_0/axi_txc_arstn]
      connect_bd_net [get_bd_pins axi_ethernet_0_dma/s2mm_prmry_reset_out_n] [get_bd_pins axi_ethernet_0/axi_rxd_arstn]
      connect_bd_net [get_bd_pins axi_ethernet_0_dma/s2mm_sts_reset_out_n] [get_bd_pins axi_ethernet_0/axi_rxs_arstn]
      set_property -dict [list CONFIG.ETHERNET_BOARD_INTERFACE {sgmii_lvds} CONFIG.PHY_TYPE {SGMII} CONFIG.PHYRST_BOARD_INTERFACE {phy_reset_out} CONFIG.DIFFCLK_BOARD_INTERFACE {sgmii_phyclk} CONFIG.MDIO_BOARD_INTERFACE {mdio_mdc} CONFIG.ENABLE_LVDS {true} CONFIG.lvdsclkrate {625}] [get_bd_cells axi_ethernet_0]
      apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {sgmii_phyclk ( 625 MHz SGMII differential clock from Marvell PHY ) } Manual_Source {Auto}}  [get_bd_intf_pins axi_ethernet_0/lvds_clk]
      apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {mdio_mdc ( Onboard PHY ) } Manual_Source {Auto}}  [get_bd_intf_pins axi_ethernet_0/mdio]
      apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {phy_reset_out ( Onboard PHY ) } Manual_Source {Auto}}  [get_bd_pins axi_ethernet_0/phy_rst_n]
      apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {sgmii_lvds ( Onboard PHY ) } Manual_Source {Auto}}  [get_bd_intf_pins axi_ethernet_0/sgmii]
      # Clocks
      connect_bd_net [get_bd_pins $mig_ui_clk] [get_bd_pins axi_ethernet_0/axis_clk]
      # DMA config for Ethernet
      set_property -dict [list CONFIG.c_sg_length_width {16} CONFIG.c_include_mm2s_dre {1} CONFIG.c_sg_use_stsapp_length {1} CONFIG.c_include_s2mm_dre {1}] [get_bd_cells axi_ethernet_0_dma]
    } elseif {$board_name == "vc707"} {
      apply_bd_automation -rule xilinx.com:bd_rule:axi_ethernet -config { FIFO_DMA {DMA} PHY_TYPE {SGMII}}  [get_bd_cells axi_ethernet_0]
      # Clocks
      apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {sgmii_mgt_clk ( SGMII MGT clock ) } Manual_Source {Auto}}  [get_bd_intf_pins axi_ethernet_0/mgt_clk]
    } else {
      apply_bd_automation -rule xilinx.com:bd_rule:axi_ethernet -config { FIFO_DMA {DMA} PHY_TYPE {SGMII}}  [get_bd_cells axi_ethernet_0]
      make_bd_pins_external  [get_bd_pins axi_ethernet_0/phy_rst_n]
      # Clocks
      apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {sfp_mgt_clk ( SFP MGT clock ) } Manual_Source {Auto}}  [get_bd_intf_pins axi_ethernet_0/mgt_clk]
    }
    # Connection automation: AXI Lite and AXI Streaming interfaces
    apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/microblaze_0 (Periph)} Slave {/axi_ethernet_0/s_axi} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_ethernet_0/s_axi]
    apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config " Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/axi_ethernet_0_dma/M_AXI_MM2S} Slave $mig_slave_interface ddr_seg {Auto} intc_ip {/axi_smc} master_apm {0}"  [get_bd_intf_pins axi_ethernet_0_dma/M_AXI_MM2S]
    apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config " Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/axi_ethernet_0_dma/M_AXI_S2MM} Slave $mig_slave_interface ddr_seg {Auto} intc_ip {/axi_smc} master_apm {0}"  [get_bd_intf_pins axi_ethernet_0_dma/M_AXI_S2MM]
    apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config " Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/axi_ethernet_0_dma/M_AXI_SG} Slave $mig_slave_interface ddr_seg {Auto} intc_ip {/axi_smc} master_apm {0}"  [get_bd_intf_pins axi_ethernet_0_dma/M_AXI_SG]
    apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/microblaze_0 (Periph)} Slave {/axi_ethernet_0_dma/S_AXI_LITE} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_ethernet_0_dma/S_AXI_LITE]
    # Interrupts
    append ints "axi_ethernet_0/interrupt "
    append ints "axi_ethernet_0/mac_irq "
    append ints "axi_ethernet_0_dma/mm2s_introut "
    append ints "axi_ethernet_0_dma/s2mm_introut "
  }
}

# Ethernet for KC705 (AXI Ethernet Lite, no license required)
if {$board_name == "kc705"} {
  # KC705 uses AXI Ethernet Lite (smaller footprint, doesn't require license but only supports 100Mbps)
  create_bd_cell -type ip -vlnv xilinx.com:ip:axi_ethernetlite axi_ethernetlite
  apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {mdio_mdc ( Onboard PHY ) } Manual_Source {Auto}}  [get_bd_intf_pins axi_ethernetlite/MDIO]
  apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {mii ( Onboard PHY ) } Manual_Source {Auto}}  [get_bd_intf_pins axi_ethernetlite/MII]
  apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/microblaze_0 (Periph)} Slave {/axi_ethernetlite/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_ethernetlite/S_AXI]
  append ints "axi_ethernetlite/ip2intc_irpt "
}

# Reset GPIO
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio reset_gpio
set_property -dict [list CONFIG.C_GPIO_WIDTH {1} CONFIG.C_ALL_OUTPUTS {1}] [get_bd_cells reset_gpio]
set_property -dict [list CONFIG.C_AUX_RST_WIDTH {1} CONFIG.C_AUX_RESET_HIGH {1}] [get_bd_cells rst_${mig_name}_100M]
connect_bd_net [get_bd_pins reset_gpio/gpio_io_o] [get_bd_pins rst_${mig_name}_100M/aux_reset_in]
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/microblaze_0 (Periph)} Slave {/reset_gpio/S_AXI} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins reset_gpio/S_AXI]

# Add AXI QSPI for KCU105 board
if {$board_name == "kcu105"} {
  create_bd_cell -type ip -vlnv xilinx.com:ip:axi_quad_spi axi_quad_spi_0
  set_property -dict [list CONFIG.C_SPI_MEMORY {2} CONFIG.C_USE_STARTUP {1} CONFIG.C_USE_STARTUP_INT {1} CONFIG.C_SPI_MODE {2} CONFIG.C_DUAL_QUAD_MODE {1} CONFIG.C_NUM_SS_BITS {2} CONFIG.C_SCK_RATIO {2} CONFIG.C_FIFO_DEPTH {256} CONFIG.QSPI_BOARD_INTERFACE {spi_flash}] [get_bd_cells axi_quad_spi_0]
  apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/microblaze_0 (Periph)} Slave {/axi_quad_spi_0/AXI_LITE} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_quad_spi_0/AXI_LITE]
  apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {spi_flash ( QSPI flash ) } Manual_Source {Auto}}  [get_bd_intf_pins axi_quad_spi_0/SPI_1]
  connect_bd_net [get_bd_pins axi_quad_spi_0/ext_spi_clk] [get_bd_pins ddr4_0/addn_ui_clkout2]
  append ints "axi_quad_spi_0/ip2intc_irpt "
} elseif {$board_name == "vcu118"} {
  create_bd_cell -type ip -vlnv xilinx.com:ip:axi_quad_spi axi_quad_spi_0
  set_property -dict [list CONFIG.QSPI_BOARD_INTERFACE {spi_flash} CONFIG.USE_BOARD_FLOW {true}] [get_bd_cells axi_quad_spi_0]
  apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/microblaze_0 (Periph)} Slave {/axi_quad_spi_0/AXI_LITE} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_quad_spi_0/AXI_LITE]
  apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {spi_flash ( QSPI flash ) } Manual_Source {Auto}}  [get_bd_intf_pins axi_quad_spi_0/SPI_1]
  connect_bd_net [get_bd_pins axi_quad_spi_0/ext_spi_clk] [get_bd_pins ddr4_0/addn_ui_clkout2]
  append ints "axi_quad_spi_0/ip2intc_irpt "
# Add linear flash on Series-7 boards
} else {
  create_bd_cell -type ip -vlnv xilinx.com:ip:axi_emc axi_emc_0
  connect_bd_net [get_bd_pins mig_0/ui_addn_clk_0] [get_bd_pins axi_emc_0/s_axi_aclk]
  connect_bd_net [get_bd_pins mig_0/ui_addn_clk_0] [get_bd_pins axi_emc_0/rdclk]
  connect_bd_net [get_bd_pins rst_mig_0_100M/peripheral_aresetn] [get_bd_pins axi_emc_0/s_axi_aresetn]
  if {$board_name == "kc705"} {
    # Configure BPI flash
    set_property -dict [list CONFIG.USE_BOARD_FLOW {true} \
    CONFIG.EMC_BOARD_INTERFACE {linear_flash} \
    CONFIG.C_MEM0_TYPE {2} \
    CONFIG.C_S_AXI_MEM_ID_WIDTH.VALUE_SRC {USER} \
    CONFIG.C_S_AXI_MEM_ID_WIDTH {0} \
    CONFIG.C_WR_REC_TIME_MEM_0 {0} \
    CONFIG.C_TLZWE_PS_MEM_0 {0} \
    CONFIG.C_TWPH_PS_MEM_0 {20000} \
    CONFIG.C_TWP_PS_MEM_0 {50000} \
    CONFIG.C_TWC_PS_MEM_0 {19000} \
    CONFIG.C_THZOE_PS_MEM_0 {15000} \
    CONFIG.C_THZCE_PS_MEM_0 {20000} \
    CONFIG.C_TPACC_PS_FLASH_0 {25000} \
    CONFIG.C_TAVDV_PS_MEM_0 {100000} \
    CONFIG.C_TCEDV_PS_MEM_0 {100000}] [get_bd_cells axi_emc_0]
  }
  apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {linear_flash ( Linear flash ) } Manual_Source {Auto}}  [get_bd_intf_pins axi_emc_0/EMC_INTF]
  apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {Auto} Clk_slave {Auto} Clk_xbar {Auto} Master {/microblaze_0 (Periph)} Slave {/axi_emc_0/S_AXI_MEM} ddr_seg {Auto} intc_ip {/microblaze_0_axi_periph} master_apm {0}}  [get_bd_intf_pins axi_emc_0/S_AXI_MEM]
  if {$board_name == "kc705"} {
    set_property range 128M [get_bd_addr_segs {microblaze_0/Data/SEG_axi_emc_0_Mem0}]
  }
}

# Configure Microblaze interrupt concat
set num_ints [llength $ints]
set_property -dict [list CONFIG.NUM_PORTS $num_ints] [get_bd_cells microblaze_0_xlconcat]
set input_index -1
foreach interrupt_pin $ints {
  incr input_index
  connect_bd_net [get_bd_pins ${interrupt_pin}] [get_bd_pins microblaze_0_xlconcat/In${input_index}]
}

# Restore current instance
current_bd_instance $oldCurInst

save_bd_design


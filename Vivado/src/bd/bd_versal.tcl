################################################################
# Block design build script for Versal designs
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

# Returns true if str contains substr
proc str_contains {str substr} {
  if {[string first $substr $str] == -1} {
    return 0
  } else {
    return 1
  }
}

# Board specific PCIe and GT LOCs
if {[str_contains $target "vck190"]} {
  set pcie_blk_locn { "X1Y0" "X1Y2" }
  set ref_board "VCK190"
} elseif {[str_contains $target "vmk180"]} {
  set pcie_blk_locn { "X1Y0" "X1Y2" }
  set ref_board "VMK180"
}

# BAR addresses and sizes
set bar_addr { 0x000A8000000 0x000B0000000 }
set bar_size { 128M 256M }
set qdma_cfg_addr { 0x400000000 0x440000000 }

# List of interrupt pins
set intr_list {}

# Add the CIPS
create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips versal_cips_0

# Configure the CIPS using automation feature
apply_bd_automation -rule xilinx.com:bd_rule:cips -config { \
  board_preset {Yes} \
  boot_config {Custom} \
  configure_noc {Add new AXI NoC} \
  debug_config {JTAG} \
  design_flow {Full System} \
  mc_type {DDR} \
  num_mc_ddr {1} \
  num_mc_lpddr {None} \
  pl_clocks {None} \
  pl_resets {None} \
}  [get_bd_cells versal_cips_0]

# -----------------------------------------------------------------------------
# Remove DDR address region 1 from the design
# -----------------------------------------------------------------------------
# Having this address region in the design leads to the following errors on PetaLinux boot:
#   nvme nvme0: I/O 4 QID 0 timeout, disable controller
#   nvme nvme0: Device shutdown incomplete; abort shutdown
#   nvme nvme0: Identify Controller failed (-4)
#   nvme nvme0: Removing after probe failure status: -5
# Removing the region is the only available workaround at this time.
set_property CONFIG.MC_CHAN_REGION1 {NONE} [get_bd_cells axi_noc_0]
set_property -dict [list CONFIG.CONNECTIONS {MC_3 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /axi_noc_0/S00_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_2 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /axi_noc_0/S01_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_0 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /axi_noc_0/S02_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_1 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /axi_noc_0/S03_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_3 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /axi_noc_0/S04_AXI]
set_property -dict [list CONFIG.CONNECTIONS {MC_2 {read_bw {100} write_bw {100} read_avg_burst {4} write_avg_burst {4}}}] [get_bd_intf_pins /axi_noc_0/S05_AXI]

# Extra config for this design
set_property -dict [list \
  CONFIG.PS_PMC_CONFIG { DDR_MEMORY_MODE {Connectivity to DDR via NOC}  \
  DEBUG_MODE JTAG  DESIGN_MODE 1  \
  PMC_GPIO0_MIO_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 0 .. 25}}}  \
  PMC_GPIO1_MIO_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 26 .. 51}}}  \
  PMC_MIO37 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA high} {PULL pullup} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
  PMC_OSPI_PERIPHERAL {{ENABLE 0} {IO {PMC_MIO 0 .. 11}} {MODE Single}}  \
  PMC_QSPI_COHERENCY 0  PMC_QSPI_FBCLK {{ENABLE 1} {IO {PMC_MIO 6}}}  \
  PMC_QSPI_PERIPHERAL_DATA_MODE x4  \
  PMC_QSPI_PERIPHERAL_ENABLE 1  \
  PMC_QSPI_PERIPHERAL_MODE {Dual Parallel}  \
  PMC_REF_CLK_FREQMHZ 33.3333  \
  PMC_SD1 {{CD_ENABLE 1} {CD_IO {PMC_MIO 28}} {POW_ENABLE 1} {POW_IO {PMC_MIO 51}} {RESET_ENABLE 0} {RESET_IO {PMC_MIO 12}} {WP_ENABLE 0} {WP_IO {PMC_MIO 1}}}  \
  PMC_SD1_COHERENCY 0  \
  PMC_SD1_DATA_TRANSFER_MODE 8Bit  \
  PMC_SD1_PERIPHERAL {{CLK_100_SDR_OTAP_DLY 0x3} {CLK_200_SDR_OTAP_DLY 0x2} {CLK_50_DDR_ITAP_DLY 0x36} {CLK_50_DDR_OTAP_DLY 0x3} {CLK_50_SDR_ITAP_DLY 0x2C} {CLK_50_SDR_OTAP_DLY 0x4} {ENABLE 1} {IO {PMC_MIO 26 .. 36}}}  PMC_SD1_SLOT_TYPE {SD 3.0} \
  PMC_USE_PMC_NOC_AXI0 1  \
  PS_BOARD_INTERFACE ps_pmc_fixed_io  \
  PS_CAN1_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 40 .. 41}}}  \
  PS_ENET0_MDIO {{ENABLE 1} {IO {PS_MIO 24 .. 25}}}  \
  PS_ENET0_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 0 .. 11}}}  \
  PS_ENET1_PERIPHERAL {{ENABLE 1} {IO {PS_MIO 12 .. 23}}}  \
  PS_GEN_IPI0_ENABLE 1  \
  PS_GEN_IPI0_MASTER A72  \
  PS_GEN_IPI1_ENABLE 1  \
  PS_GEN_IPI2_ENABLE 1  \
  PS_GEN_IPI3_ENABLE 1  \
  PS_GEN_IPI4_ENABLE 1  \
  PS_GEN_IPI5_ENABLE 1  \
  PS_GEN_IPI6_ENABLE 1  \
  PS_HSDP_EGRESS_TRAFFIC JTAG  \
  PS_HSDP_INGRESS_TRAFFIC JTAG  \
  PS_HSDP_MODE None  \
  PS_I2C0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 46 .. 47}}}  \
  PS_I2C1_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 44 .. 45}}}  \
  PS_IRQ_USAGE {{CH0 1} {CH1 1} {CH10 0} {CH11 0} {CH12 0} {CH13 0} {CH14 0} {CH15 0} {CH2 1} {CH3 1} {CH4 1} {CH5 1} {CH6 0} {CH7 0} {CH8 0} {CH9 0}}  \
  PS_MIO19 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}}  \
  PS_MIO21 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}}  \
  PS_MIO7 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}}  \
  PS_MIO9 {{AUX_IO 0} {DIRECTION in} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL disable} {SCHMITT 0} {SLEW slow} {USAGE Reserved}}  \
  PS_M_AXI_FPD_DATA_WIDTH 128 \
  PS_M_AXI_LPD_DATA_WIDTH 128 \
  PS_NUM_FABRIC_RESETS 1  \
  PS_PCIE_RESET {{ENABLE 1}}  \
  PS_PL_CONNECTIVITY_MODE Custom  \
  PS_UART0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 42 .. 43}}}  \
  PS_USB3_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 13 .. 25}}}  \
  PS_USE_FPD_CCI_NOC 1  \
  PS_USE_FPD_CCI_NOC0 1  \
  PS_USE_M_AXI_FPD 1  \
  PS_USE_M_AXI_LPD 1  \
  PS_USE_NOC_LPD_AXI0 1  \
  PS_USE_PMCPL_CLK0 1  \
  PS_USE_PMCPL_CLK1 0  \
  PS_USE_PMCPL_CLK2 0  \
  PS_USE_PMCPL_CLK3 0  \
  SMON_ALARMS Set_Alarms_On  \
  SMON_ENABLE_TEMP_AVERAGING 0  \
  SMON_TEMP_AVERAGING_SAMPLES 0 \
  } \
  CONFIG.PS_PMC_CONFIG_APPLIED {1} \
  CONFIG.PS_PL_CONNECTIVITY_MODE {Custom} \
] [get_bd_cells versal_cips_0]

# QDMA support block
proc create_qdma_support { index } {

  global pcie_blk_locn
  set hier_obj [create_bd_cell -type hier qdma_support_$index]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_cq

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 m_axis_rc

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:pcie4_cfg_control_rtl:1.0 pcie_cfg_control

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:pcie_cfg_fc_rtl:1.1 pcie_cfg_fc

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:pcie3_cfg_interrupt_rtl:1.0 pcie_cfg_interrupt

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:pcie3_cfg_msg_received_rtl:1.0 pcie_cfg_mesg_rcvd

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:pcie3_cfg_mesg_tx_rtl:1.0 pcie_cfg_mesg_tx

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:pcie4_cfg_mgmt_rtl:1.0 pcie_cfg_mgmt

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:pcie4_cfg_status_rtl:1.0 pcie_cfg_status

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 pcie_mgt

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 pcie_refclk

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:pcie3_transmit_fc_rtl:1.0 pcie_transmit_fc

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_cc

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 s_axis_rq


  # Create pins
  create_bd_pin -dir O phy_rdy_out
  create_bd_pin -dir I -type rst sys_reset
  create_bd_pin -dir O -type clk user_clk
  create_bd_pin -dir O user_lnk_up
  create_bd_pin -dir O -type rst user_reset

  # Create instance: bufg_gt_sysclk, and set properties
  set bufg_gt_sysclk [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf bufg_gt_sysclk ]
  set_property -dict [ list \
   CONFIG.C_BUFG_GT_SYNC {true} \
   CONFIG.C_BUF_TYPE {BUFG_GT} \
 ] $bufg_gt_sysclk

  # Create instance: const_1b1, and set properties
  set const_1b1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_1b1 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {1} \
   CONFIG.CONST_WIDTH {1} \
 ] $const_1b1

  # Create instance: gt_quad_0, and set properties
  set gt_quad_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:gt_quad_base gt_quad_0 ]
  set_property -dict [ list \
   CONFIG.PORTS_INFO_DICT {\
     LANE_SEL_DICT {PROT0 {RX0 RX1 RX2 RX3 TX0 TX1 TX2 TX3}}\
     GT_TYPE {GTY}\
     REG_CONF_INTF {APB3_INTF}\
     BOARD_PARAMETER {}\
   } \
   CONFIG.REFCLK_STRING {\
HSCLK0_LCPLLGTREFCLK0 refclk_PROT0_R0_100_MHz_unique1 HSCLK0_RPLLGTREFCLK0\
refclk_PROT0_R0_100_MHz_unique1 HSCLK1_LCPLLGTREFCLK0\
refclk_PROT0_R0_100_MHz_unique1 HSCLK1_RPLLGTREFCLK0\
refclk_PROT0_R0_100_MHz_unique1} \
 ] $gt_quad_0

  # Create instance: pcie, and set properties
  global ref_board
  set pcie [ create_bd_cell -type ip -vlnv xilinx.com:ip:pcie_versal pcie ]
  set_property -dict [ list \
   CONFIG.AXISTEN_IF_CQ_ALIGNMENT_MODE {Address_Aligned} \
   CONFIG.AXISTEN_IF_RQ_ALIGNMENT_MODE {DWORD_Aligned} \
   CONFIG.MSI_X_OPTIONS {None} \
   CONFIG.PF0_DEVICE_ID {B0B4} \
   CONFIG.PF0_INTERRUPT_PIN {INTA} \
   CONFIG.PF0_LINK_STATUS_SLOT_CLOCK_CONFIG {true} \
   CONFIG.PF0_MSIX_CAP_PBA_BIR {BAR_1:0} \
   CONFIG.PF0_MSIX_CAP_PBA_OFFSET {00000000} \
   CONFIG.PF0_MSIX_CAP_TABLE_BIR {BAR_1:0} \
   CONFIG.PF0_MSIX_CAP_TABLE_OFFSET {00000000} \
   CONFIG.PF0_MSIX_CAP_TABLE_SIZE {000} \
   CONFIG.PF0_MSI_CAP_MULTIMSGCAP {1_vector} \
   CONFIG.PF0_REVISION_ID {00} \
   CONFIG.PF0_SRIOV_VF_DEVICE_ID {C034} \
   CONFIG.PF0_SUBSYSTEM_ID {0007} \
   CONFIG.PF0_SUBSYSTEM_VENDOR_ID {10EE} \
   CONFIG.PF1_DEVICE_ID {913F} \
   CONFIG.PF1_INTERRUPT_PIN {NONE} \
   CONFIG.PF1_MSIX_CAP_PBA_BIR {BAR_1:0} \
   CONFIG.PF1_MSIX_CAP_PBA_OFFSET {00000000} \
   CONFIG.PF1_MSIX_CAP_TABLE_BIR {BAR_1:0} \
   CONFIG.PF1_MSIX_CAP_TABLE_OFFSET {00000000} \
   CONFIG.PF1_MSIX_CAP_TABLE_SIZE {000} \
   CONFIG.PF1_MSI_CAP_MULTIMSGCAP {1_vector} \
   CONFIG.PF1_REVISION_ID {00} \
   CONFIG.PF1_SRIOV_VF_DEVICE_ID {C134} \
   CONFIG.PF1_SUBSYSTEM_ID {0007} \
   CONFIG.PF1_SUBSYSTEM_VENDOR_ID {10EE} \
   CONFIG.PF2_DEVICE_ID {B2B4} \
   CONFIG.PF2_INTERRUPT_PIN {NONE} \
   CONFIG.PF2_MSIX_CAP_PBA_BIR {BAR_1:0} \
   CONFIG.PF2_MSIX_CAP_PBA_OFFSET {00000000} \
   CONFIG.PF2_MSIX_CAP_TABLE_BIR {BAR_1:0} \
   CONFIG.PF2_MSIX_CAP_TABLE_OFFSET {00000000} \
   CONFIG.PF2_MSIX_CAP_TABLE_SIZE {000} \
   CONFIG.PF2_MSI_CAP_MULTIMSGCAP {1_vector} \
   CONFIG.PF2_REVISION_ID {00} \
   CONFIG.PF2_SRIOV_VF_DEVICE_ID {C234} \
   CONFIG.PF2_SUBSYSTEM_ID {0007} \
   CONFIG.PF2_SUBSYSTEM_VENDOR_ID {10EE} \
   CONFIG.PF3_DEVICE_ID {B3B4} \
   CONFIG.PF3_INTERRUPT_PIN {NONE} \
   CONFIG.PF3_MSIX_CAP_PBA_BIR {BAR_1:0} \
   CONFIG.PF3_MSIX_CAP_PBA_OFFSET {00000000} \
   CONFIG.PF3_MSIX_CAP_TABLE_BIR {BAR_1:0} \
   CONFIG.PF3_MSIX_CAP_TABLE_OFFSET {00000000} \
   CONFIG.PF3_MSIX_CAP_TABLE_SIZE {000} \
   CONFIG.PF3_MSI_CAP_MULTIMSGCAP {1_vector} \
   CONFIG.PF3_REVISION_ID {00} \
   CONFIG.PF3_SRIOV_VF_DEVICE_ID {C334} \
   CONFIG.PF3_SUBSYSTEM_ID {0007} \
   CONFIG.PF3_SUBSYSTEM_VENDOR_ID {10EE} \
   CONFIG.PL_LINK_CAP_MAX_LINK_SPEED {16.0_GT/s} \
   CONFIG.PL_LINK_CAP_MAX_LINK_WIDTH {X4} \
   CONFIG.REF_CLK_FREQ {100_MHz} \
   CONFIG.TL_PF_ENABLE_REG {1} \
   CONFIG.acs_ext_cap_enable {false} \
   CONFIG.axisten_freq {250} \
   CONFIG.axisten_if_enable_client_tag {true} \
   CONFIG.axisten_if_enable_msg_route_override {TRUE} \
   CONFIG.axisten_if_width {256_bit} \
   CONFIG.cfg_ext_if {false} \
   CONFIG.cfg_mgmt_if {true} \
   CONFIG.copy_pf0 {true} \
   CONFIG.coreclk_freq {500} \
   CONFIG.dedicate_perst {false} \
   CONFIG.device_port_type {Root_Port_of_PCI_Express_Root_Complex} \
   CONFIG.en_dbg_descramble {false} \
   CONFIG.en_ext_clk {FALSE} \
   CONFIG.en_l23_entry {false} \
   CONFIG.en_parity {false} \
   CONFIG.en_transceiver_status_ports {false} \
   CONFIG.enable_auto_rxeq {False} \
   CONFIG.enable_ccix {FALSE} \
   CONFIG.enable_code {0000} \
   CONFIG.enable_dvsec {FALSE} \
   CONFIG.enable_gen4 {true} \
   CONFIG.enable_ibert {false} \
   CONFIG.enable_jtag_dbg {false} \
   CONFIG.enable_more_clk {false} \
   CONFIG.ext_pcie_cfg_space_enabled {false} \
   CONFIG.ext_xvc_vsec_enable {false} \
   CONFIG.extended_tag_field {true} \
   CONFIG.insert_cips {false} \
   CONFIG.lane_order {Bottom} \
   CONFIG.legacy_ext_pcie_cfg_space_enabled {false} \
   CONFIG.mcap_enablement {None} \
   CONFIG.mode_selection {Advanced} \
   CONFIG.pcie_blk_locn [lindex $pcie_blk_locn $index] \
   CONFIG.pf0_ari_enabled {false} \
   CONFIG.pf0_bar0_64bit {true} \
   CONFIG.pf0_bar0_enabled {true} \
   CONFIG.pf0_bar0_prefetchable {true} \
   CONFIG.pf0_bar0_scale {Gigabytes} \
   CONFIG.pf0_bar0_size {4} \
   CONFIG.pf0_bar1_64bit {false} \
   CONFIG.pf0_bar1_enabled {false} \
   CONFIG.pf0_bar1_prefetchable {false} \
   CONFIG.pf0_bar1_scale {Kilobytes} \
   CONFIG.pf0_bar1_size {128} \
   CONFIG.pf0_bar2_64bit {false} \
   CONFIG.pf0_bar2_enabled {false} \
   CONFIG.pf0_bar2_prefetchable {false} \
   CONFIG.pf0_bar2_scale {Kilobytes} \
   CONFIG.pf0_bar2_size {128} \
   CONFIG.pf0_bar3_64bit {false} \
   CONFIG.pf0_bar3_enabled {false} \
   CONFIG.pf0_bar3_prefetchable {false} \
   CONFIG.pf0_bar3_scale {Kilobytes} \
   CONFIG.pf0_bar3_size {128} \
   CONFIG.pf0_bar4_64bit {false} \
   CONFIG.pf0_bar4_enabled {false} \
   CONFIG.pf0_bar4_prefetchable {false} \
   CONFIG.pf0_bar4_scale {Kilobytes} \
   CONFIG.pf0_bar4_size {128} \
   CONFIG.pf0_bar5_enabled {false} \
   CONFIG.pf0_bar5_prefetchable {false} \
   CONFIG.pf0_bar5_scale {Kilobytes} \
   CONFIG.pf0_bar5_size {128} \
   CONFIG.pf0_class_code_base {06} \
   CONFIG.pf0_class_code_interface {00} \
   CONFIG.pf0_class_code_sub {04} \
   CONFIG.pf0_expansion_rom_enabled {false} \
   CONFIG.pf0_msi_enabled {false} \
   CONFIG.pf0_msix_enabled {false} \
   CONFIG.pf1_bar0_64bit {true} \
   CONFIG.pf1_bar0_enabled {true} \
   CONFIG.pf1_bar0_prefetchable {true} \
   CONFIG.pf1_bar0_scale {Gigabytes} \
   CONFIG.pf1_bar0_size {4} \
   CONFIG.pf1_bar1_64bit {false} \
   CONFIG.pf1_bar1_enabled {false} \
   CONFIG.pf1_bar1_prefetchable {false} \
   CONFIG.pf1_bar1_scale {Kilobytes} \
   CONFIG.pf1_bar1_size {128} \
   CONFIG.pf1_bar2_64bit {false} \
   CONFIG.pf1_bar2_enabled {false} \
   CONFIG.pf1_bar2_prefetchable {false} \
   CONFIG.pf1_bar2_scale {Kilobytes} \
   CONFIG.pf1_bar2_size {128} \
   CONFIG.pf1_bar3_64bit {false} \
   CONFIG.pf1_bar3_enabled {false} \
   CONFIG.pf1_bar3_prefetchable {false} \
   CONFIG.pf1_bar3_scale {Kilobytes} \
   CONFIG.pf1_bar3_size {128} \
   CONFIG.pf1_bar4_64bit {false} \
   CONFIG.pf1_bar4_enabled {false} \
   CONFIG.pf1_bar4_prefetchable {false} \
   CONFIG.pf1_bar4_scale {Kilobytes} \
   CONFIG.pf1_bar4_size {128} \
   CONFIG.pf1_bar5_enabled {false} \
   CONFIG.pf1_bar5_prefetchable {false} \
   CONFIG.pf1_bar5_scale {Kilobytes} \
   CONFIG.pf1_bar5_size {128} \
   CONFIG.pf1_class_code_base {06} \
   CONFIG.pf1_class_code_interface {00} \
   CONFIG.pf1_class_code_sub {0A} \
   CONFIG.pf1_expansion_rom_enabled {false} \
   CONFIG.pf1_msi_enabled {false} \
   CONFIG.pf1_msix_enabled {false} \
   CONFIG.pf1_vendor_id {10EE} \
   CONFIG.pf2_bar0_64bit {true} \
   CONFIG.pf2_bar0_enabled {true} \
   CONFIG.pf2_bar0_prefetchable {true} \
   CONFIG.pf2_bar0_scale {Gigabytes} \
   CONFIG.pf2_bar0_size {4} \
   CONFIG.pf2_bar1_64bit {false} \
   CONFIG.pf2_bar1_enabled {false} \
   CONFIG.pf2_bar1_prefetchable {false} \
   CONFIG.pf2_bar1_scale {Kilobytes} \
   CONFIG.pf2_bar1_size {128} \
   CONFIG.pf2_bar2_64bit {false} \
   CONFIG.pf2_bar2_enabled {false} \
   CONFIG.pf2_bar2_prefetchable {false} \
   CONFIG.pf2_bar2_scale {Kilobytes} \
   CONFIG.pf2_bar2_size {128} \
   CONFIG.pf2_bar3_64bit {false} \
   CONFIG.pf2_bar3_enabled {false} \
   CONFIG.pf2_bar3_prefetchable {false} \
   CONFIG.pf2_bar3_scale {Kilobytes} \
   CONFIG.pf2_bar3_size {128} \
   CONFIG.pf2_bar4_64bit {false} \
   CONFIG.pf2_bar4_enabled {false} \
   CONFIG.pf2_bar4_prefetchable {false} \
   CONFIG.pf2_bar4_scale {Kilobytes} \
   CONFIG.pf2_bar4_size {128} \
   CONFIG.pf2_bar5_enabled {false} \
   CONFIG.pf2_bar5_prefetchable {false} \
   CONFIG.pf2_bar5_scale {Kilobytes} \
   CONFIG.pf2_bar5_size {128} \
   CONFIG.pf2_class_code_base {06} \
   CONFIG.pf2_class_code_interface {00} \
   CONFIG.pf2_class_code_sub {0A} \
   CONFIG.pf2_expansion_rom_enabled {false} \
   CONFIG.pf2_msi_enabled {false} \
   CONFIG.pf2_msix_enabled {false} \
   CONFIG.pf2_vendor_id {10EE} \
   CONFIG.pf3_bar0_64bit {true} \
   CONFIG.pf3_bar0_enabled {true} \
   CONFIG.pf3_bar0_prefetchable {true} \
   CONFIG.pf3_bar0_scale {Gigabytes} \
   CONFIG.pf3_bar0_size {4} \
   CONFIG.pf3_bar1_64bit {false} \
   CONFIG.pf3_bar1_enabled {false} \
   CONFIG.pf3_bar1_prefetchable {false} \
   CONFIG.pf3_bar1_scale {Kilobytes} \
   CONFIG.pf3_bar1_size {128} \
   CONFIG.pf3_bar2_64bit {false} \
   CONFIG.pf3_bar2_enabled {false} \
   CONFIG.pf3_bar2_prefetchable {false} \
   CONFIG.pf3_bar2_scale {Kilobytes} \
   CONFIG.pf3_bar2_size {128} \
   CONFIG.pf3_bar3_64bit {false} \
   CONFIG.pf3_bar3_enabled {false} \
   CONFIG.pf3_bar3_prefetchable {false} \
   CONFIG.pf3_bar3_scale {Kilobytes} \
   CONFIG.pf3_bar3_size {128} \
   CONFIG.pf3_bar4_64bit {false} \
   CONFIG.pf3_bar4_enabled {false} \
   CONFIG.pf3_bar4_prefetchable {false} \
   CONFIG.pf3_bar4_scale {Kilobytes} \
   CONFIG.pf3_bar4_size {128} \
   CONFIG.pf3_bar5_enabled {false} \
   CONFIG.pf3_bar5_prefetchable {false} \
   CONFIG.pf3_bar5_scale {Kilobytes} \
   CONFIG.pf3_bar5_size {128} \
   CONFIG.pf3_class_code_base {06} \
   CONFIG.pf3_class_code_interface {00} \
   CONFIG.pf3_class_code_sub {0A} \
   CONFIG.pf3_expansion_rom_enabled {false} \
   CONFIG.pf3_msi_enabled {false} \
   CONFIG.pf3_msix_enabled {false} \
   CONFIG.pf3_vendor_id {10EE} \
   CONFIG.pipe_line_stage {2} \
   CONFIG.pipe_sim {false} \
   CONFIG.sys_reset_polarity {ACTIVE_LOW} \
   CONFIG.vendor_id {10EE} \
   CONFIG.xlnx_ref_board $ref_board \
 ] $pcie

  # Create instance: pcie_phy, and set properties
  set pcie_phy [ create_bd_cell -type ip -vlnv xilinx.com:ip:pcie_phy_versal pcie_phy ]
  set_property -dict [ list \
   CONFIG.PL_LINK_CAP_MAX_LINK_SPEED {16.0_GT/s} \
   CONFIG.PL_LINK_CAP_MAX_LINK_WIDTH {X4} \
   CONFIG.aspm {No_ASPM} \
   CONFIG.async_mode {SRNS} \
   CONFIG.disable_double_pipe {YES} \
   CONFIG.en_gt_pclk {false} \
   CONFIG.ins_loss_profile {Add-in_Card} \
   CONFIG.lane_order {Bottom} \
   CONFIG.lane_reversal {false} \
   CONFIG.phy_async_en {true} \
   CONFIG.phy_coreclk_freq {500_MHz} \
   CONFIG.phy_refclk_freq {100_MHz} \
   CONFIG.phy_userclk_freq {250_MHz} \
   CONFIG.pipeline_stages {2} \
   CONFIG.sim_model {NO} \
   CONFIG.tx_preset {4} \
 ] $pcie_phy

  # Create instance: refclk_ibuf, and set properties
  set refclk_ibuf [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf refclk_ibuf ]
  set_property -dict [ list \
   CONFIG.C_BUF_TYPE {IBUFDSGTE} \
 ] $refclk_ibuf

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins pcie_refclk] [get_bd_intf_pins refclk_ibuf/CLK_IN_D]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins pcie_mgt] [get_bd_intf_pins pcie_phy/pcie_mgt]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins m_axis_cq] [get_bd_intf_pins pcie/m_axis_cq]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins m_axis_rc] [get_bd_intf_pins pcie/m_axis_rc]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins pcie_cfg_fc] [get_bd_intf_pins pcie/pcie_cfg_fc]
  connect_bd_intf_net -intf_net Conn6 [get_bd_intf_pins pcie_cfg_interrupt] [get_bd_intf_pins pcie/pcie_cfg_interrupt]
  connect_bd_intf_net -intf_net Conn7 [get_bd_intf_pins pcie_cfg_mesg_rcvd] [get_bd_intf_pins pcie/pcie_cfg_mesg_rcvd]
  connect_bd_intf_net -intf_net Conn8 [get_bd_intf_pins pcie_cfg_mesg_tx] [get_bd_intf_pins pcie/pcie_cfg_mesg_tx]
  connect_bd_intf_net -intf_net Conn9 [get_bd_intf_pins s_axis_cc] [get_bd_intf_pins pcie/s_axis_cc]
  connect_bd_intf_net -intf_net Conn10 [get_bd_intf_pins s_axis_rq] [get_bd_intf_pins pcie/s_axis_rq]
  connect_bd_intf_net -intf_net Conn11 [get_bd_intf_pins pcie_cfg_control] [get_bd_intf_pins pcie/pcie_cfg_control]
  connect_bd_intf_net -intf_net Conn12 [get_bd_intf_pins pcie_cfg_mgmt] [get_bd_intf_pins pcie/pcie_cfg_mgmt]
  connect_bd_intf_net -intf_net Conn13 [get_bd_intf_pins pcie_cfg_status] [get_bd_intf_pins pcie/pcie_cfg_status]
  connect_bd_intf_net -intf_net Conn14 [get_bd_intf_pins pcie_transmit_fc] [get_bd_intf_pins pcie/pcie_transmit_fc]
  connect_bd_intf_net -intf_net gt_quad_0_GT0_BUFGT [get_bd_intf_pins gt_quad_0/GT0_BUFGT] [get_bd_intf_pins pcie_phy/GT_BUFGT]
  connect_bd_intf_net -intf_net gt_quad_0_GT_Serial [get_bd_intf_pins gt_quad_0/GT_Serial] [get_bd_intf_pins pcie_phy/GT0_Serial]
  connect_bd_intf_net -intf_net pcie_phy_GT_RX0 [get_bd_intf_pins gt_quad_0/RX0_GT_IP_Interface] [get_bd_intf_pins pcie_phy/GT_RX0]
  connect_bd_intf_net -intf_net pcie_phy_GT_RX1 [get_bd_intf_pins gt_quad_0/RX1_GT_IP_Interface] [get_bd_intf_pins pcie_phy/GT_RX1]
  connect_bd_intf_net -intf_net pcie_phy_GT_RX2 [get_bd_intf_pins gt_quad_0/RX2_GT_IP_Interface] [get_bd_intf_pins pcie_phy/GT_RX2]
  connect_bd_intf_net -intf_net pcie_phy_GT_RX3 [get_bd_intf_pins gt_quad_0/RX3_GT_IP_Interface] [get_bd_intf_pins pcie_phy/GT_RX3]
  connect_bd_intf_net -intf_net pcie_phy_GT_TX0 [get_bd_intf_pins gt_quad_0/TX0_GT_IP_Interface] [get_bd_intf_pins pcie_phy/GT_TX0]
  connect_bd_intf_net -intf_net pcie_phy_GT_TX1 [get_bd_intf_pins gt_quad_0/TX1_GT_IP_Interface] [get_bd_intf_pins pcie_phy/GT_TX1]
  connect_bd_intf_net -intf_net pcie_phy_GT_TX2 [get_bd_intf_pins gt_quad_0/TX2_GT_IP_Interface] [get_bd_intf_pins pcie_phy/GT_TX2]
  connect_bd_intf_net -intf_net pcie_phy_GT_TX3 [get_bd_intf_pins gt_quad_0/TX3_GT_IP_Interface] [get_bd_intf_pins pcie_phy/GT_TX3]
  connect_bd_intf_net -intf_net pcie_phy_gt_rxmargin_q0 [get_bd_intf_pins gt_quad_0/gt_rxmargin_intf] [get_bd_intf_pins pcie_phy/gt_rxmargin_q0]
  connect_bd_intf_net -intf_net pcie_phy_mac_rx [get_bd_intf_pins pcie/phy_mac_rx] [get_bd_intf_pins pcie_phy/phy_mac_rx]
  connect_bd_intf_net -intf_net pcie_phy_mac_tx [get_bd_intf_pins pcie/phy_mac_tx] [get_bd_intf_pins pcie_phy/phy_mac_tx]
  connect_bd_intf_net -intf_net pcie_phy_phy_mac_command [get_bd_intf_pins pcie/phy_mac_command] [get_bd_intf_pins pcie_phy/phy_mac_command]
  connect_bd_intf_net -intf_net pcie_phy_phy_mac_rx_margining [get_bd_intf_pins pcie/phy_mac_rx_margining] [get_bd_intf_pins pcie_phy/phy_mac_rx_margining]
  connect_bd_intf_net -intf_net pcie_phy_phy_mac_status [get_bd_intf_pins pcie/phy_mac_status] [get_bd_intf_pins pcie_phy/phy_mac_status]
  connect_bd_intf_net -intf_net pcie_phy_phy_mac_tx_drive [get_bd_intf_pins pcie/phy_mac_tx_drive] [get_bd_intf_pins pcie_phy/phy_mac_tx_drive]
  connect_bd_intf_net -intf_net pcie_phy_phy_mac_tx_eq [get_bd_intf_pins pcie/phy_mac_tx_eq] [get_bd_intf_pins pcie_phy/phy_mac_tx_eq]

  # Create port connections
  connect_bd_net -net bufg_gt_sysclk_BUFG_GT_O [get_bd_pins bufg_gt_sysclk/BUFG_GT_O] [get_bd_pins gt_quad_0/apb3clk] [get_bd_pins pcie/sys_clk] [get_bd_pins pcie_phy/phy_refclk]
  connect_bd_net -net const_1b1_dout [get_bd_pins bufg_gt_sysclk/BUFG_GT_CE] [get_bd_pins const_1b1/dout]
  connect_bd_net -net gt_quad_0_ch0_phyready [get_bd_pins gt_quad_0/ch0_phyready] [get_bd_pins pcie_phy/ch0_phyready]
  connect_bd_net -net gt_quad_0_ch0_phystatus [get_bd_pins gt_quad_0/ch0_phystatus] [get_bd_pins pcie_phy/ch0_phystatus]
  connect_bd_net -net gt_quad_0_ch0_rxoutclk [get_bd_pins gt_quad_0/ch0_rxoutclk] [get_bd_pins pcie_phy/gt_rxoutclk]
  connect_bd_net -net gt_quad_0_ch0_txoutclk [get_bd_pins gt_quad_0/ch0_txoutclk] [get_bd_pins pcie_phy/gt_txoutclk]
  connect_bd_net -net gt_quad_0_ch1_phyready [get_bd_pins gt_quad_0/ch1_phyready] [get_bd_pins pcie_phy/ch1_phyready]
  connect_bd_net -net gt_quad_0_ch1_phystatus [get_bd_pins gt_quad_0/ch1_phystatus] [get_bd_pins pcie_phy/ch1_phystatus]
  connect_bd_net -net gt_quad_0_ch2_phyready [get_bd_pins gt_quad_0/ch2_phyready] [get_bd_pins pcie_phy/ch2_phyready]
  connect_bd_net -net gt_quad_0_ch2_phystatus [get_bd_pins gt_quad_0/ch2_phystatus] [get_bd_pins pcie_phy/ch2_phystatus]
  connect_bd_net -net gt_quad_0_ch3_phyready [get_bd_pins gt_quad_0/ch3_phyready] [get_bd_pins pcie_phy/ch3_phyready]
  connect_bd_net -net gt_quad_0_ch3_phystatus [get_bd_pins gt_quad_0/ch3_phystatus] [get_bd_pins pcie_phy/ch3_phystatus]
  connect_bd_net -net pcie_pcie_ltssm_state [get_bd_pins pcie/pcie_ltssm_state] [get_bd_pins pcie_phy/pcie_ltssm_state]
  connect_bd_net -net pcie_phy_gt_pcieltssm [get_bd_pins gt_quad_0/pcieltssm] [get_bd_pins pcie_phy/gt_pcieltssm]
  connect_bd_net -net pcie_phy_gtrefclk [get_bd_pins gt_quad_0/GT_REFCLK0] [get_bd_pins pcie_phy/gtrefclk]
  connect_bd_net -net pcie_phy_pcierstb [get_bd_pins gt_quad_0/ch0_pcierstb] [get_bd_pins gt_quad_0/ch1_pcierstb] [get_bd_pins gt_quad_0/ch2_pcierstb] [get_bd_pins gt_quad_0/ch3_pcierstb] [get_bd_pins pcie_phy/pcierstb]
  connect_bd_net -net pcie_phy_phy_coreclk [get_bd_pins pcie/phy_coreclk] [get_bd_pins pcie_phy/phy_coreclk]
  connect_bd_net -net pcie_phy_phy_mcapclk [get_bd_pins pcie/phy_mcapclk] [get_bd_pins pcie_phy/phy_mcapclk]
  connect_bd_net -net pcie_phy_phy_pclk [get_bd_pins gt_quad_0/ch0_rxusrclk] [get_bd_pins gt_quad_0/ch0_txusrclk] [get_bd_pins gt_quad_0/ch1_rxusrclk] [get_bd_pins gt_quad_0/ch1_txusrclk] [get_bd_pins gt_quad_0/ch2_rxusrclk] [get_bd_pins gt_quad_0/ch2_txusrclk] [get_bd_pins gt_quad_0/ch3_rxusrclk] [get_bd_pins gt_quad_0/ch3_txusrclk] [get_bd_pins pcie/phy_pclk] [get_bd_pins pcie_phy/phy_pclk]
  connect_bd_net -net pcie_phy_phy_userclk [get_bd_pins pcie/phy_userclk] [get_bd_pins pcie_phy/phy_userclk]
  connect_bd_net -net pcie_phy_phy_userclk2 [get_bd_pins pcie/phy_userclk2] [get_bd_pins pcie_phy/phy_userclk2]
  connect_bd_net -net pcie_phy_rdy_out [get_bd_pins phy_rdy_out] [get_bd_pins pcie/phy_rdy_out]
  connect_bd_net -net pcie_user_clk [get_bd_pins user_clk] [get_bd_pins pcie/user_clk]
  connect_bd_net -net pcie_user_lnk_up [get_bd_pins user_lnk_up] [get_bd_pins pcie/user_lnk_up]
  connect_bd_net -net pcie_user_reset [get_bd_pins user_reset] [get_bd_pins pcie/user_reset]
  connect_bd_net -net refclk_ibuf_IBUF_DS_ODIV2 [get_bd_pins bufg_gt_sysclk/BUFG_GT_I] [get_bd_pins refclk_ibuf/IBUF_DS_ODIV2]
  connect_bd_net -net refclk_ibuf_IBUF_OUT [get_bd_pins pcie/sys_clk_gt] [get_bd_pins pcie_phy/phy_gtrefclk] [get_bd_pins refclk_ibuf/IBUF_OUT]
  connect_bd_net -net sys_reset_1 [get_bd_pins sys_reset] [get_bd_pins pcie/sys_reset] [get_bd_pins pcie_phy/phy_rst_n]

  # Restore current instance
  current_bd_instance /
}

proc create_qdma { index } {
  global pcie_blk_locn
  set qdma [ create_bd_cell -type ip -vlnv xilinx.com:ip:qdma qdma_$index ]
  set_property -dict [ list \
    CONFIG.BASEADDR {0x00000000} \
    CONFIG.HIGHADDR {0x001FFFFF} \
    CONFIG.MSI_X_OPTIONS {None} \
    CONFIG.PF0_MSIX_CAP_TABLE_SIZE_qdma {000} \
    CONFIG.PF0_SRIOV_VF_DEVICE_ID {C034} \
    CONFIG.PF1_MSIX_CAP_TABLE_SIZE_qdma {000} \
    CONFIG.PF1_SRIOV_VF_DEVICE_ID {C134} \
    CONFIG.PF2_MSIX_CAP_TABLE_SIZE_qdma {000} \
    CONFIG.PF2_SRIOV_VF_DEVICE_ID {C234} \
    CONFIG.PF3_MSIX_CAP_TABLE_SIZE_qdma {000} \
    CONFIG.PF3_SRIOV_VF_DEVICE_ID {C334} \
    CONFIG.axi_data_width {256_bit} \
    CONFIG.axil_master_64bit_en {false} \
    CONFIG.axilite_master_en {false} \
    CONFIG.axisten_freq {250} \
    CONFIG.bridge_burst {TRUE} \
    CONFIG.coreclk_freq {500} \
    CONFIG.csr_axilite_slave {true} \
    CONFIG.device_port_type {Root_Port_of_PCI_Express_Root_Complex} \
    CONFIG.en_axi_master_if {true} \
    CONFIG.en_bridge_slv {true} \
    CONFIG.functional_mode {AXI_Bridge} \
    CONFIG.last_core_cap_addr {0x1F0} \
    CONFIG.mode_selection {Advanced} \
    CONFIG.pf0_bar0_prefetchable_qdma {true} \
    CONFIG.pf0_bar0_scale_qdma {Gigabytes} \
    CONFIG.pf0_bar0_size_qdma {2} \
    CONFIG.pf0_bar0_type_qdma {AXI_Bridge_Master} \
    CONFIG.pf0_bar2_64bit_qdma {false} \
    CONFIG.pf0_bar2_enabled_qdma {false} \
    CONFIG.pf0_bar2_size_qdma {4} \
    CONFIG.pf0_bar2_type_qdma {AXI_Lite_Master} \
    CONFIG.pf0_base_class_menu_qdma {Bridge_device} \
    CONFIG.pf0_class_code_base_qdma {06} \
    CONFIG.pf0_class_code_qdma {060400} \
    CONFIG.pf0_class_code_sub_qdma {04} \
    CONFIG.pf0_device_id {B0B4} \
    CONFIG.pf0_msix_cap_pba_offset {00000000} \
    CONFIG.pf0_msix_cap_table_offset {00000000} \
    CONFIG.pf0_msix_cap_table_size {000} \
    CONFIG.pf0_msix_enabled {false} \
    CONFIG.pf0_msix_enabled_qdma {false} \
    CONFIG.pf0_sriov_bar0_size {4} \
    CONFIG.pf0_sriov_bar0_type {AXI_Bridge_Master} \
    CONFIG.pf0_sriov_bar2_type {AXI_Lite_Master} \
    CONFIG.pf0_sub_class_interface_menu_qdma {PCI_to_PCI_bridge} \
    CONFIG.pf1_bar0_prefetchable_qdma {true} \
    CONFIG.pf1_bar0_scale_qdma {Gigabytes} \
    CONFIG.pf1_bar0_size_qdma {4} \
    CONFIG.pf1_bar0_type_qdma {AXI_Bridge_Master} \
    CONFIG.pf1_bar2_64bit_qdma {false} \
    CONFIG.pf1_bar2_enabled_qdma {false} \
    CONFIG.pf1_bar2_size_qdma {4} \
    CONFIG.pf1_bar2_type_qdma {AXI_Lite_Master} \
    CONFIG.pf1_base_class_menu_qdma {Bridge_device} \
    CONFIG.pf1_class_code_base_qdma {06} \
    CONFIG.pf1_class_code_qdma {060A00} \
    CONFIG.pf1_class_code_sub_qdma {0A} \
    CONFIG.pf1_msix_enabled_qdma {false} \
    CONFIG.pf1_sriov_bar0_size {4} \
    CONFIG.pf1_sriov_bar0_type {AXI_Bridge_Master} \
    CONFIG.pf1_sriov_bar2_type {AXI_Lite_Master} \
    CONFIG.pf1_sub_class_interface_menu_qdma {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pf2_bar0_prefetchable_qdma {true} \
    CONFIG.pf2_bar0_scale_qdma {Gigabytes} \
    CONFIG.pf2_bar0_size_qdma {4} \
    CONFIG.pf2_bar0_type_qdma {AXI_Bridge_Master} \
    CONFIG.pf2_bar2_64bit_qdma {false} \
    CONFIG.pf2_bar2_enabled_qdma {false} \
    CONFIG.pf2_bar2_size_qdma {4} \
    CONFIG.pf2_bar2_type_qdma {AXI_Lite_Master} \
    CONFIG.pf2_base_class_menu_qdma {Bridge_device} \
    CONFIG.pf2_class_code_base_qdma {06} \
    CONFIG.pf2_class_code_qdma {060A00} \
    CONFIG.pf2_class_code_sub_qdma {0A} \
    CONFIG.pf2_device_id {B2B4} \
    CONFIG.pf2_msix_enabled_qdma {false} \
    CONFIG.pf2_sriov_bar0_size {4} \
    CONFIG.pf2_sriov_bar0_type {AXI_Bridge_Master} \
    CONFIG.pf2_sriov_bar2_type {AXI_Lite_Master} \
    CONFIG.pf2_sub_class_interface_menu_qdma {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pf3_bar0_prefetchable_qdma {true} \
    CONFIG.pf3_bar0_scale_qdma {Gigabytes} \
    CONFIG.pf3_bar0_size_qdma {4} \
    CONFIG.pf3_bar0_type_qdma {AXI_Bridge_Master} \
    CONFIG.pf3_bar2_64bit_qdma {false} \
    CONFIG.pf3_bar2_enabled_qdma {false} \
    CONFIG.pf3_bar2_size_qdma {4} \
    CONFIG.pf3_bar2_type_qdma {AXI_Lite_Master} \
    CONFIG.pf3_base_class_menu_qdma {Bridge_device} \
    CONFIG.pf3_class_code_base_qdma {06} \
    CONFIG.pf3_class_code_qdma {060A00} \
    CONFIG.pf3_class_code_sub_qdma {0A} \
    CONFIG.pf3_device_id {B3B4} \
    CONFIG.pf3_msix_enabled_qdma {false} \
    CONFIG.pf3_sriov_bar0_size {4} \
    CONFIG.pf3_sriov_bar0_type {AXI_Bridge_Master} \
    CONFIG.pf3_sriov_bar2_type {AXI_Lite_Master} \
    CONFIG.pf3_sub_class_interface_menu_qdma {InfiniBand_to_PCI_host_bridge} \
    CONFIG.pl_link_cap_max_link_speed {16.0_GT/s} \
    CONFIG.pl_link_cap_max_link_width {X4} \
    CONFIG.plltype {QPLL1} \
    CONFIG.vdm_en {true} \
    CONFIG.xdma_axilite_slave {true} \
    CONFIG.pcie_blk_locn [lindex $pcie_blk_locn $index] \
  ] $qdma

}

create_qdma 0
create_qdma_support 0
if {$dual_design} {
  create_qdma 1
  create_qdma_support 1
}

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 const_high
connect_bd_net [get_bd_pins const_high/dout] [get_bd_pins qdma_support_0/sys_reset]
connect_bd_net [get_bd_pins const_high/dout] [get_bd_pins qdma_0/soft_reset_n]
if {$dual_design} {
  connect_bd_net [get_bd_pins const_high/dout] [get_bd_pins qdma_support_1/sys_reset]
  connect_bd_net [get_bd_pins const_high/dout] [get_bd_pins qdma_1/soft_reset_n]
}

# Ports
proc connect_qdma_ports { index } {
  create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 pci_exp_$index
  connect_bd_intf_net -intf_net qdma_support_${index}_pcie_mgt [get_bd_intf_ports pci_exp_$index] [get_bd_intf_pins qdma_support_${index}/pcie_mgt]

  create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 ref_clk_$index
  connect_bd_intf_net -intf_net pcie_refclk_$index [get_bd_intf_ports ref_clk_$index] [get_bd_intf_pins qdma_support_${index}/pcie_refclk]
}

connect_qdma_ports 0
if {$dual_design} {
  connect_qdma_ports 1
}

# QDMA interrupts
proc connect_qdma_intr { index } {
  global intr_list
  lappend intr_list "qdma_$index/interrupt_out"
  lappend intr_list "qdma_$index/interrupt_out_msi_vec0to31"
  lappend intr_list "qdma_$index/interrupt_out_msi_vec32to63"
}

connect_qdma_intr 0
if {$dual_design} {
  connect_qdma_intr 1
}

# Connections between QDMA and QDMA support block
proc connect_qdma_support { index } {
  connect_bd_intf_net [get_bd_intf_pins qdma_${index}/pcie_cfg_control_if] -boundary_type upper [get_bd_intf_pins qdma_support_${index}/pcie_cfg_control]
  connect_bd_intf_net [get_bd_intf_pins qdma_${index}/pcie_cfg_interrupt] -boundary_type upper [get_bd_intf_pins qdma_support_${index}/pcie_cfg_interrupt]
  connect_bd_intf_net [get_bd_intf_pins qdma_${index}/pcie_cfg_mgmt_if] -boundary_type upper [get_bd_intf_pins qdma_support_${index}/pcie_cfg_mgmt]

  connect_bd_intf_net [get_bd_intf_pins qdma_${index}/s_axis_cc] -boundary_type upper [get_bd_intf_pins qdma_support_${index}/s_axis_cc]
  connect_bd_intf_net [get_bd_intf_pins qdma_${index}/s_axis_rq] -boundary_type upper [get_bd_intf_pins qdma_support_${index}/s_axis_rq]

  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins qdma_support_${index}/m_axis_cq] [get_bd_intf_pins qdma_${index}/m_axis_cq]
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins qdma_support_${index}/m_axis_rc] [get_bd_intf_pins qdma_${index}/m_axis_rc]

  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins qdma_support_${index}/pcie_cfg_fc] [get_bd_intf_pins qdma_${index}/pcie_cfg_fc]
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins qdma_support_${index}/pcie_cfg_mesg_rcvd] [get_bd_intf_pins qdma_${index}/pcie_cfg_mesg_rcvd]
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins qdma_support_${index}/pcie_cfg_mesg_tx] [get_bd_intf_pins qdma_${index}/pcie_cfg_mesg_tx]
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins qdma_support_${index}/pcie_cfg_status] [get_bd_intf_pins qdma_${index}/pcie_cfg_status_if]

  connect_bd_net [get_bd_pins qdma_support_${index}/phy_rdy_out] [get_bd_pins qdma_${index}/phy_rdy_out_sd]
  connect_bd_net [get_bd_pins qdma_support_${index}/user_clk] [get_bd_pins qdma_${index}/user_clk_sd]
  connect_bd_net [get_bd_pins qdma_support_${index}/user_lnk_up] [get_bd_pins qdma_${index}/user_lnk_up_sd]
  connect_bd_net [get_bd_pins qdma_support_${index}/user_reset] [get_bd_pins qdma_${index}/user_reset_sd]
  connect_bd_intf_net -boundary_type upper [get_bd_intf_pins qdma_support_${index}/pcie_transmit_fc] [get_bd_intf_pins qdma_${index}/pcie_transmit_fc_if]
}

connect_qdma_support 0
if {$dual_design} {
  connect_qdma_support 1
}

# Add smartconnects for S_AXI interfaces
create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc_fpd
set_property -dict [list CONFIG.NUM_SI {1}] [get_bd_cells axi_smc_fpd]
connect_bd_net [get_bd_pins versal_cips_0/pl0_ref_clk] [get_bd_pins axi_smc_fpd/aclk]
connect_bd_net [get_bd_pins versal_cips_0/pl0_ref_clk] [get_bd_pins versal_cips_0/m_axi_fpd_aclk]

create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc_lpd
set_property -dict [list CONFIG.NUM_SI {1}] [get_bd_cells axi_smc_lpd]
connect_bd_net [get_bd_pins versal_cips_0/pl0_ref_clk] [get_bd_pins axi_smc_lpd/aclk]
connect_bd_net [get_bd_pins versal_cips_0/pl0_ref_clk] [get_bd_pins versal_cips_0/m_axi_lpd_aclk]

# Add processor system reset for the PL0_REF_CLK 350MHz
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 reset_pl0_ref_clk
connect_bd_net [get_bd_pins versal_cips_0/pl0_ref_clk] [get_bd_pins reset_pl0_ref_clk/slowest_sync_clk]
connect_bd_net [get_bd_pins versal_cips_0/pl0_resetn] [get_bd_pins reset_pl0_ref_clk/ext_reset_in]
connect_bd_net [get_bd_pins reset_pl0_ref_clk/interconnect_aresetn] [get_bd_pins axi_smc_fpd/aresetn]
connect_bd_net [get_bd_pins reset_pl0_ref_clk/interconnect_aresetn] [get_bd_pins axi_smc_lpd/aresetn]

proc connect_qdma_saxi { index } {
  global qdma_cfg_addr
  
  # QDMA: S_AXI_BRIDGE
  apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config [list Clk_master {/versal_cips_0/pl0_ref_clk (333 MHz)} Clk_slave "/qdma_$index/axi_aclk (250 MHz)" Clk_xbar "/qdma_$index/axi_aclk (250 MHz)" Master {/versal_cips_0/M_AXI_FPD} Slave "/qdma_$index/S_AXI_BRIDGE" ddr_seg {Auto} intc_ip {/axi_smc_fpd} master_apm {0}]  [get_bd_intf_pins qdma_$index/S_AXI_BRIDGE]

  # QDMA: S_AXI_LITE
  apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config [list Clk_master {/versal_cips_0/pl0_ref_clk (333 MHz)} Clk_slave "/qdma_$index/axi_aclk (250 MHz)" Clk_xbar "/qdma_$index/axi_aclk (250 MHz)" Master {/versal_cips_0/M_AXI_FPD} Slave "/qdma_$index/S_AXI_LITE" ddr_seg {Auto} intc_ip {/axi_smc_fpd} master_apm {0}]  [get_bd_intf_pins qdma_$index/S_AXI_LITE]
  
  set_property offset [lindex $qdma_cfg_addr $index] [get_bd_addr_segs versal_cips_0/M_AXI_FPD/SEG_qdma_${index}_CTL0]
  set_property range 256M [get_bd_addr_segs versal_cips_0/M_AXI_FPD/SEG_qdma_${index}_CTL0]

  # QDMA: S_AXI_LITE_CSR
  apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config [list Clk_master {/versal_cips_0/pl0_ref_clk (333 MHz)} Clk_slave "/qdma_$index/axi_aclk (250 MHz)" Clk_xbar "/qdma_$index/axi_aclk (250 MHz)" Master {/versal_cips_0/M_AXI_LPD} Slave "/qdma_$index/S_AXI_LITE_CSR" ddr_seg {Auto} intc_ip {/axi_smc_lpd} master_apm {0}]  [get_bd_intf_pins qdma_$index/S_AXI_LITE_CSR]
  
  set_property range 16K [get_bd_addr_segs versal_cips_0/M_AXI_LPD/SEG_qdma_${index}_CTL0]

  # QDMA: M_AXI_BRIDGE
  set noc_num_si [get_property CONFIG.NUM_SI [get_bd_cells axi_noc_0]]
  set noc_num_si_plus_one [expr {$noc_num_si+1}]
  set_property -dict [list CONFIG.NUM_SI $noc_num_si_plus_one CONFIG.NUM_CLKS $noc_num_si_plus_one] [get_bd_cells axi_noc_0]
  set_property -dict [list CONFIG.CONNECTIONS {MC_0 { read_bw {1720} write_bw {1720} read_avg_burst {4} write_avg_burst {4}} }] [get_bd_intf_pins /axi_noc_0/S0${noc_num_si}_AXI]
  set_property -dict [list CONFIG.ASSOCIATED_BUSIF "S00_AXI:S0${noc_num_si}_AXI"] [get_bd_pins /axi_noc_0/aclk0]
  connect_bd_net [get_bd_pins qdma_${index}/axi_aclk] [get_bd_pins axi_noc_0/aclk${noc_num_si}]
  apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config [list Clk_master "/qdma_$index/axi_aclk (250 MHz)" Clk_slave {/versal_cips_0/fpd_cci_noc_axi0_clk (824 MHz)} Clk_xbar {Auto} Master "/qdma_$index/M_AXI_BRIDGE" Slave "/axi_noc_0/S0${noc_num_si}_AXI" ddr_seg {Auto} intc_ip {/axi_noc_0} master_apm {0}]  [get_bd_intf_pins axi_noc_0/S0${noc_num_si}_AXI]
  # Set the BAR address and size
  global bar_addr
  global bar_size
  set_property offset [lindex $bar_addr $index] [get_bd_addr_segs "versal_cips_0/M_AXI_FPD/SEG_qdma_${index}_BAR0"]
  set_property range [lindex $bar_size $index] [get_bd_addr_segs "versal_cips_0/M_AXI_FPD/SEG_qdma_${index}_BAR0"]
}

connect_qdma_saxi 0
if {$dual_design} {
  connect_qdma_saxi 1
}

# Create PERST ports
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_low
set_property -dict [list CONFIG.CONST_VAL {0}] [get_bd_cells const_low]
create_bd_port -dir O -from 0 -to 0 -type rst perst_0
connect_bd_net [get_bd_pins /const_low/dout] [get_bd_ports perst_0]
if {$dual_design} {
  create_bd_port -dir O -from 0 -to 0 -type rst perst_1
  connect_bd_net [get_bd_pins /const_low/dout] [get_bd_ports perst_1]
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

# Connect the interrupts
set intr_index 0
foreach intr $intr_list {
  connect_bd_net [get_bd_pins $intr] [get_bd_pins versal_cips_0/pl_ps_irq$intr_index]
  set intr_index [expr {$intr_index+1}]
}

# Assign any addresses that haven't already been assigned
assign_bd_address

validate_bd_design
save_bd_design

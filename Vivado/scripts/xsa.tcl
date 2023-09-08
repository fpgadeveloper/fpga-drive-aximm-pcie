# Opsero Electronic Design Inc. Copyright 2023
#
# This script runs synthesis, implementation and exports the hardware for a project.
#
# This script requires the target name and number of jobs to be specified upon launch.
# This can be done in two ways:
#
#   1. Using two arguments passed to the script via tclargs.
#      eg. vivado -mode batch -source xsa.tcl -notrace -tclargs <target-name> <jobs>
#
#   2. By setting the target variables before sourcing the script.
#      eg. set target <target-name>
#          set jobs <number-of-jobs>
#          source xsa.tcl -notrace
#
# The valid target names are:
#   * zcu104       * zcu102_hpc0  * zcu102_hpc1  * zcu106_hpc0
#   * pynqzu       * genesyszu    * uzev
#
#*****************************************************************************************

# Check the version of Vivado used
set version_required "2022.1"
set ver [lindex [split $::env(XILINX_VIVADO) /] end]
if {![string equal $ver $version_required]} {
  puts "###############################"
  puts "### Failed to build project ###"
  puts "###############################"
  puts "This project was designed for use with Vivado $version_required."
  puts "You are using Vivado $ver. Please install Vivado $version_required,"
  puts "or download the project sources from a commit of the Git repository"
  puts "that was intended for your version of Vivado ($ver)."
  return
}

# Possible targets
dict set target_dict zcu104 { xczu7ev-ffvc1156-2-e xilinx.com:zcu104:part0:1.1 { 0 1 2 3 } zynqmp }
dict set target_dict zcu102_hpc0 { xczu9eg-ffvb1156-2-e xilinx.com:zcu102:part0:3.4 { 0 1 2 3 } zynqmp }
dict set target_dict zcu102_hpc1 { xczu9eg-ffvb1156-2-e xilinx.com:zcu102:part0:3.4 { 0 1 } zynqmp }
dict set target_dict zcu106_hpc0 { xc7z045ffg900-2 xilinx.com:zcu106:part0:2.6 { 0 1 2 3 } zynqmp }
dict set target_dict pynqzu { xczu5eg-sfvc784-1-e tul.com.tw:pynqzu:part0:1.1 { 0 1 2 3 } zynqmp }
dict set target_dict genesyszu { xczu5ev-sfvc784-1-e digilentinc.com:gzu_5ev:part0:1.1 { 0 1 2 3 } zynqmp }
dict set target_dict uzev { xczu7ev-fbvb900-1-i avnet.com:ultrazed_7ev_cc:part0:1.5 { 0 1 2 3 } zynqmp }

if { $argc == 2 } {
  set target [lindex $argv 0]
  puts "Target for the build: $target"
  set jobs [lindex $argv 1]
  puts "Number of jobs: $jobs"
} elseif { [info exists target] && [dict exists $target_dict $target] } {
  puts "Target for the build: $target"
  if { ![info exists jobs] } {
    set jobs 8
  }
} else {
  puts ""
  if { [info exists target] } {
    puts "ERROR: Invalid target $target"
    puts ""
  }
  puts "The build script requires two arguments. The first argument to specifies"
  puts "the design to build, while the second specifies the number of jobs to run."
  puts "Possible values for target are are:"
  puts "   * zcu104       * zcu102_hpc0  * zcu102_hpc1  * zcu106_hpc0"
  puts "   * pynqzu       * genesyszu    * uzev"
  puts ""
  puts "Example 1 (from the Windows command line):"
  puts "   vivado -mode batch -source xsa.tcl -notrace -tclargs zcu106_hpc0 8"
  puts ""
  puts "Example 2 (from Vivado Tcl console):"
  puts "   set target zcu106_hpc0"
  puts "   set jobs 8"
  puts "   source xsa.tcl -notrace"
  return
}

set design_name ${target}
set block_name fpgadrv

# Set the reference directory for source file relative paths (by default the value is script directory path)
set origin_dir "."

# Set the directory path for the original project from where this script was exported
set orig_proj_dir "[file normalize "$origin_dir/$design_name"]"

# Open project
open_project $origin_dir/$design_name/$design_name.xpr

launch_runs synth_1 -jobs $jobs
wait_on_run synth_1
launch_runs impl_1 -jobs $jobs -to_step write_bitstream
wait_on_run impl_1
write_hw_platform -fixed -include_bit -force -file $origin_dir/$design_name/${block_name}_wrapper.xsa
validate_hw_platform -verbose $origin_dir/$design_name/${block_name}_wrapper.xsa


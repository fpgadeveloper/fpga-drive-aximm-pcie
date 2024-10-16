# Opsero Electronic Design Inc. Copyright 2024
#
# Project build script
#
# This script requires the target name to be specified upon launch. This can be done
# in two ways:
#
#   1. Using a single argument passed to the script via tclargs.
#      eg. vivado -mode batch -source build.tcl -notrace -tclargs <target-name>
#
#   2. By setting the target variable before sourcing the script.
#      eg. set target <target-name>
#          source build.tcl -notrace
#
# For a list of possible targets, see below.
#
#*****************************************************************************************

# Check the version of Vivado used
set version_required "2024.1"
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

# Add Xilinx board store to the repo paths
set repo_paths [get_param board.repoPaths]
lappend repo_paths [get_property LOCAL_ROOT_DIR [xhub::get_xstores xilinx_board_store]]
set_param board.repoPaths $repo_paths

# Possible targets
dict set target_dict auboard { avnet.com auboard_15p { X4 } mb }
dict set target_dict kc705_hpc { xilinx.com kc705 { X4 } mb }
dict set target_dict kc705_lpc { xilinx.com kc705 { X1 } mb }
dict set target_dict kcu105_hpc { xilinx.com kcu105 { X4 X4 } mb }
dict set target_dict kcu105_lpc { xilinx.com kcu105 { X1 } mb }
dict set target_dict pz_7015 { avnet.com picozed_7015_fmc2 { X1 } zynq }
dict set target_dict pz_7030 { avnet.com picozed_7030_fmc2 { X1 } zynq }
dict set target_dict uzev { avnet.com ultrazed_7ev_cc { X4 X4 } zynqmp }
dict set target_dict vc707_hpc1 { xilinx.com vc707 { X4 } mb }
dict set target_dict vc707_hpc2 { xilinx.com vc707 { X4 } mb }
dict set target_dict vc709_hpc { xilinx.com vc709 { X4 } mb }
dict set target_dict vck190_fmcp1 { xilinx.com vck190 { X4 X4 } versal }
dict set target_dict vck190_fmcp2 { xilinx.com vck190 { X4 X4 } versal }
dict set target_dict vek280 { xilinx.com vek280 { X4 X4 } versal }
dict set target_dict vek280_es_revb { xilinx.com vek280_es_revb { X4 X4 } versal }
dict set target_dict vmk180_fmcp1 { xilinx.com vmk180 { X4 X4 } versal }
dict set target_dict vmk180_fmcp2 { xilinx.com vmk180 { X4 X4 } versal }
dict set target_dict vpk120 { xilinx.com vpk120 { X4 } versal }
dict set target_dict vpk180 { xilinx.com vpk180 { X4 } versal }
dict set target_dict vcu118 { xilinx.com vcu118 { X4 X4 } mb }
dict set target_dict zc706_hpc { xilinx.com zc706 { X4 } zynq }
dict set target_dict zc706_lpc { xilinx.com zc706 { X1 } zynq }
dict set target_dict zcu104 { xilinx.com zcu104 { X1 } zynqmp }
dict set target_dict zcu106_hpc0 { xilinx.com zcu106 { X4 X4 } zynqmp }
dict set target_dict zcu106_hpc1 { xilinx.com zcu106 { X1 } zynqmp }
dict set target_dict zcu111 { xilinx.com zcu111 { X4 X4 } zynqmp }
dict set target_dict zcu208 { xilinx.com zcu208 { X4 X4 } zynqmp }
dict set target_dict zcu216 { xilinx.com zcu216 { X4 X4 } zynqmp }

# Function to display the options and get user input
proc selectTarget {target_dict} {
    # Create a list to hold the keys in order
    set keys_list [dict keys $target_dict]
    set keys_list [lsort $keys_list]

    # Forever loop until we break it when the user confirms their selection
    while {1} {
        # Initialize a counter for the numbering
        set counter 0

        # Display options
        puts "Possible target designs:"
        foreach key $keys_list {
            incr counter
            puts "  $counter: $key"
        }

        # Ask for user input
        set user_choice -1
        while {($user_choice < 1) || ($user_choice > $counter)} {
            puts -nonewline "Choose target design (1-$counter): "
            flush stdout
            gets stdin user_choice

            # Check if the input is a valid number
            if {![string is integer -strict $user_choice]} {
                set user_choice -1
                continue
            }
        }

        # Confirm selection
        set selected_key [lindex $keys_list [expr {$user_choice - 1}]]
        puts -nonewline "Confirm selection '$selected_key' (Y/n): "
        flush stdout
        gets stdin confirmation

        # Check confirmation
        if {[string match -nocase "y*" $confirmation] || [string equal -length 1 "" $confirmation]} {
            # If the user confirmed, return the selected key
            return $selected_key
        }
    }
}

# Target can be specified by creating the target variable before sourcing, or in the command line arguments
if { [info exists target] } {
  if { ![dict exists $target_dict $target] } {
    puts "Invalid target specified: $target"
    exit 1
  }
} elseif { $argc == 0 } {
  set target [selectTarget $target_dict]
} else {
  set target [lindex $argv 0]
  if { ![dict exists $target_dict $target] } {
    puts "Invalid target specified: $target"
    exit 1
  }
}

# At this point of the script, we are guaranteed to have a valid target
puts "Target design: $target"

set design_name ${target}
set block_name fpgadrv
set board_url [lindex [dict get $target_dict $target] 0]
set board_name [lindex [dict get $target_dict $target] 1]
set proj_board [get_board_parts "$board_url:$board_name:*" -latest_file_version]
# Check if the board files are installed, if not, install them
if { $proj_board == "" } {
    puts "Failed to find board files for $board_name. Installing board files..."
    xhub::refresh_catalog [xhub::get_xstores xilinx_board_store]
    xhub::install [xhub::get_xitems $board_url:xilinx_board_store:$board_name*]
    set proj_board [get_board_parts "$board_url:$board_name:*" -latest_file_version]
} else {
    puts "Board files found for $board_name"
}

set fpga_part [get_property PART_NAME [get_board_parts $proj_board]]
set num_lanes [lindex [dict get $target_dict $target] 2]
set dual_design [expr {[llength $num_lanes] == 2}]
set bd_script [lindex [dict get $target_dict $target] 3]

# Set the reference directory for source file relative paths (by default the value is script directory path)
set origin_dir "."

# Set the directory path for the original project from where this script was exported
set orig_proj_dir "[file normalize "$origin_dir/$design_name"]"

# Create project
create_project $design_name $origin_dir/$design_name -part ${fpga_part}

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Set project properties
set_property board_part $proj_board [current_project]

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}


# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property -name "top" -value "${block_name}_wrapper" -objects $obj

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Set 'constrs_1' fileset object
set obj [get_filesets constrs_1]

# Add/Import constrs file and set constrs file properties
set file "[file normalize "$origin_dir/src/constraints/${target}.xdc"]"
set file_added [add_files -norecurse -fileset $obj $file]
set file "$origin_dir/src/constraints/${target}.xdc"
set file [file normalize $file]
set file_obj [get_files -of_objects [get_filesets constrs_1] [list "*$file"]]
set_property "file_type" "XDC" $file_obj

# Set 'constrs_1' fileset properties
set obj [get_filesets constrs_1]
set_property "target_constrs_file" "[file normalize "$origin_dir/src/constraints/${target}.xdc"]" $obj

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

# Set 'sim_1' fileset object
set obj [get_filesets sim_1]
# Empty (no sources present)

# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]
set_property -name "top" -value "${block_name}_wrapper" -objects $obj

# Create 'synth_1' run (if not found)
if {[string equal [get_runs -quiet synth_1] ""]} {
  create_run -name synth_1 -part ${fpga_part} -flow {Vivado Synthesis 2024} -strategy "Vivado Synthesis Defaults" -report_strategy {No Reports} -constrset constrs_1
} else {
  set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]
  set_property flow "Vivado Synthesis 2024" [get_runs synth_1]
}
set obj [get_runs synth_1]

# set the current synth run
current_run -synthesis [get_runs synth_1]

# Create 'impl_1' run (if not found)
if {[string equal [get_runs -quiet impl_1] ""]} {
  create_run -name impl_1 -part ${fpga_part} -flow {Vivado Implementation 2024} -strategy "Vivado Implementation Defaults" -report_strategy {No Reports} -constrset constrs_1 -parent_run synth_1
} else {
  set_property strategy "Vivado Implementation Defaults" [get_runs impl_1]
  set_property flow "Vivado Implementation 2024" [get_runs impl_1]
}
set obj [get_runs impl_1]
if {$bd_script == "versal"} {
  set_property -name "steps.write_device_image.args.readback_file" -value "0" -objects $obj
  set_property -name "steps.write_device_image.args.verbose" -value "0" -objects $obj
} else {
  set_property -name "steps.write_bitstream.args.readback_file" -value "0" -objects $obj
  set_property -name "steps.write_bitstream.args.verbose" -value "0" -objects $obj
}

# set the current impl run
current_run -implementation [get_runs impl_1]

puts "INFO: Project created:${design_name}"

# Create the GT LOC dictionary that is used by the block design script
source $origin_dir/src/bd/gt_locs.tcl

# Create block design
source $origin_dir/src/bd/bd_${bd_script}.tcl

# Generate the wrapper
make_wrapper -files [get_files *${block_name}.bd] -top
add_files -norecurse ${design_name}/${design_name}.gen/sources_1/bd/${block_name}/hdl/${block_name}_wrapper.v

# Update the compile order
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Ensure parameter propagation has been performed
close_bd_design [current_bd_design]
open_bd_design [get_files ${block_name}.bd]
validate_bd_design -force
save_bd_design


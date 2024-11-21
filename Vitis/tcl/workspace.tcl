# -------------------------------------------------------------------------------------
# Opsero Electronic Design Inc. Copyright 2024
# -------------------------------------------------------------------------------------
# *** VITIS WORKSPACE BUILDER SCRIPT ***
#
# This script contains functions that are used by the main script (build-vitis.tcl).
# The functions are used to create the Vitis workspace based on the variables and 
# functions defined in the main script.
#
# These are the steps in workspace creation:
#
# (1) Create the local software repository:
#     If there is an "EmbeddedSw" folder in the project root, then create a local
#     software repo inside the Vitis workspace called "embeddedsw". The local software
#     repo is then filled with the contents of "EmbeddedSw" and the remaining sources
#     are copied from the Vitis installation.
# (2) Check that the .xsa file exists for the target design.
# (3) Create the platform and application for the .xsa file:
#     The script will create a platform and stand-alone application for the .xsa file.
#     The application to create must be specified by the "support_app" and 
#     "template_app" variables. The name of the application is specified by the
#      "app_name" variable.
# (4) Copy boot files into boot folder:
#     The script will create a "boot" folder inside the Vitis folder and copy the
#     boot file for the target project into that folder.
#
# -------------------------------------------------------------------------------------

# Returns true if str contains substr
proc str_contains {str substr} {
  if {[string first $substr $str] == -1} {
    return 0
  } else {
    return 1
  }
}

# Recursive copy function
# Note: Does not overwrite existing files, thus our modified files are untouched.
proc copy-r {{dir .} target_dir} {
  foreach i [lsort [glob -nocomplain -dir $dir *]] {
    # Get the name of the file or directory
    set name [lindex [split $i /] end]
    if {[file type $i] eq {directory}} {
      # If doesn't exist in target, then create it
      set target_subdir ${target_dir}/$name
      if {[file exists $target_subdir] == 0} {
        file mkdir $target_subdir
      }
      # Copy all files contained in this subdirectory
      eval [copy-r $i $target_subdir]
    } else {
      # Copy the file if it doesn't already exist
      if {[file exists ${target_dir}/$name] == 0} {
        file copy $i $target_dir
      }
    }
  }
} ;# RS

# Recursive find subdirectory function
# Recursively searches for subdirectories whose names are given in the arguments, and returns 
# full paths of the parent directories. Files are completely ignored.
# Example usage: glob-dir-r [pwd] src data (recursively find all directories containing "src" 
# or "data" subdirectories in current path)
proc glob-dir-r {{dir .} args} {
  set res {}
  foreach i [lsort [glob -nocomplain -dir $dir *]] {
    if {[file isdirectory $i]} {
      if {[llength $args]} {
        foreach arg $args {
          if {[file tail $i] == $arg} {
            lappend res [file dirname $i]
            return $res
          }
        }
      }
      eval [list lappend res] [eval [linsert $args 0 glob-dir-r $i]]
    }
  }
  return $res
}

# Print statements
proc print_platform {name msg} {
  puts "  PLATFORM ($name): $msg"
}

proc print_app {name msg} {
  puts "  APPLICATION ($name): $msg"
}

proc print_sysproj {name msg} {
  puts "  SYSPROJ ($name): $msg"
}

# Create the local software repository (embeddedsw) for the modified drivers
proc create_local_embeddedsw {workspace_dir} {
  # Xilinx Vitis install directory
  set vitis_path $::env(XILINX_VITIS)
  set embeddedsw_path "$workspace_dir/embeddedsw"
  # Copy the EmbeddedSw folder into the Vitis workspace
  file mkdir $embeddedsw_path
  copy-r "../EmbeddedSw" $embeddedsw_path
  # List all of the "src" or "data" directories so that we know what to copy
  # from the Vitis installation original driver sources
  set local_dirs [glob-dir-r $embeddedsw_path src data]
  set orig_dirs {}
  foreach d $local_dirs {
    set rel_path [string map [list "${workspace_dir}/" ""] $d]
    if {[string index $d end] == "9"} {
      lappend orig_dirs [string replace "$vitis_path/data/$rel_path" end end ""]
    } else {
      lappend orig_dirs "$vitis_path/data/$rel_path"
    }
  }
  # Copy the relevant original sources into the local software repository
  foreach local_dir $local_dirs orig_dir $orig_dirs {
    puts "Copying files from $orig_dir to $local_dir"
    # Copy the original files to local repo, without overwriting existing code
    copy-r $orig_dir $local_dir
  }
}

# Returns a list of platforms in the workspace
proc get_list_of_platforms {} {
  set platforms [platform list]
  set list_of_platforms {}
  # For each line of the platform list
  foreach line [split $platforms "\n"] {
    set values [regexp -all -inline {\S+} $line]
    # If the second column is "YES", then get the 1st column (platform name)
    if {[lindex $values 1] == "YES"} {
      append list_of_platforms "[lindex $values 0] "
    }
  }
  return $list_of_platforms
}

# Returns a list of apps in the workspace
proc get_list_of_apps {} {
  # Run "app list" with catch because it will throw an error if there are no apps found
  if {[catch "app list" apps]} {
    puts "No applications in workspace."
    set apps {}
  }
  set list_of_apps {}
  # For each line of the app list
  foreach line [split $apps "\n"] {
    # If line begins with a lowercase a-z, then we assume it is an app name
    set words [regexp -all -inline {\S+} $line]
    set first_word [lindex $words 0]
    if {[string match {[a-z]*} $first_word]} {
      append list_of_apps "$first_word "
    }
  }
  return $list_of_apps
}

# Returns a dict with results from "domain/platform/app report"
# Arguments:
#   report_type:   domain or platform or app
#   platform_name: Name of the platform
#   domain_name:   Name of the domain
#   app_name:      Name of the app
#
# Example "domain report": get_report <platform_name> <domain_name>
# ==================================================
# PROPERTY                  VALUE
# ==================================================
# name                      standalone_domain
# display-name              standalone on ps7_cortexa9_0
# description               standalone_domain
# os                        standalone
# isBootDomain              false
# qemu-data                 C:/Xilinx/Vitis/2020.2/data/emulation/platforms/zynq/sw/a9_standalone/qemu/
# qemu-args                 C:/Xilinx/Vitis/2020.2/data/emulation/platforms/zynq/sw/a9_standalone/qemu/qemu_args.txt
# processor                 ps7_cortexa9_0
# osVersion                 7.3
# arch                      32-bit
# Platform                  zedboard_max_tp_wrapper
# 
# Example "platform report": get_report <platform_name>
# ================================================================================
# PROPERTY                    VALUE
# ================================================================================
# name                        zedboard_test
# description                 zedboard_test
# hw spec                     F:/vivado-2020-2/ethernet-fmc-max-throughput/Vivado
#                             o/zedboard_max_tp/zedboard_max_tp_wrapper.xsa
# output dir                  F:/vivado-2020-2/ethernet-fmc-emc-test/Vitis
# type                        
# samples                     
# prebuilt                    false
# processors                  ps7_cortexa9_0,ps7_cortexa9_1
# Domains                     zynq_fsbl
#
# Example "app report": get_report <app_name>
# ================================================================================
# PROPERTY                 VALUE
# ================================================================================
# fsblpath                 F:/vivado-2020-2/ethernet-fmc-emc-test/Vitis/zedboard_m
#                          ax_tp_wrapper/export/zedboard_max_tp_wrapper/sw/zedboard
#                          _max_tp_wrapper/boot/fsbl.elf
# Platform Path            F:/vivado-2020-2/ethernet-fmc-emc-test/Vitis/zedboard_m
#                          ax_tp_wrapper/export/zedboard_max_tp_wrapper/zedboard_ma
#                          x_tp_wrapper.xpfm
# Domain                   standalone_domain
# platform                 zedboard_max_tp_wrapper
#
proc get_report {report_type a {b "standalone_domain"}} {
  set report [dict create]
  if {$report_type == "app"} {
    set report_text [app report $a]
  } elseif {$report_type == "domain"} {
    platform active $a
    domain active $b
    set report_text [domain report]
  } elseif {$report_type == "platform"} {
    platform active $a
    set report_text [platform report]
  } else {
    puts "ERROR: get_report supported values for report_type are: domain, platform or app"
    return $report
  }
  # For each line of the report
  foreach line [split $report_text "\n"] {
    set values [regexp -all -inline {\S+} $line]
    # If there are two columns, then put this into the dictionary
    if {[llength $values] == 2} {
      dict append report {*}$values
    }
  }
  return $report
}

# Returns the processor instance name from platform
# Vitis 2020.2 lists the processors in the following order and this function assumes that this order is always maintained:
#   - microblaze: microblaze_0
#   - zynq:       ps7_cortexa9_0,ps7_cortexa9_1
#   - zynqmp:     psu_cortexa53_0,psu_cortexa53_1,psu_cortexa53_2,psuu_cortexa53_3,psu_cortexr5_0,psu_cortexr5_1,psu_pmu_0
#
proc get_processor_from_platform {platform_name} {
  set platform_report [get_report "platform" $platform_name]
  set procs [dict get $platform_report "processors"]
  set list_of_procs [split $procs ","]
  # Return the first processor instance listed (we assume that 1st one is the one we want to run our main application on)
  return [lindex $list_of_procs 0]
}

# Returns true if xsa_file is newer than the local copy in platform_name
proc xsa_needs_updating {workspace_dir xsa_file platform_name} {
  # If the .xsa needs updating
  set xsa_wildcard "$workspace_dir/$platform_name/hw/*.xsa"
  set xsa_local_files [glob -nocomplain -- $xsa_wildcard]
  if { [llength $xsa_local_files] != 1 } {
    return 1
  }
  set xsa_local_copy [lindex $xsa_local_files 0]
  set xsa_source_date [file mtime $xsa_file]
  set xsa_local_copy_date [file mtime $xsa_local_copy]
  if {$xsa_source_date > $xsa_local_copy_date} { return 1 } else { return 0 }
}

# Cleans the system project
proc clean_sysproj {sysproj_name} {
  if {[catch "sysproj clean -name $sysproj_name" result]} {
    puts "ERROR: sysproj clean returned an error\n$result"
  }
}

# Creates the board.h file that defines the board name
proc create_board_h {board_name target_dir} {
  # Xilinx Vitis install directory to get the version number
  set workspace_dir $::env(XILINX_VITIS)
  set vitis_ver [lindex [file split $workspace_dir] end]
  # Create the file
  set fd [open "${target_dir}/board.h" "w"]
  puts $fd "/* This file is automatically generated */"
  puts $fd "#ifndef BOARD_H_"
  puts $fd "#define BOARD_H_"
  puts $fd "#define BOARD_NAME \"[string toupper $board_name]\""
  puts $fd "#define VITIS_VERSION \"$vitis_ver\""
  puts $fd "#define BOARD_[string toupper $board_name] 1"
  puts $fd "#endif"
  close $fd
}

# Add the local software repo to the workspace
proc add_local_software_repo {workspace_dir} {
  # Check if the software repo is already in the workspace
  set embsw [file normalize "${workspace_dir}/embeddedsw"]
  set sw_repos [repo -get]
  if {[string first $embsw $sw_repos] >= 0} {
    puts "Local software repo (embeddedsw) already in workspace."
  } else {
    puts "Adding local software repo (embeddedsw) to the workspace."
    repo -set $embsw
  }
}

# Create the platform
proc create_platform {xsa_file platform_name support_app} {
  platform create -name ${platform_name} -hw ${xsa_file}
  platform write
  set proc_instance [get_processor_from_platform $platform_name]
  # Microblaze and Zynq ARM are 32-bit, ZynqMP ARM and Versal are 64-bit processors
  if {$proc_instance == "psu_cortexa53_0" || [str_contains $proc_instance "psv_cortexa72_0"]} {
    set arch_bit "64-bit"
  } else {
    set arch_bit "32-bit"
  }
  # Create a standalone domain
  domain create -name {standalone_domain} \
    -display-name "standalone on $proc_instance" \
    -os {standalone} \
    -proc $proc_instance \
    -runtime {cpp} \
    -arch $arch_bit \
    -support-app $support_app
  platform write
  # Custom modifications to the platform
  custom_platform_mods $platform_name
}

# Generates the boot files for Microblaze designs
proc microblaze_boot_files {workspace_dir xsa_file app_name proc_instance target} {
  global mb_combine_bit_elf
  global vivado_postfix
  set vivado_path [file dirname $xsa_file]
  set xsa_filename [file tail $xsa_file]
  set wrapper_name [file rootname $xsa_filename]
  set block_design [string map [list "_wrapper" ""] $wrapper_name]
  set vivado_folder [file tail $vivado_path]
  if {$mb_combine_bit_elf} {
    # Generate the download.bit file with combined .bit and .elf
    exec updatemem --bit "${vivado_path}/${vivado_folder}.runs/impl_1/${wrapper_name}.bit" \
      --meminfo "${vivado_path}/${vivado_folder}.runs/impl_1/${wrapper_name}.mmi" \
      --data "${workspace_dir}/${app_name}/Debug/${app_name}.elf" \
      --proc "${block_design}_i/$proc_instance" \
      -force --out "./boot/${target}/${target}.bit"
    # Delete the logfiles generated by updatemem
    file delete "updatemem.log" "updatemem.jou"
  } else {
    # Just copy the bitstream and .elf
    puts "Copying bitstream and elf for $vivado_folder project."
    # Copy the bitstream and elf file to the boot folder
    file copy -force "${vivado_path}/${vivado_folder}.runs/impl_1/${wrapper_name}.bit" "./boot/${target}/${target}.bit"
    file copy -force "${workspace_dir}/${app_name}/Debug/${app_name}.elf" "./boot/${target}"
  }
}

# Function to prepend a string to file paths in "file =" lines
proc prepend_to_file_paths {file_data prepend_string} {
  # Split file data into lines
  set lines [split $file_data "\n"]
  
  # Loop through the lines and modify those with "file ="
  foreach line $lines {
    if {[regexp {file\s*=\s*(.*)} $line match filepath]} {
      # Prepend the string to the file path
      set modified_filepath "${prepend_string}[string trim $filepath]"
      set modified_line [string map "$filepath $modified_filepath" $line]
      lappend modified_lines $modified_line
    } else {
        # Keep the line unchanged if it doesn't match
      lappend modified_lines $line
    }
  }

  # Join the modified lines back into the file content
  return [join $modified_lines "\n"]
}

# Function to append new content before the last closing curly brace
proc append_to_outermost_curly_brace {file_content new_content} {
  # Find the last closing curly brace position
  set last_curly_pos [string last "\}" $file_content]
  
  # If no closing curly brace is found, we have a problem with the file structure
  if {$last_curly_pos == -1} {
    error "No closing curly brace found in the file"
  }
  
  # Insert the new content before the last closing curly brace
  set new_file_data [string range $file_content 0 [expr {$last_curly_pos - 1}]]
  append new_file_data $new_content "\n\}"
  
  return $new_file_data
}

# Function to generate boot.bif and BOOT.BIN files for a Versal device
proc versal_boot_files {workspace_dir xsa_file vivado_path vivado_folder app_name} {
  set xsa_filename [file tail $xsa_file]
  set wrapper_name [file rootname $xsa_filename]
  set workspace_boot_path "${workspace_dir}/boot"
  set bif_src_path "${vivado_path}/${vivado_folder}.runs/impl_1/${wrapper_name}.bif"
  set bif_dst_path "${workspace_boot_path}/boot.bif"
  set boot_bin_path "${workspace_boot_path}/BOOT.BIN"
  puts "bif source: $bif_src_path"
  puts "bif desg: $bif_dst_path"
  # Create directory for the boot file if it doesn't already exist
  if {[file exists $workspace_boot_path] == 0} {
    file mkdir $workspace_boot_path
  }
  # Copy the bif file from the Vivado implementation
  file copy -force $bif_src_path $bif_dst_path
  # Read the bif file content
  set bif_file_content [read [open $bif_dst_path r]]
  # Define the new image and partition content to append
  set new_image_block " image
 {
  name = user_subsystem
  id = 0x1c000000
  partition
  {
   core = a72-0
   file = ${workspace_dir}/${app_name}/Debug/${app_name}.elf
  }
 }"
  set prepend_path "${vivado_path}/${vivado_folder}.runs/impl_1/"
  # Get the modified content with updated file paths
  set modified_content [prepend_to_file_paths $bif_file_content $prepend_path]

  # Append the new content and get the final modified content
  set final_content [append_to_outermost_curly_brace $modified_content $new_image_block]

  # Write the final content back to the file
  set file_handle [open $bif_dst_path w]
  puts $file_handle $final_content
  close $file_handle

  # Use bootgen to generate the BOOT.BIN file
  exec bootgen -arch versal -image $bif_dst_path -o $boot_bin_path -w on
}

# Creates Vitis workspace for a project
proc create_vitis_ws {workspace_dir target target_dict vivado_dir app_name support_app template_app} {
  global vivado_postfix

  # Copy original library sources into the local Vitis repo
  if {[file exists "../EmbeddedSw"]} {
    puts "Creating the local embeddedsw repo from original sources"
    create_local_embeddedsw $workspace_dir
  }
  
  set design_prefix [string range $vivado_postfix 1 end]
  # Verify the xsa file exists in the vivado folder
  set file_list [glob -nocomplain "$vivado_dir/$target/*.xsa"]
  if {[llength $file_list] != 0} {
    set xsa_file [lindex $file_list 0]
  } else {
    puts "### XSA file not found for target $target ###"
    puts "You must build and export the Vivado project before building the Vitis workspace."
    exit 1
  }
  
  # Create "boot" directory if it doesn't already exist
  if {[file exists "./boot"] == 0} {
    file mkdir "./boot"
  }
  
  # Set the workspace directory
  setws $workspace_dir
  
  # Add local software repo to workspace
  if {[file exists "../EmbeddedSw"]} {
    add_local_software_repo $workspace_dir
  }

  # Get a list of platforms and apps already in the workspace
  set list_of_platforms [get_list_of_platforms]
  set list_of_apps [get_list_of_apps]
  
  set vivado_path [file dirname $xsa_file]
  set vivado_folder [file tail $vivado_path]
  set platform_name $target
  set sysproj_name "${app_name}_system"
  set sysproj_build 0

  print_platform $platform_name "XSA path:\n    $xsa_file"
  # -----------------------------------------------------
  # PLATFORM: Create the platform for this Vivado project
  # -----------------------------------------------------
  # If the platform has been created
  if {$platform_name in $list_of_platforms} {
    print_platform $platform_name "Platform already exists in the workspace."
    # If the .xsa needs updating
    if {[xsa_needs_updating $workspace_dir $xsa_file $platform_name]} {
      print_platform $platform_name "Hardware XSA file has changed."
      print_platform $platform_name "Cleaning platform."
      platform active $platform_name
      platform clean
      print_platform $platform_name "Cleaning system project."
      clean_sysproj $sysproj_name
      print_platform $platform_name "Updating hardware."
      platform config -updatehw $xsa_file
    }
    # If the platform is not compiled, we recreate from scratch because
    # we don't know what config or mods have been done and what hasn't
    if {[file exists "$workspace_dir/$platform_name/export/$platform_name"] == 0} {
      print_platform $platform_name "Platform is not built. Recreating platform."
      # Delete the platform
      platform remove $platform_name
      # Recreate the platform from scratch
      create_platform $xsa_file $platform_name $support_app
      platform active $platform_name
      platform generate
      set sysproj_build 1
    }
  # If the platform doesn't exist, the create it
  } else {
    print_platform $platform_name "Creating Platform for $platform_name."
    # Create the platform
    create_platform $xsa_file $platform_name $support_app
    platform active $platform_name
    platform generate
    # If the system project is already in the workspace, then clean sysproj
    if {$app_name in $list_of_apps} {
      clean_sysproj $sysproj_name
    }
    set sysproj_build 1
  }
  # ---------------------------------------------
  # APPLICATION: Generate the example application
  # ---------------------------------------------
  # If the application has already been created and built, then skip
  if {[file exists "$workspace_dir/$app_name/Debug/${app_name}.elf"] == 1} {
    print_app $app_name "Already built."
  # If the application has already been created but not built, then build
  } elseif {$app_name in $list_of_apps} {
    print_app $app_name "Exists but not built."
    app clean -name $app_name
    app build -name $app_name
    set sysproj_build 1
  # If the app doesn't exist then create and build it
  } else {
    print_app $app_name "Creating application."
    # Create the application for standalone domain
    app create -name $app_name \
      -template $template_app \
      -platform ${platform_name} \
      -domain {standalone_domain}
    # Custom modifications to the app
    custom_app_mods $platform_name $app_name $workspace_dir
    # Create the board.h file
    create_board_h [lindex [dict get $target_dict $target] 0] "$workspace_dir/${app_name}/src"
    # Build the application
    print_app $app_name "Building application."
    app build -name $app_name
    set sysproj_build 1
  }
  # ---------------------------------------------------------
  # SYSPROJ: Build the system project and copy the boot files
  # ---------------------------------------------------------
  if {$sysproj_build} {
    print_sysproj $sysproj_name "Building system project."
    sysproj build -name $sysproj_name
  }
  # If all required files exist, then generate boot files
  # Create directory for the boot file if it doesn't already exist
  if {[file exists "./boot/$target"] == 0} {
    print_sysproj $sysproj_name "Creating the boot folder."
    file mkdir "./boot/$target"
  }
  # Get the processor instance name
  set proc_instance [get_processor_from_platform $platform_name]
  # For Microblaze designs
  if {[str_contains $proc_instance "microblaze"]} {
    print_sysproj $sysproj_name "Creating bitstream and copying to the ./boot/${target} directory."
    microblaze_boot_files $workspace_dir $xsa_file $app_name $proc_instance $target
  # For Versal designs
  } elseif {[str_contains $proc_instance "psv_cortexa72_0"]} {
    print_sysproj $sysproj_name "Creating the BOOT.BIN file and copying to the ./boot/${target} directory."
    versal_boot_files $workspace_dir $xsa_file $vivado_path $vivado_folder $app_name
    set bootbin_file "${workspace_dir}/boot/BOOT.BIN"
    if {[file exists $bootbin_file] == 1} {
      file copy -force $bootbin_file "./boot/${target}"
    }
  # For Zynq and Zynq MP designs
  } else {
    print_sysproj $sysproj_name "Copying the BOOT.BIN file to the ./boot/${target} directory."
    # Copy the already generated BOOT.BIN file
    set bootbin_file "${workspace_dir}/${sysproj_name}/Debug/sd_card/BOOT.BIN"
    if {[file exists $bootbin_file] == 1} {
      file copy -force $bootbin_file "./boot/${target}"
    } else {
      print_sysproj $sysproj_name "No BOOT.BIN file found."
    }
  }
}

# Function to display the target design options and get selection from the user
# This gets called when the build script is run without any arguments
proc select_target {target_dict} {
  # Create a list to hold the keys in order
  set keys_list [dict keys $target_dict]
  set keys_list [lsort $keys_list]

  puts "------------------------"
  puts " SELECT A TARGET DESIGN"
  puts "------------------------"
  puts ""

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



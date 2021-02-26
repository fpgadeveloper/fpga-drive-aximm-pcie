# -------------------------------------------------------------------------------------
# Opsero Electronic Design Inc. Copyright 2021
# -------------------------------------------------------------------------------------
# *** VITIS WORKSPACE BUILDER SCRIPT ***
#
# This script is called by the main script (build-vitis.tcl) and it's job is to 
# create the Vitis workspace based on the variables and functions defined in
# the main script.
#
# These are the steps in workspace creation:
#
# (1) Create the local software repository:
#     If there is an "EmbeddedSw" folder in the project root, then create a local
#     software repo inside the Vitis workspace called "embeddedsw". The local software
#     repo is then filled with the contents of "EmbeddedSw" and the remaining sources
#     are copied from the Vitis installation.
# (2) Look for exported Vivado projects:
#     The script will search the folders in the "vivado_dirs" list variable, looking
#     for .xsa files.
# (3) Create the platform and application for each .xsa file:
#     The script will create a platform and stand-alone application for each .xsa file.
#     The application to create must be specified by the "support_app" and 
#     "template_app" variables. The name of the application will be the "app_postfix"
#     variable appended to the board name.
# (4) Copy boot files into boot folder:
#     The script will create a "boot" folder inside the Vitis workspace and copy the
#     boot files for each project into the folder.
# (5) Check all applications:
#     The script will check each application and report build status (success or 
#     failure).
#
# Usage notes:
#
# * Once this script has built the Vitis workspace, it can be run again to incorporate
#   changes, without rebuilding everything. For example:
#     - If the Vivado project changes (.xsa) and is re-exported, run the build script
#       again to rebuild the platform and application for that .xsa.
#     - If an application did not build the first time, and you have made modifications
#       to fix the issue, run the build script again to rebuild the application.
# * To remove a platform or application from the workspace, you will have to open the
#   workspace in Vitis and perform the delete from the IDE. You can then use the build
#   script to recreate the platform and application.
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
proc create_local_embeddedsw {} {
  # Xilinx Vitis install directory
  set vitis_dir $::env(XILINX_VITIS)
  # Copy the EmbeddedSw folder into the Vitis workspace
  file mkdir "embeddedsw"
  copy-r "../EmbeddedSw" "embeddedsw"
  # List all of the "src" or "data" directories so that we know what to copy
  # from the Vitis installation original driver sources
  set local_dirs [glob-dir-r "embeddedsw" src data]
  set orig_dirs {}
  foreach d $local_dirs {
    if {[string index $d end] == "9"} {
      lappend orig_dirs [string replace "$vitis_dir/data/$d" end end ""]
    } else {
      lappend orig_dirs "$vitis_dir/data/$d"
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
    if {[string match {[a-z]*} $line]} {
      append list_of_apps "$line "
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
proc xsa_needs_updating {xsa_file platform_name} {
  # If the .xsa needs updating
  set xsa_local_copy "$platform_name/hw/${platform_name}.xsa"
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
  set vitis_dir $::env(XILINX_VITIS)
  set vitis_ver [lindex [file split $vitis_dir] end]
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

# Returns list of Vivado projects in the given directory
proc get_vivado_projects {vivado_dir} {
  # Create the empty list
  set vivado_proj_list {}
  # Make a list of all subdirectories in Vivado directory
  foreach {vivado_proj_dir} [glob -type d "${vivado_dir}/*"] {
    # Get the vivado project name from the project directory name
    set vivado_proj [lindex [split $vivado_proj_dir /] end]
    # Ignore directories returned by glob that don't contain an underscore
    if { ([string first "_" $vivado_proj] == -1) } {
      continue
    }
    # Add the Vivado project to the list
    lappend vivado_proj_list $vivado_proj
  }
  return $vivado_proj_list
}

# Add the local software repo to the workspace
proc add_local_software_repo {vitis_dir} {
  # Check if the software repo is already in the workspace
  set embsw [file normalize "${vitis_dir}/embeddedsw"]
  set sw_repos [repo -get]
  if {[string first $embsw $sw_repos] >= 0} {
    puts "Local software repo (embeddedsw) already in workspace."
  } else {
    puts "Adding local software repo (embeddedsw) to the workspace."
    repo -set $embsw
  }
}

# Create the platform
proc create_platform {xsa_file platform_name} {
  global support_app
  platform create -name ${platform_name} -hw ${xsa_file}
  platform write
  set proc_instance [get_processor_from_platform $platform_name]
  # Microblaze and Zynq ARM are 32-bit, ZynqMP ARM are 64-bit processors
  if {$proc_instance == "psu_cortexa53_0"} {
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
proc microblaze_boot_files {vivado_path app_name proc_instance} {
  global mb_combine_bit_elf
  set vivado_folder [file tail $vivado_path]
  if {$mb_combine_bit_elf} {
    # Generate the download.bit file with combined .bit and .elf
    exec updatemem --bit "${vivado_path}/${vivado_folder}.runs/impl_1/${vivado_folder}_wrapper.bit" \
      --meminfo "${vivado_path}/${vivado_folder}.runs/impl_1/${vivado_folder}_wrapper.mmi" \
      --data "./${app_name}/Debug/${app_name}.elf" \
      --proc "${vivado_folder}_i/$proc_instance" \
      -force --out "./boot/${vivado_folder}/${vivado_folder}.bit"
    # Delete the logfiles generated by updatemem
    file delete "updatemem.log" "updatemem.jou"
  } else {
    # Just copy the bitstream and .elf
    puts "Copying bitstream and elf for $vivado_folder project."
    # Copy the bitstream and elf file to the boot folder
    file copy "${vivado_path}/${vivado_folder}.runs/impl_1/${vivado_folder}_wrapper.bit" "./boot/${vivado_folder}"
    file copy "./${app_name}/Debug/${app_name}.elf" "./boot/${vivado_folder}"
  }
}

# Creates Vitis workspace for a project
proc create_vitis_ws {vivado_dirs} {
  global app_postfix
  global vivado_postfix
  global support_app
  global template_app
  # First make sure there is at least one exported Vivado project
  set xsa_files {}
  # For each of the Vivado dirs
  foreach {vivado_dir} $vivado_dirs {
    # Check each Vivado project for export files
    foreach {vivado_folder} [get_vivado_projects $vivado_dir] {
      # If the hardware has been exported for Vitis
      set xsa_file "$vivado_dir/$vivado_folder/${vivado_folder}_wrapper.xsa"
      if {[file exists $xsa_file]} {
        lappend xsa_files $xsa_file
      }
    }
  }
  
  set exported_projects [llength $xsa_files]
  # If no projects then exit
  if {$exported_projects == 0} {
    puts "### There are no exported Vivado projects ###"
    puts "You must build and export a Vivado project before building the Vitis workspace."
    exit
  }
  puts "Found $exported_projects exported Vivado projects:"
  foreach {xsa_file} $xsa_files { puts "  $xsa_file" }
  
  # Create "boot" directory if it doesn't already exist
  if {[file exists "./boot"] == 0} {
    file mkdir "./boot"
  }
  
  # Set the workspace directory
  set vitis_dir [pwd]
  puts "Vitis workspace: $vitis_dir"
  setws $vitis_dir
  
  # Add local software repo to workspace
  if {[file exists "../EmbeddedSw"]} {
    add_local_software_repo $vitis_dir
  }

  # Get a list of platforms and apps already in the workspace
  set list_of_platforms [get_list_of_platforms]
  set list_of_apps [get_list_of_apps]
  
  # Add each exported Vivado project to Vitis workspace
  foreach {xsa_file} $xsa_files {
    set xsa_filename_only [file tail $xsa_file]
    set platform_name [file rootname $xsa_filename_only]
    set vivado_path [file dirname $xsa_file]
    set vivado_folder [file tail $vivado_path]
    set board_name [string map [list $vivado_postfix ""] $vivado_folder]
    set app_name "${board_name}$app_postfix"
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
      if {[xsa_needs_updating $xsa_file $platform_name]} {
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
      if {[file exists "$platform_name/export/$platform_name"] == 0} {
        print_platform $platform_name "Platform is not built. Recreating platform."
        # Delete the platform
        platform remove $platform_name
        # Recreate the platform from scratch
        create_platform $xsa_file $platform_name
        platform active $platform_name
        platform generate
        set sysproj_build 1
      }
    # If the platform doesn't exist, the create it
    } else {
      print_platform $platform_name "Creating Platform for $xsa_filename_only."
      # Create the platform
      create_platform $xsa_file $platform_name
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
    if {[file exists "$app_name/Debug/${app_name}.elf"] == 1} {
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
      custom_app_mods $platform_name $app_name
      # Create the board.h file
      set board_name_only [string map {_hpc0 "" _hpc1 "" _hpc2 "" _lpc0 "" _lpc1 "" _lpc2 "" _hpc "" _lpc "" _dual ""} $board_name]
      create_board_h $board_name_only "${app_name}/src"
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
      # If all required files exist, then generate boot files
      # Create directory for the boot file if it doesn't already exist
      if {[file exists "./boot/$vivado_folder"] == 0} {
        file mkdir "./boot/$vivado_folder"
      }
      # Get the processor instance name
      set proc_instance [get_processor_from_platform $platform_name]
      # For Microblaze designs
      if {[str_contains $proc_instance "microblaze"]} {
        microblaze_boot_files $vivado_path $app_name $proc_instance
      # For Zynq and Zynq MP designs
      } else {
        print_sysproj $sysproj_name "Copying the BOOT.BIN file to the ./boot/${vivado_folder} directory."
        # Copy the already generated BOOT.BIN file
        set bootbin_file "./${sysproj_name}/Debug/sd_card/BOOT.BIN"
        if {[file exists $bootbin_file] == 1} {
          file copy -force $bootbin_file "./boot/${vivado_folder}"
        } else {
          print_sysproj $sysproj_name "No BOOT.BIN file found."
        }
      }
    }
  }
}

# Checks all applications
proc check_apps {} {
  global app_postfix
  # Set the workspace directory
  setws [pwd]
  puts "Checking build status of all applications:"
  # Get list of applications
  foreach {app_dir} [glob -type d "./*$app_postfix"] {
    # Get the app name
    set app_name [lindex [split $app_dir /] end]
    if {[file exists "$app_dir/Debug/${app_name}.elf"] == 1} {
      puts "  SUCCESS: ${app_name} was built"
    } else {
      puts "  ERROR: ${app_name} failed to build"
    }
  }
}
  
# Copy original library sources into the local Vitis repo
if {[file exists "../EmbeddedSw"]} {
  puts "Building the local Vitis repo from original sources"
  create_local_embeddedsw
}

# Create the Vitis workspace
puts "Creating the Vitis workspace"
create_vitis_ws $vivado_dirs
check_apps

exit

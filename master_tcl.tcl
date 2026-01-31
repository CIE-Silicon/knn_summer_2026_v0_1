# =========================================================================
# SoC Project Master Setup Script
# =========================================================================

# 1. Define paths relative to this script's location
set origin_dir [file normalize [file dirname [info script]]]
set script_dir [file join $origin_dir "SCRIPTS"]


puts "********************************************************"
puts " SOC PROJECT ROOT DETECTED AT:"
puts " $origin_dir"
puts "********************************************************"

# Define the relative path to your IP repository
set_property  ip_repo_paths  [file normalize "$origin_dir/IP_REPO"] [current_project]

# Refresh the catalog so Vivado "sees" the IPs inside
update_ip_catalog

# 2. Rebuild the Project Structure
# This runs the script you exported from Vivado
source [file join $script_dir "build_project.tcl"]

# 3. Rebuild the Block Design (BD)
# This draws the RISC-V SoC architecture
source [file join $script_dir "recreate_bd.tcl"]


puts "-------------------------------------------------------"
puts " SoC Project Rebuild Complete! "
puts "-------------------------------------------------------"

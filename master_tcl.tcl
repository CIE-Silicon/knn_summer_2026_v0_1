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



# 2. Rebuild the Project 

source [file join $script_dir "build_project.tcl"]


puts "-------------------------------------------------------"
puts " SoC Project Rebuild Complete! "
puts "-------------------------------------------------------"

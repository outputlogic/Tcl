
# set rams [get_cells -hier -filter {REF_NAME=~RAMB36*}]

# Include RAMB36/RAMB18/FIFO
set rams [get_cells -hier -filter {PRIMITIVE_GROUP==BMEM}]

set FH [open rams_placement.tcl w]
puts $FH [format "
set placement \[list \\"]
foreach cell [lsort -dictionary $rams] {
  set loc [get_property -quiet LOC $cell]
  set bel [get_property -quiet BEL $cell]
  set placement "$loc/[lindex [split $bel .] end]"
  puts $FH [format "   %s\t%s \\" $cell $placement]
}
puts $FH [format "  \]

if {\[catch {place_cell \$placement} errorstring\]} {
  puts \" -E- \$errorstring\"
} else {
  puts \" -I- placement completed\"
}
"]
close $FH

# The following code is too slow. Replaced by the code above
# set FH [open rams_placement.tcl w]
# foreach cell $rams {
#   puts $FH [format {set_property {%s} {%s} [get_cells {%s}]} LOC [get_property -quiet LOC $cell] $cell]
#   puts [format {set_property {%s} {%s} [get_cells {%s}]} LOC [get_property -quiet LOC $cell] $cell]
# }
# close $FH

# Example of exported format:
#  set placement [list \
#     core_u/classification_u1/CLA_PRI_TABLE_DRAM/ram_data_1_ram_data_1_0_0	RAMB36_X1Y25/RAMB36E1 \
#     core_u/desegment_u1/BLOCK_LIST_RAM_u/ram_data_1_ram_data_1_0_0	RAMB36_X8Y15/RAMB36E1 \
#     core_u/desegment_u1/BLOCK_LIST_RAM_u/ram_data_1_ram_data_1_0_2	RAMB36_X8Y16/RAMB36E1 \
#     core_u/desegment_u1/BLOCK_STORE_u/ram_data_1_ram_data_1_0_0	RAMB36_X10Y25/RAMB36E1 \
#     ...
#     core_u/y1564_mon_u1/y1564Mon_frame_capture_storage_bram/ram_data_ram_data_0_1	RAMB36_X1Y55/RAMB36E1 \
#    ]
#  
#  if {[catch {place_cell $placement} errorstring]} {
#    puts " -E- $errorstring"
#  } else {
#    puts " -I- placement completed"
#  }

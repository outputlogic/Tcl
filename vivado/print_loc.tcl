
# Proc to reload current script
proc [file tail [info script]] {} " source [info script]; puts \" [info script] reloaded\" "


# David Pefourque
#
# This script iterates through all the clocks and search for for each
# clock domain all the endpoints matching a register (LIB_CELL: =~ FD*).
# Then it prints the endpoint name, lib_cell and coordonates.
#
# For example:
#
#  Processing clock XYZ
#  Location information
#  -I- Number of cells: 124
#     <cell>	FDCE	X111	Y375
#     <cell>	FDCE	X104	Y374
#     <cell>	FDSE	X106	Y377


proc get_ffs_by_clock {clockName} {
  set clock [get_clocks -quiet $clockName]
  if {$clock  == {}} { error " Clock $clockName does not exist" }
  set sourcePins [get_pins -quiet [get_property source_pins $clock]]
  if {$sourcePins == {}} {
    set sourcePins [get_ports -quiet [get_property source_pins $clock]]
    puts " -I- Source port(s): $sourcePins"
  } else {
    puts " -I- Source pin(s): $sourcePins"
  }
  if {$sourcePins == {}} {
    error " Cannot find any source pin for clock $clockName"
  }
  set endpoints [list]
  # Get all the endpoints. Iterate through all the source pins
  foreach pin $sourcePins {
#     puts " -D- Getting fanout of $pin :"
#     set fanout [eval [concat all_fanout $pin -flat -only_cells -endpoints_only]]
    # Get all the components in the transitive fanout of the clock
    set fanout [eval [concat all_fanout $pin -flat -only_cells]]
    foreach elm $fanout {
#       puts " -D-          $elm"
    }
    set endpoints [concat $endpoints $fanout]
  }
  if {$endpoints == {}} {
    puts " -W- no endpoint found"
    return [list]
  }
  # Filter the list to only keep the registers (FD*)
#   set endpoints [filter [get_cells $endpoints] {LIB_CELL =~ FD*}]
  puts " -I- Number of endpoints: [llength $endpoints]"
  puts " -I- Endpoints: $endpoints"
  return $endpoints
}

proc print_loc {cells} {
  global FH
  puts " -I- Number of cells: [llength $cells]"
#   set cells [lrange $cells 0 5]
  foreach cell [lsort [get_cells -quiet $cells]] {
    set LOC [get_property -quiet LOC $cell]
    if {$LOC == {}} {
      puts " -E- cannot extract location from cell $cell"
      puts $FH " -E- cannot extract location from cell $cell"
      continue
    }
    set LIB_CELL [get_property -quiet LIB_CELL $cell]
    set X {N/A}; set Y {N/A}
    regexp {^.*X([0-9]+)Y([0-9]+)$} $LOC -- X Y
    puts [format "      %s\t%s\t%s\t%s" $cell $LIB_CELL X${X} Y${Y}]
    puts $FH [format "      %s\t%s\t%s\t%s" $cell $LIB_CELL X${X} Y${Y}]
  }
}

set filename {print_loc.rpt}
set FH [open $filename {w}]

foreach clock [get_clocks] {
  puts "\n Processing clock $clock"
  puts $FH "\n Processing clock $clock"
  if {[catch {set cells [get_ffs_by_clock $clock]} errorstring]} {
    puts " -E- $errorstring"
    puts $FH " -E- $errorstring"
    continue
  }
  puts "   Clock source pin(s): [get_property source_pins $clock]"
  puts $FH "   Clock source pin(s):"
  foreach pin [get_property source_pins $clock] {
    if {[get_pins $pin -quiet] != {}} {
      set pin [get_pins $pin]
      set LOC [get_property LOC [get_cells -of $pin]]
      set LIB_CELL [get_property LIB_CELL [get_cells -of $pin]]
    } elseif {[get_ports $pin -quiet] != {}} {
      set pin [get_ports $pin]
      set LOC [get_property LOC $pin]
      set LIB_CELL {<PORT>}
    } else {
      puts " -E- cannot determine whether the pin $pin is a pin or a port"
      puts $FH " -E- cannot determine whether the pin $pin is a pin or a port"
      continue
    }
    puts [format "      %s\t%s\t%s" $pin $LIB_CELL $LOC]
    puts $FH [format "      %s\t%s\t%s" $pin $LIB_CELL $LOC]
  }
  puts "   Number of elements: [llength $cells]"
  puts $FH "   Number of elements: [llength $cells]"
  puts "   Location information"
  puts $FH "   Location information"
  print_loc $cells
}

close $FH
puts "\n File $filename has been generated\n"

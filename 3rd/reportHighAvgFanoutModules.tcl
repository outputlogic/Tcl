##
## fred
##

###############################################################################
# Xilinx Inc.
###############################################################################
# 2013/12/09 - initial version 1.0
###############################################################################
# 2013/12/09 - version 1.0a: fixed dependency on csvFile + removed useless vars
###############################################################################

proc reportHighAvgFanoutModules {{maxLvl 1} {csvFile "avgFanout"} {curLvl 0}} {
  if {$curLvl == 0} {
    # For the current level (default: top-level), generate CSV file header + stats report
    set CSV [open ${csvFile}.csv w]
    puts $CSV [join [list avgFanout cellCount LUT DMEM FLOP_LATCH BMEM MULT LUT1 LUT2 LUT3 LUT4 LUT5 LUT6 hierInst] ,]
    close $CSV
    reportAvgFanout $csvFile [llength [get_ports]]
  }

  # Reporting each hierarchical module at the current level
  set hierCells [get_cells -quiet -filter {!IS_PRIMITIVE}]
  if {$hierCells == {}} {return}
  foreach hierCell [lsort $hierCells] {
    set pcSubst [regsub {[][{};#\\\$\s\u0080-\uffff]} [get_property PARENT $hierCell] {\\\0}]
    set scopeCell [regsub "^$pcSubst\[/\]?" [get_property NAME $hierCell] {}]
    set hierPinCount [llength [get_nets -quiet -filter {TYPE == SIGNAL} -of [get_pins -of $hierCell]]]
    if {$hierPinCount == 0} { puts "Zero pin on hier cell $hierCell - skipping..."; continue }
    # Changing scope to hierarchical cell
    current_instance $scopeCell -quiet
    set code [reportAvgFanout $csvFile $hierPinCount]
    if {$maxLvl >= [expr $curLvl + 1] && $code == 0} {
      reportHighAvgFanoutModules $maxLvl $csvFile [expr $curLvl + 1]
    }
    # Changing scope back to 
    current_instance .. -quiet
  }
}

proc reportAvgFanout {{csvFile ""} {portCount 0}} {
  set nets [get_nets -quiet -hier -top_net_of_hierarchical_group -filter {TYPE == SIGNAL}]
  if {$nets == {}} {return 4}
  set netCount [llength $nets]
  set accFanout [expr [join [get_property FLAT_PIN_COUNT $nets] +] - $netCount]
  set avgFanout [format "%.2f" [expr 1.0 * $accFanout / $netCount]]
  set cells [get_cells -of [get_pins -leaf -of $nets]]
  set netCellCount [llength $cells]
  if {$netCellCount < 50000} {return 2}
  set leafCells [get_cells -hier -filter {IS_PRIMITIVE && PRIMITIVE_LEVEL != MACRO}]
  set leafCellCount [llength $leafCells]
  if {$leafCellCount < 50000} {return 3}
  puts [format "+ Average Fanout: %-5s - Hier Cells: %-8s - Hier Instance: %s" $avgFanout $leafCellCount [current_instance . -quiet]]
  if {$csvFile != ""} {
    set leafRefNames [get_property REF_NAME $leafCells]
    set refNames [lsort -unique $leafRefNames]
    foreach refName {LUT1 LUT2 LUT3 LUT4 LUT5 LUT6} { set refCount($refName) 0 }
    foreach refName $refNames {
      set refCount($refName) [llength [lsearch -all -exact $leafRefNames $refName]]
    }
    set primGroups {LUT DMEM FLOP_LATCH BMEM MULT}
    foreach pg $primGroups { set pgCount($pg) 0 }
    foreach refName $refNames {
      set libCell [get_lib_cells $refName -quiet]
      if {$libCell == {}} {continue}
      set pg [get_property PRIMITIVE_GROUP $libCell]
      if {[lsearch -exact $primGroups $pg] == -1} { continue }
      incr pgCount($pg) $refCount($refName)
    }
    if {![info exist pgCount(LUT)] || $pgCount(LUT) == 0} { set pgCount(LUT) 1 }
    set csvList [list $avgFanout $leafCellCount]
    foreach pg $primGroups { lappend csvList $pgCount($pg) }
    foreach refName {LUT1 LUT2 LUT3 LUT4 LUT5 LUT6} {
      lappend csvList [format "%.2f" [expr 1.0 * $refCount($refName) / $pgCount(LUT)]]
    }
    lappend csvList [current_instance . -quiet]
    set CSV [open ${csvFile}.csv a]
    puts $CSV [join $csvList ,]
    close $CSV
  }
  return 0
}

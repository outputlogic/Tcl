
# Original script from Fred
# /home/frederi/patcl/apps/avgFanout.tcl
# Minor update to add CARRY/MUX to the report

proc hierAvgFanout {{showDistrib all} {maxLvl 1} {csvFile "avgFanout"} {minModSize 20000} {startLvl 0} {curLvl 0}} {
  if {$curLvl == 0} {
    set CSV [open ${csvFile}.csv w]
    puts $CSV [join [list nAvgFanout hAvgFanout netRentExp hieRentExp nAccFanout hAccFanout netCount netCell hierCell LUT DMEM FLOP_LATCH BMEM MULT MUXFX CARRY LUT1 LUT2 LUT3 LUT4 LUT5 LUT6 hierInst] ,]
    close $CSV
  }
  if {$maxLvl < $curLvl} {return}
  if {$curLvl == 0 && [current_instance . -quiet] == [get_property TOP [current_design]]} {
      set code [reportAvgFanout $showDistrib $csvFile [llength [get_nets -filter {TYPE == SIGNAL} -of [get_ports] -quiet]] 1]
  }
  set hierCells [get_cells -quiet -filter {!IS_PRIMITIVE}]
  if {$hierCells == {}} {return}
  foreach hierCell [lsort $hierCells] {
    #puts "\nhierCell:  $hierCell"
    set pcSubst [regsub {[][{};#\\\$\s\u0080-\uffff]} [get_property PARENT $hierCell] {\\\0}]
    set scopeCell [regsub "^$pcSubst\[/\]?" [get_property NAME $hierCell] {}]
    #puts "scopeCell: $scopeCell"
    set hierPinCount [llength [get_nets -quiet -filter {TYPE == SIGNAL} -of [get_pins -of $hierCell]]]
    if {$hierPinCount == 0} { puts "Zero pin on hier cell $hierCell"; continue }
    current_instance $scopeCell -quiet
    #puts "currInst:  [current_instance . -quiet]"
    if {$startLvl <= $curLvl} {
      set code [reportAvgFanout $showDistrib $csvFile $hierPinCount $minModSize]
    } else {
      set code 5
    }
    #puts "code: $code - curLvl: $curLvl - maxLvl: $maxLvl"
    #puts "curLvl: $curLvl - code: $code - [current_instance . -quiet]"
    if {$maxLvl >= [expr $curLvl + 1] && $code == 0} {
      hierAvgFanout $showDistrib $maxLvl $csvFile $minModSize $startLvl [expr $curLvl + 1]
    }
    current_instance .. -quiet
  }
}

proc reportAvgFanout {{showDistrib "all"} {csvFile ""} {portCount 0} {minModSize 1} {cellName ""}} {
  set printRentDetails 1
  if {$portCount == 0 && [current_instance . -quiet] == [get_property TOP [current_design]]} {
    set portCount [llength [get_nets -filter {TYPE == SIGNAL} -of [get_ports] -quiet]]
  }
  #puts "nAvgFanout - $showDistrib - $csvFile - $cellName"
  set nets [get_nets -quiet -hier -top_net_of_hierarchical_group -filter {TYPE == SIGNAL}]
  if {$nets == {}} {return 4}
  set netCount [llength $nets]
  set nAccFanout [expr [join [get_property FLAT_PIN_COUNT $nets] +] - $netCount]
  set nAvgFanout [format "%.2f" [expr 1.0 * $nAccFanout / $netCount]]
  #if {$nAvgFanout < 3.85} {return 1}
  set nCells [get_cells -of [get_pins -leaf -of $nets]]
# Shouldn't we only take cells inside the modules instead? The line above grabs all the 
# connected cells
# set nCells [filter [get_cells -of [get_pins -leaf -of $nets]] "NAME =~ [current_instance . -quiet]/*"]
  set nCellCount [llength $nCells]
  #if {$nCellCount < $minModSize} {puts "nCellCount: $nCellCount - [current_instance . -quiet]"; return 2}
  if {$nCellCount < $minModSize} {return 2}
  set hCellCount [llength [get_cells -hier -filter {IS_PRIMITIVE && PRIMITIVE_LEVEL != MACRO}]]
  #if {$hCellCount < $minModSize} {puts "hCellCount: $hCellCount - [current_instance . -quiet]"; return 3}
  if {$hCellCount < $minModSize} {return 3}
  if {$cellName == {}} {
    puts "\nInstance: [current_instance . -quiet]"
  } else {
    puts "\nInstance: $cellName"
  }
  if {$portCount > 0} {
    # Rent of module + its connectivity
    set nAvgPins [expr 1.0 * ($nAccFanout + $netCount - $portCount) / $nCellCount]
    set nRentExp [format "%.2f" [expr 1.0 * (log($portCount) - log($nAvgPins)) / log($nCellCount)]]
    # Rent of hier module only
    if {[get_property TOP [current_design -quiet]] == [current_instance . -quiet]} {
      set hPins [get_pins -leaf -of $nets]
    } else {
      set hPins [get_pins -filter "NAME =~ [current_instance . -quiet]/*" -leaf -of $nets]
    }
    set hPinCount  [llength $hPins]
    set hAccFanout [expr $hPinCount + $portCount - $netCount]
    set hAvgFanout [format "%.2f" [expr 1.0 * $hAccFanout / $netCount]]
    set hCellCount [llength [get_cells -of $hPins]]
    set hAvgPins [expr 1.0 * $hPinCount / $hCellCount]
    set hRentExp [format "%.2f" [expr 1.0 * (log($portCount) - log($hAvgPins)) / log($hCellCount)]]
  } else {
    set nRentExp 0.00
    set hRentExp 0.00
  }
  puts [format "+ FlatAvgFo: %s (%s / %s) - HierAvgFo: %s (%s / %s) - nRent: %s - hRent: %s - Net Cells: %s - Hier Cells: %s" $nAvgFanout $nAccFanout $netCount $hAvgFanout $hAccFanout $netCount $nRentExp $hRentExp $nCellCount $hCellCount]
  if {$printRentDetails && $portCount > 0} {
    puts [format "  nRent-AvgPins: (%s - %s) / %s = %.2f -- ((netPinCount - portCount) / nCellCount)" [expr $nAccFanout + $netCount] $portCount $nCellCount $nAvgPins]
    puts [format "  nRent-RentExp: (%.2f - %.2f) / %.2f = %.2f -- ((log(portCount) - log(avgPins)) / log(nCellCount))" [expr log($portCount)] [expr log($nAvgPins)] [expr log($nCellCount)] $nRentExp]
    puts [format "  hRent-AvgPins: %s / %s = %.2f -- (hPinCount / hCellCount)" $hPinCount $hCellCount $hAvgPins]
    puts [format "  hRent-RentExp: (%.2f - %.2f) / %.2f = %.2f -- ((log(portCount) - log(avgPins)) / log(hCellCount))" [expr log($portCount)] [expr log($hAvgPins)] [expr log($hCellCount)] $hRentExp]
  }
  if {$showDistrib == "all" || $showDistrib == "summary" || $csvFile != ""} {
    set allRefNames [get_property REF_NAME $nCells]
    set refNames [lsort -unique $allRefNames]
    foreach refName {LUT1 LUT2 LUT3 LUT4 LUT5 LUT6} { set refCount($refName) 0 }
    foreach refName $refNames {
      set refCount($refName) [llength [lsearch -all -exact $allRefNames $refName]]
    }
    set primGroups {LUT DMEM FLOP_LATCH BMEM MULT MUXFX CARRY}
    foreach pg $primGroups { set pgCount($pg) 0 }
    set refTxt ""
    foreach refName $refNames {
      #set pg [get_property PRIMITIVE_GROUP [get_lib_cells $refName]]
      set libCell [get_lib_cells $refName -quiet]
      if {$libCell == {}} {continue}
      set pg [get_property PRIMITIVE_GROUP $libCell]
      if {[lsearch -exact $primGroups $pg] == -1} { continue }
      incr pgCount($pg) $refCount($refName)
      lappend refTxt [format "  %10s: %s" $refName $refCount($refName)]
    }
    if {$showDistrib == "all" || $showDistrib == "summary"} {
      puts "+ Cell distribution: summary"
      foreach pg $primGroups {
        puts [format "  %10s: %s" $pg $pgCount($pg)]
      }
    }
    if {$showDistrib == "all"} {
      puts "+ Cell distribution: details"
      puts [join $refTxt \n]
    }
  }
  if {$csvFile != ""} {
    if {![info exist pgCount(LUT)] || $pgCount(LUT) == 0} { set pgCount(LUT) 1 }
    set csvList [list $nAvgFanout $hAvgFanout $nRentExp $hRentExp $nAccFanout $hAccFanout $netCount $nCellCount $hCellCount]
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

# % source reportReplication.tcl –notrace
# % reportReplication replication.csv
# 
# Several options:
# 1)	Undo ALL replications
# % undoReplication 0 replication.csv
# 
# 2)	Undo replication of control signal drivers only
# % undoReplication 1 replication.csv
# 
# 3)	Undo replication of selected cells only (cell names are based on what reportReplication prints in the log file or csv)
# % set listOfRepCells {cellA cellB…}
# % foreach cell $listOfRepCells {
#       lappend removeCells [combineReplicatedCells $cell 1]
# }
# % remove_cell $removeCells

proc reportReplication {{csvFile "replication.csv"} {timing 0} {LUTs 0}} {

  set mCellNotFound 0
  set nbPhysOptRepCells 0
  set nbCustomRepCells 0
  
  if {$LUTs} {
    set repCells [get_cells -hier {*_rep*} -filter {PRIMITIVE_SUBGROUP == LUT}]
    lappend repCells [get_cells -quiet -hier {*_hdup*} -filter {PRIMITIVE_SUBGROUP == LUT}]
  } else {
    set repCells [get_cells -hier {*_rep*} -filter {PRIMITIVE_GROUP == REGISTER || PRIMITIVE_GROUP == FLOP_LATCH}]
    lappend repCells [get_cells -quiet -hier {*_hdup*} -filter {PRIMITIVE_GROUP == REGISTER || PRIMITIVE_GROUP == FLOP_LATCH}]
  }

  foreach cell [lsort -unique $repCells] {
    set poRep 1
    if       {[regexp {^(.*)_replica_replica_[0-9]*$} $cell foo rCell]} {
      incr nbPhysOptRepCells
    } elseif {[regexp {^(.*)_replica_[0-9]*$}         $cell foo rCell]} {
      incr nbPhysOptRepCells
    } elseif {[regexp {^(.*)_replica_replica$}        $cell foo rCell]} {
      incr nbPhysOptRepCells
    } elseif {[regexp {^(.*)_replica$}                $cell foo rCell]} {
      incr nbPhysOptRepCells
    } elseif {[regexp {^(.*)_hdup[0-9]*$}             $cell foo rCell]} {
      # Customer replication
      incr nbPhysOptRepCells
      incr nbCustomRepCells
    } else {
      set rCell $cell
      set poRep 0
    }
    if       {[regexp {^(.*)_rep__[0-9]*_rep__[0-9]*$} $rCell foo mCell]} {
    } elseif {[regexp {^(.*)_rep__[0-9]*_rep$}         $rCell foo mCell]} {
    } elseif {[regexp {^(.*)_rep_rep__[0-9]*$}         $rCell foo mCell]} {
    } elseif {[regexp {^(.*)_rep_rep$}                 $rCell foo mCell]} {
    } elseif {[regexp {^(.*)_rep__[0-9]*$}             $rCell foo mCell]} {
    } elseif {[regexp {^(.*)_rep[0-9]*_[0-9]*$}        $rCell foo mCell]} {
    } elseif {[regexp {^(.*)_rep_[0-9]*\[[0-9]+\]$}    $rCell foo mCell]} {
    } elseif {[regexp {^(.*)_rep[0-9]*$}               $rCell foo mCell]} {
    } elseif {[regexp {^(.*)_rep$}                     $rCell foo mCell]} {
    } elseif {$poRep} {
      set mCell $rCell
    } else {
      puts "Skipping $cell"
      continue
    }
    #[regexp {(.*)_rep__[0-9]+_rep__[0-9]+$} $rCell foo mCell]
    #[regexp {(.*)_rep__[0-9]+$}        $rCell foo mCell]
    set net [get_nets -of [get_pins -filter {direction == out} -of $cell]]
    set fo [get_property FLAT_PIN_COUNT $net]
    set cePins  [llength [get_pins -quiet -leaf -of $net -filter {IS_ENABLE}]]
    set rstPins [llength [get_pins -quiet -leaf -of $net -filter {IS_CLEAR || IS_PRESET || IS_RESET || IS_SETRESET}]]
    if {[info exist count($mCell)]} {
      incr count($mCell)
      incr fanout($mCell) $fo
      incr ceCount($mCell) $cePins 
      incr rstCount($mCell) $rstPins 
    } else {
      set count($mCell) 1
      set ceCount($mCell) $cePins 
      set rstCount($mCell) $rstPins 
      set fanout($mCell) $fo
      set poRepCount($mCell) 0
      if {$timing} {
        set period($mCell) [get_property PERIOD -min [get_clocks -of [get_pins -filter IS_CLOCK -of $cell]]]
      }
      set mCell [get_cells $mCell -quiet]
      if {[llength $mCell] > 1} {
        foreach c $mCell {
          if {[get_property NAME $c] == "[get_property PARENT $c]/[get_property ORIG_CELL_NAME $c]"} {
            set mCell $c
            break
          }
        }
      }
      if {$mCell != {}} {
        set mNet [get_nets -of [get_pins -filter {direction == out} -of $mCell]]
        incr fanout($mCell)   [get_property FLAT_PIN_COUNT $mNet]
        incr ceCount($mCell)  [llength [get_pins -quiet -leaf -of $mNet -filter {IS_ENABLE}]]
        incr rstCount($mCell) [llength [get_pins -quiet -leaf -of $mNet -filter {IS_CLEAR || IS_PRESET || IS_RESET || IS_SETRESET}]]
        incr count($mCell) 1
      } else {
        incr mCellNotFound
      }
    }
    incr poRepCount($mCell) $poRep
  }
  
  set totRep 0
  foreach {c n} [array get count] {
    lappend rep($n) $c
    incr totRep $n
  }
  
  puts "\nTotal replicated cells     = $totRep"
  puts "Synthesis replicated cells = [expr $totRep - $nbPhysOptRepCells]"
  puts "PhysOpt replicated cells   = $nbPhysOptRepCells (custom rep: $nbCustomRepCells)"
  puts "Original cells not found   = $mCellNotFound"

  if {$LUTs && $csvFile == "replication.csv"} {
    set csvFile "lutReplication.csv"
  }
  set CSV [open $csvFile w]

  if {$timing} {
    puts [format "\n%3s - %3s - %6s - %6s - %6s - %6s - %s\n" "rep" "ppr" "fanout" "ce" "rst" "period" "origCell"]
    puts $CSV "NbRep,physOptRep,combFO,cePins,rstPins,period,origCell"
  } else {
    puts [format "\n%3s - %3s - %6s - %6s - %6s - %s\n" "rep" "ppr" "fanout" "ce" "rst" "origCell"]
    puts $CSV "NbRep,physOptRep,combFO,cePins,rstPins,origCell"
  }
  foreach r [lsort -integer -decreasing [array names rep]] {
    foreach c [lsort $rep($r)] {
      if {$timing} {
        puts [format "%3s - %3s - %6s - %6s - %6s - %6s - %s" $r $poRepCount($c) $fanout($c) $ceCount($c) $rstCount($c) $period($c) $c]
        puts $CSV "$r,$poRepCount($c),$fanout($c),$ceCount($c),$rstCount($c),$period($c),$c"
      } else {
        puts [format "%3s - %3s - %6s - %6s - %6s - %s" $r $poRepCount($c) $fanout($c) $ceCount($c) $rstCount($c) $c]
        puts $CSV "$r,$poRepCount($c),$fanout($c),$ceCount($c),$rstCount($c),$c"
      }
    }
  }
  close $CSV

  puts "\nLegend:"
  puts " - rep      = total number of replications (synthesis and phys_opt combined)"
  puts " - ppr      = number of post-place replications (phys_opt)"
  puts " - fanout   = recombined fanout for a group of replicated cells"
  puts " - ce       = number of clock enable pins in the recombined fanout"
  puts " - rst      = number of set/reset/clear/preset pins in the recombined fanout"
  puts " - origCell = name of the original cell before replication"
 
  puts "\nCreated CSV file $csvFile"
}


proc getReplicatedCells {refCells {includeRefCells ""}} {

  set result {}
  if {[llength $refCells] == 0} {
    puts "Error - expecting at least 1 reference cell name or pattern"
    return ""
  }
  foreach refCell $refCells {
    set tmp {}
    #puts "Analyzing [llength $matchedCells]" 
    foreach cell [get_cells ${refCell}* -filter {IS_SEQUENTIAL}] {
      set poRep 1
      if {$cell == $refCell} { continue }
      if       {[regexp {^(.*)_replica_replica_[0-9]*$} $cell foo rCell]} {
      } elseif {[regexp {^(.*)_replica_[0-9]*$}         $cell foo rCell]} {
      } elseif {[regexp {^(.*)_replica_replica$}        $cell foo rCell]} {
      } elseif {[regexp {^(.*)_replica$}                $cell foo rCell]} {
      } elseif {[regexp {^(.*)_hdup[0-9]*$}             $cell foo rCell]} {
      } else   {
        set rCell $cell
        set poRep 0
      }
      if       {[regexp {^(.*)_rep__[0-9]*_rep__[0-9]*$} $rCell foo mCell]} {
      } elseif {[regexp {^(.*)_rep__[0-9]*_rep$}         $rCell foo mCell]} {
      } elseif {[regexp {^(.*)_rep_rep__[0-9]*$}         $rCell foo mCell]} {
      } elseif {[regexp {^(.*)_rep_rep$}                 $rCell foo mCell]} {
      } elseif {[regexp {^(.*)_rep__[0-9]*$}             $rCell foo mCell]} {
      } elseif {[regexp {^(.*)_rep[0-9]*_[0-9]*$}        $rCell foo mCell]} {
      } elseif {[regexp {^(.*)_rep_[0-9]*\[[0-9]+\]$}    $rCell foo mCell]} {
      } elseif {[regexp {^(.*)_rep[0-9]*$}               $rCell foo mCell]} {
      } elseif {[regexp {^(.*)_rep$}                     $rCell foo mCell]} {
      } elseif {$poRep} {
      } else   {
        #puts "Skipping $cell"
        continue
      }
      lappend tmp $cell
    }
    if {[llength $tmp] > 0} {
      foreach cell $tmp {
        lappend result $cell
      }
    }
    if {[regexp {include} $includeRefCells]} {
      set cell [get_cells -quiet $refCell]
      if {$cell != {}} {
        lappend result $cell
      }
    }
  }
  return $result
}

 
proc combineReplicatedCells { masterCell {returnCellsToRemove 0} } {
  set cells [getReplicatedCells $masterCell]
  if {[llength $cells] == 0} {
    puts "No replicated cell found - skipping combining"
    return 0
  } elseif {$masterCell == $cells} {
    puts "Replicated cell and master cell are same - skipping combining"
  }
  set nbLoads 0
  puts [format "#### Combining %3s replicated cells - original cell: $masterCell ####" [llength $cells]]
  set masterCell [get_cells -quiet $masterCell]
  if {$masterCell == {}} {
    if {[llength $cells] == 1} {
      puts "One replicated cell but no master cell - skipping combining"
      return 0
    }
    foreach cell $cells {
      set cell [get_cells [regsub {\{(.*)\}} $cell {\1}]]
      if {![regexp {^FD*} [get_property REF_NAME $cell]]} { continue }
      set isDriven [expr [llength [get_pins -quiet -leaf -filter {DIRECTION==OUT} -of [get_nets -quiet -of [get_pins -filter {REF_PIN_NAME==D} -of $cell]]]] == 1]
      set oNet [get_nets -quiet -of [get_pins -filter {REF_PIN_NAME==Q} -of $cell]]
      if {$oNet != {}} { set hasLoad  [expr [get_property FLAT_PIN_COUNT $oNet] > 1] } else { set hasLoad 0 }
      if {$isDriven && $hasLoad} {
        set masterCell $cell
        break
      }
    }
  }
  if {$masterCell == {}} { puts "Master cell not found"; return }
  if {![regexp {^FD*} [get_property REF_NAME $masterCell]]} { puts "Master cell not FD*"; return }
  if {[get_pins -quiet -leaf -filter {DIRECTION==OUT} -of [get_nets -quiet -of [get_pins -filter {REF_PIN_NAME==D} -of $masterCell]]] == {}} {
    puts "Master cell has no driver"
    return
  }
  if {[get_pins -quiet -leaf -filter {DIRECTION==IN} -of [get_nets -quiet -of [get_pins -filter {REF_PIN_NAME==Q} -of $masterCell]]] == {}} {
    puts "Master cell has no loads"
    return
  }
  set masterOutPin [get_pins -of $masterCell -filter {DIRECTION == OUT}]
  set masterNet [get_nets -of $masterOutPin]
  foreach cell $cells {
    set cell [get_cells [regsub {\{(.*)\}} $cell {\1}]]
    if {$cell == $masterCell} { continue }
    set cellOutPin [get_pins -of $cell -filter {DIRECTION == OUT}]
    set cellNet [get_nets -of $cellOutPin]
    if {$cellNet == {}} {
      set cellHierLoadPins {}
    } else {
      incr nbLoads [expr [get_property FLAT_PIN_COUNT $cellNet] - 1]
      set cellHierLoadPins [get_pins -quiet -of $cellNet -filter {DIRECTION == IN || !IS_LEAF}]
    }
    if {$cellHierLoadPins == {}} {
      puts "Info - no pin to reconnect found for replicated cell $cell"
      lappend removeCell $cell
      continue
    }
#   puts "<cellOutPin:$cellOutPin><cellLoadPins:[llength $cellHierLoadPins]>"
#   puts " Reconnecting [llength $cellHierLoadPins] hierarchical loads from $cellNet to $masterNet"
    if {[catch {disconnect_net -net $cellNet -objects $cellHierLoadPins} mess]} {
      set remainingPins [get_pins -quiet -of $cellNet -filter {DIRECTION == IN || !IS_LEAF}]
      set disconnectedPins {}
      foreach pin $cellHierLoadPins {
        if {[lsearch -exact $remainingPins $pin] != -1} { continue }
        lappend disconnectedPins $pin
      }
      #puts "\nWarning - disconnect pin failed:"
      #puts -nonewline "  $mess"
      #puts "  => Original number of pins: [llength $cellHierLoadPins]"
      #puts "  => Number of pins still connected: [llength $remainingPins]"
      #puts "  => Number of disconnected pins: [llength $disconnectedPins]"
      puts "Warning - disconnect pin failed - #pins=[llength $cellHierLoadPins] - #connected=[llength $remainingPins] - #disconnected=[llength $disconnectedPins]"
      set cellHierLoadPins $disconnectedPins
    } else {
      lappend removeCell $cell
    }
    foreach pin $cellHierLoadPins { lappend connectPin $pin }
  }
  if {![info exists connectPin]} {
    puts "Warning - no pin to reconnect - $masterCell"
  } elseif {[catch {connect_net -net_object_list [list $masterNet $connectPin]} mess]} {
    #puts "\nWarning - connect pin failed:"
    #puts -nonewline $mess
    #puts "  => net: $masterNet"
    #puts "  => pins: ([llength $connectPin])"
    #puts "           [join $connectPin "\n           "]"
    puts "Warning - connect pin failed - pins=[llength $connectPin] - net=$masterNet"
  }
  if {$returnCellsToRemove} {
    if {[info exists removeCell]} { return $removeCell }
  } else {
    if {[info exists removeCell]} {
      remove_cell $removeCell
    } else {
      puts "Info - no replicated cell to remove"
    }
    return $nbLoads
  }
}

proc undoReplication {{csOnly 0} {csvFileIn replication.csv}} {
  if {![file exists $csvFileIn]} {
    puts "Missing CSV file with replication information. Please run reportReplication first"
    return {}
  } 
  set totOrigCells 0
  set totUselessOrigCells 0
  set CSV [open $csvFileIn r]
  gets $CSV l
  set hasTiming [regexp {,period,} $l]
  while {[gets $CSV l] >= 0} {
    if {$hasTiming} {
      if {![regexp {^(\d+),(\d+),(\d+),(\d+),(\d+),(\S+),(\S+)$} $l foo rep ppr afo ce rst period origCell]} { continue }
    } else {
      if {![regexp {^(\d+),(\d+),(\d+),(\d+),(\d+),(\S+)$} $l foo rep ppr afo ce rst origCell]} { continue }
    }
    if {$rep == 1} { continue }
    if {$csOnly && $ce == 0 && $rst == 0} { continue }
    puts "\n## Starting replication undo - pins: $afo - ce: $ce - rst:$rst"
    set removeCell [combineReplicatedCells $origCell 1]
    if {$removeCell != {} && [lsort -unique [get_property class $removeCell -quiet]] == "cell"} {
      lappend removeCells $removeCell
    }
  }
  if {![info exists removeCells]} {
    puts "Info - no replicated cell to remove"
  } else {
    remove_cell $removeCells
  }
  close $CSV
}

proc reportReplicatedCellPlacement {{minFanout 1} {maxFanout 100000} {csOnly 0} {boxSize 5} {csvFileIn replication.csv} {csvFileOut replicationPlacementQoR.csv}} {
  if {![file exists $csvFileIn]} {
    puts "Missing CSV file with replication information. Please run reportReplication first"
    return {}
  }
  set uselessRepCells {}
  set totRepCells 0
  set totUselessRepCells 0
  set totOrigCells 0
  set totUselessOrigCells 0
  set CSV [open $csvFileIn r]
  set CSVOut [open $csvFileOut w]
  puts $CSVOut "Fanout,X,Y,PlaceQoR,TotRep,SynRep,PhysRep,CE,RST,OrigCellName"
  while {[gets $CSV l] >= 0} {
    if {![regexp {^(\d+),(\d+),(\d+),(\d+),(\d+),(\S+)$} $l foo rep ppr afo ce rst origCell]} {
      continue
    }
    if {$afo > $maxFanout} { continue }
    if {$afo < $minFanout} { continue }
    if {$csOnly && $ce == 0 && $rst == 0} { continue }
    set repCells [getReplicatedCells $origCell include]
    set xs {}; set ys {}
    foreach loc [get_property LOC $repCells] {
      if {![regexp {SLICE_X(\d+)Y(\d+)} $loc foo x y]} { puts "$loc"; continue }
      lappend xs $x; lappend ys $y
    }
    set xs [lsort -integer -unique $xs]; set ys [lsort -integer -unique $ys]
    set xdelta [expr [lindex $xs end] - [lindex $xs 0]]
    set ydelta [expr [lindex $ys end] - [lindex $ys 0]]
    puts "Fanout=$afo - Rep=$rep - Xdelta=$xdelta - Ydelta=$ydelta - $origCell"
    if {$xdelta < $boxSize & $ydelta < $boxSize} {
      puts "  -> WARNING - replicated cells closely placed!!"
      lappend uselessRepCells $origCell
      incr totUselessRepCells [llength $repCells]
      incr totUselessOrigCells 
      set bad 1
    } else {
      set bad 0
    }
    puts $CSVOut [join [list $afo $xdelta $ydelta $bad $rep [expr $rep - $ppr -1] $ppr $ce $rst $origCell] ,]
    incr totRepCells [llength $repCells]
    incr totOrigCells 
  }
  close $CSV
  close $CSVOut

  puts "+---------------- SUMMARY ----------------+"
  set pcUselessRepCells [format "%.2f" [expr 100.0 * $totUselessRepCells / $totRepCells]]
  puts "Total Useless Replicated Cells: $totUselessRepCells / $totRepCells (${pcUselessRepCells}%)"
  set pcUselessOrigCells [format "%.2f" [expr 100.0 * $totUselessOrigCells / $totOrigCells]]
  puts "Total Useless Original Replicated Cells: $totUselessOrigCells / $totOrigCells (${pcUselessOrigCells}%)"
  return $uselessRepCells
}

proc hilitReplicatedCells {{minFanout 1} {maxFanout 100000} {csOnly 0} {synthOnly 0} {csvFile replication.csv}} {
  if {![file exists $csvFile]} {
    puts "Missing CSV file with replication information. Please run reportReplication first"
    return 1
  }
  set CSV [open $csvFile r]
  set colors [list red green blue magenta yellow cyan orange]
  set nbColors [llength $colors]
  set indColor 0
  set totRepCells 0
  set totHilitGroups 0
  while {[gets $CSV l] >= 0} {
    if {![regexp {^(\d+),(\d+),(\d+),(\d+),(\d+),(\S+)$} $l foo rep ppr afo ce rst origCell]} {
      continue
    }
    if {$afo > $maxFanout} { continue }
    if {$afo < $minFanout} { continue }
    if {$csOnly && $ce == 0 && $rst == 0} { continue }
    if {$synthOnly && [expr $rep - $ppr] == 1} { continue }
    set repCells [getReplicatedCells $origCell include]
    #select_objects $repCells
    set color [lindex $colors $indColor]
    puts "Highlighting color: $color - cells: [llength $repCells] - $origCell"
    mark_objects $repCells -color $color
    highlight_objects [get_nets -of [get_pins -filter DIRECTION==OUT -of $repCells]] -color $color
    set indColor [expr ($indColor + 1) % $nbColors]
    incr totRepCells [llength $repCells]
    incr totHilitGroups
  }
  close $CSV

  puts "Total Replicated Cells Highlighted:        $totRepCells"
  puts "Total Replicated Cells Groups Highlighted: $totHilitGroups"
}


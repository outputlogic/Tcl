# From Fred

proc reportReplication {{csvFile "replication.csv"}} {

  set mCellNotFound 0
  set nbPhysOptRepCells 0
  
  foreach cell [get_cells -hier {*_rep_* *_rep} -filter {IS_SEQUENTIAL}] {
    set poRep 1
    if       {[regexp {^(.*)_replica_replica_[0-9]*$} $cell foo rCell]} {
      incr nbPhysOptRepCells
    } elseif {[regexp {^(.*)_replica_[0-9]*$}         $cell foo rCell]} {
      incr nbPhysOptRepCells
    } elseif {[regexp {^(.*)_replica_replica$}        $cell foo rCell]} {
      incr nbPhysOptRepCells
    } elseif {[regexp {^(.*)_replica$}                $cell foo rCell]} {
      incr nbPhysOptRepCells
    } else {
      set rCell $cell
      set poRep 0
    }
    if       {[regexp {^(.*)_rep__[0-9]*_rep__[0-9]*$} $rCell foo mCell]} {
    } elseif {[regexp {^(.*)_rep__[0-9]*_rep$}         $rCell foo mCell]} {
    } elseif {[regexp {^(.*)_rep_rep__[0-9]*$}         $rCell foo mCell]} {
    } elseif {[regexp {^(.*)_rep_rep$}                 $rCell foo mCell]} {
    } elseif {[regexp {^(.*)_rep__[0-9]*$}             $rCell foo mCell]} {
    } elseif {[regexp {^(.*)_rep$}                     $rCell foo mCell]} {
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
      set mCell [get_cells $mCell -quiet]
      if {$mCell != {}} {
        set mNet [get_nets -of [get_pins -filter {direction == out} -of $mCell]]
        incr fanout($mCell)   [get_property FLAT_PIN_COUNT $mNet]
        incr ceCount($mCell)  [llength [get_pins -quiet -leaf -of $mNet -filter {IS_ENABLE}]]
        incr rstCount($mCell) [llength [get_pins -quiet -leaf -of $mNet -filter {IS_CLEAR || IS_PRESET || IS_RESET || IS_SETRESET}]]
        incr count($mCell)  2
      } else {
        incr mCellNotFound
      }
    }
    incr poRepCount($mCell) $poRep
  }
  
  foreach {c n} [array get count] {
    lappend rep($n) $c
  }
  
  puts "\nOriginal cells not found: $mCellNotFound"
  puts "\nPhys-opt replicated cells: $nbPhysOptRepCells"

  set CSV [open $csvFile w]

  puts [format "\n%3s - %3s - %6s - %6s - %6s - %s\n" "rep" "ppr" "fanout" "ce" "rst" "origCell"]
  puts $CSV "NbRep,physOptRep,combFO,cePins,rstPins,origCell"
  foreach r [lsort -integer -decreasing [array names rep]] {
    foreach c [lsort $rep($r)] {
      puts [format "%3s - %3s - %6s - %6s - %6s - %s" $r $poRepCount($c) $fanout($c) $ceCount($c) $rstCount($c) $c]
      puts $CSV "$r,$poRepCount($c),$fanout($c),$ceCount($c),$rstCount($c),$c"
    }
  }
  close $CSV
  puts "\nCreated CSV file $csvFile"
}


proc getReplicatedCells {refCell} {

  set result {}
 
  foreach cell [get_cells ${refCell}* -filter {IS_SEQUENTIAL}] {
    set poRep 1
    if       {[regexp {^(.*)_replica_replica_[0-9]*$} $cell foo rCell]} {
    } elseif {[regexp {^(.*)_replica_[0-9]*$}         $cell foo rCell]} {
    } elseif {[regexp {^(.*)_replica_replica$}        $cell foo rCell]} {
    } elseif {[regexp {^(.*)_replica$}                $cell foo rCell]} {
    } else   {
      set rCell $cell
    }
    if       {[regexp {^(.*)_rep__[0-9]*_rep__[0-9]*$} $rCell foo mCell]} {
    } elseif {[regexp {^(.*)_rep__[0-9]*_rep$}         $rCell foo mCell]} {
    } elseif {[regexp {^(.*)_rep_rep__[0-9]*$}         $rCell foo mCell]} {
    } elseif {[regexp {^(.*)_rep_rep$}                 $rCell foo mCell]} {
    } elseif {[regexp {^(.*)_rep__[0-9]*$}             $rCell foo mCell]} {
    } elseif {[regexp {^(.*)_rep$}                     $rCell foo mCell]} {
    } else {
      #puts "Skipping $cell"
      continue
    }
    lappend result $cell
  }
  return $result
}


proc combineReplicatedCells { masterCell } {
  set cells [getReplicatedCells $masterCell]
  if {[llength $cells] == 0} {
    puts "No replicated cell found"
    return 0
  }
  set nbLoads 0
  puts "\n\n#### Combining [llength $cells] replicated cells ####"
  set masterOutPin [get_pins -of [get_cells $masterCell] -filter {DIRECTION == OUT}]
  set masterNet [get_nets -of $masterOutPin]
  foreach cell $cells {
    if {$cell == $masterCell} { continue }
    set cellOutPin [get_pins -of [get_cells $cell] -filter {DIRECTION == OUT}]
    set cellNet [get_nets -of $cellOutPin]
    incr nbLoads [expr [get_property FLAT_PIN_COUNT $cellNet] - 1]
    set cellHierLoadPins [get_pins -of $cellNet -filter {DIRECTION == IN || !IS_LEAF}]
    if {$cellHierLoadPins == {}} {
      puts "Skipping - no pin to reconnect found for replicated cell $cell"
      continue
    }
#   puts "<cellOutPin:$cellOutPin><cellLoadPins:[llength $cellHierLoadPins]>"
#   puts " Reconnecting [llength $cellHierLoadPins] hierarchical loads from $cellNet to $masterNet"
    disconnect_net -net $cellNet -objects $cellHierLoadPins
    connect_net    -net $masterNet -objects $cellHierLoadPins -hier
  }
  return $nbLoads
}


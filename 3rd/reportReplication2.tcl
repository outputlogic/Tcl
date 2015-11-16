proc reportReplication {{csvFile "replication.csv"}} {

  set mCellNotFound 0
  set nbPhysOptRepCells 0
  
  foreach cell [get_cells -hier {*_rep*} -filter {PRIMITIVE_GROUP == REGISTER || PRIMITIVE_GROUP == FLOP_LATCH}] {
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
    } elseif {[regexp {^(.*)_rep[0-9]*_[0-9]*$}        $rCell foo mCell]} {
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
  
  foreach {c n} [array get count] {
    lappend rep($n) $c
  }
  
  puts "\nOriginal cells not found: $mCellNotFound"
  puts "\nPhys-opt replicated cells: $nbPhysOptRepCells"

  set CSV [open $csvFile w]

  puts "\nLegend:"
  puts " - rep = total number of replications (synthesis and phys_opt combined)"
  puts " - ppr = number of replications done by phys_opt"
  puts " - fanout = recombined fanout for a group of replicated cells"
  puts " - ce = number of clock enable pins in the recombined fanout"
  puts " - rst = number of set/reset/clear/preset pins in the recombined fanout"
  puts " - origCell = name of the original cell before replication"
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

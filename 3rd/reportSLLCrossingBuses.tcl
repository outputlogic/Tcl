proc reportSLLCrossingBuses {{returnArray 0}} {
  array set sllNets [getRoutedSLLNets]
  
  foreach {column nets} [array get sllNets] {
    foreach net $nets {
      if {[get_property FLAT_PIN_COUNT $net] > 2} {
        puts "Info - net with fanout > 1 - skipping $net"
        continue
      }
      set net [get_nets -segments -top_net_of_hierarchical_group $net]
      set opin [get_pins -filter {DIRECTION==OUT} -of $net]
      set drivCell [get_cells -of [get_pins -leaf -filter {DIRECTION==OUT} -of $net]]
      set drivSLR  [get_slrs -of $drivCell]
      set loadCell [get_cells -of [get_pins -leaf -filter {DIRECTION==IN} -of $net]]
      set loadSLR  [get_slrs -of $loadCell]
      if {[regexp {^(.*)\[\d+\]$} $opin foo baseName]} {
      } elseif {[regexp {^(.*)_\d+$} $opin foo baseName]} {
      } else {
         puts "Info - Pattern not matched: $opin - skipping net $net"
         continue
      }
      if {[llength $drivSLR] == 1 && [llength $loadSLR] == 1 && $drivSLR != $loadSLR} {
        eval lappend $drivSLR\($baseName\) $drivCell
        eval lappend $loadSLR\($baseName\) $loadCell
      } else {
        puts "Info - unexpected cell SLRs - driver: $drivSLR - load: $loadSLR - skipping net $net"
        continue
      }
    }
  }

  foreach baseName [lsort [array names SLR0]] {
    puts [format "%5s - %s" [llength $SLR0($baseName)] $baseName]
  }

  if {$returnArray} {
    return [list [array get SLR0] [array get SLR1]]
  }
}
 
proc hilitSLLBuses {{s0 {}} {s1 {}} {minWidth 128} {maxWidth 100000} {expandOneLevel 0} {busList {}}} {
  if {$s0 == {} || $s1 == {}} {
    lassign [reportSLLCrossingFlooplan 1] s0 s1
  }
  array set slr0 $s0
  array set slr1 $s1
  set colors {magenta red orange blue cyan green yellow}
  set i 0 
  if {$busList == {}} {
    set busList [lsort [array names slr0]]
  }
  foreach busName $busList {
    if {[llength $slr0($busName)] < $minWidth || [llength $slr0($busName)] > $maxWidth} {
      continue
    }
    set color [lindex $colors $i]
    puts [format "%5s - %8s - %s" [llength $slr0($busName)] $color $busName]
    #highlight_objects -color $color $loads
    #highlight_objects -color $color $clockRegions($cr)
    if {$expandOneLevel} {
      set slrPins [get_pins -filter {REF_PIN_NAME==D || REF_PIN_NAME==Q} -of [get_cells $slr0($busName)]]
      mark_objects -color $color [get_cells -of [get_pins -leaf -of [get_nets -of $slrPins]]]
      set slrPins [get_pins -filter {REF_PIN_NAME==D || REF_PIN_NAME==Q} -of [get_cells $slr1($busName)]]
      mark_objects -color $color [get_cells -of [get_pins -leaf -of [get_nets -of $slrPins]]]
    } else {
      mark_objects -color $color [get_cells $slr0($busName)]
      mark_objects -color $color [get_cells $slr1($busName)]
    }
    set i [expr ($i+1)%[llength $colors]]
  }
}

## Provided by Frank Mueller
proc getRoutedSLLNets {} {
  set chip_SLRs [get_slrs]
  set bot_SLR [lindex $chip_SLRs 0]
  set top_SLR [lindex $chip_SLRs end]
  array set clock_regions {}

  foreach SLR [lrange $chip_SLRs 0 end-1] {
    set clock_regions($SLR) [get_clock_regions -of $SLR]
    regexp {X(\d*)Y(\d*)} [lindex $clock_regions($SLR) 0] all clock_regions_minx($SLR) clock_regions_miny($SLR)
    regexp {X(\d*)Y(\d*)} [lindex $clock_regions($SLR) end] all clock_regions_maxx($SLR) clock_regions_maxy($SLR)
    for {set x $clock_regions_minx($SLR)} {$x<=$clock_regions_maxx($SLR)} {incr x} {
      set clock_region "X${x}Y$clock_regions_maxy($SLR)"
      set all_SLLs($clock_region) [get_nodes -of  [get_tiles LAGUNA_TILE_X*Y* -of [get_clock_regions $clock_region]] -filter NAME=~*UBUMP*]
      regexp {LAGUNA_TILE_X(\d*)Y(\d*)} [lindex [get_tiles -of $all_SLLs($clock_region)] 0] all CLB_col_min LagunaY 
      regexp {LAGUNA_TILE_X(\d*)Y(\d*)} [lindex [get_tiles -of $all_SLLs($clock_region)] end] all CLB_col_max LagunaY 
      set sllNets($clock_region$CLB_col_min) [get_nets -quiet -of  [get_nodes -of  [get_tiles LAGUNA_TILE_X${CLB_col_min}Y* -of [get_clock_regions $clock_region]] -filter NAME=~*UBUMP*]]
      set sllNets($clock_region$CLB_col_max) [get_nets -quiet -of  [get_nodes -of  [get_tiles LAGUNA_TILE_X${CLB_col_max}Y* -of [get_clock_regions $clock_region]] -filter NAME=~*UBUMP*]]
    }
  }
  return [array get sllNets]
}


proc reportSLLUsage {} {
  set chip_SLRs [get_slrs]
  set bot_SLR [lindex $chip_SLRs 0]
  set top_SLR [lindex $chip_SLRs end]
  array set clock_regions {}
  set percent 0

  foreach SLR [lrange $chip_SLRs 0 end-1] {
    set clock_regions($SLR) [get_clock_regions -of $SLR]
    regexp {X(\d*)Y(\d*)} [lindex $clock_regions($SLR) 0] all clock_regions_minx($SLR) clock_regions_miny($SLR)
    regexp {X(\d*)Y(\d*)} [lindex $clock_regions($SLR) end] all clock_regions_maxx($SLR) clock_regions_maxy($SLR)
    puts -nonewline "top $SLR "
    for {set x $clock_regions_minx($SLR)} {$x<=$clock_regions_maxx($SLR)} {incr x} {
      set clock_region "X${x}Y$clock_regions_maxy($SLR)"
      set all_SLLs($clock_region) [get_nodes -of  [get_tiles LAGUNA_TILE_X*Y* -of [get_clock_regions $clock_region]] -filter NAME=~*UBUMP*]
      regexp {LAGUNA_TILE_X(\d*)Y(\d*)} [lindex [get_tiles -of $all_SLLs($clock_region)] 0] all CLB_col_min LagunaY 
      regexp {LAGUNA_TILE_X(\d*)Y(\d*)} [lindex [get_tiles -of $all_SLLs($clock_region)] end] all CLB_col_max LagunaY 
      set used_SLLs($clock_region$CLB_col_min) [get_nodes -quiet -of  [get_nets -quiet -of  [get_nodes -of  [get_tiles LAGUNA_TILE_X${CLB_col_min}Y* -of [get_clock_regions $clock_region]] -filter NAME=~*UBUMP*]] -filter NAME=~*UBUMP*]
      set used_SLLs($clock_region$CLB_col_max) [get_nodes -quiet -of  [get_nets -quiet -of  [get_nodes -of  [get_tiles LAGUNA_TILE_X${CLB_col_max}Y* -of [get_clock_regions $clock_region]] -filter NAME=~*UBUMP*]] -filter NAME=~*UBUMP*]
      if {$percent} {
          puts -nonewline "[format "%.2f%%" [expr {100.0 * [llength $used_SLLs($clock_region$CLB_col_min)] / [llength $all_SLLs($clock_region)] * 2} ]] " 
          puts -nonewline "[format "%.2f%%" [expr {100.0 * [llength $used_SLLs($clock_region$CLB_col_max)] / [llength $all_SLLs($clock_region)] * 2} ]] "
      } else {
          puts -nonewline "[llength $used_SLLs($clock_region$CLB_col_min)] " 
          puts -nonewline "[llength $used_SLLs($clock_region$CLB_col_max)] "
      }
    }
    puts ""
  }
}

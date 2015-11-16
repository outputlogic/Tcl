
# fanin/fanout procs to highlight cells in the fanin/fanout of a list of cells

proc fanin { pattern {level 1} {showlevels {0 1 2 3 4 5}} {reset 1} } {
  global obj
  if {$showlevels == {}} { set showlevels {0 1 2 3 4 5} }
  set cells [get_cells -quiet $pattern -filter {IS_PRIMITIVE && REF_NAME != VCC && REF_NAME != GND}]
  puts " $pattern -> [llength $cells]"
  if {[llength $cells] == 0} {
    return -code ok
  }
  set clkRegionCells [lsort [get_clock_regions -quiet -of $cells]]
  set pblocksCells [lsort [get_pblocks -quiet -of $cells]]
  puts "  # cells (magenta) :\t[llength $cells]\t| $clkRegionCells\t| $pblocksCells\t| [lrange [lsort -unique [get_property PARENT $cells]] 0 20]"
  if {$reset} {
    unmark_objects
    unhighlight_objects
  }
  if {[lsearch $showlevels 0] != -1} {
    mark_objects -quiet -color magenta $cells
    highlight_objects -quiet -color magenta $cells
  }
  set obj(fanin:cells) $cells
  if {$level >= 1} {
    set driversL1 [get_cells -quiet -of [get_pins -quiet -leaf -of [get_nets -quiet -of [get_pins -quiet -of $cells -filter {DIRECTION == IN && !IS_CLOCK}]] -filter {DIRECTION == OUT && !IS_CLOCK}] -filter {REF_NAME != VCC && REF_NAME != GND}]
    set driversL1 [get_cells -quiet [ldiff $driversL1 $cells]]
    set clkRegionL1 [lsort [get_clock_regions -quiet -of $driversL1]]
    set pblocksL1 [lsort [get_pblocks -quiet -of $driversL1]]
    puts "  # L1 (red)    :\t[llength $driversL1]\t| $clkRegionL1\t| $pblocksL1\t| [lrange [lsort -unique [get_property PARENT $driversL1]] 0 20]"
    if {[lsearch $showlevels 1] != -1} {
      mark_objects -quiet -color red $driversL1
      highlight_objects -quiet -color red $driversL1
    }
    set obj(fanin:L1) $driversL1
  }
  if {$level >= 2} {
    set driversL2 [get_cells -quiet -of [get_pins -quiet -leaf -of [get_nets -quiet -of [get_pins -quiet -of $driversL1 -filter {DIRECTION == IN && !IS_CLOCK}]] -filter {DIRECTION == OUT && !IS_CLOCK}] -filter {REF_NAME != VCC && REF_NAME != GND}]
    set driversL2 [get_cells -quiet [ldiff $driversL2 [concat $driversL1 $cells]]]
    set clkRegionL2 [lsort [get_clock_regions -quiet -of $driversL2]]
    set pblocksL2 [lsort [get_pblocks -quiet -of $driversL2]]
    puts "  # L2 (orange) :\t[llength $driversL2]\t| $clkRegionL2\t| $pblocksL2\t| [lrange [lsort -unique [get_property PARENT $driversL2]] 0 20]"
    if {[lsearch $showlevels 2] != -1} {
      mark_objects -quiet -color orange $driversL2
      highlight_objects -quiet -color orange $driversL2
    }
    set obj(fanin:L2) $driversL2
  }
  if {$level >= 3} {
    set driversL3 [get_cells -quiet -of [get_pins -quiet -leaf -of [get_nets -quiet -of [get_pins -quiet -of $driversL2 -filter {DIRECTION == IN && !IS_CLOCK}]] -filter {DIRECTION == OUT && !IS_CLOCK}] -filter {REF_NAME != VCC && REF_NAME != GND}]
    set driversL3 [get_cells -quiet [ldiff $driversL3 [concat $driversL2 $driversL1 $cells]]]
    set clkRegionL3 [lsort [get_clock_regions -quiet -of $driversL3]]
    set pblocksL3 [lsort [get_pblocks -quiet -of $driversL3]]
    puts "  # L3 (cyan)   :\t[llength $driversL3]\t| $clkRegionL3\t| $pblocksL3\t| [lrange [lsort -unique [get_property PARENT $driversL3]] 0 20]"
    if {[lsearch $showlevels 3] != -1} {
      mark_objects -quiet -color cyan $driversL3
      highlight_objects -quiet -color cyan $driversL3
    }
    set obj(fanin:L3) $driversL3
  }
  if {$level >= 4} {
    set driversL4 [get_cells -quiet -of [get_pins -quiet -leaf -of [get_nets -quiet -of [get_pins -quiet -of $driversL3 -filter {DIRECTION == IN && !IS_CLOCK}]] -filter {DIRECTION == OUT && !IS_CLOCK}] -filter {REF_NAME != VCC && REF_NAME != GND}]
    set driversL4 [get_cells -quiet [ldiff $driversL4 [concat $driversL3 $driversL2 $driversL1 $cells]]]
    set clkRegionL4 [lsort [get_clock_regions -quiet -of $driversL4]]
    set pblocksL4 [lsort [get_pblocks -quiet -of $driversL4]]
    puts "  # L4 (blue)   :\t[llength $driversL4]\t| $clkRegionL4\t| $pblocksL4\t| [lrange [lsort -unique [get_property PARENT $driversL4]] 0 20]"
    if {[lsearch $showlevels 4] != -1} {
      mark_objects -quiet -color blue $driversL4
      highlight_objects -quiet -color blue $driversL4
    }
    set obj(fanin:L4) $driversL4
  }
  if {$level >= 5} {
    set driversL5 [get_cells -quiet -of [get_pins -quiet -leaf -of [get_nets -quiet -of [get_pins -quiet -of $driversL4 -filter {DIRECTION == IN && !IS_CLOCK}]] -filter {DIRECTION == OUT && !IS_CLOCK}] -filter {REF_NAME != VCC && REF_NAME != GND}]
    set driversL5 [get_cells -quiet [ldiff $driversL5 [concat $driversL4 $driversL3 $driversL2 $driversL1 $cells]]]
    set clkRegionL5 [lsort [get_clock_regions -quiet -of $driversL5]]
    set pblocksL5 [lsort [get_pblocks -quiet -of $driversL5]]
    puts "  # L5 (yellow) :\t[llength $driversL5]\t| $clkRegionL5\t| $pblocksL5\t| [lrange [lsort -unique [get_property PARENT $driversL5]] 0 20]"
    if {[lsearch $showlevels 5] != -1} {
      mark_objects -quiet -color yellow $driversL5
      highlight_objects -quiet -color yellow $driversL5
    }
    set obj(fanin:L5) $driversL5
  }
  return -code ok
}

proc fanout { pattern {level 1} {showlevels {0 1 2 3 4 5}} {reset 1} } {
  global obj
  if {$showlevels == {}} { set showlevels {0 1 2 3 4 5} }
  set cells [get_cells -quiet $pattern -filter {IS_PRIMITIVE && REF_NAME != VCC && REF_NAME != GND}]
  puts " pattern -> [llength $cells]"
#   puts " $pattern -> [llength $cells]"
  if {[llength $cells] == 0} {
    return -code ok
  }
  set clkRegionCells [lsort [get_clock_regions -quiet -of $cells]]
  set pblocksCells [lsort [get_pblocks -quiet -of $cells]]
  puts "  # cells (magenta) :\t[llength $cells]\t| $clkRegionCells\t| $pblocksCells\t| [lrange [lsort -unique [get_property PARENT $cells]] 0 20]"
  if {$reset} {
    unmark_objects
    unhighlight_objects
  }
  if {[lsearch $showlevels 0] != -1} {
    mark_objects -quiet -color magenta $cells
    highlight_objects -quiet -color magenta $cells
  }
  set obj(fanout:cells) $cells
  if {$level >= 1} {
    set loadsL1 [get_cells -quiet -of [get_pins -quiet -leaf -of [get_nets -quiet -of [get_pins -quiet -of $cells -filter {DIRECTION == OUT && !IS_CLOCK}]] -filter {DIRECTION == IN && !IS_CLOCK}] -filter {REF_NAME != VCC && REF_NAME != GND}]
    set loadsL1 [get_cells -quiet [ldiff $loadsL1 $cells]]
    set clkRegionL1 [lsort [get_clock_regions -quiet -of $loadsL1]]
    set pblocksL1 [lsort [get_pblocks -quiet -of $loadsL1]]
    puts "  # L1 (red)    :\t[llength $loadsL1]\t| $clkRegionL1\t| $pblocksL1\t| [lrange [lsort -unique [get_property PARENT $loadsL1]] 0 20]"
    if {[lsearch $showlevels 1] != -1} {
      mark_objects -quiet -color red $loadsL1
      highlight_objects -quiet -color red $loadsL1
    }
    set obj(fanout:L1) $loadsL1
  }
  if {$level >= 2} {
    set loadsL2 [get_cells -quiet -of [get_pins -quiet -leaf -of [get_nets -quiet -of [get_pins -quiet -of $loadsL1 -filter {DIRECTION == OUT && !IS_CLOCK}]] -filter {DIRECTION == IN && !IS_CLOCK}] -filter {REF_NAME != VCC && REF_NAME != GND}]
    set loadsL2 [get_cells -quiet [ldiff $loadsL2 [concat $loadsL1 $cells]]]
    set clkRegionL2 [lsort [get_clock_regions -quiet -of $loadsL2]]
    set pblocksL2 [lsort [get_pblocks -quiet -of $loadsL2]]
    puts "  # L2 (orange) :\t[llength $loadsL2]\t| $clkRegionL2\t| $pblocksL2\t| [lrange [lsort -unique [get_property PARENT $loadsL2]] 0 20]"
    if {[lsearch $showlevels 2] != -1} {
      mark_objects -quiet -color orange $loadsL2
      highlight_objects -quiet -color orange $loadsL2
    }
    set obj(fanout:L2) $loadsL2
  }
  if {$level >= 3} {
    set loadsL3 [get_cells -quiet -of [get_pins -quiet -leaf -of [get_nets -quiet -of [get_pins -quiet -of $loadsL2 -filter {DIRECTION == OUT && !IS_CLOCK}]] -filter {DIRECTION == IN && !IS_CLOCK}] -filter {REF_NAME != VCC && REF_NAME != GND}]
    set loadsL3 [get_cells -quiet [ldiff $loadsL3 [concat $loadsL2 $loadsL1 $cells]]]
    set clkRegionL3 [lsort [get_clock_regions -quiet -of $loadsL3]]
    set pblocksL3 [lsort [get_pblocks -quiet -of $loadsL3]]
    puts "  # L3 (cyan)   :\t[llength $loadsL3]\t| $clkRegionL3\t| $pblocksL3\t| [lrange [lsort -unique [get_property PARENT $loadsL3]] 0 20]"
    if {[lsearch $showlevels 3] != -1} {
      mark_objects -quiet -color cyan $loadsL3
      highlight_objects -quiet -color cyan $loadsL3
    }
    set obj(fanout:L3) $loadsL3
  }
  if {$level >= 4} {
    set loadsL4 [get_cells -quiet -of [get_pins -quiet -leaf -of [get_nets -quiet -of [get_pins -quiet -of $loadsL3 -filter {DIRECTION == OUT && !IS_CLOCK}]] -filter {DIRECTION == IN && !IS_CLOCK}] -filter {REF_NAME != VCC && REF_NAME != GND}]
    set loadsL4 [get_cells -quiet [ldiff $loadsL4 [concat $loadsL3 $loadsL2 $loadsL1 $cells]]]
    set clkRegionL4 [lsort [get_clock_regions -quiet -of $loadsL4]]
    set pblocksL4 [lsort [get_pblocks -quiet -of $loadsL4]]
    puts "  # l4 (blue)   :\t[llength $loadsL4]\t| $clkRegionL4\t| $pblocksL4\t| [lrange [lsort -unique [get_property PARENT $loadsL4]] 0 20]"
    if {[lsearch $showlevels 4] != -1} {
      mark_objects -quiet -color blue $loadsL4
      highlight_objects -quiet -color blue $loadsL4
    }
    set obj(fanout:L4) $loadsL4
  }
  if {$level >= 5} {
    set loadsL5 [get_cells -quiet -of [get_pins -quiet -leaf -of [get_nets -quiet -of [get_pins -quiet -of $loadsL4 -filter {DIRECTION == OUT && !IS_CLOCK}]] -filter {DIRECTION == IN && !IS_CLOCK}] -filter {REF_NAME != VCC && REF_NAME != GND}]
    set loadsL5 [get_cells -quiet [ldiff $loadsL5 [concat $loadsL4 $loadsL3 $loadsL2 $loadsL1 $cells]]]
    set clkRegionL5 [lsort [get_clock_regions -quiet -of $loadsL5]]
    set pblocksL5 [lsort [get_pblocks -quiet -of $loadsL5]]
    puts "  # L5 (yellow) :\t[llength $loadsL5]\t| $clkRegionL5\t| $pblocksL5\t| [lrange [lsort -unique [get_property PARENT $loadsL5]] 0 20]"
    if {[lsearch $showlevels 5] != -1} {
      mark_objects -quiet -color yellow $loadsL5
      highlight_objects -quiet -color yellow $loadsL5
    }
    set obj(fanout:L5) $loadsL5
  }
  return -code ok
}


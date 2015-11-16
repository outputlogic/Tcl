
# Proc to reload current script
proc [file tail [info script]] {} " source [info script]; puts \" [info script] reloaded\" "


#
# This proc returns a list of pairs of hierarchical pins between 2 blocks.
# For each unique timing path between the 2 blocks, the hierarchical pins
# for the 2 blocks that the timing path is going through is extracted. The
# pair of hierarchical pins in then added to the list being returned by the proc.
#
# For example:
#   set hierPins [get_hier_pins inst/dport_rx_phy_inst inst/dport_link_inst]
# 
# There is also a verbose mode that is triggered by adding '1' in third position:
#   set hierPins [get_hier_pins inst/dport_rx_phy_inst inst/dport_link_inst 1]
#
# To uniquify the list of pairs of pins, use 'lsort' command:
#   set hierPins [lsort -unique [get_hier_pins inst/dport_rx_phy_inst inst/dport_link_inst]]
#
proc get_hier_pins {BlockA BlockB {verbose 0}} {
  if {[get_cells $BlockA] == {}} {
    error "Cannot find cell $BlockA"
  }
  if {[get_cells $BlockB] == {}} {
    error "Cannot find cell $BlockB"
  }
  # Get output pins of BlockA
  set outputPinsBlockA [get_pins -of [get_cells $BlockA] -filter {(direction == out) || (direction == inout)}]
  if {[llength $outputPinsBlockA] == 0} {
    error "Cannot find any output pin for $BlockA"
  }
  if {$verbose} {
    puts " -I- Number of output pins for $BlockA: [llength $outputPinsBlockA]"
    puts " -I- Output pins for $BlockA: $outputPinsBlockA"
  }
  # Get inputs pins of BlockB
  set inputPinsBlockB [get_pins -of [get_cells $BlockB] -filter {(direction == in) || (direction == inout)}]
  if {[llength $inputPinsBlockB] == 0} {
    error "Cannot find any input pin for $BlockB"
  }
  if {$verbose} {
    puts " -I- Number of input pins for $BlockB: [llength $inputPinsBlockB]"
    puts " -I- Input pins for $BlockB: $inputPinsBlockB"
  }
  # Go to BlockB to find endpoints that belong to BlockB only
  current_instance $BlockB
  # The -endpoints_only does not seem to return all the leaf pins of interest, so
  # filter the pins to keep leaf pins instead
#   set endpoints [all_fanout $inputPinsBlockB -flat -endpoints_only]
  set endpoints [filter [all_fanout $inputPinsBlockB -flat] {IS_LEAF==1}]
  if {$verbose} {
    puts " -I- Number of endpoints: [llength $endpoints]"
    puts " -I- Endpoints: $endpoints"
  }
  # Go back to the top
  current_instance
  # Get all unique timing paths through the output pins of BlockA and
  # to the all endpoints (BlockB)
  set timing_paths [get_timing_paths -quiet -through $outputPinsBlockA -to $endpoints -nworst 1 -setup -unique_pins -max_paths [llength $endpoints]]
#   set timing_paths [get_timing_paths -quiet -from [get_pins -of [get_cells -hier -filter "name=~$BlockA/*"]] -to $endpoints -nworst 1 -setup -unique_pins -max_paths [llength $endpoints]]
#   set timing_paths [get_timing_paths -quiet -from [get_pins -of [get_cells -hier -filter "name=~$BlockA/*"]] -to [get_pins -of [get_cells -hier -filter "name=~$BlockB/*"]] -nworst 1 -setup -unique_pins -max_paths [llength $endpoints]]
  if {$verbose} {
    puts " -I- Number of timing paths: [llength $timing_paths]"
  }
  # Iterate through all the paths and extract the hierarchical pins that cross BlockA and BlockB
  set interBlockPins [list]
  set num 0
  foreach path $timing_paths {
    incr num
    if {$verbose} {
      puts " -I- Path $num : $path"
    }
    set report [report_timing -quiet -of_objects $path -return_string -no_header]
    # The report is parsed until a net that belongs to BlockB is found. The 2 pins
    # that connect in the transitive fanin of the net should be the 2 pins of interest

    set pinBlockA {}
    set netBlockB {}
    foreach line [split $report \n] {
      # Search for lines such as:
      #   net (fo=1033, unplaced)      0.466     0.466    inst/dport_rx_phy_inst/lnk_clk
      if {[regexp {net\s*\(.+\).+\s([^\s]+)\s*$} $line -- netname]} {
        if {[string first $BlockB $netname] == 0} {
          # Keep track of the first net found in the report that belongs to BlockB
          # When found, then stop processing the report
          set netBlockB $netname
          break
        }
      } elseif {[regexp {\s([^\s]+)\s*$} $line -- pinname]} {
        # Search for lines such as:
        #   FDRE (Prop_fdre_C_Q)         0.249     7.495 r  usbEngine1/u4/inta_reg/Q
        #                                0.383    -1.672 r  Inst_mac_logic/Inst_mac_25x18/p_accum_reg/P[47]
        if {[string first $BlockA $pinname] == 0} {
          # Keep track of the last pin found in the report that belongs to BlockA
          set pinBlockA $pinname
        }
      }
    }
    if {$pinBlockA == {}} {
      puts " -E- could not find any pin from $BlockA from report. Process next timing path"
      # Process next timing path
      continue
    }
    if {$netBlockB == {}} {
      puts " -E- could not find net from report. Process next timing path"
      # Process next timing path
      continue
    }

    # Search for the last hierarchical pin of BlockA that is in the transitive
    # fanout of $pinBlockA
    # Assumption: the net does not split between $pinBlockA and the hierarchical
    # pin on BlockA that we are interested in
    set loop 1
    set pin $pinBlockA
    set visited $pin
    while $loop {
      # Net connected to pin
      set net [get_nets -of [get_pins $pin] -boundary_type upper]
      # Hierarchical pins connected to net
      foreach p [get_pins -of $net -filter {IS_LEAF == 0}] {
        if {[lsearch -exact $visited $p] == -1} {
          # Search for the first hierarchical pin that is found and that
          # has not been visited yet
          break
        } else {
        }
      }
      # If the hierarchical pin name does not match $BlockA, it means that we have
      # already left BlockA. In this case, the previous hierarchical pin that has
      # been vivited ($pin) is the last hierarchical pin that belongs to BlockA
      if {[string first $BlockA $p] == -1} {
        set hierPinBlockA $pin
        set loop 0
        break
      }
      set pin $p
      lappend visited $pin
    }

    # Search for the first hierarchical pin of BlockB that is in the transitive
    # fanin of $netBlockB
    # Assumption: the net does not split between the hierarchical pin on BlockB 
    # and the net $netBlockB
    set loop 1
    # It reuses the same piece of code as above, so I need a pin to get started
    set pin [lindex [get_pins -of [get_nets $netBlockB] -filter {IS_LEAF == 0}] 0]
    set visited $pin
    while $loop {
      # Net connected to pin
      set net [get_nets -of [get_pins $pin] -boundary_type upper]
      # Hierarchical pins connected to net
      foreach p [get_pins -of $net -filter {IS_LEAF == 0}] {
        if {[lsearch -exact $visited $p] == -1} {
          # Search for the first hierarchical pin that is found and that
          # has not been visited yet
          break
        } else {
        }
      }
      # If the hierarchical pin name does not match $BlockB, it means that we have
      # already left BlockB. In this case, the previous hierarchical pin that has
      # been vivited ($pin) is the last hierarchical pin that belongs to BlockB
      if {[string first $BlockB $p] == -1} {
        set hierPinBlockB $pin
        set loop 0
        break
      }
      set pin $p
      lappend visited $pin
    }

    # Save the result
    lappend interBlockPins [list $hierPinBlockA $hierPinBlockB]
    if {$verbose} {
      puts " -I- hierPinBlockA : $hierPinBlockA"
      puts " -I- hierPinBlockB : $hierPinBlockB"
    }
  }
  
  return $interBlockPins
}

# puts " get_hier_pins.tcl sourced"

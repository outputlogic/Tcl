
proc highlightClockRoot {clock rootColor {clkRegionColor green} {skipClockRootNodeHighlight 0}} {
      
    set clockNet [get_nets -quiet $clock]
    if {$clockNet == {}} {
        set clock [get_clocks -quiet $clock]
        if {$clock == {}}              { puts "Error - invalid timing clock or clock net" return
        } elseif {[llength $clock] != 1} { puts "Error - expecting 1 clock only - $clock"; return }
        set srcPin [get_pins -quiet [get_property SOURCE_PINS $clock]]
        if {$srcPin == {}} { set srcPin [get_ports -quiet [get_property SOURCE_PINS $clock]] }
        if {[llength $srcPin] != 1} { puts "Error - expecting clock with 1 source only - $srcPin"; return }
        set clockNet [get_nets -of $srcPin]
        if {$clockNet == {}} { puts "Error - no net connected to clock driver"; return }
        set clockNet [get_nets -quiet [lsort -unique [get_property PARENT [get_nets -filter {TYPE == GLOBAL_CLOCK} -of [all_fanout -flat $clockNet]]]]]
        if {[llength $clockNet] != 1} { puts "Error - found [llength $clockNet] GLOBAL_CLOCK nets for clock $clock. Expecting 1 only..."; return}
    }
    if {[get_property CLOCK_ROOT $clockNet] == {}} { puts "Error - cannot find CLOCK_ROOT info on net $clockNet"; return }
    if {[get_property -quiet MULTI_CLOCK_ROOT_REPORT $clockNet] != ""} {
      puts "Info - net has multiple clock roots: [get_property MULTI_CLOCK_ROOT_REPORT $clockNet]"
    }
    set clockNet_driver [get_cells -of $clockNet -filter REF_NAME=~BUFG*]
    set clockRegions [get_clock_regions -quiet -of [get_sites -quiet -of [get_cells -quiet -of [get_pins -leaf -of $clockNet -filter DIRECTION==IN]]]]
    if {$clkRegionColor != {} && $clockRegions != {}} {
        highlight_objects -color $clkRegionColor $clockRegions 
    }
    unhighlight_objects [get_clock_regions [get_property CLOCK_ROOT $clockNet]]
    highlight_objects -color $rootColor [get_clock_regions [get_property CLOCK_ROOT $clockNet]]
    mark_objects -color blue $clockNet_driver
    # Highlighting nodes if info avail
    set CLOCK_ROOT_NODE [get_property CLOCK_ROOT_NODE $clockNet]
    if {!$skipClockRootNodeHighlight && $CLOCK_ROOT_NODE != {}} {
        set CLOCK_ROOT_NODE [get_nodes $CLOCK_ROOT_NODE]
        highlight_objects -color $rootColor $CLOCK_ROOT_NODE
    }
}

proc annotateClockRootProperty {{rpt_file "none"}} {
      
      if {$rpt_file eq "none"} {
            set data [split [report_clock_utilization -clock_roots_only -return_string] "\n"]
      } else {
            set fp [open ${rpt_file} r]
            set file_data [read $fp]
            close $fp
            set data [split $file_data "\n"]
      }

      # +-------+-----------------------------------------------------------------------+-------------------+------------------------------------------------------+
      # | Index | Clock Net                                                             | Root Clock Region | Clock Root Node                                      |
      # +-------+-----------------------------------------------------------------------+-------------------+------------------------------------------------------+
      # |     1 | dbg_hub/inst/idrck                                                    | X1Y3              | RCLK_RCLK_BRAM_L_AUXCLMP_FT_X23Y269/CLK_VDISTR_BOT0  |
      # |     2 | free_clk                                                              | X3Y6              | RCLK_CLEL_R_L_X52Y389/CLK_TEST_BUF_SITE_1_CLK_IN     |
      # |     3 | i_pll/inst/clk_out2                                                   | X1Y3              | RCLK_CLE_M_L_X33Y269/CLK_VDISTR_BOT                  |
      # |     4 | i_transceiver_example_wrapper/gtwiz_userclk_rx_inst/O1                | X1Y4              | RCLK_RCLK_BRAM_L_BRAMCLMP_FT_X18Y329/CLK_VDISTR_BOT0 |
      # |     5 | i_transceiver_example_wrapper/gtwiz_userclk_tx_inst/O1                | X1Y4              | RCLK_CLEL_R_L_X17Y329/CLK_VDISTR_BOT                 |
      # |     6 | mb_sub_wrapper_i/mb_sub_i/microblaze_sub_system/mdm_1/U0/Dbg_Clk_0    | X2Y3              | RCLK_CLEL_R_L_X36Y269/CLK_VDISTR_BOT                 |
      # |     7 | mb_sub_wrapper_i/mb_sub_i/microblaze_sub_system/mdm_1/U0/Dbg_Update_0 | X2Y3              | RCLK_RCLK_BRAM_L_BRAMCLMP_FT_X36Y269/CLK_VDISTR_BOT1 |
      # +-------+-----------------------------------------------------------------------+-------------------+------------------------------------------------------+

      set section_header {^.*Index.*Clock Net.*Root Clock Region.*Clock Root Node.*$}
      set section_end {^$}
      set in_section 0
      create_property CLOCK_ROOT_NODE net
      create_property MULTI_CLOCK_ROOT_REPORT net
      foreach line $data {
            if {[regexp -- $section_header $line ]} { set in_section 1}
            if {[regexp -- $section_end $line ]} { set in_section 0}
            if {$in_section} {
                  puts $line
                  if {[regexp {\|\s*(\d*)\s*\|\s*(\S*)\s*\|\s*(\S*)\s*\|\s*(\S*)\s*\|} $line all index clockNet rootClockRegion clockRootNode]} {
                        if {$clockNet == "" && $rootClockRegion != ""} {
                          set prevRootClockRegion [get_property CLOCK_ROOT [get_nets $prevClockNet]]
                          set multiClockRoot [get_property MULTI_CLOCK_ROOT_REPORT [get_nets $prevClockNet]]
                          if {$multiClockRoot == ""} {
                            set_property MULTI_CLOCK_ROOT_REPORT [concat $prevRootClockRegion $rootClockRegion] [get_nets $prevClockNet]
                          } else {
                            set_property MULTI_CLOCK_ROOT_REPORT [concat $multiClockRoot $rootClockRegion] [get_nets $prevClockNet]
                          }
                          set prevClockRootNode [get_property CLOCK_ROOT_NODE [get_nets $prevClockNet]]
                          set_property CLOCK_ROOT_NODE [concat $prevClockRootNode $clockRootNode] [get_nets $prevClockNet]
                          continue
                        }
                        set prevClockNet $clockNet
                        if {$rootClockRegion == "" && $clockRootNode == ""} { continue }
                        set_property CLOCK_ROOT $rootClockRegion [get_nets $clockNet]
                        set_property CLOCK_ROOT_NODE $clockRootNode [get_nets $clockNet]
                        lappend clkNets $clockNet
                  }
            }
      }

      return $clkNets

      if {!$set_property} {
            return CLOCK_ROOT
      } else {
            return 1
      }

}

#set clkNet [get_nets xxx]
proc reportBufceRowProgDly {clkNet} {
  set clkNet [get_nets $clkNet]
  set bufceRowSites [get_sites -of [get_site_pins -filter {NAME =~ BUFCE_ROW_*/CLK_IN} -of [get_nodes -of $clkNet]]]
  foreach bufceRow $bufceRowSites {
    puts "$bufceRow - Clock Region: [get_clock_regions -of $bufceRow] - Prog Delay Config: [internal::get_prog_delay -site $bufceRow]"
  }
}

proc incrBufceRowProgDly {clkNet} {
  set clkNet [get_nets $clkNet]
  set bufceRowSites [get_sites -of [get_site_pins -filter {NAME =~ BUFCE_ROW_*/CLK_IN} -of [get_nodes -of $clkNet]]]
  foreach bufceRow $bufceRowSites {
    set oldVal [internal::get_prog_delay -site $bufceRow]
    set newVal [expr $oldVal + 1]
    internal::set_prog_delay -site $bufceRow -val $newVal
    puts "$bufceRow - Clock Region: [get_clock_regions -of $bufceRow] - New Prog Delay Config: [internal::get_prog_delay -site $bufceRow] (old value: $oldVal)"
  }
}

proc setBufceRowProgDly {clkNet progDlyVals} {
  set clkNet [get_nets $clkNet]
  array set progDlyArray $progDlyVals
  set bufceRowSites [get_sites -of [get_site_pins -filter {NAME =~ BUFCE_ROW_*/CLK_IN} -of [get_nodes -of $clkNet]]]
  foreach bufceRow $bufceRowSites {
    set clkReg [get_clock_regions -of $bufceRow]
    puts "Processing $clkReg - $bufceRow"
    set Y [regsub {X(\d+)Y(\d+)} $clkReg {Y\2}]
    if {![info exists progDlyArray($Y)]} { puts "Skipping ($Y)"; continue }
    set oldVal [internal::get_prog_delay -site $bufceRow]
    set newVal $progDlyArray($Y)
    internal::set_prog_delay -site $bufceRow -val $newVal
    puts "$bufceRow - Clock Region: $clkReg - New Prog Delay Config: [internal::get_prog_delay -site $bufceRow] (old value: $oldVal)"
  }
}

proc highlightRouteToClockPin {clkPins {color red}} {
  set clkPins [get_pins -quiet $clkPins]
  if {$clkPins == {}} { puts "Error - invalid arg"; return }
  foreach clkPin $clkPins {
    set clkPinDrv [get_pins -filter {direction == out} -leaf -of [get_nets -of $clkPin]]
    highlight_objects [get_nodes -from [get_site_pins -of $clkPinDrv] -to [get_site_pins -of $clkPin] -of [get_nets -of $clkPin]] -color $color
    mark_objects -color $color $clkPin
  }
}

proc displayClockRegionLoads {net {indent ""}} {
  set clockRegions [get_clock_regions]
  set xrange [lsort -unique -integer [regsub -all {X(\S+)Y(\S+)} $clockRegions {\1}]]
  set yrange [lsort -unique -integer -decreasing [regsub -all {X(\S+)Y(\S+)} $clockRegions {\2}]]
  foreach cr $clockRegions { set cellCnt($cr) 0 }
  #foreach cell [all_fanout -flat -endpoints_only -only_cells $net] {}
  foreach cell [get_cells -quiet -of [get_pins -quiet -leaf -filter {DIRECTION==IN} -of $net]] {
    if {[catch {set cr [get_clock_regions -of $cell]} foo]} { continue }
    incr cellCnt($cr)
  }
  foreach y $yrange {
    set row {}
    foreach x $xrange {
      set cr X${x}Y${y}
      lappend row [format "%6s" $cellCnt($cr)]
    }
    puts [format "${indent}%-3s [join $row {|}]" Y${y}]
  }
  set row {}
  foreach x $xrange { lappend row [format "%6s" X${x}] }
  puts "${indent}    [join $row { }]"
}

proc displayClockRegionLoadsOfNet {object} {
  if {[lsort -unique [get_property CLASS $object]] == "pin"} {
    set tmpNet [get_nets -of $object]
  } else {
    set tmpNet $object
  }
  displayClockRegionLoads $tmpNet
}

proc reportClockTrack {{clkBuffers ""}} {
  if {$clkBuffers==""} {
    set clkBuffers [get_cells -hierarchical -filter {PRIMITIVE_TYPE=~CLOCK.BUFFER.* && PRIMITIVE_TYPE!=CLOCK.BUFFER.BUFG_GT_SYNC}]
  }
  if {$clkBuffers==""} {
    puts "Error - no clock buffer found in the design"
    return
  }
  set total 0
  set distrOnly 0
  set noTrack 0
  foreach buf $clkBuffers {
    set bufOPin [get_pins -filter {DIRECTION==OUT} -of $buf]
    set nodes [get_nodes -from [get_site_pins -of $bufOPin] -of [get_nets -of $bufOPin]]
    set routingIndex [regsub {.*HROUTE_([RL])(\d+).*} [lindex [filter $nodes {NAME=~*HROUTE_R* || NAME=~*HROUTE_L*}] 0] {\2}]
    if {$routingIndex == ""} {
      set distrIndex [regsub {.*HDISTR_([LR])(\d+).*} [lindex [filter $nodes {NAME=~*HDISTR_R* || NAME=~*HDISTR_L*}] 0] {\2}]
      set index $distrIndex
      set tag "D"
      if {$distrIndex != ""} { incr distrOnly }
    } else {
      set index $routingIndex
      set tag "R"
    }
    puts [format "%2s (%s) - %-10s - %s" $index $tag [get_property REF_NAME $buf] $buf]
    if {$index == ""} {
      set index "none"
      incr noTrack
    }
    if {[info exist count($index)]} {
      incr count($index)
    } else {
      set count($index) 1
    }
    incr total
  }
  puts "\n### Global Clock Routing and Distribution Track Usage Summary ###"
  foreach index [lsort [array names count]] {
    puts [format " Track %4s = %2s buffers" $index $count($index)]
  }
  puts ""
  puts "Total Buffers   = $total"
  puts "Routing+Distrib = [expr $total - $distrOnly - $noTrack]"
  puts "Distrib Only    = $distrOnly"
  puts "No Track        = $noTrack"
}

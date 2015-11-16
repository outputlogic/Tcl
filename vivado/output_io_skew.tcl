
# Proc to reload current script
proc [file tail [info script]] {} " source [info script]; puts \" [info script] reloaded\" "


##############################################################################
##############################################################################
#
# Skew for CK 
# output_io_skew -ports [concat [get_ports rldiii_ck_p[0]] [get_ports rldiii_a*] [get_ports  rldiii_ba*] [get_ports rldiii_we*] [get_ports  rldiii_cs*] ]
#
# Skew for DK[0]
# output_io_skew -clock [get_ports rldiii_dk_p[0]] -ports [concat [get_ports rldiii_dk_p[0]] [get_ports rldiii_dq[0]] [get_ports rldiii_dq[1]] [get_ports rldiii_dq[2]] [get_ports rldiii_dq[3]] [get_ports rldiii_dq[4]] [get_ports rldiii_dq[5]] [get_ports rldiii_dq[6]] [get_ports rldiii_dq[7]] [get_ports rldiii_dq[8]] [get_ports rldiii_dq[9]] [get_ports rldiii_dq[10]] [get_ports rldiii_dq[11]] [get_ports rldiii_dq[12]] [get_ports rldiii_dq[13]] [get_ports rldiii_dq[14]] [get_ports rldiii_dq[15]] [get_ports rldiii_dq[16]] [get_ports rldiii_dq[17]] ]
# output_io_skew -clock DK_0 -ports [concat [get_ports rldiii_dq[0]] [get_ports rldiii_dq[1]] [get_ports rldiii_dq[2]] [get_ports rldiii_dq[3]] [get_ports rldiii_dq[4]] [get_ports rldiii_dq[5]] [get_ports rldiii_dq[6]] [get_ports rldiii_dq[7]] [get_ports rldiii_dq[8]] [get_ports rldiii_dq[9]] [get_ports rldiii_dq[10]] [get_ports rldiii_dq[11]] [get_ports rldiii_dq[12]] [get_ports rldiii_dq[13]] [get_ports rldiii_dq[14]] [get_ports rldiii_dq[15]] [get_ports rldiii_dq[16]] [get_ports rldiii_dq[17]] ]
#
# Skew for DK[1]
# output_io_skew -ports [concat [get_ports rldiii_dk_p[1]] [get_ports rldiii_dq[18]] [get_ports rldiii_dq[19]] [get_ports rldiii_dq[20]] [get_ports rldiii_dq[21]] [get_ports rldiii_dq[22]] [get_ports rldiii_dq[23]] [get_ports rldiii_dq[24]] [get_ports rldiii_dq[25]] [get_ports rldiii_dq[26]] [get_ports rldiii_dq[27]] [get_ports rldiii_dq[28]] [get_ports rldiii_dq[29]] [get_ports rldiii_dq[30]] [get_ports rldiii_dq[31]] [get_ports rldiii_dq[32]] [get_ports rldiii_dq[33]] [get_ports rldiii_dq[34]] [get_ports rldiii_dq[35]] ]
#
##############################################################################
##############################################################################

# FIX for DK[0]
# create_generated_clock -name DK_0 -source [get_pins u_rld3_x36_nodm/u_mig_7series_v1_7_rld_memc_ui_top_std/u_rld_phy_top/u_qdr_rld_mc_phy/qdr_rld_phy_4lanes_0.u_qdr_rld_phy_4lanes/qdr_rld_byte_lane_A.qdr_rld_byte_lane_A/gen_ddr_dk.gen_diff_ddr_dk.ddr_dk/C] -divide_by 1 [get_ports {rldiii_dk_p[0]}]
# report_timing -to {rldiii_dq[0]} -delay_type max -corner Fast
# report_timing -to {rldiii_dq[0]} -delay_type min -corner Fast
# report_timing -to {rldiii_dq[0]} -delay_type max -corner Slow
# report_timing -to {rldiii_dq[0]} -delay_type min -corner Slow

# set_data_check -setup 0 -clock [get_clocks DK_0] -from [get_ports rldiii_dk_p[0]] -to [list rldiii_dq[0] rldiii_dq[1] rldiii_dq[2] rldiii_dq[3] rldiii_dq[4] rldiii_dq[5] rldiii_dq[6] rldiii_dq[7] rldiii_dq[8] rldiii_dq[9] rldiii_dq[10] rldiii_dq[11] rldiii_dq[12] rldiii_dq[13] rldiii_dq[14] rldiii_dq[15] rldiii_dq[16] rldiii_dq[17]]
# report_timing -to [list rldiii_dq[0] rldiii_dq[1] rldiii_dq[2] rldiii_dq[3] rldiii_dq[4] rldiii_dq[5] rldiii_dq[6] rldiii_dq[7] rldiii_dq[8] rldiii_dq[9] rldiii_dq[10] rldiii_dq[11] rldiii_dq[12] rldiii_dq[13] rldiii_dq[14] rldiii_dq[15] rldiii_dq[16] rldiii_dq[17]]

# report_datasheet -file datasheet.rpt 

#------------------------------------------------------------------------
# output_io_skew
#------------------------------------------------------------------------
# Report DDR output skews
#------------------------------------------------------------------------
proc output_io_skew { args } {

  proc lshift {inputlist} {
    upvar $inputlist argv
    set arg  [lindex $argv 0]
    set argv [lrange $argv 1 end]
    return $arg
  }

  #-------------------------------------------------------
  # Process command line arguments
  #-------------------------------------------------------
  set msgLevel 0
  set error 0
  set help 0
  set removeClockUncertainty  0
  set removeRequirement  0
  set ocv 1
  set debug 0
  set setOfPorts [list]
  set refClock {}
  set commandLine $args
  if {[llength $args] == 0} { incr help }
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -ports -
      -port -
      -p {
           set setOfPorts [concat $setOfPorts [lshift args]]
      }
      -clock -
      -c {
           set refClock [lshift args]
      }
      -remove_clock_uncertainty -
      -rcu -
      -r {
            set removeClockUncertainty 1
      }
      -remove_requirement -
      -rr {
            set removeRequirement 1
      }
      -no_ocv  {
            set ocv 0
      }
      -debug -
      -d {
            set debug 1
      }
      -q -
      -quiet {
            set msgLevel -1
      }
      -v -
      -verbose {
            set msgLevel 1
      }
      -h -
      -help {
            incr help
      }
      default {
            if {[string match "-*" $name]} {
              puts " ERROR - option '$name' is not a valid option."
              incr error
            } else {
              puts "ERROR - option '$name' is not a valid option."
              incr error
            }
      }
    }
  }
  
  if {$help} {
    set callerName [lindex [info level [expr [info level] -1]] 0]
    # <-- HELP
    puts [format {
  Usage: %s
              [-ports|-p <listOfPorts>]
              [-clock|-c <refClock>]
              [-remove_clock_uncertainty|-rcu]
              [-remove_requirement|-rr]
              [-quiet|-q]
              [-verbose|-v]
              [-help|-h]
              
  Description: reports the skew on some output data ports relative to an output reference clock port.
               The script can be used to report skew on output DDR busses.
               The -remove_clock_uncertainty option removes the effect of the clock uncertainty from 
               the path delay calculation for all the ports.
               The -remove_requirement option removes the effect of the clock requirement (capture clock
               path) from the path delay calculation for all the ports.
  
  Example:
     output_io_skew -clock DK_0 -ports [concat [get_ports rldiii_dq[0]] [get_ports rldiii_dq[1]] .... [get_ports rldiii_dq[17]] ]
     output_io_skew -clock [get_ports rldiii_dk_p[0]] -ports [concat [get_ports rldiii_dq[0]] [get_ports rldiii_dq[1]] .... [get_ports rldiii_dq[17]] ]

} $callerName]
    # HELP -->
    return {}
  }

  # Check whether the reference clock matches a clock name or a port name
  if {[get_clocks -of_objects [get_ports $refClock -quiet] -quiet] != {}} {
    # -clock provided a clock port
    set refClock [get_clocks -of_objects [get_ports $refClock -quiet] -quiet] 
  } elseif {[get_clocks $refClock -quiet] != {}} {
    # -clock provided a clock name
    set refClock [get_clocks $refClock -quiet]
  } else {
    set refClock {}
  }
  
  if {$refClock == {}} {
    puts " ERROR - no valid reference clock provided."
    incr error
  }
  
  if {$error} {
    return {}
  }
  
  if {$msgLevel >= 1} {
    puts " -I- Starting output_io_skew on [clock format [clock seconds]]"
    puts " -I- Arguments: $commandLine"
    puts " -I- Reference clock: $refClock"
    puts " -I- List of ports: $setOfPorts"
  }
    
  # Reset some initialized data structures
  catch {unset portList}
  catch {unset Slow_max}
  catch {unset Slow_min}
  catch {unset Slow_clk}
  catch {unset Fast_max}
  catch {unset Fast_min}
  catch {unset Fast_clk}

  set portList $setOfPorts

  set subExp [regsub {[][{};#\\\$\s\u0080-\uffff]} [current_instance .]/ {\\\0}]

  # Turn off the multi-corners mode
  if {!$ocv} {
    config_timing_corner -multi_corner off
  }

  # Collecting data for each corner
  foreach corner {Slow Fast} {
      # Setting corner configuration
      config_timing_corner -corner $corner -delay_type min_max
      switch $corner {
          Slow { config_timing_corner -corner Fast -delay_type none }
          Fast { config_timing_corner -corner Slow -delay_type none }
      }
      # Querying slack for min and max delay analysis
      foreach port $portList {
          set portname [regsub -all $subExp $port {_}]
          set maxPath [get_timing_path -to [get_ports $port] -delay_type max]
          set minPath [get_timing_path -to [get_ports $port] -delay_type min]
          if {$msgLevel >= 1} {
            puts " -I- Processing port $port ($portname)"
            puts " -I- Max Path: $maxPath"
            puts " -I- Min Path: $minPath"
          }
          set maxSlack [get_property SLACK $maxPath]
          set minSlack [get_property SLACK $minPath]
          set maxUncertainty [get_property UNCERTAINTY $maxPath]
          set minUncertainty [get_property UNCERTAINTY $minPath]
          set maxRequirement [get_property REQUIREMENT $maxPath]
          set minRequirement [get_property REQUIREMENT $minPath]
          if {$msgLevel >= 1} { puts " -I- Max Path Requirement: $maxRequirement" }
          if {$msgLevel >= 1} { puts " -I- Min Path Requirement: $minRequirement" }
          if {([string is double $maxUncertainty]) && $removeClockUncertainty} {
              # The uncertainty is a negative number, so substract the uncertainty 
              # to "add" it back to the slack
              if {$msgLevel >= 1} { puts " -I- Removing clock uncertainty from Max Slack: MaxSlack=$maxSlack / Uncertainty=$maxUncertainty" }
              set maxSlack [format "%.6f" [expr $maxSlack - $maxUncertainty] ]
          }
          if {([string is double $minUncertainty]) && $removeClockUncertainty} {
              # The uncertainty is a positive number
              if {$msgLevel >= 1} { puts " -I- Removing clock uncertainty from Min Slack: MinSlack=$minSlack / Uncertainty=$minUncertainty" }
              set minSlack [format "%.6f" [expr $minSlack + $minUncertainty] ]
          }
          if {([string is double $maxRequirement]) && $removeRequirement} {
              if {$msgLevel >= 1} { puts " -I- Removing clock requirement from Max Slack: MaxSlack=$maxSlack / Requirement=$maxRequirement" }
              set maxSlack [format "%.6f" [expr $maxSlack - $maxRequirement] ]
          }
          if {([string is double $minRequirement]) && $removeRequirement} {
              if {$msgLevel >= 1} { puts " -I- Removing clock requirement from Min Slack: MinSlack=$minSlack / Requirement=$minRequirement" }
              set minSlack [format "%.6f" [expr $minSlack - $minRequirement] ]
          }
          set relatedClockMax [get_property ENDPOINT_CLOCK $maxPath]
          set relatedClockMin [get_property ENDPOINT_CLOCK $minPath]
          if {($relatedClockMax == {}) || ($relatedClockMin == {})} {
              puts "WARNING - could not extract clock name for port $port. Skipping this port."
              continue
          }
          if {($relatedClockMax != $refClock) || ($relatedClockMin != $refClock)} {
              puts "WARNING - port $port has a clock ($relatedClockMax) that differs to the reference clock ($refClock). Skipping this port."
              continue
          }
          set porttable($portname) $port
          set ${corner}_min($portname) $minSlack
          set ${corner}_max($portname) $maxSlack
          if {$relatedClockMax != $relatedClockMin} {
              puts "WARNING - $port reported against different clocks - $relatedClockMin (Min) && $relatedClockMax (Max)"
              set ${corner}_clk($portname) "???"
          } else {
              set ${corner}_clk($portname) $relatedClockMax
          }
          if {$msgLevel >= 1} {
              puts " -I- Max Slack: $maxSlack ($relatedClockMax)"
              puts " -I- Min Slack: $minSlack ($relatedClockMin)"
          }
          # For debug purpose
          if {$debug} {
            puts " -I- REPORT_TIMING ($corner/MAX)"
            report_timing -of $maxPath
            puts " -I- REPORT_TIMING ($corner/MIN)"
            report_timing -of $minPath
          }
      }
  }
  config_timing_corner -corner Slow -delay_type min_max
  config_timing_corner -corner Fast -delay_type min_max

  # Restore the multi-corners mode
  if {!$ocv} {
    config_timing_corner -multi_corner on
  }

  # Analyzing data
  set tWdth 65
  puts [string repeat "-" $tWdth]
  if {$removeClockUncertainty} {
      puts "-- Skew table for reference clock $refClock (EXCLUDES CLOCK UNCERTAINTY)"
  } else {
      puts "-- Skew table for reference clock $refClock (INCLUDES CLOCK UNCERTAINTY)"
  }
  puts [string repeat "-" $tWdth]
  puts [format "%-20s | %-6s | %-8s | %-8s | %-s" "Port Name" Corner TCO(max) TCO(min) Clock]
  puts [string repeat "-" $tWdth]
  set allTimingPaths [list]
  foreach portname [lsort [array names Slow_max]] {
      foreach corner {Slow Fast} {
          set clk [expr $${corner}_clk\($portname\)]
          set clkPeriod [get_property PERIOD [get_clocks $clk]]
          #set tcoMax [format "%.3f" [eval expr $clkPeriod - $${corner}_max\($portname\)]]
          set tcoMax [format "%.3f" [expr $${corner}_max\($portname\)]]
          set tcoMin [format "%.3f" [expr $${corner}_min\($portname\)]]
          puts [format "%-20s | %-6s | %8s | %8s | %-s" $porttable($portname) $corner $tcoMax $tcoMin $clk]
          lappend allTimingPaths [list $porttable($portname) $corner $tcoMax $tcoMin $clk]
      }
      puts [string repeat "-" $tWdth]
  }

  catch {
    # Summary of worst tc0Max and tc0Min for Slow/Fast corners
    puts [string repeat "-" $tWdth]
    puts "-- SUMMARY"
    puts [string repeat "-" $tWdth]
    # Slow corner
    foreach {- - Slow_Worst_tc0Max - clock} [lindex [lsort -index 1 -dictionary -decreasing [lsort -index 2 -real -increasing $allTimingPaths]] 0 ] { break }
    foreach {- - - Slow_Worst_tc0Min clock} [lindex [lsort -index 1 -dictionary -decreasing [lsort -index 3 -real -increasing $allTimingPaths]] 0 ] { break }
    # Fast corner
    foreach {- - Fast_Worst_tc0Max - clock} [lindex [lsort -index 1 -dictionary -increasing [lsort -index 2 -real -increasing $allTimingPaths]] 0 ] { break }
    foreach {- - - Fast_Worst_tc0Min clock} [lindex [lsort -index 1 -dictionary -increasing [lsort -index 3 -real -increasing $allTimingPaths]] 0 ] { break }
    puts [format "%-20s | %-6s | %8s | %8s | %-s" {Skew} {Slow} $Slow_Worst_tc0Max $Slow_Worst_tc0Min $clock]
    puts [format "%-20s | %-6s | %8s | %8s | %-s" {Skew} {Fast} $Fast_Worst_tc0Max $Fast_Worst_tc0Min $clock]
    puts [string repeat "-" $tWdth]
    # Now get the global worst skew
    foreach {worstCorner worstSkew} [lindex [lsort -real -increasing -index 1 [list [list {Slow} $Slow_Worst_tc0Max] [list {Slow} $Slow_Worst_tc0Min] \
                                                                            [list {Fast} $Fast_Worst_tc0Max] [list {Fast} $Fast_Worst_tc0Min] ] ] \
                                     0 ] { break }
    puts [format "%-20s | %-6s | %8s | %8s | %-s" {Worst Skew} $worstCorner $worstSkew {} $clock]
    puts [string repeat "-" $tWdth]
  }

  if {$msgLevel >= 1} {
    puts " -I- Ending output_io_skew on [clock format [clock seconds]]"
  }

  return {}
}




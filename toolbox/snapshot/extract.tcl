####################################################################################################
# HEADER_BEGIN
# COPYRIGHT NOTICE
# Copyright 2001-2015 Xilinx Inc. All Rights Reserved.
# http://www.xilinx.com/support
# HEADER_END
####################################################################################################

proc [file tail [info script]] {} " source [info script]; puts \" [info script] reloaded\" "
proc reload {} " source [info script]; puts \" [info script] reloaded\" "

########################################################################################
##
## Company:        Xilinx, Inc.
## Created by:     David Pefourque
##
## Version:        2016.01.17
## Tool Version:   Vivado 2014.1
## Description:    This file defined default metrics for snapshot.tcl
##
########################################################################################

########################################################################################
## 2016.01.17 - Fixed error when extracting metrics from report_route_status
## 2016.01.11 - Added metric report.design_analysis.congestion
## 2015.12.14 - Minor restructuring so that existing metrics are not overriden
##            - Moved parseRDACongestion to ::tb::snapshot::parseRDACongestion
##            - Added report_design_analysis metrics in non-Vivado flow
##            - Added support for -once for method 'set'
## 2015.10.01 - Added placer/router congestion from report_design_analysis
## 2015.05.05 - Added report from report_design_analysis
## 2014.12.11 - Added report from check_timing
## 2014.10.07 - Check if a metric has already been defined before setting it so that
##              it does not get overriden
##            - Extract metrics from report_route_status when metric report.route_status
##              has been set in non-Vivado mode
##            - Extract metrics from report_timing_summary when metric report.timing_summary
##              has been set in non-Vivado mode
## 2014.08.22 - Removed -max_path with report_timing_summary
## 2014.07.08 - Added metric report.control_sets
## 2014.06.26 - Initial release
########################################################################################

# Code from Frederic Revenu
# Extract the placement + routing congestions from report_design_analysis
# Format: North-South-East-West
#         PlacerNorth-PlacerSouth-PlacerEast-PlacerWest RouterNorth-RouterSouth-RouterEast-RouterWest
proc ::tb::snapshot::parseRDACongestion {report} {
  set section "other"
  set placerCong [list u u u u]
  set routerCong [list u u u u]
  foreach line [split $report \n] {
    if {[regexp {^\d. (\S+) Maximum Level Congestion Reporting} $line foo step]} {
      switch -exact $step {
        "Placed" { set section "placer" }
        "Router" { set section "router" }
        default  { set section "other" }
      }
    } elseif {[regexp {^\| (\S+)\s*\| (\S+)\s*\| \S+\s*\| \S+\s*| \S+\s*\| \S+\s*\| \S+\s*\| \S+\s*\| \S+\s*\| \S+\s*\| \S+\s*\|} $line foo card cong] || \
              [regexp {^\| (\S+)\s*\| (\S+)\s*\| \S+\s*\| \s*\S+ -> \S+\s*\|\s*$} $line foo card cong]} {
      switch -exact $cong {
        "1x1"     { set level 0 }
        "2x2"     { set level 1 }
        "4x4"     { set level 2 }
        "8x8"     { set level 3 }
        "16x16"   { set level 4 }
        "32x32"   { set level 5 }
        "64x64"   { set level 6 }
        "128x128" { set level 7 }
        "256x256" { set level 8 }
        default   { set level u }
      }
      if {$section == "placer"} {
        switch -exact $card {
          "North" { set placerCong [lreplace $placerCong 0 0 $level] }
          "South" { set placerCong [lreplace $placerCong 1 1 $level] }
          "East"  { set placerCong [lreplace $placerCong 2 2 $level] }
          "West"  { set placerCong [lreplace $placerCong 3 3 $level] }
        }
      } elseif {$section == "router"} {
        switch -exact $card {
          "North" { set routerCong [lreplace $routerCong 0 0 $level] }
          "South" { set routerCong [lreplace $routerCong 1 1 $level] }
          "East"  { set routerCong [lreplace $routerCong 2 2 $level] }
          "West"  { set routerCong [lreplace $routerCong 3 3 $level] }
        }
      }
    } elseif {[regexp {^\d\. } $line]} {
      set section "other"
    }
  }
  return [list [join $placerCong -] [join $routerCong -]]
}

if {[package provide Vivado] != {}} {
  # Default metrics only for Vivado
  namespace eval ::tb::snapshot::extract {
    proc default {} {
      variable [namespace parent]::params
      variable [namespace parent]::verbose
      variable [namespace parent]::debug
      # Vivado related statistics
      # The release name is shortened: 2014.3.0 => 2014.3
      snapshot set -once vivado.version [regsub {^([0-9]+\.[0-9]+)\.0$} [version -short] {\1}]
      snapshot set -once vivado.details [version]
      catch { snapshot set -once vivado.plateform $::tcl_platform(platform)  }
      catch { snapshot set -once vivado.os $::tcl_platform(os)  }
      catch { snapshot set -once vivado.osVersion $::tcl_platform(osVersion)  }
      # Project related statistics
      set project [current_project -quiet]
      if {$project != {}} {
        snapshot set -once project.details [report_property -quiet -return_string $project]
        snapshot set -once project.dir [file normalize [get_property -quiet DIRECTORY $project]]
        snapshot set -once project.part [get_property -quiet PART $project]
        snapshot set -once project.runs [get_runs -quiet]
      }
#       set run {}
      # Run related statistics
      set run [current_run -quiet]
      if {$run != {}} {
        snapshot set -once run.details [report_property -quiet -return_string $run]
        snapshot set -once run.dir [file normalize [get_property -quiet DIRECTORY $run]]
        snapshot set -once run.part [get_property -quiet PART $run]
        snapshot set -once run.parent [get_property -quiet PARENT $run]
        snapshot set -once run.progress [get_property -quiet PROGRESS $run]
        snapshot set -once run.stats.elapsed [get_property -quiet STATS.ELAPSED $run]
        snapshot set -once run.stats.tns [get_property -quiet STATS.TNS $run]
        snapshot set -once run.stats.ths [get_property -quiet STATS.THS $run]
        snapshot set -once run.stats.wns [get_property -quiet STATS.WNS $run]
        snapshot set -once run.stats.whs [get_property -quiet STATS.WHS $run]
        snapshot set -once run.stats.tpws [get_property -quiet STATS.TPWS $run]
      }
      # Messages related statistics
      snapshot set -once msg.error [get_msg_config -quiet -count -severity {error}]
      snapshot set -once msg.criticalwarning [get_msg_config -quiet -count -severity {critical warning}]
      snapshot set -once msg.warning [get_msg_config -quiet -count -severity {warning}]
      snapshot set -once msg.info [get_msg_config -quiet -count -severity {info}]
      # Design related statistics
      snapshot set -once design.nets [llength [get_nets -quiet -hier]]
      snapshot set -once design.cells [llength [get_cells -quiet -hier]]
      snapshot set -once design.ports [llength [get_ports -quiet]]
      snapshot set -once design.clocks.list [lsort [get_clocks -quiet]]
      snapshot set -once design.clocks.num [llength [get_clocks -quiet]]
      snapshot set -once design.allclocks.list [lsort [get_clocks -quiet -include_generated_clocks]]
      snapshot set -once design.allclocks.num [llength [get_clocks -quiet -include_generated_clocks]]
      snapshot set -once design.pblocks.list [lsort [get_pblocks -quiet]]
      snapshot set -once design.pblocks.num [llength [get_pblocks -quiet]]
      snapshot set -once design.ips.list [lsort [get_ips -quiet]]
      snapshot set -once design.ips.num [llength [get_ips -quiet]]
      # Various reports
      if {1} {
        if {![snapshot exists route.compile_order.constraints]} {
          catch {
            set filename [format {report_compile_order.%s} [clock seconds]]
            report_compile_order -constraints -file $filename
            set FH [open $filename {r}]
            set report [read $FH]
            close $FH
            file delete $filename
            snapshot set route.compile_order.constraints $report
          }
        }
      }
      if {![snapshot exists report.route_status]} {
        snapshot set report.route_status [report_route_status -quiet -return_string]
      }
#       snapshot set route.status [report_route_status -quiet -return_string]
#       snapshot set report.route_status [report_route_status -quiet -return_string]
#       set report [report_route_status -quiet -return_string]
#       snapshot set report.route_status $report
      set report [snapshot get report.route_status]
      foreach line [split $report \n] {
        if {[regexp {nets with routing errors[^\:]+\:\s*([0-9]+)\s*\:} $line - val]} {
          snapshot set -once report.route_status.errors $val
        } elseif {[regexp {fully routed nets[^\:]+\:\s*([0-9]+)\s*\:} $line - val]} {
          snapshot set -once report.route_status.routed $val
        } elseif {[regexp {nets with fixed routing[^\:]+\:\s*([0-9]+)\s*\:} $line - val]} {
          snapshot set -once report.route_status.fixed $val
        } elseif {[regexp {routable nets[^\:]+\:\s*([0-9]+)\s*\:} $line - val]} {
          snapshot set -once report.route_status.nets $val
        } else {
        }
      }
      if {![snapshot exists report.timing_summary]} {
        snapshot set report.timing_summary [report_timing_summary -quiet -delay_type min_max -no_detailed_paths -return_string]
      }
#       snapshot set report.timing_summary [report_timing_summary -quiet -return_string]
#       set report [report_timing_summary -quiet -delay_type min_max -no_detailed_paths -return_string]
#       snapshot set report.timing_summary $report
      set report [snapshot get report.timing_summary]
      # Quick way to extract WNS/TNS information from the timing summary report
      set report [split $report \n]
      if {[set i [lsearch -regexp $report {Design Timing Summary}]] != -1} {
         foreach {wns tns tnsFallingEp tnsTotalEp whs ths thsFallingEp thsTotalEp wpws tpws tpwsFailingEp tpwsTotalEp} [regexp -inline -all -- {\S+} [lindex $report [expr $i + 6]]] { break }
         snapshot set -once report.timing_summary.wns $wns
         snapshot set -once report.timing_summary.tns $tns
         snapshot set -once report.timing_summary.tns.failing $tnsFallingEp
         snapshot set -once report.timing_summary.tns.total $tnsTotalEp
         snapshot set -once report.timing_summary.whs $whs
         snapshot set -once report.timing_summary.ths $ths
         snapshot set -once report.timing_summary.ths.failing $thsFallingEp
         snapshot set -once report.timing_summary.ths.total $thsTotalEp
         snapshot set -once report.timing_summary.wpws $wpws
         snapshot set -once report.timing_summary.tpws $tpws
         snapshot set -once report.timing_summary.tpws.failing $tpwsFailingEp
         snapshot set -once report.timing_summary.tpws.total $tpwsTotalEp
      }
      if {![snapshot exists report.clocks]} {
        snapshot set report.clocks [report_clocks -quiet -return_string]
      }
      if {![snapshot exists report.clock_interaction]} {
        snapshot set report.clock_interaction [report_clock_interaction -quiet -return_string]
      }
      if {![snapshot exists report.clock_utilization]} {
        snapshot set report.clock_utilization [report_clock_utilization -quiet -return_string]
      }
      if {![snapshot exists report.clock_networks]} {
        snapshot set report.clock_networks [report_clock_networks -quiet -return_string]
      }
      if {![snapshot exists report.utilization]} {
        snapshot set report.utilization [report_utilization -quiet -return_string]
      }
      if {![snapshot exists report.high_fanout_nets]} {
        snapshot set report.high_fanout_nets [report_high_fanout_nets -quiet -return_string]
      }
      if {![snapshot exists report.ip_status]} {
        snapshot set report.ip_status [report_ip_status -quiet -return_string]
      }
      if {![snapshot exists report.control_sets]} {
        snapshot set report.control_sets [report_control_sets -quiet -return_string]
      }
      if {![snapshot exists report.ram_utilization]} {
        catch {snapshot set report.ram_utilization [report_ram_utilization -quiet -return_string]}
      }
      if {![snapshot exists report.slr]} {
        if {[llength [get_slrs -quiet]] > 1} { snapshot set report.slr [report_utilization -quiet -slr -return_string] }
      }
      if {![snapshot exists report.check_timing]} {
        catch {
          set filename [format {check_timing.%s} [clock seconds]]
          check_timing -file $filename
          set FH [open $filename {r}]
          set report [read $FH]
          close $FH
          file delete $filename
          snapshot set report.check_timing $report
        }
      }
      catch {
        if {![snapshot exists report.design_analysis]} {
          set report [report_design_analysis -max_paths 100 -timing -congestion -complexity -return_string]
          snapshot set report.design_analysis $report
        }
        set report [snapshot get report.design_analysis]
        set congestion [::tb::snapshot::parseRDACongestion $report]
        snapshot set -once report.design_analysis.congestion.placer [lindex $congestion 0]
        snapshot set -once report.design_analysis.congestion.router [lindex $congestion 1]
        # Adding metric report.design_analysis.congestion which is the congestion that is most
        # relevant for current snapshot
        if {[lindex $congestion 1] == {u-u-u-u}} {
        	# If the router congestion is unset (u-u-u-u), then save the placer congestion
          snapshot set -once report.design_analysis.congestion [lindex $congestion 0]
        } else {
        	# else, save the router congestion
          snapshot set -once report.design_analysis.congestion [lindex $congestion 1]
        }
      }
    }
  }
} else {
  # This section is reached when the snapshot is taken outside of vivado.
  # In this mode, if metrics report.route_status and report.timing_summary have been
  # specified then some sub-metrics are being extracted.
  # Example:
  #   % snapshot addfile report.timing_summary postroute.rpt
  #   % snapshot addfile report.route_status rouet_status.rpt
  #   % snapshot extract
  #   % snapshot save

#   namespace eval ::tb::snapshot::extract {}
  namespace eval ::tb::snapshot::extract {
    proc default {} {
      variable [namespace parent]::params
      variable [namespace parent]::verbose
      variable [namespace parent]::debug
      set release {}
      if {[snapshot exists report.route_status]} {
        set report [snapshot get report.route_status]
        foreach line [split $report \n] {
          if {[regexp {nets with routing errors[^\:]+\:\s*([0-9]+)\s*\:} $line - val]} {
            snapshot set -once report.route_status.errors $val
          } elseif {[regexp {fully routed nets[^\:]+\:\s*([0-9]+)\s*\:} $line - val]} {
            snapshot set -once report.route_status.routed $val
          } elseif {[regexp {nets with fixed routing[^\:]+\:\s*([0-9]+)\s*\:} $line - val]} {
            snapshot set -once report.route_status.fixed $val
          } elseif {[regexp {routable nets[^\:]+\:\s*([0-9]+)\s*\:} $line - val]} {
            snapshot set -once report.route_status.nets $val
          } elseif {[regexp -nocase {\|\s*Tool\s*Version\s*:\s*Vivado\s*(v\.)?([0-9\.]+)\s} $line - - val]} {
            # Extract Vivado release from header:
            # | Tool Version : Vivado v.2014.3 (lin64) Build 1034051 Fri Oct  3 16:31:15 MDT 2014
            set release $val
          } else {
          }
        }
      }
      if {[snapshot exists report.timing_summary]} {
        set report [snapshot get report.timing_summary]
        # Quick way to extract WNS/TNS information from the timing summary report
        set report [split $report \n]
        if {[set i [lsearch -regexp $report {Design Timing Summary}]] != -1} {
           foreach {wns tns tnsFallingEp tnsTotalEp whs ths thsFallingEp thsTotalEp wpws tpws tpwsFailingEp tpwsTotalEp} [regexp -inline -all -- {\S+} [lindex $report [expr $i + 6]]] { break }
           snapshot set -once report.timing_summary.wns $wns
           snapshot set -once report.timing_summary.tns $tns
           snapshot set -once report.timing_summary.tns.failing $tnsFallingEp
           snapshot set -once report.timing_summary.tns.total $tnsTotalEp
           snapshot set -once report.timing_summary.whs $whs
           snapshot set -once report.timing_summary.ths $ths
           snapshot set -once report.timing_summary.ths.failing $thsFallingEp
           snapshot set -once report.timing_summary.ths.total $thsTotalEp
           snapshot set -once report.timing_summary.wpws $wpws
           snapshot set -once report.timing_summary.tpws $tpws
           snapshot set -once report.timing_summary.tpws.failing $tpwsFailingEp
           snapshot set -once report.timing_summary.tpws.total $tpwsTotalEp
        }
        # Extract Vivado release from header:
        # | Tool Version : Vivado v.2014.3 (lin64) Build 1034051 Fri Oct  3 16:31:15 MDT 2014
        if {[set i [lsearch -regexp $report {\|\s*Tool\s*Version\s*:\s*Vivado\s*(v\.)?([0-9\.]+)\s}]] != -1} {
          regexp -nocase {\|\s*Tool\s*Version\s*:\s*Vivado\s*(v\.)?([0-9\.]+)\s} [lindex $report $i] - - val
          set release $val
        }
      }
      if {[snapshot exists report.design_analysis]} {
        set report [snapshot get report.design_analysis]
        set congestion [::tb::snapshot::parseRDACongestion $report]
        snapshot set -once report.design_analysis.congestion.placer [lindex $congestion 0]
        snapshot set -once report.design_analysis.congestion.router [lindex $congestion 1]
        # Adding metric report.design_analysis.congestion which is the congestion that is most
        # relevant for current snapshot
        if {[lindex $congestion 1] == {u-u-u-u}} {
        	# If the router congestion is unset (u-u-u-u), then save the placer congestion
          snapshot set -once report.design_analysis.congestion [lindex $congestion 0]
        } else {
        	# else, save the router congestion
          snapshot set -once report.design_analysis.congestion [lindex $congestion 1]
        }
        # Extract Vivado release from header:
        # | Tool Version : Vivado v.2014.3 (lin64) Build 1034051 Fri Oct  3 16:31:15 MDT 2014
        set report [split $report \n]
        if {[set i [lsearch -regexp $report {\|\s*Tool\s*Version\s*:\s*Vivado\s*(v\.)?([0-9\.]+)\s}]] != -1} {
          regexp -nocase {\|\s*Tool\s*Version\s*:\s*Vivado\s*(v\.)?([0-9\.]+)\s} [lindex $report $i] - - val
          set release $val
        }
      }
      # The release name is shortened: 2014.3.0 => 2014.3
      snapshot set -once vivado.version [regsub {^([0-9]+\.[0-9]+)\.0$} $release {\1}]
    }
  }

}


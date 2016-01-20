####################################################################################################
# HEADER_BEGIN
# COPYRIGHT NOTICE
# Copyright 2001-2016 Xilinx Inc. All Rights Reserved.
# http://www.xilinx.com/support
# HEADER_END
####################################################################################################

# proc [file tail [info script]] {} " source [info script]; puts \" [info script] reloaded\" "
# proc reload {} " source [info script]; puts \" [info script] reloaded\" "

########################################################################################
##
## Company:        Xilinx, Inc.
## Created by:     David Pefourque
##
## Description:    Generate a design summary report
##
########################################################################################

########################################################################################
## 2016.01.18 - Added tag metrics
##            - Added congestion metrics
##            - Added constraints metrics
##            - Added check_timing metrics
##            - Added clock_interaction metrics
##            - Added route metrics
##            - Added additional default metrics
##            - Added additional timing metrics
##            - Misc enhancements
## 2015.08.26 - Initial release
########################################################################################

# Example of report:
#   +-----------------------------------------------------------------------------------------------------------------------+
#   | Design Summary                                                                                                        |
#   +----------------------------------------------+-------------------------------------------------+----------------------+
#   | Id                                           | Name                                            | Value                |
#   +----------------------------------------------+-------------------------------------------------+----------------------+
#   | tag.experiment                               | Experiment                                      | myexperiment         |
#   | tag.project                                  | Project                                         | myproject            |
#   | tag.step                                     | Step                                            | place_design         |
#   | tag.version                                  | Version                                         | myversion            |
#   +----------------------------------------------+-------------------------------------------------+----------------------+
#   | vivado.os                                    | OS                                              | Linux                |
#   | vivado.osVersion                             | OS Version                                      | 2.6.18-371.4.1.el5   |
#   | vivado.plateform                             | Plateform                                       | unix                 |
#   | vivado.top                                   | Top Module Name                                 | hothk_sata_top       |
#   | vivado.version                               | Vivado Release                                  | 2016.1               |
#   +----------------------------------------------+-------------------------------------------------+----------------------+
#   | design.cells.blackbox                        | Number of blackbox cells                        | 0                    |
#   | design.cells.hier                            | Number of hierarchical cells                    | 11488                |
#   | design.cells.primitive                       | Number of primitive cells                       | 1104666              |
#   | design.clocks.autoderived                    | Number of auto-derived clocks                   | 43                   |
#   | design.clocks.primary                        | Number of primary clocks                        | 13                   |
#   | design.clocks.usergenerated                  | Number of user generated clocks                 | 33                   |
#   | design.clocks.virtual                        | Number of virtual clocks                        | 0                    |
#   | design.clocks                                | Number of clocks                                | 89                   |
#   | design.ips                                   | Number of IPs                                   | 0                    |
#   | design.nets.slls                             | Number of SLL nets                              | 0                    |
#   | design.nets                                  | Number of nets                                  | 1318820              |
#   | design.part                                  | Part                                            | xcku115-flvf1924-2-e |
#   | design.pblocks                               | Number of pblocks                               | 0                    |
#   | design.ports                                 | Number of ports                                 | 280                  |
#   | design.slrs                                  | Number of SLRs                                  | 2                    |
#   +----------------------------------------------+-------------------------------------------------+----------------------+
#   | utilization.clb.ff.pct                       | CLB Registers (%)                               | 31.38                |
#   | utilization.clb.ff                           | CLB Registers                                   | 416347               |
#   | utilization.clb.lut.pct                      | CLB LUTs (%)                                    | 83.98                |
#   | utilization.clb.lut                          | CLB LUTs                                        | 557059               |
#   | utilization.ctrlsets.lost                    | Registers Lost due to Control Sets              | n/a                  |
#   | utilization.ctrlsets.uniq                    | Unique Control Sets                             | n/a                  |
#   | utilization.dsp.pct                          | DSPs (%)                                        | 0.43                 |
#   | utilization.dsp                              | DSPs                                            | 24                   |
#   | utilization.io.pct                           | IOs (%)                                         | 22.53                |
#   | utilization.io                               | IOs                                             | 164                  |
#   | utilization.ram.blockram                     | RAM (Blocks)                                    | 2038                 |
#   | utilization.ram.distributedram               | RAM (Distributed)                               | 1068                 |
#   | utilization.ram.tile.pct                     | Block RAM Tile (%)                              | 69.00                |
#   | utilization.ram.tile                         | Block RAM Tile                                  | 1490.5               |
#   +----------------------------------------------+-------------------------------------------------+----------------------+
#   | timing.ths                                   | THS                                             | -15171.135           |
#   | timing.thsFallingEp                          | THS Failing Endpoints                           | 398034               |
#   | timing.thsTotalEp                            | THS Total Endpoints                             | 1110733              |
#   | timing.tns                                   | TNS                                             | -129.755             |
#   | timing.tnsFallingEp                          | TNS Failing Endpoints                           | 732                  |
#   | timing.tnsTotalEp                            | TNS Total Endpoints                             | 1110733              |
#   | timing.tpws                                  | TPWS                                            | 0.000                |
#   | timing.tpwsFailingEp                         | TPWS Failing Endpoints                          | 0                    |
#   | timing.tpwsTotalEp                           | TPWS Total Endpoints                            | 433087               |
#   | timing.whs.epclock                           | WHS Endpoint Clock                              | txoutclk_out[3]      |
#   | timing.whs.spclock                           | WHS Startpoint Clock                            | txoutclk_out[3]      |
#   | timing.whs                                   | WHS                                             | -0.944               |
#   | timing.wns.epclock                           | WNS Endpoint Clock                              | axi_aclk             |
#   | timing.wns.spclock                           | WNS Startpoint Clock                            | dmon                 |
#   | timing.wns                                   | WNS                                             | -1.250               |
#   | timing.wpws                                  | WPWS                                            | 0.000                |
#   +----------------------------------------------+-------------------------------------------------+----------------------+
#   | clkinteraction.asynchronous_groups           | Clock Interaction (Asynchronous Groups)         | 266                  |
#   | clkinteraction.false_path                    | Clock Interaction (False Path)                  | 2                    |
#   | clkinteraction.partial_false_path            | Clock Interaction (Partial False Path)          | 33                   |
#   | clkinteraction.timed                         | Clock Interaction (Timed)                       | 111                  |
#   | clkinteraction.timed_unsafe                  | Clock Interaction (Timed (unsafe))              | 1                    |
#   +----------------------------------------------+-------------------------------------------------+----------------------+
#   | checktiming.constant_clock                   | check_timing (constant_clock)                   | 0                    |
#   | checktiming.generated_clocks                 | check_timing (generated_clocks)                 | 0                    |
#   | checktiming.latch_loops                      | check_timing (latch_loops)                      | 0                    |
#   | checktiming.loops                            | check_timing (loops)                            | 0                    |
#   | checktiming.multiple_clock                   | check_timing (multiple_clock)                   | 0                    |
#   | checktiming.no_clock                         | check_timing (no_clock)                         | 15                   |
#   | checktiming.no_input_delay                   | check_timing (no_input_delay)                   | 68                   |
#   | checktiming.no_output_delay                  | check_timing (no_output_delay)                  | 147                  |
#   | checktiming.partial_input_delay              | check_timing (partial_input_delay)              | 0                    |
#   | checktiming.partial_output_delay             | check_timing (partial_output_delay)             | 0                    |
#   | checktiming.pulse_width_clock                | check_timing (pulse_width_clock)                | 0                    |
#   | checktiming.unconstrained_internal_endpoints | check_timing (unconstrained_internal_endpoints) | 0                    |
#   +----------------------------------------------+-------------------------------------------------+----------------------+
#   | congestion.placer                            | Placer Congestion                               | u-u-u-u              |
#   | congestion.router                            | Router Congestion                               | u-u-u-u              |
#   +----------------------------------------------+-------------------------------------------------+----------------------+
#   | route.errors                                 | Nets with routing errors                        | 4880                 |
#   | route.fixed                                  | Nets with fixed routing                         | n/a                  |
#   | route.nets                                   | Routable nets                                   | 1038                 |
#   | route.routed                                 | Fully routed nets                               | n/a                  |
#   +----------------------------------------------+-------------------------------------------------+----------------------+
#   | constraints.create_clock                     | create_clock                                    | 13                   |
#   | constraints.create_generated_clock           | create_generated_clock                          | 67                   |
#   | constraints.group_path                       | group_path                                      | 0                    |
#   | constraints.set_bus_skew                     | set_bus_skew                                    | 0                    |
#   | constraints.set_case_analysis                | set_case_analysis                               | 15                   |
#   | constraints.set_clock_groups                 | set_clock_groups                                | 292                  |
#   | constraints.set_clock_latency                | set_clock_latency                               | 0                    |
#   | constraints.set_clock_sense                  | set_clock_sense                                 | 0                    |
#   | constraints.set_clock_uncertainty            | set_clock_uncertainty                           | 0                    |
#   | constraints.set_data_check                   | set_data_check                                  | 0                    |
#   | constraints.set_disable_timing               | set_disable_timing                              | 0                    |
#   | constraints.set_external_delay               | set_external_delay                              | 0                    |
#   | constraints.set_false_path                   | set_false_path                                  | 162                  |
#   | constraints.set_input_delay                  | set_input_delay                                 | 0                    |
#   | constraints.set_input_jitter                 | set_input_jitter                                | 0                    |
#   | constraints.set_max_delay                    | set_max_delay                                   | 0                    |
#   | constraints.set_min_delay                    | set_min_delay                                   | 0                    |
#   | constraints.set_multicycle_path              | set_multicycle_path                             | 66                   |
#   | constraints.set_output_delay                 | set_output_delay                                | 0                    |
#   | constraints.set_system_jitter                | set_system_jitter                               | 0                    |
#   +----------------------------------------------+-------------------------------------------------+----------------------+

namespace eval ::tb {
#   namespace export -force report_design_summary
}

namespace eval ::tb::utils {
  namespace export -force report_design_summary
}

namespace eval ::tb::utils::report_design_summary {
  namespace export -force report_design_summary
  variable version {2016.01.18}
  variable params
  variable output {}
  variable reports
  variable metrics
  array set params [list format {table} verbose 0 debug 0]
  array set reports [list]
  array set metrics [list]
}

proc ::tb::utils::report_design_summary::lshift {inputlist} {
  upvar $inputlist argv
  set arg  [lindex $argv 0]
  set argv [lrange $argv 1 end]
  return $arg
}

proc ::tb::utils::report_design_summary::report_design_summary {args} {
  variable reports
  variable metrics
  variable params
  variable output
  catch {unset metrics}
  catch {unset reports}
  set params(verbose) 0
  set params(debug) 0
  set params(format) {table}
  set sections {default}
  set filename {}
  set filemode {w}
  set returnstring 0
  set project {}
  set version {}
  set experiment {}
  set step {}
  set showdetails 0
  set error 0
  set help 0
#   if {[llength $args] == 0} {
#     set help 1
#   }
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-f(i(le?)?)?$} {
        set filename [lshift args]
      }
      {^-ap(p(e(nd?)?)?)?$} {
        set filemode {a}
      }
      {^-csv?$} {
        set params(format) {csv}
      }
      {^-a(ll?)?$} {
        set sections [concat $sections [list utilization \
                                             constraints \
                                             timing \
                                             clock_interaction \
                                             congestion \
                                             check_timing \
                                             route_status] ]
      }
      {^-c(h(e(c(k(_(t(i(m(i(ng?)?)?)?)?)?)?)?)?)?)?$} {
        lappend sections {check_timing}
      }
      {^-r(o(u(te?)?)?)?$} {
        lappend sections {route_status}
      }
      {^-cl(o(c(k(_(i(n(t(e(r(a(c(t(i(on?)?)?)?)?)?)?)?)?)?)?)?)?)?)?$} {
        lappend sections {clock_interaction}
      }
      {^-u(t(i(l(i(z(a(t(i(on?)?)?)?)?)?)?)?)?)?$} {
        lappend sections {utilization}
      }
      {^-cons(t(r(a(i(n(ts?)?)?)?)?)?)?$} {
        lappend sections {constraints}
      }
      {^-t(i(m(i(ng?)?)?)?)?$} {
        lappend sections {timing}
      }
      {^-cong(e(s(t(i(on?)?)?)?)?)?$} {
        lappend sections {congestion}
      }
      {^-pr(o(j(e(ct?)?)?)?)?$} {
           set project [lshift args]
      }
      {^-ve(r(s(i(on?)?)?)?)?$} {
           set version [lshift args]
      }
      {^-ex(p(e(r(i(m(e(nt?)?)?)?)?)?)?)?$} {
           set experiment [lshift args]
      }
      {^-st(ep?)?$} {
           set step [lshift args]
      }
      {^-de(t(a(i(ls?)?)?)?)?$} {
           set showdetails 1
      }
      {^-r(e(t(u(r(n(_(s(t(r(i(ng?)?)?)?)?)?)?)?)?)?)?)?$} {
        set returnstring 1
      }
      {^-v(e(r(b(o(se?)?)?)?)?)?$} {
        set params(verbose) 1
      }
      {^-d(e(b(ug?)?)?)?$} {
        set params(debug) 1
      }
      {^-h(e(lp?)?)?$} {
           set help 1
      }
      default {
            if {[string match "-*" $name]} {
              puts " -E- option '$name' is not a valid option."
              incr error
            } else {
              puts " -E- option '$name' is not a valid option."
              incr error
            }
      }
    }
  }

  if {$help} {
    puts [format {
  Usage: report_design_summary
            +--------------------+
              [-all]
              [-utilization]
              [-timing]
              [-congestion]
              [-constraints]
              [-check_timing]
              [-clock_interaction]
              [-route]
            +--------------------+
              [-project <string>]
              [-version <string>]
              [-experiment <string>]
              [-step <string>]
            +--------------------+
              [-details]
              [-file <filename>]
              [-append]
              [-csv]
              [-return_string]
              [-verbose|-v]
              [-help|-h]

  Description: Generate a design summary report

    Use -details with -file to append full reports
    Use -project/-version/-experiment/-step to save informative tags

  Example:
     tb::report_design_summary -file myreport.rpt -details -all
     tb::report_design_summary -timing -csv -return_string
} ]
    # HELP -->
    return -code ok
  }

  if {($filename == {}) && $showdetails} {
    puts " -E- -details must be used with -file"
    incr error
  }

  if {($filename != {}) && $returnstring} {
    puts " -E- cannot use -file & -return_string together"
    incr error
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  set startTime [clock seconds]
  set output [list]

  if {[catch {

    ########################################################################################
    ##
    ##
    ##
    ########################################################################################

    if {[lsearch $sections {default}] != -1} {

      addMetric {vivado.version}   {Vivado Release}
      addMetric {vivado.plateform} {Plateform}
      addMetric {vivado.os}        {OS}
      addMetric {vivado.osVersion} {OS Version}
      addMetric {vivado.top}       {Top Module Name}
      addMetric {vivado.dir}       {Project Directory}

      setMetric {vivado.version}   [regsub {^([0-9]+\.[0-9]+)\.0$} [version -short] {\1}]
      setMetric {vivado.plateform} $::tcl_platform(platform)
      setMetric {vivado.os}        $::tcl_platform(os)
      setMetric {vivado.osVersion} $::tcl_platform(osVersion)
      setMetric {vivado.top}       [get_property -quiet TOP [current_design -quiet]]
      setMetric {vivado.dir}       [get_property -quiet XLNX_PROJ_DIR [current_design -quiet]]

    }

    ########################################################################################
    ##
    ##
    ##
    ########################################################################################

    if {[lsearch $sections {default}] != -1} {
      addMetric {tag.project}      {Project}
      addMetric {tag.version}      {Version}
      addMetric {tag.experiment}   {Experiment}
      addMetric {tag.step}         {Step}

      setMetric {tag.project}      $project
      setMetric {tag.version}      $version
      setMetric {tag.experiment}   $experiment
      setMetric {tag.step}         $step
    }

    ########################################################################################
    ##
    ##
    ##
    ########################################################################################

    if {[lsearch $sections {default}] != -1} {

      addMetric {design.part}                 {Part}
      addMetric {design.nets}                 {Number of nets}
      addMetric {design.nets.slls}            {Number of SLL nets}
      addMetric {design.cells.primitive}      {Number of primitive cells}
      addMetric {design.cells.hier}           {Number of hierarchical cells}
      addMetric {design.cells.blackbox}       {Number of blackbox cells}
      addMetric {design.ports}                {Number of ports}
      addMetric {design.clocks}               {Number of clocks}
      addMetric {design.clocks.primary}       {Number of primary clocks}
      addMetric {design.clocks.usergenerated} {Number of user generated clocks}
      addMetric {design.clocks.autoderived}   {Number of auto-derived clocks}
      addMetric {design.clocks.virtual}       {Number of virtual clocks}
      addMetric {design.pblocks}              {Number of pblocks}
      addMetric {design.ips}                  {Number of IPs}
      addMetric {design.slrs}                 {Number of SLRs}

      setMetric {design.part}      [get_property -quiet PART [current_design]]
      setMetric {design.ports}     [llength [get_ports -quiet]]
      setMetric {design.pblocks}   [llength [get_pblocks -quiet]]
      setMetric {design.ips}       [llength [get_ips -quiet]]
      setMetric {design.slrs}      [llength [get_slrs -quiet]]

      setMetric {design.nets}      [llength [get_nets -quiet -hier -top_net_of_hierarchical_group -filter {TYPE == SIGNAL}]]
      if {[llength [get_slrs -quiet]] <= 1} {
        setMetric {design.nets.slls} {n/a}
      } else {
        setMetric {design.nets.slls} [llength [get_nets -quiet -hier -top_net_of_hierarchical_group -filter {CROSSING_SLRS != ""}]]
      }

      set cells [get_cells -quiet -hier]
      setMetric {design.cells.primitive}  [llength [filter -quiet $cells {IS_PRIMITIVE}]]
      setMetric {design.cells.hier}       [llength [filter -quiet $cells {!IS_PRIMITIVE}]]
      setMetric {design.cells.blackbox}   [llength [filter -quiet $cells {IS_BLACKBOX}]]

      set clocks [get_clocks -quiet]
      setMetric {design.clocks}               [llength $clocks]
      setMetric {design.clocks.primary}       [llength [filter -quiet $clocks {!IS_GENERATED}] ]
      setMetric {design.clocks.usergenerated} [llength [filter -quiet $clocks {!IS_VIRTUAL && IS_GENERATED && IS_USER_GENERATED}] ]
      setMetric {design.clocks.autoderived}   [llength [filter -quiet $clocks {!IS_VIRTUAL && IS_GENERATED && !IS_USER_GENERATED}] ]
      setMetric {design.clocks.virtual}       [llength [filter -quiet $clocks {IS_VIRTUAL}] ]

    }

    ########################################################################################
    ##
    ## Timing metrics
    ##
    ########################################################################################

    if {[lsearch $sections {timing}] != -1} {

      addMetric {timing.wns}           {WNS}
      addMetric {timing.tns}           {TNS}
      addMetric {timing.tnsFallingEp}  {TNS Failing Endpoints}
      addMetric {timing.tnsTotalEp}    {TNS Total Endpoints}
      addMetric {timing.whs}           {WHS}
      addMetric {timing.ths}           {THS}
      addMetric {timing.thsFallingEp}  {THS Failing Endpoints}
      addMetric {timing.thsTotalEp}    {THS Total Endpoints}
      addMetric {timing.wpws}          {WPWS}
      addMetric {timing.tpws}          {TPWS}
      addMetric {timing.tpwsFailingEp} {TPWS Failing Endpoints}
      addMetric {timing.tpwsTotalEp}   {TPWS Total Endpoints}
      addMetric {timing.wns.spclock}   {WNS Startpoint Clock}
      addMetric {timing.wns.epclock}   {WNS Endpoint Clock}
      addMetric {timing.whs.spclock}   {WHS Startpoint Clock}
      addMetric {timing.whs.epclock}   {WHS Endpoint Clock}

      set report [split [getReport {report_timing_summary} {-quiet -no_detailed_paths -no_check_timing -no_header}] \n]
      if {[set i [lsearch -regexp $report {Design Timing Summary}]] != -1} {
         foreach {wns tns tnsFallingEp tnsTotalEp whs ths thsFallingEp thsTotalEp wpws tpws tpwsFailingEp tpwsTotalEp} [regexp -inline -all -- {\S+} [lindex $report [expr $i + 6]]] { break }
         setMetric {timing.wns}           $wns
         setMetric {timing.tns}           $tns
         setMetric {timing.tnsFallingEp}  $tnsFallingEp
         setMetric {timing.tnsTotalEp}    $tnsTotalEp
         setMetric {timing.whs}           $whs
         setMetric {timing.ths}           $ths
         setMetric {timing.thsFallingEp}  $thsFallingEp
         setMetric {timing.thsTotalEp}    $thsTotalEp
         setMetric {timing.wpws}          $wpws
         setMetric {timing.tpws}          $tpws
         setMetric {timing.tpwsFailingEp} $tpwsFailingEp
         setMetric {timing.tpwsTotalEp}   $tpwsTotalEp
      }

      # Saving startpoint/endpoint clock(s) of WNS path
      set wnsPath [get_timing_paths -quiet -setup -max_paths 1]
      set spClk [get_property -quiet STARTPOINT_CLOCK $wnsPath]
      set epClk [get_property -quiet ENDPOINT_CLOCK $wnsPath]
      setMetric {timing.wns.spclock}   $spClk
      setMetric {timing.wns.epclock}   $epClk
      setReport {WNS} [report_timing -quiet -of $wnsPath -return_string]

      # Saving startpoint/endpoint clock(s) of WHS path
      set whsPath [get_timing_paths -quiet -hold -max_paths 1]
      set spClk [get_property -quiet STARTPOINT_CLOCK $whsPath]
      set epClk [get_property -quiet ENDPOINT_CLOCK $whsPath]
      setMetric {timing.whs.spclock}   $spClk
      setMetric {timing.whs.epclock}   $epClk
      setReport {WHS} [report_timing -quiet -of $whsPath -return_string]

    }

    ########################################################################################
    ##
    ## Check timing metrics
    ##
    ########################################################################################

    if {[lsearch $sections {check_timing}] != -1} {

      addMetric {checktiming.no_clock}             {check_timing (no_clock)}
      addMetric {checktiming.constant_clock}       {check_timing (constant_clock)}
      addMetric {checktiming.pulse_width_clock}    {check_timing (pulse_width_clock)}
      addMetric {checktiming.unconstrained_internal_endpoints}      \
                                                   {check_timing (unconstrained_internal_endpoints)}
      addMetric {checktiming.no_input_delay}       {check_timing (no_input_delay)}
      addMetric {checktiming.no_output_delay}      {check_timing (no_output_delay)}
      addMetric {checktiming.multiple_clock}       {check_timing (multiple_clock)}
      addMetric {checktiming.generated_clocks}     {check_timing (generated_clocks)}
      addMetric {checktiming.loops}                {check_timing (loops)}
      addMetric {checktiming.partial_input_delay}  {check_timing (partial_input_delay)}
      addMetric {checktiming.partial_output_delay} {check_timing (partial_output_delay)}
      addMetric {checktiming.latch_loops}          {check_timing (latch_loops)}

      set report {}
      catch {
        set file [format {check_timing.%s} [clock seconds]]
        check_timing -quiet -file $file
        set FH [open $file {r}]
        set report [read $FH]
        close $FH
        if {!$params(debug)} {
          # Keep the file in debug mode
          file delete $file
        } else {
          dputs " -I- writing check_timing file '$file'"
        }
      }
      setReport {check_timing} $report

      extractMetric {check_timing} {checktiming.no_clock}                     {\s+There are\s+([0-9\.]+)\s+register/latch pins with no clock}                 {n/a}
      extractMetric {check_timing} {checktiming.constant_clock}               {\s+There are\s+([0-9\.]+)\s+register/latch pins with constant_clock}           {n/a}
      extractMetric {check_timing} {checktiming.pulse_width_clock}            {\s+There are\s+([0-9\.]+)\s+register/latch pins which need pulse_width check}  {n/a}

      set res1 [extractMetric {check_timing} {checktiming.unconstrained_internal_endpoints}     {\s+There are\s+([0-9\.]+)\s+pins that are not constrained for maximum delay\.}  0 0]
      set res2 [extractMetric {check_timing} {checktiming.unconstrained_internal_endpoints}     {\s+There are\s+([0-9\.]+)\s+pins that are not constrained for maximum delay due to constant clock}  0 0]
      setMetric {checktiming.unconstrained_internal_endpoints} [expr $res1 + $res2]

      set res1 [extractMetric {check_timing} {checktiming.no_input_delay}     {\s+There.+\s+([0-9\.]+)\s+input port with no input delay specified}  0 0]
      set res2 [extractMetric {check_timing} {checktiming.no_input_delay}     {\s+There are\s+([0-9\.]+)\s+input ports with no input delay but user has a false path constraint}  0 0]
      setMetric {checktiming.no_input_delay} [expr $res1 + $res2]

      set res1 [extractMetric {check_timing} {checktiming.no_output_delay}    {\s+There are\s+([0-9\.]+)\s+ports with no output delay specified}  0 0]
      set res2 [extractMetric {check_timing} {checktiming.no_output_delay}    {\s+There are\s+([0-9\.]+)\s+ports with no output delay but user has a false path constraint}  0 0]
      set res3 [extractMetric {check_timing} {checktiming.no_output_delay}    {\s+There are\s+([0-9\.]+)\s+ports with no output delay but with a timing clock defined on it or propagating through it}  0 0]
      setMetric {checktiming.no_output_delay} [expr $res1 + $res2 + $res3]

      extractMetric {check_timing} {checktiming.multiple_clock}               {\s+There are\s+([0-9\.]+)\s+register/latch pins with multiple clocks}                    {n/a}
      extractMetric {check_timing} {checktiming.generated_clocks}             {\s+There are\s+([0-9\.]+)\s+generated clocks that are not connected to a clock source}   {n/a}
      extractMetric {check_timing} {checktiming.loops}                        {\s+There are\s+([0-9\.]+)\s+combinational loops in the design}                           {n/a}
      extractMetric {check_timing} {checktiming.partial_input_delay}          {\s+There are\s+([0-9\.]+)\s+input ports with partial input delay specified}              {n/a}
      extractMetric {check_timing} {checktiming.partial_output_delay}         {\s+There are\s+([0-9\.]+)\s+ports with partial output delay specified}                   {n/a}
      extractMetric {check_timing} {checktiming.latch_loops}                  {\s+There are\s+([0-9\.]+)\s+combinational latch loops in the design through latch input} {n/a}

    }

    ########################################################################################
    ##
    ## Clock interaction metrics
    ##
    ########################################################################################

    if {[lsearch $sections {clock_interaction}] != -1} {

      set report [getReport {report_clock_interaction} {-quiet -no_header}]

      set clock_interaction_table [::tb::utils::report_design_summary::parseClockInteractionReport $report]
      set colFromClock -1
      set colToClock -1
      set colCommonPrimaryClock -1
      set colInterClockConstraints -1
      set colTNSFailingEndpoints -1
      set colTNSTotalEndpoints -1
      set colWNSClockEdges -1
      set colWNS -1
      set colTNS -1
      set colWNSPathRequirement -1
      if {$clock_interaction_table != {}} {
        set header [lindex $clock_interaction_table 0]
        for {set i 0} {$i < [llength $header]} {incr i} {
          # Header from report_clock_interaction:
          #   {From Clock} {To Clock} {WNS Clock Edges} WNS(ns) TNS(ns) {TNS Failing Endpoints} {TNS Total Endpoints} {WNS Path Requirement(ns)} {Common Primary Clock} {Inter-Clock Constraints}
          switch -regexp -- [lindex $header $i] {
            "From Clock" {
              set colFromClock $i
            }
            "To Clock" {
              set colToClock $i
            }
            "Common Primary Clock" {
              set colCommonPrimaryClock $i
            }
            "Inter-Clock Constraints" {
              set colInterClockConstraints $i
            }
            "TNS Failing Endpoints" {
              set colTNSFailingEndpoints $i
            }
            "TNS Total Endpoints" {
              set colTNSTotalEndpoints $i
            }
            "WNS Clock Edges" {
              set colWNSClockEdges $i
            }
            "WNS\\\(ns\\\)" {
              set colWNS $i
            }
            "TNS\\\(ns\\\)" {
              set colTNS $i
            }
            "WNS Path Requirement" {
              set colWNSPathRequirement $i
            }
            default {
            }
          }
        }
      }

      set n 0
      catch {unset clockInteractionReport}
      foreach row [lrange $clock_interaction_table 1 end] {
        incr n
        set fromClock [lindex $row $colFromClock]
        set toClock [lindex $row $colToClock]
#         set failingEndpoints [lindex $row $colTNSFailingEndpoints]
#         set totalEndpoints [lindex $row $colTNSTotalEndpoints]
#         set commonPrimaryClock [lindex $row $colCommonPrimaryClock]
        set interClockConstraints [lindex $row $colInterClockConstraints]
#         set wnsClockEdges [lindex $row $colWNSClockEdges]
#         set wns [lindex $row $colWNS]
#         set tns [lindex $row $colTNS]
#         set wnsPathRequirement [lindex $row $colWNSPathRequirement]
#         # Save the clock pair
#         lappend clockPairs [list $fromClock $toClock]
        dputs " -D- Processing report_clock_interaction \[$n/[expr [llength $clock_interaction_table] -1]\]: $fromClock -> $toClock \t ($interClockConstraints)"
        if {![info exists clockInteractionReport($interClockConstraints)]} {
          set clockInteractionReport($interClockConstraints) 0
        }
        incr clockInteractionReport($interClockConstraints)
      }

      foreach name [array names clockInteractionReport] {
        regsub -all { } [string tolower $name] {_} string
        regsub -all {\(} $string {} string
        regsub -all {\)} $string {} string
        addMetric clkinteraction.$string    [format {Clock Interaction (%s)} $name]
        setMetric clkinteraction.$string    $clockInteractionReport($name)
      }

    }

    ########################################################################################
    ##
    ## Congestion metrics
    ##
    ########################################################################################

    if {[lsearch $sections {congestion}] != -1} {

      addMetric {congestion.placer}    {Placer Congestion}
      addMetric {congestion.router}    {Router Congestion}

      set report [getReport {report_design_analysis} {-quiet -congestion -no_header}]
      set congestion [::tb::utils::report_design_summary::parseRDACongestion $report]
      setMetric {congestion.placer}  [lindex $congestion 0]
      setMetric {congestion.router}  [lindex $congestion 1]

    }

    ########################################################################################
    ##
    ## Constraints metrics
    ##
    ########################################################################################

    if {[lsearch $sections {constraints}] != -1} {

      # All tracked timing constraints
      set timCons [list create_clock \
                        create_generated_clock \
                        set_clock_latency \
                        set_clock_uncertainty \
                        set_clock_groups \
                        set_clock_sense \
                        set_input_jitter \
                        set_system_jitter \
                        set_external_delay \
                        set_input_delay \
                        set_output_delay \
                        set_data_check \
                        set_case_analysis \
                        set_false_path \
                        set_multicycle_path \
                        set_max_delay \
                        set_min_delay \
                        group_path \
                        set_disable_timing \
                        set_bus_skew ]
      catch {unset commands}
      catch {unset res}
      foreach el $timCons {
        set commands($el) 0
      }

      catch {
        set xdc [format {write_xdc.%s} [clock seconds]]
        write_xdc -quiet -exclude_physical -file $xdc
        set res [getVivadoCommands $xdc]
        if {!$params(debug)} {
          # Keep the file in debug mode
          file delete $xdc
        } else {
          dputs " -I- writing XDC file '$xdc'"
        }
      }

      array set commands $res

      foreach el $timCons {
        addMetric constraints.$el    $el
      }

      foreach el $timCons {
        setMetric constraints.$el    $commands($el)
      }

    }

    ########################################################################################
    ##
    ## Utilization metrics
    ##
    ########################################################################################

    if {[lsearch $sections {utilization}] != -1} {

      set report [getReport {report_utilization} {-quiet}]
#       if {![regexp {\|\s+CLB LUTs[^\|]*\s*\|\s+([0-9\.]+)\s+\|} $report -- val]} { set val {n/a} } ; setMetric design.clb.lut $val
#       if {![regexp {\|\s+CLB LUTs[^\|]*\s*\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+([0-9\.]+)\s+\|} $report -- val]} { set val {n/a} } ; setMetric design.clb.lut.pct $val

      # +-------------------------------------------------------------+----------+-------+-----------+-------+
      # |                          Site Type                          |   Used   | Fixed | Available | Util% |
      # +-------------------------------------------------------------+----------+-------+-----------+-------+
      # | CLB                                                         |       33 |     0 |     34260 |  0.10 |
      # |   CLBL                                                      |       21 |     0 |           |       |
      # |   CLBM                                                      |       12 |     0 |           |       |
      # | LUT as Logic                                                |       96 |     0 |    274080 |  0.04 |
      # |   using O5 output only                                      |        0 |       |           |       |
      # |   using O6 output only                                      |       68 |       |           |       |
      # |   using O5 and O6                                           |       28 |       |           |       |
      # | LUT as Memory                                               |        0 |     0 |    144000 |  0.00 |
      # |   LUT as Distributed RAM                                    |        0 |     0 |           |       |
      # |   LUT as Shift Register                                     |        0 |     0 |           |       |
      # | LUT Flip Flop Pairs                                         |      153 |     0 |    274080 |  0.06 |
      # |   fully used LUT-FF pairs                                   |       63 |       |           |       |
      # |   LUT-FF pairs with unused LUT                              |       57 |       |           |       |
      # |   LUT-FF pairs with unused Flip Flop                        |       33 |       |           |       |
      # | Unique Control Sets                                         |       13 |       |           |       |
      # | Maximum number of registers lost to control set restriction | 21(Lost) |       |           |       |
      # +-------------------------------------------------------------+----------+-------+-----------+-------+

      addMetric {utilization.clb.lut}        {CLB LUTs}
      addMetric {utilization.clb.lut.pct}    {CLB LUTs (%)}
      addMetric {utilization.clb.ff}         {CLB Registers}
      addMetric {utilization.clb.ff.pct}     {CLB Registers (%)}
      addMetric {utilization.ctrlsets.uniq}  {Unique Control Sets}
      addMetric {utilization.ctrlsets.lost}  {Registers Lost due to Control Sets}

      extractMetric {report_utilization} {utilization.clb.lut}       {\|\s+CLB LUTs[^\|]*\s*\|\s+([0-9\.]+)\s+\|}                                                      {n/a}
      extractMetric {report_utilization} {utilization.clb.lut.pct}   {\|\s+CLB LUTs[^\|]*\s*\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+([0-9\.]+)\s+\|}      {n/a}
      extractMetric {report_utilization} {utilization.clb.ff}        {\|\s+CLB Registers[^\|]*\s*\|\s+([0-9\.]+)\s+\|}                                                 {n/a}
      extractMetric {report_utilization} {utilization.clb.ff.pct}    {\|\s+CLB Registers[^\|]*\s*\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+([0-9\.]+)\s+\|} {n/a}
      extractMetric {report_utilization} {utilization.ctrlsets.uniq} {\|\s+Unique Control Sets[^\|]*\s*\|\s+([0-9\.]+)\s+\|}                                           {n/a}
      extractMetric {report_utilization} {utilization.ctrlsets.lost} {\|\s+.+registers lost to control set restriction[^\|]*\s*\|\s+([0-9\.]+).+\s+\|}                 {n/a}

      # +-------------------+------+-------+-----------+-------+
      # |     Site Type     | Used | Fixed | Available | Util% |
      # +-------------------+------+-------+-----------+-------+
      # | Block RAM Tile    |    8 |     0 |       912 |  0.88 |
      # |   RAMB36/FIFO*    |    8 |     0 |       912 |  0.88 |
      # |     FIFO36E2 only |    8 |       |           |       |
      # |   RAMB18          |    0 |     0 |      1824 |  0.00 |
      # +-------------------+------+-------+-----------+-------+

      addMetric {utilization.ram.tile}     {Block RAM Tile}
      addMetric {utilization.ram.tile.pct} {Block RAM Tile (%)}

      extractMetric {report_utilization} {utilization.ram.tile}     {\|\s+Block RAM Tile[^\|]*\s*\|\s+([0-9\.]+)\s+\|}                                                 {n/a}
      extractMetric {report_utilization} {utilization.ram.tile.pct} {\|\s+Block RAM Tile[^\|]*\s*\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+([0-9\.]+)\s+\|} {n/a}

      # +-----------+------+-------+-----------+-------+
      # | Site Type | Used | Fixed | Available | Util% |
      # +-----------+------+-------+-----------+-------+
      # | DSPs      |    0 |     0 |      2520 |  0.00 |
      # +-----------+------+-------+-----------+-------+

      addMetric {utilization.dsp}     {DSPs}
      addMetric {utilization.dsp.pct} {DSPs (%)}

      extractMetric {report_utilization} {utilization.dsp}     {\|\s+DSPs[^\|]*\s*\|\s+([0-9\.]+)\s+\|}                                                 {n/a}
      extractMetric {report_utilization} {utilization.dsp.pct} {\|\s+DSPs[^\|]*\s*\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+([0-9\.]+)\s+\|} {n/a}

      # +------------------+------+-------+-----------+-------+
      # |     Site Type    | Used | Fixed | Available | Util% |
      # +------------------+------+-------+-----------+-------+
      # | Bonded IOB       |   11 |     0 |       328 |  3.35 |
      # | HPIOB_M          |    6 |     0 |        96 |  6.25 |
      # |   INPUT          |    2 |       |           |       |
      # |   OUTPUT         |    4 |       |           |       |
      # |   BIDIR          |    0 |       |           |       |
      # | HPIOB_S          |    5 |     0 |        96 |  5.21 |
      # |   INPUT          |    0 |       |           |       |
      # |   OUTPUT         |    5 |       |           |       |
      # |   BIDIR          |    0 |       |           |       |
      # | HDIOB_M          |    0 |     0 |        60 |  0.00 |
      # | HDIOB_S          |    0 |     0 |        60 |  0.00 |
      # | HPIOB_SNGL       |    0 |     0 |        16 |  0.00 |
      # | HPIOBDIFFINBUF   |    0 |     0 |        96 |  0.00 |
      # | HPIOBDIFFOUTBUF  |    0 |     0 |        96 |  0.00 |
      # | HDIOBDIFFINBUF   |    0 |     0 |        60 |  0.00 |
      # | BITSLICE_CONTROL |    0 |     0 |        32 |  0.00 |
      # | BITSLICE_RX_TX   |    0 |     0 |       208 |  0.00 |
      # | BITSLICE_TX      |    0 |     0 |        32 |  0.00 |
      # | RIU_OR           |    0 |     0 |        16 |  0.00 |
      # +------------------+------+-------+-----------+-------+

      addMetric {utilization.io}     {IOs}
      addMetric {utilization.io.pct} {IOs (%)}

      extractMetric {report_utilization} {utilization.io}     {\|\s+Bonded IOB[^\|]*\s*\|\s+([0-9\.]+)\s+\|}                                                 {n/a}
      extractMetric {report_utilization} {utilization.io.pct} {\|\s+Bonded IOB[^\|]*\s*\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+([0-9\.]+)\s+\|} {n/a}

    }

    ########################################################################################
    ##
    ## Utilization metrics
    ##
    ########################################################################################

    if {[lsearch $sections {utilization}] != -1} {

      set report [getReport {report_ram_utilization} {-quiet}]

      # +----------------+------------+
      # | Memory Type    | Total Used |
      # +----------------+------------+
      # | BlockRAM       |       1102 |
      # +----------------+------------+
      # |       RAMB18E2 |         12 |
      # +----------------+------------+
      # |       RAMB36E2 |       1090 |
      # +----------------+------------+
      # | DistributedRAM |       3071 |
      # +----------------+------------+
      # |       RAM64X1D |         28 |
      # +----------------+------------+
      # |       RAM32X1S |          6 |
      # +----------------+------------+
      # |        RAM64M8 |        369 |
      # +----------------+------------+
      # |       RAM32M16 |       2668 |
      # +----------------+------------+

      addMetric {utilization.ram.blockram}       {RAM (Blocks)}
      addMetric {utilization.ram.distributedram} {RAM (Distributed)}

      extractMetric {report_ram_utilization} {utilization.ram.blockram}        {\|\s+BlockRAM[^\|]*\s*\|\s+([0-9\.]+)\s+\|}        {n/a}
      extractMetric {report_ram_utilization} {utilization.ram.distributedram}  {\|\s+DistributedRAM[^\|]*\s*\|\s+([0-9\.]+)\s+\|}  {n/a}

    }

    ########################################################################################
    ##
    ##
    ##
    ########################################################################################

    if {[lsearch $sections {route_status}] != -1} {

      set report [getReport {report_route_status} {-quiet}]

      #                                               :      # nets :
      #   ------------------------------------------- : ----------- :
      #   # of logical nets.......................... :     1648481 :
      #       # of nets not needing routing.......... :      736037 :
      #           # of internally routed nets........ :      524080 :
      #           # of nets with no loads............ :      211957 :
      #       # of routable nets..................... :      912444 :
      #           # of fully routed nets............. :      912444 :
      #       # of nets with routing errors.......... :           0 :
      #   ------------------------------------------- : ----------- :

      #                                               :      # nets :
      #   ------------------------------------------- : ----------- :
      #   # of logical nets.......................... :     1318920 :
      #       # of nets with no placed pins.......... :     1251890 :
      #       # of nets not needing routing.......... :       61112 :
      #           # of internally routed nets........ :         349 :
      #           # of nets with no loads............ :       60763 :
      #       # of routable nets..................... :        1038 :
      #           # of unrouted nets................. :        1038 :
      #       # of nets with routing errors.......... :        4880 :
      #           # of nets with some unplaced pins.. :        4880 :
      #           # of nets with some unrouted pins.. :        2164 :
      #   ------------------------------------------- : ----------- :

      addMetric {route.errors}    {Nets with routing errors}
      addMetric {route.routed}    {Fully routed nets}
      addMetric {route.fixed}     {Nets with fixed routing}
      addMetric {route.nets}      {Routable nets}

      extractMetric {report_route_status} {route.errors} {nets with routing errors[^\:]+\:\s*([0-9]+)\s*\:}        {n/a}
      extractMetric {report_route_status} {route.routed} {fully routed nets[^\:]+\:\s*([0-9]+)\s*\:}               {n/a}
      extractMetric {report_route_status} {route.fixed}  {nets with fixed routing[^\:]+\:\s*([0-9]+)\s*\:}         {n/a}
      extractMetric {report_route_status} {route.nets}   {routable nets[^\:]+\:\s*([0-9]+)\s*\:}                   {n/a}

   }

    ########################################################################################
    ##
    ##
    ##
    ########################################################################################

#     parray ::tb::utils::report_design_summary::metrics
#     parray ::tb::utils::report_design_summary::reports

    ########################################################################################
    ##
    ##
    ##
    ########################################################################################

    # Gather the list of metrics categories
    # E.g: metric = 'design.ram.blockram' -> category = 'design'
    set categories [list]
    foreach key [lsort [array names metrics *:def]] {
      lappend categories [lindex [split $key .] 0]
    }
    set categories [lsort -unique $categories]

#     set tbl [::tb::prettyTable {Design Summary}]
    set tbl [::Table::Create {Design Summary}]
    $tbl indent 1
#     $tbl configure -indent 2
    $tbl header [list {Id} {Description} {Value}]
    foreach category [presort_list [list tag \
                                         vivado \
                                         design \
                                         utilization \
                                         timing \
                                         clkinteraction \
                                         checktiming \
                                         congestion \
                                         route \
                                         constraints \
                                   ] $categories] {
      switch $category {
        xxx {
          continue
        }
        default {
        }
      }
      $tbl separator
      foreach key [lsort [array names metrics $category.*:def]] {
        regsub {:def} $key {} key
        # E.g: key = 'design.ram.blockram' -> metric = 'ram.blockram'
        regsub "$category." $key {} metric
        switch $key {
          vivado.dir  {
            # Metric not added
          }
          default {
            $tbl addrow [list $key $metrics(${key}:description) $metrics(${key}:val)]
          }
        }
      }
    }
#     set output [concat $output [split [$tbl export -format $params(format)] \n] ]
    switch $params(format) {
      table {
        set output [concat $output [split [$tbl print] \n] ]
      }
      csv {
        set output [concat $output [split [$tbl csv] \n] ]
        if {$filename != {}} {
          # Append a comment out version of the table
          foreach line [split [$tbl print] \n] {
            lappend output [format {#  %s} $line]
          }
        }
      }
    }
    catch {$tbl destroy}

    ########################################################################################
    ##
    ##
    ##
    ########################################################################################

  } errorstring]} {
    puts " -E- $errorstring"
  }

  if {$params(debug)} {
  }

  set stopTime [clock seconds]
  puts " -I- report_design_summary completed in [expr $stopTime - $startTime] seconds"

  if {$filename != {}} {
    set FH [open $filename $filemode]
    puts $FH "# ---------------------------------------------------------------------------------"
    puts $FH [format {# Created on %s with report_design_summary (%s)} [clock format [clock seconds]] $::tb::utils::report_design_summary::version ]
    puts $FH "# ---------------------------------------------------------------------------------\n"
    puts $FH [join $output \n]
    if {$showdetails} {
      # Dump full reports inside file
      foreach name [list report_utilization \
                         report_ram_utilization \
                         report_timing_summary \
                         WNS \
                         WHS \
                         report_clock_interaction \
                         check_timing \
                         report_design_analysis \
                         report_route_status \
                   ] {
        if {[info exists reports($name)]} {
          set report $reports($name)
          puts $FH "\n########################################################################################"
          puts $FH "## Vivado report: $name"
          puts $FH "########################################################################################"
          puts $FH "#"
          foreach line [split $report \n] {
            puts $FH [format {#  %s} $line]
          }
        }
      }
    }
    close $FH
    puts " -I- Generated file [file normalize $filename]"
    return -code ok
  }

  if {$returnstring} {
    return [join $output \n]
  } else {
    puts [join $output \n]
  }
  return -code ok
}

########################################################################################
##
##
##
########################################################################################
proc ::tb::utils::report_design_summary::setReport {name report} {
  variable reports
  if {[info exists reports($name)]} {
    puts "Found report $name. Overridding report."
  }
  set reports($name) $report
  return $report
}

proc ::tb::utils::report_design_summary::getReport {name {options {}}} {
  variable reports
  if {[info exists reports($name)]} {
    puts "Found report $name"
    return $reports($name)
  }
  set res {}
  if {[catch { set res [eval [concat $name $options -return_string]] } errorstring]} {
    puts " -E- $errorstring"
  }
#   puts "report $name: $res"
  set reports($name) $res
  return $res
}

proc ::tb::utils::report_design_summary::addMetric {name {description {}}} {
  variable metrics
  if {[info exists metrics(${name}:def)]} {
    puts " -E- metric '$name' already exist"
    return -code ok
  }
  if {$description == {}} { set description $name }
  set metrics(${name}:def) 1
  set metrics(${name}:description) $description
  set metrics(${name}:val) {}
  return -code ok
}

proc ::tb::utils::report_design_summary::setMetric {name value} {
  variable metrics
  if {![info exists metrics(${name}:def)]} {
    puts " -E- metric '$name' does not exist"
    return -code ok
  }
  dputs " -I- setting: $name = $value"
  set metrics(${name}:def) 2
  set metrics(${name}:val) $value
  return -code ok
}

proc ::tb::utils::report_design_summary::extractMetric {report name exp {notfound {n/a}} {save 1}} {
  variable metrics
  variable reports
  if {![info exists metrics(${name}:def)]} {
    puts " -E- metric '$name' does not exist"
    return -code ok
  }
  if {[info exists reports($report)]} {
    dputs " -I- found report '$report'"
    set report $reports($report)
  } else {
    dputs " -I- inline report"
  }
  if {![regexp -nocase -- $exp $report -- value]} {
    set value $notfound
    dputs " -I- failed to extract metric '$name' from report"
  }
  if {!$save} {
    return $value
  }
  setMetric $name $value
#   dputs " -I- setting: $name = $value"
  set metrics(${name}:def) 2
  set metrics(${name}:val) $value
  return -code ok
}

proc ::tb::utils::report_design_summary::presort_list {l1 l2} {
  set l [list]
  foreach el $l1 {
    if {[lsearch $l2 $el] != -1} {
      lappend l $el
    }
  }
  foreach el $l2 {
    if {[lsearch $l $el] == -1} {
      lappend l $el
    }
  }
  return $l
}

proc ::tb::utils::report_design_summary::dputs {args} {
  variable params
  if {$params(debug)} {
    eval [concat puts $args]
  }
  return -code ok
}

namespace eval ::tb::utils {
  namespace import -force ::tb::utils::report_design_summary::report_design_summary
}

namespace eval ::tb {
#   namespace import -force ::tb::utils::report_design_summary
}

###########################################################################
##
## Simple package to handle printing of tables
##
## %> set tbl [Table::Create {this is my title}]
## %> $tbl header [list "name" "#Pins" "case_value" "user_case_value"]
## %> $tbl addrow [list A/B/C/D/E/F 12 - -]
## %> $tbl addrow [list A/B/C/D/E/F 24 1 -]
## %> $tbl separator
## %> $tbl addrow [list A/B/C/D/E/F 48 0 1]
## %> $tbl indent 0
## %> $tbl print
## +-------------+-------+------------+-----------------+
## | name        | #Pins | case_value | user_case_value |
## +-------------+-------+------------+-----------------+
## | A/B/C/D/E/F | 12    | -          | -               |
## | A/B/C/D/E/F | 24    | 1          | -               |
## +-------------+-------+------------+-----------------+
## | A/B/C/D/E/F | 48    | 0          | 1               |
## +-------------+-------+------------+-----------------+
## %> $tbl indent 2
## %> $tbl print
##   +-------------+-------+------------+-----------------+
##   | name        | #Pins | case_value | user_case_value |
##   +-------------+-------+------------+-----------------+
##   | A/B/C/D/E/F | 12    | -          | -               |
##   | A/B/C/D/E/F | 24    | 1          | -               |
##   +-------------+-------+------------+-----------------+
##   | A/B/C/D/E/F | 48    | 0          | 1               |
##   +-------------+-------+------------+-----------------+
## %> $tbl sort {-index 1 -increasing} {-index 2 -dictionary}
## %> $tbl print
## %> $tbl destroy
##
###########################################################################

# namespace eval Table { set n 0 }

# Trick to silence the linter
eval [list namespace eval ::Table {
  set n 0
} ]

proc ::Table::Create { {title {}} } { #-- constructor
  # Summary :
  # Argument Usage:
  # Return Value:

  variable n
  set instance [namespace current]::[incr n]
  namespace eval $instance { variable tbl [list]; variable header [list]; variable indent 0; variable title {}; variable numrows 0 }
  interp alias {} $instance {} ::Table::do $instance
  # Set the title
  $instance title $title
  set instance
}

proc ::Table::do {self method args} { #-- Dispatcher with methods
  # Summary :
  # Argument Usage:
  # Return Value:

  upvar #0 ${self}::tbl tbl
  upvar #0 ${self}::header header
  upvar #0 ${self}::numrows numrows
  switch -- $method {
      header {
        set header [lindex $args 0]
        return 0
      }
      addrow {
        eval lappend tbl $args
        incr numrows
        return 0
      }
      separator {
        eval lappend tbl {%%SEPARATOR%%}
        return 0
      }
      title {
        set ${self}::title [lindex $args 0]
        return 0
      }
      indent {
        set ${self}::indent $args
        return 0
      }
      print {
        eval ::Table::print $self
      }
      csv {
        eval ::Table::printcsv $self
      }
      length {
        return $numrows
      }
      sort {
        # Each argument is a list of: <lsort arguments>
        set command {}
        while {[llength $args]} {
          if {$command == {}} {
            set command "lsort [[namespace parent]::lshift args] \$tbl"
          } else {
            set command "lsort [[namespace parent]::lshift args] \[$command\]"
          }
        }
        if {[catch { set tbl [eval $command] } errorstring]} {
          puts " -E- $errorstring"
        } else {
        }
      }
      reset {
        set ${self}::tbl [list]
        set ${self}::header [list]
        set ${self}::indent 0
        set ${self}::title {}
        return 0
      }
      destroy {
        set ${self}::tbl [list]
        set ${self}::header [list]
        set ${self}::indent 0
        set ${self}::title {}
        namespace delete $self
        return 0
      }
      default {error "unknown method $method"}
  }
}

proc ::Table::print {self} {
   upvar #0 ${self}::tbl table
   upvar #0 ${self}::header header
   upvar #0 ${self}::indent indent
   upvar #0 ${self}::title title
   set maxs {}
   foreach item $header {
       lappend maxs [string length $item]
   }
   set numCols [llength $header]
   foreach row $table {
       if {$row eq {%%SEPARATOR%%}} { continue }
       for {set j 0} {$j<$numCols} {incr j} {
            set item [lindex $row $j]
            set max [lindex $maxs $j]
            if {[string length $item]>$max} {
               lset maxs $j [string length $item]
           }
       }
   }
  set head " [string repeat " " [expr $indent * 4]]+"
  foreach max $maxs {append head -[string repeat - $max]-+}

  # Generate the title
  if {$title ne {}} {
    # The upper separator should something like +----...----+
    append res " [string repeat " " [expr $indent * 4]]+[string repeat - [expr [string length [string trim $head]] -2]]+\n"
    # Suports multi-lines title
    foreach line [split $title \n] {
      append res " [string repeat " " [expr $indent * 4]]| "
      append res [format "%-[expr [string length [string trim $head]] -4]s" $line]
      append res " |\n"
    }
  }

  # Generate the table header
  append res $head\n
  # Generate the table rows
  set first 1
  set numsep 0
  foreach row [concat [list $header] $table] {
      if {$row eq {%%SEPARATOR%%}} {
        incr numsep
        if {$numsep == 1} { append res $head\n }
        continue
      } else {
        set numsep 0
      }
      append res " [string repeat " " [expr $indent * 4]]|"
      foreach item $row max $maxs {append res [format " %-${max}s |" $item]}
      append res \n
      if {$first} {
        append res $head\n
        set first 0
        incr numsep
      }
  }
  append res $head
  set res
}

proc ::Table::printcsv {self args} {
  upvar #0 ${self}::tbl table
  upvar #0 ${self}::header header
  upvar #0 ${self}::title title

  array set defaults [list \
      -delimiter {,} \
    ]
  array set options [array get defaults]
  array set options $args
  set sepChar $options(-delimiter)

  set res {}
  # Support for multi-lines title
  set first 1
  foreach line [split $title \n] {
    if {$first} {
      set first 0
      append res "# title${sepChar}[::Table::list2csv [list $line] $sepChar]\n"
    } else {
      append res "#      ${sepChar}[::Table::list2csv [list $line] $sepChar]\n"
    }
  }
  append res "[::Table::list2csv $header $sepChar]\n"
  set count 0
  set numsep 0
  foreach row $table {
    incr count
    if {$row eq {%%SEPARATOR%%}} {
      incr numsep
      if {$numsep == 1} {
        append res "# [::Table::list2csv {++++++++++++++++++++++++++++++++++++++++++++++++++} $sepChar]\n"
      } else {
        set numsep 0
      }
      continue
    }
    append res "[::Table::list2csv $row $sepChar]\n"
  }
  return $res
}

proc ::Table::list2csv { list {sepChar ,} } {
  set out ""
  set sep {}
  foreach val $list {
    if {[string match "*\[\"$sepChar\]*" $val]} {
      append out $sep\"[string map [list \" \"\"] $val]\"
    } else {
      append out $sep\"$val\"
    }
    set sep $sepChar
  }
  return $out
}

# Code from Frederic Revenu
# Extract the placement + routing congestions from report_design_analysis
# Format: North-South-East-West
#         PlacerNorth-PlacerSouth-PlacerEast-PlacerWest RouterNorth-RouterSouth-RouterEast-RouterWest
proc ::tb::utils::report_design_summary::parseRDACongestion {report} {
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

# Return a list of Vivado commands used in a Tcl script.
# Format: <command> <number>
# For example:
#   get_nets 35 get_pins 242 set_false_path 162 set_multicycle_path 66 \
#   create_generated_clock 67 set_clock_groups 292 current_instance 10 \
#   set_case_analysis 15 get_cells 191 get_clocks 717 get_ports 26 create_clock 12

proc ::tb::utils::report_design_summary::getVivadoCommands {filename} {
  set slave [interp create]
  $slave eval [format {
    catch {unset commands}
    global commands

    proc unknown {args} {
      global commands
      set cmd [lindex $args 0]
      if {[regexp {^[0-9]$} $cmd]} {
        return -code ok
      }
      if {![info exists commands($cmd)]} {
        set commands($cmd) 0
      }
      incr commands($cmd)
      return -code ok
    }

    source %s
  } $filename ]

  set result [$slave eval array get commands]
  interp delete $slave
  return $result
}

#------------------------------------------------------------------------
# ::tb::utils::report_design_summary::extract_columns
#------------------------------------------------------------------------
# Extract position of columns based on the column separator string
#  str:   string to be used to extract columns
#  match: column separator string
#------------------------------------------------------------------------
proc ::tb::utils::report_design_summary::extract_columns { str match } {
  set col 0
  set columns [list]
  set previous -1
  while {[set col [string first $match $str [expr $previous +1]]] != -1} {
    if {[expr $col - $previous] > 1} {
      lappend columns $col
    }
    set previous $col
  }
  return $columns
}

#------------------------------------------------------------------------
# ::tb::utils::report_design_summary::extract_row
#------------------------------------------------------------------------
# Extract all the cells of a row (string) based on the position
# of the columns
#------------------------------------------------------------------------
proc ::tb::utils::report_design_summary::extract_row {str columns} {
  lappend columns [string length $str]
  set row [list]
  set pos 0
  foreach col $columns {
    set value [string trim [string range $str $pos $col]]
    lappend row $value
    set pos [incr col 2]
  }
  return $row
}

#------------------------------------------------------------------------
# ::tb::utils::report_design_summary::parseClockInteractionReport
#------------------------------------------------------------------------
# Extract the clock table from report_clock_interaction and return
# a Tcl list
#------------------------------------------------------------------------
proc ::tb::utils::report_design_summary::parseClockInteractionReport {report} {
  set columns [list]
  set table [list]
  set report [split $report \n]
  set SM {header}
  for {set index 0} {$index < [llength $report]} {incr index} {
    set line [lindex $report $index]
    switch $SM {
      header {
        if {[regexp {^\-+\s+\-+\s+\-+} $line]} {
          set columns [extract_columns [string trimright $line] { }]
          set header1 [extract_row [lindex $report [expr $index -2]] $columns]
          set header2 [extract_row [lindex $report [expr $index -1]] $columns]
          set row [list]
          foreach h1 $header1 h2 $header2 {
            lappend row [string trim [format {%s %s} [string trim [format {%s} $h1]] [string trim [format {%s} $h2]]] ]
          }
          lappend table $row
          set SM {table}
        }
      }
      table {
        # Check for empty line or for line that match '<empty>'
        if {(![regexp {^\s*$} $line]) && (![regexp -nocase {^\s*No clocks found.\s*$} $line])} {
          set row [extract_row $line $columns]
          lappend table $row
        }
      }
      end {
      }
    }
  }
  return $table
}

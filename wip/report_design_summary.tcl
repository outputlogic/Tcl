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
## Description:    Generate a design summary report
##
########################################################################################

########################################################################################
## 2015.08.26 - Initial release
########################################################################################

# Example of report:

# catch { tclapp::install designutils }

# if {[catch {package require prettyTable}]} {
#   lappend auto_path {/home/dpefour/git/scripts/toolbox}
#   package require prettyTable
# }

namespace eval ::tb {
  namespace export -force report_design_summary
}

namespace eval ::tb::utils {
  namespace export -force report_design_summary
}

namespace eval ::tb::utils::report_design_summary {
  namespace export -force report_design_summary
  variable version {2015.08.26}
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
  set returnstring 0
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
      {^-c(sv?)?$} {
        set params(format) {csv}
      }
      {^-t(i(m(i(ng?)?)?)?)?$} {
        lappend sections {timing}
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
              [-timing]
              [-file <filename>]
              [-csv]
              [-return_string]
              [-verbose|-v]
              [-help|-h]

  Description: Generate a design summary report

  Example:
     report_design_summary -file myreport.rpt
     report_design_summary -timing -csv -return_string
} ]
    # HELP -->
    return -code ok
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

      set report [split [getReport {report_timing_summary} {-no_detailed_paths -no_check_timing -no_header}] \n]
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

    }

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
      setMetric {vivado.top}       [get_property -quiet TOP [current_design -quiet]]
      setMetric {vivado.dir}       [get_property -quiet XLNX_PROJ_DIR [current_design -quiet]]

    }

    ########################################################################################
    ##
    ##
    ##
    ########################################################################################

    if {[lsearch $sections {default}] != -1} {

      addMetric {design.part}      {Part}
      addMetric {design.nets}      {Number of nets}
      addMetric {design.cells}     {Number of cells}
      addMetric {design.ports}     {Number of ports}
      addMetric {design.clocks}    {Number of clocks}
      addMetric {design.allclocks} {Number of clocks and generated clocks}
      addMetric {design.pblocks}   {Number of pblocks}
      addMetric {design.ips}       {Number of IPs}

      setMetric {design.part}      [get_property -quiet PART [current_design]]
      setMetric {design.nets}      [llength [get_nets -quiet -hier -top_net_of_hierarchical_group -filter {TYPE == SIGNAL}]]
      setMetric {design.cells}     [llength [get_cells -quiet -hier]]
      setMetric {design.ports}     [llength [get_ports -quiet]]
      setMetric {design.clocks}    [llength [get_clocks -quiet]]
      setMetric {design.allclocks} [llength [get_clocks -quiet -include_generated_clocks]]
      setMetric {design.pblocks}   [llength [get_pblocks -quiet]]
      setMetric {design.ips}       [llength [get_ips -quiet]]

    }

    ########################################################################################
    ##
    ##
    ##
    ########################################################################################

    if {[lsearch $sections {default}] != -1} {

      set report [getReport {report_utilization} {}]
#       if {![regexp {\|\s+CLB LUTs[^\|]*\s*\|\s+([0-9\.]+)\s+\|} $report -- val]} { set val {N/A} } ; setMetric design.clb.lut $val
#       if {![regexp {\|\s+CLB LUTs[^\|]*\s*\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+([0-9\.]+)\s+\|} $report -- val]} { set val {N/A} } ; setMetric design.clb.lut.pct $val

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

      addMetric {design.clb.lut}        {CLB LUTs}
      addMetric {design.clb.lut.pct}    {CLB LUTs (%)}
      addMetric {design.clb.ff}         {CLB Registers}
      addMetric {design.clb.ff.pct}     {CLB Registers (%)}
      addMetric {design.ctrlsets.uniq}  {Unique Control Sets}
      addMetric {design.ctrlsets.lost}  {Registers Lost due to Control Sets}

      extractMetric {report_utilization} {design.clb.lut}       {\|\s+CLB LUTs[^\|]*\s*\|\s+([0-9\.]+)\s+\|}                                                      {N/A}
      extractMetric {report_utilization} {design.clb.lut.pct}   {\|\s+CLB LUTs[^\|]*\s*\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+([0-9\.]+)\s+\|}      {N/A}
      extractMetric {report_utilization} {design.clb.ff}        {\|\s+CLB Registers[^\|]*\s*\|\s+([0-9\.]+)\s+\|}                                                 {N/A}
      extractMetric {report_utilization} {design.clb.ff.pct}    {\|\s+CLB Registers[^\|]*\s*\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+([0-9\.]+)\s+\|} {N/A}
      extractMetric {report_utilization} {design.ctrlsets.uniq} {\|\s+Unique Control Sets[^\|]*\s*\|\s+([0-9\.]+)\s+\|}                                           {N/A}
      extractMetric {report_utilization} {design.ctrlsets.lost} {\|\s+.+registers lost to control set restriction[^\|]*\s*\|\s+([0-9\.]+).+\s+\|}                 {N/A}

      # +-------------------+------+-------+-----------+-------+
      # |     Site Type     | Used | Fixed | Available | Util% |
      # +-------------------+------+-------+-----------+-------+
      # | Block RAM Tile    |    8 |     0 |       912 |  0.88 |
      # |   RAMB36/FIFO*    |    8 |     0 |       912 |  0.88 |
      # |     FIFO36E2 only |    8 |       |           |       |
      # |   RAMB18          |    0 |     0 |      1824 |  0.00 |
      # +-------------------+------+-------+-----------+-------+

      addMetric {design.ram.tile}     {Block RAM Tile}
      addMetric {design.ram.tile.pct} {Block RAM Tile (%)}

      extractMetric {report_utilization} {design.ram.tile}     {\|\s+Block RAM Tile[^\|]*\s*\|\s+([0-9\.]+)\s+\|}                                                 {N/A}
      extractMetric {report_utilization} {design.ram.tile.pct} {\|\s+Block RAM Tile[^\|]*\s*\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+([0-9\.]+)\s+\|} {N/A}

      # +-----------+------+-------+-----------+-------+
      # | Site Type | Used | Fixed | Available | Util% |
      # +-----------+------+-------+-----------+-------+
      # | DSPs      |    0 |     0 |      2520 |  0.00 |
      # +-----------+------+-------+-----------+-------+

      addMetric {design.dsp}     {DSPs}
      addMetric {design.dsp.pct} {DSPs (%)}

      extractMetric {report_utilization} {design.dsp}     {\|\s+DSPs[^\|]*\s*\|\s+([0-9\.]+)\s+\|}                                                 {N/A}
      extractMetric {report_utilization} {design.dsp.pct} {\|\s+DSPs[^\|]*\s*\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+([0-9\.]+)\s+\|} {N/A}

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

      addMetric {design.io}     {IOs}
      addMetric {design.io.pct} {IOs (%)}

      extractMetric {report_utilization} {design.io}     {\|\s+Bonded IOB[^\|]*\s*\|\s+([0-9\.]+)\s+\|}                                                 {N/A}
      extractMetric {report_utilization} {design.io.pct} {\|\s+Bonded IOB[^\|]*\s*\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+([0-9\.]+)\s+\|} {N/A}

    }

    ########################################################################################
    ##
    ##
    ##
    ########################################################################################

    if {[lsearch $sections {default}] != -1} {

      set report [getReport {report_ram_utilization} {}]

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

      addMetric {design.ram.blockram}       {RAM (Blocks)}
      addMetric {design.ram.distributedram} {RAM (Distributed)}

      extractMetric {report_ram_utilization} {design.ram.blockram}        {\|\s+BlockRAM[^\|]*\s*\|\s+([0-9\.]+)\s+\|}        {N/A}
      extractMetric {report_ram_utilization} {design.ram.distributedram}  {\|\s+DistributedRAM[^\|]*\s*\|\s+([0-9\.]+)\s+\|}  {N/A}

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
    $tbl header [list {Id} {Name} {Value}]
    foreach category [presort_list [list vivado timing design] $categories] {
      switch $category {
        xxx {
          continue
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
  puts "  report_design_summary done in [expr $stopTime - $startTime] seconds"

  if {$filename != {}} {
    set FH [open $filename {w}]
    puts $FH "# ---------------------------------------------------------------------------------"
    puts $FH [format {# Created on %s with report_design_summary (%s)} [clock format [clock seconds]] $::tb::utils::report_design_summary::version ]
    puts $FH "# ---------------------------------------------------------------------------------\n"
    puts $FH [join $output \n]
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

proc ::tb::utils::report_design_summary::extractMetric {report name exp {notfound {N/A}}} {
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

proc ::tb::utils::report_design_summary::dputs_ {msg} {
  variable params
  if {$params(debug)} {
    puts $msg
  }
  return -code ok
}

# ##-----------------------------------------------------------------------
# ## splitLine
# ##-----------------------------------------------------------------------
# ## Convert a CSV string to a Tcl list based on a field separator
# ##-----------------------------------------------------------------------
# proc ::tb::utils::report_design_summary::splitLine { str {sepChar ,} } {
#   regsub -all {(\A\"|\"\Z)} $str \0 str
#   set str [string map [list $sepChar\"\"$sepChar $sepChar$sepChar] $str]
#   set str [string map [list $sepChar\"\"\" $sepChar\0\" \
#                             \"\"\"$sepChar \"\0$sepChar \
#                             $sepChar\"\"$sepChar $sepChar$sepChar \
#                            \"\" \" \
#                            \" \0 \
#                            ] $str]
#   set end 0
#   while {[regexp -indices -start $end {(\0)[^\0]*(\0)} $str \
#           -> start end]} {
#       set start [lindex $start 0]
#       set end   [lindex $end 0]
#       set range [string range $str $start $end]
#       set first [string first $sepChar $range]
#       if {$first >= 0} {
#           set str [string replace $str $start $end \
#               [string map [list $sepChar \1] $range]]
#       }
#       incr end
#   }
#   set str [string map [list $sepChar \0 \1 $sepChar \0 {} ] $str]
#   return [split $str \0]
# }

namespace eval ::tb::utils {
  namespace import -force ::tb::utils::report_design_summary::report_design_summary
}

namespace eval ::tb {
  namespace import -force ::tb::utils::report_design_summary
}

# ###########################################################################
# ##
# ## Simple package to handle printing of tables
# ##
# ## %> set tbl [Table::Create]
# ## %> $tbl header [list "name" "#Pins" "case_value" "user_case_value"]
# ## %> $tbl addrow [list A/B/C/D/E/F 12 - -]
# ## %> $tbl addrow [list A/B/C/D/E/F 24 1 -]
# ## %> $tbl separator
# ## %> $tbl addrow [list A/B/C/D/E/F 48 0 1]
# ## %> $tbl indent 0
# ## %> $tbl print
# ## +-------------+-------+------------+-----------------+
# ## | name        | #Pins | case_value | user_case_value |
# ## +-------------+-------+------------+-----------------+
# ## | A/B/C/D/E/F | 12    | -          | -               |
# ## | A/B/C/D/E/F | 24    | 1          | -               |
# ## +-------------+-------+------------+-----------------+
# ## | A/B/C/D/E/F | 48    | 0          | 1               |
# ## +-------------+-------+------------+-----------------+
# ## %> $tbl indent 2
# ## %> $tbl print
# ##   +-------------+-------+------------+-----------------+
# ##   | name        | #Pins | case_value | user_case_value |
# ##   +-------------+-------+------------+-----------------+
# ##   | A/B/C/D/E/F | 12    | -          | -               |
# ##   | A/B/C/D/E/F | 24    | 1          | -               |
# ##   +-------------+-------+------------+-----------------+
# ##   | A/B/C/D/E/F | 48    | 0          | 1               |
# ##   +-------------+-------+------------+-----------------+
# ##
# ###########################################################################
# 
# namespace eval Table { set n 0 }
# 
# proc Table::Create {} { #-- constructor
#   variable n
#   set instance [namespace current]::[incr n]
#   namespace eval $instance { variable tbl [list {}]; variable indent 0 }
#   interp alias {} $instance {} ::Table::do $instance
#   set instance
# }
# 
# proc Table::do {self method args} { #-- Dispatcher with methods
#   upvar #0 ${self}::tbl tbl
#   switch -- $method {
#       header {
#         eval lset tbl 0 $args
#         return 0
#       }
#       addrow {
#         eval lappend tbl $args
#         return 0
#       }
#       separator {
#         eval lappend tbl {%%SEPARATOR%%}
#         return 0
#       }
#       indent {
#         set ${self}::indent $args
#         return 0
#       }
#       print  {
#         eval Table::print $self
#       }
#       reset  {
#         set ${self}::tbl [list {}]
#         set ${self}::indent 0
#         return 0
#       }
#       default {error "unknown method $method"}
#   }
# }
# 
# proc Table::print {self} {
#    upvar #0 ${self}::tbl table
#    upvar #0 ${self}::indent indent
#    set maxs {}
#    foreach item [lindex $table 0] {
#        lappend maxs [string length $item]
#    }
#    set numCols [llength [lindex $table 0]]
#    foreach row [lrange $table 1 end] {
#        if {$row eq {%%SEPARATOR%%}} { continue }
#        for {set j 0} {$j<$numCols} {incr j} {
#             set item [lindex $row $j]
#             set max [lindex $maxs $j]
#             if {[string length $item]>$max} {
#                lset maxs $j [string length $item]
#            }
#        }
#    }
#    set head " [string repeat " " [expr $indent * 4]]+"
#    foreach max $maxs {append head -[string repeat - $max]-+}
#    set res $head\n
#    set first 1
#    foreach row $table {
#        if {$row eq {%%SEPARATOR%%}} {
#          append res $head\n
#          continue
#        }
#        append res " [string repeat " " [expr $indent * 4]]|"
#        foreach item $row max $maxs {append res [format " %-${max}s |" $item]}
#        append res \n
#        if {$first} {
#          append res $head\n
#          set first 0
#        }
#    }
#    #append res $head
#    set res
# }

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

##########################################################
# lshift
##########################################################
proc lshift {varname {nth 0}} {
	upvar $varname args
	set r [lindex $args $nth]
	set args [lreplace $args $nth $nth]
	return $r
}


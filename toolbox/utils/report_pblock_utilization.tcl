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
## Description:    Generate a Pblocks utilization report from one or more hierarchical cell(s)
##
########################################################################################

########################################################################################
## 2015.09.18 - Initial release
########################################################################################

# Example of report:
#
#  % tb::report_pblock_utilization -cell [get_cells * -filter {!IS_PRIMITIVE}]
#    +-------------+---------+-----------+
#    | Cell        | # Leafs | No Pblock |
#    +-------------+---------+-----------+
#    | clkgen      | 10      | 10        |
#    | cpuEngine   | 12049   | 12049     |
#    | fftEngine   | 3655    | 3655      |
#    | mgtEngine   | 1232    | 1232      |
#    | usbEngine0  | 11360   | 11360     |
#    | usbEngine1  | 11360   | 11360     |
#    | wbArbEngine | 858     | 858       |
#    +-------------+---------+-----------+
#  % tb::report_pblock_utilization -cell [get_cells usbEngine0/* -filter {!IS_PRIMITIVE}]
#    +--------------------------+---------+-----------+
#    | Cell                     | # Leafs | No Pblock |
#    +--------------------------+---------+-----------+
#    | usbEngine0/dma_out       | 148     | 148       |
#    | usbEngine0/u0            | 282     | 282       |
#    | usbEngine0/u1            | 2377    | 2377      |
#    | usbEngine0/u2            | 4       | 4         |
#    | usbEngine0/u4            | 6833    | 6833      |
#    | usbEngine0/u5            | 70      | 70        |
#    | usbEngine0/usbEngineSRAM | 67      | 67        |
#    | usbEngine0/usb_dma_wb_in | 1058    | 1058      |
#    | usbEngine0/usb_in        | 280     | 280       |
#    | usbEngine0/usb_out       | 148     | 148       |
#    +--------------------------+---------+-----------+
#  % tb::report_pblock_utilization -cell [get_cells * -filter {!IS_PRIMITIVE}]
#    +----------------------+---------+-----------+--------+--------+-------+------------------------+---------------------------+------------------------+---------------------------+
#    | Cell                 | # Leafs | No Pblock | SLR0   | SLR1   | SLR2  | pblock_Laguna_slr0_top | pblock_Laguna_slr1_bottom | pblock_Laguna_slr1_top | pblock_Laguna_slr2_bottom |
#    +----------------------+---------+-----------+--------+--------+-------+------------------------+---------------------------+------------------------+---------------------------+
#    | dr0_rdr0_mid_in_1    | 1036    | 2         | 0      | 0      | 0     | 0                      | 1034                      | 0                      | 0                         |
#    | dr0_rdr0_mid_in_2    | 1036    | 2         | 1034   | 0      | 0     | 0                      | 0                         | 0                      | 0                         |
#    | dr0_rdr0_mid_in_3    | 1036    | 1036      | 0      | 0      | 0     | 0                      | 0                         | 0                      | 0                         |
#    | dr0_rdr1_mid_in_1    | 1036    | 2         | 0      | 1034   | 0     | 0                      | 0                         | 0                      | 0                         |
#    | dr0_rdr1_mid_in_2    | 1036    | 2         | 0      | 1034   | 0     | 0                      | 0                         | 0                      | 0                         |
#    | dr0_rdr1_mid_in_3    | 1036    | 2         | 0      | 1034   | 0     | 0                      | 0                         | 0                      | 0                         |
#    | dr0_to_xup_midflop_1 | 13      | 13        | 0      | 0      | 0     | 0                      | 0                         | 0                      | 0                         |
#    | dr0_to_xup_midflop_2 | 13      | 13        | 0      | 0      | 0     | 0                      | 0                         | 0                      | 0                         |
#    | dr1_rdr0_mid_in_1    | 1036    | 1036      | 0      | 0      | 0     | 0                      | 0                         | 0                      | 0                         |
#    | dr1_rdr0_mid_in_2    | 1036    | 1036      | 0      | 0      | 0     | 0                      | 0                         | 0                      | 0                         |
#    | iilk_np_top1         | 93927   | 13        | 117    | 93714  | 0     | 49                     | 34                        | 0                      | 0                         |
#    | iilk_x2x_top0        | 27162   | 13        | 34     | 83     | 26866 | 49                     | 34                        | 49                     | 34                        |
#    | iilk_x2x_top1        | 27162   | 13        | 34     | 83     | 26866 | 49                     | 34                        | 49                     | 34                        |
#    | iilk_x2x_top2        | 27194   | 13        | 34     | 83     | 26898 | 49                     | 34                        | 49                     | 34                        |
#    | ilk_d0_out_mid_3     | 1039    | 2         | 0      | 1037   | 0     | 0                      | 0                         | 0                      | 0                         |
#    | mux2to1_top0         | 4142    | 0         | 0      | 4142   | 0     | 0                      | 0                         | 0                      | 0                         |
#    | mux2to1_top1         | 4147    | 0         | 0      | 4147   | 0     | 0                      | 0                         | 0                      | 0                         |
#    | xup_dt1_midflop_1    | 1037    | 2         | 0      | 0      | 0     | 0                      | 1035                      | 0                      | 0                         |
#    | xup_dt1_midflop_2    | 1037    | 2         | 1035   | 0      | 0     | 0                      | 0                         | 0                      | 0                         |
#    | xup_in_midflop_1     | 1037    | 2         | 0      | 1035   | 0     | 0                      | 0                         | 0                      | 0                         |
#    | xup_in_midflop_2     | 1037    | 2         | 0      | 1035   | 0     | 0                      | 0                         | 0                      | 0                         |
#    +----------------------+---------+-----------+--------+--------+-------+------------------------+---------------------------+------------------------+---------------------------+

if {[catch {package require prettyTable}]} {
  lappend auto_path {/home/dpefour/git/scripts/toolbox}
  package require prettyTable
}

namespace eval ::tb {
  namespace export -force report_pblock_utilization
}

namespace eval ::tb::utils {
  namespace export -force report_pblock_utilization
}

namespace eval ::tb::utils::report_pblock_utilization {
  namespace export -force report_pblock_utilization
  variable version {2015.09.18}
}

proc ::tb::utils::report_pblock_utilization::lshift {inputlist} {
  upvar $inputlist argv
  set arg  [lindex $argv 0]
  set argv [lrange $argv 1 end]
  return $arg
}

proc ::tb::utils::report_pblock_utilization::report_pblock_utilization {args} {

  set reportfilename {}
  set csvfilename {}
  set modules [list]
  set returnstring 0
  set verbose 0
  set error 0
  set help 0
  if {[llength $args] == 0} {
    set help 1
  }
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-c(e(l(ls?)?)?)?$} -
      {^-cells$} {
        foreach cell [lshift args] {
          lappend modules $cell
        }
      }
      {^-f(i(le?)?)?$} -
      {^-file$} {
        set reportfilename [lshift args]
      }
      {^-cs(v?)$} -
      {^-csv$} {
        set csvfilename [lshift args]
      }
      {^-r(e(t(u(r(n(_(s(t(r(i(ng?)?)?)?)?)?)?)?)?)?)?)?$} -
      {^-return_string$} {
        set returnstring 1
      }
      {^-v(e(r(b(o(se?)?)?)?)?)?$} -
      {^-verbose$} {
        set verbose 1
      }
      {^-h(e(lp?)?)?$} -
      {^-help$} {
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
  Usage: report_pblock_utilization
              -cell <cell|list_of_cells>
              [-file <filename>]
              [-csv <filename>]
              [-return_string]
              [-verbose|-v]
              [-help|-h]

  Description: Generate a Pblock utilization report from one or more hierarchical cell(s)

  Example:
     report_pblock_utilization -cell [get_cells * -filter {!IS_PRIMITIVE}]
     report_pblock_utilization -cell [get_cells i_coresw_pmux/* -filter {!IS_PRIMITIVE}] -file report_pblock_utilization.rpt -csv report_pblock_utilization.csv
     report_pblock_utilization -cell {i_coresw_pmux/pmrx_CORE12_USER18 i_coresw_pmux/pmtx_CORE17_IOU40}
     report_pblock_utilization -cell i_coresw_pmux/pmrx_CORE12_USER18
} ]
    # HELP -->
    return -code ok
  }

  if {![llength $modules]} {
    puts " -E- Use -cell to specify a list of cell(s)"
    incr error
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  set allPblocks [lsort [get_pblocks -quiet]]

  set tbl [::tb::prettyTable]
  set header [list {Cell} {Leafs} {No Pblock}]
  foreach pblock $allPblocks { lappend header $pblock }
  $tbl header $header

  set startTime [clock seconds]
  set count 0
  foreach module [lsort $modules] {
    incr count
    if {$verbose} {
      puts [format { Processing [%s/%s] %s} $count [llength $modules] $module]
    }
#     if {[llength $allPblocks] == 0} { continue }
    set cells [get_cells -quiet -hier -filter "NAME =~ $module/* && IS_PRIMITIVE"]
    set nopblock 0
    catch { unset pblocks }
    foreach el $allPblocks { set pblocks($el) 0 }
    foreach cell $cells {
      set pblock [get_pblocks -quiet -of $cell]
      if {$pblock != {}} {
        incr pblocks($pblock)
      } else {
        incr nopblock
      }
    }
    set row [list $module [llength $cells] $nopblock]
    foreach pblock $allPblocks {
      if {[info exists pblocks($pblock)]} {
        lappend row $pblocks($pblock)
      } else {
        lappend row 0
      }
    }
    $tbl addrow $row
  }

  set stopTime [clock seconds]
  puts " -I- report_pblock_utilization done in [expr $stopTime - $startTime] seconds"

  if {$verbose || (($reportfilename == {}) && ($csvfilename == {}))} {
    puts [$tbl print]
  }

  if {$reportfilename != {}} {
    set FH [open $reportfilename {w}]
    puts $FH "# -----------------------------------------------------------------------------"
    puts $FH [format {# Created on %s with report_pblock_utilization} [clock format [clock seconds]] ]
    puts $FH "# -----------------------------------------------------------------------------\n"
    puts $FH [$tbl export -format table]
    close $FH
#     $tbl print -file $reportfilename
    puts " -I- Generated file [file normalize $reportfilename]"
  }

  if {$csvfilename != {}} {
    set FH [open $csvfilename {w}]
    puts $FH "# -----------------------------------------------------------------------------"
    puts $FH [format {# Created on %s with report_pblock_utilization} [clock format [clock seconds]] ]
    puts $FH "# -----------------------------------------------------------------------------\n"
    puts $FH [$tbl export -format csv]
    close $FH
#     $tbl export -format csv -file $csvfilename
    puts " -I- Generated CSV file [file normalize $csvfilename]"
  }

  set report [$tbl print]

  catch {$tbl destroy}

  if {$returnstring} {
    return $report
  } else {
    return -code ok
  }
}

namespace eval ::tb::utils {
  namespace import -force ::tb::utils::report_pblock_utilization::report_pblock_utilization
}

namespace eval ::tb {
  namespace import -force ::tb::utils::report_pblock_utilization
}

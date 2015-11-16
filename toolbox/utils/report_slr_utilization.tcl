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
## Description:    Generate a SLR utilization report from one or more hierarchical cell(s)
##
########################################################################################

########################################################################################
## 2015.09.18 - Changed namespace
##            - Minor changes to suppress some messages
##            - Improved command line options
##            - Removed columns for non-existing SLRs
## 2015.05.22 - Initial release
########################################################################################

# Example of report:
#    +-----------------------------------+------+------+------+------+------+------+
#    | Cell                              | #    | SLR0 | SLR1 | SLR2 | SLR3 | I/O  |
#    +-----------------------------------+------+------+------+------+------+------+
#    | i_coresw_pmux/pmrx_CORE12_USER18  | 8896 | 5488 | 1393 | 113  | 1902 | SLR0 |
#    | i_coresw_pmux/pmrx_CORE16_MEMC18  | 8144 | 225  | 2402 | 719  | 4798 | SLR1 |
#    | i_coresw_pmux/pmrx_CORE19_GPU18   | 8141 | 0    | 417  | 5717 | 2007 | SLR2 |
#    | i_coresw_pmux/pmrx_CORE21_GPU38   | 8881 | 0    | 0    | 0    | 8881 | SLR3 |
#    | i_coresw_pmux/pmrx_CORE31_USER37  | 8881 | 1333 | 7548 | 0    | 0    | SLR0 |
#    | i_coresw_pmux/pmrx_CORE33_USER39  | 8904 | 739  | 4774 | 790  | 2601 | SLR0 |
#    | i_coresw_pmux/pmrx_CORE34_MEMC37  | 8141 | 0    | 8141 | 0    | 0    | SLR1 |
#    | i_coresw_pmux/pmrx_CORE37_IOU20   | 8881 | 1014 | 5743 | 2124 | 0    | SLR2 |
#    | i_coresw_pmux/pmrx_CORE38_IOU21   | 8881 | 0    | 487  | 5236 | 3158 | SLR2 |
#    | i_coresw_pmux/pmrx_CPU20_CORE39   | 5921 | 0    | 1112 | 1929 | 2880 | SLR2 |
#    | i_coresw_pmux/pmtx_CORE11_USER17  | 5462 | 3047 | 1122 | 27   | 1266 | SLR0 |
#    | i_coresw_pmux/pmtx_CORE13_USER19  | 5481 | 879  | 1795 | 173  | 2634 | SLR0 |
#    | i_coresw_pmux/pmtx_CORE17_IOU40   | 5456 | 623  | 3803 | 1030 | 0    | SLR2 |
#    | i_coresw_pmux/pmtx_CORE18_IOU22   | 5952 | 0    | 701  | 4521 | 730  | SLR2 |
#    | i_coresw_pmux/pmtx_CORE20_GPU37   | 5704 | 0    | 0    | 0    | 5704 | SLR3 |
#    | i_coresw_pmux/pmtx_CORE22_GPU39   | 5456 | 0    | 120  | 960  | 4376 | SLR3 |
#    | i_coresw_pmux/pmtx_CORE32_USER38  | 5956 | 520  | 4055 | 577  | 804  | SLR0 |
#    | i_coresw_pmux/pmtx_CORE35_MEMC38  | 5952 | 324  | 886  | 54   | 4688 | SLR1 |
#    | i_coresw_pmux/pmtx_CORE36_MEMC39  | 5456 | 0    | 1639 | 933  | 2884 | SLR1 |
#    | i_coresw_pmux/pmtx_CPU40_CORE40   | 2480 | 0    | 689  | 588  | 1203 | SLR3 |
#    | i_coresw_pmux/tx_en_gen[0].en_gen | 8    | 0    | 8    | 0    | 0    |      |
#    | i_coresw_pmux/tx_en_gen[1].en_gen | 8    | 0    | 8    | 0    | 0    |      |
#    | i_coresw_pmux/tx_en_gen[2].en_gen | 8    | 0    | 8    | 0    | 0    |      |
#    | i_coresw_pmux/tx_en_gen[3].en_gen | 8    | 0    | 8    | 0    | 0    |      |
#    +-----------------------------------+------+------+------+------+------+------+
#    +--------------------------------+-------+-------+-------+-------+-------+-----+
#    | Cell                           | #     | SLR0  | SLR1  | SLR2  | SLR3  | I/O |
#    +--------------------------------+-------+-------+-------+-------+-------+-----+
#    | u_ibert_core/inst/QUAD[0].u_q  | 18122 | 18100 | 22    | 0     | 0     |     |
#    | u_ibert_core/inst/QUAD[10].u_q | 18137 | 320   | 0     | 0     | 17817 |     |
#    | u_ibert_core/inst/QUAD[11].u_q | 18147 | 320   | 0     | 0     | 17827 |     |
#    | u_ibert_core/inst/QUAD[12].u_q | 18132 | 18100 | 32    | 0     | 0     |     |
#    | u_ibert_core/inst/QUAD[13].u_q | 18142 | 18115 | 27    | 0     | 0     |     |
#    | u_ibert_core/inst/QUAD[14].u_q | 18133 | 320   | 7     | 17806 | 0     |     |
#    | u_ibert_core/inst/QUAD[15].u_q | 18143 | 320   | 0     | 17823 | 0     |     |
#    | u_ibert_core/inst/QUAD[16].u_q | 18133 | 320   | 0     | 17804 | 9     |     |
#    | u_ibert_core/inst/QUAD[17].u_q | 18143 | 320   | 0     | 0     | 17823 |     |
#    | u_ibert_core/inst/QUAD[18].u_q | 18133 | 320   | 0     | 0     | 17813 |     |
#    | u_ibert_core/inst/QUAD[19].u_q | 18143 | 320   | 0     | 2     | 17821 |     |
#    | u_ibert_core/inst/QUAD[1].u_q  | 18132 | 18107 | 25    | 0     | 0     |     |
#    | u_ibert_core/inst/QUAD[2].u_q  | 18127 | 18088 | 39    | 0     | 0     |     |
#    | u_ibert_core/inst/QUAD[3].u_q  | 18137 | 334   | 17803 | 0     | 0     |     |
#    | u_ibert_core/inst/QUAD[4].u_q  | 18132 | 319   | 17813 | 0     | 0     |     |
#    | u_ibert_core/inst/QUAD[5].u_q  | 18142 | 320   | 17819 | 3     | 0     |     |
#    | u_ibert_core/inst/QUAD[6].u_q  | 18132 | 320   | 0     | 17812 | 0     |     |
#    | u_ibert_core/inst/QUAD[7].u_q  | 18142 | 320   | 0     | 17822 | 0     |     |
#    | u_ibert_core/inst/QUAD[8].u_q  | 18132 | 320   | 0     | 17812 | 0     |     |
#    | u_ibert_core/inst/QUAD[9].u_q  | 18142 | 320   | 0     | 0     | 17822 |     |
#    | u_ibert_core/inst/UUT_MASTER   | 3449  | 113   | 295   | 1114  | 1927  |     |
#    | u_ibert_core/inst/U_ICON       | 55    | 0     | 0     | 1     | 54    |     |
#    | u_ibert_core/inst/bscan_inst   | 1     | 0     | 1     | 0     | 0     |     |
#    | u_ibert_core/inst/u_bufr       | 1     | 0     | 0     | 0     | 1     |     |
#    +--------------------------------+-------+-------+-------+-------+-------+-----+
#    +-----------------------+---------+--------+--------+--------+--------+---------------------+
#    | Cell                  | #       | SLR0   | SLR1   | SLR2   | SLR3   | I/O                 |
#    +-----------------------+---------+--------+--------+--------+--------+---------------------+
#    | cfg_check             | 6       | 0      | 6      | 0      | 0      |                     |
#    | dbg_hub               | 1026    | 2      | 1024   | 0      | 0      |                     |
#    | emu_clocking          | 16      | 4      | 5      | 7      | 0      | SLR1 SLR2           |
#    | emu_reset             | 380     | 0      | 380    | 0      | 0      | SLR1                |
#    | i_coresw_glue         | 46      | 0      | 46     | 0      | 0      | SLR1                |
#    | i_coresw_part_wrapper | 1874179 | 465372 | 487252 | 455662 | 465893 |                     |
#    | i_coresw_pmux         | 137058  | 14192  | 46859  | 25491  | 50516  | SLR0 SLR1 SLR2 SLR3 |
#    | vio_0                 | 1779    | 0      | 1779   | 0      | 0      |                     |
#    +-----------------------+---------+--------+--------+--------+--------+---------------------+

if {[catch {package require prettyTable}]} {
  lappend auto_path {/home/dpefour/git/scripts/toolbox}
  package require prettyTable
}

namespace eval ::tb {
  namespace export -force report_slr_utilization
}

namespace eval ::tb::utils {
  namespace export -force report_slr_utilization
}

namespace eval ::tb::utils::report_slr_utilization {
  namespace export -force report_slr_utilization
  variable version {2015.09.18}
}

proc ::tb::utils::report_slr_utilization::lshift {inputlist} {
  upvar $inputlist argv
  set arg  [lindex $argv 0]
  set argv [lrange $argv 1 end]
  return $arg
}

proc ::tb::utils::report_slr_utilization::report_slr_utilization {args} {

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
  Usage: report_slr_utilization
              -cell <cell|list_of_cells>
              [-file <filename>]
              [-csv <filename>]
              [-return_string]
              [-verbose|-v]
              [-help|-h]

  Description: Generate a SLR utilization report from one or more hierarchical cell(s)

  Example:
     report_slr_utilization -cell [get_cells i_coresw_pmux/* -filter {!IS_PRIMITIVE}] -file report_slr_utilization.rpt -csv report_slr_utilization.csv
     report_slr_utilization -cell {i_coresw_pmux/pmrx_CORE12_USER18 i_coresw_pmux/pmtx_CORE17_IOU40}
     report_slr_utilization -cell i_coresw_pmux/pmrx_CORE12_USER18
     report_slr_utilization -cell [get_cells * -filter {!IS_PRIMITIVE}]
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

  set allSLRs [lsort [get_slrs -quiet]]

  set tbl [::tb::prettyTable]
  set header [list {Cell} {Leafs}]
  foreach slr $allSLRs { lappend header $slr }
  lappend header {I/O}
  $tbl header $header

  set startTime [clock seconds]
  set count 0
  foreach module [lsort $modules] {
    incr count
    if {$verbose} {
      puts [format { Processing [%s/%s] %s} $count [llength $modules] $module]
    }
    set cells [get_cells -quiet -hier -filter "NAME =~ $module/* && IS_PRIMITIVE"]
    set ios [filter -quiet $cells {(REF_NAME =~ IBUF*) || (REF_NAME =~ OBUF*)}]
    catch { unset slrs }
    foreach el $allSLRs { set slrs($el) 0 }
    foreach cell $cells {
      set slr [get_slrs -quiet -of $cell]
      if {$slr != {}} {
        incr slrs($slr)
      }
    }
    set row [list $module [llength $cells] ]
    foreach slr $allSLRs {
      if {[info exists slrs($slr)]} {
        lappend row $slrs($slr)
      } else {
        lappend row 0
      }
    }
    lappend row [get_slrs -quiet -of $ios]
    $tbl addrow $row
  }

  set stopTime [clock seconds]
  puts " -I- report_slr_utilization done in [expr $stopTime - $startTime] seconds"

  if {$verbose || (($reportfilename == {}) && ($csvfilename == {}))} {
    puts [$tbl print]
  }

  if {$reportfilename != {}} {
    set FH [open $reportfilename {w}]
    puts $FH "# -----------------------------------------------------------------------------"
    puts $FH [format {# Created on %s with report_slr_utilization} [clock format [clock seconds]] ]
    puts $FH "# -----------------------------------------------------------------------------\n"
    puts $FH [$tbl export -format table]
    close $FH
#     $tbl print -file $reportfilename
    puts " -I- Generated file [file normalize $reportfilename]"
  }

  if {$csvfilename != {}} {
    set FH [open $csvfilename {w}]
    puts $FH "# -----------------------------------------------------------------------------"
    puts $FH [format {# Created on %s with report_slr_utilization} [clock format [clock seconds]] ]
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
  namespace import -force ::tb::utils::report_slr_utilization::report_slr_utilization
}

namespace eval ::tb {
  namespace import -force ::tb::utils::report_slr_utilization
}

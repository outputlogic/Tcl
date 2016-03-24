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
## Description:    Generate a net correlation report from timing paths
##
########################################################################################

########################################################################################
## 2016.03.23 - Added columns 'Tiles Delta X', 'Tiles Delta Y'
##            - Added columns 'INT Distance (X+Y)', 'INT Delta X', 'INT Delta Y', 'INT Inbox'
##            - Fixed extraction of INTerconnect data ('Driver INT', 'Receiver INT')
## 2016.02.29 - Added columns 'Levels', 'Net vs. Estimated', 'Net vs. P2P'
## 2016.02.26 - Initial release
########################################################################################

# Example of report:
#  +---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
#  | Net Correlation (Huawei_docsis)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
#  | Margin=0.1 / Delta=0.020ns                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
#  | EstDly/P2PDly < 0.9                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
#  | EstDly/P2PDly > 1.1                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
#  | Estimated vs. P2P = Estimated / P2P                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
#  | Error vs. P2P (%) = 100 * (P2P - Estimated) / P2P                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
#  | Absolute Error = ABS(P2P - Estimated)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
#  | Total number of paths processed: 500                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
#  | Total number of nets processed: 531                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
#  | Total number of nets reported in the table: 101                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
#  +---------------+--------------------------+--------+----------------+----------------+--------------------+------------------------------+------------+---------------------------+------------+--------+---------------+-------------------+----------------+------------+-----------------+-----------+-------------------+-------------------+---------------------+-------------------+-------------+--------+--------------+----------------------+---------------+---------------+-------+-------------+--------------+----------------------------------------------------------------------------------------------------------------------------------------------------------------+----------------------------------------------+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
#  | Design        | Part                     | Path # | Driver Tile    | Receiver Tile  | Driver Site        | Receiver Site                | Driver Pin | Receiver Pin              | Path Slack | Levels | Routable Nets | Driver Incr Delay | Net Incr Delay | Delay Type | Estimated Delay | P2P Delay | Estimated vs. P2P | Error vs. P2P (%) | Absolute Error (ns) | Net vs. Estimated | Net vs. P2P | Fanout | SLR Crossing | Tiles Distance (X+Y) | Tiles Delta X | Tiles Delta Y | Inbox | Driver INT  | Receiver INT | Net                                                                                                                                                            | Driver                                       | Receiver                                                                                                                                                                         |
#  +---------------+--------------------------+--------+----------------+----------------+--------------------+------------------------------+------------+---------------------------+------------+--------+---------------+-------------------+----------------+------------+-----------------+-----------+-------------------+-------------------+---------------------+-------------------+-------------+--------+--------------+----------------------+---------------+---------------+-------+-------------+--------------+----------------------------------------------------------------------------------------------------------------------------------------------------------------+----------------------------------------------+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
#  | Huawei_docsis | xcku115-flva1517-2-i-es2 | 1      | CLEL_R_X64Y143 | DSP_X59Y285    | SLICE_X96Y143 AQ   | DSP48E2_X16Y114 RSTB_B       | FDPE/Q     | DSP_A_B_DATA/RSTB         | -1.220     | 0      | 1             | 0.115             | 2.718          | routed     | 1.991           | 2.296     | 0.87              | 13.28             | 0.305               | 1.37              | 1.18        | 118718 | 0            | 217                  | 200           | 17            | 0     | INT_X64Y143 | INT_X59Y286  | u_d30dphy_top/u_duc/u_stage1_sr2/hb15[2].hb15_inst/phase0_filter[2].mac_systolic_chainin_inst/instance_dsp48_preadd_mult_rnd_pcin_postadd/DSP48E2_inst/RSTB    | u_clk_ku115/u0_rst_clk_352m/rst_reg_reg[3]/Q | u_d30dphy_top/u_duc/u_stage1_sr2/hb15[2].hb15_inst/phase0_filter[2].mac_systolic_chainin_inst/instance_dsp48_preadd_mult_rnd_pcin_postadd/DSP48E2_inst/DSP_A_B_DATA_INST/RSTB    |
#  | Huawei_docsis | xcku115-flva1517-2-i-es2 | 20     | CLEL_R_X64Y143 | DSP_X59Y280    | SLICE_X96Y143 AQ   | DSP48E2_X16Y112 RSTCTRL_B    | FDPE/Q     | DSP_ALU/RSTCTRL           | -1.103     | 0      | 1             | 0.115             | 2.752          | routed     | 1.946           | 2.24      | 0.87              | 13.13             | 0.294               | 1.41              | 1.23        | 118718 | 0            | 212                  | 200           | 12            | 0     | INT_X64Y143 | INT_X59Y282  | u_d30dphy_top/u_duc/u_stage1_sr2/hb15[2].hb15_inst/phase0_filter[1].mac_systolic_inst/instance_dsp48_preadd_mult_pcin_postadd_pcout_1/DSP48E2_inst/RSTCTRL     | u_clk_ku115/u0_rst_clk_352m/rst_reg_reg[3]/Q | u_d30dphy_top/u_duc/u_stage1_sr2/hb15[2].hb15_inst/phase0_filter[1].mac_systolic_inst/instance_dsp48_preadd_mult_pcin_postadd_pcout_1/DSP48E2_inst/DSP_ALU_INST/RSTCTRL          |
#  | Huawei_docsis | xcku115-flva1517-2-i-es2 | 24     | CLEL_R_X64Y143 | DSP_X59Y265    | SLICE_X96Y143 AQ   | DSP48E2_X16Y106 RSTB_B       | FDPE/Q     | DSP_A_B_DATA/RSTB         | -1.091     | 0      | 1             | 0.115             | 2.585          | routed     | 1.771           | 2.058     | 0.86              | 13.95             | 0.287               | 1.46              | 1.26        | 118718 | 0            | 196                  | 100           | 96            | 0     | INT_X64Y143 | INT_X59Y266  | u_d30dphy_top/u_duc/u_stage2/hb2_inst/inst_1lane_filter[2].hb7_1lane_4ch_inst/mult_add[0].dsp_sum2_inst/u_dsp48_preadd_mult_rnd_pcin_postadd/DSP48E2_inst/RSTB | u_clk_ku115/u0_rst_clk_352m/rst_reg_reg[3]/Q | u_d30dphy_top/u_duc/u_stage2/hb2_inst/inst_1lane_filter[2].hb7_1lane_4ch_inst/mult_add[0].dsp_sum2_inst/u_dsp48_preadd_mult_rnd_pcin_postadd/DSP48E2_inst/DSP_A_B_DATA_INST/RSTB |
#  | Huawei_docsis | xcku115-flva1517-2-i-es2 | 27     | CLEL_R_X64Y143 | DSP_X59Y220    | SLICE_X96Y143 AQ   | DSP48E2_X16Y89 RSTB_B        | FDPE/Q     | DSP_A_B_DATA/RSTB         | -1.088     | 0      | 1             | 0.115             | 2.596          | routed     | 1.441           | 1.631     | 0.88              | 11.65             | 0.190               | 1.80              | 1.59        | 118718 | 0            | 150                  | 140           | 10            | 0     | INT_X64Y143 | INT_X59Y223  | u_d30dphy_top/u_duc/u_stage1_sr2/hb15[0].hb15_inst/phase0_filter[2].mac_systolic_chainin_inst/instance_dsp48_preadd_mult_rnd_pcin_postadd/DSP48E2_inst/RSTB    | u_clk_ku115/u0_rst_clk_352m/rst_reg_reg[3]/Q | u_d30dphy_top/u_duc/u_stage1_sr2/hb15[0].hb15_inst/phase0_filter[2].mac_systolic_chainin_inst/instance_dsp48_preadd_mult_rnd_pcin_postadd/DSP48E2_inst/DSP_A_B_DATA_INST/RSTB    |
#  ...
#  +---------------+--------------------------+--------+----------------+----------------+--------------------+------------------------------+------------+---------------------------+------------+--------+---------------+-------------------+----------------+------------+-----------------+-----------+-------------------+-------------------+---------------------+-------------------+-------------+--------+--------------+----------------------+---------------+---------------+-------+-------------+--------------+----------------------------------------------------------------------------------------------------------------------------------------------------------------+----------------------------------------------+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
#  +-------------------------------------------------+  +-----------------------------------------+
#  | Primitives                                      |  | Primitives                              |
#  | EstDly/P2PDly < 0.9                             |  | EstDly/P2PDly > 1.1                     |
#  +--------+---------------------------+----+-------+  +--------+-------------------+----+-------+
#  | From   | To                        | #  | %     |  | From   | To                | #  | %     |
#  +--------+---------------------------+----+-------+  +--------+-------------------+----+-------+
#  | FDPE/Q | FDCE/CLR                  | 28 | 27.72 |  | FDCE/Q | FDCE/CE           | 12 | 11.88 |
#  | FDPE/Q | DSP_ALU/RSTCTRL           | 10 | 9.90  |  | FDCE/Q | DSP_A_B_DATA/A[*] | 2  | 1.98  |
#  | LUT2/O | FDCE/CE                   | 10 | 9.90  |  | FDCE/Q | DSP_A_B_DATA/CEB2 | 1  | 0.99  |
#  | FDPE/Q | LUT2/I0                   | 8  | 7.92  |  | FDPE/Q | DSP_A_B_DATA/RSTA | 1  | 0.99  |
#  | FDCE/Q | FDRE/CE                   | 6  | 5.94  |  +--------+-------------------+----+-------+
#  | FDPE/Q | DSP_A_B_DATA/RSTB         | 6  | 5.94  |
#  | FDPE/Q | DSP_A_B_DATA/RSTA         | 4  | 3.96  |
#  | FDPE/Q | DSP_ALU/RSTALUMODE        | 4  | 3.96  |
#  | FDPE/Q | DSP_OUTPUT/RSTP           | 3  | 2.97  |
#  | FDPE/Q | DSP_M_DATA/RSTM           | 2  | 1.98  |
#  | FDPE/Q | DSP_PREADD_DATA/RSTD      | 2  | 1.98  |
#  | FDPE/Q | DSP_PREADD_DATA/RSTINMODE | 2  | 1.98  |
#  +--------+---------------------------+----+-------+
#  +-------------------------+  +-------------------------+
#  | Sub-Groups              |  | Sub-Groups              |
#  | EstDly/P2PDly < 0.9     |  | EstDly/P2PDly > 1.1     |
#  +------+-----+----+-------+  +------+-----+----+-------+
#  | From | To  | #  | %     |  | From | To  | #  | %     |
#  +------+-----+----+-------+  +------+-----+----+-------+
#  | SDR  | SDR | 34 | 33.66 |  | SDR  | SDR | 12 | 11.88 |
#  | SDR  | DSP | 33 | 32.67 |  | SDR  | DSP | 4  | 3.96  |
#  | LUT  | SDR | 10 | 9.90  |  +------+-----+----+-------+
#  | SDR  | LUT | 8  | 7.92  |
#  +------+-----+----+-------+

namespace eval ::tb {
#   namespace export -force report_net_correlation
}

# Packages dependencies
if {[catch {package require prettyTable}]} {
  lappend auto_path {/home/dpefour/git/scripts/toolbox}
  package require prettyTable
}
package require p2pdelay

namespace eval ::tb::utils {
  namespace export -force report_net_correlation
}

namespace eval ::tb::utils::report_net_correlation {
  namespace export -force report_net_correlation
  variable version {2016.03.23}
  variable params
  variable output {}
  variable nNets 0
  variable nTotalNets 0
  variable arrStats
  array set params [list format {both} verbose 0 debug 0 firstrun 1 ]
}

proc ::tb::utils::report_net_correlation::lshift {inputlist} {
  upvar $inputlist argv
  set arg  [lindex $argv 0]
  set argv [lrange $argv 1 end]
  return $arg
}

proc ::tb::utils::report_net_correlation::report_net_correlation {args} {
  variable params
  variable nNets
  variable nTotalNets
  variable arrStats
  variable output
  set params(verbose) 0
  set params(debug) 0
  set params(format) {both}
  set filename {}
  set filemode {w}
  set paths [list]
  # Margin of 10%
  set margin 0.1
  # Minimum difference between estimated and p2p delays: 20ps
  set delta 0.020
  # Inbox dimensions (X, Y) for estimated delay : values for UltraScale and UltraScale Plus
  set inboxSizeX 20
  set inboxSizeY 26
  set design {}
  set returnstring 0
  set error 0
  set help 0
  if {[llength $args] == 0} {
    set help 1
  }
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-o(f(_(o(b(j(e(c(t(s?)?)?)?)?)?)?)?)?)?$} {
        set paths [lshift args]
      }
      {^-ma(r(g(in?)?)?)?$} {
        set margin [lshift args]
      }
      {^-de(l(ta?)?)?$} {
        set delta [lshift args]
      }
      {^-de(s(i(gn?)?)?)?$} {
        set design [lshift args]
      }
      {^-f(i(le?)?)?$} {
        set filename [lshift args]
      }
      {^-ap(p(e(nd?)?)?)?$} {
        set filemode {a}
      }
      {^-fo(r(m(at?)?)?)?$} {
        set params(format) [lshift args]
      }
      {^-csv?$} {
        set params(format) {csv}
      }
      {^-table?$} {
        set params(format) {table}
      }
      {^-re(t(u(r(n(_(s(t(r(i(ng?)?)?)?)?)?)?)?)?)?)?$} {
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
  Usage: report_net_correlation
              -of_objects <timing_paths_objects>
              [-margin <number>]
              [-delta <number>]
              [-design <string>]
              [-file <filename>]
              [-append]
              [-format <table|csv|both>][-csv][-table]
              [-return_string]
              [-verbose|-v]
              [-help|-h]

  Description: Generate a net correlation report

    Use -margin to specify the acceptable margin for the ratio
    between estimated and p2p delay. The default margin is 0.1 (10%%)
    Use -delta to specify the absolute minimum difference between estimated
    and p2p delay to be reported. The default delta is 0.020 (20ps)
    Use -return_string to return the report as a string

    The column 'Routable Nets' indicates the number of nets in the paths
    that are not intra-site.

  Example:
     set spaths [get_timing_paths -setup -nworst 1 -max 10]
     tb::report_net_correlation -of $spaths -file myreport.csv
     tb::report_net_correlation -of $spaths -margin 0.2
} ]
    # HELP -->
    return -code ok
  }

  if {[llength $paths] == 0} {
    puts " -E- no timing paths provided"
    incr error
  }

  switch $params(format) {
    csv -
    table -
    both {
    }
    default {
      puts " -E- invalid format (-format). Expected values: csv | table | both"
      incr error
    }
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  if {$params(firstrun)} {
    puts " ######################################################"
    puts " ##"
    puts " ## This is the first run on this design. The device"
    puts " ## initialization can take up to 10mns to 15mns."
    puts " ## This initialization is a one-step process that won't"
    puts " ## be required for subsequent runs."
    puts " ##"
    puts " ######################################################"
  }

  set startTime [clock seconds]
  set outputCSV [list]
  set outputRPT [list]
  set output [list]
  set filename [file normalize $filename]

  if {[catch {

    ########################################################################################
    ##
    ## Extract data from timing paths
    ##
    ########################################################################################

    set tbl [GetNetCorrelation -paths $paths -margin $margin -delta $delta -inboxX $inboxSizeX -inboxY $inboxSizeY -design $design]

    if {$design == {}} {
      # If no design name, then hide the first 2 columns
      $tbl configure -display_columns [iota 2 40]
    }

    $tbl export -format csv -return_var report
    set outputCSV [split $report \n]

    $tbl export -format table -return_var report
    set outputRPT [split $report \n]

#     puts [$tbl print]
    catch {$tbl destroy}

    ########################################################################################
    ##
    ## Generate the summary tables
    ##
    ########################################################################################

    set output [list]

    set tbl1 [::tb::prettyTable "Primitives\nEstDly/P2PDly < [expr 1.0 - $margin]"]
    $tbl1 header [list {From} {To} {#} {%}]
    set L [getFrequencyDistribution $arrStats(primitive:under)]
    foreach el $L {
      foreach {name num} $el { break }
      foreach {from to} $name { break }
      set row [list $from $to $num]
      lappend row [format {%.2f} [expr 100 * $num / double($nNets)]]
      $tbl1 addrow $row
    }
#     puts [$tbl1 print]

    set tbl2 [::tb::prettyTable "Primitives\nEstDly/P2PDly > [expr 1.0 + $margin]"]
    $tbl2 header [list {From} {To} {#} {%}]
    set L [getFrequencyDistribution $arrStats(primitive:over)]
    foreach el $L {
      foreach {name num} $el { break }
      foreach {from to} $name { break }
      set row [list $from $to $num]
      lappend row [format {%.2f} [expr 100 * $num / double($nNets)]]
      $tbl2 addrow $row
    }
#     puts [$tbl2 print]

#     puts [sideBySide [$tbl1 print] [$tbl2 print]]
    set output [concat $output [split [sideBySide [$tbl1 print] [$tbl2 print]] \n] ]

    catch {$tbl1 destroy}
    catch {$tbl2 destroy}

    ########################################################################################

    set tbl1 [::tb::prettyTable "Sub-Groups\nEstDly/P2PDly < [expr 1.0 - $margin]"]
    $tbl1 header [list {From} {To} {#} {%}]
    set L [getFrequencyDistribution $arrStats(subgroup:under)]
    foreach el $L {
      foreach {name num} $el { break }
      foreach {from to} $name { break }
      set row [list $from $to $num]
      lappend row [format {%.2f} [expr 100 * $num / double($nNets)]]
      $tbl1 addrow $row
    }
#     puts [$tbl1 print]

    set tbl2 [::tb::prettyTable "Sub-Groups\nEstDly/P2PDly > [expr 1.0 + $margin]"]
    $tbl2 header [list {From} {To} {#} {%}]
    set L [getFrequencyDistribution $arrStats(subgroup:over)]
    foreach el $L {
      foreach {name num} $el { break }
      foreach {from to} $name { break }
      set row [list $from $to $num]
      lappend row [format {%.2f} [expr 100 * $num / double($nNets)]]
      $tbl2 addrow $row
    }
#     puts [$tbl2 print]

#     puts [sideBySide [$tbl1 print] [$tbl2 print]]
    set output [concat $output [split [sideBySide [$tbl1 print] [$tbl2 print]] \n] ]

    catch {$tbl1 destroy}
    catch {$tbl2 destroy}

    ########################################################################################

    # Append summary tables at the end of the table report
    foreach line $output {
      lappend outputRPT $line
    }

    ########################################################################################
    ##
    ##
    ##
    ########################################################################################

  } errorstring]} {
    puts " -E- $errorstring"
  }

  # Mark that report_net_correlation has already been run once
  set params(firstrun) 0

  if {$params(debug)} {
  }

  set stopTime [clock seconds]
  puts " -I- report_net_correlation completed in [expr $stopTime - $startTime] seconds"

  if {$filename != {}} {
    switch $params(format) {
      csv {
        set FH [open $filename $filemode]
        puts $FH "# ---------------------------------------------------------------------------------"
        puts $FH [format {# Created on %s with report_net_correlation (%s)} [clock format [clock seconds]] $::tb::utils::report_net_correlation::version ]
        puts $FH "# ---------------------------------------------------------------------------------\n"
        puts $FH [join $outputCSV \n]
        close $FH
        puts " -I- Generated CSV file $filename"
      }
      table {
        set FH [open $filename $filemode]
        puts $FH "# ---------------------------------------------------------------------------------"
        puts $FH [format {# Created on %s with report_net_correlation (%s)} [clock format [clock seconds]] $::tb::utils::report_net_correlation::version ]
        puts $FH "# ---------------------------------------------------------------------------------\n"
        puts $FH [join $outputRPT \n]
        close $FH
        puts " -I- Generated report file $filename"
      }
      both {
        set FH [open [format {%s.csv} [file rootname [file normalize $filename]]] $filemode]
        puts $FH "# ---------------------------------------------------------------------------------"
        puts $FH [format {# Created on %s with report_net_correlation (%s)} [clock format [clock seconds]] $::tb::utils::report_net_correlation::version ]
        puts $FH "# ---------------------------------------------------------------------------------\n"
        puts $FH [join $outputCSV \n]
        close $FH
        puts " -I- Generated CSV file [format {%s.csv} [file rootname [file normalize $filename]]]"
        set FH [open [format {%s.rpt} [file rootname [file normalize $filename]]] $filemode]
        puts $FH "# ---------------------------------------------------------------------------------"
        puts $FH [format {# Created on %s with report_net_correlation (%s)} [clock format [clock seconds]] $::tb::utils::report_net_correlation::version ]
        puts $FH "# ---------------------------------------------------------------------------------\n"
        puts $FH [join $outputRPT \n]
        close $FH
        puts " -I- Generated report file [format {%s.rpt} [file rootname [file normalize $filename]]]"
      }
      default {
      }
    }
    return -code ok
  }

  if {$returnstring} {
    switch $params(format) {
      csv {
        return [join $outputCSV \n]
      }
      table {
        return [join $outputRPT \n]
      }
      both {
        return [join $outputRPT \n]
      }
    }
  } else {
    switch $params(format) {
      csv {
        puts [join $outputCSV \n]
      }
      table {
        puts [join $outputRPT \n]
      }
      both {
        puts [join $outputRPT \n]
      }
    }
  }
  return -code ok
}

########################################################################################
##
##
##
########################################################################################
proc ::tb::utils::report_net_correlation::GetNetCorrelation { args } {
  variable params
  variable nNets
  variable nTotalNets
  variable arrStats
  # Margin: 10% / Delta: 20ps
  array set defaults [list paths [list] margin 0.1 delta 0.020 inboxX 20 inboxY 26 design {}]
  array set options [array get defaults]
  array set options $args
  set paths $options(-paths)
  set margin $options(-margin)
  set delta $options(-delta)
  set design $options(-design)
  set inboxSizeX $options(-inboxX)
  set inboxSizeY $options(-inboxY)

  if {($paths == {})} {
    error " error - empty path"
  }

  set part [get_property PART [current_design]]
  if {$design == {}} {
    set tbl [tb::prettyTable "Net Correlation\nEstDly/P2PDly < [expr 1.0 - $margin]\nEstDly/P2PDly > [expr 1.0 + $margin]"]
  } else {
    set tbl [tb::prettyTable "Net Correlation ($design)\nEstDly/P2PDly < [expr 1.0 - $margin]\nEstDly/P2PDly > [expr 1.0 + $margin]" ]
  }
  $tbl header [list {Design} {Part} {Path #} {Driver Tile} {Receiver Tile} {Driver Site} {Receiver Site} {Driver Pin} {Receiver Pin} {Path Slack} {Levels} {Routable Nets} {Driver Incr Delay} {Net Incr Delay} {Delay Type} {Estimated Delay} {P2P Delay} {Estimated vs. P2P} {Error vs. P2P (%)} {Absolute Error (ns)} {Net vs. Estimated} {Net vs. P2P} {Fanout} {SLR Crossing} {INT Inbox} {Tiles Distance (X+Y)} {Tiles Delta X} {Tiles Delta Y} {INT Distance (X+Y)} {INT Delta X} {INT Delta Y} {Driver INT} {Receiver INT} {Net} {Driver} {Receiver}  ]

  catch {unset arrStats}
  set arrStats(primitive:over) [list]
  set arrStats(primitive:under) [list]
  set arrStats(subgroup:over) [list]
  set arrStats(subgroup:under) [list]
  set nNets 0
  set nTotalNets 0
  set nIntrasiteNets 0
  set nWithinMarginNets 0
  set nUnderDeltaNets 0
  set count -1
  foreach path $paths {
    incr count
    dputs " -D- Processing path $count"
    if {[get_property CLASS [get_property STARTPOINT_PIN $path]] == {port}} {
      puts " -W- skipping path $count due to input port: $path"
      continue
    }
    if {[get_property CLASS [get_property ENDPOINT_PIN $path]] == {port}} {
      puts " -W- skipping path $count due to output port: $path"
      continue
    }
    if {[regexp {MaxDelay.+datapath_only} [get_property EXCEPTION $path]]} {
      puts " -W- skipping path $count due to Max Delay DPO: $path"
      continue
    }

    set slack [get_property -quiet SLACK $path]
    # Get the number of nets on the path that are not INTRASITE
    set nonIntrasiteNets [filter -quiet [get_nets -quiet -of $path] {ROUTE_STATUS != INTRASITE}]
    set lvls [get_property -quiet LOGIC_LEVELS $path]
    set spPin [get_property -quiet STARTPOINT_PIN $path]
    set spPinType [pin2pintype $spPin]

    set epPin [get_property -quiet ENDPOINT_PIN $path]
    set epPinType [pin2pintype $epPin]

    if {[catch { set pathInfo [get_path_info $path 1] } errorstring]} {
      puts " -E- skipping path $count due to error below: $path"
      puts " -E- get_path_info: $errorstring"
      continue
    }
    dputs "<pathInfo:[join $pathInfo \n]>"

    # Iterating over all the nets of the path
    if {[catch {

      # Skip the last element of $pathInfo since this is the endpoint information
      foreach elm [lrange $pathInfo 0 end-1] {
        foreach {pindata netdata inputpinname} $elm { break }
        foreach {pinname pinrisefall pinincrdelay pindelay} $pindata { break }
        foreach {netname netlength netfanout nettype netincrdelay netdelay} $netdata { break }
        dputs "<$netname:$pinname:$inputpinname>"

        set net [get_nets -quiet $netname]
        set pinobj [get_pins -quiet $pinname]
        set inputpinobj [get_pins -quiet $inputpinname]
        set pintype [pin2pintype $pinobj]
        set inputpintype [pin2pintype $inputpinobj]
        # Is the net an intra-site net?
        if {[get_property -quiet ROUTE_STATUS $net] == {INTRASITE}} {
          puts " -I- skipping intra-site net $pintype -> $inputpintype ($netname) (path $count)"
          incr nIntrasiteNets
          continue
        }

        if {[catch {set p2pDelay [tb::p2pdelay get_p2p_delay -from $pinname -to $inputpinname -options {-disableGlobals -removeLUTPinDelay}]} errorstring]} {
          set p2pDelay {n/a}
        } else {
          # Convert delay in ns
          set p2pDelay [expr $p2pDelay / 1000.0]
        }
        dputs "<p2pDelay:$p2pDelay>"
        if {[catch {set estDelay [tb::p2pdelay get_est_wire_delay -from $pinname -to $inputpinname]} errorstring]} {
          set estDelay {n/a}
        } else {
          # Convert delay in ns
          set estDelay [expr $estDelay / 1000.0]
        }
        # est / p2p
        set correlation {n/a}
        # ((p2p – est) / p2p)  * 100
        set correlationPct {n/a}
        # abs(p2p - est)
        set absoluteErr {n/a}
        if {[string is double $p2pDelay] && [string is double $estDelay] && ($estDelay != {}) && ($p2pDelay != {})} {
          if {$p2pDelay != 0} {
            set correlation [format {%.2f} [expr double($estDelay) / double($p2pDelay)] ]
            # ((p2p – est) / p2p)  * 100
            set correlationPct [format {%.2f} [expr 100.0 * (double($p2pDelay) - double($estDelay)) / double($p2pDelay)] ]
          } else {
            set correlation {#DIV0}
            set correlationPct {#DIV0}
          }
          # absolute error
          set absoluteErr [format {%.3f} [expr abs($estDelay - $p2pDelay)] ]
        } else {
          set correlation {n/a}
          set correlationPct {n/a}
          set absoluteErr {n/a}
        }
        #  Net Delay vs Estimated
        set netDelayOverEstimated {n/a}
        if {[string is double $netincrdelay] && [string is double $estDelay] && ($netincrdelay != {}) && ($estDelay != {})} {
          if {$estDelay != 0} {
            catch { set netDelayOverEstimated [format {%.2f} [expr double($netincrdelay) / double($estDelay)] ] }
          } else {
            set netDelayOverEstimated {#DIV0}
          }
        }
        #  Net Delay vs P2P
        set netDelayOverP2P {n/a}
        if {[string is double $netincrdelay] && [string is double $p2pDelay] && ($netincrdelay != {}) && ($p2pDelay != {})} {
          if {$p2pDelay != 0} {
            catch { set netDelayOverP2P [format {%.2f} [expr double($netincrdelay) / double($p2pDelay)] ] }
          } else {
            set netDelayOverP2P {#DIV0}
          }
        }

        set slrs [get_slrs -quiet -of [get_pins [list $pinname $inputpinname] ]]
        if {[llength $slrs] == 1} {
          set slrcrossing 0
        } else {
          if {[regexp {SLR([0-9]+) SLR([0-9]+)} [lsort $slrs] - min max]} {
            # Calculate number of SLR crossing between the 2 SLRs
            set slrcrossing [expr $max - $min]
        } else {
            puts " -W- could not extract SLRs from '$slrs'"
            set slrcrossing 1
          }
        }

        incr nTotalNets

        if {[string is double $correlation] && ($correlation != {})} {
          if {($correlation >= [expr 1.0 - $margin]) && ($correlation <= [expr 1.0 + $margin])} {
            # If the ratio is within the margin, skip the net
            puts " -I- skipping net '$netname' (ration = $correlation) (within margin) (path $count)"
            incr nWithinMarginNets
            continue
          }
        }

        # Skip net if the difference between the estimated delay and P2P delay is less than 20ps
        if {[string is double $p2pDelay] && [string is double $estDelay] && ($estDelay != {}) && ($p2pDelay != {})} {
          if {[expr abs(double($estDelay) - double($p2pDelay))] < $delta} {
            puts " -I- skipping net '$netname' (estDelay=$estDelay / p2pDelay=$p2pDelay) (diff<${delta}ns) (path $count)"
            incr nUnderDeltaNets
            continue
          }
        }

        set srcTile [get_tiles -quiet -of [get_property -quiet SITE [get_cells -quiet -of $pinobj]]]
        set destTile [get_tiles -quiet -of [get_property -quiet SITE [get_cells -quiet -of $inputpinobj]]]
        set srcTile_X [get_property -quiet TILE_X $srcTile]
        set srcTile_Y [get_property -quiet TILE_Y $srcTile]
        set destTile_X [get_property -quiet TILE_X $destTile]
        set destTile_Y [get_property -quiet TILE_Y $destTile]
        set deltaTileX [expr abs($srcTile_X - $destTile_X)]
        set deltaTileY [expr abs($srcTile_Y - $destTile_Y)]
        set srcINT [returnClosestINT $pinobj]
        set destINT [returnClosestINT $inputpinobj]
        set srcINT_X {n/a} ; set srcINT_Y {n/a} ; set destINT_X {n/a} ; set destINT_Y {n/a}
        regexp {^INT_X([0-9]+)Y([0-9]+)} $srcINT - srcINT_X srcINT_Y
        regexp {^INT_X([0-9]+)Y([0-9]+)} $destINT - destINT_X destINT_Y
        if {[catch {set deltaIntX [expr abs($srcINT_X - $destINT_X)]}]} {
          set deltaIntX {n/a}
        }
        if {[catch {set deltaIntY [expr abs($srcINT_Y - $destINT_Y)]}]} {
          set deltaIntY {n/a}
        }
        if {[string is double $deltaIntX] && [string is double $deltaIntY] && ($deltaIntX != {}) && ($deltaIntY != {})} {
          if {($deltaIntX <= $inboxSizeX) && ($deltaIntY <= $inboxSizeY)} {
            # This in an inbox net
            set inbox 1
          } else {
            # This is an outbox net
            set inbox 0
          }
          set distanceINT [expr $deltaIntX + $deltaIntY]
        } else {
          set inbox {n/a}
          set distanceINT {n/a}
        }

        $tbl addrow [list $design \
                          $part \
                          $count \
                          $srcTile \
                          $destTile \
                          [tb::p2pdelay pin_info $pinname] \
                          [tb::p2pdelay pin_info $inputpinname] \
                          $pintype \
                          $inputpintype \
                          $slack \
                          $lvls \
                          [llength $nonIntrasiteNets] \
                          $pinincrdelay \
                          $netincrdelay \
                          $nettype \
                          $estDelay \
                          $p2pDelay \
                          $correlation \
                          $correlationPct \
                          $absoluteErr \
                          $netDelayOverEstimated \
                          $netDelayOverP2P \
                          $netfanout \
                          $slrcrossing \
                          $inbox \
                          $netlength \
                          $deltaTileX \
                          $deltaTileY \
                          $distanceINT \
                          $deltaIntX \
                          $deltaIntY \
                          $srcINT \
                          $destINT \
                          $netname \
                          $pinname \
                          $inputpinname \
                          ]

        # Save the list of primitive pairs for statistics
        if {[string is double $correlation] && ($correlation != {})} {
          if {$correlation > [expr 1.0 - $margin]} {
            set fromsubgroup [get_property -quiet PRIMITIVE_SUBGROUP [get_cells -quiet -of $pinobj]]
            set tosubgroup [get_property -quiet PRIMITIVE_SUBGROUP [get_cells -quiet -of $inputpinobj]]
            lappend arrStats(primitive:over) [list $pintype $inputpintype]
            lappend arrStats(subgroup:over) [list $fromsubgroup $tosubgroup]
          } elseif {$correlation < [expr 1.0 + $margin]} {
            set fromsubgroup [get_property -quiet PRIMITIVE_SUBGROUP [get_cells -quiet -of $pinobj]]
            set tosubgroup [get_property -quiet PRIMITIVE_SUBGROUP [get_cells -quiet -of $inputpinobj]]
            lappend arrStats(primitive:under) [list $pintype $inputpintype]
            lappend arrStats(subgroup:under) [list $fromsubgroup $tosubgroup]
          } else {
          }
        }

        incr nNets
      }

    } errorstring]} {
      puts " -E- $errorstring"
    }

  }

  if {$design == {}} {
    set title "Net Correlation"
  } else {
    set title "Net Correlation ($design)"
  }
  append title "\nMargin=$margin / Delta=${delta}ns"
  append title "\nEstDly/P2PDly < [expr 1.0 - $margin]"
  append title "\nEstDly/P2PDly > [expr 1.0 + $margin]"
  append title "\nEstimated vs. P2P = Estimated / P2P"
  append title "\nError vs. P2P (%) = 100 * (P2P - Estimated) / P2P"
  append title "\nAbsolute Error = ABS(P2P - Estimated)"
  append title "\nTotal number of paths processed: [llength $paths]"
  append title "\nTotal number of nets processed: $nTotalNets"
  append title "\nTotal number of nets reported in the table: $nNets"
  append title "\nTotal number of nets with ratio within margin: $nWithinMarginNets"
  append title "\nTotal number of nets with absolute error within delta: $nUnderDeltaNets"
  append title "\nTotal number of intra-site nets: $nIntrasiteNets"
  $tbl title $title

  return $tbl
}

proc ::tb::utils::report_net_correlation::get_path_info { path {netlength 0} } {
  if {($path == {})} {
    error " error - no path(s)"
  }
  set rpt [split [report_timing -of $path -no_header -return_string] \n]
  # Create an associative array with the output pins as key and input pins as values
#   array set pathPins [get_pins -quiet -of $path]
  set L [get_pins -quiet -of $path]
  if {[get_property CLASS [get_property STARTPOINT_PIN $path]] == {port}} {
    set L [linsert $L 0 [get_ports [get_property STARTPOINT_PIN $path]]]
  }
  if {[get_property CLASS [get_property ENDPOINT_PIN $path]] == {port}} {
    lappend $L [get_ports [get_property ENDPOINT_PIN $path]]
  }

  # Do not use 'array set' to create associative array due to following bug:
  # Example: L = [list i_top/i_data_path/rx2_dc_i_r_reg[3]/Q i_top/i_data_path/dc_rx2_tp\\.ant_id_reg[3]/D ]
  # The 'array set' command result in 'i_top/i_data_path/dc_rx2_tp\\.ant_id_reg[3]/D' be
  # converted as 'i_top/i_data_path/dc_rx2_tp\.ant_id_reg[3]/D' which changes the pin name.
#   array set pathPins $L
  foreach {el val} $L { set pathPins($el) $val }

  set data [list]
  set SM {init}
  set numSep 0
  set netname {}
  set pinname {}
  set pinrisefall {}
  set pinincrdelay {}
  set pindelay {}
  set netfanout {}
  set nettype {}
  set netincrdelay {}
  set netdelay {}
  for {set i 0} {$i < [llength $rpt]} {incr i} {
    set line [lindex $rpt $i]
    set nextline [lindex $rpt [expr $i+1]]
     switch $SM {
       init {
         if {[regexp {\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-} $line]} {
           incr numSep
         }
         if {$numSep == 2} {
           set SM {main}
         }
       }
       main {
         # Some lines might be splitted in 2 lines for formating reasons:
         #     SLICE_X175Y240       CARRY4 (Prop_carry4_S[1]_CO[2])
         #                                                       0.282     6.157 f  core_u/desegment_u1/svbl_529.svbl_544.svbl_545.freeBlockReadEnable9_0_I_1_CARRY4/CO[2]
         # When this happens, the code below attach the next line to the current one
         if {[regexp {^\s*(\-?[0-9\.]+)\s+(\-?[0-9\.]+)\s+([^\s]+)(\s|$)} $nextline]} {
           append line $nextline
           # Skip next line now
           incr i
         } elseif {[regexp {^\s*(\-?[0-9\.]+)\s+(\-?[0-9\.]+)\s+(r|f)\s+([^\s]+)(\s|$)} $nextline]} {
           append line $nextline
           # Skip next line now
           incr i
         }
         if {[regexp {\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-} $line]} {
           set SM {end}
         } elseif {[regexp {^\s*net\s*\(fo=([0-9]+)\s*,\s*([^\)]+)\s*\)\s*(\-?[0-9\.]+)\s+(\-?[0-9\.]+)\s+([^\s]+)(\s|$)} $line - netfanout nettype netincrdelay netdelay netname]} {
           # Example of net delay:
           #         net (fo=0)                   0.000     3.333    main_clocks_u/BASE_CLOCKS_u/clockMainRefIn_p
           dputs "net:<$netname><$netfanout><$nettype><$netincrdelay><$netdelay>"
           dputs "pinname:<$pinname>"
           set inputpinname {N/A}
           if {[info exists pathPins($pinname)]} {
             set inputpinname $pathPins($pinname)
           }
           dputs "inputpinname:<$inputpinname>"
           lappend data [list [list $pinname $pinrisefall $pinincrdelay $pindelay] [list $netname $netfanout $nettype $netincrdelay $netdelay] $inputpinname ]
           set pinname {NOT_FOUND}
         } elseif {[regexp {^.+\(.+\)\s*(\-?[0-9\.]+)\s+(\-?[0-9\.]+)\s+(r|f)\s+([^\s]+)(\s|$)} $line - pinincrdelay pindelay pinrisefall pinname]} {
           # Example of pin delay:
           #   SLICE_X171Y243       FDRE (Prop_fdre_C_Q)         0.216     4.874 r  core_u/desegment_u1/PUT_FLOW_RAM_u/readData[19]/Q
           #   SLICE_X175Y243                                                    r  core_u/desegment_u1/svbl_529.svbl_544.svbl_545.freeBlockReadEnable9_0_I_18_i_RNO_0/I0
           #   SLICE_X175Y243       LUT5 (Prop_lut5_I0_O)        0.043     5.409 f  core_u/desegment_u1/svbl_529.svbl_544.svbl_545.freeBlockReadEnable9_0_I_18_i_RNO_0/O
           dputs "pin:<$pinname><$pinrisefall><$pinincrdelay><$pindelay>"
         } elseif {[regexp {^.+\s+(r|f)\s+([^\s]+)(\s|$)} $line - pinrisefall pinname]} {
           # Example of pin endpoint:
           #   RAMB36_X9Y21         RAMB36E1                                     r  core_u/policer_u1/rxOctetCnt_i0/count_ram_i0/ram_data_1_ram_data_1_0_2/ADDRBWRADDR
#            puts "pin:<$pinname><$pinrisefall>"
         } else {
         }
       }
       end {
         break
       }
     }
  }
  # The last pin information (endpoint) was not registered since it is not followed by a net
  # So let's do it now
  lappend data [list [list $pinname $pinrisefall {} {}] [list {} {} {} {} {}] {} ]
  # Now add the net length information
  if {$netlength == 1} {
    set data2 [list]
    set length 0.0
    set distances [list]
    for {set i 0} {$i < [expr [llength $data] -1]} {incr i} {
     set obj1 [lindex $data $i]
     set obj2 [lindex $data [expr $i +1]]
     foreach {pindata1 netdata1 inputpindata1} $obj1 { break }
     foreach {pindata2 netdata2 inputpindata2} $obj2 { break }
#       puts "\n pindata1: $pindata1"
#       puts " netdata1: $netdata1"
#       puts " pindata2: $pindata2"
#       puts " netdata2: $netdata2"
      foreach {pinname1 pinrisefall1 pinincrdelay1 pindelay1} $pindata1 { break }
      foreach {netname1 netfanout1 nettype1 netincrdelay1 netdelay1} $netdata1 { break }
      foreach {pinname2 pinrisefall2 pinincrdelay2 pindelay2} $pindata2 { break }
      foreach {netname2 netfanout2 nettype2 netincrdelay2 netdelay2} $netdata2 { break }
      set segmentlength [format {%.2f} [dist_cells [get_cells -quiet -of [get_pins -quiet $pinname1]] [get_cells -quiet -of [get_pins -quiet $pinname2]] ]]
      # If length is an integer (X+Y)
      set segmentlength [scan $segmentlength {%d}]
#       puts "  --> $netname1 : $segmentlength"
      lappend data2 [list [list $pinname1 $pinrisefall1 $pinincrdelay1 $pindelay1] [list $netname1 $segmentlength $netfanout1 $nettype1 $netincrdelay1 $netdelay1] $inputpindata1 ]
      set length [expr $length + $segmentlength]
    }
    lappend data2 [list [list $pinname2 $pinrisefall2 {} {}] [list {} {} {} {} {} {}] {} ]
    # If length is a real (flight line)
#     set length [format {%.2f} $length]
    # If length is an integer (X+Y)
    set length [scan $length {%d}]
    set data $data2
  }
  # Return the results
  return $data
}

proc ::tb::utils::report_net_correlation::dist_sites { site1 site2 } {
  set site1 [get_sites -quiet $site1]
  set site2 [get_sites -quiet $site2]
  if {($site1 == {}) || ($site2 == {})} {
    error " error - empty site(s)"
  }
  set RPM_X1 [get_property -quiet RPM_X $site1]
  set RPM_Y1 [get_property -quiet RPM_Y $site1]
  set RPM_X2 [get_property -quiet RPM_X $site2]
  set RPM_Y2 [get_property -quiet RPM_Y $site2]
  # Fligh line distance
#   set distance [format {%.2f} [expr sqrt( pow(double($RPM_X1) - double($RPM_X2), 2) + pow(double($RPM_Y1) - double($RPM_Y2), 2) )] ]
  # X+Y distance
  set distance [format {%d} [expr abs($RPM_X1 - $RPM_X2) + abs($RPM_Y1 - $RPM_Y2) ] ]
  return $distance
}

proc ::tb::utils::report_net_correlation::dist_tiles { tile1 tile2 } {
  set tile1 [get_tiles -quiet $tile1]
  set tile2 [get_tiles -quiet $tile2]
  if {($tile1 == {}) || ($tile2 == {})} {
    error " error - empty tile(s)"
  }
  set TILE_X1 [get_property -quiet TILE_X $tile1]
  set TILE_Y1 [get_property -quiet TILE_Y $tile1]
  set TILE_X2 [get_property -quiet TILE_X $tile2]
  set TILE_Y2 [get_property -quiet TILE_Y $tile2]
  # X+Y distance
  set distance [format {%d} [expr abs($TILE_X1 - $TILE_X2) + abs($TILE_Y1 - $TILE_Y2) ] ]
  return $distance
}

proc ::tb::utils::report_net_correlation::dist_cells { cell1 cell2 } {
  set cell1 [get_cells -quiet $cell1]
  set cell2 [get_cells -quiet $cell2]
  if {($cell1 == {}) || ($cell2 == {})} {
    error " error - empty cells(s)"
  }
  set site1 [get_property -quiet SITE $cell1]
  set site2 [get_property -quiet SITE $cell2]
  if {($site1 == {}) || ($site2 == {})} {
    error " error - unplaced cells(s)"
  }
#   return [dist_sites $site1 $site2]
  set tile1 [get_tiles -quiet -of $site1]
  set tile2 [get_tiles -quiet -of $site2]
  return [dist_tiles $tile1 $tile2]
}

proc ::tb::utils::report_net_correlation::pin2pintype { pin } {
  if {[catch {set cell [get_cells -quiet -of $pin]} errorstring]} {
    set pin [get_pins -quiet $pin]
    set cell [get_cells -quiet -of $pin
  }
  set cellType [get_property -quiet REF_NAME $cell ]
  if {$cellType == {}} {
    set pinType {<PORT>}
  } else {
    # Check whether the pin is a bus or not
    set pinBusName [get_property -quiet BUS_NAME $pin]
    if {$pinBusName == {}} {
      # The pin is not part of a bus
      set pinType [format {%s/%s} $cellType [get_property -quiet REF_PIN_NAME $pin ] ]
    } else {
      # The pin is part of a bus
      set pinType [format {%s/%s[*]} $cellType $pinBusName]
    }
#     set pinType [format {%s/%s} $cellType [get_property -quiet REF_PIN_NAME $pin ] ]
  }
  return $pinType
}

proc ::tb::utils::report_net_correlation::returnClosestINT {pin} {
  set sitePin [get_site_pins -quiet -of $pin]
  set nodes [get_nodes -quiet -of $sitePin]
  for {set i 0} {$i < 10} {incr i} {
    foreach node $nodes {
      # We don't want to match names such as INT_INTF_R_PCIE4_X57Y153/LOGIC_OUTS_L29
      # but instead INT_X57Y153/INT_NODE_SDQ_40_INT_OUT1
#       if {[regexp {^INT_[0-9A-Z_]*X(\d+)Y(\d+).*} [get_property NAME $node] dum x y]} {}
      if {[regexp {^INT_X(\d+)Y(\d+).*} [get_property NAME $node] dum x y]} {
        return [lindex [split [get_property -quiet NAME $node] /] 0]
      }
    }
    set nodes [get_nodes -quiet -of [get_pips -quiet -of $nodes]]
  }
  return {n/a}
}

proc ::tb::utils::report_net_correlation::dputs {args} {
  variable params
  if {$params(debug)} {
    eval [concat puts $args]
  }
  return -code ok
}

# Example:
#   getFrequencyDistribution [list clk_out2_pll_clrx_2 clk_out2_pll_lnrx_3 clk_out2_pll_lnrx_3 ]
# => {clk_out2_pll_lnrx_3 2} {clk_out2_pll_clrx_2 1}
proc ::tb::utils::report_net_correlation::getFrequencyDistribution {L} {
  catch {unset arr}
  set res [list]
  foreach el $L {
    if {![info exists arr($el)]} { set arr($el) 0 }
    incr arr($el)
  }
  foreach {el num} [array get arr] {
    lappend res [list $el $num]
  }
  set res [lsort -decreasing -real -index 1 [lsort -increasing -dictionary -index 0 $res]]
  return $res
}

# #   set output [concat $output [split [sideBySide [$tbl export -format $params(format)] [$tbl_ export -format $params(format)]] \n] ]
proc ::tb::utils::report_net_correlation::sideBySide {args} {
  # Add a list of tables side-by-side.
  set res [list]
  set length [list]
  set numtables [llength $args]
  catch { unset arr }
  set idx 0
  foreach tbl $args {
    set arr($idx) [split $tbl \n]
    lappend length [llength $arr($idx) ]
    incr idx
  }
  set max [expr max([join $length ,])]
  for {set linenum 0} {$linenum < $max} {incr linenum} {
    set line {}
    for {set idx 0} {$idx < $numtables} {incr idx} {
      set row [lindex $arr($idx) $linenum]
      if {$row == {}} {
        # This happens when tables of different size are being passed as
        # argument
        # If the end of the table has been reached, add empty spaces
        # The number of empty spaces is equal to the length of the first table row
        set row [string repeat { } [string length [lindex $arr($idx) 0]] ]
      }
      append line [format {%s  } $row]
    }
    lappend res $line
  }
  return [join $res \n]
}

# Generate a list of integers
proc ::tb::utils::report_net_correlation::iota {from to} {
  set out [list]
  if {$from <= $to} {
    for {set i $from} {$i <= $to} {incr i}    {lappend out $i}
  } else {
    for {set i $from} {$i >= $to} {incr i -1} {lappend out $i}
  }
  return $out
}

namespace eval ::tb::utils {
  namespace import -force ::tb::utils::report_net_correlation::report_net_correlation
}

namespace eval ::tb {
  namespace import -force ::tb::utils::report_net_correlation
}

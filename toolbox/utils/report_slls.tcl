####################################################################################################
# HEADER_BEGIN
# COPYRIGHT NOTICE
# Copyright 2001-2015 Xilinx Inc. All Rights Reserved.
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
## Description:    Generate a report for SLL nets
##
## Based on code from Frank Mueller and Frederic Revenu
##
########################################################################################

########################################################################################
## 2016.01.20 - Changed the method to load xilinx::designutils to prevent warning        
## 2015.12.10 - Minor change when loading xilinx::designutils to prevent Error message
## 2015.10.08 - Removed dependency to internal package
##            - Fixed typo SSL -> SLL
## 2015.10.05 - Fixed wrong SLL calculation (fmulle)
##              Should now match the post-route reports
## 2015.09.22 - Misc robustness improvements
## 2015.09.17 - Initial release
########################################################################################

# Example of report:
#
#   SLL Summary:
#   ============
#    SLR1->SLR2 0 5 9 35 411 94 259 38 899 446 197 1 
#    SLR0->SLR1 0 60 985 1440 850 454 600 241 823 440 266 0 
#  
#   SLL Details:
#   ============
#  
#    +------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
#    | Detailed SLL Report                                                                                                                                                                                                                |
#    +----------+--------------+---------------+---------------------------+--------+---------------------------------------+------------+--------------------------------+------------+-----------------------------+--------------------+
#    | Location | Clock Region | Laguna Column | Net Name                  | Fanout | Driver Cell                           | Driver SLR | Driver PBlock                  | Loads SLRs | Loads Pblocks               | # Loads w/o Pblock |
#    +----------+--------------+---------------+---------------------------+--------+---------------------------------------+------------+--------------------------------+------------+-----------------------------+--------------------+
#    | Top SLR0 | X0Y4         | 12            | dr0_rdr0_mid_in_1/Q[301]  | 1      | dr0_rdr0_mid_in_1/dataout_r_reg[301]  | SLR1       | pblock_Laguna_slr1_bottom_left | SLR0       | pblock_Laguna_slr0_top_left | 0                  |
#    | Top SLR0 | X0Y4         | 12            | dr0_rdr0_mid_in_1/Q[378]  | 1      | dr0_rdr0_mid_in_1/dataout_r_reg[378]  | SLR1       | pblock_Laguna_slr1_bottom_left | SLR0       | pblock_Laguna_slr0_top_left | 0                  |
#    | Top SLR0 | X0Y4         | 12            | dr0_rdr0_mid_in_1/Q[46]   | 1      | dr0_rdr0_mid_in_1/dataout_r_reg[46]   | SLR1       | pblock_Laguna_slr1_bottom_left | SLR0       | pblock_Laguna_slr0_top_left | 0                  |
#    | Top SLR0 | X0Y4         | 12            | dr0_rdr0_mid_in_1/Q[589]  | 1      | dr0_rdr0_mid_in_1/dataout_r_reg[589]  | SLR1       | pblock_Laguna_slr1_bottom_left | SLR0       | pblock_Laguna_slr0_top_left | 0                  |
#    | Top SLR0 | X0Y4         | 12            | dr0_rdr0_mid_in_1/Q[632]  | 1      | dr0_rdr0_mid_in_1/dataout_r_reg[632]  | SLR1       | pblock_Laguna_slr1_bottom_left | SLR0       | pblock_Laguna_slr0_top_left | 0                  |
#    | Top SLR0 | X0Y4         | 12            | dr0_rdr0_mid_in_1/Q[704]  | 1      | dr0_rdr0_mid_in_1/dataout_r_reg[704]  | SLR1       | pblock_Laguna_slr1_bottom_left | SLR0       | pblock_Laguna_slr0_top_left | 0                  |
#    | Top SLR0 | X0Y4         | 12            | dr0_rdr0_mid_in_1/Q[849]  | 1      | dr0_rdr0_mid_in_1/dataout_r_reg[849]  | SLR1       | pblock_Laguna_slr1_bottom_left | SLR0       | pblock_Laguna_slr0_top_left | 0                  |
#    | Top SLR0 | X0Y4         | 12            | xup_dt1_midflop_1/Q[1020] | 1      | xup_dt1_midflop_1/dataout_r_reg[1020] | SLR1       | pblock_Laguna_slr1_bottom_left | SLR0       | pblock_Laguna_slr0_top_left | 0                  |
#    | Top SLR0 | X0Y4         | 12            | xup_dt1_midflop_1/Q[107]  | 1      | xup_dt1_midflop_1/dataout_r_reg[107]  | SLR1       | pblock_Laguna_slr1_bottom_left | SLR0       | pblock_Laguna_slr0_top_left | 0                  |
#    | Top SLR0 | X0Y4         | 12            | xup_dt1_midflop_1/Q[129]  | 1      | xup_dt1_midflop_1/dataout_r_reg[129]  | SLR1       | pblock_Laguna_slr1_bottom_left | SLR0       | pblock_Laguna_slr0_top_left | 0                  |
#    +------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
#  
#   SLL nets with multiple nodes:
#   =============================
#  
#    +-----------------------------------------------------------------------------------------------------------------------------------------------------------------+
#    | SLL Nets                                                                                                                                                        |
#    +-----------------------------------------------------------------------------------------------------------------------+-----------------------------------------+
#    | Net Name                                                                                                              | Location                                |
#    +-----------------------------------------------------------------------------------------------------------------------+-----------------------------------------+
#    | iclock_reset_ctrl/reset_host                                                                                          | {X1Y4 27} {X2Y9 35} {X4Y4 75} {X4Y9 67} |
#    | iclock_reset_ctrl/reset_sys_tmp                                                                                       | {X2Y9 35} {X3Y4 59}                     |
#    | idfc_top/d0_bp_rx/d0_bp_crc_int                                                                                       | {X3Y4 51} {X3Y9 51}                     |
#    | idfc_top/d1_bp_rx/d1_bp_crc_int                                                                                       | {X3Y4 51} {X3Y9 51}                     |
#    | iefc_top/oobfc_4m_np/efc_crc_int                                                                                      | {X2Y4 43} {X3Y9 51}                     |
#    | iilk_x2x_top0/i1_ilk_tamba_x2x_top/cpu_if_sample_i/cpu_if_to_access_complete_sample/x2x_il1_cpu_if_access_complete    | {X2Y4 43} {X3Y9 51}                     |
#    +-----------------------------------------------------------------------------------------------------------------------------------------------------------------+


# if {[catch {package require prettyTable}]} {
#   lappend auto_path {/home/dpefour/git/scripts/toolbox}
#   package require prettyTable
# }

# Install 'designutils' to access the package for tables
catch {
	if {[lsearch [tclapp::list_apps] {xilinx::designutils}] == -1} {
# 		tclapp::install designutils
		tclapp::load xilinx::designutils
	}
}

namespace eval ::tb {
  namespace export -force report_slls get_sll_nets get_sll_nodes
}

namespace eval ::tb::utils {
  namespace export -force report_slls get_sll_nets get_sll_nodes
}

namespace eval ::tb::utils::report_slls {
  namespace export -force report_slls get_sll_nets get_sll_nodes
  variable version {2016.01.20}
  variable params
  variable output {}
  array set params [list format {table} verbose 0 debug 0]
}

proc ::tb::utils::report_slls::lshift {inputlist} {
  upvar $inputlist argv
  set arg  [lindex $argv 0]
  set argv [lrange $argv 1 end]
  return $arg
}

proc ::tb::utils::report_slls::report_slls {args} {
  variable params
  variable output
  set params(verbose) 0
  set params(debug) 0
  set params(format) {table}
  set valid_clock_regions [get_clock_regions -quiet -of [get_slrs -quiet]]
  set filename {}
  set percent 0
  set details 0
  set returnstring 0
  set error 0
  set help 0
#   if {[llength $args] == 0} {
#     set help 1
#   }
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-f(i(le?)?)?$} -
      {^-file$} {
        set filename [lshift args]
      }
      {^-d(e(t(a(i(ls?)?)?)?)?)?$} -
      {^-details$} {
        set details 1
      }
      {^-p(e(r(c(e(nt?)?)?)?)?)?$} -
      {^-percent$} {
        set percent 1
      }
      {^-r(e(g(i(on?)?)?)?)?$} -
      {^-regions$} {
        set valid_clock_regions [list]
        foreach el [split [lshift args] ,] {
          set valid_clock_regions [concat $valid_clock_regions [expandClockRegions $el]]
        }
        debug { puts " -D- Clock regions: $valid_clock_regions" }
      }
      {^-c(sv?)?$} -
      {^-csv$} {
        set params(format) {csv}
      }
      {^-r(e(t(u(r(n(_(s(t(r(i(ng?)?)?)?)?)?)?)?)?)?)?)?$} -
      {^-return_string$} {
        set returnstring 1
      }
      {^-v(e(r(b(o(se?)?)?)?)?)?$} -
      {^-verbose$} {
        set params(verbose) 1
      }
      {^-debug$} {
        set params(debug) 1
      }
      {^-h(e(lp?)?)?$} -
      {^-help$} {
           set help 1
      }
      default {
            if {[string match "-*" [lindex $name 0]]} {
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
  Usage: report_slls
              [-region <clock_regions>|-r <clock_regions]
              [-file <filename>|-f <filename>]
              [-csv]
              [-details|-d]
              [-percent|-p]
              [-return_string]
              [-verbose|-v]
              [-help|-h]

  Description: Generate report for SLL nets (UltraScale only)

    Use -details to provide net-level information.
    A subset list of clock regions can be specified with -region.
    A range a region can be specified with: XminYmin:XmaxYmax. Multiple
    regions or ranges can be specified using comma between them.

  Example:
     report_slls
     report_slls -file sll_usage.rpt
     report_slls -file sll_usage.csv -csv -percent
     report_slls -details -region X1Y4
     report_slls -details -region X1Y4:X5Y4
     report_slls -details -region X1Y4:X3Y4,X1Y9:X3Y9
} ]
    # HELP -->
    return -code ok
  }

  # Get the current architecture
  set architecture [::tb::utils::report_slls::getArchitecture]
  switch $architecture {
    artix7 -
    kintex7 -
    virtex7 -
    zynq {
      puts " -E- architecture $architecture is not supported."
      incr error
    }
    kintexu -
    kintexum -
    virtexu -
    virtexum {
    }
    default {
      puts " -E- architecture $architecture is not supported."
      incr error
    }
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

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

  set chip_SLRs [get_slrs]
  set bot_SLR [lindex $chip_SLRs 0]
  set top_SLR [lindex $chip_SLRs end]
  array set clock_regions {}
  set sll_nodes [list]
  set lagunaColumns [list]
  set lagunaClockRegions [list]
  set sll_nets [list]
  catch {unset all_nets}

  lappend output {}
  lappend output { SLL Summary:}
  lappend output { ============}

  foreach SLR [lsort -decreasing [lrange $chip_SLRs 0 end-1]] {
    set line {}
#     set clock_regions($SLR) [lsort [get_clock_regions -of $SLR]]
    set clock_regions($SLR) [get_clock_regions -of $SLR]
#     regexp {X(\d*)Y(\d*)} [lindex [lsort $clock_regions($SLR)] 0] all clock_regions_minx($SLR) clock_regions_miny($SLR)
#     regexp {X(\d*)Y(\d*)} [lindex [lsort $clock_regions($SLR)] end] all clock_regions_maxx($SLR) clock_regions_maxy($SLR)
    regexp {X(\d*)Y(\d*)} [lindex [lsort $clock_regions($SLR)] 0] - Xmin Ymin
    regexp {X(\d*)Y(\d*)} [lindex [lsort $clock_regions($SLR)] end] - Xmax Ymax
    set clock_regions_minx($SLR) [min $Xmin $Xmax]
    set clock_regions_maxx($SLR) [max $Xmin $Xmax]
    set clock_regions_miny($SLR) [min $Ymin $Ymax]
    set clock_regions_maxy($SLR) [max $Ymin $Ymax]
    debug { puts -nonewline " -D- top ${SLR}->SLR[expr {[get_property SLR_INDEX $SLR] + 1}] " }
    append line "  ${SLR}->SLR[expr {[get_property SLR_INDEX $SLR] + 1}] "
    for {set x $clock_regions_minx($SLR)} {$x<=$clock_regions_maxx($SLR)} {incr x} {
      set clock_region "X${x}Y$clock_regions_maxy($SLR)"
      if {[lsearch $valid_clock_regions $clock_region] == -1} {
        # Skip the clock region if it is not in the list of clock regions
        # that should be analyzed
        continue
      }
      set all_SLLs($clock_region) [get_nodes -quiet -of [get_tiles -quiet LAGUNA_TILE_X*Y* -of [get_clock_regions -quiet $clock_region]] -regexp -filter {NAME =~ .*UBUMP\d.*}]
      set baseClockRegion [get_property -quiet BASE_CLOCK_REGION [lindex $all_SLLs($clock_region) 0]]
      set tiles [lsort [get_tiles -of $all_SLLs($clock_region)]]
#       regexp {LAGUNA_TILE_X(\d*)Y(\d*)} [lindex $tiles 0] - CLB_col_min LagunaY
#       regexp {LAGUNA_TILE_X(\d*)Y(\d*)} [lindex $tiles end] - CLB_col_max LagunaY
      regexp {LAGUNA_TILE_X(\d*)Y(\d*)} [lindex $tiles 0] - Xmin LagunaY
      regexp {LAGUNA_TILE_X(\d*)Y(\d*)} [lindex $tiles end] - Xmax LagunaY
      set CLB_col_min [min $Xmin $Xmax]
      set CLB_col_max [max $Xmin $Xmax]
      set used_SLLs($SLR:$clock_region:$CLB_col_min) [get_nodes -quiet -of [get_nets -quiet -of [get_nodes -of [get_tiles -quiet LAGUNA_TILE_X${CLB_col_min}Y* -of [get_clock_regions -quiet $clock_region]] -regexp -filter {NAME =~ .*UBUMP\d.*}]] -filter BASE_CLOCK_REGION=~$baseClockRegion&&NAME=~LAGUNA_TILE_X${CLB_col_min}Y*UBUMP*]
      set used_SLLs($SLR:$clock_region:$CLB_col_max) [get_nodes -quiet -of [get_nets -quiet -of [get_nodes -of [get_tiles -quiet LAGUNA_TILE_X${CLB_col_max}Y* -of [get_clock_regions -quiet $clock_region]] -regexp -filter {NAME =~ .*UBUMP\d.*}]] -filter BASE_CLOCK_REGION=~$baseClockRegion&&NAME=~LAGUNA_TILE_X${CLB_col_max}Y*UBUMP*]

      set sllNets($SLR:$clock_region:$CLB_col_min) [get_nets -quiet -of $used_SLLs($SLR:$clock_region:$CLB_col_min)]
      set sllNets($SLR:$clock_region:$CLB_col_max) [get_nets -quiet -of $used_SLLs($SLR:$clock_region:$CLB_col_max)]

      lappend lagunaColumns $CLB_col_min
      lappend lagunaColumns $CLB_col_max
      lappend lagunaClockRegions $clock_region

#       foreach el $used_SLLs($SLR:$clock_region:$CLB_col_min) { lappend sll_nodes $el }
#       foreach el $used_SLLs($SLR:$clock_region:$CLB_col_max) { lappend sll_nodes $el }
#       foreach el $sllNets($SLR:$clock_region:$CLB_col_min) { lappend sll_nets $el }
#       foreach el $sllNets($SLR:$clock_region:$CLB_col_max) { lappend sll_nets $el }
      
      foreach el $sllNets($SLR:$clock_region:$CLB_col_min) { lappend all_nets($el) [list $clock_region $CLB_col_min] }
      foreach el $sllNets($SLR:$clock_region:$CLB_col_max) { lappend all_nets($el) [list $clock_region $CLB_col_max] }
      
      if {$percent} {
        debug {
          puts -nonewline "[format "%.2f%%" [expr {100.0 * [llength $used_SLLs($SLR:$clock_region:$CLB_col_min)] / [llength $all_SLLs($clock_region)] * 2} ]] "
          puts -nonewline "[format "%.2f%%" [expr {100.0 * [llength $used_SLLs($SLR:$clock_region:$CLB_col_max)] / [llength $all_SLLs($clock_region)] * 2} ]] "
        }
        append line "[format "%.2f%%" [expr {100.0 * [llength $used_SLLs($SLR:$clock_region:$CLB_col_min)] / [llength $all_SLLs($clock_region)] * 2} ]] "
        append line "[format "%.2f%%" [expr {100.0 * [llength $used_SLLs($SLR:$clock_region:$CLB_col_max)] / [llength $all_SLLs($clock_region)] * 2} ]] "
      } else {
        debug {
          puts -nonewline "[llength $used_SLLs($SLR:$clock_region:$CLB_col_min)] "
          puts -nonewline "[llength $used_SLLs($SLR:$clock_region:$CLB_col_max)] "
        }
        append line "[llength $used_SLLs($SLR:$clock_region:$CLB_col_min)] "
        append line "[llength $used_SLLs($SLR:$clock_region:$CLB_col_max)] "
      }
    }
    debug {
      puts ""
    }
    lappend output $line
  }

  if {$details} {
    set tbl [::tclapp::xilinx::designutils::prettyTable {Detailed SLL Report}]
    $tbl config -indent 2
    $tbl header [list {Location} {Clock Region} {Laguna Column} {Net Name} {Fanout} \
                      {Driver Cell} {Driver SLR} {Driver PBlock} \
                      {Loads SLRs} {Loads Pblocks} {# Loads w/o Pblock} \
                ]

    set lagunaColumns [lsort -integer -unique $lagunaColumns]
    set lagunaClockRegions [lsort -unique $lagunaClockRegions]
    foreach SLR [lrange $chip_SLRs 0 end-1] {
      debug {
        puts -nonewline " -D- Processing $SLR"
      }
      foreach clock_region $lagunaClockRegions {
        debug {
          puts -nonewline " $clock_region"
        }
        set nets [list]
        foreach key [lsort [array names sllNets $SLR:$clock_region:*]] {
          foreach el $sllNets($key) { lappend nets $el }
        }
        if {[llength $nets] != 0} {
          foreach net [lsort $nets] {
            set driverPin [get_pins -quiet -leaf -of $net -filter {DIRECTION == OUT}]
            set driver [get_cells -quiet -of $driverPin]
            set loads [get_cells -quiet -of [get_pins -quiet -leaf -of $net -filter {DIRECTION == IN}]]
            set spPblock [get_pblocks -quiet -of $driver]
            set spSLR [get_slrs -quiet -of $driver]
            set epPblock [list]
            set epSLR [list]
            set fanout [expr [get_property -quiet FLAT_PIN_COUNT $net] -1]
            foreach load $loads {
              set pblock [get_pblocks -quiet -of $load]
              if {$pblock != {}} {
                lappend epPblock $pblock
              }
#               lappend epSLR [get_slrs -quiet -of $load]
            }
            set epSLR [get_slrs -quiet -of $loads]
            # Get the list of laguna column(s) for that net and  that clock region
            set lagunaCol {}
            foreach el $all_nets($net) {
              # Extract clock region and laguna column
              foreach {region col} $el { break }
              if {$region == $clock_region} { lappend lagunaCol $col }
            }
            $tbl addrow [list "Top $SLR" $clock_region [lsort $lagunaCol] $net $fanout \
                              $driver $spSLR $spPblock \
                              [lsort -unique $epSLR] [lsort -unique $epPblock] [expr [llength $loads] - [llength $epPblock]] ]
          }
        }
      }
      debug {
        puts ""
      }
    }

    lappend output {}
    lappend output { SLL Details:}
    lappend output { ============}
    lappend output {}
    set output [concat $output [split [$tbl export -format $params(format)] \n] ]
    catch { $tbl destroy }

    lappend output {}
#     lappend output { SLL Nets with Multiple Nodes:}
    lappend output { Nets with Multiple SLL Nodes:}
    lappend output { =============================}
    lappend output {}
    set nets [list]
    foreach net [lsort [array names all_nets]] {
      if {[llength $all_nets($net)] != 1} {
        lappend nets $net
      }
    }
    if {[llength $nets]} {
      set tbl [::tclapp::xilinx::designutils::prettyTable {SLL Nets}]
      $tbl config -indent 2
      $tbl header [list {Net Name} {Location} ]
      foreach net $nets {
        $tbl addrow [list $net [lsort $all_nets($net)]]
      }
      set output [concat $output [split [$tbl export -format $params(format)] \n] ]
      catch { $tbl destroy }
    }

  }

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

  set stopTime [clock seconds]
  puts " -I- report_slls done in [expr $stopTime - $startTime] seconds"

  if {$filename != {}} {
    set FH [open $filename {w}]
    puts $FH "# -------------------------------------------------------------------"
    puts $FH [format {# Created on %s with report_slls} [clock format [clock seconds]] ]
    puts $FH "# -------------------------------------------------------------------\n"
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

proc ::tb::utils::report_slls::get_sll_nets { {regions {}} } {
  set nets [get_nets -quiet -of [get_sll_nodes $regions]]
  return $nets
}

proc ::tb::utils::report_slls::get_sll_nodes { {regions {}} } {
  set error 0
  # Get the current architecture
  set architecture [::tb::utils::report_slls::getArchitecture]
  switch $architecture {
    artix7 -
    kintex7 -
    virtex7 -
    zynq {
      puts " -E- architecture $architecture is not supported."
      incr error
    }
    kintexu -
    kintexum -
    virtexu -
    virtexum {
    }
    default {
      puts " -E- architecture $architecture is not supported."
      incr error
    }
  }
  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }
  if {$regions == {}} {
    set regions [get_clock_regions -quiet -of [get_slrs -quiet]]
  } else {
    set regions [expandClockRegions $regions]
  }
  debug { puts " -D- Regions: $regions" }

  set chip_SLRs [get_slrs]
  set bot_SLR [lindex $chip_SLRs 0]
  set top_SLR [lindex $chip_SLRs end]
  array set clock_regions {}
  set sll_nodes [list]
#   set ssl_nets [list]

  foreach SLR [lsort -decreasing [lrange $chip_SLRs 0 end-1]] {
    set clock_regions($SLR) [get_clock_regions -of $SLR]
#     regexp {X(\d*)Y(\d*)} [lindex [lsort $clock_regions($SLR)] 0] all clock_regions_minx($SLR) clock_regions_miny($SLR)
#     regexp {X(\d*)Y(\d*)} [lindex [lsort $clock_regions($SLR)] end] all clock_regions_maxx($SLR) clock_regions_maxy($SLR)
    regexp {X(\d*)Y(\d*)} [lindex [lsort $clock_regions($SLR)] 0] - Xmin Ymin
    regexp {X(\d*)Y(\d*)} [lindex [lsort $clock_regions($SLR)] end] - Xmax Ymax
    set clock_regions_minx($SLR) [min $Xmin $Xmax]
    set clock_regions_maxx($SLR) [max $Xmin $Xmax]
    set clock_regions_miny($SLR) [min $Ymin $Ymax]
    set clock_regions_maxy($SLR) [max $Ymin $Ymax]
    for {set x $clock_regions_minx($SLR)} {$x<=$clock_regions_maxx($SLR)} {incr x} {
      set clock_region "X${x}Y$clock_regions_maxy($SLR)"
      if {[lsearch $regions $clock_region] == -1} {
        # Skip the clock region if it is not in the list of clock regions
        # that should be analyzed
        continue
      }
      set all_SLLs($clock_region) [get_nodes -quiet -of [get_tiles -quiet LAGUNA_TILE_X*Y* -of [get_clock_regions -quiet $clock_region]] -regexp -filter {NAME =~ .*UBUMP\d.*}]
      set baseClockRegion [get_property -quiet BASE_CLOCK_REGION [lindex $all_SLLs($clock_region) 0]]
      set tiles [lsort [get_tiles -of $all_SLLs($clock_region)]]
#       regexp {LAGUNA_TILE_X(\d*)Y(\d*)} [lindex $tiles 0] all CLB_col_min LagunaY
#       regexp {LAGUNA_TILE_X(\d*)Y(\d*)} [lindex $tiles end] all CLB_col_max LagunaY
      regexp {LAGUNA_TILE_X(\d*)Y(\d*)} [lindex $tiles 0] - Xmin LagunaY
      regexp {LAGUNA_TILE_X(\d*)Y(\d*)} [lindex $tiles end] - Xmax LagunaY
      set CLB_col_min [min $Xmin $Xmax]
      set CLB_col_max [max $Xmin $Xmax]
      set used_SLLs($SLR:$clock_region:$CLB_col_min) [get_nodes -quiet -of [get_nets -quiet -of [get_nodes -of [get_tiles -quiet LAGUNA_TILE_X${CLB_col_min}Y* -of [get_clock_regions -quiet $clock_region]] -regexp -filter {NAME =~ .*UBUMP\d.*}]] -filter BASE_CLOCK_REGION=~$baseClockRegion&&NAME=~LAGUNA_TILE_X${CLB_col_min}Y*UBUMP*]
      set used_SLLs($SLR:$clock_region:$CLB_col_max) [get_nodes -quiet -of [get_nets -quiet -of [get_nodes -of [get_tiles -quiet LAGUNA_TILE_X${CLB_col_max}Y* -of [get_clock_regions -quiet $clock_region]] -regexp -filter {NAME =~ .*UBUMP\d.*}]] -filter BASE_CLOCK_REGION=~$baseClockRegion&&NAME=~LAGUNA_TILE_X${CLB_col_max}Y*UBUMP*]
#       set sllNets($SLR:$clock_region:$CLB_col_min) [get_nets -quiet -of $used_SLLs($SLR:$clock_region:$CLB_col_min)]
#       set sllNets($SLR:$clock_region:$CLB_col_max) [get_nets -quiet -of $used_SLLs($SLR:$clock_region:$CLB_col_max)]
      foreach el $used_SLLs($SLR:$clock_region:$CLB_col_min) { lappend sll_nodes $el }
      foreach el $used_SLLs($SLR:$clock_region:$CLB_col_max) { lappend sll_nodes $el }
#       foreach el $sllNets($SLR:$clock_region:$CLB_col_min) { lappend sll_nets $el }
#       foreach el $sllNets($SLR:$clock_region:$CLB_col_max) { lappend sll_nets $el }
    }
  }
#   return $sll_nets
  return $sll_nodes
}

proc ::tb::utils::report_slls::max {x y} {expr {$x>$y?$x:$y}}
proc ::tb::utils::report_slls::min {x y} {expr {$x<$y? $x:$y}}

proc ::tb::utils::report_slls::expandClockRegions { pattern } {
  if {[regexp {^X(\d*)Y(\d*)$} $pattern]} {
    # Single clock region
    return $pattern
  }
  if {[regexp {^X(\d*)Y(\d*)\:X(\d*)Y(\d*)$} $pattern - Xmin Ymin Xmax Ymax]} {
    # Range of clock regions
#     puts "$Xmin $Ymin $Xmax $Ymax"
    set regions [list]
    for { set X [min $Xmin $Xmax] } { $X <= [max $Xmin $Xmax] } { incr X } {
      for { set Y [min $Ymin $Ymax] } { $Y <= [max $Ymin $Ymax] } { incr Y } {
        lappend regions "X${X}Y${Y}"
      }
    }
    return $regions
  }
  # Unrecognized pattern
  return $pattern
}

proc ::tb::utils::report_slls::getArchitecture {} {
  # Example of returned value: artix7 diabloevalarch elbertevalarch kintex7 kintexu kintexum olyevalarch v7evalarch virtex7 virtex9 virtexu virtexum zynq zynque ...
  #    7-Serie    : artix7 kintex7 virtex7 zynq
  #    UltraScale : kintexu kintexum virtexu virtexum
  #    Diablo (?) : virtex9 virtexum zynque
  return [get_property -quiet ARCHITECTURE [get_property -quiet PART [current_project]]]
}

#------------------------------------------------------------------------
# ::tb::utils::report_slls::debug
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
#------------------------------------------------------------------------
proc ::tb::utils::report_slls::debug {body} {
  variable params
  if {$params(debug)} {
    uplevel 1 [list eval $body]
  }
  return -code ok
}

namespace eval ::tb::utils {
  namespace import -force ::tb::utils::report_slls::report_slls
  namespace import -force ::tb::utils::report_slls::get_sll_nets
  namespace import -force ::tb::utils::report_slls::get_sll_nodes
}

namespace eval ::tb {
  namespace import -force ::tb::utils::report_slls
  namespace import -force ::tb::utils::get_sll_nets
  namespace import -force ::tb::utils::get_sll_nodes
}

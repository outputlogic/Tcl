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
## Description:    Generate a report for a list of primitive cells
##
########################################################################################

########################################################################################
## 2015.09.25 - Initial release
########################################################################################

# Example of report:
#
#  vivado% tb::report_cells -sites {SLICE_X132Y625:SLICE_X136Y272} -file cells.rpt -expand 3 -details -fanout -max_cell_fanout
#   
#    -I- Skipping cell 'irdr_tops/rdr_top_i0/rdr_eng0_i/GEN_ARB_DOWN.rdr_arb_top_down_i/csm_dat_last[0][1023]_i_1' (LUT2) from max fanout limit (1025)
#    -I- Skipping cell 'irdr_tops/rdr_top_i0/rdr_eng0_i/GEN_ARB_DOWN.rdr_arb_top_down_i/csm_dat_last[1][1023]_i_1' (LUT2) from max fanout limit (1025)
#     +-----------------------------------------------------------------------------------------------------------------+
#     | Cell Paths Distribution (ORIG_REF_NAME)                                                                         |
#     | Number of leaf cells: 46058                                                                                     |
#     | Average fanout for non-clock pins: 3.24                                                                         |
#     +------------------------------------------------------------------------------+-------+--------+-----------------+
#     | Hierarchical Paths                                                           | #     | %      | Avg Cell Fanout |
#     +------------------------------------------------------------------------------+-------+--------+-----------------+
#     | rdr_tops -> rdr_top -> rdr_eng -> rdr_arb_top_down                           | 43413 | 94.26% | 3.41            |
#     | rdr_tops -> rdr_top -> rdr_eng -> rdr_arb_top_down -> rdr_infifo_512x1088    | 1267  | 2.75%  | 2.45            |
#     | rdr_tops -> rdr_top -> rdr_eng -> rdr_arb_top_down -> rdr_dpmem_generic      | 1040  | 2.26%  | 1.92            |
#     | rdr_tops -> rdr_top -> rdr_eng -> rdr_arb_top_down -> flop_array_binary_fifo | 273   | 0.59%  | 2.19            |
#     | rdr_tops -> rdr_top -> rdr_eng -> rdr_arb_top_down -> rdr_dist_mem_192x16    | 54    | 0.12%  | 2.98            |
#     | rdr_tops -> rdr_top -> rdr_eng -> rdr_arb_top_down -> fifo_rd_ctrl           | 11    | 0.02%  | 4.27            |
#     +------------------------------------------------------------------------------+-------+--------+-----------------+
#     +----------------------------+
#     | Primitive Distribution     |
#     +-----------+-------+--------+
#     | Ref Names | #     | %      |
#     +-----------+-------+--------+
#     | FDRE      | 18363 | 39.87% |
#     | LUT6      | 11442 | 24.84% |
#     | LUT5      | 4935  | 10.71% |
#     | LUT3      | 4454  | 9.67%  |
#     | LUT4      | 3845  | 8.35%  |
#     | MUXF7     | 2592  | 5.63%  |
#     | MUXF8     | 199   | 0.43%  |
#     | LUT2      | 142   | 0.31%  |
#     | RAMB36E2  | 33    | 0.07%  |
#     | SRL16E    | 26    | 0.06%  |
#     | LUT1      | 11    | 0.02%  |
#     | CARRY8    | 10    | 0.02%  |
#     | FDSE      | 6     | 0.01%  |
#     +-----------+-------+--------+
#     +----------------------------+
#     | Primitive Group Distribution |
#     +-----------+-------+--------+
#     | Ref Names | #     | %      |
#     +-----------+-------+--------+
#     | CLB       | 27656 | 60.05% |
#     | REGISTER  | 18369 | 39.88% |
#     | BLOCKRAM  | 33    | 0.07%  |
#     +-----------+-------+--------+
#     +----------------------------+
#     | Primitive Sub-Group Distribution |
#     +-----------+-------+--------+
#     | Ref Names | #     | %      |
#     +-----------+-------+--------+
#     | LUT       | 24829 | 53.91% |
#     | SDR       | 18369 | 39.88% |
#     | MUXF      | 2791  | 6.06%  |
#     | BRAM      | 33    | 0.07%  |
#     | SRL       | 26    | 0.06%  |
#     | CARRY     | 10    | 0.02%  |
#     +-----------+-------+--------+

if {[catch {package require prettyTable}]} {
  lappend auto_path {/home/dpefour/git/scripts/toolbox}
  package require prettyTable
}

namespace eval ::tb {
  namespace export -force report_cells
}

namespace eval ::tb::utils {
  namespace export -force report_cells
}

namespace eval ::tb::utils::report_cells {
  namespace export -force report_cells
  variable version {2015.09.25}
  variable params
  variable output {}
  variable db
  catch { unset db }
  array set params [list format {table} verbose 0 debug 0]
}

proc ::tb::utils::report_cells::lshift {inputlist} {
  upvar $inputlist argv
  set arg  [lindex $argv 0]
  set argv [lrange $argv 1 end]
  return $arg
}

proc ::tb::utils::report_cells::report_cells {args} {
  variable params
  variable output
  variable db
  set params(verbose) 0
  set params(debug) 0
  set params(format) {table}
  set cells [list]
#   set expand -1
  set expand 0
  set maxrow -1
  set filename {}
  set details 0
  set showAvgFanout 0
  set limitCellMaxFanout -1
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
      {^-fa(n(o(ut?)?)?)?$} -
      {^-fanout$} {
        set showAvgFanout 1
      }
      {^-m(a(x(_(c(e(l(l(_(f(a(n(o(ut?)?)?)?)?)?)?)?)?)?)?)?)?)?$} -
      {^-max_cell_fanout$} {
        set limitCellMaxFanout [lshift args]
      }
      {^-e(x(p(a(nd?)?)?)?)?$} -
      {^-expand$} {
        set expand [lshift args]
      }
      {^-m(a(x(r(ow?)?)?)?)?$} -
      {^-maxrow$} {
        set maxrow [lshift args]
      }
      {^-r(e(g(i(on?)?)?)?)?$} -
      {^-region$} -
      {^-regions$} {
        set pattern [lshift args]
        set regions [get_clock_regions -quiet [expandPattern $pattern]]
        if {[llength $regions] == 0} {
          puts " -W- pattern '$pattern' does not match any clock region"
        } else {
          foreach el [get_cells -quiet -of $regions] {
            lappend cells $el
          }
        }
      }
      {^-s(l(i(c(es?)?)?)?)?$} -
      {^-slices$} -
      {^-s(i(te?)?)?$} -
      {^-site$} -
      {^-sites$} {
        set pattern [lshift args]
        set sites [get_sites -quiet [expandPattern $pattern]]
        if {[llength $sites] == 0} {
          puts " -W- pattern '$pattern' does not match any site"
        } else {
          foreach el [get_cells -quiet -of $sites] {
            lappend cells $el
          }
        }
      }
      {^-c(e(l(ls?)?)?)?$} -
      {^-cells$} {
        foreach el [lshift args] {
          lappend cells $el
        }
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
      {^-rebuild$} {
        # Force rebuilding the internal database
        catch {unset db}
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
#           puts " -E- option '$name' is not a valid option."
#           incr error
          # Default are expected to be cells
          foreach el $name {
            lappend cells $el
          }
        }
      }
    }
  }

  if {$help} {
    puts [format {
  Usage: report_cells
              [<list_of_cells>]
              [-cells <list_of_cells>|-c <list_of_cells>]
              [-regions <range>|-r <range>]
              [-sites <range>|-s <range>]
              [-details|-d]
              [-expand <num>|-e <num>]]
              [-fanout]
              [-max_cell_fanout <num>]
              [-maxrow <num>]
              [-file <filename>|-f <filename>]
              [-csv]
              [-return_string]
              [-verbose|-v]
              [-help|-h]

  Description: Generate report for list of primitive cells

    Use -details to provide additional information.
    Use -regions to provide a range of region(s).
    Use -sites to provide a range of site(s)/slice(s).
    Use -maxrow to reduce the number of reported rows in the 
    cells ditribution table.

    Use -fanout to report average fanout (RUNTIME INTENSIVE).
    Use -max_cell_fanout in conjunction with -fanout to skip cells with
    a fanout above the specified threshold. For example, cells driving
    reset nets.

  Example:
     report_cells [get_selected_objects]
     report_cells -cells [get_cells -of [get_clock_region {X0Y4}]]
     report_cells -cells $cells -file report.rpt
     report_cells -cells $cells -file report.csv -csv -details -expand 2
     report_cells -cells $cells -fanout -max_cell_fanout 500
     report_cells -regions {X0Y0:X1Y2} -file report.rpt
     report_cells -sites {SLICE_X19Y300:SLICE_X20Y350} -file report.rpt
} ]
    # HELP -->
    return -code ok
  }

  # Get the current architecture
  set architecture [::tb::utils::report_cells::getArchitecture]
  switch $architecture {
    artix7 -
    kintex7 -
    virtex7 -
    zynq -
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

  # Only keep primitives which are not macros
  set cells [filter -quiet [get_cells -quiet $cells] {IS_PRIMITIVE && (PRIMITIVE_LEVEL != MACRO) && (REF_NAME != GND) && (REF_NAME != VCC)}]
  if {[llength $cells] == 0} {
    puts " -E- no primitive cell(s). Use -cells to specify list of cells"
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

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

  debug {
    puts " -D- #cells: [llength $cells]"
  }
  if {[llength [array names db]] == 0} {
    # It should be a one time process unless the hierarchical modules change in the netlist
    buildDB
  }

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

  # Calculate the average fanout for non-clock output pins
  set opins [get_pins -quiet -of $cells -filter {!IS_CLOCK && DIRECTION == OUT && IS_CONNECTED && IS_LEAF}]
  set nets [get_nets -quiet -of $opins]
  set avgFanoutAllCells {N/A}
  if {[llength $nets] != 0} {
    set totalFlatPinCount [expr [join [get_property -quiet FLAT_PIN_COUNT $nets] +] ]
    set avgFanoutAllCells [format {%.2f} [expr (1.0 * ($totalFlatPinCount - [llength $opins])) / [llength $opins]]]
#     lappend output "  Average fanout for non-clock pins: $avgFanoutAllCells"
  }

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

#   catch {unset hierPaths}
  set hierPaths [list]
  catch {unset fanout}
  foreach cell $cells parent [get_property -quiet PARENT $cells] {
    set path [getHierPath $parent]
    if {($path == {}) || ($path == {{}})} {
      # For cells at top-level
      set path {<TOP_LEVEL>}
    }
    lappend hierPaths $path

    if {$showAvgFanout} {
      # Calculate total fanout for this cell
      set opins [get_pins -quiet -of $cell -filter {!IS_CLOCK && DIRECTION == OUT && IS_CONNECTED && IS_LEAF}]
      set nets [get_nets -quiet -of $opins]
      set avgFanout {N/A}
      if {[llength $nets] != 0} {
        set totalFlatPinCount [expr [join [get_property -quiet FLAT_PIN_COUNT $nets] +] ]
        if {($limitCellMaxFanout != -1) && ($totalFlatPinCount >= $limitCellMaxFanout)} {
          # Skip cell for average fanout computation
          puts " -I- Skipping cell '$cell' ([get_property -quiet REF_NAME $cell]) from max fanout limit ($totalFlatPinCount)"
          lappend output " -I- Skipping cell '$cell' ([get_property -quiet REF_NAME $cell]) from max fanout limit ($totalFlatPinCount)"
          continue
        } else {
          if {$totalFlatPinCount > 400} {
            puts " -W- cell '$cell' ([get_property -quiet REF_NAME $cell]) has a high fanout of $totalFlatPinCount. Consider using -max_cell_fanout to remove outliers for the fanout computation."
            lappend output " -W- cell '$cell' ([get_property -quiet REF_NAME $cell]) has a high fanout of $totalFlatPinCount. Consider using -max_cell_fanout to remove outliers for the fanout computation."
          }
        }
        # Save the average pin fanout of the cell
#         lappend fanout($path) [expr ((1.0 * $totalFlatPinCount) - [llength $opins]) / [llength $opins] ]
        # Save the total fanout for the cell for all the output pins
        lappend fanout($path) [expr $totalFlatPinCount - [llength $opins] ]
        set avgFanout $fanout($path)
      }
    }

  }

  if {$expand == -1} {
    set L $hierPaths
  } else {
    catch { unset tmpfanout }
    foreach el $hierPaths {
      set newpath [lrange $el 0 $expand]
      lappend L $newpath
      # The data structure 'fanout' needs to be updated since the full cell path
      # is trunctated into a shorter one
      if {[info exist fanout($el)]} {
        if {[info exists tmpfanout($newpath)]} {
          set tmpfanout($newpath) [concat $tmpfanout($newpath) $fanout($el)]
        } else {
          set tmpfanout($newpath) $fanout($el)
        }
        # Since 'fanout($el)' already includes the list of fanouts for all cells of '$el',
        # the entry 'fanout($el)' is removed so that it is not processed multiple times
        unset fanout($el)
      } else {
        # If -fanout has been used, we should not reach this line.
        # However, if -details has not been used, then 'fanout' does not exist
        # and this line is reached.
      }
    }
    catch { unset fanout }
    array set fanout [array get tmpfanout]
    catch { unset tmpfanout }
  }

#   set tbl [::tb::prettyTable "Cell Paths Distribution (ORIG_REF_NAME) (#[llength $hierPaths])" ]
  set tbl [::tb::prettyTable "Cell Paths Distribution (ORIG_REF_NAME)\nNumber of leaf cells: [llength $hierPaths]\nAverage fanout for non-clock pins: $avgFanoutAllCells" ]
  $tbl configure -indent 2
  if {$showAvgFanout} {
    $tbl header [list {Hierarchical Paths} {#} {%} {Avg Cell Fanout}]
  } else {
    $tbl header [list {Hierarchical Paths} {#} {%}]
  }

  set L [getFrequencyDistribution $L]
  set num 0
  foreach el $L {
    foreach {path count} $el { break }
    if {[info exists fanout($path)]} {
      set totalFlatPinCount [expr [join [concat $fanout($path) 0] +] ]
      set avgFanout [format {%.2f} [expr (1.0 * $totalFlatPinCount) / [llength $fanout($path)]]]
    } else {
      set avgFanout {N/A}
    }
    if {$showAvgFanout} {
      $tbl addrow [list [join $path { -> }] \
                      $count \
                      [format {%.2f%%} [expr 100.0 * (double($count) / [llength $hierPaths])] ] \
                      $avgFanout \
                ]
    } else {
      $tbl addrow [list [join $path { -> }] \
                      $count \
                      [format {%.2f%%} [expr 100.0 * (double($count) / [llength $hierPaths])] ] \
                ]
    }
    incr num
    if {($maxrow != -1) && ($num >= $maxrow)} {
      $tbl addrow [list {...} {...} {...}]
      break
    }
  }

  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

  if {$details} {
    set tbl [::tb::prettyTable {Primitive Distribution}]
    $tbl config -indent 2
    $tbl header [list {Ref Names} {#} {%}]

    set L [list]
    foreach cell $cells ref [get_property -quiet REF_NAME $cells] {
      lappend L $ref
    }

    set L [getFrequencyDistribution $L]
    foreach el $L {
      foreach {ref count} $el { break }
      $tbl addrow [list $ref \
                        $count \
                        [format {%.2f%%} [expr 100.0 * (double($count) / [llength $cells])] ] \
                  ]
    }

    set output [concat $output [split [$tbl export -format $params(format)] \n] ]
    catch { $tbl destroy }
  }

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

  if {$details} {
    set tbl [::tb::prettyTable {Primitive Group Distribution}]
    $tbl config -indent 2
    $tbl header [list {Ref Names} {#} {%}]

    set L [list]
    foreach cell $cells ref [get_property -quiet PRIMITIVE_GROUP $cells] {
      lappend L $ref
    }

    set L [getFrequencyDistribution $L]
    foreach el $L {
      foreach {ref count} $el { break }
      $tbl addrow [list $ref \
                        $count \
                        [format {%.2f%%} [expr 100.0 * (double($count) / [llength $cells])] ] \
                  ]
    }

    set output [concat $output [split [$tbl export -format $params(format)] \n] ]
    catch { $tbl destroy }
  }

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

  if {$details} {
    set tbl [::tb::prettyTable {Primitive Sub-Group Distribution}]
    $tbl config -indent 2
    $tbl header [list {Ref Names} {#} {%}]

    set L [list]
    foreach cell $cells ref [get_property -quiet PRIMITIVE_SUBGROUP $cells] {
      lappend L $ref
    }

    set L [getFrequencyDistribution $L]
    foreach el $L {
      foreach {ref count} $el { break }
      $tbl addrow [list $ref \
                        $count \
                        [format {%.2f%%} [expr 100.0 * (double($count) / [llength $cells])] ] \
                  ]
    }

    set output [concat $output [split [$tbl export -format $params(format)] \n] ]
    catch { $tbl destroy }
  }

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

  set stopTime [clock seconds]
  puts " -I- report_cells completed in [expr $stopTime - $startTime] seconds"

  if {$filename != {}} {
    set FH [open $filename {w}]
    puts $FH "# -------------------------------------------------------------------"
    puts $FH [format {# Created on %s with report_cells} [clock format [clock seconds]] ]
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

proc ::tb::utils::report_cells::max {x y} {expr {$x>$y?$x:$y}}
proc ::tb::utils::report_cells::min {x y} {expr {$x<$y? $x:$y}}

proc ::tb::utils::report_cells::expandPattern { pattern } {
  if {[regexp {^([^\:]*)X(\d*)Y(\d*)$} $pattern]} {
    # Single element (e.g clock region)
    return $pattern
  }
  if {[regexp {^(.*)X(\d*)Y(\d*)\:(.*)X(\d*)Y(\d*)$} $pattern - prefix Xmin Ymin - Xmax Ymax]} {
    # Range of elements (e.g clock regions)
#     puts "$Xmin $Ymin $Xmax $Ymax"
    set regions [list]
    for { set X [min $Xmin $Xmax] } { $X <= [max $Xmin $Xmax] } { incr X } {
      for { set Y [min $Ymin $Ymax] } { $Y <= [max $Ymin $Ymax] } { incr Y } {
        lappend regions "${prefix}X${X}Y${Y}"
      }
    }
    return $regions
  }
  # Unrecognized pattern
  return $pattern
}

# Example:
#   getFrequencyDistribution [list clk_out2_pll_clrx_2 clk_out2_pll_lnrx_3 clk_out2_pll_lnrx_3 ]
# => {clk_out2_pll_lnrx_3 2} {clk_out2_pll_clrx_2 1}
proc ::tb::utils::report_cells::getFrequencyDistribution {L} {
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

proc ::tb::utils::report_cells::getArchitecture {} {
  # Example of returned value: artix7 diabloevalarch elbertevalarch kintex7 kintexu kintexum olyevalarch v7evalarch virtex7 virtex9 virtexu virtexum zynq zynque ...
  #    7-Serie    : artix7 kintex7 virtex7 zynq
  #    UltraScale : kintexu kintexum virtexu virtexum
  #    Diablo (?) : virtex9 virtexum zynque
  return [get_property -quiet ARCHITECTURE [get_property -quiet PART [current_project]]]
}

# Build an internal data structure that save the parent and REF_NAME/ORIG_REF_NAME information of
# all hierarchical cells and macros
proc ::tb::utils::report_cells::buildDB { {pattern {}} } {
  variable db
  catch { unset db }
  set startTime [clock seconds]
  if {$pattern != {}} {
    # Keep only macro-level cells and hierarchical cells
    set cells [get_cells -quiet -hier -filter [format {(NAME =~ %s/*) && (!IS_PRIMITIVE || (IS_PRIMITIVE && (PRIMITIVE_LEVEL == MACRO)))} $pattern] ]
  } else {
    # Keep only macro-level cells and hierarchical cells
    set cells [get_cells -quiet -hier -filter {!IS_PRIMITIVE || (IS_PRIMITIVE && (PRIMITIVE_LEVEL == MACRO))}]
  }
  debug {
    puts " -D- #cells: [llength $cells] : [lrange $cells 0 100] ..."
  }
  foreach cell $cells parent [get_property -quiet PARENT $cells] origRefName [get_property -quiet ORIG_REF_NAME $cells] refName [get_property -quiet REF_NAME $cells] {
    if {$origRefName == {}} {
      set db(${cell}:ref) $refName
    } else {
      set db(${cell}:ref) $origRefName
    }
    if {$parent == {}} {
      # Cells at top-level
#       set parent {<TOP_LEVEL>}
    }
    set db(${cell}:parent) $parent
  }
  # Add entry inside database for top-level
  set db(:ref) {}
  set db(:parent) {}
  set stopTime [clock seconds]
  debug {
    puts " -D- buildDB completed in [expr $stopTime - $startTime] seconds"
  }
# parray db
  return -code ok
}

# Convert a primitive instance name into a list of parent's module names (ORIG_REF_NAME)
# Primitive:
#   rdr_tops/rdr_top_i0/rdr_eng0_i/GEN_ARB_DOWN.GEN_ARB_OUT_DN[8].rdr_arb_out_opt_dn_i/arb_out_fifo_dat/flop_array/flop_arr_reg[1][10]
# Returned list:
#   rdr_tops  rdr_top rdr_eng  rdr_arb_out_opt_dn
proc ::tb::utils::report_cells::getHierPath { name } {
  variable db
  set L [list]
  while {1} {
    if {![info exists db(${name}:ref)]} {
      puts " -E- cannot find '$name:ref' inside db"
      return [list]
    }
    lappend L $db(${name}:ref)
    set name $db(${name}:parent)
    if {$name == {}} { break }
  }
  return [lreverse $L]
}


#------------------------------------------------------------------------
# ::tb::utils::report_cells::debug
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
#------------------------------------------------------------------------
proc ::tb::utils::report_cells::debug {body} {
  variable params
  if {$params(debug)} {
    uplevel 1 [list eval $body]
  }
  return -code ok
}

namespace eval ::tb::utils {
  namespace import -force ::tb::utils::report_cells::report_cells
}

namespace eval ::tb {
  namespace import -force ::tb::utils::report_cells
}

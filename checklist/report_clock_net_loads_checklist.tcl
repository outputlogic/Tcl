####################################################################################################
# HEADER_BEGIN
# COPYRIGHT NOTICE
# Copyright 2001-2013 Xilinx Inc. All Rights Reserved.
# http://www.xilinx.com/support
# HEADER_END
####################################################################################################

########################################################################################
##
## Company:        Xilinx, Inc.
## Created by:     David Pefourque
##
## Version:        09/13/2013
## Tool Version:   Vivado 2013.3
##
########################################################################################

########################################################################################
## 09/13/2013 - Replaced property name LIB_CELL with REF_NAME
## 09/10/2013 - Changed command name from clockLoads to report_clock_net_loads
##            - Splited tables between clock pins and non-clock pins loads
##            - Minor updates to output formating
## 09/09/2013 - Added support for -file/-append/-return_string
##            - Moved code in a private namespace
##            - Removed errors from linter (lint_files)
##            - Improve runtime in non-verbose mode
## 08/27/2013 - Initial release based on clockLoads version 1.0 (Tony Scarangella)
##              Reformated the output
########################################################################################

namespace eval ::tclapp::xilinx::checklist {
  namespace export report_clock_net_loads

  # User command exported to the global namespace
  if {[lsearch $listUserCommands {report_clock_net_loads}] == -1} {
    lappend listUserCommands [list {report_clock_net_loads} {Generates a Clock Loads Report}]
  }
}

proc ::tclapp::xilinx::checklist::report_clock_net_loads { args } {
  # Summary :
  # Argument Usage:
  # Return Value:

  uplevel [concat ::tclapp::xilinx::checklist::report_clock_net_loads::report_clock_net_loads $args]
}

# Trick to silence the linter
eval [list namespace eval ::tclapp::xilinx::checklist::report_clock_net_loads {
  variable version {09/13/2013}
} ]

# ===================================================================================
#                           SCRIPT DESCRIPTION
# ===================================================================================
#
# THIS PROGRAM CREATES A CLOCK LOAD REPORT. ALL NETS WITH TYPE *CLOCK ARE DISCOVERED
# FROM THE PROJECT. THE FANOUT, DRIVER AND LOADS ARE CAPTURED. A UNIQUE LIST OF LOAD
# CELLS IS GENERATED. EACH UNIQUE CELL IS SEARCHED FOR IN THE NETLOAD CELLS LIST. IF
# A MATCH IS FOUND THE TOTAL IS INCREMENTED.
# THERE IS A VERBOSE MODE (TCL CONSOLE WINDOW) BY ENABLING VERBOSE_DEGUG = 1. IF NOT
# ENABLED NORMAL OPERATION IS TO GENERATE A CLOCK_LOAD_REPORT.TXT FILE.
# CREATED BY
#           TONY SCARANGELLA
# -----------------------------------------------------------------------------
#
# SYNTAX:
# =======
#    Load first: sources clockloads then call "clockloads"
#
#     Example:
#       clockloads
#
# INSTRUCTIONS:
# =============
#
#
#
# INPUT DATA:
# ===========
#
#
#
#
# RESULTS:
# ========
#
#
#
# ===================================================================================
#..................................................................................#
#                                                                                  #
#                              P R O C E D U R E S                                 #
#                                                                                  #
#..................................................................................#

proc ::tclapp::xilinx::checklist::report_clock_net_loads::report_clock_net_loads { args } {
  # Summary :
  # Argument Usage:
  # Return Value:

  #-------------------------------------------------------
  # Process command line arguments
  #-------------------------------------------------------
  set error 0
  set verbose 0
  set filename {}
  set mode {w}
  set FH {}
  set returnString 0
  set help 0
  while {[llength $args]} {
    set name [[namespace parent]::lshift args]
    switch -regexp -- $name {
      -file -
      {^-f(i(le?)?)?$} {
           set filename [[namespace parent]::lshift args]
           if {$filename == {}} {
             puts " -E- no filename specified."
             incr error
           }
      }
      -append -
      {^-a(p(p(e(nd?)?)?)?)?$} {
           set mode {a}
      }
      -verbose -
      {^-v(e(r(b(o(se?)?)?)?)?)?$} {
           set verbose 1
      }
      -return_string -
      {^-r(e(t(u(r(n(_(s(t(r(i(ng?)?)?)?)?)?)?)?)?)?)?)?$} {
           set returnString 1
      }
      -help -
      {^-h(e(lp?)?)?$} {
           set help 1
      }
      ^--version$ {
           variable version
           return $version
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
  Usage: report_clock_net_loads
              [-file]              - Report file name
              [-append]            - Append to file
              [-verbose]           - Verbose mode
              [-return_string]     - Return report as string
              [-help|-h]           - This help message

  Description: Generates a Clock Loads Report

     This command creates a clock load report. All nets with type *clock are discovered
     from the project. the fanout, driver and loads are captured. A unique list of load
     cells is generated. Each unique cell is searched for in the netload cells list. If
     a match is found the total is incremented. There is a verbose mode with -verbose 
     option.

  Example:
     report_clock_net_loads
     report_clock_net_loads -file my_report.rpt -verbose
} ]
    # HELP -->
    return {}
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  set start [clock seconds]
  set systemTime [clock seconds]
  set netCount 0
  set output [list]
  set clk_nets [list]
  set tableSummary [[namespace parent]::Table::Create]
  set table [[namespace parent]::Table::Create]

  set clk_nets [lsort -dictionary [get_nets -quiet -top_net_of_hierarchical_group -hierarchical * -filter Type=~*Clock]]

  lappend output "There are [llength $clk_nets] Clock nets"
  puts "There are [llength $clk_nets] Clock nets"

  # Define the summary table of all the nets
  $tableSummary reset
  $tableSummary title {Clock Nets Summary}
  $tableSummary header [list {Index} {Net Name} {Driver Ref} {Fanout} {Driver Pin} {Unique Loads}]

  foreach clkNet $clk_nets {
    incr netCount
    # Remove the driver from the fanout calculation
    set netFan [expr [get_property -quiet FLAT_PIN_COUNT [get_nets $clkNet]] -1]
    
    # Progress bar
#     progressBar $netCount [llength $clk_nets]

    set netSourceCells [get_cells -quiet -of [get_pins -quiet -of [get_nets $clkNet] -leaf -filter {DIRECTION==OUT}]]
    set netLoadPins [lsort -dictionary [get_pins -quiet -of [get_nets $clkNet] -leaf -filter {DIRECTION==IN}]]
    set driverPin [get_pins -quiet -of [get_nets -quiet $clkNet] -leaf -filter {DIRECTION==OUT}]
    set driverRef [get_property -quiet REF_NAME [get_cells -quiet -of $driverPin]]

    # Tcl list for the list of all the loads so that it can be sorted out
    set nonClockPinloads [list]
    set clockPinloads [list]
    # Tcl associative array to extract the list of count per unique load
    catch {unset uniqueClockPinLoads}
    catch {unset uniqueNonClockPinLoads}
    if {$verbose} {
      # In verbose mode, some extra processing is done to be able to generate the
      # detailed tables. Since this is runtime intensive, only run this code in
      # this mode
      foreach pin $netLoadPins {
        set cell [get_cells -quiet -of $pin]
        set libcell [get_property -quiet REF_NAME $cell]
        if {[get_property -quiet {IS_CLOCK} $pin]} {
          if {![info exists uniqueClockPinLoads($libcell)]} { set uniqueClockPinLoads($libcell) 0 }
          incr uniqueClockPinLoads($libcell) 1
          lappend clockPinloads [list $pin $libcell]
        } else {
          if {![info exists uniqueNonClockPinLoads($libcell)]} { set uniqueNonClockPinLoads($libcell) 0 }
          incr uniqueNonClockPinLoads($libcell) 1
          lappend nonClockPinloads [list $pin $libcell]
        }
      }
      # Sort 'clockPinloads' and 'nonClockPinloads' first on the cell name
      set clockPinloads [lsort -dictionary -index 0 $clockPinloads]
      set nonClockPinloads [lsort -dictionary -index 0 $nonClockPinloads]
      # ... then on the cell ref name
      set clockPinloads [lsort -dictionary -index 1 $clockPinloads]
      set nonClockPinloads [lsort -dictionary -index 1 $nonClockPinloads]
    } else {
      # In non-verbose mode, simplify the code so that only the 'uniqueLoads' array is
      # being built
      foreach libcell [get_property -quiet REF_NAME [get_cells -quiet -of [filter $netLoadPins {IS_CLOCK}]]] {
        if {![info exists uniqueClockPinLoads($libcell)]} { set uniqueClockPinLoads($libcell) 0 }
        incr uniqueClockPinLoads($libcell) 1
      }
      foreach libcell [get_property -quiet REF_NAME [get_cells -quiet -of [filter $netLoadPins {!IS_CLOCK}]]] {
        if {![info exists uniqueNonClockPinLoads($libcell)]} { set uniqueNonClockPinLoads($libcell) 0 }
        incr uniqueNonClockPinLoads($libcell) 1
      }
    }
    
    # Update the summary table
    $tableSummary addrow [list $netCount $clkNet $driverRef $netFan $driverPin [lsort -unique [concat [array names uniqueClockPinLoads] [array names uniqueNonClockPinLoads]] ] ]

    lappend output [format "\n(%-d) %-7s %-s" ${netCount} {Clock Net:} $clkNet]
    lappend output [format " %-14s %-14d" Fanout: $netFan]
    if {$verbose == 1 }  {
      lappend output [format " %-14s %-s" {Source Pin:} $netSourceCells]
    }
    lappend output [format " %-14s %-s" Source: [get_property -quiet REF_NAME $netSourceCells]]
    if {[info exists uniqueNonClockPinLoads]} {
      lappend output [format " %-14s %-s" {Unique Loads to Non-Clock Pin:} [lsort -unique [array names uniqueNonClockPinLoads]]]
    }
    if {[info exists uniqueClockPinLoads]} {
      lappend output [format " %-14s %-s" {Unique Loads to Clock Pin:} [lsort -unique [array names uniqueClockPinLoads]]]
    }

    if {[info exists uniqueNonClockPinLoads]} {
      $table reset
      $table title {Non-Clock Pin Loads}
      $table header [list {Cell Ref} {Number Used}]
      foreach elm [lsort [array names uniqueNonClockPinLoads]] {
        $table addrow [list $elm $uniqueNonClockPinLoads($elm)]
      }
      set output [concat $output [split [$table print] \n] ]
    }
    if {[info exists uniqueClockPinLoads]} {
      $table reset
      $table title {Clock Pin Loads}
      $table header [list {Cell Ref} {Number Used}]
      foreach elm [lsort [array names uniqueClockPinLoads]] {
        $table addrow [list $elm $uniqueClockPinLoads($elm)]
      }
      set output [concat $output [split [$table print] \n] ]
    }
    
    if {$verbose} {
      if {$nonClockPinloads != {}} {
        $table reset
        $table title {Detail of All Non-Clock Pins Loads}
        $table header [list {Cell Ref} {Pin Name} ]
        foreach elm $nonClockPinloads {
          foreach {pin libcell} $elm { break }
          $table addrow [list $libcell $pin ]
        }
        set output [concat $output [split [$table print] \n] ]
      }
      if {$clockPinloads != {}} {
        $table reset
        $table title {Detail of All Clock Pins Loads}
        $table header [list {Cell Ref} {Pin Name} ]
        foreach elm $clockPinloads {
          foreach {pin libcell} $elm { break }
          $table addrow [list $libcell $pin ]
        }
        set output [concat $output [split [$table print] \n] ]
      }
    }

  }

  set end [clock seconds]
  set duration [expr $end - $start]
  lappend output "\nGenerated clock loading on $netCount clock nets"
  lappend output "Date: [clock format $systemTime -format %D] Compile time: $duration seconds "
  puts "\nGenerated clock loading on $netCount clock nets"
  puts "Date: [clock format $systemTime -format %D] Compile time: $duration seconds "

  # Add the summary table at the very begining
#   set output [concat $output [split [$tableSummary print] \n] ]
  set output [concat [split [$tableSummary print] \n] $output ]

  if {$filename !={}} {
    set FH [open $filename $mode]
    puts $FH [::tclapp::xilinx::checklist::generate_file_header {report_clock_net_loads}]
    puts $FH [join $output \n]
    close $FH
    puts "\n Report file [file normalize $filename] has been generated\n"
  } else {
    puts [join $output \n]
  }

  # Destroy the objects
  catch {$tableSummary destroy}
  catch {$table destroy}

  # Return result as string?
  if {$returnString} {
    return [join $output \n]
  }

  return 0
}

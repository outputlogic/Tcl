####################################################################################################
# HEADER_BEGIN
# COPYRIGHT NOTICE
# Copyright 2001-2015 Xilinx Inc. All Rights Reserved.
# http://www.xilinx.com/support
# HEADER_END
####################################################################################################

########################################################################################
##
## Company:        Xilinx, Inc.
## Created by:     David Pefourque
##
## Description:    Convert report_clock_interaction to CSV file
##
########################################################################################

########################################################################################
## 2015.03.16 - Initial release
########################################################################################

# Example:
#   set report [report_clock_interaction -return_string]
#   clock_interaction_to_csv -report $report -csv report.csv

# Using designutils from Tcl Store
if {[lsearch [tclapp::list_apps] {xilinx::designutils}] == -1} {
  catch { tclapp::install designutils }
}

namespace eval ::clock_interaction_to_csv {}

proc ::clock_interaction_to_csv { args } {
  return [uplevel [concat ::clock_interaction_to_csv::clock_interaction_to_csv $args]]
}

proc ::clock_interaction_to_csv::clock_interaction_to_csv {args} {
  
  set clock_interaction_report {}
  set csvfilename {}
  set quiet 0
  set error 0
  set help 0
  if {[llength $args] == 0} {
    set help 1
  }
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -r -
      -report {
        set clock_interaction_report [lshift args]
      }
      -c -
      -csv {
        set csvfilename [lshift args]
      }
      -q -
      -quiet {
        set quiet 1
      }
      -h -
      -help {
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
  Usage: clock_interaction_to_csv
              -report <clock interaction report>
              [-csv <filename>]
              [-quiet]
              [-help|-h]

  Description: Convert a report_clock_interaction into a CSV file

  Example:
     set report [report_clock_interaction -return_string]
     clock_interaction_to_csv -report $report -csv report.csv
     clock_interaction_to_csv -report $report -csv report.csv -quiet
} ]
    # HELP -->
    return -code ok
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  # Convert the text report into a Tcl list  
  set clock_interaction [parse_report_clock_interaction $clock_interaction_report]

  set tbl [::xilinx::designutils::prettyTable]
  
  $tbl header [lindex $clock_interaction 0]
  foreach row [lrange $clock_interaction 1 end] {
    $tbl addrow $row
  }
  
  if {!$quiet} {
    $tbl configure -indent 2
    puts " -I- Clock interaction report:"
    puts [$tbl print]
  }
  
  if {$csvfilename != {}} {
    $tbl export -format csv -file $csvfilename
    puts " -I- CSV file [file normalize $csvfilename] generated"
  }
  
  # Delete table
  catch {$tbl destroy}
  
  return -code ok
}

proc ::clock_interaction_to_csv::lshift {inputlist} {
  upvar $inputlist argv
  set arg  [lindex $argv 0]
  set argv [lrange $argv 1 end]
  return $arg
}

proc ::clock_interaction_to_csv::extract_columns { str match } {
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

proc ::clock_interaction_to_csv::extract_row {str columns} {
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

proc ::clock_interaction_to_csv::parse_report_clock_interaction {report} {
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

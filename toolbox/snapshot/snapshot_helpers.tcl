####################################################################################################
# HEADER_BEGIN
# COPYRIGHT NOTICE
# Copyright 2001-2014 Xilinx Inc. All Rights Reserved.
# http://www.xilinx.com/support
# HEADER_END
####################################################################################################

########################################################################################
##
## Company:        Xilinx, Inc.
## Created by:     David Pefourque
##
## Version:        2014.10.04
## Tool Version:   Vivado 2014.1
## Description:    Helper procs for snapshot_core.tcl that are not directly related to
##                 the snapshot process. They can just help to extract data for save as
##                 metrics.
##
########################################################################################

########################################################################################
## 2014.10.04 - Added luniq
## 2014.06.25 - Initial release
########################################################################################

if {[info exists DEBUG]} { puts " Sourcing [file normalize [info script]]" }

# Proc to reload current script
proc [file tail [info script]] {} " source [info script]; puts \" [info script] reloaded\" "

namespace eval ::tb {
}

###########################################################################
##
## Higher level procs
##
###########################################################################

#------------------------------------------------------------------------
# Namespace for the package
#------------------------------------------------------------------------

# Trick to silence the linter
eval [list namespace eval ::tb::snapshot {
} ]

#------------------------------------------------------------------------
# ::tb::snapshot::luniq
#------------------------------------------------------------------------
# Usage: luniq <list>
#------------------------------------------------------------------------
# List with duplicates removed, and keeping the original order.
#------------------------------------------------------------------------
proc ::tb::snapshot::luniq {L} {
  # removes duplicates without sorting the input list
  set t [list]
  foreach i $L {if {[lsearch -exact $t $i]==-1} {lappend t $i}}
  return $t
} 

#------------------------------------------------------------------------
# ::tb::snapshot::duration
#------------------------------------------------------------------------
# Usage: duration <time_in_seconds>
#------------------------------------------------------------------------
# Convert a number of seconds in a human readable string.
# Example:
#      set startTime [clock seconds]
#      ...
#      set endTime [clock seconds]
#      puts "The runtime is: [duration [expr $endTime - startTime]]"
#------------------------------------------------------------------------
proc ::tb::snapshot::duration { int_time } {
   set timeList [list]
   if {$int_time == 0} { return "0 sec" }
   foreach div {86400 3600 60 1} mod {0 24 60 60} name {day hr min sec} {
     set n [expr {$int_time / $div}]
     if {$mod > 0} {set n [expr {$n % $mod}]}
     if {$n > 1} {
       lappend timeList "$n ${name}s"
     } elseif {$n == 1} {
       lappend timeList "$n $name"
     }
   }
   return [join $timeList]
}

#------------------------------------------------------------------------
# ::tb::snapshot::list2csv
#------------------------------------------------------------------------
# Convert a Tcl list to a CSV-friedly string
#------------------------------------------------------------------------
proc ::tb::snapshot::list2csv { list {sepChar ,} } {
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

#------------------------------------------------------------------------
# ::tb::snapshot::csv2list
#------------------------------------------------------------------------
# Convert a CSV string to a Tcl list based on a field separator
#------------------------------------------------------------------------
proc ::tb::snapshot::csv2list { str {sepChar ,} } {
  regsub -all {(\A\"|\"\Z)} $str \0 str
  set str [string map [list $sepChar\"\"$sepChar $sepChar$sepChar] $str]
  set str [string map [list $sepChar\"\"\" $sepChar\0\" \
                            \"\"\"$sepChar \"\0$sepChar \
                            $sepChar\"\"$sepChar $sepChar$sepChar \
                           \"\" \" \
                           \" \0 \
                           ] $str]
  set end 0
  while {[regexp -indices -start $end {(\0)[^\0]*(\0)} $str \
          -> start end]} {
      set start [lindex $start 0]
      set end   [lindex $end 0]
      set range [string range $str $start $end]
      set first [string first $sepChar $range]
      if {$first >= 0} {
          set str [string replace $str $start $end \
              [string map [list $sepChar \1] $range]]
      }
      incr end
  }
  set str [string map [list $sepChar \0 \1 $sepChar \0 {} ] $str]
  return [split $str \0]
}

##-----------------------------------------------------------------------
## ::tb::snapshot::csv2table
##-----------------------------------------------------------------------
## Convert a CSV content into a table and return the formatted table
##-----------------------------------------------------------------------
proc ::tb::snapshot::csv2table {content {title {}} {csvDelimiter ,}} {
  set CSV [list]
  foreach line [split $content \n] {
    # Skip comments and empty lines
    if {[regexp {^\s*#} $line]} { continue }
    if {[regexp {^\s*$} $line]} { continue }
    lappend CSV [csv2list $line $csvDelimiter]
  }
  set header [lindex $CSV 0]
  set rows [lrange $CSV 1 end]
  set tbl [::tb::snapshot::table::Create]
  if {$title != {}} {
    $tbl title $title
  }
  $tbl header $header
  foreach row $rows {
    $tbl addrow $row
  }
  set table [$tbl print]
  $tbl destroy
  return $table
}

##-----------------------------------------------------------------------
## ::tb::snapshot::list2table
##-----------------------------------------------------------------------
## Convert a CSV formatted list into a table and return the formatted table
##-----------------------------------------------------------------------
proc ::tb::snapshot::list2table {csvList {title {}}} {
  set header [lindex $csvList 0]
  set rows [lrange $csvList 1 end]
  set tbl [::tb::snapshot::table::Create]
  if {$title != {}} {
    $tbl title $title
  }
  $tbl header $header
  foreach row $rows {
    $tbl addrow $row
  }
  set table [$tbl print]
  $tbl destroy
  return $table
}

##-----------------------------------------------------------------------
## ::tb::snapshot::read_csv
##-----------------------------------------------------------------------
## Read CSV file and return a list of header+rows
##-----------------------------------------------------------------------
proc ::tb::snapshot::read_csv {filename {csvDelimiter ,}} {
  if {![file exists $filename]} {
    error " -E- file '$filename' does not exist"
  }
  set FH [open $filename]
  set CSV [list]
  while {![eof $FH]} {
    gets $FH line
    # Skip comments and empty lines
    if {[regexp {^\s*#} $line]} { continue }
    if {[regexp {^\s*$} $line]} { continue }
    lappend CSV [csv2list $line $csvDelimiter]
  }
  close $FH
  return $CSV
}

##-----------------------------------------------------------------------
## ::tb::snapshot::read_file
##-----------------------------------------------------------------------
## Read file and return the file content
##-----------------------------------------------------------------------
proc ::tb::snapshot::read_file {filename} {
  if {![file exists $filename]} {
    error " -E- file '$filename' does not exist"
  }
  set FH [open $filename]
  set content [read $FH]
  close $FH
  return $content
}

##########################################################################
##
## Simple helpers to handle parsing of Vivado report files
##
###########################################################################

# Trick to silence the linter
eval [list namespace eval ::tb::snapshot::parse { 
  set n 0 
} ]


#------------------------------------------------------------------------
# ::tb::snapshot::extract_columns
#------------------------------------------------------------------------
# Extract position of columns based on the column separator string
#  str:   string to be used to extract columns
#  match: column separator string
#------------------------------------------------------------------------
proc ::tb::snapshot::parse::extract_columns { str match } {
  # Summary :
  # Argument Usage:
  # Return Value:

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
# ::tb::snapshot::extract_row
#------------------------------------------------------------------------
# Extract all the cells of a row (string) based on the position
# of the columns
#------------------------------------------------------------------------
proc ::tb::snapshot::parse::extract_row {str columns} {
  # Summary :
  # Argument Usage:
  # Return Value:

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
# ::tb::snapshot::parse::report_clock_interaction
#------------------------------------------------------------------------
# Extract the clock table from report_clock_interaction and return
# a Tcl list
#------------------------------------------------------------------------
proc ::tb::snapshot::parse::report_clock_interaction {report} {
  # Summary :
  # Argument Usage:
  # Return Value:

  set columns [list]
  set table [list]
  set report [split $report \n]
  set SM {header}
  for {set index 0} {$index < [llength $report]} {incr index} {
    set line [lindex $report $index]
    switch $SM {
      header {
        if {[regexp {^\-+\s+\-+\s+\-+} $line]} {
#           set columns [::tb::snapshot::extract_columns $line { }]
#           set columns [::tb::snapshot::parse::extract_columns [string trimright $line] { }]
          set columns [extract_columns [string trimright $line] { }]
#           puts "Columns: $columns"
#           set header1 [::tb::snapshot::parse::extract_row [lindex $report [expr $index -2]] $columns]
#           set header2 [::tb::snapshot::parse::extract_row [lindex $report [expr $index -1]] $columns]
          set header1 [extract_row [lindex $report [expr $index -2]] $columns]
          set header2 [extract_row [lindex $report [expr $index -1]] $columns]
          set row [list]
          foreach h1 $header1 h2 $header2 {
            lappend row [string trim [format {%s %s} [string trim [format {%s} $h1]] [string trim [format {%s} $h2]]] ]
          }
#           puts "header:$row"
          lappend table $row
          set SM {table}
        }
      }
      table {
        # Check for empty line or for line that match '<empty>'
        if {(![regexp {^\s*$} $line]) && (![regexp -nocase {^\s*No clocks found.\s*$} $line])} {
#           set row [::tb::snapshot::parse::extract_row $line $columns]
          set row [extract_row $line $columns]
          lappend table $row
#           puts "row:$row"
        }
      }
      end {
      }
    }
  }
  return $table
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

# namespace eval ::tb::snapshot::table { set n 0 }

# Trick to silence the linter
eval [list namespace eval ::tb::snapshot::table { 
  set n 0 
} ]

proc ::tb::snapshot::table::Create { {title {}} } { #-- constructor
  # Summary :
  # Argument Usage:
  # Return Value:

  variable n
  set instance [namespace current]::[incr n]
  namespace eval $instance { variable tbl [list]; variable header [list]; variable indent 0; variable title {}; variable numrows 0 }
  interp alias {} $instance {} ::tb::snapshot::table::do $instance
  # Set the title
  $instance title $title
  set instance
}

proc ::tb::snapshot::table::do {self method args} { #-- Dispatcher with methods
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
        eval ::tb::snapshot::table::print $self
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

proc ::tb::snapshot::table::print {self} {
  # Summary :
  # Argument Usage:
  # Return Value:

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
  foreach row [concat [list $header] $table] {
      if {$row eq {%%SEPARATOR%%}} { 
        append res $head\n
        continue 
      }
      append res " [string repeat " " [expr $indent * 4]]|"
      foreach item $row max $maxs {append res [format " %-${max}s |" $item]}
      append res \n
      if {$first} {
        append res $head\n
        set first 0
      }
  }
  append res $head
  set res
}



#################################################################################
#################################################################################
#################################################################################


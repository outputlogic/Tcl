#!/bin/sh
# use -*-TCL-*- \
exec tclsh "$0" "$@"

###########################################################################
##
## Package for handling tables and printing of tables
##
###########################################################################

# To use this package:
#   lappend ::auto_path <directory>
#   package require Table

#------------------------------------------------------------------------
# Namespace for the package
#------------------------------------------------------------------------

namespace eval ::Table { 
  set n 0 
  set params [list indent 0 maxNumRows 10000 maxNumRowsToDisplay 50 title {} ]
  set version 0.1
}

#------------------------------------------------------------------------
# ::Table::Create
#------------------------------------------------------------------------
# Constructor for a new Table object
#------------------------------------------------------------------------
proc ::Table::Create { {name {}} } {
  variable n
  # Search for the next available object number, i.e namespace should not 
  # already exist
  while { [namespace exist [set instance [namespace current]::[incr n]] ]} {}
  namespace eval $instance { 
    variable header [list]
    variable table [list]
    variable separators [list]
    variable params
    variable numRows 0
  }
  catch {unset ${instance}::params}
  array set ${instance}::params $::Table::params
  # Save the table's name
  set ${instance}::params(title) $name
  interp alias {} $instance {} ::Table::do $instance
  set instance
}

#------------------------------------------------------------------------
# ::Table::Sizeof
#------------------------------------------------------------------------
# Memory footprint of all the existing Table objects
#------------------------------------------------------------------------
proc ::Table::Sizeof {} {
  return [::Table::method:sizeof ::Table]
}

#------------------------------------------------------------------------
# ::Table::Info
#------------------------------------------------------------------------
# Provide information about all the existing objects
#------------------------------------------------------------------------
proc ::Table::Info {} {
  foreach child [lsort [namespace children]] {
    puts "\n  Object $child"
    puts "  ==================="
    $child info
  }
  return 0
}

#------------------------------------------------------------------------
# ::Table::DestroyAll
#------------------------------------------------------------------------
# Detroy all the existing objects and release the memory
#------------------------------------------------------------------------
proc ::Table::DestroyAll {} {
  set count 0
  foreach child [namespace children] {
    $child destroy
    incr count
  }
  puts "  $count object(s) have been destroyed"
  return 0
}

#------------------------------------------------------------------------
# ::Table::docstring
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Return the embedded help of a proc
#------------------------------------------------------------------------
proc ::Table::docstring procname {
   if {[info proc $procname] ne $procname} { return }
   # reports a proc's args and leading comments.
   # Multiple documentation lines are allowed.
   set res ""
   # This comment should not appear in the docstring
   foreach line [split [uplevel 1 [list info body $procname]] \n] {
       if {[string trim $line] eq ""} continue
       if ![regexp {^\s*#(.+)} $line -> line] break
       lappend res [string trim $line]
   }
   join $res \n
}

#------------------------------------------------------------------------
# ::Table::lshift
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Stack function
#------------------------------------------------------------------------
proc ::Table::lshift {inputlist} {
  upvar $inputlist argv
  set arg  [lindex $argv 0]
  set argv [lrange $argv 1 end]
  return $arg
}

#------------------------------------------------------------------------
# ::Table::do
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Dispatcher with methods
#------------------------------------------------------------------------
proc ::Table::do {self args} {
  upvar #0 ${self}::table table
  upvar #0 ${self}::indent indent
  if {[llength $args] == 0} {
#     error " -E- wrong number of parameters: <object> <method> \[<arguments>\]"
    set method {?}
  } else {
    # The first argument is the method
    set method [lshift args]
  }
  if {[info proc ::Table::method:${method}] == "::Table::method:${method}"} {
    eval ::Table::method:${method} $self $args
  } else {
    # Search for a unique matching method among all the available methods
    set match [list]
    foreach procname [info proc ::Table::method:*] {
      if {[string first $method [regsub {::Table::method:} $procname {}]] == 0} {
        lappend match [regsub {::Table::method:} $procname {}]
      }
    }
    switch [llength $match] {
      0 {
        error " -E- unknown method $method"
      }
      1 {
        set method $match
        eval ::Table::method:${method} $self $args
      }
      default {
        error " -E- multiple methods match '$method': $match"
      }
    }
  }
}

#------------------------------------------------------------------------
# ::Table::method:?
#------------------------------------------------------------------------
# Usage: <object> ?
#------------------------------------------------------------------------
# Return all the available methods. The methods with no embedded help
# are not displayed (i.e hidden)
#------------------------------------------------------------------------
proc ::Table::method:? {self args} {
  # This help message
  puts "   Usage: <object> <method> \[<arguments>\]"
  puts "   Where <method> is:"
  foreach procname [lsort [info proc ::Table::method:*]] {
    regsub {::Table::method:} $procname {} method
    set help [::Table::docstring $procname]
    if {$help ne ""} {
      puts "         [format {%-12s%s- %s} $method \t $help]"
    }
  }
  puts ""
}

#------------------------------------------------------------------------
# ::Table::method:header
#------------------------------------------------------------------------
# Usage: <object> header <list>
#------------------------------------------------------------------------
# Set the table header
#------------------------------------------------------------------------
proc ::Table::method:header {self args} {
  # Set the header of the table
  if {$args != {}} {
    eval set ${self}::header $args
  } else {
    # If no argument is provided then return the current header
  }
  set ${self}::header
}

#------------------------------------------------------------------------
# ::Table::method:addrow
#------------------------------------------------------------------------
# Usage: <object> addrow <list>
#------------------------------------------------------------------------
# Add a row to the table
#------------------------------------------------------------------------
proc ::Table::method:addrow {self args} {
  # Add a row to the table
  set maxNumRows [subst $${self}::params(maxNumRows)]
  if {([subst $${self}::numRows] >= $maxNumRows) && ($maxNumRows != -1)} {
    error " -E- maximum number of rows reached ([subst $${self}::params(maxNumRows)]). Failed adding new row"
  }
  eval lappend ${self}::table $args
  incr ${self}::numRows
  return 0
}

#------------------------------------------------------------------------
# ::Table::method:indent
#------------------------------------------------------------------------
# Usage: <object> indent [<value>]
#------------------------------------------------------------------------
# Set/get the indent level for the table
#------------------------------------------------------------------------
proc ::Table::method:indent {self args} {
  # Set the indent level for the table
  if {$args != {}} {
    set ${self}::params(indent) $args
  } else {
    # If no argument is provided then return the current indent level
  }
  set ${self}::params(indent)
}

#------------------------------------------------------------------------
# ::Table::method:get_param
#------------------------------------------------------------------------
# **HIDDEN**
#------------------------------------------------------------------------
# Usage: <object> get_param <param>
#------------------------------------------------------------------------
# Get a parameter from the 'params' associative array
#------------------------------------------------------------------------
proc ::Table::method:get_param {self args} {
  if {[llength $args] != 1} {
    error " -E- wrong number of parameters: <object> get_param <param>"
  }
  if {![info exists ${self}::params([lindex $args 0])]} {
    error " -E- unknown parameter '[lindex $args 0]'"
  }
  return [subst $${self}::params([lindex $args 0])]
}

#------------------------------------------------------------------------
# ::Table::method:set_param
#------------------------------------------------------------------------
# **HIDDEN**
#------------------------------------------------------------------------
# Usage: <object> set_param <param> <value>
#------------------------------------------------------------------------
# Set a parameter inside the 'params' associative array
#------------------------------------------------------------------------
proc ::Table::method:set_param {self args} {
  if {[llength $args] < 2} {
    error " -E- wrong number of parameters: <object> set_param <param> <value>"
  }
  set ${self}::params([lindex $args 0]) [lrange $args 1 end]
  return 0
}

#------------------------------------------------------------------------
# ::Table::method:separator 
#------------------------------------------------------------------------
# Usage: <object> separator
#------------------------------------------------------------------------
# Add a separator after the last inserted row
#------------------------------------------------------------------------
proc ::Table::method:separator {self args} {
  # Add a row separator
  if {[subst $${self}::numRows] > 0} {
    # Add the current row number to the list of separators
    eval lappend ${self}::separators [subst $${self}::numRows]
  }
  return 0
}

#------------------------------------------------------------------------
# ::Table::method:reset
#------------------------------------------------------------------------
# Usage: <object> reset
#------------------------------------------------------------------------
# Reset the object to am empty one. All the data of that object are lost
#------------------------------------------------------------------------
proc ::Table::method:reset {self args} {
  # Reset object and empty all the data
  set ${self}::header [list]
  set ${self}::table [list]
  set ${self}::separators [list]
  set ${self}::numRows 0
  catch {unset ${self}::params}
  array set ${self}::params $::Table::params
#   set ${self}::params(indent) 0
  return 0
}

#------------------------------------------------------------------------
# ::Table::method:destroy
#------------------------------------------------------------------------
# Usage: <object> destroy
#------------------------------------------------------------------------
# Destroy an object and release its memory footprint. The object is not
# accessible anymore after that command
#------------------------------------------------------------------------
proc ::Table::method:destroy {self args} {
  # Destroy object
  set ${self}::header [list]
  set ${self}::table [list]
  set ${self}::separators [list]
  set ${self}::numRows 0
  catch {unset ${self}::params}
  namespace delete $self
  return 0
}

#------------------------------------------------------------------------
# ::Table::method:sizeof
#------------------------------------------------------------------------
# Usage: <object> sizeof
#------------------------------------------------------------------------
# Return the memory footprint of the object
#------------------------------------------------------------------------
proc ::Table::method:sizeof {ns args} {
  # Return memory footprint of the object
  set sum [expr wide(0)]
  foreach var [info vars ${ns}::*] {
      if {[info exists $var]} {
          upvar #0 $var v
          if {[array exists v]} {
              incr sum [string bytelength [array get v]]
          } else {
              incr sum [string bytelength $v]
          }
      }
  }
  foreach child [namespace children $ns] {
      incr sum [::Table::method:sizeof $child]
  }
  set sum
}

#------------------------------------------------------------------------
# ::Table::method:print
#------------------------------------------------------------------------
# Usage: <object> print [<options>]
#------------------------------------------------------------------------
# Return the printed table
#------------------------------------------------------------------------
proc ::Table::method:print {self args} {
  # Print table. The output can be captured in a variable
  upvar #0 ${self}::header header
  upvar #0 ${self}::table table
  upvar #0 ${self}::separators separators
  upvar #0 ${self}::params params
  upvar #0 ${self}::numRows numRows
  set indent $params(indent)

  set error 0
  set help 0
  set filename {}
  set startRow 0
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -f -
      -file {
           set filename [lshift args]
      }
      -from {
           set startRow [lshift args]
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
  Usage: <object> print 
              [-file <filename>]
              [-from <start_row_number>]
              [-help|-h]
              
  Description: Print table content.
  
  Example:
     <object> print
} ]
    # HELP -->
    return {}
  }
    
  set maxs {}
  foreach item $header {
      lappend maxs [string length $item]
  }
  set numCols [llength $header]
  set count 0
  set maxNumRowsToDisplay [subst $${self}::params(maxNumRowsToDisplay)]
  foreach row $table {
      incr count
      if {($count > $maxNumRowsToDisplay) && ($maxNumRowsToDisplay != -1)} {
        # Did we reach the maximum of rows to be displayed?
        break
      }
      for {set j 0} {$j<$numCols} {incr j} {
           set item [lindex $row $j]
           set max [lindex $maxs $j]
           if {[string length $item]>$max} {
              lset maxs $j [string length $item]
          }
      }
  }
  # Create the row separator string
  set indentString [string repeat " " $indent]
  set separator "${indentString}+"
  foreach max $maxs { append separator "-[string repeat - $max]-+" }
  set res {}
  # Generate the title
  if {$params(title) ne {}} {
    # The upper separator should something like +----...----+
    append res "${indentString}+[string repeat - [expr [string length $separator] - [string length $indentString] -2]]+\n"
    append res "${indentString}| "
    append res [format "%-[expr [string length $separator] - [string length $indentString] -4]s" $params(title)]
    append res " |"
  }
  # Generate the table header
  append res "\n${separator}\n"
  append res "${indentString}|"
  foreach item $header max $maxs {append res [format " %-${max}s |" $item]}
  append res "\n${separator}\n"
  # Generate the table rows
  set count 0
  foreach row $table {
      incr count
      if {($count > $maxNumRowsToDisplay) && ($maxNumRowsToDisplay != -1)} {
        # Did we reach the maximum of rows to be displayed?
        break
      }
      append res "${indentString}|"
      foreach item $row max $maxs {append res [format " %-${max}s |" $item]}
      append res \n
      # Check if a separator has been assigned to this row number and add a separator
      # if so.
      if {[lsearch $separators $count] != -1} {
        append res "$separator\n"
      }
  }
  # Add table footer only if the last row does not have a separator defined, otherwise the separator
  # is printed twice
  if {[lsearch $separators $count] == -1} {
    append res $separator
  }
  if {($count > $maxNumRowsToDisplay) && ($maxNumRowsToDisplay != -1)} {
    # Did we reach the maximum of rows to be displayed?
    append res "\n\n -W- Table truncated. Only the first [subst $${self}::params(maxNumRowsToDisplay)] rows are displayed\n"
  }
  if {$filename != {}} {
    set FH [open $filename w]
    puts $FH $res
    close $FH
    return 
  } else {
    set res
  }
}

#------------------------------------------------------------------------
# ::Table::method:info
#------------------------------------------------------------------------
# Usage: <object> info
#------------------------------------------------------------------------
# List various information about the object
#------------------------------------------------------------------------
proc ::Table::method:info {self args} {
  # Information about the object
  upvar #0 ${self}::header header
  upvar #0 ${self}::table table
  upvar #0 ${self}::params params
  puts [format {    Header: %s} $header]
  puts [format {    # Cols: %s} [llength $header]]
  puts [format {    # Rows: %s} [subst $${self}::numRows] ]
  foreach param [lsort [array names params]] {
    puts [format {    Param[%s]: %s} $param $params($param)]
  }
  puts [format {    Memory footprint: %d bytes} [::Table::method:sizeof $self]]
}

#------------------------------------------------------------------------
# ::Table::method:sort
#------------------------------------------------------------------------
# Usage: <object> [<COLUMN_HEADER>] [+<COLUMN_HEADER>] [-<COLUMN_HEADER>] 
#------------------------------------------------------------------------
# Sort the table based on the specified column header. The table can
# be sorted ascending or descending
#------------------------------------------------------------------------
proc ::Table::method:sort {self args} {
  # Sort the table based on one or more column headers
  upvar #0 ${self}::header header
  upvar #0 ${self}::table table
  upvar #0 ${self}::params params
  foreach elm $args {
    set direction {increasing}
    set column {}
    if {[regexp {^(\+)(.+)$} $elm -- - column]} {
      set direction {increasing}
    } elseif {[regexp {^(\-)(.+)$} $elm -- - column]} {
      set direction {decreasing}
    } elseif {[regexp {^(.+)$} $elm -- column]} {
      set direction {increasing}
    } else {
      continue
    }
    set index [lsearch $header $column]
    if {$index == -1} {
      puts " -E- unknown column header '$column'"
      continue
    }
    if {[catch { set table [lsort -$direction -dictionary -index $index $table] } errorstring]} {
      puts " -E- Sorting by column '$column': $errorstring"
    } else {
      # Since the rows are sorted, the separators don't mean anything anymore, so remove them
      set ${self}::separators [list]
      puts " -I- Sorting ($direction) by column '$column' completed"
    }
  }
}

#------------------------------------------------------------------------
# ::Table::method:configure
#------------------------------------------------------------------------
# Usage: <object> configure [<options>]
#------------------------------------------------------------------------
# Configure some of the object parameters
#------------------------------------------------------------------------
proc ::Table::method:configure {self args} {
  # Configure object
  set error 0
  set help 0
  if {[llength $args] == 0} {
    set help 1
  }
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -title {
           set ${self}::params(title) [lshift args]
      }
      -indent {
           set ${self}::params(indent) [lshift args]
      }
      -limit {
           set ${self}::params(maxNumRows) [lshift args]
      }
      -display -
      -display_limit {
           set ${self}::params(maxNumRowsToDisplay) [lshift args]
      }
      -remove_separator -
      -remove_separators {
           set ${self}::separators [list]
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
  Usage: <object> configure 
              [-title <string>]
              [-indent <indent_level>]
              [-limit <max_number_of_rows>]
              [-display_limit <max_number_of_rows_to_display>]
              [-remove_separators]
              [-help|-h]
              
  Description: Configure some of the internal parameters.
  
  Example:
     <object> configure -indent 2
} ]
    # HELP -->
    return {}
  }
    
}

#------------------------------------------------------------------------
# ::Table::method:clone
#------------------------------------------------------------------------
# Usage: <object> clone
#------------------------------------------------------------------------
# Clone the object and return the cloned object. The original object
# is not modified
#------------------------------------------------------------------------
proc ::Table::method:clone {self args} {
  # Clone object. Return new object
  upvar #0 ${self}::header header
  upvar #0 ${self}::table table
  upvar #0 ${self}::params params
  upvar #0 ${self}::separators separators
  upvar #0 ${self}::numRows numRows
  set tbl [::Table::Create]
  set ${tbl}::header $header
  set ${tbl}::table $table
  set ${tbl}::separators $separators
  set ${tbl}::numRows $numRows
  array set ${tbl}::params [array get params]
  return $tbl
}


#------------------------------------------------------------------------
# Provide the package
#------------------------------------------------------------------------
package provide Table $::Table::version

#--------------------------- Self-test code
if {[info ex argv0] && [file tail [info script]] == [file tail $argv0]} {
  # File executed from tclsh
  puts "Package Table"
  # Simple index generator, if the directory contains only this package
  pkg_mkIndex -verbose [file dirn [info scr]] [file tail [info scr]]
} else {
  # File sourced

  # Simplify re-sourcing this file
  proc [file tail [info script]] {} "source [info script]"
 
  puts "  [info script] sourced."
}
#------------------------------------------

###########################################################################
##
## Examples
##
###########################################################################

if 0 {
  set tbl [::Table::Create {This is the title of the table}]
  $tbl header [list "name" "#Pins" "case_value" "user_case_value"]
  $tbl addrow [list A/B/C/D/E/F 12 - -]
  $tbl addrow [list A/B/C/D/E/G 24 1 -]
  $tbl addrow [list A/B/C/D/E/H 48 0 1]
  $tbl addrow [list A/B/C/D/E/H 46 0 1]
  $tbl addrow [list A/B/C/D/E/H 44 1 0]
  $tbl addrow [list A/B/C/D/E/H 42 1 0]
  $tbl addrow [list A/B/C/D/E/H 40 1 0]
  $tbl separator
  $tbl separator
  $tbl separator
  $tbl addrow [list A/I1 10 1 0]
  $tbl addrow [list A/I2 12 0 1]
  $tbl addrow [list A/I3 8 - -]
  $tbl addrow [list A/I4 6 - -]
  $tbl separator
  $tbl separator
  $tbl print
  $tbl indent 2
  $tbl print
  # $tbl reset
  $tbl header [list "name" "#Pins" "case_value" "user_case_value" "HEAD1" "HEAD2" "HEAD3" "HEAD4"]
  $tbl print
  $tbl sizeof
  set new [$tbl clone]
  $new print
  $new sort -#Pins
  $new print
  ::Table::Sizeof
  ::Table::Info
  # ::Table::DestroyAll
  # $tbl destroy
}

if 0 {
  set pins [get_pins -hier *]
  set tbl [::Table::Create]
  $tbl configure -limit -1
  $tbl configure -display_limit -1
  set Header [list NAME CLASS DIRECTION IS_LEAF IS_CLOCK LOGIC_VALUE SETUP_SLACK HOLD_SLACK]
  $tbl header $Header
  foreach pin $pins {
    set row [list]
    foreach prop $Header {
      lappend row [get_property $prop $pin]
    }
    $tbl addrow $row
  }
  $tbl sort -SETUP_SLACK
  $tbl print -file table.rpt
}

if 0 {
  #------------------------------------------------------------------------
  # ::Table::method:addpin
  #------------------------------------------------------------------------
  # Usage: <object> addpin [<object>|<list_of_objects>]
  #------------------------------------------------------------------------
  # Add Vivado Pin object(s) to the table
  #------------------------------------------------------------------------
  proc ::Table::method:addpin {self args} {
    # Add Vivado Pin object(s) to the table
    set header [$self header]
    set collectionResultDisplayLimit [get_param tcl.collectionResultDisplayLimit]
    set_param tcl.collectionResultDisplayLimit 0
    set count 0
    foreach object [lindex $args 0] {
      set pin [get_pins -quiet $object]
      if {$pin == {}} { continue }
      set valid_properties [list_property $pin]
      set row [list]
      foreach column $header {
        if {[string toupper $column] eq {OBJECT}} {
          lappend row $pin
          continue
        } elseif {[lsearch $valid_properties $column] == -1} {
          lappend row {N/A}
          continue
        }
        lappend row [get_property $column $pin]
      }
      # The row is manullay added to the table. The 'addrow' method is not
      # called since the Vivado object is lost in the 'eval' command inside
      # this method.
      lappend ${self}::table $row
      incr ${self}::numRows
#       $self addrow $row
      incr count
    }
    puts "  $count pin object(s) have been added"
    set_param tcl.collectionResultDisplayLimit $collectionResultDisplayLimit
    return 0
  }

  #------------------------------------------------------------------------
  # Usage: <object> addcell [<object>|<list_of_objects>]
  #------------------------------------------------------------------------
  # Add Vivado Cell object(s) to the table
  #------------------------------------------------------------------------
  proc ::Table::method:addcell {self args} {
    # Add Vivado Cell object(s) to the table
    set header [$self header]
    set collectionResultDisplayLimit [get_param tcl.collectionResultDisplayLimit]
    set_param tcl.collectionResultDisplayLimit 0
    set count 0
    foreach object [lindex $args 0] {
      set cell [get_cells -quiet $object]
      if {$cell == {}} { continue }
      set valid_properties [list_property $cell]
      set row [list]
      foreach column $header {
        if {[string toupper $column] eq {OBJECT}} {
          lappend row $cell
          continue
        } elseif {[lsearch $valid_properties $column] == -1} {
          lappend row {N/A}
          continue
        }
        lappend row [get_property $column $cell]
      }
      # The row is manullay added to the table. The 'addrow' method is not
      # called since the Vivado object is lost in the 'eval' command inside
      # this method.
      lappend ${self}::table $row
      incr ${self}::numRows
#       $self addrow $row
      incr count
    }
    puts "  $count cell object(s) have been added"
    set_param tcl.collectionResultDisplayLimit $collectionResultDisplayLimit
    return 0
  }
  
  #------------------------------------------------------------------------
  # Usage: <object> addcolumn [<name>]
  #------------------------------------------------------------------------
  # Add a column to the table
  #------------------------------------------------------------------------
  proc ::Table::method:addcolumn {self args} {
    # Add a column to the table
    upvar #0 ${self}::header header
    upvar #0 ${self}::table table
    upvar #0 ${self}::numRows numRows
    set count 0
    foreach column $args {
      # Skip if the column already exist
      if {[lsearch $header $column] != -1} {
        puts " -W- Column '$column' already exist. Skipped"
        continue
      }
      # Append the column to the table header
      lappend header $column
      for {set i 0} {$i < $numRows} {incr i} {
        # The assumption is that the first element of the row is always a Vivado object
        set object [lindex [lindex $table $i] 0]
        # Check if the column is a valid property of the object
        set valid_properties [list_property $object]
        if {[lsearch $valid_properties $column] == -1} {
          set value {N/A}
#           puts " -W- Not a valid property '$column' for the object. Skipped"
        } else {
          set value [get_property -quiet $column $object]
        }
        lset table $i [linsert [lindex $table $i] end $value]
#         lset table $i [linsert [lindex $table $i] end [get_property -quiet $column $object]]
      }
      incr count
    }
    puts "  $count column(s) have been added"
    return 0
  }
  
  set tbl [::Table::Create]
  $tbl configure -limit -1
  $tbl configure -display_limit -1
#   set Header [list OBJECT NAME CLASS DIRECTION IS_LEAF IS_CLOCK LOGIC_VALUE SETUP_SLACK HOLD_SLACK]
  set Header [list OBJECT CLASS DIRECTION LOGIC_VALUE SETUP_SLACK HOLD_SLACK]
  $tbl header $Header
  set pins [get_pins -hier *]
  foreach pin [lrange $pins 0 20] {
    $tbl addpin $pin
  }
  $tbl separator
  $tbl addpin [lrange $pins 30 40]
  $tbl sort -SETUP_SLACK
  $tbl addcolumn IS_LEAF IS_CLOCK 
  $tbl print -file table.rpt
}

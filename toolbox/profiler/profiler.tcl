####################################################################################################
# HEADER_BEGIN
# COPYRIGHT NOTICE
# Copyright 2001-2016 Xilinx Inc. All Rights Reserved.
# http://www.xilinx.com/support
# HEADER_END
####################################################################################################

########################################################################################
##
## Company:        Xilinx, Inc.
## Created by:     David Pefourque
##
## Version:        2016.07.29
## Tool Version:   Vivado 2014.1
## Description:    This package provides a simple profiler for Vivado commands
##
########################################################################################

########################################################################################
## 2016.07.29 - Added method 'configure'
##            - Added tuncation of long command lines inside log file
##              (improved performance and better support for very large XDC)
## 2014.07.03 - Fixed issue with clock formating that prevented the script from running
##              under Windows
## 2014.05.13 - Updated package requirement to Vivado 2014.1
## 2013.10.03 - Changed version format to 2013.10.03 to be compatible with 'package' command
##            - Added version number to namespace
## 09/16/2013 - Updated 'docstring' to support meta-comment 'Categories' for linter
## 03/29/2013 - Minor fix
## 03/26/2013 - Reformated the log file and added the top 50 worst runtimes
##            - Renamed subcommand 'exec' to 'time'
##            - Removed 'read_xdc' from the list of commands that contribute to the
##              total runtime
##            - Added subcommand 'version'
##            - Added subcommand 'configure'
##            - Added options -collection_display_limit & -src_info to subcommand 'start'
##            - Modified the subcommand 'time' to accept the same command line arguments
##              as the subcommand 'start'
## 03/21/2013 - Initial release
########################################################################################

# Profiler usage:
#    profiler add *    (-help for additional help)
#    profiler start    (-help for additional help)
#      <execute code>
#    profiler stop
#    profiler summary  (-help for additional help)
#
# OR
#
#    profiler add *    (-help for additional help)
#    profiler time { ... }

if {[package provide Vivado] == {}} {return}

package require Vivado 1.2014.1
package require struct::matrix

namespace eval ::tb {
    namespace export profiler
}

proc ::tb::profiler { args } {
  # Summary : Tcl profiler

  # Argument Usage:
  # args : sub-command. The supported sub-commands are: start | stop | summary | add | remove | reset | status

  # Return Value:
  # returns the status or an error code

#   if {[catch {set res [uplevel [concat ::tb::profiler::profiler $args]]} errorstring]} {
#     error " -E- the profiler failed with the following error: $errorstring"
#   }
  return [uplevel [concat ::tb::profiler::profiler $args]]
}


###########################################################################
##
## Package for profiling Tcl code
##
###########################################################################

#------------------------------------------------------------------------
# Namespace for the package
#------------------------------------------------------------------------

# Trick to silence the linter
eval [list namespace eval ::tb::profiler {
  variable version {2016.07.29}
  variable cmdlist [list]
  variable tmstart [list]
  variable tmend [list]
  variable params
  variable db [list]
  variable summary
  catch {unset params}
  array set params [list mode {stopped} expandObjects 0 collectionResultDisplayLimit -1 ]
} ]

#------------------------------------------------------------------------
# ::tb::profiler::profiler
#------------------------------------------------------------------------
# Main function
#------------------------------------------------------------------------
proc ::tb::profiler::profiler { args } {
  # Summary :
  # Argument Usage:
  # Return Value:

  #-------------------------------------------------------
  # Process command line arguments
  #-------------------------------------------------------
  set error 0
  set show_help 0
  set method [lshift args]
  switch -exact -- $method {
    dump {
      return [eval [concat ::tb::profiler::dump] ]
    }
    ? -
    -h -
    -help {
      incr show_help
    }
    default {
      return [eval [concat ::tb::profiler::do ${method} $args] ]
    }
  }

  if {$show_help} {
    # <-- HELP
    puts ""
    ::tb::profiler::method:?
    puts [format {
   Description: Utility to profile Vivado commands

   Example1:
      profiler add *
      profiler start -incr
        <execute some Tcl code with Vivado commands>
      profiler stop
      profiler summary
      profiler reset

   Example2:
      profiler add *
      profiler time { <execute some Tcl code with Vivado commands> }
      profiler summary
      profiler reset

    } ]
    # HELP -->
    return
  }

}

#------------------------------------------------------------------------
# ::tb::profiler::lshift
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Stack function
#------------------------------------------------------------------------
proc ::tb::profiler::lshift {inputlist} {
  # Summary :
  # Argument Usage:
  # Return Value:

  upvar $inputlist argv
  set arg  [lindex $argv 0]
  set argv [lrange $argv 1 end]
  return $arg
}

#------------------------------------------------------------------------
# ::tb::profiler::lflatten
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Flatten a nested list
#------------------------------------------------------------------------
proc ::tb::profiler::lflatten {inputlist} {
  # Summary :
  # Argument Usage:
  # Return Value:

  while { $inputlist != [set inputlist [join $inputlist]] } { }
  return $inputlist
}

#------------------------------------------------------------------------
# ::tb::profiler::lremove
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Remove element from a list
#------------------------------------------------------------------------
proc ::tb::profiler::lremove {_inputlist element} {
  # Summary :
  # Argument Usage:
  # Return Value:

  upvar 1 $_inputlist inputlist
  set pos [lsearch -exact $inputlist $element]
  set inputlist [lreplace $inputlist $pos $pos]
}
#------------------------------------------------------------------------
# ::tb::profiler::docstring
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Return the embedded help of a proc
#------------------------------------------------------------------------
proc ::tb::profiler::docstring {procname} {
  # Summary :
  # Argument Usage:
  # Return Value:

  if {[info proc $procname] ne $procname} { return }
  # reports a proc's args and leading comments.
  # Multiple documentation lines are allowed.
  set res ""
  # This comment should not appear in the docstring
  foreach line [split [uplevel 1 [list info body $procname]] \n] {
      if {[string trim $line] eq ""} continue
      # Skip comments that have been added to support rdi::register_proc command
      if {[regexp -nocase -- {^\s*#\s*(Summary|Argument Usage|Return Value|Categories)\s*\:} $line]} continue
      if {![regexp {^\s*#(.+)} $line -> line]} break
      lappend res [string trim $line]
  }
  join $res \n
}

#------------------------------------------------------------------------
# ::tb::profiler::do
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Dispatcher with methods
#------------------------------------------------------------------------
proc ::tb::profiler::do {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  if {[llength $args] == 0} {
#     error " -E- wrong number of parameters: profiler <sub-command> \[<arguments>\]"
    set method {?}
  } else {
    # The first argument is the method
    set method [lshift args]
  }
  if {[info proc ::tb::profiler::method:${method}] == "::tb::profiler::method:${method}"} {
    eval ::tb::profiler::method:${method} $args
  } else {
    # Search for a unique matching method among all the available methods
    set match [list]
    foreach procname [info proc ::tb::profiler::method:*] {
      if {[string first $method [regsub {::tb::profiler::method:} $procname {}]] == 0} {
        lappend match [regsub {::tb::profiler::method:} $procname {}]
      }
    }
    switch [llength $match] {
      0 {
        error " -E- unknown sub-command $method"
      }
      1 {
        set method $match
        return [eval ::tb::profiler::method:${method} $args]
      }
      default {
        error " -E- multiple sub-commands match '$method': $match"
      }
    }
  }
}

#------------------------------------------------------------------------
# ::tb::profiler::method:?
#------------------------------------------------------------------------
# Usage: profiler ?
#------------------------------------------------------------------------
# Return all the available methods. The methods with no embedded help
# are not displayed (i.e hidden)
#------------------------------------------------------------------------
proc ::tb::profiler::method:? {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # This help message
  puts "   Usage: profiler <sub-command> \[<arguments>\]"
  puts "   Where <sub-command> is:"
  foreach procname [lsort [info proc ::tb::profiler::method:*]] {
    regsub {::tb::profiler::method:} $procname {} method
    set help [::tb::profiler::docstring $procname]
    if {$help ne ""} {
      puts "         [format {%-12s%s- %s} $method \t $help]"
    }
  }
  puts ""
}

#------------------------------------------------------------------------
# ::tb::profiler::enter
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Called before a profiled command is executed
#------------------------------------------------------------------------
proc ::tb::profiler::enter {cmd op} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable db
  lappend db [list [clock microseconds] 1 $cmd]
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::profiler::leave1
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Called after a profiled command is executed
#------------------------------------------------------------------------
proc ::tb::profiler::leave1 {cmd code result op} {
  # Summary :
  # Argument Usage:
  # Return Value:
  variable db
  variable params
  if {$params(expandObjects)} {
    # Save the list of return objects
    lappend db [list [clock microseconds] 0 $cmd $code $result]
  } else {
    # Only save the number of return objects
    lappend db [list [clock microseconds] 0 $cmd $code [list [format {%d objects} [llength $result]]] ]
  }
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::profiler::leave2
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Verbose version of ::tb::profiler::leave1
# Save the source information inside the database
#------------------------------------------------------------------------
proc ::tb::profiler::leave2 {cmd code result op} {
  # Summary :
  # Argument Usage:
  # Return Value:
  variable db
  variable params
  # Create temp variable in case [current_design] does not exist
  set src_info {}
  catch { set src_info [get_property -quiet src_info [current_design -quiet]] }
  if {$params(expandObjects)} {
    # Save the list of return objects
    lappend db [list [clock microseconds] 0 $cmd $code $result $src_info ]
  } else {
    # Only save the number of return objects
    lappend db [list [clock microseconds] 0 $cmd $code [list [format {%d objects} [llength $result]]] $src_info]
  }
#   lappend db [list [clock microseconds] 0 $cmd $code $result [get_property src_info [current_design]] ]
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::profiler::trace_off
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Remove all 'trace' commands
#------------------------------------------------------------------------
proc ::tb::profiler::trace_off {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable cmdlist
  foreach cmd $cmdlist {
    catch { trace remove execution $cmd enter ::tb::profiler::enter }
    catch { trace remove execution $cmd leave ::tb::profiler::leave }
  }
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::profiler::trace_on
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Add all 'trace' commands
#------------------------------------------------------------------------
proc ::tb::profiler::trace_on {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable cmdlist
  # For safety, tries to remove any existing 'trace' commands
  ::tb::profiler::trace_off
  # Now adds 'trace' commands
  foreach cmd $cmdlist {
    catch { trace add execution $cmd enter ::tb::profiler::enter }
    catch { trace add execution $cmd leave ::tb::profiler::leave }
  }
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::profiler::dump
#------------------------------------------------------------------------
# Usage: profiler dump
#------------------------------------------------------------------------
# Dump profiler status
#------------------------------------------------------------------------
proc ::tb::profiler::dump {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Dump 'trace' information
  ::tb::profiler::trace_info
  # Dump non-array variables
  foreach var [lsort [info var ::tb::profiler::*]] {
    if {![info exists $var]} { continue }
    if {![array exists $var]} {
      puts "   $var: [subst $$var]"
    }
  }
  # Dump array variables
  foreach var [lsort [info var ::tb::profiler::*]] {
    if {![info exists $var]} { continue }
    if {[array exists $var]} {
      parray $var
    }
  }
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::profiler::trace_info
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Dump the 'trace' information on each command
#------------------------------------------------------------------------
proc ::tb::profiler::trace_info {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable cmdlist
  foreach cmd $cmdlist {
    if {[catch { puts "   $cmd:[trace info execution $cmd]" } errorstring]} {
       puts "   $cmd: <ERROR: $errorstring>"
    }
  }
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::profiler::method:version
#------------------------------------------------------------------------
# Usage: profiler version
#------------------------------------------------------------------------
# Return the version of the profiler
#------------------------------------------------------------------------
proc ::tb::profiler::method:version {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Version of the profiler
  variable version
#   puts " -I- Profiler version $version"
  return -code ok "Profiler version $version"
}

#------------------------------------------------------------------------
# ::tb::profiler::method:add
#------------------------------------------------------------------------
# Usage: profiler add [<options>]
#------------------------------------------------------------------------
# Add Vivado command(s) to the profiler
#------------------------------------------------------------------------
proc ::tb::profiler::method:add {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Add Vivado command(s) to the profiler (-help)
  variable cmdlist
  variable params
  if {$params(mode) == {started}} {
    error " -E- cannot add command(s) when the profiler is running. Use 'profiler stop' to stop the profiler"
  }
  if {[llength $args] == 0} {
    error " -E- no argument provided"
  }

  set error 0
  set commands [list]
  set force 0
  set tmp_args [list]
  set help 0
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -f -
      -force {
           set force 1
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
              lappend tmp_args $name
            }
      }
    }
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  if {$help} {
    puts [format {
  Usage: profiler add
              <pattern_of_commands>
              [<pattern_of_commands>]
              [-f|-force]
              [-help|-h]

  Description: Add commands to the profiler

  Example:
     profiler add *
     profiler add get_*
     profiler add -force *
} ]
    # HELP -->
    return {}
  }

  # Restore 'args'
  set args $tmp_args

  foreach pattern [::tb::profiler::lflatten $args] {
    if {[string first {*} $pattern] != -1} {
      # If the pattern contains an asterix '*' then the next 'foreach' loop
      # should not generate some of the warning messages since the user
      # just provided a pattern
      set verbose 0
    } else {
      # A specific command name has been provided, so the code below has to
      # be a little more verbose
      set verbose 1
    }
    foreach cmd [lsort [uplevel #0 [list info commands $pattern]]] {
      if {$force} {
        # If -force has been used, then trace any command, no question asked!
        lappend commands $cmd
        continue
      }
      # Otherwise, only trace Vivado commands
      if {[catch "set tmp \[help $cmd\]" errorstring]} {
        continue
      }
      if {[regexp -nocase -- {Tcl Built-In Commands} $tmp]} {
        if {$verbose} { puts " -W- the Tcl command '$cmd' cannot be profiled. Skipped" }
        continue
      }
#       if {[regexp -nocase -- {^(help|source|add|undo|redo|rename_ref|start_gui|stop_gui|show_objects|show_schematic|startgroup|end|endgroup)$} $cmd]} { }
#       if {[regexp -nocase -- {^(help|source|read_checkpoint|open_run|add|undo|redo|rename_ref|start_gui|stop_gui|show_objects|show_schematic|startgroup|end|endgroup)$} $cmd]} { }
      if {[regexp -nocase -- {^(help|source|add|undo|redo|rename_ref|start_gui|stop_gui|show_objects|show_schematic|startgroup|end|endgroup)$} $cmd]} {
        if {$verbose} { puts " -W- the Vivado command '$cmd' cannot be profiled. Skipped" }
        continue
      }
      lappend commands $cmd
    }
  }
  if {[llength $commands] == 0} {
    error " -E- no Vivado command matched '$args'"
  }
  puts " -I- [llength $commands] command(s) added to the profiler"
  puts " -I- Command(s): $commands"
  set cmdlist [concat $cmdlist $commands]
  set cmdlist [lsort -unique $cmdlist]
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::profiler::method:remove
#------------------------------------------------------------------------
# Usage: profiler remove <list>
#------------------------------------------------------------------------
# Remove Vivado command(s) from the profiler
#------------------------------------------------------------------------
proc ::tb::profiler::method:remove {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Remove Vivado command(s) from the profiler
  variable cmdlist
  variable params
  if {$params(mode) == {started}} {
    error " -E- cannot remove command(s) when the profiler is running. Use 'profiler stop' to stop the profiler"
  }
  if {[llength $args] == 0} {
    error " -E- no argument provided"
  }
  set commands [list]
  foreach pattern [::tb::profiler::lflatten $args] {
    foreach cmd [lsort [uplevel #0 [list info commands $pattern]]] {
      lappend commands $cmd
    }
  }
  set count 0
  set removed [list]
  foreach cmd $commands {
    if {[lsearch $cmdlist $cmd] != -1} {
      incr count
    }
    ::tb::profiler::lremove cmdlist $cmd
    lappend removed $cmd
  }
  set cmdlist [lsort -unique $cmdlist]
  puts " -I- $count command(s) have been removed"
  puts " -I- Removed command(s): [lsort -unique $removed]"
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::profiler::method:reset
#------------------------------------------------------------------------
# Usage: profiler reset
#------------------------------------------------------------------------
# Reset the profiler
#------------------------------------------------------------------------
proc ::tb::profiler::method:reset {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Reset the profiler
  variable cmdlist
  variable tmstart
  variable tmend
  variable params
  variable db
  if {$params(mode) == {started}} {
    error " -E- cannot reset the profiler when running. Use 'profiler stop' to stop the profiler"
  }
#   set cmdlist [list]
  set tmstart [list]
  set tmend [list]
  set db [list]
  set params(collectionResultDisplayLimit) -1
  puts " -I- profiler reset"
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::profiler::method:status
#------------------------------------------------------------------------
# Usage: profiler status
#------------------------------------------------------------------------
# Return the status of the profiler
#------------------------------------------------------------------------
proc ::tb::profiler::method:status {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Status of the profiler
  variable cmdlist
  variable params
  if {$params(mode) == {started}} {
    puts " -I- the profiler is started"
  } else {
    puts " -I- the profiler is stopped"
  }
  puts " -I- [llength $cmdlist] command(s) are traced:"
  puts " -I- Command(s): $cmdlist"
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::profiler::method:start
#------------------------------------------------------------------------
# Usage: profiler start [<options>]
#------------------------------------------------------------------------
# Start the profiler:
#   - adds the 'trace' commands
#   - starts the timer
#------------------------------------------------------------------------
proc ::tb::profiler::method:start {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Start the profiler (-help)
  variable cmdlist
  variable tmstart
  variable tmend
  variable params
  if {$params(mode) == {started}} {
    error " -E- the profiler is already running. Use 'profiler stop' to stop the profiler"
  }

  set error 0
  set incremental 0
  set src_info 0
  set collection_display_limit $params(collectionResultDisplayLimit)
  set help 0
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -incr {
           set incremental 1
      }
      -src -
      -src_info {
           set src_info 1
      }
      -limit -
      -collection_display_limit {
          set collection_display_limit [lshift args]
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

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  if {$help} {
    puts [format {
  Usage: profiler start
              [-incr]
              [-src_info]
              [-collection_display_limit|-limit <num>]
              [-help|-h]

  Description: Start the profiler

  Example:
     profiler start
     profiler start -incr -src_info -collection_display_limit 500
} ]
    # HELP -->
    return {}
  }

  if {[llength $cmdlist] == 0} {
    error " -E- no command has been added to the profiler. Use 'profiler add' to add Vivado commands"
  }

  if {!$incremental} {
    # Reset the profiler
    ::tb::profiler::method:reset
  }
  # Used the -src_info to show detailed information on each XDC constraint?
  if {$src_info} {
    if {[lsearch $cmdlist get_property] != -1} {
      puts " -W- Removing 'get_property' from the list of commands to be traced (uncompatible with -src_info)"
      ::tb::profiler::lremove cmdlist get_property
    }
    if {[lsearch $cmdlist current_design] != -1} {
      puts " -W- Removing 'current_design' from the list of commands to be traced (uncompatible with -src_info)"
      ::tb::profiler::lremove cmdlist current_design
    }
    interp alias {} ::tb::profiler::leave {} ::tb::profiler::leave2
  } else {
    interp alias {} ::tb::profiler::leave {} ::tb::profiler::leave1
  }
  # Set the parameter tcl.collectionResultDisplayLimit if necessary
  if {$collection_display_limit != -1} {
    # Save the current parameter value so that it can be restored
    # Catch the following code as 'get_param' only works if a project is already opened
    catch {
      puts " -I- setting the parameter 'tcl.collectionResultDisplayLimit' to '$collection_display_limit'"
      set params(collectionResultDisplayLimit:ORG) [get_param tcl.collectionResultDisplayLimit]
      set_param tcl.collectionResultDisplayLimit $collection_display_limit
    }
  }
  # Add 'trace' on the commands
  ::tb::profiler::trace_on
  # Start the timer
  lappend tmstart [clock microseconds]
  set params(mode) {started}
  if {!$incremental} {
    puts " -I- profiler started on [clock format [expr [lindex $tmstart end] / 1000000]]"
  } else {
    puts " -I- profiler started in incremental mode on [clock format [expr [lindex $tmstart end] / 1000000]]"
  }
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::profiler::method:stop
#------------------------------------------------------------------------
# Usage: profiler stop
#------------------------------------------------------------------------
# Stop the profiler
#------------------------------------------------------------------------
proc ::tb::profiler::method:stop {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Stop the profiler
  variable tmend
  variable params
  if {$params(mode) == {stopped}} {
    error " -E- the profiler is not running. Use 'profiler start' to start the profiler"
  }
  lappend tmend [clock microseconds]
  set params(mode) {stopped}
  # Remove 'trace' from the commands
  ::tb::profiler::trace_off
  # Restoring the parameter tcl.collectionResultDisplayLimit
  if {[info exists params(collectionResultDisplayLimit:ORG)]} {
    # Catch the following code as 'get_param' only works if a project is already opened
    catch {
      puts " -I- restoring the parameter 'tcl.collectionResultDisplayLimit' to '$params(collectionResultDisplayLimit:ORG)'"
      set_param tcl.collectionResultDisplayLimit $params(collectionResultDisplayLimit:ORG)
      unset params(collectionResultDisplayLimit:ORG)
    }
  }
  puts " -I- profiler stopped on [clock format [expr [lindex $tmend end] / 1000000]]"
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::profiler::method:summary
#------------------------------------------------------------------------
# Usage: profiler summary [<options>]
#------------------------------------------------------------------------
# Print the profiler summary
#------------------------------------------------------------------------
proc ::tb::profiler::method:summary {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Return the profiler summary (-help)
  variable cmdlist
  variable tmstart
  variable tmend
  variable params
  variable db
  variable summary
  if {$params(mode) == {started}} {
    error " -E- the profiler is still running. Use 'profiler stop' to stop the profiler"
  }
  if {([llength $tmstart] == 0) || ([llength $tmend] == 0)} {
    error " -E- the profiler has not been run. Use 'profiler start' to start the profiler"
  }

  set error 0
  set return_string 0
  set logfile {}
  set help 0
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -return_string {
           set return_string 1
      }
      -log {
           set logfile [lshift args]
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

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  if {$help} {
    puts [format {
  Usage: profiler summary
              [-return_string]
              [-log <filename>]
              [-help|-h]

  Description: Return the profiler summary

  Example:
     profiler summary
     profiler summary -return_string
     profiler summary -log profiler.log
} ]
    # HELP -->
    return {}
  }

  # Just in case: destroy previous matrix if it was not done before
  catch {summary destroy}
  struct::matrix summary
  set output [list]
  lappend output "--------- PROFILER STATS ---------------------------------------------"
  array set tmp {}
  array set cnt {}
  array set sum {}
  array set min {}
  array set max {}
  set commands [list]
  # Total time inside the traced commands
  set totaltime 0
  # Total runtime
  set totalruntime 0
  # Multiple runs if 'profiler start -incr' has been used
  foreach t_start $tmstart t_end $tmend {
    incr totalruntime [expr $t_end - $t_start]
  }
  set ID 0
  foreach i $db {
    lassign $i clk enter cmdline code result src_info
    set cmd [lindex $cmdline 0]
    # Skip commands that do not belong anymore to the list of commands to be traced
    # This can happen if the user remove some commands with 'profiler remove' after
    # the profiler was run
    if {[lsearch $cmdlist $cmd] == -1} {
      continue
    }
    if {![info exists cnt($cmd)]} {set cnt($cmd) 0}
    if {![info exists sum($cmd)]} {set sum($cmd) 0}
    if {![info exists min($cmd)]} {set min($cmd) 0}
    if {![info exists max($cmd)]} {set max($cmd) 0}
    if {$enter} {
      lappend tmp($cmd) $clk
    } else {
      set delta [expr {$clk-[lindex $tmp($cmd) end]}]
      if {[llength $tmp($cmd)] == 1} {
        unset tmp($cmd)
      } else {
        set tmp($cmd) [lrange $tmp($cmd) 0 end-1]
      }
      incr cnt($cmd) 1
      incr sum($cmd) $delta
      # Some commands should not contribute to the total runtime
      if {![regexp {^(open_checkpoint|read_checkpoint|read_xdc|open_run|open_project)$} $cmd]} {
        incr totaltime $delta
      }
      if {$min($cmd) == 0 || $delta < $min($cmd)} {set min($cmd) $delta}
      if {$max($cmd) == 0 || $delta > $max($cmd)} {set max($cmd) $delta}
      # Save the command inside the Tcl variable
      lappend commands [list $ID $delta $cmdline $code $result $src_info]
      incr ID
    }
  }
  if {[llength $tmstart] > 1} {
    lappend output "Number of profiler runs: [llength $tmstart]"
  }
  lappend output "Total time: [expr {$totalruntime/1000.0}]ms ([format %.2f%% [expr {$totaltime*100.0/$totalruntime}]] overhead + non-profiled commands)"
  summary add columns 7
  summary add row [list {command:} {min} {max} {avg} {total} {ncalls} {%runtime}]
  set ncalls 0
  foreach cmd $cmdlist {
    if {![info exists sum($cmd)]} {
      continue
    }
    set avg [expr {int(1.0*$sum($cmd)/$cnt($cmd))}]
    set percent [expr {$sum($cmd)*100.0/($totaltime)}]

    # The commands that do not contribute to the total runtime are formatted differently
    if {![regexp {^(open_checkpoint|read_checkpoint|read_xdc|open_run|open_project)$} $cmd]} {
      summary add row [list $cmd \
                         [format {%.3fms} [expr $min($cmd) / 1000.0]] \
                         [format {%.3fms} [expr $max($cmd) / 1000.0]] \
                         [format {%.3fms} [expr $avg / 1000.0]] \
                         [format {%.3fms} [expr $sum($cmd) / 1000.0]] \
                         $cnt($cmd) \
                         [format {%.2f%%} $percent] \
                         ]
      incr ncalls $cnt($cmd)
    } else {
      summary add row [list [format {(%s)} $cmd] \
                         [format {(%.3fms)} [expr $min($cmd) / 1000.0]] \
                         [format {(%.3fms)} [expr $max($cmd) / 1000.0]] \
                         [format {(%.3fms)} [expr $avg / 1000.0]] \
                         [format {(%.3fms)} [expr $sum($cmd) / 1000.0]] \
                         [format {(%s)} $cnt($cmd)] \
                         {-} \
                         ]
    }

  }
  summary add row [list {-------} {-------} {-------} {-------} {-------} {-----} {-----} ]
  summary add row [list {TOTAL} {} {} {} [format {%.3fms} [expr $totaltime / 1000.0]] $ncalls {100%}]
  lappend output [summary format 2string]
  lappend output "----------------------------------------------------------------------"
  summary destroy
  if {$logfile != {}} {
    if {[catch {
      set FH [open $logfile w]
      puts $FH "# [::tb::profiler::method:version]"
      puts $FH "# Created on [clock format [clock seconds]]"
      puts $FH "\n############## STATISTICS #################\n"
      # Summary table
      foreach i [split [join $output \n] \n] {
        puts $FH [format {#  %s} $i]
      }
      puts $FH "\n############## TOP 50 RUNTIMES ##############\n"
      # Select the top 100 offenders from a runtime perspective
      set offenders [lrange [lsort -index 1 -decreasing -integer $commands] 0 49]
      struct::matrix summary
      summary add columns 3
      summary add row [list {ID} {runtime} {command}]
      summary add row [list {--} {-------} {-------}]
      foreach i $offenders {
        lassign $i ID delta cmdline code result src_info
        if {[string length $cmdline] > 200} {
          # Cut the command line at first space after the first 200 characters
          set idx [string first " " [string range $cmdline 200 end]]
          set cmdline [format {%s ... <%s more characters>} [string range $cmdline 0 [expr 200 + $idx]] [expr [string length $cmdline] -200 -$idx] ]
        }
        summary add row [list $ID "[expr $delta / 1000.0]ms" $cmdline]
      }
      foreach i [split [summary format 2string] \n] {
        puts $FH [format {#  %s} $i]
      }
      summary destroy
      puts $FH "\n############## DETAILED SUMMARY ###########"
      foreach i $commands {
        lassign $i ID delta cmdline code result src_info
        set cmd [lindex $cmdline 0]
        if {$src_info != {}} {
          puts $FH "\n# ID:$ID time:[format {%.3fms} [expr $delta / 1000.0]] $src_info"
        } else {
          puts $FH "\n# ID:$ID time:[format {%.3fms} [expr $delta / 1000.0]] "
        }
        if {[string length $cmdline] > 1000} {
          # Cut the command line at first space after the first 1000 characters
          set idx [string first " " [string range $cmdline 1000 end]]
          set cmdline [format {%s ... <%s more characters>} [string range $cmdline 0 [expr 1000 + $idx]] [expr [string length $cmdline] -1000 -$idx] ]
        }
        puts $FH $cmdline
        if {$code != 0} {
          puts $FH [format { -E- returned error code: %s} $code]
        }
        if {[regexp {^(report_.+)$} $cmd]} {
          # Special treatment if the executed command is a report. In this case
          # just print the report as is
          if {$result != {}} {
            foreach el [split $result \n] {
              puts $FH [format {#    %s} $el]
            }
          }
        } else {
          catch {
            if {$result != {}} {
              if {[llength $result] == 1} {
                puts $FH [format {#    %s} $result]
              } else {
                puts $FH [format {# %d elements:} [llength $result]]
                foreach el [lsort $result] {
                  puts $FH [format {#    %s} $el]
                }
              }
            }
          }
        }
      }
    } errorstring]} {
        puts " -I- failed to generate log file '$logfile': $errorstring"
    } else {
        puts " -I- log file '$logfile' has been created"
    }
    close $FH
  }
  if {$return_string} {
    return -code ok [join $output \n]
  } else {
    puts [join $output \n]
    return -code ok
  }
}

#------------------------------------------------------------------------
# ::tb::profiler::method:time
#------------------------------------------------------------------------
# Usage: profiler time [<options>]
#------------------------------------------------------------------------
# Profile the specified code
#------------------------------------------------------------------------
proc ::tb::profiler::method:time {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Profile the inline Tcl code (-help)
  variable cmdlist
  variable params
  if {$params(mode) == {started}} {
    error " -E- the profiler is already running. Use 'profiler stop' to stop the profiler"
  }

  set error 0
  set sections [list]
  set startOptions [list]
  set logfile {}
  set help 0
  if {[llength $args] == 0} { incr help }
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -incr {
          lappend startOptions {-incr}
      }
      -src -
      -src_info {
          lappend startOptions {-src_info}
      }
      -limit -
      -collection_display_limit {
          lappend startOptions {-limit}
          lappend startOptions [lshift args]
      }
      -log {
           set logfile [lshift args]
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
              # Append to the list of Tcl sections(s) to execute
              lappend sections $name
            }
      }
    }
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  if {$help} {
    puts [format {
  Usage: profiler time <SectionOfTclCode>
              [-incr]
              [-src_info]
              [-collection_display_limit|-limit <num>]
              [-log <filename>]
              [-help|-h]

  Description: Run the profiler on an inline Tcl code

  Example:
     profiler time { read_xdc ./constraints.xdc } -collection_display_limit 500
     profiler time -incr -src_info { read_xdc ./constraints.xdc } -log profiler.log
} ]
    # HELP -->
    return {}
  }

  if {[llength $cmdlist] == 0} {
    error " -E- no command has been added to the profiler. Use 'profiler add' to add Vivado commands"
  }

  if {[llength $sections] == 0} {
    error " -E- no in-line code provided"
  }

  # Start the profiler
  eval [concat ::tb::profiler::method:start $startOptions]

  # Execute each section of Tcl code
  foreach section $sections {
    set res {}
    if {[catch { set res [uplevel 1 [concat eval $section]] } errorstring]} {
      ::tb::profiler::method:stop
      error " -E- the profiler failed with the following error: $errorstring"
    }
  }

  # Stop the profiler
  ::tb::profiler::method:stop

  # Generate the summary and log file if requested
  if {$logfile != {}} {
    ::tb::profiler::method:summary -log $logfile
  }

  return -code ok
}

#------------------------------------------------------------------------
# ::tb::profiler::method:configure
#------------------------------------------------------------------------
# Usage: profiler configure [<options>]
#------------------------------------------------------------------------
# Configure some of the profiler parameters
#------------------------------------------------------------------------
proc ::tb::profiler::method:configure {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Configure the profiler (-help)
  variable params
  set error 0
  set help 0
  if {[llength $args] == 0} {
    set help 1
  }
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -limit -
      -collection_display_limit {
          set params(collectionResultDisplayLimit) [lshift args]
      }
      -detail -
      -details {
          set params(expandObjects) 1
      }
      -summary -
      -summary {
          set params(expandObjects) 0
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
  Usage: profiler configure
              [-collection_display_limit|-limit <num>]
              [-summary][-details]
              [-help|-h]

  Description: Configure the profiler

    -details: expand inside the log file the list of objects returned by each command
    -summary: summarize inside the log file the number of objects returned by by each command

    Default behavior is -summary

  Example:
     profiler configure -collection_display_limit 500 -details
} ]
    # HELP -->
    return -code ok
  }
  return -code ok
}



#################################################################################

namespace import ::tb::profiler

# Information
# profiler -help
# # puts " Add commands to the profiler with:"
# # puts "     profiler add *\n"
# profiler add *

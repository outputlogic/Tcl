####################################################################################################
# HEADER_BEGIN
# COPYRIGHT NOTICE
# Copyright 2001-2014 Xilinx Inc. All Rights Reserved.
# http://www.xilinx.com/support
# HEADER_END
####################################################################################################

# Proc to reload current script
proc [file tail [info script]] {} " source [info script]; puts \" [info script] reloaded\" "

interp alias {} s {} snapshot.tcl

proc do {args} {
  snapshot extract -save
  tb::snapshot::db2csv -file metrics.csv
}

# lappend auto_path /home/dpefour/git/scripts/toolbox
# package require toolbox

# Script usage:
#    snapshot add *    (-help for additional help)
#    snapshot start    (-help for additional help)
#      <execute code>
#    snapshot stop
#    snapshot summary  (-help for additional help)

# Is the script being run from within vivado?
if {[package provide Vivado] == {}} {
#   error " ERROR - script needs Vivado to work"
#   return
  switch $::tcl_platform(platform) {
    unix {
      lappend auto_path {/home/dpefour/TCL/tcllib1.14/packages}
      lappend auto_path {/home/dpefour/root/usr/lib/sqlite3.8.0.2}
    }
    windows {
      # For SQLITE3 and other packages under Windows
      lappend auto_path {C:\Xilinx\lib}
    }
    default {
      error " ERROR - unknown platform '$tcl_platform(platform)'"
    }
  }
} else {
  switch $::tcl_platform(platform) {
    unix {
      # TCLLIB is provided with Vivado, no need to include it
#       lappend auto_path {/home/dpefour/TCL/tcllib1.14/packages}
      lappend auto_path {/home/dpefour/root/usr/lib/sqlite3.8.0.2}
    }
    windows {
      # For SQLITE3 and other packages under Windows
      lappend auto_path {C:\Xilinx\lib}
    }
    default {
      error " ERROR - unknown platform '$tcl_platform(platform)'"
    }
  }
}

# package require Vivado 1.2014.1
package require sqlite3
package require struct::matrix
package require report
package require csv

namespace eval ::tb::snapshot::extract {
    proc default {} {
      variable [namespace parent]::params
      variable [namespace parent]::verbose
      variable [namespace parent]::debug
      # Vivado related statistics
      snapshot set vivado.version [version -short]
      snapshot set vivado.details [version]
      catch { snapshot set vivado.plateform $::tcl_platform(platform)  }
      catch { snapshot set vivado.os $::tcl_platform(os)  }
      catch { snapshot set vivado.osVersion $::tcl_platform(osVersion)  }
      # Project related statistics
      set project [current_project -quiet]
      if {$project != {}} {
        snapshot set project.details [report_property -quiet -return_string $project]
        snapshot set project.dir [file normalize [get_property -quiet DIRECTORY $project]]
        snapshot set project.part [get_property -quiet PART $project]
        snapshot set project.runs [get_runs -quiet]
      }
#       set run {}
      # Run related statistics
      set run [current_run -quiet]
      if {$run != {}} {
        snapshot set run.details [report_property -quiet -return_string $run]
        snapshot set run.dir [file normalize [get_property -quiet DIRECTORY $run]]
        snapshot set run.part [get_property -quiet PART $run]
        snapshot set run.parent [get_property -quiet PARENT $run]
        snapshot set run.progress [get_property -quiet PROGRESS $run]
        snapshot set run.stats.elapsed [get_property -quiet STATS.ELAPSED $run]
        snapshot set run.stats.tns [get_property -quiet STATS.TNS $run]
        snapshot set run.stats.ths [get_property -quiet STATS.THS $run]
        snapshot set run.stats.wns [get_property -quiet STATS.WNS $run]
        snapshot set run.stats.whs [get_property -quiet STATS.WHS $run]
        snapshot set run.stats.tpws [get_property -quiet STATS.TPWS $run]
      }
      # Messages related statistics
      snapshot set msg.error [get_msg_config -quiet -count -severity {error}]
      snapshot set msg.criticalwarning [get_msg_config -quiet -count -severity {critical warning}]
      snapshot set msg.warning [get_msg_config -quiet -count -severity {warning}]
      snapshot set msg.info [get_msg_config -quiet -count -severity {info}]
      # Design related statistics
      snapshot set design.nets [llength [get_nets -quiet -hier]]
      snapshot set design.cells [llength [get_cells -quiet -hier]]
      snapshot set design.ports [llength [get_ports -quiet]]
      snapshot set design.clocks.list [lsort [get_clocks -quiet]]
      snapshot set design.clocks.num [llength [get_clocks -quiet]]
      snapshot set design.clocks.list [lsort [get_clocks -quiet]]
      snapshot set design.clocks.num [llength [get_clocks -quiet]]
      snapshot set design.allclocks.list [lsort [get_clocks -quiet -include_generated_clocks]]
      snapshot set design.allclocks.num [llength [get_clocks -quiet -include_generated_clocks]]
      snapshot set design.pblocks.list [lsort [get_pblocks -quiet]]
      snapshot set design.pblocks.num [llength [get_pblocks -quiet]]
      snapshot set design.ips.list [lsort [get_ips -quiet]]
      snapshot set design.ips.num [llength [get_ips -quiet]]
      # Various reports
      if {1} {
        catch {
          set filename [format {report_compile_order.%s} [clock seconds]]
          report_compile_order -constraints -file $filename
          set FH [open $filename {r}]
          set report [read $FH]
          close $FH
          file delete $filename
          snapshot set route.compile_order.constraints $report
        }
      }
      snapshot set route.status [report_route_status -quiet -return_string]
      snapshot set report.route_status [report_route_status -quiet -return_string]
      snapshot set report.timing_summary [report_timing_summary -quiet -return_string]
      snapshot set report.clocks [report_clocks -quiet -return_string]
      snapshot set report.clock_interaction [report_clock_interaction -quiet -return_string]
      snapshot set report.clock_utilization [report_clock_utilization -quiet -return_string]
      snapshot set report.clock_networks [report_clock_networks -quiet -return_string]
      snapshot set report.utilization [report_utilization -quiet -return_string]
      snapshot set report.high_fanout_nets [report_high_fanout_nets -quiet -return_string]
      snapshot set report.ip_status [report_ip_status -quiet -return_string]
      catch {snapshot set report.ram_utilization [report_ram_utilization -quiet -return_string]}
      if {[llength [get_slrs -quiet]] > 1} { snapshot set report.slr [report_utilization -quiet -slr -return_string] }
    }
}

namespace eval ::tb {
    namespace export snapshot
}

# namespace eval ::tb::snapshot::extract {
#   proc set_metric_value {args} {
#     # Summary :
#     # Argument Usage:
#     # Return Value:
#
#     if {[llength $args] < 2} {
#       error "wrong number of parameters: set_metric_value <metric> <value>"
#     }
#     [namespace parent]::method::set [lindex $args 0] [lrange $args 1 end]
#     return 0
#   }
#
#   proc get_metric_value {args} {
#     # Summary :
#     # Argument Usage:
#     # Return Value:
#
#     if {[llength $args] != 1} {
#       error "wrong number of parameters: get_metric_value <metric>"
#     }
#     return [[namespace parent]::method::get [lindex $args 0]]
#   }
# }

########################################################################################
##
## Company:        Xilinx, Inc.
## Created by:     David Pefourque
##
## Version:        2014.05.12
## Tool Version:   Vivado 2013.1
## Description:    This utility provides a simple way to extract and save metrics
##
########################################################################################

########################################################################################
## 2014.05.12 - Updated database to 1.3
##            - Added release/description/parentid to database
##            - Added support for HTML format to method db2dir
##            - Added -time to methods configure/extract/save
##            - Removed dependency to Vivado
##            - Other enhancements and fixes
## 2014.05.05 - Added method db2dir
##            - Added method addparam
##            - Updated the list of default metrics to extract
##            - Other enhancements and fixes
## 2014.03.06 - Initial release
########################################################################################

proc ::tb::snapshot { args } {
  # Summary : Tcl snapshot

  # Argument Usage:
  # args : sub-command. The supported sub-commands are: start | stop | summary | add | remove | reset | status

  # Return Value:
  # returns the status or an error code

#   if {[catch {set res [uplevel [concat ::tb::snapshot::snapshot $args]]} errorstring]} {
#     error " -E- the snapshot failed with the following error: $errorstring"
#   }
  return [uplevel [concat ::tb::snapshot::snapshot $args]]
}


###########################################################################
##
## Package for taking snapshots of metrics
##
###########################################################################

#------------------------------------------------------------------------
# Namespace for the package
#------------------------------------------------------------------------

# Trick to silence the linter
eval [list namespace eval ::tb::snapshot {
  variable version {2014.05.12}
  variable params
  variable metrics
  variable summary
  variable snapshotlog [list]
  variable logFH {}
  variable logFile {}
#   variable verbose 0
  variable verbose 1
  variable debug 0
  catch {unset params}
  catch {unset metrics}
  array set params [list db {} project {} run {} version {} experiment {} step {} release {} description {} time 0]
  array set metrics [list ]
} ]

#------------------------------------------------------------------------
# ::tb::snapshot::snapshot
#------------------------------------------------------------------------
# Main function
#------------------------------------------------------------------------
proc ::tb::snapshot::snapshot { args } {
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
      return [eval [concat ::tb::snapshot::dump] ]
    }
    load {
      return [eval [concat ::tb::snapshot::method:load $args] ]
    }
    ? -
    -h -
    -help {
      incr show_help
    }
    default {
      return [eval [concat ::tb::snapshot::do ${method} $args] ]
    }
  }

  if {$show_help} {
    # <-- HELP
    print stdout ""
    ::tb::snapshot::method:?
    print stdout [format {
   Description: Utility to provides a simple way to extract and save metrics

   Example:
      snapshot configure -db metrics.db -newdb
      snapshot set metric1 value1
      snapshot extract
      snapshot save

    } ]
    # HELP -->
    return
  }

}

#------------------------------------------------------------------------
# ::tb::snapshot::lshift
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Stack function
#------------------------------------------------------------------------
proc ::tb::snapshot::lshift {inputlist} {
  # Summary :
  # Argument Usage:
  # Return Value:

  upvar $inputlist argv
  set arg  [lindex $argv 0]
  set argv [lrange $argv 1 end]
  return $arg
}

#------------------------------------------------------------------------
# ::tb::snapshot::list2csv
#------------------------------------------------------------------------
# **INTERNAL**
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
# ::tb::snapshot::txt2html
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# String to HTML conversion
#------------------------------------------------------------------------
proc ::tb::snapshot::txt2html {string} {
  # Summary :
  # Argument Usage:
  # Return Value:

  return [string map {&lt; &amp;lt; &gt; &amp;gt; &amp; &amp;amp; \&quot; &amp;quot;} $string]
}

#------------------------------------------------------------------------
# ::tb::snapshot::truncateText
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Format a value to only show the first n characters of the first line
#------------------------------------------------------------------------
proc ::tb::snapshot::truncateText {value {max 50}} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # If the value is multi-lines, return only the first n characters of the first line
  set lines [split $value \n]
  if {[llength $lines] > 1} { set flag 1 } else { set flag 0 }
  set str [lindex $lines 0]
  if {[string length $str] > $max} { set flag 1 }
  if {$flag} {
#     return [format {%s  <...>} [string range $str 0 [expr $max - 1]]]
    set str [string range $str 0 [expr $max - 1]]
    return [format {%s  <%d more characters>} \
                      $str \
                      [expr [string length $value] - [string length $str]] \
           ]
  } else {
    return $value
  }
}

# #------------------------------------------------------------------------
# # ::tb::snapshot::lflatten
# #------------------------------------------------------------------------
# # **INTERNAL**
# #------------------------------------------------------------------------
# # Flatten a nested list
# #------------------------------------------------------------------------
# proc ::tb::snapshot::lflatten {inputlist} {
#   # Summary :
#   # Argument Usage:
#   # Return Value:
#
#   while { $inputlist != [set inputlist [join $inputlist]] } { }
#   return $inputlist
# }
#
# #------------------------------------------------------------------------
# # ::tb::snapshot::lremove
# #------------------------------------------------------------------------
# # **INTERNAL**
# #------------------------------------------------------------------------
# # Remove element from a list
# #------------------------------------------------------------------------
# proc ::tb::snapshot::lremove {_inputlist element} {
#   # Summary :
#   # Argument Usage:
#   # Return Value:
#
#   upvar 1 $_inputlist inputlist
#   set pos [lsearch -exact $inputlist $element]
#   set inputlist [lreplace $inputlist $pos $pos]
# }

#------------------------------------------------------------------------
# ::tb::snapshot::docstring
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Return the embedded help of a proc
#------------------------------------------------------------------------
proc ::tb::snapshot::docstring {procname} {
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
# ::tb::snapshot::do
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Dispatcher with methods
#------------------------------------------------------------------------
proc ::tb::snapshot::do {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  if {[llength $args] == 0} {
#     error " -E- wrong number of parameters: snapshot <sub-command> \[<arguments>\]"
    set method {?}
  } else {
    # The first argument is the method
    set method [lshift args]
  }
  if {[info proc ::tb::snapshot::method:${method}] == "::tb::snapshot::method:${method}"} {
    eval ::tb::snapshot::method:${method} $args
  } else {
    # Search for a unique matching method among all the available methods
    set match [list]
    foreach procname [info proc ::tb::snapshot::method:*] {
      if {[string first $method [regsub {::tb::snapshot::method:} $procname {}]] == 0} {
        lappend match [regsub {::tb::snapshot::method:} $procname {}]
      }
    }
    switch [llength $match] {
      0 {
        error " -E- unknown sub-command $method"
      }
      1 {
        set method $match
        return [eval ::tb::snapshot::method:${method} $args]
      }
      default {
        error " -E- multiple sub-commands match '$method': $match"
      }
    }
  }
}

#------------------------------------------------------------------------
# ::tb::snapshot::method:?
#------------------------------------------------------------------------
# Usage: snapshot ?
#------------------------------------------------------------------------
# Return all the available methods. The methods with no embedded help
# are not displayed (i.e hidden)
#------------------------------------------------------------------------
proc ::tb::snapshot::method:? {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # This help message
  print stdout "   Usage: snapshot <sub-command> \[<arguments>\]"
  print stdout "   Where <sub-command> is:"
  foreach procname [lsort [info proc ::tb::snapshot::method:*]] {
    regsub {::tb::snapshot::method:} $procname {} method
    set help [::tb::snapshot::docstring $procname]
    if {$help ne ""} {
      print stdout "         [format {%-12s%s- %s} $method \t $help]"
    }
  }
  print stdout ""
}

#------------------------------------------------------------------------
# ::tb::snapshot::method:configure
#------------------------------------------------------------------------
# Usage: snapshot configure [<options>]
#------------------------------------------------------------------------
# Configure some of the snapshot parameters
#------------------------------------------------------------------------
proc ::tb::snapshot::method:configure {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Configure the snapshot
  variable params
  variable verbose
  variable debug
  variable logFH
  variable logFile
  set reset 0
  set error 0
  set help 0
  if {[llength $args] == 0} {
    set help 1
  }
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -db {
           set params(db) [lshift args]
#            set params(db) [file normalize [lshift args]]
#            if {$params(db) == {}} {
#              error " -E- empty database name"
#            }
           set path [file normalize $params(db)]
           set dir [file dirname $path]
           if {![file isdirectory $dir]} {
             print warning "path '$dir' does not exist"
           } elseif {$verbose} {
             print info "database location: $path"
           }
      }
      -p -
      -project {
           set params(project) [lshift args]
      }
      -r -
      -run {
           set params(run) [lshift args]
      }
      -ver -
      -version {
           set params(version) [lshift args]
      }
      -e -
      -experiment {
           set params(experiment) [lshift args]
      }
      -s -
      -step {
           set params(step) [lshift args]
      }
      -rel -
      -release -
      -vivado {
           set params(release) [lshift args]
      }
      -d -
      -desc -
      -description {
           set params(description) [lshift args]
      }
      -log {
           set logFile [lshift args]
           set logFH [open $logFile {w}]
           print info "Opening log file: [file normalize $logFile] on [clock format [clock seconds]]"
           print log "#####################################"
           print log "## [clock format [clock seconds]]"
           print log "#####################################"
      }
      -time {
           set params(time) [lshift args]
      }
      -nolog {
           if {$logFH != {}} {
            close $logFH
            set logFH {}
            print info "Closing log file: [file normalize $logFile] on [clock format [clock seconds]]"
           }
           set logFile {}
      }
      -newdb {
           set reset 1
      }
      -verbose {
           set verbose 1
      }
      -quiet {
           set verbose 0
      }
      -debug {
           set debug 1
      }
      -nodebug {
           set debug 0
      }
      -h -
      -help {
           set help 1
      }
      default {
            if {[string match "-*" $name]} {
              print error "option '$name' is not a valid option."
              incr error
            } else {
              print error "option '$name' is not a valid option."
              incr error
            }
      }
    }
  }

  if {$help} {
    print stdout [format {
  Usage: snapshot configure
              [-db <filename>]
              [-newdb]
              [-project|-p <string>]
              [-run|-r <string>]
              [-version|-ver <string>]
              [-experiment|-e <string>]
              [-step|-s <string>]
              [-release|-rel <string>]
              [-description|-desc|-d <string>]
              [-time <time_in_seconds>]
              [-log <logfile>|-nolog]
              [-verbose|-quiet]
              [-help|-h]

  Description: Configure the snapshot

  Example:
     snapshot configure -newdb
} ]
    # HELP -->
    return -code ok
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  if {$reset} {
    set db [getDB]
    if {[file exists $db]} {
      if {[catch {file delete -force $db} errorstring]} {
#         error " -E- $errorstring"
        print error "cannot delete database $db"
      } else {
        if {$verbose} {
          print info "Deleting database $db"
        }
      }
    }
  }

  return -code ok
}

#------------------------------------------------------------------------
# ::tb::snapshot::method:extract
#------------------------------------------------------------------------
# Usage: snapshot extract [<options>]
#------------------------------------------------------------------------
# Launch the extraction of all the metrics for the current snapshot
#------------------------------------------------------------------------
proc ::tb::snapshot::method:extract {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Extract all the metrics
  variable params
  variable verbose
  variable debug
  # Save current state of verbosity & debug
  set _verbose_ $verbose
  set _debug_ $debug
  set mode {extract}
  set time 0
  set save 0
  set error 0
  set help 0
#   if {[llength $args] == 0} {
#     set help 1
#   }
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -list {
        set mode {list}
      }
      -save {
        set save 1
      }
      -time {
        ::tb::snapshot::method:configure -time [lshift args]
      }
      -reset {
        ::tb::snapshot::method:reset
      }
      -db {
        ::tb::snapshot::method:configure -db [lshift args]
      }
      -p -
      -project {
        ::tb::snapshot::method:configure -project [lshift args]
      }
      -r -
      -run {
        ::tb::snapshot::method:configure -run [lshift args]
      }
      -ver -
      -version {
        ::tb::snapshot::method:configure -version [lshift args]
      }
      -e -
      -experiment {
        ::tb::snapshot::method:configure -experiment [lshift args]
      }
      -s -
      -step {
        ::tb::snapshot::method:configure -step [lshift args]
      }
      -rel -
      -release -
      -vivado {
           ::tb::snapshot::method:configure -release [lshift args]
      }
      -d -
      -desc -
      -description {
           ::tb::snapshot::method:configure -description [lshift args]
      }
      -newdb {
        ::tb::snapshot::method:configure -newdb
      }
      -verbose {
        ::tb::snapshot::method:configure -verbose
      }
      -quiet {
        ::tb::snapshot::method:configure -quiet
      }
      -debug {
        ::tb::snapshot::method:configure -debug
      }
      -nodebug {
        ::tb::snapshot::method:configure -nodebug
      }
      -h -
      -help {
           set help 1
      }
      default {
            if {[string match "-*" $name]} {
              print error "option '$name' is not a valid option."
              incr error
            } else {
              print error "option '$name' is not a valid option."
              incr error
            }
      }
    }
  }

  if {$help} {
    print stdout [format {
  Usage: snapshot extract
          +-------------------------+
              [-list]
              [-save]
          +-------------------------+
              [-reset]
              [-db <filename>]
              [-newdb]
              [-project|-p <string>]
              [-run|-r <string>]
              [-version|-ver <string>]
              [-experiment|-e <string>]
              [-step|-s <string>]
              [-release|-rel <string>]
              [-description|-desc|-d <string>]
              [-time <time_in_seconds>]
              [-verbose|-quiet]
              [-help|-h]

  Description: Extract the metrics for the snapshot

  Example:
     snapshot extract -experiment noHighFanout
     snapshot extract -experiment noHighFanout -save
} ]
    # HELP -->
    # Restore state of verbosity & debug
    set verbose $_verbose_
    set debug $_debug_
    return -code ok
  }

  if {$error} {
    # Restore state of verbosity & debug
    set verbose $_verbose_
    set debug $_debug_
    error " -E- some error(s) happened. Cannot continue"
  }

  foreach procname [lsort [info proc ::tb::snapshot::extract::*]] {
    switch $mode {
      extract {
        if {$verbose} {
          print info "Started extract on $procname on [clock format [clock seconds]]"
        }
        if {[catch {$procname} errorstring]} {
          error " -E- $errorstring"
        }
        if {$verbose} {
          print info "Completed extract on $procname on [clock format [clock seconds]]"
        }
      }
      list {
        print info "Found extract proc $procname"
      }
      default {
      }
    }
  }

  if {$save} {
    snapshot save
  }

  # Restore state of verbosity & debug
  set verbose $_verbose_
  set debug $_debug_

  return -code ok
}

#------------------------------------------------------------------------
# ::tb::snapshot::method:db
#------------------------------------------------------------------------
# Usage: snapshot db [<options>]
#------------------------------------------------------------------------
# Set the path to the SQLite3 database
#------------------------------------------------------------------------
proc ::tb::snapshot::method:db {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Set the database location
  variable params
  variable verbose
  variable debug
  # Save current state of verbosity & debug
  set _verbose_ $verbose
  set _debug_ $debug
  set error 0
  set help 0
  if {[llength $args] == 0} {
    set help 1
  }
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -db {
        ::tb::snapshot::method:configure -db [lshift args]
      }
      -newdb {
        ::tb::snapshot::method:configure -newdb
      }
      -verbose {
        ::tb::snapshot::method:configure -verbose
      }
      -quiet {
        ::tb::snapshot::method:configure -quiet
      }
      -debug {
        ::tb::snapshot::method:configure -debug
      }
      -nodebug {
        ::tb::snapshot::method:configure -nodebug
      }
      -h -
      -help {
           set help 1
      }
      default {
            if {[string match "-*" $name]} {
              print error "option '$name' is not a valid option."
              incr error
            } else {
              ::tb::snapshot::method:configure -db $name
#               print error "option '$name' is not a valid option."
#               incr error
            }
      }
    }
  }

  if {$help} {
    print stdout [format {
  Usage: snapshot db
              [-db <filename>|<filename>]
              [-newdb]
              [-verbose|-quiet]
              [-help|-h]

  Description: Set the database location

  Example:
     snapshot db -newdb ./metrics.db
} ]
    # HELP -->
    # Restore state of verbosity & debug
    set verbose $_verbose_
    set debug $_debug_
    return -code ok
  }

  if {$error} {
    # Restore state of verbosity & debug
    set verbose $_verbose_
    set debug $_debug_
    error " -E- some error(s) happened. Cannot continue"
  }

  # Restore state of verbosity & debug
  set verbose $_verbose_
  set debug $_debug_

  return -code ok
}

#------------------------------------------------------------------------
# ::tb::snapshot::dump
#------------------------------------------------------------------------
# **HIDDEN**
#------------------------------------------------------------------------
# Usage: snapshot dump
#------------------------------------------------------------------------
# Dump snapshot status
#------------------------------------------------------------------------
proc ::tb::snapshot::dump {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Dump non-array variables
  foreach var [lsort [info var ::tb::snapshot::*]] {
    if {![info exists $var]} { continue }
    if {![array exists $var]} {
      print stdout "   $var: [truncateText [subst $$var]]"
    }
  }
  # Dump array variables
  foreach var [lsort [info var ::tb::snapshot::*]] {
    if {![info exists $var]} { continue }
    if {[array exists $var]} {
      print stdout "   === $var ==="
#       parray $var
      foreach key [lsort [array names $var]] {
        print stdout "     $key : [truncateText [subst $${var}($key)] ]"
      }
    }
  }
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::snapshot::execSQL
#------------------------------------------------------------------------
# **HIDDEN**
#------------------------------------------------------------------------
# Execute SQL command
#------------------------------------------------------------------------
proc ::tb::snapshot::execSQL {&SQL {cmd {pragma integrity_check} } } {
  # Summary :
  # Argument Usage:
  # Return Value:

  upvar &SQL SQL
  variable verbose
  variable debug
  if {$debug} {
    print debug "SQL command: $cmd"
  }

  # Wait for the database to be unlocked
#   while {[catch { uplevel [list SQL eval $cmd] } errorstring]} {}
  while {[catch { set res [uplevel [list SQL eval $cmd]] } errorstring]} {
    if {[regexp {database is locked} $errorstring]} {
      if {$verbose} { print info "SQL database locked ..." }
      exec sleep 1
    } elseif {[regexp {attempt to write a readonly database} $errorstring]} {
      if {$verbose} { print info "SQL database read-only ..." }
      exec sleep 1
    } else {
      error $errorstring
    }
  }
#   return 0
  return $res
}

#------------------------------------------------------------------------
# ::tb::snapshot::method:save
#------------------------------------------------------------------------
# Save metrics into SQL database
#------------------------------------------------------------------------
proc ::tb::snapshot::method:save {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Save metrics into SQL database
  variable metrics
  variable params
  variable snapshotlog
  variable verbose
  variable debug
  set time $params(time)
  set error 0
  set help 0
#   if {[llength $args] == 0} {
#     set help 1
#   }
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -time {
           set time [lshift args]
      }
      -h -
      -help {
           set help 1
      }
      default {
            if {[string match "-*" $name]} {
              print error "option '$name' is not a valid option."
              incr error
            } else {
              print error "option '$name' is not a valid option."
              incr error
            }
      }
    }
  }

  if {$help} {
    print stdout [format {
  Usage: snapshot save
              [-time <time_in_seconds>]
              [-help|-h]

  Description: Save the snapshot

  Example:
     snapshot save
     snapshot save -time [clock seconds]
} ]
    # HELP -->
    return -code ok
  }

  if {$time == 0} {
    set time [clock seconds]
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  set db [getDB]
  set firstSetup 0
  if {![file exists $db]} { set firstSetup 1 }
  if {$verbose} {
    print info "<<<<<<<<<<< Saving Metrics <<<<<<<<<<<<<"
    print info "Database: $db"
  }
#   catch {file delete $db}
  sqlite3 SQL $db -create true
  execSQL SQL { PRAGMA foreign_keys = ON; }
  # PRAGMA for very large databases:
  execSQL SQL {
    PRAGMA main.temp_store = MEMORY;
    PRAGMA main.page_size = 4096;
    PRAGMA main.cache_size=10000;
    PRAGMA main.locking_mode=EXCLUSIVE;
    PRAGMA main.synchronous=NORMAL;
    PRAGMA main.journal_mode=MEMORY;
    PRAGMA main.cache_size=5000;
  }
  execSQL SQL {
    CREATE TABLE IF NOT EXISTS param (
             id INTEGER PRIMARY KEY AUTOINCREMENT,
             property TEXT,
             value TEXT DEFAULT NULL
             );
    CREATE TABLE IF NOT EXISTS snapshot (
             id INTEGER PRIMARY KEY AUTOINCREMENT,
             parentid INTEGER,
             project TEXT DEFAULT NULL,
             release TEXT DEFAULT NULL,
             version TEXT DEFAULT NULL,
             experiment TEXT DEFAULT NULL,
             step TEXT DEFAULT NULL,
             run TEXT DEFAULT NULL,
             description TEXT DEFAULT NULL,
             date TEXT,
             time TEXT,
             FOREIGN KEY(parentid) REFERENCES snapshot(id) ON UPDATE SET NULL
             );
    CREATE TABLE IF NOT EXISTS metric (
             id INTEGER PRIMARY KEY AUTOINCREMENT,
             snapshotid INTEGER,
             name TEXT DEFAULT NULL,
             value BLOB DEFAULT NULL,
             source TEXT DEFAULT NULL,
             FOREIGN KEY(snapshotid) REFERENCES snapshot(id) ON UPDATE SET NULL
             );
  }

  if {$firstSetup} {
    # Database version & other parameters
    execSQL SQL { INSERT INTO param(property,value) VALUES("version","1.3"); }
    execSQL SQL { INSERT INTO param(property,value) VALUES("date",strftime('%Y-%m-%d %H:%M:%S','now') ); }
    execSQL SQL " INSERT INTO param(property,value) VALUES('time','[clock milliseconds]' ); "
    execSQL SQL " INSERT INTO param(property,value) VALUES('directory','[file normalize [uplevel #0 pwd]]' ); "
  }

  set dbVersion [SQL eval { SELECT value FROM param WHERE property='version' LIMIT 1; } ]
  set project [getProject]
  set run [getRun]
#   execSQL SQL " INSERT INTO snapshot(version,experiment,step,date,time) VALUES('[getVersion]','[getExperiment]','[getStep]','[clock format $time -format {%Y-%m-%d %H:%M:%S}]','$time' ); "

  switch $dbVersion {
    1.2 {
      execSQL SQL " INSERT INTO snapshot(version,experiment,step,date,time) VALUES('[getVersion]','[getExperiment]','[getStep]','[clock format $time -format {%Y-%m-%d %H:%M:%S}]','$time' ); "
    }
    1.3 {
      execSQL SQL " INSERT INTO snapshot(version,experiment,step,release,description,date,time) VALUES('[getVersion]','[getExperiment]','[getStep]','[getRelease]','[getDescription]','[clock format $time -format {%Y-%m-%d %H:%M:%S}]','$time' ); "
    }
    default {
      error "database version $dbVersion not supported"
    }
  }

  set snapshotid [SQL last_insert_rowid]
  if {$verbose} {
    print info "Snapshot ID: $snapshotid"
  }
  if {$project != {}} {
    execSQL SQL " UPDATE snapshot SET project='$project' WHERE id=$snapshotid; "
  } else {
#     execSQL SQL " UPDATE snapshot SET project='' WHERE id=$snapshotid; "
    set project [get_property -quiet NAME [current_project -quiet]]
    execSQL SQL " UPDATE snapshot SET project='$project' WHERE id=$snapshotid; "
  }
  if {$run != {}} {
    execSQL SQL " UPDATE snapshot SET run='$run' WHERE id=$snapshotid; "
  } else {
#     execSQL SQL " UPDATE snapshot SET run='' WHERE id=$snapshotid; "
    set run [get_property -quiet NAME [current_run -quiet]]
    execSQL SQL " UPDATE snapshot SET run='$run' WHERE id=$snapshotid; "
  }

  # Save metrics
  foreach metric [lsort [array names metrics]] {
# print debug "metric: '$metric'"
    set value $metrics($metric)
# print debug "value: '$value'"
    execSQL SQL { INSERT INTO metric(snapshotid,name,value,source) VALUES($snapshotid,$metric,$value,NULL) ; }
    set metricid [SQL last_insert_rowid]
    if {$verbose} {
      print info "(ID=$metricid) $metric = [truncateText $value]"
    }
  }

  # Save system log
#   execSQL SQL { INSERT INTO metric(snapshotid,name,value,source) VALUES($snapshotid,"snapshotlog",$snapshotlog,NULL) ; }
  set content [join $snapshotlog \n]
#   execSQL SQL { INSERT INTO metric(snapshotid,name,value,source) VALUES($snapshotid,"snapshotlog",$content,NULL) ; }
  execSQL SQL { INSERT INTO metric(snapshotid,name,value,source) VALUES($snapshotid,'snapshot.log',$content,NULL) ; }
  execSQL SQL { INSERT INTO metric(snapshotid,name,value,source) VALUES($snapshotid,'snapshot.project',$project,NULL) ; }
  execSQL SQL { INSERT INTO metric(snapshotid,name,value,source) VALUES($snapshotid,'snapshot.run',$run,NULL) ; }
  execSQL SQL " INSERT INTO metric(snapshotid,name,value,source) VALUES($snapshotid,'snapshot.version','[getVersion]',NULL) ; "
  execSQL SQL " INSERT INTO metric(snapshotid,name,value,source) VALUES($snapshotid,'snapshot.experiment','[getExperiment]',NULL) ; "
  execSQL SQL " INSERT INTO metric(snapshotid,name,value,source) VALUES($snapshotid,'snapshot.step','[getStep]',NULL) ; "
  execSQL SQL " INSERT INTO metric(snapshotid,name,value,source) VALUES($snapshotid,'snapshot.release','[getRelease]',NULL) ; "
  execSQL SQL " INSERT INTO metric(snapshotid,name,value,source) VALUES($snapshotid,'snapshot.description','[getDescription]',NULL) ; "
  execSQL SQL " INSERT INTO metric(snapshotid,name,value,source) VALUES($snapshotid,'snapshot.date','[clock format $time -format {%Y-%m-%d %H:%M:%S}]',NULL) ; "
  execSQL SQL { INSERT INTO metric(snapshotid,name,value,source) VALUES($snapshotid,'snapshot.time',$time,NULL) ; }

  SQL close
  if {$verbose} {
    print info ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  }
  return $snapshotid
}

#------------------------------------------------------------------------
# ::tb::snapshot::method:load
#------------------------------------------------------------------------
# Load metrics from SQL database to array
#------------------------------------------------------------------------
proc ::tb::snapshot::method:load {&var snapshotid} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Load metrics from SQL database to array
  upvar 2 ${&var} var
  variable metrics
  variable params
  variable verbose
  variable debug
  set db [getDB]
  # Remove array
  catch {unset var}
  if {![file exists $db]} {
    error " -E- Database '$db' does not exist"
  }
  if {$verbose} {
    print info "<<<<<<<<<<< Loading Metrics <<<<<<<<<<<<"
    print info "Database: $db"
  }
  sqlite3 SQL $db -readonly true
  execSQL SQL { pragma integrity_check }
  set dbVersion [SQL eval { SELECT value FROM param WHERE property='version' LIMIT 1; } ]
  if {$verbose} { print info "Database version: $dbVersion" }

  set CMD "SELECT id, project, run, version, experiment, step, date, time
          FROM snapshot
          WHERE id IN ('[join $snapshotid ',']')
          ;
         "
  execSQL SQL { pragma integrity_check }
  SQL eval $CMD values {
#     parray values
    set id $values(id)
    set project $values(project)
    set run $values(run)
    set version $values(version)
    set experiment $values(experiment)
    set step $values(step)
    set date $values(date)
    set time $values(time)
    foreach el {id project run version experiment step date time} { set var($el) $values($el) }
    if {$verbose} {
      print info "Snapshot ID=$id : project:$project run:$run version:$version experiment:$experiment step:$step date:$date time:$time"
    }
  }
  set CMD "SELECT snapshotid, name, value, source
          FROM metric
          WHERE snapshotid IN ('[join $snapshotid ',']')
          ;
         "
  execSQL SQL { pragma integrity_check }
  SQL eval $CMD values {
#     parray values
    set id $values(snapshotid)
    set metric $values(name)
    set value $values(value)
    set source $values(source)
    set var($metric) $value
    if {$verbose} {
      print info "(snapshot ID=$id) $metric = [truncateText $value]"
    }
  }

  SQL close
  if {$verbose} {
    print info ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  }
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::snapshot::getDB
#------------------------------------------------------------------------
# **HIDDEN**
#------------------------------------------------------------------------
# Return the SQLite3 database name to save the metrics
#------------------------------------------------------------------------
proc ::tb::snapshot::getDB {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable params
  set db {}
  if {![info exists params(db)]} {
    set db [file normalize {metrics.db}]
  } elseif {[regexp {^\s*$} $params(db)]} {
    set db [file normalize {metrics.db}]
  } else {
    set db [file normalize $params(db)]
  }
  return $db
}

#------------------------------------------------------------------------
# ::tb::snapshot::getExperiment
#------------------------------------------------------------------------
# **HIDDEN**
#------------------------------------------------------------------------
# Return the experiment name
#------------------------------------------------------------------------
proc ::tb::snapshot::getExperiment {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable params
  set name {}
  if {![info exists params(experiment)]} {
    set name {default}
  } elseif {[regexp {^\s*$} $params(experiment)]} {
    set name {default}
  } else {
    set name $params(experiment)
  }
  return $name
}

#------------------------------------------------------------------------
# ::tb::snapshot::getVersion
#------------------------------------------------------------------------
# **HIDDEN**
#------------------------------------------------------------------------
# Return the version
#------------------------------------------------------------------------
proc ::tb::snapshot::getVersion {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable params
  set name {}
  if {![info exists params(version)]} {
    set name {default}
  } elseif {[regexp {^\s*$} $params(version)]} {
    set name {default}
  } else {
    set name $params(version)
  }
  return $name
}

#------------------------------------------------------------------------
# ::tb::snapshot::getStep
#------------------------------------------------------------------------
# **HIDDEN**
#------------------------------------------------------------------------
# Return the flow step name
#------------------------------------------------------------------------
proc ::tb::snapshot::getStep {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable params
  set name {}
  if {![info exists params(step)]} {
    set name {default}
  } elseif {[regexp {^\s*$} $params(step)]} {
    set name {default}
  } else {
    set name $params(step)
  }
  return $name
}

#------------------------------------------------------------------------
# ::tb::snapshot::getRun
#------------------------------------------------------------------------
# **HIDDEN**
#------------------------------------------------------------------------
# Return the run name
#------------------------------------------------------------------------
proc ::tb::snapshot::getRun {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable params
  set name {}
  if {![info exists params(run)]} {
    set name {}
  } elseif {[regexp {^\s*$} $params(run)]} {
    set name {}
  } else {
    set name $params(run)
  }
#   if {$name == {}} {
#     set name [get_property -quiet NAME [current_run -quiet]]
#   }
  return $name
}

#------------------------------------------------------------------------
# ::tb::snapshot::getProject
#------------------------------------------------------------------------
# **HIDDEN**
#------------------------------------------------------------------------
# Return the project name
#------------------------------------------------------------------------
proc ::tb::snapshot::getProject {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable params
  set name {}
  if {![info exists params(project)]} {
    set name {}
  } elseif {[regexp {^\s*$} $params(project)]} {
    set name {}
  } else {
    set name $params(project)
  }
#   if {$name == {}} {
#     set name [get_property -quiet NAME [current_project -quiet]]
#   }
  return $name
}

#------------------------------------------------------------------------
# ::tb::snapshot::getRelease
#------------------------------------------------------------------------
# **HIDDEN**
#------------------------------------------------------------------------
# Return the release name
#------------------------------------------------------------------------
proc ::tb::snapshot::getRelease {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable params
  set name {}
  if {![info exists params(release)]} {
    set name {}
  } elseif {[regexp {^\s*$} $params(release)]} {
    set name {}
  } else {
    set name $params(release)
  }
  return $name
}

#------------------------------------------------------------------------
# ::tb::snapshot::getDescription
#------------------------------------------------------------------------
# **HIDDEN**
#------------------------------------------------------------------------
# Return the description
#------------------------------------------------------------------------
proc ::tb::snapshot::getDescription {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable params
  set name {}
  if {![info exists params(description)]} {
    set name {}
  } elseif {[regexp {^\s*$} $params(description)]} {
    set name {}
  } else {
    set name $params(description)
  }
  return $name
}

#------------------------------------------------------------------------
# ::tb::snapshot::method:version
#------------------------------------------------------------------------
# Usage: snapshot version
#------------------------------------------------------------------------
# Return the version of the snapshot
#------------------------------------------------------------------------
proc ::tb::snapshot::method:version {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Version of the script
  variable version
  return -code ok "Snapshot script version $version"
}

#------------------------------------------------------------------------
# ::tb::snapshot::method:get_param
#------------------------------------------------------------------------
# **HIDDEN**
#------------------------------------------------------------------------
# Usage: snapshot get_param <param>
#------------------------------------------------------------------------
# Get a parameter from the 'params' associative array
#------------------------------------------------------------------------
proc ::tb::snapshot::method:get_param {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable params
  if {[llength $args] != 1} {
    error "wrong number of parameters: snapshot get_param <param>"
  }
  if {![info exists params([lindex $args 0])]} {
    error "unknown parameter '[lindex $args 0]'"
  }
  return [subst $params([lindex $args 0])]
}

#------------------------------------------------------------------------
# ::tb::snapshot::method:set_param
#------------------------------------------------------------------------
# **HIDDEN**
#------------------------------------------------------------------------
# Usage: snapshot set_param <param> <value>
#------------------------------------------------------------------------
# Set a parameter inside the 'params' associative array
#------------------------------------------------------------------------
proc ::tb::snapshot::method:set_param {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable params
  if {[llength $args] < 2} {
    error "wrong number of parameters: snapshot set_param <param> <value>"
  }
  set params([lindex $args 0]) [lrange $args 1 end]
  return 0
}

#------------------------------------------------------------------------
# ::tb::snapshot::method:get
#------------------------------------------------------------------------
# Usage: snapshot get <param>
#------------------------------------------------------------------------
# Get a parameter from the 'metrics' associative array
#------------------------------------------------------------------------
proc ::tb::snapshot::method:get {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Get a metric value
  variable metrics
  if {[llength $args] != 1} {
    error "wrong number of parameters: snapshot get <metric>"
  }
  if {![info exists metrics([lindex $args 0])]} {
    error "unknown metric '[lindex $args 0]'"
  }
  return [subst $metrics([lindex $args 0])]
}

#------------------------------------------------------------------------
# ::tb::snapshot::method:set
#------------------------------------------------------------------------
# Usage: snapshot set <param> <value>
#------------------------------------------------------------------------
# Set a parameter inside the 'metrics' associative array
#------------------------------------------------------------------------
proc ::tb::snapshot::method:set {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Set a metric value
  variable metrics
#   if {[llength $args] < 2} {
#     error "wrong number of parameters: snapshot set <metric> <value>"
#   }
  switch [llength $args] {
    0 -
    1 {
      error "wrong number of parameters: snapshot set <metric> <value>"
    }
    2 {
      set metrics([lindex $args 0]) [lindex $args 1]
    }
    default {
      set metrics([lindex $args 0]) [lrange $args 1 end]
    }
  }
#   set metrics([lindex $args 0]) [lrange $args 1 end]
  return 0
}

#------------------------------------------------------------------------
# ::tb::snapshot::method:addfile
#------------------------------------------------------------------------
# Usage: snapshot addfile <metric> <filename>
#------------------------------------------------------------------------
# Save the file content inside the 'metrics' associative array
#------------------------------------------------------------------------
proc ::tb::snapshot::method:addfile {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Save the content of a file as a metric
  variable metrics
  variable debug
  variable verbose
  if {[llength $args] < 2} {
    error "wrong number of parameters: snapshot addfile <metric> <filename>"
  }
  set filename [file normalize [lindex $args 1]]
  if {![file exists $filename]} {
    error " -E- file $filename does not exist"
  }
  set FH [open $filename {r}]
  set content [read $FH]
  close $FH
  if {$verbose} {
    print info "Reading file $filename ([string length $content] characters)"
  }
  set metrics([lindex $args 0]) $content
  return 0
}

#------------------------------------------------------------------------
# ::tb::snapshot::method:addparam
#------------------------------------------------------------------------
# Usage: snapshot addparam [<metric>] <parameter>
#------------------------------------------------------------------------
# Save a Vivado parameter inside the 'metrics' associative array
#------------------------------------------------------------------------
proc ::tb::snapshot::method:addparam {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Save the content of a file as a metric
  variable metrics
  variable debug
  variable verbose
  switch [llength $args] {
    1 {
      set parameter [lindex $args 0]
      set metric $parameter
    }
    2 {
      set metric [lindex $args 0]
      set parameter [lindex $args 1]
    }
    default {
      error "wrong number of parameters: snapshot addfile [<metric>] <parameter>"
    }
  }
  if {[catch {set value [get_param $parameter]} errorstring]} {
    error $errorstring
  }
  set metrics($metric) $value
  if {$verbose} {
    print info "Metric $metric / Parameter $parameter = $value"
  }
  return 0
}

#------------------------------------------------------------------------
# ::tb::snapshot::method:reset
#------------------------------------------------------------------------
# Usage: snapshot reset
#------------------------------------------------------------------------
# Reset the snapshot
#------------------------------------------------------------------------
proc ::tb::snapshot::method:reset {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Reset the snapshot
  variable params
  variable metrics
#   variable summary
#   variable verbose 0
#   variable debug 0
  variable snapshotlog [list]
  catch {unset params}
  catch {unset metrics}
  array set params [list db {} project {} run {} version {} experiment {} step {} release {} description {} time 0]
  array set metrics [list ]
  print info "Resetting snapshot"
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::snapshot::method:dbreport
#------------------------------------------------------------------------
# Usage: snapshot dbreport [<options>]
#------------------------------------------------------------------------
# Print a summary of all snapshots inside the database
#------------------------------------------------------------------------
proc ::tb::snapshot::method:dbreport { args } {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Print a summary of all snapshots inside the database
  return [uplevel [concat ::tb::snapshot::dbreport $args]]
}

#------------------------------------------------------------------------
# ::tb::snapshot::method:db2csv
#------------------------------------------------------------------------
# Usage: snapshot db2csv [<options>]
#------------------------------------------------------------------------
# Convert database to CSV
#------------------------------------------------------------------------
proc ::tb::snapshot::method:db2csv { args } {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Convert database to CSV
  return [uplevel [concat ::tb::snapshot::db2csv $args]]
}

#------------------------------------------------------------------------
# ::tb::snapshot::db2csv
#------------------------------------------------------------------------
# Usage: ::tb::snapshot::db2csv [<options>]
#------------------------------------------------------------------------
# Convert database to CSV
#------------------------------------------------------------------------
proc ::tb::snapshot::db2csv {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable summary
  variable params
  variable verbose
  variable debug
  # Save current state of verbosity & debug
  set _verbose_ $verbose
  set _debug_ $debug
  set db [getDB]
  set allsnapshotids {}
  set project {%}
  set run {%}
  set version {%}
  set experiment {%}
  set step {%}
  set release {%}
  set csvfile {}
  set csvdelimiter {,}
  set mode {w}
  set metrics {}
  set reset 0
  set error 0
  set help 0
#   if {[llength $args] == 0} {
#     set help 1
#   }
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -db {
        set db [lshift args]
      }
      -file {
        set csvfile [lshift args]
      }
      -append {
        set mode {a}
      }
      -delimiter {
        set csvdelimiter [lshift args]
      }
      -m -
      -metrics {
        set metrics [concat $metrics [lshift args]]
      }
      -id {
        set allsnapshotids [concat $allsnapshotids [split [lshift args] ,]]
      }
      -p -
      -project {
        set project [lshift args]
      }
      -r -
      -run {
        set run [lshift args]
      }
      -ver -
      -version {
        set version [lshift args]
      }
      -e -
      -experiment {
        set experiment [lshift args]
      }
      -s -
      -step {
        set step [lshift args]
      }
      -rel -
      -release -
      -vivado {
           set release [lshift args]
      }
      -verbose {
        ::tb::snapshot::method:configure -verbose
      }
      -quiet {
        ::tb::snapshot::method:configure -quiet
      }
      -debug {
        ::tb::snapshot::method:configure -debug
      }
      -nodebug {
        ::tb::snapshot::method:configure -nodebug
      }
      -h -
      -help {
           set help 1
      }
      default {
            if {[string match "-*" $name]} {
              print error "option '$name' is not a valid option."
              incr error
            } else {
              print error "option '$name' is not a valid option."
              incr error
            }
      }
    }
  }

  if {$help} {
    print stdout [format {
  Usage: ::tb::snapshot::db2csv
              [-db <filename>]
              [-metrics <list_metrics>]
              [-file <filename>]
              [-append]
              [-delimiter <char>]
              [-id <list_snapshot_ids>]
              [-project|-p <string>]
              [-run|-r <string>]
              [-version|-ver <string>]
              [-experiment|-e <string>]
              [-step|-s <string>]
              [-release|-rel <string>]
              [-verbose|-quiet]
              [-help|-h]

  Description: Convert a database to CSV file

  Example:
     ::tb::snapshot::db2csv
     ::tb::snapshot::db2csv -db ./metrics.db -csv ./metrics.csv -metrics {metric1 metric2 ... metricN} -delimiter ,
     ::tb::snapshot::db2csv -experiment {No%%Buffer%%}
} ]
    # HELP -->
    set verbose $_verbose_
    set debug $_debug_
    return -code ok
  }

  if {![file exists $db]} {
    print error "Database '$db' does not exist"
    incr error
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  if {$verbose} {
    print info "<<<<<<<<<<<<<<<< db2csv <<<<<<<<<<<<<<<<"
    print info "Database: $db"
  }
  sqlite3 SQL $db -readonly true
  execSQL SQL { pragma integrity_check }
  set dbVersion [SQL eval { SELECT value FROM param WHERE property='version' LIMIT 1; } ]
  if {$verbose} { 
    print info "Database version: $dbVersion" 
    print info "CSV generation started on [clock format [clock seconds]]"
  }

  if {$allsnapshotids == {}} {
    set allsnapshotids [lsort [execSQL SQL "SELECT id FROM snapshot" ]]
#     puts "<allsnapshotids:$allsnapshotids>"
  } else {
    set L $allsnapshotids
    set allsnapshotids [list]
    foreach elm $L {
      if {[regexp {^[0-9]+$} $elm]} {
        lappend allsnapshotids $elm
      } elseif {[regexp {^([0-9]+)\-([0-9]+)$} $elm - n1 n2]} {
        if {$n1 > $n2} { foreach n1 $n2 n2 $n1 break }
        for { set i $n1 } { $i <= $n2 } { incr i } {
           lappend allsnapshotids $i
        }
      } else {
        error "invalid format for snapshot id: $elm"
      }
    }
    set allsnapshotids [lsort -unique $allsnapshotids]
    if {$debug} {
      print info "List of snapshot ids: $allsnapshotids"
    }
  }

  switch $dbVersion {
    1.2 {
      set CMD "SELECT id
          FROM snapshot
          WHERE id IN ('[join $allsnapshotids ',']')
                AND ( (project LIKE '$project') OR (project IS NULL) )
                AND ( (run LIKE '$run') OR (run IS NULL) )
                AND version LIKE '$version'
                AND experiment LIKE '$experiment'
                AND step LIKE '$step'
          ;
         "
    }
    1.3 {
      set CMD "SELECT id
          FROM snapshot
          WHERE id IN ('[join $allsnapshotids ',']')
                AND ( (project LIKE '$project') OR (project IS NULL) )
                AND ( (run LIKE '$run') OR (run IS NULL) )
                AND version LIKE '$version'
                AND experiment LIKE '$experiment'
                AND step LIKE '$step'
                AND ( (release LIKE '$release') OR (release IS NULL) )
          ;
         "
    }
    default {
      error "database version $dbVersion not supported"
    }
  }
  set snapshotids [lsort -integer [execSQL SQL $CMD]]
  
  if {$metrics == {}} {
    set CMD "SELECT DISTINCT name FROM metric WHERE snapshotid IN ('[join $snapshotids ',']')"
    set metrics [lsort [execSQL SQL $CMD]]
  }
#   puts "<metrics:$metrics>";

  # Some styles for the report
  catch { ::report::rmstyle simpletable }
  ::report::defstyle simpletable {} {
    data	set [split "[string repeat "| "   [columns]]|"]
    top	set [split "[string repeat "+ - " [columns]]+"]
    bottom	set [top get]
    top	enable
    bottom	enable
  }
  catch { ::report::rmstyle captionedtable }
  ::report::defstyle captionedtable {{n 1}} {
	  simpletable
	  topdata   set [data get]
	  topcapsep set [top get]
	  topcapsep enable
	  tcaption $n
	}
  catch {matrixFormat destroy}
  ::report::report matrixFormat [expr 10 + [llength $metrics]] style captionedtable 1
#   matrixFormat justify 2 center

  # Just in case: destroy previous matrix if it was not done before
  catch {summary destroy}
  struct::matrix summary
  summary add columns [expr 10 + [llength $metrics]]
  summary add row [concat [list {id} {project} {release} {version} {experiment} {step} {run} {description} {date} {time} ] $metrics ]

  set numrow 0
  foreach id $snapshotids {
    set CMD "SELECT project, run, version, experiment, step, release, description, date, time
           FROM snapshot
           WHERE id = $id
           ;
           "
    execSQL SQL { pragma integrity_check }
    SQL eval $CMD values {
  #     parray values
      set project $values(project)
      set run $values(run)
      set version $values(version)
      set experiment $values(experiment)
      set step $values(step)
      set release $values(release)
      set description $values(description)
      set date $values(date)
      set time $values(time)
      foreach el {project run version experiment step release description date time} { set var($el) $values($el) }
      if {$debug} {
        print debug "Snapshot ID=$id : project:$project version:$version experiment:$experiment step:$step release:$release run:$run date:$date time:$time"
      }

      incr numrow
      summary add row
      summary set cell 0 $numrow $id
      summary set cell 1 $numrow $project
      summary set cell 2 $numrow $release
      summary set cell 3 $numrow $version
      summary set cell 4 $numrow $experiment
      summary set cell 5 $numrow $step
      summary set cell 6 $numrow $run
      summary set cell 7 $numrow $description
      summary set cell 8 $numrow $date
      summary set cell 9 $numrow $time

      set CMD2 "SELECT name, value
             FROM metric
             WHERE snapshotid = $id
                   AND ( name IN ('[join $metrics ',']') )
             ;
             "
      execSQL SQL { pragma integrity_check }
      SQL eval $CMD2 metricinfo {
        set metricname $metricinfo(name)
        set metricvalue $metricinfo(value)
        set numcol [expr 10 + [lsearch $metrics $metricname]]
#         summary set cell $numcol $numrow $metricvalue
#         summary set cell $numcol $numrow [list2csv [list [truncateText $metricvalue]] $csvdelimiter]
        summary set cell $numcol $numrow [truncateText $metricvalue]
#         summary set cell $numcol $numrow [::csv::join [list [truncateText $metricvalue]] ,]
#         summary set cell $numcol $numrow [::csv::join [list [truncateText $metricvalue]] $csvdelimiter]
        if {$debug} {
          print debug "snapshotid=$id / name=$metricname / value='[truncateText $metricvalue]'"
        }
      }


    }

  }

#   print stdout [summary format 2string matrixFormat]
#   print stdout [matrixFormat printmatrix ::tb::snapshot::summary]
#   csv::writematrix ::tb::snapshot::summary stdout $csvdelimiter
# #   csv::writematrix matrixFormat ::tb::snapshot::summary stdout

  if {$csvfile == {}} {
#     print stdout [csv::report printmatrix ::tb::snapshot::summary]
    csv::writematrix ::tb::snapshot::summary stdout $csvdelimiter
# #     csv::writematrix summary <chan> ,
# #     csv::writematrix matrixFormat summary stdout
  } else {
    set csvfile [file normalize $csvfile]
    set FH [open $csvfile $mode]
    puts $FH "# Created on [clock format [clock seconds]]"
    puts $FH "# Database: $db"
#     puts $FH [csv::report printmatrix ::tb::snapshot::summary]
#     puts $FH {}
    csv::writematrix ::tb::snapshot::summary $FH $csvdelimiter
    close $FH
    print stdout " File $csvfile has been created"
  }
  
  summary destroy
  matrixFormat destroy

  SQL close
  if {$verbose} {
    print info "CSV generation completed on [clock format [clock seconds]]"
    print info ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  }

  # Restore state of verbosity & debug
  set verbose $_verbose_
  set debug $_debug_

  return -code ok
}

#------------------------------------------------------------------------
# ::tb::snapshot::method:db2dir
#------------------------------------------------------------------------
# Usage: snapshot db2dir [<options>]
#------------------------------------------------------------------------
# Export database to directory
#------------------------------------------------------------------------
proc ::tb::snapshot::method:db2dir { args } {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Export database to directory
  return [uplevel [concat ::tb::snapshot::db2dir $args]]
}

#------------------------------------------------------------------------
# ::tb::snapshot::db2dir
#------------------------------------------------------------------------
# Usage: ::tb::snapshot::db2dir [<options>]
#------------------------------------------------------------------------
# Export database to directory
#------------------------------------------------------------------------
proc ::tb::snapshot::db2dir {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable summary
  variable params
  variable verbose
  variable debug
  # Save current state of verbosity & debug
  set _verbose_ $verbose
  set _debug_ $debug
  set db [getDB]
  set allsnapshotids {}
  set project {%}
  set run {%}
  set version {%}
  set experiment {%}
  set step {%}
  set release {%}
  set exportDir {}
  set exportFormat {}
  set directoryExpr {}
  set filenameExpr {%id.%project.%version.%experiment.%step.%metricname}
  set saveHtml 0
  set writeMetricFiles 1
  set indexFH {}
  set snapshotFH {}
  set metrics {}
  set reset 0
  set error 0
  set help 0
#   if {[llength $args] == 0} {
#     set help 1
#   }
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -db {
        set db [lshift args]
      }
      -dir -
      -directory {
#         set exportDir [lshift args]
        set exportDir [file normalize [lshift args]]
      }
      -fileexpr {
        set filenameExpr [lshift args]
      }
      -direxpr {
        set directoryExpr [lshift args]
      }
      -format {
        set exportFormat [lshift args]
      }
      -html {
        set saveHtml 1
      }
      -index -
      -index_only {
        set writeMetricFiles 0
      }
      -m -
      -metrics {
        set metrics [concat $metrics [lshift args]]
      }
      -id {
        set allsnapshotids [concat $allsnapshotids [split [lshift args] ,]]
      }
      -p -
      -project {
        set project [lshift args]
      }
      -r -
      -run {
        set run [lshift args]
      }
      -ver -
      -version {
        set version [lshift args]
      }
      -e -
      -experiment {
        set experiment [lshift args]
      }
      -s -
      -step {
        set step [lshift args]
      }
      -rel -
      -release -
      -vivado {
           set release [lshift args]
      }
      -verbose {
        ::tb::snapshot::method:configure -verbose
      }
      -quiet {
        ::tb::snapshot::method:configure -quiet
      }
      -debug {
        ::tb::snapshot::method:configure -debug
      }
      -nodebug {
        ::tb::snapshot::method:configure -nodebug
      }
      -h -
      -help {
           set help 1
      }
      default {
            if {[string match "-*" $name]} {
              print error "option '$name' is not a valid option."
              incr error
            } else {
              print error "option '$name' is not a valid option."
              incr error
            }
      }
    }
  }

  if {$help} {
    print stdout [format {
  Usage: ::tb::snapshot::db2dir
              -dir <directory>
              [-db <filename>]
              [-metrics <list_metrics>]
              [-id <list_snapshot_ids>]
              [-project|-p <string>]
              [-run|-r <string>]
              [-version|-ver <string>]
              [-experiment|-e <string>]
              [-step|-s <string>]
              [-release|-rel <string>]
              [-format flat|hier1|hier2|hier3]
              [-direxpr <string>]
              [-fileexpr <string>]
              [-html]
              [-index|-index_only]
              [-verbose|-quiet]
              [-help|-h]

  Description: Export a database to a directory
  
    Supported parameters for -fileexpr/-direxpr: %%id, %%project, %%version, %%experiment, %%step, %%release, %%metricname
    
    Option -format overrides options -fileexpr/-direxpr

  Example:
     ::tb::snapshot::db2dir
     ::tb::snapshot::db2dir -db ./metrics.db -dir /my/export/dir -metrics {metric1 metric2 ... metricN}
     ::tb::snapshot::db2dir -experiment {No%%Buffer%%} -dir .
} ]
    # HELP -->
    set verbose $_verbose_
    set debug $_debug_
    return -code ok
  }

  if {![file exists $db]} {
    print error "Database '$db' does not exist"
    incr error
  }

  if {$exportDir == {}} {
    print error "Use -dir to define the export directory"
    incr error
  }

  if {![file isdirectory $exportDir]} {
    print error "Directory '$exportDir' does not exist"
    incr error
  }

  if {!$saveHtml && !$writeMetricFiles} {
    print error "-index_only can only be used with -html"
    incr error
  }

  switch $exportFormat {
    {} {
    }
    flat {
      set directoryExpr {}
      set filenameExpr {%id.%project.%version.%experiment.%step.%metricname}
    }
    hier1 {
      set directoryExpr {%project.%version.%experiment}
      set filenameExpr {%id.%step.%metricname}
    }
    hier2 {
      set directoryExpr {%project.%version.%experiment.%step}
      set filenameExpr {%id.%metricname}
    }
    hier3 {
      set directoryExpr {%project.%version.%experiment/%step}
      set filenameExpr {%id.%metricname}
    }
    hier4 {
      set directoryExpr {%project/%version/%experiment/%step}
      set filenameExpr {%metricname}
    }
    default {
      print error "Format '$exportFormat' is not valid"
      incr error
    }
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }
  
  if {$verbose} {
    print info "<<<<<<<<<<<<<<<< db2dir <<<<<<<<<<<<<<<<"
    print info "Database: $db"
  }
  sqlite3 SQL $db -readonly true
  execSQL SQL { pragma integrity_check }
  set dbVersion [SQL eval { SELECT value FROM param WHERE property='version' LIMIT 1; } ]
  if {$verbose} { 
    print info "Database version: $dbVersion" 
    print info "Export started on [clock format [clock seconds]]"
  }

  if {$allsnapshotids == {}} {
    set allsnapshotids [lsort [execSQL SQL "SELECT id FROM snapshot" ]]
#     puts "<allsnapshotids:$allsnapshotids>"
  } else {
    set L $allsnapshotids
    set allsnapshotids [list]
    foreach elm $L {
      if {[regexp {^[0-9]+$} $elm]} {
        lappend allsnapshotids $elm
      } elseif {[regexp {^([0-9]+)\-([0-9]+)$} $elm - n1 n2]} {
        if {$n1 > $n2} { foreach n1 $n2 n2 $n1 break }
        for { set i $n1 } { $i <= $n2 } { incr i } {
           lappend allsnapshotids $i
        }
      } else {
        error "invalid format for snapshot id: $elm"
      }
    }
    set allsnapshotids [lsort -unique $allsnapshotids]
    if {$debug} {
      print info "List of snapshot ids: $allsnapshotids"
    }
  }

  switch $dbVersion {
    1.2 {
      set CMD "SELECT id
          FROM snapshot
          WHERE id IN ('[join $allsnapshotids ',']')
                AND ( (project LIKE '$project') OR (project IS NULL) )
                AND ( (run LIKE '$run') OR (run IS NULL) )
                AND version LIKE '$version'
                AND experiment LIKE '$experiment'
                AND step LIKE '$step'
          ;
         "
    }
    1.3 {
      set CMD "SELECT id
          FROM snapshot
          WHERE id IN ('[join $allsnapshotids ',']')
                AND ( (project LIKE '$project') OR (project IS NULL) )
                AND ( (run LIKE '$run') OR (run IS NULL) )
                AND version LIKE '$version'
                AND experiment LIKE '$experiment'
                AND step LIKE '$step'
                AND ( (release LIKE '$release') OR (release IS NULL) )
          ;
         "
    }
    default {
      error "database version $dbVersion not supported"
    }
  }
  set snapshotids [lsort -integer [execSQL SQL $CMD]]

  if {$metrics == {}} {
    set CMD "SELECT DISTINCT name FROM metric WHERE snapshotid IN ('[join $snapshotids ',']')"
    set metrics [lsort [execSQL SQL $CMD]]
  }
#   puts "<metrics:$metrics>";

  set steps [lsort [execSQL SQL "SELECT DISTINCT step FROM snapshot WHERE id IN ('[join $snapshotids ',']')" ]]
#   puts "<steps:$steps>"
  set experiments [lsort [execSQL SQL "SELECT DISTINCT experiment FROM snapshot WHERE id IN ('[join $snapshotids ',']')" ]]
#   puts "<experiments:$experiments>"
  set versions [lsort [execSQL SQL "SELECT DISTINCT version FROM snapshot WHERE id IN ('[join $snapshotids ',']')" ]]
#   puts "<versions:$versions>"
  set releases [lsort [execSQL SQL "SELECT DISTINCT release FROM snapshot WHERE id IN ('[join $snapshotids ',']')" ]]
#   puts "<releases:$releases>"

  if {$saveHtml} {
#     catch {exec ln -s /wrk/hdstaff/dpefour/support/Olympus/assets/www/media $exportDir}
#     catch {
#       if {![file isdirectory [file join $exportDir media] ]} {
#         exec cp -r /wrk/hdstaff/dpefour/support/Olympus/assets/www/media $exportDir
#       }
#     }
    set indexFH [open [file join $exportDir "index.html"] {w}]
#     puts $indexFH "<head><body>"
    htmlHeader $indexFH
    htmlBody $indexFH
    puts $indexFH "<h4>Database: [file normalize $db]</h4>"
    puts $indexFH "<h3>Filters (<span id='selectall'>ON</span>/<span id='unselectall'>OFF<span>):</h3>"
    puts -nonewline $indexFH "<table border='1' cellpadding='2' cellspacing='2'><tr><td>"
    puts -nonewline $indexFH "Releases"
    puts -nonewline $indexFH "</td><td>"
    foreach r $releases {
      puts -nonewline $indexFH "<div style='float:left'><label><input type='checkbox' name='release' value='$r' class='filter' checked />$r</label></div>"
    }
    puts -nonewline $indexFH "</td></tr><tr><td>"
    puts -nonewline $indexFH "Versions"
    puts -nonewline $indexFH "</td><td>"
    foreach v $versions {
      puts -nonewline $indexFH "<div style='float:left'><label><input type='checkbox' name='version' value='$v' class='filter' checked />$v</label></div>"
    }
    puts -nonewline $indexFH "</td></tr><tr><td>"
    puts -nonewline $indexFH "Experiments"
    puts -nonewline $indexFH "</td><td>"
    foreach e $experiments {
#       puts -nonewline $indexFH "<div style='float:left'><label><input type='checkbox' name='experiment' value='$e' class='filter' checked />$e</label></div>"
      puts -nonewline $indexFH "<div><label><input type='checkbox' name='experiment' value='$e' class='filter' checked />$e</label></div>"
    }
    puts -nonewline $indexFH "</td></tr><tr><td>"
    puts -nonewline $indexFH "Steps"
    puts -nonewline $indexFH "</td><td>"
    foreach s $steps {
      puts -nonewline $indexFH "<div style='float:left'><label><input type='checkbox' name='step' value='$s' class='filter' checked />$s</label></div>"
    }
    puts -nonewline $indexFH "</td></tr></table>"
#     htmlTableHeader $indexFH {Snapshots Summary :} [list {ID} {Project} {Run} {Version} {Experiment} {Step}]
    htmlTableHeader $indexFH {Snapshots Summary :} [list {ID} {Project} {Release} {Version} {Experiment} {Step} {Run} {Date}]
    if {$verbose} {
      print info "Creating HTML index file [file join $exportDir index.html]"
    }
  }

  set numrow 0
  foreach id $snapshotids {
    set CMD "SELECT project, run, version, experiment, step, release, description, date, time
           FROM snapshot
           WHERE id = $id
           ;
           "
    execSQL SQL { pragma integrity_check }
    SQL eval $CMD values {
  #     parray values
      incr numrow
      set project $values(project)
      set run $values(run)
      set version $values(version)
      set experiment $values(experiment)
      set step $values(step)
      set release $values(release)
      set description $values(description)
      set date $values(date)
      set time $values(time)
      foreach el {project run version experiment step release description date time} { set var($el) $values($el) }
      if {$verbose} {
        print info "Processing snapshot ID=$id : project:$project version:$version experiment:$experiment step:$step release:$release run:$run date:$date time:$time"
      }
#       if {$debug} {
#         print debug "Snapshot ID=$id : project:$project run:$run version:$version experiment:$experiment step:$step date:$date time:$time"
#       }

      set CMD2 "SELECT name, value
             FROM metric
             WHERE snapshotid = $id
                   AND ( name IN ('[join $metrics ',']') )
             ;
             "
      execSQL SQL { pragma integrity_check }
      set first 1
      set snapshotFH {}
      SQL eval $CMD2 metricinfo {
        set metricname $metricinfo(name)
        set metricvalue $metricinfo(value)
        regsub -all "%id" $filenameExpr $id filename
        regsub -all "%project" $filename $project filename
        regsub -all "%release" $filename $release filename
        regsub -all "%version" $filename $version filename
        regsub -all "%experiment" $filename $experiment filename
        regsub -all "%step" $filename $step filename
        regsub -all "%metricname" $filename $metricname filename
        regsub -all "%id" $directoryExpr $id dirname
        regsub -all "%project" $dirname $project dirname
        regsub -all "%release" $dirname $release dirname
        regsub -all "%version" $dirname $version dirname
        regsub -all "%experiment" $dirname $experiment dirname
        regsub -all "%step" $dirname $step dirname
        regsub -all "%metricname" $dirname $metricname dirname
        if {$dirname != {}} {
          if {![file isdirectory [file join $exportDir $dirname]]} {
            if {$verbose} {
              print stdout "Creating directory [file join $exportDir $dirname]"
            }
            file mkdir [file join $exportDir $dirname]
          }
        }
        if {$saveHtml} {
          append filename {.html}
          if {$first} {
            if {$indexFH != {}} {
#               puts $indexFH "<h5><a href='[file join $dirname ${id}.html]' target='_blank'>snapshot ID=$id : project:$project run:$run version:$version experiment:$experiment step:$step</a></h5>"
#               htmlTableRow $indexFH [list release_$release version_$version experiment_$experiment step_$step] [list [format {<a href='%s' target='_blank'>%s</a>} [file join $dirname ${id}.html] $id] $project $run $version $experiment $step]
              htmlTableRow $indexFH [list release_$release version_$version experiment_$experiment step_$step] [list [format {<a href='%s' target='_blank'>%s</a>} [file join $dirname ${id}.html] $id] $project $release $version $experiment $step $run $date]
              flush $indexFH
            }
#             catch {
#               if {![file isdirectory [file join $exportDir $dirname media]]} {
#                 exec cp -r /wrk/hdstaff/dpefour/support/Olympus/assets/www/media [file join $exportDir $dirname]
#               }
#             }
            set snapshotFH [open [file join $exportDir $dirname "${id}.html"] {w}]
#             puts $snapshotFH "<head><body>"
#             puts $snapshotFH "<h1>snapshot ID=$id : project:$project run:$run version:$version experiment:$experiment step:$step date:$date time:$time</h1><hr>"
            htmlHeader $snapshotFH
            htmlBody $snapshotFH
            # Calculate dir depth between index.html and snapshot HTML file
            set depth [expr [llength [file split [file join $exportDir $dirname "${id}.html"]]] - [llength [file split [file join $exportDir "index.html"]]] ]
            puts -nonewline $snapshotFH [format {<a href='%s'>[Index page]</a>} "[string repeat ../ $depth]./index.html" ]
            puts -nonewline $snapshotFH [format {[%s]} [file join $exportDir $dirname ${id}.html] ]
#             puts $snapshotFH "<h2>Snapshot id=$id : project:$project run:$run version:$version experiment:$experiment step:$step date:$date time:$time</h2>"
#             puts $snapshotFH "<h4>Database: [file normalize $db]</h4>"
#             puts $snapshotFH "<h4>File: [file join $exportDir $dirname ${id}.html]</h4>"
            puts -nonewline $snapshotFH "<table border='1' cellpadding='2' cellspacing='2' style='margin-top: 10px'>"
            puts -nonewline $snapshotFH "<tr><td>ID</td><td>Project</td><td>Release</td><td>Version</td><td>Experiment</td><td>Step</td><td>Run</td><td>Date</td><td>Description</td></tr>"
            puts -nonewline $snapshotFH "<tr><td>$id</td><td>$project</td><td>$release</td><td>$version</td><td>$experiment</td><td>$step</td><td>$run</td><td>$date</td><td>$description</td></tr>"
            puts -nonewline $snapshotFH "</table>"
            htmlTableHeader $snapshotFH {Metrics Summary :} [list {Metric Name} {Metric Value}]
#             htmlTableHeader $snapshotFH "Snapshot id=$id : project:$project run:$run version:$version experiment:$experiment step:$step date:$date time:$time" [list {Metric Name} {Metric Value}]
            if {$verbose} {
              print info "Creating snapshot HTML index file [file join $exportDir $dirname ${id}.html]"
            }
          }
        }
        if {$writeMetricFiles} {
          if {$debug} {
            print debug "Writting metric file [file join $exportDir $dirname $filename] := [txt2html [truncateText $metricvalue]]"
          }
          set metricFH [open [file join $exportDir $dirname $filename] {w}]
          if {$saveHtml} {
            if {$metricFH != {}} {
            }
            puts -nonewline $metricFH [format {<a href='%s'>[Snapshot page]</a>} ${id}.html ]
            puts -nonewline $metricFH [format {[%s]} [file join $exportDir $dirname $filename] ]
            puts -nonewline $metricFH "<table border='1' cellpadding='2' cellspacing='2' style='margin-top: 10px'>"
            puts -nonewline $metricFH "<tr><td>ID</td><td>Project</td><td>Release</td><td>Version</td><td>Experiment</td><td>Step</td><td>Run</td><td>Date</td><td>Description</td></tr>"
            puts -nonewline $metricFH "<tr><td>$id</td><td>$project</td><td>$release</td><td>$version</td><td>$experiment</td><td>$step</td><td>$run</td><td>$date</td><td>$description</td></tr>"
            puts -nonewline $metricFH "</table>"
            puts -nonewline $metricFH [format "<h2>%s</h2><hr><pre>\n%s\n</pre><hr>" $metricname [txt2html $metricvalue]]
#             puts $snapshotFH [format {<h4><a href='%s' target='_blank'>%s</a>:%s</h4>} $filename $metricname [truncateText $metricvalue]]
            htmlTableRow $snapshotFH {} [list [format {<a href='%s' target='_blank'>%s</a>} $filename $metricname] [truncateText $metricvalue] ]
          } else {
            puts -nonewline $metricFH $metricvalue
          }
#           puts -nonewline $metricFH $metricvalue
          close $metricFH
#           if {$debug} {
#             print debug "snapshotid=$id / name=$metricname / value='[truncateText $metricvalue]'"
#           }
        } else {
          htmlTableRow $snapshotFH {} [list [format {<a href='%s' target='_blank'>%s</a>} $filename $metricname] [truncateText $metricvalue] ]
        }
        set first 0
      }
      
      if {$snapshotFH != {}} {
#         puts $snapshotFH "</body></head>"
        htmlTableFooter $snapshotFH
        htmlFooter $snapshotFH
        close $snapshotFH
        set snapshotFH {}
      }


    }

  }
  
  if {$indexFH != {}} {
#     puts $indexFH "</body></head>"
    htmlTableFooter $indexFH
    htmlFooter $indexFH
    close $indexFH
    set indexFH {}
  }

  SQL close
  if {$verbose} {
    print info "Export completed on [clock format [clock seconds]]"
    print info ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  }

  # Restore state of verbosity & debug
  set verbose $_verbose_
  set debug $_debug_

  return -code ok
}

#------------------------------------------------------------------------
# ::tb::snapshot::dbreport
#------------------------------------------------------------------------
# Usage: ::tb::snapshot::dbreport
#------------------------------------------------------------------------
# Print a summary of all snapshots inside the database
#------------------------------------------------------------------------
proc ::tb::snapshot::dbreport {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable summary
  variable params
  variable verbose
  variable debug
  # Save current state of verbosity & debug
  set _verbose_ $verbose
  set _debug_ $debug
  set db [getDB]
  set allsnapshotids {}
  set project {%}
  set run {%}
  set version {%}
  set experiment {%}
  set step {%}
  set release {%}
  set reset 0
  set error 0
  set help 0
#   if {[llength $args] == 0} {
#     set help 1
#   }
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -db {
        set db [lshift args]
      }
      -id {
        set allsnapshotids [concat $allsnapshotids [split [lshift args] ,]]
      }
      -p -
      -project {
        set project [lshift args]
      }
      -r -
      -run {
        set run [lshift args]
      }
      -ver -
      -version {
        set version [lshift args]
      }
      -e -
      -experiment {
        set experiment [lshift args]
      }
      -s -
      -step {
        set step [lshift args]
      }
      -rel -
      -release -
      -vivado {
           set release [lshift args]
      }
      -verbose {
        ::tb::snapshot::method:configure -verbose
      }
      -quiet {
        ::tb::snapshot::method:configure -quiet
      }
      -debug {
        ::tb::snapshot::method:configure -debug
      }
      -nodebug {
        ::tb::snapshot::method:configure -nodebug
      }
      -h -
      -help {
           set help 1
      }
      default {
            if {[string match "-*" $name]} {
              print error "option '$name' is not a valid option."
              incr error
            } else {
              print error "option '$name' is not a valid option."
              incr error
            }
      }
    }
  }

  if {$help} {
    print stdout [format {
  Usage: ::tb::snapshot::dbreport
              [-db <filename>]
              [-id <list_snapshot_ids>]
              [-project|-p <string>]
              [-run|-r <string>]
              [-version|-ver <string>]
              [-experiment|-e <string>]
              [-step|-s <string>]
              [-release|-rel <string>]
              [-verbose|-quiet]
              [-help|-h]

  Description: Generate a summary report of a database

  Example:
     ::tb::snapshot::dbreport
     ::tb::snapshot::dbreport -db ./metrics.db
     ::tb::snapshot::dbreport -experiment {No%%Buffer%%}
} ]
    # HELP -->
    set verbose $_verbose_
    set debug $_debug_
    return -code ok
  }

  if {![file exists $db]} {
    print error "Database '$db' does not exist"
    incr error
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  # Some styles for the report
  catch { ::report::rmstyle simpletable }
  ::report::defstyle simpletable {} {
    data	set [split "[string repeat "| "   [columns]]|"]
    top	set [split "[string repeat "+ - " [columns]]+"]
    bottom	set [top get]
    top	enable
    bottom	enable
  }
  catch { ::report::rmstyle captionedtable }
  ::report::defstyle captionedtable {{n 1}} {
	  simpletable
	  topdata   set [data get]
	  topcapsep set [top get]
	  topcapsep enable
	  tcaption $n
	}
  catch {matrixFormat destroy}
  ::report::report matrixFormat 10 style captionedtable 1
#   matrixFormat justify 2 center

  # Just in case: destroy previous matrix if it was not done before
  catch {summary destroy}
  struct::matrix summary
  summary add columns 10
  summary add row [list {id} {project} {release} {version} {experiment} {step} {run} {date} {time} {# metrics} ]

  if {$verbose} {
    print info "<<<<<<<<<<<<<<< dbreport <<<<<<<<<<<<<<<"
    print info "Database: $db"
  }
  sqlite3 SQL $db -readonly true
  execSQL SQL { pragma integrity_check }
  set dbVersion [SQL eval { SELECT value FROM param WHERE property='version' LIMIT 1; } ]
  if {$verbose} { 
    print info "Database version: $dbVersion" 
    print info "DB report started on [clock format [clock seconds]]"
  }

  if {$allsnapshotids == {}} {
    set allsnapshotids [lsort [execSQL SQL "SELECT id FROM snapshot" ]]
#     puts "<allsnapshotids:$allsnapshotids>"
  } else {
    set L $allsnapshotids
    set allsnapshotids [list]
    foreach elm $L {
      if {[regexp {^[0-9]+$} $elm]} {
        lappend allsnapshotids $elm
      } elseif {[regexp {^([0-9]+)\-([0-9]+)$} $elm - n1 n2]} {
        if {$n1 > $n2} { foreach n1 $n2 n2 $n1 break }
        for { set i $n1 } { $i <= $n2 } { incr i } {
           lappend allsnapshotids $i
        }
      } else {
        error "invalid format for snapshot id: $elm"
      }
    }
    set allsnapshotids [lsort -unique $allsnapshotids]
    if {$debug} {
      print info "List of snapshot ids: $allsnapshotids"
    }
  }

  switch $dbVersion {
    1.2 {
      set CMD "SELECT id, project, run, version, experiment, step, date, time
          FROM snapshot
          WHERE id IN ('[join $allsnapshotids ',']')
                AND ( (project LIKE '$project') OR (project IS NULL) )
                AND ( (run LIKE '$run') OR (run IS NULL) )
                AND version LIKE '$version'
                AND experiment LIKE '$experiment'
                AND step LIKE '$step'
          ;
         "
    }
    1.3 {
      set CMD "SELECT id, project, run, version, experiment, step, release, description, date, time
          FROM snapshot
          WHERE id IN ('[join $allsnapshotids ',']')
                AND ( (project LIKE '$project') OR (project IS NULL) )
                AND ( (run LIKE '$run') OR (run IS NULL) )
                AND version LIKE '$version'
                AND experiment LIKE '$experiment'
                AND step LIKE '$step'
                AND ( (release LIKE '$release') OR (release IS NULL) )
          ;
         "
    }
    default {
      error "database version $dbVersion not supported"
    }
  }

  execSQL SQL { pragma integrity_check }
  SQL eval $CMD values {
#     parray values
    set id $values(id)
    set project $values(project)
    set run $values(run)
    set version $values(version)
    set experiment $values(experiment)
    set step $values(step)
    set release $values(release)
    set description $values(description)
    set date $values(date)
    set time $values(time)
    foreach el {id project run version experiment step release description date time} { set var($el) $values($el) }
    if {$debug} {
      print debug "Snapshot ID=$id : project:$project version:$version experiment:$experiment step:$step release:$release run:$run date:$date time:$time"
    }

    execSQL SQL { pragma integrity_check }
    set nummetrics [SQL eval "SELECT count(name) FROM metric WHERE snapshotid = $id"]
    summary add row [list $id $project $release $version $experiment $step $run $date $time $nummetrics ]

#     summary add row [list $id $project $run $version $experiment $step $date $time ]
  }

#   print stdout [summary format 2string]
  print stdout [summary format 2string matrixFormat]
#   print stdout [matrixFormat printmatrix summary]
  summary destroy
  matrixFormat destroy

  SQL close
  if {$verbose} {
    print info "DB report completed on [clock format [clock seconds]]"
    print info ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  }

  # Restore state of verbosity & debug
  set verbose $_verbose_
  set debug $_debug_

  return -code ok
}

#------------------------------------------------------------------------
# ::tb::snapshot::print
#------------------------------------------------------------------------
# Usage: ::tb::snapshot::print <type> <message> <nonewline>
#------------------------------------------------------------------------
# Print message
#------------------------------------------------------------------------
proc ::tb::snapshot::print {type message {nonewline ""}} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable snapshotlog
  variable logFH
  set callerName [lindex [info level [expr [info level] -1]] 0]
  set type [string tolower $type]
  set msg {}
  set fatalError 0
  switch -exact $type {
    "stdout" {
      set msg $message
    }
    "fatal" {
      set msg " FATAL ERROR: $message"
#       set msg " -E- $message"
      incr fatalError
    }
    "error" {
#       set msg "  ERROR: $message"
      set msg " -E- $message"
    }
    "warning" {
#       set msg "  WARNING: $message"
      set msg " -W- $message"
    }
    "info" {
#       set msg "  INFO: $message"
      set msg " -I- $message"
    }
    "debug" {
#       set msg "  INFO: $message"
      set msg " DEBUG: $message"
    }
    "log" {
      set msg " LOG: $message"
      #-------------------------------------------------------
      # Log message.
      #-------------------------------------------------------
      if {$logFH != {}} {
        if {$nonewline != ""} {
          puts -nonewline $logFH $msg
        } else {
          puts $logFH $msg
        }
        flush $logFH
      }
      return -code ok
    }
   default {}
  }
  #-------------------------------------------------------
  # Print message.
  #-------------------------------------------------------
  if {$nonewline != ""} {
    puts -nonewline stdout $msg
  } else {
    puts stdout $msg
  }
  flush stdout
  #-------------------------------------------------------
  # Keep message inside namespace.
  #-------------------------------------------------------
  lappend snapshotlog $msg
  #-------------------------------------------------------
  # Log message.
  #-------------------------------------------------------
  if {$logFH != {}} {
    if {$nonewline != ""} {
      puts -nonewline $logFH $msg
    } else {
      puts $logFH $msg
    }
    flush $logFH
  }
  #-------------------------------------------------------
  # Done.
  #-------------------------------------------------------
  if {$fatalError} {
    error " A fatal error happened."
  }
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::snapshot::htmlHeader
#------------------------------------------------------------------------
# Usage: ::tb::snapshot::htmlHeader
#------------------------------------------------------------------------
# Generate HTML header
#------------------------------------------------------------------------
proc ::tb::snapshot::htmlHeader {channel} {
  # Summary :
  # Argument Usage:
  # Return Value:

  puts $channel [format {
<!DOCTYPE html>
<html>
<head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <link rel="shortcut icon" type="image/ico" href="http://www.xilinx.com/favicon.ico" />
    <title></title>
    <style type="text/css" title="currentStyle">
      @import "http://code.jquery.com/ui/1.8.4/themes/smoothness/jquery-ui.css";
      @import "http://cdn.datatables.net/1.9.4/css/jquery.dataTables.css";
    </style>
    <style type="text/css" title="currentStyle">
      table.display tr.even.row_selected td {
        background-color: #B0BED9;
      }
      table.display tr.odd.row_selected td {
        background-color: #9FAFD1;
      }
      table.display tr.even.row_selected td.k7only {
        background-color: #B0BED9;
      }
      table.display tr.odd.row_selected td.k7only {
        background-color: #9FAFD1;
      }
      table.display tr.even.row_selected td.k8only {
        background-color: #B0BED9;
      }
      table.display tr.odd.row_selected td.k8only {
        background-color: #9FAFD1;
      }
      /* lavender */
      table.display tr.even td.k7only {
        background-color: #E6E6FA;
      }
      table.display tr.odd td.k7only {
        background-color: #E6E6FA;
      }
      /* PaleTurquoise */
      table.display tr.even td.k8only {
        background-color: #AFEEEE;
      }
      table.display tr.odd td.k8only {
        background-color: #AFEEEE;
      }
    </style>

    <script src="http://code.jquery.com/jquery-1.8.2.min.js"></script>
    <script src="http://cdn.datatables.net/1.9.4/js/jquery.dataTables.min.js"></script>
    <script type="text/javascript" charset="utf-8">
        function fnShowHide( iCol )
        {
            /* Get the DataTables object again - this is not a recreation, just a get of the object */
            /*var oTable = $('#example').dataTable();*/
            var bVis = oTable.fnSettings().aoColumns[iCol].bVisible;
            oTable.fnSetColumnVis( iCol, bVis ? false : true );
        }
    </script>

    <script type="text/javascript" charset="utf-8">
      var oTable;
      $(document).ready(function() {

           /* Add a click handler for filtering rows based on the filtering checkboxes */
           $('.filter').click( function() {
               if ( !$(this).is(':checked') ) {
                   // Extract the class from the checkbox that has been clicked on: $(this).prop('name')+"_"+$(this).val()
                   $("#table tbody tr").filter("[class~='"+$(this).prop('name')+"_"+$(this).val()+"']").hide();
               } else {
                   // Extract the class from the checkbox that has been clicked on: $(this).prop('name')+"_"+$(this).val()
                   $("#table tbody tr").filter("[class~='"+$(this).prop('name')+"_"+$(this).val()+"']").show();
               }
           } );

           /* Add a click handler to check all the checkboxes and show all the rows */
           $('#selectall').click( function() {
               $("#table tbody tr").show();
               $(".filter").attr('checked','checked');
           } );

           /* Add a click handler to uncheck all the checkboxes and hide all the rows */
           $('#unselectall').click( function() {
               $("#table tbody tr").hide();
               $(".filter").removeAttr('checked');
           } );

          /* Add a click handler to the rows - this could be used as a callback */
          $("#table tbody tr").click( function( e ) {
            if ( $(this).hasClass('row_selected') ) {
                $(this).removeClass('row_selected');
            }
            else {
                // Comment out next line to allow multiple row selection
                // oTable.$('tr.row_selected').removeClass('row_selected');
                $(this).addClass('row_selected');
            }
          });
        
          $('#table').dataTable( {
              "aaSorting": [],
              "aoColumnDefs": [
              ],
              "bJQueryUI": true,
              "sPaginationType": "full_numbers",
              "bPaginate": false
           } );
           
          /* Init the table */
          oTable = $('#table').dataTable();
        
      } );
    </script>
</head>
} ]

}

#------------------------------------------------------------------------
# ::tb::snapshot::htmlBody
#------------------------------------------------------------------------
# Usage: ::tb::snapshot::htmlBody
#------------------------------------------------------------------------
# Generate HTML body
#------------------------------------------------------------------------
proc ::tb::snapshot::htmlBody {channel} {
  # Summary :
  # Argument Usage:
  # Return Value:

  puts $channel [format {
  <body>
}]

}

#------------------------------------------------------------------------
# ::tb::snapshot::htmlTableHeader
#------------------------------------------------------------------------
# Usage: ::tb::snapshot::htmlTableHeader
#------------------------------------------------------------------------
# Generate HTML table header
#------------------------------------------------------------------------
proc ::tb::snapshot::htmlTableHeader {channel title header} {
  # Summary :
  # Argument Usage:
  # Return Value:

  if {$title != {}} {
    puts -nonewline $channel [format {
     <div class="container_wrapper">
        <h3>%s</h3>} [txt2html $title] ]
  } else {
    puts -nonewline $channel [format {
     <div class="container_wrapper">} ]
  }

  puts -nonewline $channel [format {
        <table cellpadding="0" cellspacing="0" border="1" class="display" id="table">
          <thead>
            <tr> }]

  foreach elm $header {
    puts -nonewline $channel [format {
              <th>%s</th> } [txt2html $elm] ]
  }

  puts -nonewline $channel [format {
            </tr>
          </thead>
          <tbody> }]

}

#------------------------------------------------------------------------
# ::tb::snapshot::htmlTableRow
#------------------------------------------------------------------------
# Usage: ::tb::snapshot::htmlTableRow
#------------------------------------------------------------------------
# Generate HTML table row
#------------------------------------------------------------------------
proc ::tb::snapshot::htmlTableRow {channel class row} {
  # Summary :
  # Argument Usage:
  # Return Value:

    puts -nonewline $channel [format {
            <tr class="odd gradeX %s"> } $class]
    foreach elm $row {
      puts -nonewline $channel [format {
              <td>%s</td> } [txt2html $elm] ]
    }
    puts -nonewline $channel [format {
            </tr> }]

}

#------------------------------------------------------------------------
# ::tb::snapshot::htmlTableFooter
#------------------------------------------------------------------------
# Usage: ::tb::snapshot::htmlTableFooter
#------------------------------------------------------------------------
# Generate HTML table footer
#------------------------------------------------------------------------
proc ::tb::snapshot::htmlTableFooter {channel} {
  # Summary :
  # Argument Usage:
  # Return Value:

  puts $channel [format {
          </tbody>
        </table>
     </div>
}]

}

#------------------------------------------------------------------------
# ::tb::snapshot::htmlFooter
#------------------------------------------------------------------------
# Usage: ::tb::snapshot::htmlFooter
#------------------------------------------------------------------------
# Generate HTML footer
#------------------------------------------------------------------------
proc ::tb::snapshot::htmlFooter {channel} {
  # Summary :
  # Argument Usage:
  # Return Value:

  puts $channel [format {
  </body>
</html>
}]

}



#################################################################################

# For debug:
proc reload {} { catch {namespace delete ::tb::snapshot}; source -notrace ~/git/scripts/wip/snapshot.tcl; puts " snapshot.tcl reloaded" }
namespace import ::tb::snapshot

# Information
# snapshot -help
# # puts " Add commands to the snapshot with:"
# # puts "     snapshot add *\n"
# snapshot add *


# # Vivado 2014.3 @ brisk119
# 
# dpefour@brisk119-10% lsb_release -a
# LSB Version:    :core-3.0-amd64:core-3.0-ia32:core-3.0-noarch:graphics-3.0-amd64:graphics-3.0-ia32:graphics-3.0-noarch
# Distributor ID: RedHatEnterpriseWS
# Description:    Red Hat Enterprise Linux WS release 4 (Nahant Update 7)
# Release:        4
# Codename:       NahantUpdate7
# 
# Vivado% source snapshot.tcl
# couldn't load file "/home/dpefour/root/usr/lib/sqlite3.8.0.2/libsqlite3.8.0.2.so": /home/dpefour/root/usr/lib/sqlite3.8.0.2/libsqlite3.8.0.2.so: requires glibc 2.5 or later dynamic linker
#     while executing
# "package require sqlite3"
#     (file "../snapshot.tcl" line 36)
# 
# 
# # Vivado 2014.3 @ teapot5
# 
# dpefour@teapot4-13% lsb_release -a
# LSB Version:    :core-4.0-amd64:core-4.0-ia32:core-4.0-noarch:graphics-4.0-amd64:graphics-4.0-ia32:graphics-4.0-noarch:printing-4.0-amd64:printing-4.0-ia32:printing-4.0-noarch
# Distributor ID: RedHatEnterpriseClient
# Description:    Red Hat Enterprise Linux Client release 5.9 (Tikanga)
# Release:        5.9
# Codename:       Tikanga
# 
# Vivado% source snapshot.tcl




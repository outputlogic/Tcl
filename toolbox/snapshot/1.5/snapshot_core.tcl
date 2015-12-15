#!/bin/sh
# use -*-TCL-*- \
exec tclsh "$0" "$@"

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
## Version:        2015.12.15
## Tool Version:   Vivado 2014.1
## Description:    This utility provides a simple way to extract and save metrics
##
########################################################################################

########################################################################################
## 2015.12.15 - Added -noreset to 'take_snapshot'
##            - Minor reformatting (tabs->spaces)
## 2015.12.14 - Added -once to method 'set'
## 2015.05.06 - Fixed uninitialized variable when database is locked and timeout occurs
## 2014.10.24 - Moved the SQL TABLE/PRAGMA structures in standalone procs
##            - Added more snapshot related information in verbose mode
## 2014.10.08 - Added method 'exists' to check if a metric has already been defined
##            - Fixed issue in method 'get'
##            - Added support for command options to method 'addfile'
##            - Added support for command options to method 'addparam'
##            - The machine name is now saved as metric value inside the snapshot
## 2014.09.25 - The parentid is now saved as metric value inside the snapshot
## 2014.06.27 - The released name is extracted from Vivado version when not specified
##            - Added timeout to execSQL when the database is locked
##            - Added -timeout to relevant procs
##            - Removed default extraction metrics to extract.tcl
##            - Added support for command options to method 'set'
##            - Other enhancements and fixes
## 2014.06.03 - Splitted snapshot.tcl into snapshot_core.tcl, snapshot_db2csv.tcl
##              and snapshot_db2dir.tcl
##            - Other enhancements and fixes
## 2014.06.02 - Updated database to 1.5
##            - Added columns 'type'/'ref'/'binary'/'enabled'/'eol'/'size' to database (metric table)
##            - Removed column 'source' from database (metric table)
##            - Updated relevant procs to support new type/ref/binary/enabled columns
##            - Added -transpose to method db2csv
##            - Updated to latest JavaScript libraries
##            - Moved from JQuery UI to Bootstrap
##            - Other enhancements and fixes
## 2014.05.27 - Fixed execSQL to use the SQL command passed as parameter
## 2014.05.22 - Added take_snapshot
##            - Added support for incremental metrics extraction (-id/-incremental)
##            - Other enhancements and fixes
## 2014.05.14 - Updated database to 1.4
##            - Added column 'enabled' to database (snapshot table)
##            - Renamed method load to db2array
##            - Replaced -newdb by -createdb
##            - Added -fragment/-metricexpr to method db2dir
##            - Added support for environment variables to specify the snapshot's parameters:
##                  setenv SNAPSHOT_DB <path_to_database>
##                  setenv SNAPSHOT_PROJECT <string>
##                  setenv SNAPSHOT_RELEASE <string>
##                  setenv SNAPSHOT_VERSION <string>
##                  setenv SNAPSHOT_EXPERIMENT <string>
##                  setenv SNAPSHOT_STEP <string>
##                  setenv SNAPSHOT_RUN <string>
##                  setenv SNAPSHOT_DESCRIPTION <string>
##                  setenv SNAPSHOT_LASTID <integer>
##            - Added support for 'parentid' inside method save
##            - Binary files can be read in/out as metric
##            - Added the ability to code the step name inside the filename:
##                  snapshot.<step>.tcl
##            - The script can be executed to execute any of the sub-methods:
##                  % ./snapshot.tcl dbreport -db ./metrics.db
##            - Other enhancements and fixes
## 2014.05.12 - Updated database to 1.3
##            - Added columns 'release'/'description'/'parentid' to database (snapshot table)
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

# Suggested list of Vivado steps:
#     synth_design
#     opt_design
#     power_opt_design
#     place_design
#     post_place_power_opt_design
#     phys_opt_design
#     route_design
#     post_route_phys_opt_design
#     write_bitstream


# Proc to reload current script
proc [file tail [info script]] {} " source [info script]; puts \" [info script] reloaded\" "

if {[info exists DEBUG]} { puts " Sourcing [file normalize [info script]]" }

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

# Namespace to save procs used during extraction
namespace eval ::tb::snapshot::extract {}

# Try to load the package 'extract' to load the metrics that need to be extracted
catch { package require extract }

namespace eval ::tb {
    namespace export snapshot take_snapshot
}

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

proc ::tb::take_snapshot { args } {
  # Summary : Tcl snapshot

  # Argument Usage:
  # args : sub-command. The supported sub-commands are: start | stop | summary | add | remove | reset | status

  # Return Value:
  # returns the status or an error code

#   if {[catch {set res [uplevel [concat ::tb::snapshot::snapshot $args]]} errorstring]} {
#     error " -E- the snapshot failed with the following error: $errorstring"
#   }
  return [uplevel [concat ::tb::snapshot::take_snapshot $args]]
}

###########################################################################
##
## Higher level proc
##
###########################################################################

#------------------------------------------------------------------------
# ::tb::snapshot::take_snapshot
#------------------------------------------------------------------------
# Main function
#------------------------------------------------------------------------

proc ::tb::snapshot::take_snapshot { args } {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable params
  variable metrics
  variable metricTypes
  variable metricRefs
  variable verbose
  variable debug
  # Save current state of verbosity & debug
  set _verbose_ $verbose
  set _debug_ $debug
  set lastid {}
  set incremental 0
  set id {}
  set time 0
  set reset 1
  set error 0
  set help 0
#   if {[llength $args] == 0} {
#     set help 1
#   }
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -id {
        set id [lshift args]
      }
      -incr -
      -incremental {
        # Incremental extraction
        set incremental 1
      }
      -noreset -
      -noreset {
        # Prevent resetting the metrics before extraction
        set reset 0
      }
      -time {
        ::tb::snapshot::method:configure -time [lshift args]
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
      -timeout {
        ::tb::snapshot::method:configure -timeout [lshift args]
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
  Usage: take_snapshot
              [-db <filename>]
              [-project|-p <string>]
              [-release|-rel <string>]
              [-version|-ver <string>]
              [-experiment|-e <string>]
              [-step|-s <string>]
              [-run|-r <string>]
              [-description|-desc|-d <string>]
              [-time <time_in_seconds>]
              [-timeout <seconds>]
              [-id <snapshot_id>|-incr|-incremental]
              [-noreset]
              [-verbose|-quiet]
              [-help|-h]

  Description: Take a snapshot

  Example:
     take_snapshot -step route_design
     take_snapshot -experiment noHighFanout -step place_design
} ]
    # HELP -->
    # Restore state of verbosity & debug
    set verbose $_verbose_
    set debug $_debug_
    return -code ok
  }

  if {$incremental && ($id != {})} {
    print error "cannot use -id and -incremental at the same time"
    incr error
  }

  if {$error} {
    # Restore state of verbosity & debug
    set verbose $_verbose_
    set debug $_debug_
    error " -E- some error(s) happened. Cannot continue"
  }

  print stdout "Running 'take_snapshot' for step '$params(step)' on [clock format [clock seconds]] ..."
  if {$reset} {
   # Destroy all the metrics first
    catch {unset metrics}
    catch {unset metricTypes}
    catch {unset metricRefs}
    array set metrics [list]
    array set metricTypes [list]
    array set metricRefs [list]
  }
  # Extract the metrics
  ::tb::snapshot::method:extract
  # Save the snapshot
  if {$incremental} {
    set lastid [::tb::snapshot::method:save -incremental]
  } elseif {$id != {}} {
    set lastid [::tb::snapshot::method:save -id $id]
  } else {
    set lastid [::tb::snapshot::method:save]
  }
  print stdout "Completed 'take_snapshot' for step '$params(step)' on [clock format [clock seconds]] ..."

  # Restore state of verbosity & debug
  set verbose $_verbose_
  set debug $_debug_

  return $lastid
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
  variable version {2015.12.15}
  variable params
  variable metrics
  variable metricTypes
  variable metricRefs
  variable summary
  variable snapshotlog [list]
  variable logFH {}
  variable logFile {}
#   variable verbose 0
  variable verbose 1
  variable debug 0
  catch {unset params}
  catch {unset metrics}
  catch {unset metricTypes}
  catch {unset metricRefs}
  array set params [list db {} project {} run {} version {} experiment {} step {} release {} description {} time 0 timeout 600 lastid {} ]
  array set metrics [list ]
  array set metricTypes [list ]
  array set metricRefs [list ]
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
    db2ar -
    db2arr -
    db2arra -
    db2array {
      return [eval [concat ::tb::snapshot::method:db2array $args] ]
    }
    dump {
      return [eval [concat ::tb::snapshot::dump] ]
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

     Suggested list of Vivado steps for -step option:
         synth_design
         opt_design
         power_opt_design
         place_design
         post_place_power_opt_design
         phys_opt_design
         route_design
         post_route_phys_opt_design
         write_bitstream

   Example:
      snapshot configure -db metrics.db -createdb
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
# ::tb::snapshot::SQLInit
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Return the SQL command to initialize the table(s) once created
#------------------------------------------------------------------------
proc ::tb::snapshot::SQLInit {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Database version & other parameters
  return [format {
    INSERT INTO param(property,value) VALUES("version","1.5");
    INSERT INTO param(property,value) VALUES("date",strftime('%%Y-%%m-%%d %%H:%%M:%%S','now') );
    INSERT INTO param(property,value) VALUES('time','%s' );
    INSERT INTO param(property,value) VALUES('directory','%s' );
  } [clock seconds] [file normalize [uplevel #0 pwd]] ]
}

#------------------------------------------------------------------------
# ::tb::snapshot::SQLPragmasSQLPragmas
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Return the SQL pragmas structure
#------------------------------------------------------------------------
proc ::tb::snapshot::SQLPragmas {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # PRAGMA for very large databases:
  return [format {
    PRAGMA foreign_keys = ON;
    PRAGMA main.temp_store = MEMORY;
    PRAGMA main.page_size = 4096;
    PRAGMA main.cache_size=10000;
    PRAGMA main.locking_mode=EXCLUSIVE;
    PRAGMA main.synchronous=NORMAL;
    PRAGMA main.journal_mode=MEMORY;
    PRAGMA main.cache_size=5000;
  }]
}

#------------------------------------------------------------------------
# ::tb::snapshot::SQLTables
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Return the SQL tables structure
#------------------------------------------------------------------------
proc ::tb::snapshot::SQLTables {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Tables structure for database version 1.5
  return [format {
    CREATE TABLE IF NOT EXISTS param (
             id INTEGER PRIMARY KEY AUTOINCREMENT,
             property TEXT,
             value TEXT DEFAULT NULL
             );
    CREATE TABLE IF NOT EXISTS snapshot (
             id INTEGER PRIMARY KEY AUTOINCREMENT,
             parentid INTEGER,
             enabled BOOLEAN DEFAULT ( 1 ),
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
             enabled BOOLEAN DEFAULT ( 1 ),
             name TEXT DEFAULT NULL,
             value BLOB DEFAULT NULL,
             size INTEGER DEFAULT NULL,
             eol INTEGER DEFAULT NULL,
             binary BOOLEAN DEFAULT ( 0 ),
             type TEXT DEFAULT NULL,
             ref TEXT DEFAULT NULL,
             FOREIGN KEY(snapshotid) REFERENCES snapshot(id) ON UPDATE SET NULL
             );
  }]
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

  # Configure the snapshot (-help)
  variable params
  variable verbose
  variable debug
  variable logFH
  variable logFile
  global env
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
           # Update the global variable 'env' so that this information can be passed to jobs sent to LSF
           set env(SNAPSHOT_DB) $params(db)
      }
      -p -
      -project {
           set params(project) [lshift args]
           # Update the global variable 'env' so that this information can be passed to jobs sent to LSF
           set env(SNAPSHOT_PROJECT) $params(project)
      }
      -r -
      -run {
           set params(run) [lshift args]
#            # Update the global variable 'env' so that this information can be passed to jobs sent to LSF
#            set env(SNAPSHOT_RUN) $params(run)
      }
      -ver -
      -version {
           set params(version) [lshift args]
           # Update the global variable 'env' so that this information can be passed to jobs sent to LSF
           set env(SNAPSHOT_VERSION) $params(version)
      }
      -e -
      -experiment {
           set params(experiment) [lshift args]
           # Update the global variable 'env' so that this information can be passed to jobs sent to LSF
           set env(SNAPSHOT_EXPERIMENT) $params(experiment)
      }
      -s -
      -step {
           set params(step) [lshift args]
#            # Update the global variable 'env' so that this information can be passed to jobs sent to LSF
#            set env(SNAPSHOT_STEP) $params(step)
      }
      -rel -
      -release -
      -vivado {
           set params(release) [lshift args]
           # Update the global variable 'env' so that this information can be passed to jobs sent to LSF
           set env(SNAPSHOT_RELEASE) $params(release)
      }
      -d -
      -desc -
      -description {
           set params(description) [lshift args]
#            # Update the global variable 'env' so that this information can be passed to jobs sent to LSF
           set env(SNAPSHOT_DESCRIPTION) $params(description)
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
      -createdb {
           set reset 1
      }
      -timeout {
           set params(timeout) [lshift args]
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
              [-createdb]
              [-project|-p <string>]
              [-release|-rel <string>]
              [-version|-ver <string>]
              [-experiment|-e <string>]
              [-step|-s <string>]
              [-run|-r <string>]
              [-description|-desc|-d <string>]
              [-time <time_in_seconds>]
              [-timeout <seconds>]
              [-log <logfile>|-nolog]
              [-verbose|-quiet]
              [-help|-h]

  Description: Configure the snapshot

  Example:
     snapshot configure -createdb
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

  # Extract all the metrics (-help)
  variable params
  variable verbose
  variable debug
  # Save current state of verbosity & debug
  set _verbose_ $verbose
  set _debug_ $debug
  set mode {extract}
  set incremental 0
  set lastid 0
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
      -dry -
      -dry-run {
        set mode {norun}
      }
      -incr -
      -incremental {
           # Incremental extraction
           set incremental 1
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
      -createdb {
        ::tb::snapshot::method:configure -createdb
      }
      -timeout {
        ::tb::snapshot::method:configure -timeout [lshift args]
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
              [-dry-run]
              [-save]
          +-------------------------+
              [-reset]
              [-db <filename>]
              [-createdb]
              [-project|-p <string>]
              [-release|-rel <string>]
              [-version|-ver <string>]
              [-experiment|-e <string>]
              [-step|-s <string>]
              [-run|-r <string>]
              [-description|-desc|-d <string>]
              [-time <time_in_seconds>]
              [-incr|-incremental]
              [-timeout <seconds>]
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
      norun {
        print info "Found extract proc $procname"
      }
      default {
      }
    }
  }

  if {$save && ($mode != {norun})} {
    if {$incremental} {
      set lastid [snapshot save -incremental]
    } else {
      set lastid [snapshot save]
    }
  }

  # Restore state of verbosity & debug
  set verbose $_verbose_
  set debug $_debug_

  return $lastid
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

  # Set the database location (-help)
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
      -createdb {
        ::tb::snapshot::method:configure -createdb
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
              [<filename>]
              [-db <filename>|<filename>]
              [-createdb]
              [-verbose|-quiet]
              [-help|-h]

  Description: Set the database location

  Example:
     snapshot db -db ./metrics.db
     snapshot db ./metrics.db -createdb
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

  global env
  print stdout "   ### SNAPSHOT ###"
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
  # Dump environment variables
  print stdout "   ### ENVIRONMENT ###"
  foreach key [lsort [array names env SNAPSHOT_*]] {
    print stdout "     $key : $env($key)"
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

  variable verbose
  variable params
  variable debug
  if {$debug} {
    print debug "SQL command: $cmd"
  }

  set loop 0
  # Wait for the database to be unlocked
#   while {[catch { uplevel [list ${&SQL} eval $cmd] } errorstring]} {}
  while {[catch { set res [uplevel [list ${&SQL} eval $cmd]] } errorstring]} {
    if {[regexp {database is locked} $errorstring]} {
      if {$verbose} { print info "SQL database locked ..." }
      exec sleep 1
      incr loop
    } elseif {[regexp {attempt to write a readonly database} $errorstring]} {
      if {$verbose} { print info "SQL database read-only ..." }
      exec sleep 1
      incr loop
    } else {
      error $errorstring
    }
    if {$loop > $params(timeout)} { set res {}; break }
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

  # Save metrics into SQL database (-help)
  variable metrics
  variable metricTypes
  variable metricRefs
  variable params
  variable snapshotlog
  variable verbose
  variable debug
  global env
  set time $params(time)
  # For incremental mode
  set id {}
  set error 0
  set help 0
#   if {[llength $args] == 0} {
#     set help 1
#   }
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -id {
           set id [lshift args]
      }
      -incr -
      -incremental {
           # Incrementally save the metrics to the snapshot of id 'lastid'
           set id $params(lastid)
      }
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
              [-id <snapshot_id>|-incr|-incremental]
              [-time <time_in_seconds>]
              [-help|-h]

  Description: Save the snapshot

  Example:
     snapshot save
     snapshot save -id 1
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
  # Add the PARAGMAs
  execSQL SQL [::tb::snapshot::SQLPragmas]
  # Add the TABLEs
  execSQL SQL [::tb::snapshot::SQLTables]

  if {$firstSetup} {
    # Database version & other parameters
    execSQL SQL [::tb::snapshot::SQLInit]
#     execSQL SQL { INSERT INTO param(property,value) VALUES("version","1.5"); }
#     execSQL SQL { INSERT INTO param(property,value) VALUES("date",strftime('%Y-%m-%d %H:%M:%S','now') ); }
#     execSQL SQL " INSERT INTO param(property,value) VALUES('time','[clock seconds]' ); "
#     execSQL SQL " INSERT INTO param(property,value) VALUES('directory','[file normalize [uplevel #0 pwd]]' ); "
  }

  if {$id != {}} {
    # Incremental mode. The snapshot id must be valid before continuing
    set allsnapshotids [lsort [execSQL SQL "SELECT id FROM snapshot" ]]
    if {[lsearch $allsnapshotids $id] == -1} {
      SQL close
      error " -E- Snapshot id '$id' does not exist inside database $db'"
    }
  }

  set dbVersion [execSQL SQL { SELECT value FROM param WHERE property='version' LIMIT 1; } ]
  set project [getProject]
  set run [getRun]
#   execSQL SQL " INSERT INTO snapshot(version,experiment,step,date,time) VALUES('[getVersion]','[getExperiment]','[getStep]','[clock format $time -format {%Y-%m-%d %H:%M:%S}]','$time' ); "

  if {$id == {}} {
    # Standard mode. A snapshot gets added to the database
    switch $dbVersion {
      1.5 {
        # Get the last snapshot's id
        set lastid [::tb::snapshot::getLastID]
        if {$lastid != {}} {
          # Save the previously saved snapshot as the parentid of the current one
          if {[catch {execSQL SQL " INSERT INTO snapshot(parentid,version,experiment,step,release,description,date,time) VALUES($lastid,'[getVersion]','[getExperiment]','[getStep]','[getRelease]','[getDescription]','[clock format $time -format {%Y-%m-%d %H:%M:%S}]','$time' ); "} errorstring]} {
            # If the above command fails, it is most likely due to the foreign key constraint on 'parentid'.
            # In this scenario, let's try to save the snapshot without the 'parentid'
            execSQL SQL " INSERT INTO snapshot(version,experiment,step,release,description,date,time) VALUES('[getVersion]','[getExperiment]','[getStep]','[getRelease]','[getDescription]','[clock format $time -format {%Y-%m-%d %H:%M:%S}]','$time' ); "
            catch {unset env(SNAPSHOT_LASTID)}
            catch {set params(lastid) {}}
          }
        } else {
          execSQL SQL " INSERT INTO snapshot(version,experiment,step,release,description,date,time) VALUES('[getVersion]','[getExperiment]','[getStep]','[getRelease]','[getDescription]','[clock format $time -format {%Y-%m-%d %H:%M:%S}]','$time' ); "
        }
      }
      default {
        error "database version $dbVersion not supported"
      }
    }
    set snapshotid [SQL last_insert_rowid]
    if {$project != {}} {
      execSQL SQL " UPDATE snapshot SET project='$project' WHERE id=$snapshotid; "
    } else {
#       execSQL SQL " UPDATE snapshot SET project='' WHERE id=$snapshotid; "
      # Catch so that it does not error out outside of Vivado
      catch { set project [get_property -quiet NAME [current_project -quiet]] }
      execSQL SQL " UPDATE snapshot SET project='$project' WHERE id=$snapshotid; "
    }
    if {$run != {}} {
      execSQL SQL " UPDATE snapshot SET run='$run' WHERE id=$snapshotid; "
    } else {
#       execSQL SQL " UPDATE snapshot SET run='' WHERE id=$snapshotid; "
      # Catch so that it does not error out outside of Vivado
      catch { set run [get_property -quiet NAME [current_run -quiet]] }
      execSQL SQL " UPDATE snapshot SET run='$run' WHERE id=$snapshotid; "
    }
  } else {
    # Incremental mode. No snapshot gets added to the database. Only the metrics are being saved
    # under an existing snapshot id
    set snapshotid $id
  }

  # Save last snapshot id inside the internal array as well as inside the global 'env' variable
  # so that it can be passed on when Vivado jobs are sent to LSF
  set params(lastid) $snapshotid
  set env(SNAPSHOT_LASTID) $snapshotid
  set version [getVersion]
  set experiment [getExperiment]
  set step [getStep]
  set release [getRelease]
  set description [getDescription]
  if {$verbose} {
    print info "Project: $project"
    print info "Release: $release"
    print info "Experiment: $experiment"
    print info "Step: $step"
    print info "Run: $run"
    print info "Snapshot ID: $snapshotid"
  }

  # Save metrics
  foreach metric [lsort [array names metrics]] {
# print debug "metric: '$metric'"
    set value $metrics($metric)
# print debug "value: '$value'"
    execSQL SQL { INSERT INTO metric(snapshotid,name,value) VALUES($snapshotid,$metric,$value) ; }
    set metricid [SQL last_insert_rowid]
    execSQL SQL " UPDATE metric SET size=[string length $value], eol=[llength [split $value \n]] WHERE id=$metricid ; "
    if {[info exists metricTypes($metric)]} {
      execSQL SQL " UPDATE metric SET type='$metricTypes($metric)' WHERE id=$metricid ; "
    }
    if {[info exists metricRefs($metric)]} {
      execSQL SQL " UPDATE metric SET ref='$metricRefs($metric)' WHERE id=$metricid ; "
    }
    # To test whether a file is "binary", in the sense that it contains NUL bytes
    set isBinary [expr {[string first \x00 $value]>=0}]
    if {$isBinary} {
      execSQL SQL " UPDATE metric SET binary=1 WHERE id=$metricid ; "
    }
    if {$verbose} {
      print info "(ID=$metricid) $metric = [truncateText $value]"
    }
  }

  # Save system log
#   execSQL SQL { INSERT INTO metric(snapshotid,name,value,type,ref) VALUES($snapshotid,"snapshotlog",$snapshotlog,'blob',NULL) ; }
  set content [join $snapshotlog \n]
  if {[catch {set machine [uplevel #0 exec hostname]}]} {
    set machine {}
  }
#   execSQL SQL { INSERT INTO metric(snapshotid,name,value,type,ref) VALUES($snapshotid,"snapshotlog",$content,'blob',NULL) ; }
  execSQL SQL { INSERT INTO metric(snapshotid,name,value,type,ref,size,eol) VALUES($snapshotid,'snapshot.machine',$machine,'blob',NULL,-1,-1) ; }
  execSQL SQL { INSERT INTO metric(snapshotid,name,value,type,ref,size,eol) VALUES($snapshotid,'snapshot.log',$content,'blob',NULL,-1,-1) ; }
  execSQL SQL " INSERT INTO metric(snapshotid,name,value,type,ref,size,eol) VALUES($snapshotid,'snapshot.env','[array get env SNAPSHOT*]','blob',NULL,-1,-1) ; "
  execSQL SQL { INSERT INTO metric(snapshotid,name,value,type,ref,size,eol) VALUES($snapshotid,'snapshot.project',$project,'blob',NULL,-1,-1) ; }
  execSQL SQL { INSERT INTO metric(snapshotid,name,value,type,ref,size,eol) VALUES($snapshotid,'snapshot.run',$run,'blob',NULL,-1,-1) ; }
  execSQL SQL { INSERT INTO metric(snapshotid,name,value,type,ref,size,eol) VALUES($snapshotid,'snapshot.version',$version,'blob',NULL,-1,-1) ; }
  execSQL SQL { INSERT INTO metric(snapshotid,name,value,type,ref,size,eol) VALUES($snapshotid,'snapshot.experiment',$experiment,'blob',NULL,-1,-1) ; }
  execSQL SQL { INSERT INTO metric(snapshotid,name,value,type,ref,size,eol) VALUES($snapshotid,'snapshot.step',$step,'blob',NULL,-1,-1) ; }
  execSQL SQL { INSERT INTO metric(snapshotid,name,value,type,ref,size,eol) VALUES($snapshotid,'snapshot.release',$release,'blob',NULL,-1,-1) ; }
  execSQL SQL { INSERT INTO metric(snapshotid,name,value,type,ref,size,eol) VALUES($snapshotid,'snapshot.description',$description,'blob',NULL,-1,-1) ; }
  execSQL SQL { INSERT INTO metric(snapshotid,name,value,type,ref,size,eol) VALUES($snapshotid,'snapshot.parentid',$lastid,'blob',NULL,-1,-1) ; }
  execSQL SQL " INSERT INTO metric(snapshotid,name,value,type,ref,size,eol) VALUES($snapshotid,'snapshot.date','[clock format $time -format {%Y-%m-%d %H:%M:%S}]','blob',NULL,-1,-1) ; "
  execSQL SQL { INSERT INTO metric(snapshotid,name,value,type,ref,size,eol) VALUES($snapshotid,'snapshot.time',$time,'blob',NULL,-1,-1) ; }

  SQL close
  if {$verbose} {
    print info ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  }
  return $snapshotid
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
  global env
  set db {}
  if {![info exists params(db)] || ([info exists params(db)] && [regexp {^\s*$} $params(db)])} {
    if {![info exists env(SNAPSHOT_DB)]} {
      set db [file normalize {metrics.db}]
    } else {
      set db [file normalize $env(SNAPSHOT_DB)]
    }
  } else {
    set db [file normalize $params(db)]
  }
  return $db
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
  global env
  set name {}
  if {![info exists params(project)] || ([info exists params(project)] && [regexp {^\s*$} $params(project)])} {
    if {![info exists env(SNAPSHOT_PROJECT)]} {
      set name {}
    } else {
      set name $env(SNAPSHOT_PROJECT)
    }
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
  global env
  set name {}
  if {![info exists params(release)] || ([info exists params(release)] && [regexp {^\s*$} $params(release)])} {
    if {![info exists env(SNAPSHOT_RELEASE)]} {
      set name {}
      # If no release is defined, try to extract release from vivado version
      catch { set name [regsub {^([0-9]+\.[0-9]+)\.0$} [version -short] {\1}] }
    } else {
      set name $env(SNAPSHOT_RELEASE)
    }
  } else {
    set name $params(release)
  }
  return $name
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
  global env
  set name {}
  if {![info exists params(experiment)] || ([info exists params(experiment)] && [regexp {^\s*$} $params(experiment)])} {
    if {![info exists env(SNAPSHOT_EXPERIMENT)]} {
      set name {}
    } else {
      set name $env(SNAPSHOT_EXPERIMENT)
    }
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
  global env
  set name {}
  if {![info exists params(version)] || ([info exists params(version)] && [regexp {^\s*$} $params(version)])} {
    if {![info exists env(SNAPSHOT_VERSION)]} {
      set name {}
    } else {
      set name $env(SNAPSHOT_VERSION)
    }
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
  global env
  set name {}
  if {![info exists params(step)] || ([info exists params(step)] && [regexp {^\s*$} $params(step)])} {
    if {![info exists env(SNAPSHOT_STEP)]} {
      set step [::tb::snapshot::getVivadoRunStep]
      switch $step {
        synth_design -
        opt_design -
        power_opt_design -
        place_design -
        post_place_power_opt_design -
        phys_opt_design -
        route_design -
        post_route_phys_opt_design -
        write_bitstream {
          set name $step
        }
        default {
          set name {}
        }
      }
    } else {
      set name $env(SNAPSHOT_STEP)
    }
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
  global env
  set name {}
  if {![info exists params(run)] || ([info exists params(run)] && [regexp {^\s*$} $params(run)])} {
    if {![info exists env(SNAPSHOT_RUN)]} {
      set name {}
    } else {
      set name $env(SNAPSHOT_RUN)
    }
  } else {
    set name $params(run)
  }
#   if {$name == {}} {
#     set name [get_property -quiet NAME [current_run -quiet]]
#   }
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
  global env
  set name {}
  if {![info exists params(description)] || ([info exists params(description)] && [regexp {^\s*$} $params(description)])} {
    if {![info exists env(SNAPSHOT_DESCRIPTION)]} {
      set name {}
    } else {
      set name $env(SNAPSHOT_DESCRIPTION)
    }
  } else {
    set name $params(description)
  }
  return $name
}

#------------------------------------------------------------------------
# ::tb::snapshot::getVivadoRunStep
#------------------------------------------------------------------------
# **HIDDEN**
#------------------------------------------------------------------------
# Return the run step name of the running Vivado job
#------------------------------------------------------------------------
proc ::tb::snapshot::getVivadoRunStep {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable params
  foreach step [list opt_design \
                     power_opt_design \
                     place_design \
                     post_place_power_opt_design \
                     phys_opt_design \
                     route_design \
                     post_route_phys_opt_design \
                     write_bitstream ] {
    if {[file exists .${step}.begin.rst] && ![file exists .${step}.end.rst]} {
      return $step
    }
  }
  if {[file exists .vivado.begin.rst] && ![file exists .vivado.end.rst]} {
    return {synth_design}
  }
  catch {
    # Only when run inside Vivado
    if {[get_param synth.vivado.isSynthRun] == 1} {
      return {synth_design}
    }
  }
  return {}
}

#------------------------------------------------------------------------
# ::tb::snapshot::method:getLastID
#------------------------------------------------------------------------
# **HIDDEN**
#------------------------------------------------------------------------
# Return the id of the last inserted snapshot
#------------------------------------------------------------------------
proc ::tb::snapshot::getLastID {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable params
  global env
  set id {}
  if {![info exists params(lastid)] || ([info exists params(lastid)] && [regexp {^\s*$} $params(lastid)])} {
    if {![info exists env(SNAPSHOT_LASTID)]} {
      set id {}
    } else {
      set id $env(SNAPSHOT_LASTID)
    }
  } else {
    set id $params(lastid)
  }
  return $id
}

#------------------------------------------------------------------------
# ::tb::snapshot::method:lastid
#------------------------------------------------------------------------
# Usage: snapshot lastid
#------------------------------------------------------------------------
# Get the database id of the last inserted snapshot
#------------------------------------------------------------------------
proc ::tb::snapshot::method:lastid {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Get id of last snapshot
  return [::tb::snapshot::getLastID]
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
# ::tb::snapshot::method:exists
#------------------------------------------------------------------------
# Usage: snapshot exists <metric>
#------------------------------------------------------------------------
# Return 1 if metric <metric> has already been defined. 0 Otherwise
#------------------------------------------------------------------------
proc ::tb::snapshot::method:exists {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Check if metric defined
  variable metrics
  if {[llength $args] != 1} {
    error "wrong number of parameters: snapshot exist <metric>"
  }
  if {![info exists metrics([lindex $args 0])]} {
    return 0
  }
  return 1
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
  return [subst -nocommands -novariables $metrics([lindex $args 0])]
}

#------------------------------------------------------------------------
# ::tb::snapshot::method:set
#------------------------------------------------------------------------
# Usage: snapshot set <param> <value> [<options>]
#------------------------------------------------------------------------
# Set a parameter inside the 'metrics' associative array
#------------------------------------------------------------------------
proc ::tb::snapshot::method:set {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Set a metric value (-help)
  variable metrics
  variable metricTypes
  variable metricRefs
  variable verbose

  set type {blob}
  set error 0
  set help 0
  set override 1
  set parameters [list]
#   if {[llength $args] == 0} {
#     set help 1
#   }
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -type {
        set type [string tolower [lshift args]]
      }
      -ref {
        set ref [lshift args]
      }
      -blob {
        set type {blob}
      }
      -file {
        set type {file}
      }
      -param {
        set type {param}
      }
      -once -
      -nooverride {
        set override 0
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
#               print error "option '$name' is not a valid option."
#               incr error
              lappend parameters $name
              lappend parameters [lshift args]
            }
      }
    }
  }

  if {$help} {
    print stdout [format {
  Usage: snapshot set
              <name> <value>
              [-blob][-file]-param]
              [-type <blob|param|file>]
              [-ref <string>]
              [-once]
              [-help|-h]

  Description: Set a metric value
  
    -once: does not override the metric value if already set

  Example:
     snapshot set numnets 1000
     snapshot set tim_sum [report_timing_summary -return_string] -blob
} ]
    # HELP -->
    return -code ok
  }
  
  switch $type {
    file -
    param -
    blob {
    }
    default {
      print error "'$type' is an invalid type. The valid types are: blob"
      incr error
    }
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  switch [llength $parameters] {
    0 -
    1 {
      error "wrong number of parameters: snapshot set <metric> <value>"
    }
    2 {
      if {!$override && [info exists metrics([lindex $parameters 0])]} {
        if {$verbose} { 
          puts " -W- metric '[lindex $parameters 0]' already defined. Metric value not overriden (-once)"
        }
        return 1
      }
      set metrics([lindex $parameters 0]) [lindex $parameters 1]
      set metricTypes([lindex $parameters 0]) $type
      if {[info exists ref]} {
        set metricRefs([lindex $parameters 0]) $ref
      }
    }
    default {
      if {!$override && [info exists metrics([lindex $parameters 0])]} {
        if {$verbose} { 
          puts " -W- metric '[lindex $parameters 0]' already defined. Metric value not overriden (-once)"
        }
        return 1
      }
      set metrics([lindex $parameters 0]) [lrange $parameters 1 end]
      set metricTypes([lindex $parameters 0]) $type
      if {[info exists ref]} {
        set metricRefs([lindex $parameters 0]) $ref
      }
    }
  }

  return 0
}

#------------------------------------------------------------------------
# ::tb::snapshot::method:addfile
#------------------------------------------------------------------------
# Usage: snapshot addfile <metric> <filename>
#------------------------------------------------------------------------
# Save the file content inside the 'metrics' associative array. Binary
# files are supported.
#------------------------------------------------------------------------
proc ::tb::snapshot::method:addfile {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Save the content of a file as a metric (-help)
  variable metrics
  variable metricTypes
  variable metricRefs
  variable debug
  variable verbose

  set error 0
  set help 0
  set parameters [list]
#   if {[llength $args] == 0} {
#     set help 1
#   }
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -h -
      -help {
           set help 1
      }
      default {
            if {[string match "-*" $name]} {
              print error "option '$name' is not a valid option."
              incr error
            } else {
#               print error "option '$name' is not a valid option."
#               incr error
              lappend parameters $name
            }
      }
    }
  }

  if {$help} {
    print stdout [format {
  Usage: snapshot addfile
              <metric> <filename>
              [-help|-h]

  Description: Set a metric value as the content of a file

  Example:
     snapshot addfile mymetric ./report.rpt
     snapshot addfile doc ./documentation.pdf
} ]
    # HELP -->
    return -code ok
  }
  
  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  switch [llength $parameters] {
    0 -
    1 {
      error "wrong number of parameters: snapshot addfile <metric> <filename>"
    }
    2 {
      set filename [file normalize [lindex $parameters 1]]
      if {![file exists $filename]} {
        error " -E- file $filename does not exist"
      }
      set FH [open $filename {r}]
      # Support for binary files
      fconfigure $FH -encoding binary -translation binary
      set content [read $FH]
      close $FH
      # To test whether a file is "binary", in the sense that it contains NUL bytes
      set isBinary [expr {[string first \x00 $content]>=0}]
      if {$verbose} {
        print info "Reading file $filename ([string length $content] characters)"
      }
      set metrics([lindex $parameters 0]) $content
      set metricTypes([lindex $parameters 0]) {file}
      set metricRefs([lindex $parameters 0]) $filename
    }
    default {
      error "wrong number of parameters: snapshot addfile <metric> <filename>"
    }
  }

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

  # Save a Vivado parameter as a metric (-help)
  variable metrics
  variable metricTypes
  variable metricRefs
  variable debug
  variable verbose

  set error 0
  set help 0
  set parameters [list]
#   if {[llength $args] == 0} {
#     set help 1
#   }
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -h -
      -help {
           set help 1
      }
      default {
            if {[string match "-*" $name]} {
              print error "option '$name' is not a valid option."
              incr error
            } else {
#               print error "option '$name' is not a valid option."
#               incr error
              lappend parameters $name
            }
      }
    }
  }

  if {$help} {
    print stdout [format {
  Usage: snapshot addparam
              [<metric>] <parameter>
              [-help|-h]

  Description: Set a metric value as a Vivado parameter

  Example:
     snapshot addparam displayLimit tcl.collectionResultDisplayLimit
     snapshot addparam tcl.collectionResultDisplayLimit
} ]
    # HELP -->
    return -code ok
  }
  
  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

 switch [llength $parameters] {
   1 {
     set parameter [lindex $parameters 0]
     set metric $parameter
   }
   2 {
     set metric [lindex $parameters 0]
     set parameter [lindex $parameters 1]
   }
   default {
     error "wrong number of parameters: snapshot addparam \[<metric>\] <parameter>"
   }
 }
 if {[catch {set value [get_param $parameter]} errorstring]} {
   error $errorstring
 }
 set metrics($metric) $value
 set metricTypes($metric) {param}
 set metricRefs($metric) $parameter
 if {$verbose} {
   print info "Metric $metric / Parameter $parameter = $value / Type = $metricTypes($metric) / Ref = $metricRefs($metric)"
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

  # Reset the snapshot (-help)
  variable params
  variable metrics
  variable metricTypes
  variable metricRefs
#   variable summary
#   variable verbose 0
#   variable debug 0
  variable snapshotlog [list]
  global env

  set force 0
  set error 0
  set help 0
  set resetMetrics 1
  set resetParams 0
  set resetLastid 0
#   if {[llength $args] == 0} {
#     set help 1
#   }
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -a -
      -all {
           set resetParams 1
      }
      -f -
      -force {
           set resetParams 1
           set resetLastid 1
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
  Usage: snapshot reset
              [-all|-a]
              [-force|-f]
              [-help|-h]

  Description: Reset the snapshot metrics and/or parameters

  Example:
     snapshot reset
     snapshot reset -force
} ]
    # HELP -->
    return -code ok
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  if {$resetMetrics} {
    catch {unset metrics}
    catch {unset metricTypes}
    catch {unset metricRefs}
    array set metrics [list]
    array set metricTypes [list]
    array set metricRefs [list]
  }
  if {$resetParams} {
    if {$resetLastid} {
      # The parameter 'lastid' is reset
      catch {unset params}
      array set params [list db {} project {} run {} version {} experiment {} step {} release {} description {} time 0 timeout 600 lastid {} ]
      catch {unset env(SNAPSHOT_LASTID) }
    } else {
      # The parameter 'lastid' is not reset
      array set params [list db {} project {} run {} version {} experiment {} step {} release {} description {} time 0 timeout 600]
    }
  }
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

  # Print a summary of all snapshots inside the database (-help)
  return [uplevel [concat ::tb::snapshot::dbreport $args]]
}

#------------------------------------------------------------------------
# ::tb::snapshot::method:db2array
#------------------------------------------------------------------------
# Load metrics from SQL database to array
#------------------------------------------------------------------------
proc ::tb::snapshot::method:db2array {&var snapshotid} {
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
  set dbVersion [execSQL SQL { SELECT value FROM param WHERE property='version' LIMIT 1; } ]
  if {$verbose} { print info "Database version: $dbVersion" }

  set CMD "SELECT id, project, run, version, experiment, step, release, description, date, time
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
    set release $values(release)
    set description $values(description)
    set date $values(date)
    set time $values(time)
    foreach el {id project run version experiment step date time} { set var($el) $values($el) }
    if {$verbose} {
      print info "Processing snapshot ID=$id : project:$project version:$version experiment:$experiment step:$step release:$release run:$run date:$date time:$time"
    }
  }
  # When a duplicate metric name is found for a snapshot, keep the last one only. This is to support
  # the incremental flow when snapshot metric can be re-taken for a snapshot
  set CMD "SELECT snapshotid, name, value, type, ref
          FROM metric
          WHERE snapshotid IN ('[join $snapshotid ',']')
          AND (enabled == 1)
          AND id IN ( SELECT MAX(id)
                      FROM metric
                      WHERE (enabled == 1)
                      GROUP BY snapshotid, name
                    )
          ;
         "
#   set CMD "SELECT snapshotid, name, value, type, ref
#           FROM metric
#           WHERE snapshotid IN ('[join $snapshotid ',']') AND (enabled == 1)
#           ;
#          "
  execSQL SQL { pragma integrity_check }
  SQL eval $CMD values {
#     parray values
    set id $values(snapshotid)
    set metric $values(name)
    set value $values(value)
    set type $values(type)
    set ref $values(ref)
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
              [-release|-rel <string>]
              [-version|-ver <string>]
              [-experiment|-e <string>]
              [-step|-s <string>]
              [-run|-r <string>]
              [-verbose|-quiet]
              [-help|-h]

  Description: Generate a summary report of a database

  Example:
     snapshot dbreport
     snapshot dbreport -db ./metrics.db
     snapshot dbreport -experiment {No%%Buffer%%}
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
  set dbVersion [execSQL SQL { SELECT value FROM param WHERE property='version' LIMIT 1; } ]
  if {$verbose} {
    print info "Database version: $dbVersion"
    print info "DB report started on [clock format [clock seconds]]"
  }

  if {$allsnapshotids == {}} {
    set allsnapshotids [lsort [execSQL SQL "SELECT id FROM snapshot WHERE (enabled == 1)" ]]
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
    1.5 {
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
    # When a duplicate metric name is found for a snapshot, keep the last one only. This is to support
    # the incremental flow when snapshot metric can be re-taken for a snapshot
    set nummetrics [execSQL SQL "SELECT count(*) FROM ( SELECT DISTINCT name FROM metric WHERE (snapshotid = $id) AND (enabled == 1) )"]
#     set nummetrics [SQL eval "SELECT count(name) FROM metric WHERE snapshotid = $id AND (enabled == 1)"]
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



#################################################################################
#################################################################################
#################################################################################

# For debug:
# proc reload {} { catch {namespace delete ::tb::snapshot}; source -notrace ~/git/scripts/wip/snapshot/snapshot.tcl; puts " snapshot.tcl reloaded" }
catch { namespace import ::tb::snapshot }
catch { namespace import ::tb::take_snapshot }

if {[file tail [info script]]==[file tail $argv0]} {
  # This file is executed from tclsh
  if {$argv != {}} {
    # The script can be executed to run any of the sub-methods
    if {[catch {set res [eval [concat ::tb::snapshot $argv]]} errorstring]} {
      puts $errorstring
    }
    catch { puts $res }
  } else {
    ::tb::snapshot -help
  }
} else {
  # This file is sourced
  # The step name can be coded inside the filename: snapshot.<step>.tcl
  if {[regexp {^snapshot\.(.+)\.tcl$} [file tail [info script]] - ___step___]} {
    ::tb::snapshot::method:configure -step $___step___
  }
  catch {unset ___step___}
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


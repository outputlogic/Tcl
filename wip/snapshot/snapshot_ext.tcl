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
## Version:        2014.12.05
## Tool Version:   Vivado 2014.1
## Description:    Plugin for snapshot_core.tcl . Adds user friendly commands to
##                 query the snapshot database
##
########################################################################################

########################################################################################
## 2014.12.05 - Added -quiet to 'get_metric_values'
## 2014.11.26 - Fixed minor issue in 'get_snapshot_ids'
## 2014.10.30 - Added 'get_releases' 
##            - Added 'open_sqlite_db'
## 2014.10.24 - Added -memory to open_snapshot_db to open a shadow copy of database 
##              in memory
##            - Added 'create_snapshot_db' to create empty snapshot database
##            - Added 'create_sqlite_db' to create empty sqlite3 database
## 2014.10.07 - Added 'query' to send SQL query to database
## 2014.10.04 - Changed the way to remove duplicates by preserving original order
##              of elements in the list
## 2014.09.25 - Added 'get_parent_ids'
##            - Updated 'get_snapshot_ids'
##            - Minor updates of example scripts
## 2014.06.03 - Initial release
########################################################################################

########################################################################################
## Example script:
##   source snapshot.tcl
##   source snapshot_ext.tcl
##   tb::open_snapshot_db -db metrics.db
##   tb::get_projects
##   set l [tb::get_snapshot_ids -project project1]
##   tb::get_experiments
##   tb::get_experiments  [tb::get_snapshot_ids -project project1]
##   tb::get_experiments -glob {%lm100%}
##   tb::close_snapshot_db
########################################################################################

########################################################################################
## Example script:
##   source ~/git/scripts/wip/snapshot/snapshot_core.tcl
##   source ~/git/scripts/wip/snapshot/snapshot_ext.tcl
##   
##   set SQL [tb::open_snapshot_db -db metrics.db -rw]
##   
##   foreach id [tb::get_metric_ids] {
##     set value [tb::get_metric_value -id $id]
##     ::tb::snapshot::execSQL $SQL " UPDATE metric SET type='blob', size=[string length $value], eol=[llength [split $value \n]] WHERE id=$id ; "
##     # To test whether a file is "binary", in the sense that it contains NUL bytes
##     set isBinary [expr {[string first \x00 $value]>=0}]
##     if {$isBinary} {
##       ::tb::snapshot::execSQL $SQL " UPDATE metric SET binary=1 WHERE id=$metricid ; "
##     }
##   }
##   
##   tb::close_snapshot_db
########################################################################################
##  Upgrade database from 1.4 to 1.5:
##   UPDATE param SET value=1.5 WHERE property='version';
##   ALTER TABLE metric ADD COLUMN enabled BOOLEAN DEFAULT ( 1 )  ;
##   ALTER TABLE metric ADD COLUMN size INTEGER DEFAULT NULL   ;
##   ALTER TABLE metric ADD COLUMN eol INTEGER DEFAULT NULL   ;
##   ALTER TABLE metric ADD COLUMN binary BOOLEAN DEFAULT ( 0 )   ;
##   ALTER TABLE metric ADD COLUMN type TEXT DEFAULT NULL   ;
##   ALTER TABLE metric ADD COLUMN ref TEXT DEFAULT NULL   ;
########################################################################################

if {[info exists DEBUG]} { puts " Sourcing [file normalize [info script]]" }

# Proc to reload current script
proc [file tail [info script]] {} " source [info script]; puts \" [info script] reloaded\" "

namespace eval ::tb {
#     namespace export open_sqlite_db open_snapshot_db close_snapshot_db create_snapshot_db create_sqlite_db
#     namespace export get_snapshot_ids
#     namespace export get_projects
#     namespace export get_experiments
#     namespace export get_versions
#     namespace export get_runs
#     namespace export get_steps
#     namespace export get_releases
#     namespace export get_parent_ids
#     namespace export get_descriptions
#     namespace export get_metric_names
#     namespace export get_metric_ids
#     namespace export get_metric_values
}

proc ::tb::open_sqlite_db { args } {
  # Summary : Open SQLite database

  # Argument Usage:
  # -db : path to sqlite database
  # -verbose : verbose mode

  # Return Value:
  # returns the SQL command created to query the database

#   if {[catch {set res [uplevel [concat ::tb::snapshot::snapshot $args]]} errorstring]} {
#     error " -E- the snapshot failed with the following error: $errorstring"
#   }
  return [uplevel [concat ::tb::snapshot::open_sqlite_db $args]]
}

proc ::tb::open_snapshot_db { args } {
  # Summary : Open snapshot database

  # Argument Usage:
  # -db : path to snapshot database
  # -verbose : verbose mode

  # Return Value:
  # returns the SQL command created to query the database

#   if {[catch {set res [uplevel [concat ::tb::snapshot::snapshot $args]]} errorstring]} {
#     error " -E- the snapshot failed with the following error: $errorstring"
#   }
  return [uplevel [concat ::tb::snapshot::open_snapshot_db $args]]
}

proc ::tb::close_snapshot_db { args } {
  # Summary : Close snapshot database

  # Argument Usage:

  # Return Value:
  # returns the status or an error code

#   if {[catch {set res [uplevel [concat ::tb::snapshot::snapshot $args]]} errorstring]} {
#     error " -E- the snapshot failed with the following error: $errorstring"
#   }
  return [uplevel [concat ::tb::snapshot::close_snapshot_db $args]]
}

proc ::tb::create_snapshot_db { args } {
  # Summary : Create snapshot database

  # Argument Usage:

  # Return Value:
  # returns the status or an error code

#   if {[catch {set res [uplevel [concat ::tb::snapshot::snapshot $args]]} errorstring]} {
#     error " -E- the snapshot failed with the following error: $errorstring"
#   }
  return [uplevel [concat ::tb::snapshot::create_snapshot_db $args]]
}

proc ::tb::create_sqlite_db { args } {
  # Summary : Create empty sqlite3 database

  # Argument Usage:

  # Return Value:
  # returns the status or an error code

#   if {[catch {set res [uplevel [concat ::tb::snapshot::snapshot $args]]} errorstring]} {
#     error " -E- the snapshot failed with the following error: $errorstring"
#   }
  return [uplevel [concat ::tb::snapshot::create_sqlite_db $args]]
}

proc ::tb::get_snapshot_ids { args } {
  # Summary : Get the list of snapshot id(s) matching various criterias

  # Argument Usage:
  # args : sub-command. The supported sub-commands are: start | stop | summary | add | remove | reset | status

  # Return Value:
  # returns the list of snapshot id(s)

#   if {[catch {set res [uplevel [concat ::tb::snapshot::snapshot $args]]} errorstring]} {
#     error " -E- the snapshot failed with the following error: $errorstring"
#   }
  return [uplevel [concat ::tb::snapshot::get_snapshot_ids $args]]
}

proc ::tb::get_projects { args } {
  # Summary : Get the list of projects

  # Argument Usage:
  # -ids : List of snapshot id(s)
  # -glob : SQL pattern to filter the list of projects

  # Return Value:
  # returns the list of projects

#   if {[catch {set res [uplevel [concat ::tb::snapshot::snapshot $args]]} errorstring]} {
#     error " -E- the snapshot failed with the following error: $errorstring"
#   }
  return [uplevel [concat ::tb::snapshot::get_projects $args]]
}

proc ::tb::get_experiments { args } {
  # Summary : Get the list of experiments

  # Argument Usage:
  # -ids : List of snapshot id(s)
  # -glob : SQL pattern to filter the list of experiments

  # Return Value:
  # returns the list of experiments

#   if {[catch {set res [uplevel [concat ::tb::snapshot::snapshot $args]]} errorstring]} {
#     error " -E- the snapshot failed with the following error: $errorstring"
#   }
  return [uplevel [concat ::tb::snapshot::get_experiments $args]]
}

proc ::tb::get_versions { args } {
  # Summary : Get the list of versions

  # Argument Usage:
  # -ids : List of snapshot id(s)
  # -glob : SQL pattern to filter the list of versions

  # Return Value:
  # returns the list of versions

#   if {[catch {set res [uplevel [concat ::tb::snapshot::snapshot $args]]} errorstring]} {
#     error " -E- the snapshot failed with the following error: $errorstring"
#   }
  return [uplevel [concat ::tb::snapshot::get_versions $args]]
}

proc ::tb::get_releases { args } {
  # Summary : Get the list of releases

  # Argument Usage:
  # -ids : List of snapshot id(s)
  # -glob : SQL pattern to filter the list of releases

  # Return Value:
  # returns the list of releases

#   if {[catch {set res [uplevel [concat ::tb::snapshot::snapshot $args]]} errorstring]} {
#     error " -E- the snapshot failed with the following error: $errorstring"
#   }
  return [uplevel [concat ::tb::snapshot::get_releases $args]]
}

proc ::tb::get_runs { args } {
  # Summary : Get the list of runs

  # Argument Usage:
  # -ids : List of snapshot id(s)
  # -glob : SQL pattern to filter the list of runs

  # Return Value:
  # returns the list of runs

#   if {[catch {set res [uplevel [concat ::tb::snapshot::snapshot $args]]} errorstring]} {
#     error " -E- the snapshot failed with the following error: $errorstring"
#   }
  return [uplevel [concat ::tb::snapshot::get_runs $args]]
}

proc ::tb::get_steps { args } {
  # Summary : Get the list of steps

  # Argument Usage:
  # -ids : List of snapshot id(s)
  # -glob : SQL pattern to filter the list of steps

  # Return Value:
  # returns the list of steps

#   if {[catch {set res [uplevel [concat ::tb::snapshot::snapshot $args]]} errorstring]} {
#     error " -E- the snapshot failed with the following error: $errorstring"
#   }
  return [uplevel [concat ::tb::snapshot::get_steps $args]]
}

proc ::tb::get_parent_ids { args } {
  # Summary : Get the list of parent ids

  # Argument Usage:
  # -ids : List of snapshot id(s)

  # Return Value:
  # returns the list of parent ids

#   if {[catch {set res [uplevel [concat ::tb::snapshot::snapshot $args]]} errorstring]} {
#     error " -E- the snapshot failed with the following error: $errorstring"
#   }
  return [uplevel [concat ::tb::snapshot::get_parent_ids $args]]
}

proc ::tb::get_descriptions { args } {
  # Summary : Get the list of descriptions

  # Argument Usage:
  # -ids : List of snapshot id(s)
  # -glob : SQL pattern to filter the list of descriptions

  # Return Value:
  # returns the list of descriptions

#   if {[catch {set res [uplevel [concat ::tb::snapshot::snapshot $args]]} errorstring]} {
#     error " -E- the snapshot failed with the following error: $errorstring"
#   }
  return [uplevel [concat ::tb::snapshot::get_descriptions $args]]
}

proc ::tb::get_metric_names { args } {
  # Summary : Get the list of metric names

  # Argument Usage:
  # -ids : List of snapshot id(s)
  # -glob : SQL pattern to filter the list of metric names

  # Return Value:
  # returns the list of metric names

#   if {[catch {set res [uplevel [concat ::tb::snapshot::snapshot $args]]} errorstring]} {
#     error " -E- the snapshot failed with the following error: $errorstring"
#   }
  return [uplevel [concat ::tb::snapshot::get_metric_names $args]]
}

proc ::tb::get_metric_ids { args } {
  # Summary : Get the list of metric ids

  # Argument Usage:
  # -ids : List of snapshot id(s)
  # -glob : SQL pattern to filter the list of metric names

  # Return Value:
  # returns the list of metric ids

#   if {[catch {set res [uplevel [concat ::tb::snapshot::snapshot $args]]} errorstring]} {
#     error " -E- the snapshot failed with the following error: $errorstring"
#   }
  return [uplevel [concat ::tb::snapshot::get_metric_ids $args]]
}

proc ::tb::get_metric_values { args } {
  # Summary : Get a list of metric values

  # Argument Usage:
  # -id : metric id

  # Return Value:
  # returns a list of metric values

#   if {[catch {set res [uplevel [concat ::tb::snapshot::snapshot $args]]} errorstring]} {
#     error " -E- the snapshot failed with the following error: $errorstring"
#   }
  return [uplevel [concat ::tb::snapshot::get_metric_values $args]]
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
  variable SQL {}
} ]

#------------------------------------------------------------------------
# ::tb::snapshot::create_sqlite_db
#------------------------------------------------------------------------
# Usage: create_sqlite_db [<options>]
#------------------------------------------------------------------------
# Create empty sqlite database
#------------------------------------------------------------------------
proc ::tb::snapshot::create_sqlite_db {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable SQL
  set db {}
  set inmemory 0
  set force 0
  set verbose 0
  set error 0
  set help 0
  if {[llength $args] == 0} {
    set help 1
  }
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-db$} {
           set db [lshift args]
      }
      {^-memory$} -
      {^-m(e(m(o(ry?)?)?)?)$} {
           set inmemory 1
      }
      {^-force$} -
      {^-f(o(r(ce?)?)?)$} {
           set force 1
      }
      {^-verbose$} -
      {^-v(e(r(b(o(se?)?)?)?)?)?$} {
        set verbose 1
      }
      {^-h$} -
      {^-help$} -
      {^-h(e(lp?)?)?$} {
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
  Usage: create_sqlite_db
              [-db <filename>]
              [-memory]
              [-force]
              [-verbose]
              [-help|-h]

  Description: Create an empty sqlite3 database

    Use -memory to create an in-memory database.
    
    Use -force to override an existing on-disk database.

  Example:
     create_sqlite_db -db metrics.db -force
     create_sqlite_db -memory
} ]
    # HELP -->
    return -code ok
  }

  if {$SQL != {}} {
    print error "SQLite3 database already opened"
    incr error
  }

  if {$inmemory && ($db != {})} {
    print error "Options -db and -memory are mutually exclusives"
    incr error
  } else {
    if {($db != {}) && [file exists $db]} {
      if {$force} {
        print warning "Database '$db' already exists and is overriden"
        catch {file delete -force $db}
      } else {
        print error "Database '$db' already exists"
        incr error
      }
    }
  }
  
  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  if {$verbose} {
    print info "<<<<<<<<<<<<<<<< create_sqlite_db <<<<<<<<<<<<<<<<"
    print info "Database: $db"
  }

  if {$inmemory} {
    sqlite3 SQL[pid] {:memory:}
    set SQL SQL[pid]
    execSQL $SQL { pragma integrity_check }
  } else {
    sqlite3 SQL[pid] $db -create true
    set SQL SQL[pid]
    execSQL $SQL { pragma integrity_check }
  }

  # Add the PARAGMAs
  execSQL $SQL [::tb::snapshot::SQLPragmas]
  if {$verbose} {
    print info ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  }

  return $SQL
#   return -code ok
}

#------------------------------------------------------------------------
# ::tb::snapshot::create_snapshot_db
#------------------------------------------------------------------------
# Usage: create_snapshot_db [<options>]
#------------------------------------------------------------------------
# Create empty snapshot database
#------------------------------------------------------------------------
proc ::tb::snapshot::create_snapshot_db {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable SQL
  set db {}
  set inmemory 0
  set force 0
  set verbose 0
  set error 0
  set help 0
  if {[llength $args] == 0} {
    set help 1
  }
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-db$} {
           set db [lshift args]
      }
      {^-memory$} -
      {^-m(e(m(o(ry?)?)?)?)$} {
           set inmemory 1
      }
      {^-force$} -
      {^-f(o(r(ce?)?)?)$} {
           set force 1
      }
      {^-verbose$} -
      {^-v(e(r(b(o(se?)?)?)?)?)?$} {
        set verbose 1
      }
      {^-h$} -
      {^-help$} -
      {^-h(e(lp?)?)?$} {
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
  Usage: create_snapshot_db
              [-db <filename>]
              [-memory]
              [-force]
              [-verbose]
              [-help|-h]

  Description: Create sqlite3 snapshot database

    Use -memory to create an in-memory database.
    
    Use -force to override an existing on-disk database.

  Example:
     create_snapshot_db -db metrics.db -force
     create_snapshot_db -memory
} ]
    # HELP -->
    return -code ok
  }

  if {$SQL != {}} {
    print error "SQLite3 database already opened"
    incr error
  }

  if {$inmemory && ($db != {})} {
    print error "Options -db and -memory are mutually exclusives"
    incr error
  } else {
    if {($db != {}) && [file exists $db]} {
      if {$force} {
        print warning "Database '$db' already exists and is overriden"
        catch {file delete -force $db}
      } else {
        print error "Database '$db' already exists"
        incr error
      }
    }
  }
  
  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  if {$verbose} {
    print info "<<<<<<<<<<<<<<<< create_snapshot_db <<<<<<<<<<<<<<<<"
    print info "Database: $db"
  }

  if {$inmemory} {
    sqlite3 SQL[pid] {:memory:}
    set SQL SQL[pid]
    execSQL $SQL { pragma integrity_check }
  } else {
    sqlite3 SQL[pid] $db -create true
    set SQL SQL[pid]
  }

  # Add the PARAGMAs
  execSQL $SQL [::tb::snapshot::SQLPragmas]
  # Add the TABLEs
  execSQL $SQL [::tb::snapshot::SQLTables]
  # Database version & other parameters
  execSQL $SQL [::tb::snapshot::SQLInit]

  execSQL $SQL { pragma integrity_check }
  set dbVersion [execSQL $SQL { SELECT value FROM param WHERE property='version' LIMIT 1; } ]
  if {$verbose} {
    print info "Database version: $dbVersion"
  }
  if {$verbose} {
    print info ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  }

  return $SQL
#   return -code ok
}

#------------------------------------------------------------------------
# ::tb::snapshot::open_snapshot_db
#------------------------------------------------------------------------
# Usage: open_snapshot_db [<options>]
#------------------------------------------------------------------------
# Open snapshot database
#------------------------------------------------------------------------
proc ::tb::snapshot::open_snapshot_db {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable SQL
  set db {}
  set readOnly {true}
  set inmemory 0
  set verbose 0
  set error 0
  set help 0
  if {[llength $args] == 0} {
    set help 1
  }
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-db$} {
           set db [lshift args]
      }
      {^-rw$} {
           set readOnly {false}
      }
      {^-memory$} -
      {^-m(e(m(o(ry?)?)?)?)$} {
           set inmemory 1
      }
      {^-verbose$} -
      {^-v(e(r(b(o(se?)?)?)?)?)?$} {
        set verbose 1
      }
      {^-h$} -
      {^-help$} -
      {^-h(e(lp?)?)?$} {
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
  Usage: open_snapshot_db
              [-db <filename>]
              [-rw]
              [-memory]
              [-verbose]
              [-help|-h]

  Description: Open snapshot database

    Use -memory to open a work copy of the database in memory. The original
    database is never affected.

  Example:
     open_snapshot_db -db metrics.db
     open_snapshot_db -db metrics.db -rw
     open_snapshot_db -db metrics.db -memory
} ]
    # HELP -->
    return -code ok
  }

  if {$SQL != {}} {
    print error "SQLite3 database already opened"
    incr error
  }

  if {![file exists $db]} {
    print error "Database '$db' does not exist"
    incr error
  }
  
  if {$inmemory && ($readOnly == {false})} {
    print error "Options -rw and -memory are mutually exclusives"
    incr error
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  if {$verbose} {
    print info "<<<<<<<<<<<<<<<< open_snapshot_db <<<<<<<<<<<<<<<<"
    print info "Database: $db"
  }

  if {$inmemory} {
    sqlite3 SQL[pid] {:memory:}
    set SQL SQL[pid]
    execSQL $SQL { pragma integrity_check }
    $SQL eval " ATTACH DATABASE '$db' AS DB "
    set tables [$SQL eval { SELECT name FROM DB.sqlite_master WHERE type='table' }]
    if {$verbose} { print info "Tables: [lsort $tables]" }
    foreach table $tables {
      if {$table == {sqlite_sequence}} { continue }
      if {$verbose} { print info "Loading table: $table" }
      $SQL eval " CREATE TABLE $table AS SELECT * FROM DB.$table "
    }
    $SQL eval { DETACH DATABASE DB }
  } else {
    sqlite3 SQL[pid] $db -readonly $readOnly
    set SQL SQL[pid]
  }

  execSQL $SQL { pragma integrity_check }
  set dbVersion [execSQL $SQL { SELECT value FROM param WHERE property='version' LIMIT 1; } ]
  if {$verbose} {
    print info "Database version: $dbVersion"
  }
  if {$verbose} {
    print info ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  }

  return $SQL
#   return -code ok
}

#------------------------------------------------------------------------
# ::tb::snapshot::open_sqlite_db
#------------------------------------------------------------------------
# Usage: open_sqlite_db [<options>]
#------------------------------------------------------------------------
# Open SQlite3 database
#------------------------------------------------------------------------
proc ::tb::snapshot::open_sqlite_db {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable SQL
  set db {}
  set readOnly {true}
  set inmemory 0
  set verbose 0
  set error 0
  set help 0
  if {[llength $args] == 0} {
    set help 1
  }
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-db$} {
           set db [lshift args]
      }
      {^-rw$} {
           set readOnly {false}
      }
      {^-memory$} -
      {^-m(e(m(o(ry?)?)?)?)$} {
           set inmemory 1
      }
      {^-verbose$} -
      {^-v(e(r(b(o(se?)?)?)?)?)?$} {
        set verbose 1
      }
      {^-h$} -
      {^-help$} -
      {^-h(e(lp?)?)?$} {
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
  Usage: open_sqlite_db
              [-db <filename>]
              [-rw]
              [-memory]
              [-verbose]
              [-help|-h]

  Description: Open sqlite3 database

    Use -memory to open a work copy of the database in memory. The original
    database is never affected.

  Example:
     open_sqlite_db -db metrics.db
     open_sqlite_db -db metrics.db -rw
     open_sqlite_db -db metrics.db -memory
} ]
    # HELP -->
    return -code ok
  }

  if {$SQL != {}} {
    print error "SQLite3 database already opened"
    incr error
  }

  if {![file exists $db]} {
    print error "Database '$db' does not exist"
    incr error
  }
  
  if {$inmemory && ($readOnly == {false})} {
    print error "Options -rw and -memory are mutually exclusives"
    incr error
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  if {$verbose} {
    print info "<<<<<<<<<<<<<<<< open_sqlite_db <<<<<<<<<<<<<<<<"
    print info "Database: $db"
  }

  if {$inmemory} {
    sqlite3 SQL[pid] {:memory:}
    set SQL SQL[pid]
    execSQL $SQL { pragma integrity_check }
    $SQL eval " ATTACH DATABASE '$db' AS DB "
    set tables [$SQL eval { SELECT name FROM DB.sqlite_master WHERE type='table' }]
    if {$verbose} { print info "Tables: [lsort $tables]" }
    foreach table $tables {
      if {$table == {sqlite_sequence}} { continue }
      if {$verbose} { print info "Loading table: $table" }
      $SQL eval " CREATE TABLE $table AS SELECT * FROM DB.$table "
    }
    $SQL eval { DETACH DATABASE DB }
  } else {
    sqlite3 SQL[pid] $db -readonly $readOnly
    set SQL SQL[pid]
  }

  execSQL $SQL { pragma integrity_check }
  if {$verbose} {
    print info "Tables found: $tables"
  }
  if {$verbose} {
    print info ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  }

  return $SQL
#   return -code ok
}

#------------------------------------------------------------------------
# ::tb::snapshot::close_snapshot_db
#------------------------------------------------------------------------
# Usage: close_snapshot_db [<options>]
#------------------------------------------------------------------------
# Close snapshot database
#------------------------------------------------------------------------
proc ::tb::snapshot::close_snapshot_db {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable SQL
  set verbose 0
  set error 0
  set help 0
#   if {[llength $args] == 0} {
#     set help 1
#   }
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-verbose$} -
      {^-v(e(r(b(o(se?)?)?)?)?)?$} {
        set verbose 1
      }
      {^-h$} -
      {^-help$} -
      {^-h(e(lp?)?)?$} {
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
  Usage: close_snapshot_db
              [-verbose]
              [-help|-h]

  Description: Close sqlite3 database

  Example:
     close_snapshot_db
} ]
    # HELP -->
    return -code ok
  }

  if {$SQL == {}} {
    print error "SQLite3 database not opened"
    incr error
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  if {$verbose} {
    print info "<<<<<<<<<<<<<<<< close_snapshot_db <<<<<<<<<<<<<<<<"
  }
  $SQL close
  set SQL {}
  if {$verbose} {
    print info ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  }

  return -code ok
}

#------------------------------------------------------------------------
# ::tb::snapshot::query
#------------------------------------------------------------------------
# Usage: query [<options>]
#------------------------------------------------------------------------
# Execute SQL query on metric database
#------------------------------------------------------------------------
proc ::tb::snapshot::query {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable SQL
  set SQLCmd {}
  set verbose 0
  set debug 0
  set error 0
  set help 0
#   if {[llength $args] == 0} {
#     set help 1
#   }
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-verbose$} -
      {^-v(e(r(b(o(se?)?)?)?)?)?$} {
        set verbose 1
      }
      {^-debug$} -
      {^-d(e(b(ug?)?)?)?$} {
        set debug 1
      }
      {^-h$} -
      {^-help$} -
      {^-h(e(lp?)?)?$} {
           set help 1
      }
      default {
            if {[string match "-*" $name]} {
              print error "option '$name' is not a valid option."
              incr error
            } else {
              set SQLCmd $name
#               print error "option '$name' is not a valid option."
#               incr error
            }
      }
    }
  }

  if {$help} {
    print stdout [format {
  Usage: query
              <SQL_Query>
              [-verbose]
              [-help|-h]

  Description: Return the result of the SQL query

  Example:
     query "SELECT value FROM param WHERE property='version' LIMIT 1;"
} ]
    # HELP -->
    return -code ok
  }

  if {$SQL == {}} {
    print error "SQLite3 database not opened"
    incr error
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  if {$verbose} {
    print info "<<<<<<<<<<<<<<< query <<<<<<<<<<<<<<<"
  }

  set result [execSQL $SQL $SQLCmd]

  if {$verbose} {
    print info ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  }

  return $result
}

#------------------------------------------------------------------------
# ::tb::snapshot::get_snapshot_ids
#------------------------------------------------------------------------
# Usage: get_snapshot_ids [<options>]
#------------------------------------------------------------------------
# Get the list of snapshot id(s) matching various criterias
#------------------------------------------------------------------------
proc ::tb::snapshot::get_snapshot_ids {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable SQL
  set allsnapshotids {}
  set metricids {}
  set parentids {}
  set project {%}
  set run {%}
  set version {%}
  set experiment {%}
  set step {%}
  set release {%}
  set verbose 0
  set debug 0
  set error 0
  set help 0
#   if {[llength $args] == 0} {
#     set help 1
#   }
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-project$} -
      {^-p$} -
      {^-pr(o(j(e(ct?)?)?)?)?$} {
        set project [lshift args]
      }
      {^-r$} -
      {^-run$} -
      {^-r(un?)?$} {
        set run [lshift args]
      }
      {^-ver$} -
      {^-version$} -
      {^-v(e(r(s(i(on?)?)?)?)?)?$} {
        set version [lshift args]
      }
      {^-e$} -
      {^-experiment$} -
      {^-e(x(p(e(r(i(m(e(nt?)?)?)?)?)?)?)?)?$} {
        set experiment [lshift args]
      }
      {^-s$} -
      {^-step$} -
      {^-s(t(ep?)?)?$} {
        set step [lshift args]
      }
      {^-rel$} -
      {^-release$} -
      {^-vivado$} -
      {^-r(e(l(e(a(se?)?)?)?)?)?$} {
           set release [lshift args]
      }
      {^-of_metric_id$} -
      {^-o(f(_(m(e(t(r(i(c(_(i(ds?)?)?)?)?)?)?)?)?)?)?)?$} {
           set metricids [lshift args]
      }
      {^-parentids$} -
      {^-pa(r(e(n(t(i(ds?)?)?)?)?)?)?$} {
           set parentids [lshift args]
      }
      {^-verbose$} -
      {^-v(e(r(b(o(se?)?)?)?)?)?$} {
        set verbose 1
      }
      {^-debug$} -
      {^-d(e(b(ug?)?)?)?$} {
        set debug 1
      }
      {^-h$} -
      {^-help$} -
      {^-h(e(lp?)?)?$} {
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
  Usage: get_snapshot_ids
              [-project <string>]
              [-release <string>]
              [-version <string>]
              [-experiment <string>]
              [-step <string>]
              [-run <string>]
              [-of_metric_ids <list_metric_ids>]
              [-parentids <list_snapshot_ids>]
              [-verbose]
              [-help|-h]

  Description: Get the list of snapshot id(s) matching various criterias

  Example:
     get_snapshot_ids
     get_snapshot_ids -experiment {No%%Buffer%%}
     get_snapshot_ids -of_metric_ids 12
} ]
    # HELP -->
    return -code ok
  }

  if {$SQL == {}} {
    print error "SQLite3 database not opened"
    incr error
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  if {$verbose} {
    print info "<<<<<<<<<<<<<<< get_snapshot_ids <<<<<<<<<<<<<<<"
  }
  if {$verbose} {
  }

  if {$metricids != {}} {
    # Return the list of snapshot id(s) related to a list of metric id(s)
    set CMD "SELECT snapshotid
        FROM metric
        WHERE id IN ('[join $metricids ',']')
              AND (enabled == 1)
        ;
       "
  } else {
    # Return the list of snapshot id(s) from various criterias
    set allsnapshotids [lsort [execSQL $SQL "SELECT id FROM snapshot WHERE (enabled == 1)" ]]
    if {$parentids == {}} {
      set parentids $allsnapshotids
    }
    set CMD "SELECT id
        FROM snapshot
        WHERE id IN ('[join $allsnapshotids ',']')
              AND ( (project LIKE '$project') OR (project IS NULL) )
              AND ( (run LIKE '$run') OR (run IS NULL) )
              AND version LIKE '$version'
              AND experiment LIKE '$experiment'
              AND step LIKE '$step'
              AND ( (release LIKE '$release') OR (release IS NULL) )
       "
    if {$parentids != {}} {
      append CMD "              AND ( (parentid IN ('[join $parentids ',']')) OR (parentid IS NULL) )"
    }
    append CMD "\n;"
  }

#   set ids [$SQL eval $CMD]
  set ids [lsort -unique -integer [execSQL $SQL $CMD]]

  if {$verbose} {
    print info ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  }

  return $ids
}

#------------------------------------------------------------------------
# ::tb::snapshot::get_projects
#------------------------------------------------------------------------
# Usage: get_projects [<options>]
#------------------------------------------------------------------------
# Get the list of projects
#------------------------------------------------------------------------
proc ::tb::snapshot::get_projects {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable SQL
  set snapshotids {}
  set glob {%}
  set verbose 0
  set debug 0
  set error 0
  set help 0
#   if {[llength $args] == 0} {
#     set help 1
#   }
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-id$} -
      {^-ids$} -
      {^-i(ds?)?$} {
        set snapshotids [lshift args]
      }
      {^-glob$} -
      {^-g(l(ob?)?)?$} {
        set glob [lshift args]
      }
      {^-verbose$} -
      {^-v(e(r(b(o(se?)?)?)?)?)?$} {
        set verbose 1
      }
      {^-debug$} -
      {^-d(e(b(ug?)?)?)?$} {
        set debug 1
      }
      {^-h$} -
      {^-help$} -
      {^-h(e(lp?)?)?$} {
           set help 1
      }
      default {
            if {[string match "-*" $name]} {
              print error "option '$name' is not a valid option."
              incr error
            } else {
              set snapshotids $name
#               print error "option '$name' is not a valid option."
#               incr error
            }
      }
    }
  }

  if {$help} {
    print stdout [format {
  Usage: get_projects
              [-ids <list_snapshot_ids>]
              [-glob <exp>]
              [-verbose]
              [-help|-h]

  Description: Return the list of projects

  Example:
     get_projects
     get_projects -glob {%%high%%}
     get_projects [get_snapshot_ids -version {%%BUF%%}]
} ]
    # HELP -->
    return -code ok
  }

  if {$SQL == {}} {
    print error "SQLite3 database not opened"
    incr error
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  if {$snapshotids == {}} {
    set snapshotids [lsort [execSQL $SQL "SELECT id FROM snapshot WHERE (enabled == 1)" ]]
  }

  if {$verbose} {
    print info "<<<<<<<<<<<<<<< get_projects <<<<<<<<<<<<<<<"
  }

  set CMD "SELECT project
      FROM snapshot
      WHERE id IN ('[join $snapshotids ',']')
            AND project LIKE '$glob'
      ;
     "

#   set projects [lsort -unique [execSQL $SQL $CMD]]
  set projects [::tb::snapshot::luniq [execSQL $SQL $CMD]]

  if {$verbose} {
    print info ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  }

  return $projects
}


#------------------------------------------------------------------------
# ::tb::snapshot::get_experiments
#------------------------------------------------------------------------
# Usage: get_experiments [<options>]
#------------------------------------------------------------------------
# Get the list of experiments
#------------------------------------------------------------------------
proc ::tb::snapshot::get_experiments {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable SQL
  set snapshotids {}
  set glob {%}
  set verbose 0
  set debug 0
  set error 0
  set help 0
#   if {[llength $args] == 0} {
#     set help 1
#   }
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-id$} -
      {^-ids$} -
      {^-i(ds?)?$} {
        set snapshotids [lshift args]
      }
      {^-glob$} -
      {^-g(l(ob?)?)?$} {
        set glob [lshift args]
      }
      {^-verbose$} -
      {^-v(e(r(b(o(se?)?)?)?)?)?$} {
        set verbose 1
      }
      {^-debug$} -
      {^-d(e(b(ug?)?)?)?$} {
        set debug 1
      }
      {^-h$} -
      {^-help$} -
      {^-h(e(lp?)?)?$} {
           set help 1
      }
      default {
            if {[string match "-*" $name]} {
              print error "option '$name' is not a valid option."
              incr error
            } else {
              set snapshotids $name
#               print error "option '$name' is not a valid option."
#               incr error
            }
      }
    }
  }

  if {$help} {
    print stdout [format {
  Usage: get_experiments
              [-ids <list_snapshot_ids>]
              [-glob <exp>]
              [-verbose]
              [-help|-h]

  Description: Return the list of experiments

  Example:
     get_experiments
     get_experiments -glob {%%high%%}
     get_experiments [get_snapshot_ids -version {%%BUF%%}]
} ]
    # HELP -->
    return -code ok
  }

  if {$SQL == {}} {
    print error "SQLite3 database not opened"
    incr error
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  if {$snapshotids == {}} {
    set snapshotids [lsort [execSQL $SQL "SELECT id FROM snapshot WHERE (enabled == 1)" ]]
  }

  if {$verbose} {
    print info "<<<<<<<<<<<<<<< get_experiments <<<<<<<<<<<<<<<"
  }

  set CMD "SELECT experiment
      FROM snapshot
      WHERE id IN ('[join $snapshotids ',']')
            AND experiment LIKE '$glob'
      ;
     "

#   set experiments [lsort -unique [execSQL $SQL $CMD]]
  set experiments [::tb::snapshot::luniq [execSQL $SQL $CMD]]

  if {$verbose} {
    print info ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  }

  return $experiments
}

#------------------------------------------------------------------------
# ::tb::snapshot::get_versions
#------------------------------------------------------------------------
# Usage: get_versions [<options>]
#------------------------------------------------------------------------
# Get the list of versions
#------------------------------------------------------------------------
proc ::tb::snapshot::get_versions {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable SQL
  set snapshotids {}
  set glob {%}
  set verbose 0
  set debug 0
  set error 0
  set help 0
#   if {[llength $args] == 0} {
#     set help 1
#   }
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-id$} -
      {^-ids$} -
      {^-i(ds?)?$} {
        set snapshotids [lshift args]
      }
      {^-glob$} -
      {^-g(l(ob?)?)?$} {
        set glob [lshift args]
      }
      {^-verbose$} -
      {^-v(e(r(b(o(se?)?)?)?)?)?$} {
        set verbose 1
      }
      {^-debug$} -
      {^-d(e(b(ug?)?)?)?$} {
        set debug 1
      }
      {^-h$} -
      {^-help$} -
      {^-h(e(lp?)?)?$} {
           set help 1
      }
      default {
            if {[string match "-*" $name]} {
              print error "option '$name' is not a valid option."
              incr error
            } else {
              set snapshotids $name
#               print error "option '$name' is not a valid option."
#               incr error
            }
      }
    }
  }

  if {$help} {
    print stdout [format {
  Usage: get_versions
              [-ids <list_snapshot_ids>]
              [-glob <exp>]
              [-verbose]
              [-help|-h]

  Description: Return the list of versions

  Example:
     get_versions
     get_versions -glob {%%high%%}
     get_versions [get_snapshot_ids -version {%%BUF%%}]
} ]
    # HELP -->
    return -code ok
  }

  if {$SQL == {}} {
    print error "SQLite3 database not opened"
    incr error
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  if {$snapshotids == {}} {
    set snapshotids [lsort [execSQL $SQL "SELECT id FROM snapshot WHERE (enabled == 1)" ]]
  }

  if {$verbose} {
    print info "<<<<<<<<<<<<<<< get_versions <<<<<<<<<<<<<<<"
  }

  set CMD "SELECT version
      FROM snapshot
      WHERE id IN ('[join $snapshotids ',']')
            AND version LIKE '$glob'
      ;
     "

#   set versions [lsort -unique [execSQL $SQL $CMD]]
  set versions [::tb::snapshot::luniq [execSQL $SQL $CMD]]

  if {$verbose} {
    print info ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  }

  return $versions
}

#------------------------------------------------------------------------
# ::tb::snapshot::get_releases
#------------------------------------------------------------------------
# Usage: get_releases [<options>]
#------------------------------------------------------------------------
# Get the list of releases
#------------------------------------------------------------------------
proc ::tb::snapshot::get_releases {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable SQL
  set snapshotids {}
  set glob {%}
  set verbose 0
  set debug 0
  set error 0
  set help 0
#   if {[llength $args] == 0} {
#     set help 1
#   }
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-id$} -
      {^-ids$} -
      {^-i(ds?)?$} {
        set snapshotids [lshift args]
      }
      {^-glob$} -
      {^-g(l(ob?)?)?$} {
        set glob [lshift args]
      }
      {^-verbose$} -
      {^-v(e(r(b(o(se?)?)?)?)?)?$} {
        set verbose 1
      }
      {^-debug$} -
      {^-d(e(b(ug?)?)?)?$} {
        set debug 1
      }
      {^-h$} -
      {^-help$} -
      {^-h(e(lp?)?)?$} {
           set help 1
      }
      default {
            if {[string match "-*" $name]} {
              print error "option '$name' is not a valid option."
              incr error
            } else {
              set snapshotids $name
#               print error "option '$name' is not a valid option."
#               incr error
            }
      }
    }
  }

  if {$help} {
    print stdout [format {
  Usage: get_releases
              [-ids <list_snapshot_ids>]
              [-glob <exp>]
              [-verbose]
              [-help|-h]

  Description: Return the list of releases

  Example:
     get_releases
     get_releases -glob {%%high%%}
     get_releases [get_snapshot_ids -version {%%BUF%%}]
} ]
    # HELP -->
    return -code ok
  }

  if {$SQL == {}} {
    print error "SQLite3 database not opened"
    incr error
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  if {$snapshotids == {}} {
    set snapshotids [lsort [execSQL $SQL "SELECT id FROM snapshot WHERE (enabled == 1)" ]]
  }

  if {$verbose} {
    print info "<<<<<<<<<<<<<<< get_releases <<<<<<<<<<<<<<<"
  }

  set CMD "SELECT release
      FROM snapshot
      WHERE id IN ('[join $snapshotids ',']')
            AND release LIKE '$glob'
      ;
     "

#  set releases [lsort -unique [execSQL $SQL $CMD]]
  set releases [::tb::snapshot::luniq [execSQL $SQL $CMD]]

  if {$verbose} {
    print info ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  }

  return $releases
}

#------------------------------------------------------------------------
# ::tb::snapshot::get_runs
#------------------------------------------------------------------------
# Usage: get_runs [<options>]
#------------------------------------------------------------------------
# Get the list of runs
#------------------------------------------------------------------------
proc ::tb::snapshot::get_runs {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable SQL
  set snapshotids {}
  set glob {%}
  set verbose 0
  set debug 0
  set error 0
  set help 0
#   if {[llength $args] == 0} {
#     set help 1
#   }
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-id$} -
      {^-ids$} -
      {^-i(ds?)?$} {
        set snapshotids [lshift args]
      }
      {^-glob$} -
      {^-g(l(ob?)?)?$} {
        set glob [lshift args]
      }
      {^-verbose$} -
      {^-v(e(r(b(o(se?)?)?)?)?)?$} {
        set verbose 1
      }
      {^-debug$} -
      {^-d(e(b(ug?)?)?)?$} {
        set debug 1
      }
      {^-h$} -
      {^-help$} -
      {^-h(e(lp?)?)?$} {
           set help 1
      }
      default {
            if {[string match "-*" $name]} {
              print error "option '$name' is not a valid option."
              incr error
            } else {
              set snapshotids $name
#               print error "option '$name' is not a valid option."
#               incr error
            }
      }
    }
  }

  if {$help} {
    print stdout [format {
  Usage: get_runs
              [-ids <list_snapshot_ids>]
              [-glob <exp>]
              [-verbose]
              [-help|-h]

  Description: Return the list of runs

  Example:
     get_runs
     get_runs -glob {%%high%%}
     get_runs [get_snapshot_ids -version {%%BUF%%}]
} ]
    # HELP -->
    return -code ok
  }

  if {$SQL == {}} {
    print error "SQLite3 database not opened"
    incr error
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  if {$snapshotids == {}} {
    set snapshotids [lsort [execSQL $SQL "SELECT id FROM snapshot WHERE (enabled == 1)" ]]
  }

  if {$verbose} {
    print info "<<<<<<<<<<<<<<< get_runs <<<<<<<<<<<<<<<"
  }

  set CMD "SELECT run
      FROM snapshot
      WHERE id IN ('[join $snapshotids ',']')
            AND run LIKE '$glob'
      ;
     "

#   set runs [lsort -unique [execSQL $SQL $CMD]]
  set runs [::tb::snapshot::luniq [execSQL $SQL $CMD]]

  if {$verbose} {
    print info ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  }

  return $runs
}

#------------------------------------------------------------------------
# ::tb::snapshot::get_steps
#------------------------------------------------------------------------
# Usage: get_steps [<options>]
#------------------------------------------------------------------------
# Get the list of steps
#------------------------------------------------------------------------
proc ::tb::snapshot::get_steps {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable SQL
  set snapshotids {}
  set glob {%}
  set verbose 0
  set debug 0
  set error 0
  set help 0
#   if {[llength $args] == 0} {
#     set help 1
#   }
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-id$} -
      {^-ids$} -
      {^-i(ds?)?$} {
        set snapshotids [lshift args]
      }
      {^-glob$} -
      {^-g(l(ob?)?)?$} {
        set glob [lshift args]
      }
      {^-verbose$} -
      {^-v(e(r(b(o(se?)?)?)?)?)?$} {
        set verbose 1
      }
      {^-debug$} -
      {^-d(e(b(ug?)?)?)?$} {
        set debug 1
      }
      {^-h$} -
      {^-help$} -
      {^-h(e(lp?)?)?$} {
           set help 1
      }
      default {
            if {[string match "-*" $name]} {
              print error "option '$name' is not a valid option."
              incr error
            } else {
              set snapshotids $name
#               print error "option '$name' is not a valid option."
#               incr error
            }
      }
    }
  }

  if {$help} {
    print stdout [format {
  Usage: get_steps
              [-ids <list_snapshot_ids>]
              [-glob <exp>]
              [-verbose]
              [-help|-h]

  Description: Return the list of steps

  Example:
     get_steps
     get_steps -glob {%%high%%}
     get_steps [get_snapshot_ids -version {%%BUF%%}]
} ]
    # HELP -->
    return -code ok
  }

  if {$SQL == {}} {
    print error "SQLite3 database not opened"
    incr error
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  if {$snapshotids == {}} {
    set snapshotids [lsort [execSQL $SQL "SELECT id FROM snapshot WHERE (enabled == 1)" ]]
  }

  if {$verbose} {
    print info "<<<<<<<<<<<<<<< get_steps <<<<<<<<<<<<<<<"
  }

  set CMD "SELECT step
      FROM snapshot
      WHERE id IN ('[join $snapshotids ',']')
            AND step LIKE '$glob'
      ;
     "

#  set steps [lsort -unique [execSQL $SQL $CMD]]
  set steps [::tb::snapshot::luniq [execSQL $SQL $CMD]]

  if {$verbose} {
    print info ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  }

  return $steps
}

#------------------------------------------------------------------------
# ::tb::snapshot::get_parent_ids
#------------------------------------------------------------------------
# Usage: get_parent_ids [<options>]
#------------------------------------------------------------------------
# Get the list of parent ids
#------------------------------------------------------------------------
proc ::tb::snapshot::get_parent_ids {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable SQL
  set snapshotids {}
  set verbose 0
  set debug 0
  set error 0
  set help 0
#   if {[llength $args] == 0} {
#     set help 1
#   }
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-id$} -
      {^-ids$} -
      {^-i(ds?)?$} {
        set snapshotids [lshift args]
      }
      {^-verbose$} -
      {^-v(e(r(b(o(se?)?)?)?)?)?$} {
        set verbose 1
      }
      {^-debug$} -
      {^-d(e(b(ug?)?)?)?$} {
        set debug 1
      }
      {^-h$} -
      {^-help$} -
      {^-h(e(lp?)?)?$} {
           set help 1
      }
      default {
            if {[string match "-*" $name]} {
              print error "option '$name' is not a valid option."
              incr error
            } else {
              set snapshotids $name
#               print error "option '$name' is not a valid option."
#               incr error
            }
      }
    }
  }

  if {$help} {
    print stdout [format {
  Usage: get_parent_ids
              [-ids <list_snapshot_ids>]
              [-verbose]
              [-help|-h]

  Description: Return the list of parents

  Example:
     get_parent_ids
     get_parent_ids [get_snapshot_ids -version {%%BUF%%}]
} ]
    # HELP -->
    return -code ok
  }

  if {$SQL == {}} {
    print error "SQLite3 database not opened"
    incr error
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  if {$snapshotids == {}} {
    set snapshotids [lsort [execSQL $SQL "SELECT id FROM snapshot WHERE (enabled == 1)" ]]
  }

  if {$verbose} {
    print info "<<<<<<<<<<<<<<< get_parent_ids <<<<<<<<<<<<<<<"
  }

  set CMD "SELECT parentid
      FROM snapshot
      WHERE id IN ('[join $snapshotids ',']')
      ;
     "

#   set parentids [lsort -unique [execSQL $SQL $CMD]]
  set parentids [::tb::snapshot::luniq [execSQL $SQL $CMD]]

  if {$verbose} {
    print info ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  }

  return $parentids
}

#------------------------------------------------------------------------
# ::tb::snapshot::get_descriptions
#------------------------------------------------------------------------
# Usage: get_descriptions [<options>]
#------------------------------------------------------------------------
# Get the list of descriptions
#------------------------------------------------------------------------
proc ::tb::snapshot::get_descriptions {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable SQL
  set snapshotids {}
  set glob {%}
  set verbose 0
  set debug 0
  set error 0
  set help 0
#   if {[llength $args] == 0} {
#     set help 1
#   }
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-id$} -
      {^-ids$} -
      {^-i(ds?)?$} {
        set snapshotids [lshift args]
      }
      {^-glob$} -
      {^-g(l(ob?)?)?$} {
        set glob [lshift args]
      }
      {^-verbose$} -
      {^-v(e(r(b(o(se?)?)?)?)?)?$} {
        set verbose 1
      }
      {^-debug$} -
      {^-d(e(b(ug?)?)?)?$} {
        set debug 1
      }
      {^-h$} -
      {^-help$} -
      {^-h(e(lp?)?)?$} {
           set help 1
      }
      default {
            if {[string match "-*" $name]} {
              print error "option '$name' is not a valid option."
              incr error
            } else {
              set snapshotids $name
#               print error "option '$name' is not a valid option."
#               incr error
            }
      }
    }
  }

  if {$help} {
    print stdout [format {
  Usage: get_descriptions
              [-ids <list_snapshot_ids>]
              [-glob <exp>]
              [-verbose]
              [-help|-h]

  Description: Return the list of descriptions

  Example:
     get_descriptions
     get_descriptions -glob {%%high%%}
     get_descriptions [get_snapshot_ids -version {%%BUF%%}]
} ]
    # HELP -->
    return -code ok
  }

  if {$SQL == {}} {
    print error "SQLite3 database not opened"
    incr error
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  if {$snapshotids == {}} {
    set snapshotids [lsort [execSQL $SQL "SELECT id FROM snapshot WHERE (enabled == 1)" ]]
  }

  if {$verbose} {
    print info "<<<<<<<<<<<<<<< get_descriptions <<<<<<<<<<<<<<<"
  }

  set CMD "SELECT description
      FROM snapshot
      WHERE id IN ('[join $snapshotids ',']')
            AND description LIKE '$glob'
      ;
     "

#   set descriptions [lsort -unique [execSQL $SQL $CMD]]
  set descriptions [::tb::snapshot::luniq [execSQL $SQL $CMD]]

  if {$verbose} {
    print info ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  }

  return $descriptions
}

#------------------------------------------------------------------------
# ::tb::snapshot::get_metric_names
#------------------------------------------------------------------------
# Usage: get_metric_names [<options>]
#------------------------------------------------------------------------
# Get the list of metric names
#------------------------------------------------------------------------
proc ::tb::snapshot::get_metric_names {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable SQL
  set snapshotids {}
  set glob {%}
  set verbose 0
  set debug 0
  set error 0
  set help 0
#   if {[llength $args] == 0} {
#     set help 1
#   }
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-id$} -
      {^-ids$} -
      {^-i(ds?)?$} {
        set snapshotids [lshift args]
      }
      {^-glob$} -
      {^-g(l(ob?)?)?$} {
        set glob [lshift args]
      }
      {^-verbose$} -
      {^-v(e(r(b(o(se?)?)?)?)?)?$} {
        set verbose 1
      }
      {^-debug$} -
      {^-d(e(b(ug?)?)?)?$} {
        set debug 1
      }
      {^-h$} -
      {^-help$} -
      {^-h(e(lp?)?)?$} {
           set help 1
      }
      default {
            if {[string match "-*" $name]} {
              print error "option '$name' is not a valid option."
              incr error
            } else {
              set snapshotids $name
#               print error "option '$name' is not a valid option."
#               incr error
            }
      }
    }
  }

  if {$help} {
    print stdout [format {
  Usage: get_metric_names
              [-ids <list_snapshot_ids>]
              [-glob <exp>]
              [-verbose]
              [-help|-h]

  Description: Return the list of metric names

  Example:
     get_metric_names
     get_metric_names -glob {%%high%%}
     get_metric_names [get_snapshot_ids -version {%%BUF%%}]
} ]
    # HELP -->
    return -code ok
  }

  if {$SQL == {}} {
    print error "SQLite3 database not opened"
    incr error
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  if {$snapshotids == {}} {
    set snapshotids [lsort [execSQL $SQL "SELECT id FROM snapshot WHERE (enabled == 1)" ]]
  }

  if {$verbose} {
    print info "<<<<<<<<<<<<<<< get_metric_names <<<<<<<<<<<<<<<"
  }

  set CMD "SELECT name
      FROM metric
      WHERE snapshotid IN ('[join $snapshotids ',']')
            AND name LIKE '$glob'
            AND (enabled == 1)
      ;
     "

#   set metric_names [lsort -unique [execSQL $SQL $CMD]]
  set metric_names [::tb::snapshot::luniq [execSQL $SQL $CMD]]

  if {$verbose} {
    print info ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  }

  return $metric_names
}

#------------------------------------------------------------------------
# ::tb::snapshot::get_metric_ids
#------------------------------------------------------------------------
# Usage: get_metric_ids [<options>]
#------------------------------------------------------------------------
# Get the list of metric ids
#------------------------------------------------------------------------
proc ::tb::snapshot::get_metric_ids {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable SQL
  set snapshotids {}
  set glob {%}
  set verbose 0
  set debug 0
  set error 0
  set help 0
#   if {[llength $args] == 0} {
#     set help 1
#   }
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-id$} -
      {^-ids$} -
      {^-i(ds?)?$} {
        set snapshotids [lshift args]
      }
      {^-glob$} -
      {^-g(l(ob?)?)?$} {
        set glob [lshift args]
      }
      {^-verbose$} -
      {^-v(e(r(b(o(se?)?)?)?)?)?$} {
        set verbose 1
      }
      {^-debug$} -
      {^-d(e(b(ug?)?)?)?$} {
        set debug 1
      }
      {^-h$} -
      {^-help$} -
      {^-h(e(lp?)?)?$} {
           set help 1
      }
      default {
            if {[string match "-*" $name]} {
              print error "option '$name' is not a valid option."
              incr error
            } else {
              set snapshotids $name
#               print error "option '$name' is not a valid option."
#               incr error
            }
      }
    }
  }

  if {$help} {
    print stdout [format {
  Usage: get_metric_ids
              [-ids <list_snapshot_ids>]
              [-glob <exp>]
              [-verbose]
              [-help|-h]

  Description: Return the list of metric ids

  Example:
     get_metric_ids
     get_metric_ids -glob {%%high%%}
     get_metric_ids [get_snapshot_ids -version {%%BUF%%}]
} ]
    # HELP -->
    return -code ok
  }

  if {$SQL == {}} {
    print error "SQLite3 database not opened"
    incr error
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  if {$snapshotids == {}} {
    set snapshotids [lsort [execSQL $SQL "SELECT id FROM snapshot WHERE (enabled == 1)" ]]
  }

  if {$verbose} {
    print info "<<<<<<<<<<<<<<< get_metric_ids <<<<<<<<<<<<<<<"
  }

  set CMD "SELECT id
      FROM metric
      WHERE snapshotid IN ('[join $snapshotids ',']')
            AND name LIKE '$glob'
            AND (enabled == 1)
      ;
     "

#   set metric_ids [lsort -unique -integer [execSQL $SQL $CMD]]
  set metric_ids [::tb::snapshot::luniq [execSQL $SQL $CMD]]

  if {$verbose} {
    print info ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  }

  return $metric_ids
}

#------------------------------------------------------------------------
# ::tb::snapshot::get_metric_values
#------------------------------------------------------------------------
# Usage: get_metric_values [<options>]
#------------------------------------------------------------------------
# Get a list of metric values
#------------------------------------------------------------------------
proc ::tb::snapshot::get_metric_values {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable SQL
  set metricids {}
  set quiet 0
  set verbose 0
  set debug 0
  set error 0
  set help 0
  if {[llength $args] == 0} {
    set help 1
  }
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-ids$} -
      {^-i(ds?)?$} {
        set metricids [lshift args]
      }
      {^-quiet$} -
      {^-q(u(i(et?)?)?)?$} {
        set quiet 1
      }
      {^-verbose$} -
      {^-v(e(r(b(o(se?)?)?)?)?)?$} {
        set verbose 1
      }
      {^-debug$} -
      {^-d(e(b(ug?)?)?)?$} {
        set debug 1
      }
      {^-h$} -
      {^-help$} -
      {^-h(e(lp?)?)?$} {
           set help 1
      }
      default {
            if {[string match "-*" $name]} {
              print error "option '$name' is not a valid option."
              incr error
            } else {
              set metricids $name
#               print error "option '$name' is not a valid option."
#               incr error
            }
      }
    }
  }

  if {$help} {
    print stdout [format {
  Usage: get_metric_values
              [-ids <list_metric_ids>]
              [-quiet]
              [-verbose]
              [-help|-h]

  Description: Return a list of metric values

  Example:
     get_metric_values -id 32
} ]
    # HELP -->
    return -code ok
  }

  if {$SQL == {}} {
    print error "SQLite3 database not opened"
    incr error
  }

  if {$metricids == {}} {
    # Do not error out and no message in quiet mode
    if {$quiet} { return {} }
    print error "no metric id provided"
    incr error
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  if {$verbose} {
    print info "<<<<<<<<<<<<<<< get_metric_values <<<<<<<<<<<<<<<"
  }

  set CMD "SELECT value
      FROM metric
      WHERE id IN ('[join $metricids ',']')
            AND (enabled == 1)
      ;
     "

#   set metric_values [lsort -unique [execSQL $SQL $CMD]]
  set metric_values [::tb::snapshot::luniq [execSQL $SQL $CMD]]

  if {$verbose} {
    print info ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  }

  return $metric_values
}






#################################################################################
#################################################################################
#################################################################################

# For debug:
# proc reload {} { catch {namespace delete ::tb::snapshot}; source -notrace ~/git/scripts/wip/snapshot/snapshot.tcl; puts " snapshot.tcl reloaded" }
# catch { namespace import ::tb::open_sqlite_db }
# catch { namespace import ::tb::open_snapshot_db }
# catch { namespace import ::tb::close_snapshot_db }
# catch { namespace import ::tb::create_snapshot_db }
# catch { namespace import ::tb::create_sqlite_db }
# catch { namespace import ::tb::get_snapshot_ids }
# catch { namespace import ::tb::get_projects }
# catch { namespace import ::tb::get_experiments }
# catch { namespace import ::tb::get_versions }
# catch { namespace import ::tb::get_runs }
# catch { namespace import ::tb::get_steps }
# catch { namespace import ::tb::get_releases }
# catch { namespace import ::tb::get_parent_ids }
# catch { namespace import ::tb::get_descriptions }
# catch { namespace import ::tb::get_metric_names }
# catch { namespace import ::tb::get_metric_ids }
# catch { namespace import ::tb::get_metric_values }


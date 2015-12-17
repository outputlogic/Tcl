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
## Version:        2015.12.17
## Tool Version:   Vivado 2014.1
## Description:    Plugin for snapshot_core.tcl to export database to CSV file
##
########################################################################################

########################################################################################
## 2015.12.17 - Renamed namespace variable to prevent name collision with plugin 
## 2014.06.03 - Splited from original snapshot.tcl
##            - Other enhancements and fixes
##            - Initial release
########################################################################################

if {[info exists DEBUG]} { puts " Sourcing [file normalize [info script]]" }

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

  # Convert database to CSV (-help)
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

  variable summaryMatrix
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
  set transpose 0
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
      -metric -
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
      -transpose {
        set transpose 1
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
              [-release|-rel <string>]
              [-version|-ver <string>]
              [-experiment|-e <string>]
              [-step|-s <string>]
              [-run|-r <string>]
              [-transpose]
              [-verbose|-quiet]
              [-help|-h]

  Description: Convert a database to CSV file

  Example:
     snapshot db2csv
     snapshot db2csv -db ./metrics.db -file ./metrics.csv -metrics {metric1 metric2 ... metricN} -delimiter ,
     snapshot db2csv -experiment {No%%Buffer%%}
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
  set dbVersion [execSQL SQL { SELECT value FROM param WHERE property='version' LIMIT 1; } ]
  if {$verbose} {
    print info "Database version: $dbVersion"
    print info "CSV generation started on [clock format [clock seconds]]"
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
    # TODO: Should the list of metric names be filters by eol<=1
    set CMD "SELECT DISTINCT name FROM metric WHERE snapshotid IN ('[join $snapshotids ',']') AND (enabled == 1) AND (binary == 0)"
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
  catch {summaryMatrix destroy}
  struct::matrix summaryMatrix
  summaryMatrix add columns [expr 10 + [llength $metrics]]
  summaryMatrix add row [concat [list {id} {project} {release} {version} {experiment} {step} {run} {description} {date} {time} ] $metrics ]

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
      summaryMatrix add row
      summaryMatrix set cell 0 $numrow $id
      summaryMatrix set cell 1 $numrow $project
      summaryMatrix set cell 2 $numrow $release
      summaryMatrix set cell 3 $numrow $version
      summaryMatrix set cell 4 $numrow $experiment
      summaryMatrix set cell 5 $numrow $step
      summaryMatrix set cell 6 $numrow $run
      summaryMatrix set cell 7 $numrow $description
      summaryMatrix set cell 8 $numrow $date
      summaryMatrix set cell 9 $numrow $time

      # When a duplicate metric name is found for a snapshot, keep the last one only. This is to support
      # the incremental flow when snapshot metric can be re-taken for a snapshot
      # Skip metric values that are binary or have more than 1 line
      set CMD2 "SELECT name, value
             FROM metric
             WHERE snapshotid = $id
             AND (enabled == 1)
             AND ( name IN ('[join $metrics ',']') )
             AND id IN ( SELECT MAX(id)
                         FROM metric
                         WHERE snapshotid = $id
                         AND (enabled == 1)
                         AND (binary == 0)
                         AND (eol <= 1)
                         GROUP BY snapshotid, name
                       )
             ORDER BY name ASC
             ;
             "
#       set CMD2 "SELECT name, value
#              FROM metric
#              WHERE snapshotid = $id
#                    AND (enabled == 1)
#                    AND ( name IN ('[join $metrics ',']') )
#              ;
#              "
      execSQL SQL { pragma integrity_check }
      SQL eval $CMD2 metricinfo {
        set metricname $metricinfo(name)
        set metricvalue $metricinfo(value)
        set numcol [expr 10 + [lsearch $metrics $metricname]]
#         summaryMatrix set cell $numcol $numrow $metricvalue
#         summaryMatrix set cell $numcol $numrow [list2csv [list [truncateText $metricvalue]] $csvdelimiter]
        # TODO: Since the metric values that are binary or have multiple lines have been skiped, does the metric value need to be truncated?
        summaryMatrix set cell $numcol $numrow [truncateText $metricvalue]
#         summaryMatrix set cell $numcol $numrow [::csv::join [list [truncateText $metricvalue]] ,]
#         summaryMatrix set cell $numcol $numrow [::csv::join [list [truncateText $metricvalue]] $csvdelimiter]
        if {$debug} {
          print debug "snapshotid=$id / name=$metricname / value='[truncateText $metricvalue]'"
        }
      }


    }

  }

  # Transpose matrix?
  if {$transpose} {
    if {$verbose} {
      print info "Matrix transposed"
    }
    summaryMatrix transpose
  }

#   print stdout [summaryMatrix format 2string matrixFormat]
#   print stdout [matrixFormat printmatrix ::tb::snapshot::summaryMatrix]
#   csv::writematrix ::tb::snapshot::summaryMatrix stdout $csvdelimiter
# #   csv::writematrix matrixFormat ::tb::snapshot::summaryMatrix stdout

  if {$csvfile == {}} {
#     print stdout [csv::report printmatrix ::tb::snapshot::summaryMatrix]
    csv::writematrix ::tb::snapshot::summaryMatrix stdout $csvdelimiter
# #     csv::writematrix summaryMatrix <chan> ,
# #     csv::writematrix matrixFormat summaryMatrix stdout
  } else {
    set csvfile [file normalize $csvfile]
    set FH [open $csvfile $mode]
    puts $FH "# Created on [clock format [clock seconds]]"
    puts $FH "# Database: $db"
#     puts $FH [csv::report printmatrix ::tb::snapshot::summaryMatrix]
#     puts $FH {}
    csv::writematrix ::tb::snapshot::summaryMatrix $FH $csvdelimiter
    close $FH
    print stdout " File $csvfile has been created"
  }

  summaryMatrix destroy
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


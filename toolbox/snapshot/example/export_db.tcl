#!/bin/sh
# use -*-TCL-*- \
exec tclsh "$0" "$@"

# This script update a sqlite3 database to add post-processed metrics related to timing summary and route status

package require snapshot
package require sqlite3

if {[llength $argv] == 0} {
    puts [format {
  Usage: export_db.tcl <database>

  Description:

     This scripts exports the report_design_analysis reports

  Example:
     export_db.tcl metrics.db
     export_db.tcl *.db
} ]
    # HELP -->
  exit 0
}

set files [list]
foreach pattern $argv {
  foreach filename [glob -nocomplain $pattern] {
    lappend files [file normalize $filename]
  }
}
set files [lsort -unique $files]

set num 0
foreach db $files {
  incr num
  set dir [file dirname $db]
  puts "  Processing \[$num/[llength $files]\] $db"
  # Saving timestamp of current directory and database
  set tsDir [clock format [file mtime $dir]]
  set tsDb [clock format [file mtime $db]]
  # Open database
  sqlite3 SQL $db
  # sqlite3 SQL $db -readonly true

  set snapshotids [lsort -integer [::tb::snapshot::execSQL SQL "SELECT id FROM snapshot" ]]

  foreach id $snapshotids {
    set rundir [::tb::snapshot::execSQL SQL "SELECT value FROM metric WHERE name='rundir' AND snapshotid = $id " ]
    set report [::tb::snapshot::execSQL SQL "SELECT value FROM metric WHERE name='report.design_analysis' AND snapshotid = $id " ]
    set step [::tb::snapshot::execSQL SQL "SELECT value FROM metric WHERE name='snapshot.step' AND snapshotid = $id " ]
#     puts "$id: [::tb::snapshot::truncateText $report]"
    if {![file isdirectory $rundir]} {
      puts "    id=$id: step: $step / skipping / cannot find directory ($rundir)"
      continue
    }
    set tsRundir [clock format [file mtime $rundir]]
    set filename [file join $rundir report_design_analysis.setup.${step}.rpt]
    if {[file exists $filename]} {
      puts "    id=$id: step: $step / skipping / file already exist ($filename)"
      continue
    }
    puts "    id=$id: step: $step / exporting $filename"
    set FH [open $filename {w}]
    puts $FH [join $report \n]
    close $FH
    catch { exec touch -md $tsRundir $rundir }
#     catch { exec touch -md $tsRundir $filename }
  }

  SQL close
  # Restore timestamp of directory and database
  catch { exec touch -md $tsDb $db }
  catch { exec touch -md $tsDir $dir }
}

exit 0

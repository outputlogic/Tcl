#!/bin/sh
# use -*-TCL-*- \
exec tclsh "$0" "$@"

# This script update a sqlite3 database to add post-processed metrics related to timing summary and route status

package require snapshot
package require sqlite3

if {[llength $argv] == 0} {
    puts [format {
  Usage: search_db.tcl <database>

  Description:

     This scripts search information inside database

  Example:
     search_db.tcl metrics.db
     search_db.tcl *.db
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
  set SQL [::tb::open_snapshot_db -db $db -memory]

  set allsnapshotids [::tb::get_snapshot_ids]
  set projects [lsort [::tb::get_projects]]
  set count 0
  foreach project $projects {
    set projectids [::tb::get_snapshot_ids -project $project]
    set versions [lsort [::tb::get_versions -ids $projectids]]
    foreach version $versions {
      set versionids [::tb::get_snapshot_ids -project $project -version $version]
      set releases [lsort [::tb::get_releases -ids $versionids]]
      foreach release $releases {
        set releaseids [::tb::get_snapshot_ids -project $project -version $version -release $release]
        set experiments [lsort [::tb::get_experiments -ids $releaseids]]
        foreach experiment $experiments {
          puts [format {    %s -> %s -> %s -> %s} $project $version $release $experiment]
          foreach step [::tb::get_steps -ids [::tb::get_snapshot_ids -project $project -version $version -release $release -experiment $experiment]] {
            set id [::tb::get_snapshot_ids -project $project -version $version -release $release -experiment $experiment -step $step]
            if {[llength $id] > 1} {
              continue
            }
            set rundir [::tb::snapshot::execSQL $SQL "SELECT value FROM metric WHERE name='rundir' AND snapshotid = $id " ]
            set report [::tb::snapshot::execSQL $SQL "SELECT value FROM metric WHERE name='report.design_analysis' AND snapshotid = $id " ]
            set step [::tb::snapshot::execSQL $SQL "SELECT value FROM metric WHERE name='snapshot.step' AND snapshotid = $id " ]
            set wns [::tb::get_metric_values -ids [::tb::get_metric_ids -ids $id -glob {report.timing_summary.wns}]]
            set tns [::tb::get_metric_values -ids [::tb::get_metric_ids -ids $id -glob {report.timing_summary.tns}]]
            set tnsFailing [::tb::get_metric_values -ids [::tb::get_metric_ids -ids $id -glob {report.timing_summary.tns.failing}]]
            set whs [::tb::get_metric_values -ids [::tb::get_metric_ids -ids $id -glob {report.timing_summary.whs}]]
            set ths [::tb::get_metric_values -ids [::tb::get_metric_ids -ids $id -glob {report.timing_summary.ths}]]
            set thsFailing [::tb::get_metric_values -ids [::tb::get_metric_ids -ids $id -glob {report.timing_summary.ths.failing}]]
            set overlaps [::tb::get_metric_values -ids [::tb::get_metric_ids -ids $id -glob {report.route_status.errors}]]
            set placerCong [::tb::get_metric_values -quiet -ids [::tb::get_metric_ids -ids $id -glob {report.design_analysis.congestion.placer}]]
            set routerCong [::tb::get_metric_values -quiet -ids [::tb::get_metric_ids -ids $id -glob {report.design_analysis.congestion.router}]]
            puts "      id=$id: step: $step / WNS=$wns / PCong=$placerCong / RCong=$routerCong"
          }
        }
      }
    }
  }

  ::tb::close_snapshot_db
  # Restore timestamp of directory and database
  catch { exec touch -md $tsDb $db }
  catch { exec touch -md $tsDir $dir }
}

exit 0

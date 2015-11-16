#!/bin/sh
# use -*-TCL-*- \
exec tclsh "$0" "$@"

# This script update a sqlite3 database to add post-processed metrics related to timing summary and route status

package require snapshot
package require sqlite3

proc insert {snapshotid metric value} {
  set id [::tb::snapshot::execSQL SQL "SELECT id FROM metric WHERE name='$metric' AND snapshotid = $snapshotid " ]
  if {$id != {}} {
    return
  }
  puts "  $metric\t$value"
  ::tb::snapshot::execSQL SQL { INSERT INTO metric(snapshotid,name,value,type,ref) VALUES($snapshotid,$metric,$value,'blob','') ; }
  set metricid [SQL last_insert_rowid]
  ::tb::snapshot::execSQL SQL " UPDATE metric SET size=[string length $value], eol=[llength [split $value \n]] WHERE id=$metricid ; "
  # To test whether a file is "binary", in the sense that it contains NUL bytes
  set isBinary [expr {[string first \x00 $value]>=0}]
  if {$isBinary} {
    ::tb::snapshot::execSQL SQL " UPDATE metric SET binary=1 WHERE id=$metricid ; "
  }
}

set db {tmp.db}

sqlite3 SQL $db
# sqlite3 SQL $db -readonly true

set snapshotids [lsort -integer [::tb::snapshot::execSQL SQL "SELECT id FROM snapshot" ]]

foreach id $snapshotids {
  # Timing Summary
  set report [::tb::snapshot::execSQL SQL "SELECT value FROM metric WHERE name='report.timing_summary' AND snapshotid = $id " ]
  puts "$id: [::tb::snapshot::truncateText $report]"
  set report [split $report \n]
  if {[set i [lsearch -regexp $report {Design Timing Summary}]] != -1} {
     foreach {wns tns tnsFallingEp tnsTotalEp whs ths thsFallingEp thsTotalEp wpws tpws tpwsFailingEp tpwsTotalEp} [regexp -inline -all -- {\S+} [lindex $report [expr $i + 6]]] { break }
     insert $id report.timing_summary.wns $wns
     insert $id report.timing_summary.tns $tns
     insert $id report.timing_summary.tns.failing $tnsFallingEp
     insert $id report.timing_summary.tns.total $tnsTotalEp
     insert $id report.timing_summary.whs $whs
     insert $id report.timing_summary.ths $ths
     insert $id report.timing_summary.ths.failing $thsFallingEp
     insert $id report.timing_summary.ths.total $thsTotalEp
     insert $id report.timing_summary.wpws $wpws
     insert $id report.timing_summary.tpws $tpws
     insert $id report.timing_summary.tpws.failing $tpwsFailingEp
     insert $id report.timing_summary.tpws.total $tpwsTotalEp
  }

  # Route Status
  set report [::tb::snapshot::execSQL SQL "SELECT value FROM metric WHERE name='report.route_status' AND snapshotid = $id " ]
  puts "$id: [::tb::snapshot::truncateText $report]"
  foreach line [split $report \n] {
    if {[regexp {nets with routing errors.+\:\s*([0-9]+)\s*\:} $line - val]} {
      insert $id report.route_status.errors $val
    } elseif {[regexp {fully routed nets.+\:\s*([0-9]+)\s*\:} $line - val]} {
      insert $id report.route_status.routed $val
    } elseif {[regexp {nets with fixed routing.+\:\s*([0-9]+)\s*\:} $line - val]} {
      insert $id report.route_status.fixed $val
    } elseif {[regexp {routable nets.+\:\s*([0-9]+)\s*\:} $line - val]} {
      insert $id report.route_status.nets $val
    } else {
    }
  }

}

SQL close

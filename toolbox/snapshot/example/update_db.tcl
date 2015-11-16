#!/bin/sh
# use -*-TCL-*- \
exec tclsh "$0" "$@"

# This script update a sqlite3 database to add post-processed metrics related to timing summary and route status

package require snapshot
package require sqlite3

proc updateCongestion {id} {
  # report_design_analysis report
  set report [::tb::snapshot::execSQL SQL "SELECT value FROM metric WHERE name='report.design_analysis' AND snapshotid = $id " ]
  set step [::tb::snapshot::execSQL SQL "SELECT value FROM metric WHERE name='snapshot.step' AND snapshotid = $id " ]
  set congestion [::tb::snapshot::execSQL SQL "SELECT value FROM metric WHERE name='report.design_analysis.congestion.placer' AND snapshotid = $id " ]
  if {$congestion != {}} {
    puts "    id=$id: step: $step / congestion metrics exist. Skipping ..."
    return
  }
#   puts "$id: [::tb::snapshot::truncateText $report]"
  set congestion [parseRDACongestion $report]
  insert $id report.design_analysis.congestion.placer [lindex $congestion 0]
  insert $id report.design_analysis.congestion.router [lindex $congestion 1]
  puts "    id=$id: step: $step / placer congestion: [lindex $congestion 0] / router congestion: [lindex $congestion 1]"
}

proc updateTimingSummary {id} {
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
}

proc updateRouteStatus {id} {
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

# Code from Frederic Revenu
# Extract the placement + routing congestions from report_design_analysis
# Format: North-South-East-West
#         PlacerNorth-PlacerSouth-PlacerEast-PlacerWest RouterNorth-RouterSouth-RouterEast-RouterWest
proc parseRDACongestion {report} {
  set section "other"
  set placerCong [list u u u u]
  set routerCong [list u u u u]
  foreach line [split $report \n] {
    if {[regexp {^\d. (\S+) Maximum Level Congestion Reporting} $line foo step]} {
      switch -exact $step {
        "Placed" { set section "placer" }
        "Router" { set section "router" }
        default  { set section "other" }
      }
    } elseif {[regexp {^\| (\S+)\s*\| (\S+)\s*\| \S+\s*\| \S+\s*| \S+\s*\| \S+\s*\| \S+\s*\| \S+\s*\| \S+\s*\| \S+\s*\| \S+\s*\|} $line foo card cong] || \
              [regexp {^\| (\S+)\s*\| (\S+)\s*\| \S+\s*\| \s*\S+ -> \S+\s*\|\s*$} $line foo card cong]} {
      switch -exact $cong {
        "1x1"     { set level 0 }
        "2x2"     { set level 1 }
        "4x4"     { set level 2 }
        "8x8"     { set level 3 }
        "16x16"   { set level 4 }
        "32x32"   { set level 5 }
        "64x64"   { set level 6 }
        "128x128" { set level 7 }
        "256x256" { set level 8 }
        default   { set level u }
      }
      if {$section == "placer"} {
        switch -exact $card {
          "North" { set placerCong [lreplace $placerCong 0 0 $level] }
          "South" { set placerCong [lreplace $placerCong 1 1 $level] }
          "East"  { set placerCong [lreplace $placerCong 2 2 $level] }
          "West"  { set placerCong [lreplace $placerCong 3 3 $level] }
        }
      } elseif {$section == "router"} {
        switch -exact $card {
          "North" { set routerCong [lreplace $routerCong 0 0 $level] }
          "South" { set routerCong [lreplace $routerCong 1 1 $level] }
          "East"  { set routerCong [lreplace $routerCong 2 2 $level] }
          "West"  { set routerCong [lreplace $routerCong 3 3 $level] }
        }
      }
    } elseif {[regexp {^\d\. } $line]} {
      set section "other"
    }
  }
  return [list [join $placerCong -] [join $routerCong -]]
}

proc insert {snapshotid metric value} {
  set id [::tb::snapshot::execSQL SQL "SELECT id FROM metric WHERE name='$metric' AND snapshotid = $snapshotid " ]
  if {$id != {}} {
    return
  }
#   puts "    $metric\t$value"
  ::tb::snapshot::execSQL SQL { INSERT INTO metric(snapshotid,name,value,type,ref) VALUES($snapshotid,$metric,$value,'blob','') ; }
  set metricid [SQL last_insert_rowid]
  ::tb::snapshot::execSQL SQL " UPDATE metric SET size=[string length $value], eol=[llength [split $value \n]] WHERE id=$metricid ; "
  # To test whether a file is "binary", in the sense that it contains NUL bytes
  set isBinary [expr {[string first \x00 $value]>=0}]
  if {$isBinary} {
    ::tb::snapshot::execSQL SQL " UPDATE metric SET binary=1 WHERE id=$metricid ; "
  }
}

if {[llength $argv] == 0} {
    puts [format {
  Usage: update_db.tcl <database>

  Description:

     This adds the placer/router congestion metrics

  Example:
     update_db.tcl metrics.db
     update_db.tcl *.db
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
  # Backup
  if {![file exists ${db}.BAK]} {
    puts "    Backing up: $db -> ${db}.BAK"
    file copy -force $db ${db}.BAK
    catch { exec touch -md $tsDb ${db}.BAK }
  }
  # Open database
  sqlite3 SQL $db
  # sqlite3 SQL $db -readonly true

  set snapshotids [lsort -integer [::tb::snapshot::execSQL SQL "SELECT id FROM snapshot" ]]

  foreach id $snapshotids {
#     updateTimingSummary $id
#     updateRouteStatus $id
    updateCongestion $id
  }

  SQL close
  # Restore timestamp of directory and database
  catch { exec touch -md $tsDb $db }
  catch { exec touch -md $tsDir $dir }
}

exit 0

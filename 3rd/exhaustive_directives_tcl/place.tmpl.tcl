open_checkpoint CHECKPOINT

place_design -directive PLACE_DIRECTIVE
write_checkpoint -force DIRECTORY/postplace.dcp
report_timing_summary -no_detailed_paths -file DIRECTORY/postplace.rpt

if {[catch {
  source /wrk/hdstaff/dpefour/designs/zte/804253/0619/reportCriticalPathInfo.tcl
  package require snapshot
  snapshot configure -db /wrk/hdstaff/dpefour/designs/zte/804253/0619/metrics.db -project zte_otn -version 0619 -experiment PLACE_DIRECTIVE.AggressiveExplore.Explore -step place_design
  reportCriticalPathInfo DIRECTORY/reportCriticalPathInfo.csv
  uplevel #0 exec /home/dpefour/bin/csv2tbl -csv DIRECTORY/reportCriticalPathInfo.csv -out DIRECTORY/reportCriticalPathInfo.rpt
  snapshot addfile reportCriticalPathInfo.csv DIRECTORY/reportCriticalPathInfo.csv
  snapshot addfile reportCriticalPathInfo.rpt DIRECTORY/reportCriticalPathInfo.rpt
  snapshot extract -save
} errorstring]} {
  puts "ERROR - $errorstring"
}

exit

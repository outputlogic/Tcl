set runDir  [lindex $argv 0]
set logFile [lindex $argv 1]
set dsgName [lindex $argv 2]

set dcp ""
set LOG [open $logFile r]
while {[gets $LOG line] >= 0} {
  if {[regexp {^Command:\s+open_checkpoint\s+(\S+)} $line all dcp]} {
    break
  }
}
close $LOG
if {$dcp == ""} {
  puts "ERROR - Cannot find open_checkpoint command in log file"
  exit
}

if {[file exists $dcp]} {
  set dcpFile $dcp
} else {
  set dcpFile [regsub {\.OUTPUT} $logFile {}]/$dcp
  if {![file exists $dcpFile]} {
    puts "ERROR - Cannot find dcp file $dcpFile"
    exit
  }
}

if {[catch {open_checkpoint $dcpFile} mess]} {
  if {[regexp {ERROR: \[Project 1-589\] Checkpoint part '\S+' is not available. Closest-matching available part\(s\)\: (\S+)} $mess all tgtPart]} {
    open_checkpoint $dcpFile -part [regsub {,} $tgtPart {}]
  } else {
    puts "ERROR - Unsupported part"
    exit
  }
}

report_timing
report_timing_summary -file rts_withRep.rpt
report_utilization -file util_withRep.rpt
report_control_sets -file cs_withRep.rpt

reportReplication
undoReplication
report_timing
report_timing_summary -file rts_withoutRep.rpt
report_utilization -file util_withoutRep.rpt
report_control_sets -file cs_withoutRep.rpt

#place_design
#report_timing
#report_timing_summary -file rts_postplace.rpt
#report_utilization -file util_postplace.rpt

exit

set runDir           [lindex $argv 0]

open_checkpoint $runDir/postroute.dcp
file copy $runDir/rts_postroute.rpt $runDir/rts_postroute.rpt.previous
report_timing_summary -file $runDir/rts_postroute.rpt

exit

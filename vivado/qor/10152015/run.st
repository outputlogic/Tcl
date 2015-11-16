# Disable Light Timer
# set_param sta.sta4Timer false

# Verbose mode
# set_param place.hardVerbose 469538
# set_param place.oldMsgVerbose true
# set_param route.flowDbg 1

# Do not use new placer
# catch { set_param place.runNextGen 0  }

# Placer fix:
# set_param place.blockFFForLutRam true

proc snapit {experiment step directive} {
  if {[catch {
    snapshot configure -db %{ROOTDIR}/metrics.db -project %{PROJECT} -version %{VERSION} -experiment $experiment -step $step
#     if {[catch {reportCriticalPathInfo %{RUNDIR}/reportCriticalPathInfo.setup.${step}.${directive}.csv setup} errorstring]} {
#       puts " - E- reportCriticalPathInfo failed for setup: $errorstring"
#     }
#     if {[catch {reportCriticalPathInfo %{RUNDIR}/reportCriticalPathInfo.hold.${step}.${directive}.csv hold} errorstring]} {
#       puts " - E- reportCriticalPathInfo failed for hold: $errorstring"
#     }
#     if {[file exists %{RUNDIR}/reportCriticalPathInfo.setup.${step}.${directive}.csv]} {
#       catch { uplevel #0 exec /home/dpefour/bin/csv2tbl -csv %{RUNDIR}/reportCriticalPathInfo.setup.${step}.${directive}.csv -out %{RUNDIR}/reportCriticalPathInfo.setup.${step}.${directive}.rpt }
#       catch { snapshot addfile reportCriticalPathInfo.setup.csv %{RUNDIR}/reportCriticalPathInfo.setup.${step}.${directive}.csv }
#       catch { snapshot addfile reportCriticalPathInfo.setup.rpt %{RUNDIR}/reportCriticalPathInfo.setup.${step}.${directive}.rpt }
#     }
#     if {[file exists %{RUNDIR}/reportCriticalPathInfo.hold.${step}.${directive}.csv]} {
#       catch { uplevel #0 exec /home/dpefour/bin/csv2tbl -csv %{RUNDIR}/reportCriticalPathInfo.hold.${step}.${directive}.csv -out %{RUNDIR}/reportCriticalPathInfo.hold.${step}.${directive}.rpt }
#       catch { snapshot addfile reportCriticalPathInfo.hold.csv %{RUNDIR}/reportCriticalPathInfo.hold.${step}.${directive}.csv }
#       catch { snapshot addfile reportCriticalPathInfo.hold.rpt %{RUNDIR}/reportCriticalPathInfo.hold.${step}.${directive}.rpt }
#     }

    set spaths [get_timing_paths -quiet -nworst 1 -max_path 1000 -slack_lesser_than 0.0 -setup]
    ::tb::report_path_analysis -of $spaths -setup -file %{RUNDIR}/report_path_analysis.setup.${step}.${directive}.rpt
    ::tb::report_path_analysis -R -csv     -setup -file %{RUNDIR}/report_path_analysis.setup.${step}.${directive}.csv
    catch { snapshot addfile report_path_analysis.setup.csv %{RUNDIR}/report_path_analysis.setup.${step}.${directive}.csv }
    catch { snapshot addfile report_path_analysis.setup.rpt %{RUNDIR}/report_path_analysis.setup.${step}.${directive}.rpt }

    set hpaths [get_timing_paths -quiet -nworst 1 -max_path 1000 -slack_lesser_than 0.0 -hold]
    ::tb::report_path_analysis -of $hpaths -hold -file %{RUNDIR}/report_path_analysis.hold.${step}.${directive}.rpt
    ::tb::report_path_analysis -R -csv     -hold -file %{RUNDIR}/report_path_analysis.hold.${step}.${directive}.csv
    catch { snapshot addfile report_path_analysis.hold.csv %{RUNDIR}/report_path_analysis.hold.${step}.${directive}.csv }
    catch { snapshot addfile report_path_analysis.hold.rpt %{RUNDIR}/report_path_analysis.hold.${step}.${directive}.rpt }
    
    snapshot set directive $directive
    snapshot set rundir %{RUNDIR}
    snapshot extract -save
    snapshot reset
  } errorstring]} {
    puts "ERROR - $errorstring"
  }
}

catch {
#   source /home/dpefour/git/scripts/3rd/reportCriticalPathInfo.tcl
#   package require snapshot
  package require toolbox
  snapshot reset
}

set experiment %{EXPERIMENT}
set step 0

if {[catch {open_checkpoint %{CHECKPOINT}}]} {
  # If open_checkpoint failed (NFS issue?), try a second time
  open_checkpoint %{CHECKPOINT}
}

# delete_pblock [get_pblocks]
# read_xdc %{ROOTDIR}/floorplan.xdc

report_timing_summary -no_detailed_paths -file %{RUNDIR}/postopt.rpt
snapit $experiment [incr step].opt_design {}

# set start [clock seconds]
# opt_design -directive Default
# set stop [clock seconds]
# write_checkpoint -force %{RUNDIR}/postopt.dcp
# # report_timing_summary -no_detailed_paths -file %{RUNDIR}/postopt.rpt
# report_timing_summary -file %{RUNDIR}/postopt.rpt
# snapshot set duration [::tb::snapshot::duration [expr $stop - $start]]
# snapit $experiment [incr step].opt_design Default

set start [clock seconds]
place_design -directive %{PLACE_DIRECTIVE}
set stop [clock seconds]
write_checkpoint -force %{RUNDIR}/postplace.dcp
# report_timing_summary -no_detailed_paths -file %{RUNDIR}/postplace.rpt
report_timing_summary -file %{RUNDIR}/postplace.rpt
snapshot set duration [::tb::snapshot::duration [expr $stop - $start]]
snapit $experiment [incr step].place_design %{PLACE_DIRECTIVE}

set start [clock seconds]
phys_opt_design -directive Explore
set stop [clock seconds]
# write_checkpoint -force %{RUNDIR}/postphysopt.dcp
report_timing_summary -no_detailed_paths -file %{RUNDIR}/postphysopt.rpt
snapshot set duration [::tb::snapshot::duration [expr $stop - $start]]
snapit $experiment [incr step].phys_opt_design Explore

############################
#### PhysOpt Iterations ####
############################
set wns [get_property SLACK [get_timing_paths]]
# set tns $wns
set tns [format {%.2f} [expr 0.0 [join [get_property -quiet SLACK [get_timing_paths -quiet -slack_less_than 0.0 -setup -max_paths 50]] "+"]] ]
set prevWns -1000
set prevTns -1000
set i 0
set MAX_ITER 3
# In ns
set DELTA 0.010
# Stop iterating if delta between previous WNS and current WNS is less than 10ps
# while {$wns < 0 && $prevWns < $wns && ([expr abs($prevWns - $wns)] > 0.01)} {}
while {($wns < 0 && $prevWns < $wns && ([expr abs($prevWns - $wns)] > 0.01))
       || ($tns < 0 && $prevTns < $tns && ([expr abs($prevTns - $tns)] > 0.01)) } {
  set prevWns $wns
  set prevTns $tns
  incr i
  puts "## phys_opt_design - iteration $i - SLACK: $wns - TNS: $tns ##"

  set start [clock seconds]
  phys_opt_design -directive AggressiveExplore
  set stop [clock seconds]
#   write_checkpoint -force %{RUNDIR}/postphysopt.AggressiveExplore_iter${i}.dcp
  report_timing_summary -no_detailed_paths -file %{RUNDIR}/postphysopt.AggressiveExplore_iter${i}.rpt
  snapshot set duration [::tb::snapshot::duration [expr $stop - $start]]
  snapit $experiment [incr step].phys_opt_design AggressiveExplore

  set start [clock seconds]
  phys_opt_design -directive AggressiveFanoutOpt
  set stop [clock seconds]
#   write_checkpoint -force %{RUNDIR}/postphysopt.AggressiveFanoutOpt_iter${i}.dcp
  report_timing_summary -no_detailed_paths -file %{RUNDIR}/postphysopt.AggressiveFanoutOpt_iter${i}.rpt
  snapshot set duration [::tb::snapshot::duration [expr $stop - $start]]
  snapit $experiment [incr step].phys_opt_design AggressiveFanoutOpt

  set start [clock seconds]
  phys_opt_design -directive AlternateReplication
  set stop [clock seconds]
#   write_checkpoint -force %{RUNDIR}/postphysopt.AlternateReplication_iter${i}.dcp
  report_timing_summary -no_detailed_paths -file %{RUNDIR}/postphysopt.AlternateReplication_iter${i}.rpt
  snapshot set duration [::tb::snapshot::duration [expr $stop - $start]]
  snapit $experiment [incr step].phys_opt_design AlternateReplication

  set prevWns $wns
  set prevTns $tns
  set wns [get_property SLACK [get_timing_paths]]
  set tns [format {%.2f} [expr 0.0 [join [get_property -quiet SLACK [get_timing_paths -quiet -slack_less_than 0.0 -setup -max_paths 50]] "+"]] ]

  if {$i >= $MAX_ITER} {
    puts "## phys_opt_design - MAX_ITER ($MAX_ITER) reached. Exiting phys_opt_design loop ##"
    puts "## phys_opt_design - iteration $i - SLACK: $wns - TNS: $tns ##"
    break
  }
}
############################

write_checkpoint -force %{RUNDIR}/postphysopt.dcp
# report_timing_summary -no_detailed_paths -file %{RUNDIR}/postphysopt.rpt
report_timing_summary -file %{RUNDIR}/postphysopt.rpt

set start [clock seconds]
# route_design -directive Explore -tns_cleanup
route_design -directive Explore
set stop [clock seconds]
write_checkpoint -force %{RUNDIR}/postroute.dcp
# report_timing_summary -no_detailed_paths -file %{RUNDIR}/postroute.rpt
report_timing_summary -file %{RUNDIR}/postroute.rpt
snapshot set duration [::tb::snapshot::duration [expr $stop - $start]]
snapit $experiment [incr step].route_design Explore

#################################
#### Post-Route Optimization ####
#################################
set wns [get_property SLACK [get_timing_paths]]
if {$wns < 0} {
  set start [clock seconds]
  phys_opt_design
  set stop [clock seconds]
#   write_checkpoint -force %{RUNDIR}/postrouteopt.dcp
  report_timing_summary -no_detailed_paths -file %{RUNDIR}/postrouteopt.rpt
  snapshot set duration [::tb::snapshot::duration [expr $stop - $start]]
  snapit $experiment [incr step].phys_opt_design Default
}


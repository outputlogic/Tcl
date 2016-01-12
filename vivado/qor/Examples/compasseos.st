######################################################################
#
# Variables Initialization
#
######################################################################

set rootDir        {%{ROOTDIR}}
set runDir         {%{RUNDIR}}
# set db             {%{ROOTDIR}/metrics.db}
set db             $rootDir/metrics.db
set project        {%{PROJECT}}
set version        {%{VERSION}}
set experiment     {%{EXPERIMENT}}
set checkpoint     {%{CHECKPOINT}}
set placeDirective {%{PLACE_DIRECTIVE}}
# set floorplan      {%{ROOTDIR}/%{FLOORPLAN}
# set floorplan      $rootDir/%{FLOORPLAN}
set floorplan      {%{FLOORPLAN}}

set physOptIter    1
set physOptDelta   0.010

######################################################################
#
# Included from install.cfg
#
######################################################################
%{RUN_SCRIPT_INCLUDE}

######################################################################
#
# Procs (from common.tcl)
#
######################################################################

proc generate_RAM_FIFO_timing {args} {}
proc export_unpblocked_cells {args} {}
proc export_timing_paths {args} {}
proc snapshot {args} {}
proc snapit {args} {}

######################################################################
#
# Implementation script
#
######################################################################

# Verbose mode
set_param place.hardVerbose 469538
set_param place.oldMsgVerbose true
set_param route.flowDbg 1

catch {
  catch {
  	if {[lsearch [tclapp::list_apps] {xilinx::designutils}] == -1} {
  		tclapp::install designutils
  	}
  }
  package require toolbox
  snapshot reset
}

catch {
  if {[file exists $rootDir/common.tcl]} {
    puts " Sourcing common script file '$rootDir/common.tcl'"
    source $rootDir/common.tcl
  }
}

set step 0

if {[catch {open_checkpoint $checkpoint}]} {
  # If open_checkpoint failed (NFS issue?), try a second time
  open_checkpoint $checkpoint
}

if {[get_pblocks] != {}} { delete_pblock [get_pblocks] }
if {[catch { read_xdc $floorplan } errorstring]} {
  puts $errorstring
}

# Read RAMB preplacement
# read_xdc $rootDir/RAMB_placement.xdc
# Read FIFO preplacement
# read_xdc $rootDir/FIFO_placement.xdc
# Read DSP preplacement
# read_xdc $rootDir/DSP_placement.xdc

# report_timing_summary -no_detailed_paths -file $runDir/opt_design.rpt
# snapit $db $runDir $project $version $experiment [incr step].opt_design {}

# set start [clock seconds]
# opt_design -directive Explore
# # opt_design -propconst -sweep -retarget -remap
# set stop [clock seconds]
# write_checkpoint -force $runDir/postopt.dcp
# report_timing_summary -no_detailed_paths -file $runDir/postopt.rpt
# # report_timing_summary -file $runDir/postopt.rpt
# snapshot set duration [::tb::snapshot::duration [expr $stop - $start]]
# snapit $db $runDir $project $version $experiment [incr step].opt_design Explore

# catch { tclapp::install designutils }
# # convert_muxfx_to_luts [-cell <arg>] [-only_muxf8] [-help]
# ::tclapp::xilinx::designutils::convert_muxfx_to_luts

# Over-constraint the design for phys_opt_design with set_clock_uncertainty
# set_clock_uncertainty 0.300 [get_clocks clk_sys_core_pll]

# Save pre-placement checkpoint
write_checkpoint -force $runDir/preplace.dcp

set start [clock seconds]
place_design -directive $placeDirective
set stop [clock seconds]
write_checkpoint -force $runDir/postplace.dcp
report_timing_summary -no_detailed_paths -file $runDir/postplace.rpt
# report_timing_summary -file $runDir/postplace.rpt
snapshot set duration [::tb::snapshot::duration [expr $stop - $start]]
snapit $db $runDir $project $version $experiment [incr step].place_design $placeDirective

# Dump RAMB/FIFO input/output timing
generate_RAM_FIFO_timing $runDir postplace

# Export timing paths (Setup only)
set spaths [get_timing_paths -quiet -nworst 1 -max_path 1000 -slack_lesser_than 0.0 -setup]
catch { export_timing_paths $spaths postplace $runDir }

# Export cells without pblock assignment
catch { export_unpblocked_cells $runDir/unpblocked.xdc }

# Dump RAM/FIFO/DSP placement
catch { xilinx::designutils::write_loc_constraints -force -file $runDir/RAMB_placement.xdc -all_placement -of_object [get_cells -hier -filter REF_NAME=~RAMB*] }
catch { xilinx::designutils::write_loc_constraints -force -file $runDir/FIFO_placement.xdc -all_placement -of_object [get_cells -hier -filter REF_NAME=~FIFO*] }
catch { xilinx::designutils::write_loc_constraints -force -file $runDir/DSP_placement.xdc -all_placement -of_object [get_cells -hier -filter REF_NAME=~DSP48E2*] }

# set start [clock seconds]
# place_design -post_place_opt
# set stop [clock seconds]
# write_checkpoint -force $runDir/postplaceopt.dcp
# report_timing_summary -no_detailed_paths -file $runDir/postplaceopt.rpt
# # report_timing_summary -file $runDir/postplaceopt.rpt
# snapshot set duration [::tb::snapshot::duration [expr $stop - $start]]
# snapit $db $runDir $project $version $experiment [incr step].place_design_opt post_place_opt
#
# # Dump RAMB/FIFO input/output timing
# generate_RAM_FIFO_timing $runDir postplaceopt
#
# # Export timing paths (Setup only)
# set spaths [get_timing_paths -quiet -nworst 1 -max_path 1000 -slack_lesser_than 0.0 -setup]
# catch { export_timing_paths $spaths postplaceopt $runDir }

# Over-constraint the design for phys_opt_design with set_clock_uncertainty
# set_clock_uncertainty 0.300 [get_clocks clk_sys_core_pll]

# set start [clock seconds]
# phys_opt_design -directive AggressiveExplore
# set stop [clock seconds]
# # write_checkpoint -force $runDir/postphysopt.dcp
# report_timing_summary -no_detailed_paths -file $runDir/postphysopt.rpt
# snapshot set duration [::tb::snapshot::duration [expr $stop - $start]]
# snapit $db $runDir $project $version $experiment [incr step].phys_opt_design AggressiveExplore

############################
#### PhysOpt Iterations ####
############################
set wns [get_property SLACK [get_timing_paths]]
# set tns $wns
set tns [format {%.2f} [expr 0.0 [join [get_property -quiet SLACK [get_timing_paths -quiet -slack_less_than 0.0 -setup -max_paths 50]] "+"]] ]
set prevWns -1000
set prevTns -1000
set i 0
# set MAX_ITER 1
set MAX_ITER $physOptIter
# In ns
# set DELTA 0.010
set DELTA $physOptDelta
# Stop iterating if delta between previous WNS and current WNS is less than 10ps
# while {$wns < 0 && $prevWns < $wns && ([expr abs($prevWns - $wns)] > 0.01)} {}
while {($wns < 0 && $prevWns < $wns && ([expr abs($prevWns - $wns)] > $DELTA))
       || ($tns < 0 && $prevTns < $tns && ([expr abs($prevTns - $tns)] > $DELTA)) } {
  set prevWns $wns
  set prevTns $tns
  incr i
  puts "## phys_opt_design - iteration $i - SLACK: $wns - TNS: $tns ##"

  set start [clock seconds]
  if {[catch {phys_opt_design -directive AggressiveExplore} errorstring]} {
    puts "## ERROR in phys_opt_design -directive AggressiveExplore - iteration $i"
    puts $errorstring
  } else {
    set stop [clock seconds]
    write_checkpoint -force $runDir/postphysopt.dcp
#     write_checkpoint -force $runDir/postphysopt.AggressiveExplore_iter${i}.dcp
    report_timing_summary -no_detailed_paths -file $runDir/postphysopt.AggressiveExplore_iter${i}.rpt
    snapshot set duration [::tb::snapshot::duration [expr $stop - $start]]
    snapit $db $runDir $project $version $experiment [incr step].phys_opt_design AggressiveExplore
  }

  set prevWns $wns
  set prevTns $tns
  set wns [get_property SLACK [get_timing_paths]]
  set tns [format {%.2f} [expr 0.0 [join [get_property -quiet SLACK [get_timing_paths -quiet -slack_less_than 0.0 -setup -max_paths 50]] "+"]] ]
  if {($wns < 0 && $prevWns < $wns && ([expr abs($prevWns - $wns)] > $DELTA))
       || ($tns < 0 && $prevTns < $tns && ([expr abs($prevTns - $tns)] > $DELTA)) } {
    # Continue to the next phys_opt_design
  } else {
    # Stop running phys_opt_design
    break
  }

  set start [clock seconds]
  if {[catch {phys_opt_design -directive AggressiveFanoutOpt} errorstring]} {
    puts "## ERROR in phys_opt_design -directive AggressiveFanoutOpt - iteration $i"
    puts $errorstring
  } else {
    set stop [clock seconds]
    write_checkpoint -force $runDir/postphysopt.dcp
#     write_checkpoint -force $runDir/postphysopt.AggressiveFanoutOpt_iter${i}.dcp
    report_timing_summary -no_detailed_paths -file $runDir/postphysopt.AggressiveFanoutOpt_iter${i}.rpt
    snapshot set duration [::tb::snapshot::duration [expr $stop - $start]]
    snapit $db $runDir $project $version $experiment [incr step].phys_opt_design AggressiveFanoutOpt
  }

  set prevWns $wns
  set prevTns $tns
  set wns [get_property SLACK [get_timing_paths]]
  set tns [format {%.2f} [expr 0.0 [join [get_property -quiet SLACK [get_timing_paths -quiet -slack_less_than 0.0 -setup -max_paths 50]] "+"]] ]
  if {($wns < 0 && $prevWns < $wns && ([expr abs($prevWns - $wns)] > $DELTA))
       || ($tns < 0 && $prevTns < $tns && ([expr abs($prevTns - $tns)] > $DELTA)) } {
    # Continue to the next phys_opt_design
  } else {
    # Stop running phys_opt_design
    break
  }

  if {[catch {phys_opt_design -directive AlternateReplication} errorstring]} {
    puts "## ERROR in phys_opt_design -directive AlternateReplication - iteration $i"
    puts $errorstring
  } else {
    set stop [clock seconds]
    write_checkpoint -force $runDir/postphysopt.dcp
#     write_checkpoint -force $runDir/postphysopt.AlternateReplication_iter${i}.dcp
    report_timing_summary -no_detailed_paths -file $runDir/postphysopt.AlternateReplication_iter${i}.rpt
    snapshot set duration [::tb::snapshot::duration [expr $stop - $start]]
    snapit $db $runDir $project $version $experiment [incr step].phys_opt_design AlternateReplication
  }

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

# Reset set_clock_uncertainty
# set_clock_uncertainty 0 [get_clocks clk_sys_core_pll]

write_checkpoint -force $runDir/postphysopt.dcp
report_timing_summary -no_detailed_paths -file $runDir/postphysopt.rpt
# report_timing_summary -file $runDir/postphysopt.rpt

# Dump RAMB/FIFO input/output timing
generate_RAM_FIFO_timing $runDir postphysopt

# Export timing paths (Setup only)
set spaths [get_timing_paths -quiet -nworst 1 -max_path 1000 -slack_lesser_than 0.0 -setup]
catch { export_timing_paths $spaths postphysopt $runDir }

set start [clock seconds]
route_design -directive Explore -tns_cleanup
# route_design -directive Default
set stop [clock seconds]
write_checkpoint -force $runDir/postroute.dcp
report_timing_summary -no_detailed_paths -file $runDir/postroute.rpt
# report_timing_summary -file $runDir/postroute.rpt
snapshot set duration [::tb::snapshot::duration [expr $stop - $start]]
snapit $db $runDir $project $version $experiment [incr step].route_design Explore
# snapit $db $runDir $project $version $experiment [incr step].route_design Default

# Dump RAMB/FIFO input/output timing
generate_RAM_FIFO_timing $runDir postroute

# Dump SLL usage and other reports
catch { tb::report_slls -details -file $runDir/report_slls.rpt }
catch { tb::report_slr_utilization -cell [get_cells * -filter {!IS_PRIMITIVE}] -file $runDir/report_slr_utilization.rpt }
catch { tb::report_pblock_utilization -cell [get_cells * -filter {!IS_PRIMITIVE}] -file $runDir/report_pblock_utilization.rpt }

# Export timing paths (Setup only)
set spaths [get_timing_paths -quiet -nworst 1 -max_path 1000 -slack_lesser_than 0.0 -setup]
catch { export_timing_paths $spaths postroute $runDir }

#################################
#### Post-Route Optimization ####
#################################
set wns [get_property SLACK [get_timing_paths]]
if {$wns < 0} {
  set start [clock seconds]
  phys_opt_design
  set stop [clock seconds]
#   write_checkpoint -force $runDir/postrouteopt.dcp
  report_timing_summary -no_detailed_paths -file $runDir/postrouteopt.rpt
  snapshot set duration [::tb::snapshot::duration [expr $stop - $start]]
  snapit $db $runDir $project $version $experiment [incr step].phys_opt_design Default
}

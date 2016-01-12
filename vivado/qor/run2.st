<?php

$SNAPSHOT_IS_ENABLED = %{FLOW.SNAPSHOT.IS_ENABLED};
$OPT_DESIGN_IS_ENABLED = %{FLOW.OPT_DESIGN.IS_ENABLED};
$POST_PLACE_OPT_IS_ENABLED = %{FLOW.POST_PLACE_OPT.IS_ENABLED};
$POST_ROUTE_PHYS_OPT_DESIGN_IS_ENABLED = %{FLOW.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED};

?>
######################################################################
#
# Variables Initialization
#
######################################################################

set rootDir             {%{ROOTDIR}}
set runDir              {%{RUNDIR}}
# set db                  {%{ROOTDIR}/metrics.db}
set db                  $rootDir/metrics.db
set project             {%{PROJECT}}
set version             {%{VERSION}}
set experiment          {%{EXPERIMENT}}
# set checkpoint          {%{ROOTDIR}/%{CHECKPOINT}}
# set checkpoint          $rootDir/%{CHECKPOINT}
set checkpoint          {%{CHECKPOINT}}
# set floorplan           {%{ROOTDIR}/%{FLOORPLAN}}
# set floorplan           $rootDir/%{FLOORPLAN}
set floorplan           {%{FLOORPLAN}}
set optCmdLine          {%{OPT_CMDLINE}}
set placeDirective      {%{PLACE_DIRECTIVE}}
set physoptDirectives   {%{PHYSOPT_DIRECTIVES}}
set physOptMinIter      %{PHYSOPT_MIN_ITER}
set physOptMaxIter      %{PHYSOPT_MAX_ITER}
set physOptDeltaWns     %{PHYSOPT_DELTA_WNS}
set physOptDeltaTns     %{PHYSOPT_DELTA_TNS}
set routeCmdLine        {%{ROUTE_CMDLINE}}
set reportTimingCmdLine {%{REPORT_TIMING_CMDLINE}}

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

<? if ($OPT_DESIGN_IS_ENABLED != 0): ?>
set start [clock seconds]
uplevel 0 [concat opt_design $optCmdLine]
set stop [clock seconds]
write_checkpoint -force $runDir/postopt.dcp
uplevel 0 [concat report_timing_summary $reportTimingCmdLine -file $runDir/postopt.rpt ]
<? if ($SNAPSHOT_IS_ENABLED != 0): ?>
snapshot set duration [::tb::snapshot::duration [expr $stop - $start]]
snapit $db $runDir $project $version $experiment [incr step].opt_design Default
<? endif; // SNAPSHOT_IS_ENABLED ?>
<? else: // OPT_DESIGN_IS_ENABLED ?>
uplevel 0 [concat report_timing_summary $reportTimingCmdLine -file $runDir/postopt.rpt ]
<? if ($SNAPSHOT_IS_ENABLED != 0): ?>
snapit $db $runDir $project $version $experiment [incr step].opt_design Default
<? endif; // SNAPSHOT_IS_ENABLED ?>
<? endif; // OPT_DESIGN_IS_ENABLED ?>

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
uplevel 0 [concat report_timing_summary $reportTimingCmdLine -file $runDir/postplace.rpt ]
<? if ($SNAPSHOT_IS_ENABLED != 0): ?>
snapshot set duration [::tb::snapshot::duration [expr $stop - $start]]
snapit $db $runDir $project $version $experiment [incr step].place_design $placeDirective
<? endif; ?>

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

<? if ($POST_PLACE_OPT_IS_ENABLED != 0): ?>
set start [clock seconds]
place_design -post_place_opt
set stop [clock seconds]
write_checkpoint -force $runDir/postplaceopt.dcp
uplevel 0 [concat report_timing_summary $reportTimingCmdLine -file $runDir/postplaceopt.rpt ]
<? if ($SNAPSHOT_IS_ENABLED != 0): ?>
snapshot set duration [::tb::snapshot::duration [expr $stop - $start]]
snapit $db $runDir $project $version $experiment [incr step].place_design_opt post_place_opt
<? endif; // SNAPSHOT_IS_ENABLED ?>

# Dump RAMB/FIFO input/output timing
generate_RAM_FIFO_timing $runDir postplaceopt

# Export timing paths (Setup only)
set spaths [get_timing_paths -quiet -nworst 1 -max_path 1000 -slack_lesser_than 0.0 -setup]
catch { export_timing_paths $spaths postplaceopt $runDir }
<? endif; // POST_PLACE_OPT_IS_ENABLED ?>

# Over-constraint the design for phys_opt_design with set_clock_uncertainty
# set_clock_uncertainty 0.300 [get_clocks clk_sys_core_pll]

# set start [clock seconds]
# phys_opt_design -directive AggressiveExplore
# set stop [clock seconds]
# # write_checkpoint -force $runDir/postphysopt.dcp
# uplevel 0 [concat report_timing_summary $reportTimingCmdLine -file $runDir/postphysopt.rpt ]
<? if ($SNAPSHOT_IS_ENABLED != 0): ?>
# snapshot set duration [::tb::snapshot::duration [expr $stop - $start]]
# snapit $db $runDir $project $version $experiment [incr step].phys_opt_design AggressiveExplore
<? endif; ?>

############################
#### PhysOpt Iterations ####
############################
set wns [get_property SLACK [get_timing_paths]]
# set tns $wns
set tns [format {%.2f} [expr 0.0 [join [get_property -quiet SLACK [get_timing_paths -quiet -slack_less_than 0.0 -setup -max_paths 100]] "+"]] ]
set prevWns -1000
set prevTns -1000
set iter 0
set idx -1
if {[llength $physoptDirectives]} {
  set loop 1
} else {
  set loop 0
}

while {$loop} {
  set prevWns $wns
  set prevTns $tns
  incr iter
  incr idx
  if {$idx >= [llength $physoptDirectives]} { set idx 0 }
  set directive [lindex $physoptDirectives $idx]
  puts "## phys_opt_design - iteration $iter - SLACK: $wns - TNS: $tns ##"
  puts "## phys_opt_design - iteration $iter - Directive: $directive ##"

  set start [clock seconds]
  if {[catch {phys_opt_design -directive $directive} errorstring]} {
    puts "## ERROR in phys_opt_design -directive $directive - iteration $iter"
    puts $errorstring
  } else {
    set stop [clock seconds]
    write_checkpoint -force $runDir/postphysopt.dcp
#     write_checkpoint -force $runDir/postphysopt.${directive}_iter${iter}.dcp
    uplevel 0 [concat report_timing_summary $reportTimingCmdLine -file $runDir/postphysopt.${directive}_iter${iter}.rpt ]
<? if ($SNAPSHOT_IS_ENABLED != 0): ?>
    snapshot set duration [::tb::snapshot::duration [expr $stop - $start]]
    snapit $db $runDir $project $version $experiment [incr step].phys_opt_design $directive
<? endif; ?>
  }

  if {$iter < $physOptMinIter} {
    puts "## phys_opt_design - Delta WNS: [expr abs($prevWns - $wns)] / WNS: $wns / Previous WNS: $prevWns ##"
    puts "## phys_opt_design - Delta TNS: [expr abs($prevTns - $tns)] / TNS: $tns / Previous TNS: $prevTns ##"
    puts "## phys_opt_design - iteration $iter - SLACK: $wns - TNS: $tns ##"
    # Continue if the minimum number of iterations has not been reached
    continue
  }

  set prevWns $wns
  set prevTns $tns
  set wns [get_property SLACK [get_timing_paths]]
  set tns [format {%.2f} [expr 0.0 [join [get_property -quiet SLACK [get_timing_paths -quiet -slack_less_than 0.0 -setup -max_paths 100]] "+"]] ]
  if {($wns < 0 && $prevWns < $wns && ([expr abs($prevWns - $wns)] > $physOptDeltaWns))
       || ($tns < 0 && $prevTns < $tns && ([expr abs($prevTns - $tns)] > $physOptDeltaTns)) } {
    # Continue to the next phys_opt_design
  } else {
    # Stop running phys_opt_design
    puts "## phys_opt_design - WNS/TNS delta limit reach. Exiting phys_opt_design loop ##"
    puts "## phys_opt_design - Delta WNS: [expr abs($prevWns - $wns)] / WNS: $wns / Previous WNS: $prevWns ##"
    puts "## phys_opt_design - Delta TNS: [expr abs($prevTns - $tns)] / TNS: $tns / Previous TNS: $prevTns ##"
    puts "## phys_opt_design - iteration $iter - SLACK: $wns - TNS: $tns ##"
    set loop 0
    break
  }

  if {$iter >= $physOptMaxIter} {
    # Stop if the maximum number of iterations has been reached
    puts "## phys_opt_design - Max iterations ($physOptMaxIter) reached. Exiting phys_opt_design loop ##"
    puts "## phys_opt_design - iteration $iter - SLACK: $wns - TNS: $tns ##"
    set loop 0
    break
  }

  puts "## phys_opt_design - Delta WNS: [expr abs($prevWns - $wns)] / WNS: $wns / Previous WNS: $prevWns ##"
  puts "## phys_opt_design - Delta TNS: [expr abs($prevTns - $tns)] / TNS: $tns / Previous TNS: $prevTns ##"
  puts "## phys_opt_design - iteration $iter - SLACK: $wns - TNS: $tns ##"

}
############################

# Reset set_clock_uncertainty
# set_clock_uncertainty 0 [get_clocks clk_sys_core_pll]

write_checkpoint -force $runDir/postphysopt.dcp
uplevel 0 [concat report_timing_summary $reportTimingCmdLine -file $runDir/postphysopt.rpt ]

# Dump RAMB/FIFO input/output timing
generate_RAM_FIFO_timing $runDir postphysopt

# Export timing paths (Setup only)
set spaths [get_timing_paths -quiet -nworst 1 -max_path 1000 -slack_lesser_than 0.0 -setup]
catch { export_timing_paths $spaths postphysopt $runDir }

set start [clock seconds]
uplevel 0 [concat route_design $routeCmdLine]
# route_design -directive Explore -tns_cleanup
# route_design -directive Default
set stop [clock seconds]
write_checkpoint -force $runDir/postroute.dcp
uplevel 0 [concat report_timing_summary $reportTimingCmdLine -file $runDir/postroute.rpt ]
<? if ($SNAPSHOT_IS_ENABLED != 0): ?>
snapshot set duration [::tb::snapshot::duration [expr $stop - $start]]
snapit $db $runDir $project $version $experiment [incr step].route_design Explore
# snapit $db $runDir $project $version $experiment [incr step].route_design Default
<? endif; ?>

# Dump RAMB/FIFO input/output timing
generate_RAM_FIFO_timing $runDir postroute

# Dump SLL usage and other reports
catch { tb::report_slls -details -file $runDir/report_slls.rpt }
catch { tb::report_slr_utilization -cell [get_cells * -filter {!IS_PRIMITIVE}] -file $runDir/report_slr_utilization.rpt }
catch { tb::report_pblock_utilization -cell [get_cells * -filter {!IS_PRIMITIVE}] -file $runDir/report_pblock_utilization.rpt }

# Export timing paths (Setup only)
set spaths [get_timing_paths -quiet -nworst 1 -max_path 1000 -slack_lesser_than 0.0 -setup]
catch { export_timing_paths $spaths postroute $runDir }

<? if ($POST_ROUTE_PHYS_OPT_DESIGN_IS_ENABLED != 0): ?>
#################################
#### Post-Route Optimization ####
#################################
set wns [get_property SLACK [get_timing_paths]]
if {$wns < 0} {
  set start [clock seconds]
  phys_opt_design
  set stop [clock seconds]
#   write_checkpoint -force $runDir/postrouteopt.dcp
  uplevel 0 [concat report_timing_summary $reportTimingCmdLine -file $runDir/postrouteopt.rpt ]
<? if ($SNAPSHOT_IS_ENABLED != 0): ?>
  snapshot set duration [::tb::snapshot::duration [expr $stop - $start]]
  snapit $db $runDir $project $version $experiment [incr step].phys_opt_design Default
<? endif; ?>
}
<? endif; // POST_ROUTE_PHYS_OPT_DESIGN_IS_ENABLED ?>

# From John Bieker

##############################################################################
# Enter Project Specific Data Below

# Set host list to list of hostnames if using multiple machines ie {hostname1 hostname2}
set hostlist {xcoapps58 xcoapps59 xcoapps60 xcoapps58 xcoapps59 xcoapps60 xcoapps58 xcoapps59 xcoapps60 xcoapps58 xcoapps59 xcoapps60 xcoapps58 xcoapps59 xcoapps60 }

set root_dir /group/bcapps/jbieker/ciena/drop_082316/sem1
set synth_checkpoint   ${root_dir}/synth.dcp
set opt_checkpoint   ${root_dir}/opt_design.dcp
set pre_place_script ${root_dir}/tcl/pre_place1.tcl
set popt_loop_script ${root_dir}/tcl/popt_loop.tcl

set tool_version 2016.3_0908_1

set directive_list [list Default WLDrivenBlockPlacement EarlyBlockPlacement Explore ExtraNetDelay_high ExtraPostPlacementOpt AltSpreadLogic_high]
#set directive_list [list Explore ExtraNetDelay_high SpreadLogic_high SpreadLogic_medium ExtraPostPlacementOpt Default SSI_SpreadSLLs SSI_BalanceSLLs SSI_BalanceSLRs SSI_HighUtilSLRs WLDrivenBlockPlacement ]
#set directive_list [list AltWLDrivenPlacement Default Explore ExtraNetDelay_high ExtraNetDelay_low SpreadLogic_high SpreadLogic_low SSI_SpreadSLLs SSI_BalanceSLLs SSI_BalanceSLRs SSI_HighUtilSLRs WLDrivenBlockPlacement ]
##############################################################################

set mydir [pwd]
puts stdout "current directory: $mydir"

# If the number of hosts is less than the number of directives to be run, extend $hostlist by copying the first hostname over and over until the
# number of directives matches the number of hosts
if "[llength $hostlist] < [llength $directive_list]" {
  for {set j 0} {$j < [expr [llength $directive_list] - [llength $hostlist]]} {} {
    lappend hostlist [lindex $hostlist 0]
  }
}

 set i 1
 set xt_vpos 15
 set xt_vpos_incr 25
 set xt_hpos 0
 set xt_hpos_incr 40

 puts $directive_list
 foreach place_directive $directive_list {
   puts "$i: $place_directive"
   # Create subdirectory if it does not exist then cd to it.
   if {[file exists $place_directive] == 1} {
     cd $place_directive
   } else {
     file mkdir $place_directive
     cd $place_directive
   }

   # generate script file
   set fileId [open $place_directive.tcl w]
   puts $fileId "\nopen_checkpoint $opt_checkpoint"
   puts $fileId "opt_design -directive Explore"
   puts $fileId "opt_design -control_set_merge -hier_fanout_limit 512"
   #puts $fileId "report_timing_summary -file opt_tim.rpt"
   puts $fileId "source $pre_place_script"
   puts $fileId "place_design -fanout_opt -directive $place_directive"
   puts $fileId "report_timing_summary -file placed_tim.rpt"
   puts $fileId "write_checkpoint -force placed.dcp"
   puts $fileId "source $popt_loop_script"
   close $fileId

   # Launch XTERM and run Vivado in batch mode with script
   if {$env(RDI_PLATFORM) == "win64"} {
     cmd /c "vivado -mode batch -source $place_directive.tcl" &
     after 500
     incr i
     cd ..
   } else {
     set xtitle "$place_directive"
     set fileId [open remote.csh w]
     if {[regexp -lineanchor "^\:" $env(DISPLAY)]} {
       set display $env(HOSTNAME)$env(DISPLAY)
     } else {
       set display $env(DISPLAY)
     }
     puts $fileId "setenv DISPLAY $display"
     puts $fileId "m1 -vivado $tool_version"
     puts $fileId "cd $mydir/$place_directive"
     puts $fileId "xterm -title $xtitle -sb -sl 8192 -geometry 150x25+$xt_vpos+$xt_hpos -e vivado -mode batch -source $place_directive.tcl"
     close $fileId
     exec ssh [lindex $hostlist [expr $i-1]] "source $mydir/$place_directive/remote.csh" &
     after 500
     incr i
     incr xt_vpos $xt_vpos_incr
     incr xt_hpos $xt_hpos_incr
     cd ..
   }
 }

exit

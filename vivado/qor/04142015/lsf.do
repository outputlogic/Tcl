#!/bin/sh
# use -*-TCL-*- \
exec tclsh "$0" "$@"

set WDIR [file dirname [file normalize [info script]]]
if {[file exists $WDIR/lsf.pid]} {
  puts " -I- file $WDIR/lsf.pid exists. Some jobs could be running. Run lsf.check to get the job status"
  exit 0
}

#  RuntimeOptimized       \

set lsfjobs [list]

foreach dir [list \
 Default                \
 WLDrivenBlockPlacement \
 SpreadLogic_medium     \
 SpreadLogic_low        \
 LateBlockPlacement     \
 SpreadLogic_high       \
 ExtraNetDelay_high     \
 ExtraNetDelay_low      \
 Explore                \
 ExtraNetDelay_medium   \
 ExtraPostPlacementOpt  \
 SSI_HighUtilSLRs       \
 ] {
  puts "bsub -P swapps_2013.x -app sil_rhel5 -o /dev/null -q long -R \"rusage\[mem=12000\]\" vivado -mode batch -source WORKINGDIR/$dir/run.tcl -log WORKINGDIR/$dir/run.log -jou WORKINGDIR/$dir/run.jou"
  set res [exec bsub -P swapps_2013.x -app sil_rhel5 -o /dev/null -q long -R {rusage[mem=12000]} vivado -mode batch -source WORKINGDIR/$dir/run.tcl -log WORKINGDIR/$dir/run.log -jou WORKINGDIR/$dir/run.jou ]
  if {[regexp {\<([0-9]+)\>} $res -- job]} {
    puts " => LSF Job: $job"
    lappend lsfjobs $job
  }
}

exec sleep 20

# set res [uplevel #0 [concat exec bjobs -w $lsfjobs]]
if {[catch { set res [uplevel #0 [concat exec bjobs -w $lsfjobs]] } errorstring]} {
  puts "ERROR - $errorstring"
}

set FH [open ./lsf.pid a]
puts $FH $res
close $FH

exit 0

bsub -P swapps_2013.x -app sil_rhel5 -o /dev/null -q long -R "rusage[mem=12000]" vivado -mode batch -source WORKINGDIR/Default/run.tcl -log WORKINGDIR/Default/run.log -jou WORKINGDIR/Default/run.jou
bsub -P swapps_2013.x -app sil_rhel5 -o /dev/null -q long -R "rusage[mem=12000]" vivado -mode batch -source WORKINGDIR/WLDrivenBlockPlacement/run.tcl -log WORKINGDIR/WLDrivenBlockPlacement/run.log -jou WORKINGDIR/WLDrivenBlockPlacement/run.jou
bsub -P swapps_2013.x -app sil_rhel5 -o /dev/null -q long -R "rusage[mem=12000]" vivado -mode batch -source WORKINGDIR/SpreadLogic_medium/run.tcl -log WORKINGDIR/SpreadLogic_medium/run.log -jou WORKINGDIR/SpreadLogic_medium/run.jou
bsub -P swapps_2013.x -app sil_rhel5 -o /dev/null -q long -R "rusage[mem=12000]" vivado -mode batch -source WORKINGDIR/SpreadLogic_low/run.tcl -log WORKINGDIR/SpreadLogic_low/run.log -jou WORKINGDIR/SpreadLogic_low/run.jou
bsub -P swapps_2013.x -app sil_rhel5 -o /dev/null -q long -R "rusage[mem=12000]" vivado -mode batch -source WORKINGDIR/LateBlockPlacement/run.tcl -log WORKINGDIR/LateBlockPlacement/run.log -jou WORKINGDIR/LateBlockPlacement/run.jou
bsub -P swapps_2013.x -app sil_rhel5 -o /dev/null -q long -R "rusage[mem=12000]" vivado -mode batch -source WORKINGDIR/SpreadLogic_high/run.tcl -log WORKINGDIR/SpreadLogic_high/run.log -jou WORKINGDIR/SpreadLogic_high/run.jou
bsub -P swapps_2013.x -app sil_rhel5 -o /dev/null -q long -R "rusage[mem=12000]" vivado -mode batch -source WORKINGDIR/ExtraNetDelay_high/run.tcl -log WORKINGDIR/ExtraNetDelay_high/run.log -jou WORKINGDIR/ExtraNetDelay_high/run.jou
bsub -P swapps_2013.x -app sil_rhel5 -o /dev/null -q long -R "rusage[mem=12000]" vivado -mode batch -source WORKINGDIR/ExtraNetDelay_low/run.tcl -log WORKINGDIR/ExtraNetDelay_low/run.log -jou WORKINGDIR/ExtraNetDelay_low/run.jou
bsub -P swapps_2013.x -app sil_rhel5 -o /dev/null -q long -R "rusage[mem=12000]" vivado -mode batch -source WORKINGDIR/Explore/run.tcl -log WORKINGDIR/Explore/run.log -jou WORKINGDIR/Explore/run.jou
bsub -P swapps_2013.x -app sil_rhel5 -o /dev/null -q long -R "rusage[mem=12000]" vivado -mode batch -source WORKINGDIR/ExtraNetDelay_medium/run.tcl -log WORKINGDIR/ExtraNetDelay_medium/run.log -jou WORKINGDIR/ExtraNetDelay_medium/run.jou
bsub -P swapps_2013.x -app sil_rhel5 -o /dev/null -q long -R "rusage[mem=12000]" vivado -mode batch -source WORKINGDIR/ExtraPostPlacementOpt/run.tcl -log WORKINGDIR/ExtraPostPlacementOpt/run.log -jou WORKINGDIR/ExtraPostPlacementOpt/run.jou
bsub -P swapps_2013.x -app sil_rhel5 -o /dev/null -q long -R "rusage[mem=12000]" vivado -mode batch -source WORKINGDIR/SSI_HighUtilSLRs/run.tcl -log WORKINGDIR/SSI_HighUtilSLRs/run.log -jou WORKINGDIR/SSI_HighUtilSLRs/run.jou


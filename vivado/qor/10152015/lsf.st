#!/bin/sh
# use -*-TCL-*- \
exec tclsh "$0" "$@"

set WDIR [file dirname [file normalize [info script]]]
if {[file exists $WDIR/lsf.pid]} {
  puts " -I- file $WDIR/lsf.pid already exists. Some jobs could be running. Run lsf.check to get the job status"
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
  puts "bsub -P swapps_2013.x -app sil_rhel5 -o /dev/null -q long -R \"rusage\[mem=%{MEMORY}\]\" vivado -mode batch -source %{ROOTDIR}/$dir/run.tcl -log %{ROOTDIR}/$dir/run.log -jou %{ROOTDIR}/$dir/run.jou"
  set res [exec bsub -P swapps_2013.x -app sil_rhel5 -o /dev/null -q long -R {rusage[mem=%{MEMORY}]} vivado -mode batch -source %{ROOTDIR}/$dir/run.tcl -log %{ROOTDIR}/$dir/run.log -jou %{ROOTDIR}/$dir/run.jou ]
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

bsub -P swapps_2013.x -app sil_rhel5 -o /dev/null -q long -R "rusage[mem=%{MEMORY}]" vivado -mode batch -source %{ROOTDIR}/Default/run.tcl -log %{ROOTDIR}/Default/run.log -jou %{ROOTDIR}/Default/run.jou
bsub -P swapps_2013.x -app sil_rhel5 -o /dev/null -q long -R "rusage[mem=%{MEMORY}]" vivado -mode batch -source %{ROOTDIR}/WLDrivenBlockPlacement/run.tcl -log %{ROOTDIR}/WLDrivenBlockPlacement/run.log -jou %{ROOTDIR}/WLDrivenBlockPlacement/run.jou
bsub -P swapps_2013.x -app sil_rhel5 -o /dev/null -q long -R "rusage[mem=%{MEMORY}]" vivado -mode batch -source %{ROOTDIR}/SpreadLogic_medium/run.tcl -log %{ROOTDIR}/SpreadLogic_medium/run.log -jou %{ROOTDIR}/SpreadLogic_medium/run.jou
bsub -P swapps_2013.x -app sil_rhel5 -o /dev/null -q long -R "rusage[mem=%{MEMORY}]" vivado -mode batch -source %{ROOTDIR}/SpreadLogic_low/run.tcl -log %{ROOTDIR}/SpreadLogic_low/run.log -jou %{ROOTDIR}/SpreadLogic_low/run.jou
bsub -P swapps_2013.x -app sil_rhel5 -o /dev/null -q long -R "rusage[mem=%{MEMORY}]" vivado -mode batch -source %{ROOTDIR}/LateBlockPlacement/run.tcl -log %{ROOTDIR}/LateBlockPlacement/run.log -jou %{ROOTDIR}/LateBlockPlacement/run.jou
bsub -P swapps_2013.x -app sil_rhel5 -o /dev/null -q long -R "rusage[mem=%{MEMORY}]" vivado -mode batch -source %{ROOTDIR}/SpreadLogic_high/run.tcl -log %{ROOTDIR}/SpreadLogic_high/run.log -jou %{ROOTDIR}/SpreadLogic_high/run.jou
bsub -P swapps_2013.x -app sil_rhel5 -o /dev/null -q long -R "rusage[mem=%{MEMORY}]" vivado -mode batch -source %{ROOTDIR}/ExtraNetDelay_high/run.tcl -log %{ROOTDIR}/ExtraNetDelay_high/run.log -jou %{ROOTDIR}/ExtraNetDelay_high/run.jou
bsub -P swapps_2013.x -app sil_rhel5 -o /dev/null -q long -R "rusage[mem=%{MEMORY}]" vivado -mode batch -source %{ROOTDIR}/ExtraNetDelay_low/run.tcl -log %{ROOTDIR}/ExtraNetDelay_low/run.log -jou %{ROOTDIR}/ExtraNetDelay_low/run.jou
bsub -P swapps_2013.x -app sil_rhel5 -o /dev/null -q long -R "rusage[mem=%{MEMORY}]" vivado -mode batch -source %{ROOTDIR}/Explore/run.tcl -log %{ROOTDIR}/Explore/run.log -jou %{ROOTDIR}/Explore/run.jou
bsub -P swapps_2013.x -app sil_rhel5 -o /dev/null -q long -R "rusage[mem=%{MEMORY}]" vivado -mode batch -source %{ROOTDIR}/ExtraNetDelay_medium/run.tcl -log %{ROOTDIR}/ExtraNetDelay_medium/run.log -jou %{ROOTDIR}/ExtraNetDelay_medium/run.jou
bsub -P swapps_2013.x -app sil_rhel5 -o /dev/null -q long -R "rusage[mem=%{MEMORY}]" vivado -mode batch -source %{ROOTDIR}/ExtraPostPlacementOpt/run.tcl -log %{ROOTDIR}/ExtraPostPlacementOpt/run.log -jou %{ROOTDIR}/ExtraPostPlacementOpt/run.jou
bsub -P swapps_2013.x -app sil_rhel5 -o /dev/null -q long -R "rusage[mem=%{MEMORY}]" vivado -mode batch -source %{ROOTDIR}/SSI_HighUtilSLRs/run.tcl -log %{ROOTDIR}/SSI_HighUtilSLRs/run.log -jou %{ROOTDIR}/SSI_HighUtilSLRs/run.jou

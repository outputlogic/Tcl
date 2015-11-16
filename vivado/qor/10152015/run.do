#!/bin/sh
# use -*-TCL-*- \
exec tclsh "$0" "$@"

# set WDIR [pwd]
set WDIR [file dirname [file normalize [info script]]]
set VERSION [lindex [file split $WDIR] end-1]
set PROJECT {Default}
set EXPERIMENT [lindex [file split $WDIR] end]

#### lsf.do

set FH [open lsf.do r]
set script [read $FH]
close $FH
set script [regsub -all ROOTDIR $script [pwd]]
set FH [open lsf.do w]
puts $FH $script
close $FH

#### run.tmpl

set FH [open run.tmpl r]
set script [read $FH]
close $FH

#  RuntimeOptimized       \

foreach directive [list \
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
  set EXPERIMENT [lindex [file split $WDIR] end].${directive}
  set dir $directive
  set res [regsub -all VERSION $script $VERSION]
  set res [regsub -all PROJECT $res $PROJECT]
  set res [regsub -all EXPERIMENT $res $EXPERIMENT.$dir]
  set res [regsub -all RUNDIR $res $WDIR/$dir]
  set res [regsub -all ROOTDIR $res $WDIR]
  set res [regsub -all CHECKPOINT $res $WDIR/htg740_top_opt.dcp]
  set res [regsub -all PLACE_DIRECTIVE $res $directive]
  file mkdir $dir
  set FH [open $dir/run.tcl w]
  puts $FH $res
  close $FH
}

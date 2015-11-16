#!/bin/sh
# use -*-TCL-*- \
exec tclsh "$0" "$@"

set WDIR [file dirname [file normalize [info script]]]
set DROPDIR [lindex [file split $WDIR] end-1]
set EXPDIR [lindex [file split $WDIR] end]


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
  set dir $directive
  set res [regsub -all DROPDIR $script $DROPDIR]
  set res [regsub -all EXPDIR $res $EXPDIR]
  set res [regsub -all DIRECTORY $res [pwd]/$dir]
  set res [regsub -all ROOTDIR $res [pwd]]
  set res [regsub -all CHECKPOINT $res [pwd]/htg740_top_opt.dcp]
  set res [regsub -all PLACE_DIRECTIVE $res $directive]
  file mkdir $dir
  set FH [open $dir/run.tcl w]
  puts $FH $res
  close $FH
}

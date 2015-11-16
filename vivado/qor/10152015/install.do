#!/bin/sh
# use -*-TCL-*- \
exec tclsh "$0" "$@"

# Checkpoint inside working directory
set CHECKPOINT {htg740_top_opt.dcp}

# set WDIR [pwd]
set WDIR [file dirname [file normalize [info script]]]
set VERSION [lindex [file split $WDIR] end-1]
set PROJECT {Default}
set EXPERIMENT [lindex [file split $WDIR] end]


# Generate lsf.do
# exec smtpl -i ${WDIR}/lsf.st -o ${WDIR}/lsf.do -MEMORY=12000 -ROOTDIR=$WDIR
exec smtpl -i ${WDIR}/lsf.st -o ${WDIR}/lsf.start -force -MEMORY=12000 -ROOTDIR=$WDIR
exec chmod +x ${WDIR}/lsf.start
puts " File ${WDIR}/lsf.do generated"

# Generate all run.tcl

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
  file mkdir $dir
  set EXPERIMENT [lindex [file split $WDIR] end].${directive}
  exec smtpl -i ${WDIR}/run.st -o ${WDIR}/$dir/run.tcl -force -ROOTDIR=$WDIR -RUNDIR=$WDIR/$dir -CHECKPOINT=$WDIR/$CHECKPOINT -PLACE_DIRECTIVE=$dir -VERSION=$VERSION -PROJECT=$PROJECT -EXPERIMENT=$EXPERIMENT
  puts " File ${WDIR}/$dir/run.tcl generated"
}

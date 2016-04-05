#!/bin/sh
# use -*-TCL-*- \
exec tclsh "$0" ${1+"$@"}

set DEBUG 0

proc init {} {
  # Checkpoint inside working directory
  # set CHECKPOINT {top.dcp}
  set CHECKPOINT [pwd]/x_top.dcp

  # set VERSION [lindex [file split $::WDIR] end-1]
  set VERSION {Default}
  set PROJECT {Default}
  # set EXPERIMENT [lindex [file split $WDIR] end]
  set EXPERIMENT {Default}
  # set FLOORPLAN {pblocks.xdc}
  set FLOORPLAN [pwd]/pblocks.xdc

  set LSF_MEMORY 20000
  set RUN_SCRIPT_INCLUDE {}

  # Default list of all directives
  set DIRECTIVES [list \
   Default                \
   WLDrivenBlockPlacement \
   AltWLDrivenPlacement   \
   SpreadLogic_high       \
   SpreadLogic_medium     \
   SpreadLogic_low        \
   AltSpreadLogic_high    \
   AltSpreadLogic_medium  \
   AltSpreadLogic_low     \
   LateBlockPlacement     \
   ExtraNetDelay_high     \
   ExtraNetDelay_medium   \
   ExtraNetDelay_low      \
   Explore                \
   ExtraPostPlacementOpt  \
   SSI_HighUtilSLRs       \
   SSI_ExtraTimingOpt     \
   SSI_SpreadSLLs         \
   SSI_BalanceSLLs        \
   SSI_BalanceSLRs        \
   RuntimeOptimized       \
   Quick                  \
   ]

  iterator PLACE_DIRECTIVE $DIRECTIVES

}

proc main { {scriptname run.st} } {
  global WDIR
  global CONFIG_VARS

  if {![file exists $scriptname]} {
    puts " -E- File '$scriptname' does not exist"
    return -code ok
  }

  catch {unset CONFIG_VARS}
  set CONFIG_VARS(_) [list {} {}]

  # set WDIR [pwd]
  set WDIR [file dirname [file normalize [info script]]]

  # Override the 'set' command to save defined Tcl variables inside the
  # array 'CONFIG_VARS'
  rename set setTCL
  proc set { var value } { global CONFIG_VARS ; setTCL CONFIG_VARS($var) $value ; uplevel 1 [list setTCL $var $value ] }
  proc iterator  {name value } { global CONFIG_VARS ; setTCL CONFIG_VARS(_) [list $name $value] }

  # Define the default variables
  init

  if {[file exists $WDIR/install.cfg]} {
    puts " Sourcing configuration file '[file normalize $WDIR/install.cfg]'"
    source $WDIR/install.cfg
  }

  # Is there a script specific configuration file?
  if {[file exists [file rootname $scriptname].cfg]} {
    puts " Sourcing configuration file '[file normalize [file rootname $scriptname].cfg]'"
    source [file rootname $scriptname].cfg
  }

  # Restore the original 'set' command
  rename set {}
  rename setTCL set

  if {$::DEBUG} { parray CONFIG_VARS }

  # Append all variables that have been defined inside the command line arguments
  set arguments [list]
  set arguments [list -ROOTDIR=$WDIR ]
  foreach key [array names CONFIG_VARS] {
    # Skip the iterator
    if {$key == {_}} { continue }
    lappend arguments [format {-%s=%s} $key $CONFIG_VARS($key)]
  }

  if {$::DEBUG} {
    puts " -D- arguments: $arguments"
  }

  # Generate all run.tcl scripts inside their own directory
  set iterName [lindex $CONFIG_VARS(_) 0]
  set iterValues [lindex $CONFIG_VARS(_) 1]
  foreach iter $iterValues {
    set dir $iter
    file mkdir $dir
    set EXPERIMENT [lindex [file split $WDIR] end].${iter}
    uplevel #0 [linsert \
                        [linsert $arguments 0 exec smtpl -i ${WDIR}/$scriptname \
                                                         -o ${WDIR}/$dir/run.tcl \
                                                         -opp ${WDIR}/$dir/run.php \
                                                         -force ] \
                        end \
                        -$iterName=$iter \
                        -EXPERIMENT=$EXPERIMENT \
                        -RUNDIR=$WDIR/$dir \
                        -ROOTDIR=$WDIR ]
#     exec smtpl -i ${WDIR}/run.st \
#                -o ${WDIR}/$dir/run.tcl \
#                -opp ${WDIR}/$dir/run.php \
#                -force \
#                -ROOTDIR=$WDIR \
#                -RUN_SCRIPT_INCLUDE=$RUN_SCRIPT_INCLUDE \
#                -RUNDIR=$WDIR/$dir \
#                -FLOORPLAN=$WDIR/$FLOORPLAN \
#                -CHECKPOINT=$WDIR/$CHECKPOINT \
#                -PLACE_DIRECTIVE=$dir \
#                -VERSION=$VERSION \
#                -PROJECT=$PROJECT \
#                -EXPERIMENT=$EXPERIMENT
    puts " File ${WDIR}/$dir/run.tcl generated"
  }

  # Generate lsf.do
  uplevel #0 [linsert $arguments 0 exec smtpl -i ${WDIR}/lsf.st \
                                              -o ${WDIR}/lsf.do \
                                              -force \
                                              -ROOTDIR=$WDIR ]
#   exec smtpl -i ${WDIR}/lsf.st \
#              -o ${WDIR}/lsf.do \
#              -force \
#              -MEMORY=$LSF_MEMORY \
#              -ROOTDIR=$WDIR \
#              -DIRECTIVES=$DIRECTIVES
  exec chmod +x ${WDIR}/lsf.do
  puts " File ${WDIR}/lsf.do generated"

  # Generate clean.do
  uplevel #0 [linsert $arguments 0 exec smtpl -i ${WDIR}/clean.st \
                                              -o ${WDIR}/clean.do \
                                              -force ]
#   exec smtpl -i ${WDIR}/clean.st \
#              -o ${WDIR}/clean.do \
#              -force \
#              -DIRECTIVES=$DIRECTIVES
  exec chmod +x ${WDIR}/clean.do
  puts " File ${WDIR}/clean.do generated"

  return -code ok
}

if {[llength $argv] == 1} {
  set filename1 $argv
  set filename2 ${filename1}.st
  # 'run' should match 'run.st'
  if {![file exists $filename1] && [file exists $filename2]} {
    set filename $filename2
  } else {
    set filename $filename1
  }
  if {![file exists $filename]} {
    puts " -E- File '$filename' does not exist"
    exit 1
  }
  puts " -I- Using script $filename"
  # Call main proc
  main $filename
} else {
  # Call main proc
  main run.st
}

exit 0

#    *  Explore - Increased placer effort in detail placement and
#       post-placement optimization.
#
#    *  WLDrivenBlockPlacement - Wire length-driven placement of RAM and DSP
#       blocks. Override timing-driven placement by directing the Vivado placer
#       to minimize the distance of connections to and from blocks.
#
#    *  AltWLDrivenPlacement - The Vivado placer may increase wire length, or
#       the cumulative distance between connected cells, in order to place
#       related logic placement within physical boundaries such as clock
#       regions or IO column crossings. This directive gives higher priority to
#       minimizing wire length.
#
#       Note: This directive is for use with UltraScale devices only
#
#    *  ExtraNetDelay_high - Increases estimated delay of high fanout and
#       long-distance nets. Three levels of pessimism are supported: high,
#       medium, and low. ExtraNetDelay_high applies the highest level of
#       pessimism.
#
#    *  ExtraNetDelay_medium - Increases estimated delay of high fanout and
#       long-distance nets. Three levels of pessimism are supported: high,
#       medium, and low. ExtraNetDelay_medium applies the default level of
#       pessimism.
#
#    *  ExtraNetDelay_low - Increases estimated delay of high fanout and
#       long-distance nets. Three levels of pessimism are supported: high,
#       medium, and low. ExtraNetDelay_low applies the lowest level of
#       pessimism.
#
#    *  SpreadLogic_high - Distribute logic across the device. Three levels are
#       supported: high, medium, and low. SpreadLogic_high achieves the highest
#       level of distribution.
#
#    *  SpreadLogic_medium - Distribute logic across the device. Three levels
#       are supported: high, medium, and low. SpreadLogic_medium achieves a
#       nominal level of distribution.
#
#    *  SpreadLogic_low - Distribute logic across the device. Three levels are
#       supported: high, medium, and low. SpreadLogic_low achieves a minimal
#       level of distribution.
#
#    *  AltSpreadLogic_high - (UltraScale only) Spreads logic throughout the
#       device to avoid creating congested regions using algorithms created
#       specifically for UltraScale target devices. Three levels are supported:
#       high, medium, and low. AltSpreadLogic_high achieves the highest level
#       of spreading.
#
#    *  AltSpreadLogic_medium - (UltraScale only) Spreads logic throughout the
#       device to avoid creating congested regions using algorithms created
#       specifically for UltraScale target devices. Three levels are supported:
#       high, medium, and low. AltSpreadLogic_medium achieves a medium level of
#       spreading compared to low and high.
#
#    *  AltSpreadLogic_low - (UltraScale only) Spreads logic throughout the
#       device to avoid creating congested regions using algorithms created
#       specifically for UltraScale target devices. Three levels are supported:
#       high, medium, and low. AltSpreadLogic_low achieves the lowest level of
#       spreading.
#
#    *  ExtraPostPlacementOpt - Increased placer effort in post-placement
#       optimization.
#
#    *  SSI_ExtraTimingOpt - Use an alternate algorithm for timing-driven
#       partitioning across SLRs.
#
#    *  SSI_SpreadSLLs - Partition across SLRs and allocate extra area for
#       regions of higher connectivity.
#
#    *  SSI_BalanceSLLs - Partition across SLRs while attempting to balance
#       SLLs between SLRs.
#
#    *  SSI_BalanceSLRs - Partition across SLRs to balance number of cells
#       between SLRs.
#
#    *  SSI_HighUtilSLRs - Direct the placer to attempt to place logic closer
#       together in each SLR.
#
#    *  RuntimeOptimized - Run fewest iterations, trade higher design
#       performance for faster runtime.
#
#    *  Quick - Absolute, fastest runtime, non-timing-driven, performs the
#       minimum required placement for a legal design.
#
#    *  Default - Run place_design with default settings.

#!/bin/sh
# Run smtpl from the users PATH \
exec ./smtpl -offset $LINENO -i "$0" ${1+"$@"} --CHECKPOINT=fdsfds

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

snapshot configure -db %{ROOTDIR}/metrics.db -project %{PROJECT} -version %{VERSION} -experiment $experiment -step $step

set experiment %{EXPERIMENT}

if {[catch {open_checkpoint %{CHECKPOINT}}]} {
  # If open_checkpoint failed (NFS issue?), try a second time
  open_checkpoint %{CHECKPOINT}
}

delete_pblock [get_pblocks]
read_xdc %{ROOTDIR}/floorplan.xdc

report_timing_summary -no_detailed_paths -file %{RUNDIR}/postopt.rpt

place_design -directive %{PLACE_DIRECTIVE}

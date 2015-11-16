#!/bin/csh 
setenv DISPLAY xsjrdevl18:5
setenv VIVADO_HOME /proj/xbuilds/2013.3_INT_0919_1/installs/lin64/Vivado/2013.3/bin
cd /wrk/hdstaff/dpefour/designs/alu/drop_09_18
set_v_head
xterm -title Explore__AggressiveExplore__ExtraNetDelay_medium -sb -sl 8192 -geometry 150x25+95+60 -e ${VIVADO_HOME}/vivado -mode tcl
# xterm -title Explore__AggressiveExplore__ExtraNetDelay_medium -sb -sl 8192 -geometry 150x25+95+60 -e vivado -mode batch -source run.tcl

# Start Xterm from current machine:
#   nice -n 5 xterm -title Explore__AggressiveExplore__ExtraNetDelay_medium -sb -sl 8192 -geometry 150x25+95+60 -e vivado -mode tcl
#   exec nice -n 5 xterm -title $xtitle -sb -sl 8192 -geometry 150x25+$xt_vpos+$xt_hpos -e "vivado -mode batch -source $place_directive.tcl" &
# Start Xterm from remote machine:
#   ssh xsjrdevl18 source ~/git/scripts/utils/remote.csh &
#   exec ssh [lindex $hostlist [expr $i-1]] "source $mydir/$place_directive/remote.csh" &


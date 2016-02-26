######################################################################
#
# Variables Initialization
#
######################################################################

set rootDir        {%{ROOTDIR}}
set runDir         {%{RUNDIR}}
# set db             {%{ROOTDIR}/metrics.db}
# set db             $rootDir/metrics.db
set db             $runDir/metrics.db
set project        {%{PROJECT}}
set version        {%{VERSION}}
set experiment     {%{EXPERIMENT}}

set logFile        {%{LOGFILE}}
set designName     {%{DESIGNNAME}}
set suiteName      {%{SUITENAME}}
set checkpoint     {%{CHECKPOINT}}

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
  lappend auto_path /home/dpefour/git/scripts/toolbox
  package require toolbox
  snapshot reset
}

catch {
  if {[file exists $rootDir/common.tcl]} {
    puts " Sourcing common script file '$rootDir/common.tcl'"
    source $rootDir/common.tcl
  }
}

if {[file exists $runDir/$checkpoint]} {
  set checkpoint $runDir/$checkpoint
} else {
  set checkpoint [regsub {\.OUTPUT} $logFile {}]/$checkpoint
  if {![file exists $checkpoint]} {
    puts "ERROR - Cannot find dcp file $checkpoint"
    exit
  }
  # Make a local copy of the checkpoint
  catch { file copy -force $checkpoint $runDir }
}

if {[catch {open_checkpoint $checkpoint} errorstring]} {
  if {[regexp {ERROR: \[Project 1-589\] Checkpoint part '\S+' is not available. Closest-matching available part\(s\)\: (\S+)} $errorstring - tgtPart]} {
    open_checkpoint $checkpoint -part [regsub {,} $tgtPart {}]
  } else {
    puts "ERROR - Unsupported part"
    exit
  }
}

set spaths [get_timing_paths -setup -max 100 -nworst 1]
set hpaths [get_timing_paths -hold  -max 100 -nworst 1]

# report_net_correlation $spaths 0.1 net_corr_setup.csv $designName
# report_net_correlation $hpaths 0.1 net_corr_hold.csv $designName

tb::report_net_correlation -of $spaths -margin 0.1 -delta 0.020 -format both -file net_corr_setup.csv -design $designName
tb::report_net_correlation -of $hpaths -margin 0.1 -delta 0.020 -format both -file net_corr_hold.csv -design $designName

catch { ::tb::report_path_analysis -of $spaths         -sort_by tns -setup -file $runDir/report_path_analysis.setup.rpt }
catch { ::tb::report_path_analysis -of $spaths -R -csv -sort_by tns -setup -file $runDir/report_path_analysis.setup.csv }

catch { ::tb::report_path_analysis -of $hpaths         -sort_by tns -hold -file $runDir/report_path_analysis.hold.rpt }
catch { ::tb::report_path_analysis -of $hpaths -R -csv -sort_by tns -hold -file $runDir/report_path_analysis.hold.csv }

tb::report_design_summary -all -file [file rootname [file tail $checkpoint]]_sum.csv -details -csv -verbose -project $project -version $version -experiment $experiment -step place_design

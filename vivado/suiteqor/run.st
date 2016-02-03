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
}

if {[catch {open_checkpoint $checkpoint} errorstring]} {
  if {[regexp {ERROR: \[Project 1-589\] Checkpoint part '\S+' is not available. Closest-matching available part\(s\)\: (\S+)} $errorstring - tgtPart]} {
    open_checkpoint $checkpoint -part [regsub {,} $tgtPart {}]
  } else {
    puts "ERROR - Unsupported part"
    exit
  }
}

# tb::report_design_summary -file $runDir/summary.csv -details -csv
# tb::report_design_summary -file ./summary.csv -details -csv -verbose
# tb::report_design_summary -all -file ./summary.csv -details -csv -verbose
set res [tb::report_design_summary -serialize -all -file [file rootname [file tail $checkpoint]]_opt_sum.csv -details -csv -verbose -project $project -version $version -experiment $experiment -step opt_design]

snapshot configure -db $db -project $project -version $version -experiment $experiment -step opt_design
foreach el $res {
  foreach {metric value} $el { break }
  snapshot set -once $metric $value
}
snapshot extract -save
snapshot reset

catch { close_design }

set fisDir [file dirname $checkpoint]

if {[file exists $fisDir/postplace.dcp]} {
  open_checkpoint $fisDir/postplace.dcp
  set res [tb::report_design_summary -serialize -all -file [file rootname [file tail $checkpoint]]_place_sum.csv -details -csv -verbose -project $project -version $version -experiment $experiment -step place_design]
  snapshot configure -db $db -project $project -version $version -experiment $experiment -step place_design
  foreach el $res {
    foreach {metric value} $el { break }
    snapshot set -once $metric $value
  }
  snapshot extract -save
  snapshot reset
  catch { close_design }
}

if {[file exists $fisDir/postroute.dcp]} {
  open_checkpoint $fisDir/postroute.dcp
  set res [tb::report_design_summary -serialize -all -file [file rootname [file tail $checkpoint]]_route_sum.csv -details -csv -verbose -project $project -version $version -experiment $experiment -step route_design]
  snapshot configure -db $db -project $project -version $version -experiment $experiment -step route_design
  foreach el $res {
    foreach {metric value} $el { break }
    snapshot set -once $metric $value
  }
  snapshot extract -save
  snapshot reset
  catch { close_design }
}

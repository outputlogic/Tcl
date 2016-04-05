#!/bin/sh
# use -*-TCL-*- \
exec tclsh "$0" ${1+"$@"}

set DEBUG 0

proc init {} {

  set fisPath0 {/proj/rdi-xco/fisusr/no_backup/ABELite/Results}
  set fisPath1 {/proj/fisdata/fisusr/no_backup/RDI_fisusr_olympus1}
  set fisRun   {20160128}

  set LOGFILES [glob -nocomplain $fisPath0/US_CUSTOMER/*/TEST_WORK_${fisRun}_*_lnx64.OUTPUT]
  iterator LOGFILE $LOGFILES

  # set VERSION [lindex [file split $::WDIR] end-1]
  set VERSION {Default}
  set PROJECT {Default}
  # set EXPERIMENT [lindex [file split $WDIR] end]
  set EXPERIMENT {Default}

  set LSF_MEMORY 10000
  set RUN_SCRIPT_INCLUDE {}

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

  # List of all directories that will be created
  set DIRECTORIES [list]

  # Generate all run.tcl scripts inside their own directory
  set iterName [lindex $CONFIG_VARS(_) 0]
  set iterValues [lindex $CONFIG_VARS(_) 1]
  foreach iter $iterValues {
    set logFile $iter
    # E.g: iterValues:/proj/rdi-xco/fisusr/no_backup/ABELite/Results/US_CUSTOMER/Ericsson_radio8808b41e_tsr874758_2015_08_30/TEST_WORK_20160128_024527_lnx64.OUTPUT
    if {[regexp {.*/([^/]+)/([^/]+)/TEST_WORK_.*_lnx64.OUTPUT} $iter - suiteName designName]} {
      set dir [format {%s_%s} $suiteName $designName]
      lappend DIRECTORIES $dir
    } else {
      puts " -E- Could not extract suite and design from '$iter'"
      continue
    }

    # Extract checkpoint from log file
    set checkpoint {}
    set LOG [open $logFile r]
    while {[gets $LOG line] >= 0} {
      if {[regexp {^Command:\s+open_checkpoint\s+(\S+)} $line - checkpoint]} {
        break
      }
    }
    close $LOG
    if {$checkpoint == {}} {
      puts " -E- Cannot find open_checkpoint command in log file '$logFile'"
      continue
    }
    set dcp [regsub {\.OUTPUT} $logFile {}]/$checkpoint
    if {![file exists $dcp]} {
      puts " -W- Cannot find dcp file $dcp"
      # Keep going as DCP might be manually placed by the user inside run directory
#       continue
    }

    file mkdir $dir
    set EXPERIMENT [lindex [file split $WDIR] end].$dir
    uplevel #0 [linsert \
                        [linsert $arguments 0 exec smtpl -i ${WDIR}/$scriptname \
                                                         -o ${WDIR}/$dir/run.tcl \
                                                         -opp ${WDIR}/$dir/run.php \
                                                         -force ] \
                        end \
                        -$iterName=$iter \
                        -EXPERIMENT=$EXPERIMENT \
                        -RUNDIR=$WDIR/$dir \
                        -ROOTDIR=$WDIR \
                        -CHECKPOINT=$checkpoint \
                        -DESIGNNAME=$designName \
                        -SUITENAME=$suiteName \
                        ]
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

  # To remove duplicates when multiple fisruns where done the same day
  set DIRECTORIES [lsort -unique $DIRECTORIES]

  # Generate lsf.do
  uplevel #0 [linsert $arguments 0 exec smtpl -i ${WDIR}/lsf.st \
                                              -o ${WDIR}/lsf.do \
                                              -force \
                                              -ROOTDIR=$WDIR \
                                              -DIRECTORIES=$DIRECTORIES ]
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
                                              -force \
                                              -DIRECTORIES=$DIRECTORIES ]

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

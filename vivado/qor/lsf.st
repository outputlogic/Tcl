#!/bin/sh
# use -*-TCL-*- \
exec tclsh "$0" "$@"

set WDIR [file dirname [file normalize [info script]]]
if {[file exists $WDIR/lsf.pid]} {
  puts " -I- file $WDIR/lsf.pid exists. Some jobs could be running. Run lsf.check to get the job status"
  exit 0
}

set lsfjobs [list]

foreach dir [list %{DIRECTIVES}] {
  puts "bsub -P swapps_2013.x -app sil_rhel5 -o /dev/null -q long -R \"rusage\[mem=%{LSF_MEMORY}\]\" vivado -mode batch -source %{ROOTDIR}/$dir/run.tcl -log %{ROOTDIR}/$dir/run.log -jou %{ROOTDIR}/$dir/run.jou"
  set res [exec bsub -P swapps_2013.x -app sil_rhel5 -o /dev/null -q long -R {rusage[mem=%{LSF_MEMORY}]} vivado -mode batch -source %{ROOTDIR}/$dir/run.tcl -log %{ROOTDIR}/$dir/run.log -jou %{ROOTDIR}/$dir/run.jou ]
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

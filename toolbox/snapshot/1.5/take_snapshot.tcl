
# The project name is extracted from the directory where the job is run:
#  /home/user/vivado/project_1/project_1.runs/impl_1 => project_1
#
# The release name is shortened: 
#  2014.3.0 => 2014.3

snapshot configure -db {} \
                   -project [lindex [file split [pwd]] end-2] \
                   -release [regsub {^([0-9]+\.[0-9]+)\.0$} [version -short] {\1}] \
                   -version {} \
                   -experiment {} \
                   -run {} \
                   -description {}

if {[regexp {^take_snapshot\.(.+)\.tcl$} [file tail [info script]] - ___step___]} {
  snapshot configure -step $___step___
}

take_snapshot

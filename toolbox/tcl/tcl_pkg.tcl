####################################################################################################
# HEADER_BEGIN
# COPYRIGHT NOTICE
# Copyright 2001-2013 Xilinx Inc. All Rights Reserved.
# http://www.xilinx.com/support
# HEADER_END
####################################################################################################

source [file join  [file dirname [info script]] tcl.tcl]
source [file join  [file dirname [info script]] list.tcl]
source [file join  [file dirname [info script]] array.tcl]

# eval [list namespace eval ::tb {
#   namespace import ::tb::tcl::*
# } ]

if {[info var ::__TOOLBOXVERBOSE__] != {}} {
  catch { puts -nonewline [format {     %-20s : %-40s (%s} \
             {tcl} \
             {Various Tcl helper procs} \
             ${::tb::tcl::version} \
             ] }
}

package provide tcl ${::tb::tcl::version}

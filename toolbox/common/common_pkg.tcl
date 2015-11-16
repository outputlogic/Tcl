####################################################################################################
# HEADER_BEGIN
# COPYRIGHT NOTICE
# Copyright 2001-2013 Xilinx Inc. All Rights Reserved.
# http://www.xilinx.com/support
# HEADER_END
####################################################################################################

source [file join  [file dirname [info script]] common.tcl]

if {[info var ::__TOOLBOXVERBOSE__] != {}} {
  catch { puts -nonewline [format {     %-20s : %-40s (%s} \
             {common} \
             {Various helper procs} \
             ${::tb::common::version} \
             ] }
}

package provide common ${::tb::common::version}

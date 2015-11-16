####################################################################################################
# HEADER_BEGIN
# COPYRIGHT NOTICE
# Copyright 2001-2013 Xilinx Inc. All Rights Reserved.
# http://www.xilinx.com/support
# HEADER_END
####################################################################################################

if {[package provide Vivado] == {}} {return}

source [file join  [file dirname [info script]] profiler.tcl]

if {[info var ::__TOOLBOXVERBOSE__] != {}} {
  catch { puts -nonewline [format {     %-20s : %-40s (%s} \
             {profiler} \
             {Profiler for Vivado commands} \
             ${::tb::profiler::version} \
             ] }
}

package provide profiler ${::tb::profiler::version}

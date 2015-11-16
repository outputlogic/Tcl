####################################################################################################
# HEADER_BEGIN
# COPYRIGHT NOTICE
# Copyright 2001-2014 Xilinx Inc. All Rights Reserved.
# http://www.xilinx.com/support
# HEADER_END
####################################################################################################

if {[package provide Vivado] == {}} {return}

source [file join  [file dirname [info script]] p2pdelay.tcl]

if {[info var ::__TOOLBOXVERBOSE__] != {}} {
  catch { puts -nonewline [format {     %-20s : %-40s (%s} \
             {p2pdelay} \
             {Client/Server implementation to get p2pdelay route delays/information} \
             ${::tb::p2pdelay::version} \
             ] }
}

package provide p2pdelay ${::tb::p2pdelay::version}

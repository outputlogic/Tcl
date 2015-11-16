####################################################################################################
# HEADER_BEGIN
# COPYRIGHT NOTICE
# Copyright 2001-2013 Xilinx Inc. All Rights Reserved.
# http://www.xilinx.com/support
# HEADER_END
####################################################################################################

source [file join  [file dirname [info script]] prettyTable.tcl]

if {[info var ::__TOOLBOXVERBOSE__] != {}} {
  catch { puts -nonewline [format {     %-20s : %-40s (%s} \
             {prettyTable} \
             {Simple way to handle formatted tables} \
             ${::tb::prettyTable::version} \
             ] }
}

package provide prettyTable ${::tb::prettyTable::version}

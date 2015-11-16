####################################################################################################
# HEADER_BEGIN
# COPYRIGHT NOTICE
# Copyright 2001-2013 Xilinx Inc. All Rights Reserved.
# http://www.xilinx.com/support
# HEADER_END
####################################################################################################

# if {[package provide Vivado] == {}} {return}

source [file join  [file dirname [info script]] ishell.tcl]

if {[info var ::__TOOLBOXVERBOSE__] != {}} {
  catch { puts -nonewline [format {     %-20s : %-40s (%s} \
             {ishell} \
             {Intereactive Tcl shell} \
             ${::tb::ishell::version} \
             ] }
}

package provide ishell ${::tb::ishell::version}

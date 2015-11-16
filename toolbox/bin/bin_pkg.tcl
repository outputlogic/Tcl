####################################################################################################
# HEADER_BEGIN
# COPYRIGHT NOTICE
# Copyright 2001-2013 Xilinx Inc. All Rights Reserved.
# http://www.xilinx.com/support
# HEADER_END
####################################################################################################

foreach _file_ [lsort -dictionary [glob -nocomplain [file join  [file dirname [info script]] *]] ] {
  if {([file tail $_file_] == {pkgIndex.tcl}) || [regexp {_pkg.tcl$} [file tail $_file_]] } {
    continue
  }
  source $_file_
}
unset _file_

if {[info var ::__TOOLBOXVERBOSE__] != {}} {
  catch { puts -nonewline [format {     %-20s : %-40s (%s} \
             {bin} \
             {Various command line utilities} \
             ${::tb::bin::version} \
             ] }
}

package provide bin ${::tb::bin::version}

# Import inside namespace ::tb all the exported procs from ::tb::bin
# namespace eval ::tb {
#     namespace import ::tb::bin::*
# }

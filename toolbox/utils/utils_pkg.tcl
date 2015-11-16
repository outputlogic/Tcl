####################################################################################################
# HEADER_BEGIN
# COPYRIGHT NOTICE
# Copyright 2001-2013 Xilinx Inc. All Rights Reserved.
# http://www.xilinx.com/support
# HEADER_END
####################################################################################################

if {[package provide Vivado] == {}} {
    # PRAGMA: returnok
    return
}

if {![package vsatisfies [package provide Vivado] 1.2014.1]} {
    # PRAGMA: returnok
    return
}

package require Vivado 1.2014.1

foreach _file_ [lsort -dictionary [glob -nocomplain [file join  [file dirname [info script]] *.tcl]] ] {
  if {([file tail $_file_] == {pkgIndex.tcl}) || [regexp {_pkg.tcl$} [file tail $_file_]] } {
    continue
  }
  source $_file_
}
unset _file_

if {[info var ::__TOOLBOXVERBOSE__] != {}} {
  catch { puts -nonewline [format {     %-20s : %-40s (%s} \
             {utils} \
             {Various Vivado helper procs} \
             ${::tb::utils::version} \
             ] }
}

package provide utils ${::tb::utils::version}

# Import inside namespace ::tb all the exported procs from ::tb::utils
namespace eval ::tb {
    namespace import ::tb::utils::*
}

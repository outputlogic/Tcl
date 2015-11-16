####################################################################################################
# HEADER_BEGIN
# COPYRIGHT NOTICE
# Copyright 2001-2013 Xilinx Inc. All Rights Reserved.
# http://www.xilinx.com/support
# HEADER_END
####################################################################################################

# if {[package provide Vivado] == {}} {
#     # PRAGMA: returnok
#     return
# }
# 
# if {![package vsatisfies [package provide Vivado] 2013.1]} {
#     # PRAGMA: returnok
#     return
# }
# 
# package require Vivado 2013.1
# package require Vivado 1.2014.1

set tcl_interactive false

if {[info var ::__TOOLBOXVERBOSE__] != {}} {
  puts "\n The following packages have been loaded:"
}
foreach file [lsort -dictionary [concat \
          [glob -nocomplain [file join  [file dirname [info script]] *_pkg.tcl]]  \
          [glob -nocomplain [file join  [file dirname [info script]] */*_pkg.tcl]] ] ] {
  if {[file tail $file] == {toolbox_pkg.tcl}} {
    continue
  }
  set package [regsub {_pkg.tcl} [file tail $file] {}]
# puts "File: $file / package $package"
  source $file
# puts "     $package : [package require $package]"

#   catch { puts [format {     %-20s : %-10s} $package [package require $package] ] }
if {[info var ::__TOOLBOXVERBOSE__] != {}} {
    catch { package require $package; puts ")" }
  } else {
    catch { package require $package }
  }
}
unset file
unset package

if {[info var ::__TOOLBOXVERBOSE__] != {}} {
  puts -nonewline "\n Package toolbox: "
}
package provide toolbox 0.1

# Import inside global namespace all the exported procs from ::tclapp::xilinx::checklist
namespace eval :: {
    namespace import -force ::tb::*
}
# namespace import ::tb::*

set tcl_interactive true

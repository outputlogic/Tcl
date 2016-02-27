# Tcl package index file, version 1.1
# This file is generated by the "pkg_mkIndex" command
# and sourced either when an application starts up or
# by a "package unknown" script.  It invokes the
# "package ifneeded" command to set up package-related
# information so that packages will be loaded automatically
# in response to "package require" commands.  When this
# script is sourced, the variable $dir must contain the
# full path name of this file's directory.

if {![package vsatisfies [package provide Tcl] 8.4]} {
    # PRAGMA: returnok
    return
}

namespace eval ::tb::p2pdelay {
    variable version {2016.02.26}
    # Allow Tcl to find tclIndex
    variable home [file join [pwd] [file dirname [info script]]]
    if {[lsearch -exact $::auto_path $home] == -1} {
      lappend ::auto_path $home
    }
}

# package ifneeded p2pdelay                 ${::tb::p2pdelay::version} [list source [file join $dir p2pdelay_pkg.tcl]]

# Package below this line are Vivado packages only
if {[package provide Vivado] == {}} {return}

package ifneeded p2pdelay                 ${::tb::p2pdelay::version} [list source [file join $dir p2pdelay_pkg.tcl]]

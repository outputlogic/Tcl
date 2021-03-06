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

namespace eval ::tb {
    # Allow Tcl to find tclIndex
    variable home [file join [pwd] [file dirname [info script]]]
    if {[lsearch -exact $::auto_path $home] == -1} {
      lappend ::auto_path $home
    }
}

package ifneeded toolbox        0.1        [list source [file join $dir toolbox_pkg.tcl]]

# package ifneeded common         2013.10.03 [list source [file join $dir common_pkg.tcl]]
# package ifneeded prettyTable    2013.10.03 [list source [file join $dir prettyTable_pkg.tcl]]
# package ifneeded tree           2013.10.04 [list source [file join $dir tree_pkg.tcl]]

set maindir $dir
set dir [file join $maindir common];        source [file join $dir pkgIndex.tcl]
set dir [file join $maindir prettyTable];   source [file join $dir pkgIndex.tcl]
set dir [file join $maindir tree];          source [file join $dir pkgIndex.tcl]
set dir [file join $maindir utils];         source [file join $dir pkgIndex.tcl]
set dir [file join $maindir tcl];           source [file join $dir pkgIndex.tcl]
set dir [file join $maindir snapshot];      source [file join $dir pkgIndex.tcl]
set dir [file join $maindir bin];           source [file join $dir pkgIndex.tcl]
set dir $maindir; unset maindir

# Package below this line are Vivado packages only
if {[package provide Vivado] == {}} {return}

# package ifneeded profiler       2013.10.03 [list source [file join $dir profiler_pkg.tcl]]

set maindir $dir
set dir [file join $maindir profiler];      source [file join $dir pkgIndex.tcl]
set dir $maindir; unset maindir

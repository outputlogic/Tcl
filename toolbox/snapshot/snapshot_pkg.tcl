####################################################################################################
# HEADER_BEGIN
# COPYRIGHT NOTICE
# Copyright 2001-2013 Xilinx Inc. All Rights Reserved.
# http://www.xilinx.com/support
# HEADER_END
####################################################################################################

# if {[package provide Vivado] == {}} {return}

source [file join  [file dirname [info script]] snapshot_core.tcl]
source [file join  [file dirname [info script]] snapshot_db2csv.tcl]
source [file join  [file dirname [info script]] snapshot_db2dir.tcl]
source [file join  [file dirname [info script]] snapshot_ext.tcl]
source [file join  [file dirname [info script]] snapshot_helpers.tcl]
source [file join  [file dirname [info script]] snapshot_summary]
source [file join  [file dirname [info script]] snapshot_merge]
source [file join  [file dirname [info script]] extract.tcl]

if {[info var ::__TOOLBOXVERBOSE__] != {}} {
  catch { puts -nonewline [format {     %-20s : %-40s (%s} \
             {snapshot} \
             {Snapshots/metrics extraction} \
             ${::tb::snapshot::version} \
             ] }
}

package provide snapshot ${::tb::snapshot::version}

####################################################################################################
# HEADER_BEGIN
# COPYRIGHT NOTICE
# Copyright 2001-2013 Xilinx Inc. All Rights Reserved.
# http://www.xilinx.com/support
# HEADER_END
####################################################################################################

eval [list namespace eval ::tb {
  namespace export -force sarray larray

  # parray exists in 8.5
  if {[info proc ::parray] == {}} { namespace export -force parray }
}]

########################################################################################
##
## Company:        Xilinx, Inc.
## Created by:     David Pefourque
## 
## Version:        2013.10.03
## Description:    This package provides tcl helper procs
##
########################################################################################

# Proc to reload current script
proc [file tail [info script]] {} " source [info script]; puts \" [info script] reloaded\" "

########################################################################################
## 2013.10.03 - Initial release
########################################################################################

###########################################################################
##
## Package for helper rpocs
##
###########################################################################

#------------------------------------------------------------------------
# Namespace for the package
#------------------------------------------------------------------------

# Trick to silence the linter
eval [list namespace eval ::tb::tcl { 
  namespace export -force sarray larray
  
  # parray exists in 8.5
  if {[info proc ::parray] == {}} { namespace export -force parray }

  
#   variable version {2013.10.03}
} ]

#------------------------------------------------------------------------
# ::tb::tcl::parray
#------------------------------------------------------------------------
# Print array to stdout
#------------------------------------------------------------------------
proc ::tb::tcl::parray {array {pattern *}} {
   upvar $array a
   if { ![array exists a] } { error "\"$array\" isn't an array" }
   set lines [list]
   set max 0
   foreach name [array names a $pattern] {
     set len [string length $name]
     if { $len > $max } { set max $len }
   }
   set max [expr {$max + [string length $array] + 2}]
   foreach name [array names a $pattern] {
     set line [format %s(%s) $array $name]
     lappend lines [format "%-*s = %s" $max $line $a($name)]
   }
   puts [join [lsort $lines] \n]
   # return [join [lsort $lines] \n]
}

#------------------------------------------------------------------------
# ::tb::tcl::sarray ::tb::tcl::larray 
#------------------------------------------------------------------------
# Save/load array to/from file
#------------------------------------------------------------------------
proc ::tb::tcl::sarray {filename arrayname} {
        upvar $arrayname name
        set fid [open $filename w]
        foreach index [lsort [array names name]] {
                regsub -all -- {\n} [list $index $name($index)] {\n} tmp
                puts $fid $tmp
        }
        close $fid
        return
}

proc ::tb::tcl::larray {filename arrayname} {
        upvar $arrayname name
        set fid [open $filename r]
        while {![eof $fid]} {
                gets $fid zeile
                if {$zeile eq {}} {
                        continue
                }
                regsub -all -- {\\n} $zeile "\n" tmp
                array set name $tmp
        }
        close $fid
        return
}


###########################################################################
##
## Import procs to ::tb namespace
##
########################################################################
eval [list namespace eval ::tb {
  namespace import -force ::tb::tcl::*
} ]

###########################################################################
##
## Examples Scripts
##
###########################################################################

if 0 {
}


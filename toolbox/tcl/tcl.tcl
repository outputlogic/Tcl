####################################################################################################
# HEADER_BEGIN
# COPYRIGHT NOTICE
# Copyright 2001-2013 Xilinx Inc. All Rights Reserved.
# http://www.xilinx.com/support
# HEADER_END
####################################################################################################

namespace eval ::tb {
  namespace export -force K
  namespace export -force iota dec2bin bin2dec
  namespace export -force expandBusNames collapseBusNames

}

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
  namespace export -force K
  namespace export -force iota dec2bin bin2dec
  namespace export -force expandBusNames collapseBusNames

#   variable version {2013.10.03}
} ]

#------------------------------------------------------------------------
# ::tb::tcl::iota
#------------------------------------------------------------------------
# Generate List of Numbers
#------------------------------------------------------------------------
# % iota 5
# => 0 1 2 3 4
#------------------------------------------------------------------------
proc ::tb::tcl::iota { n } {
  for { set i 0 } { $i < $n } { incr i } {
     lappend retval $i
  }
  return $retval
}

#------------------------------------------------------------------------
# ::tb::tcl::dec2bin
#------------------------------------------------------------------------
# Converting Decimal to Binary
#------------------------------------------------------------------------

# proc ::tb::tcl::dec2bin {i} {
#   #returns a string, e.g. dec2bin 10 => 1010
#   set res {}
#   while {$i>0} {
#     set res [expr {$i%2}]$res
#     set i [expr {$i/2}]
#   }
#   if {$res == {}} {set res 0}
#   return $res
# }

proc ::tb::tcl::dec2bin {i {width {}}} {
  #returns the binary representation of $i
  # width determines the length of the returned string (left truncated or added left 0)
  # use of width allows concatenation of bits sub-fields
  set res {}
  if {$i<0} {
    set sign -
    set i [expr {abs($i)}]
  } else {
    set sign {}
  }
  while {$i>0} {
    set res [expr {$i%2}]$res
    set i [expr {$i/2}]
  }
  if {$res == {}} {set res 0}

  if {$width != {}} {
    append d [string repeat 0 $width] $res
    set res [string range $d [string length $res] end]
  }
  return $sign$res
}

#------------------------------------------------------------------------
# ::tb::tcl::bin2dec
#------------------------------------------------------------------------
# Converting Binary to Decimal
#------------------------------------------------------------------------
proc ::tb::tcl::bin2dec {bin} {
  if {$bin == 0} {
    return 0
  } elseif {[string match -* $bin]} {
    set sign -
    set bin [string range $bin[set bin {}] 1 end]
  } else {
    set sign {}
  }
  set res 0
  for {set j 0} {$j < [string length $bin]} {incr j} {
    set bit [string index $bin $j]
    set res [expr {$res << 1}]
    set res [expr {$res | $bit}]
  }
  return $sign$res
}

#------------------------------------------------------------------------
# ::tb::tcl::K
#------------------------------------------------------------------------
# K combinator
#------------------------------------------------------------------------
proc ::tb::tcl::K {a b} {return $a}

#------------------------------------------------------------------------
# ::tb::tcl::expandBusNames
#------------------------------------------------------------------------
# Expand a list of bus names
#------------------------------------------------------------------------
# % expandBusNames { a b b[1:2] b[4:6] }
# => a b {b[1]} {b[2]} {b[4]} {b[5]} {b[6]}
#------------------------------------------------------------------------
proc ::tb::tcl::expandBusNames { L } {
  set pins [list]
  foreach elm [lsort -dictionary $L] {
    if {[regexp {^\{?(.+)\[([0-9]+)\:([0-9]+)\]\}?$} $elm - name index1 index2]} {
      if {$index1 > $index2} {
        foreach {index1 index2} [list $index2 $index1] break
      }
      for {set i $index1} {$i <= $index2} {incr i} {
        lappend pins [format {%s[%s]} $name $i]
#         lappend pins "$name\[$i\]"
      }
    } else {
      lappend pins $elm
    }
  }
#   if {[llength $pins] == 1} { return [lindex $pins 0] }
  return $pins
}

#------------------------------------------------------------------------
# ::tb::tcl::collapseBusNames
#------------------------------------------------------------------------
# Collapse a list of bus names
#------------------------------------------------------------------------
# % collapseBusNames { a b b[1] b[2] b[6] b[5] b[4] }
# => a b {b[1:2]} {b[4:6]}
#------------------------------------------------------------------------
proc ::tb::tcl::collapseBusNames { L } {
  
  proc createBusDef { name min max } {
    if {$max == $min} {
      return [format {%s[%s]} $name $max]
    } else {
      return [format {%s[%s:%s]} $name $min $max]
    }
  }
  
  set pins [list]
  set previousName {}
  set previousIndexMin -1
  set previousIndex -1
  set previousIsbus 0
  set isbus 0
  foreach elm [lsort -dictionary $L] {
    set name $elm
    set isbus 0
    if {[regexp {^\{?(.+)\[([0-9]+)\]\}?$} $elm - name index]} {
      set isbus 1
    }
    # It the pins does not match a bus then it's simple
    if {!$isbus} {
      if {$previousIsbus} {
        # The previous bit belongs to a bus. Save the bus information
        lappend pins [createBusDef $previousName $previousIndexMin $previousIndex]
      }
      lappend pins $name
      set previousIsbus $isbus; set previousName $name; set previousIndex -1; set previousIndexMin -1
      continue
    }
    # If it is a bus then that's more complicated
    if {!$previousIsbus} {
      # If the previous pin was not a bus
      set previousIsbus $isbus; set previousName $name; set previousIndex $index; set previousIndexMin $index
      continue
    }
    if {($name != $previousName) && ($previousIsbus)} {
      # If the previous pin was a different bus
      lappend pins [createBusDef $previousName $previousIndexMin $previousIndex]
      set previousIsbus $isbus; set previousName $name; set previousIndex $index; set previousIndexMin $index
      continue
    }
    # The previous pin belongs to the same bus
    if {$index == [expr $previousIndex +1]} {
      set previousIsbus $isbus; set previousIndex $index
      continue
    }
    # The bit number inside the bus is not linear. Save the partial bus information
    lappend pins [createBusDef $previousName $previousIndexMin $previousIndex]
    set previousIsbus $isbus; set previousIndex $index; set previousIndexMin $index
  }

  # If the last pin belongs to a bus, then the bus information still needs to be saved
  if {$isbus} {
    lappend pins [createBusDef $previousName $previousIndexMin $previousIndex]
  }
#   if {[llength $pins] == 1} { return [lindex $pins 0] }
  return $pins
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


####################################################################################################
# HEADER_BEGIN
# COPYRIGHT NOTICE
# Copyright 2001-2013 Xilinx Inc. All Rights Reserved.
# http://www.xilinx.com/support
# HEADER_END
####################################################################################################

namespace eval ::tb {
  namespace export -force lflatten lshift unlshift lremove
  namespace export -force lshuffle lmorph ldraw islist listify
  namespace export -force lintersect linterleave ldiff
  namespace export -force lfirst llast
  namespace export -force lmin lmax lsum lmean
  namespace export -force lhead ltail lskim lrevert ladd
  namespace export -force lexpand lequal
  namespace export -force lmap lgrep

  # lassign exists in 8.5
  if {[info proc ::lassign] == {}} { namespace export -force lassign }

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
  namespace export -force lflatten lshift unlshift lremove
  namespace export -force lshuffle lmorph ldraw islist listify
  namespace export -force linterleave lfirst llast
  namespace export -force lmin lmax lsum lmean
  namespace export -force lhead ltail lskim lrevert ladd
  namespace export -force lexpand lequal

  # lassign exists in 8.5
  if {[info proc ::lassign] == {}} { namespace export lassign }

#   variable version {2013.10.08}
} ]


#------------------------------------------------------------------------
# ::tb::tcl::lshift
#------------------------------------------------------------------------
# Stack function
#------------------------------------------------------------------------
proc ::tb::tcl::lshift {inputlist} {
  upvar $inputlist argv
  set arg  [lindex $argv 0]
  set argv [lrange $argv 1 end]
  return $arg
}

#------------------------------------------------------------------------
# ::tb::tcl::unlshift
#------------------------------------------------------------------------
# Stack function
#------------------------------------------------------------------------
proc ::tb::tcl::unlshift { ls data } {
   upvar 1 $ls LIST
   set LIST [concat $data $LIST]
}

#------------------------------------------------------------------------
# ::tb::tcl::lflatten
#------------------------------------------------------------------------
# Flatten
#------------------------------------------------------------------------
proc ::tb::tcl::lflatten {data} {
  while { $data != [set data [join $data]] } { }
  return $data
}

#------------------------------------------------------------------------
# ::tb::tcl::lremove
#------------------------------------------------------------------------
# Remove all the elements matching a value from a list
#------------------------------------------------------------------------
proc ::tb::tcl::lremove {_list el} {
  upvar 1 $_list list
  set list [lsearch -all -inline -not -exact $list $el]
}

#------------------------------------------------------------------------
# ::tb::tcl::lmax
# ::tb::tcl::lmin
# ::tb::tcl::lsum
# ::tb::tcl::lmean
#------------------------------------------------------------------------
# Various math functions
#------------------------------------------------------------------------
proc ::tb::tcl::lmax L {lindex [lsort -real $L] end}
proc ::tb::tcl::lmin L {lindex [lsort -real $L] 0}
proc ::tb::tcl::lsum L {expr [join $L +]+0}
proc ::tb::tcl::lmean L {expr double([join $L +])/[llength $L]}

#------------------------------------------------------------------------
# ::tb::tcl::lfirst 
# ::tb::tcl::llast
#------------------------------------------------------------------------
# Return first/last element of a list
#------------------------------------------------------------------------
proc ::tb::tcl::lfirst L {lindex $L 0}
proc ::tb::tcl::llast L {lindex $L end}

#------------------------------------------------------------------------
# ::tb::tcl::lassign
#------------------------------------------------------------------------
# Assign a list to a list of variables
#------------------------------------------------------------------------
proc ::tb::tcl::lassign {list args} {
  if {$args == ""} {
    return -code error {wrong # args: should be "lassign list varName ?varName ...?"}
  }
  uplevel 1 [list foreach $args [linsert $list end {}] break]
  return [lrange $list [llength $args] end]
}

#------------------------------------------------------------------------
# ::tb::tcl::lmorph
#------------------------------------------------------------------------
# Morph a list (i.e. slightly shuffle it)
#------------------------------------------------------------------------
#  %morph {1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20} 100
#   7 15 1 9 11 19 6 5 4 13 3 10 20 2 16 8 17 12 18 14
#   %morph {1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20} 10 ;# only 10% change
#   12 2 3 4 5 6 7 8 9 10 18 1 13 14 15 16 17 11 20 19
#  ----------------------------------------------------------------------
proc ::tb::tcl::lmorph {list {perc 100}} {
  set modulo [expr {100/$perc}]
  expr {srand([clock clicks])}
  set len [llength $list]
  set len2 $len
  incr len -1
  for {set i 0} {$i < $len} {incr i} {
    set n [expr {int($i + $len2 * rand())}]
    incr len2 -1
    if {$i%$modulo==0} {
      # Swap elements at i & n
      set temp [lindex $list $i]
      lset list $i [lindex $list $n]
      lset list $n $temp
    }
  }
  return $list
}

#------------------------------------------------------------------------
# ::tb::tcl::lshuffle
#------------------------------------------------------------------------
# Shuffle a list
#------------------------------------------------------------------------
proc ::tb::tcl::lshuffle { list } {
  set n [llength $list]
  for { set i 1 } { $i < $n } { incr i } {
    set j [expr { int( rand() * $n ) }]
    set temp [lindex $list $i]
    lset list $i [lindex $list $j]
    lset list $j $temp
  }
  return $list
 }

#------------------------------------------------------------------------
# ::tb::tcl::ldraw
#------------------------------------------------------------------------
# Draw an element from a list
#------------------------------------------------------------------------
proc ::tb::tcl::ldraw L {
  lindex $L [expr {int(rand()*[llength $L])}]
}

#------------------------------------------------------------------------
# ::tb::tcl::lhead
# ::tb::tcl::ltail
#------------------------------------------------------------------------
# Return the head or tail of a list
#------------------------------------------------------------------------
proc ::tb::tcl::lhead L {lindex $L 0}
proc ::tb::tcl::ltail L {lrange $L 1 end}

#------------------------------------------------------------------------
# ::tb::tcl::islist
#------------------------------------------------------------------------
# Is a list?
#------------------------------------------------------------------------
proc ::tb::tcl::islist {s} {expr ![catch {llength $s}]}

#------------------------------------------------------------------------
# ::tb::tcl::listify
#------------------------------------------------------------------------
# Convert a string to a list (listify)
#------------------------------------------------------------------------
# % string2list {a   b c     d}
# a b c d
#------------------------------------------------------------------------
proc ::tb::tcl::listify L {
  regexp -all -inline {\S+} $L
}

#------------------------------------------------------------------------
# ::tb::tcl::lskim
#------------------------------------------------------------------------
# Return the nth element of a list of lists
#------------------------------------------------------------------------
proc ::tb::tcl::lskim { L {n 0} } {
  set res [list]
  foreach i $L {lappend res [lindex $i $n]}
  set res
}

#------------------------------------------------------------------------
# ::tb::tcl::lrevert
#------------------------------------------------------------------------
# Reverse a list
#------------------------------------------------------------------------
proc ::tb::tcl::lrevert L {
   for {set res {}; set i [llength $L]} {$i>0} {#see loop} {
       lappend res [lindex $L [incr i -1]]
   }
   set res
}

#------------------------------------------------------------------------
# ::tb::tcl::ladd
#------------------------------------------------------------------------
# Add an element to a list if it does not already exist
#------------------------------------------------------------------------
proc ::tb::tcl::ladd {_L x} {
  upvar 1 $_L L
#   if {[lsearch $L $x]<0} {lappend L $x}
  if {[lsearch -exact $L $x]<0} {lappend L $x}
}

#------------------------------------------------------------------------
# ::tb::tcl::linterleave
#------------------------------------------------------------------------
# Interleave multiple lists
#------------------------------------------------------------------------
# % interleave {a1 a2 a3 a4} {b1 b2 b3 b4} {c1 c2 c3 c4} {d1 d2 d3 d4}
# a1 b1 c1 d1 a2 b2 c2 d2 a3 b3 c3 d3 a4 b4 c4 d4
#
# % set elems {when 900 years old you reach look as good you will not}
#  array set my_set [interleave $elems {}]
# % array names my_set
# will as years not good look you 900 when reach old
#------------------------------------------------------------------------
proc ::tb::tcl::linterleave {args} {
  if {[llength $args] == 0} {return {}}
  set data {}
  set idx  0
  set head {}
  set body "lappend data"
  foreach arg $args {
    lappend head v$idx $arg
    append  body " \$v$idx"
    incr idx
  }
  eval foreach $head [list $body]
  return $data
}

#------------------------------------------------------------------------
# ::tb::tcl::lintersect
#------------------------------------------------------------------------
# Intersection between 2 lists
#------------------------------------------------------------------------
proc ::tb::tcl::lintersect {a b} {
  foreach e $a {
    set x($e) {}
  }
  set result {}
  foreach e $b {
    if {[info exists x($e)]} {
      lappend result $e
    }
  }
  return $result
}

# proc ::tb::tcl::lintersect {args} {
#   set res [list]
#   foreach element [lindex $args 0] {
#     set found 1
#     foreach list [lrange $args 1 end] {
#       if {[lsearch -exact $list $element] < 0} {
#         set found 0; break
#       }
#     }
#     if {$found} {lappend res $element}
#   }
#   set res
# }

#------------------------------------------------------------------------
# ::tb::tcl::ldiff
#------------------------------------------------------------------------
# Difference between 2 lists
#------------------------------------------------------------------------
proc ::tb::tcl::ldiff {a b} {
#   upvar $la a
#   upvar $lb b
  set diff [list]
  foreach i $a {
    if { [lsearch -exact $b $i]==-1} { 
      lappend diff $i 
    }
  }
  foreach i $b {
    if { [lsearch -exact $a $i]==-1} { 
      if { [lsearch -exact $diff $i]==-1} { 
        lappend diff $i 
      }
    }
  }
  return $diff
}

#------------------------------------------------------------------------
# ::tb::tcl::lmap
#------------------------------------------------------------------------
# Return a new list by applying an expresion to all elements of a list
#------------------------------------------------------------------------
# % set l [list a b c d]
#  a b c d
#
# % lmap l { format %s%s $_ $_ }
#  aa bb cc dd
#------------------------------------------------------------------------
proc ::tb::tcl::lmap {l expr} {
  upvar $l list
  set res [list]
  foreach _ $list {
    lappend res [eval $expr]
  }
  return $res
}

#------------------------------------------------------------------------
# ::tb::tcl::lgrep
#------------------------------------------------------------------------
# Return a new list of all the elements that matching the expression
#------------------------------------------------------------------------
# % set l [list a b c d]
#  a b c d
#
# % lgrep l { string match *d* $_ }
#  d
#------------------------------------------------------------------------
proc ::tb::tcl::lgrep {l expr} {
  upvar $l list
  set res [list]
  foreach _ $list {
    if [eval $expr] {
      lappend res $_
    }
  }
  return $res
}

#------------------------------------------------------------------------
# ::tb::tcl::lexpand
#------------------------------------------------------------------------
# Expand multiple lists and call external proc on each of the
# combination
#------------------------------------------------------------------------
# % proc foo {args} { puts "<[llength $args]:$args>" }
# % lexpand foo {1 2} {a b}
#    <2:1 a>
#    <2:1 b>
#    <2:2 a>
#    <2:2 b>
#------------------------------------------------------------------------
proc ::tb::tcl::lexpand { fct args } {
  set cmd {}
  set count [llength $args]
  foreach L [lrevert $args] {
    incr count -1
    set cmd [format "foreach _%s_ {%s} \{ %s " $count $L $cmd]
  }
  append cmd "$fct"
  for {set i 0} {$i < [llength $args]} {incr i} { append cmd " \$_${i}_" }
  append cmd [string repeat "\}" [llength $args] ]
# puts "<cmd:$cmd>"
  uplevel 1 [list eval $cmd]
  return 0
}

#------------------------------------------------------------------------
# ::tb::tcl::lequal
#------------------------------------------------------------------------
# Return 1 if 2 list are equal, 0 otherwise
#------------------------------------------------------------------------
proc ::tb::tcl::lequal {l1 l2} {
  if {[llength $l1] != [llength $l2]} {
    return false
  }
  set l2 [lsort $l2]
  foreach elem $l1 {
    set idx [lsearch -exact -sorted $l2 $elem]
    if {$idx == -1} {
        return false
    } else {
        set l2 [lreplace [K $l2 [unset l2]] $idx $idx]
    }
  }
  return [expr {[llength $l2] == 0}]
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


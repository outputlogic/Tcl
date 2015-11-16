########################################################################################
##
## Company:        Xilinx, Inc.
## Created by:     David Pefourque
## 
## Version:        05/23/2013
## Description:    This package provides a simple way to handle trees
##
##
## BASIC USAGE:
## ============
## 
## 1- Create new tree with 1 root and 9 nodes
##
##  set root [tree createnode {root node}]
##  $root setasroot
##  set n1 [tree createnode {node 1}]
##  set n2 [tree createnode {node 2}]
##  set n3 [tree createnode {node 3}]
##  set n4 [tree createnode {node 4}]
##  set n5 [tree createnode {node 5}]
##  set n6 [tree createnode {node 6}]
##  set n7 [tree createnode {node 7}]
##  set n8 [tree createnode {node 8}]
##  set n9 [tree createnode {node 9}]
##  $root addchildren [list $n1 $n2 $n3]
##  $n1 addchildren [list $n4 $n5 $n6]
##  $n5 addchildren [list $n7 $n8 $n9]
##
## 2- Printing and reporting
##
##  $root print
##  $root print -level 3
##  $root info
##  $root stats
##  $root isroot
##  $n1 info
##  $n1 stats
##  $n1 descendants
##  $n1 descendants oldestfirst
##  $n1 descendants depthfirst
##  $n1 descendants breadthfirst
##  $n9 ancestors
##  $n9 ancestors newestfirst
##  $n9 ancestors depthfirst
##  $n9 ancestors breadthfirst
##  $n9 isleaf
##  $root find {node 7}
##  $root leaves
##  $n5 parents
##  $n5 children
##  $n5 siblings
##  
##
## ADVANCED USAGE:
## ===============
## 
## 1- Custom parameters
##
##  $n5 set myparam1 myvalue1
##  $n5 set myparam2 myvalue2
##  $n5 set myparam3 myvalue3
##  $n5 info
##  $n5 serialize
##  $n9 deserialize [list p1 v1 p2 v2 p3 v3]
##  $n9 info
##  $n9 serialize
##  
## 2- Custom pruning
##
##  proc foo1 {self} {
##    puts "Pruning $self"
##    return 0
##  }
##  proc foo2 {self} {
##    puts "Pruning $self"
##    if {[lsearch [list ::tree::6] $self] != -1} { return 1 }
##    if {[lsearch [list ::tree::7] $self] != -1} { return -1 }
##    return 0
##  }
##  $root prune ::foo1
##  $root prune ::foo2
##  $root prune ::foo2 depthfirst
##  
## 3- Custom printing
##
##  proc myprint {self class} {
##    # The format can be different depending on the node class
##    switch [string tolower $class] {
##      node {
##        return "$self\t(name:[$self name])(class:[$self class])"
##      }
##      root {
##        return "\n$self (class:[$self class])"
##      }
##      world {
##        return "\n*${self}* (class:[$self class])"
##      }
##      default {
##        error "unknown type '$class'"
##      }
##    }
##  }
##  $root print -format ::myprint
## 
## 
########################################################################################


proc tree {args} {
  return [uplevel [concat ::tree::main $args]]
}

eval [list namespace eval ::tree { 
  variable n 0 
  variable params [list clock 0 debug 0 depth -1 maxdepth 10 parents [list] children [list] class {NODE} name {} ]
  variable data [list]
  variable version {05-20-2013}
  variable nodes [list]
  variable roots [list]
  variable world {}
  variable last {}
  variable maxnumnodes 1000
  variable dump:output {}
  variable dump:format {::tree::private:format}
} ]

#------------------------------------------------------------------------
# ::tree::main
#------------------------------------------------------------------------
# Main function
#------------------------------------------------------------------------
proc ::tree::main { args } {
  # Summary :
  # Argument Usage:
  # Return Value:

  #-------------------------------------------------------
  # Process command line arguments
  #-------------------------------------------------------
  set error 0
  set show_help 0
  if {[llength $args] == 0} { set args {-help} }
  set method [lshift args]
  switch -exact -- $method {
    createnode {
      return [eval [concat ::tree::private:createnode $args] ]
    }
    getorcreatenode {
      return [eval [concat ::tree::private:getorcreatenode $args] ]
    }
    sizeof {
      return [eval [concat ::tree::private:sizeof] ]
    }
    info {
      return [eval [concat ::tree::private:info] ]
    }
    destroyall {
      return [eval [concat ::tree::private:destroyall] ]
    }
    export {
      return [eval [concat ::tree::private:export $args] ]
    }
    last {
      # Return last created node
      return $::tree::last
    }
    world {
      # Return the world node
      return $::tree::world
    }
    root -
    roots {
      # Return the root nodes
      return $::tree::roots
    }
    node -
    nodes {
      # Return all the node
      return $::tree::nodes
    }
    stats {
      if {$::tree::world != {}} {
        $::tree::world stats
        return 0
      } else {
        return 1
      }
    }
    print {
      if {$::tree::world != {}} {
        eval [concat $::tree::world print $args]
        return 0
      } else {
        return 1
      }
    }
    -h -
    -help {
      incr show_help
    }
    default {
      error "Wrong argument to ::tree::main"
    }
  }
  
  if {$show_help} {
    # <-- HELP
    puts [format {
      Usage: tree
                  [createnode]           - Create a new node object
                  [getorcreatenode]      - Return node if exists or create a new node
                  [last]                 - Return last created node
                  [nodes]                - Return all the nodes
                  [roots]                - Return all the root nodes
                  [world]                - Return all the world node
                  [stats]                - Generate various statistics
                  [sizeof]               - Provides the memory consumption of all the tree objects
                  [info]                 - Provides a summary of all the tree objects that have been created
                  [destroyall]           - Destroy all the tree objects and release the memory
                  [-h|-help]             - This help message
                  
      Description: Utility to create and manipulate trees
      
      Example Script:
         set root [tree createnode]
         $root setasroot
         $root destroy
    
    } ]
    # HELP -->
    return
  }

}

#------------------------------------------------------------------------
# ::tree::print
#------------------------------------------------------------------------
# Dump the beautified tree from the world object
#------------------------------------------------------------------------
proc ::tree::print {args} {
  return [eval [concat ::tree::main print $args]]
}

#------------------------------------------------------------------------
# ::tree::private:createnode
#------------------------------------------------------------------------
# Constructor for a new tree object
#------------------------------------------------------------------------
proc ::tree::private:createnode { {name {}} } {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable n
  if {[llength $::tree::nodes] >= $::tree::maxnumnodes} {
    error "cannot create new node. The maximum number of nodes ($::tree::maxnumnodes) has been reached"
  }
  # Search for the next available object number, i.e namespace should not 
  # already exist
  while { [namespace exist [set instance [namespace current]::[incr n]] ]} {}
  namespace eval $instance { 
    variable params
    variable data
  }
  catch {unset ${instance}::params}
  catch {unset ${instance}::data}
  array set ${instance}::params $::tree::params
  array set ${instance}::data $::tree::data
  # Update the default settings
  set ${instance}::params(class) {NODE}
  set ${instance}::params(name) $name
  set ${instance}::params(clock) [clock clicks]
  # Save the node element
  lappend ::tree::nodes $instance
  # Last node created
  set ::tree::last $instance
  interp alias {} $instance {} ::tree::private:do $instance
  set instance
}

#------------------------------------------------------------------------
# ::tree::private:getorcreatenode
#------------------------------------------------------------------------
# Get the first object with the specified name or create a new one.
#------------------------------------------------------------------------
proc ::tree::private:getorcreatenode { {name {}} } {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable n
  if {$::tree::world != {}} {
    set node [$::tree::world find $name]
    if {$node == {}} {
      set node [::tree::private:createnode $name]
    }
    return $node
  } else {
    return {}
  }
}

#------------------------------------------------------------------------
# ::tree::private:export
#------------------------------------------------------------------------
# Export tree structure to file
#------------------------------------------------------------------------
proc ::tree::private:export {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  if {[llength $args] != 1} {
    error "wrong number of parameters: ::tree::private:export <filename>"
  }
  set filename [lindex $args 0]
  set FH [open $filename {w}]
  puts $FH "\n########################"
  puts $FH "# Create nodes"
  puts $FH "########################"
  foreach node $::tree::nodes {
    regsub -all {::tree::} $node {node_} var
    # Do not export the 'world' node as it is automatically created once a 'root' node exists
    if {[$node isworld]} { continue }
    puts $FH [format {set %s [tree createnode {%s}]} $var [$node name]]
    if {[$node isroot]} {
      puts $FH [format {$%s setasroot} $var]
    }
  }
  puts $FH "\n########################"
  puts $FH "# Configure nodes"
  puts $FH "########################"
  foreach node $::tree::nodes {
    regsub -all {::tree::} $node {node_} var
    if {[$node isworld]} { continue }
    set name [$node name]
    set class [$node class]
    set depth [subst $${node}::params(depth)]
    set children [$node children]
    set parents [$node parents]
    set cmd [list]
    regsub -all {::tree::} $children {$node_} children
    regsub -all {::tree::} $parents {$node_} parents
    regsub -all {::tree::} $cmd {$node_} cmd
    if {[$node isroot]} {
      puts $FH [format {$%s configure %s -children [list %s]} $var $cmd $children]
    } else {
      puts $FH [format {$%s configure %s -children [list %s] -parents [list %s]} $var $cmd $children $parents]
    }
    set data [$node serialize]
    if {$data != {}} {
      puts $FH [format {$%s deserialize [list %s ]} $var [$node serialize]]
    }
  }
  close $FH
}

#------------------------------------------------------------------------
# ::tree::private:sizeof
#------------------------------------------------------------------------
# Memory footprint of all the existing tree objects
#------------------------------------------------------------------------
proc ::tree::private:sizeof {} {
  # Summary :
  # Argument Usage:
  # Return Value:

  return [::tree::method:sizeof ::tree]
}

#------------------------------------------------------------------------
# ::tree::private:format
#------------------------------------------------------------------------
# Default printing format for the tree
#------------------------------------------------------------------------
proc ::tree::private:format {self class} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # The format can be different depending on the node class
  switch [string tolower $class] {
    node {
      return "$self\t(name:[$self name])(class:[$self class])"
    }
    root {
      return "\n$self"
    }
    world {
      return "\n*${self}*"
    }
    default {
      error "unknown type '$class'"
    }
  }
}

#------------------------------------------------------------------------
# ::tree::private:info
#------------------------------------------------------------------------
# Provide information about all the existing tree objects
#------------------------------------------------------------------------
proc ::tree::private:info {} {
  # Summary :
  # Argument Usage:
  # Return Value:

  foreach child [lsort -dictionary [namespace children]] {
    puts "\n  Object $child"
    puts "  ==================="
    $child info
  }
  return 0
}

#------------------------------------------------------------------------
# ::tree::private:destroyall
#------------------------------------------------------------------------
# Detroy all the existing tree objects and release the memory
#------------------------------------------------------------------------
proc ::tree::private:destroyall {} {
  # Summary :
  # Argument Usage:
  # Return Value:

  set count 0
  foreach child [namespace children] {
    $child destroy
    incr count
  }
  puts "  $count object(s) have been destroyed"
  # Reset counter
  set ::tree::n 0
  return 0
}

#------------------------------------------------------------------------
# ::tree::private:docstring
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Return the embedded help of a proc
#------------------------------------------------------------------------
proc ::tree::private:docstring {procname} {
  # Summary :
  # Argument Usage:
  # Return Value:

  if {[info proc $procname] ne $procname} { return }
  # reports a proc's args and leading comments.
  # Multiple documentation lines are allowed.
  set res ""
  # This comment should not appear in the docstring
  foreach line [split [uplevel 1 [list info body $procname]] \n] {
      if {[string trim $line] eq ""} continue
      # Skip comments that have been added to support rdi::register_proc command
      if {[regexp -nocase -- {^\s*#\s*(Summary|Argument Usage|Return Value)\s*\:} $line]} continue
      if {![regexp {^\s*#(.+)} $line -> line]} break
      lappend res [string trim $line]
  }
  join $res \n
}

#------------------------------------------------------------------------
# ::tree::lshift
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Stack function
#------------------------------------------------------------------------
proc ::tree::lshift {inputlist} {
  # Summary :
  # Argument Usage:
  # Return Value:

  upvar $inputlist argv
  set arg  [lindex $argv 0]
  set argv [lrange $argv 1 end]
  return $arg
}

#------------------------------------------------------------------------
# ::tree::lremove
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Remove element from a list
#------------------------------------------------------------------------
proc ::tree::lremove {_list el} {
  # Summary :
  # Argument Usage:
  # Return Value:

  upvar 1 $_list list
  set pos [lsearch -exact $list $el]
  set list [lreplace $list $pos $pos]
}

#------------------------------------------------------------------------
# ::tree::ldraw
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Draw a random element from a list
#------------------------------------------------------------------------
proc ::tree::ldraw {L} {
  # Summary :
  # Argument Usage:
  # Return Value:

  return [ lindex $L [expr {int(rand()*[llength $L])}] ]
}

#------------------------------------------------------------------------
# ::tree::lflatten
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Flatten a list
#------------------------------------------------------------------------
proc ::tree::lflatten {L} {
  # Summary :
  # Argument Usage:
  # Return Value:

  while { $L != [set L [join $L]] } { }
  return $L
}

#------------------------------------------------------------------------
# ::tree::lflatten
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Reverse a list a list
#------------------------------------------------------------------------
proc ::tree::lrevert {L} {
  # Summary :
  # Argument Usage:
  # Return Value:

  set res {}
  set i [llength $L]
  while {$i} {lappend res [lindex $L [incr i -1]]}
  set res
}

#------------------------------------------------------------------------
# ::tree::isnode
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Return 1 if the node exists and is a valid node
#------------------------------------------------------------------------
proc ::tree::isnode {node} {
  # Summary :
  # Argument Usage:
  # Return Value:

  if {[info exists ${node}::params]} {
    return 1
  } else {
    return 0
  }
}

#------------------------------------------------------------------------
# ::tree::private:do
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Dispatcher with methods
#------------------------------------------------------------------------
proc ::tree::private:do {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  upvar #0 ${self}::table table
  upvar #0 ${self}::indent indent
  if {[llength $args] == 0} {
#     error "wrong number of parameters: <treeObject> <method> \[<arguments>\]"
    set method {?}
  } else {
    # The first argument is the method
    set method [lshift args]
  }
  if {[info proc ::tree::method:${method}] == "::tree::method:${method}"} {
    eval ::tree::method:${method} $self $args
  } else {
    # Search for a unique matching method among all the available methods
    set match [list]
    foreach procname [info proc ::tree::method:*] {
      if {[string first $method [regsub {::tree::method:} $procname {}]] == 0} {
        lappend match [regsub {::tree::method:} $procname {}]
      }
    }
    switch [llength $match] {
      0 {
        error "unknown method $method"
      }
      1 {
        set method $match
        eval ::tree::method:${method} $self $args
      }
      default {
        error "multiple methods match '$method': $match"
      }
    }
  }
}

#------------------------------------------------------------------------
# ::tree::method:?
#------------------------------------------------------------------------
# Usage: <treeObject> ?
#------------------------------------------------------------------------
# Return all the available methods. The methods with no embedded help
# are not displayed (i.e hidden)
#------------------------------------------------------------------------
proc ::tree::method:? {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # This help message
  puts "   Usage: <treeObject> <method> \[<arguments>\]"
  puts "   Where <method> is:"
  foreach procname [lsort [info proc ::tree::method:*]] {
    regsub {::tree::method:} $procname {} method
    set help [::tree::private:docstring $procname]
    if {$help ne ""} {
      puts "       [format {%-12s%s- %s} $method \t $help]"
    }
  }
  puts ""
}

#------------------------------------------------------------------------
# ::tree::method:get_param
#------------------------------------------------------------------------
# **HIDDEN**
#------------------------------------------------------------------------
# Usage: <treeObject> get_param <param>
#------------------------------------------------------------------------
# Get a parameter from the 'params' associative array
#------------------------------------------------------------------------
proc ::tree::method:get_param {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  if {[llength $args] != 1} {
    error "wrong number of parameters: <treeObject> get_param <param>"
  }
  if {![info exists ${self}::params([lindex $args 0])]} {
    error "unknown parameter '[lindex $args 0]'"
  }
  return [subst $${self}::params([lindex $args 0])]
}

#------------------------------------------------------------------------
# ::tree::method:set_param
#------------------------------------------------------------------------
# **HIDDEN**
#------------------------------------------------------------------------
# Usage: <treeObject> set_param <param> <value>
#------------------------------------------------------------------------
# Set a parameter inside the 'params' associative array
#------------------------------------------------------------------------
proc ::tree::method:set_param {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  if {[llength $args] < 2} {
    error "wrong number of parameters: <treeObject> set_param <param> <value>"
  }
  set ${self}::params([lindex $args 0]) [lrange $args 1 end]
  return 0
}

#------------------------------------------------------------------------
# ::tree::method:get
#------------------------------------------------------------------------
# Usage: <treeObject> get <param>
#------------------------------------------------------------------------
# Get a parameter from the 'data' associative array
#------------------------------------------------------------------------
proc ::tree::method:get {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Get a user parameter
  if {[llength $args] != 1} {
    error "wrong number of parameters: <treeObject> get <param>"
  }
  if {![info exists ${self}::data([lindex $args 0])]} {
#     error "unknown parameter '[lindex $args 0]'"
    return {}
  }
  return [subst $${self}::data([lindex $args 0])]
}

#------------------------------------------------------------------------
# ::tree::method:set
#------------------------------------------------------------------------
# Usage: <treeObject> set <param> <value>
#------------------------------------------------------------------------
# Set a parameter inside the 'data' associative array
#------------------------------------------------------------------------
proc ::tree::method:set {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Set a user parameter
  if {[llength $args] < 2} {
    error "wrong number of parameters: <treeObject> set <param> <value>"
  }
  set ${self}::data([lindex $args 0]) [lrange $args 1 end]
  return 0
}

#------------------------------------------------------------------------
# ::tree::method:deserialize
#------------------------------------------------------------------------
# Usage: <treeObject> deserialize
#------------------------------------------------------------------------
# Set the content of 'data' associative array with <list>
#------------------------------------------------------------------------
proc ::tree::method:deserialize {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Deserialize the user parameters
  if {[llength $args] != 1} {
    error "wrong number of parameters: <treeObject> serialize <list>"
  }
  catch {unset ${self}::data}
  array set ${self}::data [lindex $args 0]
  return 0
}

#------------------------------------------------------------------------
# ::tree::method:serialize
#------------------------------------------------------------------------
# Usage: <treeObject> serialize <list>
#------------------------------------------------------------------------
# Get the content of 'data' associative array as a Tcl list
#------------------------------------------------------------------------
proc ::tree::method:serialize {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Serialize the user parameters
  if {[llength $args] != 0} {
    error "wrong number of parameters: <treeObject> deserialize"
  }
  return [array get ${self}::data]
}

#------------------------------------------------------------------------
# ::tree::method:destroy
#------------------------------------------------------------------------
# Usage: <treeObject> destroy
#------------------------------------------------------------------------
# Destroy an object and release its memory footprint. The object is not
# accessible anymore after that command
#------------------------------------------------------------------------
proc ::tree::method:destroy {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Destroy node
  upvar #0 ${self}::params params
  # Remove references of that objects inside the parents
  foreach parent $params(parents) {
    ::tree::lremove ${parent}::params(children) $self
  }
  # Remove references of that objects inside the children
  foreach child $params(children) {
    ::tree::lremove ${child}::params(parents) $self
  }
  # Now destroy the object
  if {[$self isworld]} {
    set ::tree::world {}
  }
  if {[$self isroot]} {
#     $self unsetasroot
    ::tree::method:unsetasroot $self
  }
  # Remove the object from the list of nodes
  ::tree::lremove ::tree::nodes $self
  catch {unset ${self}::params}
  namespace delete $self
  return 0
}

#------------------------------------------------------------------------
# ::tree::method:destroyall
#------------------------------------------------------------------------
# Usage: <treeObject> destroyall
#------------------------------------------------------------------------
# Destroy an object and all its descendants. The object are not
# accessible anymore after that command
#------------------------------------------------------------------------
proc ::tree::method:destroyall {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Destroy the node and all its descendants
  set count 1
  # Destroy all the descendants first
  foreach descendant [$self descendants] {
    $descendant destroy
    incr count
  }
  # Destroy object last
  $self destroy
  puts "  $count object(s) have been destroyed"
  return 0
}

#------------------------------------------------------------------------
# ::tree::method:cut
#------------------------------------------------------------------------
# Usage: <treeObject> cut
#------------------------------------------------------------------------
# Cut an object from its parents and children. Children of the object
# become the children of the parents and vice versa
#------------------------------------------------------------------------
proc ::tree::method:cut {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Cut node from its relationships
  upvar #0 ${self}::params params
  if {[$self isworld]} {
    error "cannot cut the world node"
  }
  if {[$self isroot]} {
    error "cannot cut a root node"
  }
  # Add the children of that objects to the parents of that objects
  foreach parent $params(parents) {
    $parent configure -addchildren $params(children)
  }
  # Remove references of that objects inside the parents
  foreach parent $params(parents) {
    ::tree::lremove ${parent}::params(children) $self
  }
  set params(parents) [list]
  # Add the children of that object to its parents
  foreach child $params(children) {
    $child configure -addparents $params(parents)
  }
  # Remove references of that objects inside the children
  foreach child $params(children) {
    ::tree::lremove ${child}::params(parents) $self
  }
  set params(children) [list]
  return 0
}

#------------------------------------------------------------------------
# ::tree::method:detatch
#------------------------------------------------------------------------
# Usage: <treeObject> detatch
#------------------------------------------------------------------------
# Detatch an object from its parents and children
#------------------------------------------------------------------------
proc ::tree::method:detatch {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Detatch node from its relationships
  upvar #0 ${self}::params params
  if {[$self isworld]} {
    error "cannot cut the world node"
  }
  if {[$self isroot]} {
    error "cannot cut a root node"
  }
  # Remove references of that objects inside the parents
  foreach parent $params(parents) {
    ::tree::lremove ${parent}::params(children) $self
  }
  set params(parents) [list]
  # Remove references of that objects inside the children
  foreach child $params(children) {
    ::tree::lremove ${child}::params(parents) $self
  }
  set params(children) [list]
  return 0
}

#------------------------------------------------------------------------
# ::tree::method:sizeof
#------------------------------------------------------------------------
# Usage: <treeObject> sizeof
#------------------------------------------------------------------------
# Return the memory footprint of the object
#------------------------------------------------------------------------
proc ::tree::method:sizeof {ns args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Return memory footprint of the node
  set sum [expr wide(0)]
  foreach var [info vars ${ns}::*] {
      if {[info exists $var]} {
          upvar #0 $var v
          if {[array exists v]} {
              incr sum [string bytelength [array get v]]
          } else {
              incr sum [string bytelength $v]
          }
      }
  }
  foreach child [namespace children $ns] {
      incr sum [::tree::method:sizeof $child]
  }
  set sum
}

#------------------------------------------------------------------------
# ::tree::method:info
#------------------------------------------------------------------------
# Usage: <treeObject> info
#------------------------------------------------------------------------
# List various information about the node
#------------------------------------------------------------------------
proc ::tree::method:info {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Information about the node
  upvar #0 ${self}::params params
  upvar #0 ${self}::data data
  puts [format {    Node: %s} $self]
  foreach param [lsort [array names params]] {
    puts [format {    Param[%s]: %s} $param $params($param)]
  }
  foreach param [lsort [array names data]] {
    puts [format {    Data[%s] : %s} $param $data($param)]
  }
  puts [format {    Memory footprint: %d bytes} [::tree::method:sizeof $self]]
}

#------------------------------------------------------------------------
# ::tree::method:stats
#------------------------------------------------------------------------
# Usage: <treeObject> stats
#------------------------------------------------------------------------
# Generate various statistics about the node
#------------------------------------------------------------------------
proc ::tree::method:stats {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Statistics about the node
  upvar #0 ${self}::params params
  puts [format {    Node          : %s} $self ]
  puts [format {    Depth         : %s} [$self depth] ]
  puts [format {    # Parents     : %s} [$self numparents] ]
  puts [format {    # Children    : %s} [$self numchildren] ]
  puts [format {    # Roots       : %s} [llength [$self roots]] ]
  puts [format {    # Siblings    : %s} [$self numsiblings] ]
  puts [format {    # Ancestors   : %s} [$self numancestors] ]
  puts [format {    # Descendants : %s} [$self numdescendants] ]
  puts [format {    # Leaves      : %s} [$self numleaves] ]
  puts [format {    isWorld       : %s} [$self isworld] ]
  puts [format {    isRoot        : %s} [$self isroot] ]
  puts [format {    isNode        : %s} [$self isnode] ]
  puts [format {    isLeaf        : %s} [$self isleaf] ]
  puts [format {    isOrphan      : %s} [$self isorphan] ]
  set L [list]
  foreach leaf [$self leaves] { lappend L [$leaf depth] }
  if {$L != {}} {
    puts [format {    Max depth of all leaves: %s} [lindex [lsort -integer $L ] end] ]
  }
}

#------------------------------------------------------------------------
# ::tree::method:isroot
#------------------------------------------------------------------------
# Usage: <treeObject> isroot
#------------------------------------------------------------------------
# Return 1 if <treeObject> is the root, 0 otherwise
#------------------------------------------------------------------------
proc ::tree::method:isroot {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Return 1 if root node
  upvar #0 ${self}::params params
  if {$params(class) == {ROOT}} {
    return 1
  } else {
    return 0
  }
}

#------------------------------------------------------------------------
# ::tree::method:isnode
#------------------------------------------------------------------------
# Usage: <treeObject> isnode
#------------------------------------------------------------------------
# Return 1 if <treeObject> is a node that is NOT the root, 0 otherwise
#------------------------------------------------------------------------
proc ::tree::method:isnode {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Return 1 if node
  upvar #0 ${self}::params params
  if {$params(class) == {NODE}} {
    return 1
  } else {
    return 0
  }
}

#------------------------------------------------------------------------
# ::tree::method:isworld
#------------------------------------------------------------------------
# **HIDDEN**
#------------------------------------------------------------------------
# Usage: <treeObject> isworld
#------------------------------------------------------------------------
# Return 1 if <treeObject> is the WORLD node, 0 otherwise
#------------------------------------------------------------------------
proc ::tree::method:isworld {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  upvar #0 ${self}::params params
  if {$params(class) == {WORLD}} {
    return 1
  } else {
    return 0
  }
}

#------------------------------------------------------------------------
# ::tree::method:isleaf
#------------------------------------------------------------------------
# Usage: <treeObject> isleaf
#------------------------------------------------------------------------
# Return 1 if <treeObject> is a leaf node, 0 otherwise
#------------------------------------------------------------------------
proc ::tree::method:isleaf {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Return 1 if leaf node
  upvar #0 ${self}::params params
  if {([llength $params(children)] == 0) && ([llength $params(parents)] != 0)} {
    return 1
  } else {
    return 0
  }
}

#------------------------------------------------------------------------
# ::tree::method:isorphan
#------------------------------------------------------------------------
# Usage: <treeObject> isorphan
#------------------------------------------------------------------------
# Return 1 if <treeObject> is an orphan node, 0 otherwise
#------------------------------------------------------------------------
proc ::tree::method:isorphan {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Return 1 if orphan node
  upvar #0 ${self}::params params
  if {([llength $params(children)] == 0) && ([llength $params(parents)] == 0)} {
    return 1
  } else {
    return 0
  }
}

#------------------------------------------------------------------------
# ::tree::method:name
#------------------------------------------------------------------------
# Usage: <treeObject> name
#------------------------------------------------------------------------
# Return the node name
#------------------------------------------------------------------------
proc ::tree::method:name {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Return the node name
  upvar #0 ${self}::params params
  return $params(name)
}

#------------------------------------------------------------------------
# ::tree::method:class
#------------------------------------------------------------------------
# Usage: <treeObject> class
#------------------------------------------------------------------------
# Return the node class
#------------------------------------------------------------------------
proc ::tree::method:class {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Return the node class
  upvar #0 ${self}::params params
  return $params(class)
}

#------------------------------------------------------------------------
# ::tree::method:depth
#------------------------------------------------------------------------
# Usage: <treeObject> depth
#------------------------------------------------------------------------
# Return the node depth
#------------------------------------------------------------------------
proc ::tree::method:depth {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Return the node depth
  upvar #0 ${self}::params params
  # If the depth is available, then return it
  if {$params(depth) != -1} { return $params(depth) }
  # Otherwise calculate it
  if {$params(class) == {WORLD}} { return -1 }
  if {$params(parents) == {}} { return 1 }
  if {$params(class) == {ROOT}} { return 1 }
  # To make it simplier, if the object has multiple parents, then
  # the depth is calculated based on the first one. An alternative
  # would be to calculate the max depth from all the parents
  set depth [expr [[lindex $params(parents) 0] depth] + 1]
  set params(depth) $depth
  return $depth
}

#------------------------------------------------------------------------
# ::tree::method:parents
#------------------------------------------------------------------------
# Usage: <treeObject> parents
#------------------------------------------------------------------------
# Return the node parents
#------------------------------------------------------------------------
proc ::tree::method:parents {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Return the node parents
  upvar #0 ${self}::params params
  return $params(parents)
}

#------------------------------------------------------------------------
# ::tree::method:children
#------------------------------------------------------------------------
# Usage: <treeObject> children
#------------------------------------------------------------------------
# Return the node children
#------------------------------------------------------------------------
proc ::tree::method:children {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Return the node children
  upvar #0 ${self}::params params
  return $params(children)
}

#------------------------------------------------------------------------
# ::tree::method:siblings
#------------------------------------------------------------------------
# Usage: <treeObject> siblings
#------------------------------------------------------------------------
# Return the node siblings (including itself)
#------------------------------------------------------------------------
proc ::tree::method:siblings {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Return the node siblings
  set siblings [list]
  foreach parent [$self parents] {
    foreach child [$parent children] {
      lappend siblings $child
    }
  }
  return $siblings
}

#------------------------------------------------------------------------
# ::tree::method:numchildren
#------------------------------------------------------------------------
# Usage: <treeObject> numchildren
#------------------------------------------------------------------------
# Return the number of node children
#------------------------------------------------------------------------
proc ::tree::method:numchildren {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Return the number of children
  upvar #0 ${self}::params params
  return [llength $params(children)]
}

#------------------------------------------------------------------------
# ::tree::method:numparents
#------------------------------------------------------------------------
# Usage: <treeObject> numparents
#------------------------------------------------------------------------
# Return the number of node parents
#------------------------------------------------------------------------
proc ::tree::method:numparents {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Return the number of parents
  upvar #0 ${self}::params params
  return [llength $params(parents)]
}

#------------------------------------------------------------------------
# ::tree::method:numsiblings
#------------------------------------------------------------------------
# Usage: <treeObject> numsiblings
#------------------------------------------------------------------------
# Return the number of node siblings
#------------------------------------------------------------------------
proc ::tree::method:numsiblings {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Return the number of siblings
  upvar #0 ${self}::params params
  return [llength [$self siblings]]
}

#------------------------------------------------------------------------
# ::tree::method:numleaves
#------------------------------------------------------------------------
# Usage: <treeObject> numleaves
#------------------------------------------------------------------------
# Return the number of leaves under the node
#------------------------------------------------------------------------
proc ::tree::method:numleaves {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Return the number of leaves
  upvar #0 ${self}::params params
  return [llength [$self leaves]]
}

#------------------------------------------------------------------------
# ::tree::method:numdescendants
#------------------------------------------------------------------------
# Usage: <treeObject> numdescendants
#------------------------------------------------------------------------
# Return the number of descendants of the node
#------------------------------------------------------------------------
proc ::tree::method:numdescendants {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Return the number of descendants
  upvar #0 ${self}::params params
  return [llength [$self descendants]]
}

#------------------------------------------------------------------------
# ::tree::method:numancestors
#------------------------------------------------------------------------
# Usage: <treeObject> numancestors
#------------------------------------------------------------------------
# Return the number of ancestors of the node
#------------------------------------------------------------------------
proc ::tree::method:numancestors {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Return the number of ancestors
  upvar #0 ${self}::params params
  return [llength [$self ancestors]]
}

#------------------------------------------------------------------------
# ::tree::method:find
#------------------------------------------------------------------------
# Usage: <treeObject> find <name>
#------------------------------------------------------------------------
# Find if one of the descendants has the same name
#------------------------------------------------------------------------
proc ::tree::method:find {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Find first descendant that matches provided name
  upvar #0 ${self}::params params
  if {[llength $args] != 1} {
    error "wrong number of parameters: <treeObject> find <name>"
  }
  set name [lindex $args 0]
  if {[$self name] == $name} {
    return $self
  }
  foreach child $params(children) {
    if {[set c [$child find $name]] != {}} {
      # Return the first child found
      return $c
    }
  }
  # Nothing found, return empty string
  return {}
}

#------------------------------------------------------------------------
# ::tree::method:findall
#------------------------------------------------------------------------
# Usage: <treeObject> findall <name>
#------------------------------------------------------------------------
# Find all the descendant that have the same name
#------------------------------------------------------------------------
proc ::tree::method:findall {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Find all descendants that match provided name
  upvar #0 ${self}::params params
  if {[llength $args] != 1} {
    error "wrong number of parameters: <treeObject> find <name>"
  }
  set name [lindex $args 0]
  set allnodes [list]
  if {[$self name] == $name} {
    lappend allnodes $self
  }
  foreach child $params(children) {
    if {[set c [$child findall $name]] != {}} {
      # Return all the children found
      set allnodes [concat $allnodes $c]
    }
  }
  # Return all found nodes
  return $allnodes
}

#------------------------------------------------------------------------
# ::tree::method:getorcreatenode
#------------------------------------------------------------------------
# Usage: <treeObject> getorcreatenode <name>
#------------------------------------------------------------------------
# Return the first descendant that has the same name or create new node
#------------------------------------------------------------------------
proc ::tree::method:getorcreatenode {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Return first descendant that matches provided name or create new node
  upvar #0 ${self}::params params
  if {[llength $args] != 1} {
    error "wrong number of parameters: <treeObject> getorcreatenode <name>"
  }
  set name [lindex $args 0]
  set node [$self find $name]
  if {$node != {}} {
    return $node
  }
  return [::tree::private:createnode $name]
}

#------------------------------------------------------------------------
# ::tree::method:descendants
#------------------------------------------------------------------------
# Usage: <treeObject> descendants
#------------------------------------------------------------------------
# Get all the descendants of the node
#------------------------------------------------------------------------
proc ::tree::method:descendants {self {mode {oldestfirst}}} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Return all the descendants
  upvar #0 ${self}::params params
  set mode [string tolower $mode]
  if {$mode == {oldestfirst}} {
    # Traversal from the oldest to the newest
    set descendants [list]
    foreach child $params(children) {
      set descendants [concat $descendants $child [$child descendants $mode]]
    }
  } elseif {$mode == {depthfirst}} {
    # Depth-first traversal
    set descendants [list]
    foreach child $params(children) {
      set descendants [concat $descendants [$child descendants $mode] $child]
    }
  } elseif {$mode == {breadthfirst}} {
    # Breadth-first traversal
    set descendants $params(children)
    foreach child $params(children) {
      set descendants [concat $descendants [$child descendants $mode]]
    }
  } else {
    error "unknown traversal mode '$mode'. The valid modes are: oldestfirst depthfirst breadthfirst"
  }
  return $descendants
}

#------------------------------------------------------------------------
# ::tree::method:leaves
#------------------------------------------------------------------------
# Usage: <treeObject> leaves
#------------------------------------------------------------------------
# Get all the descendants of the object which are leaves
#------------------------------------------------------------------------
proc ::tree::method:leaves {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Return all the leaves below the node
  set descendants [$self descendants]
  set leaves [list]
  foreach descendant $descendants {
    if {[$descendant isleaf]} {
      lappend leaves $descendant
    }
  }
  return $leaves
}

#------------------------------------------------------------------------
# ::tree::method:roots
#------------------------------------------------------------------------
# Usage: <treeObject> roots
#------------------------------------------------------------------------
# Get all the roots of the object
#------------------------------------------------------------------------
proc ::tree::method:roots {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Return all the root(s) of the node
  set ancestors [$self ancestors]
  set roots [list]
  foreach ancestor $ancestors {
    if {[$ancestor isroot]} {
      lappend roots $ancestor
    }
  }
  return $roots
}

#------------------------------------------------------------------------
# ::tree::method:ancestors
#------------------------------------------------------------------------
# Usage: <treeObject> ancestors
#------------------------------------------------------------------------
# Get all the ancestors of the node
#------------------------------------------------------------------------
proc ::tree::method:ancestors {self {mode {newestfirst}}} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Return all the ancestors
  upvar #0 ${self}::params params
  set mode [string tolower $mode]
  if {[$self isworld]} { return {} }
  if {$mode == {newestfirst}} {
    # Traversal from the oldest to the newest
    set ancestors [list]
    foreach parent $params(parents) {
      if {[$parent isworld]} { continue }
      set ancestors [concat $ancestors $parent [$parent ancestors $mode]]
    }
  } elseif {$mode == {depthfirst}} {
    # Depth-first traversal
    set ancestors [list]
    foreach parent $params(parents) {
      if {[$parent isworld]} { continue }
      set ancestors [concat $ancestors [$parent ancestors $mode] $parent]
    }
  } elseif {$mode == {breadthfirst}} {
    # Breadth-first traversal
    set ancestors [list]
    foreach parent $params(parents) {
      if {[$parent isworld]} { continue }
      lappend ancestors $parent
    }
    foreach parent $params(parents) {
      if {[$parent isworld]} { continue }
      set ancestors [concat $ancestors [$parent ancestors $mode]]
    }
  } else {
    error "unknown traversal mode '$mode'. The valid modes are: newestfirst depthfirst breadthfirst"
  }
  return $ancestors
}

#------------------------------------------------------------------------
# ::tree::method:setasroot
#------------------------------------------------------------------------
# Usage: <treeObject> setasroot
#------------------------------------------------------------------------
# Set a node as a root node
#------------------------------------------------------------------------
proc ::tree::method:setasroot {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Set a node as a root node
  upvar #0 ${self}::params params
  if {$params(class) == {ROOT}} {
    error "node is already a root node"
  }
  if {$params(parents) != {}} {
    error "cannot set as root a node that has some parents"
  }
  lappend ::tree::roots $self
  set params(class) {ROOT}
  # Now add the new root node as a child of the world node
  if {$::tree::world == {}} {
    set ::tree::world [::tree::private:createnode]
#     $::tree::world configure -class world
#     eval set ${::tree::world}::params(class) {WORLD}
    set ${::tree::world}::params(class) {WORLD}
  }
  lappend params(parents) $::tree::world
  lappend ${::tree::world}::params(children) $self
  set ${::tree::world}::params(children) [lsort -unique [subst $${::tree::world}::params(children)]]
  return 0
}

#------------------------------------------------------------------------
# ::tree::method:unsetasroot
#------------------------------------------------------------------------
# **HIDDEN**
#------------------------------------------------------------------------
# Usage: <treeObject> unsetasroot
#------------------------------------------------------------------------
# Convert a root node as a regular node
#------------------------------------------------------------------------
proc ::tree::method:unsetasroot {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  upvar #0 ${self}::params params
  if {$params(class) != {ROOT}} {
    error "node is not a root node"
  }
  ::tree::lremove ::tree::roots $self
  ::tree::lremove ${self}::params(parents) $::tree::world
  set params(class) {NODE}
  # Now remove the root node as a child of the world node
  if {$::tree::world != {}} {
    ::tree::lremove ${::tree::world}::params(children) $self
 }
  return 0
}

#------------------------------------------------------------------------
# ::tree::method:addchildren
#------------------------------------------------------------------------
# Usage: <treeObject> addchildren
#------------------------------------------------------------------------
# Add children nodes to a node
#------------------------------------------------------------------------
proc ::tree::method:addchildren {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Add children to the node
  upvar #0 ${self}::params params
  set error 0
  foreach child [::tree::lflatten $args] {
    if {([$self isroot] && [$child isnode]) || ([$self isworld] && [$child isroot]) || ([$self isnode] && [$child isnode])} { set valid 1 } else { set valid 0 }
    if {$valid} {
      if {[lsearch $params(children) $child] == -1} {
        lappend params(children) $child
        # Add the parent to the child too
        if {[lsearch [subst $${child}::params(parents)] $self] == -1} {
          lappend ${child}::params(parents) $self
        }
      } else {
        puts " -W- node $child is already a child of $self"
        incr error
      }
    } else {
      error "cannot add a node of type [subst $${child}::params(class)] as a child of a node of type [subst $${self}::params(class)]"
    }
  }
  if {$error} {return 1} else { return 0}
}

#------------------------------------------------------------------------
# ::tree::method:addparents
#------------------------------------------------------------------------
# Usage: <treeObject> addparents
#------------------------------------------------------------------------
# Add parent nodes to a node
#------------------------------------------------------------------------
proc ::tree::method:addparents {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Add parents to the node
  upvar #0 ${self}::params params
  set error 0
  foreach parent [::tree::lflatten $args] {
    if {([$self isroot] && [$parent isworld]) || ([$self isnode] && [$parent isroot]) || ([$self isnode] && [$parent isnode])} { set valid 1 } else { set valid 0 }
    if {$valid} {
      if {[lsearch $params(parents) $parent] == -1} {
        lappend params(parents) $parent
        # Add the child to the parent too
        if {[lsearch [subst $${parent}::params(children)] $self] == -1} {
          lappend ${parent}::params(children) $self
        }
      } else {
        puts " -W- node $parent is already a parent of $self"
        incr error
      }
    } else {
      error "cannot add a node of type [subst $${parent}::params(class)] as a parent of a node of type [subst $${self}::params(class)]"
    }
  }
  if {$error} {return 1} else { return 0}
}

#------------------------------------------------------------------------
# ::tree::method:removechildren
#------------------------------------------------------------------------
# Usage: <treeObject> removechildren
#------------------------------------------------------------------------
# Remove children nodes from a node
#------------------------------------------------------------------------
proc ::tree::method:removechildren {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Remove children from the node
  upvar #0 ${self}::params params
  set error 0
  foreach child [::tree::lflatten $args] {
    if {([$self isroot] && [$child isnode]) || ([$self isworld] && [$child isroot]) || ([$self isnode] && [$child isnode])} { set valid 1 } else { set valid 0 }
    if {$valid} {
      if {[lsearch $params(children) $child] != -1} {
        ::tree::lremove params(children) $child
        # Remove the parent from the child too
        if {[lsearch [subst $${child}::params(parents)] $self] != -1} {
          ::tree::lremove ${child}::params(parents) $self
        }
      } else {
        puts " -W- node $child is not a child of $self"
        incr error
      }
    } else {
      error "cannot remove a node of type [subst $${child}::params(class)] as a child of a node of type [subst $${self}::params(class)]"
    }
  }
  if {$error} {return 1} else { return 0}
}

#------------------------------------------------------------------------
# ::tree::method:removeparents
#------------------------------------------------------------------------
# Usage: <treeObject> removeparents
#------------------------------------------------------------------------
# Add parent nodes to a node
#------------------------------------------------------------------------
proc ::tree::method:removeparents {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Remove parents from the node
  upvar #0 ${self}::params params
  set error 0
  foreach parent [::tree::lflatten $args] {
    if {([$self isroot] && [$parent isworld]) || ([$self isnode] && [$parent isroot]) || ([$self isnode] && [$parent isnode])} { set valid 1 } else { set valid 0 }
    if {$valid} {
      if {[lsearch $params(parents) $parent] != -1} {
        ::tree::lremove params(parents) $parent
        # Remove the child to the parent too
        if {[lsearch [subst $${parent}::params(children)] $self] != -1} {
          ::tree::lremove ${parent}::params(children) $self
        }
      } else {
        puts " -W- node $parent is not a parent of $self"
        incr error
      }
    } else {
      error "cannot remove a node of type [subst $${parent}::params(class)] as a parent of a node of type [subst $${self}::params(class)]"
    }
  }
  if {$error} {return 1} else { return 0}
}

#------------------------------------------------------------------------
# ::tree::method:prune
#------------------------------------------------------------------------
# Usage: <treeObject> prune <proc> <mode>
#------------------------------------------------------------------------
# Tree traversal from current node
#------------------------------------------------------------------------
proc ::tree::method:prune {self fct {mode {oldestfirst}}} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Tree traversal from node
  upvar #0 ${self}::params params
  set mode [string tolower $mode]
  if {[info proc $fct] == {}} {
    error "proc '$fct' does not exist"
  }
  # The method calls a user proc for each node. The proc can return
  # the following value:
  #  0 - OK, continue
  #  1 - Do not prune children of that node
  #      Option only meaningful in the mode 'oldestfirst'
  # -1 - Abort, stop pruning
  if {$mode == {oldestfirst}} {
    ##########################################
    # Traversal from the oldest to the newest
    ##########################################
    set status [eval $fct $self]
    switch -- $status {
      1 {
        # Do not prune children but return the OK status
        puts " -W- not pruning children of node $self"
        return 0
      }
      -1 {
        # Abort pruning
        puts " -W- pruning aborted from node $self"
        return -1
      }
    }
    foreach child $params(children) {
      set status [::tree::method:prune $child $fct $mode]
      switch -- $status {
        -1 {
          # Abort pruning
#           puts " -W- pruning aborted from node $child"
          return -1
        }
      }
    }
  } elseif {$mode == {depthfirst}} {
    ##########################################
    # Depth-first traversal
    ##########################################
    foreach child $params(children) {
      set status [::tree::method:prune $child $fct $mode]
      switch -- $status {
        1 {
          # This option does not make sense in a depth-first traversal
          # since the children are prunes before the parents
        }
        -1 {
          # Abort pruning
#           puts " -W- pruning aborted from node $child"
          return -1
        }
      }
    }
    set status [eval $fct $self]
    switch -- $status {
      -1 {
        # Abort pruning
        puts " -W- pruning aborted from node $self"
        return -1
      }
    }
  } elseif {$mode == {breadthfirst}} {
    ##########################################
    # Breadth-first traversal
    ##########################################
    set status [eval $fct $self]
    switch -- $status {
      1 {
        # Do not prune children but return the OK status
        return 0
      }
      -1 {
        # Abort pruning
        puts " -W- pruning aborted from node $self"
        return -1
      }
    }
    set grandchildren [list]
    foreach child $params(children) {
      set status [eval $fct $child]
      switch -- $status {
        0 {
          # Ok, continue with grand-children
          set grandchildren [concat $grandchildren [subst $${child}::params(children)]]
        }
        1 {
          # Do not prune grand-children but return the OK status
#           return 0
        }
        -1 {
          # Abort pruning
#           puts " -W- pruning aborted from node $child"
          return -1
        }
      }
    }
    foreach child $grandchildren {
      set status [::tree::method:prune $child $fct $mode]
      switch -- $status {
        -1 {
          # Abort pruning
#           puts " -W- pruning aborted from node $child"
          return -1
        }
      }
    }
  } else {
    error "unknown traversal mode '$mode'. The valid modes are: oldestfirst depthfirst breadthfirst"
  }
  return 0
}

#------------------------------------------------------------------------
# ::tree::method:configure
#------------------------------------------------------------------------
# Usage: <treeObject> configure [<options>]
#------------------------------------------------------------------------
# Configure some of the object parameters
#------------------------------------------------------------------------
proc ::tree::method:configure {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Configure node parameters
  set error 0
  set help 0
  if {[llength $args] == 0} {
    set help 1
  }
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -name {
           set ${self}::params(name) [lshift args]
      }
      -class {
           set str [string toupper [lshift args]]
           if {[lsearch [list NODE ROOT WORLD] $str] != -1} {
             set ${self}::params(class) $str
           } else {
             error "unknown class '$str'"
           }
      }
      -depth {
           set ${self}::params(depth) [lshift args]
      }
      -child -
      -children {
           set ${self}::params(children) [list]
           $self addchildren [lshift args]
      }
      -addchild -
      -addchildren {
           $self addchildren [lshift args]
      }
      -removechild -
      -removechildren {
           $self removechildren [lshift args]
      }
      -parent -
      -parents {
           set ${self}::params(parents) [list]
           $self addparents [lshift args]
     }
      -addparent -
      -addparents {
           $self addparents [lshift args]
      }
      -removeparent -
      -removeparents {
           $self removeparents [lshift args]
      }
      -h -
      -help {
           set help 1
      }
      default {
            if {[string match "-*" $name]} {
              puts " -E- option '$name' is not a valid option."
              incr error
            } else {
              puts " -E- option '$name' is not a valid option."
              incr error
            }
      }
    }
  }
  
  if {$help} {
    puts [format {
  Usage: <treeObject> configure 
              [-name <string>]
              [-depth <integer>]
              [-children <list_of_nodes>]
              [-addchildren <list_of_nodes>]
              [-removechildren <list_of_nodes>]
              [-parents <list_of_nodes>]
              [-addparents <list_of_nodes>]
              [-removeparents <list_of_nodes>]
              [-help|-h]
              
  Description: Configure some of the node parameters.
  
  Example:
     <treeObject> configure -children [list $node1 $node2] -parents $node3
} ]
    # HELP -->
    return {}
  }
    
}

#------------------------------------------------------------------------
# ::tree::method:print
#------------------------------------------------------------------------
# Usage: <treeObject> print [<options>]
#------------------------------------------------------------------------
# Print the tree from the node
#------------------------------------------------------------------------
proc ::tree::method:print {self args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Print the tree
  set error 0
  set help 0
  set filename {}
  set append 0
  set format {::tree::private:format}
  set level -1
#   if {[llength $args] == 0} {
#     set help 1
#   }
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -f -
      -file -
      -filename {
           set filename [lshift args]
      }
      -a -
      -append {
           set append 1
      }
      -format {
           set format [lshift args]
      }
      -level -
      -levels {
           set level [lshift args]
      }
      -h -
      -help {
           set help 1
      }
      default {
            if {[string match "-*" $name]} {
              puts " -E- option '$name' is not a valid option."
              incr error
            } else {
              puts " -E- option '$name' is not a valid option."
              incr error
            }
      }
    }
  }
  
  if {$help} {
    puts [format {
  Usage: <treeObject> print 
              [-format <proc>]
              [-level <max_num_levels>]
              [-file <filename>]
              [-append]
              [-help|-h]
              
  Description: Print the tree from the node.
  
  Example:
     <treeObject> print -file tree.rpt -level 3
} ]
    # HELP -->
    return {}
  }
  
  if {[info proc $format] == {}} {
    error "cannot find proc '$format'"
  }
  set ::tree::dump:format $format
  
  # Clear the output
  set ::tree::dump:output {}
  # Generate the output
  $self dump $level
  
  if {$filename != {}} {
    if {$append} {
      set FH [open $filename a]
    } else {
      set FH [open $filename w]
    }
    puts $FH "# Tree generated on [clock format [clock clicks]]\n"
    puts $FH [join ${::tree::dump:output} \n]
    close $FH
    puts " -I- tree saved inside file '$filename'"
  } else {
    # Print the output to stdout
    puts [join ${::tree::dump:output} \n]
  }
 
  # Clear the output
  set ::tree::dump:output {}
  return 0
}

#------------------------------------------------------------------------
# Usage: <treeObject> dump
#------------------------------------------------------------------------
# **HIDDEN**
#------------------------------------------------------------------------
# Beautified dump the node and it's children
# http://wiki.tcl.tk/36962
#------------------------------------------------------------------------
proc ::tree::method:dump {self {level -1} args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  upvar #0 ${self}::params params
  # Did we reach the maximum number of levels to print?
  if {$level == 0} {
    # Yes
    return 0
  }
  # If the node is not the root node
  if {[$self isnode]} {
    foreach ancestor [$self ancestors {depthfirst}] {
      # If the ancestor is the root node
      if {[$ancestor isroot]} {append dumpLine " "; continue;}
      # If the ancestor is the last sibling, insert empty spaces; otherwise, insert a pipe 
#       if {[lindex [$ancestor siblings] end] == "$ancestor"} {append dumpLine "   "} else {append dumpLine " ¦ "}
      if {[lindex [$ancestor siblings] end] == "$ancestor"} {append dumpLine "   "} else {append dumpLine " | "}
    }
    # If the node is the last sibling, insert a '+-'; otherwise, insert a '+-' 
    if {[lindex [$self siblings] end] == $self} {append dumpLine " +-"} else {append dumpLine " +-"}
    # Print the tree characteres and the node's info
    lappend ::tree::dump:output "$dumpLine [eval ${::tree::dump:format} $self {node}]"
  } elseif {[$self isroot]} {
    # If the node is the root node
    lappend ::tree::dump:output [eval ${::tree::dump:format} $self {root}]
  } else {
    # If the node is the world node
    lappend ::tree::dump:output [eval ${::tree::dump:format} $self {world}]
  }
  # One level less to go
  incr level -1
  # Go recursive for each child
  foreach child [$self children] {$child dump $level}
  return 0
}



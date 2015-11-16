#!/bin/sh
# use -*-TCL-*- \
exec tclsh "$0" "$@"

###########################################################################
##
## Package for generating VCD files
##
###########################################################################

# To use this package:
#   lappend ::auto_path <directory>
#   package require VCD

#------------------------------------------------------------------------
# Namespace for the package
#------------------------------------------------------------------------

namespace eval ::VCD { 
  set n 0 
  set params [list]
  set version 0.1
}

#------------------------------------------------------------------------
# ::VCD::Create
#------------------------------------------------------------------------
# Constructor for a new VCD object
#------------------------------------------------------------------------
proc ::VCD::Create {} {
  variable n
  # Search for the next available object number, i.e namespace should not 
  # already exist
  while { [namespace exist [set instance [namespace current]::[incr n]] ]} {}
  namespace eval $instance { 
    variable params
    variable names [list]
    variable clocks [list]
    variable signals [list]
    variable transitions [list]
  }
  catch {unset ${instance}::params}
  array set ${instance}::params $::VCD::params
  interp alias {} $instance {} ::VCD::do $instance
  set instance
}

#------------------------------------------------------------------------
# ::VCD::Sizeof
#------------------------------------------------------------------------
# Memory footprint of all the existing VCD objects
#------------------------------------------------------------------------
proc ::VCD::Sizeof {} {
  return [::VCD::method:sizeof ::VCD]
}

#------------------------------------------------------------------------
# ::VCD::Info
#------------------------------------------------------------------------
# Provide information about all the existing objects
#------------------------------------------------------------------------
proc ::VCD::Info {} {
  foreach child [lsort [namespace children]] {
    puts "\n  Object $child"
    puts "  ==================="
    $child info
  }
  return 0
}

#------------------------------------------------------------------------
# ::VCD::DestroyAll
#------------------------------------------------------------------------
# Detroy all the existing objects and release the memory
#------------------------------------------------------------------------
proc ::VCD::DestroyAll {} {
  set count 0
  foreach child [namespace children] {
    $child destroy
    incr count
  }
  puts "  $count object(s) have been destroyed"
  return 0
}

#------------------------------------------------------------------------
# ::VCD::docstring
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Return the embedded help of a proc
#------------------------------------------------------------------------
proc ::VCD::docstring procname {
   if {[info proc $procname] ne $procname} { return }
   # reports a proc's args and leading comments.
   # Multiple documentation lines are allowed.
   set res ""
   # This comment should not appear in the docstring
   foreach line [split [uplevel 1 [list info body $procname]] \n] {
       if {[string trim $line] eq ""} continue
       if ![regexp {^\s*#(.+)} $line -> line] break
       lappend res [string trim $line]
   }
   join $res \n
}

#------------------------------------------------------------------------
# ::VCD::lshift
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Stack function
#------------------------------------------------------------------------
proc ::VCD::lshift {inputlist} {
  upvar $inputlist argv
  set arg  [lindex $argv 0]
  set argv [lrange $argv 1 end]
  return $arg
}

#------------------------------------------------------------------------
# ::VCD::do
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Dispatcher with methods
#------------------------------------------------------------------------
proc ::VCD::do {self args} {
  upvar #0 ${self}::names names
  upvar #0 ${self}::clocks clocks
  upvar #0 ${self}::signals signals
  upvar #0 ${self}::transitions transitions
  upvar #0 ${self}::params params
  if {[llength $args] == 0} {
#     error " -E- wrong number of parameters: <object> <method> \[<arguments>\]"
    set method {?}
  } else {
    # The first argument is the method
    set method [lshift args]
  }
  if {[info proc ::VCD::method:${method}] == "::VCD::method:${method}"} {
    eval ::VCD::method:${method} $self $args
  } else {
    # Search for a unique matching method among all the available methods
    set match [list]
    foreach procname [info proc ::VCD::method:*] {
      if {[string first $method [regsub {::VCD::method:} $procname {}]] == 0} {
        lappend match [regsub {::VCD::method:} $procname {}]
      }
    }
    switch [llength $match] {
      0 {
        error " -E- unknown method $method"
      }
      1 {
        set method $match
        eval ::VCD::method:${method} $self $args
      }
      default {
        error " -E- multiple methods match '$method': $match"
      }
    }
  }
}

#------------------------------------------------------------------------
# ::VCD::method:?
#------------------------------------------------------------------------
# Usage: <object> ?
#------------------------------------------------------------------------
# Return all the available methods. The methods with no embedded help
# are not displayed (i.e hidden)
#------------------------------------------------------------------------
proc ::VCD::method:? {self args} {
  # This help message
  puts "   Usage: <object> <method> \[<arguments>\]"
  puts "   Where <method> is:"
  foreach procname [lsort [info proc ::VCD::method:*]] {
    regsub {::VCD::method:} $procname {} method
    set help [::VCD::docstring $procname]
    if {$help ne ""} {
      puts "         [format {%-12s%s- %s} $method \t $help]"
    }
  }
  puts ""
}

#------------------------------------------------------------------------
# ::VCD::method:get_param
#------------------------------------------------------------------------
# **HIDDEN**
#------------------------------------------------------------------------
# Usage: <object> get_param <param>
#------------------------------------------------------------------------
# Get a parameter from the 'params' associative array
#------------------------------------------------------------------------
proc ::VCD::method:get_param {self args} {
  if {[llength $args] != 1} {
    error " -E- wrong number of parameters: <object> get_param <param>"
  }
  if {![info exists ${self}::params([lindex $args 0])]} {
    error " -E- unknown parameter '[lindex $args 0]'"
  }
  return [subst $${self}::params([lindex $args 0])]
}

#------------------------------------------------------------------------
# ::VCD::method:set_param
#------------------------------------------------------------------------
# **HIDDEN**
#------------------------------------------------------------------------
# Usage: <object> set_param <param> <value>
#------------------------------------------------------------------------
# Set a parameter inside the 'params' associative array
#------------------------------------------------------------------------
proc ::VCD::method:set_param {self args} {
  if {[llength $args] < 2} {
    error " -E- wrong number of parameters: <object> set_param <param> <value>"
  }
  set ${self}::params([lindex $args 0]) [lrange $args 1 end]
  return 0
}

#------------------------------------------------------------------------
# ::VCD::method:reset
#------------------------------------------------------------------------
# Usage: <object> reset
#------------------------------------------------------------------------
# Reset the object to am empty one. All the data of that object are lost
#------------------------------------------------------------------------
proc ::VCD::method:reset {self args} {
  # Reset object and empty all the data
  set ${self}::names [list]
  set ${self}::clocks [list]
  set ${self}::signals [list]
  set ${self}::transitions [list]
  catch {unset ${self}::params}
  array set ${self}::params $::VCD::params
  return 0
}

#------------------------------------------------------------------------
# ::VCD::method:destroy
#------------------------------------------------------------------------
# Usage: <object> destroy
#------------------------------------------------------------------------
# Destroy an object and release its memory footprint. The object is not
# accessible anymore after that command
#------------------------------------------------------------------------
proc ::VCD::method:destroy {self args} {
  # Destroy object
  set ${self}::names [list]
  set ${self}::clocks [list]
  set ${self}::signals [list]
  set ${self}::transitions [list]
  catch {unset ${self}::params}
  namespace delete $self
  return 0
}

#------------------------------------------------------------------------
# ::VCD::method:sizeof
#------------------------------------------------------------------------
# Usage: <object> sizeof
#------------------------------------------------------------------------
# Return the memory footprint of the object
#------------------------------------------------------------------------
proc ::VCD::method:sizeof {ns args} {
  # Return memory footprint of the object
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
      incr sum [::VCD::method:sizeof $child]
  }
  set sum
}

#------------------------------------------------------------------------
# ::VCD::method:info
#------------------------------------------------------------------------
# Usage: <object> info
#------------------------------------------------------------------------
# List various information about the object
#------------------------------------------------------------------------
proc ::VCD::method:info {self args} {
  # Information about the object
  upvar #0 ${self}::names names
  upvar #0 ${self}::clocks clocks
  upvar #0 ${self}::signals signals
  upvar #0 ${self}::transitions transitions
  upvar #0 ${self}::params params
  puts [format {    Names    : %s} [lsort $names]]
  puts [format {    # Clocks : %s} [llength $clocks]]
  puts [format {    # Signals: %s} [llength $signals]]
  foreach param [lsort [array names params]] {
    puts [format {    Param[%s]: %s} $param $params($param)]
  }
  puts [format {    Memory footprint: %d bytes} [::VCD::method:sizeof $self]]
}

#------------------------------------------------------------------------
# ::VCD::method:configure
#------------------------------------------------------------------------
# Usage: <object> configure [<options>]
#------------------------------------------------------------------------
# Configure some of the object parameters
#------------------------------------------------------------------------
proc ::VCD::method:configure {self args} {
  # Configure object
  set error 0
  set help 0
  if {[llength $args] == 0} {
    set help 1
  }
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
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
  Usage: <object> configure 
              [-help|-h]
              
  Description: Configure some of the internal parameters.
  
  Example:
     <object> configure 
} ]
    # HELP -->
    return {}
  }
    
}

#------------------------------------------------------------------------
# ::VCD::method:clone
#------------------------------------------------------------------------
# Usage: <object> clone
#------------------------------------------------------------------------
# Clone the object and return the cloned object. The original object
# is not modified
#------------------------------------------------------------------------
proc ::VCD::method:clone {self args} {
  # Clone object. Return new object
  upvar #0 ${self}::names names
  upvar #0 ${self}::clocks clocks
  upvar #0 ${self}::signals signals
  upvar #0 ${self}::transitions transitions
  upvar #0 ${self}::params params
  set vcd [::VCD::Create]
  set ${vcd}::names $names
  set ${vcd}::clocks $clocks
  set ${vcd}::signals $signals
  set ${vcd}::transitions $transitions
  array set ${vcd}::params [array get params]
  return $vcd
}

#------------------------------------------------------------------------
# ::VCD::method:addclock
#------------------------------------------------------------------------
# Usage: <object> addclock [<options>]
#------------------------------------------------------------------------
# Add new clock
#------------------------------------------------------------------------
proc ::VCD::method:addclock {self args} {
  # Add new clock
  set clock {}
  set waveform {}
  set period {}
  set error 0
  set help 0
  if {[llength $args] == 0} {
    set help 1
  }
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -n -
      -name {
           set clock [lshift args]
      }
      -w -
      -waveform {
           set waveform [lshift args]
      }
      -p -
      -period {
           set period [lshift args]
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
  Usage: <object> addclock 
              [-help|-h]
              
  Description: Add a new clock.
  
  Example:
     <object> addclock -name CLK1 -period 10 -waveform {2 5}
} ]
    # HELP -->
    return {}
  }
  
  if {$clock == {}} {
    error " -E- no clock name specified. Cannot continue"
  }
  if {[lsearch [subst $${self}::names] $clock] != -1} {
    error " -E- clock or signal '$clock' already exist. Cannot continue"
  }
  if {$period == {}} {
    error " -E- no period defined for clock '$clock'. Cannot continue"
  }
  if {$waveform == {}} {
    set waveform [list 0.0 [expr double($period)/2] ]
  } elseif {[expr [llength $waveform] % 2] == 1} {
    error " -E- the waveform '$waveform' has an odd number of edges. Only an even number of edges is supported"
  }
  
  lappend ${self}::clocks [list $clock $period $waveform]
  lappend ${self}::names $clock
  
  puts " -I- add new clock '$clock'. Period=$period / Waveform={$waveform}"
  return 0
}

#------------------------------------------------------------------------
# ::VCD::method:addsignal
#------------------------------------------------------------------------
# Usage: <object> addsignal [<options>]
#------------------------------------------------------------------------
# Add new signal
#------------------------------------------------------------------------
proc ::VCD::method:addsignal {self args} {
  # Add new signal
  set signal {}
  set transitions [list]
  set error 0
  set help 0
  if {[llength $args] == 0} {
    set help 1
  }
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -n -
      -name {
           set signal [lshift args]
      }
      -a -
      -add {
           lappend transitions [lshift args]
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
  Usage: <object> addsignal
              [-help|-h]
              
  Description: Add a new signal.
  
  Example:
     <object> addsignal -name SIG1
} ]
    # HELP -->
    return {}
  }
  
  if {$signal == {}} {
    error " -E- no signal name specified. Cannot continue"
  }
  if {[lsearch [subst $${self}::names] $signal] != -1} {
    error " -E- clock or signal '$signal' already exist. Cannot continue"
  }
  
  lappend ${self}::signals [list $signal]
  lappend ${self}::names $signal
  
  foreach item $transitions {
    foreach {time value} $item { break }
    lappend ${self}::transitions [list $time $signal $value]
  }
  
  puts " -I- add new signal '$signal'"
  return 0
}

#------------------------------------------------------------------------
# ::VCD::method:transition
#------------------------------------------------------------------------
# Usage: <object> transition [<options>]
#------------------------------------------------------------------------
# Add transition(s) to a signal or clock
#------------------------------------------------------------------------
proc ::VCD::method:transition {self args} {
  # Add transition(s) to a signal or clock
  set signal {}
  set transitions [list]
  set error 0
  set help 0
  if {[llength $args] == 0} {
    set help 1
  }
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -n -
      -name {
           set signal [lshift args]
      }
      -a -
      -add {
           lappend transitions [lshift args]
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
  Usage: <object> transition
              [-help|-h]
              
  Description: Add transition(s) to a signal or clock.
  
  Example:
     <object> transition -name SIG1
} ]
    # HELP -->
    return {}
  }
  
  if {$signal == {}} {
    error " -E- no signal name specified. Cannot continue"
  }
  if {[lsearch [subst $${self}::names] $signal] == -1} {
    error " -E- clock or signal '$signal' does not exist. Cannot continue"
  }
  
  foreach item $transitions {
    foreach {time value} $item { break }
    lappend ${self}::transitions [list $time $signal $value]
  }
  
  puts " -I- add new transition(s) for '$signal'"
  return 0
}

#------------------------------------------------------------------------
# ::VCD::method:generate
#------------------------------------------------------------------------
# Usage: <object> generate [<options>]
#------------------------------------------------------------------------
# Generate VCD
#------------------------------------------------------------------------
proc ::VCD::method:generate {self args} {
  # Generate VCD
  upvar #0 ${self}::names names
  upvar #0 ${self}::clocks clocks
  upvar #0 ${self}::signals signals
  upvar #0 ${self}::transitions transitions
  upvar #0 ${self}::params params
  set start 0
  set end 10000
  set timeline [list]
  set filename {}
  set timescale {ns}
  set error 0
  set help 0
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -s -
      -start {
           set start [lshift args]
      }
      -e -
      -end {
           set end [lshift args]
      }
      -f -
      -file {
           set filename [lshift args]
      }
      -t -
      -ts -
      -timescale {
           set timescale [lshift args]
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
  Usage: <object> generate 
              [-start|-s <time>]
              [-end|-e <time>]
              [-file|-f <filename>]
              [-timescale|-t <s|ms|us|ns|ps|fs>]
              [-help|-h]
              
  Description: Generate VCD.
  
  Example:
     <object> generate -file test.vcd
} ]
    # HELP -->
    return {}
  }
  
  if {[lsearch [list s ms us ns ps fs] $timescale] == -1} {
    error " -E- unknown timescale '$timescale'. Cannot continue"
  }
  
  set content [format {
 $date %s $end
 $version Generated with VCD package $end
 $timescale 1 %s $end
 $scope module top $end
} [clock format [clock seconds]] $timescale ]

  set numvar 0
  catch {unset set vcdname}
  foreach item [lsort $names] {
    if {![info exist vcdname($item)]} {
      set vcdname($item) [format %c [expr 65 + $numvar]]
      incr numvar
    }
    append content "[format { $var wire 1 %s %s $end} $vcdname($item) $item]\n"
  }

  append content [format {
 $upscope $end
 $enddefinitions $end
}]
  
  # Generate the timeline of events for clocks
  foreach item $clocks {
    foreach {name period waveform} $item { break }
    set time 0.0
    # Default value at time 0
    lappend timeline [list $time $name 0]
    while 1 {
      foreach {rising falling} $waveform {
        lappend timeline [list [expr double($time) + double($rising)] $name 1]
        lappend timeline [list [expr double($time) + double($falling)] $name 0]
      }
      set time [expr double($time) + double($period)]
      if {$time > $end} {
        break
      }
    }
  }

  # Initialize the initial value of the signals (not clocks)
  foreach item $signals {
    foreach {name} $item { break }
    # Default value at time 0
    lappend timeline [list 0.0 $name 0]
  }
  
  # Generate the timeline from the list of transitions
  foreach item $transitions {
    foreach {time name value} $item { break }
    lappend timeline [list [expr double($time)] $name $value]
  }
  
  # Reorder the timeline
  set timeline [lsort -real -index 0 -increasing $timeline]
  
  # Generate the VCD content for the timeline
  foreach event $timeline {
    foreach {time name value} $event { break }
    if {$time < $start} {
      continue
    }
    if {$time > $end} {
      break
    }
    append content "\n#${time}"
    append content "\n ${value}$vcdname($name)"
  }

  if {$filename != {}} {
    set FH [open $filename w]
    puts $FH $content
    close $FH
    puts " -I- VCD saved inside file '$filename'"
    return 0
  }
  
  return $content
}



#------------------------------------------------------------------------
# Provide the package
#------------------------------------------------------------------------
package provide VCD $::VCD::version

#--------------------------- Self-test code
if {[info ex argv0] && [file tail [info script]] == [file tail $argv0]} {
  # File executed from tclsh
  puts "Package VCD"
  # Simple index generator, if the directory contains only this package
  pkg_mkIndex -verbose [file dirn [info scr]] [file tail [info scr]]
} else {
  # File sourced

  # Simplify re-sourcing this file
  proc [file tail [info script]] {} "source [info script]"
 
  puts "  [info script] sourced."
}
#------------------------------------------

###########################################################################
##
## Examples
##
###########################################################################

if 0 {
  proc T { {init {}} } {
    # Toggle the T_STATE variable each time it is called
    global T_STATE
    if {![info exists T_STATE]} { set T_STATE 0; return $T_STATE }
    switch $init {
      1 {
        set T_STATE 1
      }
      0 {
        set T_STATE 0
      }
      default {
        set T_STATE [expr 1 - $T_STATE]
      } 
    }
    return $T_STATE
  }
  set vcd [::VCD::Create]
  $vcd addclock -name CLK1 -waveform {0 5} -period 10
  $vcd addclock -name CLK2 -waveform {4 8} -period 10
  $vcd addclock -name CLK3 -waveform {1 6} -period 30
  $vcd addsignal -name SIG1 -add {0 0} -add {10 x} -add {20 1}
  $vcd transition -name SIG1 -add {30 0} -add {35 x} -add {40 1}
  $vcd transition -name CLK1 -add {12 x} -add {13 1}
  $vcd generate -file test.vcd -end 100
}


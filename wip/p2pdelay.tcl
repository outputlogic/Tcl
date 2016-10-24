####################################################################################################
# HEADER_BEGIN
# COPYRIGHT NOTICE
# Copyright 2001-2016 Xilinx Inc. All Rights Reserved.
# http://www.xilinx.com/support
# HEADER_END
####################################################################################################

########################################################################################
##
## Company:        Xilinx, Inc.
## Created by:     David Pefourque
##
## Version:        2016.08.22
## Tool Version:   Vivado 2014.1
## Description:    This package provides commands for timing correlation
##
########################################################################################

########################################################################################
## 2016.08.22 - Added support for disableglobals for methods get_p2p_info/get_p2p_delay
##            - Added method compare_p2p_est
##            - Updated all methods' command line options to support regexp
## 2016.08.10 - Added support for crunch delay/system/both delay extraction (UltraScale Plus)
##            - Added support for -p2p/-system/-delay/-removelutpindelay for method get_p2p_info
##            - Added support for -p2p/-system/-delay/-removelutpindelay for method get_p2p_delay
## 2016.02.26 - Improved support when multiple site pins are connected to a pin
## 2016.02.24 - Removed limit to the number of expansions (internal::route_dbg_p2p_route)
##              (runtime impact)
## 2016.02.11 - Fixed issue with get_p2p_info where options were not passed to
##              internal::route_dbg_p2p_route
## 2014.12.16 - Added pin_info to return pin site information
## 2014.09.22 - Added get_est_wire_delay for pin-to-pin estimated wire delays
## 2014.09.09 - Save latest p2p report inside ::tb::p2pdelay::report
##            - Added method last_report
##            - Other minor updates
## 2014.07.28 - Initial release
########################################################################################

if {0} {
  # CLIENT
  source p2pdelay.tcl
  p2pdelay config -host {localhost} -port 12345 -noecho
  p2pdelay status
  ::tb::p2pdelay::isP2pServerReady
  p2pdelay get_p2p_info -from int1_reg/Q -to "SLICE_X47Y51 A1"
  p2pdelay get_p2p_info -from "SLICE_X47Y51 AQ" -to "SLICE_X47Y51 A1"
  p2pdelay get_est_wire_delay -from "SLICE_X47Y51 AQ" -to "SLICE_X47Y51 A1"
  p2pdelay get_est_wire_delay -from "SLICE_X47Y51 AQ" -to "SLICE_X47Y51 A1" -fanout 12
  ::tb::p2pdelay::get_p2p_info -from "SLICE_X47Y51 AQ" -to "SLICE_X47Y51 A1"
  get_p2p_info -from "SLICE_X47Y51 AQ" -to "SLICE_X47Y51 A1"
  get_p2p_delay -from "SLICE_X47Y51 AQ" -to "SLICE_X47Y51 A1"
  get_est_wire_delay -from "SLICE_X47Y51 AQ" -to "SLICE_X47Y51 A1"
  p2pdelay stop_server
#   ::tb::p2pdelay::rexec pwd
#   ::tb::p2pdelay::getP2pInfo -from int1_reg/Q -to "SLICE_X47Y51 A1"
#   ::tb::p2pdelay::rexec ::tb::p2pdelay::stopP2pServer


  # SERVER
  source p2pdelay.tcl
  p2pdelay config -port 12345 -part xc7vx415tffg1158-2L -log p2pdelay.log -nodebug -echo
  p2pdelay start_server -timeout 30

  source p2pdelay.tcl
  p2pdelay config -port 12345 -part xc7vx415tffg1158-2L -log p2pdelay.log -nodebug -noecho -options {-removeLUTPinDelay}
  p2pdelay start_server -timeout 30
#   ::tb::p2pdelay::startP2pServer -timeout 30

}

if {[package provide Vivado] == {}} {return}

package require Vivado 1.2014.1

namespace eval ::tb {
    namespace export p2pdelay get_p2p_delay get_p2p_info get_est_wire_delay
}

namespace eval ::tb::p2pdelay {
    namespace export get_p2p_delay get_p2p_info get_est_wire_delay
}

proc ::tb::p2pdelay { args } {
  # Summary : Tcl p2pdelay

  # Argument Usage:
  # args : sub-command. The supported sub-commands are: start | stop | summary | add | remove | reset | status

  # Return Value:
  # returns the status or an error code

#   if {[catch {set res [uplevel [concat ::tb::p2pdelay::p2pdelay $args]]} errorstring]} {
#     error " -E- the p2pdelay failed with the following error: $errorstring"
#   }
  return [uplevel [concat ::tb::p2pdelay::p2pdelay $args]]
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::get_est_wire_delay
#------------------------------------------------------------------------
# Usage: ::tb::p2pdelay::get_est_wire_delay [<options>]
#------------------------------------------------------------------------
# Get the P2P estimated wire delay
#------------------------------------------------------------------------
proc ::tb::p2pdelay::get_est_wire_delay {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  return [uplevel [concat ::tb::p2pdelay::method:get_est_wire_delay $args]]
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::get_p2p_delay
#------------------------------------------------------------------------
# Usage: ::tb::p2pdelay::get_p2p_delay [<options>]
#------------------------------------------------------------------------
# Get the P2P route delay
#------------------------------------------------------------------------
proc ::tb::p2pdelay::get_p2p_delay {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  return [uplevel [concat ::tb::p2pdelay::method:get_p2p_delay $args]]
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::get_p2p_info
#------------------------------------------------------------------------
# Usage: ::tb::p2pdelay::get_p2p_info [<options>]
#------------------------------------------------------------------------
# Get the P2P route info
#------------------------------------------------------------------------
proc ::tb::p2pdelay::get_p2p_info {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  return [uplevel [concat ::tb::p2pdelay::method:get_p2p_info $args]]
}


###########################################################################
##
## Package for profiling Tcl code
##
###########################################################################

#------------------------------------------------------------------------
# Namespace for the package
#------------------------------------------------------------------------

# Trick to silence the linter
eval [list namespace eval ::tb::p2pdelay {
  variable version {2016.08.22}
  variable params
  variable tcpstate {}
  variable socket {}
  variable script {}
  variable result {}
  variable report {}
  catch {unset params}
  # delay: p2p | crunch | system | both
  # (p2p == crunch)
  array set params [list delay {p2p} host {} port {12345} mode {client} log {} verbose 0 part {} timeout 0 debug 0 echo 0 options {}]
} ]

#------------------------------------------------------------------------
# ::tb::p2pdelay::p2pdelay
#------------------------------------------------------------------------
# Main function
#------------------------------------------------------------------------
proc ::tb::p2pdelay::p2pdelay { args } {
  # Summary :
  # Argument Usage:
  # Return Value:

  #-------------------------------------------------------
  # Process command line arguments
  #-------------------------------------------------------
  set error 0
  set show_help 0
  set method [lshift args]
  switch -exact -- $method {
    dump {
      return [eval [concat ::tb::p2pdelay::dump] ]
    }
    ? -
    -h -
    -help {
      incr show_help
    }
    default {
      return [eval [concat ::tb::p2pdelay::do ${method} $args] ]
    }
  }

  if {$show_help} {
    # <-- HELP
    puts ""
    ::tb::p2pdelay::method:?
    puts [format {
   Description: Utility to query p2p route delays

   Example: P2P delays from current Vivado session
      p2pdelay get_p2p_info -from "SLICE_X47Y51 AQ" -to "SLICE_X47Y51 A1"
      p2pdelay get_p2p_delay -from "SLICE_X47Y51 AQ" -to "SLICE_X47Y51 A1"
      ::tb::p2pdelay::get_p2p_info -from "SLICE_X47Y51 AQ" -to "SLICE_X47Y51 A1"
      get_p2p_info -from "SLICE_X47Y51 AQ" -to "SLICE_X47Y51 A1"
      get_p2p_delay -from "SLICE_X47Y51 AQ" -to "SLICE_X47Y51 A1"

   Example: Client side (client/server mode)
      p2pdelay config -host localhost -port 12345 -echo
      p2pdelay status
      ::tb::p2pdelay::isP2pServerReady
      p2pdelay get_p2p_info -from int1_reg/Q -to "SLICE_X47Y51 A1"
      p2pdelay get_p2p_info -from "SLICE_X47Y51 AQ" -to "SLICE_X47Y51 A1"
      p2pdelay get_p2p_delay -from "SLICE_X47Y51 AQ" -to "SLICE_X47Y51 A1"
      ::tb::p2pdelay::get_p2p_info -from "SLICE_X47Y51 AQ" -to "SLICE_X47Y51 A1"
      get_p2p_info -from "SLICE_X47Y51 AQ" -to "SLICE_X47Y51 A1"
      get_p2p_delay -from "SLICE_X47Y51 AQ" -to "SLICE_X47Y51 A1"
      p2pdelay stop_server


   Example: Server side (client/server mode)
      p2pdelay config -port 12345 -part xc7vx415tffg1158-2L -log p2pdelay.log -echo
      p2pdelay start_server -timeout 300

    } ]
    # HELP -->
    return
  }

}

#------------------------------------------------------------------------
# ::tb::p2pdelay::lshift
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Stack function
#------------------------------------------------------------------------
proc ::tb::p2pdelay::lshift {inputlist} {
  # Summary :
  # Argument Usage:
  # Return Value:

  upvar $inputlist argv
  set arg  [lindex $argv 0]
  set argv [lrange $argv 1 end]
  return $arg
}

##-----------------------------------------------------------------------
## split-csv
##-----------------------------------------------------------------------
## Convert a CSV string to a Tcl list based on a field separator
##-----------------------------------------------------------------------
proc ::tb::p2pdelay::split-csv { str {sepChar ,} {trim 0} } {
  regsub -all {(\A\"|\"\Z)} $str \0 str
  set str [string map [list $sepChar\"\"$sepChar $sepChar$sepChar] $str]
  set str [string map [list $sepChar\"\"\" $sepChar\0\" \
                            \"\"\"$sepChar \"\0$sepChar \
                            $sepChar\"\"$sepChar $sepChar$sepChar \
                           \"\" \" \
                           \" \0 \
                           ] $str]
  set end 0
  while {[regexp -indices -start $end {(\0)[^\0]*(\0)} $str \
          -> start end]} {
      set start [lindex $start 0]
      set end   [lindex $end 0]
      set range [string range $str $start $end]
      set first [string first $sepChar $range]
      if {$first >= 0} {
          set str [string replace $str $start $end \
              [string map [list $sepChar \1] $range]]
      }
      incr end
  }
  set str [string map [list $sepChar \0 \1 $sepChar \0 {} ] $str]
  if {$trim} {
    # Some CSV are formated with space/tab added as padding between
    # delimiters. This remove those padding at the start/end of the
    # cell value
    set L [list]
    foreach el [split $str \0] {
      lappend L [string trim $el]
    }
    return $L
  }
  return [split $str \0]
}

##-----------------------------------------------------------------------
## join-csv
##-----------------------------------------------------------------------
## Convert a Tcl list based into a CSV string
##-----------------------------------------------------------------------
proc ::tb::p2pdelay::join-csv { list {sepChar ,} } {
  set out ""
  set sep {}
  foreach val $list {
    if {[string match "*\[\"$sepChar\]*" $val]} {
      append out $sep\"[string map [list \" \"\"] $val]\"
    } else {
      append out $sep\"$val\"
    }
    set sep $sepChar
  }
  return $out
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::isIpV4Address
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Figure out what this machine's IP address is
#------------------------------------------------------------------------
proc ::tb::p2pdelay::isIpV4Address { string } {
  # Summary :
  # Argument Usage:
  # Return Value:

  set octet {(?:\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5])}
  set pattern "^[join [list $octet $octet $octet $octet] {\.}]\$"
  return [regexp -- $pattern $string]
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::getMyIP
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Figure out what this machine's IP address is
#------------------------------------------------------------------------
proc ::tb::p2pdelay::getMyIP {{port 5435}} {
  # Summary :
  # Argument Usage:
  # Return Value:

  set myip {}
  set tss [socket -server tserv $port]
  set ts2 [socket [info hostname] $port]
  set myip [lindex [fconfigure $ts2 -sockname] 0]
  close $tss
  close $ts2
  return $myip
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::hostname2ip
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Convert a host name to an IP address
#------------------------------------------------------------------------
proc ::tb::p2pdelay::hostname2ip {hostname} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Disable message: WARNING: [Common 17-259] Unknown Tcl command 'host xsjdpefour40' sending command to the OS shell for execution.
  set_msg_config -id {Common 17-259} -limit 0
  if {[catch {set res [uplevel #0 exec host $hostname]} errorstring]} {
    reset_msg_config -id {Common 17-259} -limit
    return {}
  }
  set ip {}
  regexp -nocase {has address\s*([^\s]+)\s*$} $res - ip
  reset_msg_config -id {Common 17-259} -limit
  return $ip
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::extendServerTimeout
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Extend the timeout to stop the p2p server
#------------------------------------------------------------------------
proc ::tb::p2pdelay::extendServerTimeout { {timeout {}} } {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable params
  if {$timeout == {}} { set timeout $params(timeout) }
  # After each new connection, remove any existing timeout and restart a new one
  after cancel [after info]
  if {$timeout > 0} {
    puts stderr " -I- Timeout set to $timeout seconds on [clock format [clock seconds]]"
    after [expr $timeout * 1000] set ::tb::p2pdelay::tcpstate "tcp:timeout"
  }
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::docstring
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Return the embedded help of a proc
#------------------------------------------------------------------------
proc ::tb::p2pdelay::docstring {procname} {
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
      if {[regexp -nocase -- {^\s*#\s*(Summary|Argument Usage|Return Value|Categories)\s*\:} $line]} continue
      if {![regexp {^\s*#(.+)} $line -> line]} break
      lappend res [string trim $line]
  }
  join $res \n
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::do
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Dispatcher with methods
#------------------------------------------------------------------------
proc ::tb::p2pdelay::do {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  if {[llength $args] == 0} {
#     error " -E- wrong number of parameters: p2pdelay <sub-command> \[<arguments>\]"
    set method {?}
  } else {
    # The first argument is the method
    set method [lshift args]
  }
  if {[info proc ::tb::p2pdelay::method:${method}] == "::tb::p2pdelay::method:${method}"} {
    eval ::tb::p2pdelay::method:${method} $args
  } else {
    # Search for a unique matching method among all the available methods
    set match [list]
    foreach procname [info proc ::tb::p2pdelay::method:*] {
      if {[string first $method [regsub {::tb::p2pdelay::method:} $procname {}]] == 0} {
        lappend match [regsub {::tb::p2pdelay::method:} $procname {}]
      }
    }
    switch [llength $match] {
      0 {
        error " -E- unknown sub-command $method"
      }
      1 {
        set method $match
        return [eval ::tb::p2pdelay::method:${method} $args]
      }
      default {
        error " -E- multiple sub-commands match '$method': $match"
      }
    }
  }
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::method:?
#------------------------------------------------------------------------
# Usage: p2pdelay ?
#------------------------------------------------------------------------
# Return all the available methods. The methods with no embedded help
# are not displayed (i.e hidden)
#------------------------------------------------------------------------
proc ::tb::p2pdelay::method:? {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # This help message
  puts "   Usage: p2pdelay <sub-command> \[<arguments>\]"
  puts "   Where <sub-command> is:"
  foreach procname [lsort [info proc ::tb::p2pdelay::method:*]] {
    regsub {::tb::p2pdelay::method:} $procname {} method
    set help [::tb::p2pdelay::docstring $procname]
    if {$help ne ""} {
      puts "         [format {%-17s%s- %s} $method \t $help]"
    }
  }
  puts ""
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::dump
#------------------------------------------------------------------------
# Usage: p2pdelay dump
#------------------------------------------------------------------------
# Dump p2pdelay status
#------------------------------------------------------------------------
proc ::tb::p2pdelay::dump {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Dump non-array variables
  foreach var [lsort [info var ::tb::p2pdelay::*]] {
    if {![info exists $var]} { continue }
    if {![array exists $var]} {
      puts "   $var: [subst $$var]"
    }
  }
  # Dump array variables
  foreach var [lsort [info var ::tb::p2pdelay::*]] {
    if {![info exists $var]} { continue }
    if {[array exists $var]} {
      parray $var
    }
  }
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::method:version
#------------------------------------------------------------------------
# Usage: p2pdelay version
#------------------------------------------------------------------------
# Return the version of the p2pdelay
#------------------------------------------------------------------------
proc ::tb::p2pdelay::method:version {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Version of the p2pdelay
  variable version
#   puts " -I- p2pdelay version $version"
  return -code ok "p2pdelay version $version"
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::method:reset
#------------------------------------------------------------------------
# Usage: p2pdelay reset
#------------------------------------------------------------------------
# Reset the p2pdelay parameters
#------------------------------------------------------------------------
proc ::tb::p2pdelay::method:reset {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Reset the p2pdelay parameters
  variable params
  variable socket
  variable script
  variable result
  variable report
  variable tcpstate
  catch {unset params}
  set socket {}
  set script {}
  set result {}
  set report {}
  set tcpstate {}
  array set params [list host {} port {12345} mode {client} log {} verbose 0 part {} timeout 0 debug 0 options {}]
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::method:last_report
#------------------------------------------------------------------------
# Usage: p2pdelay last_report
#------------------------------------------------------------------------
# Return the last p2p report
#------------------------------------------------------------------------
proc ::tb::p2pdelay::method:last_report {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Get the last p2pdelay report
  variable report
  return $report
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::method:rexec
#------------------------------------------------------------------------
# Usage: ::tb::p2pdelay::rexec <command>
#------------------------------------------------------------------------
# Execute command on remote host
#------------------------------------------------------------------------
proc ::tb::p2pdelay::rexec {cmd} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable params
  variable result
  if {$params(host) == {}} {
    error " -E- no host defined"
  }
  if {$params(port) == {}} {
    error " -E- no port defined"
  }
  if {![isP2pServerReady -host $params(host) -port $params(port)]} {
    error " -E- no p2pdelay server listening on '$params(host)' port '$params(port)'"
  }
  set chan [socket $params(host) $params(port)]
#   fconfigure $chan -blocking 0 -buffering none
  fconfigure $chan -buffering line
  puts -nonewline $chan [list $cmd]
  flush $chan
  if {![eof $chan]} {
    set result [read $chan]
  } else {
    set result {}
  }
#   puts " result<$chan>:<$res>"
  close $chan
  return $result
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::method:log
#------------------------------------------------------------------------
# Usage: ::tb::p2pdelay::log <string>
#------------------------------------------------------------------------
# Append message to log file
#------------------------------------------------------------------------
proc ::tb::p2pdelay::log {msg} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable params
  if {$params(log) == {}} {
    return -code ok
  }
  set FH [open $params(log) {a}]
  puts $FH $msg
  close $FH
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::getP2pDelay
#------------------------------------------------------------------------
# Usage: ::tb::p2pdelay::getP2pDelay [<options>]
#------------------------------------------------------------------------
# Get P2P delay from either the remote Vivado session or current Vivado
# session
#------------------------------------------------------------------------
proc ::tb::p2pdelay::getP2pDelay { args } {
  set res [eval [concat getP2pInfo $args -delay {p2p}]]
  # Return max delay
  set delay [lindex $res 0]
  return $delay
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::getSystemDelay
#------------------------------------------------------------------------
# Usage: ::tb::p2pdelay::getSystemDelay [<options>]
#------------------------------------------------------------------------
# Get System delay from either the remote Vivado session or current Vivado
# session
#------------------------------------------------------------------------
proc ::tb::p2pdelay::getSystemDelay { args } {
  set res [eval [concat getP2pInfo $args -delay {system}]]
  # Return max delay
  set delay [lindex $res 1]
  return $delay
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::getP2pInfo
#------------------------------------------------------------------------
# Usage: ::tb::p2pdelay::getP2pInfo [<options>]
#------------------------------------------------------------------------
# Get p2p delay from either the remote Vivado session or current Vivado
# session
#------------------------------------------------------------------------
proc ::tb::p2pdelay::getP2pInfo { args } {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Add Vivado command(s) to the p2pdelay (-help)
  variable params
  variable report
  set defaults [list -delay $params(delay) -from {} -to {} -port $params(port) -host $params(host) -options $params(options)]
  array set options $defaults
  array set options $args
  set delay $options(-delay)
  set port $options(-port)
  set host $options(-host)
  set from $options(-from)
  set to $options(-to)
  set opt $options(-options)
  switch [llength $from] {
    0 {
      error " -E- nothing provided for -from"
    }
    1 {
      if {[get_pins -quiet $from] != {}} {
        set from [::tb::p2pdelay::method:pin_info -pin $from]
#         set from [split [lindex [get_site_pin -quiet -of [get_pin -quiet $from]] 0] /]
      } elseif {$from == {}} {
        set from [get_pins -quiet -leaf -of [get_nets -quiet -of [get_pins -quiet $options(-to)]] -filter {DIRECTION==OUT}]
        set from [::tb::p2pdelay::method:pin_info -pin $from]
#         set from [split [lindex [get_site_pin -quiet -of [get_pin -quiet $from]] 0] /]
      }
    }
    2 {
      # Format: "site pin"
      # Ok, nothing to do
    }
    default {
      error " -E- wrong format for -from"
    }
  }
  switch [llength $to] {
    0 {
      error " -E- nothing provided for -to"
    }
    1 {
      if {[get_pins -quiet $to] != {}} {
        set to [::tb::p2pdelay::method:pin_info -pin $to]
#         set to [split [lindex [get_site_pin -quiet -of [get_pin -quiet $to]] 0] /]
      } else {
        set to {}
      }
    }
    2 {
      # Format: "site pin"
      # Ok, nothing to do
    }
    default {
      error " -E- wrong format for -to"
    }
  }
  switch $delay {
    both -
    p2p -
    crunch -
    system {
    }
    default {
      error " -E- wrong delay type '$delay'. Valid types are: p2p | crunch | system"
    }
  }
# puts "<from:$from><to:$to>"
# if {$params(debug)} { puts "<from:$from><to:$to>" }
  if {($from =={}) || ($to == {})} {
    # The -from or -to could not be resolved
    error " -E- error with -from/-to"
  }
  if {($port == {}) || ($host == {})} {
    set report [getP2pRouteReport -from $from -to $to -options $opt]
  } else {
    if {[isP2pServerReady -port $port -host $host]} {
      if {$params(debug)} { puts stderr " -D- Sending request to server host:$host / port:$port" }
      set report [rexec [format {::tb::p2pdelay::getP2pRouteReport -from "%s" -to "%s" -options "%s"} $from $to $opt]]
    } else {
      puts " -W- could not connect to P2P server host:$host / port:$port . Running command locally"
      set report [getP2pRouteReport -from $from -to $to -options $opt]
    }
  }
# puts "report:<$report>"
#   if {$params(echo)} { puts stderr $::tb::p2pdelay::result }
  if {$params(echo)} { puts stderr $::tb::p2pdelay::report }
  switch $delay {
    p2p -
    crunch {
      # Crunch delay = delay seen by router
      set res [getP2pRouteInfo $report]
    }
    system {
      # System delay = delay seen by STA
      set res [getSystemDlyRouteInfo $report]
    }
    both {
      set res [list [getP2pRouteInfo $report] [getSystemDlyRouteInfo $report] ]
    }
  }
  return $res
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::getP2pRouteInfo
#------------------------------------------------------------------------
# Usage: ::tb::p2pdelay::getP2pRouteInfo [<options>]
#------------------------------------------------------------------------
# Return a list of information from P2P route report (dly instDly wl res)
#------------------------------------------------------------------------
# Routing from SLICE_X47Y51 DQ->SLICE_X47Y51 B1
# routing from (79 310 92) to (79 310 38)
# PATH (dly = 704, instDly = 0, wl = 6, res = 45) Num Expansions: 323851
#     (79 310 38 CLBLM_L_B1 : LUTINPUT) 704
#     (78 310 58 IMUX14 : PINFEED) 257
#     (78 310 4 BYP_BOUNCE4 : BOUNCEIN) 114
#     (78 310 25 BYP_ALT4 : PINBOUNCE) 114
#     (78 310 216 SR1BEG_S0 : SINGLE) 11
#     (79 310 91 CLBLM_LOGIC_OUTS3 : OUTBOUND) 0
#     (79 310 92 CLBLM_L_DQ : OUTPUT) 0
# PATH (dly = 704, wl = 6, res = 45, FastMinDly = 282) Num Expansions: 323851
# Path Delay: 704
# System Delay (min, max): (51, 84)
#------------------------------------------------------------------------
proc ::tb::p2pdelay::getP2pRouteInfo {report} {
  # PATH (dly = 704, instDly = 0, wl = 6, res = 45)
  if {[regexp -nocase -- {PATH\s*\(\s*dly\s*\=\s*([^\s]+)\s*\,\s*instDly\s*\=\s*([^\s]+)\s*\,\s*wl\s*\=\s*([^\s]+)\s*\,\s*res\s*\=\s*([^\s]+)\s*\)} $report - dly instDly wl res ]} {
    return [list $dly $instDly $wl $res]
  } else {
    error " error - could not extract P2P delay from \n $report"
  }
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::getSystemDlyRouteInfo
#------------------------------------------------------------------------
# Usage: ::tb::p2pdelay::getSystemDlyRouteInfo [<options>]
#------------------------------------------------------------------------
# Return a list of information from System Delay route report (min max)
#------------------------------------------------------------------------
# Routing from SLICE_X47Y51 DQ->SLICE_X47Y51 B1
# routing from (79 310 92) to (79 310 38)
# PATH (dly = 704, instDly = 0, wl = 6, res = 45) Num Expansions: 323851
#     (79 310 38 CLBLM_L_B1 : LUTINPUT) 704
#     (78 310 58 IMUX14 : PINFEED) 257
#     (78 310 4 BYP_BOUNCE4 : BOUNCEIN) 114
#     (78 310 25 BYP_ALT4 : PINBOUNCE) 114
#     (78 310 216 SR1BEG_S0 : SINGLE) 11
#     (79 310 91 CLBLM_LOGIC_OUTS3 : OUTBOUND) 0
#     (79 310 92 CLBLM_L_DQ : OUTPUT) 0
# PATH (dly = 704, wl = 6, res = 45, FastMinDly = 282) Num Expansions: 323851
# Path Delay: 704
# System Delay (min, max): (51, 84)
#------------------------------------------------------------------------
proc ::tb::p2pdelay::getSystemDlyRouteInfo {report} {
  # System Delay (min, max): (51, 84)
  if {[regexp -nocase -- {System Delay\s*\(\s*min\s*,\s*max\s*\)\s*:\s*\(\s*([^\s]+)\s*\,\s*([^\s]+)\s*\)} $report - min max ]} {
    return [list $min $max]
  } else {
    error " error - could not extract system delay from \n $report"
  }
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::getP2pRouteReport
#------------------------------------------------------------------------
# Usage: ::tb::p2pdelay::getP2pRouteReport [<options>]
#------------------------------------------------------------------------
# Get p2p report from current Vivado session
#------------------------------------------------------------------------
# ::internal::route_dbg_p2p_route  -from <arg> -to <arg> -fromNode <args>
#                                  -toNode <args> [-minDly <arg>] [-maxDly <arg>]
#                                  [-minBSlack <arg>] [-maxBSlack <arg>]
#                                  [-type <arg>] [-disableGlobals]
#                                  [-disableMaskPruning] [-removeLUTPinDelay]
#                                  [-nodeExcludeFile <arg>] [-numPaths <arg>]
#                                  -sweep <arg> -highlight <arg>
#                                  -highlight_pushed <arg>
#                                  -highlight_popped <arg> [-select_pushed]
#                                  [-select_popped] [-quiet] [-verbose]
#
# Usage:
#   Name                   Description
#   ----------------------------------
#   -from                  Driver node. "col row idx" or "site pin"
#   -to                    Target node. "col row idx" or "site pin"
#   -fromNode              Driver node. Use get_nodes/get_site_pins to get the
#                          node
#   -toNode                Load node. Use get_nodes/get_site_pins to get the
#                          node
#   [-minDly]              Min delay constraint
#                          Default: 0
#   [-maxDly]              Max delay constraint
#                          Default: 0
#   [-minBSlack]           Min bslack value
#                          Default: 0
#   [-maxBSlack]           Max bslack value
#                          Default: 0
#   [-type]                Route mode (MIN_DLY, ASTAR, ATREE, B_HOLD, C_HOLD)
#   [-disableGlobals]      Disable global nodes
#   [-disableMaskPruning]  Disable Aggressive Mask based pruning for ASTAR
#   [-removeLUTPinDelay]   Remove LUTPIn delays from the interconnect delay
#   [-nodeExcludeFile]     Nodes to be excluded
#   [-numPaths]            Number of Disjoint shortest paths to be extracted
#                          Default: 1
#   -sweep                 Sweep on all combinations of fromNode, toNode and
#                          write to file the expansions. Only works with
#                          fromNode & toNode options. Argument gives the
#                          filename.
#   -highlight             Highlight the routed path. Valid values are red,
#                          green, blue, magenta, yellow, cyan, and orange
#   -highlight_pushed      Highlight the nodes pushed in the heap. Valid values
#                          are red, green, blue, magenta, yellow, cyan, and
#                          orange
#   -highlight_popped      Highlight the nodes popped from the heap. Valid
#                          values are red, green, blue, magenta, yellow, cyan,
#                          and orange
#   [-select_pushed]       Selecting the nodes pushed in the heap
#   [-select_popped]       Select the nodes popped from the heap
#   [-quiet]               Ignore command errors
#   [-verbose]             Suspend message limits during command execution
#------------------------------------------------------------------------
proc ::tb::p2pdelay::getP2pRouteReport { args } {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable params
  variable result
  set defaults [list -from {} -to {} -options $params(options)]
  array set options $defaults
  array set options $args
  set cmdLine [list -from $options(-from) -to $options(-to)]
  foreach opt $options(-options) {
    lappend cmdLine $opt
  }
  set pid [uplevel #0 pid]

  # CR 935541:
  #   P2P router fails to find connection in MIN_DLY mode because source and target
  #   points are too far, and we run out of expansions.
  #   This is a basic check we have to control runtime. To skip that check set the
  #   following param before running p2p router:
  #   set_param route.maxSingleExpInMillions 0
  catch {
    set tmp [get_param route.maxSingleExpInMillions]
    set_param route.maxSingleExpInMillions 0
  }

  if {$params(debug)} { puts stderr " -D- ::internal::route_dbg_p2p_route $cmdLine" }
  eval [concat ::internal::route_dbg_p2p_route $cmdLine > p2p${pid}.out]

  # Restore expansion value
  catch { set_param route.maxSingleExpInMillions $tmp }

  set FH [open p2p${pid}.out]
  set content [read $FH]
  close $FH
  file delete p2p${pid}.out
# puts "content:<$content>"
  return $content
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::getP2pEstWireDelay
#------------------------------------------------------------------------
# Usage: ::tb::p2pdelay::getP2pEstWireDelay [<options>]
#------------------------------------------------------------------------
# Get pin-to-pin estimated wire delay from current Vivado session
#------------------------------------------------------------------------
proc ::tb::p2pdelay::getP2pEstWireDelay { args } {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable params
  variable result
  set defaults [list -from {} -to {}]
  array set options $defaults
  array set options $args
  set cmdLine [list -from $options(-from) -to $options(-to)]
  if {$params(debug)} { puts stderr " -D- ::internal::report_est_wire_delay $cmdLine" }
  set delay [eval [concat ::internal::report_est_wire_delay $cmdLine]]
  set result $delay
  return $delay
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::isP2pServerReady
#------------------------------------------------------------------------
# Usage: ::tb::p2pdelay::isP2pServerReady [<options>]
#------------------------------------------------------------------------
# Check if a remote p2pdelay server is listening
#------------------------------------------------------------------------
proc ::tb::p2pdelay::isP2pServerReady {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Add Vivado command(s) to the p2pdelay (-help)
  variable params
#   set defaults [list -port $params(port) -host {localhost}]
  set defaults [list -port $params(port) -host $params(host)]
  array set options $defaults
  array set options $args
  set port $options(-port)
  set host $options(-host)
  if {[catch {set chan [socket $host $port]} returnstring]} {
    return 0
  }
#   set msg [read $chan]
#   puts $msg
  close $chan
  return 1
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::createServerMsg
#------------------------------------------------------------------------
# Usage: ::tb::p2pdelay::createServerMsg [<options>]
#------------------------------------------------------------------------
# Create message with server information
#------------------------------------------------------------------------
proc ::tb::p2pdelay::createServerMsg {} {
  variable params
  set hostname [uplevel #0 exec hostname]
  set hostid [uplevel #0 exec hostid]
  set port $params(port)
  set ip [getMyIP]
  set msg [format " P2P Server listening on '$hostname' port '$port'
    Hostname : $hostname
    Hostid   : $hostid
    IP       : $ip
    Port     : $port
"]
  return $msg
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::createServerShortMsg
#------------------------------------------------------------------------
# Usage: ::tb::p2pdelay::createServerShortMsg [<options>]
#------------------------------------------------------------------------
# Create short message with server information
#------------------------------------------------------------------------
proc ::tb::p2pdelay::createServerShortMsg {} {
  variable params
  set hostname [uplevel #0 exec hostname]
  set hostid [uplevel #0 exec hostid]
  set port $params(port)
  set ip [getMyIP]
  set msg [format " P2P Server listening on hostname:$hostname / ip:$ip / port:$port / hostid:$hostid "]
  return $msg
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::startP2pServer
#------------------------------------------------------------------------
# Usage: ::tb::p2pdelay::startP2pServer [<options>]
#------------------------------------------------------------------------
# Start p2pdelay server
#------------------------------------------------------------------------
proc ::tb::p2pdelay::startP2pServer { args } {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Add Vivado command(s) to the p2pdelay (-help)
  variable params
  variable tcpstate
  variable socket
  set defaults [list -host $params(host) -port $params(port) -part $params(part) -timeout $params(timeout)]
  array set options $defaults
  array set options $args
  set host $options(-host)
  set port $options(-port)
  set part $options(-part)
  set timeout $options(-timeout)
  # Save timeout info in the case it was passed as argument
  set params(timeout) $timeout
  if {($host != {localhost}) && ($host != {})} {
    error " error - p2pdelay server can only run on localhost. Use '-host localhost' to specify the local host"
  }
  if {$port == {}} {
    error " error - no port specified. Use -port to specify a port"
  }
  if {$part == {}} {
    error " error - no part specified. Use -part to specify a part"
  } else {
    if {[lsearch [get_parts] $part] == -1} {
      error " error - part $part is not valid"
    }
  }
  log "\n# Server started on [clock format [clock seconds]]"
  if {[catch {set socket [socket -server accept $port]} errorstring]} {
    # couldn't open socket: port number too high
    # couldn't open socket: address already in use
    error " error - $errorstring"
  }
  puts stderr " Creating in-memory project for part $part"
#   create_project p2pServer -in_memory -part $part
  create_project p2pServer -in_memory
  link_design -part $part
  # set the timeout value
  if {$timeout > 0} {
    puts stderr " -I- Timeout set to $timeout seconds on [clock format [clock seconds]]"
    after [expr $timeout * 1000] set ::tb::p2pdelay::tcpstate "tcp:timeout"
  }
  set hostname [uplevel #0 exec hostname]
  set hostid [uplevel #0 exec hostid]
  foreach line [split [createServerMsg] \n] { log "# $line" }
#   log [createServerMsg]
  puts stderr [createServerMsg]
  set params(mode) {server}
  vwait ::tb::p2pdelay::tcpstate
  if {$::tb::p2pdelay::tcpstate == {tcp:timeout}} {
    puts " -I- Server stopped by timeout on [clock format [clock seconds]]"
  } else {
    puts " -I- Server stopped on [clock format [clock seconds]]"
  }
  stopP2pServer
  set params(mode) {client}
  puts stderr " Closing project"
  close_project -delete
  # Removing all 'after'
  after cancel [after info]
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::stopP2pServer
#------------------------------------------------------------------------
# Usage: ::tb::p2pdelay::stopP2pServer
#------------------------------------------------------------------------
# Stop the p2pdelay server. This command must be run on the Running
# server side.
#------------------------------------------------------------------------
proc ::tb::p2pdelay::stopP2pServer {} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable tcpstate
  variable socket
  variable params
  if {$params(mode) != {server}} {
    puts stderr " -W- Can only be used on a running server"
    return -code ok
  }
  set tcpstate {tcp:stop}
  if {$socket == {}} {
    return -code ok
  }
  close $socket
  set socket {}
  log "# Server stopping [clock format [clock seconds]]"
#   set params(mode) {client}
  return -code ok
}


#------------------------------------------------------------------------
# ::tb::p2pdelay::handle
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Handle for socket communication
#------------------------------------------------------------------------
proc ::tb::p2pdelay::handle {chan} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable script
  variable params
        if {[eof $chan]} {
if {$params(debug)} { puts "EOF for $chan" }
            close $chan
            # Extend the server timeout (if applicable)
            extendServerTimeout
            return
        }
        if {![catch {read $chan} chunk]} {
if {$params(debug)} { puts "<chunk:$chunk>" }
            append script $chunk
            if {[info complete $script]} {
if {$params(debug)} { puts "Executing:<$script>" }
              if {[regexp {^\s*$} $script]} {
                # This case most likely happens only when isP2pServerReady is executed
#                 puts $chan " Server [uplevel #0 [list exec hostname]] is alive"
                close $chan
                return
              }
              log "# Server executing command on [clock format [clock seconds]]"
              foreach line [split [lindex $script 0] \n] {
                log "$line"
              }
              uplevel #0 [list catch [format {eval %s} $script] ::tb::p2pdelay::result]
# puts "<::tb::p2pdelay::result:$::tb::p2pdelay::result>"
              log "# Server completed command on [clock format [clock seconds]]"
              log "# Result:"
              foreach line [split $::tb::p2pdelay::result \n] {
                log "#    $line"
              }
              if {$params(echo)} { puts stderr $::tb::p2pdelay::result }
if {$params(debug)} { puts "result:<$::tb::p2pdelay::result>" }
# puts "returnstring:<$::returnstring>"
#               uplevel #0 [list catch [format {set ::tb::p2pdelay::result [eval %s]} $script] ::returnstring]
              set script ""
              puts -nonewline $chan $::tb::p2pdelay::result
              flush $chan
              close $chan
            } else {
if {$params(debug)} { puts "Script fragment:<$script>" }
            }
        } else {
if {$params(debug)} { puts "closing channel $chan" }
          close $chan
        }
  puts stderr [createServerShortMsg]
  # Extend the server timeout (if applicable)
  extendServerTimeout
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::accept
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Proc executed when data are received
#------------------------------------------------------------------------
proc ::tb::p2pdelay::accept {chan addr port} {
  # Summary :
  # Argument Usage:
  # Return Value:

#   fconfigure $chan -buffering line
  variable params
  fconfigure $chan -blocking 0 -buffering none
  fileevent $chan readable \
         [list ::tb::p2pdelay::handle $chan]
  puts " $addr:$port connected on [clock format [clock seconds]] ($chan)"
  puts " $addr:$port connected on [clock format [clock seconds]] ($chan)"
  log "# Connection from $addr:$port connected on [clock format [clock seconds]] ($chan)"

#   # After each new connection, remove any existing timeout and restart a new one
#   extendServerTimeout
#   after cancel [after info]
#   set timeout $params(timeout)
#   if {$timeout > 0} {
#     puts stderr " -I- Timeout set to $timeout seconds"
#     after [expr $timeout * 1000] set ::tb::p2pdelay::tcpstate "tcp:timeout"
#   }

  return -code ok
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::method:configure
#------------------------------------------------------------------------
# Usage: p2pdelay configure [<options>]
#------------------------------------------------------------------------
# Configure some of the  p2pdelay parameters
#------------------------------------------------------------------------
proc ::tb::p2pdelay::method:configure {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Configure p2pdelay (-help)
  variable params
  set reset 0
  set error 0
  set help 0
  if {[llength $args] == 0} {
    set help 1
  }
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-ho(st?)?$} {
        set params(host) [lshift args]
      }
      {^-po(rt?)?$} {
        set params(port) [lshift args]
      }
      {^-pa(rt?)?$} {
        set params(part) [lshift args]
      }
      {^-ti(m(e(o(ut?)?)?)?)?$} {
        set params(timeout) [lshift args]
      }
      {^-op(t(i(o(ns?)?)?)?)?$} {
        set params(options) [lshift args]
      }
      {^-log?$} {
        set params(log) [lshift args]
        set FH [open $params(log) {a}]
        puts " -I- Opening log file: [file normalize $params(log)] on [clock format [clock seconds]]"
        puts $FH "#####################################"
        puts $FH "## [clock format [clock seconds]]"
        puts $FH "#####################################"
        close $FH
      }
      {^-v(e(r(b(o(se?)?)?)?)?)?$} {
        set params(verbose) 1
      }
      {^-qu(i(et?)?)?$} -
      {^-nov(e(r(b(o(se?)?)?)?)?)?$} {
        set params(verbose) 0
      }
      {^-d(e(b(ug?)?)?)?$} {
        set params(debug) 1
      }
      {^-nod(e(b(ug?)?)?)?$} {
        set params(debug) 0
      }
      {^-ec(ho?)?$} {
        set params(echo) 1
      }
      {^-noe(c(ho?)?)?$} {
        set params(echo) 0
      }
      {^-h(e(lp?)?)?$} {
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
    puts stdout [format {
  Usage: p2pdelay configure
              [-host <IP Address>]
              [-port <number>]
              [-part <xilinx_part_name>]
              [-timeout <seconds>]
              [-options <list_of_options>]
              [-log <logfile>]
              [-verbose|-quiet]
              [-echo|-noecho]
              [-help|-h]

  Description: Configure p2pdelay

    Use -options to provide additional command line option to ::internal::route_dbg_p2p_route

  Example:
     p2pdelay configure -host localhost -port 12345
     p2pdelay configure -host localhost -port 12345 -options {-removeLUTPinDelay}
} ]
    # HELP -->
    return -code ok
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::method:compare_p2p_est
#------------------------------------------------------------------------
# Usage: p2pdelay compare_p2p_est [<options>]
#------------------------------------------------------------------------
# Configure P2P vs Estimates delays inside a file
#------------------------------------------------------------------------
proc ::tb::p2pdelay::method:compare_p2p_est {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Compare P2p vs. Estimated delays from file (-help)
  variable params
  set ifilename {}
  set ofilename {}
  set csvDelimiter {,}
  set opt $params(options)
  set fanout {}
  set error 0
  set help 0
  if {[llength $args] == 0} {
    set help 1
  }
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-i(n(p(ut?)?)?)?$} {
        set ifilename [lshift args]
      }
      {^-o(u(t(p(ut?)?)?)?)?$} {
        set ofilename [lshift args]
      }
      {^-re(m(o(v(e(l(u(t(p(i(n(d(e(l(ay?)?)?)?)?)?)?)?)?)?)?)?)?)?)?$} {
        lappend opt {-removeLUTPinDelay}
      }
      {^-di(s(a(b(l(e(g(l(o(b(a(ls?)?)?)?)?)?)?)?)?)?)?)?$} {
        lappend opt {-disableGlobals}
      }
      {^-op(t(i(o(ns?)?)?)?)?$} {
        set opt [concat $opt [lshift args]]
      }
      {^-fa(n(o(ut?)?)?)?$} {
        set fanout [lshift args]
      }
      {^-de(l(i(m(i(t(er?)?)?)?)?)?)?$} {
        set csvDelimiter [lshift args]
      }
      {^-v(e(r(b(o(se?)?)?)?)?)?$} {
        set params(verbose) 1
      }
      {^-qu(i(et?)?)?$} -
      {^-nov(e(r(b(o(se?)?)?)?)?)?$} {
        set params(verbose) 0
      }
      {^-d(e(b(ug?)?)?)?$} {
        set params(debug) 1
      }
      {^-nod(e(b(ug?)?)?)?$} {
        set params(debug) 0
      }
      {^-h(e(lp?)?)?$} {
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
    puts stdout [format {
  Usage: p2pdelay compare_p2p_est
              -input <filename>
              -output <filename>
              [-removelutpindelay]
              [-disableglobals]
              [-fanout <net_fanout>]
              [-options <list_of_options>]
              [-delimiter <csv-delimiter>]
              [-verbose|-quiet]
              [-help|-h]

  Description: Compare P2p vs. Estimated delays from file

    The input file format is: <fromPin>,<toPin>
    For example:
        int12_inv_i_1/O,int12_reg_inv/D
        SLICE_X1Y16 AQ,IOB_X0Y16 O

    Use -options to provide additional command line option to ::internal::route_dbg_p2p_route
    Use -removelutpindelay as replacement for '-options {-removeLUTPinDelay}'
    Use -disableglobals as replacement for '-options {-disableGlobals}'
    Use -fanout to adjust the estimated delay based on net fanout

  Example:
     p2pdelay compare_p2p_est -input pairs.csv -output compare.csv
     p2pdelay compare_p2p_est -input pairs.csv -output compare.csv -options {-removeLUTPinDelay -disableGlobals}
     p2pdelay compare_p2p_est -input pairs.csv -output compare.csv -removeLUTPinDelay -disableGlobals -fanout 100
} ]
    # HELP -->
    return -code ok
  }

  if {![file exists $ifilename]} {
    incr error
    puts " -E- file '$ifilename' does not exist"
  }

  if {$ofilename == {}} {
    incr error
    puts " -E- output file not provided (-output)"
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  set FHin [open $ifilename {r}]
  set FHout [open $ofilename {w}]

  puts $FHout "# input file: [file normalize $ifilename]"
  if {$fanout == {}} {
    puts $FHout "# estDly: Estimated delay (Placer)"
  } else {
    puts $FHout "# estDly: Estimated delay (Placer) (fanout = $fanout)"
  }
  puts $FHout "# p2pDly: Best route delay (Router) (=crunch delay)"
  puts $FHout "# sysDly: Best route delay (STA) (=system delay)"
  set options $opt
  if {$fanout != {}} { set options [concat $options -fanout $fanout] }
  if {$options == {}} {
    puts $FHout "# Options: <none>"
  } else {
    puts $FHout "# Options: $options"
  }
  puts $FHout "from,to,estDly,p2pDly,sysDly,ratio (est/p2p),absErr (est-p2p),ratio (est/sys),absErr (est-sys)"

  while {![eof $FHin]} {
    gets $FHin line
    if {[regexp {^\s*$} $line] || [regexp {^\s*#} $line]} {
      continue
    }
    set pins [split-csv $line $csvDelimiter]
    switch [llength $pins] {
      2 {
        set from [string trim [lindex $pins 0]]
        set to [string trim [lindex $pins 1]]
      }
      default {
        puts " -W- Invalid format. Skipping line '$line'"
        continue
      }
    }
    if {[catch {
      # P2p delay + system delay
      foreach {p2pdly sysdly} [get_p2p_delay -from $from -to $to -delay both -options [list {*}$opt] ] { break }
      # Estimated delay
      set estdly [get_est_wire_delay -from $from -to $to -fanout $fanout]
    } errorstring]} {
      puts " -W- Error during P2P/Estimated delay extraction: from=$from / to=$to"
      set row [list $from $to - - - - - - -]
      puts $FHout [join-csv $row $csvDelimiter]
      continue
    }
    set row [list]
    lappend row $from
    lappend row $to
    lappend row $estdly
    lappend row $p2pdly
    lappend row $sysdly
    if {$p2pdly == 0} {
      lappend row {#DIV0}
    } else {
      if {[catch {set ratio [expr double($estdly)/double($p2pdly)]}]} {
        lappend row {N/A}
      } else {
        lappend row [format {%.2f} $ratio]
      }
    }
    if {[catch {set err [expr abs(double($estdly) - double($p2pdly))]}]} {
      lappend row {N/A}
    } else {
      lappend row [format {%.2f} $err]
    }
    if {$sysdly == 0} {
      lappend row {#DIV0}
    } else {
      if {[catch {set ratio [expr double($estdly)/double($sysdly)]}]} {
        lappend row {N/A}
      } else {
        lappend row [format {%.2f} $ratio]
      }
    }
    if {[catch {set err [expr abs(double($estdly) - double($sysdly))]}]} {
      lappend row {N/A}
    } else {
      lappend row [format {%.2f} $err]
    }
    puts $FHout [join-csv $row $csvDelimiter]
  }

  close $FHout
  close $FHin

  puts " -I- Generated file [file normalize $ofilename]"

  return -code ok
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::method:get_p2p_info
#------------------------------------------------------------------------
# Usage: p2pdelay get_p2p_info [<options>]
#------------------------------------------------------------------------
# Get the P2P route info
#------------------------------------------------------------------------
proc ::tb::p2pdelay::method:get_p2p_info {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Get the P2P route info (-help)
  variable params
  set delay $params(delay)
  set port $params(port)
  set host $params(host)
  set opt $params(options)
  set from {}
  set to {}
  if {$params(mode) == {server}} {
    puts " -E- cannot use get_p2p_info on the server side. The command must be run from the client side"
    return -code error
  }
  set reset 0
  set error 0
  set help 0
  if {[llength $args] == 0} {
    set help 1
  }
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-de(l(ay?)?)?$} {
        set delay [lshift args]
      }
      {^-p2p?$} {
        set delay {p2p}
      }
      {^-sy(s(t(em?)?)?)?$} {
        set delay {system}
      }
      {^-ho(st?)?$} {
        set host [lshift args]
      }
      {^-po(rt?)?$} {
        set port [lshift args]
      }
      {^-f(r(om?)?)?$} {
        set from [lshift args]
      }
      {^-to?$} {
        set to [lshift args]
      }
      {^-re(m(o(v(e(l(u(t(p(i(n(d(e(l(ay?)?)?)?)?)?)?)?)?)?)?)?)?)?)?$} {
        lappend opt {-removeLUTPinDelay}
      }
      {^-di(s(a(b(l(e(g(l(o(b(a(ls?)?)?)?)?)?)?)?)?)?)?)?$} {
        lappend opt {-disableGlobals}
      }
      {^-op(t(i(o(ns?)?)?)?)?$} {
        set opt [concat $opt [lshift args]]
      }
      {^-h(e(lp?)?)?$} {
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
    puts stdout [format {
  Usage: p2pdelay get_p2p_info
              -from <pin>|-from {<site> <pin>}
              -to <pin>|-to {<site> <pin>}
              [-p2p][-system][-delay <p2p|crunch|system|both>]
              [-removelutpindelay]
              [-disableglobals]
              [-options <list_options>]
              [-host <IP Address>]
              [-port <number>]
              [-help|-h]

  Description: Get the P2P route info

    Use -options to provide additional command line option to ::internal::route_dbg_p2p_route
    Use -delay to select the delay type:
      p2p|crunch: delay seen by router
      system: system delay seen by STA (UltraScale Plus and beyond)
      both: return a list of both p2p and system delays
      Default: p2p
    Use -removelutpindelay as replacement for '-options {-removeLUTPinDelay}'
    Use -disableglobals as replacement for '-options {-disableGlobals}'
    Use -p2p as replacement for '-delay p2p'
    Use -system as replacement for '-delay system'

  Example:
     p2pdelay get_p2p_info -from {SLICE_X47Y51 AQ} -to {SLICE_X47Y51 A1}
     p2pdelay get_p2p_info -from int1_reg/Q -to {SLICE_X47Y51 A1} -options {-removeLUTPinDelay}
     p2pdelay get_p2p_info -from int1_reg/Q -to {SLICE_X47Y51 A1} -options {-removeLUTPinDelay} -delay system
     p2pdelay get_p2p_info -from int1_reg/Q -to {SLICE_X47Y51 A1} -removelutpindelay -p2p
} ]
    # HELP -->
    return -code ok
  }

  switch [llength $from] {
    0 {
      puts " -E- nothing provided for -from"
      incr error
    }
    1 {
      if {[get_pins -quiet $from] != {}} {
        set from [::tb::p2pdelay::method:pin_info -pin $from]
#         set from [split [lindex [get_site_pin -quiet -of [get_pin -quiet $from]] 0] /]
      } elseif {$from == {}} {
        set from [get_pins -quiet -leaf -of [get_nets -quiet -of [get_pins -quiet $options(-to)]] -filter {DIRECTION==OUT}]
        set from [::tb::p2pdelay::method:pin_info -pin $from]
#         set from [split [lindex [get_site_pin -quiet -of [get_pin -quiet $from]] 0] /]
      }
    }
    2 {
      # Format: "site pin"
      # Ok, nothing to do
    }
    default {
      puts " -E- wrong format for -from"
      incr error
    }
  }
  switch [llength $to] {
    0 {
      error " -E- nothing provided for -to"
    }
    1 {
      if {[get_pins -quiet $to] != {}} {
        set to [::tb::p2pdelay::method:pin_info -pin $to]
#         set to [split [lindex [get_site_pin -quiet -of [get_pin -quiet $to]] 0] /]
      } else {
        set to {}
      }
    }
    2 {
      # Format: "site pin"
      # Ok, nothing to do
    }
    default {
      puts " -E- wrong format for -to"
      incr error
    }
  }
# puts "<from:$from><to:$to>"
# if {$params(debug)} { puts "<from:$from><to:$to>" }
  if {($from =={}) || ($to == {})} {
    # The -from or -to could not be resolved
    puts " -E- error with -from/-to"
    incr error
  }
  switch $delay {
    both -
    p2p -
    crunch -
    system {
    }
    default {
      puts " -E- wrong delay type '$delay'. Valid types are: p2p | crunch | system"
      incr error
    }
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  return [getP2pInfo -delay $delay -from $from -to $to -host $host -port $port -options $opt]
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::method:get_p2p_delay
#------------------------------------------------------------------------
# Usage: p2pdelay get_p2p_delay [<options>]
#------------------------------------------------------------------------
# Get the P2P route delay
#------------------------------------------------------------------------
proc ::tb::p2pdelay::method:get_p2p_delay {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Get the P2P route delay (-help)
  variable params
  set delay $params(delay)
  set port $params(port)
  set host $params(host)
  set opt $params(options)
  set from {}
  set to {}
  if {$params(mode) == {server}} {
    puts " -E- cannot use get_p2p_delay on the server side. The command must be run from the client side"
    return -code error
  }
  set reset 0
  set error 0
  set help 0
  if {[llength $args] == 0} {
    set help 1
  }
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-de(l(ay?)?)?$} {
        set delay [lshift args]
      }
      {^-p2p?$} {
        set delay {p2p}
      }
      {^-sy(s(t(em?)?)?)?$} {
        set delay {system}
      }
      {^-ho(st?)?$} {
        set host [lshift args]
      }
      {^-po(rt?)?$} {
        set port [lshift args]
      }
      {^-f(r(om?)?)?$} {
        set from [lshift args]
      }
      {^-to?$} {
        set to [lshift args]
      }
      {^-re(m(o(v(e(l(u(t(p(i(n(d(e(l(ay?)?)?)?)?)?)?)?)?)?)?)?)?)?)?$} {
        lappend opt {-removeLUTPinDelay}
      }
      {^-di(s(a(b(l(e(g(l(o(b(a(ls?)?)?)?)?)?)?)?)?)?)?)?$} {
        lappend opt {-disableGlobals}
      }
      {^-op(t(i(o(ns?)?)?)?)?$} {
        set opt [concat $opt [lshift args]]
      }
      {^-h(e(lp?)?)?$} {
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
    puts stdout [format {
  Usage: p2pdelay get_p2p_delay
              -from <pin>|-from {<site> <pin>}
              -to <pin>|-to {<site> <pin>}
              [-p2p][-system][-delay <p2p|crunch|system|both>]
              [-removelutpindelay]
              [-disableglobals]
              [-options <list_options>]
              [-host <IP Address>]
              [-port <number>]
              [-help|-h]

  Description: Get the P2P route delay or System delay

    Use -options to provide additional command line option to ::internal::route_dbg_p2p_route
    Use -delay to select the delay type:
      p2p|crunch: delay seen by router
      system: system delay seen by STA (UltraScale Plus and beyond)
      both: return a list of both p2p and system delays
      Default: p2p
    Use -removelutpindelay as replacement for '-options {-removeLUTPinDelay}'
    Use -disableglobals as replacement for '-options {-disableGlobals}'
    Use -p2p as replacement for '-delay p2p'
    Use -system as replacement for '-delay system'

  Example:
     p2pdelay get_p2p_delay -from {SLICE_X47Y51 AQ} -to {SLICE_X47Y51 A1}
     p2pdelay get_p2p_delay -from int1_reg/Q -to {SLICE_X47Y51 A1} -options {-removeLUTPinDelay}
     p2pdelay get_p2p_delay -from int1_reg/Q -to {SLICE_X47Y51 A1} -options {-removeLUTPinDelay -disableGlobals}
     p2pdelay get_p2p_delay -from int1_reg/Q -to {SLICE_X47Y51 A1} -delay system
     p2pdelay get_p2p_delay -from int1_reg/Q -to {SLICE_X47Y51 A1} -removelutpindelay -p2p
} ]
    # HELP -->
    return -code ok
  }

  switch [llength $from] {
    0 {
      puts " -E- nothing provided for -from"
      incr error
    }
    1 {
      if {[get_pins -quiet $from] != {}} {
        set from [::tb::p2pdelay::method:pin_info -pin $from]
#         set from [split [lindex [get_site_pin -quiet -of [get_pin -quiet $from]] 0] /]
      } elseif {$from == {}} {
        set from [get_pins -quiet -leaf -of [get_nets -quiet -of [get_pins -quiet $options(-to)]] -filter {DIRECTION==OUT}]
        set from [::tb::p2pdelay::method:pin_info -pin $from]
#         set from [split [lindex [get_site_pin -quiet -of [get_pin -quiet $from]] 0] /]
      }
    }
    2 {
      # Format: "site pin"
      # Ok, nothing to do
    }
    default {
      puts " -E- wrong format for -from"
      incr error
    }
  }
  switch [llength $to] {
    0 {
      error " -E- nothing provided for -to"
    }
    1 {
      if {[get_pins -quiet $to] != {}} {
        set to [::tb::p2pdelay::method:pin_info -pin $to]
#         set to [split [lindex [get_site_pin -quiet -of [get_pin -quiet $to]] 0] /]
      } else {
        set to {}
      }
    }
    2 {
      # Format: "site pin"
      # Ok, nothing to do
    }
    default {
      puts " -E- wrong format for -to"
      incr error
    }
  }
# puts "<from:$from><to:$to>"
# if {$params(debug)} { puts "<from:$from><to:$to>" }
  if {($from =={}) || ($to == {})} {
    # The -from or -to could not be resolved
    puts " -E- error with -from/-to"
    incr error
  }
  switch $delay {
    both -
    p2p -
    crunch -
    system {
    }
    default {
      puts " -E- wrong delay type '$delay'. Valid types are: p2p | crunch | system"
      incr error
    }
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  switch $delay {
    p2p -
    crunch {
      return [lindex [getP2pInfo -delay $delay -from $from -to $to -host $host -port $port -options $opt] 0]
    }
    system {
      return [lindex [getP2pInfo -delay $delay -from $from -to $to -host $host -port $port -options $opt] 1]
    }
    both {
      set res [getP2pInfo -delay $delay -from $from -to $to -host $host -port $port -options $opt]
      set p2p [lindex $res 0]
      set system [lindex $res 1]
      return [list [lindex $p2p 0] [lindex $system 1] ]
    }
  }
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::method:get_est_wire_delay
#------------------------------------------------------------------------
# Usage: p2pdelay get_est_wire_delay [<options>]
#------------------------------------------------------------------------
# Get the P2P estimated wire delay
#------------------------------------------------------------------------
proc ::tb::p2pdelay::method:get_est_wire_delay {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Get the P2P estimated wire delay (-help)
  variable params
  set port $params(port)
  set host $params(host)
  set from {}
  set to {}
  set fanout {}
  if {$params(mode) == {server}} {
    puts " -E- cannot use get_est_wire_delay on the server side. The command must be run from the client side"
    return -code error
  }
  set reset 0
  set error 0
  set help 0
  if {[llength $args] == 0} {
    set help 1
  }
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-ho(st?)?$} {
        set host [lshift args]
      }
      {^-po(rt?)?$} {
        set port [lshift args]
      }
      {^-f(r(om?)?)?$} {
        set from [lshift args]
      }
      {^-to?$} {
        set to [lshift args]
      }
      {^-fa(n(o(ut?)?)?)?$} {
        set fanout [lshift args]
      }
      {^-h(e(lp?)?)?$} {
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
    puts stdout [format {
  Usage: p2pdelay get_est_wire_delay
              -from <pin>|-from {<site> <pin>}
              -to <pin>|-to {<site> <pin>}
              [-fanout <net_fanout>]
              [-host <IP Address>]
              [-port <number>]
              [-help|-h]

  Description: Get the P2P estimated wire delay

    Use -fanout to adjust the estimated delay based on net fanout

  Example:
     p2pdelay get_est_wire_delay -from {SLICE_X47Y51 AQ} -to {SLICE_X47Y51 A1}
     p2pdelay get_est_wire_delay -from int1_reg/Q -to {SLICE_X47Y51 A1} -fanout 20
} ]
    # HELP -->
    return -code ok
  }

  switch [llength $from] {
    0 {
      puts " -E- nothing provided for -from"
      incr error
    }
    1 {
      if {[get_pins -quiet $from] != {}} {
        set from [::tb::p2pdelay::method:pin_info -pin $from]
#         set from [split [lindex [get_site_pin -quiet -of [get_pin -quiet $from]] 0] /]
      } elseif {$from == {}} {
        set from [get_pins -quiet -leaf -of [get_nets -quiet -of [get_pins -quiet $options(-to)]] -filter {DIRECTION==OUT}]
        set from [::tb::p2pdelay::method:pin_info -pin $from]
#         set from [split [lindex [get_site_pin -quiet -of [get_pin -quiet $from]] 0] /]
      }
    }
    2 {
      # Format: "site pin"
      # Ok, nothing to do
    }
    default {
      puts " -E- wrong format for -from"
      incr error
    }
  }
  switch [llength $to] {
    0 {
      error " -E- nothing provided for -to"
    }
    1 {
      if {[get_pins -quiet $to] != {}} {
        set to [::tb::p2pdelay::method:pin_info -pin $to]
#         set to [split [lindex [get_site_pin -quiet -of [get_pin -quiet $to]] 0] /]
      } else {
        set to {}
      }
    }
    2 {
      # Format: "site pin"
      # Ok, nothing to do
    }
    default {
      puts " -E- wrong format for -to"
      incr error
    }
  }
# puts "<from:$from><to:$to>"
# if {$params(debug)} { puts "<from:$from><to:$to>" }
  if {($from =={}) || ($to == {})} {
    # The -from or -to could not be resolved
    puts " -E- error with -from/-to"
    incr error
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  if {($port == {}) || ($host == {})} {
    set delay [getP2pEstWireDelay -from $from -to $to]
  } else {
    if {[isP2pServerReady -port $port -host $host]} {
      if {$params(debug)} { puts stderr " -D- Sending request to server host:$host / port:$port" }
      set delay [rexec [format {::tb::p2pdelay::getP2pEstWireDelay -from "%s" -to "%s"} $from $to]]
    } else {
      puts " -W- could not connect to P2P server host:$host / port:$port . Running command locally"
      set delay [getP2pEstWireDelay -from $from -to $to]
    }
  }
  # Adjust delay for fanout?
  if {[regexp {^[0-9]+$} $fanout]} {
    if {$params(debug)} { puts stderr " -D- Estimated wire delay before fanout adjustment: $delay" }
    if {$fanout > 500} { set fanout 500 }
    if {$fanout <= 1} {
      set fanoutPenalty 0.0
    } else {
      # Magic formula to calculate the delay penalty based on the net fanout (i.e number of loads)
      set fanoutPenalty [format {%.2f} [expr  10 * (2.53 * log($fanout) -1.67) ] ]
    }
    set delay [expr int($delay + $fanoutPenalty)]
    if {$params(debug)} { puts stderr " -D- Estimated wire delay after fanout adjustment (fanout:$fanout / penalty:${fanoutPenalty}ps): $delay" }
  }
  return $delay
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::method:pin_info
#------------------------------------------------------------------------
# Usage: p2pdelay pin_info [<options>]
#------------------------------------------------------------------------
# Get the pin site infomation
#------------------------------------------------------------------------
proc ::tb::p2pdelay::method:pin_info {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Get the site infomation from a pin (-help)
  variable params
  set pinname {}
  set pininfo {}
  set reset 0
  set error 0
  set help 0
  if {[llength $args] == 0} {
    set help 1
  }
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-p(in?)?$} {
        set pinname [lshift args]
      }
      {^-h(e(lp?)?)?$} {
        set help 1
      }
      default {
        if {[string match "-*" $name]} {
          puts " -E- option '$name' is not a valid option."
          incr error
        } else {
          set pinname $name
#           puts " -E- option '$name' is not a valid option."
#           incr error
        }
      }
    }
  }

  if {$help} {
    puts stdout [format {
  Usage: p2pdelay pin_info
              -pin <pin>
              <pin>
              [-help|-h]

  Description: Get the pin site infomation

  Example:
     p2pdelay pin_info -pin int1_reg/Q
     p2pdelay pin_info int1_reg/Q
} ]
    # HELP -->
    return -code ok
  }

  switch [llength $pinname] {
    0 {
      puts " -E- nothing provided for -pin"
      incr error
    }
    1 {
      set pin [get_pins -quiet $pinname]
      switch [llength $pin] {
        0 {
          puts " -E- cannot find pin '$pinname'"
          incr error
        }
        1 {
          set sitepins [get_site_pin -quiet -of [get_pin -quiet $pinname]]
          if {[llength $sitepins] == 1} {
            set pininfo [split [get_site_pin -quiet -of [get_pin -quiet $pinname]] /]
          } else {
            # Multiple site pins are returned. This can happen, for example, with CARRY8/COUT
            # that connects to 2 site pins COUT and HMUX inside the site
            # By default, take the first one
            set pininfo [split [lindex [get_site_pin -quiet -of [get_pin -quiet $pinname]] 0] /]
            # Now let's find the correct one (if any found)
            # This can be runtime intensive!
            foreach sitepin $sitepins {
              # Get node outside of site
              set nodes [get_nodes -quiet -of $sitepin]
              # Is there a net connected to it?
              set net [get_nets -quiet -of $nodes]
              if {$net != {}} {
                set pininfo [split $sitepin /]
                break
              }
            }
          }
#           set pininfo [split [lindex [get_site_pin -quiet -of [get_pin -quiet $pinname]] 0] /]
        }
        default {
          puts " -E- multiple pins ([llength $pin]) match '$pinname'"
          incr error
        }
      }
    }
    default {
      puts " -E- multiple pins names ([llength $pinname])"
      incr error
    }
  }
#   if {$pininfo == {}} {
#     # The -pin could not be resolved
#     puts " -E- could not extract site information from pin '$pinname'"
#     incr error
#   }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  return $pininfo
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::method:start_server
#------------------------------------------------------------------------
# Usage: p2pdelay start_server
#------------------------------------------------------------------------
# Start the p2p server
#------------------------------------------------------------------------
proc ::tb::p2pdelay::method:start_server {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Start the p2p server
  variable params
  if {$params(mode) == {server}} {
    puts " -E- server is already running"
    return -code error
  }
  eval [concat startP2pServer $args]
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::method:stop_server
#------------------------------------------------------------------------
# Usage: p2pdelay stop_server
#------------------------------------------------------------------------
# Stop the remote p2p server
#------------------------------------------------------------------------
proc ::tb::p2pdelay::method:stop_server {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Stop the p2p server
  variable params
  set port $params(port)
  set host $params(host)
  if {$params(mode) == {server}} {
    puts " -E- cannot use stop_server on the server side. The command must be run from the client side"
    return -code error
  }
  if {![isP2pServerReady -port $port -host $host]} {
    puts " -W- could not connect to P2P server host:$host / port:$port"
    return -code error
  }
  ::tb::p2pdelay::rexec ::tb::p2pdelay::stopP2pServer
  puts " -I- stopped P2P server host:$host / port:$port"
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::p2pdelay::method:status
#------------------------------------------------------------------------
# Usage: p2pdelay status
#------------------------------------------------------------------------
# Status of the P2P server
#------------------------------------------------------------------------
proc ::tb::p2pdelay::method:status {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Status of the p2p server
  variable params
  set port $params(port)
  set host $params(host)
  if {$params(mode) == {server}} {
    puts " -E- cannot use status on the server side. The command must be run from the client side"
    return -code error
  }
  if {![isP2pServerReady -port $port -host $host]} {
    puts " -W- could not connect to P2P server host:$host / port:$port"
    return -code error
  }
  set options [rexec {set ::tb::p2pdelay::params(options)}]
  set part [rexec {set ::tb::p2pdelay::params(part)}]
  if {$options == {}} {
    puts " -I- online P2P server host:$host / port:$port / part:$part"
  } else {
    puts " -I- online P2P server host:$host / port:$port / part:$part / options:$options"
  }
  return -code ok
}

#################################################################################

namespace import -force ::tb::p2pdelay
namespace import -force ::tb::p2pdelay::get_p2p_delay
namespace import -force ::tb::p2pdelay::get_p2p_info
namespace import -force ::tb::p2pdelay::get_est_wire_delay

# Information
# p2pdelay -help
# # puts " Add commands to the p2pdelay with:"
# # puts "     p2pdelay add *\n"

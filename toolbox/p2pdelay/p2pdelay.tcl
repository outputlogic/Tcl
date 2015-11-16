####################################################################################################
# HEADER_BEGIN
# COPYRIGHT NOTICE
# Copyright 2001-2014 Xilinx Inc. All Rights Reserved.
# http://www.xilinx.com/support
# HEADER_END
####################################################################################################

########################################################################################
##
## Company:        Xilinx, Inc.
## Created by:     David Pefourque
##
## Version:        2014.12.16
## Tool Version:   Vivado 2014.1
## Description:    This package provides commands for timing correlation
##
########################################################################################

########################################################################################
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
  variable version {2014.12.16}
  variable params
  variable tcpstate {}
  variable socket {}
  variable script {}
  variable result {}
  variable report {}
  catch {unset params}
  array set params [list host {} port {12345} mode {client} log {} verbose 0 part {} timeout 0 debug 0 echo 0 options {}]
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
# Get p2p delay from either the remote Vivado session or current Vivado
# session
#------------------------------------------------------------------------
proc ::tb::p2pdelay::getP2pDelay { args } {
  set res [eval [concat getP2pInfo $args]]
  set delay [lindex $res 0]
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
  set defaults [list -from {} -to {} -port $params(port) -host $params(host) -options $params(options)]
  array set options $defaults
  array set options $args
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
        set from [split [lindex [get_site_pin -quiet -of [get_pin -quiet $from]] 0] /]
      } elseif {$from == {}} {
        set from [get_pins -quiet -leaf -of [get_nets -quiet -of [get_pins -quiet $options(-to)]] -filter {DIRECTION==OUT}]
        set from [split [lindex [get_site_pin -quiet -of [get_pin -quiet $from]] 0] /]
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
        set to [split [lindex [get_site_pin -quiet -of [get_pin -quiet $to]] 0] /]
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
  set res [getP2pRouteInfo $report]
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
#------------------------------------------------------------------------
proc ::tb::p2pdelay::getP2pRouteInfo {report} {
  # PATH (dly = 704, instDly = 0, wl = 6, res = 45)
  if {[regexp -nocase -- {PATH\s*\(\s*dly\s*\=\s*([^\s]+)\s*\,\s*instDly\s*\=\s*([^\s]+)\s*\,\s*wl\s*\=\s*([^\s]+)\s*\,\s*res\s*\=\s*([^\s]+)\s*\)} $report - dly instDly wl res ]} {
    return [list $dly $instDly $wl $res]
  } else {
    error " error - could not extract delay from \n $report"
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
  if {$params(debug)} { puts stderr " -D- ::internal::route_dbg_p2p_route $cmdLine" }
  eval [concat ::internal::route_dbg_p2p_route $cmdLine > p2p${pid}.out]
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
# Configure some of the p2pdelay parameters
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
    switch -exact -- $name {
      -host -
      -host {
           set params(host) [lshift args]
      }
      -port -
      -port {
           set params(port) [lshift args]
      }
      -part -
      -part {
           set params(part) [lshift args]
      }
      -timeout -
      -timeout {
           set params(timeout) [lshift args]
      }
      -option -
      -options {
           set params(options) [lshift args]
      }
      -log {
           set params(log) [lshift args]
           set FH [open $params(log) {a}]
           puts " -I- Opening log file: [file normalize $params(log)] on [clock format [clock seconds]]"
           puts $FH "#####################################"
           puts $FH "## [clock format [clock seconds]]"
           puts $FH "#####################################"
           close $FH
      }
      -verbose {
           set params(verbose) 1
      }
      -quiet {
           set params(verbose) 0
      }
      -debug {
           set params(debug) 1
      }
      -nodebug {
           set params(debug) 0
      }
      -echo {
           set params(echo) 1
      }
      -noecho {
           set params(echo) 0
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
    switch -exact -- $name {
      -host -
      -host {
           set host [lshift args]
      }
      -port -
      -port {
           set port [lshift args]
      }
      -from -
      -from {
           set from [lshift args]
      }
      -to -
      -to {
           set to [lshift args]
      }
      -option -
      -options {
           set opt [lshift args]
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
    puts stdout [format {
  Usage: p2pdelay get_p2p_info
              -from <pin>|-from {<site> <pin>}
              -to <pin>|-to {<site> <pin>}
              [-options <list_options>]
              [-host <IP Address>]
              [-port <number>]
              [-help|-h]

  Description: Get the P2P route info

    Use -options to provide additional command line option to ::internal::route_dbg_p2p_route

  Example:
     p2pdelay get_p2p_info -from {SLICE_X47Y51 AQ} -to {SLICE_X47Y51 A1}
     p2pdelay get_p2p_info -from int1_reg/Q -to {SLICE_X47Y51 A1} -options {-removeLUTPinDelay}
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
        set from [split [lindex [get_site_pin -quiet -of [get_pin -quiet $from]] 0] /]
      } elseif {$from == {}} {
        set from [get_pins -quiet -leaf -of [get_nets -quiet -of [get_pins -quiet $options(-to)]] -filter {DIRECTION==OUT}]
        set from [split [lindex [get_site_pin -quiet -of [get_pin -quiet $from]] 0] /]
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
        set to [split [lindex [get_site_pin -quiet -of [get_pin -quiet $to]] 0] /]
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
  
  return [getP2pInfo -from $from -to $to -host $host -port $port -options $opt]
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
    switch -exact -- $name {
      -host -
      -host {
           set host [lshift args]
      }
      -port -
      -port {
           set port [lshift args]
      }
      -from -
      -from {
           set from [lshift args]
      }
      -to -
      -to {
           set to [lshift args]
      }
      -option -
      -options {
           set opt [lshift args]
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
    puts stdout [format {
  Usage: p2pdelay get_p2p_delay
              -from <pin>|-from {<site> <pin>}
              -to <pin>|-to {<site> <pin>}
              [-options <list_options>]
              [-host <IP Address>]
              [-port <number>]
              [-help|-h]

  Description: Get the P2P route delay

    Use -options to provide additional command line option to ::internal::route_dbg_p2p_route

  Example:
     p2pdelay get_p2p_delay -from {SLICE_X47Y51 AQ} -to {SLICE_X47Y51 A1}
     p2pdelay get_p2p_delay -from int1_reg/Q -to {SLICE_X47Y51 A1} -options {-removeLUTPinDelay}
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
        set from [split [lindex [get_site_pin -quiet -of [get_pin -quiet $from]] 0] /]
      } elseif {$from == {}} {
        set from [get_pins -quiet -leaf -of [get_nets -quiet -of [get_pins -quiet $options(-to)]] -filter {DIRECTION==OUT}]
        set from [split [lindex [get_site_pin -quiet -of [get_pin -quiet $from]] 0] /]
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
        set to [split [lindex [get_site_pin -quiet -of [get_pin -quiet $to]] 0] /]
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
  
  return [lindex [getP2pInfo -from $from -to $to -host $host -port $port] 0]
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
    switch -exact -- $name {
      -host -
      -host {
           set host [lshift args]
      }
      -port -
      -port {
           set port [lshift args]
      }
      -from -
      -from {
           set from [lshift args]
      }
      -to -
      -to {
           set to [lshift args]
      }
      -fanout -
      -fanout {
           set fanout [lshift args]
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
        set from [split [lindex [get_site_pin -quiet -of [get_pin -quiet $from]] 0] /]
      } elseif {$from == {}} {
        set from [get_pins -quiet -leaf -of [get_nets -quiet -of [get_pins -quiet $options(-to)]] -filter {DIRECTION==OUT}]
        set from [split [lindex [get_site_pin -quiet -of [get_pin -quiet $from]] 0] /]
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
        set to [split [lindex [get_site_pin -quiet -of [get_pin -quiet $to]] 0] /]
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
    switch -exact -- $name {
      -p -
      -pi -
      -pin {
           set pinname [lshift args]
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
              set pinname $name
#               puts " -E- option '$name' is not a valid option."
#               incr error
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
          set pininfo [split [lindex [get_site_pin -quiet -of [get_pin -quiet $pinname]] 0] /]
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

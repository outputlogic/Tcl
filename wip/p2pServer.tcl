
# Proc to reload current script
proc [file tail [info script]] {} " source [info script]; puts \" [info script] reloaded\" "

# get_p2p_delay -from -to
# config_p2p_delay -host -port -server -part -timeout
# config_p2p_server -host -port -server
# run_p2p_server
# -host: <hostname> or <ip>
# p2pdelay config -port -host -log -part
# p2pdelay get_delay -from -to
# p2pdelay server -connect -port -host
# p2pdelay server -start -port -log -part
# p2pdelay server -stop -port -host
# p2pdelay server -check -port -host
# p2pdelay status
# p2pdelay rexec <cmd>
# p2pdly rexec <cmd>
# p2pdelay::get_p2p_delay


# SERVER_SIDE
# source ~/git/scripts/wip/p2pServer.tcl
# startP2pServer -part xc7vx415tffg1158-2L
# startP2pServer -part xc7vh870thcg1932-2G

# CLIENT_SIDE
# source ~/git/scripts/wip/p2pServer.tcl
# set p2pDelay [getP2pPinToPinDelay -from <pin> -to <pin> ]
# set p2pDelay [getP2pPinToPinDelay -to <pin> ]
# set p2pDelay [getP2pPinToPinDelay -to "SLICE_X169Y36 AX" ]
# set p2pDelay [getP2pPinToPinDelay -from "GTHE2_CHANNEL_X1Y3 RXHEADERVALID0" -to "SLICE_X169Y36 AX" ]
# set p2pReport [rexec {getP2pSitePin2SitePinReport -from "GTHE2_CHANNEL_X1Y3 RXHEADERVALID0" -to "SLICE_X169Y36 AX" } ]

# 'localhost' when running the server or IP address for p2p server when running the client
set host {localhost}
set port 12345
set sockettimeout 2000 ;# in ms
set socket {}
set script {}

# link_design -part xcku040-fbva676-3-e-ies
# create_project p2pServer -in_memory -part xcku040-fbva676-3-e-ies
# create_project p2pServer -in_memory -part xc7vx415tffg1158-2L
# close_project -delete

###############################################

# rexec [list ::internal::route_dbg_p2p_route -from "GTHE2_CHANNEL_X1Y3 RXHEADERVALID0" -to "SLICE_X169Y36 AX" ]
# rexec [list getP2pPinToPinDelay "GTHE2_CHANNEL_X1Y3 RXHEADERVALID0" -to "SLICE_X169Y36 AX" ]
# rexec {getP2pSitePin2SitePinReport -from "GTHE2_CHANNEL_X1Y3 RXHEADERVALID0" -to "SLICE_X169Y36 AX" }
# getP2pPinToPinDelay -from "GTHE2_CHANNEL_X1Y3 RXHEADERVALID0" -to "SLICE_X169Y36 AX" 

proc rexec {cmd} {
#   set chan [socket localhost $::port]
  set chan [socket $::host $::port]
#   fconfigure $chan -blocking 0 -buffering none
  fconfigure $chan -buffering line 
  puts -nonewline $chan [list $cmd]
  flush $chan
  if {![eof $chan]} {
    set res [read $chan]
  } else {
    set res {}
  }
#   puts " result<$chan>:<$res>"
  close $chan
  return $res
}

proc log {msg} {
  set FH [open {p2pserver.log} {a}]
  puts $FH $msg
  close $FH
}

###############################################

proc getP2pPinToPinDelay { args } {
  set defaults [list -from {} -to {} -port $::port -host $::host]
  array set options $defaults
  array set options $args
  set port $options(-port)
  set host $options(-host)
  set to $options(-to)
  if {[get_pins -quiet $to] != {}} {
puts -nonewline "<to><$to>"
    set to [split [lindex [get_site_pin -quiet -of [get_pin -quiet $to]] 0] /]
puts "<$to>"
  }
  set from $options(-from)
  if {[get_pins -quiet $from] != {}} {
    set from [split [lindex [get_site_pin -quiet -of [get_pin -quiet $from]] 0] /]
  } elseif {$from == {}} {
    set from [get_pins -quiet -leaf -of [get_nets -quiet -of [get_pins -quiet $options(-to)]] -filter {DIRECTION==OUT}]
puts -nonewline "<from><$from>"
    set from [split [lindex [get_site_pin -quiet -of [get_pin -quiet $from]] 0] /]
puts "<$from>"
  }
  if {($from =={}) || ($to == {})} {
    # The -from or -to could not be resolved
  return {-}
  }
  if {[isP2pServerReady -port $port -host $host]} {
    set report [rexec [format {getP2pSitePin2SitePinReport -from "%s" -to "%s"} $from $to]]
  } else {
    set report [getP2pSitePin2SitePinReport -from $from -to $to]
  }
# puts "report:<$report>"
  # PATH (dly = 1637, ..
  if {[regexp -nocase -- {PATH\s*\(\s*dly\s*\=\s*([^\s]+)\s*\,} $report - delay]} {
    return $delay
  } else {
    error " error - could not extract delay from \n $report"
  } 
}

proc getP2pSitePin2SitePinReport { args } {
  set defaults [list -from {} -to {}]
  array set options $defaults
  array set options $args
  set from $options(-from)
  set to $options(-to)
  ::internal::route_dbg_p2p_route -from $from -to $to > p2p.out
  set FH [open p2p.out]
  set content [read $FH]
  close $FH
  file delete p2p.out
# puts "content:<$content>"
  return $content
}

proc isP2pServerReady {args} {
#   set defaults [list -port $::port -host {localhost}]
  set defaults [list -port $::port -host $::host]
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

proc startP2pServer { args } {
  global tcpstate
#   set defaults [list -port $::port -part {} -timeout -1]
  set defaults [list -port $::port -part {xc7vx415tffg1158-2L} -timeout -1]
  array set options $defaults
  array set options $args
  set port $options(-port)
  set part $options(-part)
  set timeout $options(-timeout)
  if {$port == {}} { set port $::port }
  if {$part == {}} { 
    error " error - no part specified. Use -part to specify a part"
  } else {
    if {[lsearch [get_parts] $part] == -1} {
      error " error - part $part is not valid"
    }
  }
  log "\n# Server started on [clock format [clock seconds]]"
  puts stderr " Creating in-memory project for part $part"
#   create_project p2pServer -in_memory -part $part
  create_project p2pServer -in_memory
  link_design -part $part
  # set the timeout value
  set ::socket [socket -server accept $port]
  # after $sockettimeout set tcpstate "tcp:timeout"
  # # wait for the socket to be writable
  # fileevent $sock writable { set tcpstate [stok $sock ] }
  set hostname [uplevel #0 exec hostname]
  set hostid [uplevel #0 exec hostid]
  log "# Server listening on $hostname port $port on [clock format [clock seconds]]"
  puts stderr " Server listening on [uplevel #0 exec hostid] port $port"
  puts stderr "    Hostname: $hostname"
  puts stderr "    Hostid  : $hostid"
  set res [uplevel #0 exec host $hostname]
  set ip {}
  regexp -nocase {has address\s*([^\s]+)\s*$} $res - ip
  puts stderr "    IP      : $ip"
  vwait tcpstate
  puts stderr " Closing project"
  close_project -delete
#   after 100 update
  # after cancel set tcpstate "tcp:timeout"

}

proc stopP2pServer {} {
  set ::tcpstate {tcp:ok}
  close $::socket
  log "# Server stopping [clock format [clock seconds]]"
#   puts stderr " Closing project"
#   close_project -delete
}


proc handle {chan} {
        global script
        if {[eof $chan]} {
puts "EOF for $chan"
            close $chan
            return
        }
        if {![catch {read $chan} chunk]} {
            if {$chunk eq "bye\n"} {
                puts $chan "Bye!"
                close $chan
                return
            }
puts "<chunk:$chunk>"
            append script $chunk
            if {[info complete $script]} {
puts "Executing:<$script>"
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
              uplevel #0 [list catch [format {eval %s} $script] ::result]
              log "# Server completed command on [clock format [clock seconds]]"
              log "# Result:"
              foreach line [split $::result \n] {
                log "#    $line"
              }
puts "result:<$::result>"
# puts "returnstring:<$::returnstring>"
#               uplevel #0 [list catch [format {set ::result [eval %s]} $script] ::returnstring]
              set script ""
              puts -nonewline $chan $::result
              flush $chan
              close $chan
            } else {
puts "Script fragment:<$script>"
            }
        } else {
puts "closing channel $chan"
            close $chan
        }
}

proc accept {chan addr port} {
#   fconfigure $chan -buffering line
  fconfigure $chan -blocking 0 -buffering none
  fileevent $chan readable \
         [list handle $chan]
  puts " $addr:$port connected ... ($chan)"
  log "# Connection from $addr:$port connected ($chan)"
}

proc stok {sock} {

  # we could get here because of an error
  set resp [fconfigure $sock -error]

  if {$resp == "" } {
    return "tcp:ok"
  }

  return "tcp:closed"
}

###############################################



###############################################





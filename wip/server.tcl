
# Proc to reload current script
proc [file tail [info script]] {} " source [info script]; puts \" [info script] reloaded\" "


set port 12345
set sockettimeout 2000 ;# in ms
set script {}




###############################################

proc rexec {cmd} {
  set chan [socket localhost $::port]
  fconfigure $chan -buffering line
  puts $chan [list $cmd]
  while {![eof $chan]} {
    gets $chan line
    puts " result<$chan>:<$line>"
  }
  close $chan
}

proc rexec2 {cmd} {
  set chan [socket localhost $::port]
#   fconfigure $chan -blocking 0 -buffering none
  fconfigure $chan -buffering line 
  puts $chan [list $cmd]
  flush $chan
  if {![eof $chan]} {
    set res [read $chan]
  }
  puts " result<$chan>:<$res>"
  close $chan
}

###############################################

proc start_server { {port {}} } {
  global tcpstate
  if {$port == {}} { set port $::port }
  # set the timeout value
  set sock [socket -server accept $port]
  # after $sockettimeout set tcpstate "tcp:timeout"
  # # wait for the socket to be writable
  # fileevent $sock writable { set tcpstate [stok $sock ] }
  puts stderr " Server listening on port $port"
  vwait tcpstate
  # after cancel set tcpstate "tcp:timeout"

}

proc stop {} {
  set ::forever 1
  set ::tcpstate {tcp:ok}
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
              uplevel #0 [list catch [format {eval %s} $script] result]
              set script ""
              puts $chan $::result
              flush $chan
              close $chan
            } else {
puts "Script fragment:<$script>"
            }
        } else {
            close $chan
        }
}

proc accept {chan addr port} {
#   fconfigure $chan -buffering line
  fconfigure $chan -blocking 0 -buffering none
  fileevent $chan readable \
         [list handle $chan]
  puts "$addr:$port connected ..."
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





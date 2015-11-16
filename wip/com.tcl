
# Proc to reload current script
proc [file tail [info script]] {} " source [info script]; puts \" [info script] reloaded\" "

# Which port do we listen on. The second element can be an alternative socket
# command.
# set ports {{12345 {}} {443 {}}}
set ports {{12345 {}} }

# Which commands shall be understood by our protocol
set commands {
   echo
   I
   help
   listme
   bye
   reload
   showstate
   auth
}

array unset help
array set help {
   help             {Lists the available commands.}
   {help <command>} {Prints a short help on the given command.}
   {echo <arg>}     {Return the given arguments.}
   {I am <name>}    {Tell the server your name and it will greet you.}
   listme           {Returns the Tcl script that implements this server.}
   bye              {Close the connection.}
   showstate        {Show the state array of the current connection.}
   {auth <user> <password>} {Authenticate yourself.}
}

proc showstate {} {
   upvar 1 state state
   farray state
}

proc reload {args} {
   after idle [list source [info script]]
   return "Matrix reloaded! ;)"
}

proc echo {args} {
   upvar 1 state state
   return $args
}

proc I {args} {
   set args [lrange $args 1 end]
   return "Hello $args!"
}

proc listme {} {
   set fd [open [info script]]
   set script [read $fd]
   close $fd
   return $script
}

proc bye {} {
   upvar 1 state state
   after idle [list slaveServer::closeSocket $state(socket)]
   return "Good bye!"
}

proc strip {string} {
   regsub -all -line {^\s+} $string {}
}

proc max {a b} {expr {$a > $b ? $a : $b}}

proc farray {array {separator =} {pattern *}} {
   upvar $array a
   set names [lsort [array names a $pattern]]
   set max 0
   foreach name $names {
       set max [max $max [string length $name]]
   }
   set result [list]
   foreach name $names {
       lappend result [format " %-*s %s %s" $max $name $separator $a($name)]
   }
   return [join $result "\n"]
}

proc help {{{<command>} {}}} {
   global help
   set helps [farray help - ${<command>}*]
   if {$helps == ""} {
       set helps "No help available for ${<command>}!"
   }
   return "\n$helps\n"
}

namespace eval slaveServer {
   # procs that start with a lowercase letter are public
   namespace export {[a-z]*}
   variable serversocket
}

proc slaveServer::closeSocket {socket} {
   variable $socket
   upvar 0 $socket state
   puts stderr "Closing $socket [clock format [clock seconds]]"
   catch {close $socket}
   unset state
}

# This gets called whenever a client connects
proc slaveServer::Server {socket host port} {
   variable $socket
   upvar 0 $socket state
   # just to be sure ...
   array unset state
   set state(socket) $socket
   set state(host) $host
   set state(port) $port
   puts stderr "New Connection: $socket $host $port [clock format [clock seconds]]"
   fconfigure $socket -buffering line -blocking 0
   fileevent $socket readable [namespace code [list Handler $socket]]
   puts $socket "Welcome to this little demo server!"
   puts $socket "Type \"help\" to see what you can do here."
}

# This gets called whenever a client sends a new line
# of data or disconnects
proc slaveServer::Handler {socket} {
   variable $socket
   upvar 0 $socket state

   # Do we have a disconnect?
   if {[eof $socket]} {
       closeSocket $socket
       return
   }

   # Does reading the socket give us an error?
   if {[catch {gets $socket line} ret] == -1} {
       puts stderr "Closing $socket"
       closeSocket $socket
       return
   }
   # Did we really get a whole line?
   if {$ret == -1} return

   # ... and is it not empty? ...
   set line [string trim $line]
   if {$line == ""} return

   ## ... and not an SSL request? ...
   #if {[string index $line 0] == "\200"} {
   #    puts stderr "SSL request - closing connection"
   #    closeSocket $socket
   #    return
   #}

   # OK, so log it ...
   puts stderr "$socket > $line"

   # ... evaluate it, ...
   if {[catch {slave eval $line} ret]} {
       set ret "ERROR: $ret"
   }
   # ... log the result ...
   puts stderr [regsub -all -line ^ $ret "$socket < "]

   # ... and send it back to the client.
   if {[catch {puts $socket $ret}]} {
       closeSocket $socket
   }
   
 # dpefour
 closeSocket $socket
}

proc slaveServer::init {ports commands} {
   variable serversockets
   # (re-)create a safe slave interpreter
   catch {interp delete slave}
   interp create -safe slave
   # remove all predefined commands from the slave
   foreach command [slave eval info commands] {
       slave hide $command
   }
   # link the commands for the protocol into the slave
   puts -nonewline stderr "Initializing commands:"
   foreach command $commands {
       puts -nonewline stderr " $command"
       interp alias slave $command {} $command
   }
   puts stderr ""
   #(re-)create the server socket
   if {[info exists serversockets]} {
       foreach sock $serversockets {
           catch {close $sock}
       }
       unset serversockets
   }
   puts -nonewline stderr "Opening sockets:"
   foreach {port} $ports {
       foreach {port socketCmd} $port {}
       if {$socketCmd == {}} { set socketCmd ::socket }
       puts -nonewline stderr " $port ($socketCmd)"
       lappend serversockets \
           [$socketCmd -server [namespace code Server] $port]
   }
   puts stderr ""
}

slaveServer::init $ports $commands
if {![info exists forever]} {
   set forever 1
   vwait forever
}


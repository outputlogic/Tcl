##-----------------------------------------------------------------------
## lshift unlshift
##-----------------------------------------------------------------------
## Stack functions
##-----------------------------------------------------------------------
proc ::tclapp::tclstore::lshift { inputlist } {
  upvar $inputlist argv
  set arg  [lindex $argv 0]
  set argv [lrange $argv 1 end]
  return $arg
}

proc ::tclapp::tclstore::unlshift { ls data } {
   upvar 1 $ls LIST
   set LIST [concat $data $LIST]
}

#------------------------------------------------------------------------
# print
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Print message to stdout and/or log file.
# Example:
#      print stdout "..."
#      print error "..."
#      print log "..."
#------------------------------------------------------------------------
proc ::tclapp::tclstore::print { type message {nonewline ""} } {
  variable params
  variable verbose
  variable debug
  set callerName [lindex [info level [expr [info level] -1]] 0]
  set type [string tolower $type]
  set msg ""
  switch -exact $type {
    "stdout" {
      set msg $message
    }
    "fatal" {
      set msg "  FATAL ERROR: $message"
    }
    "error" {
#       set msg "  ERROR: $message"
      set msg " -E- $message"
    }
    "warning" {
#       set msg "  WARNING: $message"
      set msg " -W- $message"
    }
    "info" {
#       set msg "  INFO: $message"
      set msg " -I- $message"
    }
    "log" {
      print_log "$message" $nonewline
      return 0
    }
    "debug" {
      if {$debug} {
#         set msg "  DEBUG::${callerName}: $message"
        set msg " -D- \[${callerName}\] $message"
      } else {
        return 0
      }
    }
    default {}
  }
  #-------------------------------------------------------
  # Print message.
  #-------------------------------------------------------
  if {$nonewline != ""} {
    puts -nonewline stdout $msg
  } else {
    puts stdout $msg
  }
  flush stdout
  #-------------------------------------------------------
  # Save (commented-out) message to log file.
  #-------------------------------------------------------
#   set msg "# ${msg}"
#   print_log $msg $nonewline
  foreach line [split $msg \n] {
    print_log "# ${line}" $nonewline
  }
  return 0
}

#------------------------------------------------------------------------
# print_log
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Proc used internally to save message to log file.
#------------------------------------------------------------------------
proc ::tclapp::tclstore::print_log { msg {nonewline ""} } {
  variable params
  variable verbose
  variable debug
  #-------------------------------------------------------
  # Save message to log file.
  #-------------------------------------------------------
  if {$params(log.fh) != {}} {
    set FH $params(log.fh)
    if {$nonewline != ""} {
      puts -nonewline $FH "$msg"
    } else {
      puts $FH "$msg"
    }
    flush $FH
  }
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::getAppBaseName
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Get base name of an app. The base name has the format <COMPANY>::<APP>
#------------------------------------------------------------------------
proc ::tclapp::tclstore::getAppBaseName {app} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Remove ::tclapp from app name
  regsub {^(::)?tclapp::} $app {} app
  regsub {^(::)?tclapp} $app {} app
  regsub {^::} $app {} app
  return $app
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::indentString
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Indent message with optional indent string
#------------------------------------------------------------------------
proc ::tclapp::tclstore::indentString {msg {indent {}}} {
  set res [list]
  foreach line [split $msg \n] {
    lappend res [format {%s%s} $indent $line]
  }
  return [join $res \n]
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::runVivadoCmd
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Execute a Vivado command
#------------------------------------------------------------------------
proc ::tclapp::tclstore::runVivadoCmd {commands} {
  global tcl_platform
  variable params
  print info "repository: $params(repository)"
  switch $tcl_platform(platform) {
    unix {
      return [runVivadoCmdUnix $commands]
    }
    windows {
      return [runVivadoCmdWindows $commands]
    }
    default {
    }
  }
}

proc ::tclapp::tclstore::runVivadoCmdUnix {commands} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable params
  variable verbose
  variable debug
  set dir [uplevel #0 pwd]
  if {$debug} {
    print debug "Vivado script:"
    print debug [indentString $commands [string repeat { } 5]]
  }
  set shellscript [file normalize [file join $dir vivado[uplevel #0 pid].sh]]
  set runscript [file normalize [file join $dir vivado[uplevel #0 pid].tcl]]
  set vivadolog [file normalize [file join $dir vivado[uplevel #0 pid].log]]
  set vivadojou [file normalize [file join $dir vivado[uplevel #0 pid].jou]]
  set FH [open $shellscript {w}]
  puts $FH [format {#!/bin/bash
export XILINX_TCLAPP_REPO="%s"
export XILINX_LOCAL_USER_DATA="NO"
%s -mode tcl -notrace -source "%s" -log "%s" -journal "%s"
} $params(repository) $params(vivadobin) $runscript $vivadolog $vivadojou]
  close $FH
  uplevel #0 exec chmod +x $shellscript
  set FH [open $runscript {w}]
  puts $FH "puts -nonewline {<<SCRIPT>>}"
  puts $FH "if \{\[catch \{"
  foreach cmd $commands {
    puts $FH "  $cmd"
  }
  puts $FH "\} errorstring\]\} \{"
  puts $FH "  puts -nonewline \{<<VIVADOERROR>>\}"
  puts $FH "  puts -nonewline \$errorstring"
  puts $FH "  puts -nonewline \{<</VIVADOERROR>>\}"
  puts $FH "\} else \{"
  puts $FH "\}"
  puts $FH "puts -nonewline {<</SCRIPT>>}"
  puts $FH "exit"
  close $FH
  print info "running Vivado ... please wait"
#   foreach [list exitCode message] [eval [concat system $params(vivadobin) -mode tcl -source $runscript]] { break }
  foreach [list exitCode message] [eval [concat system $shellscript]] { break }
  if {$debug} {
    print debug "exitCode: $exitCode"
    print debug "message: [join $message { }]"
  }
  if {$exitCode != 0} {
    print error "Vivado command failed"
    error "$message"
  }
#   if {[lsearch -inline -all -not -exact $message {<<ERROR>>}]} {}
  if {[regexp {<<VIVADOERROR>>} $message]} {
    print warning "An error was detected inside Vivado log file [file normalize $vivadolog]"
    set exitCode 1
  }
  regsub {^.*<<SCRIPT>>} $message {} message
  regsub {<</SCRIPT>>.*$} $message {} message
  if {!$debug} {
    # Keep the files in debug mode
    file delete $shellscript
    file delete $runscript
    file delete $vivadolog
    file delete $vivadojou
  }
  return [list $exitCode $message]
}

proc ::tclapp::tclstore::runVivadoCmdWindows {commands} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable params
  variable verbose
  variable debug
  set dir [uplevel #0 pwd]
  if {$debug} {
    print debug "Vivado script:"
    print debug [indentString $commands [string repeat { } 5]]
  }
  set shellscript [file normalize [file join $dir vivado[uplevel #0 pid].bat]]
  set runscript [file normalize [file join $dir vivado[uplevel #0 pid].tcl]]
  set vivadolog [file normalize [file join $dir vivado[uplevel #0 pid].log]]
  set vivadojou [file normalize [file join $dir vivado[uplevel #0 pid].jou]]
  set FH [open $shellscript {w}]
  puts $FH [format {@echo off
set XILINX_TCLAPP_REPO=%s
set XILINX_LOCAL_USER_DATA=NO
call %s -mode tcl -notrace -source "%s" -log "%s" -journal "%s"
} $params(repository) $params(vivadobin) $runscript $vivadolog $vivadojou]
  close $FH
#   uplevel #0 exec chmod +x $shellscript
  set FH [open $runscript {w}]
  puts $FH "puts -nonewline {<<SCRIPT>>}"
  puts $FH "if \{\[catch \{"
  foreach cmd $commands {
    puts $FH "  $cmd"
  }
  puts $FH "\} errorstring\]\} \{"
  puts $FH "  puts -nonewline \{<<VIVADOERROR>>\}"
  puts $FH "  puts -nonewline \$errorstring"
  puts $FH "  puts -nonewline \{<</VIVADOERROR>>\}"
  puts $FH "\} else \{"
  puts $FH "\}"
  puts $FH "puts -nonewline {<</SCRIPT>>}"
  puts $FH "exit"
  close $FH
  print info "running Vivado ... please wait"
#   foreach [list exitCode message] [eval [concat system $params(vivadobin) -mode tcl -source $runscript]] { break }
  foreach [list exitCode message] [eval [concat system $shellscript]] { break }
  if {$debug} {
    print debug "exitCode: $exitCode"
    print debug "message: [join $message { }]"
  }
  if {$exitCode != 0} {
    print error "Vivado command failed"
    error "$message"
  }
#   if {[lsearch -inline -all -not -exact $message {<<ERROR>>}]} {}
  if {[regexp {<<VIVADOERROR>>} $message]} {
    print warning "An error was detected inside Vivado log file [file normalize $vivadolog]"
    set exitCode 1
  }
  regsub {^.*<<SCRIPT>>} $message {} message
  regsub {<</SCRIPT>>.*$} $message {} message
  if {!$debug} {
    # Keep the files in debug mode
    file delete $shellscript
    file delete $runscript
    file delete $vivadolog
    file delete $vivadojou
  }
  return [list $exitCode $message]
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::runGitCmd
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Execute a Git command
#------------------------------------------------------------------------
proc ::tclapp::tclstore::runGitCmd {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable params
  variable verbose
  variable debug
  set dir [uplevel #0 pwd]
  if {$debug} {
    print debug "Git command: $args"
  }
#   foreach [list exitCode message] [ system ssh git-dev [format {cd %s ; %s %s} $dir $params(git) $args] ] { break }
#   foreach [list exitCode message] [ system [format {%s %s} $gitBin $args] ] { break }
  foreach [list exitCode message] [eval [concat system $params(gitbin) $args ]] { break }
  if {$debug} {
    print debug "exitCode: $exitCode"
    print debug "message: [join $message { }]"
  }
  if {$exitCode != 0} {
    print error "Git command failed"
    error "$message"
  }
  return [list $exitCode $message]
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::runCurlCmd
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Execute a Curl command
#------------------------------------------------------------------------
proc ::tclapp::tclstore::runCurlCmd {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable params
  variable verbose
  variable debug
  if {$debug} {
    print debug "Curl command: $args"
  }
  if {$params(proxy.https) != {}} {
    foreach [list exitCode message] [eval [concat system $params(curlbin) -L --insecure -x $params(proxy.https) $args ]] { break }
#     foreach [list exitCode message] [eval [concat system $params(curlbin) -x $params(proxy.https) $args ]] { break }
#     foreach [list exitCode message] [eval [concat system $params(vivadobin) -exec xilcurl -x $params(proxy.https) $args ]] { break }
  } elseif {$params(proxy.http) != {}} {
    foreach [list exitCode message] [eval [concat system $params(curlbin) -L --insecure -x $params(proxy.http) $args ]] { break }
#     foreach [list exitCode message] [eval [concat system $params(curlbin) -x $params(proxy.http) $args ]] { break }
#     foreach [list exitCode message] [eval [concat system $params(vivadobin) -exec xilcurl -x $params(proxy.http) $args ]] { break }
  } else {
    foreach [list exitCode message] [eval [concat system $params(curlbin) -L --insecure $args ]] { break }
#     foreach [list exitCode message] [eval [concat system $params(curlbin) $args ]] { break }
#     foreach [list exitCode message] [eval [concat system $params(vivadobin) -exec xilcurl $args ]] { break }
  }
  if {$debug} {
    print debug "exitCode: $exitCode"
    print debug "message: [join $message { }]"
  }
  if {$exitCode != 0} {
    print error "Curl command failed"
    error "$message"
  }
  return [list $exitCode $message]
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::system
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Execute a process under UNIX.
# Return a TCL list. The first element of the list is the exit code
# for the process. The second element of the list is the message
# returned by the process.
# The exit code is 0 if the process executed successfully.
# The exit code is 1, 2, 3, or 4 otherwise.
# Example:
#      foreach [list exitCode message] [::tclapp::tclstore::system ls -lrt] { break }
#------------------------------------------------------------------------
proc ::tclapp::tclstore::system { args } {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable verbose
  variable debug

  #-------------------------------------------------------
  # Save the command being executed inside the log file.
  #-------------------------------------------------------
  if {$debug} { print debug "Unix call: $args" }

  #-------------------------------------------------------
  # Execute the command inside the global namespace (level #0).
  #-------------------------------------------------------
  catch {set result [eval [list uplevel #0 exec $args]] } returnstring

  #-------------------------------------------------------
  # Check the status of the process.
  #-------------------------------------------------------
  if { [string equal $::errorCode NONE] } {

    # The command exited with a normal status, but wrote something
    # to stderr, which is included in $returnstring.
    set exitCode 0

    if {$debug} { print debug "::errorCode = NONE" }

  } else {

    switch -exact -- [lindex $::errorCode 0] {

      CHILDKILLED {

        foreach { - pid sigName msg } $::errorCode { break }

        # A child process, whose process ID was $pid,
        # died on a signal named $sigName.  A human-
        # readable message appears in $msg.
        set exitCode 2

        if {$debug} {
          print debug "::errorCode = CHILDKILLED"
          print debug "Child process $pid died from signal named $sigName"
          print debug "Message: $msg"
        }

      }

      CHILDSTATUS {

        foreach { - pid code } $::errorCode { break }

        # A child process, whose process ID was $pid,
        # exited with a non-zero exit status, $code.
        set exitCode 1

        if {$debug} {
          print debug "::errorCode = CHILDSTATUS"
          print debug "Child process $pid exited with status $code"
        }

      }

      CHILDSUSP {

        foreach { - pid sigName msg } $::errorCode { break }

        # A child process, whose process ID was $pid,
        # has been suspended because of a signal named
        # $sigName.  A human-readable description of the
        # signal appears in $msg.
        set exitCode 3

        if {$debug} {
          print debug "::errorCode = CHILDSUSP"
          print debug "Child process $pid suspended because signal named $sigName"
          print debug "Message: $msg"
        }

      }

      POSIX {

        foreach { - errName msg } $::errorCode { break }

        # One of the kernel calls to launch the command
        # failed.  The error code is in $errName, and a
        # human-readable message is in $msg.
        set exitCode 4

        if {$debug} {
          print debug "::errorCode = POSIX"
          print debug "One of the kernel calls to launch the command failed. The error code is $errName"
          print debug "Message: $msg"
        }

      }

    }

  }

  if {$debug} {
    print debug "returnstring=[join [split $returnstring \n] {\\}]"
    print debug "exitCode=$exitCode"
  }

  return [list $exitCode $returnstring]
}

##-----------------------------------------------------------------------
## backup_file
##-----------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
## Backup a file by renaming the file to <filename>.<index>.extension .
## the function search for the first available <index> number.
## Example:
##      backup_file run.log
##              => existing run.log backed up as run.1.log
##-----------------------------------------------------------------------

proc ::tclapp::tclstore::backup_file { filename } {

  if {![file exists $filename]} {
    print warning "file $filename does not exist"
    return 0
  }

  set rootname [file rootname $filename]
  set extension [file extension $filename]

  set index 1

  while {1} {
    if {![file exists ${rootname}.${index}${extension}]} {
      break
    }
    incr index
  }

#   set exitCode [file copy -force -- $filename ${rootname}.${index}${extension}]
  set exitCode [file rename -force -- $filename ${rootname}.${index}${extension}]

  return $exitCode
}

##-----------------------------------------------------------------------
## read_file_regexp
##-----------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
## Returns all lines that match occurrence of a regular expression in the
## file
##-----------------------------------------------------------------------
proc ::tclapp::tclstore::read_file_regexp {filename rexp} {
  set lines [list]
  set FH {}
  if {[catch {set FH [open $filename r]} errorstring]} {
      error " error - $errorstring"
  }
  while {![eof $FH]} {
    gets $FH line
    if {[regexp $rexp $line]} { lappend lines $line }
  }
  close $FH
  return $lines
}

##-----------------------------------------------------------------------
## initialize
##-----------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
## Initialize some of the internal parameters based on the user's
## environment
##-----------------------------------------------------------------------
proc ::tclapp::tclstore::initialize { {type {vivado|git|curl}} } {
  global tcl_platform
  variable params
  switch $tcl_platform(platform) {
    unix {
      initializeUnix $type
    }
    windows {
      initializeWindows $type
    }
    default {
    }
  }
  return -code ok
}

proc ::tclapp::tclstore::initializeWindows { {type {vivado|git|curl}} } {
  variable params
  variable debug
  variable verbose
  set error 0
  if {[regexp $type vivado]} {
    if {$params(vivadobin) == {}} {
      print error "path to Vivado must be specified with --vivadobin=<PATH_TO_VIVADO.BAT>"
      incr error
    } else {
      # Example path: C:/Xilinx/Vivado/2014.2/bin/vivado.bat
      # Extract the directory and file name to build the where.exe command
      set dir [file dirname $params(vivadobin)]
      set file [file tail $params(vivadobin)]
      if {[catch {set result [exec where.exe ${dir}:${file}]} errorstring]} {
        print error "cannot access '$params(vivadobin)'"
        incr error
      } else {
        # To avoid issues, replace all '\' by '/'
        set params(vivadobin) [regsub -all {\\} $result {/}]
        print info "vivado: $params(vivadobin)"
        if {[catch {set result [exec $params(vivadobin) -version]} errorstring]} {
          print error "cannot execute '$params(vivadobin)': $errorstring"
          incr error
        } else {
          foreach line [split $result \n] {
            if {[regexp {^Vivado\s+v?([0-9\.]+)\s} $line - params(vivadoversion)]} { break }
          }
          # Set the default catalog version to the current Vivado version: <MAJOR>.<MINOR>
          set params(vivadoversion) [join [lrange [split $params(vivadoversion) {.}] 0 1] {.}]
          print info "Vivado version: $params(vivadoversion)"
          # Due to API changes, let's restrict to 2014.3 and upward
          if {[package vcompare $params(vivadoversion) 2014.3] < 0} {
            print error "need Vivado 2014.3 and upward"
            incr error
          }
        }
      }
    }
  }

  if {[regexp $type git]} {
    if {$params(vivadobin) == {}} {
      print error "Vivado path must be configured first"
      incr error
    } else {
      set params(gitbin) [glob [file join {*}[lrange [file split [file dirname $params(vivadobin)]] 0 end-1] tps win64 git-* bin git.exe]]
      print info "git: $params(gitbin)"
      if {[catch {set result [exec $params(gitbin) --version]} errorstring]} {
        print error "cannot access '$params(gitbin)' in your search path"
        incr error
      } else {
        if {[regexp {^git version\s+([0-9\.]+)(\s|(\.msysgit)|$)} $result - params(gitversion)]} {}
        print info "git version: $params(gitversion)"
      }
    }
  }

  if {[regexp $type curl]} {
    if {$params(vivadobin) == {}} {
      print error "Vivado path must be configured first"
      incr error
    } else {
      # --insecure : to prevent errors from https
      set params(curlbin) "$params(vivadobin) -exec xilcurl --insecure"
      print info "curl: $params(curlbin)"
    }
  }

  if {$error} {
    error "\n Some error(s) occured. Cannot continue.\n"
#     exit -1
  }

  set params(initialized) 1
  return -code ok
}

proc ::tclapp::tclstore::initializeUnix { {type {vivado|git|curl}} } {
  variable params
  variable debug
  variable verbose
  set error 0
  if {[regexp $type vivado]} {
    if {[catch {set result [exec which $params(vivadobin)]} errorstring]} {
      print error "cannot access '$params(vivadobin)' in your search path"
      incr error
    } else {
      set params(vivadobin) $result
      print info "vivado: $params(vivadobin)"
      if {[catch {set result [exec $params(vivadobin) -version]} errorstring]} {
        print error "cannot execute '$params(vivadobin)': $errorstring"
        incr error
      } else {
        foreach line [split $result \n] {
          if {[regexp {^Vivado\s+v?([0-9\.]+)\s} $line - params(vivadoversion)]} { break }
        }
        # Set the default catalog version to the current Vivado version: <MAJOR>.<MINOR>
        set params(vivadoversion) [join [lrange [split $params(vivadoversion) {.}] 0 1] {.}]
        print info "Vivado version: $params(vivadoversion)"
        # Due to API changes, let's restrict to 2014.3 and upward
        if {[package vcompare $params(vivadoversion) 2014.3] < 0} {
          print error "need Vivado 2014.3 and upward"
          incr error
        }
      }
    }
  }

  if {[regexp $type git]} {
#     if {[catch {set result [exec which git]} errorstring]} {}
    if {[catch {set result [exec which $params(gitbin)]} errorstring]} {
      print error "cannot access '$params(gitbin)' in your search path"
      incr error
    } else {
      set params(gitbin) $result
      print info "git: $params(gitbin)"
      if {[catch {set result [exec $params(gitbin) --version]} errorstring]} {
        print error "cannot access '$params(gitbin)' in your search path"
        incr error
      } else {
        if {[regexp {^git version\s+([0-9\.]+)(\s|$)} $result - params(gitversion)]} {}
        print info "git version: $params(gitversion)"
      }
    }
  }

  if {[regexp $type curl]} {
    if {[catch {set result [exec which $params(curlbin)]} errorstring]} {
      print error "cannot access '$params(curlbin)' in your search path"
      incr error
    } else {
      set params(curlbin) $result
      print info "curl: $params(curlbin)"
    }
  }

  if {$error} {
    error "\n Some error(s) occured. Cannot continue.\n"
#     exit -1
  }

  set params(initialized) 1
  return -code ok
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::docstring
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Return the embedded help of a proc
#------------------------------------------------------------------------
proc ::tclapp::tclstore::docstring {procname} {
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
# ::tclapp::tclstore::do
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Dispatcher with methods
#------------------------------------------------------------------------
proc ::tclapp::tclstore::do {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  if {[llength $args] == 0} {
#     error " -E- wrong number of parameters: tclstore <sub-command> \[<arguments>\]"
    set method {?}
  } else {
    # The first argument is the method
    set method [lshift args]
  }
  if {[info proc ::tclapp::tclstore::method:${method}] == "::tclapp::tclstore::method:${method}"} {
    eval ::tclapp::tclstore::method:${method} $args
  } else {
    # Search for a unique matching method among all the available methods
    set match [list]
    foreach procname [info proc ::tclapp::tclstore::method:*] {
      if {[string first $method [regsub {::tclapp::tclstore::method:} $procname {}]] == 0} {
        lappend match [regsub {::tclapp::tclstore::method:} $procname {}]
      }
    }
    switch [llength $match] {
      0 {
        error " -E- unknown sub-command $method"
      }
      1 {
        set method $match
        return [eval ::tclapp::tclstore::method:${method} $args]
      }
      default {
        error " -E- multiple sub-commands match '$method': $match"
      }
    }
  }
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::method:?
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Usage: tclstore ?
#------------------------------------------------------------------------
# Return all the available methods. The methods with no embedded help
# are not displayed (i.e hidden)
#------------------------------------------------------------------------
proc ::tclapp::tclstore::method:? {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Long help message
  variable params
  print stdout "   Usage: tclstore <sub-command> \[<arguments>\]"
  print stdout "   Where <sub-command> is:"
  foreach procname [lsort [info proc ::tclapp::tclstore::method:*]] {
    regsub {::tclapp::tclstore::method:} $procname {} method
    if {$method == {?}} { set method {-h|?} }
    set help [::tclapp::tclstore::docstring $procname]
    if {$help ne ""} {
      if {[lsearch -exact [list update_repo ] $method] != -1} {
        if {$params(flow) == {gatekeeper}} {
#           print stdout "         [format {%-15s%s- %s} $method \t $help]"
#           print stdout "     (*) [format {%-15s%s- %s} $method \t $help]"
          print stdout "         [format {%-15s%s- %s} $method \t $help] (*)"
        } else {
#           print stdout "         [format {%-15s%s- %s} $method \t $help]"
        }
      } else {
        if {$params(flow) == {gatekeeper}} {
          print stdout "         [format {%-15s%s- %s} $method \t $help]"
        } else {
          print stdout "         [format {%-15s%s- %s} $method \t $help]"
        }
      }

    }
  }
  print stdout ""
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::tclstore
#------------------------------------------------------------------------
# Main function when calling the script from the command line
#------------------------------------------------------------------------
proc ::tclapp::tclstore::tclstore { args } {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable params
  variable SCRIPT_VERSION
  #-------------------------------------------------------
  # Pre-process command line arguments
  #-------------------------------------------------------
  set originalCmdLine $args
  set cmdLine [list]
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-G$} -
      {^--G$} -
      {^-gatekeeper$} -
      {^--gatekeeper$} {
        set params(flow) {gatekeeper}
      }
      {^-vivado$} -
      {^--vivado$} {
        set params(vivadobin) [lshift args]
      }
      {^-vivadobin$} -
      {^--vivadobin$} {
        set params(vivadobin) [lshift args]
      }
      {^-gitbin$} -
      {^--gitbin$} {
        set params(gitbin) [lshift args]
      }
      {^-curlbin$} -
      {^--curlbin$} {
        set params(curlbin) [lshift args]
      }
      {^-proxy-http$} -
      {^--proxy-http$} {
        set params(proxy.http) [lshift args]
      }
      {^-proxy-https$} -
      {^--proxy-https$} {
        set params(proxy.https) [lshift args]
      }
      {^-vivado=(.*)$} -
      {^--vivado=(.*)$} {
        regexp {^-?-vivado=(.*)$} $name - params(vivadobin)
      }
      {^-vivadobin=(.*)$} -
      {^--vivadobin=(.*)$} {
        regexp {^-?-vivadobin=(.*)$} $name - params(vivadobin)
      }
      {^-gitbin=(.*)$} -
      {^--gitbin=(.*)$} {
        regexp {^-?-gitbin=(.*)$} $name - params(gitbin)
      }
      {^-curlbin=(.*)$} -
      {^--curlbin=(.*)$} {
        regexp {^-?-curlbin=(.*)$} $name - params(curlbin)
      }
      {^-proxy-http=(.*)$} -
      {^--proxy-http=(.*)$} {
        regexp {^-?-proxy-http=(.*)$} $name - params(proxy.http)
      }
      {^-proxy-https=(.*)$} -
      {^--proxy-https=(.*)$} {
        regexp {^-?-proxy-https=(.*)$} $name - params(proxy.https)
      }
      default {
        lappend cmdLine $name
      }
    }
  }
  set args $cmdLine
  #-------------------------------------------------------
  # Open log file only when no help is requested
  #-------------------------------------------------------
  if {([lsearch -exact $cmdLine {-h}] == -1) &&
      ([lsearch -exact $cmdLine {-help}] == -1) &&
      ([lsearch -exact $cmdLine {--h}] == -1) &&
      ([lsearch -exact $cmdLine {--help}] == -1) } {
      if {$params(log.filename) != {}} {
        if {[file exists $params(log.filename)]} {
          if {$params(log.mode) == {w}} {
            backup_file $params(log.filename)
          }
        }
        if {[catch {set FH [open $params(log.filename) $params(log.mode)]} errorstring]} {
          puts " -W- cannot open log file '[file normalize $params(log.filename)]': $errorstring"
        } else {
          set params(log.fh) $FH
          puts $FH "\n" 
          puts $FH "###############################################################" 
          puts $FH "###############################################################" 
          puts $FH "##" 
          puts $FH "##  Log file created on [exec date]" 
          puts $FH "##" 
          puts $FH "###############################################################" 
          puts $FH "###############################################################\n" 
          print info "Start logging messages to '[file normalize $params(log.filename)]' on [exec date].\n"
          # Log the command being executed
          print log "\ntclstore $originalCmdLine\n"
        }
      }
    }
  #-------------------------------------------------------
  # Process command line arguments
  #-------------------------------------------------------
  set error 0
  set show_help 0
  set method [lshift args]
  switch -exact -- $method {
    ? -
    -h -
    -help {
      incr show_help
    }
    --h -
    --help {
      set params(flow) {gatekeeper}
      incr show_help
    }
    -I -
    -shell -
    -shell {
        ::tclapp::tclstore::shell
    }
    default {
      return [eval [concat ::tclapp::tclstore::do ${method} $args] ]
    }
  }

  if {$show_help} {
    # <-- HELP
    print stdout ""
    ::tclapp::tclstore::method:?
    print stdout [format {
   Description: Utility to package apps for the Xilinx Tcl Store (%s)

   Windows Support:
   ----------------
     For Windows, the path to vivado.bat must be specified with --vivado=C:\Xilinx\Vivado\2014.3\bin\vivado.bat
                                                                ^^      ^

   Example: Contributor Flow
      # Make sure that 'vivado' is available from the command line, along with 'git' and 'curl'
      tclstore clone_repo -dir ./temp -user frank
      # Modify the files under the app area
      tclstore package_app -repo ./temp/XilinxTclStore -app xilinx::designutils -revision "Fixed issue with ..."
      # Verify all the files. Only commit files to git that are under the app directory

   Example: Contributor Flow (Windows)
      # Specify path to vivado.bat with --vivado
      tclstore clone_repo --vivado=C:\Xilinx\Vivado\2014.3\bin\vivado.bat -dir ./temp -user frank
      # Modify the files under the app area
      tclstore package_app --vivado=C:\Xilinx\Vivado\2014.3\bin\vivado.bat -repo ./temp/XilinxTclStore -app xilinx::designutils -revision "Fixed issue with ..."
      # Verify all the files. Only commit files to git that are under the app directory


    } $SCRIPT_VERSION ]

    if {$params(flow) == {gatekeeper}} {
#       print stdout [format {
#    Example:
#       }]
    }

    # HELP -->
    return -code ok
  }

}

##-----------------------------------------------------------------------
## shell
##-----------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
## Interactive TCL shell.
##-----------------------------------------------------------------------
proc ::tclapp::tclstore::shell {} {

  # Interactive shell
  set prompt {tclstore% }
  set command {}
  #-------------------------------------------------------
  # The following message is not saved in the log file.
  #-------------------------------------------------------
  puts "\n  Interactive tclstore shell. Type '?' for help.\n"
  while 1 {
    puts -nonewline ${prompt}
    flush stdout
    gets stdin cmd
    append command $cmd
    #-------------------------------------------------------
    # Check that the command is complete before executing it.
    #-------------------------------------------------------
    if {[info complete $command]} {
      if {[regexp {^\s*(exit|quit)\s*$} $command]} {
        break
      }
      if {[regexp {^\s*\?\s*$} $command]} {

        puts [format {
                     +-- tclstore --+
      tclstore clone_repo             clone the Xilinx Tcl Store repository (-h)
      tclstore package_app            package an app (-h)
}]
        ::tclapp::tclstore::tclstore -help
        set command {}
        continue
      }
      #-------------------------------------------------------
      # Command executed at level #0.
      #-------------------------------------------------------
      catch {uplevel #0 $command} res
      if {$res != {}} {
        puts $res
      }
      set command {}
    }
  }
  return -code ok
}

##-----------------------------------------------------------------------
## ask
##-----------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
## Interactive question to the user.
##-----------------------------------------------------------------------

proc ::tclapp::tclstore::ask {summary question prompt {answers {}}} {

  set command {}
  puts ""
  foreach line [split $summary \n] {
    puts "## $line"
  }
  puts ""
  set ans {}
  while 1 {
    puts $question
    puts -nonewline ${prompt}
    flush stdout
    gets stdin ans
    if {$answers == {}} {
      break
    } elseif {[regexp $answers $ans]} {
      break
    } else {
      puts " invalid answer!"
    }
  }
  return $ans
}

##-----------------------------------------------------------------------
## FAILED
##-----------------------------------------------------------------------
## Message.
##-----------------------------------------------------------------------

proc ::tclapp::tclstore::FAILED {} {
  return [format {
  ########    ###    #### ##       ######## ########
  ##         ## ##    ##  ##       ##       ##     ##
  ##        ##   ##   ##  ##       ##       ##     ##
  ######   ##     ##  ##  ##       ######   ##     ##
  ##       #########  ##  ##       ##       ##     ##
  ##       ##     ##  ##  ##       ##       ##     ##
  ##       ##     ## #### ######## ######## ########
}]
}

##-----------------------------------------------------------------------
## OK
##-----------------------------------------------------------------------
## Message.
##-----------------------------------------------------------------------

proc ::tclapp::tclstore::OK {} {
  return [format {
   #######  ##    ##
  ##     ## ##   ##
  ##     ## ##  ##
  ##     ## #####
  ##     ## ##  ##
  ##     ## ##   ##
   #######  ##    ##
}]
}

##-----------------------------------------------------------------------
## ERROR
##-----------------------------------------------------------------------
## Message.
##-----------------------------------------------------------------------

proc ::tclapp::tclstore::ERROR {} {
  return [format {
  ######## ########  ########   #######  ########
  ##       ##     ## ##     ## ##     ## ##     ##
  ##       ##     ## ##     ## ##     ## ##     ##
  ######   ########  ########  ##     ## ########
  ##       ##   ##   ##   ##   ##     ## ##   ##
  ##       ##    ##  ##    ##  ##     ## ##    ##
  ######## ##     ## ##     ##  #######  ##     ##
}]
}

##-----------------------------------------------------------------------
## WARNING
##-----------------------------------------------------------------------
## Message.
##-----------------------------------------------------------------------

proc ::tclapp::tclstore::WARNING {} {
  return [format {
  ##      ##    ###    ########  ##    ## #### ##    ##  ######
  ##  ##  ##   ## ##   ##     ## ###   ##  ##  ###   ## ##    ##
  ##  ##  ##  ##   ##  ##     ## ####  ##  ##  ####  ## ##
  ##  ##  ## ##     ## ########  ## ## ##  ##  ## ## ## ##   ####
  ##  ##  ## ######### ##   ##   ##  ####  ##  ##  #### ##    ##
  ##  ##  ## ##     ## ##    ##  ##   ###  ##  ##   ### ##    ##
   ###  ###  ##     ## ##     ## ##    ## #### ##    ##  ######
}]
}

##-----------------------------------------------------------------------
## INFO
##-----------------------------------------------------------------------
## Message.
##-----------------------------------------------------------------------

proc ::tclapp::tclstore::INFO {} {
  return [format {
  #### ##    ## ########  #######
   ##  ###   ## ##       ##     ##
   ##  ####  ## ##       ##     ##
   ##  ## ## ## ######   ##     ##
   ##  ##  #### ##       ##     ##
   ##  ##   ### ##       ##     ##
  #### ##    ## ##        #######
}]
}


##-----------------------------------------------------------------------
## VERIFY
##-----------------------------------------------------------------------
## Message.
##-----------------------------------------------------------------------

proc ::tclapp::tclstore::VERIFY {} {
  return [format {
  ##     ## ######## ########  #### ######## ##    ##
  ##     ## ##       ##     ##  ##  ##        ##  ##
  ##     ## ##       ##     ##  ##  ##         ####
  ##     ## ######   ########   ##  ######      ##
   ##   ##  ##       ##   ##    ##  ##          ##
    ## ##   ##       ##    ##   ##  ##          ##
     ###    ######## ##     ## #### ##          ##
}]
}

##-----------------------------------------------------------------------
## CHECK
##-----------------------------------------------------------------------
## Message.
##-----------------------------------------------------------------------

proc ::tclapp::tclstore::CHECK {} {
  return [format {
   ######  ##     ## ########  ######  ##    ##
  ##    ## ##     ## ##       ##    ## ##   ##
  ##       ##     ## ##       ##       ##  ##
  ##       ######### ######   ##       #####
  ##       ##     ## ##       ##       ##  ##
  ##    ## ##     ## ##       ##    ## ##   ##
   ######  ##     ## ########  ######  ##    ##
}]
}

##-----------------------------------------------------------------------
## OKBUT
##-----------------------------------------------------------------------
## Message.
##-----------------------------------------------------------------------

proc ::tclapp::tclstore::OKBUT {} {
  return [format {
   #######  ##    ##                   ########  ##     ## ########
  ##     ## ##   ##                    ##     ## ##     ##    ##
  ##     ## ##  ##                     ##     ## ##     ##    ##
  ##     ## #####                      ########  ##     ##    ##
  ##     ## ##  ##                     ##     ## ##     ##    ##
  ##     ## ##   ##     ### ### ###    ##     ## ##     ##    ##
   #######  ##    ##    ### ### ###    ########   #######     ##
}]
}

##-----------------------------------------------------------------------
## INCOMPLETE
##-----------------------------------------------------------------------
## Message.
##-----------------------------------------------------------------------

proc ::tclapp::tclstore::INCOMPLETE {} {
  return [format {
  #### ##    ##  ######   #######  ##     ## ########  ##       ######## ######## ########
   ##  ###   ## ##    ## ##     ## ###   ### ##     ## ##       ##          ##    ##
   ##  ####  ## ##       ##     ## #### #### ##     ## ##       ##          ##    ##
   ##  ## ## ## ##       ##     ## ## ### ## ########  ##       ######      ##    ######
   ##  ##  #### ##       ##     ## ##     ## ##        ##       ##          ##    ##
   ##  ##   ### ##    ## ##     ## ##     ## ##        ##       ##          ##    ##
  #### ##    ##  ######   #######  ##     ## ##        ######## ########    ##    ########
}]
}

##-----------------------------------------------------------------------
## MISSING
##-----------------------------------------------------------------------
## Message.
##-----------------------------------------------------------------------

proc ::tclapp::tclstore::MISSING {} {
  return [format {
  ##     ## ####  ######   ######  #### ##    ##  ######
  ###   ###  ##  ##    ## ##    ##  ##  ###   ## ##    ##
  #### ####  ##  ##       ##        ##  ####  ## ##
  ## ### ##  ##   ######   ######   ##  ## ## ## ##   ####
  ##     ##  ##        ##       ##  ##  ##  #### ##    ##
  ##     ##  ##  ##    ## ##    ##  ##  ##   ### ##    ##
  ##     ## ####  ######   ######  #### ##    ##  ######
}]
}

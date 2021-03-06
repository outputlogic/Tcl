####################################################################################################
# HEADER_BEGIN
# COPYRIGHT NOTICE
# Copyright 2001-2016 Xilinx Inc. All Rights Reserved.
# http://www.xilinx.com/support
# HEADER_END
####################################################################################################

# proc [file tail [info script]] {} " source [info script]; puts \" [info script] reloaded\" "
# proc reload {} " source [info script]; puts \" [info script] reloaded\" "

########################################################################################
##
## Company:        Xilinx, Inc.
## Created by:     David Pefourque
##
## Version:        2016.04.19
## Description:    This package provides a simple interactive Tcl shell
##
########################################################################################

########################################################################################
## 2016.04.19 - Removed message when sourced by 'package require toolbox'
## 2016.04.05 - Added methods locals/printlocals
##            - Misc enhancements
## 2015.02.23 - Initial release
########################################################################################

namespace eval ::tb {
    namespace export ishell
}

proc ::tb::ishell { args } {
  # Summary : Interactive Tcl shell

  # Argument Usage:
  # args : sub-command.

  # Return Value:
  # returns the status or an error code

#   if {[catch {set res [uplevel [concat ::tb::ishell::ishell $args]]} errorstring]} {
#     error " -E- the interactive shell failed with the following error: $errorstring"
#   }
  return [uplevel [concat ::tb::ishell::ishell $args]]
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
eval [list namespace eval ::tb::ishell {
  variable version {2016.04.19}
  catch {unset params}
  # The commands need to be uplevel-ed 4 levels to be executed
  array set params [list level 4 prompt {ishell% } history {} verbose 0 debug 0 enable 1]
} ]

#------------------------------------------------------------------------
# ::tb::ishell::ishell
#------------------------------------------------------------------------
# Main function
#------------------------------------------------------------------------
proc ::tb::ishell::ishell { args } {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Check that Vivado is run in tcl mode
  if {![catch {package require Vivado}]} {
    if {$rdi::mode!="tcl"} {
      error " -E- ishell cannot run in GUI or batch mode"
    }
  }
  #-------------------------------------------------------
  # Process command line arguments
  #-------------------------------------------------------
  set error 0
  set show_help 0
  set method [lshift args]
  switch -exact -- $method {
    dump {
      return [eval [concat ::tb::ishell::dump] ]
    }
    ? -
    -h -
    -help {
      incr show_help
    }
    -I -
    -shell -
    -shell {
        ::tb::ishell::ishell
    }
    default {
      return [eval [concat ::tb::ishell::do ${method} $args] ]
    }
  }

  if {$show_help} {
    # <-- HELP
    puts ""
    ::tb::ishell::method:?
    puts [format {
   Description: Utility for interactive Tcl shell

   Example:
      ishell start

    } ]
    # HELP -->
    return
  }

}

#------------------------------------------------------------------------
# ::tb::ishell::lshift
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Stack function
#------------------------------------------------------------------------
proc ::tb::ishell::lshift {inputlist} {
  # Summary :
  # Argument Usage:
  # Return Value:

  upvar $inputlist argv
  set arg  [lindex $argv 0]
  set argv [lrange $argv 1 end]
  return $arg
}

#------------------------------------------------------------------------
# ::tb::ishell::docstring
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Return the embedded help of a proc
#------------------------------------------------------------------------
proc ::tb::ishell::docstring {procname} {
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
# ::tb::ishell::do
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Dispatcher with methods
#------------------------------------------------------------------------
proc ::tb::ishell::do {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  if {[llength $args] == 0} {
#     error " -E- wrong number of parameters: ishell <sub-command> \[<arguments>\]"
    set method {?}
  } else {
    # The first argument is the method
    set method [lshift args]
  }
  if {[info proc ::tb::ishell::method:${method}] == "::tb::ishell::method:${method}"} {
    eval ::tb::ishell::method:${method} $args
  } else {
    # Search for a unique matching method among all the available methods
    set match [list]
    foreach procname [info proc ::tb::ishell::method:*] {
      if {[string first $method [regsub {::tb::ishell::method:} $procname {}]] == 0} {
        lappend match [regsub {::tb::ishell::method:} $procname {}]
      }
    }
    switch [llength $match] {
      0 {
        error " -E- unknown sub-command $method"
      }
      1 {
        set method $match
        return [eval ::tb::ishell::method:${method} $args]
      }
      default {
        error " -E- multiple sub-commands match '$method': $match"
      }
    }
  }
}

#------------------------------------------------------------------------
# ::tb::ishell::method:?
#------------------------------------------------------------------------
# Usage: ishell ?
#------------------------------------------------------------------------
# Return all the available methods. The methods with no embedded help
# are not displayed (i.e hidden)
#------------------------------------------------------------------------
proc ::tb::ishell::method:? {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # This help message
  puts "   Usage: ishell <sub-command> \[<arguments>\]"
  puts "   Where <sub-command> is:"
  foreach procname [lsort [info proc ::tb::ishell::method:*]] {
    regsub {::tb::ishell::method:} $procname {} method
    set help [::tb::ishell::docstring $procname]
    if {$help ne ""} {
      puts "         [format {%-12s%s- %s} $method \t $help]"
    }
  }
  puts ""
}

#------------------------------------------------------------------------
# ::tb::ishell::dump
#------------------------------------------------------------------------
# Usage: ishell dump
#------------------------------------------------------------------------
# Dump shell status
#------------------------------------------------------------------------
proc ::tb::ishell::dump {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Dump non-array variables
  foreach var [lsort [info var ::tb::ishell::*]] {
    if {![info exists $var]} { continue }
    if {![array exists $var]} {
      puts "   $var: [subst $$var]"
    }
  }
  # Dump array variables
  foreach var [lsort [info var ::tb::ishell::*]] {
    if {![info exists $var]} { continue }
    if {[array exists $var]} {
      parray $var
    }
  }
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::ishell::method:version
#------------------------------------------------------------------------
# Usage: ishell version
#------------------------------------------------------------------------
# Return the version of the interactive shell
#------------------------------------------------------------------------
proc ::tb::ishell::method:version {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Version of the shell
  variable version
#   puts " -I- Interactive shell version $version"
  return -code ok "ishell version $version"
}

#------------------------------------------------------------------------
# ::tb::ishell::method:reset
#------------------------------------------------------------------------
# Usage: ishell reset
#------------------------------------------------------------------------
# Reset the interactive shell
#------------------------------------------------------------------------
proc ::tb::ishell::method:reset {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Reset the shell
  variable params
  # The commands need to be uplevel-ed 4 levels to be executed
  array set params [list level 4 prompt {ishell% } history {} verbose 0 debug 0 enable 1]
  if {$params(verbose)} { puts " -I- ishell reset" }
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::ishell::method:enable
#------------------------------------------------------------------------
# Usage: ishell enable
#------------------------------------------------------------------------
# Enable the interactive shell
#------------------------------------------------------------------------
proc ::tb::ishell::method:enable {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Enable the shell
  variable params
  set params(enable) 1
  if {$params(verbose)} { puts " -I- ishell enabled" }
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::ishell::method:disable
#------------------------------------------------------------------------
# Usage: ishell disable
#------------------------------------------------------------------------
# Disable the interactive shell
#------------------------------------------------------------------------
proc ::tb::ishell::method:disable {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Disable the shell
  variable params
  set params(enable) 0
  if {$params(verbose)} { puts " -I- ishell disabled" }
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::ishell::method:locals
#------------------------------------------------------------------------
# Usage: ishell locals
#------------------------------------------------------------------------
# Get the list of local variables (excluding arrays)
#------------------------------------------------------------------------
proc ::tb::ishell::method:locals {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Get list of local variables (no array)
  variable params
  set defaults [list -level 3 -verbose $params(verbose) -debug $params(debug)]
  array set options $defaults
  array set options $args
  if {$options(-debug)} { puts " -D- Level: [info level] (-level=$options(-level))" }
  set env [dict create]
  foreach name [lsort [uplevel $options(-level) { info locals }]] {
    upvar $options(-level) $name var
    catch { dict set env $name $var } ;# no arrays
    catch {
      if {$options(-debug)} {
        puts " -D- $name \t:=\t$var"
      }
    }
  }
  return $env
}

#------------------------------------------------------------------------
# ::tb::ishell::method:printlocals
#------------------------------------------------------------------------
# Usage: ishell printlocals
#------------------------------------------------------------------------
# Print the list of local variables (excluding arrays)
#------------------------------------------------------------------------
proc ::tb::ishell::method:printlocals {{tag {}}} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Print local variables (no array)
  variable params
  if {$params(debug)} { puts " -D- Level: [info level]" }
  set env [::tb::ishell::method:locals -level 4]
  foreach {name value} $env {
    if {$tag != {}} {
      puts " -I- (${tag}) var $name \t:=\t$value"
    } else {
      puts " -I- var $name \t:=\t$value"
    }
  }
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::ishell::shell
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Interactive Tcl shell
#------------------------------------------------------------------------
proc ::tb::ishell::shell {args} {

  variable params

  # Interactive shell
  set defaults [list -prompt $params(prompt) -level $params(level) -verbose $params(verbose) -debug $params(debug)]
  array set options $defaults
  array set options $args
  set command {}
  #-------------------------------------------------------
  # The following message is not saved in the log file.
  #-------------------------------------------------------
  if {$options(-verbose)} { puts "\n  Interactive Tcl shell. Type '?' for help.\n" }
  if {$options(-debug)} { puts " -I- Level: [info level]" }
  while 1 {
    puts -nonewline $options(-prompt)
    flush stdout
    gets stdin cmd
    append command $cmd
    #-------------------------------------------------------
    # Check that the command is complete before executing it.
    #-------------------------------------------------------
    if {[info complete $command]} {
      if {[regexp {^\s*(exit|quit|q)\s*$} $command]} {
        break
      }
      # <empty line>
      if {[regexp {^\s*$} $command]} {
        set command {}
        continue
      }
      # history
      if {[regexp {^\s*(history|h)\s*$} $command]} {
        set idx 0
        foreach cmd $params(history) {
          puts " [incr idx] $cmd"
        }
        set command {}
        continue
      }
      # !<num>
      if {[regexp {^\s*\!([0-9]+)\s*$} $command -- idx]} {
        if {$idx > [llength $params(history)]} {
          puts " -I- $idx: Event not found."
          set command {}
          continue
        } else {
          set command [lindex $params(history) [expr $idx -1]]
        }
      }
      # !!
      if {[regexp {^\s*\!\!\s*$} $command]} {
        set command [lindex $params(history) end]
      }
      if {[regexp {^\s*\?\s*$} $command]} {

        puts [format {
              +-- shell --+
      exit|quit             exit interactive shell
      history               commands history
      !!                    recall last command
      !<num>                recall command <num>
}]
        set command {}
        continue
      }
      #-------------------------------------------------------
      # Command executed at upper level.
      #-------------------------------------------------------
      if {[catch {uplevel $options(-level) $command} res]} {
        # Command errored out
      } else {
        # Command completed successfully
        lappend params(history) $command
      }
      if {$res != {}} {
        puts $res
      }
      set command {}
    }
  }
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::ishell::method:start
#------------------------------------------------------------------------
# Usage: ishell start [<options>]
#------------------------------------------------------------------------
# Start the interactive shell
#------------------------------------------------------------------------
proc ::tb::ishell::method:start {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Start the interactive shell (-help)
  variable params

  set error 0
  set help 0
  set shellName {}
  set prompt {}
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-n$} -
      {^-name$} -
      {^-n(a(me?)?)?$} {
           set shellName [lshift args]
      }
      {^-p$} -
      {^-prompt$} -
      {^-p(r(o(m(pt?)?)?)?)?$} {
           set prompt [lshift args]
      }
      {^-h$} -
      {^-help$} -
      {^-h(e(lp?)?)?$} {
           set help 1
      }
      default {
            if {[string match "-*" $name]} {
              puts " -E- option '$name' is not a valid option."
              incr error
            } else {
              set shellName $name
#               puts " -E- option '$name' is not a valid option."
#               incr error
            }
      }
    }
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  if {$help} {
    puts [format {
  Usage: ishell start
              [-prompt <string>|-p <string>]
              [-name <string>|-n <string>]
              [-help|-h]

  Description: Start the interactive shell

  Example:
     ishell start
     ishell start -prompt {debug%% }
} ]
    # HELP -->
    return {}
  }

  if {$params(enable) == 0} {
    if {$params(verbose)} { puts " -I- ishell disabled" }
    return -code ok
  }

  if {($shellName != {}) && ($prompt == {})} {
    set prompt [format {%s%% } $shellName]
  }
  if {$prompt == {}} {
    set prompt $params(prompt)
  }
  # Start the interactive shell
  ::tb::ishell::shell -prompt $prompt

  return -code ok
}

#------------------------------------------------------------------------
# ::tb::ishell::method:configure
#------------------------------------------------------------------------
# Usage: shell configure [<options>]
#------------------------------------------------------------------------
# Configure some of the interactive shell parameters
#------------------------------------------------------------------------
proc ::tb::ishell::method:configure {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Configure the shell (-help)
  variable params
  set error 0
  set help 0
  if {[llength $args] == 0} {
    set help 1
  }
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-p$} -
      {^-prompt$} -
      {^-p(r(o(m(pt?)?)?)?)?$} {
           set params(prompt) [lshift args]
      }
      {^-l$} -
      {^-level$} -
      {^-l(e(v(el?)?)?)?$} {
           set params(level) [lshift args]
      }
      {^-v$} -
      {^-verbose$} -
      {^-v(e(r(b(o(se?)?)?)?)?)?$} {
          set params(verbose) 1
      }
      {^-s$} -
      {^-silent$} -
      {^-s(i(l(e(nt?)?)?)?)?$} {
          set params(verbose) 0
      }
      {^-noverbose$} -
      {^-nov(e(r(b(o(se?)?)?)?)?)?$} {
          set params(verbose) 0
      }
      {^-d$} -
      {^-debug$} -
      {^-d(e(b(ug?)?)?)?$} {
          set  params(debug) 1
      }
      {^-nodebug$} -
      {^-nod(e(b(ug?)?)?)?$} {
          set  params(debug) 0
      }
      {^-h$} -
      {^-help$} -
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
    puts [format {
  Usage: ishell configure
              [-prompt <string>|-p <string>]
              [-level <num>|-l <num>]
              [-verbose|-v]
              [-silent|-s]
              [-help|-h]

  Description: Configure the interactive shell

  Example:
     ishell configure -prompt {debug%% }
} ]
    # HELP -->
    return -code ok
  }
  return -code ok
}



#################################################################################

namespace import ::tb::ishell


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
## Version:        2016.01.19
## Tool Version:   Vivado 2014.1
## Description:    This package provides a simple utility for macro creation
##
########################################################################################

########################################################################################
## 2016.01.19 - Fixed issue when unrecognized objects were not skipped
##            - Added support for clock objects
## 2015.10.26 - Initial release
########################################################################################

# mac usage:
#    mac set myname
#    mac set myname [get_selected]
#    mac save
#    mac get myname

if {[package provide Vivado] == {}} {return}

package require Vivado 1.2014.1

namespace eval ::tb {
    namespace export mac
}

inter alias {} @ {} mac set
inter alias {} lmac {} mac load
inter alias {} llmac {} mac list

proc ::tb::mac { args } {
  # Summary : Macro utility

  # Argument Usage:
  # args : sub-command. The supported sub-commands are: set | configure | get | save | load | list | reset | register

  # Return Value:
  # returns the status or an error code

#   if {[catch {set res [uplevel [concat ::tb::mac::mac $args]]} errorstring]} {
#     error " -E- the mac failed with the following error: $errorstring"
#   }
  return [uplevel 0 [linsert $args 0 ::tb::mac::mac]]
#   return [uplevel [concat ::tb::mac::mac $args]]
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
eval [list namespace eval ::tb::mac {
  variable version {2016.01.19}
  variable params
  variable macros [list]
  catch {unset params}
  array set params [list repository . autosave 1 verbose 1 debug 0]
  catch { namespace delete ::staticvars:: }
} ]

#------------------------------------------------------------------------
# ::tb::mac::mac
#------------------------------------------------------------------------
# Main function
#------------------------------------------------------------------------
proc ::tb::mac::mac { args } {
  # Summary :
  # Argument Usage:
  # Return Value:

  #-------------------------------------------------------
  # Process command line arguments
  #-------------------------------------------------------
  set error 0
  set show_help 0
  if {[llength $args] == 0} { incr show_help }
  set method [lshift args]
# puts "<args:$args>"
  switch -exact -- $method {
    dump {
      return [eval [concat ::tb::mac::dump] ]
    }
    ? -
    -h -
    -help {
      incr show_help
    }
    default {
      if {$method != {}} {
        # Trick to preserve collections of vivado objects
        return [uplevel 0 [linsert $args 0 ::tb::mac::do ${method} ] ]
#         return [uplevel 0 [list ::tb::mac::do ${method} $args] ]
      }
    }
  }

  if {$show_help} {
    # <-- HELP
    puts ""
    ::tb::mac::method:?
    puts [format {
   Description: Utility for macros creation

   Example:
      mac configure -noautosave
      mac set myselection [get_selected_objects]
      mac set idt_top1 [filter [get_selected_objects] {IS_PRIMITIVE}]
      # Create macro based on current selected objects
      mac set myselection2
      mac save allmacros.mac
      select_objects [myselection]
      select_objects [mac get myselection]

    } ]
    # HELP -->
    return
  }

}

#------------------------------------------------------------------------
# ::tb::mac::lshift
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Stack function
#------------------------------------------------------------------------
proc ::tb::mac::lshift {inputlist} {
  # Summary :
  # Argument Usage:
  # Return Value:

  upvar $inputlist argv
  set arg  [lindex $argv 0]
  set argv [lrange $argv 1 end]
  return $arg
}

#------------------------------------------------------------------------
# ::tb::mac::docstring
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Return the embedded help of a proc
#------------------------------------------------------------------------
proc ::tb::mac::docstring {procname} {
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
# ::tb::mac::do
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Dispatcher with methods
#------------------------------------------------------------------------
proc ::tb::mac::do {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  if {[llength $args] == 0} {
#     error " -E- wrong number of parameters: mac <sub-command> \[<arguments>\]"
    set method {?}
  } else {
    # The first argument is the method
    set method [lshift args]
  }
  if {[info proc ::tb::mac::method:${method}] == "::tb::mac::method:${method}"} {
    eval [linsert $args 0 ::tb::mac::method:${method} ]
#     eval ::tb::mac::method:${method} $args
  } else {
    # Search for a unique matching method among all the available methods
    set match [list]
    foreach procname [info proc ::tb::mac::method:*] {
      if {[string first $method [regsub {::tb::mac::method:} $procname {}]] == 0} {
        lappend match [regsub {::tb::mac::method:} $procname {}]
      }
    }
    switch [llength $match] {
      0 {
        error " -E- unknown sub-command $method"
      }
      1 {
        set method $match
        return [eval [linsert $args 0 ::tb::mac::method:${method} ] ]
#         return [eval ::tb::mac::method:${method} $args]
      }
      default {
        error " -E- multiple sub-commands match '$method': $match"
      }
    }
  }
}

#------------------------------------------------------------------------
# ::tb::mac::method:?
#------------------------------------------------------------------------
# Usage: mac ?
#------------------------------------------------------------------------
# Return all the available methods. The methods with no embedded help
# are not displayed (i.e hidden)
#------------------------------------------------------------------------
proc ::tb::mac::method:? {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # This help message
  puts "   Usage: mac <sub-command> \[<arguments>\]"
  puts "   Where <sub-command> is:"
  foreach procname [lsort [info proc ::tb::mac::method:*]] {
    regsub {::tb::mac::method:} $procname {} method
    set help [::tb::mac::docstring $procname]
    if {$help ne ""} {
      puts "         [format {%-12s%s- %s} $method \t $help]"
    }
  }
  puts ""
}

#------------------------------------------------------------------------
# ::tb::mac::dump
#------------------------------------------------------------------------
# Usage: mac dump
#------------------------------------------------------------------------
# Dump mac status
#------------------------------------------------------------------------
proc ::tb::mac::dump {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Dump non-array variables
  foreach var [lsort [info var ::tb::mac::*]] {
    if {![info exists $var]} { continue }
    if {![array exists $var]} {
      puts "   $var: [subst $$var]"
    }
  }
  # Dump array variables
  foreach var [lsort [info var ::tb::mac::*]] {
    if {![info exists $var]} { continue }
    if {[array exists $var]} {
      parray $var
    }
  }
  # Dump static variables
  staticvars::dump

  return -code ok
}

#------------------------------------------------------------------------
# ::tb::mac::method:version
#------------------------------------------------------------------------
# Usage: mac version
#------------------------------------------------------------------------
# Return the version of the utility
#------------------------------------------------------------------------
proc ::tb::mac::method:version {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Version
  variable version
#   puts " -I- mac version $version"
  return -code ok "macro utility version $version"
}

#------------------------------------------------------------------------
# ::tb::mac::method:set
#------------------------------------------------------------------------
# Usage: mac set <list_of_objects> [<name>]
#------------------------------------------------------------------------
# Create new macro
#------------------------------------------------------------------------
# proc ::tb::mac::method:set { objs {name {default}} } {}
proc ::tb::mac::method:set { name { objs {} } } {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Create new macro
  variable params
  variable macros
# puts "<objs:$objs>"
# puts "<name:$name>"
  if {[llength $objs] == 0} {
    set objs [get_selected_objects]
  }
  set cmds [o2c $objs]
  if {$cmds == {}} {
    puts " error - no primary Vivado object(s)"
    return {}
#     error " error - no primary Vivado object"
  }
#   puts $cmds
  set proc [format "proc ::%s { {force 0} } \{" $name]
#   append proc "\n ::tb::mac::static L ; if {!\$force && \[info exists L\]} { puts {Returning existing value} ; return \$L }"
  append proc "\n ::tb::mac::static L ; if {!\$force && \[info exists L\]} { return \$L }"
  append proc "\n proc T obj { upvar 1 L L; upvar 1 idx idx ; incr idx ; if {\$obj != {}} { lappend L \$obj } else { error {} } }"
  append proc "\n proc E {} { upvar error error ; upvar idx idx ; puts \" -W- $name: failed to create object \$idx\" ; incr error }"
  append proc "\n set L \[list\]; set error 0 ; set idx -1"
  foreach cmd $cmds {
    append proc [format "\n if {\[catch {T \[%s\]} errorstring\]} { E } " $cmd]
  }
  append proc [format "\n if {\$error} { puts \" -W- $name: \$error object(s) were not created\" } "]
  append proc [format "\n return \$L \n\}"]
#   puts "<$proc>"
  # create the proc inside the global namespace
  uplevel #0 [list eval $proc]
  # Reset macro so that it's content can be re-evaluated
  ::tb::mac::method:reset $name
#   catch { unset ::tb::mac::staticvars::${name}::L }
  set macros [lsort -unique [concat $macros $name]]
  if {$params(verbose)} {
    puts " Created proc $name"
  }
  if {$params(autosave)} {
    set filename [file normalize [file join $params(repository) ${name}.mac]]
    if {[catch {
      set FH [open $filename {w}]
      puts $FH "::tb::mac register $name"
      puts $FH $proc
      close $FH
      if {$params(verbose)} {
        puts " Saved $filename"
      }
    } errorstring]} {
      puts "\n$errorstring"
    }
  }
#   puts $proc
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::mac::method:save
#------------------------------------------------------------------------
# Usage: mac save
#------------------------------------------------------------------------
# Save all macros to disk
#------------------------------------------------------------------------
proc ::tb::mac::method:save { {filename {}} } {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Save macros to file
  variable params
  variable macros
  if {$macros == {}} {
    puts " -E- no macro exist"
    return -code ok
  }
  set mode {multi}
  if {$filename != {}} {
    set mode {single}
    set FH [open $filename {w}]
  }
  foreach name [lsort -unique $macros] {
    set proc [format "proc %s {} \{%s\}" $name [info body $name] ]

    if {$mode == {single}} {
      puts $FH "::tb::mac register $name"
      puts $FH $proc
      puts $FH ""
      if {$params(verbose)} {
        puts " Included macro '$name'"
      }
    } else {
      set filename [file normalize [file join $params(repository) ${name}.mac]]
      if {[catch {
        set FH [open $filename {w}]
        puts $FH "::tb::mac register $name"
        puts $FH $proc
        close $FH
        if {$params(verbose)} {
          puts " Saved $filename"
        }
      } errorstring]} {
        puts "\n$errorstring"
      }
    }

  }
  if {$mode == {single}} {
    puts " Saved $filename"
    close $FH
  }
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::mac::method:load
#------------------------------------------------------------------------
# Usage: mac load <file(s)>
#------------------------------------------------------------------------
# Load macros from disk
#------------------------------------------------------------------------
proc ::tb::mac::method:load { {pattern {}} } {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Load macro file(s) from disk
  variable params
  variable macros
  if {$pattern == {}} {
    set files [glob [file normalize [file join $params(repository) *.mac]]]
  } elseif {[file exists ${pattern}.mac]} {
    set files ${pattern}.mac
  } else {
    set files [glob $pattern]
  }
  if {[llength $files] == 0} {
    puts " no file match '$pattern'"
    return -code ok
  }
  foreach filename $files {
    if {[catch {
      set FH [open $filename {r}]
      set content [read $FH]
      close $FH
      puts " Loaded $filename"
      uplevel #0 $content
    } errorstring]} {
      puts "\n$errorstring"
    }
  }
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::mac::method:list
#------------------------------------------------------------------------
# Usage: mac list
#------------------------------------------------------------------------
# List available macros
#------------------------------------------------------------------------
proc ::tb::mac::method:list {} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # List macros
  variable params
  variable macros
  puts "  Available macros:"
  puts "  -----------------"
  foreach m [lsort -unique $macros] {
    if {[info exists ::tb::mac::staticvars::${m}::L]} {
      set objs [subst $\{::tb::mac::staticvars::${m}::L\}]
      puts "    $m \t --> \t [llength $objs] objects \t ([lsort -unique [get_property -quiet CLASS $objs]])"
    } else {
      puts "    $m \t --> \t ?? objects"
    }
#     puts "    $m"
  }
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::mac::method:reset
#------------------------------------------------------------------------
# Usage: mac reset <macro(s)>
#------------------------------------------------------------------------
# Reset macro(s). Force macros content to be re-evaluated.
#------------------------------------------------------------------------
proc ::tb::mac::method:reset { {pattern {}} } {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Reset macro(s)
  variable params
  variable macros
  if {$pattern == {}} { return -code ok }
  foreach m [lsort -unique $macros] {
    if {[regexp "^$pattern\$" $m]} {
      if {$params(debug)} {
        puts " -I- Resetting macro '$m'"
      }
      catch { unset ::tb::mac::staticvars::${m}::L }
    }
  }
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::mac::method:register
#------------------------------------------------------------------------
# Usage: mac register <macro>
#------------------------------------------------------------------------
# Register a macro.
#------------------------------------------------------------------------
proc ::tb::mac::method:register { name } {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Register macro
  variable params
  variable macros
  if {$name == {}} {
    puts " -E- Invalid macro name '$name'"
    return -code ok
  }
  # Add the macro to the list of macros
  set macros [lsort -unique [concat $macros $name]]
  # Reset the macro
  ::tb::mac::method:reset $name
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::mac::method:get
#------------------------------------------------------------------------
# Usage: mac get <macro>
#------------------------------------------------------------------------
# Get macro content
#------------------------------------------------------------------------
proc ::tb::mac::method:get { {name {}} } {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Get macro's objects
  variable params
  variable macros
  if {$name == {}} {
    puts " no macro name provided"
    return -code ok
  } elseif {[lsearch -exact $macros $name] == -1} {
    puts " macro '$name' does not exist"
    return -code ok
  }
#   return [subst $[subst ::staticvars::${name}::L]]
  return [eval $name]
}

#------------------------------------------------------------------------
# ::tb::mac::o2c
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Stack function
#------------------------------------------------------------------------
proc ::tb::mac::o2c { objs } {
  # Summary :
  # Argument Usage:
  # Return Value:

  set cmds [list]
# static c2c
# set c2c $objs
  switch [llength [get_property -quiet CLASS $objs]] {
    0 {
# puts "<objs:$objs>"
      puts " error - no primary Vivado object(s)"
      return {}
#       error " error - no primary Vivado object"
    }
    1 {
      # A single object needs to be put in a Tcl list
      set objs [list $objs]
    }
    default {
    }
  }
  set CLASS [lsort -unique [get_property -quiet CLASS $objs]]
  set flag 1
  if {[llength $CLASS] == 1} {
    set flag 0
  }
  foreach obj $objs {
    set cmd {}
    if {$flag} { set CLASS [get_property -quiet CLASS $obj] }
# puts "<$obj><$CLASS>"
    switch $CLASS {
      cell {
        set cmd [format {get_cells -quiet {%s}} $obj]
      }
      pin {
        set cmd [format {get_pins -quiet {%s}} $obj]
      }
      port {
        set cmd [format {get_ports -quiet {%s}} $obj]
      }
      net {
        set cmd [format {get_nets -quiet {%s}} $obj]
      }
      clock {
        set cmd [format {get_clocks -quiet {%s}} $obj]
      }
      site {
        set cmd [format {get_sites -quiet {%s}} $obj]
      }
      site_pin {
        set cmd [format {get_site_pins -quiet {%s}} $obj]
      }
      timing_path {
# puts "<obj:$obj>[report_property $obj]"
        set startpin [get_property -quiet STARTPOINT_PIN $obj]
        set endpin [get_property -quiet ENDPOINT_PIN $obj]
#         set nets [get_nets -quiet -of $obj]
        set nets [get_nets -quiet -of $obj -top_net_of_hierarchical_group -filter {TYPE == SIGNAL}]
# puts "<startpin:$startpin><endpin:$endpin><nets:$nets>"
#         set cmd [format {get_timing_paths -quiet -from [get_pins -quiet {%s}] -to [get_pins -quiet {%s}] -through [get_nets -quiet [list %s]]} $startpin $endpin $nets]
        set cmd [format {get_timing_paths -quiet -from [get_%ss -quiet {%s}] -to [get_%ss -quiet {%s}] -through [get_nets -quiet [list %s]]} [get_property CLASS $startpin] $startpin [get_property CLASS $endpin] $endpin $nets]
      }
      default {
        puts " -W- skipping object $obj"
        continue
      }
    }
    # Convert {{->{ and }}->}
    regsub -all "{{" $cmd "{" cmd
    regsub -all "}}" $cmd "}" cmd
#     puts "<$cmd>"
    lappend cmds $cmd
  }
  return $cmds
}

#------------------------------------------------------------------------
# ::tb::mac::method:configure
#------------------------------------------------------------------------
# Usage: mac configure [<options>]
#------------------------------------------------------------------------
# Configure some of the mac parameters
#------------------------------------------------------------------------
proc ::tb::mac::method:configure {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Configuration (-help)
  variable params
  set error 0
  set help 0
  if {[llength $args] == 0} {
    set help 1
  }
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -repo -
      -repository {
           set params(repository) [lshift args]
      }
      -autosave {
           set params(autosave) 1
      }
      -noautosave {
           set params(autosave) 0
      }
      -verbose {
           set params(verbose) 1
      }
      -quiet -
      -noverbose {
           set params(verbose) 0
      }
      -debug {
           set params(debug) 1
      }
      -nodebug {
           set params(debug) 0
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
  Usage: mac configure
              [-repo <dir>]
              [-autosave]
              [-noautosave]
              [-verbose]
              [-noverbose|-quiet]
              [-help|-h]

  Description: Utility configuration

  Example:
     mac configure -repo /home/user/macs -noautosave
} ]
    # HELP -->
    return -code ok
  }
  return -code ok
}

# namespace eval ::tb::mac::staticvars {}

proc ::tb::mac::static {args} {
  set ns ::tb::mac::staticvars
  append ns [string trimright [uplevel 1 namespace current] :]
# puts "<ns:1><$ns><namespace><[uplevel 1 namespace current]>"
  append ns :: [namespace tail [lindex [info level -1] 0]]
# puts "<ns:2><$ns>"
  foreach var $args {
    if {![string equal [namespace tail $var] $var]} {
      return -code error -errorinfo "Static variable $var has namespace qualifiers"
    }
#     if {![info exists ${ns}::$var]} {
# puts "<ns><$ns><var><$var>"
      namespace eval $ns [list variable $var] ;# (1)
#     }
    uplevel 1 upvar #0 ${ns}::$var $var
  }
}


namespace eval ::tb::mac::staticvars {

  proc assign { var value } {
    if {[info exists "[namespace current]::${var}"]} {
      set current_value [subst "$[namespace current]::${var}"]
      set [namespace current]::${var} $value
      puts "  Setting '$var' from '$current_value' to '$value'"
    } else {
      puts "  Error - var '$var' does not exist"
    }
  }

  proc reset { var } {
    if {[info exists "[namespace current]::${var}"]} {
      unset [namespace current]::${var}
      puts "  Resetting var '$var'"
    } else {
      puts "  Error - var '$var' does not exist"
    }
  }

  proc dump { {root {}} } {
    set format {  %-15s %-15s %-15s %-7s %-15s %-20s }
    if {$root == {}} {
      set root [namespace current]
      puts ""
      puts [format $format {Namespace} {Proc} {Var} {#Objs} {Type} {Objects} ]
      puts [format $format {---------------} {---------------} {---------------} {-------} {---------------} {---------------} ]
    }
    foreach child [namespace children $root] {
      dump $child
    }
    foreach var [info var ${root}::*] {
# puts "<var><$var><[llength [split $var :]]><[split $var :]>"
      if {[info exists $var]} {
        # ::tb::mac::staticvars::<proc>::<var> or ::tb::mac::staticvars::<namespace>::<proc>::<var> ??
        switch [llength [split $var :]] {
          11 {
            # ::tb::mac::staticvars::<proc>::<var>
            foreach { - - - - - - - - procName - varName } [split $var :] { break }
            set objs [subst $$var]
            if {[llength $objs] > 2} {
              puts [format $format {} $procName $varName  [llength $objs] [lsort -unique [get_property -quiet CLASS $objs]] [format {%s ...} [lrange $objs 0 1]] ]
            } else {
              puts [format $format {} $procName $varName  [llength $objs] [lsort -unique [get_property -quiet CLASS $objs]] [lrange $objs 0 1] ]
            }
          }
          13 {
            # ::tb::mac::staticvars::<namespace>::<proc>::<var>
            foreach { - - - - - - - namespaceName - procName - varName } [split $var :] { break }
            set objs [subst $$var]
            if {[llength $objs] > 2} {
              puts [format $format $namespaceName $procName $varName [llength $objs] [lsort -unique [get_property -quiet CLASS $objs]] [format {%s ...} [lrange $objs 0 1]] ]
            } else {
              puts [format $format $namespaceName $procName $varName [llength $objs] [lsort -unique [get_property -quiet CLASS $objs]] [lrange $objs 0 1] ]
            }
          }
          default {
# <var><::staticvars::tb::mac::o2c::c2c><11><{} {} staticvars {} tb {} mac {} o2c {} c2c>
# <var><::staticvars::tb::mac::method:add::add><12><{} {} staticvars {} tb {} mac {} method add {} add>
# puts "<var><$var><[llength [split $var :]]><[split $var :]>"
          }
        }
      } else {
#         puts "  Error - var '$var' is undefined"
      }
    }
    if {$root == [namespace current]} {
      puts ""
    }
  }
}


#################################################################################

namespace import ::tb::mac

# Information
# mac -help


###########################################################################
##
## This namespace defines the implementation of procedures for GoldTime
##
###########################################################################

namespace eval ::GT {

  variable data
  
  proc lshift {inputlist} {
    upvar $inputlist argv
    set arg  [lindex $argv 0]
    set argv [lrange $argv 1 end]
    return $arg
  }

  proc format_float {number {format_str "%.2f"}} {
    switch -exact -- $number {
      UNINIT { }
      INFINITY { }
      default {set number [format $format_str $number]}
    }
    return $number;
  }

  proc indent { { level 0 } } {
    return [string repeat "  " $level]
  }
  

  #------------------------------------------------------------------------
  # output
  #------------------------------------------------------------------------
  # Format the output of the commands
  #------------------------------------------------------------------------
  proc output {type output {filename -} {append 0}} {
    switch $type {
      stdout {
        puts [join $output \n]
        return {}
      }
      string {
        return [join $output \n]
      }
      file {
        if {$append} {
          set FH [open $filename {a}]
        } else {
          set FH [open $filename {w}]
        }
        puts $FH [join $output \n]
        close $FH
        if {$append} {
          puts " -I- file '$filename' updated"
        } else {
          puts " -I- file '$filename' created"
        }
        return {}
      }
      default {
        puts " -E- proc 'output' called with unknown type '$type'"
      }
    }
  }


  #------------------------------------------------------------------------
  # show_case_value
  #------------------------------------------------------------------------
  # Report the case values on a cell or a pin
  #------------------------------------------------------------------------
  proc show_case_value { args } {
    puts " -E- NOT YET IMPLEMENTED\n"
    return
  }


  #------------------------------------------------------------------------
  # show_arcs
  #------------------------------------------------------------------------
  # Report information about timing arcs
  #------------------------------------------------------------------------
  proc show_arcs { args } {
    puts " -E- NOT YET IMPLEMENTED\n"
    return
  }


  #------------------------------------------------------------------------
  # show_info
  #------------------------------------------------------------------------
  # Report information on a net/cell/pin
  #------------------------------------------------------------------------
  proc show_info { args } {
    puts " -E- NOT YET IMPLEMENTED\n"
    return
  }



  #------------------------------------------------------------------------
  # show_cell_info
  #------------------------------------------------------------------------
  # Report information on a cell
  #------------------------------------------------------------------------
  proc show_cell_info { name } {
    puts "This is a cell: $name"
    set output [list]
    return $output
  }
  

  #------------------------------------------------------------------------
  # show_pin_info
  #------------------------------------------------------------------------
  # Report information on a pin
  #------------------------------------------------------------------------
  proc show_pin_info { name } {
    puts "This is a pin: $name"
    set output [list]
    return $output
  }
  

  #------------------------------------------------------------------------
  # show_net_info
  #------------------------------------------------------------------------
  # Report information on a net
  #------------------------------------------------------------------------
  proc show_net_info { name } {
    puts "This is a net: $name"
    set output [list]
    return $output
  }


  #------------------------------------------------------------------------
  # analyze_path
  #------------------------------------------------------------------------
  # Report information about a path defined through a list of pins
  #------------------------------------------------------------------------
  proc analyze_path { args } {
    puts " -E- NOT YET IMPLEMENTED\n"
    return
  }


  #------------------------------------------------------------------------
  # trace_arcs
  #------------------------------------------------------------------------
  # Trace enabled timing arcs from/to a pin. If a timing arcs goes to multiple 
  # pins, then the function stops
  #------------------------------------------------------------------------
  proc trace_arcs { args } {
    puts " -E- NOT YET IMPLEMENTED\n"
    return
  }



# END NAMESPACE FOR GOLDTIME
}

puts " [info script] has been successfully sourced ..."


###########################################################################
##
## This namespace defines the implementation of procedures for PrimeTime
##
###########################################################################

namespace eval ::PT {

  variable data
  
  #------------------------------------------------------------------------
  # lshift format_float indent
  #------------------------------------------------------------------------
  # Various helper functions
  #------------------------------------------------------------------------
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
    return [string repeat " " [expr $level * 4] ]
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
          puts " -I- file '$filename' updated\n"
        } else {
          puts " -I- file '$filename' created\n"
        }
        puts [join $output \n]
        return {}
      }
      default {
        puts " -E- proc 'output' called with unknown type '$type'"
      }
    }
  }


  #------------------------------------------------------------------------
  # format_string
  #------------------------------------------------------------------------
  # Format a string for, for example, a table header or row.
  #
  # E.g.: format_string $indentLevel "%-15s %-15s %-10s %-25s %-11s %-16s %-20s" "from_pin" "to_pin" "is_cellarc" "sense" "is_disabled" "is_user_disabled" "mode"
  #       format_string $indentLevel "%-15s %-15s %-10s %-25s %-11s %-16s %-20s" "--------" "------" "----------" "-----" "-----------" "----------------" "----"
  #
  #------------------------------------------------------------------------
  proc format_string { level format args } {
    # Replace all spaces with a tab
    set format [regsub -all { } $format "\t"]
    return [eval [concat format [list "%s $format"] [list [indent $level]] $args]]
  }


  #------------------------------------------------------------------------
  # format_ref_name
  #------------------------------------------------------------------------
  # Format cell's ref name. If the cell is hierarchical then the returned
  # cell's reference name is surrounded by *.
  #------------------------------------------------------------------------
  proc format_ref_name { cell_name } {
    set cell [get_cells -quiet $cell_name]
    if {$cell == {}} {
      return {-}
    }
    if {[get_attribute -quiet $cell is_hierarchical] == {true}} {
      return [format {*%s*} [get_attribute $cell ref_name]]
    }
    return [get_attribute $cell ref_name]
  }


  #------------------------------------------------------------------------
  # format_pin_name
  #------------------------------------------------------------------------
  # Format pin or port name. If the pin is hierarchical then the returned
  # pin name is surrounded by *.
  #------------------------------------------------------------------------
  proc format_pin_name { pin_name { full 1 } } {
    set pin [get_pins -quiet $pin_name]
    # Is it a pin?
    if {$pin != {}} {
      if {[get_attribute -quiet $pin is_hierarchical] == {true}} {
        if {$full} {
          return [format {*%s*} [get_attribute $pin full_name] ]
        } else {
          return [format {*%s*} [lindex [split [get_attribute $pin full_name] /] end] ]
        }
      }
      if {$full} {
        return [get_attribute $pin full_name]
      } else {
        return [lindex [split [get_attribute $pin full_name] /] end]
      }
    }
    set port [get_ports -quiet $pin_name]
    # Is it a port?
    if {$port != {}} {
      if {$full} {
        return [format {@%s@} [get_attribute $port full_name] ]
      } else {
        return [format {@%s@} [lindex [split [get_attribute $port full_name] /] end] ]
      }
    }
    # If it does not match any pin or port, just return the object name
    return [format {%s} [get_object_name $pin_name]]
#     return [format {?%s?} [get_object_name $pin_name]]
#     return {-}
  }


  #------------------------------------------------------------------------
  # format_cell_name
  #------------------------------------------------------------------------
  # Format cell name. If the cell is hierarchical then the returned
  # cell name is surrounded by *.
  #------------------------------------------------------------------------
  proc format_cell_name { cell_name { full 1 } } {
    set cell [get_cells -quiet $cell_name]
    if {$cell == {}} {
      return {-}
    }
    if {[get_attribute -quiet $cell is_hierarchical] == {true}} {
      if {$full} {
        return [format {*%s*} [get_attribute $cell full_name] ]
      } else {
        return [format {*%s*} [lindex [split [get_attribute $cell full_name] /] end] ]
      }
    }
    if {$full} {
      return [get_attribute $cell full_name]
    } else {
      return [lindex [split [get_attribute $cell full_name] /] end]
    }
  }


  #------------------------------------------------------------------------
  # search_cell
  #------------------------------------------------------------------------
  # Search for the closest hierarchical module or leaf cell that matches the provided
  # hierarchical cell name. Goes bottom-up.
  #------------------------------------------------------------------------
  # Type: both | leaf | hierarchical
  #------------------------------------------------------------------------
  proc search_cell { cell_name { type {both} } } {
    if {![regexp -nocase {^(both|hier|hierarchical|leaf)$} $type]} {
      puts "  -E- Unknown type '$type'"
      return {}
    }
    # Check for '' and '.' since 'file dirname' can return '.' when there is no hierarchy left
    if {($cell_name != {}) && ($cell_name != {.})} {
      if {[get_cells -quiet $cell_name] != {}} {
        # OK: cell $cell_name exists
        switch [string tolower $type] {
          both {
            return $cell_name
          }
          hierarchical -
          hier {
            if {[get_attribute -quiet [get_cells -quiet $cell_name] is_hierarchical] == {true}} {
              return $cell_name
            } else {
              return [search_cell [file dirname $cell_name] $type]
#               return [search_cell [join [lrange [split $cell_name / ] 0 end-1] / ] $type ]
            }
          }
          leaf {
            if {[get_attribute -quiet [get_cells -quiet $cell_name] is_hierarchical] == {false}} {
              return $cell_name
            } else {
              return [search_cell [file dirname $cell_name] $type]
#               return [search_cell [join [lrange [split $cell_name / ] 0 end-1] / ] $type ]
            }
          }
          default {
          }
        }
      } else {
        # Not a cell: try one hierarchical level above the current one
        return [search_cell [file dirname $cell_name] $type]
#         return [search_cell [join [lrange [split $cell_name / ] 0 end-1] / ] $type ]
      }
    } else {
      # Could not find any valid cell in the path of '$cell_name'"
      return {}
    }
  }


  #------------------------------------------------------------------------
  # get_connected_leaf_pins
  #------------------------------------------------------------------------
  # Get all the leaf pins connected to a hierarchical pin.
  #------------------------------------------------------------------------
  # Type: both | fanout | fanin
  #------------------------------------------------------------------------
  proc get_connected_leaf_pins { pin_name { type {both} } } {
    if {![regexp -nocase {^(both|fanout|fanin)$} $type]} {
      puts "  -E- Unknown type '$type'"
      return {}
    }
#     set pin [get_pins -quiet $pin_name]
    set pin [add_to_collection [get_pins -quiet $pin_name] [get_ports -quiet $pin_name] ]
    switch [sizeof_collection $pin] {
      1 {
        # OK: only 1 pin/port should match
      }
      0 {
        puts "  -E- Cannot find pin/port '$pin_name'"
        return {}
     }
      default {
        puts "  -E- Pin '$pin_name' match more than 1 pin/port"
        return {}
      }
    }
    if {([get_attribute -quiet $pin object_class] == {pin}) && ([get_attribute -quiet $pin is_hierarchical] != {true})} {
      puts "  -W- Pin '$pin_name' is not a hierarchical pin but a leaf pin"
      return $pin_name
    }
    set leafPins [list]
#     foreach_in_collection leaf_pin [get_pins -quiet -of [get_nets -quiet -of $pin] -leaf] {}
    foreach_in_collection leaf_pin [ add_to_collection [get_pins -quiet -of [get_nets -quiet -of $pin] -leaf] [get_ports -quiet -of [get_nets -quiet -of $pin] ] ] {
      switch [string tolower $type] {
        both {
          lappend leafPins [get_object_name $leaf_pin]
        }
        fanout {
          if {[get_attribute -quiet $leaf_pin direction] == {in}} {
            lappend leafPins [get_object_name $leaf_pin]
          }
        }
        fanin {
          if {[get_attribute -quiet $leaf_pin direction] == {out}} {
            lappend leafPins [get_object_name $leaf_pin]
          }
        }
        default {
        }
      }
    }
    return $leafPins
  }


  #------------------------------------------------------------------------
  # get_connected_pins
  #------------------------------------------------------------------------
  # Get all the pins connected to a hierarchical pin. 
  # Only the next level of pins is returned. The returned pins are not 
  # necessary leaf pins.
  #------------------------------------------------------------------------
  # Type: both | fanout | fanin
  #------------------------------------------------------------------------
  proc get_connected_pins { pin_name { type {both} } } {
    if {![regexp -nocase {^(both|fanout|fanin)$} $type]} {
      puts "  -E- Unknown type '$type'"
      return {}
    }
#     set pin [get_pins -quiet $pin_name]
    set pin [add_to_collection [get_pins -quiet $pin_name] [get_ports -quiet $pin_name] ]
    switch [sizeof_collection $pin] {
      1 {
        # OK: only 1 pin/port should match
      }
      0 {
        puts "  -E- Cannot find pin/port '$pin_name'"
        return {}
     }
      default {
        puts "  -E- Pin '$pin_name' match more than 1 pin/port"
        return {}
      }
    }
#     if {[get_attribute -quiet $pin is_hierarchical] != {true}} {}
    if {([get_attribute -quiet $pin object_class] == {pin}) && ([get_attribute -quiet $pin is_hierarchical] != {true})} {
      puts "  -W- Pin '$pin_name' is not a hierarchical pin but a leaf pin"
      return $pin_name
    }
    set allPins [list]
    foreach_in_collection conn_pin [all_fanin -flat -pin_level 1 -to $pin] {
      switch [string tolower $type] {
        both -
        fanin {
          switch [get_attribute -quiet $conn_pin object_class] {
            pin {
              if {([get_attribute -quiet $conn_pin direction] == {out}) && ($pin_name != [get_object_name $conn_pin])} {
                lappend allPins [get_object_name $conn_pin]
              }
            }
            port {
              if {([get_attribute -quiet $conn_pin direction] == {in}) && ($pin_name != [get_object_name $conn_pin])} {
                lappend allPins [get_object_name $conn_pin]
              }
            }
            default {
            }
          }
        }
        default {
        }
      }
    }
    foreach_in_collection conn_pin [all_fanout -flat -pin_level 1 -from $pin] {
      switch [string tolower $type] {
        both -
        fanout {
          switch [get_attribute -quiet $conn_pin object_class] {
            pin {
              if {([get_attribute -quiet $conn_pin direction] == {in}) && ($pin_name != [get_object_name $conn_pin])} {
                lappend allPins [get_object_name $conn_pin]
              }
            }
            port {
              if {([get_attribute -quiet $conn_pin direction] == {out}) && ($pin_name != [get_object_name $conn_pin])} {
                lappend allPins [get_object_name $conn_pin]
              }
            }
            default {
            }
          }
        }
        default {
        }
      }
    }
    return $allPins
  }


  #------------------------------------------------------------------------
  # get_report_timing_pins
  #------------------------------------------------------------------------
  # Return a Tcl list of input/output pins from a report_timing command.
  # The command to be executed is passed as a string to the command.
  #------------------------------------------------------------------------
  # Example:
  #   set pins [PT::get_report_timing_pins  " \
  #   -from vorpalClk1965 \
  #   -thro \[all_fanout -endpoints_only -flat -from Imega_dsp_X2Y0_R0/Idsp_dsp_remap_X0Y10_R0/Idsp_dsp_ft_X0Y0_R0/Idsp_dsp_core_X0Y0_R0/Idsp0/Iout/clk_b\] \
  #   -thro Imega_dsp_X2Y0_R0/Idsp_dsp_remap_X0Y10_R0/Idsp_dsp_ft_X0Y0_R0/Idsp_dsp_core_X0Y0_R0/Idsp0/Iout/ccout_fb \
  #   -fall_thro Imega_dsp_X2Y0_R0/Idsp_dsp_remap_X0Y10_R0/Idsp_dsp_ft_X0Y0_R0/Idsp_dsp_core_X0Y0_R0/Idsp0/Ialu/ccout_fb \
  #   -fall_thro Imega_dsp_X2Y0_R0/Idsp_dsp_remap_X0Y10_R0/Idsp_dsp_ft_X0Y0_R0/Idsp_dsp_core_X0Y0_R0/Idsp0/Ialu/multsign_alu_b \
  #   -to \[all_fanout -flat -endpoints_only -from Imega_dsp_X2Y0_R0/Idsp_dsp_remap_X0Y10_R0/Idsp_dsp_ft_X0Y0_R0/Idsp_dsp_core_X0Y0_R0/Idsp0/Iout/multsign_alu_b\] \
  #   -delay_type min "]
  #------------------------------------------------------------------------
  proc get_report_timing_pins { cmd } {
    set staToolName {pt}
    if {[info exists ::staToolName]} {
      set staToolName $::staToolName
    }
    switch $staToolName {
      pt {
        eval [list redirect -file get_report_timing_pins.rpt [format {report_timing %s -nosplit -max_paths 1 -nworst 1 -input_pins} $cmd]]
      }
      gt {
        eval [list redirect -file get_report_timing_pins.rpt [format {report_timing %s -nosplit -max_paths 1 -nworst 1 -input_pins -output_pins -no_hierarchical_pins} $cmd]]
      }
      default {
      }
    }
  #   eval [concat report_timing $cmd -nosplit -max_paths 1 -nworst 1 -input_pins -output_pins -no_hierarchical_pins -path_type full_clock_expanded > get_report_timing_pins.rpt]
    set FH [open get_report_timing_pins.rpt]
    set SM {start}
    set pins [list]
    set paths [list]
    while {![eof $FH]} {
      gets $FH line
      switch $SM {
        start {
          if {[regexp -nocase -- {^\s*Startpoint\s*:} $line]} {
            set SM {startpoint}
          }
        }
        startpoint {
          if {[regexp {^\s*--------------------------------------} $line]} {
            set SM {path}
          }
        }
        path {
          if {[regexp {^\s*(clock|network|input|output|library|data|max_delay|min_delay)} $line]} {
            # Those lines do not include a pin. Skip them.
            continue
          }
          if {[regexp {^\s*([^\s]+)\s+\((.+)\)} $line - pin module]} {
            if {[get_pins -quiet $pin] != {}} {
              if {[get_attribute -quiet [get_pins $pin] is_hierarchical] == {false}} {
                lappend pins $pin
                puts " -I- Found pin '$pin'"
              } else {
                puts " -I- Skipping hierarchical pin '$pin'"
              }
            } elseif {[get_ports -quiet $pin] != {}} {
              lappend pins $pin
              puts " -I- Found port '$pin'"
            } else {
              puts " -W- Invalid pin/port '$pin'"
            }
          } elseif {[regexp {^\s*$} $line]} {
          } elseif {[regexp {^\s*--------------------------------------} $line]} {
            set SM {end}
          } else {
            puts " -W- Could not extract pin name from: $line"
          }
        }
        end {
          # Save the list of pins for this timing path
          lappend paths $pins
          set SM {start}
        }
        default {
        }
      }
    }
    close $FH
#     if {[llength $paths] == 1} {
#       # If there is only 1 path, then return that path only. Otherwise, all
#       # the paths are returned as a list of paths.
#       set paths [lindex $paths 0]
#     }
    return $paths
  }


  #------------------------------------------------------------------------
  # show_case_value
  #------------------------------------------------------------------------
  # Report the case values on a cell or a pin
  #------------------------------------------------------------------------
  proc show_case_value { args } {

    set staToolName {pt}
    if {[info exists ::staToolName]} {
      set staToolName $::staToolName
    }

    #-------------------------------------------------------
    # Process command line arguments
    #-------------------------------------------------------
    set cellName {}
    set pinName {}
    set netName {}
    set type 0
    set show_only_set 0
    set full_pin_name 0
    set error 0
    set help 0
    set indentLevel 0
    set msgLevel 0
    set output [list]
    set outputType {stdout}
    set outputFilename {}
    set outputAppend 0
    set commandLine $args
    if {[llength $args] == 0} { incr help }
    # Add dummy argument to the command line so that "> file" & ">> file" 
    # are processed as a command line arguments
    lappend args {--}
    while {[llength $args]} {
      set name [lshift args]
      switch -exact -- $name {
        -cell -
        -c {
             set cellName [lshift args]
             set type [expr $type | 1]
        }
        -port -
        -pin -
        -p {
             set pinName [lshift args]
             set type [expr $type | 2]
        }
        -net -
        -n {
             set netName [lshift args]
             set type [expr $type | 4]
        }
        -only_set -
        -only {
             set show_only_set 1
        }
        -full_pin_name -
        -full {
             set full_pin_name 1
        }
        -return_string {
             set outputType {string}
        }
        -file {
             set outputType {file}
             set outputFilename [lshift args]
        }
        -append {
             set outputAppend 1
        }
        > {
             # Same as -file
             set outputType {file}
             set outputFilename [lshift args]
             set outputAppend 0
        }
        >> {
             # Same as -file & -append
             set outputType {file}
             set outputFilename [lshift args]
             set outputAppend 1
        }
        -q -
        -quiet {
              set msgLevel -1
        }
        -v -
        -verbose {
              set msgLevel 1
        }
        -h -
        -help {
              incr help
        }
        -indent {
             set indentLevel [lshift args]
        }
        -- {
          # Dummy
        }
        default {
              if {[string match "-*" $name]} {
                lappend output " -E- option '$name' is not a valid option."
                incr error
              } else {
                lappend output " -E- option '$name' is not a valid option."
                incr error
              }
        }
      }
    }
    
    if {$help} {
      set callerName [lindex [info level [expr [info level] -1]] 0]
      # <-- HELP
      lappend output [format {
    Usage: show_case_value
                [-cell|-c <name>]
                [-net|-n <name>]
                [-pin|-port|-p <name>]
                [-only_set|-only]
                [-full_pin_name|-full]
                [-return_string]
                [> <filename>|>> <filename>|-file <filename>][-append]
                [-quiet|-q]
                [-verbose|-v]
                [-help|-h]
                
    Description: Report case value(s) on a cell or pin.
    
    Example:
       show_case_value -cell Imega_cle_l_right_X1Y31_R0/Icle_cle_l_right_remap_X0Y24_R0/Icle_cle_l_right_ft_X0Y0_R0/Icle_cle_l_core_X0Y0_R0/Iff_all -only
       show_case_value -cell Imega_cle_l_right_X1Y31_R0/Icle_cle_l_right_remap_X0Y24_R0/Icle_cle_l_right_ft_X0Y0_R0/Icle_cle_l_core_X0Y0_R0/Iff_all > report.rpt
       show_case_value -file report.rpt -append -cell Imega_cle_l_right_X1Y31_R0/Icle_cle_l_right_remap_X0Y24_R0/Icle_cle_l_right_ft_X0Y0_R0/Icle_cle_l_core_X0Y0_R0/Iclk_optinv1
       show_case_value -only -pin Imega_cle_l_right_X1Y31_R0/Icle_cle_l_right_remap_X0Y24_R0/Icle_cle_l_right_ft_X0Y0_R0/Icle_cle_l_core_X0Y0_R0/Iclk_optinv1/*
  
  } ]
      # HELP -->
      return [output {stdout} $output - -]
    }
    
    switch $type {
      1 -
      2 -
      4 {
      }
      0 {
        lappend output " -E- No cell/pin/net name provided."
        incr error
      }
      default {
        lappend output " -E- Cannot use -pin/-cell/-net at the same time"
        incr error
      }
    }

    if {$error} {
      lappend output ""
      return [output $outputType $output $outputFilename $outputAppend]
    }
    
    if {$cellName != {}} {
      set cell [get_cells -quiet $cellName]
      if {$cell == {}} {
        lappend output " -E- No cell match '$cellName'"
        incr error
      } else {
        lappend output [format_string $indentLevel "%s" "\n"]
        lappend output [format_string $indentLevel "%s" "############################################################################################################"]
        lappend output [format_string $indentLevel "%s" "## CELL CASE VALUE"]
        lappend output [format_string $indentLevel "%s" "############################################################################################################"]
        lappend output [format_string $indentLevel "%s" "## CMD: show_case_value [regsub -all {(\-indent [0-9]+|\-return_string)} $commandLine {}]"]
        lappend output [format_string $indentLevel "%s" "############################################################################################################"]
        lappend output [format_string $indentLevel "%s" "## CELL: [format_cell_name $cellName 1]"]
        lappend output [format_string $indentLevel "%s" "############################################################################################################\n"]
#        set pins [get_pins -quiet -of_objects $cell -filter {pin_direction == in}]
        set pins [get_pins -quiet -of_objects $cell]
      }
    } elseif {$pinName != {}} {
#       set pin [get_pins -quiet $pinName]
      set pin [add_to_collection [get_pins -quiet $pinName] [get_ports -quiet $pinName] ]
      if {$pin == {}} {
        lappend output " -E- No pin/port match '$pinName'"
        incr error
      } else {
        lappend output [format_string $indentLevel "%s" "\n"]
        lappend output [format_string $indentLevel "%s" "############################################################################################################"]
        if {[get_attribute -quiet [index_collection $pin 0] object_class] == {pin}} {
          lappend output [format_string $indentLevel "%s" "## PIN CASE VALUE"]
        } else {
          lappend output [format_string $indentLevel "%s" "## PORT CASE VALUE"]
        }
#         lappend output [format_string $indentLevel "%s" "## PIN CASE VALUE"]
        lappend output [format_string $indentLevel "%s" "############################################################################################################"]
        lappend output [format_string $indentLevel "%s" "## CMD: show_case_value [regsub -all {(\-indent [0-9]+|\-return_string)} $commandLine {}]"]
        lappend output [format_string $indentLevel "%s" "############################################################################################################"]
        if {[get_attribute -quiet [index_collection $pin 0] object_class] == {pin}} {
          lappend output [format_string $indentLevel "%s" "## PIN: [format_pin_name $pinName 1]"]
        } else {
          lappend output [format_string $indentLevel "%s" "## PORT: [format_pin_name $pinName 1]"]
        }
#         lappend output [format_string $indentLevel "%s" "## PIN: [format_pin_name $pinName 1]"]
        lappend output [format_string $indentLevel "%s" "############################################################################################################\n"]
        set pins $pin
      }
    } elseif {$netName != {}} {
      set net [get_nets -quiet $netName]
      if {$net == {}} {
        lappend output " -E- No net match '$netName'"
        incr error
      } else {
        lappend output [format_string $indentLevel "%s" "\n"]
        lappend output [format_string $indentLevel "%s" "############################################################################################################"]
        lappend output [format_string $indentLevel "%s" "## NET CASE VALUE"]
        lappend output [format_string $indentLevel "%s" "############################################################################################################"]
        lappend output [format_string $indentLevel "%s" "## CMD: show_case_value [regsub -all {(\-indent [0-9]+|\-return_string)} $commandLine {}]"]
        lappend output [format_string $indentLevel "%s" "############################################################################################################"]
        lappend output [format_string $indentLevel "%s" "## NET: $netName"]
        lappend output [format_string $indentLevel "%s" "############################################################################################################\n"]
#         set pins [get_pins -quiet -leaf -of_objects $net -filter {pin_direction == in}]
        set pins [get_pins -quiet -leaf -of_objects $net]
      }
    } else {
      lappend output " -E- No cell/pin/net name provided."
      incr error
    }

    if {$error} {
      lappend output ""
      return [output $outputType $output $outputFilename $outputAppend]
    }

    if {$msgLevel >= 1} {
      lappend output " -I- Starting show_case_value on [clock format [clock seconds]]"
      lappend output " -I- Arguments: $commandLine"
    }
    
    if {[sizeof_collection $pins] == 0} {
      lappend output "  Error - Cell not found"
      lappend output ""
      return [output $outputType $output $outputFilename $outputAppend]
    }
    set tbl [Table::Create]
    $tbl indent $indentLevel
    $tbl header [list "pin_name" "direction" "ref_name" "case_value" "user_case_value" "net_name" ]
    set count 0
    foreach_in_collection pin $pins {
      if {[lsearch [list gnd vccint] [get_attribute -quiet $pin lib_pin_name]] != -1} {
        # Skip gnd/vccint pins
        # GoldTime returns those pins but PrimeTime does not
        continue
      }
      set pin_name [format_pin_name $pin $full_pin_name]; # Short or full hierarchical pin name
      set direction [get_attribute -quiet $pin direction]
      set ref_name [format_ref_name [get_cells -quiet -of_objects $pin] ]
      set net_name [get_object_name [all_connected $pin]]
      if {[get_attribute -quiet $pin object_class] == {pin}} {
        set case_value [get_attribute -quiet [get_pin $pin] case_value]
        set user_case_value [get_attribute -quiet [get_pin $pin] user_case_value]
      } else {
        set case_value [get_attribute -quiet [get_port $pin] case_value]
        set user_case_value [get_attribute -quiet [get_port $pin] user_case_value]
      }
#       set case_value [get_attribute -quiet [get_pin $pin] case_value]
#       set user_case_value [get_attribute -quiet [get_pin $pin] user_case_value]
      # GoldTime returns 'undef' but PrimeTime returns '' when no case value is set on a pin
      if {($case_value == {}) || ($case_value == {undef})} { set case_value - }
      if {($user_case_value == {}) || ($user_case_value == {undef})} { set user_case_value - }
      if {$show_only_set && ($case_value == {-}) && ($user_case_value == {-})} {
        # Skip pins that have not case value
        continue
      }
      $tbl addrow [list $pin_name $direction $ref_name $case_value $user_case_value $net_name ]
      incr count
    }
    lappend output [$tbl print]
    lappend output ""
    lappend output [format_string $indentLevel "Number of Pin(s): %d" $count ]
    lappend output ""

    if {$msgLevel >= 1} {
      lappend output " -I- Ending show_case_value on [clock format [clock seconds]]"
    }
  
    return [output $outputType $output $outputFilename $outputAppend]
  }


  #------------------------------------------------------------------------
  # show_arcs
  #------------------------------------------------------------------------
  # Report information about timing arcs
  #------------------------------------------------------------------------
  proc show_arcs { args } {

    set staToolName {pt}
    if {[info exists ::staToolName]} {
      set staToolName $::staToolName
    }

    #-------------------------------------------------------
    # Process command line arguments
    #-------------------------------------------------------
    set from {}
    set to {}
    set full_pin_name 0
    set error 0
    set help 0
    set indentLevel 0
    set msgLevel 0
    set output [list]
    set outputType {stdout}
    set outputFilename {}
    set outputAppend 0
    set commandLine $args
    set getTimingArcsCmdLine [list]
    if {[llength $args] == 0} { incr help }
    # Add dummy argument to the command line so that "> file" & ">> file" 
    # are processed as a command line arguments
    lappend args {--}
    while {[llength $args]} {
      set name [lshift args]
      switch -exact -- $name {
        -from -
        -f {
             set from [lshift args]
             set getTimingArcsCmdLine [concat $getTimingArcsCmdLine -from $from]
        }
        -to -
        -t {
             set to [lshift args]
             set getTimingArcsCmdLine [concat $getTimingArcsCmdLine -to $to]
        }
        -full_pin_name -
        -full {
             set full_pin_name 1
        }
        -return_string {
             set outputType {string}
        }
        -file {
             set outputType {file}
             set outputFilename [lshift args]
        }
        -append {
             set outputAppend 1
        }
        > {
             # Same as -file
             set outputType {file}
             set outputFilename [lshift args]
             set outputAppend 0
        }
        >> {
             # Same as -file & -append
             set outputType {file}
             set outputFilename [lshift args]
             set outputAppend 1
        }
        -q -
        -quiet {
              set msgLevel -1
        }
        -v -
        -verbose {
              set msgLevel 1
        }
        -h -
        -help {
              incr help
        }
        -indent {
             set indentLevel [lshift args]
        }
        -- {
          # Dummy
        }
        default {
              if {[string match "-*" $name]} {
                lappend output " -E- option '$name' is not a valid option."
                incr error
              } else {
                lappend output " -E- option '$name' is not a valid option."
                incr error
              }
        }
      }
    }
    
    if {$help} {
      set callerName [lindex [info level [expr [info level] -1]] 0]
      # <-- HELP
      lappend output [format {
    Usage: show_arcs
                [-from|-f <pin_name>]
                [-to|-t <pin_name>]
                [-full_pin_name|-full]
                [-return_string]
                [> <filename>|>> <filename>|-file <filename>][-append]
                [-quiet|-q]
                [-verbose|-v]
                [-help|-h]
                
    Description: Report timing arcs from/to pins.
    
    Example:
       show_arcs -from Imega_cle_l_right_X1Y31_R0/Icle_cle_l_right_remap_X0Y24_R0/Icle_cle_l_right_ft_X0Y0_R0/Icle_cle_l_core_X0Y0_R0/Iclk_optinv1/clk_b
       show_arcs -from Imega_cle_l_right_X1Y31_R0/Icle_cle_l_right_remap_X0Y24_R0/Icle_cle_l_right_ft_X0Y0_R0/Icle_cle_l_core_X0Y0_R0/Iff_all/clk1_b \ 
                 -to Imega_cle_l_right_X1Y31_R0/Icle_cle_l_right_remap_X0Y24_R0/Icle_cle_l_right_ft_X0Y0_R0/Icle_cle_l_core_X0Y0_R0/Iff_all/AQ
       show_arcs -to Imega_cle_l_right_X1Y31_R0/Icle_cle_l_right_remap_X0Y24_R0/Icle_cle_l_right_ft_X0Y0_R0/Icle_cle_l_core_X0Y0_R0/Iff_all/AQ
       show_arcs -to Imega_cle_l_right_X1Y31_R0/Icle_cle_l_right_remap_X0Y24_R0/Icle_cle_l_right_ft_X0Y0_R0/Icle_cle_l_core_X0Y0_R0/Iff_all/AQ -full
  
  } ]
      # HELP -->
      return [output {stdout} $output - -]
    }

    if {($from == {}) && ($to == {})} {
      lappend output " -E- No -from/-to specified."
      incr error
    }
  
    if {$error} {
      lappend output ""
      return [output $outputType $output $outputFilename $outputAppend]
    }

    if {$msgLevel >= 1} {
      lappend output " -I- Starting show_arcs on [clock format [clock seconds]]"
      lappend output " -I- Arguments: $commandLine"
      lappend output " -I- Arguments (get_timing_arcs): $getTimingArcsCmdLine"
    }
    
    lappend output [format_string $indentLevel "%s" "############################################################################################################"]
    lappend output [format_string $indentLevel "%s" "## TIMING ARCS"]
    lappend output [format_string $indentLevel "%s" "############################################################################################################"]
    lappend output [format_string $indentLevel "%s" "## CMD: show_arcs [regsub -all {(\-indent [0-9]+|\-return_string)} $commandLine {}]"]
    lappend output [format_string $indentLevel "%s" "############################################################################################################"]
    if {$from != {}} {
      lappend output [format_string $indentLevel "%s" "## From: [format_pin_name $from 1]"]
    }
    if {$to != {}} {
      lappend output [format_string $indentLevel "%s" "## To  : [format_pin_name $to 1]"]
    }
    lappend output [format_string $indentLevel "%s" "############################################################################################################\n"]

    set arcs [eval [concat get_timing_arcs $getTimingArcsCmdLine ]]
    set tbl [Table::Create]
    $tbl indent $indentLevel
    switch $staToolName {
      pt {
        $tbl header [list "from_pin" "to_pin" "is_cellarc" "sense" "is_disabled" "is_user_disabled" "mode"]
      }
      gt {
        # The 'mode' attribute does not exist in GoldTime, so replace it with 'lib_cell_arc'
        $tbl header [list "from_pin" "to_pin" "is_cellarc" "sense" "is_disabled" "is_user_disabled" "lib_cell_arc"]
      }
      default {
      }
    }
    set count 0
    set countEnabled 0
    foreach_in_collection arc $arcs {
      set is_cellarc [get_attribute -quiet $arc is_cellarc]
      set fpin [get_attribute -quiet $arc from_pin]
      set tpin [get_attribute -quiet $arc to_pin]
      set rise [get_attribute -quiet $arc delay_max_rise]
      set fall [get_attribute -quiet $arc delay_max_fall]
      set sense [get_attribute -quiet $arc sense]
      set is_disabled [get_attribute -quiet $arc is_disabled]
      set is_user_disabled [get_attribute -quiet $arc is_user_disabled]
      set from_pin_name [format_pin_name $fpin $full_pin_name]; # Short or full hierarchical pin name
      set to_pin_name [format_pin_name $tpin $full_pin_name]; # Short or full hierarchical pin name
      switch $staToolName {
        pt {
          set mode [get_attribute -quiet $arc mode]
          if {$mode == {}} { set mode - }
        }
        gt {
          # The 'mode' attribute does not exist in GoldTime, so replace it with 'lib_cell_arc'
          if {[get_attribute -quiet $arc lib_cell_arc] != {}} {
            # lib_cell_arc_type provides the information whether the path is combinational, ...
            set lib_cell_arc_type [get_attribute -quiet [index_collection [get_attribute -quiet $arc lib_cell_arc] 0] type]
            if {$lib_cell_arc_type == {}} { set lib_cell_arc_type {??} }
            if {[sizeof_collection [get_attribute -quiet $arc lib_cell_arc]] > 1} {
              if {$msgLevel >= 1} {
                set lib_cell_arc "$lib_cell_arc_type ([get_object_name [index_collection [get_attribute $arc lib_cell_arc] 0]] (1/[sizeof_collection [get_attribute $arc lib_cell_arc] ])"
              } else {
                set lib_cell_arc "$lib_cell_arc_type (1/[sizeof_collection [get_attribute $arc lib_cell_arc] ])"
              }
            } else {
              if {$msgLevel >= 1} {
                set lib_cell_arc "$lib_cell_arc_type ([get_object_name [index_collection [get_attribute $arc lib_cell_arc] 0]])"
              } else {
                set lib_cell_arc "$lib_cell_arc_type"
              }
            }
          } else {
            # A timing arc on a net does not have a lib_cell_arc
            set lib_cell_arc {-}
          }
        }
        default {
        }
      }
      if {$is_disabled == {false}} {
        # Count the number of arcs that are enabled
        incr countEnabled
      }
      if {$sense == {}} { set sense - }
      if {$is_disabled == {}} { set is_disabled - }
      if {$is_user_disabled == {}} { set is_user_disabled - }
      switch $staToolName {
        pt {
          $tbl addrow [list $from_pin_name $to_pin_name $is_cellarc $sense $is_disabled $is_user_disabled $mode]
        }
        gt {
          $tbl addrow [list $from_pin_name $to_pin_name $is_cellarc $sense $is_disabled $is_user_disabled $lib_cell_arc]
        }
        default {
        }
      }
      incr count
    }
    lappend output [$tbl print]
    lappend output ""
    lappend output [format_string $indentLevel "Number of Arc(s): %d" $count ]
    lappend output [format_string $indentLevel "Number of Enabled Arc(s): %d" $countEnabled ]
    if {$countEnabled == 0} {
      lappend output ""
      if {$count == 0} {
        lappend output [format "%s !!! WARNING: NO TIMING ARC FOUND !!!" [indent $indentLevel] ]
      } else {
        lappend output [format "%s !!! WARNING: NO ENABLED TIMING ARC FOUND !!!" [indent $indentLevel] ]
      }
    }
    lappend output ""

    if {$msgLevel >= 1} {
      lappend output " -I- Ending show_arcs on [clock format [clock seconds]]"
    }
  
    return [output $outputType $output $outputFilename $outputAppend]
  }


  #------------------------------------------------------------------------
  # show_info
  #------------------------------------------------------------------------
  # Report information on a net/cell/pin
  #------------------------------------------------------------------------
  proc show_info { args } {

    set staToolName {pt}
    if {[info exists ::staToolName]} {
      set staToolName $::staToolName
    }

    #-------------------------------------------------------
    # Process command line arguments
    #-------------------------------------------------------
    set cellName {}
    set pinName {}
    set netName {}
    set type 0
    set error 0
    set help 0
    set indentLevel 0
    set msgLevel 0
    set output [list]
    set outputType {stdout}
    set outputFilename {}
    set outputAppend 0
    set commandLine $args
    if {[llength $args] == 0} { incr help }
    # Add dummy argument to the command line so that "> file" & ">> file" 
    # are processed as a command line arguments
    lappend args {--}
    while {[llength $args]} {
      set name [lshift args]
      switch -exact -- $name {
        -cell -
        -c {
             set cellName [lshift args]
             set type [expr $type | 1]
        }
        -port -
        -pin -
        -p {
             set pinName [lshift args]
             set type [expr $type | 2]
        }
        -net -
        -n {
             set netName [lshift args]
             set type [expr $type | 4]
        }
        -return_string {
             set outputType {string}
        }
        -file {
             set outputType {file}
             set outputFilename [lshift args]
        }
        -append {
             set outputAppend 1
        }
        > {
             # Same as -file
             set outputType {file}
             set outputFilename [lshift args]
             set outputAppend 0
        }
        >> {
             # Same as -file & -append
             set outputType {file}
             set outputFilename [lshift args]
             set outputAppend 1
        }
        -q -
        -quiet {
              set msgLevel -1
        }
        -v -
        -verbose {
              set msgLevel 1
        }
        -h -
        -help {
              incr help
        }
        -indent {
             set indentLevel [lshift args]
        }
        -- {
          # Dummy
        }
        default {
              if {[string match "-*" $name]} {
                lappend output " -E- option '$name' is not a valid option."
                incr error
              } else {
                lappend output " -E- option '$name' is not a valid option."
                incr error
              }
        }
      }
    }
    
    if {$help} {
      set callerName [lindex [info level [expr [info level] -1]] 0]
      # <-- HELP
      lappend output [format {
    Usage: show_info
                [-cell|-c <name>]
                [-net|-n <name>]
                [-pin|-port|-p <name>]
                [-return_string]
                [> <filename>|>> <filename>|-file <filename>][-append]
                [-quiet|-q]
                [-verbose|-v]
                [-help|-h]
                
    Description: Report information on a cell, pin or net.
    
    Example:
       show_info -pin Imega_cle_l_right_X1Y31_R0/Icle_cle_l_right_remap_X0Y24_R0/Icle_cle_l_right_ft_X0Y0_R0/Icle_cle_l_core_X0Y0_R0/Iclk_optinv1/*
       show_info -cell Imega_cle_l_right_X1Y31_R0/Icle_cle_l_right_remap_X0Y24_R0/Icle_cle_l_right_ft_X0Y0_R0/Icle_cle_l_core_X0Y0_R0/Iclk_optinv1
       show_info -net Imega_cle_l_right_X1Y31_R0/Icle_cle_l_right_remap_X0Y24_R0/Icle_cle_l_right_ft_X0Y0_R0/Icle_cle_l_core_X0Y0_R0/clk1_b

  } ]
      # HELP -->
      return [output {stdout} $output - -]
    }
    
    switch $type {
      1 -
      2 -
      4 {
      }
      0 {
        lappend output " -E- No cell/pin/net name provided."
        incr error
      }
      default {
        lappend output " -E- Cannot use -pin/-cell/-net at the same time"
        incr error
      }
    }
    
    if {$error} {
      lappend output ""
      return [output $outputType $output $outputFilename $outputAppend]
    }
    
    if {$cellName != {}} {
      set cell [get_cells -quiet $cellName]
      if {$cell == {}} {
        lappend output " -E- No cell match '$cellName'"
        incr error
      }
    } elseif {$pinName != {}} {
#       set pin [get_pins -quiet $pinName]
      set pin [add_to_collection [get_pins -quiet $pinName] [get_ports -quiet $pinName] ]
      if {$pin == {}} {
        lappend output " -E- No pin/port match '$pinName'"
        incr error
      }
    } elseif {$netName != {}} {
      set net [get_nets -quiet $netName]
      if {$net == {}} {
        lappend output " -E- No net match '$netName'"
        incr error
      }
    } else {
      lappend output " -E- No cell/pin/port/net name provided."
      incr error
    }
  
    if {$error} {
      lappend output ""
      return [output $outputType $output $outputFilename $outputAppend]
    }

    if {$msgLevel >= 1} {
      lappend output " -I- Starting show_info on [clock format [clock seconds]]"
      lappend output " -I- Arguments: $commandLine"
    }
    
    switch $type {
      1 {
        # Cell
        set info [show_cell_info $cellName $indentLevel]
        set output [concat $output $info]
      }
      2 {
        # Pin/Port
        set info [show_pin_info $pinName $indentLevel]
        set output [concat $output $info]
      }
      4 {
        # Net
        set info {}
        foreach_in_collection net [get_nets -quiet $netName] {
          set info [concat $info [show_net_info [get_object_name $net] $indentLevel]]
          foreach_in_collection pin [all_connected -leaf $net] {
            set info [concat $info [show_pin_info [get_object_name $pin] [expr $indentLevel+1] ] ]
            lappend info [show_case_value -pin [get_object_name $pin] -return_string -indent [expr $indentLevel+2] ]
          }
        }
        set output [concat $output $info]
     }
    }

    if {$msgLevel >= 1} {
      lappend output " -I- Ending show_info on [clock format [clock seconds]]"
    }
  
    return [output $outputType $output $outputFilename $outputAppend]
  }


  #------------------------------------------------------------------------
  # show_cell_info
  #------------------------------------------------------------------------
  # Report information on a cell
  #------------------------------------------------------------------------
  proc show_cell_info { name {level 0} } {
    set output [list]
    set cells [get_cells -quiet $name]
    if {$cells == {}} {
      lappend output " -E- No cell match '$name'"
      return $output
    }
    set staToolName {pt}
    if {[info exists ::staToolName]} {
      set staToolName $::staToolName
    }
    lappend output [format_string $level "%s" "############################################################################################################"]
    lappend output [format_string $level "%s" "## CELL INFO"]
    lappend output [format_string $level "%s" "############################################################################################################"]
    lappend output [format_string $level "%s" "## CMD: show_info [regsub -all {(\-indent [0-9]+|\-return_string)} [uplevel 1 [list subst {$commandLine}]] {}]"]
    lappend output [format_string $level "%s" "############################################################################################################"]
    lappend output [format_string $level "%s" "## CELL: [format_cell_name $name 1]"]
    lappend output [format_string $level "%s" "############################################################################################################\n"]
    set tbl [Table::Create]
    $tbl indent $level
    switch $staToolName {
      pt {
        $tbl header [list "name" "ref_name" "# pins" "disable_timing" "is_combinational" "is_sequential" "is_mux" "is_memory_cell" "is_integrated_clock_gating_cell" "is_hierarchical" "is_clock_gating_check" "is_clock_network_cell" "is_rise_edge_triggered" "is_fall_edge_triggered" "is_positive_level_sensitive" "is_negative_level_sensitive" ]
      }
      gt {
        $tbl header [list "name" "ref_name" "# pins" "disable_timing" "is_combinational" "is_sequential" "is_memory_cell" "is_integrated_clock_gating_cell" "is_hierarchical" "is_rise_edge_triggered" "is_fall_edge_triggered" "is_positive_level_sensitive" "is_negative_level_sensitive" ]

      }
      default {
      }
    }
    foreach_in_collection cell $cells {
      set cell_name [format_cell_name $cell 0]; # Short cell name
      set ref_name [format_ref_name $cell]
      set number_of_pins [get_attribute -quiet $cell number_of_pins]
      set is_combinational [get_attribute -quiet $cell is_combinational]
      set disable_timing [get_attribute -quiet $cell disable_timing]
      set is_clock_gating_check [get_attribute -quiet $cell is_clock_gating_check]
      set is_clock_network_cell [get_attribute -quiet $cell is_clock_network_cell]
      set is_fall_edge_triggered [get_attribute -quiet $cell is_fall_edge_triggered]
      set is_hierarchical [get_attribute -quiet $cell is_hierarchical]
      set is_integrated_clock_gating_cell [get_attribute -quiet $cell is_integrated_clock_gating_cell]
      set is_memory_cell [get_attribute -quiet $cell is_memory_cell]
      set is_mux [get_attribute -quiet $cell is_mux]
      set is_negative_level_sensitive [get_attribute -quiet $cell is_negative_level_sensitive]
      set is_positive_level_sensitive [get_attribute -quiet $cell is_positive_level_sensitive]
      set is_sequential [get_attribute -quiet $cell is_sequential]
      set is_rise_edge_triggered [get_attribute -quiet $cell is_rise_edge_triggered]
      if {$ref_name == {}} { set ref_name - }
      if {$number_of_pins == {}} { set number_of_pins - }
      if {$is_combinational == {}} { set is_combinational - }
      switch $staToolName {
        pt {
          $tbl addrow [list $cell_name $ref_name $number_of_pins $disable_timing $is_combinational $is_sequential $is_mux $is_memory_cell $is_integrated_clock_gating_cell $is_hierarchical $is_clock_gating_check $is_clock_network_cell $is_rise_edge_triggered $is_fall_edge_triggered $is_positive_level_sensitive $is_negative_level_sensitive ]
        }
        gt {
          $tbl addrow [list $cell_name $ref_name $number_of_pins $disable_timing $is_combinational $is_sequential $is_memory_cell $is_integrated_clock_gating_cell $is_hierarchical $is_rise_edge_triggered $is_fall_edge_triggered $is_positive_level_sensitive $is_negative_level_sensitive ]
        }
        default {
        }
      }
    }
    lappend output [$tbl print]
    lappend output ""
    return $output
  }
  

  #------------------------------------------------------------------------
  # show_pin_info
  #------------------------------------------------------------------------
  # Report information on a pin
  #------------------------------------------------------------------------
  proc show_pin_info { name {level 0} } {
    set output [list]
#     set pins [get_pins -quiet $name]
    set pins [add_to_collection [get_pins -quiet $name] [get_ports -quiet $name] ]
    if {$pins == {}} {
      lappend output " -E- No pin/port match '$name'"
      return $output
    }
    set staToolName {pt}
    if {[info exists ::staToolName]} {
      set staToolName $::staToolName
    }
    lappend output [format_string $level "%s" "############################################################################################################"]
    if {[get_attribute -quiet [index_collection $pins 0] object_class] == {pin}} {
      lappend output [format_string $level "%s" "## PIN INFO"]
    } else {
      lappend output [format_string $level "%s" "## PORT INFO"]
    }
#     lappend output [format_string $level "%s" "## PIN INFO"]
    lappend output [format_string $level "%s" "############################################################################################################"]
    lappend output [format_string $level "%s" "## CMD: show_info [regsub -all {(\-indent [0-9]+|\-return_string)} [uplevel 1 [list subst {$commandLine}]] {}]"]
    lappend output [format_string $level "%s" "############################################################################################################"]
    if {[get_attribute -quiet [index_collection $pins 0] object_class] == {pin}} {
      lappend output [format_string $level "%s" "## PIN: [format_pin_name $name 1]"]
    } else {
      lappend output [format_string $level "%s" "## PORT: [format_pin_name $name 1]"]
    }
#     lappend output [format_string $level "%s" "## PIN: [format_pin_name $name 1]"]
    if {[sizeof_collection $pins] == 1} {
      # Only show the connected cell name and net name when there is a single pin
      lappend output [format_string $level "%s" "############################################################################################################"]
      catch { lappend output [format_string $level "%s" "## CELL: [format_cell_name [get_object_name [get_cells -quiet -of_objects $pins]] 1]"] }
      catch { lappend output [format_string $level "%s" "## NET : [get_object_name [all_connected $pins]]"] }
#       catch { lappend output [format "%s %s" [indent $level] "## CELL: [format_cell_name [get_object_name [get_cells -quiet -of_objects $pins]] 1]"] }
#       catch { lappend output [format "%s %s" [indent $level] "## NET : [get_object_name [all_connected $pins]]"] }
    }
    lappend output [format_string $level "%s" "############################################################################################################\n"]
    set tbl [Table::Create]
    $tbl indent $level
    switch $staToolName {
      pt {
        $tbl header [list "name" "direction" "ref_name" "disable_timing" "case_value" "user_case_value" "clocks" "is_clock_pin" "is_data_pin" "is_async_pin" "is_clear_pin" "is_preset_pin" "is_hierarchical" "is_interface_logic_pin" "is_mux_select_pin" "is_clock_gating_pin" "is_clock_used_as_clock" "is_clock_used_as_data" "is_fall_edge_triggered_clock_pin" "is_fall_edge_triggered_data_pin" "is_negative_level_sensitive_clock_pin" "is_negative_level_sensitive_data_pin" "is_positive_level_sensitive_clock_pin" "is_positive_level_sensitive_data_pin" "max_fall_slack" "max_rise_slack" "min_fall_slack" "min_rise_slack" "arrival_window" ]
      }
      gt {
        $tbl header [list "name" "direction" "ref_name" "disable_timing" "case_value" "user_case_value" "clocks" "is_clock_pin" "is_data_pin" "is_async_pin" "is_clear_pin" "is_preset_pin" "is_hierarchical" "is_interface_logic" "is_clock_gating_pin" "is_clock_used_as_clock" "is_clock_used_as_data" "is_fall_edge_triggered_clock_pin" "is_fall_edge_triggered_data_pin" "is_negative_level_sensitive_clock_pin" "is_negative_level_sensitive_data_pin" "is_positive_level_sensitive_clock_pin" "is_positive_level_sensitive_data_pin" "max_fall_slack" "max_rise_slack" "min_fall_slack" "min_rise_slack" "arrival_window" ]
      }
      default {
      }
    }
    set count 0
    set countEnabled 0
    foreach_in_collection pin $pins {
      if {[lsearch [list gnd vccint] [get_attribute -quiet $pin lib_pin_name]] != -1} {
        # Skip gnd/vccint pins
        # GoldTime returns those pins but PrimeTime does not
        continue
      }
      set pin_name [format_pin_name $pin 0]; # Short pin name
      set ref_name [format_ref_name [get_cells -quiet -of_objects $pin]]
      set clocks {}
      foreach_in_collection clock [get_attribute -quiet $pin clocks] {
        lappend clocks [get_object_name $clock]
      }
      set case_value [get_attribute -quiet $pin case_value]
      set user_case_value [get_attribute -quiet $pin user_case_value]
      set arrival_window [get_attribute -quiet $pin arrival_window]
      set direction [get_attribute -quiet $pin direction]
      set disable_timing [get_attribute -quiet $pin disable_timing]
      set is_async_pin [get_attribute -quiet $pin is_async_pin]
      set is_clear_pin [get_attribute -quiet $pin is_clear_pin]
      set is_clock_gating_pin [get_attribute -quiet $pin is_clock_gating_pin]
      set is_clock_pin [get_attribute -quiet $pin is_clock_pin]
      set is_clock_used_as_clock [get_attribute -quiet $pin is_clock_used_as_clock]
      set is_clock_used_as_data [get_attribute -quiet $pin is_clock_used_as_data]
      set is_data_pin [get_attribute -quiet $pin is_data_pin]
      set is_fall_edge_triggered_clock_pin [get_attribute -quiet $pin is_fall_edge_triggered_clock_pin]
      set is_fall_edge_triggered_data_pin [get_attribute -quiet $pin is_fall_edge_triggered_data_pin]
      set is_hierarchical [get_attribute -quiet $pin is_hierarchical]
      set is_negative_level_sensitive_clock_pin [get_attribute -quiet $pin is_negative_level_sensitive_clock_pin]
      set is_negative_level_sensitive_data_pin [get_attribute -quiet $pin is_negative_level_sensitive_data_pin]
      set is_positive_level_sensitive_clock_pin [get_attribute -quiet $pin is_positive_level_sensitive_clock_pin]
      set is_positive_level_sensitive_data_pin [get_attribute -quiet $pin is_positive_level_sensitive_data_pin]
      set is_preset_pin [get_attribute -quiet $pin is_preset_pin]
      set max_fall_slack [get_attribute -quiet $pin max_fall_slack]
      set max_rise_slack [get_attribute -quiet $pin max_rise_slack]
      set min_fall_slack [get_attribute -quiet $pin min_fall_slack]
      set min_rise_slack [get_attribute -quiet $pin min_rise_slack]
      switch $staToolName {
        pt {
          set is_mux_select_pin [get_attribute -quiet $pin is_mux_select_pin]
          set is_interface_logic_pin [get_attribute -quiet $pin is_interface_logic_pin]
        }
        gt {
          # The 'is_interface_logic_pin' attribute does not exist in GoldTime, so replace it with 'is_interface_logic'
          set is_interface_logic [get_attribute -quiet $pin is_interface_logic]
        }
        default {
        }
      }
      if {$disable_timing == {false}} {
        # Count the number of pins that are timing enabled
        incr countEnabled
      }
      # GoldTime returns 'undef' but PrimeTime returns '' when no case value is set on a pin
      if {($case_value == {}) || ($case_value == {undef})} { set case_value - }
      if {($user_case_value == {}) || ($user_case_value == {undef})} { set user_case_value - }
      switch $staToolName {
        pt {
          $tbl addrow [list $pin_name $direction $ref_name $disable_timing $case_value $user_case_value $clocks $is_clock_pin $is_data_pin $is_async_pin $is_clear_pin $is_preset_pin $is_hierarchical $is_interface_logic_pin $is_mux_select_pin $is_clock_gating_pin $is_clock_used_as_clock $is_clock_used_as_data $is_fall_edge_triggered_clock_pin $is_fall_edge_triggered_data_pin $is_negative_level_sensitive_clock_pin $is_negative_level_sensitive_data_pin $is_positive_level_sensitive_clock_pin $is_positive_level_sensitive_data_pin $max_fall_slack $max_rise_slack $min_fall_slack $min_rise_slack $arrival_window ]
        }
        gt {
          $tbl addrow [list $pin_name $direction $ref_name $disable_timing $case_value $user_case_value $clocks $is_clock_pin $is_data_pin $is_async_pin $is_clear_pin $is_preset_pin $is_hierarchical $is_interface_logic $is_clock_gating_pin $is_clock_used_as_clock $is_clock_used_as_data $is_fall_edge_triggered_clock_pin $is_fall_edge_triggered_data_pin $is_negative_level_sensitive_clock_pin $is_negative_level_sensitive_data_pin $is_positive_level_sensitive_clock_pin $is_positive_level_sensitive_data_pin $max_fall_slack $max_rise_slack $min_fall_slack $min_rise_slack $arrival_window ]
        }
        default {
        }
      }
      incr count
    }
    lappend output [$tbl print]
    if {$countEnabled == 0} {
      lappend output ""
      if {$count == 0} {
        lappend output [format "%s !!! WARNING: NO PIN FOUND !!!" [indent $level] ]
      } else {
        lappend output [format "%s !!! WARNING: NO TIMING ENABLED PIN FOUND !!!" [indent $level] ]
      }
    }
    lappend output ""
    return $output
  }
  

  #------------------------------------------------------------------------
  # show_net_info
  #------------------------------------------------------------------------
  # Report information on a net
  #------------------------------------------------------------------------
  proc show_net_info { name {level 0} } {
    set output [list]
    set nets [get_nets -quiet $name]
    if {$nets == {}} {
      lappend output " -E- No net match '$name'"
      return $output
    }
    set staToolName {pt}
    if {[info exists ::staToolName]} {
      set staToolName $::staToolName
    }
    lappend output [format_string $level "%s" "############################################################################################################"]
    lappend output [format_string $level "%s" "## NET INFO"]
    lappend output [format_string $level "%s" "############################################################################################################"]
    lappend output [format_string $level "%s" "## CMD: show_info [regsub -all {(\-indent [0-9]+|\-return_string)} [uplevel 1 [list subst {$commandLine}]] {}]"]
    lappend output [format_string $level "%s" "############################################################################################################"]
    lappend output [format_string $level "%s" "## NET: $name"]
    lappend output [format_string $level "%s" "############################################################################################################\n"]
    set tbl [Table::Create]
    $tbl indent $level
    $tbl header [list "name" "#Pins" "case_value" "user_case_value" ]
    foreach_in_collection net $nets {
      set net_name [lindex [split [get_attribute $net full_name] /] end]
#       set pins [get_pins -quiet -of_objects $net]
      set pins [add_to_collection [get_pins -quiet -of_objects $net] [get_ports -quiet -of_objects $net] ]
      set case_value [get_attribute -quiet $net case_value]
      set user_case_value [get_attribute -quiet $net user_case_value]
      # GoldTime returns 'undef' but PrimeTime returns '' when no case value is set on a pin
      if {($case_value == {}) || ($case_value == {undef})} { set case_value - }
      if {($user_case_value == {}) || ($user_case_value == {undef})} { set user_case_value - }
       $tbl addrow [list $net_name [sizeof_collection $pins] $case_value $user_case_value ]
    }
    lappend output [$tbl print]
    lappend output ""
    return $output
  }


  #------------------------------------------------------------------------
  # analyze_path
  #------------------------------------------------------------------------
  # Report information about a path defined through a list of pins
  #------------------------------------------------------------------------
  proc analyze_path { args } {

    set staToolName {pt}
    if {[info exists ::staToolName]} {
      set staToolName $::staToolName
    }

    #-------------------------------------------------------
    # Process command line arguments
    #-------------------------------------------------------
    set skip_hier_pins 0
    set show_details 0
    set allPins {}
    set report_timing_cmd {}
    set report_timing_path_num 0
    set error 0
    set help 0
    set indentLevel 0
    set msgLevel 0
    set output [list]
    set outputType {stdout}
    set outputFilename {}
    set outputAppend 0
    set commandLine $args
    set getTimingArcsCmdLine [list]
    if {[llength $args] == 0} { incr help }
    # Add dummy argument to the command line so that "> file" & ">> file" 
    # are processed as a command line arguments
    lappend args {--}
    while {[llength $args]} {
      set name [lshift args]
      switch -glob -- $name {
        -*_from -
        -*_f -
        -from -
        -f -
        -*_through -
        -*_thro -
        -*_thu -
        -through -
        -thro -
        -thu -
        -*_to -
        -*_t -
        -to -
        -t {
             set value [lshift args]
             if {![regexp {^_sel} $value]} {
               # Could be a list of pins, so iterate.
               foreach elm $value {
                 lappend allPins $elm
               }
             } else {
               foreach_in_collection elm $value {
                 lappend allPins [get_object_name $elm]
               }
             }
        }
        -delay_type -
        -group {
             # Skip those command line arguments
             set foo [lshift args]
        }
        -no_hierarchical_pins -
        -no_hierarchical_pin -
        -no_hier_pins -
        -no_hier_pin -
        -skip_hier_pins -
        -skip_hier_pin -
        -skip {
             set skip_hier_pins 1
        }
        -details -
        -detail {
             set show_details 1
        }
        -paths -
        -path {
             # Command line for report_timing command
             set report_timing_cmd [lshift args]
        }
        -npaths -
        -npath {
             # When using -path option, multiple paths can be returned (the returned
             # list is a list of paths).
             # The -npath option select the path number to be used for analyze_path.
             set report_timing_path_num [lshift args]
        }
        -return_string {
             set outputType {string}
        }
        -file {
             set outputType {file}
             set outputFilename [lshift args]
        }
        -append {
             set outputAppend 1
        }
        > {
             # Same as -file
             set outputType {file}
             set outputFilename [lshift args]
             set outputAppend 0
        }
        >> {
             # Same as -file & -append
             set outputType {file}
             set outputFilename [lshift args]
             set outputAppend 1
        }
        -q -
        -quiet {
              set msgLevel -1
        }
        -v -
        -verbose {
              set msgLevel 1
        }
        -h -
        -help {
              incr help
        }
        -indent {
             set indentLevel [lshift args]
        }
        -- {
          # Dummy
        }
        default {
              if {[string match "-*" $name]} {
                lappend output " -E- option '$name' is not a valid option."
                incr error
              } else {
                lappend output " -E- option '$name' is not a valid option."
                incr error
              }
        }
      }
    }
    
    if {$help} {
      set callerName [lindex [info level [expr [info level] -1]] 0]
      # <-- HELP
      lappend output [format {
    Usage: analyze_path
                [-*from|-*f <pin_name>]
                [-*through|-*thro <pin_name>]
                [-*to|-*t <pin_name>]
                [-skip_hier_pins|-skip|-no_hierarchical_pins|-no_hier_pins]
                [-path <report_timing_command_line>][-npath <path_number>]
                [-details]
                [-return_string]
                [> <filename>|>> <filename>|-file <filename>][-append]
                [-quiet|-q]
                [-verbose|-v]
                [-help|-h]
                
    Description: Report information on a path defined by a list of all its pins.
    
    Example:
       analyze_path -from [all_fanout -flat -pin_level 0 -from Imega_cle_l_right_X1Y31_R0/Icle_cle_l_right_remap_X0Y24_R0/Icle_cle_l_right_ft_X0Y0_R0/Icle_cle_l_core_X0Y0_R0/Iclk_optinv1/clk_b] \ 
                    -thro Imega_cle_l_right_X1Y31_R0/Icle_cle_l_right_remap_X0Y24_R0/Icle_cle_l_right_ft_X0Y0_R0/Icle_cle_l_core_X0Y0_R0/Iclk_optinv1/clk_oi_b \ 
                    -rise_thro Imega_cle_l_right_X1Y31_R0/Icle_cle_l_right_remap_X0Y24_R0/Icle_cle_l_right_ft_X0Y0_R0/Icle_cle_l_core_X0Y0_R0/Iff_all/clk1_b \ 
                    -fall_thro Imega_cle_l_right_X1Y31_R0/Icle_cle_l_right_remap_X0Y24_R0/Icle_cle_l_right_ft_X0Y0_R0/Icle_cle_l_core_X0Y0_R0/Iff_all/AQ \ 
                    -to Imega_int_X0Y31_R0/Iint_interconnect_remap_X0Y24_R0/Iint_interconnect_ft_X0Y0_R0/Icore_inst/Isite_inst/I1/Iinode_2_e_ob_1_cb_/in0

       analyze_path -path " -from virtual_vorpalClk13064 \ 
                    -thro \[all_fanout -pin_levels 0 -flat -from Imega_dsp_X2Y31_R0/Idsp_dsp_remap_X0Y25_R0/Idsp_dsp_ft_X0Y0_R0/Idsp_dsp_core_X0Y0_R0/Idsp0/Ipreadd_data/clk_b\] " \ 
                    -npath 0
 
  } ]
      # HELP -->
      return [output {stdout} $output - -]
    }

    if {$msgLevel >= 1} {
      lappend output " -I- Starting analyze_path on [clock format [clock seconds]]"
      lappend output " -I- Arguments: $commandLine"
    }
    
    if {$allPins == {} && $report_timing_cmd == {}} {
      lappend output " -E- No pin specified."
      incr error
    }
    
    if {$report_timing_cmd != {}} {
      # Extract the list of pins from report_timing command
      if {$msgLevel >= 1} {
        lappend output " -I- report_timing command line: $report_timing_cmd"
      }
      set allPaths [get_report_timing_pins $report_timing_cmd]
      if {$allPaths == {}} {
        lappend output " -E- No path extracted from running report_timing with the provided command line (-path)."
        incr error
      } else {
        if {$msgLevel >= 1} {
          lappend output " -I- Number of returned paths: [llength $allPaths]"
        }
      }
      set allPins [lindex $allPaths $report_timing_path_num]
      if {$allPins == {}} {
        lappend output " -E- No pin extracted from path $report_timing_path_num from running report_timing with the provided command line (-path)."
        incr error
      } else {
        if {$msgLevel >= 1} {
          lappend output " -I- Selected path: $report_timing_path_num"
          lappend output " -I- Number of pins of path: [llength $allPins]"
        }
      }
    }
  
    if {$error} {
      if {$msgLevel >= 1} {
        lappend output " -I- Ending analyze_path on [clock format [clock seconds]]"
      }
      lappend output ""
      return [output $outputType $output $outputFilename $outputAppend]
    }

    lappend output [format_string $indentLevel "%s" "############################################################################################################"]
    lappend output [format_string $indentLevel "%s" "## ANALYZE PATH"]
    lappend output [format_string $indentLevel "%s" "############################################################################################################"]
    lappend output [format_string $indentLevel "%s" "## CMD: analyze_path [regsub -all {(\-indent [0-9]+|\-return_string)} $commandLine {}]"]
    lappend output [format_string $indentLevel "%s" "############################################################################################################"]
    foreach pin $allPins {
      if {[get_attribute -quiet [get_pins $pin] object_class] == {pin}} {
        lappend output [format_string $indentLevel "%s" "## PIN: [format_pin_name $pin 1]"]
      } else {
        lappend output [format_string $indentLevel "%s" "## PORT: [format_pin_name $pin 1]"]
      }
#       lappend output [format_string $indentLevel "%s" "## PIN: [format_pin_name $pin 1]"]
    }
    lappend output [format_string $indentLevel "%s" "############################################################################################################\n"]
    
    # Check if the pins are leaf pins or hierarchical pins
    set error 0
    set warning 0
    set filteredPins [list]
    foreach pin $allPins {
      if {([get_pins -quiet $pin] == {}) && ([get_ports -quiet $pin] == {})} {
        set cell [search_cell $pin both]
        lappend output "-E- Cannot find pin/port '$pin'. Skipped."
        if {$cell != {}} {
          if {[get_attribute -quiet $cell is_hierarchical] == {true}} {
            lappend output "-I- Found hierarchical cell '$cell'"
          } else {
            lappend output "-I- Found leaf cell '$cell'"
          }
        } else {
          lappend output "-E- Cannot find any valid hierarchical or leaf cell in the path of the pin name"
        }
        incr error
#         lappend filteredPins $pin
      } else {
        if {[get_attribute -quiet [get_pins -quiet $pin] is_hierarchical] == {true}} {
          if {$skip_hier_pins} {
            lappend output "-W- Hierarchical pin found '$pin' and skipped (-ship_hier_pins)"
            incr warning
          } else {
            lappend output "-W- Hierarchical pin found '$pin'"
            incr warning
            lappend filteredPins $pin
          }
          foreach conn_pin [get_connected_pins $pin fanin] {
#             lappend filteredPins $conn_pin
#             lappend output "-W- Replacing hierarchical pin with output pin '$conn_pin'"
            if {$msgLevel >= 1} {
              lappend output "-I- Hierarchical pin connected to output pin '$conn_pin'"
            }
          }
          foreach conn_pin [get_connected_pins $pin fanout] {
#             lappend filteredPins $conn_pin
#             lappend output "-W- Replacing hierarchical pin with input pin '$conn_pin'"
            if {$msgLevel >= 1} {
              lappend output "-I- Hierarchical pin connected to input pin '$conn_pin'"
            }
          }
        } else {
          lappend filteredPins $pin
        }
      }
    }
    if {$error || $warning} { lappend output "" }
    
    if {[llength $allPins] != [llength $filteredPins]} {
      lappend output [format_string [expr $indentLevel + 1] "%s" "############################################################################################################"]
      foreach pin $filteredPins {
        if {[get_attribute -quiet [get_pins $pin] object_class] == {pin}} {
          lappend output [format_string [expr $indentLevel + 1] "%s" "## PIN: [format_pin_name $pin 1]"]
        } else {
          lappend output [format_string [expr $indentLevel + 1] "%s" "## PORT: [format_pin_name $pin 1]"]
        }
#         lappend output [format_string [expr $indentLevel + 1] "%s" "## PIN: [format_pin_name $pin 1]"]
      }
      lappend output [format_string [expr $indentLevel + 1] "%s" "############################################################################################################\n"]
    }
    # The list of pins should now includes the pins coming from the conversion of the hierarchical pins
    set allPins $filteredPins

    set startPin {}
    set startCell {}
    set startCellName {}
    set startNet {}
    set startNetName {}
    set endPin {}
    set endCell {}
    set endCellName {}
    set endNet {}
    set endNetName {}
    for {set index 0} {$index <= [expr [llength $allPins] -2]} {incr index} {
      # Set few variables
      set startPin [lindex $allPins $index]
      set startCell [get_cells -quiet -of_objects $startPin]
      if {$startCell != {}} { set startCellName [get_object_name $startCell] }
      set startNet [get_nets -quiet -of_objects $startPin]
      if {$startNet != {}} { set startNetName [get_object_name $startNet] }
      set endPin [lindex $allPins [expr $index + 1]]
      set endCell [get_cells -quiet -of_objects $endPin]
      if {$endCell != {}} { set endCellName [get_object_name $endCell] }
      set endNet [get_nets -quiet -of_objects $endPin]
      if {$endNet != {}} { set endNetName [get_object_name $endNet] }
      # Show information on start pin
      if {$show_details} { 
        lappend output [show_info -pin $startPin -return_string -indent [expr $indentLevel + 1] ]
      }
      # Show information on start net
      if {$startNet != {}} {
        if {$show_details} { 
          lappend output [show_case_value -net $startNetName -return_string -indent [expr $indentLevel + 2] ]
        }
      }
      # Show information on start cell
      if {$startCell != {}} {
        if {$show_details} { 
          lappend output [show_info -cell $startCellName -return_string -indent [expr $indentLevel + 2] ]
          lappend output [show_case_value -cell $startCellName -only_set -return_string -indent [expr $indentLevel + 2] ]
        }
      }
      # Show information on timing arc between start and end pin
      lappend output [show_arcs -from $startPin -to $endPin -return_string -indent [expr $indentLevel + 1] ]
    }
    # Show information on last pin
    if {$show_details} { 
      lappend output [show_info -pin $endPin -return_string -indent [expr $indentLevel + 1] ]
    }
    # Show information on last net
    if {$endNet != {}} {
      if {$show_details} { 
        lappend output [show_case_value -net $endNetName -return_string -indent [expr $indentLevel + 2] ]
      }
    }
    # Show information on last cell
    if {$endCell != {}} {
      if {$show_details} { 
        lappend output [show_info -cell $endCellName -return_string -indent [expr $indentLevel + 2] ]
        lappend output [show_case_value -cell $endCellName -only_set -return_string -indent [expr $indentLevel + 2] ]
      }
    }

    if {$msgLevel >= 1} {
      lappend output " -I- Ending analyze_path on [clock format [clock seconds]]"
    }
  
    return [output $outputType $output $outputFilename $outputAppend]
  }


  #------------------------------------------------------------------------
  # trace_arcs
  #------------------------------------------------------------------------
  # Trace enabled timing arcs from/to a pin. If a timing arcs goes to multiple 
  # pins, then the function stops
  #------------------------------------------------------------------------
  proc trace_arcs { args } {

    set staToolName {pt}
    if {[info exists ::staToolName]} {
      set staToolName $::staToolName
    }

    #-------------------------------------------------------
    # Process command line arguments
    #-------------------------------------------------------
    set pin_name {}
    set from {}
    set to {}
    set type {}
    set full_pin_name 0
    set error 0
    set help 0
    set indentLevel 0
    set msgLevel 0
    set output [list]
    set outputType {stdout}
    set outputFilename {}
    set outputAppend 0
    set commandLine $args
    if {[llength $args] == 0} { incr help }
    # Add dummy argument to the command line so that "> file" & ">> file" 
    # are processed as a command line arguments
    lappend args {--}
    while {[llength $args]} {
      set name [lshift args]
      switch -exact -- $name {
        -from -
        -f {
             set from [lshift args]
             set type {forward}
        }
        -to -
        -t {
             set to [lshift args]
             set type {backward}
        }
        -full_pin_name -
        -full {
             set full_pin_name 1
        }
        -return_string {
             set outputType {string}
        }
        -file {
             set outputType {file}
             set outputFilename [lshift args]
        }
        -append {
             set outputAppend 1
        }
        > {
             # Same as -file
             set outputType {file}
             set outputFilename [lshift args]
             set outputAppend 0
        }
        >> {
             # Same as -file & -append
             set outputType {file}
             set outputFilename [lshift args]
             set outputAppend 1
        }
        -q -
        -quiet {
              set msgLevel -1
        }
        -v -
        -verbose {
              set msgLevel 1
        }
        -h -
        -help {
              incr help
        }
        -indent {
             set indentLevel [lshift args]
        }
        -- {
          # Dummy
        }
        default {
              if {[string match "-*" $name]} {
                lappend output " -E- option '$name' is not a valid option."
                incr error
              } else {
                lappend output " -E- option '$name' is not a valid option."
                incr error
              }
        }
      }
    }
    
    if {$help} {
      set callerName [lindex [info level [expr [info level] -1]] 0]
      # <-- HELP
      lappend output [format {
    Usage: trace_arcs
                [-from|-f <pin_name>]
                [-to|-t <pin_name>]
                [-full_pin_name|-full]
                [-return_string]
                [> <filename>|>> <filename>|-file <filename>][-append]
                [-quiet|-q]
                [-verbose|-v]
                [-help|-h]
                
    Description: Trace through timing arcs from/to a pin. The trace stops either when all of the found timing
       arc(s) are disabled or when the next timing arc has multiple startpoints or endpoints.
    
    
    Example:
       trace_arcs -from Imega_cle_l_right_X1Y31_R0/Icle_cle_l_right_remap_X0Y24_R0/Icle_cle_l_right_ft_X0Y0_R0/Icle_cle_l_core_X0Y0_R0/Iclk_optinv1/clk_b
       trace_arcs -to Imega_cle_l_right_X1Y31_R0/Icle_cle_l_right_remap_X0Y24_R0/Icle_cle_l_right_ft_X0Y0_R0/Icle_cle_l_core_X0Y0_R0/Iff_all/AQ
       trace_arcs -to Imega_cle_l_right_X1Y31_R0/Icle_cle_l_right_remap_X0Y24_R0/Icle_cle_l_right_ft_X0Y0_R0/Icle_cle_l_core_X0Y0_R0/Iff_all/AQ -full
  
  } ]
      # HELP -->
      return [output {stdout} $output - -]
    }

    if {($from == {}) && ($to == {})} {
      lappend output " -E- No -from/-to specified."
      incr error
    } elseif {($from != {}) && ($to != {})} {
      lappend output " -E- Cannot use -from/-to together."
      incr error
    } else {
      if {$type == {forward}} {
        set pin_name $from
      } else {
        set pin_name $to
      }
      if {[get_pins -quiet $pin_name] == {}} {
        lappend output " -E- Cannot find pin '$pin_name'."
      }
    }
  
    if {$error} {
      lappend output ""
      return [output $outputType $output $outputFilename $outputAppend]
    }

    if {$msgLevel >= 1} {
      lappend output " -I- Starting trace_arcs on [clock format [clock seconds]]"
      lappend output " -I- Arguments: $commandLine"
    }
    
    lappend output [format_string $indentLevel "%s" "############################################################################################################"]
    lappend output [format_string $indentLevel "%s" "## TRACE TIMING ARCS"]
    lappend output [format_string $indentLevel "%s" "############################################################################################################"]
    lappend output [format_string $indentLevel "%s" "## CMD: trace_arcs [regsub -all {(\-indent [0-9]+|\-return_string)} $commandLine {}]"]
    lappend output [format_string $indentLevel "%s" "############################################################################################################"]
    if {$type == {forward}} {
      lappend output [format_string $indentLevel "%s" "## From: [format_pin_name $pin_name 1]"]
    } else {
      lappend output [format_string $indentLevel "%s" "## To : [format_pin_name $pin_name 1]"]
    }
    lappend output [format_string $indentLevel "%s" "############################################################################################################\n"]

    set tbl [Table::Create]
    $tbl indent $indentLevel
    switch $staToolName {
      pt {
        $tbl header [list "from_pin" "to_pin" "from_ref_name" "to_ref_name" "is_cellarc" "sense" "is_disabled" "is_user_disabled" "mode" ]
      }
      gt {
         # The 'mode' attribute does not exist in GoldTime, so replace it with 'lib_cell_arc'
        $tbl header [list "from_pin" "to_pin" "from_ref_name" "to_ref_name" "is_cellarc" "sense" "is_disabled" "is_user_disabled" "lib_cell_arc" ]
      }
      default {
      }
    }

    set loop 1
    while {$loop} {
      set loop 0
      if {$type == {forward}} {
        set arcs [eval [concat get_timing_arcs -from $pin_name ]]
      } else {
        set arcs [eval [concat get_timing_arcs -to $pin_name ]]
      }
      set count 0
      set countEnabled 0
      set enabledArcs [list]
      foreach_in_collection arc $arcs {
        set is_cellarc [get_attribute $arc is_cellarc]
        set fpin [get_attribute $arc from_pin]
        set tpin [get_attribute $arc to_pin]
        set fcellref [format_ref_name [get_cells -quiet -of $fpin]]
        set tcellref [format_ref_name [get_cells -quiet -of $tpin]]
        set rise [get_attribute $arc delay_max_rise]
        set fall [get_attribute $arc delay_max_fall]
        set sense [get_attribute $arc sense]
        set is_disabled [get_attribute $arc is_disabled]
        set is_user_disabled [get_attribute $arc is_user_disabled]
        if {$full_pin_name} {
          set from_pin_name [format_pin_name $fpin 1]; # Full hierarchical pin name
          set to_pin_name [format_pin_name $tpin 1]; # Full hierarchical pin name
        } else {
          # Only keep the pin name without the full hierarchical path
          set from_pin_name [format_pin_name $fpin 0]; # Short pin name
          set to_pin_name [format_pin_name $tpin 0]; # Short pin name
        }
        switch $staToolName {
          pt {
            set mode [get_attribute -quiet $arc mode]
            if {$mode == {}} { set mode - }
          }
          gt {
            # The 'mode' attribute does not exist in GoldTime, so replace it with 'lib_cell_arc'
            if {[get_attribute $arc lib_cell_arc] != {}} {
              # lib_cell_arc_type provides the information whether the path is combinational, ...
              set lib_cell_arc_type [get_attribute [index_collection [get_attribute $arc lib_cell_arc] 0] type]
              if {$lib_cell_arc_type == {}} { set lib_cell_arc_type {??} }
              if {[sizeof_collection [get_attribute $arc lib_cell_arc]] > 1} {
                if {$msgLevel >= 1} {
                  set lib_cell_arc "$lib_cell_arc_type ([get_object_name [index_collection [get_attribute $arc lib_cell_arc] 0]] (1/[sizeof_collection [get_attribute $arc lib_cell_arc] ])"
                } else {
                  set lib_cell_arc "$lib_cell_arc_type (1/[sizeof_collection [get_attribute $arc lib_cell_arc] ])"
                }
              } else {
                if {$msgLevel >= 1} {
                  set lib_cell_arc "$lib_cell_arc_type ([get_object_name [index_collection [get_attribute $arc lib_cell_arc] 0]])"
                } else {
                  set lib_cell_arc "$lib_cell_arc_type"
                }
              }
            } else {
              # A timing arc on a net does not have a lib_cell_arc
              set lib_cell_arc {-}
            }
          }
          default {
          }
        }
        if {[get_attribute $fpin full_name] == [get_attribute $tpin full_name]} {
          # For some reasons, some timing arcs have the same pin name for startpoint and endpoint so
          # skip those ones.
          continue
        }
        if {$is_disabled == {false}} {
          # Count the number of arcs that are enabled.
          incr countEnabled
          lappend enabledArcs [list $arc [get_attribute $fpin full_name] [get_attribute $tpin full_name]]
        }
        if {$sense == {}} { set sense - }
        if {$is_disabled == {}} { set is_disabled - }
        if {$is_user_disabled == {}} { set is_user_disabled - }
        switch $staToolName {
          pt {
            $tbl addrow [list $from_pin_name $to_pin_name $fcellref $tcellref $is_cellarc $sense $is_disabled $is_user_disabled $mode ]
          }
          gt {
            $tbl addrow [list $from_pin_name $to_pin_name $fcellref $tcellref $is_cellarc $sense $is_disabled $is_user_disabled $lib_cell_arc ]
          }
          default {
          }
        }
        incr count
      }
      # Now check that only 1 timing arc is valid or if multiple timing arcs are valid that
      # they all have the same start point and end point
      if {$countEnabled >= 1} {
        set startpoints [list]
        set endpoints [list]
        foreach elm $enabledArcs {
          foreach {arc from to} $elm { break }
          lappend startpoints $from
          lappend endpoints $to
        }
        set startpoints [lsort -unique $startpoints]
        set endpoints [lsort -unique $endpoints]
        if {([llength $startpoints] == 1) && ([llength $endpoints] == 1)} {
          # There are multiple timing arcs that are enabled, but they have all the
          # same starpoint and endpoint. So keep looping.
          if {$type == {forward}} {
            set pin_name $endpoints
          } else {
            set pin_name $startpoints
          }
          $tbl separator
          set loop 1
        } else {
          # There are multiple timing arcs that are enabled with multiple
          # starpoints and/or endpoints. Stop here.
          lappend output [$tbl print]
          lappend output ""
          lappend output [format "%s Several timing arcs with multiple startpoints and/or endpoints have been found. The trace stops.\n" [indent $indentLevel]]
          lappend output [format "%s Startpoints:" [indent $indentLevel] ]
          foreach startpoint $startpoints {
            lappend output [format "%s              %s\t(%s)" [indent $indentLevel] $startpoint [get_attribute -quiet [get_cells -of_objects [get_pins $startpoint]] ref_name] ]
          }
          lappend output [format "%s Endpoints:" [indent $indentLevel]]
          foreach endpoint $endpoints {
            lappend output [format "%s              %s\t(%s)" [indent $indentLevel] $endpoint [get_attribute -quiet [get_cells -of_objects [get_pins $endpoint]] ref_name] ]
          }
          set loop 0
        }
      } else {
        # No enabled timing arc has been found. Stop here.
        lappend output [$tbl print]
        lappend output ""
        if {$type == {forward}} {
          lappend output [format "%s No enabled timing arc has been found from pin '$pin_name. The trace stops.'" [indent $indentLevel]]
        } else {
          lappend output [format "%s No enabled timing arc has been found to pin '$pin_name'. The trace stops." [indent $indentLevel]]
        }
        set loop 0
      }
      
    }
    lappend output ""

    if {$msgLevel >= 1} {
      lappend output " -I- Ending trace_arcs on [clock format [clock seconds]]"
    }
  
    return [output $outputType $output $outputFilename $outputAppend]
  }




# END NAMESPACE FOR PRIMETIME
}

puts " [info script] has been successfully sourced ..."

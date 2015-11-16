
# Proc to reload current script
proc [file tail [info script]] {} " source [info script]; puts \" [info script] reloaded\" "

########################################################################################
##
## Company:        Xilinx, Inc.
## Created by:     David Pefourque
## 
## Version:        03/09/2015
## Description:    This script exposes 'reload_xdc' command to be able to reload the
##                 synthesis or implementation constraints in the same order reported
##                 by the 'report_compile_order -constraints' command.
##
########################################################################################

########################################################################################
## 03/09/2015 - Added -no_add to read_xdc command
## 03/20/2014 - Added support for reports with out-of-context sections
## 09/30/2013 - Added -unmanaged to read_xdc command
## 07/18/2013 - Initial release
########################################################################################

proc reload_xdc {args} {
  return [uplevel [concat ::reload_xdc::main $args]]
}

eval [list namespace eval ::reload_xdc { 
  variable version {03/09/2015}
} ]

#------------------------------------------------------------------------
# ::reload_xdc::main
#------------------------------------------------------------------------
# Main function
#------------------------------------------------------------------------
proc ::reload_xdc::main { args } {
  # Summary :
  # Argument Usage:
  # Return Value:

  #-------------------------------------------------------
  # Process command line arguments
  #-------------------------------------------------------
  variable version
  set error 0
  set show_help 0
  set stage {}
  set mode {run}
  set filename {}
  set verbose 0
  set reset 0
  set debug 0
  if {[llength $args] == 0} { set args {-help} }
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -synth {
           set stage {synth}
      }
      -impl {
           set stage {impl}
      }
      -auto {
           set stage {auto}
      }
      -tcl -
      -tcl_script {
           set mode {script}
      }
      -file {
           set filename [lshift args]
      }
      -reset -
      -reset_timing {
           set reset 1
      }
      -debug {
           set debug 1
      }
      -h -
      -help {
           set show_help 1
      }
      -v -
      -verbose {
           set verbose 1
      }
      -version {
           puts " -I- script version $version"
           return
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
  
  if {$show_help} {
    # <-- HELP
    puts [format {
      Usage: reload_xdc
                  [-synth]                - reload synthesis constraints
                  [-impl]                 - reload implementation constraints
                  [-auto]                 - reload synthesis or implementation constraints
                                            based on best guess
                  [-file <filename>]      - use existing report_compile_order report file
                  [-reset_timing|-reset]  - reset timing before reloading the XDC constraints
                  [-tcl_script|-tcl]      - generate script to reload XDC constraints only
                                            XDC constraint files are not reloaded
                  [-v|-verbose]           - verbose
                  [-version]              - script version
                  [-h|-help]              - This help message
                 
      Description: Utility to reload the synthesis/implementation constraints based on
                   the report_compile_order command
      
      Example Script:
         reload_xdc -synth
         reload_xdc -impl -file report_compile_order.rpt -reset_timing
         reload_xdc -impl -file report_compile_order.rpt -tcl_script
    
    } ]
    # HELP -->
    return
  }

  if {$stage == {}} {
    puts " -E- cannot determine the stage in the implementation flow. Use -synth/-impl/-auto"
    incr error
  } elseif {$stage == {auto}} {
    if {[get_property IS_IMPLEMENTATION [current_run]]} {
      set stage {impl}
    } elseif {[get_property IS_SYNTHESIS [current_run]]} {
      set stage {synth}
    } else {
      puts " -E- cannot determine the stage in the implementation flow. Use -synth/-impl to force"
      incr error
    }
  }
  
  if {($filename != {}) && (![file exists $filename])} {
    puts " -E- file '$filename' does not exist"
    incr error
  }
  
  if {$error} {
    error " -E- some error(s) occur. Cannot continue"
  }
  
  if {$filename == {}} {
    set filename [format {report_compile_order.%s} [clock seconds]]
    if {$verbose} {
      puts " -I- writing temporary report file '$filename'"
    }
    report_compile_order -constraints -file $filename
    set FH [open $filename {r}]
    set report [read $FH]
    close $FH
    if {$verbose} {
      puts " -I- removing temporary report file '$filename'"
    }
    file delete $filename
  } else {
    if {$verbose} {
      puts " -I- reading report file '$filename'"
    }
    set FH [open $filename {r}]
    set report [read $FH]
    close $FH
  }
  if {$verbose} {
    puts " -I- Report Compile Order Report:"
    foreach line [split $report \n] {
      puts "      $line"
    }
  }
#   puts "<filename:$filename>"

  array set tables [::reload_xdc::extract_tables $report]
  
  if {$debug} {
    puts "  DEBUG: Stage:$stage"
    puts "  DEBUG: Synthesis:$tables(synth)"
    foreach elm $tables(synth) { puts "     $elm" }
    puts "  DEBUG: Implementation:$tables(impl)"
    foreach elm $tables(impl) { puts "     $elm" }
  }

  if {![info exists tables($stage)]} {
    error " -E- could not extract XDC constraints for stage '$stage' from the report_compile_order command"
  }

  set script [list]
  # Skip the header (first element of the list)
  foreach row [lrange $tables($stage) 1 end] {
#     puts "row:$row"
    set cmd [list read_xdc -no_add -unmanaged]
    foreach {Index Filename Used_In Scoped_To_Ref Scoped_To_Cells Processing_Order Out_Of_Context Path} $row {
      if {$Scoped_To_Ref != {}} {
        regsub -all {, } $Scoped_To_Ref { } Scoped_To_Ref
#         set cmd [format "%s -ref {%s}" $cmd $Scoped_To_Ref]
        # Remove redundant ref names
        set cmd [format {%s -ref {%s}} $cmd [lsort -unique $Scoped_To_Ref]]
      }
      if {$Scoped_To_Cells != {}} {
        regsub -all {, } $Scoped_To_Cells { } Scoped_To_Cells
#         set cmd [format "%s -cells {%s}" $cmd $Scoped_To_Cells]
        # Remove redundant cell names
        set cmd [format {%s -cells {%s}} $cmd [lsort -unique $Scoped_To_Cells]]
      }
      if {[file exists $Path]} {
        lappend cmd $Path
      } else {
        puts " -E- cannot find file '$Path'"
        incr error
      }
    }
#     puts "cmd:$cmd"
    lappend script $cmd
  }

  if {$error} {
    error " -E- some error(s) happen. Cannot continue"
  }

  if {$mode == {run}} {
    if {$reset} {
      if {$verbose} {
        puts " -I- resetting timing constraints"
      }
      reset_timing
    }
    foreach elm $script {
#       puts "eval:$elm"
      if {$verbose} {
        puts " -I- processing: $elm"
      }
      eval $elm
    }
  } else {
    puts " -I- XDC Script:"
    foreach elm $script { puts "     $elm" }
  }
  
  return 0
}

#------------------------------------------------------------------------
# ::reload_xdc::lshift
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Stack function
#------------------------------------------------------------------------
proc ::reload_xdc::lshift {inputlist} {
  # Summary :
  # Argument Usage:
  # Return Value:

  upvar $inputlist argv
  set arg  [lindex $argv 0]
  set argv [lrange $argv 1 end]
  return $arg
}

#------------------------------------------------------------------------
# ::reload_xdc::extract_columns
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Extract position of columns based on the column separator string
#  str:   string to be used to extract columns
#  match: column separator string
#------------------------------------------------------------------------
proc ::reload_xdc::extract_columns { str match } {
  # Summary :
  # Argument Usage:
  # Return Value:

  set col 0
  set columns [list]
  set previous -1
  while {[set col [string first $match $str [expr $previous +1]]] != -1} {
    if {[expr $col - $previous] > 1} {
      lappend columns $col
    }
    set previous $col
  }
  return $columns
}

#------------------------------------------------------------------------
# ::reload_xdc::extract_row
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Extract all the cells of a row (string) based on the position
# of the columns
#------------------------------------------------------------------------
proc ::reload_xdc::extract_row {str columns} {
  # Summary :
  # Argument Usage:
  # Return Value:

  lappend columns [string length $str]
  set row [list]
  set pos 0
  foreach col $columns {
    set value [string trim [string range $str $pos $col]]
    lappend row $value
    set pos [incr col 2]
  }
  return $row
}

#------------------------------------------------------------------------
# ::reload_xdc::extract_tables
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Extract the synthesis and implementation tables from the report
#------------------------------------------------------------------------
proc ::reload_xdc::extract_tables {report} {
  # Summary :
  # Argument Usage:
  # Return Value:

  set columns [list]
  set table [list]
  set report [split $report \n]
  set SM {header}
  set synthesis [list]
  set implementation [list]
  set type {}; # synthesis / implementation
  for {set index 0} {$index < [llength $report]} {incr index} {
    set line [lindex $report $index]
    switch $SM {
      header {
        if {[regexp {^\-+\s+\-+\s+\-+} $line]} {
          set columns [::reload_xdc::extract_columns $line { }]
#           puts "Columns: $columns"
          set header [::reload_xdc::extract_row [lindex $report [expr $index -1]] $columns]
          set row [list]
          foreach elm $header {
            lappend row [string trim [format {%s} $elm]]
          }
#           puts "header:$row"
          lappend table $row
          set SM {table}
        } elseif { [regexp -nocase {^\s*Synthesis Constraint Evaluation Order} $line] ||
                   [regexp -nocase {^\s*Constraint Evaluation Order for 'synthesis'} $line] } {
          set type {synthesis}
          set table [list]
#           puts "found synthesis"
        } elseif { [regexp -nocase {^\s*Implementation Constraint Evaluation Order} $line] ||
                   [regexp -nocase {^\s*Constraint Evaluation Order for 'implementation'} $line] } {
          set type {implementation}
          set table [list]
#           puts "found implementation"
        } elseif { [regexp -nocase {^\s*\|\s*Compile Order for Out-of-Context BlockSet} $line] ||
                   [regexp -nocase {^Compile Order for Out-of-Context BlockSet} $line] } {
          #   ----------------------------------------------------------
          #   | Compile Order for Out-of-Context BlockSet: 'tri_mode_ethernet_mac_rgmii'
          #   | Top Module:                                'tri_mode_ethernet_mac_rgmii'
          #   ----------------------------------------------------------
          set SM {out_of_context}
        }
      }
      table {
        # Check for empty line or for line that match '<empty>'
        if {(![regexp {^\s*$} $line]) && (![regexp -nocase {^\s*\<\s*empty\s*\>\s*$} $line])} {
          set row [::reload_xdc::extract_row $line $columns]
          lappend table $row
#           puts "row:$row"
        } else {
          switch $type {
            synthesis {
              set synthesis $table
              set type {}
            }
            implementation {
              set implementation $table
              set type {}
            }
            default {
            }
          }
          set SM {header}
        }
      }
      out_of_context {
        # The out-of-context sections have been reached. Skip remaining lines of file
        #   ----------------------------------------------------------
        #   | Compile Order for Out-of-Context BlockSet: 'tri_mode_ethernet_mac_rgmii'
        #   | Top Module:                                'tri_mode_ethernet_mac_rgmii'
        #   ----------------------------------------------------------
      }
      end {
      }
    }
  }
#     puts "synthesis: $synthesis"
#     puts "implementation: $implementation"
  return [list synth $synthesis impl $implementation]
}



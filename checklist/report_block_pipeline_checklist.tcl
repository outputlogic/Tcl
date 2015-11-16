####################################################################################################
# HEADER_BEGIN
# COPYRIGHT NOTICE
# Copyright 2001-2013 Xilinx Inc. All Rights Reserved.
# http://www.xilinx.com/support
# HEADER_END
####################################################################################################

########################################################################################
##
## Company:        Xilinx, Inc.
## Created by:     David Pefourque
##
## Version:        09/16/2013
## Tool Version:   Vivado 2013.3
##
########################################################################################

########################################################################################
## 09/16/2013 - Added meta-comment 'Categories' to all procs
## 09/13/2013 - Replaced property name LIB_CELL with REF_NAME
## 09/10/2013 - Changed command name from lint_hard_block_pipelining to report_block_pipeline
##            - In verbose mode, print the DSP/BRAM that are OK
## 09/09/2013 - Added support for -file/-append/-return_string
##            - Moved code in a private namespace
##            - Removed errors from linter (lint_files)
## 08/27/2013 - Initial release based on lint_hard_block_pipelining version 0.1 (Jim Wu)
########################################################################################

namespace eval ::tclapp::xilinx::checklist {
  namespace export report_block_pipeline

  # User command exported to the global namespace
  if {[lsearch $listUserCommands {report_block_pipeline}] == -1} {
    lappend listUserCommands [list {report_block_pipeline} {Reports Usage of Input and Output Registers on DSP, BRAM}]
  }
}

proc ::tclapp::xilinx::checklist::report_block_pipeline { args } {
  # Summary :
  # Argument Usage:
  # Return Value:
  # Categories:

  uplevel [concat ::tclapp::xilinx::checklist::report_block_pipeline::report_block_pipeline $args]
}

# Trick to silence the linter
eval [list namespace eval ::tclapp::xilinx::checklist::report_block_pipeline { 
  variable version {09/16/2013}
} ]

## ---------------------------------------------------------------------
## Procedure Comments
##
## Description
##    This proc reports usage of input and output registers on hard blocks
##    like DSP, BRAM, etc.
##    
##    This proc must be run on a synthesized or implemented design.
##
##    The proc does not require arguments.
##
##    The result is printed on the console.
## Author: Jim Wu
##
## Version Number: 0.1
## 
## Version Change History
## Jan 23 2013: Initial revision
## --------------------------------------------------------------------- 

proc ::tclapp::xilinx::checklist::report_block_pipeline::report_block_pipeline { args } {
  # Summary :
  # Argument Usage:
  # Return Value:
  # Categories:

  #-------------------------------------------------------
  # Process command line arguments
  #-------------------------------------------------------
  set error 0
  set filename {}
  set mode {w}
  set verbose 0
  set returnString 0
  set help 0
  while {[llength $args]} {
    set name [[namespace parent]::lshift args]
    switch -regexp -- $name {
      -file -
      {^-f(i(le?)?)?$} {
           set filename [[namespace parent]::lshift args]
           if {$filename == {}} {
             puts " -E- no filename specified."
             incr error
           }
      }
      -append -
      {^-a(p(p(e(nd?)?)?)?)?$} {
           set mode {a}
      }
      -verbose -
      {^-v(e(r(b(o(se?)?)?)?)?)?$} {
           set verbose 1
      }
      -return_string -
      {^-r(e(t(u(r(n(_(s(t(r(i(ng?)?)?)?)?)?)?)?)?)?)?)?$} {
           set returnString 1
      }
      -help -
      {^-h(e(lp?)?)?$} {
           set help 1
      }
      ^--version$ {
           variable version
           return $version
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
  Usage: report_block_pipeline
              [-file]              - Report file name
              [-append]            - Append to file
              [-verbose]           - Verbose mode
              [-return_string]     - Return report as string
              [-help|-h]           - This help message

  Description: Reports Usage of Input and Output Registers on DSP, BRAM

     This command reports usage of input and output registers on hard blocks
     like DSP, BRAM, etc.
     
     This command must be run on a synthesized or implemented design.

  Example:
     report_block_pipeline
     report_block_pipeline -verbose -file myreport.rpt
} ]
    # HELP -->
    return {}
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  set family [[namespace parent]::getCurrentFamily]
  switch [string tolower $family] {
    virtex7 -
    kintex7 -
    zinq7 -
    artix7 {
      return [LintHardBlockPipelining7s -verbose $verbose -filename $filename -mode $mode -return_string $returnString]
    }
    default {
      error "Unsupported device family for [get_property PART [current_project]]"
    }
  }
}

proc ::tclapp::xilinx::checklist::report_block_pipeline::LintHardBlockPipelining7s {args} {
  # Summary :
  # Argument Usage:
  # Return Value:
  # Categories:

  # Default values
  set defaults [list -verbose 0 -filename {} -mode {w} -return_string 0]
  # First, assign default values
  array set options $defaults
  # Then, override with passeds arguments
  array set options $args
  set verbose $options(-verbose)
  set filename $options(-filename)
  set mode $options(-mode)
  set returnString $options(-return_string)
  set output [list]

  #####################################################################################
  # DSP
  #####################################################################################
  set list_dsps [get_cells -quiet -hierarchical * -filter {REF_NAME =~ DSP48E*}]
  if {$list_dsps != {}} {
    set table [[namespace parent]::Table::Create]
    set i_dsp 1
    set pipe_not_ok 0
    $table reset
    $table title {DSP48 Pipeline Register Report}
    $table header [list {IDX} {OK} {Pipeline} {AREG} {BREG} {CREG} {ADREG} {MREG} {PREG} {CELL}]
    lappend output "----DSP48 Pipeline Register Report----"
    foreach dsp $list_dsps {
        set areg  [get_property -quiet AREG  $dsp]
        set breg  [get_property -quiet BREG  $dsp]
        set creg  [get_property -quiet CREG  $dsp]
        set adreg [get_property -quiet ADREG $dsp]
        set mreg  [get_property -quiet MREG  $dsp]
        set preg  [get_property -quiet PREG  $dsp]
        set pipeline [expr {$areg + $adreg + $mreg + $preg}]
        if {$pipeline <= 3} {
            set pipeok "N"
            #set sticky bit
            set pipe_not_ok 1
        } else {
            set pipeok "Y"
            # Only print DSP that are Ok in verbose mode
            if {!$verbose} { continue }
        }
        $table addrow [list $i_dsp $pipeok $pipeline $areg $breg $creg $adreg $mreg $preg $dsp]
        incr i_dsp
    }
    set output [concat $output [split [$table print] \n] ]

    if {$pipe_not_ok} {
        lappend output "\n Some DSP48E1 instances are not fully pipelined. The design may not achieve"
        lappend output " the maximum Fmax supported by DSP48E1 block. Check the data sheet for [[namespace parent]::getCurrentFamily]"
        lappend output " for more details.\n\n\n"
    }
  }

  #####################################################################################
  # BRAM
  #####################################################################################
  set list_ram36s [get_cells -quiet -hierarchical * -filter {REF_NAME =~ RAMB36E*}]
  set list_ram18s [get_cells -quiet -hierarchical * -filter {REF_NAME =~ RAMB18E*}]
  set list_rams [concat $list_ram18s $list_ram36s]
  if {$list_rams != {}} {
    set i_ram 1
    set pipe_not_ok 0
    $table reset
    $table title {BRAM Output Register Report}
    $table header [list {IDX} {OK} {READ_WIDTH_A} {DOA_REG} {READ_WIDTH_B} {DOB_REG} {CELL}]
    lappend output "----BRAM Output Register Report----"
    foreach ram $list_rams {
        set doareg  [get_property -quiet DOA_REG  $ram]
        set dobreg  [get_property -quiet DOB_REG  $ram]
        set rd_width_a [get_property -quiet READ_WIDTH_A  $ram]
        set rd_width_b [get_property -quiet READ_WIDTH_B  $ram]
        if {($rd_width_a > 0 && $doareg == 0) || ($rd_width_b > 0 && $dobreg == 0)} {
            set pipeok "N"
            #set sticky bit
            set pipe_not_ok 1
        } else {
            set pipeok "Y"
            # Only print RAMB that are Ok in verbose mode
            if {!$verbose} { continue }
        }
        $table addrow [list $i_ram $pipeok $rd_width_a $doareg $rd_width_b $dobreg $ram]
        incr i_ram
    }
    set output [concat $output [split [$table print] \n] ]
  
    if {$pipe_not_ok} {
        lappend output "\n Some RAMB instances don't have output reigisters turn on. The design may not achieve"
        lappend output " the maximum Fmax supported by RAMB block. Check the data sheet for [[namespace parent]::getCurrentFamily]"
        lappend output " for more details."
    }
  }

  if {$filename !={}} {
    set FH [open $filename $mode]
    puts $FH [::tclapp::xilinx::checklist::generate_file_header {report_block_pipeline}]
    puts $FH [join $output \n]
    close $FH
    puts "\n Report file [file normalize $filename] has been generated\n"
  } else {
    puts [join $output \n]
  }

  # Destroy the object
  catch {$table destroy}

  # Return result as string?
  if {$returnString} {
    return [join $output \n]
  }

  return 0
}

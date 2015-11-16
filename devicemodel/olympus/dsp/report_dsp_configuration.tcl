
# Proc to reload current script
proc [file tail [info script]] {} " source [info script]; puts \" [info script] reloaded\" "

lappend auto_path /home/dpefour/git/scripts/toolbox
package require toolbox

proc report_dsp_configuration { args } {
  
  # Default values 
  set defaults [list -dsp {} -v 0 -sitemap {} -f {} -a {w}]
  # First, assign default values 
  array set options $defaults 
  # Then, override with user choice 
  array set options $args 
  set dsps $options(-dsp)
  set verbose $options(-v)
  set filename $options(-f)
  set mode $options(-a)
  set error 0
  set output [list]
  
  if {$dsps == {}} {
    error " -E- no cell provided"
  } 
  set dsps [get_cells -quiet $dsps]
  if {$dsps == {}} {
    error " -E- no cell matching"
  } 
  switch [lsort -unique [get_property -quiet REF_NAME $dsps]] {
    DSP48E2 {
    }
    default {
      error " -E- some of the cell(s) are not DSP"
    }
  }

#   set dsps [list bfil/multOp]
  
  if {$options(-sitemap) != {}} {
    if {![file exists $options(-sitemap)]} {
      error " -E- file $options(-sitemap) does not exist"
    }
    if {[catch {array set sitemap2 [source $options(-sitemap)]} errorstring]} {
      error " -E- $errorstring"
    }
  } else {
    array set sitemap2 [sitemap2]
  }
  
  foreach dsp $dsps {
    
    foreach cell [lsort -dictionary [get_cells -quiet -hier -filter "NAME=~$dsp/*"]] {
      set ref_name [get_property -quiet REF_NAME $cell]
      if {![info exists sitemap2($ref_name)]} {
        lappend output " -E- Cannot find list of attributes for $ref_name"
        continue
      }

      set tbl [prettyTable]
      set header [list]
      set row [list]

      # Dump pins
      foreach bus {INMODE OPMODE ALUMODE CARRYINSEL} {
        foreach pin [lsort -dictionary -decreasing [get_pins -quiet $cell/$bus[*]]] {
          set net [get_nets -quiet -of $pin]
          set type [get_property -quiet TYPE $net]
          switch -nocase $type {
            POWER {
              lappend header [get_property -quiet REF_PIN_NAME $pin]
              lappend row {1}
            }
            GROUND {
              lappend header [get_property -quiet REF_PIN_NAME $pin]
              lappend row {0}
            }
            default {
              lappend header [get_property -quiet REF_PIN_NAME $pin]
              lappend row {-}
            }
          }
        }
      }
      
      # Dump properties
      array set props $sitemap2($ref_name)
      set properties [lsort -dictionary $props(cfg_element)]
      if {$verbose} {
        lappend output " -I- List of properties for $ref_name: $properties"
      }
      foreach prop $properties {
        lappend row [get_property -quiet $prop $cell]
      }
      
      # Dump number of timing arcs on the cell
#       lappend header {Timing Arcs}
      lappend row [llength [get_timing_arcs -quiet -of $cell]]

      # Merge results
      set header [concat $header $properties [list {Timing Arcs}]]
      if {$header != {}} {
        $tbl header $header
        $tbl addrow $row
        $tbl configure -title "Cell : $cell\nAtom : $ref_name"
        set output [concat $output [split [$tbl print] \n] ]
#         set output [concat $output [split [$tbl export -format list] \n] ]
      }

      if {$verbose} {
        $tbl reset
        $tbl configure -title "Timing Arcs for $ref_name"
        $tbl header {Arc}
        foreach arc [get_timing_arcs -quiet -of $cell] {
          $tbl addrow $arc
        }
      }

      catch {$tbl destroy}
    }
    
  }
  
  # Save/print results
  if {$filename !={}} {
    set FH [open $filename $mode]
    puts $FH [join $output \n]
    close $FH
    puts "\n Report file [file normalize $filename] has been generated\n"
  } else {
    puts [join $output \n]
  }

  return 0
}


proc sitemap2 {} {
  return {
   DSP_A_B_DATA { cfg_element {ACASCREG AREG A_INPUT BCASCREG BREG B_INPUT} }
   DSP_ALU { cfg_element {ALUMODEREG CARRYINREG CARRYINSELREG MREG OPMODEREG RND USE_SIMD USE_WIDEXOR XORSIMD} }
   DSP_C_DATA { cfg_element CREG }
   DSP_M_DATA { cfg_element MREG }
   DSP_MULTIPLIER { cfg_element {AMULTSEL BMULTSEL USE_MULT} }
   DSP_OUTPUT { cfg_element {AUTORESET_PATDET AUTORESET_PRIORITY MASK PATTERN PREG SEL_MASK SEL_PATTERN USE_PATTERN_DETECT} }
   DSP_PREADD { cfg_element {} }
   DSP_PREADD_DATA { cfg_element {ADREG AMULTSEL BMULTSEL DREG INMODEREG PREADDINSEL USE_MULT} }
  }
}


# vivado% report_dsp_configuration -dsp bfil/multOp
# +---------------------------------------------------------------------+
# | Cell : bfil/multOp/DSP_A_B_DATA_INST                                |
# | Atom : DSP_A_B_DATA                                                 |
# +---------+----------+------+---------+----------+------+-------------+
# | A_INPUT | ACASCREG | AREG | B_INPUT | BCASCREG | BREG | Timing Arcs |
# +---------+----------+------+---------+----------+------+-------------+
# | DIRECT  | 0        | 0    | DIRECT  | 0        | 0    | 141         |
# +---------+----------+------+---------+----------+------+-------------+
# +----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
# | Cell : bfil/multOp/DSP_ALU_INST                                                                                                                                                                                                                                                                                                                    |
# | Atom : DSP_ALU                                                                                                                                                                                                                                                                                                                                     |
# +-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+------------+------------+------------+------------+---------------+---------------+---------------+------------+------------+---------------+------+-----------+------------------+----------+-------------+-------------+-------------+
# | OPMODE[8] | OPMODE[7] | OPMODE[6] | OPMODE[5] | OPMODE[4] | OPMODE[3] | OPMODE[2] | OPMODE[1] | OPMODE[0] | ALUMODE[3] | ALUMODE[2] | ALUMODE[1] | ALUMODE[0] | CARRYINSEL[2] | CARRYINSEL[1] | CARRYINSEL[0] | ALUMODEREG | CARRYINREG | CARRYINSELREG | MREG | OPMODEREG | RND              | USE_SIMD | USE_WIDEXOR | XORSIMD     | Timing Arcs |
# +-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+------------+------------+------------+------------+---------------+---------------+---------------+------------+------------+---------------+------+-----------+------------------+----------+-------------+-------------+-------------+
# | 0         | 0         | 0         | 0         | 0         | 0         | 1         | 0         | 1         | 0          | 0          | 0          | 0          | 0             | 0             | 0             | 0          | 0          | 0             | 0    | 0         | 48'h000000000000 | ONE48    | FALSE       | XOR24_48_96 | 3299        |
# +-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+-----------+------------+------------+------------+------------+---------------+---------------+---------------+------------+------------+---------------+------+-----------+------------------+----------+-------------+-------------+-------------+
# +--------------------+
# | Cell : bfil/multOp/DSP_C_DATA_INST |
# | Atom : DSP_C_DATA  |
# +------+-------------+
# | CREG | Timing Arcs |
# +------+-------------+
# | 1    | 0           |
# +------+-------------+
# +--------------------+
# | Cell : bfil/multOp/DSP_M_DATA_INST |
# | Atom : DSP_M_DATA  |
# +------+-------------+
# | MREG | Timing Arcs |
# +------+-------------+
# | 0    | 85          |
# +------+-------------+
# +----------------------------------------------+
# | Cell : bfil/multOp/DSP_MULTIPLIER_INST       |
# | Atom : DSP_MULTIPLIER                        |
# +----------+----------+----------+-------------+
# | AMULTSEL | BMULTSEL | USE_MULT | Timing Arcs |
# +----------+----------+----------+-------------+
# | AD       | B        | MULTIPLY | 1084        |
# +----------+----------+----------+-------------+
# +------------------------------------------------------------------------------------------------------------------------------------------------+
# | Cell : bfil/multOp/DSP_OUTPUT_INST                                                                                                             |
# | Atom : DSP_OUTPUT                                                                                                                              |
# +------------------+--------------------+------------------+------------------+------+----------+-------------+--------------------+-------------+
# | AUTORESET_PATDET | AUTORESET_PRIORITY | MASK             | PATTERN          | PREG | SEL_MASK | SEL_PATTERN | USE_PATTERN_DETECT | Timing Arcs |
# +------------------+--------------------+------------------+------------------+------+----------+-------------+--------------------+-------------+
# | NO_RESET         | RESET              | 48'h3FFFFFFFFFFF | 48'h000000000000 | 0    | MASK     | PATTERN     | NO_PATDET          | 192         |
# +------------------+--------------------+------------------+------------------+------+----------+-------------+--------------------+-------------+
# +---------------------------------------------------------------------------------------------------------------------------------------------------+
# | Cell : bfil/multOp/DSP_PREADD_DATA_INST                                                                                                           |
# | Atom : DSP_PREADD_DATA                                                                                                                            |
# +-----------+-----------+-----------+-----------+-----------+-------+----------+----------+------+-----------+-------------+----------+-------------+
# | INMODE[4] | INMODE[3] | INMODE[2] | INMODE[1] | INMODE[0] | ADREG | AMULTSEL | BMULTSEL | DREG | INMODEREG | PREADDINSEL | USE_MULT | Timing Arcs |
# +-----------+-----------+-----------+-----------+-----------+-------+----------+----------+------+-----------+-------------+----------+-------------+
# | 0         | 0         | 1         | 0         | 0         | 0     | AD       | B        | 0    | 0         | A           | MULTIPLY | 0           |
# +-----------+-----------+-----------+-----------+-----------+-------+----------+----------+------+-----------+-------------+----------+-------------+
# +-------------+
# | Cell : bfil/multOp/DSP_PREADD_INST |
# | Atom : DSP_PREADD |
# +-------------+
# | Timing Arcs |
# +-------------+
# | 809         |
# +-------------+


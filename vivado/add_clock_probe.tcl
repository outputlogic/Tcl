####################################################################################################
# HEADER_BEGIN
# COPYRIGHT NOTICE
# Copyright 2001-2014 Xilinx Inc. All Rights Reserved.
# http://www.xilinx.com/support
# HEADER_END
####################################################################################################

########################################################################################
##
## Company:        Xilinx, Inc.
## Created by:     David Pefourque
##
## Version:        2014.05.21
## Description:    This utility provides a command to connect a clock leaf pin to
##                 an output port through a ODDR->OBUF. The output port and ODDR/OBUF
##                 cells are automatically created and connected.
##
########################################################################################

#------------------------------------------------------------------------
# add_clock_probe
#------------------------------------------------------------------------
# Usage: add_clock_probe -pin <pinName> [-diff-port <portName> | -port <portName>]
#------------------------------------------------------------------------
# Add a probe to the design and connect it to an output port. The output
# should not exist and is created by the command
#------------------------------------------------------------------------
proc add_clock_probe {args} {

  proc lshift {inputlist} {
    upvar $inputlist argv
    set arg  [lindex $argv 0]
    set argv [lrange $argv 1 end]
    return $arg
  }

  set error 0
  set help 0
  set pinName {}
  set portName {}
  set diffPort 0
  set iostandard {}
  set showSchematic 0
  if {[llength $args] == 0} {
    set help 1
  }
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -pin -
      -pin {
           set pinName [lshift args]
      }
      -port -
      -port {
           set portName [lshift args]
      }
      -diff-port -
      -diff-port {
           set portName [lshift args]
           set diffPort 1
      }
      -iostandard -
      -iostandard {
           set iostandard [lshift args]
      }
      -s -
      -schematic {
           set showSchematic 1
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
  Usage: add_clock_probe
              [-pin <pinName>]
              [-port <portName>]
              [-diff-port <portName>]
              [-iostandard <iostandard>]
              [-schematic]
              [-help|-h]

  Description: Add probe to the design and connect the probe to an output port
  
  The pin to be probed should be an output clock pin, typically a BUFG output pin.
  The probed pin is connected to the output port through an ODDR->OBUF. The output
  port is created by the command and cannot exist before. The ODDR and OBUF are
  automatically created and instanciated at the top-level.
  
  If -diff-port is used instead of -port then a differential port is created and
  driven through a OBUFDS.
  
  It is recommended to use the command on an unplaced design.

  Example:
     add_clock_probe -pin bufg/O -port probe -iostandard HSTL
     add_clock_probe -pin bufg/O -diff-port probe -iostandard LVDS
} ]
    # HELP -->
    return -code ok
  }
  
  if {$pinName == {}} {
    puts " -E- use -pin to define an output leaf pin"
    incr error
  } else {
    set pin [get_pins -quiet $pinName -filter {IS_LEAF && (DIRECTION == OUT)}]
    switch [llength $pin] {
      0 {
        puts " -E- pin '$pinName' does not exists or is not an output leaf pin"
        incr error
      }
      1 {
        # OK
      }
      default {
        puts " -E- pin '$pinName' matches multiple output leaf pins"
        incr error
      }
    }
  }
  
  if {$portName == {}} {
    puts " -E- use -port/-diff-port to define an output port"
    incr error
  } else {
    set port [get_ports -quiet $portName]
    if {$port != {}} {
      puts " -E- port '$portName' already exists"
      incr error
    }
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  # Make sure that the cell placement array is empty
  ::add_clock_probe::clearCellLoc

  # Unplace all the cells connected to the probed pin, otherwise the net connection cannot be done
  # This stage is done early in the process so that if it fails then no port/net/cell gets created
  ::add_clock_probe::unplaceConnectedCells [get_pins $pinName]
  
  # Create port(s)
  # --------------
  if {$diffPort} {
    create_port -direction OUT ${portName}_p
    create_port -direction OUT ${portName}_n
    make_diff_pair_ports ${portName}_p ${portName}_n
  } else {
    create_port -direction OUT $portName
  }
  
  # Create ODDR cell under top level
  # --------------------------------
  set oddrCellName [::add_clock_probe::genUniqueName oddr_probe]
  set oddrCellObj [::add_clock_probe::createCell $oddrCellName ODDR]
  # Set ODDR properties
  set_property DDR_CLK_EDGE SAME_EDGE $oddrCellObj
  # Connect tied pins
  ::add_clock_probe::pinTieHigh [get_pins $oddrCellObj/D1]
  ::add_clock_probe::pinTieLow [get_pins $oddrCellObj/D2]
  ::add_clock_probe::pinTieHigh [get_pins $oddrCellObj/CE]
  
#   # Unplace all the cells connected to the probed pin, otherwise the net connection cannot be done
#   ::add_clock_probe::unplaceConnectedCells [get_pins $pinName]
  # Connect PROBED PIN -> NET -> ODDR
  connect_net -verbose -hier -net [get_nets -of [get_pins $pinName]] -obj [get_pins  $oddrCellObj/C]
  # Restore the cells placement
  ::add_clock_probe::restoreCellLoc

  # Create OBUF/OBUFDS
  # ------------------
  if {$diffPort} {
    set obufCellName [::add_clock_probe::genUniqueName obuf_probe]
    set obufCellObj [::add_clock_probe::createCell $obufCellName OBUFDS]
  } else {
    set obufCellName [::add_clock_probe::genUniqueName obuf_probe]
    set obufCellObj [::add_clock_probe::createCell $obufCellName OBUF]
  }
  
  # Connect ODDR -> OBUF/OBUFDS
  # ---------------------------
  # Creates nets
  set oddrNetName [::add_clock_probe::genUniqueName ${oddrCellName}_net]
  set oddrNetObj [::add_clock_probe::createNet $oddrNetName]
  # Connect ODDR -> NET -> OBUF
  connect_net -verbose -hier -net $oddrNetObj -obj [list [get_pins  $oddrCellObj/Q] [get_pins $obufCellObj/I] ]
  
  # Connect OBUF/OBUFDS -> PORT
  # ---------------------------
  if {$diffPort} {
    # Creates nets
    set obufNetName_N [::add_clock_probe::genUniqueName ${obufCellName}_n_net]
    set obufNetName_P [::add_clock_probe::genUniqueName ${obufCellName}_p_net]
    set obufNetObj_N [::add_clock_probe::createNet $obufNetName_N]
    set obufNetObj_P [::add_clock_probe::createNet $obufNetName_P]
    # Connect OBUF -> NET -> PORTS
    connect_net -verbose -hier -net $obufNetObj_P -obj [list [get_pins  $obufCellObj/O] [get_ports ${portName}_p] ]
    connect_net -verbose -hier -net $obufNetObj_N -obj [list [get_pins  $obufCellObj/OB] [get_ports ${portName}_n] ]
    # Set IOSTANDARD
    if {$iostandard == {}} { set iostandard LVDS }
    set_property -quiet IOSTANDARD $iostandard [get_ports ${portName}_p]
    set_property -quiet IOSTANDARD $iostandard [get_ports ${portName}_n]
  } else {
    # Creates net
    set obufNetName [::add_clock_probe::genUniqueName ${obufCellName}_net]
    set obufNetObj [::add_clock_probe::createNet $obufNetName]
    # Connect OBUF -> NET -> PORT
    connect_net -verbose -hier -net $obufNetObj -obj [list [get_pins  $obufCellObj/O] [get_ports $portName] ]
    # Set IOSTANDARD
    if {$iostandard == {}} { set iostandard HSTL }
    set_property -quiet IOSTANDARD $iostandard [get_ports $portName]
  }

  puts " The following cells/ports have been created:"
  puts "       ODDR   : $oddrCellObj"
  if {$diffPort} {
    puts "       OBUFDS : $obufCellObj"
    puts "       PORTs  : ${portName}_p (IOSTANDARD = [get_property -quiet IOSTANDARD [get_ports ${portName}_p] ])"
    puts "              : ${portName}_n (IOSTANDARD = [get_property -quiet IOSTANDARD [get_ports ${portName}_n] ])"
  } else {
    puts "       OBUF   : $obufCellObj"
    puts "       PORT   : $portName (IOSTANDARD = [get_property -quiet IOSTANDARD [get_ports $portName] ])"
  }

  if {$showSchematic} {
    if {$diffPort} {
      set objToShow [list \
                      [get_pins $pinName] \
                      [get_nets -of [get_pins $pinName]] \
                      $oddrCellObj \
                      $oddrNetObj \
                      $obufCellObj \
                      $obufNetObj_N \
                      $obufNetObj_P \
                      [get_ports ${portName}_p] \
                      [get_ports ${portName}_n] \
                  ]
      set objToRemove [filter [get_cells -of [all_fanout [get_pins $pinName] -flat -endpoints_only]] "NAME !~ $oddrCellObj"]
      show_schematic -name $pinName -regenerate $objToShow
      show_schematic -name $pinName -regenerate -remove $objToRemove
      highlight_objects $objToShow -color blue
    } else {
      set objToShow [list \
                      [get_pins $pinName] \
                      [get_nets -of [get_pins $pinName]] \
                      $oddrCellObj \
                      $oddrNetObj \
                      $obufCellObj \
                      $obufNetObj \
                      [get_ports $portName] \
                  ]
      set objToRemove [filter [get_cells -of [all_fanout [get_pins $pinName] -flat -endpoints_only]] "NAME !~ $oddrCellObj"]
      show_schematic -name $pinName -regenerate -add $objToShow
      show_schematic -name $pinName -regenerate -remove $objToRemove
      highlight_objects $objToShow -color blue
    }
  }

  return -code ok
}

######################################################################
##
## Helper procs extracted from insert_buffer.tcl from Xilinx Tcl Store
##
######################################################################

eval [list namespace eval ::add_clock_probe {
  variable debug 0
  variable LOC
} ]

proc ::add_clock_probe::unplaceConnectedCells {name {save 1}} {
  # Summary : check that all attached cells are unplaced. All the connected cells
  # can be forced to be unplaced

  # Argument Usage:
  # name : cell name or net name
  # save : if 1 then the cellplacement is internally saved so that it can be restored afterward

  # Return Value:
  # 0 if all the connected cells are unplaced. 1 otherwise
  # TCL_ERROR if failed

  variable debug
  variable LOC
  set cell [get_cells -quiet $name]
  set net [get_nets -quiet $name]
  set pin [get_pins -quiet $name -filter {IS_LEAF}]
  if {($cell == {}) && ($net == {}) && ($pin == {})} {
    error " error - cannot find a cell, a net or a leaf pin matching $name"
  }
  if {$cell != {}} {
    # This is a cell
#     set placedLeafCells [get_cells -quiet -of \
#                                  [get_nets -of $cell] -filter {IS_PRIMITIVE && PRIMITIVE_LEVEL!="INTERNAL"} ]
    set placedLeafCells [get_cells -quiet -of \
                                 [get_pins -quiet -leaf -of [get_nets -quiet -of $cell]] -filter {IS_PRIMITIVE && (LOC!= "")} ]

#     set fixedLocLeafCells [get_cells -quiet -of \
#                                  [get_pins -quiet -leaf -of [get_nets -quiet -of $cell]] -filter {IS_PRIMITIVE && (LOC!= "") && IS_LOC_FIXED} ]

  } elseif {$net != {}} {
    # This is a net
#     set placedLeafCells [get_cells -quiet -of $net \
#                      -filter {IS_PRIMITIVE && PRIMITIVE_LEVEL!="INTERNAL"} ]
    set placedLeafCells [get_cells -quiet -of [get_pins -quiet -leaf -of $net] \
                     -filter {IS_PRIMITIVE && (LOC!= "")} ]

#     set fixedLocLeafCells [get_cells -quiet -of [get_pins -quiet -leaf -of $net] \
#                      -filter {IS_PRIMITIVE && (LOC!= "") && IS_LOC_FIXED} ]
#     set fixedLocLeafCells [filter $placedLeafCells {IS_LOC_FIXED}]

  } else {
    # This is a pin
#     set placedLeafCells [get_cells -quiet -of [get_pins -quiet -leaf -of [get_nets -quiet -of $pin]] \
#                      -filter {IS_PRIMITIVE && PRIMITIVE_LEVEL!="INTERNAL && (LOC!= "")} ]
    set placedLeafCells [get_cells -quiet -of [get_pins -quiet -leaf -of [get_nets -quiet -of $pin]] \
                     -filter {IS_PRIMITIVE && (LOC!= "")} ]

#     set fixedLocLeafCells [get_cells -quiet -of [get_pins -quiet -leaf -of [get_nets -quiet -of $pin]] \
#                      -filter {IS_PRIMITIVE && (LOC!= "") && IS_LOC_FIXED} ]

  }
  # Remove the IS_LOC_FIXED/IS_BEL_FIXED
  set fixedLocLeafCells [filter $placedLeafCells {IS_LOC_FIXED}]
  set_property -quiet IS_LOC_FIXED 0 $fixedLocLeafCells
  set fixedBelLeafCells [filter $placedLeafCells {IS_BEL_FIXED}]
  set_property -quiet IS_BEL_FIXED 0 $fixedBelLeafCells
  # Now check that all the IS_LOC_FIXED are cleared
  set fixedLocLeafCells [filter $placedLeafCells {IS_LOC_FIXED}]
  if {$fixedLocLeafCells != {}} {
    if {$debug} {
      foreach cell $fixedLocLeafCells {
        puts " DEBUG: cell with fixed LOC: $cell"
      }
    }
    error " ERROR - [llength $fixedLocLeafCells] cell(s) has/have a fixed location and cannot be unplaced"
  }
  if {$placedLeafCells == {}} {
    # OK, all connected cells already unplaced
    return 0
  }

  puts " WARN - [llength $placedLeafCells] cell(s) are placed and will be unplaced"

  if {$save} {
    if {![info exists LOC]} { unset -nocomplain LOC }
    foreach cell $placedLeafCells loc [get_property -quiet LOC $placedLeafCells] bel [get_property -quiet BEL $placedLeafCells] {
      # LOC: SLICE_X23Y125
      # BEL: SLICEL.B5LUT
      set LOC($cell) [list $loc $bel]
      if {$debug>1} {
        puts " DEBUG: cell $cell ([get_property -quiet REF_NAME $cell]) is placed (LOC: $loc / BEL:$bel)"
      }
    }
    if {$debug} {
      puts " DEBUG: unplacing [llength $placedLeafCells] cells"
    }
    unplace_cell $placedLeafCells
  } else {
    return 1
  }

  return 0
}

proc ::add_clock_probe::clearCellLoc {} {
  # Summary : clear the internal database that save the cells location

  # Argument Usage:

  # Return Value:
  # 0 or TCL_ERROR if failed

  variable LOC
  catch {unset LOC}
  return 0
}

proc ::add_clock_probe::restoreCellLoc {{clear 1}} {
  # Summary : check that all attached cells are unplaced. All the connected cells
  # can be forced to be unplaced

  # Argument Usage:
  # clear : if 1 then the array keeping the cell location is deleted after the cells placement has been restored

  # Return Value:
  # 0 if all the connected cells are unplaced. 1 otherwise
  # TCL_ERROR if failed

  variable debug
  variable LOC
  if {![info exists LOC]} {
    return 0
  }
  if {$debug} {
    puts " DEBUG: restoring LOC property for [llength [array names LOC]] cells"
  }
  set cellsToPlace [list]
  set cellsToReset [list]
  foreach cell [array names LOC] {
    foreach {loc bel} $LOC($cell) { break }
    # LOC: SLICE_X23Y125
    # BEL: SLICEL.B5LUT
    # Need to generate the placement info in the following format: SLICE_X23Y125/B5LUT
    set placement "$loc/[lindex [split $bel .] end]"
    lappend cellsToReset $cell
    lappend cellsToPlace $cell
    lappend cellsToPlace $placement
    if {$debug>1} {
      puts " DEBUG: restoring placement for $cell ([get_property -quiet REF_NAME $cell]) at $placement (LOC: $loc / BEL: $bel)"
    }
  }
  # Restore the cell placement in a single call to place_cell
  if {[catch {place_cell $cellsToPlace} errorstring]} {
    puts " -E- $errorstring"
  }
  # Reset the IS_LOC_FIXED/IS_BEL_FIXED properties that are automatically set the place_cell
  set_property -quiet IS_BEL_FIXED 0 $cellsToReset
  set_property -quiet IS_LOC_FIXED 0 $cellsToReset
  # Reset list of cells placement?
  if {$clear} { catch {unset LOC} }
  return 0
}

proc ::add_clock_probe::genUniqueName {name} {
  # Summary : return an unique and non-existing cell or net name

  # Argument Usage:
  # name : base name for the cell or net

  # Return Value:
  # unique cell or net name

  # Names must be unique among the net and cell names
  if {([get_cells -quiet $name] == {}) && ([get_nets -quiet $name] == {})} { return $name }
  set index 0
  while {([get_cells -quiet ${name}_${index}] != {}) || ([get_nets -quiet ${name}_${index}] != {})} { incr index }
  return ${name}_${index}
}

proc ::add_clock_probe::createCell {cellName refName {parentName {}}} {
  # Summary : create a new cell under the parent hierarchical level

  # Argument Usage:
  # cellName : cell name (always from the top-level)
  # refName : cell ref name
  # parentName : parent hierarchical level

  # Return Value:
  # cell object

  variable debug
  if {[get_cells -quiet $cellName] != {}} {
    error " error - cell $cellName already exists"
  }
  set refName [string toupper $refName]
  set cellRef [get_lib_cells -quiet [get_libs]/$refName]
  if {$cellRef == {}} {
    error " error - cannot find cell type $refName"
  }

  # NOTE: the name passed to create_cell needs to be pre-processed
  # when the design has been partially flattened.
  # For example, if original cell is :
  #   ila_dac_baseband_ADC/U0/ila_core_inst/u_ila_regs/reg_15/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[2]
  # but that the parent of that cell is (partially flattened):
  #   ila_dac_baseband_ADC/U0
  # then create_cell cannot be called as below:
  #   create_cell -libref FDRE ila_dac_baseband_ADC/U0/ila_core_inst/u_ila_regs/reg_15/I_EN_CTL_EQ1.U_CTL/xsdb_reg_reg[2]_clone
  # otherwise create_cell tries to create cell xsdb_reg_reg[2]_clone under ila_dac_baseband_ADC/U0/ila_core_inst/u_ila_regs/reg_15/I_EN_CTL_EQ1.U_CTL
  # which does not exist. Instead, create_cell must be called with:
  #   create_cell -libref FDRE {ila_dac_baseband_ADC/U0/ila_core_inst\/u_ila_regs\/reg_15\/I_EN_CTL_EQ1.U_CTL\/xsdb_reg_reg[2]_clone}
  # The code below figures out the parent of the original driver cell and build the command
  # line for create_cell accordingly

  set hierSep [get_hierarchy_separator]
  # remove parent prefix from the cloned cell name to extract the local name
  regsub "^${parentName}${hierSep}" $cellName {} localName
  # escape all the hierarchy separator characters in the local name
  regsub -all $hierSep $localName [format {\%s} $hierSep] localName
  # create the full cell name by appending the escaped local name to the parent name
  if {$parentName != {}} {
    set cellName ${parentName}${hierSep}${localName}
    if {$debug} { puts " DEBUG: cell $cellName ($cellRef) created (parent=$parentName)" }
  } else {
    set cellName ${localName}
    if {$debug} { puts " DEBUG: cell $cellName ($cellRef) created" }
  }
  create_cell -reference $cellRef $cellName
  set cellObj [get_cells -quiet $cellName]
  return $cellObj
}

proc ::add_clock_probe::createNet {netName {parentName {}}} {
  # Summary : create a new net under the parent hierarchical level

  # Argument Usage:
  # netName : net name (always form the top-level)
  # parentName : parent hierarchical level

  # Return Value:
  # net object

  variable debug
  if {[get_nets -quiet $netName] != {}} {
    error " error - net $netName already exists"
  }

  # NOTE: the name passed to create_net needs to be pre-processed for the same reason as for createCell

  set hierSep [get_hierarchy_separator]
  # remove parent cell prefix from the cloned cell name to extract the local name
  regsub "^${parentName}${hierSep}" $netName {} localName
  # escape all the hierarchy separator characters in the local name
  regsub -all $hierSep $localName [format {\%s} $hierSep] localName
  # create the net by appending the escaped local name to the parent name
  if {$parentName != {}} {
    set netName ${parentName}${hierSep}${localName}
    if {$debug} { puts " DEBUG: net ${parentName}${hierSep}${localName} created (parent=$parentName)" }
  } else {
    set netName ${localName}
    if {$debug} { puts " DEBUG: net ${localName} created" }
  }
  create_net -verbose $netName
  set netObj [get_nets -quiet $netName]
  return $netObj
}

proc ::add_clock_probe::disconnectPin {pinName} {
  # Summary : disconnect a pin or port from the net connected to it

  # Argument Usage:
  # pinName : Pin or port name

  # Return Value:
  # 0 if succeeded
  # TCL_ERROR if an error happened

  variable debug
  if {$pinName == {}} {
    error " error - no pin specified"
  }

  set hierSep [get_hierarchy_separator]
#   set pin [get_pins -quiet $pinName]
  set pin [getPinOrPort $pinName]
  switch [llength $pin] {
    0 {
      error " error - cannot find pin or port $pinName"
    }
    1 {
      # Ok
    }
    default {
      # More than 1 pin
      error " error - more than 1 ([llength $pin]) pin or port match $pinName"
    }
  }
  set net [get_nets -quiet -of $pin]
  if {$net == {}} { return 0 }
  
  if {$debug>1} { puts " DEBUG: disconnecting pin $pin from net $net" }
  disconnect_net -verbose -prune -net $net -obj $pin
#   disconnect_net -verbose -net $net -obj $pin
  return 0
}

proc ::add_clock_probe::pinTieHigh {pinName} {
  # Summary : tie pin to VCC

  # Argument Usage:
  # pinName : Pin name

  # Return Value:
  # 0 if succeeded
  # TCL_ERROR if an error happened

  variable debug
  if {$pinName == {}} {
    error " error - no pin specified"
  }

  set hierSep [get_hierarchy_separator]
  set pin [get_pins -quiet $pinName]
  switch [llength $pin] {
    0 {
      error " error - cannot find pin $pinName"
    }
    1 {
      # Ok
    }
    default {
      # More than 1 pin
      error " error - more than 1 ([llength $pin]) pin match $pinName"
    }
  }
  # First, disconnect pin
  if {$debug>1} { puts " DEBUG: disconnectPin $pin" }
  disconnectPin $pin
  # Then tie the pin to VCC
  # Instead of connecting the pin to an existing VCC net, create a new net.
  # Doing this prevent issue when other pins of placed instanced would be connected
  # to an existing power net.
  set parentName [get_property -quiet PARENT [get_property -quiet PARENT_CELL $pin]]
  if {$parentName != {}} {
    set vccname [genUniqueName $parentName/VCC]
    set vcc [createCell $vccname VCC $parentName]
    set netname [genUniqueName ${vccname}_net]
    set net [createNet $netname $parentName]
    connect_net -hier -net $net -obj [get_pins -quiet $vcc/P]
  } else {
    set vccname [genUniqueName VCC]
    set vcc [createCell $vccname VCC]
    set netname [genUniqueName ${vccname}_net]
    set net [createNet $netname]
    connect_net -hier -net $net -obj [get_pins -quiet $vcc/P]
  }
  if {$debug>1} { puts " DEBUG: connect_net -hier -net $net -obj $pin" }
  connect_net -hier -net $net -obj $pin
  return 0
}

proc ::add_clock_probe::pinTieLow {pinName} {
  # Summary : tie pin to GND

  # Argument Usage:
  # pinName : pin name

  # Return Value:
  # 0 if succeeded
  # TCL_ERROR if an error happened

  variable debug
  if {$pinName == {}} {
    error " error - no pin specified"
  }

  set hierSep [get_hierarchy_separator]
  set pin [get_pins -quiet $pinName]
  switch [llength $pin] {
    0 {
      error " error - cannot find pin $pinName"
    }
    1 {
      # Ok
    }
    default {
      # More than 1 pin
      error " error - more than 1 ([llength $pin]) pin match $pinName"
    }
  }
  # First, disconnect pin
  if {$debug>1} { puts " DEBUG: disconnectPin $pin" }
  disconnectPin $pin
  # Then tie the pin to GND
  # Instead of connecting the pin to an existing VCC net, create a new net.
  # Doing this prevent issue when other pins of placed instanced would be connected
  # to an existing power net.
  set parentName [get_property -quiet PARENT [get_property -quiet PARENT_CELL $pin]]
  if {$parentName != {}} {
    set gndname [genUniqueName $parentName/GND]
    set gnd [createCell $gndname GND $parentName]
    set netname [genUniqueName ${gndname}_net]
    set net [createNet $netname $parentName]
    connect_net -hier -net $net -obj [get_pins -quiet $gnd/G]
  } else {
    set gndname [genUniqueName GND]
    set gnd [createCell $gndname GND]
    set netname [genUniqueName ${gndname}_net]
    set net [createNet $netname]
    connect_net -hier -net $net -obj [get_pins -quiet $gnd/G]
  }
  if {$debug>1} { puts " DEBUG: connect_net -hier -net $net -obj $pin" }
  connect_net -hier -net $net -obj $pin
  return 0
}

proc ::add_clock_probe::getPinOrPort {name} {
  # Summary : insert a buffer or any 2-pins cell on a net

  # Argument Usage:
  # name :

  # Return Value:
  # 0 if succeeded or TCL_ERROR if an error happened

  set pin [get_pins -quiet $name]
  if {$pin != {}} { return $pin }
  return [get_ports -quiet $name]
}

#####################################
################ EOF ################
#####################################



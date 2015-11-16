########################################################################################
##
## Company:        Xilinx, Inc.
## Created by:     David Pefourque
##
## Version:        2014.07.10
## Tool Version:   Vivado 2014.1
## Description:    Script to replace BRAMs with DOA_REG/DOB_REG=1 with fabric flip flops
##
########################################################################################

########################################################################################
## 2014.07.10 - Refactorized the code
##            - Fixed some issues
## xxxx-xx-xx - Initial release by John Bieker 
########################################################################################

# BE CAREFUL: will fail on protected IPs:
# ERROR: [Coretcl 2-76] Netlist change for element 'u_clt_to_bk_top0/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/SG/p_60_in[4]' is forbidden by security attributes.  Command failed.
# When this happens, the script skip the BRAM.

# How to use:
# ===========
# set brams [get_selected_objects]
# set brams [get_cells -hier -filter {NAME=~A/B/C/*}]
# set brams [filter [get_cells -hier -filter {PRIMITIVE_GROUP==BMEM}] {DOA_REG==1 || DOB_REG==1}]
# bramRegToFabric $brams

proc bramInsertRegOnNets { nets } {
  
  proc genUniqueName {name} {
    # Names must be unique among the net and cell names
    if {([get_cells -quiet $name] == {}) && ([get_nets -quiet $name] == {})} { return $name }
    set index 0
    while {([get_cells -quiet ${name}_${index}] != {}) || ([get_nets -quiet ${name}_${index}] != {})} { incr index }
    return ${name}_${index}
  }

  # Param to enable netlist changes
  set_param netlist.enableTestChange true
  
  # WARNING: [Coretcl 2-1024] Master cell 'FD' is not supported by the current part and has been retargeted to 'FDRE'.
  set_msg_config -id {Coretcl 2-1024} -limit 0

  set index 0
  ### For every net that exists in the list named $nets, loop
  foreach net $nets {
    incr index
    ### Get the driver pin of the net
    set x [get_pins -of $net -filter {DIRECTION==OUT && IS_LEAF ==1}]
    ### Add an element to the associative array called opin that contains the driver pin of the net
    set opin($net) $x
    ### For readability, create the name of the new flop based on the hierarchy of the bram and append the string fd_#
    set ff_name [genUniqueName [get_property PARENT [get_cells -of $x]]/fd_$index]
    ### For readability, create the name of the new net based on the hierarchy of the bram and append the string ram_to_fd_#
    set net_name [genUniqueName [get_property PARENT [get_cells -of $x]]/ram_to_fd_$index]
    ### Create the new FD cell
    if {[catch {debug::create_cell -reference FD $ff_name} errorstring]} {
      # Did the following error happened for protected IPs?
      # ERROR: [Coretcl 2-76] Netlist change for element 'u_clt_to_bk_top0/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/SG' is forbidden by security attributes.  Command failed.
      if {[regexp -nocase {is forbidden by security attributes} $errorstring]} {
        # Yes. Do not genereate a TCL_ERROR but a warning
        puts " -W- Cannot modify the netlist of a protected IP. No register inserted on net $net . Other nets are skipped."
        return 1
      } else {
        # No, then return the TCL_ERROR
        error $string
      }
    }
    ### Create the new net to connect from output of bram to D pin of the new FD
    debug::create_net $net_name
    ### Disconnect the driver net from the bram because the new driver comes from the Q of the FD
    debug::disconnect_net -net $net -objects $opin($net)
    ### Connect the old net to the new driver (FD/Q)
    debug::connect_net -net $net -objects [get_pins $ff_name/Q]
    ### Connect the driver side of the new net to the output of the BRAM
    debug::connect_net -net $net_name -objects $opin($net)
    ### Connect the load side of the new net to the D input of the new FD
    debug::connect_net -net $net_name -objects [get_pins $ff_name/D]
    ### Connect the clock of the new FD to the clock input of the BRAM that contains the string *RD* (ie the read clock)
    debug::connect_net -net [get_nets -of [get_pins -of [get_cells -of [get_nets $net_name]] -filter {IS_CLOCK == 1 && NAME =~ *RD*}]] -objects [get_pins $ff_name/C]
  }
  
  # WARNING: [Coretcl 2-1024] Master cell 'FD' is not supported by the current part and has been retargeted to 'FDRE'.
  reset_msg_config -id {Coretcl 2-1024} -limit
  
  # Param to enable netlist changes
  set_param netlist.enableTestChange false

  return 0
}

proc bramRegToFabric { cells } {

  # Param to enable netlist changes
  set_param netlist.enableTestChange true
  
  puts " -I- Started on [clock format [clock seconds]]"

  set brams [filter -quiet [get_cells -quiet $cells] {PRIMITIVE_GROUP==BMEM && DOA_REG==1}]
  if {$brams != {}} {
    set i 0
    foreach ram $brams {
      puts " -I- Processing ([incr i]/[llength $brams]) $ram (DOA_REG)"
      ### Create a list called nets of all of the nets connected to output pins of the BRAMs
      set pins [get_pins -quiet -of [get_cells $ram] -filter {(REF_PIN_NAME=~DOA* || REF_PIN_NAME=~DOPA*) && DIRECTION==OUT && IS_CONNECTED}]
      if {$pins == {}} { continue }
      set nets [get_nets -of $pins]
      puts " -I- Inserting FD on [llength $pins] pin(s): $pins"
      puts " -I- Started on [clock format [clock seconds]]"
      if {[catch {set res [bramInsertRegOnNets $nets]} errorstring]} {
        puts " -E- bramInsertRegOnNets: $errorstring"
      } else {
        if {$res == 0} {
          set_property {DOA_REG} 0 [get_cells $ram]
        }
      }
      puts " -I- Completed on [clock format [clock seconds]]"
    }
  }
  
  set brams [filter -quiet [get_cells -quiet $cells] {PRIMITIVE_GROUP==BMEM && DOB_REG==1}]
  if {$brams != {}} {
    set i 0
    foreach ram $brams {
      puts " -I- Processing ([incr i]/[llength $brams]) $ram (DOB_REG)"
      ### Create a list called nets of all of the nets connected to output pins of the BRAMs
      set pins [get_pins -quiet -of [get_cells $ram] -filter {(REF_PIN_NAME=~DOB* || REF_PIN_NAME=~DOPB*) && DIRECTION==OUT && IS_CONNECTED}]
      if {$pins == {}} { continue }
      set nets [get_nets -of $pins]
      puts " -I- Inserting FD on [llength $pins] pin(s): $pins"
      puts " -I- Started on [clock format [clock seconds]]"
      if {[catch {set res [bramInsertRegOnNets $nets]} errorstring]} {
        puts " -E- bramInsertRegOnNets: $errorstring"
      } else {
        if {$res == 0} {
          set_property {DOB_REG} 0 [get_cells $ram]
        }
      }
      puts " -I- Completed on [clock format [clock seconds]]"
    }
  }
  
  puts " -I- Completed on [clock format [clock seconds]]"

  # Param to enable netlist changes
  set_param netlist.enableTestChange false

  return -code ok
}

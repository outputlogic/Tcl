########################################################################################
##
## Company:        Xilinx, Inc.
## Created by:     David Pefourque
##
## Version:        2015.11.19
## Tool Version:   Vivado 2014.1
## Description:    Script to replace BRAMs with DOA_REG/DOB_REG=1 with fabric flip flops
##                 The script can also move out the register out of registered FIFOs to
##                 the fabric
##
########################################################################################

# proc [file tail [info script]] {} " source [info script]; puts \" [info script] reloaded\" "
# proc reload {} " source [info script]; puts \" [info script] reloaded\" "

########################################################################################
## 2015.11.19 - Improved runtime by connecting/disconnecting all pins at once
##            - Added unsafe mode to create multiple FD at once instead of one by one
##            - Added fifoRegToFabric to remove registers from FIFOs
##            - Cleaned-up code
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
# # SAFE mode:
# bramRegToFabric $brams
# # UNSAFE mode:
# bramRegToFabric $brams 0
#
# set fifos [get_cells -hier -filter {REF_NAME=~FIFO36* && REGISTER_MODE==REGISTERED}]
# # SAFE mode:
# fifoRegToFabric $fifos
# # UNSAFE mode:
# fifoRegToFabric $fifos 0

proc bramInsertRegOnNets { nets &arDisconnect &arConnect {safe 1} } {

  upvar ${&arDisconnect} disconnect
  upvar ${&arConnect} connect

  set createNets [list]
  set createCells [list]

  proc genUniqueName {name} {
    # Names must be unique among the net and cell names
    if {([get_cells -quiet $name] == {}) && ([get_nets -quiet $name] == {})} { return $name }
    set index 0
    while {([get_cells -quiet ${name}_${index}] != {}) || ([get_nets -quiet ${name}_${index}] != {})} { incr index }
    return ${name}_${index}
  }

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
    if {$safe} {
    	# In safe mode, each FD is created sequentially
      if {[catch {create_cell -quiet -reference FD $ff_name} errorstring]} {
        # Did the following error happened for protected IPs?
        # ERROR: [Coretcl 2-76] Netlist change for element 'u_clt_to_bk_top0/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/SG' is forbidden by security attributes.  Command failed.
        if {[regexp -nocase {is forbidden by security attributes} $errorstring]} {
          # Yes. Do not genereate a TCL_ERROR but a warning
          puts " -W- Cannot modify the netlist of a protected IP. No register inserted on net $net . Other nets are skipped."
          # Before exiting, create nets that should be created
          if {[llength $createNets]} {
            puts " -I- Creating [llength $createNets] net(s)"
            create_net -quiet $createNets
          }
          return 1
        } else {
          # Before exiting, create nets that should be created
          if {[llength $createNets]} {
            puts " -I- Creating [llength $createNets] net(s)"
            create_net -quiet $createNets
          }
          # No, then return the TCL_ERROR
          error $string
        }
      }
      puts " -I- Creating FD $ff_name"
    } else {
    	# In unsafe mode, all FDs are created at once
      lappend createCells $ff_name
    }
    ### Create the new net to connect from output of bram to D pin of the new FD
    lappend createNets $net_name
    ### Disconnect the driver net from the bram because the new driver comes from the Q of the FD
    if {[info exists disconnect($net)]} {
    	set disconnect($net) [lsort -unique [concat $disconnect($net) $opin($net)]]
    } else {
    	set disconnect($net) $opin($net)
    }
#     disconnect_net -net $net -objects $opin($net)
    ### Connect the old net to the new driver (FD/Q)
    if {[info exists connect($net)]} {
  	  set connect($net) [lsort -unique [concat $connect($net) $ff_name/Q ]]
#     	set connect($net) [lsort -unique [concat $connect($net) [get_pins -quiet $ff_name/Q] ]]
    } else {
    	set connect($net) $ff_name/Q
#     	set connect($net) [get_pins -quiet $ff_name/Q]
    }
#     connect_net -net $net -objects [get_pins $ff_name/Q]
    ### Connect the driver side of the new net to the output of the BRAM
    if {[info exists connect($net_name)]} {
    	set connect($net_name) [lsort -unique [concat $connect($net_name) [list $ff_name/D $opin($net) ] ]]
#     	set connect($net_name) [lsort -unique [concat $connect($net_name) [list [get_pins -quiet $ff_name/D] $opin($net) ] ]]
    } else {
    	set connect($net_name) [list $ff_name/D $opin($net) ]
#     	set connect($net_name) [list [get_pins -quiet $ff_name/D] $opin($net) ]
    }
#     connect_net -net $net_name -objects $opin($net)
    ### Connect the load side of the new net to the D input of the new FD
#     connect_net -net $net_name -objects [get_pins $ff_name/D]
    ### Connect the clock of the new FD to the clock input of the BRAM/FIFO that contains the string *RD* (ie the read clock)
    set clockNet [get_nets -of [get_pins -of [get_cells -of [get_nets $net]] -filter {IS_CLOCK == 1 && NAME =~ *RD*}]]
    if {[info exists connect($clockNet)]} {
    	set connect($clockNet) [lsort -unique [concat $connect($clockNet) $ff_name/C ]]
#     	set connect($clockNet) [lsort -unique [concat $connect($clockNet) [get_pins -quiet $ff_name/C] ]]
    } else {
    	set connect($clockNet) $ff_name/C
#     	set connect($clockNet) [get_pins -quiet $ff_name/C]
    }
#     connect_net -net [get_nets -of [get_pins -of [get_cells -of [get_nets $net_name]] -filter {IS_CLOCK == 1 && NAME =~ *RD*}]] -objects [get_pins $ff_name/C]
  }

  # WARNING: [Coretcl 2-1024] Master cell 'FD' is not supported by the current part and has been retargeted to 'FDRE'.
  reset_msg_config -id {Coretcl 2-1024} -limit

  # Create registers
  if {[llength $createCells]} {
    puts " -I- Creating [llength $createCells] FD(s)"
    create_cell -quiet -reference FD $createCells
  }

  # Create nets
  if {[llength $createNets]} {
    puts " -I- Creating [llength $createNets] net(s)"
    create_net -quiet $createNets
  }

  return 0
}

# proc bramRegToFabric { cells &arDisconnect &arConnect } {}
proc bramRegToFabric { cells { safe 1 } } {

#   upvar ${&arDisconnect} arDisconnect
#   upvar ${&arConnect} arConnect

  catch { unset arDisconnect }
  catch { unset arConnect }

  set debug 0

  set startTime [clock seconds]
  puts " -I- Started on [clock format $startTime]"

  set brams [filter -quiet [get_cells -quiet $cells] {REF_NAME=~RAMB* && DOA_REG==1}]
# set brams [filter -quiet [get_cells -quiet $cells] {REF_NAME=~RAMB*}]
#   set brams [filter -quiet [get_cells -quiet $cells] {PRIMITIVE_GROUP==BMEM && DOA_REG==1}]
  if {$brams != {}} {
    set i 0
    foreach ram $brams {
      puts " -I- Processing ([incr i]/[llength $brams]) $ram (DOA_REG)"
      ### Create a list called nets of all of the nets connected to output pins of the BRAMs
#       set pins [get_pins -quiet -of [get_cells $ram] -filter {REF_PIN_NAME=~DO*A* && DIRECTION==OUT && IS_CONNECTED}]
      set pins [get_pins -quiet -of [get_cells $ram] -filter {(REF_PIN_NAME=~DOA* || REF_PIN_NAME=~DOPA*) && DIRECTION==OUT && IS_CONNECTED}]
      if {$pins == {}} { continue }
      set nets [get_nets -of $pins]
      puts " -I- Inserting FD on [llength $pins] pin(s): $pins"
      if {[catch {set res [bramInsertRegOnNets $nets arDisconnect arConnect $safe]} errorstring]} {
        puts " -E- bramInsertRegOnNets: $errorstring"
      } else {
        if {$res == 0} {
          set_property {DOA_REG} 0 [get_cells $ram]
        }
      }
    }
  }

  set brams [filter -quiet [get_cells -quiet $cells] {REF_NAME=~RAMB* && DOB_REG==1}]
# set brams [filter -quiet [get_cells -quiet $cells] {REF_NAME=~RAMB*}]
#   set brams [filter -quiet [get_cells -quiet $cells] {PRIMITIVE_GROUP==BMEM && DOB_REG==1}]
  if {$brams != {}} {
    set i 0
    foreach ram $brams {
      puts " -I- Processing ([incr i]/[llength $brams]) $ram (DOB_REG)"
      ### Create a list called nets of all of the nets connected to output pins of the BRAMs
#       set pins [get_pins -quiet -of [get_cells $ram] -filter {REF_PIN_NAME=~DO*B* && DIRECTION==OUT && IS_CONNECTED}]
      set pins [get_pins -quiet -of [get_cells $ram] -filter {(REF_PIN_NAME=~DOB* || REF_PIN_NAME=~DOPB*) && DIRECTION==OUT && IS_CONNECTED}]
      if {$pins == {}} { continue }
      set nets [get_nets -of $pins]
      puts " -I- Inserting FD on [llength $pins] pin(s): $pins"
      if {[catch {set res [bramInsertRegOnNets $nets arDisconnect arConnect $safe]} errorstring]} {
        puts " -E- bramInsertRegOnNets: $errorstring"
      } else {
        if {$res == 0} {
          set_property {DOB_REG} 0 [get_cells $ram]
        }
      }
    }
  }

  # Debug
#   catch { parray arDisconnect }
#   catch { parray arConnect }

  set loads [list]
  foreach net [array names arDisconnect] {
  	set loads [concat $loads $arDisconnect($net)]
  }
  set loads [get_pins -quiet [lsort -unique $loads]]
  if {[llength $loads]} {
    puts " -I- Disconnecting [llength $loads] load(s)"
    foreach el $loads {
    	if {$debug} { puts " -D-      $el" }
    }
  	disconnect_net -objects $loads
  }

#   foreach net [array names arDisconnect] {
#   	puts " -I- Disconnecting net $net from [llength $arDisconnect($net)] load(s)"
#   	disconnect_net -net $net -objects [get_pins -quiet $arDisconnect($net)]
#   }

  # Connect all the pins and nets at once
  if {[llength [array names arConnect]]} {
    puts " -I- Connecting [llength [array names arConnect]] net(s)"
    foreach el [lsort [array names arConnect]] {
    	if {$debug} { puts " -D-      $el \t [lsort $arConnect($el)]" }
    }
  	connect_net -hier -net_object_list [array get arConnect]
  }

#   foreach net [array names arConnect] {
#   	puts " -I- Disconnecting net $net from [llength $arDisconnect($net)] load(s)"
#   	connect_net -hier -net_object_list [array get arConnect]
#   }

  set stopTime [clock seconds]
  puts " -I- Completed on [clock format $stopTime]"
  puts " -I- Completed in [expr $stopTime - $startTime] seconds"

  return -code ok
}

proc fifoRegToFabric { cells { safe 1 } } {

  catch { unset arDisconnect }
  catch { unset arConnect }

  set debug 0

  set startTime [clock seconds]
  puts " -I- Started on [clock format $startTime]"

  set fifos [filter -quiet [get_cells -quiet $cells] {REF_NAME=~FIFO36* && REGISTER_MODE=={REGISTERED}}]
  if {$fifos != {}} {
    set i 0
    foreach fifo $fifos {
      puts " -I- Processing ([incr i]/[llength $fifos]) $fifo (REGISTER_MODE)"
      ### Create a list called nets of all of the nets connected to output pins of the FIFO36
      set pins [get_pins -quiet -of [get_cells $fifo] -filter {REF_PIN_NAME=~DOUT* && DIRECTION==OUT && IS_CONNECTED}]
      if {$pins == {}} { continue }
      set nets [get_nets -of $pins]
      puts " -I- Inserting FD on [llength $pins] pin(s): $pins"
      if {[catch {set res [bramInsertRegOnNets $nets arDisconnect arConnect $safe]} errorstring]} {
        puts " -E- bramInsertRegOnNets: $errorstring"
      } else {
        if {$res == 0} {
          set_property {REGISTER_MODE} {UNREGISTERED} [get_cells $fifo]
        }
      }
    }
  }

  set loads [list]
  foreach net [array names arDisconnect] {
  	set loads [concat $loads $arDisconnect($net)]
  }
  set loads [get_pins -quiet [lsort -unique $loads]]
  if {[llength $loads]} {
    puts " -I- Disconnecting [llength $loads] load(s)"
    foreach el $loads {
    	if {$debug} { puts " -D-      $el" }
    }
  	disconnect_net -objects $loads
  }

  # Connect all the pins and nets at once
  if {[llength [array names arConnect]]} {
    puts " -I- Connecting [llength [array names arConnect]] net(s)"
    foreach el [lsort [array names arConnect]] {
    	if {$debug} { puts " -D-      $el \t [lsort $arConnect($el)]" }
    }
  	connect_net -hier -net_object_list [array get arConnect]
  }

  set stopTime [clock seconds]
  puts " -I- Completed on [clock format [clock seconds]]"
  puts " -I- Completed in [expr $stopTime - $startTime] seconds"

  return -code ok
}

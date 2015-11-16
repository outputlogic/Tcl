
# Proc to reload current script
proc [file tail [info script]] {} " source [info script]; puts \" [info script] reloaded\" "


#
# This proc returns statistics regarding a hierarchical cell. It also provides a way to select/highlight cells inside the
# hierarchical module and those connected to it.
#
# For example:
#   vivado% report_hier_cell_stats dut_module_inst/dut_subsys0/f4_de/f4_dl2ri_inst0/f4_l2ri_inst/f4_l2ri_fire_inst/genblk1[8].fire_stage
#
#    dut_module_inst/dut_subsys0/f4_de/f4_dl2ri_inst0/f4_l2ri_inst/f4_l2ri_fire_inst/genblk1[8].fire_stage :
#      Internal elements of hierarchical cell:
#        # nets : 24187
#        # cells: 18022
#        # pins : 90172
#        # I/O  : 11584
#      External elements connected to hierarchical cell:
#        # cells: 57461
#        # pins : 102897
#      Average pin/net (int): 3.207053375780378
#      Average pin/net (int+ext): 6.982345888287097
#      Detailed cell distribution (int):
#            REF_NAME:
#                   CARRY4: 71
#                     FDRE: 5819
#                     LUT1: 2
#                     LUT2: 134
#                     LUT3: 1885
#                     LUT4: 466
#                     LUT5: 1328
#                     LUT6: 5544
#                    MUXF7: 1863
#                    MUXF8: 910
#            PRIMITIVE_GROUP:
#                    CARRY: 71
#               FLOP_LATCH: 5819
#                      LUT: 9359
#                    MUXFX: 2773
#      Detailed cell distribution (int+ext):
#            REF_NAME:
#                   CARRY4: 71
#                     FDRE: 51079
#                     FDSE: 1
#                     LUT1: 2
#                     LUT2: 302
#                     LUT3: 4230
#                     LUT4: 938
#                     LUT5: 5529
#                     LUT6: 10558
#                    MUXF7: 1863
#                    MUXF8: 910
#            PRIMITIVE_GROUP:
#                    CARRY: 71
#               FLOP_LATCH: 51080
#                      LUT: 21559
#                    MUXFX: 2773
#

proc report_hier_cell_stats {args} {

  proc lshift {inputlist} {
    upvar $inputlist argv
    set arg  [lindex $argv 0]
    set argv [lrange $argv 1 end]
    return $arg
  }

  #-------------------------------------------------------
  # Process command line arguments
  #-------------------------------------------------------
  set hierCellName {}
  set selectObjects 0
  set highlightObjects 0
  set color1 {red}
  set color2 {green}
  set verbose 0
  set error 0
  set help 0
  if {[llength $args] == 0} { incr help }
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -cell -
      -c {
           set hierCellName [lshift args]
      }
      -select_objects -
      -select -
      -s {
           set selectObjects 1
      }
      -highlight_objects -
      -highlight -
      -hi {
           set highlightObjects 1
      }
      -color {
           set color1 [lshift args]
           set color2 [lshift args]
      }
      -v -
      -verbose {
            set verbose 1
      }
      -h -
      -help {
            incr help
      }
      default {
            if {[string match "-*" $name]} {
              puts " ERROR - option '$name' is not a valid option."
              incr error
            } else {
              set hierCellName $name
            }
      }
    }
  }

  if {$help} {
    set callerName [lindex [info level [expr [info level] -1]] 0]
    # <-- HELP
    puts [format {
  Usage: %s
              [-cell|-c <hierarchical cell>]
              [-select_objects|-select]
              [-highlight_objects|-highlight]
              [-color <color1> <color2>]
              [-verbose|-v]
              [-help|-h]

  Description: reports various statistics on a hierarchical cell.
  
  -select_objects: select all the cells inside the hierarchical cell
  -highlight_objects: highlight all the cells inside the hierarchical cell with color1
     and all the cells connected to the hierarchical module with color2
  -color: change default colors (color1:red color2:green)

  Example:
     report_hier_cell_stats myHierCell
     report_hier_cell_stats -cell myHierCell
     report_hier_cell_stats -cell myHierCell -verbose -color yellow red -highlight_objects

} $callerName]
    # HELP -->
    return {}
  }

  set hierCell [get_cells -quiet $hierCellName]
  if {$hierCell == {}} {
    puts " -E- Hierarchical cell '$hierCellName' does not exist"
    incr error
  }

  if {$error} {
    error { -E- Some error(s) occured. Cannot continue.}
  }

  set hierPinCount 0
  if {[llength $hierCell] == 1} {
#     if {[current_instance . -quiet] == [get_property TOP [current_design]]} {
#       set hierPinCount [llength [get_nets -filter {TYPE == SIGNAL} -of [get_ports] -quiet]]
#     } else {
#       set hierPinCount [llength [get_nets -quiet -filter {TYPE == SIGNAL} -of [get_pins -of $hierCell]]]
# #       set hierPinCount [llength [get_pins -quiet -filter "NAME =~ [current_instance . -quiet]/*" -leaf -of $nets]]
#     }
    set hierPinCount [llength [get_nets -quiet -filter {TYPE == SIGNAL} -of [get_pins -of $hierCell]]]
  }

#   current_instance -quiet $hierCell

#   set leafCells [get_cells -quiet -hier * -filter {IS_PRIMITIVE && REF_NAME!=VCC && REF_NAME!=GND}]
  set leafCells [get_cells -quiet -hier -filter "NAME=~$hierCellName/* && IS_PRIMITIVE && REF_NAME!=VCC && REF_NAME!=GND"]

#   set nets [get_nets -quiet -hier -top_net_of_hierarchical_group -filter {TYPE == SIGNAL}]
  set nets [get_nets -quiet -of $leafCells -filter {TYPE == SIGNAL}]

  set allLeafPins [get_pins -quiet -leaf -of $nets -filter {!IS_CLOCK}]
  set allLeafCells [get_cells -quiet -of $allLeafPins -filter {IS_PRIMITIVE}]
#   set intLeafPins [filter $allLeafPins "NAME =~ [current_instance . -quiet]/*"]
  set intLeafPins [filter $allLeafPins "NAME =~ $hierCellName/*"]
#   set extLeafPins [filter $allLeafPins "NAME !~ [current_instance . -quiet]/*"]
  set extLeafPins [filter $allLeafPins "NAME !~ $hierCellName/*"]
  set intLeafCells [lsort -unique [get_cells -quiet -of $intLeafPins -filter {IS_PRIMITIVE}]]
  set extLeafCells [lsort -unique [get_cells -quiet -of $extLeafPins -filter {IS_PRIMITIVE}]]

  puts " $hierCellName :"
  puts "   Internal elements of hierarchical cell:"
  puts "     # nets : [llength $nets]"
  puts "     # cells: [llength $intLeafCells]"
  puts "     # pins : [llength $intLeafPins]"
  if {[llength $hierCell] == 1} {
    puts "     # I/O  : $hierPinCount"
  }
  puts "   External elements connected to hierarchical cell:"
  puts "     # cells: [llength $extLeafCells]"
  puts "     # pins : [llength $extLeafPins]"
  if {[llength $hierCell] == 1} {
    puts "   Average pin/net (int): [expr double([llength $intLeafPins] + $hierPinCount - [llength $nets]) / [llength $nets]]"
    puts "   Average pin/net (int+ext): [expr double([llength $intLeafPins] + [llength $extLeafPins] - [llength $nets]) / [llength $nets]]"
  }

  if {$verbose} {
    puts "   Detailed cell distribution (int):"
    catch {unset refCount}
    set allRefNames [get_property REF_NAME $intLeafCells]
    set refNames [lsort -unique $allRefNames]
    foreach refName $refNames {
      set refCount($refName) [llength [lsearch -all -exact $allRefNames $refName]]
    }
    puts "         REF_NAME:"
    foreach ref_name $refNames {
      puts [format {            %10s: %s} $ref_name $refCount($ref_name)]
    }

    catch {unset pgCount}
    set allPrimGroups [get_property PRIMITIVE_GROUP $intLeafCells]
    set primGroups [lsort -unique $allPrimGroups]
    foreach primGroup $primGroups {
      set pgCount($primGroup) [llength [lsearch -all -exact $allPrimGroups $primGroup]]
    }
    puts "         PRIMITIVE_GROUP:"
    foreach primGroup $primGroups {
      puts [format {            %10s: %s} $primGroup $pgCount($primGroup)]
    }

    puts "   Detailed cell distribution (int+ext):"
    catch {unset refCount}
    set allRefNames [get_property REF_NAME $allLeafCells]
    set refNames [lsort -unique $allRefNames]
    foreach refName $refNames {
      set refCount($refName) [llength [lsearch -all -exact $allRefNames $refName]]
    }
    puts "         REF_NAME:"
    foreach ref_name $refNames {
      puts [format {            %10s: %s} $ref_name $refCount($ref_name)]
    }

    catch {unset pgCount}
    set allPrimGroups [get_property PRIMITIVE_GROUP $allLeafCells]
    set primGroups [lsort -unique $allPrimGroups]
    foreach primGroup $primGroups {
      set pgCount($primGroup) [llength [lsearch -all -exact $allPrimGroups $primGroup]]
    }
    puts "         PRIMITIVE_GROUP:"
    foreach primGroup $primGroups {
      puts [format {            %10s: %s} $primGroup $pgCount($primGroup)]
    }
  }

  if {$selectObjects} {
    select_objects -quiet $intLeafCells
    puts "   # selected cells: [llength $intLeafCells]"
  }

  if {$highlightObjects} {
    highlight_objects -quiet -color $color2 $extLeafCells
    puts "   # highlighted cells ($color2): [llength $extLeafCells]"
    highlight_objects -quiet -color $color1 $intLeafCells
    puts "   # highlighted cells ($color1): [llength $intLeafCells]"
  }

#   current_instance -quiet
#   current_instance -quiet $currentInstance

  return 0
}


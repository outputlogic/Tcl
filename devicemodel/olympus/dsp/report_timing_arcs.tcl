
# Proc to reload current script
proc [file tail [info script]] {} " source [info script]; puts \" [info script] reloaded\" "

lappend auto_path /home/dpefour/git/scripts/toolbox
catch {package require toolbox}

package require sqlite3

# Execute the SQL command. When failed, retry until the database is unlocked
proc wait_db_ready { &SQL {cmd {pragma integrity_check} } } {
  upvar &SQL SQL
  # Wait for the database to be unlocked
  while {[catch { SQL eval $cmd } errorstring]} {
    if {[regexp {database is locked} $errorstring]} {
      puts "SQL database locked ..."
      exec sleep 1
    } elseif {[regexp {attempt to write a readonly database} $errorstring]} {
      puts "SQL database read-only ..."
      exec sleep 1
    } else {
      error $errorstring
    }
  }
  return 0
}

namespace eval ::report_timing_arcs {
    namespace export report_timing_arcs generate_veam_configs

    variable version {12-03-2013}
    variable sitemap2
    variable verbose 0
    variable debug 0
}

# proc report_timing_arcs { args } {
#   uplevel [concat ::report_timing_arcs::report_timing_arcs $args]
# }

# proc generate_veam_configs { args } {
#   uplevel [concat ::report_timing_arcs::generate_veam_configs $args]
# }

proc ::report_timing_arcs::init {} {
  variable sitemap2
  catch {unset sitemap2}
  if {[file exists ./kintex7_sitemap2.ftcl]} {
    puts " -I- sourcing [file normalize ./kintex7_sitemap2.ftcl]"
    array set sitemap2 [source ./kintex7_sitemap2.ftcl]
  } elseif {[file exists /wrk/hdstaff/dpefour/support/Olympus/dotlib/kintex7_sitemap2.ftcl]} {
    puts " -I- sourcing [file normalize /wrk/hdstaff/dpefour/support/Olympus/dotlib/kintex7_sitemap2.ftcl]"
    array set sitemap2 [source /wrk/hdstaff/dpefour/support/Olympus/dotlib/kintex7_sitemap2.ftcl]
  }
  if {[file exists ./kintex8_sitemap2.ftcl]} {
    puts " -I- sourcing [file normalize ./kintex8_sitemap2.ftcl]"
    array set sitemap2 [source ./kintex8_sitemap2.ftcl]
  } elseif {[file exists /wrk/hdstaff/dpefour/support/Olympus/dotlib/kintex8_sitemap2.ftcl]} {
    puts " -I- sourcing [file normalize /wrk/hdstaff/dpefour/support/Olympus/dotlib/kintex8_sitemap2.ftcl]"
    array set sitemap2 [source /wrk/hdstaff/dpefour/support/Olympus/dotlib/kintex8_sitemap2.ftcl]
  } else {
    puts " -I- using internal sitemap2 data"
    array set sitemap2 [::report_timing_arcs::sitemap2]
  }
  return 0
}

proc ::report_timing_arcs::generate_veam_configs {cell} {
  set cellObj [get_cells -quiet $cell]
  if {$cellObj == {}} {
    error " error - only cells are supported"
  }
  foreach cell $cellObj {
    genAllVeamConfigs $cell
  }
  return 0
}

proc ::report_timing_arcs::lskim { L key } {
  set res [list]
  foreach elm $L {
    catch {unset ar}
    array set ar $elm
    if {[info exists ar($key)]} { lappend res $ar($key) }
  }
  set res
}

proc ::report_timing_arcs::report_timing_arcs {args} {
  variable version
  variable verbose
  variable debug

#   set db7 {/wrk/hdstaff/dpefour/support/Olympus/dotlib/latest/kintex7.db}
#   set db8 {/wrk/hdstaff/dpefour/support/Olympus/dotlib/latest/kintex8.db}
  set db7 {/wrk/hdstaff/dpefour/support/Olympus/dotlib/kintex7.db}
  set db8 {/wrk/hdstaff/dpefour/support/Olympus/dotlib/kintex8.db}
  set db {}
  set channel {stdout}
  set objects [list]
  set engine {}
  set filename {}
  set filemode {w}
  # Temporary file for internal::report_enabled_arcs
  set veamtemp "veam.[uplevel #0 pid].tmp"
  set veamlog "veam.[uplevel #0 pid].log"
  # Default veam attributes
  set veamattr {}
  set error 0
#   set verbose 0
#   set debug 0
  set show_help 0
  if {[llength $args] == 0} {
    incr show_help
  }
  #-------------------------------------------------------
  # Process command line arguments
  #-------------------------------------------------------
  while {[llength $args]} {
    set name [::tb::lshift args]
    switch -exact -- $name {
      -of -
      --of {
        set objects [::tb::lshift args]
      }
      -db -
      --db {
        set db [::tb::lshift args]
      }
      -veam -
      --veam {
        append engine {|veam}
      }
      -sql -
      --sql -
      -dotlib -
      --dotlib {
        append engine {|sql}
      }
      -timer -
      --timer {
        append engine {|timer}
      }
      -file -
      --file {
        set filename [::tb::lshift args]
      }
      -veamattr -
      --veamattr {
        set veamattr [::tb::lshift args]
      }
      -veamlog -
      --veamlog {
        set veamlog [::tb::lshift args]
      }
      -a -
      --append {
        set filemode {a}
      }
      -v -
      -verbose {
          set verbose 1
      }
      -d -
      -debug {
          set debug 1
          set verbose 1
      }
      -h -
      -help {
          incr show_help
      }
      default {
          if {[string match "-*" $name]} {
            puts " -E- option '$name' is not a valid option"
            incr error
          } else {
            puts " -E- option '$name' is not a valid option"
            incr error
          }
      }
    }
  }

  if {$show_help} {
    # <-- HELP
    puts [format {
      Usage: report_timing_arcs
                  [-of <list of cell or pin objects>]
                  [-timer|-veam|-dotlib]
                  [-file <filename>]
                  [-append|-a]
                  [-veamattr <veam attributes list>]
                  [-veamlog <filename>]
                  [-db <SQLite database>]
                  [-verbose|-v]
                  [-help|-h]

      Description: Utility to report timing arcs from either the Dotlib, the timer or the Veam conditions
        If -of is ommited, the command uses the list of selected objects (get_selected_objects)

      Version: %s

      Example:
         report_timing_arcs
         report_timing_arcs -dotlib -timer -of [get_selected_objects] -file myreport.rpt
         report_timing_arcs -veam -of [get_selected_objects] -veamlog veam.log -veamattr {PROP1 VAL1 PROP2 VAL2} -file myreport.rpt

    } $version ]
    # HELP -->

    return 0
  }

  if {$error} {
    error " error - some error(s) occured. Cannot continue"
  }

  if {[regexp {sql} $engine]} {
    # If no SQL database is provided, check for a local file, if not, use default databases
    if {$db == {}} {
      set arch [get_property -quiet ARCHITECTURE [get_property -quiet PART [current_project]]]
      if {[regexp {8$} $arch]} {
        if {[file exists "./kintex8.db"]} {
          set db [file normalize kintex8.db]
        } else {
          set db $db8
        }
      } else {
        if {[file exists "./kintex7.db"]} {
          set db [file normalize kintex7.db]
        } else {
          set db $db7
        }
      }
    }
    if {![file exists $db]} {
      error " File $db does not exist"
    }
  } elseif {$engine == {}} {
    set engine {timer}
  }

  if {$objects == {}} {
    set objects [get_selected_objects]
  }

  set class [lsort -unique [get_property -quiet CLASS $objects]]
  if {[llength $class] > 1} {
    error " error - does not support multiple object types ($class)"
  }

  if {$class == {pin}} {
    set dir [lsort -unique [get_property -quiet DIRECTION $objects]]
    if {[llength $dir] > 1} {
      error " error - does not support a list of pins of different direction ($dir)"
    }
  }

  if {$class == {cell}} {
    set ref_name [lsort -unique [get_property -quiet REF_NAME $objects]]
    if {[llength $ref_name] > 1} {
      error " error - does not support a list of cells of different REF_NAME ($ref_name)"
    }
  }

  if {$filename != {}} {
    puts " Creating file [file normalize $filename]"
    set channel [open $filename $filemode]
  }

  #-------------------------------------------------------
  # SQL query to extract timing arcs from Dotlib
  #-------------------------------------------------------

  if {[regexp {sql} $engine]} {
    sqlite3 SQL $db -readonly true
    wait_db_ready SQL
    puts $channel " -I- engine: dotlib"
    puts $channel " -I- DB: $db"
    puts $channel " -I- start time: [clock format [clock seconds]]"
    switch $class {
      pin {
        puts $channel " -I- pins [::tb::collapseBusNames $objects]"
        set numpins 0
        set numarcs 0
        # Since all the pins belong to the same cell, the ref name is extracted from the first pin
        puts $channel " -I- ref_name: [get_property -quiet REF_NAME [get_cells -quiet -of [lindex $objects 0]]]"
        puts $channel " -I- veam attributes: [getVeamAttributes [get_cells -quiet -of [lindex $objects 0]]]"
        foreach pin $objects {
          incr numpins
          set libcell [get_property -quiet REF_NAME [get_cells -of $pin]]
          set libpin [get_property -quiet REF_PIN_NAME $pin]
          set cellid [SQL eval { SELECT id FROM cell WHERE name=$libcell }]
          set pinid [SQL eval { SELECT id FROM pin WHERE cellid=$cellid AND name=$libpin }]
          set res [SQL eval { SELECT id, (SELECT name FROM pin WHERE id=relatedpinid), (SELECT name FROM pin WHERE id=pinid), timingid
                              FROM arc
                              WHERE relatedpinid=$pinid OR pinid=$pinid
                              ORDER BY (SELECT name FROM pin WHERE id=relatedpinid) ASC
                            }]
          foreach {id from to timingid} $res {
            SQL eval { SELECT * FROM timing WHERE id=$timingid } values {
              set msg "  \[DOTLIB\] TimingArc $from -> $to ($values(timing_type)"
              if {$values(timing_sense) != {}} {
                append msg ", $values(timing_sense)"
              }
              append msg ")"
              puts $channel $msg
              incr numarcs
            }
          }
        }
        puts $channel " -I- $numpins pin(s) processed"
        puts $channel " -I- $numarcs \[DOTLIB\] timing arc(s) found"
      }
      cell {
        puts $channel " -I- cell $objects"
        set numpins 0
        set numarcs 0
        # Since all the pins belong to the same cell, the ref name is extracted from the first pin
        puts $channel " -I- ref_name: [get_property -quiet REF_NAME [get_cells -quiet [lindex $objects 0]]]"
        puts $channel " -I- veam attributes: [getVeamAttributes [get_cells -quiet [lindex $objects 0]]]"
        foreach cell $objects {
          incr numcells
          set libcell [get_property -quiet REF_NAME $cell]
          set cellid [SQL eval { SELECT id FROM cell WHERE name=$libcell }]
          set res [SQL eval { SELECT id, (SELECT name FROM pin WHERE id=relatedpinid), (SELECT name FROM pin WHERE id=pinid), timingid
                              FROM arc
                              WHERE cellid=$cellid
                              ORDER BY (SELECT name FROM pin WHERE id=pinid) ASC
                            }]
          foreach {id from to timingid} $res {
            SQL eval { SELECT * FROM timing WHERE id=$timingid } values {
              set msg "  \[DOTLIB\] TimingArc $from -> $to ($values(timing_type)"
              if {$values(timing_sense) != {}} {
                append msg ", $values(timing_sense)"
              }
              append msg ")"
              puts $channel $msg
              incr numarcs
            }
          }
        }
        puts $channel " -I- $numcells cell(s) processed"
        puts $channel " -I- $numarcs \[DOTLIB\] timing arc(s) found"
      }
      default {
        error " error - unsupported object type ($class)"
      }
    }
    puts $channel " -I- end time: [clock format [clock seconds]]"
    flush $channel
    SQL close
  }

  #-------------------------------------------------------
  # Timer query
  #-------------------------------------------------------

  if {[regexp {timer} $engine]} {
    puts $channel " -I- engine: timer"
    puts $channel " -I- start time: [clock format [clock seconds]]"
    switch $class {
      pin {
        puts $channel " -I- pins [::tb::collapseBusNames $objects]"
        set numpins 0
        set numarcs 0
        if {$veamattr != {}} {
          # Since all the pins belong to the same cell, the ref name is extracted from the first pin
          set cell [get_cells -quiet -of [lindex $objects 0]]
          puts $channel " -I- setting properties for cell $cell: $veamattr"
          setVeamAttributes $cell $veamattr
#           foreach {prop val} $veamattr {
#             switch -nocase -- [get_property -quiet PRIMITIVE_GROUP $cell].[get_property -quiet PRIMITIVE_LEVEL $cell] {
#               MULT.INTERNAL {
#                 # For the DSP, the properties should not be set on the atoms but on the macro (atom's parent)
#                 set_property -quiet $prop $val [get_property -quiet PARENT $cell]
#               }
#               default {
#                 set_property -quiet $prop $val $cell
#               }
#             }
#           }
        }
        puts $channel " -I- ref_name: [get_property -quiet REF_NAME [get_cells -quiet -of [lindex $objects 0]]]"
        puts $channel " -I- veam attributes: [getVeamAttributes [get_cells -quiet -of [lindex $objects 0]]]"
        foreach pin $objects {
          incr numpins
          if {$dir == {IN}} {
            set arcs [get_timing_arcs -quiet -from $pin]
          } else {
            set arcs [get_timing_arcs -quiet -to $pin]
          }
          incr numarcs [llength $arcs]
          foreach arc [lsort -dictionary $arcs] {
            set from [get_property -quiet REF_PIN_NAME [get_property -quiet FROM_PIN $arc]]
            set to [get_property -quiet REF_PIN_NAME [get_property -quiet TO_PIN $arc]]
            set timing_type [get_property -quiet TYPE $arc]
            set timing_sense [get_property -quiet SENSE $arc]
            set dmaxf [get_property -quiet DELAY_MAX_FALL $arc]
            set dmaxr [get_property -quiet DELAY_MAX_RISE $arc]
            set dminf [get_property -quiet DELAY_MIN_FALL $arc]
            set dminr [get_property -quiet DELAY_MIN_RISE $arc]
            set msg "  \[TIMER\] TimingArc $from -> $to ($timing_type"
            if {$timing_sense != {}} {
              append msg ", $timing_sense"
            }
            append msg ")"
            append msg " ($dmaxr $dmaxf $dminr $dminf)"
            puts $channel $msg
          }
        }
        puts $channel " -I- $numpins pin(s) processed"
        puts $channel " -I- $numarcs \[TIMER\] timing arc(s) found"
      }
      cell {
        puts $channel " -I- cell $objects"
        set numcells 0
        set numarcs 0
        if {$veamattr != {}} {
          # Since all the pins belong to the same cell, the ref name is extracted from the first pin
          set cell [get_cells -quiet [lindex $objects 0]]
          puts $channel " -I- setting properties for cell $cell: $veamattr"
          setVeamAttributes $cell $veamattr
#           foreach {prop val} $veamattr {
#             switch -nocase -- [get_property -quiet PRIMITIVE_GROUP $cell].[get_property -quiet PRIMITIVE_LEVEL $cell] {
#               MULT.INTERNAL {
#                 # For the DSP, the properties should not be set on the atoms but on the macro (atom's parent)
#                 set_property -quiet $prop $val [get_property -quiet PARENT $cell]
#               }
#               default {
#                 set_property -quiet $prop $val $cell
#               }
#             }
#           }
        }
        puts $channel " -I- ref_name: [get_property -quiet REF_NAME [get_cells -quiet [lindex $objects 0]]]"
        puts $channel " -I- veam attributes: [getVeamAttributes [get_cells -quiet [lindex $objects 0]]]"
        foreach cell $objects {
          incr numcells
          set arcs [get_timing_arcs -quiet -of $cell]
          incr numarcs [llength $arcs]
          foreach arc $arcs {
            set from [get_property -quiet REF_PIN_NAME [get_property -quiet FROM_PIN $arc]]
            set to [get_property -quiet REF_PIN_NAME [get_property -quiet TO_PIN $arc]]
            set timing_type [get_property -quiet TYPE $arc]
            set timing_sense [get_property -quiet SENSE $arc]
            set dmaxf [get_property -quiet DELAY_MAX_FALL $arc]
            set dmaxr [get_property -quiet DELAY_MAX_RISE $arc]
            set dminf [get_property -quiet DELAY_MIN_FALL $arc]
            set dminr [get_property -quiet DELAY_MIN_RISE $arc]
            set msg "  \[TIMER\] TimingArc $from -> $to ($timing_type"
            if {$timing_sense != {}} {
              append msg ", $timing_sense"
            }
            append msg ")"
            append msg " ($dmaxr $dmaxf $dminr $dminf)"
            puts $channel $msg
          }
        }
        puts $channel " -I- $numcells cell(s) processed"
        puts $channel " -I- $numarcs \[TIMER\] timing arc(s) found"
      }
      default {
        error " error - unsupported object type ($class)"
      }
    }
    flush $channel
    puts $channel " -I- end time: [clock format [clock seconds]]"
  }

  #-------------------------------------------------------
  # Veam query
  #-------------------------------------------------------

  if {[regexp {veam} $engine]} {
    set VEAM {}
    if {$veamlog != {}} {
      puts " Creating file [file normalize $veamlog]"
      set VEAM [open $veamlog $filemode]
    }
    puts $channel " -I- engine: veam"
    puts $channel " -I- start time: [clock format [clock seconds]]"
    switch $class {
      pin {
        puts $channel " -I- pins [::tb::collapseBusNames $objects]"
        set numpins 0
        set numarcs 0
        # Since all the pins belong to the same cell, the ref name is extracted from the first pin
        set cell [get_cells -quiet -of [lindex $objects 0]]
        set libcell [get_property -quiet REF_NAME $cell ]
        if {$veamattr == {}} {
          set veamattr [getVeamAttributes $cell]
        }
        puts $channel " -I- ref_name: $libcell"
        puts $channel " -I- veam attributes: $veamattr"
        puts $channel " -I- pins [::tb::collapseBusNames $objects]"
        # Create empty $veamtemp file, just in case it does not get created with internal::report_enabled_arcs
        set FHTemp [open $veamtemp {w}]; puts $FHTemp {}; close $FHTemp
        foreach pin $objects {
          incr numpins
          set libpin [get_property -quiet REF_PIN_NAME $pin]
          puts $channel " -I- processing pin $pin ($numpins/[llength $objects]) \[$libcell\]"
          if {$dir == {IN}} {
            set cmd [list internal::report_enabled_arcs -cell [get_lib_cells [get_libs]/$libcell] \
                                      -attrList $veamattr \
                                      -file $veamtemp \
                                      -from [get_property -quiet REF_PIN_NAME $pin] \
                    ]
          } else {
            set cmd [list internal::report_enabled_arcs -cell [get_lib_cells [get_libs]/$libcell] \
                                      -attrList $veamattr \
                                      -file $veamtemp \
                                      -to [get_property -quiet REF_PIN_NAME $pin] \
                    ]
          }
          flush stdout
          set starttime [clock seconds]
          # Execute the internal::report_enabled_arcs
          catch {uplevel #0 $cmd} errorstring
          set endtime [clock seconds]
          if {$VEAM != {}} {
            puts $VEAM "#####################################################"
            puts $VEAM "CMD: $cmd"
            puts $VEAM "PIN: $pin"
            puts $VEAM "ATTR: $veamattr"
            puts $VEAM "STARTTIME: [clock format $starttime]"
            puts $VEAM "ENDTIME: [clock format $endtime]"
            puts $VEAM ""
          }
          set FHTemp [open $veamtemp {r}]
          catch {unset veamarcs}
          while {![eof $FHTemp]} {
            gets $FHTemp line
            if {[regexp -nocase -- {^\s*TimingArc\s+([^\s]+)\s+->\s+([^\s]+)\s*\((.+)\)\s*:\s*VeamCondition\s*=\s*([^\s]+)\s*:.+isEnabled\s*=\s*([^\s]+)\s*$} $line - from to type veamcondition isenabled]} {
              if {![info exists veamarcs($line)]} { set veamarcs($line) 0 }
              incr veamarcs($line)
            }
            puts $VEAM $line
          }
          close $FHTemp
          incr numarcs [llength [array names veamarcs]]
          foreach arc [lsort -dictionary [array names veamarcs]] {
            regexp -nocase -- {^\s*TimingArc\s+([^\s]+)\s+->\s+([^\s]+)\s*\((.+)\)\s*:\s*VeamCondition\s*=\s*([^\s]+)\s*:.+isEnabled\s*=\s*([^\s]+)\s*$} $arc - from to type veamcondition isenabled
            puts $channel "  \[VEAM\] TimingArc $from -> $to ($type) (veamcondition=$veamcondition) (isEnabled=$isenabled)"
          }
          puts $channel " -I- internal::report_enabled_arcs completed in [expr $endtime - $starttime] seconds"
          flush $channel
        }
        puts $channel " -I- $numpins pin(s) processed"
        puts $channel " -I- $numarcs \[VEAM\] timing arc(s) found"
        if {$VEAM != {}} { close $VEAM }
      }
      cell {
        puts $channel " -I- cells [::tb::collapseBusNames $objects]"
        set numcells 0
        set numarcs 0
        foreach cell $objects {
          incr numcells
          set libcell [get_property -quiet REF_NAME $cell ]
          if {$veamattr == {}} {
            set veamattr [getVeamAttributes $cell]
          }
          puts $channel " -I- processing pin $cell ($numcells/[llength $objects]) \[$libcell\]"
          puts $channel " -I- ref_name: $libcell"
          puts $channel " -I- veam attributes: $veamattr"
          # Create empty $veamtemp file, just in case it does not get created with internal::report_enabled_arcs
          set FHTemp [open $veamtemp {w}]; puts $FHTemp {}; close $FHTemp
          set cmd [list internal::report_enabled_arcs -cell [get_lib_cells [get_libs]/$libcell] \
                                      -attrList $veamattr \
                                      -file $veamtemp \
                    ]
          flush stdout
          set starttime [clock seconds]
          # Execute the internal::report_enabled_arcs
          catch {uplevel #0 $cmd} errorstring
          set endtime [clock seconds]
          puts $VEAM "#####################################################"
          puts $VEAM "CMD: $cmd"
          puts $VEAM "CELL: $cell"
          puts $VEAM "ATTR: $veamattr"
          puts $VEAM "STARTTIME: [clock format $starttime]"
          puts $VEAM "ENDTIME: [clock format $endtime]"
          puts $VEAM ""
          set FHTemp [open $veamtemp {r}]
          catch {unset veamarcs}
          while {![eof $FHTemp]} {
            gets $FHTemp line
            if {[regexp -nocase -- {^\s*TimingArc\s+([^\s]+)\s+->\s+([^\s]+)\s*\((.+)\)\s*:\s*VeamCondition\s*=\s*([^\s]+)\s*:.+isEnabled\s*=\s*([^\s]+)\s*$} $line - from to type veamcondition isenabled]} {
              if {![info exists veamarcs($line)]} { set veamarcs($line) 0 }
              incr veamarcs($line)
            }
            if {$VEAM != {}} { puts $VEAM $line }
          }
          close $FHTemp
          incr numarcs [llength [array names veamarcs]]
          foreach arc [lsort -dictionary [array names veamarcs]] {
            regexp -nocase -- {^\s*TimingArc\s+([^\s]+)\s+->\s+([^\s]+)\s*\((.+)\)\s*:\s*VeamCondition\s*=\s*([^\s]+)\s*:.+isEnabled\s*=\s*([^\s]+)\s*$} $arc - from to type veamcondition isenabled
            puts $channel "  \[VEAM\] TimingArc $from -> $to ($type) (veamcondition=$veamcondition) (isEnabled=$isenabled)"
          }
          puts $channel " -I- internal::report_enabled_arcs completed in [expr $endtime - $starttime] seconds"
          flush $channel
        }
        puts $channel " -I- $numcells cell(s) processed"
        puts $channel " -I- $numarcs \[VEAM\] timing arc(s) found"
        if {$VEAM != {}} { close $VEAM }
      }
      default {
        error " error - unsupported object type ($class)"
      }
    }
    puts $channel " -I- end time: [clock format [clock seconds]]"
    flush $channel
  }

  if {$channel != {stdout}} { close $channel }
  return 0
}

proc ::report_timing_arcs::getLibcellVeamAttributes {libcell} {
  variable sitemap2
  if {![info exists sitemap2($libcell)]} {
    error " error - cannot find sitemap2 information for '$libcell'"
  }
  set libcellobj [get_lib_cells [get_libs]/$libcell]
  if {[get_property -quiet PRIMITIVE_GROUP $libcellobj] == {MULT}} {
    # Special handling for DSP: if the libcell point to one of the DSP's atom
    # then the properties should be read on the DSP macro. This is to handle
    # the case where some atoms might depend on properties that are not directly
    # set on the atom. The property values can only be read on the DSP macro
    set libcellobj [get_lib_cells [get_libs]/DSP48E2]
  }
  array set ar $sitemap2($libcell)
  catch {unset res}
  set properties $ar(cfg_element)
  # Special handling for the DSP: DSP_OUTPUT and DSP_ALU depand on more
  # attributes that it is captured inside Vivado
  switch $libcell {
    DSP_OUTPUT {
      set properties [concat $properties [list {USE_MULT} {USE_SIMD}] ]
    }
    DSP_ALU {
      set properties [concat $properties [list {USE_MULT}] ]
    }
    default {
    }
  }
  foreach prop [lsort -dictionary -unique $properties] {
    set default [get_property -quiet CONFIG.${prop}.DEFAULT $libcellobj]
    set min [get_property -quiet CONFIG.${prop}.MIN $libcellobj]
    set max [get_property -quiet CONFIG.${prop}.MAX $libcellobj]
    set type [get_property -quiet CONFIG.${prop}.TYPE $libcellobj]
    set values [get_property -quiet CONFIG.${prop}.VALUES $libcellobj]
    set res($prop) [list DEFAULT $default MIN $min MAX $max TYPE $type VALUES $values]
#     puts " $prop: DEFAULT:$default / MIN:$min / MAX:$max / TYPE:$type / VALUES:$values"
  }
  return [array get res]
}

proc ::report_timing_arcs::setVeamAttributes {cell attrList} {
  set cell [get_cells -quiet $cell]
#   puts $channel " -I- setting properties for cell $cell: $attrList"
  foreach {prop val} $attrList {
    switch -nocase -- [get_property -quiet PRIMITIVE_GROUP $cell].[get_property -quiet PRIMITIVE_LEVEL $cell] {
      MULT.INTERNAL {
        # For the DSP, the properties should not be set on the atoms but on the macro (atom's parent)
        set_property -quiet $prop $val [get_property -quiet PARENT $cell]
      }
      default {
        set_property -quiet $prop $val $cell
      }
    }
  }
}

proc ::report_timing_arcs::getVeamAttributes {cell} {
  set attrList [list]
  set cell [get_cells -quiet $cell]
  set libcell [get_property -quiet REF_NAME $cell ]
  array set ar [getLibcellVeamAttributes $libcell]
  set properties [lsort -dictionary [array names ar]]
# puts " -I- veam conditions:"
  foreach prop $properties {
    set default [::report_timing_arcs::lskim [list $ar($prop)] DEFAULT]
    switch -nocase -- [get_property -quiet PRIMITIVE_GROUP $cell].[get_property -quiet PRIMITIVE_LEVEL $cell] {
      MULT.INTERNAL {
        # For the DSP, the properties should not be read on the atoms but on the macro (atom's parent)
        # That's a workaround that some atoms depend on properties (USE_MULT/USE_SIMD that are not
        # set on the atom itself)
        set val [get_property -quiet $prop [get_property -quiet PARENT $cell]]
      }
      default {
        set val [get_property -quiet $prop $cell]
      }
    }
#     set val [get_property -quiet $prop $cell]
# puts "      $prop:$val\t(default:[::report_timing_arcs::lskim [list $ar($prop)] DEFAULT])"
    set attrList [concat $attrList $prop $val]
  }
  return $attrList
}

proc ::report_timing_arcs::getLibcellVeamAttributesRange {libcell} {
  set libcell [get_lib_cells -quiet $libcell]
  set L [list]
  array set ar [getLibcellVeamAttributes $libcell]
  set properties [lsort -dictionary [array names ar]]
  foreach prop $properties {
    catch {unset _}
    array set _ $ar($prop)
    # Handle properties that have min/max values
    # E.g: MASK:min=Ox48'h000000000000, max=Ox48'hFFFFFFFFFFFF 
    set values [regsub -all {(min|max)=} $_(VALUES) {}]
    # Convert a comma separated list (string) into a Tcl list
    set values [split [regsub -all { } $values {}] ,]
    lappend L [list $prop $values]
  }
  return $L
}

proc ::report_timing_arcs::genReportTimingArcsCmd {cell libcell attrList args} {
  set L [list]
  foreach attr $attrList val $args {
    set L [concat $L $attr $val]
  }
  set filename "${libcell}.[join $L _].arcs"
  set veamlog "${libcell}.[join $L _].veam"
  # Cover the case when there is no attribute
  regsub {\.\.} $filename {.} filename
  regsub {\.\.} $veamlog {.} veamlog
  # Remove single quotes from filenames
  regsub -all {\'} $filename {} filename
  regsub -all {\'} $veamlog {} veamlog
  # Do not extract timing arcs through Veam since it's runtime intensive
  return [format {report_timing_arcs -timer -dotlib -of [get_cells %s] -veamattr {%s} -veamlog %s -file %s} $cell $L $veamlog $filename ]
#   return [format {report_timing_arcs -timer -dotlib -veam -of [get_cells %s] -veamattr {%s} -veamlog %s -file %s} $cell $L $veamlog $filename ]
}

# E.g: foreach cell [get_cells bfil/multOp/*] { genAllVeamConfigs $cell }
proc ::report_timing_arcs::genAllVeamConfigs {name} {
  set cell [get_cells -quiet $name]
  if {$cell != {}} {
    set libcell [get_lib_cells -quiet [get_property -quiet REF_NAME $cell] ]
  } else {
    set cell {}
    set libcell [get_lib_cells -quiet $name]
  }
  set attrList [getLibcellVeamAttributesRange $libcell]
  set attributes [list]
  set values [list]
  foreach elm $attrList {
    foreach {attr val} $elm { break }
    lappend attributes $attr
    lappend values $val
  }
  puts " -I- Generate all Veam configurations for $libcell"
  puts " -I- Veam attributes range: $attrList"
  set cmd {}
  set result [list]
  set count [llength $values]
  foreach L [::tb::lrevert $values] {
    incr count -1
    set cmd [format "foreach _%s_ {%s} \{ %s " [expr $count +0] $L $cmd]
  }
  append cmd "lappend result \[genReportTimingArcsCmd {$cell} {$libcell} {$attributes}"
  for {set i 0} {$i < [llength $values]} {incr i} { append cmd " \$_${i}_" }
  append cmd " \]"
  append cmd [string repeat " \}" [llength $values] ]
  uplevel 0 [list eval $cmd]
  puts " -I- Number of Veam configurations: [llength $result]"
  set filename ${libcell}.veamconfig
  set FH [open $filename {w}]
  puts $FH "# File generated on [clock format [clock seconds]]"
  puts $FH "# Number of configurations for $libcell: [llength $result]"
  puts $FH "# Backup Veam attributes: [getVeamAttributes $cell]"
  puts $FH "set backupVeamAttributes \[::report_timing_arcs::getVeamAttributes {$cell}\]"
  set count 1
  foreach config $result {
    puts $FH [format {puts -nonewline { [%s/%s]}; %s} $count [llength $result] $config]
    incr count
  }
  puts $FH "# Restore Veam attributes"
  puts $FH "::report_timing_arcs::setVeamAttributes {$cell} \$backupVeamAttributes"
  puts $FH "# ::report_timing_arcs::setVeamAttributes {$cell} \[list [getVeamAttributes $cell]\]"
  close $FH
  puts " -I- Generated file [file normalize $filename]"
  return 0
}

proc ::report_timing_arcs::sitemap2 {} {
  return {
     AND2B1L { cfg_element {} }
     BITSLICE_CONTROL { cfg_element {CTRL_CLK DIV_MODE EN_CLK_TO_EXT_NORTH EN_CLK_TO_EXT_SOUTH EN_DYN_ODLY_MODE EN_OTHER_NCLK EN_OTHER_PCLK IDLY_VT_TRACK INV_RXCLK ODLY_VT_TRACK QDLY_VT_TRACK READ_IDLE_COUNT REFCLK_SRC ROUNDING_FACTOR RXGATE_EXTEND RX_CLK_PHASE_N RX_CLK_PHASE_P RX_GATING SELF_CALIBRATE SERIAL_MODE TX_GATING} }
     BSCANE2 { cfg_element {DISABLE_JTAG JTAG_CHAIN} }
     BUFCE_LEAF { cfg_element CE_TYPE }
     BUFCE_ROW { cfg_element CE_TYPE }
     BUFG_GT { cfg_element {} }
     BUFGCE { cfg_element CE_TYPE }
     BUFGCE_DIV { cfg_element BUFGCE_DIVIDE }
     BUFGCTRL { cfg_element {INIT_OUT PRESELECT_I0 PRESELECT_I1} }
     CARRY8 { cfg_element {} }
     CFG_IO_ACCESS { cfg_element CFG_IO_ACCESS_USED }
     CFGLUT5 { cfg_element INIT }
     CMAC { cfg_element {CTL_PTP_TRANSPCLK_MODE CTL_RX_CHECK_ACK CTL_RX_CHECK_PREAMBLE CTL_RX_CHECK_SFD CTL_RX_DELETE_FCS CTL_RX_ETYPE_GCP CTL_RX_ETYPE_GPP CTL_RX_ETYPE_PCP CTL_RX_ETYPE_PPP CTL_RX_FORWARD_CONTROL CTL_RX_IGNORE_FCS CTL_RX_MAX_PACKET_LEN CTL_RX_MIN_PACKET_LEN CTL_RX_OPCODE_GPP CTL_RX_OPCODE_MAX_GCP CTL_RX_OPCODE_MAX_PCP CTL_RX_OPCODE_MIN_GCP CTL_RX_OPCODE_MIN_PCP CTL_RX_OPCODE_PPP CTL_RX_PAUSE_DA_MCAST CTL_RX_PAUSE_DA_UCAST CTL_RX_PAUSE_SA CTL_RX_PROCESS_LFI CTL_RX_VL_LENGTH_MINUS1 CTL_RX_VL_MARKER_ID0 CTL_RX_VL_MARKER_ID1 CTL_RX_VL_MARKER_ID10 CTL_RX_VL_MARKER_ID11 CTL_RX_VL_MARKER_ID12 CTL_RX_VL_MARKER_ID13 CTL_RX_VL_MARKER_ID14 CTL_RX_VL_MARKER_ID15 CTL_RX_VL_MARKER_ID16 CTL_RX_VL_MARKER_ID17 CTL_RX_VL_MARKER_ID18 CTL_RX_VL_MARKER_ID19 CTL_RX_VL_MARKER_ID2 CTL_RX_VL_MARKER_ID3 CTL_RX_VL_MARKER_ID4 CTL_RX_VL_MARKER_ID5 CTL_RX_VL_MARKER_ID6 CTL_RX_VL_MARKER_ID7 CTL_RX_VL_MARKER_ID8 CTL_RX_VL_MARKER_ID9 CTL_TEST_MODE_PIN_CHAR CTL_TX_DA_GPP CTL_TX_DA_PPP CTL_TX_ETHERTYPE_GPP CTL_TX_ETHERTYPE_PPP CTL_TX_FCS_INS_ENABLE CTL_TX_IGNORE_FCS CTL_TX_OPCODE_GPP CTL_TX_OPCODE_PPP CTL_TX_PTP_1STEP_ENABLE CTL_TX_PTP_LATENCY_ADJUST CTL_TX_SA_GPP CTL_TX_SA_PPP CTL_TX_VL_LENGTH_MINUS1 CTL_TX_VL_MARKER_ID0 CTL_TX_VL_MARKER_ID1 CTL_TX_VL_MARKER_ID10 CTL_TX_VL_MARKER_ID11 CTL_TX_VL_MARKER_ID12 CTL_TX_VL_MARKER_ID13 CTL_TX_VL_MARKER_ID14 CTL_TX_VL_MARKER_ID15 CTL_TX_VL_MARKER_ID16 CTL_TX_VL_MARKER_ID17 CTL_TX_VL_MARKER_ID18 CTL_TX_VL_MARKER_ID19 CTL_TX_VL_MARKER_ID2 CTL_TX_VL_MARKER_ID3 CTL_TX_VL_MARKER_ID4 CTL_TX_VL_MARKER_ID5 CTL_TX_VL_MARKER_ID6 CTL_TX_VL_MARKER_ID7 CTL_TX_VL_MARKER_ID8 CTL_TX_VL_MARKER_ID9 TEST_MODE_PIN_CHAR} }
     DCIRESET { cfg_element {} }
     DIFFINBUF { cfg_element {DIFF_TERM DQS_BIAS EQUALIZATION IBUF_LOW_PWR IOB_TYPE IO_TYPE ISTANDARD OFFSET_CNTRL DIFF_TERM_ADV IPROGRAMMING} }
     DNA_PORTE2 { cfg_element {} }
     DNA_PORTE3 { cfg_element DNA_PORT_USED }
     DSP_A_B_DATA { cfg_element {ACASCREG AREG A_INPUT BCASCREG BREG B_INPUT} }
     DSP_ALU { cfg_element {ALUMODEREG CARRYINREG CARRYINSELREG MREG OPMODEREG RND USE_SIMD USE_WIDEXOR XORSIMD} }
     DSP_C_DATA { cfg_element CREG }
     DSP_M_DATA { cfg_element MREG }
     DSP_MULTIPLIER { cfg_element {AMULTSEL BMULTSEL USE_MULT} }
     DSP_OUTPUT { cfg_element {AUTORESET_PATDET AUTORESET_PRIORITY MASK PATTERN PREG SEL_MASK SEL_PATTERN USE_PATTERN_DETECT} }
     DSP_PREADD { cfg_element {} }
     DSP_PREADD_DATA { cfg_element {ADREG AMULTSEL BMULTSEL DREG INMODEREG PREADDINSEL USE_MULT} }
     EFUSE_USR { cfg_element {} }
     FDCE { cfg_element INIT }
     FDPE { cfg_element INIT }
     FDRE { cfg_element INIT }
     FDSE { cfg_element INIT }
     FIFO18E2 { cfg_element {CASCADE_ORDER CLOCK_DOMAINS FIRST_WORD_FALL_THROUGH INIT PROG_EMPTY_THRESH PROG_FULL_THRESH RDCOUNT_TYPE READ_WIDTH REGISTER_MODE RSTREG_PRIORITY SLEEP_ASYNC SRVAL WRCOUNT_TYPE WRITE_WIDTH} }
     FIFO36E2 { cfg_element {CASCADE_ORDER CLOCK_DOMAINS EN_ECC_PIPE EN_ECC_READ EN_ECC_WRITE FIRST_WORD_FALL_THROUGH INIT PROG_EMPTY_THRESH PROG_FULL_THRESH RDCOUNT_TYPE READ_WIDTH REGISTER_MODE RSTREG_PRIORITY SLEEP_ASYNC SRVAL WRCOUNT_TYPE WRITE_WIDTH} }
     FRAME_ECCE3 { cfg_element {} }
     GTHE3_CHANNEL { cfg_element {ACJTAG_DEBUG_MODE ACJTAG_MODE ACJTAG_RESET ADAPT_CFG0 ADAPT_CFG1 ALIGN_COMMA_DOUBLE ALIGN_COMMA_ENABLE ALIGN_COMMA_WORD ALIGN_MCOMMA_DET ALIGN_MCOMMA_VALUE ALIGN_PCOMMA_DET ALIGN_PCOMMA_VALUE A_RXOSCALRESET A_RXPROGDIVRESET A_TXPROGDIVRESET CBCC_DATA_SOURCE_SEL CDR_SWAP_MODE_EN CHAN_BOND_KEEP_ALIGN CHAN_BOND_MAX_SKEW CHAN_BOND_SEQ_1_1 CHAN_BOND_SEQ_1_2 CHAN_BOND_SEQ_1_3 CHAN_BOND_SEQ_1_4 CHAN_BOND_SEQ_1_ENABLE CHAN_BOND_SEQ_2_1 CHAN_BOND_SEQ_2_2 CHAN_BOND_SEQ_2_3 CHAN_BOND_SEQ_2_4 CHAN_BOND_SEQ_2_ENABLE CHAN_BOND_SEQ_2_USE CHAN_BOND_SEQ_LEN CLK_CORRECT_USE CLK_COR_KEEP_IDLE CLK_COR_MAX_LAT CLK_COR_MIN_LAT CLK_COR_PRECEDENCE CLK_COR_REPEAT_WAIT CLK_COR_SEQ_1_1 CLK_COR_SEQ_1_2 CLK_COR_SEQ_1_3 CLK_COR_SEQ_1_4 CLK_COR_SEQ_1_ENABLE CLK_COR_SEQ_2_1 CLK_COR_SEQ_2_2 CLK_COR_SEQ_2_3 CLK_COR_SEQ_2_4 CLK_COR_SEQ_2_ENABLE CLK_COR_SEQ_2_USE CLK_COR_SEQ_LEN CPLL_CFG0 CPLL_CFG1 CPLL_CFG2 CPLL_CFG3 CPLL_FBDIV CPLL_FBDIV_45 CPLL_INIT_CFG0 CPLL_INIT_CFG1 CPLL_LOCK_CFG CPLL_REFCLK_DIV DDI_CTRL DDI_REALIGN_WAIT DEC_MCOMMA_DETECT DEC_PCOMMA_DETECT DEC_VALID_COMMA_ONLY DFE_D_X_REL_POS DFE_VCM_COMP_EN DMONITOR_CFG0 DMONITOR_CFG1 ES_CLK_PHASE_SEL ES_CONTROL ES_ERRDET_EN ES_EYE_SCAN_EN ES_HORZ_OFFSET ES_PMA_CFG ES_PRESCALE ES_QUALIFIER0 ES_QUALIFIER1 ES_QUALIFIER2 ES_QUALIFIER3 ES_QUALIFIER4 ES_QUAL_MASK0 ES_QUAL_MASK1 ES_QUAL_MASK2 ES_QUAL_MASK3 ES_QUAL_MASK4 ES_SDATA_MASK0 ES_SDATA_MASK1 ES_SDATA_MASK2 ES_SDATA_MASK3 ES_SDATA_MASK4 EVODD_PHI_CFG EYE_SCAN_SWAP_EN FTS_DESKEW_SEQ_ENABLE FTS_LANE_DESKEW_CFG FTS_LANE_DESKEW_EN GEARBOX_MODE GM_BIAS_SELECT LOCAL_MASTER OOBDIVCTL OOB_PWRUP PCI3_AUTO_REALIGN PCI3_PIPE_RX_ELECIDLE PCI3_RX_ASYNC_EBUF_BYPASS PCI3_RX_ELECIDLE_EI2_ENABLE PCI3_RX_ELECIDLE_H2L_COUNT PCI3_RX_ELECIDLE_H2L_DISABLE PCI3_RX_ELECIDLE_HI_COUNT PCI3_RX_ELECIDLE_LP4_DISABLE PCI3_RX_FIFO_DISABLE PCIE_BUFG_DIV_CTRL PCIE_RXPCS_CFG_GEN3 PCIE_RXPMA_CFG PCIE_TXPCS_CFG_GEN3 PCIE_TXPMA_CFG PCS_PCIE_EN PCS_RSVD0 PCS_RSVD1 PD_TRANS_TIME_FROM_P2 PD_TRANS_TIME_NONE_P2 PD_TRANS_TIME_TO_P2 PLL_SEL_MODE_GEN12 PLL_SEL_MODE_GEN3 PMA_RSV1 PROCESS_PAR RATE_SW_USE_DRP RESET_POWERSAVE_DISABLE RXBUFRESET_TIME RXBUF_ADDR_MODE RXBUF_EIDLE_HI_CNT RXBUF_EIDLE_LO_CNT RXBUF_EN RXBUF_RESET_ON_CB_CHANGE RXBUF_RESET_ON_COMMAALIGN RXBUF_RESET_ON_EIDLE RXBUF_RESET_ON_RATE_CHANGE RXBUF_THRESH_OVFLW RXBUF_THRESH_OVRD RXBUF_THRESH_UNDFLW RXCDRFREQRESET_TIME RXCDRPHRESET_TIME RXCDR_CFG0 RXCDR_CFG0_GEN3 RXCDR_CFG1 RXCDR_CFG1_GEN3 RXCDR_CFG2 RXCDR_CFG2_GEN3 RXCDR_CFG3 RXCDR_CFG3_GEN3 RXCDR_CFG4 RXCDR_CFG4_GEN3 RXCDR_CFG5 RXCDR_CFG5_GEN3 RXCDR_FR_RESET_ON_EIDLE RXCDR_HOLD_DURING_EIDLE RXCDR_LOCK_CFG0 RXCDR_LOCK_CFG1 RXCDR_LOCK_CFG2 RXCDR_PH_RESET_ON_EIDLE RXCFOK_CFG0 RXCFOK_CFG1 RXCFOK_CFG2 RXDFELPMRESET_TIME RXDFELPM_KL_CFG0 RXDFELPM_KL_CFG1 RXDFELPM_KL_CFG2 RXDFE_CFG0 RXDFE_CFG1 RXDFE_GC_CFG0 RXDFE_GC_CFG1 RXDFE_GC_CFG2 RXDFE_H2_CFG0 RXDFE_H2_CFG1 RXDFE_H3_CFG0 RXDFE_H3_CFG1 RXDFE_H4_CFG0 RXDFE_H4_CFG1 RXDFE_H5_CFG0 RXDFE_H5_CFG1 RXDFE_H6_CFG0 RXDFE_H6_CFG1 RXDFE_H7_CFG0 RXDFE_H7_CFG1 RXDFE_H8_CFG0 RXDFE_H8_CFG1 RXDFE_H9_CFG0 RXDFE_H9_CFG1 RXDFE_HA_CFG0 RXDFE_HA_CFG1 RXDFE_HB_CFG0 RXDFE_HB_CFG1 RXDFE_HC_CFG0 RXDFE_HC_CFG1 RXDFE_HD_CFG0 RXDFE_HD_CFG1 RXDFE_HE_CFG0 RXDFE_HE_CFG1 RXDFE_HF_CFG0 RXDFE_HF_CFG1 RXDFE_OS_CFG0 RXDFE_OS_CFG1 RXDFE_UT_CFG0 RXDFE_UT_CFG1 RXDFE_VP_CFG0 RXDFE_VP_CFG1 RXDLY_CFG RXDLY_LCFG RXELECIDLE_CFG RXGBOX_FIFO_INIT_RD_ADDR RXGEARBOX_EN RXISCANRESET_TIME RXLPM_CFG RXLPM_GC_CFG RXLPM_KH_CFG0 RXLPM_KH_CFG1 RXLPM_OS_CFG0 RXLPM_OS_CFG1 RXOOB_CFG RXOOB_CLK_CFG RXOSCALRESET_TIME RXOUT_DIV RXPCSRESET_TIME RXPHBEACON_CFG RXPHDLY_CFG RXPHSAMP_CFG RXPHSLIP_CFG RXPH_MONITOR_SEL RXPI_CFG0 RXPI_CFG1 RXPI_CFG2 RXPI_CFG3 RXPI_CFG4 RXPI_CFG5 RXPI_CFG6 RXPI_LPM RXPI_VREFSEL RXPMACLK_SEL RXPMARESET_TIME RXPRBS_ERR_LOOPBACK RXPRBS_LINKACQ_CNT RXSLIDE_AUTO_WAIT RXSLIDE_MODE RXSYNC_MULTILANE RXSYNC_OVRD RXSYNC_SKIP_DA RX_AFE_CM_EN RX_BIAS_CFG0 RX_BUFFER_CFG RX_CAPFF_SARC_ENB RX_CLK25_DIV RX_CLKMUX_EN RX_CLK_SLIP_OVRD RX_CM_BUF_CFG RX_CM_BUF_PD RX_CM_SEL RX_CM_TRIM RX_CTLE3_LPF RX_DATA_WIDTH RX_DDI_SEL RX_DEFER_RESET_BUF_EN RX_DFELPM_CFG0 RX_DFELPM_CFG1 RX_DFELPM_KLKH_AGC_STUP_EN RX_DFE_AGC_CFG0 RX_DFE_AGC_CFG1 RX_DFE_KL_LPM_KH_CFG0 RX_DFE_KL_LPM_KH_CFG1 RX_DFE_KL_LPM_KL_CFG0 RX_DFE_KL_LPM_KL_CFG1 RX_DFE_LPM_HOLD_DURING_EIDLE RX_DISPERR_SEQ_MATCH RX_DIVRESET_TIME RX_EN_HI_LR RX_EYESCAN_VS_CODE RX_EYESCAN_VS_NEG_DIR RX_EYESCAN_VS_RANGE RX_EYESCAN_VS_UT_SIGN RX_FABINT_USRCLK_FLOP RX_INT_DATAWIDTH RX_PMA_POWER_SAVE RX_PROGDIV_CFG RX_SAMPLE_PERIOD RX_SIG_VALID_DLY RX_SUM_DFETAPREP_EN RX_SUM_IREF_TUNE RX_SUM_RES_CTRL RX_SUM_VCMTUNE RX_SUM_VCM_OVWR RX_SUM_VREF_TUNE RX_TUNE_AFE_OS RX_WIDEMODE_CDR RX_XCLK_SEL SAS_MAX_COM SAS_MIN_COM SATA_BURST_SEQ_LEN SATA_BURST_VAL SATA_CPLL_CFG SATA_EIDLE_VAL SATA_MAX_BURST SATA_MAX_INIT SATA_MAX_WAKE SATA_MIN_BURST SATA_MIN_INIT SATA_MIN_WAKE SHOW_REALIGN_COMMA TAPDLY_SET_TX TEMPERATUR_PAR TERM_RCAL_CFG TERM_RCAL_OVRD TRANS_TIME_RATE TST_RSV0 TST_RSV1 TXBUF_EN TXBUF_RESET_ON_RATE_CHANGE TXDLY_CFG TXDLY_LCFG TXDRVBIAS_N TXDRVBIAS_P TXFIFO_ADDR_CFG TXGBOX_FIFO_INIT_RD_ADDR TXGEARBOX_EN TXOUT_DIV TXPCSRESET_TIME TXPHDLY_CFG0 TXPHDLY_CFG1 TXPH_CFG TXPH_MONITOR_SEL TXPI_CFG0 TXPI_CFG1 TXPI_CFG2 TXPI_CFG3 TXPI_CFG4 TXPI_CFG5 TXPI_GRAY_SEL TXPI_INVSTROBE_SEL TXPI_LPM TXPI_PPMCLK_SEL TXPI_PPM_CFG TXPI_SYNFREQ_PPM TXPI_VREFSEL TXPMARESET_TIME TXSYNC_MULTILANE TXSYNC_OVRD TXSYNC_SKIP_DA TX_CLK25_DIV TX_CLKMUX_EN TX_DATA_WIDTH TX_DCD_CFG TX_DCD_EN TX_DEEMPH0 TX_DEEMPH1 TX_DIVRESET_TIME TX_DRIVE_MODE TX_EIDLE_ASSERT_DELAY TX_EIDLE_DEASSERT_DELAY TX_EML_PHI_TUNE TX_FABINT_USRCLK_FLOP TX_IDLE_DATA_ZERO TX_INT_DATAWIDTH TX_LOOPBACK_DRIVE_HIZ TX_MAINCURSOR_SEL TX_MARGIN_FULL_0 TX_MARGIN_FULL_1 TX_MARGIN_FULL_2 TX_MARGIN_FULL_3 TX_MARGIN_FULL_4 TX_MARGIN_LOW_0 TX_MARGIN_LOW_1 TX_MARGIN_LOW_2 TX_MARGIN_LOW_3 TX_MARGIN_LOW_4 TX_MODE_SEL TX_PMADATA_OPT TX_PMA_POWER_SAVE TX_PROGCLK_SEL TX_PROGDIV_CFG TX_QPI_STATUS_EN TX_RXDETECT_CFG TX_RXDETECT_REF TX_SAMPLE_PERIOD TX_SARC_LPBK_ENB TX_XCLK_SEL USE_PCS_CLK_PHASE_SEL WB_MODE} }
     GTHE3_COMMON { cfg_element {BIAS_CFG0 BIAS_CFG1 BIAS_CFG2 BIAS_CFG3 BIAS_CFG4 BIAS_CFG_RSVD COMMON_CFG0 COMMON_CFG1 POR_CFG QPLL0_CFG0 QPLL0_CFG1 QPLL0_CFG1_G3 QPLL0_CFG2 QPLL0_CFG2_G3 QPLL0_CFG3 QPLL0_CFG4 QPLL0_CP QPLL0_CP_G3 QPLL0_FBDIV QPLL0_FBDIV_G3 QPLL0_INIT_CFG0 QPLL0_INIT_CFG1 QPLL0_LOCK_CFG QPLL0_LOCK_CFG_G3 QPLL0_LPF QPLL0_LPF_G3 QPLL0_REFCLK_DIV QPLL0_SDM_CFG0 QPLL0_SDM_CFG1 QPLL0_SDM_CFG2 QPLL1_CFG0 QPLL1_CFG1 QPLL1_CFG1_G3 QPLL1_CFG2 QPLL1_CFG2_G3 QPLL1_CFG3 QPLL1_CFG4 QPLL1_CP QPLL1_CP_G3 QPLL1_FBDIV QPLL1_FBDIV_G3 QPLL1_INIT_CFG0 QPLL1_INIT_CFG1 QPLL1_LOCK_CFG QPLL1_LOCK_CFG_G3 QPLL1_LPF QPLL1_LPF_G3 QPLL1_REFCLK_DIV QPLL1_SDM_CFG0 QPLL1_SDM_CFG1 QPLL1_SDM_CFG2 RSVD_ATTR0 RSVD_ATTR1 RSVD_ATTR2 RSVD_ATTR3 RXRECCLKOUT0_SEL RXRECCLKOUT1_SEL SARC_EN SARC_SEL SDM0DATA1_0 SDM0DATA1_1 SDM0INITSEED0_0 SDM0INITSEED0_1 SDM0_DATA_PIN_SEL SDM0_WIDTH_PIN_SEL SDM1DATA1_0 SDM1DATA1_1 SDM1INITSEED0_0 SDM1INITSEED0_1 SDM1_DATA_PIN_SEL SDM1_WIDTH_PIN_SEL} }
     GTYE3_CHANNEL { cfg_element {ACJTAG_DEBUG_MODE ACJTAG_MODE ACJTAG_RESET ADAPT_CFG0 ADAPT_CFG1 ADAPT_CFG2 ALIGN_COMMA_DOUBLE ALIGN_COMMA_ENABLE ALIGN_COMMA_WORD ALIGN_MCOMMA_DET ALIGN_MCOMMA_VALUE ALIGN_PCOMMA_DET ALIGN_PCOMMA_VALUE AUTO_BW_SEL_BYPASS A_RXDFETAP12HOLD A_RXDFETAP12OVRDEN A_RXDFETAP13HOLD A_RXDFETAP13OVRDEN A_RXDFETAP14HOLD A_RXDFETAP14OVRDEN A_RXDFETAP15HOLD A_RXDFETAP15OVRDEN A_RXOSCALRESET A_RXPROGDIVRESET A_TXPROGDIVRESET CAPBYPASS_FORCE CBCC_DATA_SOURCE_SEL CDR_SWAP_MODE_EN CHAN_BOND_KEEP_ALIGN CHAN_BOND_MAX_SKEW CHAN_BOND_SEQ_1_1 CHAN_BOND_SEQ_1_2 CHAN_BOND_SEQ_1_3 CHAN_BOND_SEQ_1_4 CHAN_BOND_SEQ_1_ENABLE CHAN_BOND_SEQ_2_1 CHAN_BOND_SEQ_2_2 CHAN_BOND_SEQ_2_3 CHAN_BOND_SEQ_2_4 CHAN_BOND_SEQ_2_ENABLE CHAN_BOND_SEQ_2_USE CHAN_BOND_SEQ_LEN CKOK1_CFG_0 CKOK1_CFG_1 CKOK1_CFG_2 CKOK1_CFG_3 CKOK2_CFG_0 CKOK2_CFG_1 CKOK2_CFG_2 CKOK2_CFG_3 CKOK2_CFG_4 CLK_CORRECT_USE CLK_COR_KEEP_IDLE CLK_COR_MAX_LAT CLK_COR_MIN_LAT CLK_COR_PRECEDENCE CLK_COR_REPEAT_WAIT CLK_COR_SEQ_1_1 CLK_COR_SEQ_1_2 CLK_COR_SEQ_1_3 CLK_COR_SEQ_1_4 CLK_COR_SEQ_1_ENABLE CLK_COR_SEQ_2_1 CLK_COR_SEQ_2_2 CLK_COR_SEQ_2_3 CLK_COR_SEQ_2_4 CLK_COR_SEQ_2_ENABLE CLK_COR_SEQ_2_USE CLK_COR_SEQ_LEN CPLL_CFG0 CPLL_CFG1 CPLL_CFG2 CPLL_CFG3 CPLL_FBDIV CPLL_FBDIV_45 CPLL_INIT_CFG0 CPLL_INIT_CFG1 CPLL_LOCK_CFG CPLL_REFCLK_DIV CTLE3_OCAP_EXT_CTRL CTLE3_OCAP_EXT_EN DDI_CTRL DDI_REALIGN_WAIT DEC_MCOMMA_DETECT DEC_PCOMMA_DETECT DEC_VALID_COMMA_ONLY DFE_D_X_REL_POS DFE_VCM_COMP_EN DMONITOR_CFG0 DMONITOR_CFG1 ES_CLK_PHASE_SEL ES_CONTROL ES_ERRDET_EN ES_EYE_SCAN_EN ES_HORZ_OFFSET ES_PMA_CFG ES_PRESCALE ES_QUALIFIER0 ES_QUALIFIER1 ES_QUALIFIER2 ES_QUALIFIER3 ES_QUALIFIER4 ES_QUALIFIER5 ES_QUALIFIER6 ES_QUALIFIER7 ES_QUALIFIER8 ES_QUALIFIER9 ES_QUAL_MASK0 ES_QUAL_MASK1 ES_QUAL_MASK2 ES_QUAL_MASK3 ES_QUAL_MASK4 ES_QUAL_MASK5 ES_QUAL_MASK6 ES_QUAL_MASK7 ES_QUAL_MASK8 ES_QUAL_MASK9 ES_SDATA_MASK0 ES_SDATA_MASK1 ES_SDATA_MASK2 ES_SDATA_MASK3 ES_SDATA_MASK4 ES_SDATA_MASK5 ES_SDATA_MASK6 ES_SDATA_MASK7 ES_SDATA_MASK8 ES_SDATA_MASK9 EVODD_PHI_CFG EYE_SCAN_SWAP_EN FTS_DESKEW_SEQ_ENABLE FTS_LANE_DESKEW_CFG FTS_LANE_DESKEW_EN GEARBOX_MODE GM_BIAS_SELECT ISCAN_CK_PH_SEL2 LOCAL_MASTER LOOP0_CFG LOOP10_CFG LOOP11_CFG LOOP12_CFG LOOP13_CFG LOOP1_CFG LOOP2_CFG LOOP3_CFG LOOP4_CFG LOOP5_CFG LOOP6_CFG LOOP7_CFG LOOP8_CFG LOOP9_CFG LPBK_BIAS_CTRL LPBK_EN_RCAL_B LPBK_EXT_RCAL LPBK_EXT_RL_CTRL LPBK_RG_CTRL OOBDIVCTL OOB_PWRUP PCI3_AUTO_REALIGN PCI3_PIPE_RX_ELECIDLE PCI3_RX_ASYNC_EBUF_BYPASS PCI3_RX_ELECIDLE_EI2_ENABLE PCI3_RX_ELECIDLE_H2L_COUNT PCI3_RX_ELECIDLE_H2L_DISABLE PCI3_RX_ELECIDLE_HI_COUNT PCI3_RX_ELECIDLE_LP4_DISABLE PCI3_RX_FIFO_DISABLE PCIE_BUFG_DIV_CTRL PCIE_RXPCS_CFG_GEN3 PCIE_RXPMA_CFG PCIE_TXPCS_CFG_GEN3 PCIE_TXPMA_CFG PCS_PCIE_EN PCS_RSVD0 PCS_RSVD1 PD_TRANS_TIME_FROM_P2 PD_TRANS_TIME_NONE_P2 PD_TRANS_TIME_TO_P2 PLL_SEL_MODE_GEN12 PLL_SEL_MODE_GEN3 PMA_RSV0 PMA_RSV1 PREIQ_FREQ_BST PROCESS_PAR RATE_SW_USE_DRP RESET_POWERSAVE_DISABLE RXBUFRESET_TIME RXBUF_ADDR_MODE RXBUF_EIDLE_HI_CNT RXBUF_EIDLE_LO_CNT RXBUF_EN RXBUF_RESET_ON_CB_CHANGE RXBUF_RESET_ON_COMMAALIGN RXBUF_RESET_ON_EIDLE RXBUF_RESET_ON_RATE_CHANGE RXBUF_THRESH_OVFLW RXBUF_THRESH_OVRD RXBUF_THRESH_UNDFLW RXCDRFREQRESET_TIME RXCDRPHRESET_TIME RXCDR_CFG0 RXCDR_CFG0_GEN3 RXCDR_CFG1 RXCDR_CFG1_GEN3 RXCDR_CFG2 RXCDR_CFG2_GEN3 RXCDR_CFG3 RXCDR_CFG3_GEN3 RXCDR_CFG4 RXCDR_CFG4_GEN3 RXCDR_CFG5 RXCDR_CFG5_GEN3 RXCDR_FR_RESET_ON_EIDLE RXCDR_HOLD_DURING_EIDLE RXCDR_LOCK_CFG0 RXCDR_LOCK_CFG1 RXCDR_LOCK_CFG2 RXCDR_LOCK_CFG3 RXCDR_PH_RESET_ON_EIDLE RXCFOKDONE_SRC RXCFOK_CFG0 RXCFOK_CFG1 RXCFOK_CFG2 RXDFELPMRESET_TIME RXDFELPM_KL_CFG0 RXDFELPM_KL_CFG1 RXDFELPM_KL_CFG2 RXDFE_CFG0 RXDFE_CFG1 RXDFE_GC_CFG0 RXDFE_GC_CFG1 RXDFE_GC_CFG2 RXDFE_H2_CFG0 RXDFE_H2_CFG1 RXDFE_H3_CFG0 RXDFE_H3_CFG1 RXDFE_H4_CFG0 RXDFE_H4_CFG1 RXDFE_H5_CFG0 RXDFE_H5_CFG1 RXDFE_H6_CFG0 RXDFE_H6_CFG1 RXDFE_H7_CFG0 RXDFE_H7_CFG1 RXDFE_H8_CFG0 RXDFE_H8_CFG1 RXDFE_H9_CFG0 RXDFE_H9_CFG1 RXDFE_HA_CFG0 RXDFE_HA_CFG1 RXDFE_HB_CFG0 RXDFE_HB_CFG1 RXDFE_HC_CFG0 RXDFE_HC_CFG1 RXDFE_HD_CFG0 RXDFE_HD_CFG1 RXDFE_HE_CFG0 RXDFE_HE_CFG1 RXDFE_HF_CFG0 RXDFE_HF_CFG1 RXDFE_OS_CFG0 RXDFE_OS_CFG1 RXDFE_PWR_SAVING RXDFE_UT_CFG0 RXDFE_UT_CFG1 RXDFE_VP_CFG0 RXDFE_VP_CFG1 RXDLY_CFG RXDLY_LCFG RXELECIDLE_CFG RXGBOX_FIFO_INIT_RD_ADDR RXGEARBOX_EN RXISCANRESET_TIME RXLPM_CFG RXLPM_GC_CFG RXLPM_KH_CFG0 RXLPM_KH_CFG1 RXLPM_OS_CFG0 RXLPM_OS_CFG1 RXOOB_CFG RXOOB_CLK_CFG RXOSCALRESET_TIME RXOUT_DIV RXPCSRESET_TIME RXPHBEACON_CFG RXPHDLY_CFG RXPHSAMP_CFG RXPHSLIP_CFG RXPH_MONITOR_SEL RXPI_AUTO_BW_SEL_BYPASS RXPI_CFG RXPI_LPM RXPI_RSV0 RXPI_RSV1 RXPI_SEL_LC RXPI_STARTCODE RXPI_VREFSEL RXPMACLK_SEL RXPMARESET_TIME RXPRBS_ERR_LOOPBACK RXPRBS_LINKACQ_CNT RXSLIDE_AUTO_WAIT RXSLIDE_MODE RXSYNC_MULTILANE RXSYNC_OVRD RXSYNC_SKIP_DA RX_AFE_CM_EN RX_BIAS_CFG0 RX_BUFFER_CFG RX_CAPFF_SARC_ENB RX_CLK25_DIV RX_CLKMUX_EN RX_CLK_SLIP_OVRD RX_CM_BUF_CFG RX_CM_BUF_PD RX_CM_SEL RX_CM_TRIM RX_CTLE1_KHKL RX_CTLE1_RE RX_CTLE2_KHKL RX_CTLE2_RE RX_CTLE3_AGC RX_CTLE3_RE RX_DATA_WIDTH RX_DDI_SEL RX_DEFER_RESET_BUF_EN RX_DFELPM_CFG0 RX_DFELPM_CFG1 RX_DFELPM_KLKH_AGC_STUP_EN RX_DFE_AGC_CFG0 RX_DFE_AGC_CFG1 RX_DFE_KL_LPM_KH_CFG0 RX_DFE_KL_LPM_KH_CFG1 RX_DFE_KL_LPM_KL_CFG0 RX_DFE_KL_LPM_KL_CFG1 RX_DFE_LPM_HOLD_DURING_EIDLE RX_DISPERR_SEQ_MATCH RX_DIV2_MOD_B RX_DIVRESET_TIME RX_EN_CTLE_RCAL_B RX_EN_HI_LR RX_EXT_RL_CTRL RX_EYESCAN_VS_CODE RX_EYESCAN_VS_NEG_DIR RX_EYESCAN_VS_RANGE RX_EYESCAN_VS_UT_SIGN RX_FABINT_USRCLK_FLOP RX_INT_DATAWIDTH RX_PMA_POWER_SAVE RX_PROGDIV_CFG RX_SAMPLE_PERIOD RX_SIG_VALID_DLY RX_SUM_DEG_CTRL RX_SUM_DFETAPREP_EN RX_SUM_IREF_TUNE RX_SUM_RESLOAD_OVWR RX_SUM_RES_CTRL RX_SUM_VCMTUNE RX_SUM_VCM_OVWR RX_SUM_VREF_TUNE RX_TUNE_AFE_OS RX_VREG_CTRL RX_VREG_PDB RX_WIDEMODE_CDR RX_XCLK_SEL RX_XMODE_SEL SAS_MAX_COM SAS_MIN_COM SATA_BURST_SEQ_LEN SATA_BURST_VAL SATA_CPLL_CFG SATA_EIDLE_VAL SATA_MAX_BURST SATA_MAX_INIT SATA_MAX_WAKE SATA_MIN_BURST SATA_MIN_INIT SATA_MIN_WAKE SHOW_REALIGN_COMMA TAPDLY_SET_TX TEMPERATURE_PAR TERM_RCAL_CFG TERM_RCAL_OVRD TRANS_TIME_RATE TST_RSV0 TST_RSV1 TX2TO1_TAIL TXBUF_EN TXBUF_RESET_ON_RATE_CHANGE TXDLY_CFG TXDLY_LCFG TXFIFO_ADDR_CFG TXGBOX_FIFO_INIT_RD_ADDR TXGEARBOX_EN TXOUT_DIV TXPCSRESET_TIME TXPDR_TAIL TXPHDLY_CFG0 TXPHDLY_CFG1 TXPH_CFG TXPH_MONITOR_SEL TXPI_CFG0 TXPI_CFG1 TXPI_CFG2 TXPI_CFG3 TXPI_CFG4 TXPI_CFG5 TXPI_GRAY_SEL TXPI_INVSTROBE_SEL TXPI_LPM TXPI_PPMCLK_SEL TXPI_PPM_CFG TXPI_RSV0 TXPI_RSV1 TXPI_SYNFREQ_PPM TXPI_VREFSEL TXPMARESET_TIME TXSYNC_MULTILANE TXSYNC_OVRD TXSYNC_SKIP_DA TX_CLK25_DIV TX_CLKMUX_EN TX_CLKREG_PDB TX_CLKREG_SET TX_DATA_WIDTH TX_DCD_CFG TX_DCD_EN TX_DEEMPH0 TX_DEEMPH1 TX_DIVRESET_TIME TX_DRIVE_MODE TX_EIDLE_ASSERT_DELAY TX_EIDLE_DEASSERT_DELAY TX_EML_PHI_TUNE TX_FABINT_USRCLK_FLOP TX_FIFO_BYP_EN TX_IDLE_DATA_ZERO TX_INT_DATAWIDTH TX_LOOPBACK_DRIVE_HIZ TX_MAINCURSOR_SEL TX_MARGIN_FULL_0 TX_MARGIN_FULL_1 TX_MARGIN_FULL_2 TX_MARGIN_FULL_3 TX_MARGIN_FULL_4 TX_MARGIN_LOW_0 TX_MARGIN_LOW_1 TX_MARGIN_LOW_2 TX_MARGIN_LOW_3 TX_MARGIN_LOW_4 TX_MODE_SEL TX_PHICAL_CFG0 TX_PHICAL_CFG1 TX_PHICAL_CFG2 TX_PIDAC_VREF TX_PI_BIASSET TX_PI_CFG0 TX_PI_CFG1 TX_PI_DIV2_MODE_B TX_PI_SEL_LC0 TX_PI_SEL_LC1 TX_PMADATA_OPT TX_PMA_POWER_SAVE TX_PROGCLK_SEL TX_PROGDIV_CFG TX_RXDETECT_CFG TX_RXDETECT_REF TX_SAMPLE_PERIOD TX_SARC_LPBK_ENB TX_XCLK_SEL USE_PCS_CLK_PHASE_SEL} }
     GTYE3_COMMON { cfg_element {BIAS_CFG0 BIAS_CFG1 BIAS_CFG2 BIAS_CFG3 BIAS_CFG4 BIAS_CFG_RSVD COMMON_CFG0 COMMON_CFG1 POR_CFG QPLL0_CFG0 QPLL0_CFG1 QPLL0_CFG1_G3 QPLL0_CFG2 QPLL0_CFG2_G3 QPLL0_CFG3 QPLL0_CFG4 QPLL0_CP QPLL0_CP_G3 QPLL0_FBDIV QPLL0_FBDIV_G3 QPLL0_INIT_CFG0 QPLL0_INIT_CFG1 QPLL0_LOCK_CFG QPLL0_LOCK_CFG_G3 QPLL0_LPF QPLL0_LPF_G3 QPLL0_REFCLK_DIV QPLL0_SDM_CFG0 QPLL0_SDM_CFG1 QPLL0_SDM_CFG2 QPLL1_CFG0 QPLL1_CFG1 QPLL1_CFG1_G3 QPLL1_CFG2 QPLL1_CFG2_G3 QPLL1_CFG3 QPLL1_CFG4 QPLL1_CP QPLL1_CP_G3 QPLL1_FBDIV QPLL1_FBDIV_G3 QPLL1_INIT_CFG0 QPLL1_INIT_CFG1 QPLL1_LOCK_CFG QPLL1_LOCK_CFG_G3 QPLL1_LPF QPLL1_LPF_G3 QPLL1_REFCLK_DIV QPLL1_SDM_CFG0 QPLL1_SDM_CFG1 QPLL1_SDM_CFG2 RSVD_ATTR0 RSVD_ATTR1 RSVD_ATTR2 RSVD_ATTR3 RXRECCLKOUT0_SEL RXRECCLKOUT1_SEL SARC_EN SARC_SEL SDM0DATA1_0 SDM0DATA1_1 SDM0INITSEED0_0 SDM0INITSEED0_1 SDM0_DATA_PIN_SEL SDM0_WIDTH_PIN_SEL SDM1DATA1_0 SDM1DATA1_1 SDM1INITSEED0_0 SDM1INITSEED0_1 SDM1_DATA_PIN_SEL SDM1_WIDTH_PIN_SEL} }
     HARD_SYNC { cfg_element {INIT LATENCY} }
     HPIO_VREF { cfg_element VREF_CNTR }
     HPIO_ZMATCH_BLK_HCLK { cfg_element {} }
     IBUFCTRL { cfg_element {IOB_TYPE IO_TYPE ISTANDARD} }
     IBUFDS_GTE3 { cfg_element {REFCLK_EN_FABRIC_CK REFCLK_EN_TX_PATH REFCLK_HROW_CK_SEL REFCLK_ICNTL_RX} }
     IBUFDS_GTYE3 { cfg_element {REFCLK_EN_FABRIC_CK REFCLK_EN_TX_PATH REFCLK_HROW_CK_SEL REFCLK_ICNTL_RX} }
     ICAPE3 { cfg_element {} }
     IDELAYCTRL { cfg_element {} }
     IDELAYE3 { cfg_element {CASCADE DELAY_FORMAT DELAY_SRC DELAY_TYPE DELAY_VALUE REFCLK_FREQUENCY UPDATE_MODE} }
     ILKN { cfg_element {BYPASS CTL_RX_BURSTMAX CTL_RX_CHAN_EXT CTL_RX_LAST_LANE CTL_RX_MFRAMELEN_MINUS1 CTL_RX_PACKET_MODE CTL_RX_RETRANS_MULT CTL_RX_RETRANS_RETRY CTL_RX_RETRANS_TIMER1 CTL_RX_RETRANS_TIMER2 CTL_RX_RETRANS_WDOG CTL_RX_RETRANS_WRAP_TIMER CTL_TEST_MODE_PIN_CHAR CTL_TX_BURSTMAX CTL_TX_BURSTSHORT CTL_TX_CHAN_EXT CTL_TX_DISABLE_SKIPWORD CTL_TX_FC_CALLEN CTL_TX_LAST_LANE CTL_TX_MFRAMELEN_MINUS1 CTL_TX_RETRANS_DEPTH CTL_TX_RETRANS_MULT CTL_TX_RETRANS_RAM_BANKS MODE TEST_MODE_PIN_CHAR} }
     ILMAC { cfg_element {TEST_MODE_PIN_CHAR def_bypass def_mode def_rx_burstmax def_rx_last_lane def_rx_mframelen_minus1 def_tx_burstmax def_tx_burstshort def_tx_disable_skipword def_tx_fc_callen def_tx_last_lane def_tx_mframelen_minus1 def_tx_rdyout_thresh} }
     INBUF { cfg_element {DQS_BIAS IBUF_LOW_PWR IOB_TYPE IO_TYPE ISTANDARD IPROGRAMMING} }
     INV { cfg_element {} }
     ISERDESE3 { cfg_element {DATA_WIDTH DDR_CLK_EDGE FIFO_ENABLE FIFO_SYNC_MODE IDDR_MODE} }
     KEEPER { cfg_element {} }
     LDCE { cfg_element INIT }
     LDPE { cfg_element INIT }
     LUT1 { cfg_element INIT }
     LUT2 { cfg_element INIT }
     LUT3 { cfg_element INIT }
     LUT4 { cfg_element INIT }
     LUT5 { cfg_element INIT }
     LUT6 { cfg_element INIT }
     MASTER_JTAG { cfg_element {} }
     MMCME3_ADV { cfg_element {BANDWIDTH CLKFBOUT_MULT_F CLKFBOUT_PHASE CLKFBOUT_USE_FINE_PS CLKIN1_PERIOD CLKIN2_PERIOD CLKOUT0_DIVIDE_F CLKOUT0_DUTY_CYCLE CLKOUT0_PHASE CLKOUT0_USE_FINE_PS CLKOUT1_DIVIDE CLKOUT1_DUTY_CYCLE CLKOUT1_PHASE CLKOUT1_USE_FINE_PS CLKOUT2_DIVIDE CLKOUT2_DUTY_CYCLE CLKOUT2_PHASE CLKOUT2_USE_FINE_PS CLKOUT3_DIVIDE CLKOUT3_DUTY_CYCLE CLKOUT3_PHASE CLKOUT3_USE_FINE_PS CLKOUT4_CASCADE CLKOUT4_DIVIDE CLKOUT4_DUTY_CYCLE CLKOUT4_PHASE CLKOUT4_USE_FINE_PS CLKOUT5_DIVIDE CLKOUT5_DUTY_CYCLE CLKOUT5_PHASE CLKOUT5_USE_FINE_PS CLKOUT6_DIVIDE CLKOUT6_DUTY_CYCLE CLKOUT6_PHASE CLKOUT6_USE_FINE_PS COMPENSATION DIVCLK_DIVIDE REF_JITTER1 REF_JITTER2 SS_EN SS_MODE SS_MOD_PERIOD STARTUP_WAIT} }
     MMCME3_BASE { cfg_element {BANDWIDTH CLKFBOUT_MULT_F CLKFBOUT_PHASE CLKIN1_PERIOD CLKOUT0_DIVIDE_F CLKOUT0_DUTY_CYCLE CLKOUT0_PHASE CLKOUT1_DIVIDE CLKOUT1_DUTY_CYCLE CLKOUT1_PHASE CLKOUT2_DIVIDE CLKOUT2_DUTY_CYCLE CLKOUT2_PHASE CLKOUT3_DIVIDE CLKOUT3_DUTY_CYCLE CLKOUT3_PHASE CLKOUT4_CASCADE CLKOUT4_DIVIDE CLKOUT4_DUTY_CYCLE CLKOUT4_PHASE CLKOUT5_DIVIDE CLKOUT5_DUTY_CYCLE CLKOUT5_PHASE CLKOUT6_DIVIDE CLKOUT6_DUTY_CYCLE CLKOUT6_PHASE DIVCLK_DIVIDE REF_JITTER1 STARTUP_WAIT} }
     MUXF7 { cfg_element {} }
     MUXF8 { cfg_element {} }
     MUXF9 { cfg_element {} }
     OBUF { cfg_element {DRIVE IOSTANDARD SLEW} }
     OBUFDS { cfg_element {IOSTANDARD SLEW} }
     OBUFDS_GTE3 { cfg_element {REFCLK_EN_TX_PATH REFCLK_ICNTL_TX} }
     OBUFDS_GTE3_ADV { cfg_element {REFCLK_EN_TX_PATH REFCLK_ICNTL_TX} }
     OBUFDS_GTYE3 { cfg_element {REFCLK_EN_TX_PATH REFCLK_ICNTL_TX} }
     OBUFDS_GTYE3_ADV { cfg_element {REFCLK_EN_TX_PATH REFCLK_ICNTL_TX} }
     OBUFT { cfg_element {DRIVE IOSTANDARD SLEW} }
     OBUFT_DCIEN { cfg_element {DRIVE IOSTANDARD SLEW} }
     OBUFTDS { cfg_element {IOSTANDARD SLEW} }
     OBUFTDS_DCIEN { cfg_element {IOSTANDARD SLEW} }
     OBUFTDSE3 { cfg_element {IOSTANDARD SLEW_ADV} }
     OBUFTE3 { cfg_element {DRIVE IOSTANDARD SLEW_ADV} }
     ODELAYE3 { cfg_element {CASCADE DELAY_FORMAT DELAY_TYPE DELAY_VALUE REFCLK_FREQUENCY UPDATE_MODE} }
     OR2L { cfg_element {} }
     OSERDESE3 { cfg_element {DATA_WIDTH INIT ODDR_MODE OSERDES_D_BYPASS OSERDES_T_BYPASS} }
     OSERDESE3_ODDR { cfg_element {DATA_WIDTH INIT OSERDES_D_BYPASS OSERDES_T_BYPASS} }
     PCIE_3_1 { cfg_element {ARI_CAP_ENABLE AXISTEN_IF_CC_ALIGNMENT_MODE AXISTEN_IF_CC_PARITY_CHK AXISTEN_IF_CQ_ALIGNMENT_MODE AXISTEN_IF_ENABLE_CLIENT_TAG AXISTEN_IF_ENABLE_MSG_ROUTE AXISTEN_IF_ENABLE_RX_MSG_INTFC AXISTEN_IF_RC_ALIGNMENT_MODE AXISTEN_IF_RC_STRADDLE AXISTEN_IF_RQ_ALIGNMENT_MODE AXISTEN_IF_RQ_PARITY_CHK AXISTEN_IF_WIDTH CRM_CORE_CLK_FREQ_500 CRM_USER_CLK_FREQ DEBUG_CFG_LOCAL_MGMT_REG_ACCESS_OVERRIDE DEBUG_PL_DISABLE_EI_INFER_IN_L0 DEBUG_TL_DISABLE_RX_TLP_ORDER_CHECKS DNSTREAM_LINK_NUM LL_ACK_TIMEOUT LL_ACK_TIMEOUT_EN LL_ACK_TIMEOUT_FUNC LL_CPL_FC_UPDATE_TIMER LL_CPL_FC_UPDATE_TIMER_OVERRIDE LL_FC_UPDATE_TIMER LL_FC_UPDATE_TIMER_OVERRIDE LL_NP_FC_UPDATE_TIMER LL_NP_FC_UPDATE_TIMER_OVERRIDE LL_P_FC_UPDATE_TIMER LL_P_FC_UPDATE_TIMER_OVERRIDE LL_REPLAY_TIMEOUT LL_REPLAY_TIMEOUT_EN LL_REPLAY_TIMEOUT_FUNC LTR_TX_MESSAGE_MINIMUM_INTERVAL LTR_TX_MESSAGE_ON_FUNC_POWER_STATE_CHANGE LTR_TX_MESSAGE_ON_LTR_ENABLE MCAP_CAP_NEXTPTR MCAP_CONFIGURE_OVERRIDE MCAP_ENABLE MCAP_EOS_DESIGN_SWITCH MCAP_FPGA_BITSTREAM_VERSION MCAP_GATE_IO_ENABLE_DESIGN_SWITCH MCAP_GATE_MEM_ENABLE_DESIGN_SWITCH MCAP_INPUT_GATE_DESIGN_SWITCH MCAP_INTERRUPT_ON_MCAP_EOS MCAP_INTERRUPT_ON_MCAP_ERROR MCAP_VSEC_ID MCAP_VSEC_LEN MCAP_VSEC_REV PF0_AER_CAP_ECRC_CHECK_CAPABLE PF0_AER_CAP_ECRC_GEN_CAPABLE PF0_AER_CAP_NEXTPTR PF0_ARI_CAP_NEXTPTR PF0_ARI_CAP_NEXT_FUNC PF0_ARI_CAP_VER PF0_BAR0_APERTURE_SIZE PF0_BAR0_CONTROL PF0_BAR1_APERTURE_SIZE PF0_BAR1_CONTROL PF0_BAR2_APERTURE_SIZE PF0_BAR2_CONTROL PF0_BAR3_APERTURE_SIZE PF0_BAR3_CONTROL PF0_BAR4_APERTURE_SIZE PF0_BAR4_CONTROL PF0_BAR5_APERTURE_SIZE PF0_BAR5_CONTROL PF0_BIST_REGISTER PF0_CAPABILITY_POINTER PF0_CLASS_CODE PF0_DEVICE_ID PF0_DEV_CAP2_128B_CAS_ATOMIC_COMPLETER_SUPPORT PF0_DEV_CAP2_32B_ATOMIC_COMPLETER_SUPPORT PF0_DEV_CAP2_64B_ATOMIC_COMPLETER_SUPPORT PF0_DEV_CAP2_ARI_FORWARD_ENABLE PF0_DEV_CAP2_CPL_TIMEOUT_DISABLE PF0_DEV_CAP2_LTR_SUPPORT PF0_DEV_CAP2_OBFF_SUPPORT PF0_DEV_CAP2_TPH_COMPLETER_SUPPORT PF0_DEV_CAP_ENDPOINT_L0S_LATENCY PF0_DEV_CAP_ENDPOINT_L1_LATENCY PF0_DEV_CAP_EXT_TAG_SUPPORTED PF0_DEV_CAP_FUNCTION_LEVEL_RESET_CAPABLE PF0_DEV_CAP_MAX_PAYLOAD_SIZE PF0_DPA_CAP_NEXTPTR PF0_DPA_CAP_SUB_STATE_CONTROL PF0_DPA_CAP_SUB_STATE_CONTROL_EN PF0_DPA_CAP_SUB_STATE_POWER_ALLOCATION0 PF0_DPA_CAP_SUB_STATE_POWER_ALLOCATION1 PF0_DPA_CAP_SUB_STATE_POWER_ALLOCATION2 PF0_DPA_CAP_SUB_STATE_POWER_ALLOCATION3 PF0_DPA_CAP_SUB_STATE_POWER_ALLOCATION4 PF0_DPA_CAP_SUB_STATE_POWER_ALLOCATION5 PF0_DPA_CAP_SUB_STATE_POWER_ALLOCATION6 PF0_DPA_CAP_SUB_STATE_POWER_ALLOCATION7 PF0_DPA_CAP_VER PF0_DSN_CAP_NEXTPTR PF0_EXPANSION_ROM_APERTURE_SIZE PF0_EXPANSION_ROM_ENABLE PF0_INTERRUPT_LINE PF0_INTERRUPT_PIN PF0_LINK_CAP_ASPM_SUPPORT PF0_LINK_CAP_L0S_EXIT_LATENCY_COMCLK_GEN1 PF0_LINK_CAP_L0S_EXIT_LATENCY_COMCLK_GEN2 PF0_LINK_CAP_L0S_EXIT_LATENCY_COMCLK_GEN3 PF0_LINK_CAP_L0S_EXIT_LATENCY_GEN1 PF0_LINK_CAP_L0S_EXIT_LATENCY_GEN2 PF0_LINK_CAP_L0S_EXIT_LATENCY_GEN3 PF0_LINK_CAP_L1_EXIT_LATENCY_COMCLK_GEN1 PF0_LINK_CAP_L1_EXIT_LATENCY_COMCLK_GEN2 PF0_LINK_CAP_L1_EXIT_LATENCY_COMCLK_GEN3 PF0_LINK_CAP_L1_EXIT_LATENCY_GEN1 PF0_LINK_CAP_L1_EXIT_LATENCY_GEN2 PF0_LINK_CAP_L1_EXIT_LATENCY_GEN3 PF0_LINK_STATUS_SLOT_CLOCK_CONFIG PF0_LTR_CAP_MAX_NOSNOOP_LAT PF0_LTR_CAP_MAX_SNOOP_LAT PF0_LTR_CAP_NEXTPTR PF0_LTR_CAP_VER PF0_MSIX_CAP_NEXTPTR PF0_MSIX_CAP_PBA_BIR PF0_MSIX_CAP_PBA_OFFSET PF0_MSIX_CAP_TABLE_BIR PF0_MSIX_CAP_TABLE_OFFSET PF0_MSIX_CAP_TABLE_SIZE PF0_MSI_CAP_MULTIMSGCAP PF0_MSI_CAP_NEXTPTR PF0_MSI_CAP_PERVECMASKCAP PF0_PB_CAP_DATA_REG_D0 PF0_PB_CAP_DATA_REG_D0_SUSTAINED PF0_PB_CAP_DATA_REG_D1 PF0_PB_CAP_DATA_REG_D3HOT PF0_PB_CAP_NEXTPTR PF0_PB_CAP_SYSTEM_ALLOCATED PF0_PB_CAP_VER PF0_PM_CAP_ID PF0_PM_CAP_NEXTPTR PF0_PM_CAP_PMESUPPORT_D0 PF0_PM_CAP_PMESUPPORT_D1 PF0_PM_CAP_PMESUPPORT_D3HOT PF0_PM_CAP_SUPP_D1_STATE PF0_PM_CAP_VER_ID PF0_PM_CSR_NOSOFTRESET PF0_RBAR_CAP_ENABLE PF0_RBAR_CAP_NEXTPTR PF0_RBAR_CAP_SIZE0 PF0_RBAR_CAP_SIZE1 PF0_RBAR_CAP_SIZE2 PF0_RBAR_CAP_VER PF0_RBAR_CONTROL_INDEX0 PF0_RBAR_CONTROL_INDEX1 PF0_RBAR_CONTROL_INDEX2 PF0_RBAR_CONTROL_SIZE0 PF0_RBAR_CONTROL_SIZE1 PF0_RBAR_CONTROL_SIZE2 PF0_RBAR_NUM PF0_REVISION_ID PF0_SECONDARY_PCIE_CAP_NEXTPTR PF0_SRIOV_BAR0_APERTURE_SIZE PF0_SRIOV_BAR0_CONTROL PF0_SRIOV_BAR1_APERTURE_SIZE PF0_SRIOV_BAR1_CONTROL PF0_SRIOV_BAR2_APERTURE_SIZE PF0_SRIOV_BAR2_CONTROL PF0_SRIOV_BAR3_APERTURE_SIZE PF0_SRIOV_BAR3_CONTROL PF0_SRIOV_BAR4_APERTURE_SIZE PF0_SRIOV_BAR4_CONTROL PF0_SRIOV_BAR5_APERTURE_SIZE PF0_SRIOV_BAR5_CONTROL PF0_SRIOV_CAP_INITIAL_VF PF0_SRIOV_CAP_NEXTPTR PF0_SRIOV_CAP_TOTAL_VF PF0_SRIOV_CAP_VER PF0_SRIOV_FIRST_VF_OFFSET PF0_SRIOV_FUNC_DEP_LINK PF0_SRIOV_SUPPORTED_PAGE_SIZE PF0_SRIOV_VF_DEVICE_ID PF0_SUBSYSTEM_ID PF0_TPHR_CAP_DEV_SPECIFIC_MODE PF0_TPHR_CAP_ENABLE PF0_TPHR_CAP_INT_VEC_MODE PF0_TPHR_CAP_NEXTPTR PF0_TPHR_CAP_ST_MODE_SEL PF0_TPHR_CAP_ST_TABLE_LOC PF0_TPHR_CAP_ST_TABLE_SIZE PF0_TPHR_CAP_VER PF0_VC_CAP_ENABLE PF0_VC_CAP_NEXTPTR PF0_VC_CAP_VER PF1_AER_CAP_ECRC_CHECK_CAPABLE PF1_AER_CAP_ECRC_GEN_CAPABLE PF1_AER_CAP_NEXTPTR PF1_ARI_CAP_NEXTPTR PF1_ARI_CAP_NEXT_FUNC PF1_BAR0_APERTURE_SIZE PF1_BAR0_CONTROL PF1_BAR1_APERTURE_SIZE PF1_BAR1_CONTROL PF1_BAR2_APERTURE_SIZE PF1_BAR2_CONTROL PF1_BAR3_APERTURE_SIZE PF1_BAR3_CONTROL PF1_BAR4_APERTURE_SIZE PF1_BAR4_CONTROL PF1_BAR5_APERTURE_SIZE PF1_BAR5_CONTROL PF1_BIST_REGISTER PF1_CAPABILITY_POINTER PF1_CLASS_CODE PF1_DEVICE_ID PF1_DEV_CAP_MAX_PAYLOAD_SIZE PF1_DPA_CAP_NEXTPTR PF1_DPA_CAP_SUB_STATE_CONTROL PF1_DPA_CAP_SUB_STATE_CONTROL_EN PF1_DPA_CAP_SUB_STATE_POWER_ALLOCATION0 PF1_DPA_CAP_SUB_STATE_POWER_ALLOCATION1 PF1_DPA_CAP_SUB_STATE_POWER_ALLOCATION2 PF1_DPA_CAP_SUB_STATE_POWER_ALLOCATION3 PF1_DPA_CAP_SUB_STATE_POWER_ALLOCATION4 PF1_DPA_CAP_SUB_STATE_POWER_ALLOCATION5 PF1_DPA_CAP_SUB_STATE_POWER_ALLOCATION6 PF1_DPA_CAP_SUB_STATE_POWER_ALLOCATION7 PF1_DPA_CAP_VER PF1_DSN_CAP_NEXTPTR PF1_EXPANSION_ROM_APERTURE_SIZE PF1_EXPANSION_ROM_ENABLE PF1_INTERRUPT_LINE PF1_INTERRUPT_PIN PF1_MSIX_CAP_NEXTPTR PF1_MSIX_CAP_PBA_BIR PF1_MSIX_CAP_PBA_OFFSET PF1_MSIX_CAP_TABLE_BIR PF1_MSIX_CAP_TABLE_OFFSET PF1_MSIX_CAP_TABLE_SIZE PF1_MSI_CAP_MULTIMSGCAP PF1_MSI_CAP_NEXTPTR PF1_MSI_CAP_PERVECMASKCAP PF1_PB_CAP_DATA_REG_D0 PF1_PB_CAP_DATA_REG_D0_SUSTAINED PF1_PB_CAP_DATA_REG_D1 PF1_PB_CAP_DATA_REG_D3HOT PF1_PB_CAP_NEXTPTR PF1_PB_CAP_SYSTEM_ALLOCATED PF1_PB_CAP_VER PF1_PM_CAP_ID PF1_PM_CAP_NEXTPTR PF1_PM_CAP_VER_ID PF1_RBAR_CAP_ENABLE PF1_RBAR_CAP_NEXTPTR PF1_RBAR_CAP_SIZE0 PF1_RBAR_CAP_SIZE1 PF1_RBAR_CAP_SIZE2 PF1_RBAR_CAP_VER PF1_RBAR_CONTROL_INDEX0 PF1_RBAR_CONTROL_INDEX1 PF1_RBAR_CONTROL_INDEX2 PF1_RBAR_CONTROL_SIZE0 PF1_RBAR_CONTROL_SIZE1 PF1_RBAR_CONTROL_SIZE2 PF1_RBAR_NUM PF1_REVISION_ID PF1_SRIOV_BAR0_APERTURE_SIZE PF1_SRIOV_BAR0_CONTROL PF1_SRIOV_BAR1_APERTURE_SIZE PF1_SRIOV_BAR1_CONTROL PF1_SRIOV_BAR2_APERTURE_SIZE PF1_SRIOV_BAR2_CONTROL PF1_SRIOV_BAR3_APERTURE_SIZE PF1_SRIOV_BAR3_CONTROL PF1_SRIOV_BAR4_APERTURE_SIZE PF1_SRIOV_BAR4_CONTROL PF1_SRIOV_BAR5_APERTURE_SIZE PF1_SRIOV_BAR5_CONTROL PF1_SRIOV_CAP_INITIAL_VF PF1_SRIOV_CAP_NEXTPTR PF1_SRIOV_CAP_TOTAL_VF PF1_SRIOV_CAP_VER PF1_SRIOV_FIRST_VF_OFFSET PF1_SRIOV_FUNC_DEP_LINK PF1_SRIOV_SUPPORTED_PAGE_SIZE PF1_SRIOV_VF_DEVICE_ID PF1_SUBSYSTEM_ID PF1_TPHR_CAP_DEV_SPECIFIC_MODE PF1_TPHR_CAP_ENABLE PF1_TPHR_CAP_INT_VEC_MODE PF1_TPHR_CAP_NEXTPTR PF1_TPHR_CAP_ST_MODE_SEL PF1_TPHR_CAP_ST_TABLE_LOC PF1_TPHR_CAP_ST_TABLE_SIZE PF1_TPHR_CAP_VER PF2_AER_CAP_ECRC_CHECK_CAPABLE PF2_AER_CAP_ECRC_GEN_CAPABLE PF2_AER_CAP_NEXTPTR PF2_ARI_CAP_NEXTPTR PF2_ARI_CAP_NEXT_FUNC PF2_BAR0_APERTURE_SIZE PF2_BAR0_CONTROL PF2_BAR1_APERTURE_SIZE PF2_BAR1_CONTROL PF2_BAR2_APERTURE_SIZE PF2_BAR2_CONTROL PF2_BAR3_APERTURE_SIZE PF2_BAR3_CONTROL PF2_BAR4_APERTURE_SIZE PF2_BAR4_CONTROL PF2_BAR5_APERTURE_SIZE PF2_BAR5_CONTROL PF2_BIST_REGISTER PF2_CAPABILITY_POINTER PF2_CLASS_CODE PF2_DEVICE_ID PF2_DEV_CAP_MAX_PAYLOAD_SIZE PF2_DPA_CAP_NEXTPTR PF2_DPA_CAP_SUB_STATE_CONTROL PF2_DPA_CAP_SUB_STATE_CONTROL_EN PF2_DPA_CAP_SUB_STATE_POWER_ALLOCATION0 PF2_DPA_CAP_SUB_STATE_POWER_ALLOCATION1 PF2_DPA_CAP_SUB_STATE_POWER_ALLOCATION2 PF2_DPA_CAP_SUB_STATE_POWER_ALLOCATION3 PF2_DPA_CAP_SUB_STATE_POWER_ALLOCATION4 PF2_DPA_CAP_SUB_STATE_POWER_ALLOCATION5 PF2_DPA_CAP_SUB_STATE_POWER_ALLOCATION6 PF2_DPA_CAP_SUB_STATE_POWER_ALLOCATION7 PF2_DPA_CAP_VER PF2_DSN_CAP_NEXTPTR PF2_EXPANSION_ROM_APERTURE_SIZE PF2_EXPANSION_ROM_ENABLE PF2_INTERRUPT_LINE PF2_INTERRUPT_PIN PF2_MSIX_CAP_NEXTPTR PF2_MSIX_CAP_PBA_BIR PF2_MSIX_CAP_PBA_OFFSET PF2_MSIX_CAP_TABLE_BIR PF2_MSIX_CAP_TABLE_OFFSET PF2_MSIX_CAP_TABLE_SIZE PF2_MSI_CAP_MULTIMSGCAP PF2_MSI_CAP_NEXTPTR PF2_MSI_CAP_PERVECMASKCAP PF2_PB_CAP_DATA_REG_D0 PF2_PB_CAP_DATA_REG_D0_SUSTAINED PF2_PB_CAP_DATA_REG_D1 PF2_PB_CAP_DATA_REG_D3HOT PF2_PB_CAP_NEXTPTR PF2_PB_CAP_SYSTEM_ALLOCATED PF2_PB_CAP_VER PF2_PM_CAP_ID PF2_PM_CAP_NEXTPTR PF2_PM_CAP_VER_ID PF2_RBAR_CAP_ENABLE PF2_RBAR_CAP_NEXTPTR PF2_RBAR_CAP_SIZE0 PF2_RBAR_CAP_SIZE1 PF2_RBAR_CAP_SIZE2 PF2_RBAR_CAP_VER PF2_RBAR_CONTROL_INDEX0 PF2_RBAR_CONTROL_INDEX1 PF2_RBAR_CONTROL_INDEX2 PF2_RBAR_CONTROL_SIZE0 PF2_RBAR_CONTROL_SIZE1 PF2_RBAR_CONTROL_SIZE2 PF2_RBAR_NUM PF2_REVISION_ID PF2_SRIOV_BAR0_APERTURE_SIZE PF2_SRIOV_BAR0_CONTROL PF2_SRIOV_BAR1_APERTURE_SIZE PF2_SRIOV_BAR1_CONTROL PF2_SRIOV_BAR2_APERTURE_SIZE PF2_SRIOV_BAR2_CONTROL PF2_SRIOV_BAR3_APERTURE_SIZE PF2_SRIOV_BAR3_CONTROL PF2_SRIOV_BAR4_APERTURE_SIZE PF2_SRIOV_BAR4_CONTROL PF2_SRIOV_BAR5_APERTURE_SIZE PF2_SRIOV_BAR5_CONTROL PF2_SRIOV_CAP_INITIAL_VF PF2_SRIOV_CAP_NEXTPTR PF2_SRIOV_CAP_TOTAL_VF PF2_SRIOV_CAP_VER PF2_SRIOV_FIRST_VF_OFFSET PF2_SRIOV_FUNC_DEP_LINK PF2_SRIOV_SUPPORTED_PAGE_SIZE PF2_SRIOV_VF_DEVICE_ID PF2_SUBSYSTEM_ID PF2_TPHR_CAP_DEV_SPECIFIC_MODE PF2_TPHR_CAP_ENABLE PF2_TPHR_CAP_INT_VEC_MODE PF2_TPHR_CAP_NEXTPTR PF2_TPHR_CAP_ST_MODE_SEL PF2_TPHR_CAP_ST_TABLE_LOC PF2_TPHR_CAP_ST_TABLE_SIZE PF2_TPHR_CAP_VER PF3_AER_CAP_ECRC_CHECK_CAPABLE PF3_AER_CAP_ECRC_GEN_CAPABLE PF3_AER_CAP_NEXTPTR PF3_ARI_CAP_NEXTPTR PF3_ARI_CAP_NEXT_FUNC PF3_BAR0_APERTURE_SIZE PF3_BAR0_CONTROL PF3_BAR1_APERTURE_SIZE PF3_BAR1_CONTROL PF3_BAR2_APERTURE_SIZE PF3_BAR2_CONTROL PF3_BAR3_APERTURE_SIZE PF3_BAR3_CONTROL PF3_BAR4_APERTURE_SIZE PF3_BAR4_CONTROL PF3_BAR5_APERTURE_SIZE PF3_BAR5_CONTROL PF3_BIST_REGISTER PF3_CAPABILITY_POINTER PF3_CLASS_CODE PF3_DEVICE_ID PF3_DEV_CAP_MAX_PAYLOAD_SIZE PF3_DPA_CAP_NEXTPTR PF3_DPA_CAP_SUB_STATE_CONTROL PF3_DPA_CAP_SUB_STATE_CONTROL_EN PF3_DPA_CAP_SUB_STATE_POWER_ALLOCATION0 PF3_DPA_CAP_SUB_STATE_POWER_ALLOCATION1 PF3_DPA_CAP_SUB_STATE_POWER_ALLOCATION2 PF3_DPA_CAP_SUB_STATE_POWER_ALLOCATION3 PF3_DPA_CAP_SUB_STATE_POWER_ALLOCATION4 PF3_DPA_CAP_SUB_STATE_POWER_ALLOCATION5 PF3_DPA_CAP_SUB_STATE_POWER_ALLOCATION6 PF3_DPA_CAP_SUB_STATE_POWER_ALLOCATION7 PF3_DPA_CAP_VER PF3_DSN_CAP_NEXTPTR PF3_EXPANSION_ROM_APERTURE_SIZE PF3_EXPANSION_ROM_ENABLE PF3_INTERRUPT_LINE PF3_INTERRUPT_PIN PF3_MSIX_CAP_NEXTPTR PF3_MSIX_CAP_PBA_BIR PF3_MSIX_CAP_PBA_OFFSET PF3_MSIX_CAP_TABLE_BIR PF3_MSIX_CAP_TABLE_OFFSET PF3_MSIX_CAP_TABLE_SIZE PF3_MSI_CAP_MULTIMSGCAP PF3_MSI_CAP_NEXTPTR PF3_MSI_CAP_PERVECMASKCAP PF3_PB_CAP_DATA_REG_D0 PF3_PB_CAP_DATA_REG_D0_SUSTAINED PF3_PB_CAP_DATA_REG_D1 PF3_PB_CAP_DATA_REG_D3HOT PF3_PB_CAP_NEXTPTR PF3_PB_CAP_SYSTEM_ALLOCATED PF3_PB_CAP_VER PF3_PM_CAP_ID PF3_PM_CAP_NEXTPTR PF3_PM_CAP_VER_ID PF3_RBAR_CAP_ENABLE PF3_RBAR_CAP_NEXTPTR PF3_RBAR_CAP_SIZE0 PF3_RBAR_CAP_SIZE1 PF3_RBAR_CAP_SIZE2 PF3_RBAR_CAP_VER PF3_RBAR_CONTROL_INDEX0 PF3_RBAR_CONTROL_INDEX1 PF3_RBAR_CONTROL_INDEX2 PF3_RBAR_CONTROL_SIZE0 PF3_RBAR_CONTROL_SIZE1 PF3_RBAR_CONTROL_SIZE2 PF3_RBAR_NUM PF3_REVISION_ID PF3_SRIOV_BAR0_APERTURE_SIZE PF3_SRIOV_BAR0_CONTROL PF3_SRIOV_BAR1_APERTURE_SIZE PF3_SRIOV_BAR1_CONTROL PF3_SRIOV_BAR2_APERTURE_SIZE PF3_SRIOV_BAR2_CONTROL PF3_SRIOV_BAR3_APERTURE_SIZE PF3_SRIOV_BAR3_CONTROL PF3_SRIOV_BAR4_APERTURE_SIZE PF3_SRIOV_BAR4_CONTROL PF3_SRIOV_BAR5_APERTURE_SIZE PF3_SRIOV_BAR5_CONTROL PF3_SRIOV_CAP_INITIAL_VF PF3_SRIOV_CAP_NEXTPTR PF3_SRIOV_CAP_TOTAL_VF PF3_SRIOV_CAP_VER PF3_SRIOV_FIRST_VF_OFFSET PF3_SRIOV_FUNC_DEP_LINK PF3_SRIOV_SUPPORTED_PAGE_SIZE PF3_SRIOV_VF_DEVICE_ID PF3_SUBSYSTEM_ID PF3_TPHR_CAP_DEV_SPECIFIC_MODE PF3_TPHR_CAP_ENABLE PF3_TPHR_CAP_INT_VEC_MODE PF3_TPHR_CAP_NEXTPTR PF3_TPHR_CAP_ST_MODE_SEL PF3_TPHR_CAP_ST_TABLE_LOC PF3_TPHR_CAP_ST_TABLE_SIZE PF3_TPHR_CAP_VER PL_DISABLE_AUTO_EQ_SPEED_CHANGE_TO_GEN3 PL_DISABLE_AUTO_SPEED_CHANGE_TO_GEN2 PL_DISABLE_EI_INFER_IN_L0 PL_DISABLE_GEN3_DC_BALANCE PL_DISABLE_GEN3_LFSR_UPDATE_ON_SKP PL_DISABLE_RETRAIN_ON_FRAMING_ERROR PL_DISABLE_SCRAMBLING PL_DISABLE_SYNC_HEADER_FRAMING_ERROR PL_DISABLE_UPCONFIG_CAPABLE PL_EQ_ADAPT_DISABLE_COEFF_CHECK PL_EQ_ADAPT_DISABLE_PRESET_CHECK PL_EQ_ADAPT_ITER_COUNT PL_EQ_ADAPT_REJECT_RETRY_COUNT PL_EQ_BYPASS_PHASE23 PL_EQ_DEFAULT_GEN3_RX_PRESET_HINT PL_EQ_DEFAULT_GEN3_TX_PRESET PL_EQ_PHASE01_RX_ADAPT PL_EQ_SHORT_ADAPT_PHASE PL_LANE0_EQ_CONTROL PL_LANE1_EQ_CONTROL PL_LANE2_EQ_CONTROL PL_LANE3_EQ_CONTROL PL_LANE4_EQ_CONTROL PL_LANE5_EQ_CONTROL PL_LANE6_EQ_CONTROL PL_LANE7_EQ_CONTROL PL_LINK_CAP_MAX_LINK_SPEED PL_LINK_CAP_MAX_LINK_WIDTH PL_N_FTS_COMCLK_GEN1 PL_N_FTS_COMCLK_GEN2 PL_N_FTS_COMCLK_GEN3 PL_N_FTS_GEN1 PL_N_FTS_GEN2 PL_N_FTS_GEN3 PL_REPORT_ALL_PHY_ERRORS PL_SIM_FAST_LINK_TRAINING PL_UPSTREAM_FACING PM_ASPML0S_TIMEOUT PM_ASPML1_ENTRY_DELAY PM_ENABLE_L23_ENTRY PM_ENABLE_SLOT_POWER_CAPTURE PM_L1_REENTRY_DELAY PM_PME_SERVICE_TIMEOUT_DELAY PM_PME_TURNOFF_ACK_DELAY SPARE_BIT0 SPARE_BIT1 SPARE_BIT2 SPARE_BIT3 SPARE_BIT4 SPARE_BIT5 SPARE_BIT6 SPARE_BIT7 SPARE_BIT8 SPARE_BYTE0 SPARE_BYTE1 SPARE_BYTE2 SPARE_BYTE3 SPARE_WORD0 SPARE_WORD1 SPARE_WORD2 SPARE_WORD3 SRIOV_CAP_ENABLE TL_COMPL_TIMEOUT_REG0 TL_COMPL_TIMEOUT_REG1 TL_CREDITS_CD TL_CREDITS_CH TL_CREDITS_NPD TL_CREDITS_NPH TL_CREDITS_PD TL_CREDITS_PH TL_ENABLE_MESSAGE_RID_CHECK_ENABLE TL_EXTENDED_CFG_EXTEND_INTERFACE_ENABLE TL_LEGACY_CFG_EXTEND_INTERFACE_ENABLE TL_LEGACY_MODE_ENABLE TL_PF_ENABLE_REG TL_TAG_MGMT_ENABLE TL_TX_MUX_STRICT_PRIORITY TWO_LAYER_MODE_DLCMSM_ENABLE TWO_LAYER_MODE_ENABLE TWO_LAYER_MODE_WIDTH_256 VF0_ARI_CAP_NEXTPTR VF0_CAPABILITY_POINTER VF0_MSIX_CAP_PBA_BIR VF0_MSIX_CAP_PBA_OFFSET VF0_MSIX_CAP_TABLE_BIR VF0_MSIX_CAP_TABLE_OFFSET VF0_MSIX_CAP_TABLE_SIZE VF0_MSI_CAP_MULTIMSGCAP VF0_PM_CAP_ID VF0_PM_CAP_NEXTPTR VF0_PM_CAP_VER_ID VF0_TPHR_CAP_DEV_SPECIFIC_MODE VF0_TPHR_CAP_ENABLE VF0_TPHR_CAP_INT_VEC_MODE VF0_TPHR_CAP_NEXTPTR VF0_TPHR_CAP_ST_MODE_SEL VF0_TPHR_CAP_ST_TABLE_LOC VF0_TPHR_CAP_ST_TABLE_SIZE VF0_TPHR_CAP_VER VF1_ARI_CAP_NEXTPTR VF1_MSIX_CAP_PBA_BIR VF1_MSIX_CAP_PBA_OFFSET VF1_MSIX_CAP_TABLE_BIR VF1_MSIX_CAP_TABLE_OFFSET VF1_MSIX_CAP_TABLE_SIZE VF1_MSI_CAP_MULTIMSGCAP VF1_PM_CAP_ID VF1_PM_CAP_NEXTPTR VF1_PM_CAP_VER_ID VF1_TPHR_CAP_DEV_SPECIFIC_MODE VF1_TPHR_CAP_ENABLE VF1_TPHR_CAP_INT_VEC_MODE VF1_TPHR_CAP_NEXTPTR VF1_TPHR_CAP_ST_MODE_SEL VF1_TPHR_CAP_ST_TABLE_LOC VF1_TPHR_CAP_ST_TABLE_SIZE VF1_TPHR_CAP_VER VF2_ARI_CAP_NEXTPTR VF2_MSIX_CAP_PBA_BIR VF2_MSIX_CAP_PBA_OFFSET VF2_MSIX_CAP_TABLE_BIR VF2_MSIX_CAP_TABLE_OFFSET VF2_MSIX_CAP_TABLE_SIZE VF2_MSI_CAP_MULTIMSGCAP VF2_PM_CAP_ID VF2_PM_CAP_NEXTPTR VF2_PM_CAP_VER_ID VF2_TPHR_CAP_DEV_SPECIFIC_MODE VF2_TPHR_CAP_ENABLE VF2_TPHR_CAP_INT_VEC_MODE VF2_TPHR_CAP_NEXTPTR VF2_TPHR_CAP_ST_MODE_SEL VF2_TPHR_CAP_ST_TABLE_LOC VF2_TPHR_CAP_ST_TABLE_SIZE VF2_TPHR_CAP_VER VF3_ARI_CAP_NEXTPTR VF3_MSIX_CAP_PBA_BIR VF3_MSIX_CAP_PBA_OFFSET VF3_MSIX_CAP_TABLE_BIR VF3_MSIX_CAP_TABLE_OFFSET VF3_MSIX_CAP_TABLE_SIZE VF3_MSI_CAP_MULTIMSGCAP VF3_PM_CAP_ID VF3_PM_CAP_NEXTPTR VF3_PM_CAP_VER_ID VF3_TPHR_CAP_DEV_SPECIFIC_MODE VF3_TPHR_CAP_ENABLE VF3_TPHR_CAP_INT_VEC_MODE VF3_TPHR_CAP_NEXTPTR VF3_TPHR_CAP_ST_MODE_SEL VF3_TPHR_CAP_ST_TABLE_LOC VF3_TPHR_CAP_ST_TABLE_SIZE VF3_TPHR_CAP_VER VF4_ARI_CAP_NEXTPTR VF4_MSIX_CAP_PBA_BIR VF4_MSIX_CAP_PBA_OFFSET VF4_MSIX_CAP_TABLE_BIR VF4_MSIX_CAP_TABLE_OFFSET VF4_MSIX_CAP_TABLE_SIZE VF4_MSI_CAP_MULTIMSGCAP VF4_PM_CAP_ID VF4_PM_CAP_NEXTPTR VF4_PM_CAP_VER_ID VF4_TPHR_CAP_DEV_SPECIFIC_MODE VF4_TPHR_CAP_ENABLE VF4_TPHR_CAP_INT_VEC_MODE VF4_TPHR_CAP_NEXTPTR VF4_TPHR_CAP_ST_MODE_SEL VF4_TPHR_CAP_ST_TABLE_LOC VF4_TPHR_CAP_ST_TABLE_SIZE VF4_TPHR_CAP_VER VF5_ARI_CAP_NEXTPTR VF5_MSIX_CAP_PBA_BIR VF5_MSIX_CAP_PBA_OFFSET VF5_MSIX_CAP_TABLE_BIR VF5_MSIX_CAP_TABLE_OFFSET VF5_MSIX_CAP_TABLE_SIZE VF5_MSI_CAP_MULTIMSGCAP VF5_PM_CAP_ID VF5_PM_CAP_NEXTPTR VF5_PM_CAP_VER_ID VF5_TPHR_CAP_DEV_SPECIFIC_MODE VF5_TPHR_CAP_ENABLE VF5_TPHR_CAP_INT_VEC_MODE VF5_TPHR_CAP_NEXTPTR VF5_TPHR_CAP_ST_MODE_SEL VF5_TPHR_CAP_ST_TABLE_LOC VF5_TPHR_CAP_ST_TABLE_SIZE VF5_TPHR_CAP_VER VF6_ARI_CAP_NEXTPTR VF6_MSIX_CAP_PBA_BIR VF6_MSIX_CAP_PBA_OFFSET VF6_MSIX_CAP_TABLE_BIR VF6_MSIX_CAP_TABLE_OFFSET VF6_MSIX_CAP_TABLE_SIZE VF6_MSI_CAP_MULTIMSGCAP VF6_PM_CAP_ID VF6_PM_CAP_NEXTPTR VF6_PM_CAP_VER_ID VF6_TPHR_CAP_DEV_SPECIFIC_MODE VF6_TPHR_CAP_ENABLE VF6_TPHR_CAP_INT_VEC_MODE VF6_TPHR_CAP_NEXTPTR VF6_TPHR_CAP_ST_MODE_SEL VF6_TPHR_CAP_ST_TABLE_LOC VF6_TPHR_CAP_ST_TABLE_SIZE VF6_TPHR_CAP_VER VF7_ARI_CAP_NEXTPTR VF7_MSIX_CAP_PBA_BIR VF7_MSIX_CAP_PBA_OFFSET VF7_MSIX_CAP_TABLE_BIR VF7_MSIX_CAP_TABLE_OFFSET VF7_MSIX_CAP_TABLE_SIZE VF7_MSI_CAP_MULTIMSGCAP VF7_PM_CAP_ID VF7_PM_CAP_NEXTPTR VF7_PM_CAP_VER_ID VF7_TPHR_CAP_DEV_SPECIFIC_MODE VF7_TPHR_CAP_ENABLE VF7_TPHR_CAP_INT_VEC_MODE VF7_TPHR_CAP_NEXTPTR VF7_TPHR_CAP_ST_MODE_SEL VF7_TPHR_CAP_ST_TABLE_LOC VF7_TPHR_CAP_ST_TABLE_SIZE VF7_TPHR_CAP_VER} }
     PLLE3_ADV { cfg_element {BANDWIDTH CLKFBOUT_MULT CLKFBOUT_PHASE CLKIN_PERIOD CLKOUT0_DIVIDE CLKOUT0_DUTY_CYCLE CLKOUT0_PHASE CLKOUT1_DIVIDE CLKOUT1_DUTY_CYCLE CLKOUT1_PHASE CLKOUTPHY_MODE COMPENSATION DIVCLK_DIVIDE REF_JITTER STARTUP_WAIT} }
     PLLE3_BASE { cfg_element {BANDWIDTH CLKFBOUT_MULT CLKFBOUT_PHASE CLKIN_PERIOD CLKOUT0_DIVIDE CLKOUT0_DUTY_CYCLE CLKOUT0_PHASE CLKOUT1_DIVIDE CLKOUT1_DUTY_CYCLE CLKOUT1_PHASE CLKOUTPHY_MODE DIVCLK_DIVIDE REF_JITTER STARTUP_WAIT} }
     PMV2_TEST { cfg_element {} }
     PULLDOWN { cfg_element {} }
     PULLUP { cfg_element {} }
     RAMB18E2 { cfg_element {CASCADE_ORDER_A CASCADE_ORDER_B CLOCK_DOMAINS DOA_REG DOB_REG ENADDRENA ENADDRENB INITP_00 INITP_01 INITP_02 INITP_03 INITP_04 INITP_05 INITP_06 INITP_07 INIT_00 INIT_01 INIT_02 INIT_03 INIT_04 INIT_05 INIT_06 INIT_07 INIT_08 INIT_09 INIT_0A INIT_0B INIT_0C INIT_0D INIT_0E INIT_0F INIT_10 INIT_11 INIT_12 INIT_13 INIT_14 INIT_15 INIT_16 INIT_17 INIT_18 INIT_19 INIT_1A INIT_1B INIT_1C INIT_1D INIT_1E INIT_1F INIT_20 INIT_21 INIT_22 INIT_23 INIT_24 INIT_25 INIT_26 INIT_27 INIT_28 INIT_29 INIT_2A INIT_2B INIT_2C INIT_2D INIT_2E INIT_2F INIT_30 INIT_31 INIT_32 INIT_33 INIT_34 INIT_35 INIT_36 INIT_37 INIT_38 INIT_39 INIT_3A INIT_3B INIT_3C INIT_3D INIT_3E INIT_3F INIT_A INIT_B RDADDRCHANGEA RDADDRCHANGEB READ_WIDTH_A READ_WIDTH_B RSTREG_PRIORITY_A RSTREG_PRIORITY_B SLEEP_ASYNC SRVAL_A SRVAL_B WRITE_MODE_A WRITE_MODE_B WRITE_WIDTH_A WRITE_WIDTH_B} }
     RAMB36E2 { cfg_element {CASCADE_ORDER_A CASCADE_ORDER_B CLOCK_DOMAINS DOA_REG DOB_REG ENADDRENA ENADDRENB EN_ECC_PIPE EN_ECC_READ EN_ECC_WRITE INITP_00 INITP_01 INITP_02 INITP_03 INITP_04 INITP_05 INITP_06 INITP_07 INITP_08 INITP_09 INITP_0A INITP_0B INITP_0C INITP_0D INITP_0E INITP_0F INIT_00 INIT_01 INIT_02 INIT_03 INIT_04 INIT_05 INIT_06 INIT_07 INIT_08 INIT_09 INIT_0A INIT_0B INIT_0C INIT_0D INIT_0E INIT_0F INIT_10 INIT_11 INIT_12 INIT_13 INIT_14 INIT_15 INIT_16 INIT_17 INIT_18 INIT_19 INIT_1A INIT_1B INIT_1C INIT_1D INIT_1E INIT_1F INIT_20 INIT_21 INIT_22 INIT_23 INIT_24 INIT_25 INIT_26 INIT_27 INIT_28 INIT_29 INIT_2A INIT_2B INIT_2C INIT_2D INIT_2E INIT_2F INIT_30 INIT_31 INIT_32 INIT_33 INIT_34 INIT_35 INIT_36 INIT_37 INIT_38 INIT_39 INIT_3A INIT_3B INIT_3C INIT_3D INIT_3E INIT_3F INIT_40 INIT_41 INIT_42 INIT_43 INIT_44 INIT_45 INIT_46 INIT_47 INIT_48 INIT_49 INIT_4A INIT_4B INIT_4C INIT_4D INIT_4E INIT_4F INIT_50 INIT_51 INIT_52 INIT_53 INIT_54 INIT_55 INIT_56 INIT_57 INIT_58 INIT_59 INIT_5A INIT_5B INIT_5C INIT_5D INIT_5E INIT_5F INIT_60 INIT_61 INIT_62 INIT_63 INIT_64 INIT_65 INIT_66 INIT_67 INIT_68 INIT_69 INIT_6A INIT_6B INIT_6C INIT_6D INIT_6E INIT_6F INIT_70 INIT_71 INIT_72 INIT_73 INIT_74 INIT_75 INIT_76 INIT_77 INIT_78 INIT_79 INIT_7A INIT_7B INIT_7C INIT_7D INIT_7E INIT_7F INIT_A INIT_B RDADDRCHANGEA RDADDRCHANGEB READ_WIDTH_A READ_WIDTH_B RSTREG_PRIORITY_A RSTREG_PRIORITY_B SLEEP_ASYNC SRVAL_A SRVAL_B WRITE_MODE_A WRITE_MODE_B WRITE_WIDTH_A WRITE_WIDTH_B} }
     RAMD32 { cfg_element INIT }
     RAMD64E { cfg_element INIT }
     RAMS32 { cfg_element INIT }
     RAMS64E { cfg_element INIT }
     RAMS64E1 { cfg_element INIT }
     RIU_OR { cfg_element {} }
     RX_BITSLICE { cfg_element {CASCADE DATA_TYPE DATA_WIDTH DELAY_FORMAT DELAY_TYPE DELAY_VALUE DELAY_VALUE_EXT FIFO_SYNC_MODE REFCLK_FREQUENCY UPDATE_MODE UPDATE_MODE_EXT} }
     RXTX_BITSLICE { cfg_element {FIFO_SYNC_MODE INIT PRE_EMPHASIS RX_DATA_TYPE RX_DATA_WIDTH RX_DELAY_FORMAT RX_DELAY_TYPE RX_DELAY_VALUE RX_REFCLK_FREQUENCY RX_UPDATE_MODE TBYTE_CTL TX_DATA_WIDTH TX_DELAY_FORMAT TX_DELAY_TYPE TX_DELAY_VALUE TX_OUTPUT_PHASE_90 TX_REFCLK_FREQUENCY TX_UPDATE_MODE} }
     SRL16E { cfg_element INIT }
     SRLC16E { cfg_element INIT }
     SRLC32E { cfg_element INIT }
     STARTUPE3 { cfg_element PROG_USR }
     SYSMONE1 { cfg_element {INIT_40 INIT_41 INIT_42 INIT_43 INIT_44 INIT_45 INIT_46 INIT_47 INIT_48 INIT_49 INIT_4A INIT_4B INIT_4C INIT_4D INIT_4E INIT_4F INIT_50 INIT_51 INIT_52 INIT_53 INIT_54 INIT_55 INIT_56 INIT_57 INIT_58 INIT_59 INIT_5A INIT_5B INIT_5C INIT_5D INIT_5E INIT_5F INIT_60 INIT_61 INIT_62 INIT_63 INIT_64 INIT_65 INIT_66 INIT_67 INIT_68 INIT_69 INIT_6A INIT_6B INIT_6C INIT_6D INIT_6E INIT_6F INIT_70 INIT_71 INIT_72 INIT_73 INIT_74 INIT_75 INIT_76 INIT_77 INIT_78 INIT_79 INIT_7A INIT_7B INIT_7C INIT_7D INIT_7E INIT_7F} }
     TX_BITSLICE { cfg_element {DATA_WIDTH DELAY_FORMAT DELAY_TYPE DELAY_VALUE INIT OUTPUT_PHASE_90 PRE_EMPHASIS REFCLK_FREQUENCY TBYTE_CTL UPDATE_MODE} }
     TX_BITSLICE_TRI { cfg_element {DATA_WIDTH DELAY_FORMAT DELAY_TYPE DELAY_VALUE INIT OUTPUT_PHASE_90 REFCLK_FREQUENCY UPDATE_MODE} }
     USR_ACCESSE2 { cfg_element {} }
  }
}

##-----------------------------------------------------------------------
## Initialization
##-----------------------------------------------------------------------
::report_timing_arcs::init

namespace eval :: {
  namespace import report_timing_arcs::*
}


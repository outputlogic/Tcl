# Proc to reload current script
proc [file tail [info script]] {} " source [info script]; puts \" [info script] reloaded\" "

# Check timing arcs in Kintex7 versus timing paths in UltraScale.

lappend auto_path /home/dpefour/git/scripts/toolbox
package require toolbox

lappend auto_path /wrk/hdstaff/dpefour/support/Olympus/assets/sqlite3.8.0.2
package require sqlite3


proc DSP48E1toDSP48E2 { fpgacondition {cell {}} } {
  set DSP {}
  if {$cell != {}} {
    set DSP [get_cells -quiet $cell]
  }
  set DSP48E1Properties [list ACASCREG ADREG ALUMODEREG AREG AUTORESET_PATDET A_INPUT BCASCREG BREG B_INPUT CARRYINREG CARRYINSELREG CREG DREG INMODEREG MASK MREG OPMODEREG PREG SEL_MASK SEL_PATTERN USE_DPORT USE_MULT USE_PATTERN_DETECT USE_SIMD PATTERN]
#   set output [list]
#   set output [concat $output [list USE_WIDEXOR FALSE ]]
  catch {unset DSPSettings}
  catch {unset DSPHardSettings}
  catch {unset DSPSoftSettings}
#   array set DSPSoftSettings [list USE_WIDEXOR FALSE ]
  array set DSPSoftSettings [list USE_WIDEXOR FALSE AREG 0 ACASCREG 0 BREG 0 BCASCREG 0 AMULTSEL A BMULTSEL B USE_PATTERN_DETECT PATDET USE_MULT DYNAMIC USE_SIMD ONE48]
  foreach prop $DSP48E1Properties {
    if {[regexp [format {(^|\.|\_)%s_(NO_PATDET|NO_RESET|RESET_MATCH|RESET_NOT_MATCH|XOR24_48_96|[^\_]+)(\_|$)} $prop] $fpgacondition - - value -]} {
      # Remove the current match from the string $fpgacondition. This is a workaround for the property 'PATTERN' so that it does not
      # match 'SEL_PATTERN' or 'USE_PATTERN_DETECT' that are processed before 'PATTERN'
      set fpgacondition [regsub "${prop}_${value}" $fpgacondition {}]
#       puts "  $prop = $value"
      switch $prop {
         DREG -
         ADREG {
           array set DSPHardSettings [list $prop $value ]
           # If either DREG or ADREG is set to '1', then it is like USE_DPORT is set to 'TRUE'.
           # Some of the 7-serie FPGA conditions refer to ADREG_1 or DREG_1 but not explicitly to
           # USE_DPORT_TRUE. The workaround is to add USE_DPORT_TRUE to the FPGA condition name.
           # Note: this works since USE_DPORT is processed after DREG/ADREG have been processed.
           if {$value == 1} {
             append fpgacondition "_USE_DPORT_TRUE"
           }
         }
         USE_DPORT {
           array set DSPSoftSettings [list USE_MULT DYNAMIC ]
           # Replaced by AMULTSEL in UltraScale
           if {[lsearch [list {FALSE} {false} 0] $value] != -1} {
#              set output [concat $output [list AMULTSEL A BMULTSEL B ]]
             array set DSPHardSettings [list AMULTSEL A BMULTSEL B ]
           } else {
#              set output [concat $output [list AMULTSEL AD BMULTSEL B PREADDINSEL A ]]
             array set DSPHardSettings [list AMULTSEL AD BMULTSEL B PREADDINSEL A ]
           }
           if {($DSP != {}) && ([get_property -quiet REF_NAME $DSP] == {DSP48E1})} {
             # When dealing with 7-serie, USE_DPORT must be kept in the list
#              set output [concat $output [list USE_DPORT $value ]]
             array set DSPHardSettings [list USE_DPORT $value ]
           }
           continue
         }
         default {
#            set output [concat $output [list $prop $value ]]
#            set DSPSetting($prop) $value
           array set DSPHardSettings [list $prop $value ]
         }
       }
    }
  }
  # Check whether ACASCREG, BCASCREG, AREG, BREG properties have been set. Set them to a
  # valid configuration if they have not been set
#   set L [list]
#   foreach {prop val} $output {}
  foreach {prop val} [array get DSPHardSettings] {
    switch $prop {
      AREG {
        array set DSPSoftSettings [list ACASCREG $val ]
#         if {[lsearch $output {ACASCREG}] == -1} {
#           set L [concat $L [list ACASCREG $val]]
#         }
      }
      BREG {
        array set DSPSoftSettings [list BCASCREG $val ]
#         if {[lsearch $output {BCASCREG}] == -1} {
#           set L [concat $L [list BCASCREG $val]]
#         }
      }
      ACASCREG {
        array set DSPSoftSettings [list AREG $val ]
#         if {[lsearch $output {AREG}] == -1} {
#           set L [concat $L [list AREG $val]]
#         }
      }
      BCASCREG {
        array set DSPSoftSettings [list BREG $val ]
#         if {[lsearch $output {BREG}] == -1} {
#           set L [concat $L [list BREG $val]]
#         }
      }
      ADREG {
        if {$val == 1} {
          array set DSPSoftSettings [list USE_MULT DYNAMIC ]
#           array set DSPSoftSettings [list USE_SIMD ONE48 ]
        } else {
#           array set DSPSoftSettings [list USE_MULT NONE ]
        }
      }
      USE_MULT {
#         if {[regexp -nocase {NONE} $val]} {
#           array set DSPSoftSettings [list ADREG 0 ]
#         }
        switch -nocase $val {
          NONE {
            array set DSPSoftSettings [list USE_SIMD FOUR12 ]
          }
          DYNAMIC {
            array set DSPSoftSettings [list USE_SIMD ONE48 ]
          }
          MULTIPLY {
            array set DSPSoftSettings [list ADREG 0 ]
            array set DSPSoftSettings [list USE_SIMD ONE48 ]
          }
          default {
          }
        }
      }
      default {
      }
    }
  }
  # Applying first the 'soft' properties
  array set DSPSettings [array get DSPSoftSettings]
  # Applying then the 'hard' properties
  array set DSPSettings [array get DSPHardSettings]
#   set output [concat $output $L]
#   # Still not set?
#   if {[lsearch $output {ACASCREG}] == -1} {
#     set output [concat $output [list AREG 0 ACASCREG 0]]
#   }
#   if {[lsearch $output {BCASCREG}] == -1} {
#     set output [concat $output [list BREG 0 BCASCREG 0]]
#   }
#   if {[lsearch $output {AMULTSEL}] == -1} {
#     set output [concat $output [list AMULTSEL A]]
#   }
#   if {[lsearch $output {BMULTSEL}] == -1} {
#     set output [concat $output [list BMULTSEL B]]
#   }
#   if {[lsearch $output {USE_PATTERN_DETECT}] == -1} {
#     set output [concat $output [list USE_PATTERN_DETECT PATDET]]
#   }
#   if {[lsearch $output {USE_MULT}] == -1} {
#     set output [concat $output [list USE_MULT DYNAMIC]]
#   }
#   if {[lsearch $output {USE_DPORT}] == -1} {
#     set output [concat $output [list AMULTSEL A BMULTSEL B]]
#   }
  # Remove UltraScale properties id target DSP is 7-serie
  if {$DSP != {}} {
    if {[get_property -quiet REF_NAME $DSP] == {DSP48E1}} {
      # If the cell is a 7-serie DSP, make sure to remove any property that does not
      # belong to 7-serie
      foreach prop [array names DSPSettings] {
        if {[lsearch $DSP48E1Properties $prop] == -1} {
          unset DSPSettings($prop)
        }
      }
#       set L [list]
#       foreach {prop val} $output {
#         if {[lsearch $DSP48E1Properties $prop] == -1} { continue }
#         lappend L $prop
#         lappend L $val
#       }
#       set output $L
    }
  }
#   return $output
  return [array get DSPSettings]
}

proc checkDSP48E1Arcs { args } {

  set SCRIPT_VERSION {01/13/2014}

  set DSP48E1Properties [list ACASCREG ADREG ALUMODEREG AREG AUTORESET_PATDET A_INPUT BCASCREG BREG B_INPUT CARRYINREG CARRYINSELREG CREG DREG INMODEREG MASK MREG OPMODEREG PREG SEL_MASK SEL_PATTERN USE_DPORT USE_MULT USE_PATTERN_DETECT USE_SIMD PATTERN]
  set DSP48E2Properties [list USE_WIDEXOR AMULTSEL BMULTSEL PREADDINSEL ACASCREG ADREG ALUMODEREG AREG AUTORESET_PATDET A_INPUT BCASCREG BREG B_INPUT CARRYINREG CARRYINSELREG CREG DREG INMODEREG MASK MREG OPMODEREG PREG SEL_MASK SEL_PATTERN USE_MULT USE_PATTERN_DETECT USE_SIMD PATTERN]
  set DSPProperties {}

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

  # SQLite3 database
  set sqliteDbK7 {}
  set sqliteDbK8 {}
  set cellpattern {DSP48E1}
  set timingsensepattern  {%}
  set timingtypepattern  {%}
  set fpgaconditionpattern  {}
  set frompinpattern {}
  set topinpattern {}
  set limit 999999999

  set reportfilename {}
  set filemode {w}
  set format {table}
  set reportFH {}

  set cell {}
  set setDSPProperties 1

  set error 0
  set show_help 0
  set VERBOSE 0
  set DEBUG 0
  if {[llength $args] == 0} {
    incr show_help
  }
  #-------------------------------------------------------
  # Process command line arguments
  #-------------------------------------------------------
  while {[llength $args]} {
    set name [::tb::lshift args]
    switch -exact -- $name {
      -cell -
      -dsp {
        set cell [::tb::lshift args]
      }
      -dbk7 -
      --dbk7 {
        set sqliteDbK7 [::tb::lshift args]
      }
      -dbk8 -
      --dbk8 {
        set sqliteDbK8 [::tb::lshift args]
      }
      -f -
      -from {
        set frompinpattern [::tb::lshift args]
      }
      -t -
      -to {
        set topinpattern [::tb::lshift args]
      }
      -tt -
      -timing_type {
        set timingtypepattern [::tb::lshift args]
      }
      -ts -
      -timing_sense {
        set timingsensepattern [::tb::lshift args]
      }
      -fc -
      -fpgacond {
        set fpgaconditionpattern [::tb::lshift args]
      }
      -l -
      -limit {
        set limit [::tb::lshift args]
      }
      -n -
      -no_property {
        set setDSPProperties 0
      }
      -file {
        # Remove the extension. The extension is added later on depending on the summary report being generated
#         set reportfilename [::tb::lshift args]
        set reportfilename [file rootname [::tb::lshift args] ]
      }
      -a -
      -append {
        set filemode {a}
      }
      -table {
        set format {table}
      }
      -csv {
        set format {csv}
      }
      -v -
      -verbose {
          set VERBOSE 1
      }
      -d -
      -debug {
          set DEBUG 1
          set VERBOSE 1
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
      Usage: checkDSP48E1Arcs
                  [-cell <DSP Cell>]
                  [-dbk7 <Kintex7 sqlite db>]
                  [-dbk8 <UltraScale sqlite db>]
                  [-f|-from <pattern>]
                  [-t|-to <pattern>]
                  [-tt|-timing_type <pattern>]
                  [-ts|-timing_sense <pattern>]
                  [-fc|-fpgacond <pattern>]
                  [-l|-limit <interger>]
                  [-n|-no_property]
                  [-file <filename>]
                  [-a|-append]
                  [-table|-csv]
                  [-verbose|-v]
                  [-help|-h]

      Description: Utility to compare Kintex7 timing arcs versus UltraScale timing path
        The wildcard character for the patterns is %%

        The -pin and -from/-to command options are exclusive.

        The -table|-csv select the output format. The default is -table that
        generates a tabular format. The -csv generates a CSV format.

        The -n|-no_property option prevent the properties of the DSP to be changed
        according to the FPGA condition.

      Version: %s

      Example:
         checkDSP48E1Arcs -dbk7 './kintex7.db' -dbk8 './kintex8.db' -from '%%NCLK%%' -tt '%%pulse%%' -fc "%%AREG%%"
         checkDSP48E1Arcs -dbk7 './kintex7.db' -dbk8 './kintex8.db' -to 'P\[%%\]' -file myreport.rpt
         checkDSP48E1Arcs -dbk7 './kintex7.db' -dbk8 './kintex8.db' -to 'P\[%%\]' -file myreport.csv -csv

    } $SCRIPT_VERSION ]
    # HELP -->

    return 0
  }

  if {$cell != {}} {
    if {[get_cells -quiet $cell] != {}} {
      set cell [get_cells -quiet $cell]
      if {[lsearch {DSP48E1 DSP48E2} [get_property -quiet REF_NAME $cell]] == -1} {
        puts " -E- Cell '$cell' does not match any DSP cell"
        incr error
      } else {
        switch [get_property -quiet REF_NAME $cell] {
          DSP48E1 {
            set DSPProperties $DSP48E1Properties
          }
          DSP48E2 {
            set DSPProperties $DSP48E2Properties
          }
        }
      }
    } else {
      puts " -E- Cell '$cell' does not match any cell"
      incr error
    }
  }

  if {$sqliteDbK7 == {}} {
    if {[file exists ./kintex7.db]} {
      set sqliteDbK7 [file normalize ./kintex7.db]
    } else {
      set sqliteDbK7 {/wrk/hdstaff/dpefour/support/Olympus/dotlib/kintex7.db}
    }
  }
  puts " -I- Using Kintex7 database '$sqliteDbK7'"

  if {$sqliteDbK8 == {}} {
    if {[file exists ./kintex8.db]} {
      set sqliteDbK8 [file normalize ./kintex8.db]
    } else {
      set sqliteDbK8 {/wrk/hdstaff/dpefour/support/Olympus/dotlib/kintex8.db}
    }
  }
  puts " -I- Using Kintex8 database '$sqliteDbK8'"

  if {$frompinpattern == {}} { set frompinpattern {%} }
  if {$topinpattern == {}} { set topinpattern {%} }
  if {$fpgaconditionpattern == {}} { set fpgaconditionpattern {%} }

  # SQLite3 database
  if {![file exists $sqliteDbK7]} {
    puts " -E- file '$sqliteDbK7' does not exist"
    incr error
  }
  if {![file exists $sqliteDbK8]} {
    puts " -E- file '$sqliteDbK8' does not exist"
    incr error
  }

  if {$error} {
    puts "\n Some error(s) occured. Cannot continue.\n"
    return -1
  }

  # Open SQLite3 database
  sqlite3 SQL $sqliteDbK7 -readonly true
  wait_db_ready SQL
  set dbVersion [SQL eval { SELECT value FROM param WHERE property='version'; } ]

  set tbl [::tb::prettyTable "Timing Arcs Summary\nDatabase: [file normalize $sqliteDbK7]"]
  if {$VERBOSE} {
    $tbl header [list {#} {Cell Name} {From} {To} {Timing Type} {Timing Sense} {FPGA Condition} {Cell ID} {From ID} {To ID} {Timing ID} {FPGA Condition ID} {Arc ID}]
  } else {
    $tbl header [list {#} {Cell Name} {From} {To} {Timing Type} {Timing Sense} {FPGA Condition}]
  }

  set cellids [SQL eval "SELECT id FROM cell WHERE (COALESCE(alias,name) LIKE '$cellpattern') OR (name LIKE '$cellpattern')"]
  if {[llength $cellids] == 0} {
    puts " error - no cell match pattern '$cellpattern'\n"
    SQL close
    return 1
  }
#   puts "<cellids:$cellids>"
#   puts "<fpgaconditionpattern:$fpgaconditionpattern>"

  set fpga_arc_condition_ids [SQL eval "SELECT id FROM fpga_condition WHERE (cellid IN ('[join $cellids ',']')) AND (name LIKE '$fpgaconditionpattern')"]
  set fpga_arc_conditions [SQL eval "SELECT DISTINCT name FROM fpga_condition WHERE id IN ('[join $fpga_arc_condition_ids ',']')"]
#   puts "<fpga_arc_condition_ids([llength $fpga_arc_condition_ids]):$fpga_arc_condition_ids>"
#   puts "<fpga_arc_conditions([llength $fpga_arc_conditions]):$fpga_arc_conditions>"

  set relatedpinid [list]
  set pinids [list]
  set arcids [list]
  set error 0

  set relatedpinid [SQL eval "SELECT id FROM pin WHERE ( (COALESCE(alias,name) LIKE '$frompinpattern')
                                                         OR (name LIKE '$frompinpattern' )
                                                         OR (belname LIKE '$frompinpattern' )
                                                       ) AND cellid IN ('[join $cellids ',']')"]
  set pinids [SQL eval "SELECT id FROM pin WHERE ( (COALESCE(alias,name) LIKE '$topinpattern')
                                                         OR (name LIKE '$topinpattern' )
                                                         OR (belname LIKE '$topinpattern' )
                                                       ) AND cellid IN ('[join $cellids ',']')"]
  if {[llength $relatedpinid] == 0} {
    puts " error - no From pin match patterns '$frompinpattern'"
    incr error
  }
  if {[llength $pinids] == 0} {
    puts " error - no To pin match patterns '$topinpattern'"
    incr error
  }
  # puts "<pinids:$pinids>"
  set arcids [SQL eval "SELECT id FROM arc WHERE (relatedpinid IN ('[join $relatedpinid ',']') ) AND (pinid IN ('[join $pinids ',']') )"]
  # puts "<arcids:$arcids>"
  if {[llength $arcids] == 0} {
    puts " error - no timing arc found for cell pattern '$cellpattern' with From pin pattern '$frompinpattern' and To pin pattern '$topinpattern'"
    incr error
  }

  if {$error} {
    puts ""
    SQL close
    return 1
  }

  catch {unset DSP48E1TimingArcs}
  set num 1
  set fpgacondcmd {}
  if {$fpgaconditionpattern != {}} {
    set fpgacondcmd "
            AND (arc.fpga_arc_condition_id IS NOT NULL
                 AND
                 (SELECT name FROM fpga_condition WHERE fpga_condition.id=arc.fpga_arc_condition_id) LIKE '$fpgaconditionpattern'
                )
    "
  }
  set CMD "SELECT arc.id AS arcID,
             (SELECT name FROM cell WHERE cell.id=arc.cellid) AS cellName,
             arc.cellid AS cellID,
             (SELECT name FROM pin WHERE pin.id=arc.pinid) AS pinName,
             arc.pinid AS pinID,
             (SELECT name FROM pin WHERE pin.id=arc.relatedpinid) AS relatedpinName,
             arc.relatedpinid AS relatedpinID,
             (SELECT timing_type FROM timing WHERE timing.id=arc.timingid) AS timing_type,
             (SELECT timing_sense FROM timing WHERE timing.id=arc.timingid) AS timing_sense,
             arc.timingid AS timingID,
             (SELECT name FROM fpga_condition WHERE fpga_condition.id=timing.fpga_arc_condition_id) AS fpga_condition,
             timing.fpga_arc_condition_id AS fpga_conditionID
      FROM arc
           JOIN pin pinTo ON pinTo.id=arc.pinid
           JOIN pin pinFrom ON pinFrom.id=arc.relatedpinid
           JOIN timing ON timing.id=arc.timingid
      WHERE arc.id IN ('[join $arcids ',']')
            AND timing.timing_type LIKE '$timingtypepattern'
            AND timing.timing_sense LIKE '$timingsensepattern'
            ${fpgacondcmd}
      ORDER BY cellName ASC,
               relatedpinName ASC,
               pinName ASC,
               timing_type ASC,
               timing_sense ASC
      LIMIT ${limit}
      ;
     "
  SQL eval $CMD values {
    # Save the current timing arc inside the DSP48E1TimingArcs list
    if {![info exists DSP48E1TimingArcs($values(fpga_condition))]} { set DSP48E1TimingArcs($values(fpga_condition)) [list] }
    lappend DSP48E1TimingArcs($values(fpga_condition)) [list $num $values(cellName) $values(relatedpinName) $values(pinName) $values(timing_type) $values(timing_sense) $values(fpga_condition)]
    foreach elm {cellID relatedpinID pinID timingID fpga_conditionID arcID} { if {![info exists values($elm)]} { set values($elm) {} } }
    if {$VERBOSE} {
      $tbl addrow [list $num $values(cellName) $values(relatedpinName) $values(pinName) $values(timing_type) $values(timing_sense) $values(fpga_condition) $values(cellID) $values(relatedpinID) $values(pinID) $values(timingID) $values(fpga_conditionID) $values(arcID) ]
    } else {
      $tbl addrow [list $num $values(cellName) $values(relatedpinName) $values(pinName) $values(timing_type) $values(timing_sense) $values(fpga_condition) ]
    }
    incr num
  }

  if {1} {
    # SQL does sort well bus names (e.g a[0] a[10] .. a[19] a[1] ...)
    $tbl sort -dictionary +1 +2 +3 +4 +5 +6
    # Because the table is sorted post-SQL, hide the first column since it does
    # not make sense anymore
    $tbl config -display_columns {1 2 3 4 5 6 7 8 9 10 11 12} -indent 2
    set pininfo "From Pin pattern: $frompinpattern\nTo Pin pattern: $topinpattern"
    $tbl config -title "Timing Arcs Summary\nDatabase: [file normalize $sqliteDbK7]\nDatabase version: $dbVersion\nDatabase table: arc\nCell pattern: $cellpattern\n$pininfo\nTiming type pattern: $timingtypepattern\nTiming sense pattern: $timingsensepattern\nFound arc(s): [$tbl numrows]"
  }

  if {$reportfilename == {}} {
    switch $format {
      table {
        puts [$tbl print]
      }
      csv {
        puts [$tbl export -format csv]
      }
      default {
      }
    }
  } else {
    switch $format {
      table {
        set reportFH [open ${reportfilename}.DSP48E1Arcs.rpt $filemode]
        puts $reportFH [$tbl print]
      }
      csv {
        set reportFH [open ${reportfilename}.DSP48E1Arcs.csv $filemode]
        puts $reportFH [$tbl export -format csv]
      }
      default {
      }
    }
    close $reportFH
    puts " File [file normalize $reportfilename] generated"
  }

  puts "  Found [$tbl numrows] arc(s)"

  catch {$tbl destroy}

  # Closing the SQLite3 database
  SQL close

  #-------------------------------------------------------
  # Check all the DSP48E1 timing arcs against the DSP48E2
  # timing paths
  #-------------------------------------------------------

  if {$cell != {}} {
    set arcsSummaryTable [::tb::prettyTable "Summary Table of Non-Matching Arcs"]
    $arcsSummaryTable header [list {#} {Cell name} {From} {To} {Timing Type} {Timing Sense} {FPGA Condition} {Note} {Properties} {All Properties}]
    set fpgacondSummaryTable [::tb::prettyTable "Summary Table of FPGA Conditions"]
    $fpgacondSummaryTable header [list {Cell name} {FPGA Condition} {# Arcs} {% Passed} {% Failed} {# Mismatch} {# No Path} {# Skipped} {Properties} {All Properties}]
    set count 0
    set numarcs 0
    set totalnumarcs 0
    set mismatch 0
    set totalmismatch 0
    set nopathfound 0
    set totalnopathfound 0
    set skippedpath 0
    set totalskippedpath 0
    foreach fpga_condition [lsort -dictionary [array names DSP48E1TimingArcs]] {
      incr count
#       puts "<fpga_condition:$fpga_condition><DSP48E1toDSP48E2:[DSP48E1toDSP48E2 $fpga_condition $cell]>"
      puts "  FPGA Condition ($count/[llength [array names DSP48E1TimingArcs]]): $fpga_condition"
      set K8Properties [DSP48E1toDSP48E2 $fpga_condition $cell]
      if {$setDSPProperties} {
        puts " -I- Properties: $K8Properties"
        foreach {property value} $K8Properties {
          if {$VERBOSE} { puts "    Setting property for $cell: $property = $value" }
  #         set_property $property $value $cell
        }
        if {$DEBUG} {
          puts " -I- set_property -quiet -dict {$K8Properties} \[get_cells $cell\]"
        }
        set_property -quiet -dict $K8Properties $cell
      } else {
        puts " -I- Properties (NOT SET): $K8Properties"
      }
      set K8AllProperties [list]
      foreach prop $DSPProperties {
        set K8AllProperties [concat $K8AllProperties [list $prop [get_property -quiet $prop $cell] ] ]
        if {$DEBUG} {
          puts " -I- Property $prop = [get_property -quiet $prop $cell]"
        }
      }
      puts " -I- All DSP Properties: $K8AllProperties"
      set numarcs 0
      set mismatch 0
      set nopathfound 0
      set skippedpath 0
      foreach timingArc $DSP48E1TimingArcs($fpga_condition) {
        incr numarcs
        incr totalnumarcs
        set timingArcType {}
        foreach {num cellName relatedpinName pinName timing_type timing_sense fpga_condition} $timingArc { break }
        puts "    Checking arc \[$numarcs/[llength $DSP48E1TimingArcs($fpga_condition)]\]\t$cellName\t$relatedpinName\t->\t$pinName\t($timing_type, $timing_sense)\t($fpga_condition) "
#         set commandLine [list -nworst 1 -max_paths 10]
#         set commandLine [list -nworst 1 -max_paths 1]
        set commandLine [list -nworst 1 -max_paths 1000]
        set commandLineTxt "-nworst 1 -max_paths 1000"
        switch -regexp $timing_type {
          {^(setup|recovery)_rising} {
#             set commandLine [concat $commandLine [list -delay_type max -rise_from $relatedpinName -through $pinName] ]
            set commandLine [concat $commandLine [list -delay_type max -rise_from [get_ports $pinName] -to [get_clocks -of [get_ports $relatedpinName]] ] ]
            append commandLineTxt [format { -delay_type max -rise_from [get_ports %s] -to [get_clocks -of [get_ports %s]] } "$pinName" "$relatedpinName"]
            set timingArcType [regsub {_rising} $timing_type {}]
          }
          {^(setup|recovery)_falling} {
#             set commandLine [concat $commandLine [list -delay_type max -fall_from $relatedpinName -through $pinName] ]
            set commandLine [concat $commandLine [list -delay_type max -fall_from [get_ports $pinName] -to [get_clocks -of [get_ports $relatedpinName]] ] ]
            append commandLineTxt [format { -delay_type max -fall_from [get_ports %s] -to [get_clocks -of [get_ports %s]] } "$pinName" "$relatedpinName"]
            set timingArcType [regsub {_falling} $timing_type {}]
          }
          {^(hold|removal)_rising} {
#             set commandLine [concat $commandLine [list -delay_type min -rise_from $relatedpinName -through $pinName] ]
            set commandLine [concat $commandLine [list -delay_type min -rise_from [get_ports $pinName] -to [get_clocks -of [get_ports $relatedpinName]] ] ]
            append commandLineTxt [format { -delay_type min -rise_from [get_ports %s] -to [get_clocks -of [get_ports %s]] } "$pinName" "$relatedpinName"]
            set timingArcType [regsub {_rising} $timing_type {}]
          }
          {^(hold|removal)_falling} {
#             set commandLine [concat $commandLine [list -delay_type min -fall_from $relatedpinName -through $pinName] ]
            set commandLine [concat $commandLine [list -delay_type min -fall_from [get_ports $pinName] -to [get_clocks -of [get_ports $relatedpinName]] ] ]
            append commandLineTxt [format { -delay_type min -fall_from [get_ports %s] -to [get_clocks -of [get_ports %s]] } "$pinName" "$relatedpinName"]
            set timingArcType [regsub {_falling} $timing_type {}]
          }
          {^rising_edge} {
#             set commandLine [concat $commandLine [list -delay_type max -rise_from $relatedpinName -to $pinName] ]
            set commandLine [concat $commandLine [list -delay_type max -rise_from [get_pins $cell/$relatedpinName] -to [get_ports $pinName] ] ]
            append commandLineTxt [format { -delay_type max -rise_from [get_pins %s] -to [get_ports %s]} "$cell/$relatedpinName" "$pinName"]
            set timingArcType {Clk to Q}
          }
          {^falling_edge} {
#             set commandLine [concat $commandLine [list -delay_type max -fall_from $relatedpinName -to $pinName] ]
            set commandLine [concat $commandLine [list -delay_type max -fall_from [get_pins $cell/$relatedpinName] -to [get_ports $pinName] ] ]
            append commandLineTxt [format { -delay_type max -fall_from [get_pins $cell/$relatedpinName] -to [get_ports %s]} "$cell/$relatedpinName" "$pinName"]
            set timingArcType {Clk to Q}
          }
          {^combinational} {
#             set commandLine [concat $commandLine [list -delay_type max -through $relatedpinName -through $pinName] ]
            set commandLine [concat $commandLine [list -delay_type max -from [get_ports $relatedpinName] -to [get_ports $pinName] ] ]
            append commandLineTxt [format { -delay_type max -from [get_ports %s] -to [get_ports %s]} "$relatedpinName" "$pinName"]
            set timingArcType {combinational}
          }
          {^minimum_period} {
            # This timing type cannot be checked with report_timing. Just skip it
            continue
          }
          default {
            puts " -W- Skipping timing arc (unexpected timing type '$timing_type')"
#             $arcsSummaryTable addrow [list [expr $totalskippedpath + $totalnopathfound + $totalmismatch] [get_property -quiet REF_NAME $cell] $relatedpinName $pinName $timing_type $timing_sense $fpga_condition "unexpected timing type ($timing_type)" $K8Properties $K8AllProperties]
            $arcsSummaryTable addrow [list [$arcsSummaryTable numrows] [get_property -quiet REF_NAME $cell] $relatedpinName $pinName $timing_type $timing_sense $fpga_condition "unexpected timing type ($timing_type)" $K8Properties $K8AllProperties]
            incr skippedpath
            incr totalskippedpath
            continue
          }
        }
        set_msg_config -id {Vivado 12-2286} -suppress
        set_msg_config -id {Vivado 12-975} -suppress
        eval "set paths \[get_timing_paths $commandLine\]"
        reset_msg_config -id {Vivado 12-2286} -suppress
        reset_msg_config -id {Vivado 12-975} -suppress
        switch [llength $paths] {
          0 {
            if {$VERBOSE} {
#               puts "         commandLine: $commandLine"
              puts "         commandLine: $commandLineTxt"
            }
            puts " -W- No path found"
#             $arcsSummaryTable addrow [list [expr $totalskippedpath + $totalnopathfound + $totalmismatch] [get_property -quiet REF_NAME $cell] $relatedpinName $pinName $timing_type $timing_sense $fpga_condition {no path found} $K8Properties $K8AllProperties]
            $arcsSummaryTable addrow [list [$arcsSummaryTable numrows] [get_property -quiet REF_NAME $cell] $relatedpinName $pinName $timing_type $timing_sense $fpga_condition {no path found} $K8Properties $K8AllProperties]
            incr nopathfound
            incr totalnopathfound
            continue
          }
          1 {
          }
          default {
            if {$VERBOSE} { puts " -W- Multiple paths found: [llength $paths]" }
            if {$DEBUG} {
#               puts "     commandLine: $commandLine"
              puts "     commandLine: $commandLineTxt"
              set numpath 0
              foreach path $paths {
                incr numpath
                puts "     Path ($numpath/[llength $paths]): $path (slack: [get_property -quiet SLACK $path])"
              }
            }
          }
        }
        set foundMatchingPath 0
        set numpath 0
        foreach path $paths {
          incr numpath
          set pathType {}
          if {$VERBOSE} {
            puts "      => Path ($numpath/[llength $paths]): $path"
#             puts "         commandLine: $commandLine"
            puts "         commandLine: $commandLineTxt"
            set nets [get_nets -quiet -of $path]
            set pins [get_pins -quiet -of $path]
            puts "         Pins: $pins"
            puts "         Nets: $nets"
            if {$DEBUG} {
              foreach line [split [report_property $path -return_string] \n] {
                puts "         $line"
              }
              foreach line [split [report_timing -of $path -return_string] \n] {
                puts "         $line"
              }
            }
#             report_timing -of $path -name "$numarcs"
          }
          switch [get_property -quiet INPUT_DELAY $path]|[get_property -quiet OUTPUT_DELAY $path] {
            0.000|0.000 {
              set pathType {combinational}
            }
            |0.000 {
              set pathType {Clk to Q}
            }
            0.000| {
              if {[get_property -quiet DELAY_TYPE $path] == {max}} {
                set pathType {setup}
              } else {
                set pathType {hold}
              }
            }
            default {
            }
          }
          set slack [get_property -quiet SLACK $path]
          if {$slack == {inf}} {
            puts " -W- slack: $slack"
          }
          if {$VERBOSE} {
            puts "         Timing arc: $timingArcType"
            puts "         Timing path: $pathType (slack: $slack)"
          }
          if {$pathType == $timingArcType} {
            incr foundMatchingPath
            if {$VERBOSE} { puts " -I- Path ($numpath/[llength $paths]) and timing arc match" }
            break

          } else {
#             incr mismatch
#             incr totalmismatch
            if {$VERBOSE} { puts " -W- Path ($numpath/[llength $paths]) and timing arc mismatch" }
          }
        }
        if {!$foundMatchingPath} {
          puts " -W- Timing path and timing arc mismatch"
#           $arcsSummaryTable addrow [list [expr $totalskippedpath + $totalnopathfound + $totalmismatch] [get_property -quiet REF_NAME $cell] $relatedpinName $pinName $timing_type $timing_sense $fpga_condition {mismatch} $K8Properties $K8AllProperties]
          $arcsSummaryTable addrow [list [$arcsSummaryTable numrows] [get_property -quiet REF_NAME $cell] $relatedpinName $pinName $timing_type $timing_sense $fpga_condition {mismatch} $K8Properties $K8AllProperties]
          incr mismatch
          incr totalmismatch
        } else {
          if {$VERBOSE} {
#             $arcsSummaryTable addrow [list [expr $totalskippedpath + $totalnopathfound + $totalmismatch] [get_property -quiet REF_NAME $cell] $relatedpinName $pinName $timing_type $timing_sense $fpga_condition {OK} $K8Properties $K8AllProperties]
            $arcsSummaryTable addrow [list [$arcsSummaryTable numrows] [get_property -quiet REF_NAME $cell] $relatedpinName $pinName $timing_type $timing_sense $fpga_condition {OK} $K8Properties $K8AllProperties]
          }
        }
      }
#       if {$numarcs >=3} { break }
      if {$nopathfound} {
        puts " -W- Number of no path found for this FPGA condition: $nopathfound"
      } else {
        if {$VERBOSE} { puts " -I- Number of no path found for this FPGA condition: $nopathfound" }
      }
      if {$mismatch} {
        puts " -W- Number of mismatch for this FPGA condition: $mismatch"
      } else {
        if {$VERBOSE} { puts " -I- Number of mismatch for this FPGA condition: $mismatch" }
      }
      if {$skippedpath} {
        puts " -W- Number of skipped paths for this FPGA condition: $skippedpath"
      } else {
        if {$VERBOSE} { puts " -I- Number of skipped paths for this FPGA condition: $skippedpath" }
      }

      set numfailed [expr $nopathfound + $mismatch + $skippedpath]
      set numpassed [expr [llength $DSP48E1TimingArcs($fpga_condition)] - $numfailed]
      set percentfailed [format {%.2f} [expr 100.0 * double($numfailed) / double([llength $DSP48E1TimingArcs($fpga_condition)])]]
      set percentpassed [format {%.2f} [expr 100.0 - $percentfailed] ]
      $fpgacondSummaryTable addrow [list [get_property -quiet REF_NAME $cell] \
                                         $fpga_condition \
                                         [llength $DSP48E1TimingArcs($fpga_condition)] \
                                         $percentpassed \
                                         $percentfailed \
                                         $mismatch \
                                         $nopathfound \
                                         $skippedpath \
                                         $K8Properties \
                                         $K8AllProperties]

    }

    puts " -I- Number of skipped paths: $totalskippedpath"
    puts " -I- Number of no path found: $totalnopathfound"
    puts " -I- Number of mismatch: $totalmismatch"
    puts " -I- Total number of arcs processed: $totalnumarcs"

    # Re-order the table (by FPGA Condition first, then From pin, then To pin then timing type)
    $arcsSummaryTable sort -dictionary +6 +2 +3 +4

    if {$reportfilename == {}} {
      switch $format {
        table {
          puts [$arcsSummaryTable print]
          puts [$fpgacondSummaryTable print]
        }
        csv {
          puts [$arcsSummaryTable export -format csv]
          puts [$fpgacondSummaryTable export -format csv]
        }
        default {
        }
      }
    } else {
      switch $format {
        table {
          set reportFH [open ${reportfilename}.arcs.rpt $filemode]
          puts $reportFH [$arcsSummaryTable print]
          close $reportFH
          set reportFH [open ${reportfilename}.fpgacond.rpt $filemode]
          puts $reportFH [$fpgacondSummaryTable print]
          close $reportFH
          puts " File [file normalize ${reportfilename}.arcs.rpt] generated"
          puts " File [file normalize ${reportfilename}.fpgacond.rpt] generated"
       }
        csv {
          set reportFH [open ${reportfilename}.arcs.csv $filemode]
          puts $reportFH [$arcsSummaryTable export -format csv]
          close $reportFH
          set reportFH [open ${reportfilename}.fpgacond.csv $filemode]
          puts $reportFH [$fpgacondSummaryTable export -format csv]
          close $reportFH
          puts " File [file normalize ${reportfilename}.arcs.csv] generated"
          puts " File [file normalize ${reportfilename}.fpgacond.csv] generated"
        }
        default {
        }
      }
    }

#     puts "  [$arcsSummaryTable numrows] arc(s) are not found"
    puts "  [expr $totalskippedpath + $totalnopathfound + $totalmismatch] arc(s) are not found"

    catch {$arcsSummaryTable destroy}
    catch {$fpgacondSummaryTable destroy}

  }

  return 0
}

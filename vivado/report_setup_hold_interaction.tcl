
# Proc to reload current script
proc [file tail [info script]] {} " source [info script]; puts \" [info script] reloaded\" "


# Dependencies: Those scripts are from the Tcl App Store
# source -notrace /wrk/hdstaff/dpefour/support/TclApps/XilinxTclStore/tclapp/xilinx/designutils/insert_buffer.tcl
# source -notrace /wrk/hdstaff/dpefour/support/TclApps/XilinxTclStore/tclapp/xilinx/designutils/prettyTable.tcl
source -notrace ./insert_buffer.tcl
source -notrace ./prettyTable.tcl

# Some debug messages from insert_buffer commands
# set ::tclapp::xilinx::designutils::insert_buffer::debug 2

proc report_setup_hold_interaction { {spaths {}} {nbrHold 1} {insert 0} } {

  if {$spaths == {}} {
    puts [format {
      report_setup_hold_interaction <list_of_setup_paths> <nbr_hold_paths_per_setup_path> <flag>

      <list_of_setup_paths>
          Tcl list of get_timing_paths setup paths.

      <nbr_hold_paths_per_setup_path>
          Number of hold paths to explore for each setup path. This allows to do paths
          explorations. The hold paths are constrained by the startpoint of the setup
          paths.
          Default: 1

      If <flag>=1 then LUT1 will be inserted
      If <flag>=0 then no LUT1 is inserted. Only report is generated

      => results append to file report_setup_hold_interaction.rpt

      Example:
      set spaths [get_timing_paths -setup -max_paths 1000 -nworst 1 -slack_lesser_than 0]
      report_setup_hold_interaction $spaths
      report_setup_hold_interaction $spaths 10
      report_setup_hold_interaction $spaths 5 1

}]
    return
  }

  set table [::tclapp::xilinx::designutils::prettyTable create {Setup/Hold Interaction on FD*-LUT-FD* Paths}]
#   $table header [list {Index} {Setup Path} {Setup Slack} {Hold Path} {Hold Slack} {Comment}]
  $table header [list {Index} {Status} {Setup Slack} {Hold Slack} {Path Startpoint} {Setup Endpoint} {Hold Endpoint} {Comment}]


  if {$spaths == {}} {
    set spaths [get_timing_paths -setup -max_paths 2 -nworst 1 -slack_lesser_than 0]
  }

  # List of pins (hold path endpoints) that should have a LUT1 inserted
  set targetPins [list]

  set num -1
  foreach spath $spaths {
    incr num
    # Looking for FD-LUT-FD pattern
    set startpoint [get_property STARTPOINT_PIN $spath]
    set endpoint [get_property ENDPOINT_PIN $spath]
    set startCell [get_cells -of $startpoint]
    set startRefName [get_property REF_NAME $startCell]
    set setup_slack [get_property SLACK $spath]
    if {![regexp {^FD.+} $startRefName]} {
      $table addrow [list $num {Skipped} $setup_slack {} $startpoint $endpoint {} "startpoint REF_NAME=$startRefName"]
      continue
    }
    # Check multiple hold paths for each setup path
    set hpaths [get_timing_paths -max_paths $nbrHold -nworst 1 -hold -from $startpoint]
    if {[llength $hpaths] > 1} {
      $table separator
    }
#     set hpath [get_timing_paths -max_paths 1 -nworst 1 -hold -from $startpoint]
    foreach hpath $hpaths {
      set holdEndPin [get_property ENDPOINT_PIN $hpath]
      set hold_slack [get_property SLACK $hpath]
      set hold_logic_levels [get_property LOGIC_LEVELS $hpath]
      if {$hold_logic_levels != 1} {
        # Looking for FD-LUT-FD paths only (more filtering is done later)
        $table addrow [list $num {Skipped} $setup_slack $hold_slack $startpoint $endpoint $holdEndPin "Hold LOGIC_LEVELS=$hold_logic_levels"]
        continue
      }
      set holdEndCell [get_cells -of $holdEndPin]
      set holdEndRefName [get_property REF_NAME $holdEndCell]
      if {![regexp {^FD.+} $holdEndRefName]} {
        $table addrow [list $num {Skipped} $setup_slack $hold_slack $startpoint $endpoint $holdEndPin "endpoint is not a FD"]
        continue
      }
      # Checking that the hold path nets are also part of the setup path (complete overlap)
      set hnets [get_nets -of $hpath]
      set snets [get_nets -of $spath]
      if {![lequal [lintersect $hnets $snets] $hnets]} {
        $table addrow [list $num {Skipped} $setup_slack $hold_slack $startpoint $endpoint $holdEndPin "Hold path nets not included in setup path nets (Hold: [lsort -dictionary $hnets])(Setup: [lsort -dictionary $snets])"]
        continue
      }
      set lut [get_cells -of $hpath -filter {REF_NAME =~ LUT*} -quiet]
      if {$lut == {}} {
        # Looking for FD-LUT-FD paths only (second filter)
        $table addrow [list $num {Skipped} $setup_slack $hold_slack $startpoint $endpoint $holdEndPin "comb cell is not a LUT1-6"]
        continue
      }
      # Checking that the last net between LUT-FD is within the slice => 0.000ns
      set epoint [get_property ENDPOINT_PIN $hpath]
      set hTA [get_timing_arcs -from [get_pins -filter {DIRECTION == OUT} -of $lut] -to $epoint]
      if {[get_property DELAY_MIN_RISE $hTA] != 0.000} {
        $table addrow [list $num {Skipped} $setup_slack $hold_slack $startpoint $endpoint $holdEndPin "Hold path last net delay is not 0.000ns (LUT->FD not packed on paired sites)"]
        continue
      }
#       # We might want to skip paths that have a positive hold slack
#       if {$hold_slack >=0} {
#         $table addrow [list $num {Skipped} $setup_slack $hold_slack $startpoint $endpoint $holdEndPin "positive hold slack"]
#         continue
#       }
#       set fd [get_cells -of [get_property ENDPOINT_PIN $hpath]]
#       if {![regexp {^FD[RSEC]*$} [get_property REF_NAME $fd]]} {
#           #Useless check because of the previous one...
#           #puts "... skipping: endpoint is not a FD (1 logic level path)"
#           continue
#       }
      #Saving net and enpoint on which to insert the LUT to help with hold fixing
      #and prevent LUT-FD aligned placement within the SLICE => gives flexibility to the router to take detours
      $table addrow [list $num {Candidate} $setup_slack $hold_slack $startpoint $endpoint $holdEndPin "LUT1 insertion ($holdEndPin)"]
      lappend targetPins $holdEndPin
    }
    if {[llength $hpaths] > 1} {
      $table separator
    }
  }

  puts [$table print]
  puts " Generating report file report_setup_hold_interaction.rpt"
  $table export -file report_setup_hold_interaction.rpt -append

  if {$targetPins != {}} {
    set FH [open report_setup_hold_interaction.rpt {a}]
    # Make sure to uniquify the list
    set targetPins [lsort -dictionary -unique $targetPins]
    puts " [llength $targetPins] pins are candidate for LUT1 insertion"
    puts $FH " [llength $targetPins] pins are candidate for LUT1 insertion"
    foreach pin $targetPins {
      puts "   $pin"
      puts $FH "   $pin"
    }
    # Insert LUT1 to all candidate pins. The cells of the target pins should be unplaced too
    # since the placer will need to place those FD in a different slice ... the whole purpose
    # of all this
    if {$insert} {
      puts " Inserting LUT1 before all candidate pins"
      puts $FH " Inserting LUT1 before all candidate pins"
      unplace_cell [get_cells -quiet -of $targetPins]
      ::tclapp::xilinx::designutils::insert_buffer::insert_buffer $targetPins LUT1
    }
    close $FH
  }

  catch {$table destroy}
  return 0
}

# Intersection between 2 lists
proc lintersect {a b} {
 foreach e $a {
   set x($e) {}
 }
 set result {}
 foreach e $b {
   if {[info exists x($e)]} {
     lappend result $e
   }
 }
 return $result
}

proc K {a b} {return $a}

proc lequal {l1 l2} {
    if {[llength $l1] != [llength $l2]} {
        return false
    }

    set l2 [lsort $l2]

    foreach elem $l1 {
        set idx [lsearch -exact -sorted $l2 $elem]
        if {$idx == -1} {
            return false
        } else {
            set l2 [lreplace [K $l2 [unset l2]] $idx $idx]
        }
    }

    return [expr {[llength $l2] == 0}]
}


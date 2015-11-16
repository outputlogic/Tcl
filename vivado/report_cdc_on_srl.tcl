
# Vivado script to report missing ASYNC_REG property on SRL* of CDC paths. Only the first SRL* of the
# capture clock domain is being checked for the ASYNC_REG property.

# Abstract of generated report:
# =============================
#
#  Processing CDC [3/81]: microblaze_1/microblaze_mcs_0_1/U0/Debug.debug_mdm_0/Use_E2.BSCANE2_I/UPDATE -> microblaze_1/microblaze_mcs_0_1/U0/Debug.debug_mdm_0/Use_E2.BSCANE2_I/DRCK
#    # paths: 79
#    refnames : FDCE FDRE SRL16E SRLC16E
#    Missing ASYNC_REG on microblaze_1/microblaze_mcs_0_1/U0/microblaze_I/MicroBlaze_Core_I/Area.Implement_Debug_Logic.Master_Core.Debug_Area/Using_PC_Breakpoints.All_PC_Brks[0].address_hit_I/Using_FPGA.Compare[4].SRLC16E_I/Use_unisim.MB_SRL16CE_I1
#    Missing ASYNC_REG on microblaze_1/microblaze_mcs_0_1/U0/microblaze_I/MicroBlaze_Core_I/Area.Implement_Debug_Logic.Master_Core.Debug_Area/Using_PC_Breakpoints.All_PC_Brks[0].address_hit_I/Using_FPGA.Compare[0].SRLC16E_I/Use_unisim.MB_SRL16CE_I1
#    Missing ASYNC_REG on microblaze_1/microblaze_mcs_0_1/U0/microblaze_I/MicroBlaze_Core_I/Area.Implement_Debug_Logic.Master_Core.Debug_Area/Using_PC_Breakpoints.All_PC_Brks[0].address_hit_I/Using_FPGA.Compare[1].SRLC16E_I/Use_unisim.MB_SRL16CE_I1
#    Missing ASYNC_REG on microblaze_1/microblaze_mcs_0_1/U0/microblaze_I/MicroBlaze_Core_I/Area.Implement_Debug_Logic.Master_Core.Debug_Area/Using_PC_Breakpoints.All_PC_Brks[0].address_hit_I/Using_FPGA.Compare[2].SRLC16E_I/Use_unisim.MB_SRL16CE_I1
#    Missing ASYNC_REG on microblaze_1/microblaze_mcs_0_1/U0/microblaze_I/MicroBlaze_Core_I/Area.Implement_Debug_Logic.Master_Core.Debug_Area/Using_PC_Breakpoints.All_PC_Brks[0].address_hit_I/Using_FPGA.Compare[3].SRLC16E_I/Use_unisim.MB_SRL16CE_I1
#    Missing ASYNC_REG on microblaze_1/microblaze_mcs_0_1/U0/microblaze_I/MicroBlaze_Core_I/Area.Implement_Debug_Logic.Master_Core.Debug_Area/Using_PC_Breakpoints.All_PC_Brks[0].address_hit_I/Using_FPGA.Compare[7].SRLC16E_I/Use_unisim.MB_SRL16CE_I1
#    Missing ASYNC_REG on microblaze_1/microblaze_mcs_0_1/U0/microblaze_I/MicroBlaze_Core_I/Area.Implement_Debug_Logic.Master_Core.Debug_Area/Using_PC_Breakpoints.All_PC_Brks[0].address_hit_I/Using_FPGA.Compare[5].SRLC16E_I/Use_unisim.MB_SRL16CE_I1
#    Missing ASYNC_REG on microblaze_1/microblaze_mcs_0_1/U0/microblaze_I/MicroBlaze_Core_I/Area.Implement_Debug_Logic.Master_Core.Debug_Area/Using_PC_Breakpoints.All_PC_Brks[0].address_hit_I/Using_FPGA.Compare[6].SRLC16E_I/Use_unisim.MB_SRL16CE_I1

# TODO: Paths that are safely timed could be filtered out. This can be easily done sinde the report_clock_interaction report
# has a column providing this information.

proc extract_columns { str match } {
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

proc extract_row {str columns} {
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

proc parse_report_clock_interaction {report} {
  set columns [list]
  set table [list]
  set report [split $report \n]
  set SM {header}
  for {set index 0} {$index < [llength $report]} {incr index} {
    set line [lindex $report $index]
    switch $SM {
      header {
        if {[regexp {^\-+\s+\-+\s+\-+} $line]} {
          set columns [extract_columns [string trimright $line] { }]
          set header1 [extract_row [lindex $report [expr $index -2]] $columns]
          set header2 [extract_row [lindex $report [expr $index -1]] $columns]
          set row [list]
          foreach h1 $header1 h2 $header2 {
            lappend row [string trim [format {%s %s} [string trim [format {%s} $h1]] [string trim [format {%s} $h2]]] ]
          }
          lappend table $row
          set SM {table}
        }
      }
      table {
        # Check for empty line or for line that match '<empty>'
        if {(![regexp {^\s*$} $line]) && (![regexp -nocase {^\s*No clocks found.\s*$} $line])} {
          set row [extract_row $line $columns]
          lappend table $row
        }
      }
      end {
      }
    }
  }
  return $table
}

####################################################
##
## Parsing the report_clock_interaction report to
## extract the list of clock pairs
##
####################################################

# Get the report_clock_interaction report
set clock_interaction_report [report_clock_interaction -quiet -setup -return_string]

# Convert the text report into a Tcl list
set clock_interaction_table [parse_report_clock_interaction $clock_interaction_report]

set colFromClock 0
set colToClock 0
set colCommonPrimaryClock 0
set colInterClockConstraints 0
set colTNSFailingEndpoints 0
set colTNSTotalEndpoints 0
if {$clock_interaction_table != {}} {
  set header [lindex $clock_interaction_table 0]
  for {set i 0} {$i < [llength $header]} {incr i} {
    switch -nocase [lindex $header $i] {
      "From Clock" {
        set colFromClock $i
      }
      "To Clock" {
        set colToClock $i
      }
      "Common Primary Clock" {
        set colCommonPrimaryClock $i
      }
      "Inter-Clock Constraints" {
        set colInterClockConstraints $i
      }
      "TNS Failing Endpoints" {
        set colTNSFailingEndpoints $i
      }
      "TNS Total Endpoints" {
        set colTNSTotalEndpoints $i
      }
      default {
      }
    }
  }
}

####################################################
##
## Iterate through all the clock pairs from the
## report_clock_interaction.
##
## For each clock pair, extract all the timing paths
## and check for those ending on SLR* cells
##
####################################################

set count 0
set stop 0
foreach row [lrange $clock_interaction_table 1 end] {
  incr count
  set fromClock [get_clocks [lindex $row $colFromClock]]
  set toClock [get_clocks [lindex $row $colToClock]]
  set failingEndpoints [lindex $row $colTNSFailingEndpoints]
  set totalEndpoints [lindex $row $colTNSTotalEndpoints]
  set commonPrimaryClock [lindex $row $colCommonPrimaryClock]
  set interClockConstraints [lindex $row $colInterClockConstraints]
  set clockInteraction(${fromClock}:${toClock}) $interClockConstraints
  if {$fromClock == $toClock} {
    # Let's skip intra-clock domains
    puts "\n Skipping intra-clock domain $fromClock \[$count/[expr [llength $clock_interaction_table] -1]\]"
    continue
  }
  puts "\n Processing CDC \[$count/[expr [llength $clock_interaction_table] -1]\]: $fromClock -> $toClock"
  # Get all the CDC paths between the two clock domains
  set timingPaths [get_timing_paths -quiet -from $fromClock -to $toClock -unique_pins -nworst 1 -setup -max_paths 100000 ]
  # Iterate through all the timing paths
  puts "   # paths: [llength $timingPaths]"
  puts "   refnames : [lsort -unique [get_property REF_NAME [get_property ENDPOINT_PIN $timingPaths]]]"
  foreach path $timingPaths endpoint [get_property ENDPOINT_PIN $timingPaths] refname [get_property REF_NAME [get_property ENDPOINT_PIN $timingPaths]] {
    # If the CDC path endpoint is not a SLR, then skip it and process next path
    if {![regexp {^SRL.+$} $refname]} { continue }
    set cell [get_cells -of $endpoint]
    set asyncReg [get_property -quiet ASYNC_REG $cell]
    if {$asyncReg == {}} {
      puts "   Missing ASYNC_REG on $cell"
    } else {
      puts "   Found ASYNC_REG on $cell"
    }
    if {$stop} { break }
  }
  if {$stop} { break }
}

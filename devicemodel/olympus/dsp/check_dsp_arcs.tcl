
# Proc to reload current script
proc [file tail [info script]] {} " source [info script]; puts \" [info script] reloaded\" "


# Check DSP timing arcs on input pins of sub-blocks for 8 serie

proc check_in_dsp_arcs { dsp {verbose 0} } {

  if {[get_property -quiet PRIMITIVE_SUBGROUP [get_cells -quiet $dsp]] != {dsp}} {
    error " error - $dsp is not a DSP macro"
  }
  
  set FH [open check_in_dsp_arcs.rpt {a}]

  foreach cell [lsort -dictionary [get_cells -quiet $dsp/* -filter {IS_PRIMITIVE}]] {
    puts $FH "\n Processing $cell"
    set pins [lsort -dictionary [get_pins -quiet -of [get_cells -quiet $cell] -filter {DIRECTION==IN}]]
    set count 0
    foreach pin $pins {
      set arcs [get_timing_arcs -from $pin]
      if {[llength $arcs] == 0} {
        puts $FH "   Pin $pin : [llength $arcs] timing arcs found"
        incr count
      } else {
        if {$verbose} { 
          puts $FH "   Pin $pin : [llength $arcs] timing arcs found" 
          foreach arc $arcs {
            puts $FH "       $arc" 
          }
        }
      }
    }
    if {$count == [llength $pins]} {
      puts "   WARNING: none of the input pins of $cell have a timing arc"
      puts $FH "   WARNING: none of the input pins of $cell have a timing arc"
    }
  }
  
  close $FH
  puts " Report saved in check_in_dsp_arcs.rpt"
  return 0 
}

proc check_out_dsp_arcs { dsp {verbose 0} } {

  if {[get_property -quiet PRIMITIVE_SUBGROUP [get_cells -quiet $dsp]] != {dsp}} {
    error " error - $dsp is not a DSP macro"
  }
  
  set FH [open check_out_dsp_arcs.rpt {a}]

  foreach cell [lsort -dictionary [get_cells -quiet $dsp/* -filter {IS_PRIMITIVE}]] {
    puts $FH "\n Processing $cell"
    set pins [lsort -dictionary [get_pins -quiet -of [get_cells -quiet $cell] -filter {DIRECTION==OUT}]]
    set count 0
    foreach pin $pins {
      set arcs [get_timing_arcs -to $pin]
      if {[llength $arcs] == 0} {
        puts $FH "   Pin $pin : [llength $arcs] timing arcs found"
        incr count
      } else {
        if {$verbose} { 
          puts $FH "   Pin $pin : [llength $arcs] timing arcs found" 
          foreach arc $arcs {
            puts $FH "       $arc" 
          }
        }
      }
    }
    if {$count == [llength $pins]} {
      puts "   WARNING: none of the output pins of $cell have a timing arc"
      puts $FH "   WARNING: none of the output pins of $cell have a timing arc"
    }
  }

  close $FH
  puts " Report saved in check_out_dsp_arcs.rpt"
  return 0 
}


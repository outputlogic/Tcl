# From Tony Scarangella <tonys@xilinx.com>

proc generate_speed_file_v2 {} {
  set start [clock seconds] 
  set systemTime [clock seconds]
  #Get Part
  set FileName [get_property PART [get_projects]].txt
  #Generate list of speed delays and creates a file
  set fp [open "speed_delays.txt" w]
  puts $fp [join [get_speed_models] "\n"]
  close $fp
		puts "There are [llength [get_speed_models]] speed_models for device [get_property PART [get_projects]]"
  #Open File
  set wfileID [open $FileName w]
  set rfileID [open "speed_delays.txt" r]
  #Write out Header
  puts $wfileID "\t\t\t\t\tFast Corner\tSlow Corner"
  puts $wfileID "\t\t\t\t\tMin/Max,\tMin/Max,"
  #get_speed_models from ListFile
  while {! [eof $rfileID]} {
   	set delay [gets $rfileID]
   	#puts "$delay"
   	#set FAST_MAX [report_property -all [get_speed_models -filter NAME==$delay]]
   	#set FAST_MAX [report_property -all [get_speed_models -pattern $delay]]
    if {[catch {set FAST_MAX [get_property FAST_MAX [get_speed_models -pattern $delay]]} errorstring]} {
      set FAST_MAX {?}
    } else {
     	set FAST_MAX [get_property FAST_MAX [get_speed_models -pattern $delay]]
    }
    if {[catch {set FAST_MIN [get_property FAST_MIN [get_speed_models -pattern $delay]]} errorstring]} {
      set FAST_MIN {?}
    } else {
     	set FAST_MIN [get_property FAST_MIN [get_speed_models -pattern $delay]]
    }
    if {[catch {set SLOW_MAX [get_property SLOW_MAX [get_speed_models -pattern $delay]]} errorstring]} {
      set SLOW_MAX {?}
    } else {
     	set SLOW_MAX [get_property SLOW_MAX [get_speed_models -pattern $delay]]
    }
    if {[catch {set SLOW_MIN [get_property SLOW_MIN [get_speed_models -pattern $delay]]} errorstring]} {
      set SLOW_MIN {?}
    } else {
     	set SLOW_MIN [get_property SLOW_MIN [get_speed_models -pattern $delay]]
    }
     	puts $wfileID "$delay\t($FAST_MIN/$FAST_MAX)\t($SLOW_MIN/$SLOW_MAX)"	
    }
    #Close File
    close $wfileID
    close $rfileID
    set end [clock seconds] 
    set duration [expr $end - $start] 
  puts "Date: [clock format $systemTime -format %D] Compile time: [expr ([clock seconds]-$start)/3600] hour(h), [expr (([clock seconds]-$start)%3600)/60] minute(m) and [expr (([clock seconds]-$start)%3600)%60] second(s)."

}

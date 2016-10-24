# From Takayoshi
# Report skew on Zynq EMIO interface
#
# set IOs [get_ports "SDIO_0_clk sdio_0_data_io*  sdio_0_cmd_io*"]
# report_skew [get_ports $IOs]
#
# report_timing -to [get_ports $IOs] -max_paths 10 -corners Fast -delay_type min -name Fast_min
# report_timing -to [get_ports $IOs] -max_paths 10 -corners Fast -delay_type max -name Fast_max
# report_timing -to [get_ports $IOs] -max_paths 10 -corners Slow -delay_type min -name Slow_min
# report_timing -to [get_ports $IOs] -max_paths 10 -corners Slow -delay_type max -name Slow_max

proc report_skew { ports } {
  set num [llength $ports]

  foreach path [get_timing_paths -to $ports -corners Slow -delay_type max -max_paths $num] {
    lappend SlowMax [get_property DATAPATH_DELAY $path]
  }
  set SlowMax_Skew [expr [expr max([join $SlowMax ,])] - [expr min([join $SlowMax ,])]]
  foreach path [get_timing_paths -to $ports -corners Slow -delay_type min -max_paths $num] {
    lappend SlowMin [get_property DATAPATH_DELAY $path]
  }
  set SlowMin_Skew [expr [expr max([join $SlowMin ,])] - [expr min([join $SlowMin ,])]]
  foreach path [get_timing_paths -to $ports -corners Fast -delay_type max -max_paths $num] {
    lappend FastMax [get_property DATAPATH_DELAY $path]
  }
  set FastMax_Skew [expr [expr max([join $FastMax ,])] - [expr min([join $FastMax ,])]]
  foreach path [get_timing_paths -to $ports -corners Fast -delay_type min -max_paths $num] {
    lappend FastMin [get_property DATAPATH_DELAY $path]
  }
  set FastMin_Skew [expr [expr max([join $FastMin ,])] - [expr min([join $FastMin ,])]]

  puts "For OUTPUT =============="
  puts "SlowMax_Skew:$SlowMax_Skew"
  puts "SlowMin_Skew:$SlowMin_Skew"
  puts "FastMax_Skew:$FastMax_Skew"
  puts "FastMin_Skew:$FastMin_Skew"
  puts "Max Skew : [expr max([join [list $SlowMax_Skew $SlowMin_Skew $FastMax_Skew $FastMin_Skew] ,])]"

  unset SlowMax
  unset SlowMin
  unset FastMax
  unset FastMin

  foreach path [get_timing_paths -from $ports -corners Slow -delay_type max -max_paths $num] {
    lappend SlowMax [get_property DATAPATH_DELAY $path]
  }
  set SlowMax_Skew [expr [expr max([join $SlowMax ,])] - [expr min([join $SlowMax ,])]]
  foreach path [get_timing_paths -from $ports -corners Slow -delay_type min -max_paths $num] {
    lappend SlowMin [get_property DATAPATH_DELAY $path]
  }
  set SlowMin_Skew [expr [expr max([join $SlowMin ,])] - [expr min([join $SlowMin ,])]]
  foreach path [get_timing_paths -from $ports -corners Fast -delay_type max -max_paths $num] {
    lappend FastMax [get_property DATAPATH_DELAY $path]
  }
  set FastMax_Skew [expr [expr max([join $FastMax ,])] - [expr min([join $FastMax ,])]]
  foreach path [get_timing_paths -from $ports -corners Fast -delay_type min -max_paths $num] {
    lappend FastMin [get_property DATAPATH_DELAY $path]
  }
  set FastMin_Skew [expr [expr max([join $FastMin ,])] - [expr min([join $FastMin ,])]]

  puts "For INPUT =============="
  puts "SlowMax_Skew:$SlowMax_Skew"
  puts "SlowMin_Skew:$SlowMin_Skew"
  puts "FastMax_Skew:$FastMax_Skew"
  puts "FastMin_Skew:$FastMin_Skew"
  puts "Max Skew : [expr max([join [list $SlowMax_Skew $SlowMin_Skew $FastMax_Skew $FastMin_Skew] ,])]"
}

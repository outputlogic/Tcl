set runDir           [lindex $argv 0]
set placeDirective   [lindex $argv 1]
set routeDirective   [lindex $argv 2]
set crX              [lindex $argv 3]
set crY              [lindex $argv 4]
set bufgDiv          [lindex $argv 5]
#set bufgRiu          [lindex $argv 6]

source /wrk/xsjhdnobkup3/frederi/customers/baidu_xiphy/mig_crsweep/parseRPW.tcl -notrace

for {set bufgRiu 0} {$bufgRiu < 24} {incr bufgRiu} {

  if {$bufgDiv == $bufgRiu} { continue }

  open_checkpoint /wrk/xsjhdnobkup3/frederi/customers/baidu_xiphy/mig_crsweep/post_opt.dcp

  set_property CLOCK_DELAY_GROUP migClkGrp [get_nets {u_ddr4_0/inst/u_ddr4_infrastructure/c0_riu_clk u_ddr4_0/inst/u_ddr4_infrastructure/c0_ddr4_ui_clk}]
  set_property USER_CLOCK_ROOT X${crX}Y${crY} [get_nets {u_ddr4_0/inst/u_ddr4_infrastructure/c0_ddr4_ui_clk}]
  set_property LOC BUFGCE_X1Y${bufgDiv} [get_cells u_ddr4_0/inst/u_ddr4_infrastructure/u_bufg_divClk]
  set_property LOC BUFGCE_X1Y${bufgRiu} [get_cells u_ddr4_0/inst/u_ddr4_infrastructure/u_bufg_riuClk]

  place_design -directive $placeDirective
  route_design -directive $routeDirective
  #report_timing
  #report_pulse_width -max_skew -file $runDir/max_skew_divX0Y${bufgDiv}_riuX0Y${bufgRiu}.rpt
  #report_timing_summary -file $runDir/rts_postroute.rpt
  parseRPW $runDir/max_skew_divX0Y${bufgDiv}_riuX0Y${bufgRiu}.csv

  #write_checkpoint postroute.dcp -force

  close_design

}

exit

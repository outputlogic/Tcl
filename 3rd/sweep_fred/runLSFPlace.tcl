set runDir           [lindex $argv 0]
set placeDirective   [lindex $argv 1]
set routeDirective   [lindex $argv 2]
set crX              [lindex $argv 3]
set crY              [lindex $argv 4]

source /wrk/xsjhdnobkup3/frederi/customers/baidu_xiphy/mig_crsweep/parseRPW.tcl -notrace

open_checkpoint /wrk/xsjhdnobkup3/frederi/customers/baidu_xiphy/mig_crsweep/post_opt.dcp

set_property CLOCK_DELAY_GROUP migClkGrp [get_nets {u_ddr4_0/inst/u_ddr4_infrastructure/c0_riu_clk u_ddr4_0/inst/u_ddr4_infrastructure/c0_ddr4_ui_clk}]
set_property USER_CLOCK_ROOT X${crX}Y${crY} [get_nets {u_ddr4_0/inst/u_ddr4_infrastructure/c0_ddr4_ui_clk}]

place_design -directive $placeDirective
route_design -directive $routeDirective
report_timing
#report_timing_summary -file $runDir/rts_postroute.rpt
parseRPW $runDir/max_skew_X${crX}Y${crY}.csv

#write_checkpoint postroute.dcp -force

exit

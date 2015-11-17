delete_drc_check [get_drc_checks IDDR-1 -quiet] -quiet

proc iddrResetTimingCheck {} {
  update_timing
  set vios {}

  foreach iddr [get_cells -hier -filter {REF_NAME==ISERDESE3 && IDDR_MODE==TRUE}] {
    set iddrRstPin [get_pin -filter {REF_PIN_NAME==RST} -of $iddr]
    puts "Debug: Processing IDDR RST pin $iddrRstPin"
    set tp [get_timing_paths -to $iddrRstPin]
    set except [get_property EXCEPTION $tp]
    set slack [get_property SLACK $tp]
    puts "Debug: Slack is $slack"
    if { $slack<0.000 && $except!="False Path" } {
      puts "Debug: RST pin is violating"
      set msg "Timing Violation to IDDR RST pin %ELG, please see UltraFast Methodology Guide for design considerations"
      set vio [create_drc_violation -name {IDDR-1} -msg $msg $iddrRstPin]
      lappend vios $vio

    }

  }

  if {[llength $vios] > 0 } {
    return -code error $vios
  } else {
    return {}
  }
}


create_drc_check -name {IDDR-1} -hiername {IDDR Rst} -desc {IDDR RST Timing Check} -rule_body iddrResetTimingCheck
set_property SEVERITY {CRITICAL WARNING} [get_drc_checks IDDR-1]
report_drc -check {IDDR-1}
#report_property [get_drc_check IDDR-1]

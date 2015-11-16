proc reportMMCMClocks {{skipFeedbackClocks 1} {showBufceRowProgDly 1} {showClktLoadDistrib 1} {showLoadClockRegions 1}} {

  switch -exact [get_property ARCHITECTURE [get_property PART [current_design]]] {
    "artix7"  -
    "kintex7" -
    "virtex7" { set cmbFilter {REF_NAME =~ MMCM* || REF_NAME =~ PLL*} }
    "kintexu" -
    "virtexu" { set cmbFilter {REF_NAME =~ MMCM* || REF_NAME =~ PLL*} }
    default { puts "Warning - unsupported archtecture for reportMMCMClocks"; return }
  }

  set mmcmCnt 0
  foreach clkNet [get_nets -of [get_clocks -of [get_nets -filter {TYPE != "POWER" && TYPE != "GROUND"} -of [get_pins -filter {REF_PIN_NAME =~ CLKIN*} -of [get_cells -hier -filter $cmbFilter]]]]] {
    puts "### MMCM/PLL clock input net $clkNet - clock [get_clocks -of $clkNet] ###\n"
    foreach mmcm [filter [all_fanout -quiet -flat -endpoints_only -only_cell $clkNet] $cmbFilter] {
      incr mmcmCnt
      puts " -> [get_property REF_NAME $mmcm] $mmcm ([get_clock_regions -of $mmcm]) (COMPENSATION = [get_property COMPENSATION $mmcm])"
      foreach pin [get_pins -filter {direction == in} -of $mmcm] {
        set rpn  [get_property REF_PIN_NAME $pin]
        if {$skipFeedbackClocks && $rpn == "CLKFBIN"} { continue }
        set clk [get_clocks -quiet -of $pin]
        if {$clk == {}} { continue }
        set period [get_property PERIOD $clk]
        set rise [lindex [get_property WAVEFORM $clk] 0]
        set fall [lindex [get_property WAVEFORM $clk] 1]
        puts [format "   + input  %-10s - rise=%6s - fall=%6s - period=%6s - name= %s" $rpn $rise $fall $period $clk]
      }
      foreach pin [get_pins -filter {direction == out} -of $mmcm] {
        set rpn  [get_property REF_PIN_NAME $pin]
        if {$skipFeedbackClocks && $rpn == "CLKFBOUT"} { continue }
        set clk [get_clocks -quiet -of $pin]
        if {$clk == {}} { continue }
        if {[get_nets -quiet -of $pin] == {}} { continue }
        set period [get_property PERIOD $clk]
        set rise [lindex [get_property WAVEFORM $clk] 0]
        set fall [lindex [get_property WAVEFORM $clk] 1]
        if {[catch {set fanoutPins [all_fanout -quiet -flat -endpoints_only $pin]} foo]} {
          puts "ERROR - all_fanout crash - $pin - $foo"
          continue
        }
        set fanout [llength $fanoutPins]
        if {[llength [filter $fanoutPins {REF_NAME=~BUF*}]] > 0} { set bufWarn " (fanout contains clock buffer(s) that drive other clock(s))" } else { set bufWarn "" }
        #puts [format "   + output %-10s - rise=%6s - fall=%6s - period=%6s - loads=%6s - name= %s - net= %s %s" $rpn $rise $fall $period $fanout $clk $oclkNet $bufWarn]
        puts [format "   + output %-10s - rise=%6s - fall=%6s - period=%6s - loads=%6s - name= %s" $rpn $rise $fall $period $fanout $clk]
        if {$fanout == 0} { continue }
        set oclkNet [lsort -unique [get_property PARENT [get_nets -of $fanoutPins]]]
        foreach net [get_nets $oclkNet] {
          set clockRoot [get_property CLOCK_ROOT $net]
          if {$clockRoot != ""} { set crTmp "CLOCK_ROOT=$clockRoot - " } else { set crTmp "" }
          set drvPin [get_pins -filter {DIRECTION == OUT && IS_LEAF} -of $net]
          if {$drvPin != ""} {
            set drvCell [get_cells -of $drvPin]
            set drvLOC [get_property LOC $drvCell]
            ## 2015.1 crash ## set drvCR  [get_clock_regions -of $drvCell -quiet]
            ##              ## set drvTmp " - driver= [get_property REF_NAME $drvPin](LOC=$drvLOC in clock region $drvCR) ($drvPin)"
            set drvTmp " - driver= [get_property REF_NAME $drvPin](LOC=$drvLOC) ($drvPin)"
          } else { 
            set drvTmp ""
          }
          puts [format "     + ${crTmp}net= %s${drvTmp}" $net]
          if {$showBufceRowProgDly} {
            set foundProgDly 0
            set bufceRowSites [get_sites -quiet -of [get_site_pins -quiet -filter {NAME =~ BUFCE_ROW_*/CLK_IN} -of [get_nodes -quiet -of $net]]]
            set brpd {}
            foreach bufceRow $bufceRowSites {
              if {[catch {set prgDly [internal::get_prog_delay -site $bufceRow]} foo]} {
                set prgDly "n/a"
              }
              if {$prgDly != "n/a"} { set foundProgDly 1 }
              lappend brpd "[get_clock_regions -of $bufceRow]=$prgDly"
            }
            if {$brpd != {} && $foundProgDly} {
              puts "       + BUFCE_ROW Prog Delays: [join $brpd { - }]"
            }
          }
          if {$showLoadClockRegions} { displayClockRegionLoads $net {         } }
          #if {$showClktLoadDistrib} { reportCellDistribution [all_fanout -quiet -flat -endpoints_only $net] 0 {       + } }
          if {$showClktLoadDistrib} { reportCellDistribution [get_cells -quiet -of [get_pins -quiet -leaf -filter {DIRECTION==IN} -of $net]] 0 {       + } }
        }
      }
      puts ""
    }
  }
  if {[llength [get_cells -hier -filter $cmbFilter]] != $mmcmCnt} {
    puts "Warning - MMCM/PLL count mismatch - reported = $mmcmCnt - primitives = [llength [get_cells -hier -filter $cmbFilter]]"
  }
}

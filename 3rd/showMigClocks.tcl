proc migTraceBackToMMCM {opins} {
  set opins [filter -quiet $opins REF_NAME!~MMCM*]
  if {$opins == {}} { return 0 }
  set drvs {}
  foreach i [get_pins -quiet [get_property -quiet FROM_PIN [get_timing_arcs -quiet -filter {TYPE==combinational && !IS_DISABLED} -to $opins]]] {
    set o [get_pins -quiet -leaf -filter DIRECTION==OUT -of [get_nets -of $i]]
    show_schematic -add -pin_pairs [list $i $o]
    lappend drvs $o
  }
  set clkBuf1 [filter -quiet $drvs REF_NAME=~BUFG*]
  set clkBuf2 {}
  if {$drvs != {}} {
    set clkBuf2 [migTraceBackToMMCM [lsort -unique $drvs]]
  }
  return [get_pins -quiet [concat [get_property -quiet NAME $clkBuf1] [get_property -quiet NAME $clkBuf2]]]
}

proc showMIGClocks {} {
  set migIndex 0
  set migs [get_cells -hier -filter X_ULTRASCALE_IO_FLOW!=""]
  foreach mig $migs {
    #puts "current_instance $mig"
    current_instance $mig
    set mmcm [get_cells -hier -filter REF_NAME==MMCME3_ADV]
    set bitsliceControls [get_cells -hier -filter {REF_NAME==BITSLICE_CONTROL && RX_GATING==ENABLE}]
    current_instance -quiet
    set config [get_property X_ULTRASCALE_IO_FLOW $mig]
    puts "### MIG IP $migIndex: X_ULTRASCALE_IO_FLOW = $config - [llength $bitsliceControls] BITSLICE_CONTROL/RX_GATING = ENABLE - $mig ###"
    if {$bitsliceControls == {}} {
      puts "====> No constraint needed - No BITSLICE_CONTROL/RX_GATING = ENABLE <====="
      continue
    }
    show_schematic $mmcm -name migClk$migIndex
    foreach bsc [lrange $bitsliceControls 0 0] {
      foreach i [get_pins -quiet -filter {REF_PIN_NAME==PLL_CLK || REF_PIN_NAME==RIU_CLK} -of $bsc] {
        set o [get_pins -quiet -leaf -filter DIRECTION==OUT -of [get_nets -of $i]]
        show_schematic -add -pin_pairs [list $i $o]
        lappend drvs $o
      }
    }
    show_schematic -add $mmcm
    set clkBuf1 [filter -quiet $drvs REF_NAME=~BUFG*]
    if {$drvs != {}} {
      set clkBuf2 [migTraceBackToMMCM [lsort -unique $drvs]]
    }
    set clkBuf [get_pins -quiet [concat [get_property -quiet NAME $clkBuf1] [get_property -quiet NAME $clkBuf2]]]
    set mmcmCR [get_clock_regions -of $mmcm]
    puts "set_property CLOCK_DELAY_GROUP migClkGrp$migIndex \[get_nets \{[get_nets -of $clkBuf]\}\]"
    puts "set_property USER_CLOCK_ROOT   $mmcmCR     \[get_nets \{[get_nets -of $clkBuf]\}\]"
    highlight_objects -color red  [filter [get_nets -of $clkBuf] {NAME=~*riu* || NAME=~*RIU*}]
    highlight_objects -color blue [filter [get_nets -of $clkBuf] {NAME!~*riu* && NAME!~*RIU*}]
    incr migIndex
  }
}

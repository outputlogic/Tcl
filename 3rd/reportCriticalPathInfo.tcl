proc reportCriticalPathInfo {{csvFile ""} {analysis "setup"} {nbPaths 1000} {upperSlackLimit 0}} {

  array set primTable [list BUFG CLK BUFGCTRL CLK BUFH CLK CARRY4 CARRY CARRY8 CARRY DSP48E1 DSP DSP_PREADD_DATA DSP DSP_A_B_DATA DSP FDCE FD FDPE FD FDRE FD FDRS FD FDSE FD FIFO18E1 RAMB FIFO36E1 RAMB FRAME_ECCE2 OTHER GND OTHER GTHE2_COMMON GT GTHE2_CHANNEL GT GTXE2_CHANNEL GT GTXE2_COMMON GT GTPE2_CHANNEL GT IBUF IO IBUFDS IO IBUFDS_GTE2 IO ICAPE2 OTHER IDELAYCTRL IO IDELAYE2 IO IN_FIFO IO IOBUF CLK ISERDESE2 IO LUT1 LUT LUT2 LUT LUT3 LUT LUT4 LUT LUT5 LUT LUT6 LUT LUT6_2 LUT MMCME2_ADV CLK MUXF7 MUX MUXF8 MUX OBUF IO OBUFDS_DUAL_BUF IO IDDR IO ODDR IO OSERDESE2 IO OUT_FIFO IO PCIE_2_1 PCIE PCIE_3_0 PCIE PHASER_IN IO PHASER_OUT_PHY IO PHASER_REF IO PHY_CONTROL IO IBUFCTRL IO BITSLICE_CONTROL IO PLLE2_ADV CLK RAM128X1S LUTRAM RAM32M LUTRAM RAM32X1D LUTRAM RAM32X1S LUTRAM RAM64M LUTRAM RAM64X1D LUTRAM RAM64X1S LUTRAM RAMB18E1 RAMB RAMB36E1 RAMB ROM128X1 LUTRAM ROM256X1 LUTRAM SRL16E SRL SRLC32E SRL VCC OTHER XADC OTHER RAMD64E LUTRAM RAMD64E LUTRAM RAMD32 LUTRAM RAMS32 LUTRAM RAMS64E LUTRAM]
  # Some more entries for UltraScale
  array set primTable [list DSP48E2 DSP PCIE_3_1 PCIE FIFO18E2 RAMB FIFO36E2 RAMB RAMB18E2 RAMB RAMB36E2 RAMB GTHE3_CHANNEL GT GTXE3_CHANNEL GT GTXE3_COMMON GT GTPE3_CHANNEL GT RXTX_BITSLICE IO]
  set primRef [list LUT CARRY MUX FD SRL LUTRAM RAMB DSP CLK GT PCIE IO OTHER]
# set slrRef  [list SLRO SLR1 SLR2 SLR3]
  set slrRef [get_slrs -quiet]
  if {[llength $slrRef] > 1} { set checkSLR 1 } else { set checkSLR 0 }
  set allPblocks [get_pblocks -quiet]
  if {[llength $allPblocks] > 0} { set checkPblock 1 } else { set checkPblock 0 }

  set paths [get_timing_paths -max_path $nbPaths -slack_lesser_than $upperSlackLimit -$analysis]
  if {$paths == {}} {
    puts "No path with slack lesser than ${upperSlackLimit}ns found!"
    return 0
  }

  if {$csvFile == ""} { set csvFile "reportCriticalPathInfo_${analysis}.csv" }
  set CSV [open $csvFile w]
#   set csvHeader [list srcClk dstClk slack req skew dpDly dpReq c2q setupHold uncertainty pessimism lvls maxFO accFO spType epType]
  switch $analysis {
    setup {
      set csvHeader [list srcClk dstClk slack req skew dpDly dpReq c2q setup uncertainty pessimism lvls maxFO accFO spType epType]
    }
    hold {
      set csvHeader [list srcClk dstClk slack req skew dpDly dpReq c2q hold uncertainty pessimism lvls maxFO accFO spType epType]
    }
    default {
    }
  }
  if {$checkPblock} { set csvHeader [concat $csvHeader [list spPblock epPblock #pblocked #pblock]] }
  if {$checkSLR}    { set csvHeader [concat $csvHeader $slrRef] }
  set csvHeader [concat $csvHeader $primRef]
  set csvHeader [concat $csvHeader spClockR epClockR #clockR]
  set csvHeader [concat $csvHeader path locs]
  set csvHeader [concat $csvHeader exception corner delay]
  set csvHeader [concat $csvHeader startPoint endPoint]
  puts $CSV [join $csvHeader ,]

  foreach ref $primRef { set refTot($ref) 0 }
  foreach slr $slrRef  { set slrTot($slr) 0 }

  foreach path $paths {
    set     txt [get_property STARTPOINT_CLOCK $path]
    lappend txt [get_property ENDPOINT_CLOCK $path]
    lappend txt [get_property SLACK $path]
    lappend txt [get_property REQUIREMENT $path]
    lappend txt [get_property SKEW $path]
    lappend txt [get_property -quiet DATAPATH_DELAY $path]
    
    set multipleCkToQArcsMatching 0
    set multipleSetupHoldArcsMatching 0
    # Extract the CLK->Q delay
# puts "<STARTPOINT_PIN:[get_property STARTPOINT_PIN $path]><ENDPOINT_PIN:[get_property ENDPOINT_PIN $path]>"
    set clkToQDly {}
    switch $analysis {
      setup {
        set arc [get_timing_arcs -from [get_property STARTPOINT_PIN $path] -to [lindex [get_pins -of $path] 0] -filter {TYPE == {Reg Clk to Q}}]
        if {[llength $arc] > 1} {
          incr multipleCkToQArcsMatching
          puts "Warning - [llength $arc] arcs matching for CLK->Q ([get_property STARTPOINT_PIN $path] -> [get_property ENDPOINT_PIN $path])"
        }
        # In the scenario of multiple arcs matching, keep highest delay. The 'catch' covers the case
        # when no arc is returned
        catch { set clkToQDly [expr max([join [get_property -quiet DELAY_MAX_RISE $arc] ,])] }
        if {$clkToQDly == {}} {
          # If no value for RISE, let's try with FALL
          catch { set clkToQDly [expr max([join [get_property -quiet DELAY_MAX_FALL $arc] ,])] }
        }
      }
      hold {
        set arc [get_timing_arcs -from [get_property STARTPOINT_PIN $path] -to [lindex [get_pins -of $path] 0] -filter {TYPE == {Reg Clk to Q}}]
        if {[llength $arc] > 1} {
          incr multipleCkToQArcsMatching
          puts "Warning - [llength $arc] arcs matching for CLK->Q ([get_property STARTPOINT_PIN $path] -> [get_property ENDPOINT_PIN $path])"
        }
        # In the scenario of multiple arcs matching, keep highest delay. The 'catch' covers the case
        # when no arc is returned
        catch { set clkToQDly [expr max([join [get_property -quiet DELAY_MIN_RISE $arc] ,])] }
        if {$clkToQDly == {}} {
          # If no value for RISE, let's try with FALL
          catch { set clkToQDly [expr max([join [get_property -quiet DELAY_MIN_FALL $arc] ,])] }
        }
      }
      default {
      }
    }
    if {$clkToQDly == {}} {
# puts "<clkToQDly><STARTPOINT_PIN:[get_property STARTPOINT_PIN $path]><ENDPOINT_PIN:[get_property ENDPOINT_PIN $path]>"
    }
    # Safety net:
    if {$clkToQDly == {}} { set clkToQDly 0.0 }
    
    # Extract the setup/hold delay
    set setupHoldDly {}
    switch $analysis {
      setup {
        set arc [get_timing_arcs -to [get_property ENDPOINT_PIN $path] -filter {TYPE == setup || TYPE == SETUP || TYPE == recovery || TYPE == RECOVERY}]
        if {[llength $arc] > 1} {
          incr multipleSetupHoldArcsMatching
          puts "Warning - [llength $arc] arcs matching for Setup/Recovery ([get_property STARTPOINT_PIN $path] -> [get_property ENDPOINT_PIN $path])"
        }
        # In the scenario of multiple arcs matching, keep highest delay. The 'catch' covers the case
        # when no arc is returned
        catch { set setupHoldDly [expr max([join [get_property -quiet DELAY_MAX_RISE $arc] ,])] }
        if {$setupHoldDly == {}} {
          # If no value for RISE, let's try with FALL
          catch { set setupHoldDly [expr max([join [get_property -quiet DELAY_MAX_FALL $arc] ,])] }
        }
      }
      hold {
        set arc [get_timing_arcs -to [get_property ENDPOINT_PIN $path] -filter {TYPE == hold || TYPE == HOLD || TYPE == removal || TYPE == REMOVAL}]
        if {[llength $arc] > 1} {
          incr multipleSetupHoldArcsMatching
          puts "Warning - [llength $arc] arcs matching for Hold/Removal ([get_property STARTPOINT_PIN $path] -> [get_property ENDPOINT_PIN $path])"
        }
        # In the scenario of multiple arcs matching, keep highest delay. The 'catch' covers the case
        # when no arc is returned
        catch { set setupHoldDly [expr max([join [get_property -quiet DELAY_MIN_RISE $arc] ,])] }
        if {$setupHoldDly == {}} {
          # If no value for RISE, let's try with FALL
          catch { set setupHoldDly [expr max([join [get_property -quiet DELAY_MIN_FALL $arc] ,])] }
        }
      }
      default {
      }
    }
    if {$setupHoldDly == {}} {
# puts "<setupHoldDly><STARTPOINT_PIN:[get_property STARTPOINT_PIN $path]><ENDPOINT_PIN:[get_property ENDPOINT_PIN $path]>"
    }
    # Safety net:
    if {$setupHoldDly == {}} { set setupHoldDly 0.0 }
    
    # Calculate the datapath requirement: REQUIREMENT + SKEW - CLK->Q - SETUP + HOLD
    switch $analysis {
      setup {
        set datapathRequirement [format {%.3f} [expr [get_property REQUIREMENT $path] + [get_property SKEW $path] - $clkToQDly - $setupHoldDly] ]
      }
      hold {
        set datapathRequirement [format {%.3f} [expr [get_property REQUIREMENT $path] + [get_property SKEW $path] - $clkToQDly + $setupHoldDly] ]
      }
      default {
      }
    }

    if {$multipleCkToQArcsMatching || $multipleSetupHoldArcsMatching} {
      lappend txt [format {%s (*)} $datapathRequirement]
    } else {
      lappend txt $datapathRequirement
    }
    if {$multipleCkToQArcsMatching} {
      lappend txt [format {%s (*)} $clkToQDly]
    } else {
      lappend txt $clkToQDly
    }
    if {$multipleSetupHoldArcsMatching} {
      lappend txt [format {%s (*)} $setupHoldDly]
    } else {
      lappend txt $setupHoldDly
    }

    lappend txt [get_property -quiet UNCERTAINTY $path]
    lappend txt [get_property -quiet CLOCK_PESSIMISM $path]
    lappend txt [get_property LOGIC_LEVELS $path]

    set netFanout {}
    foreach net [get_nets -of $path] {
      lappend netFanout [expr [get_property FLAT_PIN_COUNT $net] - 1]
    }
    lappend txt [lindex [lsort -increasing -integer $netFanout] end]
    lappend txt [expr [join $netFanout +]]
#     lappend txt [get_property -quiet REF_NAME [get_cells -quiet -of [get_property STARTPOINT_PIN $path]] ]
    set cellType [get_property -quiet REF_NAME [get_cells -quiet -of [get_property STARTPOINT_PIN $path]] ]
    if {$cellType == {}} { set cellType {<PORT>} }
    lappend txt $cellType
#    lappend txt [get_property -quiet REF_NAME [get_cells -quiet -of [get_property ENDPOINT_PIN $path]] ]
    set cellType [get_property -quiet REF_NAME [get_cells -quiet -of [get_property ENDPOINT_PIN $path]] ]
    if {$cellType == {}} { set cellType {<PORT>} }
    lappend txt $cellType
    if {$checkPblock} {
      lappend txt [get_pblocks -quiet -of [get_cells -quiet -of [get_property STARTPOINT_PIN $path]]]
      lappend txt [get_pblocks -quiet -of [get_cells -quiet -of [get_property ENDPOINT_PIN $path]]]
    }

    foreach ref $primRef { set refCnt($ref) 0 }
    foreach slr $slrRef { set slrCnt($slr) 0 }
    set pblocks {}

    foreach cell [get_cells -of $path] {
      set cellRef [get_property REF_NAME $cell]
      if {![info exist primTable($cellRef)]} {
        puts "Warning - unsupported REF_NAME $cellRef for statistics purpose"
      } else {
        incr refCnt($primTable($cellRef))
      }
      if {$checkSLR} {
        set slr [get_slrs -of $cell -quiet]
        if {$slr != ""} { incr slrCnt($slr) }
      }
      if {$checkPblock} {
        set pb [get_pblocks -quiet -of $cell]
        if {$pb != {}} { lappend pblocks $pb }
      }
    }

    if {$checkPblock} {
      lappend txt [llength $pblocks]
      set pblocks [lsort -unique $pblocks]
      if {$pblocks == {}} {
        lappend txt 0
      } else {
        lappend txt [llength $pblocks]
      }
    }
    if {$checkSLR} {
      foreach slr $slrRef {
        lappend txt $slrCnt($slr)
        incr slrTot($slr) $slrCnt($slr)
      }
    }
    foreach ref $primRef {
      lappend txt $refCnt($ref)
      incr refTot($ref) $refCnt($ref)
    }
    # Add clock regions info
    lappend txt [get_property -quiet CLOCK_REGION [get_sites -quiet [get_property -quiet SITE [get_cells -quiet -of [get_property STARTPOINT_PIN $path]]] ] ]
    lappend txt [get_property -quiet CLOCK_REGION [get_sites -quiet [get_property -quiet SITE [get_cells -quiet -of [get_property ENDPOINT_PIN $path]]] ] ]
    lappend txt [llength [lsort -unique [get_property -quiet CLOCK_REGION [get_sites -quiet [get_property -quiet SITE [get_cells -quiet -of $path ]] ] ] ] ]
    lappend txt [get_property -quiet REF_NAME [get_cells -quiet -of $path]]
    lappend txt [get_property -quiet LOC [get_cells -quiet -of $path]]
    lappend txt [get_property -quiet EXCEPTION $path]
    lappend txt [get_property -quiet CORNER $path]
    lappend txt [get_property -quiet DELAY_TYPE $path]
    lappend txt [get_property STARTPOINT_PIN $path]
    lappend txt [get_property ENDPOINT_PIN $path]
    puts $CSV [join $txt ,]
    #puts [join $txt " - "]
  }
  set txt [list {} {} {} {} {} {} {} {}]
  if {$checkPblock} { set txt [concat $txt [list {} {} {} {}]] }
  if {$checkSLR} {
    foreach slr $slrRef  { lappend txt $slrTot($slr) }
  }
  foreach ref $primRef { lappend txt $refTot($ref) }
  lappend txt {}
  lappend txt {}
  puts $CSV [join $txt ,]
  #puts [join $txt " - "]
  close $CSV
  puts "Analyzed [llength $paths] paths (limit: $nbPaths) - report available in $csvFile"
}


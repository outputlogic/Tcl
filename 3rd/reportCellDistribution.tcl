proc reportCellDistribution {cells {showAll 0} {indent ""}} {

  array set primTable [list BUF* CLK CARRY* CARRY DSP* DSP LD* FD FD* FD FIFO* RAMB FRAME_ECCE2 CONFIG GND CONSTANT GT* GT IBUF* IO ICAPE2 CONFIG IDELAY* IO IN_FIFO IO IOBUF IO *SERDES* IO LUT* LUT MMCME* CLK MUXF* MUX OBUF* IO *DDR* IO OUT_FIFO IO PCIE_2_1 PCIE PHASER* IO PHY_CONTROL IO *BITSLICE* IO PLL* CLK RAM*S LUTRAM RAM*M LUTRAM RAM*D LUTRAM RAMB* RAMB ROM* LUTRAM SRL* SRL VCC CONSTANT XADC CONFIG RAMD* LUTRAM RAMS* LUTRAM ILKN SPECIAL CMAC SPECIAL]
  set primRef [list LUT CARRY MUX FD SRL LUTRAM RAMB DSP CLK GT PCIE IO CONSTANT CONFIG SPECIAL OTHER]
  foreach ref $primRef {
    set refCnt($ref) 0
  }
  set totMatchCnt 0

  set cellCnt [llength $cells]
  if {$cellCnt == 0} {
    puts "Warning - no cells specified for reportCellDistribution"
    return
  }
  set refNames [get_property REF_NAME $cells]
  foreach prim [array names primTable] {
    set ind [lsearch -all -glob $refNames $prim]
    if {$ind == -1} { continue }
    set indCnt [llength $ind]
    incr refCnt($primTable($prim)) $indCnt
    incr totMatchCnt $indCnt
  }
  if {$totMatchCnt < $cellCnt} {
    incr refCnt(OTHER) [expr $cellCnt - $totMatchCnt]
  } elseif {$totMatchCnt > $cellCnt} {
    puts "Warning - Number of matched REF_NAME higher than cell count ([expr $totMatchCnt - $cellCnt]) - Possible double counting"
  }

  foreach ref $primRef {
    if {!$showAll && $refCnt($ref) == 0} { continue }
    puts [format "${indent}%6s = %s" $ref $refCnt($ref)]
  }
}

proc getCellDistribution {cells primGrp} {
  switch -exact [get_property ARCHITECTURE [get_property PART [current_design]]] {
    "artix7"  -
    "kintex7" -
    "virtex7" { return [getCellDistribution7Series $cells $primGrp] }
    "kintexu" -
    "virtexu" { return [getCellDistributionUltraScale $cells $primGrp] }
    default { puts "Warning - unsupported archtecture for getCellDistribution"; return }
  }
}

proc getCellDistributionUltraScale {cells primSubGrp} {

  foreach sg $primSubGrp {
    set sgCnt($sg) 0
  }

  # LUT CARRY MUXF SDR SRL LUTRAM BRAM DSP CLK GT PCIE IO OTHER
  foreach cell $cells {
    set cellSG [get_property PRIMITIVE_SUBGROUP $cell]
    switch -exact $cellSG {
      "INPUT_BUFFER"  { set cellSG "IO" }
      "OUTPUT_BUFFER" { set cellSG "IO" }
      "BUFFER"        { set cellSG "CLK" }
      "OTHERS"        -
      "others"        { set cellSG "OTHER" }
    }
    if {![info exists sgCnt($cellSG)]} {
        puts "Warning - unsupported PRIMITIVE_SUBGROUP $cellSG for statistics purpose - adding to OTHER"
        set cellSG "OTHER"
    }
    incr sgCnt($cellSG)
  }
  return [array get sgCnt]
}

proc getCellDistribution7Series {cells primGrp} {

  foreach g $primGrp {
    set gCnt($g) 0
  }

  # LUT CARRY MUXF SDR SRL LUTRAM BRAM DSP CLK GT PCIE IO OTHER
  foreach cell $cells {
    set cellG [get_property PRIMITIVE_GROUP $cell]
    switch -exact $cellG {
      "FLOP_LATCH" { set cellG "SDR" }
      "DMEM"       { if {[get_property PRIMITIVE_SUBGROUP $cell] == "srl"} { set cellG "SRL" } else { set cellG "LUTRAM" }}
      "BMEM"       { set cellG "BRAM" }
      "HARD_IP"    { set cellG "PCIE" }
      "MULT"       { set cellG "DSP" }
      "MUXFX"      { set cellG "MUXF" }
      "OTHERS"     { set cellG "OTHER" }
      "IO"         { if {[get_property PRIMITIVE_SUBGROUP $cell] == "gt"} { set cellG "GT" }}
    }
    if {![info exists gCnt($cellG)]} {
        puts "Warning - unsupported PRIMITIVE_GROUP $cellG for statistics purpose - adding to OTHER"
        set cellG "OTHER"
    }
    incr gCnt($cellG)
  }
  return [array get gCnt]
}

proc reportCellDistributionOfNet {object} {
  if {[lsort -unique [get_property CLASS $object]] == "pin"} {
    set tmpNet [get_nets -of [get_sel]]
  } else {
    set tmpNet $object
  }
  reportCellDistribution [get_cells -of [get_pins -leaf -filter {DIRECTION==IN} -of $tmpNet]]
}

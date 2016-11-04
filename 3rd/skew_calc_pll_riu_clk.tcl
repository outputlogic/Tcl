########################################################################################
## 2016-10-25 - Initial release, leveraged from IOSERDES Script
########################################################################################


puts "Running \"update_timing -full\" ......"
update_timing -full


proc skewCheck {} {

  # Clear DRC violation container
  set vios {}

########################################################################
# liberty format:
#
# pin (PIN) {
#    direction : input;
#    clock : true;
#    timing () {
#       timing_type: skew_rising;
#       related_pin: "RELATED";
#    }
# }
#
#
# Formula for this simple script is:
#            SKEW = PIN - RELATED + CLOCK_UNCERTAINTY
#                 where:
#                        CLOCK_UNCERTAINTY = ((TOTAL_SYSTEM_JITTER^2 + DISCRETE_JITTER^2)^1/2) / 2 + PHASE_ERROR
#                        **CLOCK_UNCERTAINTY is currently an estimate**
#
# **This is similar to Vivado Timer, but not exact**
#
# Format is max_skew_<CORNER>_<PIN>_<RELATED>
#########################################################################

  set max_skew_SLOW_PLLCLK_RIUCLK -0.200
  set max_skew_SLOW_RIUCLK_PLLCLK 1.400

  set max_skew_FAST_PLLCLK_RIUCLK -0.200
  set max_skew_FAST_RIUCLK_PLLCLK 1.400



set BSC_list [get_cells -hier -filter {REF_NAME==BITSLICE_CONTROL && RX_GATING==ENABLE}]
foreach BSC $BSC_list {
   puts "Processing BITSLICE_CONTROL instance: $BSC"

   set analyze 1
   set clock_uncertainty 0.202
   

   set RIU_CLK [get_pins -filter {REF_PIN_NAME==RIU_CLK} -of $BSC]
   set PLL_CLK [get_pins -filter {REF_PIN_NAME==PLL_CLK} -of $BSC]


   #RIU_CLK path
   set RIU_CLK_driver [get_pins  -leaf -filter DIRECTION==OUT -of [get_nets -top -seg -of $RIU_CLK]]
   set RIU_CLK_cell   [get_cells -of $RIU_CLK_driver]  
   set RIU_CLK_in_pin [get_pins  -leaf -filter REF_PIN_NAME==I -of $RIU_CLK_cell]
   set RIU_CLK_source [get_pins  -leaf -filter DIRECTION==OUT -of [get_nets -top -seg -of $RIU_CLK_in_pin]]


   set source_wire_riuclk_slow_max [get_property DELAY_SLOW_MAX_RISE [get_timing_arcs -from $RIU_CLK_source -to $RIU_CLK_in_pin]]
   set cell_riuclk_slow_max        [get_property DELAY_SLOW_MAX_RISE [get_timing_arcs -from $RIU_CLK_in_pin -to $RIU_CLK_driver]]
   set bufg_net_riuclk_slow_max    [get_property DELAY_SLOW_MAX_RISE [get_timing_arcs -from $RIU_CLK_driver -to $RIU_CLK]]
   set total_riuclk_slow_max       [expr $source_wire_riuclk_slow_max + $cell_riuclk_slow_max + $bufg_net_riuclk_slow_max]

   set source_wire_riuclk_slow_min [get_property DELAY_SLOW_MIN_RISE [get_timing_arcs -from $RIU_CLK_source -to $RIU_CLK_in_pin]]
   set cell_riuclk_slow_min        [get_property DELAY_SLOW_MIN_RISE [get_timing_arcs -from $RIU_CLK_in_pin -to $RIU_CLK_driver]]
   set bufg_net_riuclk_slow_min    [get_property DELAY_SLOW_MIN_RISE [get_timing_arcs -from $RIU_CLK_driver -to $RIU_CLK]]
   set total_riuclk_slow_min       [expr $source_wire_riuclk_slow_min + $cell_riuclk_slow_min + $bufg_net_riuclk_slow_min]

   set source_wire_riuclk_fast_max [get_property DELAY_FAST_MAX_RISE [get_timing_arcs -from $RIU_CLK_source -to $RIU_CLK_in_pin]]
   set cell_riuclk_fast_max        [get_property DELAY_FAST_MAX_RISE [get_timing_arcs -from $RIU_CLK_in_pin -to $RIU_CLK_driver]]
   set bufg_net_riuclk_fast_max    [get_property DELAY_FAST_MAX_RISE [get_timing_arcs -from $RIU_CLK_driver -to $RIU_CLK]]
   set total_riuclk_fast_max       [expr $source_wire_riuclk_fast_max + $cell_riuclk_fast_max + $bufg_net_riuclk_fast_max]

   set source_wire_riuclk_fast_min [get_property DELAY_FAST_MIN_RISE [get_timing_arcs -from $RIU_CLK_source -to $RIU_CLK_in_pin]]
   set cell_riuclk_fast_min        [get_property DELAY_FAST_MIN_RISE [get_timing_arcs -from $RIU_CLK_in_pin -to $RIU_CLK_driver]]
   set bufg_net_riuclk_fast_min    [get_property DELAY_FAST_MIN_RISE [get_timing_arcs -from $RIU_CLK_driver -to $RIU_CLK]]
   set total_riuclk_fast_min       [expr $source_wire_riuclk_fast_min + $cell_riuclk_fast_min + $bufg_net_riuclk_fast_min]

   puts "\tPATH for RIU_CLK:"
   puts "\t\tMMCM -> BUFG Wire Delay ${source_wire_riuclk_slow_max}"
   puts "\t\tBUFG Cell Delay ${cell_riuclk_slow_max}"
   puts "\t\tBUFG -> RIU_CLK Wire Delay: ${bufg_net_riuclk_slow_max}"
   puts "\t\t----------------------------------------------------"
   puts "\t\t${total_riuclk_slow_max}\n"


   #PLL_CLK path
   set PLL_CLK_driver     [get_pins  -leaf -filter DIRECTION==OUT -of [get_nets -top -seg -of $PLL_CLK]]
   set PLL_CLK_pll        [get_cells -of $PLL_CLK_driver] 
   set PLL_CLK_pll_in_pin [get_pins  -leaf -filter REF_PIN_NAME==CLKIN -of $PLL_CLK_pll]
   set PLL_CLK_out_pin    [get_pins -leaf -filter DIRECTION==OUT -of [get_nets -of $PLL_CLK_pll_in_pin]]
   set PLL_CLK_cell       [get_cells -of $PLL_CLK_out_pin]
   set PLL_CLK_in_pin     [get_pins  -leaf -filter REF_PIN_NAME==I -of $PLL_CLK_cell]
   set PLL_CLK_source     [get_pins  -leaf -filter DIRECTION==OUT -of [get_nets -top -seg -of $PLL_CLK_in_pin]]

   set source_wire_pllclk_slow_max [get_property DELAY_SLOW_MAX_RISE [get_timing_arcs -from $PLL_CLK_source -to $PLL_CLK_in_pin]]
   set cell_pllclk_slow_max        [get_property DELAY_SLOW_MAX_RISE [get_timing_arcs -from $PLL_CLK_in_pin -to $PLL_CLK_out_pin]]
   set bufg_net_pllclk_slow_max    [get_property DELAY_SLOW_MAX_RISE [get_timing_arcs -from $PLL_CLK_out_pin -to $PLL_CLK_pll_in_pin]]
   set pll_pllclk_slow_max         [get_property DELAY_SLOW_MAX_RISE [get_timing_arcs -from $PLL_CLK_pll_in_pin -to $PLL_CLK_driver]]
   set wire_pllclk_slow_max        [get_property DELAY_SLOW_MAX_RISE [get_timing_arcs -from $PLL_CLK_driver -to $PLL_CLK]]
   set total_pllclk_slow_max       [expr $source_wire_pllclk_slow_max + $cell_pllclk_slow_max + $bufg_net_pllclk_slow_max + $pll_pllclk_slow_max + $wire_pllclk_slow_max]

   set source_wire_pllclk_slow_min [get_property DELAY_SLOW_MIN_RISE [get_timing_arcs -from $PLL_CLK_source -to $PLL_CLK_in_pin]]
   set cell_pllclk_slow_min        [get_property DELAY_SLOW_MIN_RISE [get_timing_arcs -from $PLL_CLK_in_pin -to $PLL_CLK_out_pin]]
   set bufg_net_pllclk_slow_min    [get_property DELAY_SLOW_MIN_RISE [get_timing_arcs -from $PLL_CLK_out_pin -to $PLL_CLK_pll_in_pin]]
   set pll_pllclk_slow_min         [get_property DELAY_SLOW_MIN_RISE [get_timing_arcs -from $PLL_CLK_pll_in_pin -to $PLL_CLK_driver]]
   set wire_pllclk_slow_min        [get_property DELAY_SLOW_MIN_RISE [get_timing_arcs -from $PLL_CLK_driver -to $PLL_CLK]]
   set total_pllclk_slow_min       [expr $source_wire_pllclk_slow_min + $cell_pllclk_slow_min + $bufg_net_pllclk_slow_min + $pll_pllclk_slow_min + $wire_pllclk_slow_min]

   set source_wire_pllclk_fast_max [get_property DELAY_FAST_MAX_RISE [get_timing_arcs -from $PLL_CLK_source -to $PLL_CLK_in_pin]]
   set cell_pllclk_fast_max        [get_property DELAY_FAST_MAX_RISE [get_timing_arcs -from $PLL_CLK_in_pin -to $PLL_CLK_out_pin]]
   set bufg_net_pllclk_fast_max    [get_property DELAY_FAST_MAX_RISE [get_timing_arcs -from $PLL_CLK_out_pin -to $PLL_CLK_pll_in_pin]]
   set pll_pllclk_fast_max         [get_property DELAY_FAST_MAX_RISE [get_timing_arcs -from $PLL_CLK_pll_in_pin -to $PLL_CLK_driver]]
   set wire_pllclk_fast_max        [get_property DELAY_FAST_MAX_RISE [get_timing_arcs -from $PLL_CLK_driver -to $PLL_CLK]]
   set total_pllclk_fast_max       [expr $source_wire_pllclk_fast_max + $cell_pllclk_fast_max + $bufg_net_pllclk_fast_max + $pll_pllclk_fast_max + $wire_pllclk_fast_max]

   set source_wire_pllclk_fast_min [get_property DELAY_FAST_MIN_RISE [get_timing_arcs -from $PLL_CLK_source -to $PLL_CLK_in_pin]]
   set cell_pllclk_fast_min        [get_property DELAY_FAST_MIN_RISE [get_timing_arcs -from $PLL_CLK_in_pin -to $PLL_CLK_out_pin]]
   set bufg_net_pllclk_fast_min    [get_property DELAY_FAST_MIN_RISE [get_timing_arcs -from $PLL_CLK_out_pin -to $PLL_CLK_pll_in_pin]]
   set pll_pllclk_fast_min         [get_property DELAY_FAST_MIN_RISE [get_timing_arcs -from $PLL_CLK_pll_in_pin -to $PLL_CLK_driver]]
   set wire_pllclk_fast_min        [get_property DELAY_FAST_MIN_RISE [get_timing_arcs -from $PLL_CLK_driver -to $PLL_CLK]]
   set total_pllclk_fast_min       [expr $source_wire_pllclk_fast_min + $cell_pllclk_fast_min + $bufg_net_pllclk_fast_min + $pll_pllclk_fast_min + $wire_pllclk_fast_min]


   puts "\tPATH for PLL_CLK:"
   puts "\t\tMMCM -> BUFG Wire Delay ${source_wire_pllclk_slow_max}"
   puts "\t\tBUFG Cell Delay ${cell_pllclk_slow_max}"
   puts "\t\tBUFG -> PLL Wire Delay: ${bufg_net_pllclk_slow_max}"
   puts "\t\tPLL Cell Delay: ${pll_pllclk_slow_max}"
   puts "\t\tPLL -> PLL_CLK Wire Delay: ${bufg_net_pllclk_slow_max}"
   puts "\t\t----------------------------------------------------"
   puts "\t\t${total_pllclk_slow_max}\n"


   set RIU_CLK_mmcm [get_cells -of $RIU_CLK_source]
   set PLL_CLK_mmcm [get_cells -of $PLL_CLK_source]

   if {$RIU_CLK_mmcm != $PLL_CLK_mmcm} {
      puts "\tCRITICAL WARNING: RIU_CLK and PLL_CLK are driven by different MMCMs!  This does not follow the correct topology! Skipping!"
      #not necessary to set analyze to 0 but if code is reworked it might prevent a bug
      set analyze 0
   } 



   if { $analyze } {

   #Format is skew_<CORNER>_<PIN>_<RELATED>
   set skew_slow_riuclk_pllclk [expr $total_riuclk_slow_max - $total_pllclk_slow_min + $clock_uncertainty]
   set skew_fast_riuclk_pllclk [expr $total_riuclk_fast_max - $total_pllclk_fast_min + $clock_uncertainty]

   set skew_slow_pllclk_riuclk [expr $total_pllclk_slow_max - $total_riuclk_slow_min + $clock_uncertainty]
   set skew_fast_pllclk_riuclk [expr $total_pllclk_fast_max - $total_riuclk_fast_min + $clock_uncertainty]


   ## Format to 3 decimal places
   set skew_slow_riuclk_pllclk [format %.3f $skew_slow_riuclk_pllclk]
   set skew_fast_riuclk_pllclk [format %.3f $skew_fast_riuclk_pllclk]

   set skew_slow_pllclk_riuclk [format %.3f $skew_slow_pllclk_riuclk]
   set skew_fast_pllclk_riuclk [format %.3f $skew_fast_pllclk_riuclk]

   puts "\tSkew between RIU_CLK (PIN) and PLL_CLK (RELATED) in SLOW Corner: $skew_slow_riuclk_pllclk"
   puts "\tSkew between RIU_CLK (PIN) and PLL_CLK (RELATED) in FAST Corner: $skew_fast_riuclk_pllclk"

   puts "\tSkew between PLL_CLK (PIN) and RIU_CLK (RELATED) in SLOW Corner: $skew_slow_pllclk_riuclk"
   puts "\tSkew between PLL_CLK (PIN) and RIU_CLK (RELATED) in FAST Corner: $skew_fast_pllclk_riuclk\n"

   ##Perform the check
   ##Format is max_skew_<CORNER>_<PIN>_<RELATED> and skew_<CORNER>_<PIN>_<RELATED>

   if { $skew_slow_riuclk_pllclk > $max_skew_SLOW_RIUCLK_PLLCLK } {
      set msg "On BITSLICE_CONTROL cell %ELG the SLOW Corner skew between RIU_CLK (PIN) and PLL_CLK (RELATED) is $skew_slow_riuclk_pllclk while the limit is $max_skew_SLOW_RIUCLK_PLLCLK"
      set vio [create_drc_violation -name {IOSK-3} -msg $msg $BSC]
      lappend vios $vio
   }
   if { $skew_fast_riuclk_pllclk > $max_skew_FAST_RIUCLK_PLLCLK } {
      set msg "On BITSLICE_CONTROL cell %ELG the FAST Corner skew between RIU_CLK (PIN) and PLL_CLK (RELATED) is $skew_fast_riuclk_pllclk while the limit is $max_skew_FAST_RIUCLK_PLLCLK"
      set vio [create_drc_violation -name {IOSK-3} -msg $msg $BSC]
      lappend vios $vio
   }
   if { $skew_slow_pllclk_riuclk > $max_skew_SLOW_PLLCLK_RIUCLK } {
      set msg "On BITSLICE_CONTROL cell %ELG the SLOW Corner skew between PLL_CLK (PIN) and RIU_CLK (RELATED) is $skew_slow_pllclk_riuclk while the limit is $max_skew_SLOW_PLLCLK_RIUCLK"
      set vio [create_drc_violation -name {IOSK-3} -msg $msg $BSC]
      lappend vios $vio
   }
   if { $skew_fast_pllclk_riuclk > $max_skew_FAST_PLLCLK_RIUCLK } {
      set msg "On BITSLICE_CONTROL cell %ELG the FAST Corner skew between PLL_CLK (PIN) and RIU_CLK (RELATED) is $skew_fast_pllclk_riuclk while the limit is $max_skew_FAST_PLLCLK_RIUCLK"
      set vio [create_drc_violation -name {IOSK-3} -msg $msg $BSC]
      lappend vios $vio
   }

   }
  }


if {[llength $vios] > 0} {
  return -code error $vios
} else {
  return {}
}

}


delete_drc_check -name IOSK-3 -quiet
create_drc_check -name {IOSK-3} -hiername {skew} -desc {RIU_CLK PLL_CLK SKEW CHECK} -rule_body skewCheck -severity Error -msg %MSG_STRING
report_drc -checks {IOSK-3} -name RIUPLL_SKEW_CHECK -file RIU_PLL_SKEW_CHECK_drc.txt


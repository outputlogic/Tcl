

#############################################################################
#############################################################################
#############################################################################

set ::DEBUG 0

# define_gt_pblock interlaken {X0Y12} [list <pin1> .. <pinN>]
# define_gt_pblock interlaken {X0Y12 X0Y13} [list <pin1> .. <pinN>]
proc define_gt_pblock { name clockRegions pins } {
  set CMD [format "create_pblock $name"]
  switch [llength $clockRegions] {
    1 {
      append CMD [format "\nresize_pblock $name -add {CLOCKREGION_%s}" $clockRegions]
    }
    2 {
      append CMD [format "\nresize_pblock $name -add {CLOCKREGION_%s:CLOCKREGION_%s}" [lindex $clockRegions 0] [lindex $clockRegions 1] ]
    }
    default {
      puts " -E- incorrect clock region definition: $clockRegions"
      return {}
    }
  }
  set collectionResultDisplayLimit [get_param tcl.collectionResultDisplayLimit]
  set_param tcl.collectionResultDisplayLimit 0
  foreach pin $pins {
#     set filter [format {get_cells -quiet -of [get_pins -quiet -leaf -of [get_nets -quiet -of [get_pins -quiet %s]] -filter {(DIRECTION == IN) && (REF_NAME =~ FD*)}]} $pin ]
#     set filter [format {get_cells -quiet -of [get_pins -quiet -leaf -of [get_nets -quiet -of [get_pins -quiet %s]] -filter {(DIRECTION == IN) && ((REF_NAME =~ FD*) || (REF_NAME =~ SRL*) || (REF_NAME =~ RAM*))}]} $pin ]
    set filter [format {get_cells -quiet -of [get_pins -quiet -leaf -of [get_nets -quiet -of [get_pins -quiet %s]] -filter {(DIRECTION == IN) && ((REF_NAME =~ FD*) || (REF_NAME =~ SRL*) || (REF_NAME =~ RAMB*))}] -filter {PRIMITIVE_LEVEL == LEAF}} $pin ]
    set cells [eval $filter]
    if {[llength $cells] == 0} {
      append CMD [format "\n# Loads (FD*/SRL*/RAMB*): %s" [llength $cells] ]
      append CMD [format "\n# add_cells_to_pblock $name \[%s\]" $filter]
    } else {
      append CMD [format "\n# Loads (FD*/SRL*/RAMB*): %s" [llength $cells] ]
      append CMD [format "\nadd_cells_to_pblock $name \[%s\]" $filter]
    }
  }
  puts [format {
################################ GT PBLOCK DEFINITION ################################
%s
######################################################################################
} $CMD ]
  if {$::DEBUG == 0} {
    eval $CMD
  }

#   puts $CMD
  set_param tcl.collectionResultDisplayLimit $collectionResultDisplayLimit
  return -code ok
#   return $CMD
}

define_gt_pblock GT_INTERLAKEN \
                 {X0Y12 X0Y13} \
                 [list PCOAM_CORE/POMAA/PPIAA/U_IIPC_WRAPPER/DUT/inst/i_interlaken_gtwiz_userclk_rx_inst/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk_inst/O \
                       PCOAM_CORE/POMAA/PPIAA/U_IIPC_WRAPPER/DUT/inst/i_interlaken_gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk_inst/O \
                 ]

define_gt_pblock GT_U_TRANSCEIVER_LIU_CEI \
                 {X5Y8} \
                 [list PCOAM_CORE/PCFAA/CIFAA/U_TRANSCEIVER_LIU/U_GTX_IQ_TOP_CEI/u_gt_usrclk_source/rxoutclk_bufg1_i/O \
                       PCOAM_CORE/PCFAA/CIFAA/U_TRANSCEIVER_LIU/U_GTX_IQ_TOP_CEI/u_gt_usrclk_source/txoutclk_bufg0_i/O \
                       PCOAM_CORE/PCFAA/CIFAA/U_TRANSCEIVER_LIU/U_GTX_IQ_TOP_CEI/u_BUFG/O \
                       PCOAM_CORE/PCFAA/CIFAA/U_TRANSCEIVER_LIU/U_GTX_IQ_TOP_POI/u_BUFG/O \
                       PCOAM_CORE/PCFAA/CIFAA/U_TRANSCEIVER_LIU/U_GTX_IQ_TOP_POI/u_gt_usrclk_source/txoutclk_bufg0_i/O \
                       PCOAM_CORE/PCFAA/CIFAA/U_TRANSCEIVER_LIU/U_GTX_IQ_TOP_POI/u_gt_usrclk_source/rxoutclk_bufg1_i/O \
                 ]

# X5Y7 -> X3Y7 X5Y7
define_gt_pblock GT_U_TRANSCEIVER_LIU_PPI \
                 {X3Y7 X5Y7} \
                 [list PCOAM_CORE/PCFAA/CIFAA/U_TRANSCEIVER_LIU/U_GTX_IQ_TOP_PPI/u_gt_usrclk_source/rxoutclk_bufg1_i/O \
                       PCOAM_CORE/PCFAA/CIFAA/U_TRANSCEIVER_LIU/U_GTX_IQ_TOP_PPI/u_gt_usrclk_source/txoutclk_bufg0_i/O \
                       PCOAM_CORE/PCFAA/CIFAA/U_TRANSCEIVER_LIU/U_GTX_IQ_TOP_PPI/u_BUFG/O \
                 ]

# X5Y5 -> X4Y5 X5Y6
define_gt_pblock GT_TENGIGETH_PCSPMA \
                 {X4Y5 X5Y6} \
                 [list PCOAM_CORE/PCFAA/POLAA/TTIAA/U0_TTI2TENGIG/ten_gig_eth_pcs_pma_core_support_layer_i/ten_gig_eth_pcs_pma_i_inst[2].ten_gig_eth_pcs_pma_i/inst/ten_gig_kr_v6_0_local_clock_reset_block/rxoutclk_bufg_gt_i/O \
                       PCOAM_CORE/PCFAA/POLAA/TTIAA/U0_TTI2TENGIG/ten_gig_eth_pcs_pma_core_support_layer_i/ten_gig_eth_pcs_pma_i_inst[2].ten_gig_eth_pcs_pma_i/inst/ten_gig_kr_v6_0_local_clock_reset_block/rxusrclk2_bufg_gt_i/O \
                       PCOAM_CORE/PCFAA/POLAA/TTIAA/U0_TTI2TENGIG/ten_gig_eth_pcs_pma_core_support_layer_i/ten_gig_eth_pcs_pma_shared_clock_reset_block/txusrclk2_bufg_gt_i/O \
                       PCOAM_CORE/PCFAA/POLAA/TTIAA/U0_TTI2TENGIG/ten_gig_eth_pcs_pma_core_support_layer_i/ten_gig_eth_pcs_pma_shared_clock_reset_block/txoutclk_bufg_gt_i/O \
                       \
                       PCOAM_CORE/PCFAA/POLAA/TTIAA/U0_TTI2TENGIG/ten_gig_eth_pcs_pma_core_support_layer_i/ten_gig_eth_pcs_pma_i_inst[0].ten_gig_eth_pcs_pma_i/inst/ten_gig_kr_v6_0_local_clock_reset_block/rxoutclk_bufg_gt_i/O \
                       PCOAM_CORE/PCFAA/POLAA/TTIAA/U0_TTI2TENGIG/ten_gig_eth_pcs_pma_core_support_layer_i/ten_gig_eth_pcs_pma_i_inst[0].ten_gig_eth_pcs_pma_i/inst/ten_gig_kr_v6_0_local_clock_reset_block/rxusrclk2_bufg_gt_i/O \
                       PCOAM_CORE/PCFAA/POLAA/TTIAA/U0_TTI2TENGIG/ten_gig_eth_pcs_pma_core_support_layer_i/ten_gig_eth_pcs_pma_i_inst[1].ten_gig_eth_pcs_pma_i/inst/ten_gig_kr_v6_0_local_clock_reset_block/rxoutclk_bufg_gt_i/O \
                       PCOAM_CORE/PCFAA/POLAA/TTIAA/U0_TTI2TENGIG/ten_gig_eth_pcs_pma_core_support_layer_i/ten_gig_eth_pcs_pma_i_inst[1].ten_gig_eth_pcs_pma_i/inst/ten_gig_kr_v6_0_local_clock_reset_block/rxusrclk2_bufg_gt_i/O \
                 ]

define_gt_pblock GT_13L_12G5_INTERLAKEN \
                 {X4Y11 X5Y14} \
                 [list PCOAM_CORE/POMAA/AIFAA/U_ARAD_IIPC_WRAPPER/U1_xilinx_13L_12g5_interlaken_top/i_TRANSCEIVER_WRAPPER/inst/gen_gtwizard_gthe3_top.TRANSCEIVER_WRAPPER_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_tx_user_clocking_internal.gen_single_instance.gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk_inst/O \
                       PCOAM_CORE/POMAA/AIFAA/U_ARAD_IIPC_WRAPPER/U1_xilinx_13L_12g5_interlaken_top/i_TRANSCEIVER_WRAPPER/inst/gen_gtwizard_gthe3_top.TRANSCEIVER_WRAPPER_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_tx_user_clocking_internal.gen_single_instance.gtwiz_userclk_tx_inst/gen_gtwiz_userclk_tx_main.bufg_gt_usrclk2_inst/O \
                       PCOAM_CORE/POMAA/AIFAA/U_ARAD_IIPC_WRAPPER/U1_xilinx_13L_12g5_interlaken_top/i_TRANSCEIVER_WRAPPER/inst/gen_gtwizard_gthe3_top.TRANSCEIVER_WRAPPER_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_rx_user_clocking_internal.gen_single_instance.gtwiz_userclk_rx_inst/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk2_inst/O \
                       PCOAM_CORE/POMAA/AIFAA/U_ARAD_IIPC_WRAPPER/U1_xilinx_13L_12g5_interlaken_top/i_TRANSCEIVER_WRAPPER/inst/gen_gtwizard_gthe3_top.TRANSCEIVER_WRAPPER_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_rx_user_clocking_internal.gen_single_instance.gtwiz_userclk_rx_inst/gen_gtwiz_userclk_rx_main.bufg_gt_usrclk_inst/O \
                 ]


define_gt_pblock GT_PCIE_PCFAA_CIFAA_1 \
                 {X5Y9} \
                 [list PCOAM_CORE/PCFAA/CIFAA/PCEAB/pcie3_ultra_pcf/inst/bufg_gt_sysclk/O \
                 ]

# X5Y9 -> X4Y8 X5Y9
define_gt_pblock GT_PCIE_PCFAA_CIFAA_2 \
                 {X4Y8 X5Y9} \
                 [list PCOAM_CORE/PCFAA/CIFAA/PCEAB/pcie3_ultra_pcf/inst/gt_top_i/bufg_mcap_clk/O \
                       PCOAM_CORE/PCFAA/CIFAA/PCEAB/pcie3_ultra_pcf/inst/gt_top_i/phy_clk_i/bufg_gt_pclk/O \
                       PCOAM_CORE/PCFAA/CIFAA/PCEAB/pcie3_ultra_pcf/inst/gt_top_i/phy_clk_i/bufg_gt_userclk/O \
                       PCOAM_CORE/PCFAA/CIFAA/PCEAB/pcie3_ultra_pcf/inst/gt_top_i/phy_clk_i/bufg_gt_coreclk/O \
                 ]

define_gt_pblock GT_PCIE_POMAA_OAMAA_1 \
                 {X5Y10} \
                 [list PCOAM_CORE/POMAA/OAMAA/PCEAA/pcie3_ultra_pom/inst/bufg_gt_sysclk/O \
                 ]

# X5Y10 -> X4Y10 X5Y11
define_gt_pblock GT_PCIE_POMAA_OAMAA_2 \
                 {X4Y10 X5Y11} \
                 [list PCOAM_CORE/POMAA/OAMAA/PCEAA/pcie3_ultra_pom/inst/gt_top_i/bufg_mcap_clk/O \
                       PCOAM_CORE/POMAA/OAMAA/PCEAA/pcie3_ultra_pom/inst/gt_top_i/phy_clk_i/bufg_gt_pclk/O \
                       PCOAM_CORE/POMAA/OAMAA/PCEAA/pcie3_ultra_pom/inst/gt_top_i/phy_clk_i/bufg_gt_userclk/O \
                       PCOAM_CORE/POMAA/OAMAA/PCEAA/pcie3_ultra_pom/inst/gt_top_i/phy_clk_i/bufg_gt_coreclk/O \
                 ]

# X5Y6 -> X4Y6 X5Y6
define_gt_pblock GT_PCFAA_CIFAA_UMIAA \
                 {X4Y6 X5Y6} \
                 [list PCOAM_CORE/PCFAA/CIFAA/UMIAA/U0_TRANSCEIVER/U_GTX_IQ_TOP/u_gt_usrclk_source/rxoutclk_bufg1_i/O \
                       PCOAM_CORE/PCFAA/CIFAA/UMIAA/U0_TRANSCEIVER/U_GTX_IQ_TOP/u_gt_usrclk_source/txoutclk_bufg0_i/O \
                       PCOAM_CORE/PCFAA/CIFAA/UMIAA/U0_TRANSCEIVER/U_GTX_IQ_TOP/u_BUFG/O \
                       PCOAM_CORE/PCFAA/CIFAA/UMIAA/U1_TRANSCEIVER/U_GTX_IQ_TOP/u_gt_usrclk_source/rxoutclk_bufg1_i/O \
                       PCOAM_CORE/PCFAA/CIFAA/UMIAA/U1_TRANSCEIVER/U_GTX_IQ_TOP/u_gt_usrclk_source/txoutclk_bufg0_i/O \
                       PCOAM_CORE/PCFAA/CIFAA/UMIAA/U1_TRANSCEIVER/U_GTX_IQ_TOP/u_BUFG/O \
                 ]



#############################################################################
#############################################################################
#############################################################################

set ::DEBUG 1

proc max {x y} {expr {$x>$y?$x:$y}}
proc min {x y} {expr {$x<$y? $x:$y}}

proc expandClockRegions { pattern } {
  if {[regexp {^X(\d*)Y(\d*)$} $pattern]} {
    # Single clock region
    return $pattern
  }
  if {[regexp {^X(\d*)Y(\d*)\:X(\d*)Y(\d*)$} $pattern - Xmin Ymin Xmax Ymax]} {
    # Range of clock regions
#     puts "$Xmin $Ymin $Xmax $Ymax"
    set regions [list]
    for { set X [min $Xmin $Xmax] } { $X <= [max $Xmin $Xmax] } { incr X } {
      for { set Y [min $Ymin $Ymax] } { $Y <= [max $Ymin $Ymax] } { incr Y } {
        lappend regions "X${X}Y${Y}"
      }
    }
    return $regions
  }
  # Unrecognized pattern
  return $pattern
}

# define_laguna_pblock LAGUNA1 \
#                  {X0Y4 X1Y4} \
#                  laguna1 \
#                  [list ilk_c2ce_in_mid_1/dataout_r_reg[*] \
#                        ilk_c2ce_in_mid_2/dataout_r_reg[*] \
#                  ]
#
# define_laguna_pblock LAGUNA2 \
#                  {X2Y4 X3Y4} \
#                  laguna2 \
#                  [list ilk_c2ce_in_mid_1/dataout_r_reg[*] \
#                        ilk_c2ce_in_mid_2/dataout_r_reg[*] \
#                  ]
#
# define_laguna_pblock LAGUNA1 {X0Y4} laguna1 {module}
# define_laguna_pblock LAGUNA2 {X0Y4} laguna2 {module}
proc define_laguna_pblock { name clockRegions {type clockregion} { cells {} } } {
  set clock_regions [get_clock_regions [expandClockRegions $clockRegions] ]
  set pblocks [get_pblocks]
  set CMD {}
  if {[lsearch -exact $pblocks $name] == -1} {
    append CMD [format "create_pblock $name"]
#     append CMD [format "\nresize_pblock $name"]
    switch $type {
      clockregion {
        foreach CR $clock_regions {
#           append CMD [format " -add {CLOCKREGION_%s}" $CR ]
          append CMD [format "\n"]
          append CMD [format "resize_pblock $name -add {CLOCKREGION_%s}" $CR ]
        }
      }
      laguna {
        foreach CR $clock_regions {
          set sites [lsort [get_sites -of [get_tiles -of [get_clock_regions $CR] -filter {NAME =~ LAGUNA*}]] ]
          regexp {X(\d*)Y(\d*)} [lindex $sites 0] - minx miny
          regexp {X(\d*)Y(\d*)} [lindex $sites end] - maxx maxy
#           append CMD [format "\n"]
#           append CMD [format { -add [get_sites -of [get_clock_regions {%s}] -filter {NAME =~ LAGUNA*}]} $CR ]
#           append CMD [format {resize_pblock %s -add [get_sites -of [get_clock_regions {%s}] -filter {NAME =~ LAGUNA*}]} $name $CR ]
          append CMD [format "\n"]
          append CMD [format {resize_pblock %s -add {LAGUNA_X%sY%s:LAGUNA_X%sY%s}} $name [min $minx $maxx] [min $miny $maxy] [max $minx $maxx] [max $miny $maxy] ]
        }
      }
      laguna1 {
        foreach CR $clock_regions {
#           set tiles [lsort [get_tiles -of [get_clock_regions $CR] -filter {NAME =~ LAGUNA*}]]
          set sites [lsort [get_sites -of [get_tiles -of [get_clock_regions $CR] -filter {NAME =~ LAGUNA*}]] ]
          regexp {X(\d*)Y(\d*)} [lindex $sites 0] - minx miny
          regexp {X(\d*)Y(\d*)} [lindex $sites end] - maxx maxy
#           append CMD [format { -add [get_sites -of [get_tiles -of [get_clock_regions {%s}] -filter {NAME =~ LAGUNA_TILE_X%sY*}] ]} $CR $minx ]
#           append CMD [format "\n"]
#           append CMD [format {resize_pblock %s -add [get_sites -of [get_tiles -of [get_clock_regions {%s}] -filter {NAME =~ LAGUNA_TILE_X%sY*}] ]} $name $CR [min $minx $maxx] ]
          append CMD [format "\n"]
          append CMD [format {resize_pblock %s -add {LAGUNA_X%sY%s:LAGUNA_X%sY%s}} $name [min $minx $maxx] [min $miny $maxy] [min $minx $maxx] [max $miny $maxy] ]
        }
      }
      laguna2 {
        foreach CR $clock_regions {
#           set tiles [lsort [get_tiles -of [get_clock_regions $CR] -filter {NAME =~ LAGUNA*}]]
          set sites [lsort [get_sites -of [get_tiles -of [get_clock_regions $CR] -filter {NAME =~ LAGUNA*}]] ]
          regexp {X(\d*)Y(\d*)} [lindex $sites 0] - minx miny
          regexp {X(\d*)Y(\d*)} [lindex $sites end] - maxx maxy
#           append CMD [format { -add [get_sites -of [get_tiles -of [get_clock_regions {%s}] -filter {NAME =~ LAGUNA_TILE_X%sY*}] ]} $CR $maxx ]
#           append CMD [format "\n"]
#           append CMD [format {resize_pblock %s -add [get_sites -of [get_tiles -of [get_clock_regions {%s}] -filter {NAME =~ LAGUNA_TILE_X%sY*}] ]} $name $CR [max $minx $maxx] ]
          append CMD [format "\n"]
          append CMD [format {resize_pblock %s -add {LAGUNA_X%sY%s:LAGUNA_X%sY%s}} $name [max $minx $maxx] [min $miny $maxy] [max $minx $maxx] [max $miny $maxy] ]
        }
      }
      default {
        puts " -E- unknown type '$type'"
      }
    }
  }
  set collectionResultDisplayLimit [get_param tcl.collectionResultDisplayLimit]
  set_param tcl.collectionResultDisplayLimit 0
  foreach cell $cells {
    append CMD "\n"
    append CMD [format {add_cells_to_pblock [get_pblocks %s] [get_cells {%s}]} $name $cell ]
#     set filter [format {get_cells -quiet -of [get_pins -quiet -leaf -of [get_nets -quiet -of [get_pins -quiet %s]] -filter {(DIRECTION == IN) && ((REF_NAME =~ FD*) || (REF_NAME =~ SRL*) || (REF_NAME =~ RAMB*))}] -filter {PRIMITIVE_LEVEL == LEAF}} $pin ]
#     set cells [eval $filter]
#     if {[llength $cells] == 0} {
#       append CMD [format "\n# Loads (FD*/SRL*/RAMB*): %s" [llength $cells] ]
#       append CMD [format "\n# add_cells_to_pblock $name \[%s\]" $filter]
#     } else {
#       append CMD [format "\n# Loads (FD*/SRL*/RAMB*): %s" [llength $cells] ]
#       append CMD [format "\nadd_cells_to_pblock $name \[%s\]" $filter]
#     }
  }
  puts [format {
################################ PBLOCK DEFINITION ################################
%s
###################################################################################
} $CMD ]
  if {$::DEBUG == 0} {
#     eval $CMD
  }

  puts $CMD
  set_param tcl.collectionResultDisplayLimit $collectionResultDisplayLimit
  return -code ok
#   return $CMD
}


#############################################################################
#############################################################################
#############################################################################

#############################################################################
#############################################################################
#############################################################################

#############################################################################
#############################################################################
#############################################################################


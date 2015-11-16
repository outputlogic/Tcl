
# Proc to reload current script
proc [file tail [info script]] {} " source [info script]; puts \" [info script] reloaded\" "



# This proc transform an instance or pin into a list of:
#  mode = {} : list of local instance name
#  mode = ref_name : list of ref_names
#  mode = orig_ref_name : list of orig_ref_name
# E.g:
#  vivado% splitHierPath gen_obelix_100gtr[2].inst_obelix_100gtr_top/i_ln_top_defec_rs_320/i_top_decoder_rs/i_rs_decoder/core_g[6].core_b.i_error_corr/core_err_a_g[1].i_reg_err_a_0/DT_OUT_reg[7]
#  {gen_obelix_100gtr[2].inst_obelix_100gtr_top} i_ln_top_defec_rs_320 i_top_decoder_rs i_rs_decoder {core_g[6].core_b.i_error_corr} {core_err_a_g[1].i_reg_err_a_0} {DT_OUT_reg[7]}
#
#  vivado% splitHierPath gen_obelix_100gtr[2].inst_obelix_100gtr_top/i_ln_top_defec_rs_320/i_top_decoder_rs/i_rs_decoder/core_g[6].core_b.i_error_corr/core_err_a_g[1].i_reg_err_a_0/DT_OUT_reg[7] ref_name
#  obelix_100gtr_top__parameterized3 top_defec_rs_320_2647 top_decoder_320_2954 rs_decoder_320_2955 error_corr_320_3004 REG8FEC_3199 FDRE
#
#  vivado% splitHierPath gen_obelix_100gtr[2].inst_obelix_100gtr_top/i_ln_top_defec_rs_320/i_top_decoder_rs/i_rs_decoder/core_g[6].core_b.i_error_corr/core_err_a_g[1].i_reg_err_a_0/DT_OUT_reg[7] orig_ref_name
#  obelix_100gtr_top top_defec_rs_320 top_decoder_320 rs_decoder_320 error_corr_320 REG8FEC FDRE

proc splitHierPath {name {mode {}}} {
  set name [lindex $name 0]
  set pin [get_pins -quiet $name]
  if {$pin != {}} {
    # If a pin is specified as input, then keep track of the pin name
    # to build the first string that will be pushed on the lists
    set cell [get_cell -of $pin]
    set pin [get_property -quiet REF_PIN_NAME $pin]
  } else {
    set cell $name
    set pin {}
  }
  set iter 0
  # 3 lists are built. The $mode select which one is returned
  set localNames [list]
  set refNames [list]
  set origRefNames [list]
  while {1} {
    set obj [get_cells -quiet $cell]
    if {$obj == {}} {
      break
    }
    set parent [get_property -quiet PARENT $obj]
    set refName [get_property -quiet REF_NAME $obj]
    set origRefName [get_property -quiet ORIG_REF_NAME $obj]
    if {$parent != {}} {
      set leaf [string replace $obj 0 [string length $parent] {}]
    } else {
      set leaf $obj
    }
    if {$pin != {}} {
      lappend localNames $pin
      lappend refNames $pin
      lappend origRefNames $pin
#       append leaf "/$pin"
#       append refName "/$pin"
#       if {$origRefName != {}} {
#         append origRefName "/$pin"
#       }
      set pin {}
    }
    lappend localNames $leaf
    lappend refNames $refName
    if {$origRefName != {}} {
      lappend origRefNames $origRefName
    } else {
      lappend origRefNames $refName
    }
    incr iter
    set cell $parent
  }
  switch [string tolower $mode] {
    ref_name {
      return [lreverse $refNames]
    }
    orig_ref_name {
      return [lreverse $origRefNames]
    }
    default {
      return [lreverse $localNames]
    }
  }
}


# The proc below select/highlight cells that are part of critical paths between 2 clock domains
proc highlight_critical_cells_between_clk_domains {clk1 clk2 {num 10}} {
  set clk1 [get_clocks $clk1]
  set clk2 [get_clocks $clk2]
  set paths [get_timing_paths -from $clk1 -to $clk2 -delay_type max -slack_lesser_than 0 -max_paths $num -nworst 1]
  set cells [get_cells [lsort -unique [get_cells -of $paths]]]
  puts "#cells: [llength $cells]"
  highlight_objects $cells
  select_object $cells
  return 0
}

# The proc below select/highlight cells that are part of critical paths in the design
proc highlight_critical_cells {{num 10}} {
  set paths [get_timing_paths -delay_type max -slack_lesser_than 0 -max_paths $num -nworst 1]
  set cells [get_cells [lsort -unique [get_cells -of $paths]]]
  puts "#cells: [llength $cells]"
  highlight_objects $cells
  select_object $cells
  return 0
}


proc dist_sites { site1 site2 } {
 set site1 [get_sites -quiet $site1]
 set site2 [get_sites -quiet $site2]
 if {($site1 == {}) || ($site2 == {})} {
   error " error - empty site(s)"
 }
 set RPM_X1 [get_property -quiet RPM_X $site1]
 set RPM_Y1 [get_property -quiet RPM_Y $site1]
 set RPM_X2 [get_property -quiet RPM_X $site2]
 set RPM_Y2 [get_property -quiet RPM_Y $site2]
 set distance [format {%.2f} [expr sqrt( pow(double($RPM_X1) - double($RPM_X2), 2) + pow(double($RPM_Y1) - double($RPM_Y2), 2) )] ]
 return $distance
}

proc dist_cells { cell1 cell2 } {
 set cell1 [get_cells -quiet $cell1]
 set cell2 [get_cells -quiet $cell2]
 if {($cell1 == {}) || ($cell2 == {})} {
   error " error - empty cells(s)"
 }
 set site1 [get_property -quiet SITE $cell1]
 set site2 [get_property -quiet SITE $cell2]
 if {($site1 == {}) || ($site2 == {})} {
   error " error - unplaced cells(s)"
 }
 return [dist_sites $site1 $site2]
}

# +-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
# | {u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/N_Offset_RAM_reg/CLKBWRCLK --> u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/Rd_Pipe_reg[3][N_Val][20]/D}                                                                                                                                                                                                                  |
# | Startpoint : u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/N_Offset_RAM_reg/CLKBWRCLK                                                                                                                                                                                                                                                                                                                                 |
# | Endpoint : u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/Rd_Pipe_reg[3][N_Val][20]/D                                                                                                                                                                                                                                                                                                                                  |
# | Slack: -0.809                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
# +-----------------------------------------------------------------------------------------------------------------------------+-------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------------------------------------------------------------------+-------------------+----------------+------------+--------+------------+
# | Net                                                                                                                         | Driver                                                                                                                        | Receiver                                                                                                                    | Driver Incr Delay | Net Incr Delay | Net Length | Fanout | Delay Type |
# +-----------------------------------------------------------------------------------------------------------------------------+-------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------------------------------------------------------------------+-------------------+----------------+------------+--------+------------+
# | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/N_Offset_Out_d1[2]                | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/N_Offset_RAM_reg/DOBDO[2]           | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/Rd_Pipe[3][N_Val][3]_i_3/I1       | 0.622             | 2.523          | 95.21      | 1      | estimated  |
# | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/n_0_Rd_Pipe[3][N_Val][3]_i_3      | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/Rd_Pipe[3][N_Val][3]_i_3/O          | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/Rd_Pipe_reg[3][N_Val][3]_i_1/S[2] | 0.043             | 0.000          | 0.00       | 1      | routed     |
# | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/n_0_Rd_Pipe_reg[3][N_Val][3]_i_1  | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/Rd_Pipe_reg[3][N_Val][3]_i_1/CO[3]  | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/Rd_Pipe_reg[3][N_Val][7]_i_1/CI   | 0.195             | 0.000          | 2.00       | 1      | estimated  |
# | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/n_0_Rd_Pipe_reg[3][N_Val][7]_i_1  | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/Rd_Pipe_reg[3][N_Val][7]_i_1/CO[3]  | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/Rd_Pipe_reg[3][N_Val][11]_i_1/CI  | 0.053             | 0.000          | 2.00       | 1      | estimated  |
# | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/n_0_Rd_Pipe_reg[3][N_Val][11]_i_1 | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/Rd_Pipe_reg[3][N_Val][11]_i_1/CO[3] | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/Rd_Pipe_reg[3][N_Val][15]_i_1/CI  | 0.053             | 0.000          | 2.00       | 1      | estimated  |
# | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/n_0_Rd_Pipe_reg[3][N_Val][15]_i_1 | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/Rd_Pipe_reg[3][N_Val][15]_i_1/CO[3] | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/Rd_Pipe_reg[3][N_Val][19]_i_1/CI  | 0.053             | 0.000          | 2.00       | 1      | estimated  |
# | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/n_0_Rd_Pipe_reg[3][N_Val][19]_i_1 | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/Rd_Pipe_reg[3][N_Val][19]_i_1/CO[3] | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/Rd_Pipe_reg[3][N_Val][20]_i_1/CI  | 0.053             | 0.000          | 2.00       | 1      | estimated  |
# | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/n_7_Rd_Pipe_reg[3][N_Val][20]_i_1 | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/Rd_Pipe_reg[3][N_Val][20]_i_1/O[0]  | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/Rd_Pipe_reg[3][N_Val][20]/D       | 0.111             | 0.000          | 0.00       | 1      | routed     |
# +-----------------------------------------------------------------------------------------------------------------------------+-------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------------------------------------------------------------------+-------------------+----------------+------------+--------+------------+
# Total path length: 105.21

# +--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
# | {u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/u_crc32_40byte_top/crc_reg_default_reg/C --> u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/u_crc32_40byte_top/u_crc32_40byte_bit27/crc_reg_out_reg/D}                                                                                                                                                                                                                                           |
# | Startpoint : u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/u_crc32_40byte_top/crc_reg_default_reg/C                                                                                                                                                                                                                                                                                                                                                                     |
# | Endpoint : u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/u_crc32_40byte_top/u_crc32_40byte_bit27/crc_reg_out_reg/D                                                                                                                                                                                                                                                                                                                                                      |
# | Slack: -0.779                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
# +-----------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------+----------------------------------------------------------------------------------------------------------------------------------------+-------------------+----------------+------------+--------+------------+
# | Net                                                                                                                                     | Driver                                                                                                                                | Receiver                                                                                                                               | Driver Incr Delay | Net Incr Delay | Net Length | Fanout | Delay Type |
# +-----------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------+----------------------------------------------------------------------------------------------------------------------------------------+-------------------+----------------+------------+--------+------------+
# | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/u_crc32_40byte_top/u_crc32_40byte_bit14/I1                       | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/u_crc32_40byte_top/crc_reg_default_reg/Q                       | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/u_crc32_40byte_top/u_crc32_40byte_bit14/crc_reg_out_i_23__2/I1  | 0.259             | 0.536          | 15.62      | 42     | estimated  |
# | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/crc_reg_new[14]                                                  | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/u_crc32_40byte_top/u_crc32_40byte_bit14/crc_reg_out_i_23__2/O  | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/crc_reg_out_i_8__56/I3                                          | 0.043             | 2.216          | 63.15      | 23     | estimated  |
# | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/n_0_crc_reg_out_i_8__56                                          | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/crc_reg_out_i_8__56/O                                          | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/crc_reg_out_i_2__58/I4                                          | 0.043             | 0.324          | 2.83       | 1      | estimated  |
# | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/u_crc32_40byte_top/u_crc32_40byte_bit27/I744                     | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/crc_reg_out_i_2__58/O                                          | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/u_crc32_40byte_top/u_crc32_40byte_bit27/crc_reg_out_i_1__122/I0 | 0.043             | 0.340          | 6.00       | 1      | estimated  |
# | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/u_crc32_40byte_top/u_crc32_40byte_bit27/n_0_crc_reg_out_i_1__122 | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/u_crc32_40byte_top/u_crc32_40byte_bit27/crc_reg_out_i_1__122/O | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/u_crc32_40byte_top/u_crc32_40byte_bit27/crc_reg_out_reg/D       | 0.043             | 0.000          | 0.00       | 1      | routed     |
# +-----------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------+----------------------------------------------------------------------------------------------------------------------------------------+-------------------+----------------+------------+--------+------------+
# Total path length: 87.60

proc report_path_info { path } {
 package require toolbox
 if {($path == {})} {
   error " error - empty path"
 }
 set tbl [prettyTable $path]
 $tbl header [list {Net} {Driver} {Receiver} {Driver Incr Delay} {Net Incr Delay} {Net Length} {Fanout} {Delay Type} ]
 set data [get_path_info $path]
 set length 0.0
 set distances [list]
 foreach elm [lrange $data 0 end-1] {
   foreach {pindata netdata inputpinname} $elm { break }
#    puts "\n opin : $pindata"
#    puts " ipin : $inputpinname"
#    puts " net  : $netdata"
   foreach {pinname pinrisefall pinincrdelay pindelay} $pindata { break }
   foreach {netname netfanout nettype netincrdelay netdelay} $netdata { break }
   set distance [dist_cells [get_cells -quiet -of [get_pins -quiet $pinname]] [get_cells -quiet -of [get_pins -quiet $inputpinname]] ]
#    puts "  --> $netname : $distance"
   lappend distances $distance
   set length [expr $length + $distance]
   $tbl addrow [list $netname $pinname $inputpinname $pinincrdelay $netincrdelay $distance $netfanout $nettype ]
 }
 set length [format {%.2f} $length]
 set title [format "$path\nStartpoint : [get_property -quiet STARTPOINT_PIN $path]\nEndpoint : [get_property -quiet ENDPOINT_PIN $path]\nSlack: [get_property -quiet SLACK $path]"]
 $tbl configure -title $title
 puts [$tbl print]
 catch {$tbl destroy}
 puts "Total path length: $length"
 return 0
#  return [list $length $distances]
}

# vivado% report_path_summary [lrange $paths 0 10]
# +--------+-------------+-----------------+-----------------+------------------------+--------+--------+-------------+----------------+-------------------------------+-------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+----------------------------------------------------------------------------------------------------------------------------------+
# | Slack  | Requirement | Data Path Delay | Clock Path Skew | Clock Path Uncertainty | Levels | Fanout | Path Length | Max Net Length | Startpoint Clock              | Endpoint Clock                | Startpoint Pin                                                                                                                                                                                                                                                                                                                        | Datapath Startpoint Pin                                                                                                                                                                                                                                                                                                                | Endpoint Pin                                                                                                                     |
# +--------+-------------+-----------------+-----------------+------------------------+--------+--------+-------------+----------------+-------------------------------+-------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+----------------------------------------------------------------------------------------------------------------------------------+
# | -0.752 | 3.000       | 3.178           | -0.095          | 0.063                  | 0      | 8      | 267.75      | 267.75         | clk_out2_pll_map_clk          | clk_out2_pll_map_clk          | u_clt_to_bk_top0/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/SG/Traffic_Wr_Addr_reg[4][2]/C                                                                                                                                                                                                                 | u_clt_to_bk_top0/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/SG/Traffic_Wr_Addr_reg[4][2]/Q                                                                                                                                                                                                                  | u_clt_to_bk_top0/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/SG/G1[3].Traffic_RAM_reg_7/ADDRARDADDR[4] |
# | -0.750 | 3.199       | 3.878           | 0.033           | 0.138                  | 3      | 1      | 130.44      | 88.02          | clk_out2_pll_clt_os_loop_clk  | clk_out2_pll_clt_os_loop_clk  | u_clt_to_bk_top0/u_pcs_mac_top/u_rx_mac_monitor_top/u_process_40byte_1/u_crc32_40byte_top/u_crc32_40byte_bit21/crc_cin_index_choose_reg[5]/C                                                                                                                                                                                          | u_clt_to_bk_top0/u_pcs_mac_top/u_rx_mac_monitor_top/u_process_40byte_1/u_crc32_40byte_top/u_crc32_40byte_bit21/crc_cin_index_choose_reg[5]/Q                                                                                                                                                                                           | u_clt_to_bk_top0/u_pcs_mac_top/u_rx_mac_monitor_top/u_process_40byte_1/u_crc32_40byte_top/u_crc32_40byte_bit21/crc_reg_out_reg/D |
# | -0.750 | 3.000       | 3.059           | -0.155          | 0.063                  | 4      | 5      | 90.93       | 84.10          | clk_out2_pll_map_clk          | clk_out2_pll_map_clk          | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/BA/B1.Pipe_reg[2][Rate_N][14]/C                                                                                                                                                                                                                | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/BA/B1.Pipe_reg[2][Rate_N][14]/Q                                                                                                                                                                                                                 | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/BA/B1.Rate_RAM_reg_64_127_21_21/DP/I      |
# | -0.747 | 3.200       | 3.788           | -0.172          | 0.051                  | 3      | 1      | 111.42      | 60.00          | clk_out2_pll_clt_is_loop_clk  | clk_out2_pll_clt_is_loop_clk  | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_1/u_crc32_40byte_top/u_crc32_40byte_bit14/crc_din_xor5_reg/C                                                                                                                                                                                                     | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_1/u_crc32_40byte_top/u_crc32_40byte_bit14/crc_din_xor5_reg/Q                                                                                                                                                                                                      | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_1/u_crc32_40byte_top/u_crc32_40byte_bit14/crc_reg_out_reg/D |
# | -0.747 | 3.199       | 3.865           | -0.001          | 0.138                  | 3      | 3      | 99.33       | 91.08          | clk_out2_pll_clt_os_loop_clk  | clk_out2_pll_clt_os_loop_clk  | u_clt_to_bk_top0/u_pcs_mac_top/u_rx_mac_monitor_top/u_datawidth_change/u_fifo_change_width/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgc.ngecc.bmg/inst_blk_mem_gen/gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[13].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.SIMPLE_PRIM36.ram/CLKBWRCLK | u_clt_to_bk_top0/u_pcs_mac_top/u_rx_mac_monitor_top/u_datawidth_change/u_fifo_change_width/U0/inst_fifo_gen/gconvfifo.rf/grf.rf/gntv_or_sync_fifo.mem/gbm.gbmg.gbmgc.ngecc.bmg/inst_blk_mem_gen/gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[13].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.SDP.SIMPLE_PRIM36.ram/DOPBDOP[1] | u_clt_to_bk_top0/u_pcs_mac_top/u_rx_mac_monitor_top/u_mac_process_control/preamble_sfd_flag_reg[1]/D                             |
# | -0.746 | 3.200       | 3.955           | 0.031           | 0.056                  | 4      | 42     | 80.39       | 52.35          | clk_out2_mmcm_clt_is_loop_clk | clk_out2_mmcm_clt_is_loop_clk | u_clt_to_bk_top1/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_1/u_crc32_40byte_top/crc_reg_default_reg/C                                                                                                                                                                                                                       | u_clt_to_bk_top1/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_1/u_crc32_40byte_top/crc_reg_default_reg/Q                                                                                                                                                                                                                        | u_clt_to_bk_top1/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_1/u_crc32_40byte_top/u_crc32_40byte_bit28/crc_reg_out_reg/D |
# | -0.745 | 5.999       | 6.076           | -0.284          | 0.068                  | 1      | 22     | 162.08      | 152.08         | clk_out1_pll_map_clk          | clk_out1_pll_map_clk          | u_clt_to_bk_top0/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/SGC/SA4/Res_int_reg/CLK                                                                                                                                                                                                                        | u_clt_to_bk_top0/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/SGC/SA4/Res_int_reg/P[24]                                                                                                                                                                                                                       | u_clt_to_bk_top0/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/Pipe_6_Ptr_Err_Sq_reg/B[12]               |
# | -0.745 | 5.999       | 6.076           | -0.284          | 0.068                  | 1      | 22     | 162.08      | 152.08         | clk_out1_pll_map_clk          | clk_out1_pll_map_clk          | u_clt_to_bk_top0/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/SGC/SA4/Res_int_reg/CLK                                                                                                                                                                                                                        | u_clt_to_bk_top0/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/SGC/SA4/Res_int_reg/P[24]                                                                                                                                                                                                                       | u_clt_to_bk_top0/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/Pipe_6_Ptr_Err_Sq_reg/B[16]               |
# | -0.744 | 3.403       | 3.636           | -0.280          | 0.048                  | 0      | 2      | 240.88      | 240.88         | clk_out1_pll_ink_clk          | clk_out1_pll_ink_clk          | u_clt_to_bk_top0/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/SG/G1[7].Traffic_RAM_reg_2/CLKBWRCLK                                                                                                                                                                                                           | u_clt_to_bk_top0/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/SG/G1[7].Traffic_RAM_reg_2/DOBDO[3]                                                                                                                                                                                                             | u_clt_to_bk_top0/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/SG/Rd_Barrel_reg_0/DIBDI[3]               |
# +--------+-------------+-----------------+-----------------+------------------------+--------+--------+-------------+----------------+-------------------------------+-------------------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+----------------------------------------------------------------------------------------------------------------------------------+

proc report_path_summary { paths } {
  set debug 0
  package require toolbox
  set tbl [prettyTable]
  $tbl header [list {Slack} {Requirement} {Data Path Delay} {Clock Path Skew} {Clock Path Uncertainty} \
                    {Levels} {Fanout} {Path Length} {Max Net Length} \
                    {Startpoint Clock} {Endpoint Clock} {Startpoint Pin} {Datapath Startpoint Pin} {Endpoint Pin} ]

  foreach path $paths {
    if {$debug} {
      puts "\nPATH: $path"
    }
    set data [get_path_info $path]
    set pathLength 0.0
    set maxLength 0.0
    set maxFanout 0
    set datapathStartPin {}
    set first 1
    foreach elm [lrange $data 0 end-1] {
      foreach {pindata netdata inputpinname} $elm { break }
      if {$debug} {
        puts " opin : $pindata"
        puts " ipin : $inputpinname"
        puts " net  : $netdata"
      }
      foreach {pinname pinrisefall pinincrdelay pindelay} $pindata { break }
      foreach {netname netfanout nettype netincrdelay netdelay} $netdata { break }
      set distance [dist_cells [get_cells -quiet -of [get_pins -quiet $pinname]] [get_cells -quiet -of [get_pins -quiet $inputpinname]] ]
      set pathLength [format {%.2f} [expr $pathLength + $distance]]
      if {$distance > $maxLength} { set maxLength $distance }
      if {$netfanout > $maxFanout} { set maxFanout $netfanout }
      if {$distance > $maxLength} { set maxLength $distance }
      if {$debug} {
        puts "  --> $netname : $distance"
      }
      if {$first} { set datapathStartPin $pinname }
      set first 0
    }
    $tbl addrow [list \
                  [get_property -quiet {SLACK} $path] \
                  [get_property -quiet {REQUIREMENT} $path] \
                  [get_property -quiet {DATAPATH_DELAY} $path] \
                  [get_property -quiet {SKEW} $path] \
                  [get_property -quiet {UNCERTAINTY} $path] \
                  [get_property -quiet {LOGIC_LEVELS} $path] \
                  $maxFanout \
                  $pathLength \
                  $maxLength \
                  [get_property -quiet {STARTPOINT_CLOCK} $path] \
                  [get_property -quiet {ENDPOINT_CLOCK} $path] \
                  [get_property -quiet {STARTPOINT_PIN} $path] \
                  $datapathStartPin \
                  [get_property -quiet {ENDPOINT_PIN} $path] \
               ]
  }

#   set title [format "$path\nStartpoint : [get_property -quiet STARTPOINT_PIN $path]\nEndpoint : [get_property -quiet ENDPOINT_PIN $path]\nSlack: [get_property -quiet SLACK $path]"]
#   tbl configure -title $title
  puts [$tbl print]
  catch {$tbl destroy}

  return -code ok
}

# +----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
# | {u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/SG/G1[4].Traffic_RAM_reg_0/CLKBWRCLK --> u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/SG/Rd_Barrel_reg_5/DIBDI[2]}                                                                                                                                                                                         |
# | Startpoint : u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/SG/G1[4].Traffic_RAM_reg_0/CLKBWRCLK                                                                                                                                                                                                                                                                                                     |
# | Endpoint : u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/SG/Rd_Barrel_reg_5/DIBDI[2]                                                                                                                                                                                                                                                                                                                |
# | Slack: 0.041                                                                                                                                                                                                                                                                                                                                                                                                                                 |
# +------------------------------------------------------------------------------------------------------+------------------------------------------------------------------------------------------------------------------------------+--------------------------------------------------------------------------------------------------------------------+-------------------+----------------+-----------+------------+--------+------------+
# | Net                                                                                                  | Driver                                                                                                                       | Receiver                                                                                                           | Driver Incr Delay | Net Incr Delay | P2P Delay | Net Length | Fanout | Delay Type |
# +------------------------------------------------------------------------------------------------------+------------------------------------------------------------------------------------------------------------------------------+--------------------------------------------------------------------------------------------------------------------+-------------------+----------------+-----------+------------+--------+------------+
# | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/SG/p_25_in[0] | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/SG/G1[4].Traffic_RAM_reg_0/DOPBDOP[0] | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/SG/Rd_Barrel_reg_5/DIBDI[2] | 0.622             | 2.269          | 1526      | 144.37     | 2      | routed     |
# +------------------------------------------------------------------------------------------------------+------------------------------------------------------------------------------------------------------------------------------+--------------------------------------------------------------------------------------------------------------------+-------------------+----------------+-----------+------------+--------+------------+

# +--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
# | {u_clt_to_bk_top0/u_map_sar_oh_wrapper/map_sar_oh_i/otn_mapper_100ge_0/U0/map_100_cl_1/MP_tpcsm_lane0_reg_rep__0/C --> u_clt_to_bk_top0/u_map_sar_oh_wrapper/map_sar_oh_i/otn_mapper_100ge_0/U0/map_100_cl_1/MP/Pipe_reg[1][Data][19][4]/D}                                                                                                                                                                                                            |
# | Startpoint : u_clt_to_bk_top0/u_map_sar_oh_wrapper/map_sar_oh_i/otn_mapper_100ge_0/U0/map_100_cl_1/MP_tpcsm_lane0_reg_rep__0/C                                                                                                                                                                                                                                                                                                                         |
# | Endpoint : u_clt_to_bk_top0/u_map_sar_oh_wrapper/map_sar_oh_i/otn_mapper_100ge_0/U0/map_100_cl_1/MP/Pipe_reg[1][Data][19][4]/D                                                                                                                                                                                                                                                                                                                         |
# | Slack: -0.120                                                                                                                                                                                                                                                                                                                                                                                                                                          |
# +-----------------------------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------------------------+----------------------------------------------------------------------------------------------------------------------+-------------------+----------------+-----------+------------+--------+------------+
# | Net                                                                                                                   | Driver                                                                                                              | Receiver                                                                                                             | Driver Incr Delay | Net Incr Delay | P2P Delay | Net Length | Fanout | Delay Type |
# +-----------------------------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------------------------+----------------------------------------------------------------------------------------------------------------------+-------------------+----------------+-----------+------------+--------+------------+
# | u_clt_to_bk_top0/u_map_sar_oh_wrapper/map_sar_oh_i/otn_mapper_100ge_0/U0/map_100_cl_1/MP/I16                          | u_clt_to_bk_top0/u_map_sar_oh_wrapper/map_sar_oh_i/otn_mapper_100ge_0/U0/map_100_cl_1/MP_tpcsm_lane0_reg_rep__0/Q   | u_clt_to_bk_top0/u_map_sar_oh_wrapper/map_sar_oh_i/otn_mapper_100ge_0/U0/map_100_cl_1/MP/Pipe[1][Data][19][4]_i_1/I3 | 0.223             | 2.375          | 401       | 13.42      | 82     | routed     |
# | u_clt_to_bk_top0/u_map_sar_oh_wrapper/map_sar_oh_i/otn_mapper_100ge_0/U0/map_100_cl_1/MP/n_0_Pipe[1][Data][19][4]_i_1 | u_clt_to_bk_top0/u_map_sar_oh_wrapper/map_sar_oh_i/otn_mapper_100ge_0/U0/map_100_cl_1/MP/Pipe[1][Data][19][4]_i_1/O | u_clt_to_bk_top0/u_map_sar_oh_wrapper/map_sar_oh_i/otn_mapper_100ge_0/U0/map_100_cl_1/MP/Pipe_reg[1][Data][19][4]/D  | 0.043             | 0.000          | -         | 0.00       | 1      | routed     |
# +-----------------------------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------------------------+----------------------------------------------------------------------------------------------------------------------+-------------------+----------------+-----------+------------+--------+------------+

# +-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
# | {u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_1/u_crc32_40byte_top/u_crc32_40byte_bit12/crc_reg_out_reg/C --> u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_1/u_crc32_40byte_top/u_crc32_40byte_bit10/crc_reg_out_reg/D}                                                                                                                                                                                                                                   |
# | Startpoint : u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_1/u_crc32_40byte_top/u_crc32_40byte_bit12/crc_reg_out_reg/C                                                                                                                                                                                                                                                                                                                                                             |
# | Endpoint : u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_1/u_crc32_40byte_top/u_crc32_40byte_bit10/crc_reg_out_reg/D                                                                                                                                                                                                                                                                                                                                                               |
# | Slack: -0.216                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
# +----------------------------------------------------------------------------------------------------------------------------------------+--------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------+-------------------+----------------+-----------+------------+--------+------------+
# | Net                                                                                                                                    | Driver                                                                                                                               | Receiver                                                                                                                              | Driver Incr Delay | Net Incr Delay | P2P Delay | Net Length | Fanout | Delay Type |
# +----------------------------------------------------------------------------------------------------------------------------------------+--------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------+-------------------+----------------+-----------+------------+--------+------------+
# | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_1/u_crc32_40byte_top/u_crc32_40byte_bit12/crc_reg12               | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_1/u_crc32_40byte_top/u_crc32_40byte_bit12/crc_reg_out_reg/Q     | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_1/u_crc32_40byte_top/u_crc32_40byte_bit12/crc_reg_out_i_21__1/I0 | 0.259             | 0.807          | 774       | 51.22      | 12     | routed     |
# | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_1/crc_reg_new[12]                                                 | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_1/u_crc32_40byte_top/u_crc32_40byte_bit12/crc_reg_out_i_21__1/O | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_1/crc_reg_out_i_12__43/I1                                        | 0.043             | 0.913          | 872       | 59.67      | 23     | routed     |
# | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_1/n_0_crc_reg_out_i_12__43                                        | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_1/crc_reg_out_i_12__43/O                                        | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_1/crc_reg_out_i_3__43/I3                                         | 0.043             | 0.364          | 364       | 4.00       | 1      | routed     |
# | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_1/u_crc32_40byte_top/u_crc32_40byte_bit10/I633                    | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_1/crc_reg_out_i_3__43/O                                         | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_1/u_crc32_40byte_top/u_crc32_40byte_bit10/crc_reg_out_i_1__75/I1 | 0.043             | 0.758          | 752       | 50.60      | 1      | routed     |
# | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_1/u_crc32_40byte_top/u_crc32_40byte_bit10/n_0_crc_reg_out_i_1__75 | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_1/u_crc32_40byte_top/u_crc32_40byte_bit10/crc_reg_out_i_1__75/O | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_1/u_crc32_40byte_top/u_crc32_40byte_bit10/crc_reg_out_reg/D      | 0.043             | 0.000          | -         | 0.00       | 1      | routed     |
# +----------------------------------------------------------------------------------------------------------------------------------------+--------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------+-------------------+----------------+-----------+------------+--------+------------+

# +-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
# | {u_clt_to_bk_top0/u_interlaken_xil_top/u_interlaken_top/i_CORES/tmp_tx_chanin2[2]/C --> u_clt_to_bk_top0/u_interlaken_xil_top/u_interlaken_top/i_CORES/i_CORES/i_TX/i_TX/i_STRIPE/i_ADAPT/cache_eobin/D}                                                                                                                                                                                                                                                                                  |
# | Startpoint : u_clt_to_bk_top0/u_interlaken_xil_top/u_interlaken_top/i_CORES/tmp_tx_chanin2[2]/C                                                                                                                                                                                                                                                                                                                                                                                           |
# | Endpoint : u_clt_to_bk_top0/u_interlaken_xil_top/u_interlaken_top/i_CORES/i_CORES/i_TX/i_TX/i_STRIPE/i_ADAPT/cache_eobin/D                                                                                                                                                                                                                                                                                                                                                                |
# | Slack: -0.100                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
# +------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------------------------------------------------------------------------+------------------------------------------------------------------------------------------------------------------------------------+-------------------+----------------+-----------+------------+--------+------------+
# | Net                                                                                                                          | Driver                                                                                                                            | Receiver                                                                                                                           | Driver Incr Delay | Net Incr Delay | P2P Delay | Net Length | Fanout | Delay Type |
# +------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------------------------------------------------------------------------+------------------------------------------------------------------------------------------------------------------------------------+-------------------+----------------+-----------+------------+--------+------------+
# | u_clt_to_bk_top0/u_interlaken_xil_top/u_interlaken_top/i_CORES/i_CORES/i_TX/i_TX/i_STRIPE/i_ADAPT/tmp_tx_chanin2[2]          | u_clt_to_bk_top0/u_interlaken_xil_top/u_interlaken_top/i_CORES/tmp_tx_chanin2[2]/Q                                                | u_clt_to_bk_top0/u_interlaken_xil_top/u_interlaken_top/i_CORES/i_CORES/i_TX/i_TX/i_STRIPE/i_ADAPT/g0_22/I3                         | 0.259             | 0.372          | 356       | 2.00       | 5      | routed     |
# | u_clt_to_bk_top0/u_interlaken_xil_top/u_interlaken_top/i_CORES/i_CORES/i_TX/i_TX/i_STRIPE/i_ADAPT/g0_3                       | u_clt_to_bk_top0/u_interlaken_xil_top/u_interlaken_top/i_CORES/i_CORES/i_TX/i_TX/i_STRIPE/i_ADAPT/g0_22/O                         | u_clt_to_bk_top0/u_interlaken_xil_top/u_interlaken_top/i_CORES/i_CORES/i_TX/i_TX/i_STRIPE/i_ADAPT/g0_21/I4                         | 0.043             | 0.355          | 355       | 0.00       | 1      | routed     |
# | u_clt_to_bk_top0/u_interlaken_xil_top/u_interlaken_top/i_CORES/i_CORES/i_TX/i_TX/i_STRIPE/i_ADAPT/g0_5                       | u_clt_to_bk_top0/u_interlaken_xil_top/u_interlaken_top/i_CORES/i_CORES/i_TX/i_TX/i_STRIPE/i_ADAPT/g0_21/O                         | u_clt_to_bk_top0/u_interlaken_xil_top/u_interlaken_top/i_CORES/i_CORES/i_TX/i_TX/i_STRIPE/i_ADAPT/un20_is_bctlin_tmp_1_RNISV169/I1 | 0.043             | 0.887          | 886       | 18.44      | 1      | routed     |
# | u_clt_to_bk_top0/u_interlaken_xil_top/u_interlaken_top/i_CORES/i_CORES/i_TX/i_TX/i_STRIPE/i_ADAPT/bmax_count0_nxt20_1        | u_clt_to_bk_top0/u_interlaken_xil_top/u_interlaken_top/i_CORES/i_CORES/i_TX/i_TX/i_STRIPE/i_ADAPT/un20_is_bctlin_tmp_1_RNISV169/O | u_clt_to_bk_top0/u_interlaken_xil_top/u_interlaken_top/i_CORES/i_CORES/i_TX/i_TX/i_STRIPE/i_ADAPT/bmax_count0_nxt_4_sqmuxa_1/I4    | 0.043             | 0.337          | 293       | 2.00       | 24     | routed     |
# | u_clt_to_bk_top0/u_interlaken_xil_top/u_interlaken_top/i_CORES/i_CORES/i_TX/i_TX/i_STRIPE/i_ADAPT/bmax_count0_nxt_4_sqmuxa_1 | u_clt_to_bk_top0/u_interlaken_xil_top/u_interlaken_top/i_CORES/i_CORES/i_TX/i_TX/i_STRIPE/i_ADAPT/bmax_count0_nxt_4_sqmuxa_1/O    | u_clt_to_bk_top0/u_interlaken_xil_top/u_interlaken_top/i_CORES/i_CORES/i_TX/i_TX/i_STRIPE/i_ADAPT/bmax_count0_RNIF5U9A[3]/I5       | 0.043             | 0.214          | 188       | 2.00       | 13     | routed     |
# | u_clt_to_bk_top0/u_interlaken_xil_top/u_interlaken_top/i_CORES/i_CORES/i_TX/i_TX/i_STRIPE/i_ADAPT/bmax_count0_nxt[3]         | u_clt_to_bk_top0/u_interlaken_xil_top/u_interlaken_top/i_CORES/i_CORES/i_TX/i_TX/i_STRIPE/i_ADAPT/bmax_count0_RNIF5U9A[3]/O       | u_clt_to_bk_top0/u_interlaken_xil_top/u_interlaken_top/i_CORES/i_CORES/i_TX/i_TX/i_STRIPE/i_ADAPT/cache_eobin_RNO_4/I2             | 0.043             | 0.191          | 184       | 6.00       | 3      | routed     |
# | u_clt_to_bk_top0/u_interlaken_xil_top/u_interlaken_top/i_CORES/i_CORES/i_TX/i_TX/i_STRIPE/i_ADAPT/g4_0_0                     | u_clt_to_bk_top0/u_interlaken_xil_top/u_interlaken_top/i_CORES/i_CORES/i_TX/i_TX/i_STRIPE/i_ADAPT/cache_eobin_RNO_4/O             | u_clt_to_bk_top0/u_interlaken_xil_top/u_interlaken_top/i_CORES/i_CORES/i_TX/i_TX/i_STRIPE/i_ADAPT/cache_eobin_RNO_1/I5             | 0.043             | 0.320          | 319       | 2.00       | 1      | routed     |
# | u_clt_to_bk_top0/u_interlaken_xil_top/u_interlaken_top/i_CORES/i_CORES/i_TX/i_TX/i_STRIPE/i_ADAPT/g4_3                       | u_clt_to_bk_top0/u_interlaken_xil_top/u_interlaken_top/i_CORES/i_CORES/i_TX/i_TX/i_STRIPE/i_ADAPT/cache_eobin_RNO_1/O             | u_clt_to_bk_top0/u_interlaken_xil_top/u_interlaken_top/i_CORES/i_CORES/i_TX/i_TX/i_STRIPE/i_ADAPT/cache_eobin_RNO/I5               | 0.043             | 0.178          | 178       | 2.83       | 1      | routed     |
# | u_clt_to_bk_top0/u_interlaken_xil_top/u_interlaken_top/i_CORES/i_CORES/i_TX/i_TX/i_STRIPE/i_ADAPT/cache_eobin_nxt            | u_clt_to_bk_top0/u_interlaken_xil_top/u_interlaken_top/i_CORES/i_CORES/i_TX/i_TX/i_STRIPE/i_ADAPT/cache_eobin_RNO/O               | u_clt_to_bk_top0/u_interlaken_xil_top/u_interlaken_top/i_CORES/i_CORES/i_TX/i_TX/i_STRIPE/i_ADAPT/cache_eobin/D                    | 0.043             | 0.000          | -         | 0.00       | 1      | routed     |
# +------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------------------------------------------------------------------------+------------------------------------------------------------------------------------------------------------------------------------+-------------------+----------------+-----------+------------+--------+------------+

# +-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
# | {u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/N_Offset_RAM_reg/CLKBWRCLK --> u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/Rd_Pipe_reg[3][N_Val][20]/D}                                                                                                                                                                                                                              |
# | Startpoint : u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/N_Offset_RAM_reg/CLKBWRCLK                                                                                                                                                                                                                                                                                                                                             |
# | Endpoint : u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/Rd_Pipe_reg[3][N_Val][20]/D                                                                                                                                                                                                                                                                                                                                              |
# | Slack: -0.809                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
# +-----------------------------------------------------------------------------------------------------------------------------+-------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------------------------------------------------------------------+-------------------+----------------+-----------+------------+--------+------------+
# | Net                                                                                                                         | Driver                                                                                                                        | Receiver                                                                                                                    | Driver Incr Delay | Net Incr Delay | P2P Delay | Net Length | Fanout | Delay Type |
# +-----------------------------------------------------------------------------------------------------------------------------+-------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------------------------------------------------------------------+-------------------+----------------+-----------+------------+--------+------------+
# | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/N_Offset_Out_d1[2]                | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/N_Offset_RAM_reg/DOBDO[2]           | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/Rd_Pipe[3][N_Val][3]_i_3/I1       | 0.622             | 2.523          | 1425      | 95.21      | 1      | estimated  |
# | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/n_0_Rd_Pipe[3][N_Val][3]_i_3      | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/Rd_Pipe[3][N_Val][3]_i_3/O          | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/Rd_Pipe_reg[3][N_Val][3]_i_1/S[2] | 0.043             | 0.000          | -         | 0.00       | 1      | routed     |
# | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/n_0_Rd_Pipe_reg[3][N_Val][3]_i_1  | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/Rd_Pipe_reg[3][N_Val][3]_i_1/CO[3]  | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/Rd_Pipe_reg[3][N_Val][7]_i_1/CI   | 0.195             | 0.000          | 0         | 2.00       | 1      | estimated  |
# | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/n_0_Rd_Pipe_reg[3][N_Val][7]_i_1  | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/Rd_Pipe_reg[3][N_Val][7]_i_1/CO[3]  | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/Rd_Pipe_reg[3][N_Val][11]_i_1/CI  | 0.053             | 0.000          | 0         | 2.00       | 1      | estimated  |
# | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/n_0_Rd_Pipe_reg[3][N_Val][11]_i_1 | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/Rd_Pipe_reg[3][N_Val][11]_i_1/CO[3] | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/Rd_Pipe_reg[3][N_Val][15]_i_1/CI  | 0.053             | 0.000          | 0         | 2.00       | 1      | estimated  |
# | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/n_0_Rd_Pipe_reg[3][N_Val][15]_i_1 | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/Rd_Pipe_reg[3][N_Val][15]_i_1/CO[3] | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/Rd_Pipe_reg[3][N_Val][19]_i_1/CI  | 0.053             | 0.000          | 0         | 2.00       | 1      | estimated  |
# | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/n_0_Rd_Pipe_reg[3][N_Val][19]_i_1 | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/Rd_Pipe_reg[3][N_Val][19]_i_1/CO[3] | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/Rd_Pipe_reg[3][N_Val][20]_i_1/CI  | 0.053             | 0.000          | 0         | 2.00       | 1      | estimated  |
# | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/n_7_Rd_Pipe_reg[3][N_Val][20]_i_1 | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/Rd_Pipe_reg[3][N_Val][20]_i_1/O[0]  | u_clt_to_bk_top1/u_map_sar_oh_wrapper/map_sar_oh_i/sar_100g_0/U0/SAR17_5_GEN.sar_100_1/RA/Rd_Pipe_reg[3][N_Val][20]/D       | 0.111             | 0.000          | -         | 0.00       | 1      | routed     |
# +-----------------------------------------------------------------------------------------------------------------------------+-------------------------------------------------------------------------------------------------------------------------------+-----------------------------------------------------------------------------------------------------------------------------+-------------------+----------------+-----------+------------+--------+------------+

# +--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
# | {u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/u_crc32_40byte_top/crc_reg_default_reg/C --> u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/u_crc32_40byte_top/u_crc32_40byte_bit27/crc_reg_out_reg/D}                                                                                                                                                                                                                                                       |
# | Startpoint : u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/u_crc32_40byte_top/crc_reg_default_reg/C                                                                                                                                                                                                                                                                                                                                                                                 |
# | Endpoint : u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/u_crc32_40byte_top/u_crc32_40byte_bit27/crc_reg_out_reg/D                                                                                                                                                                                                                                                                                                                                                                  |
# | Slack: -0.779                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
# +-----------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------+----------------------------------------------------------------------------------------------------------------------------------------+-------------------+----------------+-----------+------------+--------+------------+
# | Net                                                                                                                                     | Driver                                                                                                                                | Receiver                                                                                                                               | Driver Incr Delay | Net Incr Delay | P2P Delay | Net Length | Fanout | Delay Type |
# +-----------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------+----------------------------------------------------------------------------------------------------------------------------------------+-------------------+----------------+-----------+------------+--------+------------+
# | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/u_crc32_40byte_top/u_crc32_40byte_bit14/I1                       | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/u_crc32_40byte_top/crc_reg_default_reg/Q                       | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/u_crc32_40byte_top/u_crc32_40byte_bit14/crc_reg_out_i_23__2/I1  | 0.259             | 0.536          | 457       | 15.62      | 42     | estimated  |
# | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/crc_reg_new[14]                                                  | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/u_crc32_40byte_top/u_crc32_40byte_bit14/crc_reg_out_i_23__2/O  | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/crc_reg_out_i_8__56/I3                                          | 0.043             | 2.216          | 1028      | 63.15      | 23     | estimated  |
# | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/n_0_crc_reg_out_i_8__56                                          | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/crc_reg_out_i_8__56/O                                          | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/crc_reg_out_i_2__58/I4                                          | 0.043             | 0.324          | 323       | 2.83       | 1      | estimated  |
# | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/u_crc32_40byte_top/u_crc32_40byte_bit27/I744                     | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/crc_reg_out_i_2__58/O                                          | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/u_crc32_40byte_top/u_crc32_40byte_bit27/crc_reg_out_i_1__122/I0 | 0.043             | 0.340          | 336       | 6.00       | 1      | estimated  |
# | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/u_crc32_40byte_top/u_crc32_40byte_bit27/n_0_crc_reg_out_i_1__122 | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/u_crc32_40byte_top/u_crc32_40byte_bit27/crc_reg_out_i_1__122/O | u_clt_to_bk_top0/u_pcs_mac_top/u_tx_mac_monitor_top/u_process_40byte_2/u_crc32_40byte_top/u_crc32_40byte_bit27/crc_reg_out_reg/D       | 0.043             | 0.000          | -         | 0.00       | 1      | routed     |
# +-----------------------------------------------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------------------------------------------+----------------------------------------------------------------------------------------------------------------------------------------+-------------------+----------------+-----------+------------+--------+------------+

proc report_path_correlation { path } {
 package require toolbox
 if {($path == {})} {
   error " error - empty path"
 }
 set pathInfo [get_path_info $path 1]
puts "<pathInfo:[join $pathInfo \n]>"
 set tbl [prettyTable $path]
 $tbl header [list {Net} {Driver} {Receiver} {Driver Incr Delay} {Net Incr Delay} {P2P Delay} {Net Length} {Fanout} {Delay Type} ]
 # Skip the past element of $pathIno since this is the endpoint information
 foreach elm [lrange $pathInfo 0 end-1] {
   foreach {pindata netdata inputpinname} $elm { break }
   foreach {pinname pinrisefall pinincrdelay pindelay} $pindata { break }
   foreach {netname netlength netfanout nettype netincrdelay netdelay} $netdata { break }
puts "<$netname:$pinname:$inputpinname>"
#    set p2pDelay [getP2pPinToPinDelay -to $inputpinname]
   if {[catch {set p2pDelay [p2pdelay get_p2p_delay -from $pinname -to $inputpinname]} errorstring]} {
     set p2pDelay {n/a}
   }
puts "<p2pDelay:$p2pDelay>"
   $tbl addrow [list $netname $pinname $inputpinname $pinincrdelay $netincrdelay $p2pDelay $netlength $netfanout $nettype ]
 }
 set title [format "$path\nStartpoint : [get_property -quiet STARTPOINT_PIN $path]\nEndpoint : [get_property -quiet ENDPOINT_PIN $path]\nSlack: [get_property -quiet SLACK $path]"]
 $tbl configure -title $title
 puts [$tbl print]
 catch {$tbl destroy}
 return 1
}

proc get_path_info { path {netlength 0} } {
 if {($path == {})} {
   error " error - empty path"
 }
 set rpt [split [report_timing -of $path -no_header -return_string] \n]
 # Create an associative array with the output pins as key and input pins as values
 array set pathPins [get_pins -quiet -of $path]
 set data [list]
 set SM {init}
 set numSep 0
 set netname {}
 set pinname {}
 set pinrisefall {}
 set pinincrdelay {}
 set pindelay {}
 set netfanout {}
 set nettype {}
 set netincrdelay {}
 set netdelay {}
 for {set i 0} {$i < [llength $rpt]} {incr i} {
   set line [lindex $rpt $i]
   set nextline [lindex $rpt [expr $i+1]]
    switch $SM {
      init {
        if {[regexp {\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-} $line]} {
          incr numSep
        }
        if {$numSep == 2} {
          set SM {main}
        }
      }
      main {
        # Some lines might be splitted in 2 lines for formating reasons:
        #     SLICE_X175Y240       CARRY4 (Prop_carry4_S[1]_CO[2])
        #                                                       0.282     6.157 f  core_u/desegment_u1/svbl_529.svbl_544.svbl_545.freeBlockReadEnable9_0_I_1_CARRY4/CO[2]
        # When this happens, the code below attach the next line to the current one
        if {[regexp {^\s*(\-?[0-9\.]+)\s+(\-?[0-9\.]+)\s+([^\s]+)(\s|$)} $nextline]} {
          append line $nextline
          # Skip next line now
          incr i
        } elseif {[regexp {^\s*(\-?[0-9\.]+)\s+(\-?[0-9\.]+)\s+(r|f)\s+([^\s]+)(\s|$)} $nextline]} {
          append line $nextline
          # Skip next line now
          incr i
        }
        if {[regexp {\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-} $line]} {
          set SM {end}
        } elseif {[regexp {^\s*net\s*\(fo=([0-9]+)\s*,\s*([^\)]+)\s*\)\s*(\-?[0-9\.]+)\s+(\-?[0-9\.]+)\s+([^\s]+)(\s|$)} $line - netfanout nettype netincrdelay netdelay netname]} {
          # Example of net delay:
          #         net (fo=0)                   0.000     3.333    main_clocks_u/BASE_CLOCKS_u/clockMainRefIn_p
#           puts "net:<$netname><$netfanout><$nettype><$netincrdelay><$netdelay>"
          set inputpinname {N/A}
          if {[info exists pathPins($pinname)]} {
            set inputpinname $pathPins($pinname)
          }
          lappend data [list [list $pinname $pinrisefall $pinincrdelay $pindelay] [list $netname $netfanout $nettype $netincrdelay $netdelay] $inputpinname ]
          set pinname {NOT_FOUND}
        } elseif {[regexp {^.+\(.+\)\s*(\-?[0-9\.]+)\s+(\-?[0-9\.]+)\s+(r|f)\s+([^\s]+)(\s|$)} $line - pinincrdelay pindelay pinrisefall pinname]} {
          # Example of pin delay:
          #   SLICE_X171Y243       FDRE (Prop_fdre_C_Q)         0.216     4.874 r  core_u/desegment_u1/PUT_FLOW_RAM_u/readData[19]/Q
          #   SLICE_X175Y243                                                    r  core_u/desegment_u1/svbl_529.svbl_544.svbl_545.freeBlockReadEnable9_0_I_18_i_RNO_0/I0
          #   SLICE_X175Y243       LUT5 (Prop_lut5_I0_O)        0.043     5.409 f  core_u/desegment_u1/svbl_529.svbl_544.svbl_545.freeBlockReadEnable9_0_I_18_i_RNO_0/O
#           puts "pin:<$pinname><$pinrisefall><$pinincrdelay><$pindelay>"
        } elseif {[regexp {^.+\s+(r|f)\s+([^\s]+)(\s|$)} $line - pinrisefall pinname]} {
          # Example of pin endpoint:
          #   RAMB36_X9Y21         RAMB36E1                                     r  core_u/policer_u1/rxOctetCnt_i0/count_ram_i0/ram_data_1_ram_data_1_0_2/ADDRBWRADDR
#           puts "pin:<$pinname><$pinrisefall>"
        } else {
        }
      }
      end {
        break
      }
    }
 }
 # The last pin information (endpoint) was not registered since it is not followed by a net
 # So let's do it now
 lappend data [list [list $pinname $pinrisefall {} {}] [list {} {} {} {} {}] {} ]
 # Now add the net length information
 if {$netlength == 1} {
   set data2 [list]
   set length 0.0
   set distances [list]
   for {set i 0} {$i < [expr [llength $data] -1]} {incr i} {
    set obj1 [lindex $data $i]
    set obj2 [lindex $data [expr $i +1]]
    foreach {pindata1 netdata1 inputpindata1} $obj1 { break }
    foreach {pindata2 netdata2 inputpindata2} $obj2 { break }
#      puts "\n pindata1: $pindata1"
#      puts " netdata1: $netdata1"
#      puts " pindata2: $pindata2"
#      puts " netdata2: $netdata2"
     foreach {pinname1 pinrisefall1 pinincrdelay1 pindelay1} $pindata1 { break }
     foreach {netname1 netfanout1 nettype1 netincrdelay1 netdelay1} $netdata1 { break }
     foreach {pinname2 pinrisefall2 pinincrdelay2 pindelay2} $pindata2 { break }
     foreach {netname2 netfanout2 nettype2 netincrdelay2 netdelay2} $netdata2 { break }
     set segmentlength [format {%.2f} [dist_cells [get_cells -quiet -of [get_pins -quiet $pinname1]] [get_cells -quiet -of [get_pins -quiet $pinname2]] ]]
#      puts "  --> $netname1 : $segmentlength"
     lappend data2 [list [list $pinname1 $pinrisefall1 $pinincrdelay1 $pindelay1] [list $netname1 $segmentlength $netfanout1 $nettype1 $netincrdelay1 $netdelay1] $inputpindata1 ]
     set length [expr $length + $segmentlength]
   }
   lappend data2 [list [list $pinname2 $pinrisefall2 {} {}] [list {} {} {} {} {} {}] {} ]
   set length [format {%.2f} $length]
   set data $data2
 }
 # Return the results
 return $data
}

proc dist_path { path } {
 if {($path == {})} {
   error " error - empty path"
 }
 set pins [get_pins -quiet -of $path]
# puts "<path([get_property -quiet SLACK $path]):$path>"
# puts "<cells([llength $cells]):$cells>"
 set length 0.0
 set distances [list]
 puts "*** $path ***"
 foreach {pin1 pin2} $pins {
  set net1 [get_nets -quiet -top -boundary_type upper -of $pin1]
  set net2 [get_nets -quiet -top -boundary_type upper -of $pin2]
  if {$net1 != $net2} {
#    error " error - $net1 ($pin1) and $net2 ($pin2) don't match"
  }
  set distance [dist_cells [get_cells -quiet -of $pin1] [get_cells -quiet -of $pin2] ]
  puts "$net1 : $distance"
  lappend distances $distance
  set length [expr $length + $distance]
 }
 set length [format {%.2f} $length]
#  return [concat $length $distances]
 return [list $length $distances]
}

proc dist_paths { paths } {
 if {($paths == {})} {
   error " error - empty paths"
 }
 foreach path $paths {
# puts "<path([get_property -quiet SLACK $path]):$path>"
   puts "\n[dist_path $path]"
 }
 return 0
}

# proc gtp_script { paths name } {
#   set cmds [list]
#   if {[get_property -quiet CLASS $paths] == {timing_path}} {
#     # A single path object needs to be put in a Tcl list
#     set paths [list $paths]
#   }
#   foreach path $paths {
#     set startpin [get_property -quiet STARTPOINT_PIN $path]
#     set endpin [get_property -quiet ENDPOINT_PIN $path]
#     set nets [get_nets -quiet -of $path]
#     set cmd [format {get_timing_paths -from [get_pins %s] -to [get_pins %s] -through [get_nets [list %s]]} $startpin $endpin $nets]
# #     puts "<$cmd>"
#     lappend cmds $cmd
#   }
# #   puts $cmds
#   set proc [format "proc gtp.%s {} \{ " $name]
#   append proc "\n set L \[list\]; set error 0 "
#   foreach cmd $cmds {
#     append proc [format "\n if {\[catch {lappend L \[%s\]} errorstring\]} { incr error } " $cmd]
#   }
#   append proc [format "\n if {\$error} { puts \" \$error error(s)\" } "]
#   append proc [format "\n return \$L \n \} "]
# #   puts "<$proc>"
#   uplevel #0 [list eval $proc]
#   puts " Created proc gtp.$name"
# #   puts $proc
# }

#   set to_p2p [split [lindex [get_site_pin -of [get_pin $receiver]] 0] /]
#   set from_p2p [split [get_site_pin -of [get_pin $driver]] /]
#   ::internal::route_dbg_p2p_route -from "$from_p2p" -to "$to_p2p" > p2p_route.out
#        Routing from GTHE2_CHANNEL_X1Y3 RXHEADERVALID0->SLICE_X169Y36 AX

proc p2p {pin1 pin2} {
  set from_p2p [split [lindex [get_site_pin -of [get_pin $pin1]] 0] /]
  set to_p2p [split [lindex [get_site_pin -of [get_pin $pin2]] 0] /]
  ::internal::route_dbg_p2p_route -from "$from_p2p" -to "$to_p2p"
}

proc p2p_cmd {pin1 pin2} {
  set from_p2p [split [lindex [get_site_pin -quiet -of [get_pin $pin1]] 0] /]
  set to_p2p [split [lindex [get_site_pin -quiet -of [get_pin $pin2]] 0] /]
  puts [format {::internal::route_dbg_p2p_route -from "%s" -to "%s"} $from_p2p $to_p2p]
}

proc get_tp_objects {paths} {
 if {($paths == {})} {
   error " error - empty path"
 }
 set flag 0
 if {[llength [get_property -quiet CLASS $paths]] == 1} {
   # A single object needs to be put in a Tcl list
   set paths [list $paths]
   set flag 1
 }
 set L [list]
 foreach path $paths {
   set l [list]
   set nets [get_nets -quiet -of $path]
   set pins [get_pins -quiet -of $path]
   foreach {pin1 pin2} $pins net $nets {
    lappend l [list $net $pin1 $pin2]
#     puts "<$net><$pin1><$pin2>"
   }
   lappend L $l
 }
 if {$flag} {
   return [lindex $L 0]
 } else {
   return $L
 }
}

# source /home/dpefour/git/scripts/wip/calc.tcl
# report_timing_summary -no_check_timing -name summary
# set spaths [get_timing_paths -quiet -nworst 1 -max_path 1000 -slack_lesser_than 0.0 -setup] ; llength $spaths
# catch { report_timing -of $spaths -name violators }
# catch { lmac postplace }
# catch { lmac postphysopt }
# catch { lmac postroute }
# catch { set postplace [postplace] }
# catch { set postphysopt [postphysopt] }
# catch { set postroute [postroute] }
# catch { report_timing -of $postplace -name postplace }
# catch { report_timing -of $postphysopt -name postphysopt }
# catch { report_timing -of $postroute -name postroute }

# set tag {postplace}
# # set tag {postphysopt}
# # set tag {postroute}
# catch { lmac RAM_input_timing_$tag }
# catch { lmac RAM_output_timing_$tag }
# catch { lmac FIFO_input_timing_$tag }
# catch { lmac FIFO_output_timing_$tag }
# catch { set RAM_input_timing_$tag [RAM_input_timing_$tag] }
# catch { set RAM_output_timing_$tag [RAM_output_timing_$tag] }
# catch { set FIFO_input_timing_$tag [FIFO_input_timing_$tag] }
# catch { set FIFO_output_timing_$tag [FIFO_output_timing_$tag] }
# catch { report_timing -of [subst $[subst RAM_input_timing_${tag}]] -name RAM_input_timing_$tag }
# catch { report_timing -of [subst $[subst RAM_output_timing_${tag}]] -name RAM_output_timing_$tag }
# catch { report_timing -of [subst $[subst FIFO_input_timing_${tag}]] -name FIFO_input_timing_$tag }
# catch { report_timing -of [subst $[subst FIFO_output_timing_${tag}]] -name FIFO_output_timing_$tag }

proc lmac { {name {default} } } {
  if {![file exists ${name}.mac]} {
    puts " file ${name}.mac does not exist"
    return -code ok 
  }
  if {[catch {
    set FH [open ${name}.mac {r}]
    set content [read $FH]
    close $FH
    puts " ... loaded ${name}.mac"
    uplevel 1 $content
  } errorstring]} {
    puts "\n$errorstring"
  }
}

proc mac { objs {name {default}} } {
  set cmds [o2c $objs]
  if {$cmds == {}} {
    puts " error - no primary Vivado object(s)"
    return {}
#     error " error - no primary Vivado object"
  }
#   puts $cmds
  set proc [format "proc %s {} \{ " $name]
  append proc "\n proc T obj { upvar 1 L L; if {\$obj != {}} { lappend L \$obj } else { error {} } } "
  append proc "\n set L \[list\]; set error 0 "
  foreach cmd $cmds {
    append proc [format "\n if {\[catch {T \[%s\]} errorstring\]} { incr error } " $cmd]
  }
  append proc [format "\n if {\$error} { puts \" Warning - \$error objects were not found\" } "]
  append proc [format "\n return \$L \n\} "]
#   puts "<$proc>"
  # create the proc inside the global namespace
  uplevel #0 [list eval $proc]
  puts -nonewline " Created proc $name"
  if {[catch {
    set FH [open ${name}.mac {w}]
    puts $FH $proc
    close $FH
    puts " ... saved ${name}.mac"
  } errorstring]} {
    puts "\n$errorstring"
  }
#   puts $proc
}

# Generate commands from objects
proc o2c { objs } {
  set cmds [list]
  switch [llength [get_property -quiet CLASS $objs]] {
    0 {
      puts " error - no primary Vivado object(s)"
      return {}
#       error " error - no primary Vivado object"
    }
    1 {
      # A single object needs to be put in a Tcl list
      set objs [list $objs]
    }
    default {
    }
  }
  set CLASS [lsort -unique [get_property -quiet CLASS $objs]]
  set flag 1
  if {[llength $CLASS] == 1} {
    set flag 0
  }
  foreach obj $objs {
    set cmd {}
    if {$flag} { set CLASS [get_property -quiet CLASS $obj] }
# puts "<$obj><$CLASS>"
    switch $CLASS {
      cell {
        set cmd [format {get_cells -quiet {%s}} $obj]
      }
      pin {
        set cmd [format {get_pins -quiet {%s}} $obj]
      }
      port {
        set cmd [format {get_ports -quiet {%s}} $obj]
      }
      net {
        set cmd [format {get_nets -quiet {%s}} $obj]
      }
      site {
        set cmd [format {get_sites -quiet {%s}} $obj]
      }
      site_pin {
        set cmd [format {get_site_pins -quiet {%s}} $obj]
      }
      timing_path {
# puts "<obj:$obj>[report_property $obj]"
        set startpin [get_property -quiet STARTPOINT_PIN $obj]
        set endpin [get_property -quiet ENDPOINT_PIN $obj]
#         set nets [get_nets -quiet -of $obj]
        set nets [get_nets -quiet -of $obj -top_net_of_hierarchical_group -filter {TYPE == SIGNAL}]
# puts "<startpin:$startpin><endpin:$endpin><nets:$nets>"
#         set cmd [format {get_timing_paths -quiet -from [get_pins -quiet {%s}] -to [get_pins -quiet {%s}] -through [get_nets -quiet [list %s]]} $startpin $endpin $nets]
        set cmd [format {get_timing_paths -quiet -from [get_%ss -quiet {%s}] -to [get_%ss -quiet {%s}] -through [get_nets -quiet [list %s]]} [get_property CLASS $startpin] $startpin [get_property CLASS $endpin] $endpin $nets]
      }
      default {
        puts " -W- skipping object $obj"
      }
    }
    # Convert {{->{ and }}->}
    regsub -all "{{" $cmd "{" cmd
    regsub -all "}}" $cmd "}" cmd
#     puts "<$cmd>"
    lappend cmds $cmd
  }
  return $cmds
}

proc @ {name body} {
  set _body_ [format {
if {$args == {}} { set args [get_selected_objects] }
}]
  append _body_ $body
#   proc @${name} {args} [list uplevel 1 $_body_]
  proc @${name} {args} $_body_
}


proc lexpand { fct args } {
  set cmd {}
  set count [llength $args]
  foreach L [::tb::lrevert $args] {
    incr count -1
    set cmd [format "foreach _%s_ {%s} \{ %s " [expr $count +0] $L $cmd]
  }
  append cmd "$fct"
  for {set i 0} {$i < [llength $args]} {incr i} { append cmd " \$_${i}_" }
  append cmd [string repeat "\}" [llength $args] ]
# puts "<cmd:$cmd>"
  uplevel 1 [list eval $cmd]
  return 0
}

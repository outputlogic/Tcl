namespace eval g2_custom_timing {
  
  proc config_corner {fast_corner slow_corner dly_type wname fname} {
    config_timing_corners -corner Fast -delay_type $fast_corner
    config_timing_corners -corner Slow -delay_type $slow_corner
    report_timing -to [get_ports o*Duc*] -delay_type $dly_type -max_paths 1000 -input_pins -file $fname -name $wname
  }
  
  proc setup_paths {duc_ID dly_type d3p0_paths d3p1_paths} {
    upvar $d3p0_paths p0
    upvar $d3p1_paths p1
     
    switch $duc_ID {
      "DUC0" {
        set p0_i [get_ports o*Duc0* -filter {NAME =~ *Port_Sync* || NAME =~ *Valid* || NAME =~ o10_Data* || NAME =~ *o_Parity*}]
        set p1_i [get_ports o*Duc0* -filter {NAME =~ o6_Ofdm_Sync_Duc* || NAME =~ o_Ofdm_Parity_Duc*  || NAME =~ *o9_Port*}]
      } 
      "DUC1" {
        set p0_i [get_ports o*Duc1* -filter {NAME =~ *Port_Sync* || NAME =~ *Valid* || NAME =~ o10_Data* || NAME =~ *o_Parity*}]
        set p1_i [get_ports o*Duc1* -filter {NAME =~ o6_Ofdm_Sync_Duc* || NAME =~ o_Ofdm_Parity_Duc*  || NAME =~ *o9_Port*}]
      }
      "DUC2" { 
        set p0_i [get_ports o*Duc2* -filter {NAME =~ *Port_Sync* || NAME =~ *Valid* || NAME =~ o10_Data* || NAME =~ *o_Parity*}]
        set p1_i [get_ports o*Duc2* -filter {NAME =~ o6_Ofdm_Sync_Duc* || NAME =~ o_Ofdm_Parity_Duc*  || NAME =~ *o9_Port*}]
      }
      "DUC3" {
        set p0_i [get_ports o*Duc3* -filter {NAME =~ *Port_Sync* || NAME =~ *Valid* || NAME =~ o10_Data* || NAME =~ *o_Parity*}]
        set p1_i [get_ports o*Duc3* -filter {NAME =~ o6_Ofdm_Sync_Duc* || NAME =~ o_Ofdm_Parity_Duc*  || NAME =~ *o9_Port*}]
      }
    }
    
    set p0 [lsort -dictionary -decreasing [get_timing_paths -to  $p0_i -delay_type $dly_type -max_paths 1000]]
    set p1 [lsort -dictionary -decreasing [get_timing_paths -to  $p1_i -delay_type $dly_type -max_paths 1000]]
    
  }

  proc run_report {bit_period setup_req hold_req timing_paths fId} {

    foreach timing_path $timing_paths {
    
      set signal_name [get_property ENDPOINT_PIN           $timing_path]
      set proc_corner [get_property CORNER                 $timing_path]
      set dly_type    [get_property DELAY_TYPE             $timing_path]
      set ck_dly      [get_property STARTPOINT_CLOCK_DELAY $timing_path]
      set dp_dly      [get_property DATAPATH_DELAY         $timing_path]
      set ck_pess     [get_property CLOCK_PESSIMISM        $timing_path]
      set ck_uncer    [get_property UNCERTAINTY            $timing_path]
      set ck_e_dly    [get_property ENDPOINT_CLOCK_DELAY   $timing_path]

      switch $dly_type {
        "min" {
          set out_dly [expr $ck_dly + $dp_dly - $ck_uncer - $ck_pess]
        }
        "max" {
          set out_dly [expr $ck_dly + $dp_dly + $ck_uncer - $ck_pess]
        }
      }
      set skew [expr $ck_e_dly - $out_dly]
      set setup [expr $skew - $setup_req]
      set hold [expr $bit_period - $skew - $hold_req]

      puts $fId [format {%-30s %-10s %-10s %-10f %-10f %-10f %-10f %-10f %-10f %-10f %-10f %-10f} $signal_name $proc_corner $dly_type $ck_dly $dp_dly $ck_e_dly $ck_uncer $ck_pess $out_dly  $skew $setup $hold ]
    }
    puts $fId [format {%-30s} "########################"]
    
  }

  set d3p0_bit_period 0.814
  set d3p0_setup_req  0.123
  set d3p0_hold_req   0.063

  set d3p1_bit_period 1.221
  set d3p1_setup_req  0.181
  set d3p1_hold_req   0.148


  set duc_ID_v      [list "DUC0" "DUC1" "DUC2" "DUC3"]
  set fast_corner_v [list "none" "none" "min" "max"]
  set slow_corner_v [list "min" "max" "none" "none"]
  set dly_type_v    [list "min" "max" "min" "max"]
  set wname_v       [list "SLOW_MIN_Ideal" "SLOW_MAX_Ideal" "FAST_MIN_Ideal" "FAST_MAX_Ideal"]
  set fname_v       [list "SLOW_MIN_Ideal.txt" "SLOW_MAX_Ideal.txt" "FAST_MIN_Ideal.txt" "FAST_MAX_Ideal.txt"]

  set d3p0_paths "new"
  set d3p1_paths "one"
  
  puts $d3p0_paths
  puts $d3p1_paths
  
#   source ./constraints/ap_196_timing_d3p0_ideal_delay.xdc
#   source ./constraints/ap_196_timing_d3p1_ideal_delay.xdc
  
  set TAG {orig_}
  
  set fId [open "${TAG}g2_respin_timing_ideal_dly.txt" "w"]
  puts $fId [format {%-30s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s %-10s}  "SIGNAL_NAME" "PROCESS" "DLY_TYPE" "SRC_CK_DLY" "DATA_DLY" "DST_CK_DLY" "CLK_UNC" "CLK_PESS" "OUT_DELAY" "SKEW" "SETUP" "HOLD"]
  
  foreach fast_corner $fast_corner_v slow_corner $slow_corner_v dly_type $dly_type_v wname $wname_v fname $fname_v  {
    config_corner $fast_corner $slow_corner $dly_type $wname ${TAG}$fname
    foreach duc $duc_ID_v {
      setup_paths $duc $dly_type d3p0_paths d3p1_paths
      run_report $d3p0_bit_period $d3p0_setup_req $d3p0_hold_req $d3p0_paths $fId
      run_report $d3p1_bit_period $d3p1_setup_req $d3p1_hold_req $d3p1_paths $fId
    }
  }  
  close $fId
  
  config_timing_corners -corner Slow -delay_type min_max
  config_timing_corners -corner Fast -delay_type min_max
  report_datasheet -show_all_corners -name "g2_respin_timing_ideal_datasheet" -file "${TAG}g2_respin_timing_ideal_datasheet.txt"  
  
}
namespace delete g2_custom_timing

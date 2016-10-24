set rootDir             {%{ROOTDIR}}
set runDir              {%{RUNDIR}}

cd $runDir

set topName {top_0_0B}

open_checkpoint $rootDir/design_linked.dcp
check_ip_cache -clear_output_repo
set cachefile .cache
if {[file exists ${cachefile}]} {
    file delete -force ${cachefile}
}
set_property MARK_DEBUG TRUE [get_nets [list {PARTITION_IDENTIFIER_FPGA_0B}  {clk} {crc_1[0]} {crc_1[1]} {crc_1[2]} {crc_1[3]} {crc_1[4]} {crc_1[5]} {crc_1[6]} {crc_1[7]} {crc_1[8]} {crc_1[9]} {crc_1[10]} {crc_1[11]} {crc_1[12]} {crc_1[13]} {crc_1[14]} {crc_1[15]} {crc_1[16]} {crc_1[17]} {crc_1[18]} {crc_1[19]} {crc_1[20]} {crc_1[21]} {crc_1[22]} {crc_1[23]} {crc_1[24]} {crc_1[25]} {crc_1[26]} {crc_1[27]} {crc_1[28]} {crc_1[29]} {crc_1[30]} {crc_1[31]} {crc_2[0]} {crc_2[1]} {crc_2[2]} {crc_2[3]} {crc_2[4]} {crc_2[5]} {crc_2[6]} {crc_2[7]} {crc_2[8]} {crc_2[9]} {crc_2[10]} {crc_2[11]} {crc_2[12]} {crc_2[13]} {crc_2[14]} {crc_2[15]} {crc_2[16]} {crc_2[17]} {crc_2[18]} {crc_2[19]} {crc_2[20]} {crc_2[21]} {crc_2[22]} {crc_2[23]} {crc_2[24]} {crc_2[25]} {crc_2[26]} {crc_2[27]} {crc_2[28]} {crc_2[29]} {crc_2[30]} {crc_2[31]} {data_out_1[0]} {data_out_1[1]} {data_out_1[2]} {data_out_1[3]} {data_out_1[4]} {data_out_1[5]} {data_out_1[6]} {data_out_1[7]} {data_out_1[8]} {data_out_1[9]} {data_out_1[10]} {data_out_1[11]} {data_out_1[12]} {data_out_1[13]} {data_out_1[14]} {data_out_1[15]} {data_out_1[16]} {data_out_1[17]} {data_out_1[18]} {data_out_1[19]} {data_out_2[0]} {data_out_2[1]} {data_out_2[2]} {data_out_2[3]} {data_out_2[4]} {data_out_2[5]} {data_out_2[6]} {data_out_2[7]} {data_out_2[8]} {data_out_2[9]} {data_out_2[10]} {data_out_2[11]} {data_out_2[12]} {data_out_2[13]} {data_out_2[14]} {data_out_2[15]} {data_out_2[16]} {data_out_2[17]} {data_out_2[18]} {data_out_2[19]} {dualData[0]} {dualData[1]} {dualData[2]} {dualData[3]} {dualData[4]} {dualData[5]} {dualData[6]} {dualData[7]} {dualData[8]} {dualData[9]} {dualData[10]} {dualData[11]} {dualData[12]} {dualData[13]} {dualData[14]} {dualData[15]} {dualData[16]} {dualData[17]} {dualData[18]} {dualData[19]} {reset_n} ]]

create_debug_core pdrpp_debug_core_0 labtools_ila_v3

set_property C_DATA_DEPTH 4096 [get_debug_cores pdrpp_debug_core_0]

set_property PORT_WIDTH 1 [get_debug_ports pdrpp_debug_core_0/clk]
connect_debug_port pdrpp_debug_core_0/clk [get_nets masterpllconfiginst/CVA_PTM_RESERVED_ENMAPPING_1918]

set_property PORT_WIDTH 127 [get_debug_ports pdrpp_debug_core_0/probe0]
connect_debug_port pdrpp_debug_core_0/probe0 [get_nets [list {crc_1[0]} {crc_1[1]} {crc_1[2]} {crc_1[3]} {crc_1[4]} {crc_1[5]} {crc_1[6]} {crc_1[7]} {crc_1[8]} {crc_1[9]} {crc_1[10]} {crc_1[11]} {crc_1[12]} {crc_1[13]} {crc_1[14]} {crc_1[15]} {crc_1[16]} {crc_1[17]} {crc_1[18]} {crc_1[19]} {crc_1[20]} {crc_1[21]} {crc_1[22]} {crc_1[23]} {crc_1[24]} {crc_1[25]} {crc_1[26]} {crc_1[27]} {crc_1[28]} {crc_1[29]} {crc_1[30]} {crc_1[31]} {crc_2[0]} {crc_2[1]} {crc_2[2]} {crc_2[3]} {crc_2[4]} {crc_2[5]} {crc_2[6]} {crc_2[7]} {crc_2[8]} {crc_2[9]} {crc_2[10]} {crc_2[11]} {crc_2[12]} {crc_2[13]} {crc_2[14]} {crc_2[15]} {crc_2[16]} {crc_2[17]} {crc_2[18]} {crc_2[19]} {crc_2[20]} {crc_2[21]} {crc_2[22]} {crc_2[23]} {crc_2[24]} {crc_2[25]} {crc_2[26]} {crc_2[27]} {crc_2[28]} {crc_2[29]} {crc_2[30]} {crc_2[31]} {data_out_1[0]} {data_out_1[1]} {data_out_1[2]} {data_out_1[3]} {data_out_1[4]} {data_out_1[5]} {data_out_1[6]} {data_out_1[7]} {data_out_1[8]} {data_out_1[9]} {data_out_1[10]} {data_out_1[11]} {data_out_1[12]} {data_out_1[13]} {data_out_1[14]} {data_out_1[15]} {data_out_1[16]} {data_out_1[17]} {data_out_1[18]} {data_out_1[19]} {data_out_2[0]} {data_out_2[1]} {data_out_2[2]} {data_out_2[3]} {data_out_2[4]} {data_out_2[5]} {data_out_2[6]} {data_out_2[7]} {data_out_2[8]} {data_out_2[9]} {data_out_2[10]} {data_out_2[11]} {data_out_2[12]} {data_out_2[13]} {data_out_2[14]} {data_out_2[15]} {data_out_2[16]} {data_out_2[17]} {data_out_2[18]} {data_out_2[19]} {dualData[0]} {dualData[1]} {dualData[2]} {dualData[3]} {dualData[4]} {dualData[5]} {dualData[6]} {dualData[7]} {dualData[8]} {dualData[9]} {dualData[10]} {dualData[11]} {dualData[12]} {dualData[13]} {dualData[14]} {dualData[15]} {dualData[16]} {dualData[17]} {dualData[18]} {dualData[19]} {PARTITION_IDENTIFIER_FPGA_0B} {clk} {reset_n} ]]


implement_debug_core [get_debug_cores]
write_debug_probes $topName.ltx -force

package require toolbox
tb::report_design_summary -csv -file summary.csv

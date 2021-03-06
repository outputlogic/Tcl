####################################################################################################
# HEADER_BEGIN
# COPYRIGHT NOTICE
# Copyright 2001-2016 Xilinx Inc. All Rights Reserved.
# http://www.xilinx.com/support
# HEADER_END
####################################################################################################

# proc [file tail [info script]] {} " source [info script]; puts \" [info script] reloaded\" "
# proc reload {} " source [info script]; puts \" [info script] reloaded\" "

########################################################################################
##
## Company:        Xilinx, Inc.
## Created by:     David Pefourque
##
## Version:        2016.11.07
## Description:    Generate a design summary report
##
########################################################################################

########################################################################################
## 2016.11.07 - Added better support for post-place utilization report
##            - Added support for extracting small percent such as "<0.1"
##            - Added new design/utilization metrics
## 2016.10.08 - Fixed command line options collisions
##            - Added new design/utilization metrics
## 2016.07.27 - Added support for -prefix (config_flow_automation)
##            - Added support for -vivadolog (config_flow_automation)
## 2016.07.25 - Added support for -methodology. Forced split between DRC & Methodology
##              checks. Added methodology.* metrics
##            - Internal data structures can now be forced to be reset in debug mode
## 2016.07.18 - Added support for -vivadolog
##            - Added congestion.estimated.global, congestion.estimated.long,
##              congestion.estimated.short metrics
##            - Added design.cells.ratiofdlut, vivado.os.description metrics
##            - Updated ordered metrics for congestion.estimated.* metrics
## 2016.07.12 - Added support for -save_reports
##            - Added design.slls metric
##            - Added support for automation of design summaries throughout
##              the implementation flow (config_flow_automation)
## 2016.06.30 - Added support for gzip-ed input files
## 2016.06.13 - Added tag.date, tag.time metrics
## 2016.03.14 - Minor changes to prevent failure when not running inside vivado
## 2016.03.04 - Added new DRC metrics from report_methodology
##            - Added support for -drc/-rm/-report_methodology
##            - Reordered the metric categories
## 2016.02.29 - Added tag.directive, tag.runtime metrics
##            - Added support for ordered metrics
## 2016.02.04 - Renamed -serialize to -return_metrics
##            - Renamed -suppress to -hide_missing
##            - Added -add_metrics
##            - Added -exclude
##            - Changed behavior of incremental mode to be more user friendly
## 2016.02.02 - Added support for -serialize
##            - Replaced -script with -tclpre/-tclpost
##            - Added support for -tclprecmd/-tclpostcmd
##            - Added clock pairs metrics
##            - Added additional default metrics
## 2016.01.29 - Fixed metric patterns (check_timing)
##            - Added support for -cdc/-rcdc
##            - Added support for incremental mode (-incremental)
##            - Added support for -script
##            - Fixed missing separator in CSV
##            - Script is more silent
## 2016.01.28 - Fixed metric pattern (check_timing)
##            - Code re-organization
##            - Added support for -rts/-rct/-rda/-rrs/-rci/-ru/-rru
## 2016.01.22 - Added support for -suppress
## 2016.01.20 - Updated label for congestion metrics
## 2016.01.18 - Added tag metrics
##            - Added congestion metrics
##            - Added constraints metrics
##            - Added check_timing metrics
##            - Added clock_interaction metrics
##            - Added route metrics
##            - Added additional default metrics
##            - Added additional timing metrics
##            - Misc enhancements
## 2015.08.26 - Initial release
########################################################################################

# Example of report:
#       +-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
#       | Design Summary                                                                                                                                                                                                              |
#       +----------------------------------------------+--------------------------------------------------------------------+---------------------------------------------------------------------------------------------------------+
#       | Id                                           | Description                                                        | Value                                                                                                   |
#       +----------------------------------------------+--------------------------------------------------------------------+---------------------------------------------------------------------------------------------------------+
#       | tag.project                                  | Project                                                            | myproject                                                                                               |
#       | tag.version                                  | Version                                                            | myversion                                                                                               |
#       | tag.experiment                               | Experiment                                                         | myexperiment                                                                                            |
#       | tag.step                                     | Step                                                               | route_design                                                                                            |
#       | tag.directive                                | Directive                                                          | Explore                                                                                                 |
#       | tag.runtime                                  | Runtime                                                            | 3612                                                                                                    |
#       +----------------------------------------------+--------------------------------------------------------------------+---------------------------------------------------------------------------------------------------------+
#       | vivado.version                               | Vivado Release                                                     | 2016.1                                                                                                  |
#       | vivado.build                                 | Vivado Build                                                       | 1496441                                                                                                 |
#       | vivado.plateform                             | Plateform                                                          | unix                                                                                                    |
#       | vivado.os                                    | OS                                                                 | Linux                                                                                                   |
#       | vivado.osVersion                             | OS Version                                                         | 2.6.18-371.4.1.el5                                                                                      |
#       | vivado.top                                   | Top Module Name                                                    | fpga0_top                                                                                               |
#       +----------------------------------------------+--------------------------------------------------------------------+---------------------------------------------------------------------------------------------------------+
#       | design.part.architecture.name                | Architecture Name                                                  | Virtex UltraScale                                                                                       |
#       | design.part.architecture                     | Architecture                                                       | virtexu                                                                                                 |
#       | design.part                                  | Part                                                               | xcvu160-flgb2104-2-e-es2                                                                                |
#       | design.part.speed.class                      | Speed class                                                        | -2                                                                                                      |
#       | design.part.speed.label                      | Speed label                                                        | ADVANCED                                                                                                |
#       | design.part.speed.id                         | Speed ID                                                           | 1.18                                                                                                    |
#       | design.part.speed.date                       | Speed date                                                         | 11-17-2015                                                                                              |
#       | design.cells.blackbox                        | Number of blackbox cells                                           | 0                                                                                                       |
#       | design.cells.hier                            | Number of hierarchical cells                                       | 46486                                                                                                   |
#       | design.cells.primitive                       | Number of primitive cells                                          | 837075                                                                                                  |
#       | design.cells.hlutnm                          | Number of HLUTNM cells                                             | 33740                                                                                                   |
#       | design.cells.hlutnm.pct                      | Number of HLUTNM cells (%)                                         | 8.67                                                                                                    |
#       | design.cells.ratiofdlut                      | Ratio of registers over LUTs                                       | 1.00                                                                                                    |
#       | design.clocks                                | Number of clocks (all inclusive)                                   | 86                                                                                                      |
#       | design.clocks.primary                        | Number of primary clocks                                           | 14                                                                                                      |
#       | design.clocks.usergenerated                  | Number of user generated clocks                                    | 1                                                                                                       |
#       | design.clocks.autoderived                    | Number of auto-derived clocks                                      | 71                                                                                                      |
#       | design.clocks.virtual                        | Number of virtual clocks                                           | 0                                                                                                       |
#       | design.ips.list                              | List of IPs                                                        |                                                                                                         |
#       | design.ips                                   | Number of IPs                                                      | 0                                                                                                       |
#       | design.nets                                  | Number of nets                                                     | 1000680                                                                                                 |
#       | design.nets.slls                             | Number of SLL nets                                                 | 7077                                                                                                    |
#       | design.pblocks                               | Number of pblocks                                                  | 0                                                                                                       |
#       | design.ports                                 | Number of ports                                                    | 587                                                                                                     |
#       | design.slrs                                  | Number of SLRs                                                     | 3                                                                                                       |
#       | design.slls                                  | SLLs Connections                                                   | SLR1->SLR2 {16 9 7 85 879 486 824 649 510 30 0 0} SLR0->SLR1 {1 4 12 164 317 943 1286 657 247 48 30 16} |
#       +----------------------------------------------+--------------------------------------------------------------------+---------------------------------------------------------------------------------------------------------+
#       | utilization.clb.ff                           | CLB Registers                                                      | 387901                                                                                                  |
#       | utilization.clb.ff.pct                       | CLB Registers (%)                                                  | 20.94                                                                                                   |
#       | utilization.clb.lut                          | CLB LUTs                                                           | 366488                                                                                                  |
#       | utilization.clb.lut.pct                      | CLB LUTs (%)                                                       | 39.56                                                                                                   |
#       | utilization.clb.lutmem                       | LUT as Memory                                                      | 2543                                                                                                    |
#       | utilization.clb.lutmem.pct                   | LUT as Memory (%)                                                  | 5.11                                                                                                    |
#       | utilization.clb.carry8                       | CARRY8                                                             | 2882                                                                                                    |
#       | utilization.clb.carry8.pct                   | CARRY8 (%)                                                         | 2.29                                                                                                    |
#       | utilization.clb.f7mux                        | F7 Muxes                                                           | 1621                                                                                                    |
#       | utilization.clb.f7mux.pct                    | F7 Muxes (%)                                                       | 0.32                                                                                                    |
#       | utilization.clb.f8mux                        | F8 Muxes                                                           | 42                                                                                                      |
#       | utilization.clb.f8mux.pct                    | F8 Muxes (%)                                                       | 0.02                                                                                                    |
#       | utilization.clb.f9mux                        | F9 Muxes                                                           | 0                                                                                                       |
#       | utilization.clb.f9mux.pct                    | F9 Muxes (%)                                                       | 0.00                                                                                                    |
#       | utilization.ctrlsets.lost                    | Registers Lost due to Control Sets                                 | n/a                                                                                                     |
#       | utilization.ctrlsets.uniq                    | Unique Control Sets                                                | 14096                                                                                                   |
#       | utilization.clk.bufgce                       | BUFGCE Buffers                                                     | 22                                                                                                      |
#       | utilization.clk.bufgce.pct                   | BUFGCE Buffers (%)                                                 | 3.27                                                                                                    |
#       | utilization.clk.bufgcediv                    | BUFGCE_DIV Buffers                                                 | 0                                                                                                       |
#       | utilization.clk.bufgcediv.pct                | BUFGCE_DIV Buffers (%)                                             | 0.00                                                                                                    |
#       | utilization.clk.bufggt                       | BUFG_GT Buffers                                                    | 21                                                                                                      |
#       | utilization.clk.bufggt.pct                   | BUFG_GT Buffers (%)                                                | 3.13                                                                                                    |
#       | utilization.clk.bufgps                       | BUFG_PS Buffers                                                    | n/a                                                                                                     |
#       | utilization.clk.bufgps.pct                   | BUFG_PS Buffers (%)                                                | n/a                                                                                                     |
#       | utilization.clk.bufgctrl                     | BUFGCTRL Buffers                                                   | 0                                                                                                       |
#       | utilization.clk.bufgctrl.pct                 | BUFGCTRL Buffers (%)                                               | 0.00                                                                                                    |
#       | utilization.dsp                              | DSPs                                                               | 0                                                                                                       |
#       | utilization.dsp.pct                          | DSPs (%)                                                           | 0.00                                                                                                    |
#       | utilization.io                               | IOs                                                                | 501                                                                                                     |
#       | utilization.io.pct                           | IOs (%)                                                            | 71.98                                                                                                   |
#       | utilization.ram.blockram                     | RAM (Blocks)                                                       | 1639                                                                                                    |
#       | utilization.ram.distributedram               | RAM (Distributed)                                                  | 2914                                                                                                    |
#       | utilization.ram.tile                         | Block RAM Tile                                                     | 1732.5                                                                                                  |
#       | utilization.ram.tile.pct                     | Block RAM Tile (%)                                                 | 52.88                                                                                                   |
#       | utilization.clb.lutmem                       | LUT as Memory                                                      | 11240                                                                                                   |
#       | utilization.clk.all                          | BUFG* Buffers                                                      | 22                                                                                                      |
#       +----------------------------------------------+--------------------------------------------------------------------+---------------------------------------------------------------------------------------------------------+
#       | timing.wns                                   | WNS                                                                | -0.019                                                                                                  |
#       | timing.tns                                   | TNS                                                                | -0.019                                                                                                  |
#       | timing.tnsFallingEp                          | TNS Failing Endpoints                                              | 1                                                                                                       |
#       | timing.tnsTotalEp                            | TNS Total Endpoints                                                | 933907                                                                                                  |
#       | timing.wns.spclock                           | WNS Startpoint Clock                                               | clk_out1_System_Clock                                                                                   |
#       | timing.wns.epclock                           | WNS Endpoint Clock                                                 | clk_out1_System_Clock                                                                                   |
#       | timing.wns.primitives                        | WNS Path                                                           | FIFO36E2 FDRE                                                                                           |
#       | timing.whs                                   | WHS                                                                | 0.030                                                                                                   |
#       | timing.ths                                   | THS                                                                | 0.000                                                                                                   |
#       | timing.thsFallingEp                          | THS Failing Endpoints                                              | 0                                                                                                       |
#       | timing.thsTotalEp                            | THS Total Endpoints                                                | 931559                                                                                                  |
#       | timing.whs.spclock                           | WHS Startpoint Clock                                               | P3RxClk                                                                                                 |
#       | timing.whs.epclock                           | WHS Endpoint Clock                                                 | P3RxClk                                                                                                 |
#       | timing.whs.primitives                        | WHS Path                                                           | FDRE LUT4 FDRE                                                                                          |
#       | timing.wpws                                  | WPWS                                                               | 0.000                                                                                                   |
#       | timing.tpws                                  | TPWS                                                               | 0.000                                                                                                   |
#       | timing.tpwsFailingEp                         | TPWS Failing Endpoints                                             | 0                                                                                                       |
#       | timing.tpwsTotalEp                           | TPWS Total Endpoints                                               | 411984                                                                                                  |
#       +----------------------------------------------+--------------------------------------------------------------------+---------------------------------------------------------------------------------------------------------+
#       | clockpair.0.wns                              | Clock Pair (WNS)                                                   | -0.02                                                                                                   |
#       | clockpair.0.tns                              | Clock Pair (TNS)                                                   | -0.02                                                                                                   |
#       | clockpair.0.from                             | Clock Pair (From)                                                  | clk_out1_System_Clock                                                                                   |
#       | clockpair.0.to                               | Clock Pair (To)                                                    | clk_out1_System_Clock                                                                                   |
#       | clockpair.1.wns                              | Clock Pair (WNS)                                                   | 0.01                                                                                                    |
#       | clockpair.1.tns                              | Clock Pair (TNS)                                                   | 0.00                                                                                                    |
#       | clockpair.1.from                             | Clock Pair (From)                                                  | clk_out2_System_Clock                                                                                   |
#       | clockpair.1.to                               | Clock Pair (To)                                                    | clk_out2_System_Clock                                                                                   |
#       | clockpair.2.wns                              | Clock Pair (WNS)                                                   | 0.02                                                                                                    |
#       | clockpair.2.tns                              | Clock Pair (TNS)                                                   | 0.00                                                                                                    |
#       | clockpair.2.from                             | Clock Pair (From)                                                  | P4RxClk                                                                                                 |
#       | clockpair.2.to                               | Clock Pair (To)                                                    | P4RxClk                                                                                                 |
#       | clockpair.3.wns                              | Clock Pair (WNS)                                                   | 0.03                                                                                                    |
#       | clockpair.3.tns                              | Clock Pair (TNS)                                                   | 0.00                                                                                                    |
#       | clockpair.3.from                             | Clock Pair (From)                                                  | P2RxClk                                                                                                 |
#       | clockpair.3.to                               | Clock Pair (To)                                                    | P2RxClk                                                                                                 |
#       | clockpair.4.wns                              | Clock Pair (WNS)                                                   | 0.04                                                                                                    |
#       | clockpair.4.tns                              | Clock Pair (TNS)                                                   | 0.00                                                                                                    |
#       | clockpair.4.from                             | Clock Pair (From)                                                  | P3RxClk                                                                                                 |
#       | clockpair.4.to                               | Clock Pair (To)                                                    | P3RxClk                                                                                                 |
#       | clockpair.5.wns                              | Clock Pair (WNS)                                                   | 0.08                                                                                                    |
#       | clockpair.5.tns                              | Clock Pair (TNS)                                                   | 0.00                                                                                                    |
#       | clockpair.5.from                             | Clock Pair (From)                                                  | P1RxClk                                                                                                 |
#       | clockpair.5.to                               | Clock Pair (To)                                                    | P1RxClk                                                                                                 |
#       | clockpair.6.wns                              | Clock Pair (WNS)                                                   | 0.20                                                                                                    |
#       | clockpair.6.tns                              | Clock Pair (TNS)                                                   | 0.00                                                                                                    |
#       | clockpair.6.from                             | Clock Pair (From)                                                  | mmcm_clkout0_3                                                                                          |
#       | clockpair.6.to                               | Clock Pair (To)                                                    | mmcm_clkout0_3                                                                                          |
#       | clockpair.7.wns                              | Clock Pair (WNS)                                                   | 0.30                                                                                                    |
#       | clockpair.7.tns                              | Clock Pair (TNS)                                                   | 0.00                                                                                                    |
#       | clockpair.7.from                             | Clock Pair (From)                                                  | clk_out1_Timestamp_Clock                                                                                |
#       | clockpair.7.to                               | Clock Pair (To)                                                    | clk_out1_Timestamp_Clock                                                                                |
#       | clockpair.8.wns                              | Clock Pair (WNS)                                                   | 0.37                                                                                                    |
#       | clockpair.8.tns                              | Clock Pair (TNS)                                                   | 0.00                                                                                                    |
#       | clockpair.8.from                             | Clock Pair (From)                                                  | clk_out2_Timestamp_Clock                                                                                |
#       | clockpair.8.to                               | Clock Pair (To)                                                    | clk_out2_Timestamp_Clock                                                                                |
#       | clockpair.9.wns                              | Clock Pair (WNS)                                                   | 0.41                                                                                                    |
#       | clockpair.9.tns                              | Clock Pair (TNS)                                                   | 0.00                                                                                                    |
#       | clockpair.9.from                             | Clock Pair (From)                                                  | mmcm_clkout0_1                                                                                          |
#       | clockpair.9.to                               | Clock Pair (To)                                                    | mmcm_clkout0_1                                                                                          |
#       +----------------------------------------------+--------------------------------------------------------------------+---------------------------------------------------------------------------------------------------------+
#       | clkinteraction.timed                         | Clock Interaction (Timed)                                          | 13                                                                                                      |
#       | clkinteraction.timed_unsafe                  | Clock Interaction (Timed (unsafe))                                 | 1                                                                                                       |
#       | clkinteraction.asynchronous_groups           | Clock Interaction (Asynchronous Groups)                            | 2                                                                                                       |
#       | clkinteraction.false_path                    | Clock Interaction (False Path)                                     | 96                                                                                                      |
#       | clkinteraction.partial_false_path            | Clock Interaction (Partial False Path)                             | 16                                                                                                      |
#       +----------------------------------------------+--------------------------------------------------------------------+---------------------------------------------------------------------------------------------------------+
#       | checktiming.constant_clock                   | check_timing (constant_clock)                                      | 0                                                                                                       |
#       | checktiming.generated_clocks                 | check_timing (generated_clocks)                                    | 0                                                                                                       |
#       | checktiming.latch_loops                      | check_timing (latch_loops)                                         | 0                                                                                                       |
#       | checktiming.loops                            | check_timing (loops)                                               | 0                                                                                                       |
#       | checktiming.multiple_clock                   | check_timing (multiple_clock)                                      | 0                                                                                                       |
#       | checktiming.no_clock                         | check_timing (no_clock)                                            | 0                                                                                                       |
#       | checktiming.no_input_delay                   | check_timing (no_input_delay)                                      | 15                                                                                                      |
#       | checktiming.no_output_delay                  | check_timing (no_output_delay)                                     | 19                                                                                                      |
#       | checktiming.partial_input_delay              | check_timing (partial_input_delay)                                 | 0                                                                                                       |
#       | checktiming.partial_output_delay             | check_timing (partial_output_delay)                                | 0                                                                                                       |
#       | checktiming.pulse_width_clock                | check_timing (pulse_width_clock)                                   | 0                                                                                                       |
#       | checktiming.unconstrained_internal_endpoints | check_timing (unconstrained_internal_endpoints)                    | 0                                                                                                       |
#       +----------------------------------------------+--------------------------------------------------------------------+---------------------------------------------------------------------------------------------------------+
#       | congestion.placer                            | Placer Congestion (N-S-E-W)                                        | 5-5-4-3                                                                                                 |
#       | congestion.router                            | Router Congestion (N-S-E-W)                                        | 0-1-0-0                                                                                                 |
#       +----------------------------------------------+--------------------------------------------------------------------+---------------------------------------------------------------------------------------------------------+
#       | route.nets                                   | Routable nets                                                      | 708670                                                                                                  |
#       | route.routed                                 | Fully routed nets                                                  | 708670                                                                                                  |
#       | route.fixed                                  | Nets with fixed routing                                            | n/a                                                                                                     |
#       | route.errors                                 | Nets with routing errors                                           | 0                                                                                                       |
#       +----------------------------------------------+--------------------------------------------------------------------+---------------------------------------------------------------------------------------------------------+
#       | cdc.cdc-1                                    | 1-bit unknown CDC circuitry (Critical)                             | 7611                                                                                                    |
#       | cdc.cdc-2                                    | 1-bit synchronized with missing ASYNC_REG property (Warning)       | 16                                                                                                      |
#       | cdc.cdc-3                                    | 1-bit synchronized with ASYNC_REG property (Info)                  | 488                                                                                                     |
#       | cdc.cdc-4                                    | Multi-bit unknown CDC circuitry (Critical)                         | 6                                                                                                       |
#       | cdc.cdc-5                                    | Multi-bit synchronized with missing ASYNC_REG property (Warning)   | 25                                                                                                      |
#       | cdc.cdc-6                                    | Multi-bit synchronized with ASYNC_REG property (Warning)           | 50                                                                                                      |
#       | cdc.cdc-7                                    | Asynchronous reset unknown CDC circuitry (Critical)                | 5265                                                                                                    |
#       | cdc.cdc-9                                    | Asynchronous reset synchronized with ASYNC_REG property (Info)     | 56                                                                                                      |
#       | cdc.cdc-10                                   | Combinatorial logic detected before a synchronizer (Critical)      | 11                                                                                                      |
#       | cdc.cdc-11                                   | Fan-out from launch flop to destination clock (Critical)           | 4                                                                                                       |
#       | cdc.cdc-12                                   | Multi-clock fan-in to synchronizer (Critical)                      | 123                                                                                                     |
#       | cdc.cdc-13                                   | 1-bit CDC path on a non-FD primitive (Critical)                    | 1908                                                                                                    |
#       | cdc.cdc-14                                   | Multi-bit CDC path on a non-FD primitive (Critical)                | 630                                                                                                     |
#       | cdc.cdc-15                                   | Clock enable controlled CDC structure detected (Warning)           | 26095                                                                                                   |
#       +----------------------------------------------+--------------------------------------------------------------------+---------------------------------------------------------------------------------------------------------+
#       | methodology.clkc-21                          | MMCME3 with ZHOLD does not drive sequential IO (Advisory)          | 1                                                                                                       |
#       | methodology.clkc-23                          | MMCME3 with ZHOLD drives sequential IO not with CLKOUT0 (Advisory) | 1                                                                                                       |
#       | methodology.clkc-39                          | Substitute PLLE3 for MMCME3 check (Advisory)                       | 3                                                                                                       |
#       | methodology.pdrc-190                         | Suboptimally placed synchronized register chain (Warning)          | 1                                                                                                       |
#       | methodology.timing-9                         | Unknown CDC Logic (Warning)                                        | 1                                                                                                       |
#       | methodology.timing-10                        | Missing property on synchronizer (Warning)                         | 1                                                                                                       |
#       | methodology.timing-11                        | Inappropriate max delay with datapath only option (Warning)        | 16                                                                                                      |
#       | methodology.timing-18                        | Missing input or output delay (Warning)                            | 54                                                                                                      |
#       | methodology.timing-24                        | Overridden Max delay datapath only (Warning)                       | 110                                                                                                     |
#       | methodology.timing-28                        | Auto-derived clock referenced by a timing constraint (Warning)     | 210                                                                                                     |
#       +----------------------------------------------+--------------------------------------------------------------------+---------------------------------------------------------------------------------------------------------+
#       | drc.bivc-1                                   | Bank IO standard Vcc  - IOBank:72 (Error)                          | 4                                                                                                       |
#       | drc.pdcn-1569                                | LUT equation term check (Warning)                                  | 272                                                                                                     |
#       | drc.pdrc-203                                 | BITSLICE0 not available during BISC (Critical)                     | 3                                                                                                       |
#       | drc.reqp-1857                                | RAMB18E2_writefirst_collision_advisory (Advisory)                  | 18                                                                                                      |
#       | drc.reqp-1858                                | RAMB36E2_writefirst_collision_advisory (Advisory)                  | 535                                                                                                     |
#       | drc.reqp-1935                                | RAMB36E2_nochange_collision_advisory (Advisory)                    | 128                                                                                                     |
#       | drc.rpbf-3                                   | IO port buffering is incomplete (Warning)                          | 4                                                                                                       |
#       | drc.rtstat-10                                | No routable loads (Warning)                                        | 1                                                                                                       |
#       +----------------------------------------------+--------------------------------------------------------------------+---------------------------------------------------------------------------------------------------------+
#       | constraints.create_clock                     | create_clock                                                       | 14                                                                                                      |
#       | constraints.create_generated_clock           | create_generated_clock                                             | 1                                                                                                       |
#       | constraints.group_path                       | group_path                                                         | 0                                                                                                       |
#       | constraints.set_bus_skew                     | set_bus_skew                                                       | 0                                                                                                       |
#       | constraints.set_case_analysis                | set_case_analysis                                                  | 15                                                                                                      |
#       | constraints.set_clock_groups                 | set_clock_groups                                                   | 1                                                                                                       |
#       | constraints.set_clock_latency                | set_clock_latency                                                  | 0                                                                                                       |
#       | constraints.set_clock_sense                  | set_clock_sense                                                    | 0                                                                                                       |
#       | constraints.set_clock_uncertainty            | set_clock_uncertainty                                              | 0                                                                                                       |
#       | constraints.set_data_check                   | set_data_check                                                     | 0                                                                                                       |
#       | constraints.set_disable_timing               | set_disable_timing                                                 | 8                                                                                                       |
#       | constraints.set_external_delay               | set_external_delay                                                 | 0                                                                                                       |
#       | constraints.set_false_path                   | set_false_path                                                     | 480                                                                                                     |
#       | constraints.set_input_delay                  | set_input_delay                                                    | 0                                                                                                       |
#       | constraints.set_input_jitter                 | set_input_jitter                                                   | 2                                                                                                       |
#       | constraints.set_max_delay                    | set_max_delay                                                      | 170                                                                                                     |
#       | constraints.set_min_delay                    | set_min_delay                                                      | 0                                                                                                       |
#       | constraints.set_multicycle_path              | set_multicycle_path                                                | 10                                                                                                      |
#       | constraints.set_output_delay                 | set_output_delay                                                   | 0                                                                                                       |
#       | constraints.set_system_jitter                | set_system_jitter                                                  | 0                                                                                                       |
#       +----------------------------------------------+--------------------------------------------------------------------+---------------------------------------------------------------------------------------------------------+

# Example of code for .Xilinx/Vivado/init.tcl
#   # Design summary (support for project mode)
#   switch -glob -- [uplevel #0 pwd] {
#     /home/dpefour/myproject/* {
#       package require toolbox
#       source /home/dpefour/git/scripts/wip/report_design_summary.tcl
#       tb::utils::report_design_summary::config_flow_automation -enable -project myproject -experiment myexperiment -version [lindex [file split [uplevel #0 pwd]] end]
#     }
#   }

namespace eval ::tb {
#   namespace export -force report_design_summary
#   namespace export -force config_flow_automation
}

namespace eval ::tb::utils {
  namespace export -force report_design_summary
  namespace export -force config_flow_automation
}

namespace eval ::tb::utils::report_design_summary {
  namespace export -force report_design_summary
  namespace export -force config_flow_automation
  variable version {2016.11.07}
  variable params
  variable output {}
  variable reports
  variable metrics
  variable tracedb
  array set params [list project {} version {} release {} experiment {} step {} directive {} runtime 0 vivado 1 format {table} incremental 0 verbose 0 debug 0]
  array set reports [list]
  array set metrics [list]
#   array set tracedb [list prefix {} vivadolog {} count 0 dir [uplevel #0 pwd] enter {} leave {} history {} cmdlist {opt_design place_design phys_opt_design route_design} cmdline {-verbose -details -all -exclude {cdc drc methodology} -csv} callback {::tb::utils::report_design_summary::callbackAutomation} ]
  array set tracedb [list prefix {} vivadolog {} count 0 dir [uplevel #0 pwd] enter {} leave {} history {} cmdlist {opt_design place_design phys_opt_design route_design} cmdline {-verbose -details -timing -utilization -route -csv} callback {::tb::utils::report_design_summary::callbackAutomation} ]
#   array set tracedb [list prefix {} vivadolog {} count 0 dir [uplevel #0 pwd] enter {} leave {} history {} cmdlist {opt_design place_design phys_opt_design route_design} cmdline {-verbose -details -all -exclude {cdc drc methodology check_timing constraints clock_interaction congestion} -csv} callback {::tb::utils::report_design_summary::callbackAutomation} ]
}

proc ::tb::utils::report_design_summary::lshift {inputlist} {
  upvar $inputlist argv
  set arg  [lindex $argv 0]
  set argv [lrange $argv 1 end]
  return $arg
}

proc ::tb::utils::report_design_summary::report_design_summary {args} {
  variable reports
  variable metrics
  variable params
  variable output
#   catch {unset metrics}
#   catch {unset reports}
  set params(vivado) 1
  set params(incremental) 0
  set params(verbose) 0
  set params(debug) 0
  set params(format) {table}
  set sections {default}
  set excludesections [list]
  set filename {}
  set filemode {w}
  set hidemissing 0
  set returnstring 0
  set returnmetrics 0
  set usermetrics [list]
#   set project {}
#   set version {}
#   set experiment {}
#   set step {}
#   set directive {}
  set project $params(project)
  set version $params(version)
  set experiment $params(experiment)
  set step $params(step)
  set directive $params(directive)
  set runtime {}
  set time [clock seconds]
  set date [clock format $time]
  set showdetails 0
  set prescript {}
  set postscript {}
  set precommand {}
  set postcommand {}
  set reportTimingSummary {}
  set reportDesignAnalysis {}
  set reportRamUtilization {}
  set reportCheckTiming {}
  set reportUtilization {}
  set reportClockInteraction {}
  set reportRouteStatus {}
  set reportCDC {}
  set reportMethodology {}
  set reportDRC {}
  set vivadoLog {}
  set saveReports 0
  set saveReportsPrefix {}
  set error 0
  set help 0
#   if {[llength $args] == 0} {
#     set help 1
#   }
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-f(i(le?)?)?$} {
        set filename [lshift args]
      }
      {^-ap(p(e(nd?)?)?)?$} {
        set filemode {a}
      }
      {^-csv?$} {
        set params(format) {csv}
      }
      {^-hi(d(e(_(m(i(s(s(i(ng?)?)?)?)?)?)?)?)?)?$} -
      {^-hide_missing$} {
        set hidemissing 1
      }
      {^-a(ll?)?$} {
        set sections [concat $sections [list utilization \
                                             constraints \
                                             timing \
                                             clock_interaction \
                                             congestion \
                                             check_timing \
                                             cdc \
                                             drc \
                                             methodology \
                                             route_status] ]
      }
      {^-ex(c(l(u(de?)?)?)?)?$} {
        foreach el [lshift args] {
          lappend excludesections $el
        }
      }
      {^-c(h(e(c(k(_(t(i(m(i(ng?)?)?)?)?)?)?)?)?)?)?$} {
        lappend sections {check_timing}
      }
      {^-r(o(u(te?)?)?)?$} {
        lappend sections {route_status}
      }
      {^-cdc?$} {
        lappend sections {cdc}
      }
      {^-drc?$} {
        lappend sections {drc}
      }
      {^-me(t(h(o(d(o(l(o(gy?)?)?)?)?)?)?)?)?$} {
        lappend sections {methodology}
      }
      {^-cl(o(c(k(_(i(n(t(e(r(a(c(t(i(on?)?)?)?)?)?)?)?)?)?)?)?)?)?)?$} {
        lappend sections {clock_interaction}
      }
      {^-u(t(i(l(i(z(a(t(i(on?)?)?)?)?)?)?)?)?)?$} {
        lappend sections {utilization}
      }
      {^-cons(t(r(a(i(n(ts?)?)?)?)?)?)?$} {
        lappend sections {constraints}
      }
      {^-t(i(m(i(ng?)?)?)?)?$} {
        lappend sections {timing}
      }
      {^-cong(e(s(t(i(on?)?)?)?)?)?$} {
        lappend sections {congestion}
      }
      {^-pr(o(j(e(ct?)?)?)?)?$} {
        set project [lshift args]
      }
      {^-ve(r(s(i(on?)?)?)?)?$} {
        set version [lshift args]
      }
      {^-ex(p(e(r(i(m(e(nt?)?)?)?)?)?)?)?$} {
        set experiment [lshift args]
      }
      {^-st(ep?)?$} {
        set step [lshift args]
      }
      {^-di(r(e(c(t(i(ve?)?)?)?)?)?)?$} {
        set directive [lshift args]
      }
      {^-run(t(i(me?)?)?)?$} {
        set runtime [lshift args]
      }
      {^-ti(me?)?$} {
        set time [lshift args]
      }
      {^-da(te?)?$} {
        set date [lshift args]
      }
      {^-de(t(a(i(ls?)?)?)?)?$} {
        set showdetails 1
      }
      {^-in(c(r(e(m(e(n(t(al?)?)?)?)?)?)?)?)?$} {
        set params(incremental) 1
      }
      {^-return_s(t(r(i(ng?)?)?)?)?$} {
        set returnstring 1
      }
      {^-return_m(e(t(r(i(cs?)?)?)?)?)?$} {
        set returnmetrics 1
      }
      {^-ad(d(_(m(e(t(r(i(cs?)?)?)?)?)?)?)?)?$} {
        set usermetrics [concat $usermetrics [lshift args]]
      }
      -rts -
      -report_timing_summary {
        set reportTimingSummary [lshift args]
        if {![file exists $reportTimingSummary]} {
          puts " -E- file '$reportTimingSummary' does not exist"
          incr error
        }
      }
      -ct -
      -rct -
      -report_check_timing {
        set reportCheckTiming [lshift args]
        if {![file exists $reportCheckTiming]} {
          puts " -E- file '$reportCheckTiming' does not exist"
          incr error
        }
      }
      -rda -
      -report_design_analysis {
        set reportDesignAnalysis [lshift args]
        if {![file exists $reportDesignAnalysis]} {
          puts " -E- file '$reportDesignAnalysis' does not exist"
          incr error
        }
      }
      -rci -
      -report_clock_interaction {
        set reportClockInteraction [lshift args]
        if {![file exists $reportClockInteraction]} {
          puts " -E- file '$reportClockInteraction' does not exist"
          incr error
        }
      }
      -ru -
      -report_utilization {
        set reportUtilization [lshift args]
        if {![file exists $reportUtilization]} {
          puts " -E- file '$reportUtilization' does not exist"
          incr error
        }
      }
      -rru -
      -report_ram_utilization {
        set reportRamUtilization [lshift args]
        if {![file exists $reportRamUtilization]} {
          puts " -E- file '$reportRamUtilization' does not exist"
          incr error
        }
      }
      -rrs -
      -report_route_status {
        set reportRouteStatus [lshift args]
        if {![file exists $reportRouteStatus]} {
          puts " -E- file '$reportRouteStatus' does not exist"
          incr error
        }
      }
      -rcdc -
      -report_cdc {
        set reportCDC [lshift args]
        if {![file exists $reportCDC]} {
          puts " -E- file '$reportCDC' does not exist"
          incr error
        }
      }
      -rm -
      -report_methodology {
        set reportMethodology [lshift args]
        if {![file exists $reportMethodology]} {
          puts " -E- file '$reportMethodology' does not exist"
          incr error
        }
      }
      -rdrc -
      -report_drc {
        set reportDRC [lshift args]
        if {![file exists $reportDRC]} {
          puts " -E- file '$reportDRC' does not exist"
          incr error
        }
      }
      {^-sa(v(e(_(r(e(p(o(r(ts?)?)?)?)?)?)?)?)?)?$} {
        set saveReports 1
        set saveReportsPrefix [lshift args]
      }
      {^-tclpre$} {
        set prescript [lshift args]
      }
      {^-tclpost$} {
        set postscript [lshift args]
      }
      {^-tclprecmd$} {
        set precommand [lshift args]
      }
      {^-tclpostcmd$} {
        set postcommand [lshift args]
      }
      {^-vi(v(a(d(o(l(og?)?)?)?)?)?)?$} {
        set vivadoLog [lshift args]
      }
      {^-v(e(r(b(o(se?)?)?)?)?)?$} {
        set params(verbose) 1
      }
      {^-d(e(b(ug?)?)?)?$} {
        set params(debug) 1
      }
      {^-h(e(lp?)?)?$} {
        set help 1
      }
      default {
        if {[string match "-*" $name]} {
          puts " -E- option '$name' is not a valid option."
          incr error
        } else {
          puts " -E- option '$name' is not a valid option."
          incr error
        }
      }
    }
  }

  if {$help} {
    puts [format {
  Usage: report_design_summary
            +--------------------+
              [-all]
              [-utilization]
              [-timing]
              [-congestion]
              [-constraints]
              [-check_timing]
              [-cdc]
              [-drc]
              [-methodology]
              [-clock_interaction]
              [-route]
              [-exclude <list_sections>]
              [-vivadolog <filename>]
            +--------------------+
              [-project <string>]
              [-version <string>]
              [-experiment <string>]
              [-step <string>]
              [-directive <string>]
              [-runtime <string>]
              [-date <string>]
              [-time <string>]
            +--------------------+
              [-rts <filename>|-report_timing_summary <filename>]
              [-rct <filename>|-report_check_timing <filename>]
              [-rda <filename>|-report_design_analysis <filename>]
              [-rci <filename>|-report_clock_interaction <filename>]
              [-ru <filename>|-report_utilization <filename>]
              [-rru <filename>|-report_ram_utilization <filename>]
              [-rrs <filename>|-report_route_status <filename>]
              [-rcdc <filename>|-report_cdc <filename>]
              [-rdrc <filename>|-report_drc <filename>]
              [-rm <filename>|-report_methodology <filename>]
            +--------------------+
              [-details]
              [-file <filename>]
              [-append]
              [-csv]
              [-incremental]
              [-hide_missing]
              [-return_string]
              [-return_metrics]
              [-save_reports <prefix>]
              [-add_metrics <list_user_metrics>]
              [-tclpre <filename>]
              [-tclpost <filename>]
              [-tclprecmd <command>]
              [-tclpostcmd <command>]
              [-verbose|-v]
              [-help|-h]

  Description: Generate a design summary report

    Use -vivadolog to point to Vivado log file to extract additional metrics
    Use -details with -file to append full reports
    Use -project/-version/-experiment/-step/-directive/-runtime to save informative tags
    Use -hide_missing to suppress metrics that have not been found
    Use -rts/-ct/-rda/-rrs/-rci/-ru/-rru/-rcdc/-rm to import on-disk reports
    Use -incremental for incremental mode
    Use -tclpre/-tclpost to provide a user scripts to be sourced
      at the beginning and at the end
    Use -tclprecmd/-tclpostcmd to provide a command to be executed
      at the beginning and at the end
    Use -return_metrics to return a Tcl list of metrics
    Use -save_reports to save all reports on disk
    Use -add_metrics to add custom metrics
    Use -exclude to exclude sections. Valid sections:
      utilization|constraints|timing|clock_interaction|congestion
      check_timing|cdc|methodology|drc|route_status

  Example:
     tb::report_design_summary -file myreport.rpt -details -all
     tb::report_design_summary -timing -csv -return_string -hide_missing
     tb::report_design_summary -vivadolog ./vivado.log -all -csv -file summary.csv
     tb::report_design_summary -vivadolog ./vivado.log -all -csv -file summary.csv -save_reports postroute -step route_design -verbose
} ]
    # HELP -->
    return -code ok
  }

  if {[lsearch -exact [package names] {Vivado}] == -1} {
    # If Vivado package is not found, then the script is not
    # running inside a Vivado session
    set params(vivado) 0
  }

  # Remove sections that have been excluded
  set sections [lsort -unique $sections]
  foreach el $excludesections {
    set posn [lsearch -exact $sections $el]
    if {$posn != -1} {
      set sections [lreplace $sections $posn $posn]
    }
  }

  if {($filename == {}) && $showdetails} {
    puts " -E- -details must be used with -file"
    incr error
  }

  if {($filename != {}) && $returnstring} {
    puts " -E- cannot use -file & -return_string together"
    incr error
  }

  if {$prescript != {}} {
    if {![file exists $prescript]} {
      puts " -E- file '$prescript' does not exist"
      incr error
    } else {
      set prescript [file normalize $prescript]
    }
  }

  if {$postscript != {}} {
    if {![file exists $postscript]} {
      puts " -E- file '$postscript' does not exist"
      incr error
    } else {
      set postscript [file normalize $postscript]
    }
  }

  if {$returnstring && $returnmetrics} {
    puts " -E- cannot use -return_summary & -return_string together"
    incr error
  }

  if {[lsearch $sections {methodology}] != -1} {
    # If -methodology has been selected, make sure Vivado version is above 2016.1
    # (report_methodology from 2016.1 and above)
    # package vcompare [package present Vivado] {1.2016.1}
    if {$params(vivado)} {
      set ver [regsub {\..+$} [version -short] {}]
      if { [regexp {^[0-9]+$} $ver] && ($ver < 2016) && ($reportMethodology == {})} {
        puts " -E- -methodology without -report_methodology can only be used with Vivado 2016.1 and above"
        incr error
      }
    }
  }

  if {$saveReports && ($saveReportsPrefix == {})} {
    puts " -E- invalid empty prefix with -save_reports"
    incr error
  }

  if {$saveReports && [regexp {^\-} $saveReportsPrefix]} {
    puts " -E- invalid prefix '$saveReportsPrefix' with -save_reports"
    incr error
  }

  if {($vivadoLog != {}) && ![file exists $vivadoLog]} {
    puts " -E- Vivado log file '$vivadoLog' does not exist"
    incr error
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  # Remove metrics and reports (if not in incremental mode)
  if {!$params(incremental)} { reset }

  # Import on-disk reports
  if {[file exists $reportTimingSummary]}    { importReport {report_timing_summary}    $reportTimingSummary }
  if {[file exists $reportCheckTiming]}      { importReport {check_timing}             $reportCheckTiming }
  if {[file exists $reportDesignAnalysis]}   { importReport {report_design_analysis}   $reportDesignAnalysis }
  if {[file exists $reportRamUtilization]}   { importReport {report_ram_utilization}   $reportRamUtilization }
  if {[file exists $reportUtilization]}      { importReport {report_utilization}       $reportUtilization }
  if {[file exists $reportClockInteraction]} { importReport {report_clock_interaction} $reportClockInteraction }
  if {[file exists $reportRouteStatus]}      { importReport {report_route_status}      $reportRouteStatus }
  if {[file exists $reportCDC]}              { importReport {report_cdc}               $reportCDC }
  if {[file exists $reportMethodology]}      { importReport {report_methodology}       $reportMethodology }
  if {[file exists $reportDRC]}              { importReport {report_drc}               $reportDRC }

  set startTime [clock seconds]
  set output [list]

  if {[catch {

    ########################################################################################
    ##
    ## Optional pre script / command
    ##
    ########################################################################################

    if {$precommand != {}} {
      puts " -I- Executing pre-command '$precommand'"
      if {[catch { eval $precommand } errorstring]} {
        puts " -E- Pre-command failed: $errorstring"
      }
    }

    if {$prescript != {}} {
      puts " -I- Sourcing pre-script '$prescript'"
      if {[catch { source $prescript } errorstring]} {
        puts " -E- Pre-script failed: $errorstring"
      }
    }

    ########################################################################################
    ##
    ## Add user metrics
    ##
    ########################################################################################

    if {[llength $usermetrics]} {
      foreach el $usermetrics {
        switch [llength $el] {
          2 {
            foreach {metric value} $el { break }
            # Force the metric to have the format: <category>.<something>
            if {![regexp {\.} $metric]} { set metric [format {custom.%s} $metric] }
            addMetric $metric {n/a}
            setMetric $metric $value
          }
          3 {
            foreach {metric description value} $el { break }
            # Force the metric to have the format: <category>.<something>
            if {![regexp {\.} $metric]} { set metric [format {custom.%s} $metric] }
            addMetric $metric $description
            setMetric $metric $value
          }
          default {
            puts " -E- wrong number of elements for '$el'"
          }
        }
      }
    }

    ########################################################################################
    ##
    ##
    ##
    ########################################################################################

    if {[lsearch $sections {default}] != -1} {
      addMetric {vivado.version}   {Vivado Release}
      addMetric {vivado.build}     {Vivado Build}
      addMetric {vivado.plateform} {Plateform}
      addMetric {vivado.os}        {OS}
      addMetric {vivado.os.version} {OS Version}
      addMetric {vivado.top}       {Top Module Name}
      addMetric {vivado.dir}       {Project Directory}

      if {$params(vivado)} {
        setMetric {vivado.version}   [regsub {^([0-9]+\.[0-9]+)\.0$} [version -short] {\1}]
        setMetric {vivado.build}     [regsub {SW Build ([0-9]+).+$} [lindex [split [version] \n] 1] {\1}]
      }
      setMetric {vivado.plateform} $::tcl_platform(platform)
      setMetric {vivado.os}        $::tcl_platform(os)
      setMetric {vivado.os.version} $::tcl_platform(osVersion)
      if {$params(vivado)} {
        setMetric {vivado.top}       [get_property -quiet TOP [current_design -quiet]]
        set dir [get_property -quiet XLNX_PROJ_DIR [current_design -quiet]]
        if {$dir == {}} { set dir [uplevel #0 pwd] }
        setMetric {vivado.dir}       $dir
      }
      catch {
        # For Linux, try to get an OS description such as:
        #   Red Hat Enterprise Linux Workstation release 6.6 (Santiago)
        set res [uplevel #0 [list exec lsb_release -a]]
        foreach line [split $res \n] {
          regexp -nocase {^Description\s*:\s*(.+)\s*$} $line - description
        }
        if {$description != {}} {
          addMetric {vivado.os.description}  {OS Description}
          setMetric {vivado.os.description}  $description
        }
      }
    }

    ########################################################################################
    ##
    ##
    ##
    ########################################################################################

    if {[lsearch $sections {default}] != -1} {
      addMetric {tag.project}      {Project}
      addMetric {tag.version}      {Version}
      addMetric {tag.experiment}   {Experiment}
      addMetric {tag.step}         {Step}
      addMetric {tag.directive}    {Directive}
      addMetric {tag.runtime}      {Runtime}
      addMetric {tag.date}         {Date}
      addMetric {tag.time}         {Time}

      setMetric {tag.project}      $project
      setMetric {tag.version}      $version
      setMetric {tag.experiment}   $experiment
      setMetric {tag.step}         $step
      setMetric {tag.directive}    $directive
      setMetric {tag.runtime}      $runtime
      setMetric {tag.date}         $date
      setMetric {tag.time}         $time
    }

    ########################################################################################
    ##
    ##
    ##
    ########################################################################################

    if {([lsearch $sections {default}] != -1) && $params(vivado)} {
      addMetric {design.part}                   {Part}
      addMetric {design.part.architecture}      {Architecture}
      addMetric {design.part.architecture.name} {Architecture Name}
      addMetric {design.part.speed.class}       {Speed class}
      addMetric {design.part.speed.label}       {Speed label}
      addMetric {design.part.speed.id}          {Speed ID}
      addMetric {design.part.speed.date}        {Speed date}
      addMetric {design.nets}                   {Number of nets}
      addMetric {design.nets.slls}              {Number of SLL nets}
      addMetric {design.cells.primitive}        {Number of primitive cells}
      addMetric {design.cells.hier}             {Number of hierarchical cells}
      addMetric {design.cells.blackbox}         {Number of blackbox cells}
      addMetric {design.cells.ratiofdlut}       {Ratio of registers over LUTs}
      addMetric {design.cells.hlutnm}           {Number of HLUTNM cells}
      addMetric {design.cells.hlutnm.pct}       {Number of HLUTNM cells (%)}
      addMetric {design.ports}                  {Number of ports}
      addMetric {design.clocks}                 {Number of clocks (all inclusive)}
      addMetric {design.clocks.primary}         {Number of primary clocks}
      addMetric {design.clocks.usergenerated}   {Number of user generated clocks}
      addMetric {design.clocks.autoderived}     {Number of auto-derived clocks}
      addMetric {design.clocks.virtual}         {Number of virtual clocks}
      addMetric {design.pblocks}                {Number of pblocks}
      addMetric {design.ips}                    {Number of IPs}
      addMetric {design.ips.list}               {List of IPs}
      addMetric {design.slrs}                   {Number of SLRs}
      if {[llength [get_slrs -quiet]] > 1} {
        if {[regexp {route} $step]} {
          # Only extract this metric in flow step *route*
          addMetric {design.slls}                   {SLLs Connections}
        }
      }

      set part [get_property -quiet PART [current_design]]
      setMetric {design.part}                   $part
      setMetric {design.part.architecture}      [get_property -quiet ARCHITECTURE $part]
      setMetric {design.part.architecture.name} [get_property -quiet ARCHITECTURE_FULL_NAME $part]
      setMetric {design.part.speed.class}       [get_property -quiet SPEED $part]
      setMetric {design.part.speed.label}       [get_property -quiet SPEED_LABEL $part]
      setMetric {design.part.speed.id}          [get_property -quiet SPEED_LEVEL_ID $part]
      setMetric {design.part.speed.date}        [get_property -quiet SPEED_LEVEL_ID_DATE $part]
      setMetric {design.ports}                  [llength [get_ports -quiet]]
      setMetric {design.pblocks}                [llength [get_pblocks -quiet]]
      setMetric {design.ips}                    [llength [get_ips -quiet]]
      setMetric {design.ips.list}               [lsort -unique [get_property -quiet IPDEF [get_ips -quiet]]]
      setMetric {design.slrs}                   [llength [get_slrs -quiet]]

      setMetric {design.nets}         [llength [get_nets -quiet -hier -top_net_of_hierarchical_group -filter {TYPE == SIGNAL}]]
      if {[llength [get_slrs -quiet]] <= 1} {
        setMetric {design.nets.slls} {n/a}
      } else {
        setMetric {design.nets.slls}  [llength [get_nets -quiet -hier -top_net_of_hierarchical_group -filter {CROSSING_SLRS != ""}]]
      }

      set cells [get_cells -quiet -hier]
      setMetric {design.cells.primitive}  [llength [filter -quiet $cells {IS_PRIMITIVE}]]
      setMetric {design.cells.hier}       [llength [filter -quiet $cells {!IS_PRIMITIVE}]]
      setMetric {design.cells.blackbox}   [llength [filter -quiet $cells {IS_BLACKBOX}]]
      set fds [filter -quiet $cells {IS_PRIMITIVE && REF_NAME =~ FD*}]
      set luts [filter -quiet $cells {IS_PRIMITIVE && REF_NAME =~ LUT*}]
      if {[llength $luts]} {
        setMetric {design.cells.ratiofdlut} [format {%.2f} [expr double([llength $fds]) / double([llength $luts])]]
      } else {
        setMetric {design.cells.ratiofdlut} {n/a}
      }
      set hlutnm [filter -quiet $luts {SOFT_HLUTNM != "" || HLUTNM != ""}]
      setMetric {design.cells.hlutnm} [llength $hlutnm]
      if {[llength $luts]} {
        # Calculate the percent of HLUTNM over the total number of LUT
        setMetric {design.cells.hlutnm.pct} [format {%.2f} [expr {100.0 * double([llength $hlutnm]) / double([llength $luts])}] ]
      } else {
        setMetric {design.cells.hlutnm.pct} {n/a}
      }

      set clocks [get_clocks -quiet]
      setMetric {design.clocks}               [llength $clocks]
      setMetric {design.clocks.primary}       [llength [filter -quiet $clocks {!IS_GENERATED}] ]
      setMetric {design.clocks.usergenerated} [llength [filter -quiet $clocks {!IS_VIRTUAL && IS_GENERATED && IS_USER_GENERATED}] ]
      setMetric {design.clocks.autoderived}   [llength [filter -quiet $clocks {!IS_VIRTUAL && IS_GENERATED && !IS_USER_GENERATED}] ]
      setMetric {design.clocks.virtual}       [llength [filter -quiet $clocks {IS_VIRTUAL}] ]

      if {[llength [get_slrs -quiet]] > 1} {
        if {[regexp {route} $step]} {
          # Only extract the SSLs metric in flow step *route*
          # SLLs connections using tb::report_slls (7-serie not supported)
          set SLLs {n/a}
          catch { set SLLs [tb::report_slls -return_summary] }
          setMetric {design.slls}     $SLLs
        }
      }
    }

    ########################################################################################
    ##
    ## Timing metrics
    ##
    ########################################################################################

    if {[lsearch $sections {timing}] != -1} {
      # Get report
#       set report [split [getReport {report_timing_summary} {-quiet -no_detailed_paths -no_check_timing -no_header}] \n]
      set report [split [getReport {report_timing_summary} {-quiet -no_detailed_paths -no_check_timing}] \n]

      addMetric {timing.wns}             {WNS}
      addMetric {timing.wns.path}        {WNS Path}
      addMetric {timing.tns}             {TNS}
      addMetric {timing.tnsFallingEp}    {TNS Failing Endpoints}
      addMetric {timing.tnsTotalEp}      {TNS Total Endpoints}
      addMetric {timing.whs}             {WHS}
      addMetric {timing.whs.path}        {WHS Path}
      addMetric {timing.ths}             {THS}
      addMetric {timing.thsFallingEp}    {THS Failing Endpoints}
      addMetric {timing.thsTotalEp}      {THS Total Endpoints}
      addMetric {timing.wpws}            {WPWS}
      addMetric {timing.tpws}            {TPWS}
      addMetric {timing.tpwsFailingEp}   {TPWS Failing Endpoints}
      addMetric {timing.tpwsTotalEp}     {TPWS Total Endpoints}
      addMetric {timing.wns.spclock}     {WNS Startpoint Clock}
      addMetric {timing.wns.epclock}     {WNS Endpoint Clock}
      addMetric {timing.whs.spclock}     {WHS Startpoint Clock}
      addMetric {timing.whs.epclock}     {WHS Endpoint Clock}

      # Extract metrics
      if {[set i [lsearch -regexp $report {Design Timing Summary}]] != -1} {
         foreach {wns tns tnsFallingEp tnsTotalEp whs ths thsFallingEp thsTotalEp wpws tpws tpwsFailingEp tpwsTotalEp} [regexp -inline -all -- {\S+} [lindex $report [expr $i + 6]]] { break }
         setMetric {timing.wns}           $wns
         setMetric {timing.tns}           $tns
         setMetric {timing.tnsFallingEp}  $tnsFallingEp
         setMetric {timing.tnsTotalEp}    $tnsTotalEp
         setMetric {timing.whs}           $whs
         setMetric {timing.ths}           $ths
         setMetric {timing.thsFallingEp}  $thsFallingEp
         setMetric {timing.thsTotalEp}    $thsTotalEp
         setMetric {timing.wpws}          $wpws
         setMetric {timing.tpws}          $tpws
         setMetric {timing.tpwsFailingEp} $tpwsFailingEp
         setMetric {timing.tpwsTotalEp}   $tpwsTotalEp
      }
    }

    if {([lsearch $sections {timing}] != -1) && $params(vivado)} {
      # Saving startpoint/endpoint clock(s) of WNS path
      set wnsPath [get_timing_paths -quiet -setup -max_paths 1]
      set spClk [get_property -quiet STARTPOINT_CLOCK $wnsPath]
      set epClk [get_property -quiet ENDPOINT_CLOCK $wnsPath]
      setMetric {timing.wns.spclock}   $spClk
      setMetric {timing.wns.epclock}   $epClk
      setMetric {timing.wns.path}  [get_property -quiet REF_NAME [get_cells -quiet -of $wnsPath]]
      setReport {WNS} [report_timing -quiet -of $wnsPath -return_string]

      # Saving startpoint/endpoint clock(s) of WHS path
      set whsPath [get_timing_paths -quiet -hold -max_paths 1]
      set spClk [get_property -quiet STARTPOINT_CLOCK $whsPath]
      set epClk [get_property -quiet ENDPOINT_CLOCK $whsPath]
      setMetric {timing.whs.spclock}   $spClk
      setMetric {timing.whs.epclock}   $epClk
      setMetric {timing.whs.path}  [get_property -quiet REF_NAME [get_cells -quiet -of $whsPath]]
      setReport {WHS} [report_timing -quiet -of $whsPath -return_string]
    }

    ########################################################################################
    ##
    ## Check timing metrics
    ##
    ########################################################################################

    if {[lsearch $sections {check_timing}] != -1} {
      # Get report
      set report [getReport {check_timing}]

      addMetric {checktiming.no_clock}             {check_timing (no_clock)}
      addMetric {checktiming.constant_clock}       {check_timing (constant_clock)}
      addMetric {checktiming.pulse_width_clock}    {check_timing (pulse_width_clock)}
      addMetric {checktiming.unconstrained_internal_endpoints}      \
                                                   {check_timing (unconstrained_internal_endpoints)}
      addMetric {checktiming.no_input_delay}       {check_timing (no_input_delay)}
      addMetric {checktiming.no_output_delay}      {check_timing (no_output_delay)}
      addMetric {checktiming.multiple_clock}       {check_timing (multiple_clock)}
      addMetric {checktiming.generated_clocks}     {check_timing (generated_clocks)}
      addMetric {checktiming.loops}                {check_timing (loops)}
      addMetric {checktiming.partial_input_delay}  {check_timing (partial_input_delay)}
      addMetric {checktiming.partial_output_delay} {check_timing (partial_output_delay)}
      addMetric {checktiming.latch_loops}          {check_timing (latch_loops)}

      # Extract metrics
      extractMetric {check_timing} {checktiming.no_clock}                     {\s+There.+\s+([0-9\.]+)\s+register/latch pins? with no clock}                 {n/a}
      extractMetric {check_timing} {checktiming.constant_clock}               {\s+There.+\s+([0-9\.]+)\s+register/latch pins? with constant_clock}           {n/a}
      extractMetric {check_timing} {checktiming.pulse_width_clock}            {\s+There.+\s+([0-9\.]+)\s+register/latch pins? which need pulse_width check}  {n/a}

      set res1 [extractMetric {check_timing} {checktiming.unconstrained_internal_endpoints}     {\s+There.+\s+([0-9\.]+)\s+pins? that \w+ not constrained for maximum delay\.}  0 0]
      set res2 [extractMetric {check_timing} {checktiming.unconstrained_internal_endpoints}     {\s+There.+\s+([0-9\.]+)\s+pins? that \w+ not constrained for maximum delay due to constant clock}  0 0]
      setMetric {checktiming.unconstrained_internal_endpoints} [expr $res1 + $res2]

      set res1 [extractMetric {check_timing} {checktiming.no_input_delay}     {\s+There.+\s+([0-9\.]+)\s+input ports? with no input delay specified}  0 0]
      set res2 [extractMetric {check_timing} {checktiming.no_input_delay}     {\s+There.+\s+([0-9\.]+)\s+input ports? with no input delay but user has a false path constraint}  0 0]
      setMetric {checktiming.no_input_delay} [expr $res1 + $res2]

      set res1 [extractMetric {check_timing} {checktiming.no_output_delay}    {\s+There.+\s+([0-9\.]+)\s+ports? with no output delay specified}  0 0]
      set res2 [extractMetric {check_timing} {checktiming.no_output_delay}    {\s+There.+\s+([0-9\.]+)\s+ports? with no output delay but user has a false path constraint}  0 0]
      set res3 [extractMetric {check_timing} {checktiming.no_output_delay}    {\s+There.+\s+([0-9\.]+)\s+ports? with no output delay but with a timing clock defined on it or propagating through it}  0 0]
      setMetric {checktiming.no_output_delay} [expr $res1 + $res2 + $res3]

      extractMetric {check_timing} {checktiming.multiple_clock}               {\s+There.+\s+([0-9\.]+)\s+register/latch pins? with multiple clocks}                    {n/a}
      extractMetric {check_timing} {checktiming.generated_clocks}             {\s+There.+\s+([0-9\.]+)\s+generated clocks? that \w+ not connected to a clock source}   {n/a}
      extractMetric {check_timing} {checktiming.loops}                        {\s+There.+\s+([0-9\.]+)\s+combinational loops? in the design}                           {n/a}
      extractMetric {check_timing} {checktiming.partial_input_delay}          {\s+There.+\s+([0-9\.]+)\s+input ports? with partial input delay specified}              {n/a}
      extractMetric {check_timing} {checktiming.partial_output_delay}         {\s+There.+\s+([0-9\.]+)\s+ports? with partial output delay specified}                   {n/a}
      extractMetric {check_timing} {checktiming.latch_loops}                  {\s+There.+\s+([0-9\.]+)\s+combinational latch loops? in the design through latch input} {n/a}

      if {$hidemissing} {
        # Cleaning: remove metrics that have values of 0 or n/a
        delMetrics checktiming.* [list {n/a} 0]
      }
    }

    ########################################################################################
    ##
    ## Report CDC metrics
    ##
    ########################################################################################

    if {[lsearch $sections {cdc}] != -1} {
      # Get report
      set report [getReport {report_cdc}]

      #  ID      Severity  Count  Description
      #  ------  --------  -----  -------------------------------------------------------
      #  CDC-1   Critical      1  1-bit unknown CDC circuitry
      #  CDC-3   Info         37  1-bit synchronized with ASYNC_REG property
      #  CDC-6   Warning       1  Multi-bit synchronized with ASYNC_REG property
      #  CDC-9   Info          1  Asynchronous reset synchronized with ASYNC_REG property
      #  CDC-15  Warning       1  Clock enable controlled CDC structure detected

      foreach line [split $report \n] {
        if {[regexp {^\s*(CDC-[0-9]+)\s+(\w+)\s+([0-9]+)\s+(.+)\s*$} $line - id severity count description]} {
          addMetric [format {cdc.%s} [string tolower $id]] [format {%s (%s)} $description $severity]
          setMetric [format {cdc.%s} [string tolower $id]] $count
        }
      }

    }

    ########################################################################################
    ##
    ## Clock interaction metrics
    ##
    ########################################################################################

    if {[lsearch $sections {clock_interaction}] != -1} {
      # Get report
#       set report [getReport {report_clock_interaction} {-quiet -no_header}]
      set report [getReport {report_clock_interaction} {-quiet}]

      # Extract metrics
      set clock_interaction_table [::tb::utils::report_design_summary::parseClockInteractionReport $report]
      set colFromClock -1
      set colToClock -1
      set colCommonPrimaryClock -1
      set colInterClockConstraints -1
      set colTNSFailingEndpoints -1
      set colTNSTotalEndpoints -1
      set colWNSClockEdges -1
      set colWNS -1
      set colTNS -1
      set colWNSPathRequirement -1
      if {$clock_interaction_table != {}} {
        set header [lindex $clock_interaction_table 0]
        for {set i 0} {$i < [llength $header]} {incr i} {
          # Header from report_clock_interaction:
          #   {From Clock} {To Clock} {WNS Clock Edges} WNS(ns) TNS(ns) {TNS Failing Endpoints} {TNS Total Endpoints} {WNS Path Requirement(ns)} {Common Primary Clock} {Inter-Clock Constraints}
          switch -regexp -- [lindex $header $i] {
            "From Clock" {
              set colFromClock $i
            }
            "To Clock" {
              set colToClock $i
            }
            "Common Primary Clock" {
              set colCommonPrimaryClock $i
            }
            "Inter-Clock Constraints" {
              set colInterClockConstraints $i
            }
            "TNS Failing Endpoints" {
              set colTNSFailingEndpoints $i
            }
            "TNS Total Endpoints" {
              set colTNSTotalEndpoints $i
            }
            "WNS Clock Edges" {
              set colWNSClockEdges $i
            }
            "WNS\\\(ns\\\)" {
              set colWNS $i
            }
            "TNS\\\(ns\\\)" {
              set colTNS $i
            }
            "WNS Path Requirement" {
              set colWNSPathRequirement $i
            }
            default {
            }
          }
        }
      }

      set n 0
      set clockPairs [list]
      catch {unset clockInteractionReport}
      foreach row [lrange $clock_interaction_table 1 end] {
        incr n
        set fromClock [lindex $row $colFromClock]
        set toClock [lindex $row $colToClock]
#         set failingEndpoints [lindex $row $colTNSFailingEndpoints]
#         set totalEndpoints [lindex $row $colTNSTotalEndpoints]
#         set commonPrimaryClock [lindex $row $colCommonPrimaryClock]
        set interClockConstraints [lindex $row $colInterClockConstraints]
#         set wnsClockEdges [lindex $row $colWNSClockEdges]
        set wns [lindex $row $colWNS]
        set tns [lindex $row $colTNS]
#         set wnsPathRequirement [lindex $row $colWNSPathRequirement]
#         # Save the clock pair
#         lappend clockPairs [list $fromClock $toClock]
        dputs " -D- Processing report_clock_interaction \[$n/[expr [llength $clock_interaction_table] -1]\]: $fromClock -> $toClock \t ($interClockConstraints)"
        if {[string is double $wns] && ($wns != {})} {
          # Clock domain pairs failing WNS
          lappend clockPairs [list $wns [list $fromClock $toClock $wns $tns] ]
        }
        if {![info exists clockInteractionReport($interClockConstraints)]} {
          set clockInteractionReport($interClockConstraints) 0
        }
        incr clockInteractionReport($interClockConstraints)
      }

      foreach name [array names clockInteractionReport] {
        regsub -all { } [string tolower $name] {_} string
        regsub -all {\(} $string {} string
        regsub -all {\)} $string {} string
        addMetric clkinteraction.$string    [format {Clock Interaction (%s)} $name]
        setMetric clkinteraction.$string    $clockInteractionReport($name)
      }

      # Sort list from worst to best WNS
      set clockPairs [lsort -real -increasing -index 0 $clockPairs]
      set count -1
      foreach el $clockPairs {
        incr count
        foreach {- L} $el { break }
        foreach {fromClock toClock wns tns} $L { break }
        addMetric clockpair.${count}.from    [format {Clock Pair (From)} ]
        addMetric clockpair.${count}.to      [format {Clock Pair (To)} ]
        addMetric clockpair.${count}.wns     [format {Clock Pair (WNS)} ]
        addMetric clockpair.${count}.tns     [format {Clock Pair (TNS)} ]
        setMetric clockpair.${count}.from    $fromClock
        setMetric clockpair.${count}.to      $toClock
        setMetric clockpair.${count}.wns     $wns
        setMetric clockpair.${count}.tns     $tns
        # Max 10 worst fromClock -> toClock are reported
        if {$count >= 9} { break }
      }

    }


    ########################################################################################
    ##
    ## Congestion metrics
    ##
    ########################################################################################

    if {[lsearch $sections {congestion}] != -1} {
      # Get report
#       set report [getReport {report_design_analysis} {-quiet -congestion -no_header}]
      set report [getReport {report_design_analysis} {-quiet -congestion}]

      addMetric {congestion.placer}    {Placer Congestion (N-S-E-W)}
      addMetric {congestion.router}    {Router Congestion (N-S-E-W)}

      # Extract metrics
      set congestion [::tb::utils::report_design_summary::parseRDACongestion $report]
      setMetric {congestion.placer}  [lindex $congestion 0]
      setMetric {congestion.router}  [lindex $congestion 1]

      if {$hidemissing} {
        # Cleaning: remove metrics that have values of u-u-u-u
        delMetrics congestion.* [list {u-u-u-u}]
      }
    }

    ########################################################################################
    ##
    ## Constraints metrics
    ##
    ########################################################################################

    if {([lsearch $sections {constraints}] != -1) && $params(vivado)} {
      # All tracked timing constraints
      set timCons [list create_clock \
                        create_generated_clock \
                        set_clock_latency \
                        set_clock_uncertainty \
                        set_clock_groups \
                        set_clock_sense \
                        set_input_jitter \
                        set_system_jitter \
                        set_external_delay \
                        set_input_delay \
                        set_output_delay \
                        set_data_check \
                        set_case_analysis \
                        set_false_path \
                        set_multicycle_path \
                        set_max_delay \
                        set_min_delay \
                        group_path \
                        set_disable_timing \
                        set_bus_skew ]
      catch {unset commands}
      catch {unset res}
      foreach el $timCons {
        set commands($el) 0
      }

      catch {
        set xdc [format {write_xdc.%s} [clock seconds]]
        write_xdc -quiet -exclude_physical -file $xdc
        set res [getVivadoCommands $xdc]
        if {!$params(debug)} {
          # Keep the file in debug mode
          file delete $xdc
        } else {
          dputs " -D- writing XDC file '$xdc'"
        }
      }

      array set commands $res

      foreach el $timCons {
        addMetric constraints.$el    $el
      }

      foreach el $timCons {
        setMetric constraints.$el    $commands($el)
      }

      if {$hidemissing} {
        # Cleaning: remove metrics that have values of 0
        delMetrics constraints.* [list 0]
      }
    }

    ########################################################################################
    ##
    ## Utilization metrics
    ##
    ########################################################################################

    if {[lsearch $sections {utilization}] != -1} {
      # Get report
      set report [getReport {report_utilization} {-quiet}]

      # +----------------------------+--------+-------+-----------+-------+
      # |          Site Type         |  Used  | Fixed | Available | Util% |
      # +----------------------------+--------+-------+-----------+-------+
      # | Slice LUTs                 | 396856 |     0 |   1221600 | 32.49 |
      # |   LUT as Logic             | 394919 |     0 |   1221600 | 32.33 |
      # |   LUT as Memory            |   1937 |     0 |    344800 |  0.56 |
      # |     LUT as Distributed RAM |     64 |     0 |           |       |
      # |     LUT as Shift Register  |   1873 |     0 |           |       |
      # | Slice Registers            | 224301 |     2 |   2443200 |  9.18 |
      # |   Register as Flip Flop    | 200897 |     0 |   2443200 |  8.22 |
      # |   Register as Latch        |  23404 |     2 |   2443200 |  0.96 |
      # | F7 Muxes                   |   6787 |     0 |    610800 |  1.11 |
      # | F8 Muxes                   |   2619 |     0 |    305400 |  0.86 |
      # +----------------------------+--------+-------+-----------+-------+
      # +----------------------------+------+-------+-----------+-------+
      # |          Site Type         | Used | Fixed | Available | Util% |
      # +----------------------------+------+-------+-----------+-------+
      # | CLB LUTs                   | 2088 |     0 |    230400 |  0.91 |
      # |   LUT as Logic             | 1916 |     0 |    230400 |  0.83 |
      # |   LUT as Memory            |  172 |     0 |    101760 |  0.17 |
      # |     LUT as Distributed RAM |   56 |     0 |           |       |
      # |     LUT as Shift Register  |  116 |     0 |           |       |
      # | CLB Registers              | 2612 |     0 |    460800 |  0.57 |
      # |   Register as Flip Flop    | 2612 |     0 |    460800 |  0.57 |
      # |   Register as Latch        |    0 |     0 |    460800 |  0.00 |
      # | CARRY8                     |    8 |     0 |     28800 |  0.03 |
      # | F7 Muxes                   |    7 |     0 |    115200 | <0.01 |
      # | F8 Muxes                   |    0 |     0 |     57600 |  0.00 |
      # | F9 Muxes                   |    0 |     0 |     28800 |  0.00 |
      # +----------------------------+------+-------+-----------+-------+

      # +-------------------------------------------------------------+----------+-------+-----------+-------+
      # |                          Site Type                          |   Used   | Fixed | Available | Util% |
      # +-------------------------------------------------------------+----------+-------+-----------+-------+
      # | CLB                                                         |       33 |     0 |     34260 |  0.10 |
      # |   CLBL                                                      |       21 |     0 |           |       |
      # |   CLBM                                                      |       12 |     0 |           |       |
      # | LUT as Logic                                                |       96 |     0 |    274080 |  0.04 |
      # |   using O5 output only                                      |        0 |       |           |       |
      # |   using O6 output only                                      |       68 |       |           |       |
      # |   using O5 and O6                                           |       28 |       |           |       |
      # | LUT as Memory                                               |        0 |     0 |    144000 |  0.00 |
      # |   LUT as Distributed RAM                                    |        0 |     0 |           |       |
      # |   LUT as Shift Register                                     |        0 |     0 |           |       |
      # | LUT Flip Flop Pairs                                         |      153 |     0 |    274080 |  0.06 |
      # |   fully used LUT-FF pairs                                   |       63 |       |           |       |
      # |   LUT-FF pairs with unused LUT                              |       57 |       |           |       |
      # |   LUT-FF pairs with unused Flip Flop                        |       33 |       |           |       |
      # | Unique Control Sets                                         |       13 |       |           |       |
      # | Maximum number of registers lost to control set restriction | 21(Lost) |       |           |       |
      # +-------------------------------------------------------------+----------+-------+-----------+-------+

      addMetric {utilization.clb.lut}        {CLB LUTs}
      addMetric {utilization.clb.lut.pct}    {CLB LUTs (%)}
      addMetric {utilization.clb.ff}         {CLB Registers}
      addMetric {utilization.clb.ff.pct}     {CLB Registers (%)}
      addMetric {utilization.clb.carry8}     {CARRY8}
      addMetric {utilization.clb.carry8.pct} {CARRY8 (%)}
      addMetric {utilization.clb.f7mux}      {F7 Muxes}
      addMetric {utilization.clb.f7mux.pct}  {F7 Muxes (%)}
      addMetric {utilization.clb.f8mux}      {F8 Muxes}
      addMetric {utilization.clb.f8mux.pct}  {F8 Muxes (%)}
      addMetric {utilization.clb.f9mux}      {F9 Muxes}
      addMetric {utilization.clb.f9mux.pct}  {F9 Muxes (%)}
      addMetric {utilization.clb.lutmem}     {LUT as Memory}
      addMetric {utilization.clb.lutmem.pct} {LUT as Memory (%)}
      addMetric {utilization.ctrlsets.uniq}  {Unique Control Sets}
      addMetric {utilization.ctrlsets.lost}  {Registers Lost due to Control Sets}

#       extractMetric {report_utilization} {utilization.clb.lut}         {\|\s+CLB LUTs[^\|]*\s*\|\s+([0-9\.]+)\s+\|}                                                      {n/a}
#       extractMetric {report_utilization} {utilization.clb.lut.pct}     {\|\s+CLB LUTs[^\|]*\s*\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+([0-9\.]+)\s+\|}      {n/a}
#       extractMetric {report_utilization} {utilization.clb.ff}          {\|\s+CLB Registers[^\|]*\s*\|\s+([0-9\.]+)\s+\|}                                                 {n/a}
#       extractMetric {report_utilization} {utilization.clb.ff.pct}      {\|\s+CLB Registers[^\|]*\s*\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+([0-9\.]+)\s+\|} {n/a}

      extractMetric2 {report_utilization} {utilization.clb.lut}        -p [list {\|\s+CLB LUTs[^\|]*\s*\|\s+([0-9\.]+)\s+\|} \
                                                                                {\|\s+SLICE LUTs[^\|]*\s*\|\s+([0-9\.]+)\s+\|} \
                                                                          ] \
                                                                       -default {n/a}
      extractMetric2 {report_utilization} {utilization.clb.lut.pct}    -p [list {\|\s+CLB LUTs[^\|]*\s*\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+([0-9\.]+)\s+\|} \
                                                                                {\|\s+SLICE LUTs[^\|]*\s*\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+([0-9\.]+)\s+\|} \
                                                                          ] \
                                                                       -default {n/a}
      extractMetric2 {report_utilization} {utilization.clb.ff}         -p [list {\|\s+CLB Registers[^\|]*\s*\|\s+([0-9\.]+)\s+\|} \
                                                                                {\|\s+SLICE Registers[^\|]*\s*\|\s+([0-9\.]+)\s+\|} \
                                                                          ] \
                                                                       -default {n/a}
      extractMetric2 {report_utilization} {utilization.clb.ff.pct}     -p [list {\|\s+CLB Registers[^\|]*\s*\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+<?([0-9\.]+)\s+\|} \
                                                                                {\|\s+SLICE Registers[^\|]*\s*\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+<?([0-9\.]+)\s+\|} \
                                                                          ] \
                                                                       -default {n/a}

      extractMetric {report_utilization} {utilization.clb.carry8}      {\|\s+CARRY8[^\|]*\s*\|\s+([0-9\.]+)\s+\|}                                                          {n/a}
      extractMetric {report_utilization} {utilization.clb.carry8.pct}  {\|\s+CARRY8[^\|]*\s*\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+<?([0-9\.]+)\s+\|}        {n/a}
      extractMetric {report_utilization} {utilization.clb.f7mux}       {\|\s+F7 Muxes[^\|]*\s*\|\s+([0-9\.]+)\s+\|}                                                        {n/a}
      extractMetric {report_utilization} {utilization.clb.f7mux.pct}   {\|\s+F7 Muxes[^\|]*\s*\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+<?([0-9\.]+)\s+\|}      {n/a}
      extractMetric {report_utilization} {utilization.clb.f8mux}       {\|\s+F8 Muxes[^\|]*\s*\|\s+([0-9\.]+)\s+\|}                                                        {n/a}
      extractMetric {report_utilization} {utilization.clb.f8mux.pct}   {\|\s+F8 Muxes[^\|]*\s*\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+<?([0-9\.]+)\s+\|}      {n/a}
      extractMetric {report_utilization} {utilization.clb.f9mux}       {\|\s+F9 Muxes[^\|]*\s*\|\s+([0-9\.]+)\s+\|}                                                        {n/a}
      extractMetric {report_utilization} {utilization.clb.f9mux.pct}   {\|\s+F9 Muxes[^\|]*\s*\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+<?([0-9\.]+)\s+\|}      {n/a}
      extractMetric {report_utilization} {utilization.clb.lutmem}      {\|\s+LUT as Memory[^\|]*\s*\|\s+([0-9\.]+)\s+\|}                                                   {n/a}
      extractMetric {report_utilization} {utilization.clb.lutmem.pct}  {\|\s+LUT as Memory[^\|]*\s*\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+<?([0-9\.]+)\s+\|} {n/a}
      extractMetric {report_utilization} {utilization.ctrlsets.uniq}   {\|\s+Unique Control Sets[^\|]*\s*\|\s+([0-9\.]+)\s+\|}                                             {n/a}
      extractMetric {report_utilization} {utilization.ctrlsets.lost}   {\|\s+.+registers lost to control set restriction[^\|]*\s*\|\s+([0-9\.]+).+\s+\|}                   {n/a}

      # +-------------------+------+-------+-----------+-------+
      # |     Site Type     | Used | Fixed | Available | Util% |
      # +-------------------+------+-------+-----------+-------+
      # | Block RAM Tile    |    8 |     0 |       912 |  0.88 |
      # |   RAMB36/FIFO*    |    8 |     0 |       912 |  0.88 |
      # |     FIFO36E2 only |    8 |       |           |       |
      # |   RAMB18          |    0 |     0 |      1824 |  0.00 |
      # +-------------------+------+-------+-----------+-------+

      addMetric {utilization.ram.tile}     {Block RAM Tile}
      addMetric {utilization.ram.tile.pct} {Block RAM Tile (%)}

      extractMetric {report_utilization} {utilization.ram.tile}     {\|\s+Block RAM Tile[^\|]*\s*\|\s+([0-9\.]+)\s+\|}                                                   {n/a}
      extractMetric {report_utilization} {utilization.ram.tile.pct} {\|\s+Block RAM Tile[^\|]*\s*\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+<?([0-9\.]+)\s+\|} {n/a}

      # +-----------+------+-------+-----------+-------+
      # | Site Type | Used | Fixed | Available | Util% |
      # +-----------+------+-------+-----------+-------+
      # | DSPs      |    0 |     0 |      2520 |  0.00 |
      # +-----------+------+-------+-----------+-------+

      addMetric {utilization.dsp}     {DSPs}
      addMetric {utilization.dsp.pct} {DSPs (%)}

      extractMetric {report_utilization} {utilization.dsp}     {\|\s+DSPs[^\|]*\s*\|\s+([0-9\.]+)\s+\|}                                                   {n/a}
      extractMetric {report_utilization} {utilization.dsp.pct} {\|\s+DSPs[^\|]*\s*\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+<?([0-9\.]+)\s+\|} {n/a}

      # +----------------------+------+-------+-----------+-------+
      # |       Site Type      | Used | Fixed | Available | Util% |
      # +----------------------+------+-------+-----------+-------+
      # | GLOBAL CLOCK BUFFERs |    5 |     0 |       544 |  0.92 |
      # |   BUFGCE             |    5 |     0 |       208 |  2.40 |
      # |   BUFGCE_DIV         |    0 |     0 |        32 |  0.00 |
      # |   BUFG_GT            |    0 |     0 |       144 |  0.00 |
      # |   BUFG_PS            |    0 |     0 |        96 |  0.00 |
      # |   BUFGCTRL*          |    0 |     0 |        64 |  0.00 |
      # +----------------------+------+-------+-----------+-------+

      addMetric {utilization.clk.bufgce}           {BUFGCE Buffers}
      addMetric {utilization.clk.bufgce.pct}       {BUFGCE Buffers (%)}
      addMetric {utilization.clk.bufgcediv}        {BUFGCE_DIV Buffers}
      addMetric {utilization.clk.bufgcediv.pct}    {BUFGCE_DIV Buffers (%)}
      addMetric {utilization.clk.bufggt}           {BUFG_GT Buffers}
      addMetric {utilization.clk.bufggt.pct}       {BUFG_GT Buffers (%)}
      addMetric {utilization.clk.bufgps}           {BUFG_PS Buffers}
      addMetric {utilization.clk.bufgps.pct}       {BUFG_PS Buffers (%)}
      addMetric {utilization.clk.bufgctrl}         {BUFGCTRL Buffers}
      addMetric {utilization.clk.bufgctrl.pct}     {BUFGCTRL Buffers (%)}
      addMetric {utilization.clk.all}              {BUFG* Buffers}

      extractMetric {report_utilization} {utilization.clk.bufgce}        {\|\s+BUFGCE[^\|]*\s*\|\s+([0-9\.]+)\s+\|}                                                  {n/a}
      extractMetric {report_utilization} {utilization.clk.bufgce.pct}    {\|\s+BUFGCE[^\|]*\s*\|\s+[^\|]+\s+\|\s+[^\|]+\s+\|\s+[^\|]+\s+\|\s+<?([0-9\.]+)\s+\|}      {n/a}
      extractMetric {report_utilization} {utilization.clk.bufgcediv}     {\|\s+BUFGCE_DIV[^\|]*\s*\|\s+([0-9\.]+)\s+\|}                                              {n/a}
      extractMetric {report_utilization} {utilization.clk.bufgcediv.pct} {\|\s+BUFGCE_DIV[^\|]*\s*\|\s+[^\|]+\s+\|\s+[^\|]+\s+\|\s+[^\|]+\s+\|\s+<?([0-9\.]+)\s+\|}  {n/a}
      extractMetric {report_utilization} {utilization.clk.bufggt}        {\|\s+BUFG_GT[^\|]*\s*\|\s+([0-9\.]+)\s+\|}                                                 {n/a}
      extractMetric {report_utilization} {utilization.clk.bufggt.pct}    {\|\s+BUFG_GT[^\|]*\s*\|\s+[^\|]+\s+\|\s+[^\|]+\s+\|\s+[^\|]+\s+\|\s+<?([0-9\.]+)\s+\|}     {n/a}
      extractMetric {report_utilization} {utilization.clk.bufgps}        {\|\s+BUFG_PS[^\|]*\s*\|\s+([0-9\.]+)\s+\|}                                                 {n/a}
      extractMetric {report_utilization} {utilization.clk.bufgps.pct}    {\|\s+BUFG_PS[^\|]*\s*\|\s+[^\|]+\s+\|\s+[^\|]+\s+\|\s+[^\|]+\s+\|\s+<?([0-9\.]+)\s+\|}     {n/a}
      extractMetric {report_utilization} {utilization.clk.bufgctrl}      {\|\s+BUFGCTRL\*?[^\|]*\s*\|\s+([0-9\.]+)\s+\|}                                             {n/a}
      extractMetric {report_utilization} {utilization.clk.bufgctrl.pct}  {\|\s+BUFGCTRL\*?[^\|]*\s*\|\s+[^\|]+\s+\|\s+[^\|]+\s+\|\s+[^\|]+\s+\|\s+<?([0-9\.]+)\s+\|} {n/a}

      if {[catch {
        # Cumulative metric (w/o BUFG_GT/BUFG_PS)
        set num 0
        if {[set val [getMetric {utilization.clk.bufgce}]] != {n/a}} { incr num $val}
        if {[set val [getMetric {utilization.clk.bufgcediv}]] != {n/a}} { incr num $val}
        if {[set val [getMetric {utilization.clk.bufgctrl}]] != {n/a}} { incr num $val}
        setMetric {utilization.clk.all} $num
      }]} {
        setMetric {utilization.clk.all} {n/a}
      }

      # +------------------+------+-------+-----------+-------+
      # |     Site Type    | Used | Fixed | Available | Util% |
      # +------------------+------+-------+-----------+-------+
      # | Bonded IOB       |   11 |     0 |       328 |  3.35 |
      # | HPIOB_M          |    6 |     0 |        96 |  6.25 |
      # |   INPUT          |    2 |       |           |       |
      # |   OUTPUT         |    4 |       |           |       |
      # |   BIDIR          |    0 |       |           |       |
      # | HPIOB_S          |    5 |     0 |        96 |  5.21 |
      # |   INPUT          |    0 |       |           |       |
      # |   OUTPUT         |    5 |       |           |       |
      # |   BIDIR          |    0 |       |           |       |
      # | HDIOB_M          |    0 |     0 |        60 |  0.00 |
      # | HDIOB_S          |    0 |     0 |        60 |  0.00 |
      # | HPIOB_SNGL       |    0 |     0 |        16 |  0.00 |
      # | HPIOBDIFFINBUF   |    0 |     0 |        96 |  0.00 |
      # | HPIOBDIFFOUTBUF  |    0 |     0 |        96 |  0.00 |
      # | HDIOBDIFFINBUF   |    0 |     0 |        60 |  0.00 |
      # | BITSLICE_CONTROL |    0 |     0 |        32 |  0.00 |
      # | BITSLICE_RX_TX   |    0 |     0 |       208 |  0.00 |
      # | BITSLICE_TX      |    0 |     0 |        32 |  0.00 |
      # | RIU_OR           |    0 |     0 |        16 |  0.00 |
      # +------------------+------+-------+-----------+-------+

      addMetric {utilization.io}     {IOs}
      addMetric {utilization.io.pct} {IOs (%)}

      extractMetric {report_utilization} {utilization.io}     {\|\s+Bonded IOB[^\|]*\s*\|\s+([0-9\.]+)\s+\|}                                                   {n/a}
      extractMetric {report_utilization} {utilization.io.pct} {\|\s+Bonded IOB[^\|]*\s*\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+[0-9\.]+\s+\|\s+<?([0-9\.]+)\s+\|} {n/a}

    }

    ########################################################################################
    ##
    ## Utilization metrics
    ##
    ########################################################################################

    if {[lsearch $sections {utilization}] != -1} {
      addMetric {utilization.ram.blockram}       {RAM (Blocks)}
      addMetric {utilization.ram.distributedram} {RAM (Distributed)}

      # Get report
      set report [getReport {report_ram_utilization} {-quiet}]

      # +----------------+------------+
      # | Memory Type    | Total Used |
      # +----------------+------------+
      # | BlockRAM       |       1102 |
      # +----------------+------------+
      # |       RAMB18E2 |         12 |
      # +----------------+------------+
      # |       RAMB36E2 |       1090 |
      # +----------------+------------+
      # | DistributedRAM |       3071 |
      # +----------------+------------+
      # |       RAM64X1D |         28 |
      # +----------------+------------+
      # |       RAM32X1S |          6 |
      # +----------------+------------+
      # |        RAM64M8 |        369 |
      # +----------------+------------+
      # |       RAM32M16 |       2668 |
      # +----------------+------------+

      # Extract metrics
      extractMetric {report_ram_utilization} {utilization.ram.blockram}        {\|\s+BlockRAM[^\|]*\s*\|\s+([0-9\.]+)\s+\|}        {n/a}
      extractMetric {report_ram_utilization} {utilization.ram.distributedram}  {\|\s+DistributedRAM[^\|]*\s*\|\s+([0-9\.]+)\s+\|}  {n/a}
    }

    ########################################################################################
    ##
    ##
    ##
    ########################################################################################

    if {[lsearch $sections {route_status}] != -1} {
      # Get report
      set report [getReport {report_route_status} {-quiet}]

      addMetric {route.errors}    {Nets with routing errors}
      addMetric {route.routed}    {Fully routed nets}
      addMetric {route.fixed}     {Nets with fixed routing}
      addMetric {route.nets}      {Routable nets}

      #                                               :      # nets :
      #   ------------------------------------------- : ----------- :
      #   # of logical nets.......................... :     1648481 :
      #       # of nets not needing routing.......... :      736037 :
      #           # of internally routed nets........ :      524080 :
      #           # of nets with no loads............ :      211957 :
      #       # of routable nets..................... :      912444 :
      #           # of fully routed nets............. :      912444 :
      #       # of nets with routing errors.......... :           0 :
      #   ------------------------------------------- : ----------- :

      #                                               :      # nets :
      #   ------------------------------------------- : ----------- :
      #   # of logical nets.......................... :     1318920 :
      #       # of nets with no placed pins.......... :     1251890 :
      #       # of nets not needing routing.......... :       61112 :
      #           # of internally routed nets........ :         349 :
      #           # of nets with no loads............ :       60763 :
      #       # of routable nets..................... :        1038 :
      #           # of unrouted nets................. :        1038 :
      #       # of nets with routing errors.......... :        4880 :
      #           # of nets with some unplaced pins.. :        4880 :
      #           # of nets with some unrouted pins.. :        2164 :
      #   ------------------------------------------- : ----------- :

      # Extract metrics
      extractMetric {report_route_status} {route.errors} {nets with routing errors[^\:]+\:\s*([0-9]+)\s*\:}        {n/a}
      extractMetric {report_route_status} {route.routed} {fully routed nets[^\:]+\:\s*([0-9]+)\s*\:}               {n/a}
      extractMetric {report_route_status} {route.fixed}  {nets with fixed routing[^\:]+\:\s*([0-9]+)\s*\:}         {n/a}
      extractMetric {report_route_status} {route.nets}   {routable nets[^\:]+\:\s*([0-9]+)\s*\:}                   {n/a}
    }

    ########################################################################################
    ##
    ## Report methodology checks metrics
    ##
    ########################################################################################

    if {[lsearch $sections {methodology}] != -1} {
      # Get report
      set report [getReport {report_methodology}]

      # 1 CKLD-2 [Warning] [Clock Net has IO Driver, not a Clock Buf, and/or non-Clock loads]
      # 1 PDRC-190 [Warning] [Suboptimally placed synchronized register chain]
      # 127 SYNTH-4 [Warning] [Shallow depth for a dedicated block RAM]
      # 1000 TIMING-10 [Warning] [Missing property on synchronizer]
      # 12 XDCB-1 [Warning] [Runtime intensive exceptions]
      foreach line [split $report \n] {
        set num {} ; set drc {} ; set severity {} ; set msg {}
        if {[regexp {^\s*([0-9]+)\s+([^s]+)\s+\[(.+)\]\s+\[(.+)\]\s*$} $line - num drc severity msg]} {
          addMetric [format {methodology.%s} [string tolower $drc]] [format {%s (%s)} $msg $severity]
          setMetric [format {methodology.%s} [string tolower $drc]] $num
        } else {
          puts " -W- invalid methodology check format for '[string trim $line]'"
        }
      }

    }

    ########################################################################################
    ##
    ## Report DRC checks metrics
    ##
    ########################################################################################

    if {[lsearch $sections {drc}] != -1} {
      # Get report
      set report [getReport {report_drc}]

      # 1 CKLD-2 [Warning] [Clock Net has IO Driver, not a Clock Buf, and/or non-Clock loads]
      # 1 PDRC-190 [Warning] [Suboptimally placed synchronized register chain]
      # 127 SYNTH-4 [Warning] [Shallow depth for a dedicated block RAM]
      # 1000 TIMING-10 [Warning] [Missing property on synchronizer]
      # 12 XDCB-1 [Warning] [Runtime intensive exceptions]
      foreach line [split $report \n] {
        set num {} ; set drc {} ; set severity {} ; set msg {}
        if {[regexp {^\s*([0-9]+)\s+([^s]+)\s+\[(.+)\]\s+\[(.+)\]\s*$} $line - num drc severity msg]} {
          addMetric [format {drc.%s} [string tolower $drc]] [format {%s (%s)} $msg $severity]
          setMetric [format {drc.%s} [string tolower $drc]] $num
        } else {
          puts " -W- invalid DRC check format for '[string trim $line]'"
        }
      }

    }

    ########################################################################################
    ##
    ## Metrics from Vivado log file
    ##
    ########################################################################################

#     if {($vivadoLog != {}) && ([lsearch $sections {congestion}] != -1)} {}
    if {($vivadoLog != {})} {
      if {[regexp {route} $step]} {
        # Only extract those congestion metrics in flow step *route*
        addMetric {congestion.estimated.global}    {Estimated Global Congestion (N-S-E-W)}
        addMetric {congestion.estimated.long}      {Estimated Long Congestion (N-S-E-W)}
        addMetric {congestion.estimated.short}     {Estimated Short Congestion (N-S-E-W)}

        # Extract metrics
        set congestion [::tb::utils::report_design_summary::parseLOGCongestion $vivadoLog {last}]
        setMetric {congestion.estimated.global}  [lindex $congestion 0]
        setMetric {congestion.estimated.long}  [lindex $congestion 1]
        setMetric {congestion.estimated.short}  [lindex $congestion 2]

        if {$hidemissing} {
          # Cleaning: remove metrics that have values of u-u-u-u
          delMetrics congestion.estimated.* [list {u-u-u-u}]
        }
      }
    }

    ########################################################################################
    ##
    ## Optional post script / command
    ##
    ########################################################################################

    if {$postcommand != {}} {
      puts " -I- Executing post-command '$postcommand'"
      if {[catch { eval $postcommand } errorstring]} {
        puts " -E- Post-command failed: $errorstring"
      }
    }

    if {$postscript != {}} {
      puts " -I- Sourcing post-script '$postscript'"
      if {[catch { source $postscript } errorstring]} {
        puts " -E- Post-script failed: $errorstring"
      }
    }

    ########################################################################################
    ##
    ##
    ##
    ########################################################################################

    if {$hidemissing} {
      # Cleaning: remove metrics that have values of n/a
#       delMetrics *.* [list {n/a}]
    }

    ########################################################################################
    ##
    ##
    ##
    ########################################################################################

    # Gather the list of metrics categories
    # E.g: metric = 'design.ram.blockram' -> category = 'design'
    set categories [list]
    foreach key [lsort [array names metrics *:def]] {
      lappend categories [lindex [split $key .] 0]
    }
    set categories [lsort -unique $categories]

#     set tbl [::tb::prettyTable {Design Summary}]
    set tbl [::Table::Create {Design Summary}]
    $tbl indent 1
#     $tbl configure -indent 2
    $tbl header [list {Id} {Description} {Value}]
    foreach category [presort_list [orderedCategories] $categories] {
      switch $category {
        xxx {
          continue
        }
        default {
        }
      }

      $tbl separator
      foreach key [presort_list [orderedMetrics] [regsub -all {:def} [lsort [array names metrics $category.*:def]] {}] ] {
        # E.g: key = 'design.ram.blockram' -> metric = 'ram.blockram'
        regsub "$category." $key {} metric
        switch $key {
          vivado.dir  {
            # Metric not added
          }
          default {
            $tbl addrow [list $key $metrics(${key}:description) $metrics(${key}:val)]
          }
        }
      }
    }
#     set output [concat $output [split [$tbl export -format $params(format)] \n] ]
    switch $params(format) {
      table {
        set output [concat $output [split [$tbl print] \n] ]
      }
      csv {
        set output [concat $output [split [$tbl csv] \n] ]
        if {$filename != {}} {
          # Append a comment out version of the table
          foreach line [split [$tbl print] \n] {
            lappend output [format {#  %s} $line]
          }
        }
      }
    }
    catch {$tbl destroy}

    ########################################################################################
    ##
    ##
    ##
    ########################################################################################

  } errorstring]} {
    puts " -E- $errorstring"
  }

  if {$params(debug)} {
  }

  set stopTime [clock seconds]
  puts " -I- report_design_summary completed in [expr $stopTime - $startTime] seconds"

  # Export reports
  if {$saveReports} {
    if {$filename != {}} {
      # If an output filename was provided, then save reports into same directory
      set dir [file dirname $filename]
    } else {
      # Otherwise save reports inside current working directory
      set dir [uplevel #0 pwd]
    }
    # Dump full reports on disk
    foreach el [list {report_utilization ru} \
                     {report_ram_utilization rru} \
                     {report_timing_summary rts} \
                     {WNS wns} \
                     {WHS whs} \
                     {report_clock_interaction rci} \
                     {check_timing ct} \
                     {report_design_analysis rda} \
                     {report_cdc cdc} \
                     {report_drc drc} \
                     {report_methodology rm} \
                     {report_route_status rrs} \
                 ] {
      foreach {name suffix} $el { break }
      if {[info exists reports($name)]} {
        set report $reports($name)
#         set rptfile [format {%s/%s.%s.rpt} $dir $saveReportsPrefix $suffix]
        set rptfile [file join $dir [format {%s.%s.rpt} $saveReportsPrefix $suffix]]
        set FH [open $rptfile {w}]
        puts $FH $report
        close $FH
        puts " -I- Saved $name report: [file normalize $rptfile]"
      }
    }
  }

  # Get all metrics as pair-value
  set allMetrics [serializeMetrics]

  if {$filename != {}} {
    set FH [open $filename $filemode]
    puts $FH "# ---------------------------------------------------------------------------------"
    puts $FH [format {# Created on %s with report_design_summary (%s)} [clock format [clock seconds]] $::tb::utils::report_design_summary::version ]
    puts $FH "# ---------------------------------------------------------------------------------\n"
    puts $FH [join $output \n]
    if {$showdetails} {
      # Dump full reports inside file
      foreach name [list report_utilization \
                         report_ram_utilization \
                         report_timing_summary \
                         WNS \
                         WHS \
                         report_clock_interaction \
                         check_timing \
                         report_design_analysis \
                         report_cdc \
                         report_methodology \
                         report_drc \
                         report_route_status \
                   ] {
        if {[info exists reports($name)]} {
          set report $reports($name)
          puts $FH "\n########################################################################################"
          puts $FH "## Vivado report: $name"
          puts $FH "########################################################################################"
          puts $FH "#"
          foreach line [split $report \n] {
            puts $FH [format {#  %s} $line]
          }
        }
      }
    }
    close $FH
    puts " -I- Generated file [file normalize $filename]"
    if {$returnmetrics} {
      return $allMetrics
    }
    return -code ok
  }

  if {$returnstring} {
    return [join $output \n]
  } elseif {$returnmetrics} {
    return $allMetrics
  } else {
    puts [join $output \n]
  }
  return -code ok
}

########################################################################################
##
##
##
########################################################################################
proc ::tb::utils::report_design_summary::serializeMetrics {} {
  variable reports
  variable metrics
  variable params
  set L [list]
  foreach el [lsort [array names metrics *:def]] {
    regsub {:def$} $el {} name
#     lappend L [list $name $metrics(${name}:val) ]
    lappend L $name
    lappend L $metrics(${name}:val)
  }
  return $L
}

proc ::tb::utils::report_design_summary::reset { {force 0} } {
  variable reports
  variable metrics
  variable params
  if {$params(debug) && !$force} {
    # Do not remove arrays in debug mode
    return -code ok
  }
  catch { unset reports }
  catch { unset metrics }
  array set reports [list]
  array set metrics [list]
  return -code ok
}

proc ::tb::utils::report_design_summary::importReport {name filename} {
  variable reports
  variable params
  if {![file exists $filename]} {
    puts " -E- file '$filename' does not exist"
    return -code ok
  }
  if {[info exists reports($name)]} {
#     if {$params(incremental)} {
#       if {$params(verbose)} { puts " -I- Found report '$name'. Report not overriden (incremental mode)" }
#       return $reports($name)
#     } else {
#       if {$params(verbose)} { puts " -I- Found report '$name'. Overridding existing report with new one" }
#     }
    if {$params(verbose)} { puts " -I- Found report '$name'. Overridding existing report with new one" }
  }
  switch $name {
    report_drc {
      # The report_drc report can be fairly large
      # so create a summary table out of it
      set report [createSummaryDRCReport $filename]
    }
    report_methodology {
      # The report_methodology report can be fairly large
      # so create a summary table out of it
      set report [createSummaryDRCReport $filename]
    }
    default {
      if {[regexp {.gz$} $filename]} {
        # gzip-ed file
        set FH [open "| zcat $filename" {r}]
      } else {
        set FH [open $filename {r}]
      }
#       set FH [open $filename {r}]
      set report [read $FH]
      close $FH
    }
  }
  set reports($name) $report
  return $report
}

proc ::tb::utils::report_design_summary::setReport {name report} {
  variable reports
  variable params
  if {[info exists reports($name)]} {
#     if {$params(incremental)} {
#       puts "Found report $name. Skipping report (incremental mode)"
#       if {$params(verbose)} { puts " -I- Found report '$name'. Report not overriden (incremental mode)" }
#       return $reports($name)
#     } else {
#       if {$params(verbose)} { puts " -I- Found report '$name'. Overridding existing report with new one" }
#     }
    if {$params(verbose)} { puts " -I- Found report '$name'. Overridding existing report with new one" }
  }
  set reports($name) $report
  return $report
}

proc ::tb::utils::report_design_summary::getReport {name {options {}}} {
  variable reports
  variable params
  if {[info exists reports($name)]} {
    if {$params(verbose)} { puts " -I- Found report '$name'" }
    return $reports($name)
  }
  if {!$params(vivado)} {
    # If not running inside Vivado, then there is command that can be run
    return {}
  }
  set res {}
  set startTime [clock seconds]
  switch $name {
    report_methodology {
      catch {
        set file [format {report_methodology.%s} [clock seconds]]
        report_methodology -quiet -file $file
        # The report_methodology report can be fairly large
        # so create a summary table out of it
        set res [createSummaryDRCReport $file]
        if {!$params(debug)} {
          # Keep the file in debug mode
          file delete $file
        } else {
          dputs " -D- writing report_methodology file '$file'"
        }
      }
    }
    report_drc {
      catch {
        set file [format {report_drc.%s} [clock seconds]]
        report_drc -quiet -file $file
        # The report_drc report can be fairly large
        # so create a summary table out of it
        set res [createSummaryDRCReport $file]
        if {!$params(debug)} {
          # Keep the file in debug mode
          file delete $file
        } else {
          dputs " -D- writing report_drc file '$file'"
        }
      }
    }
    report_cdc {
      # Only get the first table of the detailed report:
      #  ID      Severity  Count  Description
      #  ------  --------  -----  -------------------------------------------------------
      #  CDC-1   Critical      1  1-bit unknown CDC circuitry
      #  CDC-3   Info         37  1-bit synchronized with ASYNC_REG property
      #  CDC-6   Warning       1  Multi-bit synchronized with ASYNC_REG property
      #  CDC-9   Info          1  Asynchronous reset synchronized with ASYNC_REG property
      #  CDC-15  Warning       1  Clock enable controlled CDC structure detected
      catch {
        set file [format {report_cdc.%s} [clock seconds]]
        report_cdc -quiet -details -file $file
        if {[regexp {.gz$} $file]} {
          # gzip-ed file
          set FH [open "| zcat $file" {r}]
        } else {
          set FH [open $file {r}]
        }
#         set FH [open $file {r}]
        set content [list]
        set loop 1
        while {$loop && ![eof $FH]} {
          gets $FH line
          if {[regexp {^\s*Source\s+Clock\s*:} $line]} {
            # We are only interested in the first table
            # Skip detailed summary tables for clock pairs
            set loop 0
          } else {
            lappend content $line
          }
        }
        set res [join $content \n]
        close $FH
        if {!$params(debug)} {
          # Keep the file in debug mode
          file delete $file
        } else {
          dputs " -D- writing report_cdc file '$file'"
        }
      }
    }
    check_timing {
      catch {
        set file [format {check_timing.%s} [clock seconds]]
        check_timing -quiet -file $file
        if {[regexp {.gz$} $file]} {
          # gzip-ed file
          set FH [open "| zcat $file" {r}]
        } else {
          set FH [open $file {r}]
        }
#         set FH [open $file {r}]
        set res [read $FH]
        close $FH
        if {!$params(debug)} {
          # Keep the file in debug mode
          file delete $file
        } else {
          dputs " -D- writing check_timing file '$file'"
        }
      }
    }
    default {
      if {[catch { set res [eval [concat $name $options -return_string]] } errorstring]} {
        puts " -E- $errorstring"
      }
    }
  }
  set stopTime [clock seconds]
  if {$params(verbose)} { puts " -I- report '$name' completed in [expr $stopTime - $startTime] seconds" }
#   puts "report $name: $res"
  set reports($name) $res
  return $res
}

proc ::tb::utils::report_design_summary::addMetric {name {description {}}} {
  variable metrics
  variable params
  if {[info exists metrics(${name}:def)]} {
    if {$params(verbose)} { puts " -W- metric '$name' already exist. Skipping new definition" }
    return -code ok
  }
  if {$description == {}} { set description $name }
  set metrics(${name}:def) 1
  set metrics(${name}:description) $description
  set metrics(${name}:val) {}
  return -code ok
}

proc ::tb::utils::report_design_summary::getMetric {name} {
  variable metrics
  if {![info exists metrics(${name}:def)]} {
    puts " -E- metric '$name' does not exist"
    return {}
  }
  return $metrics(${name}:val)
}

proc ::tb::utils::report_design_summary::setMetric {name value} {
  variable metrics
  if {![info exists metrics(${name}:def)]} {
    puts " -E- metric '$name' does not exist"
    return -code ok
  }
  dputs " -D- setting: $name = $value"
  set metrics(${name}:def) 2
  set metrics(${name}:val) $value
  return -code ok
}

proc ::tb::utils::report_design_summary::delMetrics {pattern {values {__UnSeT__}}} {
  variable metrics
  set names [array names metrics ${pattern}:def]
  if {![llength $names]} {
    puts " -E- metric '$pattern' does not exist"
    return -code ok
  }
  foreach name $names {
    regsub {:def} $name {} name
    if {$values == {__UnSeT__}} {
      dputs " -D- removing: $name"
      array unset metrics ${name}:*
    } else {
      # If a list of values is passed to the proc, then unset the
      # metric only if its value matches one of the provided values
      if {[lsearch -exact $values $metrics(${name}:val)] != -1} {
        dputs " -D- removing: $name (value='$metrics(${name}:val)')"
        array unset metrics ${name}:*
      }
    }
  }
  return -code ok
}

proc ::tb::utils::report_design_summary::extractMetric {report name exp {notfound {n/a}} {save 1}} {
  variable metrics
  variable reports
  if {![info exists metrics(${name}:def)]} {
    puts " -E- metric '$name' does not exist"
    return -code ok
  }
  if {[info exists reports($report)]} {
    dputs " -D- found report '$report'"
    set report $reports($report)
  } else {
    dputs " -D- inline report"
  }
  if {![regexp -nocase -- $exp $report -- value]} {
    set value $notfound
    dputs " -D- failed to extract metric '$name' from report"
  }
  if {!$save} {
    return $value
  }
  setMetric $name $value
#   dputs " -D- setting: $name = $value"
#   set metrics(${name}:def) 2
#   set metrics(${name}:val) $value
  return -code ok
}

# Supports a list of patterns
proc ::tb::utils::report_design_summary::extractMetric2 {report name args} {
  variable metrics
  variable reports
  array set defaults [list \
      -default {n/a} \
      -save 1 \
      -p [list] \
    ]
  array set options [array get defaults]
  array set options $args
  if {![info exists metrics(${name}:def)]} {
    puts " -E- metric '$name' does not exist"
    return -code ok
  }
  if {[info exists reports($report)]} {
    dputs " -D- found report '$report'"
    set report $reports($report)
  } else {
    dputs " -D- inline report"
  }
  # Default value if not found in any pattern
  set value $options(-default)
  set found 0
  foreach exp $options(-p) {
    if {![regexp -nocase -- $exp $report -- value]} {
    } else {
      set found 1
      break
    }
  }
  if {!$found} {
    dputs " -D- failed to extract metric '$name' from report"
  }
  if {!$options(-save)} {
    return $value
  }
  setMetric $name $value
#   dputs " -D- setting: $name = $value"
#   set metrics(${name}:def) 2
#   set metrics(${name}:val) $value
  return -code ok
}

proc ::tb::utils::report_design_summary::presort_list {l1 l2} {
  set l [list]
  foreach el $l1 {
    if {[lsearch $l2 $el] != -1} {
      lappend l $el
    }
  }
  foreach el $l2 {
    if {[lsearch $l $el] == -1} {
      lappend l $el
    }
  }
  return $l
}

##-----------------------------------------------------------------------
## duration
##-----------------------------------------------------------------------
## Convert a number of seconds in a human readable string.
## Example:
##      set startTime [clock seconds]
##      ...
##      set endTime [clock seconds]
##      puts "The runtime is: [duration [expr $endTime - startTime]]"
##-----------------------------------------------------------------------
proc ::tb::utils::report_design_summary::duration { int_time } {
   set timeList [list]
   if {$int_time == 0} { return "0 sec" }
   foreach div {86400 3600 60 1} mod {0 24 60 60} name {day hr min sec} {
     set n [expr {$int_time / $div}]
     if {$mod > 0} {set n [expr {$n % $mod}]}
     if {$n > 1} {
       lappend timeList "$n ${name}s"
     } elseif {$n == 1} {
       lappend timeList "$n $name"
     }
   }
   return [join $timeList]
}

##-----------------------------------------------------------------------
## formatRuntime
##-----------------------------------------------------------------------
## Format runtime metric
##-----------------------------------------------------------------------
proc ::tb::utils::report_design_summary::formatRuntime {runtime} {
  if {$runtime == {}} { return {-} }
  if {![regexp {^[0-9]+$} $runtime]} { return {-} }
  if {$runtime == 0} { return {-} }
  set duration [duration $runtime]
  set str [regsub {\s*[0-9]+\s+secs?} $duration {}]
  if {$str == {}} {
    # $str is empty if $duration <= 59 seconds
    # In this case, return $duration to prevent empty string
    set str $duration
  }
  return $str
}

# Generate a list of integers
proc ::tb::utils::report_design_summary::iota {from to} {
  set out [list]
  if {$from <= $to} {
    for {set i $from} {$i <= $to} {incr i}    {lappend out $i}
  } else {
    for {set i $from} {$i >= $to} {incr i -1} {lappend out $i}
  }
  return $out
}

proc ::tb::utils::report_design_summary::dputs {args} {
  variable params
  if {$params(debug)} {
    catch { eval [concat puts $args] }
  }
  return -code ok
}

# Convert a congestion window to a congestion level
proc ::tb::utils::report_design_summary::congestionWindowToLevel {window} {
  set level {u}
  switch -exact $window {
    "1x1"     { set level 0 }
    "2x2"     { set level 1 }
    "4x4"     { set level 2 }
    "8x8"     { set level 3 }
    "16x16"   { set level 4 }
    "32x32"   { set level 5 }
    "64x64"   { set level 6 }
    "128x128" { set level 7 }
    "256x256" { set level 8 }
    default   { set level u }
  }
  return $level
}

# Code from Frederic Revenu
# Extract the placement + routing congestions from report_design_analysis
# Format: North-South-East-West
#         PlacerNorth-PlacerSouth-PlacerEast-PlacerWest RouterNorth-RouterSouth-RouterEast-RouterWest
proc ::tb::utils::report_design_summary::parseRDACongestion {report} {
  set section "other"
  set placerCong [list u u u u]
  set routerCong [list u u u u]
  foreach line [split $report \n] {
    if {[regexp {^\d. (\S+) Maximum Level Congestion Reporting} $line foo step]} {
      switch -exact $step {
        "Placed" { set section "placer" }
        "Router" { set section "router" }
        default  { set section "other" }
      }
    } elseif {[regexp {^\| (\S+)\s*\| (\S+)\s*\| \S+\s*\| \S+\s*| \S+\s*\| \S+\s*\| \S+\s*\| \S+\s*\| \S+\s*\| \S+\s*\| \S+\s*\|} $line foo card cong] || \
              [regexp {^\| (\S+)\s*\| (\S+)\s*\| \S+\s*\| \s*\S+ -> \S+\s*\|\s*$} $line foo card cong]} {
#       switch -exact $cong {
#         "1x1"     { set level 0 }
#         "2x2"     { set level 1 }
#         "4x4"     { set level 2 }
#         "8x8"     { set level 3 }
#         "16x16"   { set level 4 }
#         "32x32"   { set level 5 }
#         "64x64"   { set level 6 }
#         "128x128" { set level 7 }
#         "256x256" { set level 8 }
#         default   { set level u }
#       }
      set level [congestionWindowToLevel $cong]
      if {$section == "placer"} {
        switch -exact $card {
          "North" { set placerCong [lreplace $placerCong 0 0 $level] }
          "South" { set placerCong [lreplace $placerCong 1 1 $level] }
          "East"  { set placerCong [lreplace $placerCong 2 2 $level] }
          "West"  { set placerCong [lreplace $placerCong 3 3 $level] }
        }
      } elseif {$section == "router"} {
        switch -exact $card {
          "North" { set routerCong [lreplace $routerCong 0 0 $level] }
          "South" { set routerCong [lreplace $routerCong 1 1 $level] }
          "East"  { set routerCong [lreplace $routerCong 2 2 $level] }
          "West"  { set routerCong [lreplace $routerCong 3 3 $level] }
        }
      }
    } elseif {[regexp {^\d\. } $line]} {
      set section "other"
    }
  }
  return [list [join $placerCong -] [join $routerCong -]]
}

# INFO: [Route 35-449] Initial Estimated Congestion
#  ________________________________________________________________________
# |           | Global Congestion | Long Congestion   | Short Congestion  |
# |           |___________________|___________________|___________________|
# | Direction | Size   | % Tiles  | Size   | % Tiles  | Size   | % Tiles  |
# |___________|________|__________|________|__________|________|__________|
# |      NORTH|   64x64|      7.62|   64x64|      7.96|   64x64|     11.11|
# |___________|________|__________|________|__________|________|__________|
# |      SOUTH|   32x32|      4.03|   32x32|      3.33|   32x32|      8.74|
# |___________|________|__________|________|__________|________|__________|
# |       EAST|   32x32|      6.97|   16x16|      2.96| 128x128|     15.34|
# |___________|________|__________|________|__________|________|__________|
# |       WEST|     8x8|      0.87|     4x4|      0.52|   32x32|      8.85|
# |___________|________|__________|________|__________|________|__________|
proc ::tb::utils::report_design_summary::parseLOGCongestion {filename {table {first}}} {
  set globalCong [list u u u u]
  set longCong [list u u u u]
  set shortCong [list u u u u]
  if {![file exists $filename]} {
    puts " -E- Vivado log file '[file normalize $filename]' does not exist"
    return [list {} {} {} ]
#     return [list [join $globalCong -] [join $longCong -] [join $shortCong -] ]
  }
  if {[regexp {.gz$} $filename]} {
    # gzip-ed file
    set FH [open "| zcat $filename" {r}]
  } else {
    set FH [open $filename {r}]
  }
#   set FH [open $filename {r}]
  set loop 1
  set found 0
  set match 0
  while {$loop && ![eof $FH]} {
    set line [gets $FH]
    if {!$found} {
      if {[regexp {Initial Estimated Congestion} $line]} {
        # Begining of the 'Initial Estimated Congestion' table
        set found 1
        incr match
      }
    } else {
      if {![regexp {^\s*(\||\_)} $line]} {
        # End of table
        if {$table == {first}} {
          # Return first instance of 'Initial Estimated Congestion' table
          # ... exit loop
          set loop 0
        } else {
          # Return last instance of 'Initial Estimated Congestion' table
          # ... keep looping
        }
        set found 0
      } else {
        # The table is parsed here
        # E.g:
        #  # |      NORTH|   64x64|      7.62|   64x64|      7.96|   64x64|     11.11|
        if {[regexp -nocase {(NORTH|SOUTH|EAST|WEST)\s*\|\s*(\d+x\d+)\s*\|.+\|\s*(\d+x\d+)\s*\|.+\|\s*(\d+x\d+)\s*\|.+} $line - direction global long short]} {
          switch -nocase $direction {
            "NORTH" {
              set globalCong [lreplace $globalCong 0 0 [congestionWindowToLevel $global]]
              set longCong [lreplace $longCong 0 0 [congestionWindowToLevel $long]]
              set shortCong [lreplace $shortCong 0 0 [congestionWindowToLevel $short]]
            }
            "SOUTH" {
              set globalCong [lreplace $globalCong 1 1 [congestionWindowToLevel $global]]
              set longCong [lreplace $longCong 1 1 [congestionWindowToLevel $long]]
              set shortCong [lreplace $shortCong 1 1 [congestionWindowToLevel $short]]
            }
            "EAST" {
              set globalCong [lreplace $globalCong 2 2 [congestionWindowToLevel $global]]
              set longCong [lreplace $longCong 2 2 [congestionWindowToLevel $long]]
              set shortCong [lreplace $shortCong 2 2 [congestionWindowToLevel $short]]
            }
            "WEST" {
              set globalCong [lreplace $globalCong 3 3 [congestionWindowToLevel $global]]
              set longCong [lreplace $longCong 3 3 [congestionWindowToLevel $long]]
              set shortCong [lreplace $shortCong 3 3 [congestionWindowToLevel $short]]
            }
          }
        }
      }
    }
  }
  catch { close $FH }
  if {!$match} {
    # No table found
    return [list {} {} {} ]
  }
  # E.g:
  #  [list {6-5-5-3} {6-5-4-2} {6-5-7-5} ]
  return [list [join $globalCong -] [join $longCong -] [join $shortCong -] ]
}

# Return a list of Vivado commands used in a Tcl script.
# Format: <command> <number>
# For example:
#   get_nets 35 get_pins 242 set_false_path 162 set_multicycle_path 66 \
#   create_generated_clock 67 set_clock_groups 292 current_instance 10 \
#   set_case_analysis 15 get_cells 191 get_clocks 717 get_ports 26 create_clock 12
proc ::tb::utils::report_design_summary::getVivadoCommands {filename} {
  set slave [interp create]
  $slave eval [format {
    catch {unset commands}
    global commands

    proc unknown {args} {
      global commands
      set cmd [lindex $args 0]
      if {[regexp {^[0-9]$} $cmd]} {
        return -code ok
      }
      if {![info exists commands($cmd)]} {
        set commands($cmd) 0
      }
      incr commands($cmd)
      return -code ok
    }

    source %s
  } $filename ]

  set result [$slave eval array get commands]
  interp delete $slave
  return $result
}

#------------------------------------------------------------------------
# ::tb::utils::report_design_summary::extract_columns
#------------------------------------------------------------------------
# Extract position of columns based on the column separator string
#  str:   string to be used to extract columns
#  match: column separator string
#------------------------------------------------------------------------
proc ::tb::utils::report_design_summary::extract_columns { str match } {
  set col 0
  set columns [list]
  set previous -1
  while {[set col [string first $match $str [expr $previous +1]]] != -1} {
    if {[expr $col - $previous] > 1} {
      lappend columns $col
    }
    set previous $col
  }
  return $columns
}

#------------------------------------------------------------------------
# ::tb::utils::report_design_summary::extract_row
#------------------------------------------------------------------------
# Extract all the cells of a row (string) based on the position
# of the columns
#------------------------------------------------------------------------
proc ::tb::utils::report_design_summary::extract_row {str columns} {
  lappend columns [string length $str]
  set row [list]
  set pos 0
  foreach col $columns {
    set value [string trim [string range $str $pos $col]]
    lappend row $value
    set pos [incr col 2]
  }
  return $row
}

#------------------------------------------------------------------------
# ::tb::utils::report_design_summary::parseClockInteractionReport
#------------------------------------------------------------------------
# Extract the clock table from report_clock_interaction and return
# a Tcl list
#------------------------------------------------------------------------
proc ::tb::utils::report_design_summary::parseClockInteractionReport {report} {
  set columns [list]
  set table [list]
  set report [split $report \n]
  set SM {header}
  for {set index 0} {$index < [llength $report]} {incr index} {
    set line [lindex $report $index]
    switch $SM {
      header {
        if {[regexp {^\-+\s+\-+\s+\-+} $line]} {
          set columns [extract_columns [string trimright $line] { }]
          set header1 [extract_row [lindex $report [expr $index -2]] $columns]
          set header2 [extract_row [lindex $report [expr $index -1]] $columns]
          set row [list]
          foreach h1 $header1 h2 $header2 {
            lappend row [string trim [format {%s %s} [string trim [format {%s} $h1]] [string trim [format {%s} $h2]]] ]
          }
          lappend table $row
          set SM {table}
        }
      }
      table {
        # Check for empty line or for line that match '<empty>'
        if {(![regexp {^\s*$} $line]) && (![regexp -nocase {^\s*No clocks found.\s*$} $line])} {
          set row [extract_row $line $columns]
          lappend table $row
        }
      }
      end {
      }
    }
  }
  return $table
}


#------------------------------------------------------------------------
# ::tb::utils::report_design_summary::createSummaryDRCReport
#------------------------------------------------------------------------
# Create a summary from the report_methodology/report_drc report to
# reduce the memory footprint
#------------------------------------------------------------------------
proc ::tb::utils::report_design_summary::createSummaryDRCReport {file} {
  # Abstract original report_methodology report:
  #   2. REPORT DETAILS
  #   -----------------
  #   CKLD-2#1 Warning
  #   Clock Net has IO Driver, not a Clock Buf, and/or non-Clock loads
  #   Clock net FC_TSCLK_IBUF_inst/O is directly driven by an IO rather than a Clock Buffer or may be an IO driving a mix of Clock Buffer and non-Clock loads. This connectivity should be reviewed and corrected as appropriate. Driver(s): FC_TSCLK_IBUF_inst/IBUFCTRL_INST/O
  #   Related violations: <none>
  #
  #   PDRC-190#1 Warning
  #   Suboptimally placed synchronized register chain
  #   The FDCE cell dbg_hub/inst/CORE_XSDB.UUT_MASTER/U_ICON_INTERFACE/U_CMD5/shift_reg_in_reg[2] in site SLICE_X105Y474 is part of a synchronized register chain that is suboptimally placed as the load FDCE cell dbg_hub/inst/CORE_XSDB.UUT_MASTER/U_ICON_INTERFACE/U_CMD5/shift_reg_in_reg[1] is not placed in the same (SLICE) site.
  #   Related violations: <none>
  #
  #   SYNTH-6#1 Warning
  #   Timing of a block RAM might be sub-optimal
  #   The timing for the instance gen_phy_user.user/phy_slr_1_1/user_fault_monitor/from_rom_rdata_reg, implemented as a block RAM, might be sub-optimal as no output register was merged into the block
  #   Related violations: <none>
  #
  #   SYNTH-8#1 Warning
  #   Resource sharing
  #   The adder gen_phy_user.user/phy_slr_0_1/gen_ports[0].mld_test_pattern_1/TxPreMLD_i/TSXSUMADJ/Cnt_SOFoffsetP1_reg[3]_i_1_CARRY8 is shared. Consider applying a KEEP on the inputs of the operator to prevent sharing.
  #   Related violations: <none>
  if {[regexp {.gz$} $file]} {
    # gzip-ed file
    set FH [open "| zcat $file" {r}]
  } else {
    set FH [open $file {r}]
  }
#   set FH [open $file {r}]
  set content [list]
  catch {unset drcs}
  catch {unset drcmsg}
  catch {unset drcseverity}
  set keys [list]
  set loop 1
  set found 0
  set drcname {n/a}; set drcnum {n/a}; set severity {n/a}
  while {$loop && ![eof $FH]} {
    gets $FH line
    if {[regexp {^\s*([^-]+)-([0-9]+)#[0-9]+\s+([\w]+)} $line -- drcname drcnum severity]} {
      set found 1
      # Capture the first line of the DRC
      # e.g:
      #  PDRC-190#1 Warning
    } else {
      if {$found} {
        # Capture the second line of the DRC
        # e.g:
        #  Suboptimally placed synchronized register chain
        set drcmsg(${drcname}-${drcnum}) [string trim $line]
        set drcseverity(${drcname}-${drcnum}) [string trim $severity]
        if {![info exists drcs(${drcname}-${drcnum})]} {
          set drcs(${drcname}-${drcnum}) 0
        }
        incr drcs(${drcname}-${drcnum})
        lappend keys [list $drcname $drcnum ${drcname}-${drcnum} ]
        set found 0
        set drcname {n/a}; set drcnum {n/a}; set severity {n/a}
      }
    }
  }
  close $FH
  # Sort by drc name and drc number
  set keys [lsort -unique $keys]
  set keys [lsort -increasing -dictionary -index 0 [lsort -increasing -integer -index 1 $keys]]
  # Recreate a fake summary report which is much smaller
  # E.g:
  #   1 CKLD-2 [Warning] [Clock Net has IO Driver, not a Clock Buf, and/or non-Clock loads]
  #   1 CLKC-5 [Warning] [BUFGCE with constant CE has BUFG driver]
  #   2 CLKC-21 [Warning] [MMCME3 with ZHOLD does not drive sequential IO]
  #   1 CLKC-29 [Warning] [MMCME3 not driven by IO has BUFG in feedback loop]
  #   4 CLKC-39 [Warning] [Substitute PLLE3 for MMCME3 check]
  #   1 PDRC-190 [Warning] [Suboptimally placed synchronized register chain]
  #   127 SYNTH-4 [Warning] [Shallow depth for a dedicated block RAM]
  #   249 SYNTH-6 [Warning] [Timing of a block RAM might be sub-optimal]
  #   721 SYNTH-8 [Warning] [Resource sharing]
  #   73 SYNTH-9 [Warning] [Small multiplier]
  #   3 TIMING-3 [Warning] [Invalid primary clock on Clock Modifying Block]
  #   1000 TIMING-9 [Warning] [Unknown CDC Logic]
  #   1000 TIMING-10 [Warning] [Missing property on synchronizer]
  #   96 TIMING-11 [Warning] [Inappropriate max delay with datapath only option]
  #   11 TIMING-17 [Warning] [Non-clocked sequential cell]
  #   23 TIMING-18 [Warning] [Missing input or output delay]
  #   31 TIMING-24 [Warning] [Overridden Max delay datapath only]
  #   234 TIMING-28 [Warning] [Auto-derived clock referenced by a timing constraint]
  #   12 XDCB-1 [Warning] [Runtime intensive exceptions]
  #   2 XDCB-2 [Warning] [Clock defined on multiple objects]
  #   1 XDCC-4 [Warning] [User Clock constraint overwritten with the same name]
  #   1 XDCC-8 [Warning] [User Clock constraint overwritten on the same source]
  #   1 XDCV-2 [Warning] [Incomplete constraint coverage due to missing replicated objects.]
  foreach el $keys {
    foreach {- - key} $el { break }
    lappend content [format {  %s %s [%s] [%s]} $drcs($key) $key $drcseverity($key) $drcmsg($key)]
  }
  set res [join $content \n]
  return $res
}

#------------------------------------------------------------------------
# ::tb::utils::report_design_summary::enter
#------------------------------------------------------------------------
# Used for flow automation
#------------------------------------------------------------------------
# Called before a command is executed
#------------------------------------------------------------------------
proc ::tb::utils::report_design_summary::enter {cmd op} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable tracedb
  lappend tracedb(enter) [list [clock seconds] 1 $cmd]
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::utils::report_design_summary::leave
#------------------------------------------------------------------------
# Used for flow automation
#------------------------------------------------------------------------
# Called after a command is executed
#------------------------------------------------------------------------
proc ::tb::utils::report_design_summary::leave {cmd code result op} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable params
  variable tracedb
  lappend tracedb(leave) [list [clock seconds] 1 $cmd $code $result]

  foreach {start - cmd} [lindex $tracedb(enter) end] { break }
  foreach {end - - code result} [lindex $tracedb(leave) end] { break }

  if {$code} {
    puts " -W- Design summary skipped. Command [lindex $cmd 0] failed: [regsub {\n} $result {}]"
    return -code ok
  }

  foreach var {project version release experiment step directive runtime} { set $var $params($var) }
  set duration 0
  set directive {Default}
  # E.g: place_design
  set step [lindex $cmd 0]
  set skipsummary 0
  for {set idx 1} {$idx < [llength $cmd]} {incr idx} {
    set el [lindex $cmd $idx]
    switch -regexp -- $el {
      {^-di(r(e(c(t(i(ve?)?)?)?)?)?)?$} {
        set directive [lindex $cmd [expr $idx +1]]
        # Skip next argument
        incr idx
      }
      {^-u(n(p(l(a(ce?)?)?)?)?)?$} -
      {^-u(n(r(o(u(te?)?)?)?)?)?$} {
        # Do not generate a design summary
        set skipsummary 1
      }
      {^-h(e(lp?)?)?$} {
        # Do not generate a design summary
        set skipsummary 1
      }
      {^-d(i(s(a(b(l(e(_(a(r(cs?)?)?)?)?)?)?)?)?)?)?$} -
      {^-fo(r(c(e(_(r(e(p(l(i(c(a(t(i(o(n(_(o(n(_(n(e(ts?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?$} {
        # Do not generate a design summary
        set skipsummary 1
        # Skip next argument
        incr idx
      }
    }
  }

  if {$skipsummary} {
    set tracedb(enter) [list]
    set tracedb(leave) [list]
    return -code ok
  }

  set stepnum $tracedb(count)
  catch { set duration [expr $end - $start] }
  incr tracedb(count)
  set dir $tracedb(dir)
  set filename [file join $dir ${tracedb(prefix)}summary.${stepnum}.${step}.${directive}.csv]
#   tb::report_design_summary -project $project -version $version -experiment $experiment -step ${stepnum}.$step -directive $directive \
#                             -runtime $duration \
#                             -file $filename \
#                             {*}$tracedb(cmdline)
  set cmdline $tracedb(cmdline)
  if {$params(vivadolog) != {}} {
    if {[file exists $params(vivadolog)]} {
      lappend cmdline {-vivadolog}
      lappend cmdline $params(vivadolog)
    } else {
      puts " -W- Vivado log file '$params(vivadolog)' does not exist"
    }
  }
  # Callback proc to extract the design summary
  set callback $tracedb(callback)
  if {[catch { $callback $project $version $experiment $step $directive $stepnum $duration $dir $tracedb(prefix) $cmdline } errorstring]} {
    puts " -E- Callback failed: $errorstring"
  }

  # Keep history
  lappend tracedb(history) [list $step $directive $start $end $duration $filename \
                                 [tb::utils::report_design_summary::getMetric {timing.wns}] \
                                 [tb::utils::report_design_summary::getMetric {timing.tns}] \
                                 [tb::utils::report_design_summary::getMetric {timing.tnsFallingEp}] \
                                 [tb::utils::report_design_summary::getMetric {timing.whs}] \
                                 [tb::utils::report_design_summary::getMetric {timing.ths}] \
                                 [tb::utils::report_design_summary::getMetric {timing.thsFallingEp}] \
                           ]
  # Report flow summary
  reportFlowSummary [format {%s%s} $tracedb(prefix) flow_summary.rpt]

  # Reset variables
  set tracedb(enter) [list]
  set tracedb(leave) [list]

  return -code ok
}

#------------------------------------------------------------------------
# ::tb::utils::report_design_summary::trace_off
#------------------------------------------------------------------------
# Used for flow automation
#------------------------------------------------------------------------
# Remove all 'trace' commands
#------------------------------------------------------------------------
proc ::tb::utils::report_design_summary::trace_off {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable tracedb
  foreach cmd $tracedb(cmdlist) {
    catch { trace remove execution $cmd enter ::tb::utils::report_design_summary::enter }
    catch { trace remove execution $cmd leave ::tb::utils::report_design_summary::leave }
  }
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::utils::report_design_summary::trace_on
#------------------------------------------------------------------------
# Used for flow automation
#------------------------------------------------------------------------
# Add all 'trace' commands
#------------------------------------------------------------------------
proc ::tb::utils::report_design_summary::trace_on {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable tracedb
  # For safety, tries to remove any existing 'trace' commands
  ::tb::utils::report_design_summary::trace_off
  # Now adds 'trace' commands
  foreach cmd $tracedb(cmdlist) {
    catch { trace add execution $cmd enter ::tb::utils::report_design_summary::enter }
    catch { trace add execution $cmd leave ::tb::utils::report_design_summary::leave }
  }
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::utils::report_design_summary::trace_info
#------------------------------------------------------------------------
# Used for flow automation
#------------------------------------------------------------------------
# Dump the 'trace' information on each command
#------------------------------------------------------------------------
proc ::tb::utils::report_design_summary::trace_info {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable tracedb
  foreach cmd $tracedb(cmdlist) {
    if {[catch { puts "   $cmd:[trace info execution $cmd]" } errorstring]} {
       puts "   $cmd: <ERROR: $errorstring>"
    }
  }
  return -code ok
}

#------------------------------------------------------------------------
# ::tb::utils::report_design_summary::callbackAutomation
#------------------------------------------------------------------------
# Used for flow automation
#------------------------------------------------------------------------
# Callback proc to generate the design summary
#------------------------------------------------------------------------
proc ::tb::utils::report_design_summary::callbackAutomation {project version experiment step directive count runtime dir prefix cmdline} {
  set SLLs {}
  catch { set SLLs [tb::report_slls -return_summary] }
  set filename [file join $dir ${prefix}summary.${count}.${step}.${directive}.csv]
  tb::report_design_summary -project $project -version $version -experiment $experiment -step ${count}.$step -directive $directive \
                            -runtime $runtime \
                            -file $filename \
                            {*}$cmdline
  return -code ok
}

# proc ::tb::utils::report_design_summary::callbackAutomation {project version experiment step directive count runtime dir prefix cmdline} {
#   set SLLs {}
#   catch { set SLLs [tb::report_slls -return_summary] }
#   set filename [file join $dir ${prefix}summary.${count}.${step}.${directive}.csv]
#   tb::report_design_summary -project $project -version $version -experiment $experiment -step ${count}.$step -directive $directive \
#                             -runtime $runtime \
#                             -file $filename \
#                             {*}$cmdline \
#                             -add_metrics [list \
#                                            [list design.slls {SLLs Connections} $SLLs] \
#                                          ]
#   return -code ok
# }

#------------------------------------------------------------------------
# ::tb::utils::report_design_summary::reportFlowSummary
#------------------------------------------------------------------------
# Used for flow automation
#------------------------------------------------------------------------
# Report flow summary
#------------------------------------------------------------------------
proc ::tb::utils::report_design_summary::reportFlowSummary {{filename {flow_summary.rpt}}} {
  variable params
  variable tracedb

  # +-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
  # | Flow Summary                                                                                                                                                                              |
  # +-----------------+-----------+--------+---------+---+--------+---------+---+---------+------------------------------+------------------------------+---------------------------------------+
  # | Step            | Directive | WNS    | TNS     | # | WHS    | THS     | # | Runtime | Start                        | End                          | Filename                              |
  # +-----------------+-----------+--------+---------+---+--------+---------+---+---------+------------------------------+------------------------------+---------------------------------------+
  # | opt_design      | Default   | -3.887 | -5.923  | 2 | -0.997 | -2.886  | 6 | 1 sec   | Thu Jul 07 17:10:21 PDT 2016 | Thu Jul 07 17:10:22 PDT 2016 | summary.0.opt_design.Default.csv      |
  # | place_design    | Explore   | -5.974 | -14.049 | 5 | -2.357 | -10.817 | 6 | 13 secs | Thu Jul 07 17:10:24 PDT 2016 | Thu Jul 07 17:10:37 PDT 2016 | summary.1.place_design.Explore.csv    |
  # | phys_opt_design | Default   | -5.869 | -13.944 | 5 | -2.050 | -10.367 | 6 | 2 secs  | Thu Jul 07 17:10:39 PDT 2016 | Thu Jul 07 17:10:41 PDT 2016 | summary.2.phys_opt_design.Default.csv |
  # | route_design    | Default   | -6.022 | -19.179 | 9 | 0.120  | 0.000   | 0 | 21 secs | Thu Jul 07 17:10:46 PDT 2016 | Thu Jul 07 17:11:07 PDT 2016 | summary.4.route_design.Default.csv    |
  # | phys_opt_design | Default   | -6.022 | -19.010 | 9 | 0.120  | 0.000   | 0 | 4 secs  | Thu Jul 07 17:11:14 PDT 2016 | Thu Jul 07 17:11:18 PDT 2016 | summary.6.phys_opt_design.Default.csv |
  # +-----------------+-----------+--------+---------+---+--------+---------+---+---------+------------------------------+------------------------------+---------------------------------------+
  set tbl [::prettyTable {Flow Summary}]
  $tbl header {Step Directive WNS TNS # WHS THS # Runtime Start End Filename}
  foreach el $tracedb(history) {
    foreach {step directive start end duration file wns tns sviols whs ths hviols} $el { break }
    $tbl addrow [list $step $directive $wns $tns $sviols $whs $ths $hviols [formatRuntime $duration] [clock format $start] [clock format $end] [file tail $file] ]
  }
  if {$filename != {}} {
    puts [$tbl print]
    puts [$tbl export -format {table} -file $filename]
    puts " -I- Generated file [file normalize $filename]"
  } else {
    puts [$tbl print]
  }
  catch {$tbl destroy}

  return -code ok
}

##-----------------------------------------------------------------------
## config_flow_automation
##-----------------------------------------------------------------------
## Used for flow automation
##-----------------------------------------------------------------------
## Configuration proc
##-----------------------------------------------------------------------
proc ::tb::utils::report_design_summary::config_flow_automation {args} {
  variable params
  variable tracedb

  set enableFlowAutomation -1
  set ofilename {}
  set summary 0
  set error 0
  set show_help 0
  if {[llength $args] == 0} {
    incr show_help
  }
  #-------------------------------------------------------
  # Process command line arguments
  #-------------------------------------------------------
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-o(u(t(p(ut?)?)?)?)?$} -
      {^-f(i(le?)?)?$} {
        set ofilename [lshift args]
      }
      {^-pr(o(j(e(ct?)?)?)?)?$} {
        set params(project) [lshift args]
      }
      {^-ve(r(s(i(on?)?)?)?)?$} {
        set params(version) [lshift args]
      }
      {^-ex(p(e(r(i(m(e(nt?)?)?)?)?)?)?)?$} {
        set params(experiment) [lshift args]
      }
      {^-st(ep?)?$} {
        set params(step) [lshift args]
      }
      {^-di(r(e(c(t(i(ve?)?)?)?)?)?)?$} {
        set params(directive) [lshift args]
      }
      {^-di(r(e(c(t(o(ry?)?)?)?)?)?)?$} {
        set dir [lshift args]
        if {![file isdirectory $dir]} {
          puts " -W- Ignoring invalid directory '$dir'"
        } else {
          set tracedb(dir) $dir
        }
      }
      {^-pr(e(f(ix?)?)?)?$} {
        set tracedb(prefix) [lshift args]
      }
      {^-cm(d(l(i(ne?)?)?)?)?$} {
        set tracedb(cmdline) [lshift args]
      }
      {^-en(a(b(l(e(_(f(l(ow?)?)?)?)?)?)?)?)?$} {
        set enableFlowAutomation 1
      }
      {^-di(s(a(b(l(e(_(f(l(ow?)?)?)?)?)?)?)?)?)?$} {
        set enableFlowAutomation 0
      }
      {^-ca(l(l(b(a(ck?)?)?)?)?)?$} {
        set tracedb(callback) [lshift args]
      }
      {^-trace_info$} {
        ::tb::utils::report_design_summary::trace_info
      }
      {^-su(m(m(a(ry?)?)?)?)?$} {
        set summary 1
      }
      {^-reset$} {
        set params(project) {}
        set params(version) {}
        set params(experiment) {}
        set tracedb(count) 0
        set tracedb(dir) [uplevel #0 pwd]
        set tracedb(cmdlist) {opt_design place_design phys_opt_design route_design}
        set tracedb(cmdline) {-verbose -details -all -exclude {cdc methodology drc check_timing constraints clock_interaction congestion} -csv}
#         set tracedb(cmdline) {-verbose -details -all -exclude {cdc methodology drc} -csv}
        set tracedb(callback) {::tb::utils::report_design_summary::callbackAutomation}
        set tracedb(history) [list]
        set tracedb(enter) [list]
        set tracedb(leave) [list]
      }
      {^-vi(v(a(d(o(l(og?)?)?)?)?)?)?$} {
        set params(vivadolog) [lshift args]
      }
      {^-v(e(r(b(o(se?)?)?)?)?)?$} {
        set params(verbose) 1
      }
      {^qu(i(et?)?)?$} -
      {^-nov(e(r(b(o(se?)?)?)?)?)?$} {
        set params(verbose) 0
      }
      {^-d(e(b(ug?)?)?)?$} {
        set params(debug) 1
      }
      {^-nod(e(b(ug?)?)?)?$} {
        set params(debug) 0
      }
      {^-debug$} {
        set params(debug) 1
      }
      {^-h(e(lp?)?)?$} {
        set show_help 1
      }
      default {
        if {[string match "-*" $name]} {
          puts " -E- option '$name' is not a valid option"
          incr error
        } else {
          puts " -E- option '$name' is not a valid option"
          incr error
        }
      }
    }
  }

  if {$show_help} {
    # <-- HELP
    puts [format {
      Usage: tb::utils::report_design_summary::config_flow_automation
                  [-enable_flow]
                  [-disable_flow]
                  [-cmdline <string>]
                  [-callback <proc>]
                +--------------------+
                  [-project <string>]
                  [-version <string>]
                  [-experiment <string>]
                  [-step <string>]
                  [-directive <string>]
                +--------------------+
                  [-vivadolog <filename>]
                  [-prefix <string>]
                  [-summary]
                  [-file <filename>|-output <filename>]
                  [-reset]
                  [-debug|-nodebug]
                  [-verbose|-noverbose]
                  [-help]

      Description: Configure flow automation for design summary

        -enable_flow: enable auto-capturing of design summaries during implementation flow
        -disable_flow: disable auto-capturing of design summaries during implementation flow
        -vivadolog to point to Vivado log file to extract additional metrics
        -cmdline: command line to be passed to tb::report_design_summary command
          Default: -verbose -details -timing -utilization -route -csv
        -prefix: prefix to be added to the design summary filename

      Example:
         ::tb::utils::report_design_summary::config_flow_automation -enable_flow -cmdline {-details -all -exclude {cdc methodology drc} -csv}
         ::tb::utils::report_design_summary::config_flow_automation -enable_flow -prefix opt_
         ::tb::utils::report_design_summary::config_flow_automation -disable_flow


    } ]
    # HELP -->

    return -code ok
  }

  if {$error} {
    error "\n Some error(s) occured. Cannot continue.\n"
#    exit -1
  }

  switch $enableFlowAutomation {
    0 {
      ::tb::utils::report_design_summary::trace_off
    }
    1 {
      set tracedb(cmdlist) [list opt_design place_design phys_opt_design route_design]
      set tracedb(enter) [list]
      set tracedb(leave) [list]
      ::tb::utils::report_design_summary::trace_on
    }
    default {
    }
  }

  if {$summary} {
    reportFlowSummary $ofilename
  }

  return -code ok
}


##-----------------------------------------------------------------------
## orderedCategories orderedMetrics
##-----------------------------------------------------------------------
## Order for categories and metrics
##-----------------------------------------------------------------------
# Keep the list below in sync between report_design_summary.tcl
# and compare_design_summary
proc ::tb::utils::report_design_summary::orderedCategories {} {
  # Ordered list of categories
  set L [list \
          tag \
          vivado \
          design \
          utilization \
          timing \
          clockpair \
          clkinteraction \
          checktiming \
          congestion \
          route \
          cdc \
          methodology \
          drc \
          constraints \
        ]

  return $L
}

# Keep the list below in sync between report_design_summary.tcl
# and compare_design_summary
proc ::tb::utils::report_design_summary::orderedMetrics {} {
  # Ordered list of metrics
  set L [list \
          tag.project \
          tag.version \
          tag.experiment \
          tag.step \
          tag.directive \
          tag.runtime \
          tag.date \
          tag.time \
           \
          vivado.version \
          vivado.build \
          vivado.plateform \
          vivado.os \
          vivado.os.description \
          vivado.os.version \
          vivado.top \
           \
          design.part.architecture.name \
          design.part.architecture \
          design.part \
          design.part.speed.class \
          design.part.speed.label \
          design.part.speed.id \
          design.part.speed.date \
          design.cells.blackbox \
          design.cells.hier \
          design.cells.primitive \
          design.cells.hlutnm \
          design.cells.hlutnm.pct \
          design.cells.ratiofdlut \
          design.clocks \
          design.clocks.primary \
          design.clocks.usergenerated \
          design.clocks.autoderived \
          design.clocks.virtual \
          design.ips.list \
          design.ips \
          design.nets \
          design.nets.slls \
          design.pblocks \
          design.ports \
          design.slrs \
           \
          utilization.clb.ff \
          utilization.clb.ff.pct \
          utilization.clb.lut \
          utilization.clb.lut.pct \
          utilization.clb.lutmem \
          utilization.clb.lutmem.pct \
          utilization.clb.carry8 \
          utilization.clb.carry8.pct \
          utilization.clb.f7mux \
          utilization.clb.f7mux.pct \
          utilization.clb.f8mux \
          utilization.clb.f8mux.pct \
          utilization.clb.f9mux \
          utilization.clb.f9mux.pct \
          utilization.ctrlsets.lost \
          utilization.ctrlsets.uniq \
          utilization.clk.bufgce \
          utilization.clk.bufgce.pct \
          utilization.clk.bufgcediv \
          utilization.clk.bufgcediv.pct \
          utilization.clk.bufggt \
          utilization.clk.bufggt.pct \
          utilization.clk.bufgps \
          utilization.clk.bufgps.pct \
          utilization.clk.bufgctrl \
          utilization.clk.bufgctrl.pct \
          utilization.dsp \
          utilization.dsp.pct \
          utilization.io \
          utilization.io.pct \
          utilization.ram.blockram \
          utilization.ram.distributedram \
          utilization.ram.tile \
          utilization.ram.tile.pct \
           \
          timing.wns \
          timing.tns \
          timing.tnsFallingEp \
          timing.tnsTotalEp \
          timing.wns.spclock \
          timing.wns.epclock \
          timing.wns.path \
          timing.whs \
          timing.ths \
          timing.thsFallingEp \
          timing.thsTotalEp \
          timing.whs.spclock \
          timing.whs.epclock \
          timing.whs.path \
          timing.wpws \
          timing.tpws \
          timing.tpwsFailingEp \
          timing.tpwsTotalEp \
           \
          clkinteraction.timed \
          clkinteraction.timed_unsafe \
          clkinteraction.asynchronous_groups \
          clkinteraction.exclusive_groups \
          clkinteraction.false_path \
          clkinteraction.max_delay_datapath_only \
          clkinteraction.partial_false_path \
          clkinteraction.partial_false_path_unsafe \
           \
          checktiming.constant_clock \
          checktiming.generated_clocks \
          checktiming.latch_loops \
          checktiming.loops \
          checktiming.multiple_clock \
          checktiming.no_clock \
          checktiming.no_input_delay \
          checktiming.no_output_delay \
          checktiming.partial_input_delay \
          checktiming.partial_output_delay \
          checktiming.pulse_width_clock \
          checktiming.unconstrained_internal_endpoints \
           \
          congestion.placer \
          congestion.router \
          congestion.estimated.global \
          congestion.estimated.long \
          congestion.estimated.short \
           \
          route.nets \
          route.routed \
          route.fixed \
          route.errors \
           \
          constraints.create_clock \
          constraints.create_generated_clock \
          constraints.group_path \
          constraints.set_bus_skew \
          constraints.set_case_analysis \
          constraints.set_clock_groups \
          constraints.set_clock_latency \
          constraints.set_clock_sense \
          constraints.set_clock_uncertainty \
          constraints.set_data_check \
          constraints.set_disable_timing \
          constraints.set_external_delay \
          constraints.set_false_path \
          constraints.set_input_delay \
          constraints.set_input_jitter \
          constraints.set_max_delay \
          constraints.set_min_delay \
          constraints.set_multicycle_path \
          constraints.set_output_delay \
          constraints.set_system_jitter \
        ]

  # Trick to order clockpair metrics (clockpair.*)
  foreach idx [iota 0 9] {
    lappend L [format {clockpair.%s.wns} $idx]
    lappend L [format {clockpair.%s.tns} $idx]
    lappend L [format {clockpair.%s.from} $idx]
    lappend L [format {clockpair.%s.to} $idx]
  }

  # Trick to order CDC metrics (cdc.*)
  foreach idx [iota 0 100] {
    lappend L [format {cdc.cdc-%s} $idx]
  }

  # Trick to order methodology check metrics (drc.*)
  foreach name [list ckld clkc pdrc synth timing xdcb xdcc xdch xdcv] {
    foreach idx [iota 0 500] {
      lappend L [format {methodology.%s-%s} $name $idx]
    }
  }

  return $L
}

###########################################################################
##
## Simple package to handle printing of tables
##
## %> set tbl [Table::Create {this is my title}]
## %> $tbl header [list "name" "#Pins" "case_value" "user_case_value"]
## %> $tbl addrow [list A/B/C/D/E/F 12 - -]
## %> $tbl addrow [list A/B/C/D/E/F 24 1 -]
## %> $tbl separator
## %> $tbl addrow [list A/B/C/D/E/F 48 0 1]
## %> $tbl indent 0
## %> $tbl print
## +-------------+-------+------------+-----------------+
## | name        | #Pins | case_value | user_case_value |
## +-------------+-------+------------+-----------------+
## | A/B/C/D/E/F | 12    | -          | -               |
## | A/B/C/D/E/F | 24    | 1          | -               |
## +-------------+-------+------------+-----------------+
## | A/B/C/D/E/F | 48    | 0          | 1               |
## +-------------+-------+------------+-----------------+
## %> $tbl indent 2
## %> $tbl print
##   +-------------+-------+------------+-----------------+
##   | name        | #Pins | case_value | user_case_value |
##   +-------------+-------+------------+-----------------+
##   | A/B/C/D/E/F | 12    | -          | -               |
##   | A/B/C/D/E/F | 24    | 1          | -               |
##   +-------------+-------+------------+-----------------+
##   | A/B/C/D/E/F | 48    | 0          | 1               |
##   +-------------+-------+------------+-----------------+
## %> $tbl sort {-index 1 -increasing} {-index 2 -dictionary}
## %> $tbl print
## %> $tbl destroy
##
###########################################################################

# namespace eval Table { set n 0 }

# Trick to silence the linter
eval [list namespace eval ::Table {
  set n 0
} ]

proc ::Table::Create { {title {}} } { #-- constructor
  # Summary :
  # Argument Usage:
  # Return Value:

  variable n
  set instance [namespace current]::[incr n]
  namespace eval $instance { variable tbl [list]; variable header [list]; variable indent 0; variable title {}; variable numrows 0 }
  interp alias {} $instance {} ::Table::do $instance
  # Set the title
  $instance title $title
  set instance
}

proc ::Table::do {self method args} { #-- Dispatcher with methods
  # Summary :
  # Argument Usage:
  # Return Value:

  upvar #0 ${self}::tbl tbl
  upvar #0 ${self}::header header
  upvar #0 ${self}::numrows numrows
  switch -- $method {
      header {
        set header [lindex $args 0]
        return 0
      }
      addrow {
        eval lappend tbl $args
        incr numrows
        return 0
      }
      separator {
        eval lappend tbl {%%SEPARATOR%%}
        return 0
      }
      title {
        set ${self}::title [lindex $args 0]
        return 0
      }
      indent {
        set ${self}::indent $args
        return 0
      }
      print {
        eval ::Table::print $self
      }
      csv {
        eval ::Table::printcsv $self
      }
      length {
        return $numrows
      }
      sort {
        # Each argument is a list of: <lsort arguments>
        set command {}
        while {[llength $args]} {
          if {$command == {}} {
            set command "lsort [[namespace parent]::lshift args] \$tbl"
          } else {
            set command "lsort [[namespace parent]::lshift args] \[$command\]"
          }
        }
        if {[catch { set tbl [eval $command] } errorstring]} {
          puts " -E- $errorstring"
        } else {
        }
      }
      reset {
        set ${self}::tbl [list]
        set ${self}::header [list]
        set ${self}::indent 0
        set ${self}::title {}
        return 0
      }
      destroy {
        set ${self}::tbl [list]
        set ${self}::header [list]
        set ${self}::indent 0
        set ${self}::title {}
        namespace delete $self
        return 0
      }
      default {error "unknown method $method"}
  }
}

proc ::Table::print {self} {
   upvar #0 ${self}::tbl table
   upvar #0 ${self}::header header
   upvar #0 ${self}::indent indent
   upvar #0 ${self}::title title
   set maxs {}
   foreach item $header {
       lappend maxs [string length $item]
   }
   set numCols [llength $header]
   foreach row $table {
       if {$row eq {%%SEPARATOR%%}} { continue }
       for {set j 0} {$j<$numCols} {incr j} {
            set item [lindex $row $j]
            set max [lindex $maxs $j]
            if {[string length $item]>$max} {
               lset maxs $j [string length $item]
           }
       }
   }
  set head " [string repeat " " [expr $indent * 4]]+"
  foreach max $maxs {append head -[string repeat - $max]-+}

  # Generate the title
  if {$title ne {}} {
    # The upper separator should something like +----...----+
    append res " [string repeat " " [expr $indent * 4]]+[string repeat - [expr [string length [string trim $head]] -2]]+\n"
    # Suports multi-lines title
    foreach line [split $title \n] {
      append res " [string repeat " " [expr $indent * 4]]| "
      append res [format "%-[expr [string length [string trim $head]] -4]s" $line]
      append res " |\n"
    }
  }

  # Generate the table header
  append res $head\n
  # Generate the table rows
  set first 1
  set numsep 0
  foreach row [concat [list $header] $table] {
      if {$row eq {%%SEPARATOR%%}} {
        incr numsep
        if {$numsep == 1} { append res $head\n }
        continue
      } else {
        set numsep 0
      }
      append res " [string repeat " " [expr $indent * 4]]|"
      foreach item $row max $maxs {append res [format " %-${max}s |" $item]}
      append res \n
      if {$first} {
        append res $head\n
        set first 0
        incr numsep
      }
  }
  append res $head
  set res
}

proc ::Table::printcsv {self args} {
  upvar #0 ${self}::tbl table
  upvar #0 ${self}::header header
  upvar #0 ${self}::title title

  array set defaults [list \
      -delimiter {,} \
    ]
  array set options [array get defaults]
  array set options $args
  set sepChar $options(-delimiter)

  set res {}
  # Support for multi-lines title
  set first 1
  foreach line [split $title \n] {
    if {$first} {
      set first 0
      append res "# title${sepChar}[::Table::list2csv [list $line] $sepChar]\n"
    } else {
      append res "#      ${sepChar}[::Table::list2csv [list $line] $sepChar]\n"
    }
  }
  append res "[::Table::list2csv $header $sepChar]\n"
  set count 0
  set numsep 0
  foreach row $table {
    incr count
    if {$row eq {%%SEPARATOR%%}} {
      incr numsep
      if {$numsep == 1} {
        append res "# [::Table::list2csv {++++++++++++++++++++++++++++++++++++++++++++++++++} $sepChar]\n"
      }
      continue
    } else {
      set numsep 0
    }
    append res "[::Table::list2csv $row $sepChar]\n"
  }
  return $res
}

proc ::Table::list2csv { list {sepChar ,} } {
  set out ""
  set sep {}
  foreach val $list {
    if {[string match "*\[\"$sepChar\]*" $val]} {
      append out $sep\"[string map [list \" \"\"] $val]\"
    } else {
      append out $sep\"$val\"
    }
    set sep $sepChar
  }
  return $out
}

namespace eval ::tb::utils {
  namespace import -force ::tb::utils::report_design_summary::report_design_summary
  namespace import -force ::tb::utils::report_design_summary::config_flow_automation
}

namespace eval ::tb {
  namespace import -force ::tb::utils::report_design_summary
  namespace import -force ::tb::utils::config_flow_automation
}


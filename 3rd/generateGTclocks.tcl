########################################################################################
##
## Company:        	  Xilinx, Inc.
##
## Created by:     	  Frank Mueller (fmuelle)
##                    
## Target device: 	  V-7, UltraScale
##                    
## Description: 	  Calculate [r|t]xoutclk period based on GT*CHANNEL and GT*COMMON REFCLK inputs,  
##                    parameters, and clock select values and compare to actual clock constraint  
## 
## Dependencies: 	  Vivado 2014.1
##                    
## Calling syntax:    source <your_Tcl_script_location>/generateGTclocks.tcl
##                    
## Usage example:     Vivado% set GT_CHANNELs [get_cells -hier -filter LIB_CELL=~GT*CHANNEL] 
##                    Vivado% foreach CHANNEL $GT_CHANNELs {get_GT_CHANNEL_outclk_freq $CHANNEL}
##                    
## Revision history:
##                    Rev      Date    login  Comment
##                    2.0  02/13/14  fmuelle  added support for GTXE2
##                    2.1  02/26/14  fmuelle  added support for undefined clocks, fixed issues with non-constant clock select values
##                    2.2  03/05/14  fmuelle  added support for REFCLK coming from ports, fixed issues with multi-QPLL REFCLK name (appended QPLL number)
##                    2.3  03/13/14  fmuelle  added -quiet option to get_ports to avoid warnings.
##                    2.4  04/16/14  fmuelle  added support for [R|T]X_INT_DATAWIDTH of 2 for GTYE3_CHANNEL and QPLL[0|1]CLKOUT_RATE for GTYE3_COMMON.
##
## TODO:              run more tests on various clock select values and multiple REFCLK inputs
##
## Status:            Currently supports GTHE3, GTYE3, GTHE2, GTXE2
##                    Have not tested GTPE2
##

set DEBUG 1
proc dputs {msg} {global DEBUG; if {$DEBUG} {puts $msg} }
proc dvar {varName} {
	upvar 1 $varName varValue
	dputs "$varName = '$varValue'"
}

#global variables that define supported GT*_CHANNEL and GT*_COMMON
set V8_GT_COMMON {GTHE3_COMMON GTYE3_COMMON}
set V7_GT_COMMON {GTHE2_COMMON GTXE2_COMMON GTPE2_COMMON}
set V8_GT_CHANNEL {GTHE3_CHANNEL GTYE3_CHANNEL}
set V7_GT_CHANNEL {GTHE2_CHANNEL GTXE2_CHANNEL GTPE2_CHANNEL}
set all_GT_COMMON [concat $V7_GT_COMMON $V8_GT_COMMON]
set all_GT_CHANNEL [concat $V7_GT_CHANNEL $V8_GT_CHANNEL]
  
proc get_pin_driver {pins {options {}}} {
    # Summary : returns names of driver pins.  "0" for GROUND, "1" for POWER, "" for unconnected	
    
    # Argument Usage: 
    # pins : the pins to find drivers for
    # options : "sig_only" only return signals.  Omit POWER and GROUND
	# example:
	#    set QPLL0REFCLKSEL[0] 1
	#    set QPLL0REFCLKSEL[1] 0
	#    set QPLL0REFCLKSEL[2] 0
	#    get_pin_driver [get_pins -of $COMMON -filter NAME=~*QPLL0REFCLKSEL*]
	#    1 0 0
	dputs "\[proc\] get_pin_driver $pins $options"
	set pinDrivers {}
	set returnPins {}
	foreach pin $pins {
		set connected [get_property IS_CONNECTED $pin]
		if {$connected} {
			dputs "Connected is true"
			set driverNet [get_nets -of $pin]
			set driverNetTyp [get_property TYPE $driverNet]
			if {$driverNetTyp eq "GROUND"} {
				dputs "pin: $pin"
				dputs "driver: GROUND"
				if {$options ne "sig_only"} {set pinDrivers [concat $pinDrivers 0];set returnPins [concat $returnPins [get_property NAME $pin]]}
			} elseif {$driverNetTyp eq "POWER"} {
				dputs "pin: $pin"
				dputs "driver: POWER"
				if {$options ne "sig_only"} {set pinDrivers [concat $pinDrivers 1];set returnPins [concat $returnPins [get_property NAME $pin]]}
			} else {
				if {[get_ports -quiet -of [get_nets -segments $driverNet] -filter DIRECTION==IN] eq ""} {
					set pinDriver [get_pins -leaf -of [get_nets -segments $driverNet] -filter DIRECTION==OUT]
					dputs "pin: $pin"
					dputs "driver: $pinDriver"
					dputs "driver cell: [get_cells -of $pinDriver]"
				} else {
					set pinDriver [get_ports -quiet -of [get_nets -segments $driverNet] -filter DIRECTION==IN]
					dputs "pin: $pin"
					dputs "driver: $pinDriver"
				}
				set pinDrivers [concat $pinDrivers [get_property NAME $pinDriver]]
				set returnPins [concat $returnPins [get_property NAME $pin]]
			}
		} else {
			if {$options ne "sig_only"} {set pinDrivers [concat $pinDrivers ""];set returnPins [concat $returnPins [get_property NAME $pin]]}
			dputs "ERROR: PIN is not connected"
		}
	}
	dputs "pinDrivers: $pinDrivers"
	return $pinDrivers
	#return [list $returnPins $pinDrivers]
}

proc get_num_refclks {GT PLL} {
	global V8_GT_COMMON 
	global V7_GT_COMMON 
	global V8_GT_CHANNEL
	global V7_GT_CHANNEL
	global all_GT_COMMON
	global all_GT_CHANNEL
	dputs "\[proc\] get_num_refclks $GT $PLL"
	set GT_type [get_property LIB_CELL $GT]
	if {!([lsearch $all_GT_CHANNEL $GT_type]==-1)} {
		set pinName {REFCLK?}
	}
	if {!([lsearch $V7_GT_COMMON $GT_type]==-1)} {
		set pinName {REFCLK?}
	}
	if {!([lsearch $V8_GT_COMMON $GT_type]==-1)} {
		if {$PLL eq "QPLL0"} {set pinName {REFCLK?0}}
		if {$PLL eq "QPLL1"} {set pinName {REFCLK?1}}
	}
	return [llength [get_pin_driver [get_pins -of $GT -filter NAME=~*$pinName] sig_only]]
}

proc get_refclks {GT PLL clkArray} {
    # Summary : determines the non-constant(0,1) REFCLK inputs of CPLL and QPLL/0/1 and assigns clocks to them. Returns list of the non-constant(0,1) REFCLK pins.
    
    # Argument Usage: 
    # GT : the GT cell
    # PLL : the type of PLL (CPLL, QPLL, QPLL0, QPLL1)
    # clkArray : the COMMON or CHANNEL clock array
	# example:
	global V8_GT_COMMON 
	global V7_GT_COMMON 
	global V8_GT_CHANNEL
	global V7_GT_CHANNEL
	global all_GT_COMMON
	global all_GT_CHANNEL
	dputs "\[proc\] get_refclks $GT $PLL"
    upvar 1 $clkArray CLOCKs
	set GT_type [get_property LIB_CELL $GT]
	if {!([lsearch $all_GT_CHANNEL $GT_type]==-1)} {
		set pinName {REFCLK?}
	}
	if {!([lsearch $V7_GT_COMMON $GT_type]==-1)} {
		set pinName {REFCLK?}
	}
	if {!([lsearch $V8_GT_COMMON $GT_type]==-1)} {
		if {$PLL eq "QPLL0"} {set pinName {REFCLK?0}}
		if {$PLL eq "QPLL1"} {set pinName {REFCLK?1}}
	}
	set REFCLKs {}
	set REFCLKpins [get_pins -of $GT -filter NAME=~*$pinName]
	# set REFCLKinputs [get_pin_driver $REFCLKpins]
	# foreach REFCLKpin $REFCLKpins REFCLKinput $REFCLKinputs {}
	foreach REFCLKpin $REFCLKpins  {
	set REFCLKinput [get_pin_driver [get_pins $REFCLKpin]]
		if {!($REFCLKinput == 0 || $REFCLKinput == 1 || $REFCLKinput == "")} {
			#check if a clock is defined on the REFCLK driver and assign the clock to the REFCLK member of the CLOCKs array
			if {[get_clocks -of [get_pins $REFCLKpin]] ne ""} {
				#clock is defined on REFCLK driver pin
				dputs "clock is defined on REFCLK driver pin"
				set CLOCKs([lindex [split $REFCLKpin /] end]) [get_clocks -of [get_pins $REFCLKpin]]
			} else {
				#no clock is defined on REFCLK driver pin
				dputs "no clock is defined on REFCLK driver pin"
				set CLOCKs([lindex [split $REFCLKpin /] end]) "UNDEFINED"
			}
			lappend REFCLKs [lindex [split $REFCLKpin /] end]
		} else {
			#REFCLK driver pin is POWER or GROUND
			set CLOCKs([lindex [split $REFCLKpin /] end]) "UNDEFINED"
		}
	}
	dputs "REFCLKS: $REFCLKs"
	return $REFCLKs
}

proc pad_list {list length pad} {
	dputs "\[proc\] pad_list $length $pad"
	for {set i [llength $list]} {$i < $length} {incr i} {
		set list [concat $list $pad]
		#dputs $list
	}
	dputs "list '$list'"
	return $list
}
proc bin2dec { bin } { 
	#LSB is last in list
	set LSBLastInList 1
	set value 0
	for {set i 0} {$i < [llength $bin]} {incr i} {
		if {$LSBLastInList} {
			incr value [expr int([expr [lindex $bin $i] * [expr {pow(2,[expr {[llength $bin] - 1 - $i}])}]])]
		} else {
			incr value [expr int([expr [lindex $bin $i] * [expr {pow(2,$i)}]])]
		}
    }
    return $value 
}
 
proc get_out_clk_period {inClks clkSel outClk clkArray} {
	dputs "\[proc\] get_out_clk_period '$inClks' '$clkSel' '$clkArray'"
    upvar 1 $clkArray CLOCKs

	set numSel [llength $clkSel]
	dputs "numSel $numSel"
	set selVal [expr int([expr {pow(2,$numSel)}])]
	dputs "selVal $selVal"
	set numInClk [llength $inClks]
	dputs "numInClk $numInClk"
	set inClks [pad_list $inClks $selVal "UNDEFINED"]
	dputs $inClks
	# we want to determine the minimum period (worst case clock) for outClk.
	# if clkSel contains only '0' and '1' the mux sel is constant and we have a one for one mapping
	# if clkSel contains a signal, we need to select the fastest input clock
	# if clKSel contains signals and constants we still pick only the worst case clock (not a true mux) 
	
	if {[regexp [subst -nocommands -nobackslashes {^(\s*[0,1]\s*){$numSel}$}] $clkSel]} {
	# first test for constant sel line
		dputs "DEBUG: $inClks"
		dputs "DEBUG: $clkSel [bin2dec $clkSel]"
		set CLOCKs($outClk) $CLOCKs([lindex $inClks [bin2dec $clkSel]])
		set selClk [lindex $inClks [bin2dec $clkSel]] 
	} else {
	# sel line is non constant
	# need to return clock with minimum period
		
		set min $CLOCKs([lindex $inClks 0])
		dputs "Min period is: $min"
		set selClk [lindex $inClks 0]
		dputs "Min period clock is: $selClk"
		foreach clock $inClks {
			dputs "Clock: $clock; Period: $CLOCKs($clock)"
			# need to filter out ILLEGAL values
			if {[string is double -strict $CLOCKs($clock)]} {
				if {$CLOCKs($clock) < $min} {
					set min $CLOCKs($clock)
					set selClk $clock
				}
			}
		}
		set CLOCKs($outClk) $min
	}
	return $selClk
}

proc calc_out_clk_period {outClk inClk paramArray clkArray} {
	dputs "\[proc\] calc_out_clk_period $outClk $inClk"
	upvar 1 $clkArray CLOCKs
	upvar 1 $paramArray PARAMs

	# need to pass on ILLEGAL values to outClk if inClk is ILLEGAL
	if {$CLOCKs($inClk) eq "UNDEFINED"} {
		set CLOCKs($outClk) "UNDEFINED"
		puts "$outClk = UNDEFINED"
		return 1
	} elseif {[string is double -strict $CLOCKs($inClk)]} {
		switch $outClk {
			CPLLCLKOUT { 
				#GTHE3_CHANNEL, GTYE3_CHANNEL, GTHE2_CHANNEL, GTXE2_CHANNEL
				set CLOCKs($outClk) [expr {$CLOCKs($inClk) * $PARAMs(CPLL_REFCLK_DIV) / $PARAMs(CPLL_FBDIV) / $PARAMs(CPLL_FBDIV_45) * 1.000}]
				puts "CPLLCLKOUT = $inClk * $PARAMs(CPLL_REFCLK_DIV) / $PARAMs(CPLL_FBDIV) / $PARAMs(CPLL_FBDIV_45) = $CLOCKs($outClk)"
			}
			RXPLLREFCLK_DIV2 { 
				#GTHE3_CHANNEL, GTYE3_CHANNEL, GTHE2_CHANNEL, GTXE2_CHANNEL
				set CLOCKs($outClk) [expr $CLOCKs($inClk) * 2.000]
				puts "RXPLLREFCLK_DIV2 = $inClk * 2 = $CLOCKs($outClk)"
			}
			TXPLLREFCLK_DIV2 { 
				#GTHE3_CHANNEL, GTYE3_CHANNEL, GTHE2_CHANNEL, GTXE2_CHANNEL
				set CLOCKs($outClk) [expr $CLOCKs($inClk) * 2.000]
				puts "TXPLLREFCLK_DIV2 = $inClk * 2 = $CLOCKs($outClk)"
			}
			RXOUTCLKPMA { 
				#GTHE3_CHANNEL, GTYE3_CHANNEL, GTHE2_CHANNEL, GTXE2_CHANNEL
				set CLOCKs($outClk) [expr $CLOCKs($inClk) * $PARAMs(RX_DIV_D) * $PARAMs(RX_DIV_45) * $PARAMs(RX_DIV_24) * 1.000]
				puts "RXOUTCLKPMA = $inClk * $PARAMs(RX_DIV_D) * $PARAMs(RX_DIV_45) * $PARAMs(RX_DIV_24) = $CLOCKs($outClk)"
			}
			TXOUTCLKPMA { 
				#GTHE3_CHANNEL, GTYE3_CHANNEL, GTHE2_CHANNEL, GTXE2_CHANNEL
				set CLOCKs($outClk) [expr $CLOCKs($inClk) * $PARAMs(TX_DIV_D) * $PARAMs(TX_DIV_45) * $PARAMs(TX_DIV_24) * 1.000]
				puts "TXOUTCLKPMA = $inClk * $PARAMs(TX_DIV_D) * $PARAMs(TX_DIV_45) * $PARAMs(TX_DIV_24) = $CLOCKs($outClk)"
			}
			RXPROGDIVCLK { 
				#GTHE3_CHANNEL, GTYE3_CHANNEL 
				set CLOCKs($outClk) [expr $CLOCKs($inClk) * $PARAMs(RX_PROGDIV_CFG) * 1.000]
				puts "RXPROGDIVCLK = $inClk * $PARAMs(RX_PROGDIV_CFG) = $CLOCKs($outClk)"
			}
			TXPROGDIVCLK { 
				#GTHE3_CHANNEL, GTYE3_CHANNEL 
				set CLOCKs($outClk) [expr $CLOCKs($inClk) * $PARAMs(TX_PROGDIV_CFG) * 1.000]
				puts "TXPROGDIVCLK = $inClk * $PARAMs(TX_PROGDIV_CFG) = $CLOCKs($outClk)"
			}
			QPLL0CLK { 
				#GTHE3_COMMON, GTYE3_COMMON 
				#GTYE3_COMMON has additional parameter QPLL0LCKOUT_RATE which determines whether /2 is used for outclk
				if {$PARAMs(QPLL0CLKOUT_RATE) eq "FULL"} {
					set CLOCKs($outClk) [expr $CLOCKs($inClk) * $PARAMs(QPLL0_REFCLK_DIV) / $PARAMs(QPLL0_FBDIV)]
					puts "QPLL0CLK = $inClk * $PARAMs(QPLL0_REFCLK_DIV) / $PARAMs(QPLL0_FBDIV) = $CLOCKs($outClk)"
				} else {
					set CLOCKs($outClk) [expr $CLOCKs($inClk) * $PARAMs(QPLL0_REFCLK_DIV) / $PARAMs(QPLL0_FBDIV) * 2.0000]
					puts "QPLL0CLK = $inClk * $PARAMs(QPLL0_REFCLK_DIV) / $PARAMs(QPLL0_FBDIV) * 2 = $CLOCKs($outClk)"
				}
			}
			QPLL1CLK { 
				#GTHE3_COMMON, GTYE3_COMMON 
				#GTYE3_COMMON has additional parameter QPLL1LCKOUT_RATE which determines whether /2 is used for outclk
				if {$PARAMs(QPLL1CLKOUT_RATE) eq "FULL"} {
					set CLOCKs($outClk) [expr $CLOCKs($inClk) * $PARAMs(QPLL1_REFCLK_DIV) / $PARAMs(QPLL1_FBDIV)]
					puts "QPLL1CLK = $inClk * $PARAMs(QPLL1_REFCLK_DIV) / $PARAMs(QPLL1_FBDIV) = $CLOCKs($outClk)"
				} else {
					set CLOCKs($outClk) [expr $CLOCKs($inClk) * $PARAMs(QPLL1_REFCLK_DIV) / $PARAMs(QPLL1_FBDIV) * 2.0000]
					puts "QPLL1CLK = $inClk * $PARAMs(QPLL1_REFCLK_DIV) / $PARAMs(QPLL1_FBDIV) * 2 = $CLOCKs($outClk)"
				}
			}
			QPLLCLK {
				#GTHE2_COMMON, GTXE2_COMMON
				if {$PARAMs(QPLL_FBDIV_RATIO) == "1'b1"} {
					switch $PARAMs(QPLL_FBDIV) {
						"10'b0000100000" { set N 16}
						"10'b0000110000" { set N 20}
						"10'b0001100000" { set N 32}
						"10'b0010000000" { set N 40}
						"10'b0011100000" { set N 64}
						"10'b0100100000" { set N 80}
						"10'b0101110000" { set N 100}
						default {
							puts "ERROR: Illegal QPLL_FBDIV value '$PARAMs(QPLL_FBDIV)'"
						}
					}
					dputs "QPLL_FBDIV_RATIO=1, N=$N"
				} elseif {$PARAMs(QPLL_FBDIV_RATIO) == "1'b0"} {
					if {$PARAMs(QPLL_FBDIV) == "10'b0101000000"} {
						set N 66
					} else {
						puts "ERROR: Illegal QPLL_FBDIV value '$PARAMs(QPLL_FBDIV)'"
					}
					dputs "QPLL_FBDIV_RATIO=0, N=$N"
				}
				set CLOCKs($outClk) [expr $CLOCKs($inClk) * $PARAMs(QPLL_REFCLK_DIV) / $N * 2.0000]
				puts "QPLLCLK = $inClk * $PARAMs(QPLL_REFCLK_DIV) / $N * 2 = $CLOCKs($outClk)"
			}
			default {
				puts "ERROR: Unknown 'OUTCLOCK'"
			}
		}
		return 1
	} else {
		put "ERROR: Unknown clock period"
		return 0
	}
}

proc analyze_match {clkArray RX_TX} {
	dputs "\[proc\] analyze_match $RX_TX "
	upvar 1 $clkArray CLOCKs
	 
	if {$CLOCKs(${RX_TX}OUTCLK) ne "UNDEFINED"} {
		set ${RX_TX}outclk [format "%.2f" [expr {floor($CLOCKs(${RX_TX}OUTCLK)*100)/100}]]
	} else {
		set ${RX_TX}outclk $CLOCKs(${RX_TX}OUTCLK)
	}
	if {$CLOCKs(${RX_TX}OUTCLK_from_core) ne "UNDEFINED"} {
		set ${RX_TX}outclk_core [format "%.2f" [expr {floor($CLOCKs(${RX_TX}OUTCLK_from_core)*100)/100}]]
	} else {
		set ${RX_TX}outclk_core $CLOCKs(${RX_TX}OUTCLK_from_core)
	}

	if {[set ${RX_TX}outclk_core] eq "UNDEFINED"} { 
		set statusFile match.${RX_TX}
		puts "*******************"
		puts "${RX_TX}OUTCLKs UNDEFINED"
		puts "*******************"
	} elseif {[set ${RX_TX}outclk] eq [set ${RX_TX}outclk_core]} { 
		set statusFile match.${RX_TX}
		puts "***************"
		puts "${RX_TX}OUTCLKs MATCH"
		puts "***************"
	} else {
		set statusFile nomatch.${RX_TX}
		puts "*********************"
		puts "${RX_TX}OUTCLKs DON'T MATCH"
		puts "*********************"
	}
	#write results to an output file for quick analysis 
	set outFile [open $statusFile "a"]
	if {$CLOCKs(${RX_TX}OUTCLK) ne "UNDEFINED"} {
		puts $outFile "${RX_TX}OUTCLK: [format "%.2f" [expr {floor($CLOCKs(${RX_TX}OUTCLK)*100)/100}]]"
	} else {
		puts $outFile "${RX_TX}OUTCLK: $CLOCKs(${RX_TX}OUTCLK)"
	}
	if {$CLOCKs(${RX_TX}OUTCLK_from_core) ne "UNDEFINED"} {
		puts $outFile "${RX_TX}OUTCLK from core: [format "%.2f" [expr {floor($CLOCKs(${RX_TX}OUTCLK_from_core)*100)/100}]]"
	} else {
		puts $outFile "${RX_TX}OUTCLK from core: UNDEFINED"
	}
	close $outFile
}

#Get GT_COMMON
proc get_GT_COMMON_outclk_freq {COMMON outClks} {
	global V8_GT_COMMON 
	global V7_GT_COMMON 
	global V8_GT_CHANNEL
	global V7_GT_CHANNEL
	global all_GT_COMMON
	global all_GT_CHANNEL
	dputs "\[proc\] get_GT_COMMON_outclk_freq $COMMON $outClks"

	set VERBOSE 1

    set supportedCOMMONTypes $all_GT_COMMON

    set COMMONType [get_property LIB_CELL $COMMON]
    if {[lsearch $supportedCOMMONTypes $COMMONType] == -1} {
        puts "ERROR: GT_COMMON type '$COMMONType' is not supported"
        return 0
    }
    
    #figure out number of REFCLK inputs for QPLL0 and QPLL1

    if {!([lsearch $V8_GT_COMMON $COMMONType]==-1)} {
        set QPLLs {QPLL0 QPLL1}
    }
    if {!([lsearch $V7_GT_COMMON $COMMONType]==-1)} {
        set QPLLs {QPLL}
    }

	array set COMMONclocks {}
    array set REFCLKs {}
      
   
    #get relevant parameters to determine outclk frequencies
    if {!([lsearch $V8_GT_COMMON $COMMONType]==-1)} {
        set COMMON_params {QPLL0_FBDIV QPLL0_FBDIV_G3 QPLL0_REFCLK_DIV QPLL1_FBDIV QPLL1_FBDIV_G3 QPLL1_REFCLK_DIV QPLL0CLKOUT_RATE QPLL1CLKOUT_RATE }
    }
    if {!([lsearch $V7_GT_COMMON $COMMONType]==-1)} {
        set COMMON_params {QPLL_FBDIV QPLL_REFCLK_DIV QPLL_FBDIV_RATIO}
    }
    array set PARAMs {}

    foreach param $COMMON_params {
        set PARAMs($param) [get_property $param $COMMON]
    }
    
	if {$VERBOSE} {puts "\n[get_property LIB_CELL $COMMON] attributes";parray PARAMs}

    foreach QPLL $QPLLs {
		set REFCLKs($QPLL) [get_refclks $COMMON $QPLL COMMONclocks]

		puts "\nCOMMON_$QPLL: $COMMON"
		if {[get_num_refclks $COMMON $QPLL] == 1} {
			puts "Exactly one REFCLK Signal input"
			if {$COMMONclocks($REFCLKs($QPLL)) ne "UNDEFINED"} {
				set COMMONclocks(${QPLL}INCLK) [lindex [get_property PERIOD $COMMONclocks($REFCLKs($QPLL))] 0]
				set COMMONclocks(${QPLL}REFCLK) $COMMONclocks(${QPLL}INCLK)
			} else {
				set COMMONclocks(${QPLL}INCLK) "UNDEFINED"
				set COMMONclocks(${QPLL}REFCLK) "UNDEFINED"
			}
			puts "${QPLL}REFCLK Period: $COMMONclocks(${QPLL}REFCLK)" 
			calc_out_clk_period ${QPLL}CLK ${QPLL}INCLK PARAMs COMMONclocks
			#set COMMONclocks(${QPLL}CLK) [expr {$COMMONclocks(${QPLL}INCLK)  * $PARAMs(${QPLL}_REFCLK_DIV) / $PARAMs(${QPLL}_FBDIV)} * 2]
			dputs "${QPLL}CLK Period: $COMMONclocks(${QPLL}CLK)" 
			dputs "${QPLL}_FBDIV: $PARAMs(${QPLL}_FBDIV)"
			#dputs "${QPLL}_FBDIV_G3: $PARAMs(${QPLL}_FBDIV_G3)"
			dputs "${QPLL}_REFCLK_DIV: $PARAMs(${QPLL}_REFCLK_DIV)"
			dputs ""
		} elseif {[get_num_refclks $COMMON $QPLL] > 1} {
			puts "More than one REFCLK Signal input"

			set REFCLKSEL [get_pin_driver [lsort -decreasing [get_pins -of $COMMON -filter NAME=~*${QPLL}REFCLKSEL[*]]]]
			#check for constant REFCLKSEL
			if {[regexp {^(\s*[0|1]\s*){3}$} $REFCLKSEL]} {
				puts "${QPLL}REFCLKSEL: $REFCLKSEL\n"
				dputs "${QPLL}REFCLKSEL is constant"
				#if $REFCLKSEL is a constant we have to select the REFCLK input period based on $REFCLKSEL
				switch $REFCLKSEL {
					"0 0 0" { puts "ERROR: Reserved ${QPLL}REFCLKSEL value 3'b000."}
					"0 0 1" { set refClk "GTREFCLK0"}
					"0 1 0" { set refClk "GTREFCLK1"}
					"0 1 1" { set refClk "GTNORTHREFCLK0"}
					"1 0 0" { set refClk "GTNORTHREFCLK1"}
					"1 0 1" { set refClk "GTSOUTHREFCLK0"}
					"1 1 0" { set refClk "GTSOUTHREFCLK1"}
					"1 1 1" { set refClk "GTGREFCLK"}
					default {
						puts "ERROR: ${QPLL}REFCLKSEL value '$REFCLKSEL'"
					}
				}
				if {${QPLL} eq "QPLL0"} { append refClk "0"}
				if {${QPLL} eq "QPLL1"} { append refClk "1"}
				puts "$refClk selected"
				if {$COMMONclocks($refClk) == "UNDEFINED"} {
					set COMMONclocks(${QPLL}INCLK) "UNDEFINED"
				} else {
					set COMMONclocks(${QPLL}INCLK) [get_property PERIOD $COMMONclocks($refClk)]
				}
			} else {
				puts "${QPLL}REFCLKSEL:\n[join $REFCLKSEL \n]\n"
				dputs "${QPLL}REFCLKSEL is not constant"
				#figure out the minimum period for all REFCLK inputs and use it to calculate outclock frequencies
				dputs "MinPeriod Clock: [lindex $REFCLKs($QPLL) 0]"
				set minRefClk [lindex $REFCLKs($QPLL) 0]
				dputs "MinPeriod Clock constraint name: $REFCLKs($QPLL)"
				if {$COMMONclocks($minRefClk) ne "UNDEFINED"} {
					set minPeriod [get_property PERIOD $COMMONclocks($minRefClk)]
				} else {
					set minPeriod "UNDEFINED"
				}
				dputs "MinPeriod: $minPeriod"
				set COMMONclocks(${QPLL}INCLK) $minPeriod
				foreach refClk $REFCLKs($QPLL) {
					if {$COMMONclocks($refClk) == "UNDEFINED"} {
						set COMMONclocks(${QPLL}INCLK) "UNDEFINED"
						puts "$refClk Period 'UNDEFINED'"
						break
					} else {
						puts "$refClk Period: [get_property PERIOD $COMMONclocks($refClk)]" 
					}
					if {[get_property PERIOD $COMMONclocks($refClk)] < $minPeriod} {
						set minPeriod [get_property PERIOD $COMMONclocks($refClk)]
						set minRefClk $refClk
						set COMMONclocks(${QPLL}INCLK) $minPeriod
					}
				}
			}

			dputs "${QPLL}INCLK Period: $COMMONclocks(${QPLL}INCLK)" 
			calc_out_clk_period ${QPLL}CLK ${QPLL}INCLK PARAMs COMMONclocks
			dputs "${QPLL}CLK Period: $COMMONclocks(${QPLL}CLK)" 
			set COMMONclocks(${QPLL}REFCLK) $COMMONclocks(${QPLL}INCLK)
			puts "${QPLL}REFCLK Period: $COMMONclocks(${QPLL}REFCLK)" 
			
		} else {
			puts "No REFCLK Signal input"

			set COMMONclocks(${QPLL}INCLK) "UNDEFINED"
			set COMMONclocks(${QPLL}REFCLK) $COMMONclocks(${QPLL}INCLK)
			puts "${QPLL}REFCLK Period: $COMMONclocks(${QPLL}REFCLK)" 
			set COMMONclocks(${QPLL}CLK) "UNDEFINED"
			puts "${QPLL}CLK Period: $COMMONclocks(${QPLL}CLK)" 
		}
	}
	set returnClocks {}
	foreach clk $outClks {
		lappend returnClocks $COMMONclocks($clk)
	}
	return $returnClocks	
}


proc get_GT_CHANNEL_outclk_freq {CHANNEL} {
	global V8_GT_COMMON 
	global V7_GT_COMMON 
	global V8_GT_CHANNEL
	global V7_GT_CHANNEL
	global all_GT_COMMON
	global all_GT_CHANNEL
	dputs "\[proc\] get_GT_CHANNEL_outclk_freq $CHANNEL"
    
	set VERBOSE 1
	
	set supportedCHANNELTypes $all_GT_CHANNEL

    set CHANNELType [get_property LIB_CELL $CHANNEL]
    if {[lsearch $supportedCHANNELTypes $CHANNELType] == -1} {
        puts "ERROR: GT_CHANNEL type '$CHANNELType' is not supported"
        return 0
    }
    
	array set CHANNELclocks {}
	set CHANNELclocks(UNDEFINED) UNDEFINED
	foreach clock {RXOUTCLK TXOUTCLK} {
		if {[get_clocks -of [get_pins -of $CHANNEL -filter NAME=~*/${clock}] -quiet]!=""} {
			set CHANNELclocks(${clock}_from_core) [get_property period [get_clocks -of [get_pins -of $CHANNEL -filter NAME=~*/${clock}]]]
		} else {
			set CHANNELclocks(${clock}_from_core) "UNDEFINED"
		}
	}
    #figure out number of REFCLK inputs for CPLL and relevant clock select pins for the various muxes in GT_CHANNEL
    if {!([lsearch $V8_GT_CHANNEL $CHANNELType]==-1)} {
        set ClocksFromCOMMON {QPLL0CLK QPLL0REFCLK QPLL1CLK QPLL1REFCLK}
        set ClockSelPins {TXPLLCLKSEL TXSYSCLKSEL TXRATE TXOUTCLKSEL RXPLLCLKSEL RXSYSCLKSEL RXRATE RXOUTCLKSEL};
    }
    if {!([lsearch $V7_GT_CHANNEL $CHANNELType]==-1)} {
        set ClocksFromCOMMON {QPLLCLK QPLLREFCLK}
        set ClockSelPins {TXSYSCLKSEL TXRATE TXOUTCLKSEL RXSYSCLKSEL RXRATE RXOUTCLKSEL}
    }
	
    #get relevant parameters to determine outclk frequencies
    if {!([lsearch $V8_GT_CHANNEL $CHANNELType]==-1)} {
        set CHANNEL_params {CPLL_FBDIV CPLL_FBDIV_45 CPLL_REFCLK_DIV RXOUT_DIV RX_CLK25_DIV RX_PROGDIV_CFG RX_DATA_WIDTH RX_INT_DATAWIDTH TXOUT_DIV TX_CLK25_DIV TX_PROGDIV_CFG TX_DATA_WIDTH TX_INT_DATAWIDTH TX_PROGCLK_SEL}
    }
    if {!([lsearch $V7_GT_CHANNEL $CHANNELType]==-1)} {
        set CHANNEL_params {CPLL_FBDIV CPLL_FBDIV_45 CPLL_REFCLK_DIV RXOUT_DIV RX_CLK25_DIV RX_DATA_WIDTH RX_INT_DATAWIDTH TXOUT_DIV TX_CLK25_DIV TX_DATA_WIDTH TX_INT_DATAWIDTH }
    }
    array set PARAMs {}

    foreach param $CHANNEL_params {
        set PARAMs($param) [get_property $param $CHANNEL]
    }
	
	puts ""
	if {$VERBOSE} {puts "\n[get_property LIB_CELL $CHANNEL] attributes";parray PARAMs}
	
	set CPLLREFCLKs [get_refclks $CHANNEL CPLL CHANNELclocks]

    
	puts "\nCHANNEL_CPLL: $CHANNEL"
	if {[get_num_refclks $CHANNEL "CPLL"] == 1} {
		# we have exactly one input
		puts "Exactly one CPLL REFCLK Signal input"
		dputs "CPLLREFCLKs $CPLLREFCLKs"
		dputs "$CHANNELclocks($CPLLREFCLKs)"
		if {$CHANNELclocks($CPLLREFCLKs) eq "UNDEFINED"} {
			set CHANNELclocks(CPLLCLKIN) "UNDEFINED"
		} else {
			#need to handle case where two clocks (refclk_n, refclk_p) are defined
			if {[llength [get_property PERIOD $CHANNELclocks($CPLLREFCLKs)]] == 1} {
				set CHANNELclocks(CPLLCLKIN) [get_property PERIOD $CHANNELclocks($CPLLREFCLKs)]
 			} else {
				set CHANNELclocks(CPLLCLKIN) [lindex [get_property PERIOD $CHANNELclocks($CPLLREFCLKs)] 0]
			}
		}
		puts "CPLLCLKIN Period: $CHANNELclocks(CPLLCLKIN)" 
		calc_out_clk_period CPLLCLKOUT CPLLCLKIN PARAMs CHANNELclocks
		#set CHANNELclocks(CPLLCLKOUT) [expr {$CHANNELclocks(CPLLCLKIN) * $PARAMs(CPLL_REFCLK_DIV) / $PARAMs(CPLL_FBDIV) / $PARAMs(CPLL_FBDIV_45)}]
		dputs "CPLLCLKOUT Period: $CHANNELclocks(CPLLCLKOUT)" 
		dputs ""
	} elseif {[get_num_refclks $CHANNEL "CPLL"] > 1} {
		puts "More than one CPLL REFCLK Signal input"
		dputs "CPLLREFCLKs:\n$CPLLREFCLKs"
		dputs "CHANNELclocks([lindex $CPLLREFCLKs 0]): $CHANNELclocks([lindex $CPLLREFCLKs 0])" 

		set REFCLKSEL [get_pin_driver [lsort -decreasing [get_pins -of $CHANNEL -filter NAME=~*CPLLREFCLKSEL[*]]]]
		#check for constant REFCLKSEL
		if {[regexp {^(\s*[0|1]\s*){3}$} $REFCLKSEL]} {
			puts "CPLLREFCLKSEL: $REFCLKSEL\n"
			dputs "CPLLREFCLKSEL is constant"
			#if $REFCLKSEL is a constant we have to select the REFCLK input period based on $REFCLKSEL
			switch $REFCLKSEL {
				"0 0 0" { puts "ERROR: Reserved CPLLREFCLKSEL value 3'b000."}
				"0 0 1" { set refClk "GTREFCLK0"}
				"0 1 0" { set refClk "GTREFCLK1"}
				"0 1 1" { set refClk "GTNORTHREFCLK0"}
				"1 0 0" { set refClk "GTNORTHREFCLK1"}
				"1 0 1" { set refClk "GTSOUTHREFCLK0"}
				"1 1 0" { set refClk "GTSOUTHREFCLK1"}
				"1 1 1" { set refClk "GTGREFCLK"}
				default {
					puts "ERROR: CPLLREFCLKSEL value '$REFCLKSEL'"
				}
			}
			puts "$refClk selected"
			dputs "$CHANNELclocks($refClk)"
			if {$CHANNELclocks($refClk) == "UNDEFINED"} {
				set CHANNELclocks(CPLLCLKIN) "UNDEFINED"
			} else {
				set CHANNELclocks(CPLLCLKIN) [get_property PERIOD $CHANNELclocks($refClk)]
			}
		} else {
			puts "CPLLREFCLKSEL:\n[join $REFCLKSEL \n]\n"
			dputs "CPLLREFCLKSEL is not constant"
			#figure out the minimum period for all REFCLK inputs and use it to calculate outclock frequencies
			dputs "MinPeriod Clock: [lindex $CPLLREFCLKs 0]"
			set minRefClk [lindex $CPLLREFCLKs 0]
			dputs "MinPeriod Clock constraint name: $CHANNELclocks($minRefClk)"
			if {$CHANNELclocks($minRefClk) ne "UNDEFINED"} {
				set minPeriod [get_property PERIOD $CHANNELclocks($minRefClk)]
			} else {
				set minPeriod "UNDEFINED"
			}
			dputs "MinPeriod: $minPeriod"
			set CHANNELclocks(CPLLCLKIN) $minPeriod
			foreach refClk $CPLLREFCLKs {
				if {$CHANNELclocks($refClk) == "UNDEFINED"} {
					set CHANNELclocks(CPLLCLKIN) "UNDEFINED"
					puts "$refClk Period: 'UNDEFINED'"
					break
				} else {
					puts "$refClk Period: [get_property PERIOD $CHANNELclocks($refClk)]" 
				}
				if {[get_property PERIOD $CHANNELclocks($refClk)] < $minPeriod} {
					set minPeriod [get_property PERIOD $CHANNELclocks($refClk)]
					set minRefClk $refClk
					set CHANNELclocks(CPLLCLKIN) $minPeriod
				}
			}
		}
		puts "CPLLCLKIN Period: $CHANNELclocks(CPLLCLKIN)" 
		calc_out_clk_period CPLLCLKOUT CPLLCLKIN PARAMs CHANNELclocks
		dputs "CPLLCLKOUT Period: $CHANNELclocks(CPLLCLKOUT)" 
	} else {
		puts "No CPLL REFCLK Signal input"

		set CHANNELclocks(CPLLCLKIN) "UNDEFINED"
		calc_out_clk_period CPLLCLKOUT CPLLCLKIN PARAMs CHANNELclocks
		puts "CPLLCLKOUT Period: $CHANNELclocks(CPLLCLKOUT)" 
	}
    

  # find out which common is connected to the QPLL0/1INCLK and QPLL0/1INREFCLK pins and get the Period constraint
	set QPLLINCLK {}
	set QPLLINCLKSource {}
	foreach ClockPin $ClocksFromCOMMON {
		set clkPinDriver [get_pin_driver [get_pins -of $CHANNEL -filter NAME=~*${ClockPin}]]
		dputs "clkPinDriver '[get_pins $clkPinDriver]'"
		set clkSource [get_cells -of [get_pins $clkPinDriver] -quiet]
		dputs "$ClockPin Cell '$clkSource'"
    
		if {$clkSource eq ""} {
			set CHANNELclocks($ClockPin) "UNDEFINED"
		} else {
			set QPLLINCLKSource $clkSource
			lappend QPLLINCLK $ClockPin
			#set CHANNELclocks($ClockPin) [get_GT_COMMON_outclk_freq $clkSource $ClockPin ]
		}
	}
	dputs "QPLLINCLK $QPLLINCLK"
	if {[llength $QPLLINCLK] > 0} {
		set QPLLCLKPeriod [get_GT_COMMON_outclk_freq $QPLLINCLKSource $QPLLINCLK ]
		foreach ClockPin $QPLLINCLK period $QPLLCLKPeriod {
			dputs $ClockPin
			set CHANNELclocks($ClockPin) $period
		}
	} 
	
	# TX/RX Fabric Clock Output Control
	# calculate the various clock frequencies based on ClockSelPins settings
	foreach pin $ClockSelPins {
		# check to see if [R|T]XOUTCLK is connected before performing the clock calculations
		if {[regexp {([R|T]X).*} $pin all RX_TX] && [get_property IS_CONNECTED [get_pins -of $CHANNEL -filter NAME=~*${RX_TX}OUTCLK]] == 1} {
			#[R|T]XPLLCLKSEL
			# GTHE3_CHANNEL, GTYE3_CHANNEL
			if {!([lsearch $V8_GT_CHANNEL $CHANNELType]==-1)} {
				if {[regexp {([R|T]X)PLLCLKSEL} $pin all RX_TX]} {
					puts "\n********************"
					puts "${RX_TX}OUTCLK calculation"
					puts "\nMUX select $pin: [get_pin_driver [lsort -decreasing [get_pins -of $CHANNEL -filter NAME=~*$pin[*]]]]\n"
					set muxInClks {CPLLCLKOUT UNDEFINED QPLL1CLK QPLL0CLK}
					#get select signals
					set muxSel [get_pin_driver [lsort -decreasing [get_pins -of $CHANNEL -filter NAME=~*$pin[*]]]]  
					set selClk [get_out_clk_period $muxInClks $muxSel ${RX_TX}PREPICLK CHANNELclocks]
					puts "${RX_TX}PREPICLK selected: $selClk = $CHANNELclocks(${RX_TX}PREPICLK)"
					set CHANNELclocks(${RX_TX}POSTPICLK) $CHANNELclocks(${RX_TX}PREPICLK)
					puts "${RX_TX}POSTPICLK: $CHANNELclocks(${RX_TX}POSTPICLK)"
					#for TX need to look at TX_PROGCLK_SEL parameter
					if {$RX_TX eq "TX"} {
						if {[lindex $PARAMs(TX_PROGCLK_SEL)] eq "PREPI"} {
							set TX_PROGCLK_SEL_clock TXPREPICLK
						}
						if {[lindex $PARAMs(TX_PROGCLK_SEL)] eq "POSTPI"} {
							set TX_PROGCLK_SEL_clock TXPOSTPICLK
						}
						if {[lindex $PARAMs(TX_PROGCLK_SEL)] eq "CPLL"} {
							set TX_PROGCLK_SEL_clock CPLLCLKOUT
						}
						set CHANNELclocks(TXPROGDIVINCLK) $CHANNELclocks($TX_PROGCLK_SEL_clock)
						puts "\nMUX select TX_PROGCLK_SEL: [lindex $PARAMs(TX_PROGCLK_SEL)]"
						puts "TXPROGDIVINCLK selected: $TX_PROGCLK_SEL_clock = $CHANNELclocks(TXPROGDIVINCLK)"
					}

				}
			}
			#[R|T]XSYSCLKSEL mux
			# GTHE3_CHANNEL, GTYE3_CHANNEL
			if {!([lsearch $V8_GT_CHANNEL $CHANNELType]==-1)} {
				if {[regexp {([R|T]X)SYSCLKSEL} $pin all RX_TX]} {
					puts "\nMUX select $pin: [get_pin_driver [lsort -decreasing [get_pins -of $CHANNEL -filter NAME=~*$pin[*]]]]\n"
					set muxInClks {CPLLCLKIN UNDEFINED QPLL0REFCLK QPLL1REFCLK}; # {in0 in1 in2 in3}
					set muxSel [get_pin_driver [lsort -decreasing [get_pins -of $CHANNEL -filter NAME=~*$pin[*]]]] 
					set selClk [get_out_clk_period $muxInClks $muxSel ${RX_TX}PLLREFCLK_DIV1 CHANNELclocks]
					puts "${RX_TX}PLLREFCLK_DIV1 selected: $selClk = $CHANNELclocks(${RX_TX}PLLREFCLK_DIV1)"
					calc_out_clk_period ${RX_TX}PLLREFCLK_DIV2 ${RX_TX}PLLREFCLK_DIV1 PARAMs CHANNELclocks
					set CHANNELclocks(${RX_TX}OUTCLKFABRIC) $CHANNELclocks(${RX_TX}PLLREFCLK_DIV1)
					puts "${RX_TX}OUTCLKFABRIC: $CHANNELclocks(${RX_TX}OUTCLKFABRIC)"
				}
			} elseif {!([lsearch $V7_GT_CHANNEL $CHANNELType]==-1)} {
			# GTHE2_CHANNEL, GTXE2_CHANNEL
				if {[regexp {([R|T]X)SYSCLKSEL} $pin all RX_TX]} {
					puts "\n********************"
					puts "${RX_TX}OUTCLK calculation"
					puts "\nMUX select $pin: [get_pin_driver [lsort -decreasing [get_pins -of $CHANNEL -filter NAME=~*$pin[*]]]]\n"
					
					#[R|T]XSYSCLKSEL[1]
					set muxInClks {CPLLCLKIN QPLLREFCLK}; # {in0 in1}
					set muxSel [get_pin_driver [lsort -decreasing [get_pins -of $CHANNEL -filter NAME=~*$pin[1]]]] 
					set selClk [get_out_clk_period $muxInClks $muxSel ${RX_TX}PLLREFCLK_DIV1 CHANNELclocks]
					puts "${RX_TX}PLLREFCLK_DIV1 selected: $selClk = $CHANNELclocks(${RX_TX}PLLREFCLK_DIV1)"
					calc_out_clk_period ${RX_TX}PLLREFCLK_DIV2 ${RX_TX}PLLREFCLK_DIV1 PARAMs CHANNELclocks
					set CHANNELclocks(${RX_TX}OUTCLKFABRIC) $CHANNELclocks(${RX_TX}PLLREFCLK_DIV1)
					puts "${RX_TX}OUTCLKFABRIC: $CHANNELclocks(${RX_TX}OUTCLKFABRIC)"
					
					#[R|T]XSYSCLKSEL[0]
					set muxInClks {CPLLCLKOUT QPLLCLK}; # {in0 in1}
					set muxSel [get_pin_driver [lsort -decreasing [get_pins -of $CHANNEL -filter NAME=~*$pin[0]]]] 
					set selClk [get_out_clk_period $muxInClks $muxSel ${RX_TX}PREPICLK CHANNELclocks]
					puts "${RX_TX}PREPICLK selected: $selClk = $CHANNELclocks(${RX_TX}PREPICLK)"
				}
			}
			#[R|T]XRATE
			# GTHE3_CHANNEL, GTYE3_CHANNEL, GTHE2_CHANNEL, GTXE2_CHANNEL
			if {!([lsearch $all_GT_CHANNEL $CHANNELType]==-1)} {
				if {[regexp {([R|T]X)RATE} $pin all RX_TX]} {
					puts "\nMUX select $pin: [get_pin_driver [lsort -decreasing [get_pins -of $CHANNEL -filter NAME=~*$pin[*]]]]\n"
					set RX_TX_RATE [get_pin_driver [lsort -decreasing [get_pins -of $CHANNEL -filter NAME=~*$pin[*]]]]
					#check for 3'b000
					if {[regexp {^(\s*0\s*){3}$} $RX_TX_RATE]} {
						switch $PARAMs(${RX_TX}OUT_DIV) {
							1 { set ${RX_TX}_DIV_D 1}
							2 { set ${RX_TX}_DIV_D 2}
							4 { set ${RX_TX}_DIV_D 4}
							8 { set ${RX_TX}_DIV_D 8}
							16 { set ${RX_TX}_DIV_D 16}
							default {
								puts "ERROR: Illegal ${RX_TX}OUT_DIV value '$PARAMs(${RX_TX}OUT_DIV)'"
							}
						}
					} elseif {[regexp {^(\s*[0|1]\s*){3}$} $RX_TX_RATE]} {
						#if [R|T]XRATE is a constant we have to select [R|T]_DIV_D divider based on $RX_TX_RATE
						puts "${RX_TX}RATE = $RX_TX_RATE. ${RX_TX}_DIV_D is based on ${RX_TX}RATE."
						switch $RX_TX_RATE {
							"0 0 1" { set ${RX_TX}_DIV_D 1}
							"0 1 0" { set ${RX_TX}_DIV_D 2}
							"0 1 1" { set ${RX_TX}_DIV_D 4}
							"1 0 0" { set ${RX_TX}_DIV_D 8}
							"1 0 1" { set ${RX_TX}_DIV_D 16}
							default {
								puts "ERROR: Illegal ${RX_TX}OUT_DIV value '$PARAMs(${RX_TX}OUT_DIV)'"
							}
						}
					} else {
						#if ([R|T]X)RATE is dynamically controlled we have to select the lowest divider
						set ${RX_TX}_DIV_D 1
						puts "${RX_TX}RATE != 3'b000. ${RX_TX}_DIV_D is dynamically determined by ${RX_TX}RATE. Selecting min(${RX_TX}_DIV_D) = 1."
					}
					set PARAMs(${RX_TX}_DIV_D) [set ${RX_TX}_DIV_D]
					dputs "${RX_TX}OUT_DIV: $PARAMs(${RX_TX}OUT_DIV)"
					dputs "${RX_TX}_DIV_D: $PARAMs(${RX_TX}_DIV_D)"

					switch $PARAMs(${RX_TX}_DATA_WIDTH) {
						16 { set ${RX_TX}_DIV_45 4}
						32 { set ${RX_TX}_DIV_45 4}
						64 { set ${RX_TX}_DIV_45 4}
						20 { set ${RX_TX}_DIV_45 5}
						40 { set ${RX_TX}_DIV_45 5}
						80 { set ${RX_TX}_DIV_45 5}
						default {
							puts "ERROR: Illegal ${RX_TX}_DATA_WIDTH value '$PARAMs(${RX_TX}_DATA_WIDTH)'"
						}
					}
					set PARAMs(${RX_TX}_DIV_45) [set ${RX_TX}_DIV_45]
					dputs "${RX_TX}_DATA_WIDTH: $PARAMs(${RX_TX}_DATA_WIDTH)"
					dputs "${RX_TX}_DIV_45: $PARAMs(${RX_TX}_DIV_45)"
					
					switch $PARAMs(${RX_TX}_INT_DATAWIDTH) {
						0 { set ${RX_TX}_DIV_24 2}
						1 { set ${RX_TX}_DIV_24 4}
						2 { set ${RX_TX}_DIV_24 8}
						default {
							puts "ERROR: Illegal ${RX_TX}_INT_DATAWIDTH value '$PARAMs(${RX_TX}_INT_DATAWIDTH)'"
						}
					}
					set PARAMs(${RX_TX}_DIV_24) [set ${RX_TX}_DIV_24]
					dputs "${RX_TX}_INT_DATAWIDTH: $PARAMs(${RX_TX}_INT_DATAWIDTH)"
					dputs "${RX_TX}_DIV_24: $PARAMs(${RX_TX}_DIV_24)"

					calc_out_clk_period ${RX_TX}OUTCLKPMA ${RX_TX}PREPICLK PARAMs CHANNELclocks
					set CHANNELclocks(${RX_TX}OUTCLKPCS) $CHANNELclocks(${RX_TX}OUTCLKPMA)
					puts "${RX_TX}OUTCLKPCS: $CHANNELclocks(${RX_TX}OUTCLKPCS)"
					# GTHE3_CHANNEL, GTYE3_CHANNEL
					if {!([lsearch $V8_GT_CHANNEL $CHANNELType]==-1)} {
						if {$RX_TX eq "TX"} {
							calc_out_clk_period ${RX_TX}PROGDIVCLK TXPROGDIVINCLK PARAMs CHANNELclocks
						}
						if {$RX_TX eq "RX"} {
							calc_out_clk_period ${RX_TX}PROGDIVCLK RXPOSTPICLK PARAMs CHANNELclocks
						}
					}
				}
			}
			#[R|T]XOUTCLKSEL mux
			# GTHE3_CHANNEL, GTYE3_CHANNEL
			if {!([lsearch $V8_GT_CHANNEL $CHANNELType]==-1)} {
				if {[regexp {([R|T]X)OUTCLKSEL} $pin all RX_TX]} {
					puts "\nMUX select $pin: [get_pin_driver [lsort -decreasing [get_pins -of $CHANNEL -filter NAME=~*$pin[*]]]]\n"
					set muxInClks "UNDEFINED ${RX_TX}OUTCLKPCS ${RX_TX}OUTCLKPMA ${RX_TX}PLLREFCLK_DIV1 ${RX_TX}PLLREFCLK_DIV2 ${RX_TX}PROGDIVCLK"
					set muxSel [get_pin_driver [lsort -decreasing [get_pins -of $CHANNEL -filter NAME=~*$pin[*]]]] 
					set selClk [get_out_clk_period $muxInClks $muxSel ${RX_TX}OUTCLK CHANNELclocks]
					puts "${RX_TX}OUTCLK selected: $selClk"
					puts "${RX_TX}OUTCLK: $CHANNELclocks(${RX_TX}OUTCLK)"
					puts "${RX_TX}OUTCLK from core: $CHANNELclocks(${RX_TX}OUTCLK_from_core)"

					analyze_match CHANNELclocks ${RX_TX} 
				}
			} elseif {!([lsearch $V7_GT_CHANNEL $CHANNELType]==-1)} {
			# GTHE2_CHANNEL, GTXE2_CHANNEL
				if {[regexp {([R|T]X)OUTCLKSEL} $pin all RX_TX]} {
					puts "\nMUX select $pin: [get_pin_driver [lsort -decreasing [get_pins -of $CHANNEL -filter NAME=~*$pin[*]]]]\n"
					set muxInClks "UNDEFINED ${RX_TX}OUTCLKPCS ${RX_TX}OUTCLKPMA ${RX_TX}PLLREFCLK_DIV1 ${RX_TX}PLLREFCLK_DIV2"
					set muxSel [get_pin_driver [lsort -decreasing [get_pins -of $CHANNEL -filter NAME=~*$pin[*]]]] 
					set selClk [get_out_clk_period $muxInClks $muxSel ${RX_TX}OUTCLK CHANNELclocks]
					puts "${RX_TX}OUTCLK selected: $selClk"
					puts "${RX_TX}OUTCLK: $CHANNELclocks(${RX_TX}OUTCLK)"
					puts "${RX_TX}OUTCLK from core: $CHANNELclocks(${RX_TX}OUTCLK_from_core)"

					analyze_match CHANNELclocks ${RX_TX} 
				}
			}
		}
	}
}
if {1} {
# delete 
file delete -force match.RX
file delete -force match.TX
file delete -force nomatch.RX
file delete -force nomatch.TX

#set GT_COMMONs [get_cells -hier -filter LIB_CELL=~GT*COMMON]
set GT_CHANNELs [get_cells -hier -filter LIB_CELL=~GT*CHANNEL]

foreach CHANNEL $GT_CHANNELs {get_GT_CHANNEL_outclk_freq $CHANNEL}

}

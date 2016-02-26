proc reload {} { uplevel 1 [list source /home/dpefour/wrk/support/Diablo/estimateddly/scripts/common.tcl ] }

set DEBUG 0

######################################################################
#
# Procs
#
######################################################################

proc report_net_correlation { paths {margin 0.1} {filename report_net_correlation.csv} {design {}} } {
  if {($paths == {})} {
    error " error - empty path"
  }

  set part [get_property PART [current_design]]
  if {$design == {}} {
    set tbl [tb::prettyTable "Net Correlation\nEstDly/P2PDly < [expr 1.0 - $margin]\nEstDly/P2PDly > [expr 1.0 + $margin]"]
  } else {
    set tbl [tb::prettyTable "Net Correlation ($design)\nEstDly/P2PDly < [expr 1.0 - $margin]\nEstDly/P2PDly > [expr 1.0 + $margin]" ]
  }
  $tbl header [list {Design} {Part} {Path #} {Driver Tile} {Receiver Tile} {Driver Site} {Receiver Site} {Driver Pin} {Receiver Pin} {Path Slack} {Path Level} {Driver Incr Delay} {Net Incr Delay} {Delay Type} {Estimated Delay} {P2P Delay} {Estimated vs. P2P} {Error vs. P2P (%)} {Absolute Error} {Fanout} {Tiles Distance (X+Y)} {SLR Crossing} {Driver INT} {Receiver INT} {Net} {Driver} {Receiver}  ]

  catch {unset arrStats}
  set arrStats(primitive:over) [list]
  set arrStats(primitive:under) [list]
  set arrStats(subgroup:over) [list]
  set arrStats(subgroup:under) [list]
  set nNets 0
  set nTotalNets 0
  set count -1
  foreach path $paths {
    incr count
    if {[get_property CLASS [get_property STARTPOINT_PIN $path]] == {port}} {
      puts " -W- skipping path $count due to input port: $path"
      continue
    }
    if {[get_property CLASS [get_property ENDPOINT_PIN $path]] == {port}} {
      puts " -W- skipping path $count due to output port: $path"
      continue
    }
    if {[regexp {MaxDelay.+datapath_only} [get_property EXCEPTION $path]]} {
      puts " -W- skipping path $count due to Max Delay DPO: $path"
      continue
    }

    set slack [get_property -quiet SLACK $path]
    # Get the number of nets on the path that are not INTRASITE
    set nonIntrasiteNets [filter [get_nets -quiet -of $path] {ROUTE_STATUS != INTRASITE}]
    set spPin [get_property -quiet STARTPOINT_PIN $path]
    set spPinType [pin2pintype $spPin]

    set epPin [get_property -quiet ENDPOINT_PIN $path]
    set epPinType [pin2pintype $epPin]

    if {[catch { set pathInfo [get_path_info $path 1] } errorstring]} {
      puts " -E- skipping path $count due to error below: $path"
      puts " -E- get_path_info: $errorstring"
      continue
    }
    dputs "<pathInfo:[join $pathInfo \n]>"
    # Skip the last element of $pathInfo since this is the endpoint information
    foreach elm [lrange $pathInfo 0 end-1] {
      foreach {pindata netdata inputpinname} $elm { break }
      foreach {pinname pinrisefall pinincrdelay pindelay} $pindata { break }
      foreach {netname netlength netfanout nettype netincrdelay netdelay} $netdata { break }
      dputs "<$netname:$pinname:$inputpinname>"

      set net [get_nets -quiet $netname]
      set pinobj [get_pins -quiet $pinname]
      set inputpinobj [get_pins -quiet $inputpinname]
      set pintype [pin2pintype $pinobj]
      set inputpintype [pin2pintype $inputpinobj]
      # Is the net an intra-site net?
      if {[get_property -quiet ROUTE_STATUS $net] == {INTRASITE}} {
        puts " -I- skipping intra-site net $pintype -> $inputpintype ($netname) (path $count)"
        continue
      }

      if {[catch {set p2pDelay [tb::p2pdelay get_p2p_delay -from $pinname -to $inputpinname -options {-disableGlobals -removeLUTPinDelay}]} errorstring]} {
        set p2pDelay {n/a}
      } else {
        # Convert delay in ns
        set p2pDelay [expr $p2pDelay / 1000.0]
      }
      dputs "<p2pDelay:$p2pDelay>"
      if {[catch {set estDelay [tb::p2pdelay get_est_wire_delay -from $pinname -to $inputpinname]} errorstring]} {
        set estDelay {n/a}
      } else {
        # Convert delay in ns
        set estDelay [expr $estDelay / 1000.0]
      }
      # est / p2p
      set correlation {n/a}
      # ((p2p – est) / p2p)  * 100
      set correlationPct {n/a}
      # abs(p2p - est)
      set absoluteErr {n/a}
      if {[string is double $p2pDelay] && [string is double $estDelay] && ($estDelay != {}) && ($p2pDelay != {})} {
        if {$p2pDelay != 0} {
          set correlation [format {%.2f} [expr double($estDelay) / double($p2pDelay)] ]
          # ((p2p – est) / p2p)  * 100
          set correlationPct [format {%.2f} [expr 100.0 * (double($p2pDelay) - double($estDelay)) / double($p2pDelay)] ]
        } else {
          set correlation {#DIV0}
          set correlationPct {#DIV0}
        }
        # absolute error
        set absoluteErr [format {%.3f} [expr abs($estDelay - $p2pDelay)] ]
      } else {
        set correlation {n/a}
        set correlationPct {n/a}
        set absoluteErr {n/a}
      }

      set slrs [get_slrs -quiet -of [get_pins [list $pinname $inputpinname] ]]
      if {[llength $slrs] == 1} {
        set slrcrossing 0
      } else {
        if {[regexp {SLR([0-9]+) SLR([0-9]+)} [lsort $slrs] - min max]} {
          # Calculate number of SLR crossing between the 2 SLRs
          set slrcrossing [expr $max - $min]
      } else {
          puts " -W- could not extract SLRs from '$slrs'"
          set slrcrossing 1
        }
      }

      incr nTotalNets

      if {[string is double $correlation] && ($correlation != {})} {
        if {($correlation >= [expr 1.0 - $margin]) && ($correlation <= [expr 1.0 + $margin])} {
          # If the ratio is within the margin, skip the net
          puts " -I- skipping net '$netname' (ration = $correlation) (within margin)"
          continue
        }
      }

      # Skip net if the difference between the estimated delay and P2P delay is less than 20ps
      if {[string is double $p2pDelay] && [string is double $estDelay] && ($estDelay != {}) && ($p2pDelay != {})} {
        if {[expr abs(double($estDelay) - double($p2pDelay))] < 0.020} {
          puts " -I- skipping net '$netname' (estDelay=$estDelay / p2pDelay=$p2pDelay) (diff<20ps)"
          continue
        }
      }

      $tbl addrow [list $design \
                        $part \
                        $count \
                        [get_tiles -quiet -of [get_property -quiet SITE [get_cells -quiet -of $pinobj]]] \
                        [get_tiles -quiet -of [get_property -quiet SITE [get_cells -quiet -of $inputpinobj]]] \
                        [tb::p2pdelay pin_info $pinname] \
                        [tb::p2pdelay pin_info $inputpinname] \
                        $pintype \
                        $inputpintype \
                        $slack \
                        [llength $nonIntrasiteNets] \
                        $pinincrdelay \
                        $netincrdelay \
                        $nettype \
                        $estDelay \
                        $p2pDelay \
                        $correlation \
                        $correlationPct \
                        $absoluteErr \
                        $netfanout \
                        $netlength \
                        $slrcrossing \
                        [returnClosestINT $pinobj] \
                        [returnClosestINT $inputpinobj] \
                        $netname \
                        $pinname \
                        $inputpinname \
                        ]

      # Save the list of primitive pairs for statistics
      if {[string is double $correlation] && ($correlation != {})} {
        if {$correlation > [expr 1.0 - $margin]} {
          set fromsubgroup [get_property -quiet PRIMITIVE_SUBGROUP [get_cells -quiet -of $pinobj]]
          set tosubgroup [get_property -quiet PRIMITIVE_SUBGROUP [get_cells -quiet -of $inputpinobj]]
          lappend arrStats(primitive:over) [list $pintype $inputpintype]
          lappend arrStats(subgroup:over) [list $fromsubgroup $tosubgroup]
        } elseif {$correlation < [expr 1.0 + $margin]} {
          set fromsubgroup [get_property -quiet PRIMITIVE_SUBGROUP [get_cells -quiet -of $pinobj]]
          set tosubgroup [get_property -quiet PRIMITIVE_SUBGROUP [get_cells -quiet -of $inputpinobj]]
          lappend arrStats(primitive:under) [list $pintype $inputpintype]
          lappend arrStats(subgroup:under) [list $fromsubgroup $tosubgroup]
        } else {
        }
      }

      incr nNets
    }
  }

  if {$design == {}} {
    set title "Net Correlation"
  } else {
    set title "Net Correlation ($design)"
  }
  append title "\nEstDly/P2PDly < [expr 1.0 - $margin]"
  append title "\nEstDly/P2PDly > [expr 1.0 + $margin]"
  append title "\nEstimated vs. P2P = Estimated / P2P"
  append title "\nError vs. P2P (%) = 100 * (P2P - Estimated) / P2P"
  append title "\nAbsolute Error = ABS(P2P - Estimated)"
  append title "\nTotal number of nets processed: $nTotalNets"
  append title "\nTotal number of nets reported in the table: $nNets"
  $tbl title $title

  set filename [file normalize $filename]
  puts " -I- Generated CSV file $filename"
  $tbl export -format csv -file $filename
  set filename [format {%s.rpt} [file rootname $filename]]
  puts " -I- Generated report file $filename"
  $tbl export -format table -file $filename

  puts [$tbl print]
  catch {$tbl destroy}

  ########################################################################################

  set output [list]

  set tbl1 [::tb::prettyTable "Primitives\nEstDly/P2PDly < [expr 1.0 - $margin]"]
  $tbl1 header [list {From} {To} {#} {%}]
  set L [getFrequencyDistribution $arrStats(primitive:under)]
  foreach el $L {
    foreach {name num} $el { break }
    foreach {from to} $name { break }
    set row [list $from $to $num]
    lappend row [format {%.2f} [expr 100 * $num / double($nNets)]]
    $tbl1 addrow $row
  }
#   puts [$tbl1 print]

  set tbl2 [::tb::prettyTable "Primitives\nEstDly/P2PDly > [expr 1.0 + $margin]"]
  $tbl2 header [list {From} {To} {#} {%}]
  set L [getFrequencyDistribution $arrStats(primitive:over)]
  foreach el $L {
    foreach {name num} $el { break }
    foreach {from to} $name { break }
    set row [list $from $to $num]
    lappend row [format {%.2f} [expr 100 * $num / double($nNets)]]
    $tbl2 addrow $row
  }
#   puts [$tbl2 print]

  puts [sideBySide [$tbl1 print] [$tbl2 print]]
  set output [concat $output [split [sideBySide [$tbl1 print] [$tbl2 print]] \n] ]

  catch {$tbl1 destroy}
  catch {$tbl2 destroy}

  ########################################################################################

  set tbl1 [::tb::prettyTable "Sub-Groups\nEstDly/P2PDly < [expr 1.0 - $margin]"]
  $tbl1 header [list {From} {To} {#} {%}]
  set L [getFrequencyDistribution $arrStats(subgroup:under)]
  foreach el $L {
    foreach {name num} $el { break }
    foreach {from to} $name { break }
    set row [list $from $to $num]
    lappend row [format {%.2f} [expr 100 * $num / double($nNets)]]
    $tbl1 addrow $row
  }
#   puts [$tbl1 print]

  set tbl2 [::tb::prettyTable "Sub-Groups\nEstDly/P2PDly > [expr 1.0 + $margin]"]
  $tbl2 header [list {From} {To} {#} {%}]
  set L [getFrequencyDistribution $arrStats(subgroup:over)]
  foreach el $L {
    foreach {name num} $el { break }
    foreach {from to} $name { break }
    set row [list $from $to $num]
    lappend row [format {%.2f} [expr 100 * $num / double($nNets)]]
    $tbl2 addrow $row
  }
#   puts [$tbl2 print]

  puts [sideBySide [$tbl1 print] [$tbl2 print]]
  set output [concat $output [split [sideBySide [$tbl1 print] [$tbl2 print]] \n] ]

  catch {$tbl1 destroy}
  catch {$tbl2 destroy}

  ########################################################################################

  set FH [open $filename {a}]
  puts $FH "\nTotal number of nets processed: $nTotalNets"
  puts $FH "Total number of nets reported in the table: $nNets\n"
  # Append tables at the end of the report file
  foreach line $output {
    puts $FH [format {%s} $line]
  }
  close $FH

  return -code ok
}

proc get_path_info { path {netlength 0} } {
  if {($path == {})} {
    error " error - no path(s)"
  }
  set rpt [split [report_timing -of $path -no_header -return_string] \n]
  # Create an associative array with the output pins as key and input pins as values
#   array set pathPins [get_pins -quiet -of $path]
  set L [get_pins -quiet -of $path]
  if {[get_property CLASS [get_property STARTPOINT_PIN $path]] == {port}} {
    set L [linsert $L 0 [get_ports [get_property STARTPOINT_PIN $path]]]
  }
  if {[get_property CLASS [get_property ENDPOINT_PIN $path]] == {port}} {
    lappend $L [get_ports [get_property ENDPOINT_PIN $path]]
  }

  # Do not use 'array set' to create associative array due to following bug:
  # Example: L = [list i_top/i_data_path/rx2_dc_i_r_reg[3]/Q i_top/i_data_path/dc_rx2_tp\\.ant_id_reg[3]/D ]
  # The 'array set' command result in 'i_top/i_data_path/dc_rx2_tp\\.ant_id_reg[3]/D' be
  # converted as 'i_top/i_data_path/dc_rx2_tp\.ant_id_reg[3]/D' which changes the pin name.
#   array set pathPins $L
  foreach {el val} $L { set pathPins($el) $val }

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
           dputs "net:<$netname><$netfanout><$nettype><$netincrdelay><$netdelay>"
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
           dputs "pin:<$pinname><$pinrisefall><$pinincrdelay><$pindelay>"
         } elseif {[regexp {^.+\s+(r|f)\s+([^\s]+)(\s|$)} $line - pinrisefall pinname]} {
           # Example of pin endpoint:
           #   RAMB36_X9Y21         RAMB36E1                                     r  core_u/policer_u1/rxOctetCnt_i0/count_ram_i0/ram_data_1_ram_data_1_0_2/ADDRBWRADDR
#            puts "pin:<$pinname><$pinrisefall>"
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
#       puts "\n pindata1: $pindata1"
#       puts " netdata1: $netdata1"
#       puts " pindata2: $pindata2"
#       puts " netdata2: $netdata2"
      foreach {pinname1 pinrisefall1 pinincrdelay1 pindelay1} $pindata1 { break }
      foreach {netname1 netfanout1 nettype1 netincrdelay1 netdelay1} $netdata1 { break }
      foreach {pinname2 pinrisefall2 pinincrdelay2 pindelay2} $pindata2 { break }
      foreach {netname2 netfanout2 nettype2 netincrdelay2 netdelay2} $netdata2 { break }
      set segmentlength [format {%.2f} [dist_cells [get_cells -quiet -of [get_pins -quiet $pinname1]] [get_cells -quiet -of [get_pins -quiet $pinname2]] ]]
      # If length is an integer (X+Y)
      set segmentlength [scan $segmentlength {%d}]
#       puts "  --> $netname1 : $segmentlength"
      lappend data2 [list [list $pinname1 $pinrisefall1 $pinincrdelay1 $pindelay1] [list $netname1 $segmentlength $netfanout1 $nettype1 $netincrdelay1 $netdelay1] $inputpindata1 ]
      set length [expr $length + $segmentlength]
    }
    lappend data2 [list [list $pinname2 $pinrisefall2 {} {}] [list {} {} {} {} {} {}] {} ]
    # If length is a real (flight line)
#     set length [format {%.2f} $length]
    # If length is an integer (X+Y)
    set length [scan $length {%d}]
    set data $data2
  }
  # Return the results
  return $data
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
  # Fligh line distance
#   set distance [format {%.2f} [expr sqrt( pow(double($RPM_X1) - double($RPM_X2), 2) + pow(double($RPM_Y1) - double($RPM_Y2), 2) )] ]
  # X+Y distance
  set distance [format {%d} [expr abs($RPM_X1 - $RPM_X2) + abs($RPM_Y1 - $RPM_Y2) ] ]
  return $distance
}

proc dist_tiles { tile1 tile2 } {
  set tile1 [get_tiles -quiet $tile1]
  set tile2 [get_tiles -quiet $tile2]
  if {($tile1 == {}) || ($tile2 == {})} {
    error " error - empty tile(s)"
  }
  set TILE_X1 [get_property -quiet TILE_X $tile1]
  set TILE_Y1 [get_property -quiet TILE_Y $tile1]
  set TILE_X2 [get_property -quiet TILE_X $tile2]
  set TILE_Y2 [get_property -quiet TILE_Y $tile2]
  # X+Y distance
  set distance [format {%d} [expr abs($TILE_X1 - $TILE_X2) + abs($TILE_Y1 - $TILE_Y2) ] ]
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
#   return [dist_sites $site1 $site2]
  set tile1 [get_tiles -quiet -of $site1]
  set tile2 [get_tiles -quiet -of $site2]
  return [dist_tiles $tile1 $tile2]
}

proc pin2pintype { pin } {
  if {[catch {set cell [get_cells -quiet -of $pin]} errorstring]} {
    set pin [get_pins -quiet $pin]
    set cell [get_cells -quiet -of $pin
  }
  set cellType [get_property -quiet REF_NAME $cell ]
  if {$cellType == {}} {
    set pinType {<PORT>}
  } else {
    # Check whether the pin is a bus or not
    set pinBusName [get_property -quiet BUS_NAME $pin]
    if {$pinBusName == {}} {
      # The pin is not part of a bus
      set pinType [format {%s/%s} $cellType [get_property -quiet REF_PIN_NAME $pin ] ]
    } else {
      # The pin is part of a bus
      set pinType [format {%s/%s[*]} $cellType $pinBusName]
    }
#     set pinType [format {%s/%s} $cellType [get_property -quiet REF_PIN_NAME $pin ] ]
  }
  return $pinType
}

proc returnClosestINT {pin} {
  set sitePin [get_site_pins -quiet -of $pin]
  set nodes [get_nodes -quiet -of $sitePin]
  for {set i 0} {$i < 10} {incr i} {
    foreach node $nodes {
      if {[regexp {^INT_[0-9A-Z_]*X(\d+)Y(\d+).*} [get_property NAME $node] dum x y]} {
        return [lindex [split [get_property -quiet NAME $node] /] 0]
      }
    }
    set nodes [get_nodes -quiet -of [get_pips -quiet -of $nodes]]
  }
  return {n/a}
}

proc dputs {args} {
  global DEBUG
  if {$DEBUG} {
    eval [concat puts $args]
  }
  return -code ok
}

# Example:
#   getFrequencyDistribution [list clk_out2_pll_clrx_2 clk_out2_pll_lnrx_3 clk_out2_pll_lnrx_3 ]
# => {clk_out2_pll_lnrx_3 2} {clk_out2_pll_clrx_2 1}
proc getFrequencyDistribution {L} {
  catch {unset arr}
  set res [list]
  foreach el $L {
    if {![info exists arr($el)]} { set arr($el) 0 }
    incr arr($el)
  }
  foreach {el num} [array get arr] {
    lappend res [list $el $num]
  }
  set res [lsort -decreasing -real -index 1 [lsort -increasing -dictionary -index 0 $res]]
  return $res
}

# #   set output [concat $output [split [sideBySide [$tbl export -format $params(format)] [$tbl_ export -format $params(format)]] \n] ]
proc sideBySide {args} {
  # Add a list of tables side-by-side.
  set res [list]
  set length [list]
  set numtables [llength $args]
  catch { unset arr }
  set idx 0
  foreach tbl $args {
    set arr($idx) [split $tbl \n]
    lappend length [llength $arr($idx) ]
    incr idx
  }
  set max [expr max([join $length ,])]
  for {set linenum 0} {$linenum < $max} {incr linenum} {
    set line {}
    for {set idx 0} {$idx < $numtables} {incr idx} {
      set row [lindex $arr($idx) $linenum]
      if {$row == {}} {
        # This hhappens when tables of different size are being passed as
        # argument
        # If the end of the table has been reached, add empty spaces
        # The number of empty spaces is equal to the length of the first table row
        set row [string repeat { } [string length [lindex $arr($idx) 0]] ]
      }
      append line [format {%s  } $row]
    }
    lappend res $line
  }
  return [join $res \n]
}



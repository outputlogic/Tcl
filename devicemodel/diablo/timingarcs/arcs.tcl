proc reload {} { uplevel 1 [list source  /proj/xsjhdstaff2/dpefour/support/Diablo/timingarcs/scripts/arcs.tcl ] }


if {0} {
set cell [get_cells u0_srio_serdes_top_q222/u_serdes_top_6p25/gth_6p25g_inst/inst/gen_gtwizard_gthe3_top.srio_serdes_6p25_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[0].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/GTHE3_CHANNEL_i]
                    u0_srio_serdes_top_q222/u_serdes_top_6p25/gth_6p25g_inst/inst/gen_gtwizard_gthe3_top.srio_serdes_6p25_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[0].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST

package require toolbox

set patternName {*}
set patternRef {GT*}
set cells [get_cells -quiet -hier -filter "IS_PRIMITIVE && (NAME =~ $patternName) && (REF_NAME =~ $patternRef)"]
llength $cells

# 24 GT*
set gts [get_cells -quiet -hier -filter "IS_PRIMITIVE && (REF_NAME =~ GT*)"]

exportTimingArcs $gts arcs_GT24.csv


Diablo:
#######
exportTimingArcs [get_cells u0_srio_serdes_top_q222/u_serdes_top_6p25/gth_6p25g_inst/inst/gen_gtwizard_gthe3_top.srio_serdes_6p25_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[0].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST/GTHE3_CHANNEL_i]

U/S:
####
exportTimingArcs [get_cells u0_srio_serdes_top_q222/u_serdes_top_6p25/gth_6p25g_inst/inst/gen_gtwizard_gthe3_top.srio_serdes_6p25_gtwizard_gthe3_inst/gen_gtwizard_gthe3.gen_channel_container[0].gen_enabled_channel.gthe3_channel_wrapper_inst/channel_inst/gthe3_channel_gen.gen_gthe3_channel_inst[0].GTHE3_CHANNEL_PRIM_INST]

compareTimingArcs \
  /proj/xsjhdstaff2/dpefour/support/Diablo/estimateddly/US_CUSTOMER_2/US_CUSTOMER_Huawei_5G_TUE_2015_09_25/arcs_GT24.csv \
  /proj/xsjhdstaff2/dpefour/support/Diablo/estimateddly/DBLO_CUSTOMER_SPD3_6/DBLO_CUSTOMER_SPD3_Huawei_5G_TUE_2015_09_25/arcs_GT24.csv \
  GT_delays_diablo_vs_us.csv

}

if {0} {
set cells [get_cells -quiet -hier -filter "IS_PRIMITIVE && (REF_NAME =~ RAMB*)"]

# 3220 RAMB*
exportTimingArcs [lrange $cells 0 end] arcs_RAMB.csv

compareTimingArcs \
  /proj/xsjhdstaff2/dpefour/support/Diablo/estimateddly/US_CUSTOMER_2/US_CUSTOMER_Huawei_5G_TUE_2015_09_25/arcs_RAMB.csv \
  /proj/xsjhdstaff2/dpefour/support/Diablo/estimateddly/DBLO_CUSTOMER_SPD3_6/DBLO_CUSTOMER_SPD3_Huawei_5G_TUE_2015_09_25/arcs_RAMB.csv \
  RAMB_delays_diablo_vs_us.csv

compareTimingArcs \
  /proj/xsjhdstaff2/dpefour/support/Diablo/timingarcs/US_CUSTOMER/US_CUSTOMER_Huawei_5G_TUE_2015_09_25/arcs_RAMB.csv \
  /proj/xsjhdstaff2/dpefour/support/Diablo/timingarcs/DBLO_CUSTOMER_SPD3/DBLO_CUSTOMER_SPD3_Huawei_5G_TUE_2015_09_25/arcs_RAMB.csv \
  RAMB_delays_diablo_vs_us.csv

}

if {0} {
set cells [get_cells -quiet -hier -filter "IS_PRIMITIVE && (REF_NAME =~ DSP*) && (PRIMITIVE_LEVEL == INTERNAL)"]

# order cells
set cells [get_cells [lsort $cells]]

# 6688 DSP*
exportTimingArcs [lrange $cells 0 99] arcs_DSP.csv

compareTimingArcs \
  /proj/xsjhdstaff2/dpefour/support/Diablo/estimateddly/US_CUSTOMER_2/US_CUSTOMER_Huawei_5G_TUE_2015_09_25/arcs_DSP.csv \
  /proj/xsjhdstaff2/dpefour/support/Diablo/estimateddly/DBLO_CUSTOMER_SPD3_6/DBLO_CUSTOMER_SPD3_Huawei_5G_TUE_2015_09_25/arcs_DSP.csv \
  DSP_delays_diablo_vs_us.csv

compareTimingArcs \
  /proj/xsjhdstaff2/dpefour/support/Diablo/timingarcs/US_CUSTOMER/US_CUSTOMER_Huawei_5G_TUE_2015_09_25/arcs_DSP.csv \
  /proj/xsjhdstaff2/dpefour/support/Diablo/timingarcs/DBLO_CUSTOMER_SPD3/DBLO_CUSTOMER_SPD3_Huawei_5G_TUE_2015_09_25/arcs_DSP.csv \
  DSP_delays_diablo_vs_us.csv

}

if {0} {
set cells [get_cells [lsort [get_cells -quiet -hier -filter "IS_PRIMITIVE && (REF_NAME =~ MMCM*)"]]]

# 2 MMCM*
exportTimingArcs [lrange $cells 0 99] arcs_MMCM.csv

compareTimingArcs \
  /proj/xsjhdstaff2/dpefour/support/Diablo/estimateddly/US_CUSTOMER_2/US_CUSTOMER_Huawei_5G_TUE_2015_09_25/arcs_MMCM.csv \
  /proj/xsjhdstaff2/dpefour/support/Diablo/estimateddly/DBLO_CUSTOMER_SPD3_6/DBLO_CUSTOMER_SPD3_Huawei_5G_TUE_2015_09_25/arcs_MMCM.csv \
  MMCM_delays_diablo_vs_us.csv

compareTimingArcs \
  /proj/xsjhdstaff2/dpefour/support/Diablo/timingarcs/US_CUSTOMER/US_CUSTOMER_Huawei_5G_TUE_2015_09_25/arcs_MMCM.csv \
  /proj/xsjhdstaff2/dpefour/support/Diablo/timingarcs/DBLO_CUSTOMER_SPD3/DBLO_CUSTOMER_SPD3_Huawei_5G_TUE_2015_09_25/arcs_MMCM.csv \
  MMCM_delays_diablo_vs_us.csv

}

if {0} {
set cells [get_cells [lsort [get_cells -quiet -hier -filter "IS_PRIMITIVE && (REF_NAME =~ BUFG*)"]]]

# 58 BUFG*
exportTimingArcs [lrange $cells 0 99] arcs_BUFG.csv

compareTimingArcs \
  /proj/xsjhdstaff2/dpefour/support/Diablo/estimateddly/US_CUSTOMER_2/US_CUSTOMER_Huawei_5G_TUE_2015_09_25/arcs_BUFG.csv \
  /proj/xsjhdstaff2/dpefour/support/Diablo/estimateddly/DBLO_CUSTOMER_SPD3_6/DBLO_CUSTOMER_SPD3_Huawei_5G_TUE_2015_09_25/arcs_BUFG.csv \
  BUFG_delays_diablo_vs_us.csv

compareTimingArcs \
  /proj/xsjhdstaff2/dpefour/support/Diablo/timingarcs/US_CUSTOMER/US_CUSTOMER_Huawei_5G_TUE_2015_09_25/arcs_BUFG.csv \
  /proj/xsjhdstaff2/dpefour/support/Diablo/timingarcs/DBLO_CUSTOMER_SPD3/DBLO_CUSTOMER_SPD3_Huawei_5G_TUE_2015_09_25/arcs_BUFG.csv \
  BUFG_delays_diablo_vs_us.csv

}

if {0} {
set cells [get_cells [lsort [get_cells -quiet -hier -filter "IS_PRIMITIVE && (REF_NAME =~ MUXF7*)"]]] ; llength $cells

# 13418 MUXF7*
exportTimingArcs [lrange $cells 0 end] arcs_MUXF7.csv

compareTimingArcs \
  /proj/xsjhdstaff2/dpefour/support/Diablo/estimateddly/US_CUSTOMER_2/US_CUSTOMER_Huawei_5G_TUE_2015_09_25/arcs_MUXF7.csv \
  /proj/xsjhdstaff2/dpefour/support/Diablo/estimateddly/DBLO_CUSTOMER_SPD3_6/DBLO_CUSTOMER_SPD3_Huawei_5G_TUE_2015_09_25/arcs_MUXF7.csv \
  MUXF7_delays_diablo_vs_us.csv

compareTimingArcs \
  /proj/xsjhdstaff2/dpefour/support/Diablo/timingarcs/US_CUSTOMER/US_CUSTOMER_Huawei_5G_TUE_2015_09_25/arcs_MUXF7.csv \
  /proj/xsjhdstaff2/dpefour/support/Diablo/timingarcs/DBLO_CUSTOMER_SPD3/DBLO_CUSTOMER_SPD3_Huawei_5G_TUE_2015_09_25/arcs_MUXF7.csv \
  MUXF7_delays_diablo_vs_us.csv

}

if {0} {
set cells [get_cells [lsort [get_cells -quiet -hier -filter "IS_PRIMITIVE && (REF_NAME =~ MUXF8*)"]]] ; llength $cells

# 4976 MUXF8*
exportTimingArcs [lrange $cells 0 end] arcs_MUXF8.csv

compareTimingArcs \
  /proj/xsjhdstaff2/dpefour/support/Diablo/estimateddly/US_CUSTOMER_2/US_CUSTOMER_Huawei_5G_TUE_2015_09_25/arcs_MUXF8.csv \
  /proj/xsjhdstaff2/dpefour/support/Diablo/estimateddly/DBLO_CUSTOMER_SPD3_6/DBLO_CUSTOMER_SPD3_Huawei_5G_TUE_2015_09_25/arcs_MUXF8.csv \
  MUXF8_delays_diablo_vs_us.csv

compareTimingArcs \
  /proj/xsjhdstaff2/dpefour/support/Diablo/timingarcs/US_CUSTOMER/US_CUSTOMER_Huawei_5G_TUE_2015_09_25/arcs_MUXF8.csv \
  /proj/xsjhdstaff2/dpefour/support/Diablo/timingarcs/DBLO_CUSTOMER_SPD3/DBLO_CUSTOMER_SPD3_Huawei_5G_TUE_2015_09_25/arcs_MUXF8.csv \
  MUXF8_delays_diablo_vs_us.csv

}

if {0} {
set cells [get_cells [lsort [get_cells -quiet -hier -filter "IS_PRIMITIVE && (REF_NAME =~ LUT*)"]]] ; llength $cells

# 768272 LUT*
exportTimingArcs [lrange $cells 0 100] arcs_LUT.csv

compareTimingArcs \
  /proj/xsjhdstaff2/dpefour/support/Diablo/estimateddly/US_CUSTOMER_2/US_CUSTOMER_Huawei_5G_TUE_2015_09_25/arcs_LUT.csv \
  /proj/xsjhdstaff2/dpefour/support/Diablo/estimateddly/DBLO_CUSTOMER_SPD3_6/DBLO_CUSTOMER_SPD3_Huawei_5G_TUE_2015_09_25/arcs_LUT.csv \
  LUT_delays_diablo_vs_us.csv

compareTimingArcs \
  /proj/xsjhdstaff2/dpefour/support/Diablo/timingarcs/US_CUSTOMER/US_CUSTOMER_Huawei_5G_TUE_2015_09_25/arcs_LUT.csv \
  /proj/xsjhdstaff2/dpefour/support/Diablo/timingarcs/DBLO_CUSTOMER_SPD3/DBLO_CUSTOMER_SPD3_Huawei_5G_TUE_2015_09_25/arcs_LUT.csv \
  LUT_delays_diablo_vs_us.csv

do LUT1 LUT2 LUT3 LUT4 LUT5 LUT6
cmp LUT1 LUT2 LUT3 LUT4 LUT5 LUT6

}

##########################################################################################################################

set DEBUG 1
set VERBOSE 0

# do LUT1 LUT2 LUT3 LUT4 LUT5 LUT6
proc do { args } {
	foreach el $args {
    set cells [get_cells [lsort [get_cells -quiet -hier -filter "IS_PRIMITIVE && (REF_NAME =~ $el*)"]]] ; llength $cells
    puts " Found [llength $cells] $el"
    exportTimingArcs [lrange $cells 0 10000] arcs_${el}.csv
	}
}

# cmp LUT1 LUT2 LUT3 LUT4 LUT5 LUT6
proc cmp { args } {
	foreach el $args {
    compareTimingArcs \
      /proj/xsjhdstaff2/dpefour/support/Diablo/estimateddly/US_CUSTOMER_2/US_CUSTOMER_Huawei_5G_TUE_2015_09_25/arcs_${el}.csv \
      /proj/xsjhdstaff2/dpefour/support/Diablo/estimateddly/DBLO_CUSTOMER_SPD3_6/DBLO_CUSTOMER_SPD3_Huawei_5G_TUE_2015_09_25/arcs_${el}.csv \
      ${el}_delays_diablo_vs_us.csv
	}
}

proc exportTimingArcs { cells {filename arcs.csv} } {

  set tbl [tb::prettyTable {Timing Arcs}]
  $tbl header [list {Cell} {Cell Type} {From} {To} {Arc Type} {MAX_FALL} {MAX_RISE} {MIN_FALL} {MIN_RISE}]
  $tbl configure -display_columns {1 2 3 4 5 6 7 8 9 10}

#   foreach cell [lrange $cells 0 0] {}
  set unsorted [list]
  set count 0
  foreach cell $cells {
    incr count
    puts " Processing \[$count/[llength $cells]\] $cell"
    set arcs [get_timing_arcs -quiet -of $cell -filter {!IS_DISABLED && !IS_USER_DISABLED}]
    set celltype [get_property -quiet REF_NAME $cell]
    foreach arc $arcs {
      set frompin [get_property -quiet REF_PIN_NAME [get_property -quiet FROM_PIN $arc]]
      set topin [get_property -quiet REF_PIN_NAME [get_property -quiet TO_PIN $arc]]
      set type [get_property -quiet TYPE $arc]
      set maxfalldly [get_property -quiet DELAY_MAX_FALL $arc]
      set maxrisedly [get_property -quiet DELAY_MAX_RISE $arc]
      set minfalldly [get_property -quiet DELAY_MIN_FALL $arc]
      set minrisedly [get_property -quiet DELAY_MIN_RISE $arc]
      lappend unsorted [list $cell $celltype $frompin $topin $type $maxfalldly $maxrisedly $minfalldly $minrisedly]
    }
  }
  # set sorted [lsort -increasing -dictionary -index 4 [lsort -increasing -dictionary -index 3 [lsort -increasing -dictionary -index 2 [lsort -increasing -dictionary -index 0 $unsorted]]]]
  set sorted [lsort -increasing -dictionary -index 0 [lsort -increasing -dictionary -index 2 [lsort -increasing -dictionary -index 3 [lsort -increasing -dictionary -index 4 $unsorted]]]]
  foreach el $sorted {
    foreach {cell celltype frompin topin type maxfalldly maxrisedly minfalldly minrisedly} $el { break }
#     puts " $celltype $frompin $topin $type $maxfalldly $maxrisedly $minfalldly $minrisedly"
  #   puts " $cell $frompin $topin $type $maxfalldly $maxrisedly $minfalldly $minrisedly"
    $tbl addrow [list $cell $celltype $frompin $topin $type $maxfalldly $maxrisedly $minfalldly $minrisedly]
  }

  # puts [$tbl print]

  $tbl configure -display_columns {0 1 2 3 4 5 6 7 8 9 10}
  puts " File $filename generated"
  $tbl export -format csv -file $filename

  catch {destroy $tbl}

  return -code ok

}

proc compareTimingArcs { usarcfile diabloarcfile {filename compare.csv} } {
  catch {unset db}
  set diabloArcs [readTimingArcs /proj/xsjhdstaff2/dpefour/support/Diablo/estimateddly/DBLO_CUSTOMER_SPD3_6/DBLO_CUSTOMER_SPD3_Huawei_5G_TUE_2015_09_25/arcs.csv ]
  set usArcs [readTimingArcs /proj/xsjhdstaff2/dpefour/support/Diablo/estimateddly/US_CUSTOMER_2/US_CUSTOMER_Huawei_5G_TUE_2015_09_25/arcs.csv ]

  # 24 GTs
  set diabloArcs [readTimingArcs /proj/xsjhdstaff2/dpefour/support/Diablo/estimateddly/DBLO_CUSTOMER_SPD3_6/DBLO_CUSTOMER_SPD3_Huawei_5G_TUE_2015_09_25/arcs_GT24.csv ]
  set usArcs [readTimingArcs /proj/xsjhdstaff2/dpefour/support/Diablo/estimateddly/US_CUSTOMER_2/US_CUSTOMER_Huawei_5G_TUE_2015_09_25/arcs_GT24.csv ]

#   set diabloArcs [readTimingArcs /proj/xsjhdstaff2/dpefour/support/Diablo/estimateddly/DBLO_CUSTOMER_SPD3_6/DBLO_CUSTOMER_SPD3_Huawei_5G_TUE_2015_09_25/arcs_GT1.csv ]
#   set usArcs [readTimingArcs /proj/xsjhdstaff2/dpefour/support/Diablo/estimateddly/US_CUSTOMER_2/US_CUSTOMER_Huawei_5G_TUE_2015_09_25/arcs_GT1.csv ]

  set diabloArcs [readTimingArcs $diabloarcfile ]
  set usArcs [readTimingArcs $usarcfile ]

  set cells [list]

  foreach arc $diabloArcs {
    foreach {cell celltype frompin topin type maxfalldly maxrisedly minfalldly minrisedly} $arc { break }
    lappend db(${cell}:${frompin}:${topin}:${type}) [list {diablo} $celltype $maxfalldly $maxrisedly $minfalldly $minrisedly]
    lappend cells $cell
  }
  set cells [lsort -unique $cells]

  foreach arc $usArcs {
    foreach {cell celltype frompin topin type maxfalldly maxrisedly minfalldly minrisedly} $arc { break }
    set match [getBestMatch $cells $cell]
    if {[lsearch -exact $cells $match] == -1} {
      lappend cells $match
    }
    lappend db(${match}:${frompin}:${topin}:${type}) [list {us} $celltype $maxfalldly $maxrisedly $minfalldly $minrisedly]
  }
  set cells [lsort -unique $cells]


# parray db

  set tbl [tb::prettyTable "Timing Arcs\nRatio: U/S delays over Diablo delays\nDelta: U/S delays minus Diablo delays\nREF_NAME: Diablo"]
#   $tbl header [list {REF_NAME} {From} {To} {Arc Type} {MAX_FALL} {MAX_RISE} {MIN_FALL} {MIN_RISE} {Comment} {Cell} ]
  $tbl header [list {REF_NAME} {From} {To} {Arc Type} {MAX (ratio)} {MAX (delta)} {MIN (ratio)} {MIN (delta)} {Comment} {Cell} {MAX (U/S)} {MIN (U/S)} {MAX (Diablo)} {MIN (Diablo)} ]

  foreach cell $cells {
# puts "<cell:$cell>"
    foreach key [lsort [array names db [normalize $cell]:*]] {
      regsub [normalize $cell]: $key {} subkey
      # E.g: subkey == RXUSRCLK2:RXBYTEREALIGN:Reg Clk to Q
      foreach {frompin topin arctype} [split $subkey :] { break }
      set values $db($key)
# puts "<values:$values><[llength $values]>"
      if {[llength $values] == 1} {
        foreach {serie celltype maxfalldly maxrisedly minfalldly minrisedly} [lindex $values 0] { break }
# puts "<serie:$serie>"
        switch $serie {
          diablo {
            puts " -I- us : missing $frompin -> $topin ($arctype)"
            $tbl addrow [list $celltype $frompin $topin $arctype {-} {-} {-} {-} {Missing in U/S} $cell {-} {-} {-} {-} ]
#             $tbl addrow [list {} $frompin $topin $arctype {-} {-} {-} {-} {Missing in U/S}]

            continue
          }
          us {
            puts " -I- diablo : missing $frompin -> $topin ($type)"
            $tbl addrow [list $celltype $frompin $topin $arctype {-} {-} {-} {-} {Missing in Diablo} $cell {-} {-} {-} {-} ]
#             $tbl addrow [list {} $frompin $topin $arctype {-} {-} {-} {-} {Missing in Diablo}]
            continue
          }
          default {
            puts " -E- unknown serie '$serie'
            continue
          }
        }
      }
      set diabloTiming [list]
      set usTiming [list]
      set diablocelltype {n/a}
      foreach el $values {
        foreach {serie celltype maxfalldly maxrisedly minfalldly minrisedly} $el { break }
        switch $serie {
          diablo {
            set diabloTiming [list $maxfalldly $maxrisedly $minfalldly $minrisedly]
            set diablocelltype $celltype
          }
          us {
            set usTiming [list $maxfalldly $maxrisedly $minfalldly $minrisedly]
          }
          default {
            puts " -E- unknown serie '$serie'
            continue
          }
        }
      }
      if {$diablocelltype != {n/a}} {
      	# Make sure that the reported cell type is by default the cell type from Diablo
      	set celltype $diablocelltype
      }
#       set row [list $type $frompin $topin $arctype]
      set row [list $celltype $frompin $topin $arctype]
#       set row [list {} $frompin $topin $arctype]
      # RISE and FALL have same delays, so only iterate through 1 MAX and 1 MIN
      for {set idx 1} {$idx <=3} {incr idx 2} {
        if {[catch {set res [format {%.3f} [expr double([lindex $usTiming $idx]) / double([lindex $diabloTiming $idx])]] } errorstring]} {
          puts " -E- $errorstring"
          set res {#DIV0}
        }
        lappend row $res
        if {[catch {set res [format {%.3f} [expr double([lindex $usTiming $idx]) - double([lindex $diabloTiming $idx])]] } errorstring]} {
          puts " -E- $errorstring"
          set res {#DIV0}
        }
        lappend row $res
      }
      # For the comment field
      lappend row {}
      lappend row $cell
      lappend row [lindex $usTiming 0]
      lappend row [lindex $usTiming 2]
      lappend row [lindex $diabloTiming 0]
      lappend row [lindex $diabloTiming 2]
      $tbl addrow $row
# puts "<$frompin -> $topin ($arctype)><diabloTiming:$diabloTiming><usTiming:$usTiming>"
# puts "<$key>"
    }
  }

#   puts [$tbl print]

  puts " File $filename generated"
  $tbl export -format csv -file $filename
  set filename [format {%s.rpt} [file rootname $filename]]
  puts " File $filename generated"
  $tbl export -format table -file $filename

  catch {$tbl destroy}

  return -code ok

}

proc normalize { name } {
  regsub -all {\[} $name {\\[} name
  regsub -all {\]} $name {\\]} name
  return $name
}

proc getBestMatch {list element} {
  if {[lsearch -exact $list $element] != -1} {
    return $element
  }
  foreach el $list {
    if {[string first "$element/" $el] == 0} {
      return $el
    }
    if {[string first $element $el] == 0} {
      return $el
    }
  }
  return {n/a}
}

proc readTimingArcs { filename } {
  set tbl [tb::prettyTable]
  read-csv tbl $filename
#   puts [$tbl print]
  set rows [subst $${tbl}::table]
  catch {$tbl destroy}
  return $rows
}

##-----------------------------------------------------------------------
## split-csv
##-----------------------------------------------------------------------
## Convert a CSV string to a Tcl list based on a field separator
##-----------------------------------------------------------------------
proc split-csv { str {sepChar ,} } {
  regsub -all {(\A\"|\"\Z)} $str \0 str
  set str [string map [list $sepChar\"\"$sepChar $sepChar$sepChar] $str]
  set str [string map [list $sepChar\"\"\" $sepChar\0\" \
                            \"\"\"$sepChar \"\0$sepChar \
                            $sepChar\"\"$sepChar $sepChar$sepChar \
                           \"\" \" \
                           \" \0 \
                           ] $str]
  set end 0
  while {[regexp -indices -start $end {(\0)[^\0]*(\0)} $str \
          -> start end]} {
      set start [lindex $start 0]
      set end   [lindex $end 0]
      set range [string range $str $start $end]
      set first [string first $sepChar $range]
      if {$first >= 0} {
          set str [string replace $str $start $end \
              [string map [list $sepChar \1] $range]]
      }
      incr end
  }
  set str [string map [list $sepChar \0 \1 $sepChar \0 {} ] $str]
  return [split $str \0]
}

##-----------------------------------------------------------------------
## read-csv
##-----------------------------------------------------------------------
## Read CSV file and return a Table object
##-----------------------------------------------------------------------
# E.g: read-csv tbl $filename $csvDelimiter $parseHeader
proc read-csv {&tbl filename {csvDelimiter ,} {parseHeader 1}} {
  variable VERBOSE
  variable channel
  if {![file exists $filename]} {
    error " -E- file '$filename' does not exist"
  }
  upvar 1 ${&tbl} tbl
  set FH [open $filename]
  set first 1
  set count 0
  while {![eof $FH]} {
    gets $FH line
    # Skip comments and empty lines
    if {[regexp {^\s*#} $line]} { continue }
    if {[regexp {^\s*$} $line]} { continue }
    if {$first} {
      set header [split-csv $line $csvDelimiter]
      if {[subst $${tbl}::header] != {}} {
        # If we are in merge mode, then check that the header for this CSV file
        # does match the existing header
        if {![lequal [subst $${tbl}::header] $header]} {
          if {$VERBOSE} {
            puts " -I- CSV header: $header"
            puts " -I- Table header: [subst $${tbl}::header]"
          }
          puts " -W- The CSV header does not match. File $filename skipped"
          return 1
        }
      }
      if {$parseHeader} {
        $tbl header $header
      } else {
        # If the CSV file has no header, create an empty header with correct number
        # of columns and add the first line as a row
        set L [list] ; foreach el $header { lappend L {} }
        $tbl header $L
        $tbl addrow $header
        incr count
      }
      set first 0
    } else {
      $tbl addrow [split-csv $line $csvDelimiter]
      incr count
    }
  }
  close $FH
  if {$VERBOSE && ($channel != {})} {
    puts $channel " -I- Header: $header"
    puts $channel " -I- Number of imported row(s): $count"
  }
  return 0
}


# +-------------------------------------------------------------------------------------------------------------------+
# | Timing Arcs                                                                                                       |
# | Ratio U/S delays over Diablo delays                                                                               |
# +------+-----------+-----------------+--------------+----------+----------+----------+----------+-------------------+
# | Cell | From      | To              | Arc Type     | MAX_FALL | MAX_RISE | MIN_FALL | MIN_RISE | Comment           |
# +------+-----------+-----------------+--------------+----------+----------+----------+----------+-------------------+
# |      | RXUSRCLK2 | RXBYTEISALIGNED | Reg Clk to Q | 1.76     | 1.76     | 1.71     | 1.71     |                   |
# |      | RXUSRCLK2 | RXBYTEREALIGN   | Reg Clk to Q | 1.86     | 1.86     | 1.78     | 1.78     |                   |
# |      | RXUSRCLK2 | RXCHBONDO[0]    | Reg Clk to Q | -        | -        | -        | -        | Missing in U/S    |
# |      | RXUSRCLK2 | RXCHBONDO[1]    | Reg Clk to Q | -        | -        | -        | -        | Missing in U/S    |
# |      | RXUSRCLK2 | RXCHBONDO[2]    | Reg Clk to Q | -        | -        | -        | -        | Missing in U/S    |
# |      | RXUSRCLK2 | RXCHBONDO[3]    | Reg Clk to Q | -        | -        | -        | -        | Missing in U/S    |
# |      | RXUSRCLK2 | RXCHBONDO[4]    | Reg Clk to Q | -        | -        | -        | -        | Missing in U/S    |
# |      | RXUSRCLK2 | RXCTRL0[0]      | Reg Clk to Q | 1.74     | 1.74     | 1.56     | 1.56     |                   |
# |      | RXUSRCLK2 | RXCTRL0[1]      | Reg Clk to Q | 1.63     | 1.63     | 1.53     | 1.53     |                   |
# |      | RXUSRCLK2 | RXCTRL1[0]      | Reg Clk to Q | 1.55     | 1.55     | 1.49     | 1.49     |                   |
# |      | RXUSRCLK2 | RXCTRL1[1]      | Reg Clk to Q | 1.56     | 1.56     | 1.55     | 1.55     |                   |
# |      | RXUSRCLK2 | RXCTRL3[0]      | Reg Clk to Q | 1.74     | 1.74     | 1.69     | 1.69     |                   |
# |      | RXUSRCLK2 | RXCTRL3[1]      | Reg Clk to Q | 1.66     | 1.66     | 1.63     | 1.63     |                   |
# |      | RXUSRCLK2 | RXDATA[0]       | Reg Clk to Q | 1.75     | 1.75     | 1.71     | 1.71     |                   |
# |      | RXUSRCLK2 | RXDATA[10]      | Reg Clk to Q | 1.91     | 1.91     | 1.84     | 1.84     |                   |
# |      | RXUSRCLK2 | RXDATA[11]      | Reg Clk to Q | 1.77     | 1.77     | 1.73     | 1.73     |                   |
# |      | RXUSRCLK2 | RXDATA[12]      | Reg Clk to Q | 1.80     | 1.80     | 1.78     | 1.78     |                   |
# |      | RXUSRCLK2 | RXDATA[13]      | Reg Clk to Q | 1.90     | 1.90     | 1.83     | 1.83     |                   |
# |      | RXUSRCLK2 | RXDATA[14]      | Reg Clk to Q | 1.90     | 1.90     | 1.86     | 1.86     |                   |
# |      | RXUSRCLK2 | RXDATA[15]      | Reg Clk to Q | 1.97     | 1.97     | 1.90     | 1.90     |                   |
# |      | RXUSRCLK2 | RXDATA[1]       | Reg Clk to Q | 1.76     | 1.76     | 1.72     | 1.72     |                   |
# |      | RXUSRCLK2 | RXDATA[2]       | Reg Clk to Q | 1.79     | 1.79     | 1.74     | 1.74     |                   |
# |      | RXUSRCLK2 | RXDATA[3]       | Reg Clk to Q | 1.90     | 1.90     | 1.75     | 1.75     |                   |
# |      | RXUSRCLK2 | RXDATA[4]       | Reg Clk to Q | 2.10     | 2.10     | 1.81     | 1.81     |                   |
# |      | RXUSRCLK2 | RXDATA[5]       | Reg Clk to Q | 1.91     | 1.91     | 1.86     | 1.86     |                   |
# |      | RXUSRCLK2 | RXDATA[6]       | Reg Clk to Q | 1.92     | 1.92     | 1.78     | 1.78     |                   |
# |      | RXUSRCLK2 | RXDATA[7]       | Reg Clk to Q | 1.93     | 1.93     | 1.87     | 1.87     |                   |
# |      | RXUSRCLK2 | RXDATA[8]       | Reg Clk to Q | 1.77     | 1.77     | 1.73     | 1.73     |                   |
# |      | RXUSRCLK2 | RXDATA[9]       | Reg Clk to Q | 1.80     | 1.80     | 1.74     | 1.74     |                   |
# |      | RXUSRCLK2 | RXRESETDONE     | Reg Clk to Q | -        | -        | -        | -        | Missing in Diablo |
# |      | RXUSRCLK2 | RXUSRCLK        | skew         | 0.93     | 0.93     | 0.93     | 0.93     |                   |
# |      | RXUSRCLK  | RXCHBONDO[0]    | Reg Clk to Q | -        | -        | -        | -        | Missing in Diablo |
# |      | RXUSRCLK  | RXCHBONDO[1]    | Reg Clk to Q | -        | -        | -        | -        | Missing in Diablo |
# |      | RXUSRCLK  | RXCHBONDO[2]    | Reg Clk to Q | -        | -        | -        | -        | Missing in Diablo |
# |      | RXUSRCLK  | RXCHBONDO[3]    | Reg Clk to Q | -        | -        | -        | -        | Missing in Diablo |
# |      | RXUSRCLK  | RXCHBONDO[4]    | Reg Clk to Q | -        | -        | -        | -        | Missing in Diablo |
# |      | RXUSRCLK  | RXUSRCLK2       | skew         | 0.63     | 0.63     | 0.63     | 0.63     |                   |
# |      | TXUSRCLK2 | TXBUFSTATUS[0]  | Reg Clk to Q | 1.99     | 1.99     | 1.83     | 1.83     |                   |
# |      | TXUSRCLK2 | TXBUFSTATUS[1]  | Reg Clk to Q | 1.97     | 1.97     | 1.82     | 1.82     |                   |
# |      | TXUSRCLK2 | TXCTRL2[0]      | hold         | 1.61     | 1.61     | 0.90     | 0.90     |                   |
# |      | TXUSRCLK2 | TXCTRL2[0]      | setup        | -2.31    | -2.31    | -1.34    | -1.34    |                   |
# |      | TXUSRCLK2 | TXCTRL2[1]      | hold         | 1.91     | 1.91     | 1.28     | 1.28     |                   |
# |      | TXUSRCLK2 | TXCTRL2[1]      | setup        | -2.16    | -2.16    | -1.37    | -1.37    |                   |
# |      | TXUSRCLK2 | TXDATA[0]       | hold         | 2.67     | 2.67     | 1.62     | 1.62     |                   |
# |      | TXUSRCLK2 | TXDATA[0]       | setup        | -4.03    | -4.03    | -1.97    | -1.97    |                   |
# |      | TXUSRCLK2 | TXDATA[10]      | hold         | 2.08     | 2.08     | 1.22     | 1.22     |                   |
# |      | TXUSRCLK2 | TXDATA[10]      | setup        | -2.16    | -2.16    | -1.22    | -1.22    |                   |
# |      | TXUSRCLK2 | TXDATA[11]      | hold         | 1.69     | 1.69     | 1.16     | 1.16     |                   |
# |      | TXUSRCLK2 | TXDATA[11]      | setup        | -1.66    | -1.66    | -0.97    | -0.97    |                   |
# |      | TXUSRCLK2 | TXDATA[12]      | hold         | 1.60     | 1.60     | 1.03     | 1.03     |                   |
# |      | TXUSRCLK2 | TXDATA[12]      | setup        | -1.71    | -1.71    | -1.08    | -1.08    |                   |
# |      | TXUSRCLK2 | TXDATA[13]      | hold         | 2.43     | 2.43     | 1.18     | 1.18     |                   |
# |      | TXUSRCLK2 | TXDATA[13]      | setup        | -2.05    | -2.05    | -0.89    | -0.89    |                   |
# |      | TXUSRCLK2 | TXDATA[14]      | hold         | 1.86     | 1.86     | 1.16     | 1.16     |                   |
# |      | TXUSRCLK2 | TXDATA[14]      | setup        | -1.50    | -1.50    | -0.88    | -0.88    |                   |
# |      | TXUSRCLK2 | TXDATA[15]      | hold         | 3.20     | 3.20     | 1.46     | 1.46     |                   |
# |      | TXUSRCLK2 | TXDATA[15]      | setup        | -4.29    | -4.29    | -1.70    | -1.70    |                   |
# |      | TXUSRCLK2 | TXDATA[1]       | hold         | 1.87     | 1.87     | 1.07     | 1.07     |                   |
# |      | TXUSRCLK2 | TXDATA[1]       | setup        | -1.80    | -1.80    | -0.96    | -0.96    |                   |
# |      | TXUSRCLK2 | TXDATA[2]       | hold         | 2.08     | 2.08     | 1.07     | 1.07     |                   |
# |      | TXUSRCLK2 | TXDATA[2]       | setup        | -2.70    | -2.70    | -1.45    | -1.45    |                   |
# |      | TXUSRCLK2 | TXDATA[3]       | hold         | -24.71   | -24.71   | -58.67   | -58.67   |                   |
# |      | TXUSRCLK2 | TXDATA[3]       | setup        | 1.42     | 1.42     | 1.63     | 1.63     |                   |
# |      | TXUSRCLK2 | TXDATA[4]       | hold         | 1.50     | 1.50     | 0.84     | 0.84     |                   |
# |      | TXUSRCLK2 | TXDATA[4]       | setup        | -2.25    | -2.25    | -1.35    | -1.35    |                   |
# |      | TXUSRCLK2 | TXDATA[5]       | hold         | 1.59     | 1.59     | 1.09     | 1.09     |                   |
# |      | TXUSRCLK2 | TXDATA[5]       | setup        | -2.00    | -2.00    | -1.23    | -1.23    |                   |
# |      | TXUSRCLK2 | TXDATA[6]       | hold         | 1.56     | 1.56     | 1.10     | 1.10     |                   |
# |      | TXUSRCLK2 | TXDATA[6]       | setup        | -2.48    | -2.48    | -1.52    | -1.52    |                   |
# |      | TXUSRCLK2 | TXDATA[7]       | hold         | 4.20     | 4.20     | 1.99     | 1.99     |                   |
# |      | TXUSRCLK2 | TXDATA[7]       | setup        | -4.14    | -4.14    | -1.98    | -1.98    |                   |
# |      | TXUSRCLK2 | TXDATA[8]       | hold         | 2.09     | 2.09     | 1.08     | 1.08     |                   |
# |      | TXUSRCLK2 | TXDATA[8]       | setup        | -1.70    | -1.70    | -0.82    | -0.82    |                   |
# |      | TXUSRCLK2 | TXDATA[9]       | hold         | 1.21     | 1.21     | 0.75     | 0.75     |                   |
# |      | TXUSRCLK2 | TXDATA[9]       | setup        | -2.42    | -2.42    | -1.48    | -1.48    |                   |
# |      | TXUSRCLK2 | TXRESETDONE     | Reg Clk to Q | -        | -        | -        | -        | Missing in Diablo |
# |      | TXUSRCLK2 | TXUSRCLK        | skew         | 0.78     | 0.78     | 0.78     | 0.78     |                   |
# |      | TXUSRCLK  | TXUSRCLK2       | skew         | 0.75     | 0.75     | 0.75     | 0.75     |                   |
# +------+-----------+-----------------+--------------+----------+----------+----------+----------+-------------------+


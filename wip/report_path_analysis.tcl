####################################################################################################
# HEADER_BEGIN
# COPYRIGHT NOTICE
# Copyright 2001-2016 Xilinx Inc. All Rights Reserved.
# http://www.xilinx.com/support
# HEADER_END
####################################################################################################

proc [file tail [info script]] {} " source [info script]; puts \" [info script] reloaded\" "
proc reload {} " source [info script]; puts \" [info script] reloaded\" "

########################################################################################
##
## Company:        Xilinx, Inc.
## Created by:     David Pefourque
##
## Description:    Generate a report from a list of timing paths
##
########################################################################################

########################################################################################
## 2016.02.08 - Improved supported primitives (UltraScale Plus)
## 2015.10.21 - Fixed issue when timing paths start or end on a port
##            - Remove PBlock table when there is no pblock in the design
##            - Added new column 'ILKN' to support interlaken
##            - Fixed missing atoms for DSP
## 2015.10.07 - Added some tables for startpoints/endpoints distributions
##            - Added new properties spPinType, epPinType
## 2015.09.29 - Added some tables for top-level modules
##            - Added some tables for path distribution
## 2015.09.28 - Fixed sorting issue in the first path table in the case the path objects
##              would not be sorted by slack
## 2015.09.11 - Added new column (ckRegion)
##            - Added new table 'PBlocks Pairs Distribution'
##            - Improved supported primitives (SRL16E)
## 2015.08.17 - Fixed issues with WNS being reported as 'N/A'
##            - Fixes issues with infinite slack paths
## 2015.08.13 - Fixed incorrect TNS calculation when paths have positive slack
##            - Added new columns (startPointPin endPointPin)
## 2015.06.25 - Initial release
########################################################################################

set ::DEBUG_SHOW_ALL_TABLES 0

# Example of report:

if {[catch {package require prettyTable}]} {
  lappend auto_path {/home/dpefour/git/scripts/toolbox}
  package require prettyTable
}

namespace eval ::tb {
  namespace export -force report_path_analysis
}

namespace eval ::tb::utils {
  namespace export -force report_path_analysis
}

namespace eval ::tb::utils::report_path_analysis {
  namespace export -force report_path_analysis
  variable version {2016.02.08}
  variable pathObj
  variable pathData
  variable params
  variable output {}
#DEBUG
#   catch {unset pathObj}
#   catch {unset pathData}
#   catch {unset params}
  array set params [list format {table} delayType {setup} sortby 1 numpaths 0 maxrows 50 verbose 0 debug 0]
}

proc ::tb::utils::report_path_analysis::lshift {inputlist} {
  upvar $inputlist argv
  set arg  [lindex $argv 0]
  set argv [lrange $argv 1 end]
  return $arg
}

proc ::tb::utils::report_path_analysis::report_path_analysis {args} {
  variable pathObj
  variable pathData
  variable params
  variable output
  set params(verbose) 0
  set params(debug) 0
  set params(delayType) {setup}
  set params(format) {table}
  set maxPaths 10
  set maxRows $params(maxrows)
  set upperSlackLimit 0.0
  set delayType {}
  set filename {}
  set paths [list]
  set returnstring 0
  set rebuild 1
  set error 0
  set help 0
#   if {[llength $args] == 0} {
#     set help 1
#   }
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-o(f(_(o(b(j(e(c(t(s?)?)?)?)?)?)?)?)?)?$} {
           set paths [lshift args]
      }
      -f -
      -file {
        set filename [lshift args]
      }
      -csv {
        set params(format) {csv}
      }
      -return -
      -return_string {
        set returnstring 1
      }
      -v -
      -verbose {
        set params(verbose) 1
      }
      {^-max$} -
      -max_paths {
        set maxPaths [lshift args]
      }
      -max_row -
      -max_rows {
        set maxRows [lshift args]
        set params(maxrows) $maxRows
      }
      -sort -
      -sort_by {
        set value [string tolower [lshift args]]
        switch $value {
          count {
            set params(sortby) 0
          }
          wns {
            set params(sortby) 1
          }
          tns {
            set params(sortby) 2
          }
          default {
            incr error
            puts " -E- invalid value for -sort_by: count | wns | tns"
          }
        }
      }
      -setup -
      -setup {
        lappend delayType {setup}
      }
      -hold -
      -hold {
        lappend delayType {hold}
      }
      -R -
      -reentrant {
        set rebuild 0
      }
      -d -
      -debug {
        set params(debug) 1
      }
      -h -
      -help {
           set help 1
      }
      default {
            if {[string match "-*" [lindex $name 0]]} {
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
  Usage: report_path_analysis
              [-of_objects <timing_paths_objects>]
              [-setup|-hold]
              [-max_paths <num>]
              [-max_rows <num>]
              [-sort_by <count|wns|tns>]
              [-file <filename>]
              [-csv]
              [-return_string]
              [-R|-reentrant]
              [-verbose|-v]
              [-help|-h]

  Description: Generate report based on a list of timing paths

  Example:
     report_path_analysis -of_objects [get_timing_paths -setup]
} ]
    # HELP -->
    return -code ok
  }

  if {[llength [lsort -unique $delayType]] == 2} {
    puts " -E- options -setup & -hold can not be specified together"
    incr error
  } else {
    switch [lsort -unique $delayType] {
      hold {
        set params(delayType) {hold}
      }
      default {
        set params(delayType) {setup}
      }
    }

    if {($rebuild == 0) && ![info exists pathData(@)]} {
      puts " -E- cannot use -reentrant|-R when no data structure exists"
      incr error
    }
  }

  if {($filename != {}) && $returnstring} {
    puts " -E- cannot use -file & -return_string together"
    incr error
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  if {$paths == [list]} {
    # Get the list of paths
    set paths [get_timing_paths -quiet -nworst 1 -max_path $maxPaths -slack_lesser_than $upperSlackLimit -$params(delayType)]
  } else {
    # If a single path was passed, the path needs to be included in a list
    if {![catch {set res [get_property CLASS $paths]}]} {
      if {[llength $res] == 1} {
        set paths [list $paths]
      }
    }
  }

  set startTime [clock seconds]
  set output [list]

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

  if {$rebuild} {
    buildPathData $paths $params(delayType)
    set nPaths [llength $paths]
  } else {
#     set paths [getParam {timing_path}]
    set paths $pathData(OBJS)
    set nPaths $pathData(@)
  }
  set params(numpaths) $nPaths

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

  reportPathSummary 0 [expr $nPaths -1]

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

  set tbl [createTable -title {Source Clock Distribution (createTable)} \
                       -param {srcClk} \
                       -header [list {Source Clock}] \
                       ]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

  set tbl [createTable -title {Destination Clock Distribution (createTable)} \
                       -param {dstClk} \
                       -header [list {Destination Clock}] \
                       ]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

  set tbl [createTable -title {Clock Pair Distribution (createTable)} \
                       -param {srcClk dstClk} \
                       -header [list {Source} {Destination}] \
                       ]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

  set tbl [createTable -title {Clock Pair Distribution (createTable)} \
                       -param {srcClk dstClk} \
                       -header [list {Source} {Destination}] \
                       -refparam {slack} \
                       -refheader {WNS} \
                       -refstats 1 \
                       -percentlimit 1.0 \
                       -maxvalues 10 \
                      ]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

  set tbl [::tb::prettyTable {Primitive Groups Distribution}]
  $tbl configure -indent 2
  $tbl header [list {Name} {#} {%}]
  set L [list]
  # The param 'primitive' returns a list of cells with a count associated. The list must
  # be post-processed to 1) be flattend 2) remove all cell with 0 occurence 3) expand cells with
  # multiple occurence so that they can be counted adequately
  #   {LUT 5 CARRY 0 MUX 0 FD 2 SRL 0 LUTRAM 0 RAMB 0 DSP 0 CLK 0 GT 0 PCIE 0 IO 0 OTHER 0} {LUT 4 CARRY 0 MUX 0 FD 2 SRL 0 LUTRAM 0 RAMB 0 DSP 0 CLK 0 GT 0 PCIE 0 IO 0 OTHER 0} {LUT 4 CARRY 0 MUX 0 FD 2 SRL 0 LUTRAM 0 RAMB 0 DSP 0 CLK 0 GT 0 PCIE 0 IO 0 OTHER 0}
  foreach {prim count} [lflatten [getParam primitive]] {
    if {$count == 0} { continue }
    for {set i 0} {$i < $count} {incr i} {
      lappend L $prim
    }
  }
  set nPrimitives [llength $L]
  set L [getFrequencyDistribution $L]
  foreach el $L {
    foreach {name num} $el { break }
    set row [list $name $num]
    lappend row [format {%.2f} [expr 100 * $num / double($nPrimitives)]]
    $tbl addrow $row
  }
#   puts [$tbl print]
  # Trim the table by the max number of rows
  $tbl trim $params(maxrows)
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

  set tbl [::tb::prettyTable {Primitives Distribution}]
  $tbl configure -indent 2
  $tbl header [list {Name} {#} {%} {# (uniq inst)} {% (uniq inst)}]
  set L1 [list]
  # Iterate for each path to prevent uniquification for same cells
  # by get_cells across all paths
  foreach path $paths {
    set L1 [concat $L1 [get_property -quiet REF_NAME [get_cells -of $path]]]
  }
  set nPrimitives1 [llength $L1]
  set L1 [getFrequencyDistribution $L1]
  set L2 [get_property -quiet REF_NAME [get_cells -of $paths]]
  set nPrimitives2 [llength $L2]
  set L2 [getFrequencyDistribution $L2]
  foreach el1 $L1 el2 $L2 {
    # By construction, name1==name2
    foreach {name1 num1} $el1 { break }
    foreach {name2 num2} $el2 { break }
    set row [list $name1]
    lappend row $num1
    lappend row [format {%.2f} [expr 100 * $num1 / double($nPrimitives1)]]
    lappend row $num2
    lappend row [format {%.2f} [expr 100 * $num2 / double($nPrimitives2)]]
    $tbl addrow $row
  }
#   puts [$tbl print]
  # Trim the table by the max number of rows
  $tbl trim $params(maxrows)
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

  set tbl [createTable -title {Startpoints/Endpoints Distribution (createTable)} \
                       -param {spType epType} \
                       -header [list {Startpoint} {Endpoint}] \
                       -refparam {slack} \
                       -refheader {WNS} \
                       -refstats 1 \
                       -percentlimit 1.0 \
                       -maxvalues 10 \
                       ]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

  set tbl [createTable -title {Startpoints/Endpoints Pins Distribution (createTable)} \
                       -param {spPinType epPinType} \
                       -header [list {Startpoint} {Endpoint}] \
                       -refparam {slack} \
                       -refheader {WNS} \
                       -refstats 1 \
                       -percentlimit 1.0 \
                       -maxvalues 10 \
                       ]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

  set tbl [createTable -title {Levels Distribution (createTable)} \
                       -param {lvls} \
                       -header [list {Level}] \
                       ]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

  set tbl [createTable -title {Levels Distribution (createTable)} \
                       -param {lvls} \
                       -header [list {Level}] \
                       -refparam {slack} \
                       -refheader {WNS} \
                       -refstats 1 \
                       -percentlimit 1.0 \
                       -maxvalues 10 \
                       ]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

  set tbl [::tb::prettyTable {Levels Distribution (by Clock Pair)}]
  $tbl configure -indent 2
  $tbl header [list {Source} {Destination} 0 1 2 3 4 5 6 7 8 9 10 11-15 16-20 21-25 26-30 31+]
  set L [getFrequencyDistribution [getParam {srcClk dstClk lvls}]]
  catch {unset arr}
  set clockPairs [list]
  foreach el $L {
    foreach {name num} $el { break }
    foreach {srcClk dstClk lvls} $name { break }
    lappend clockPairs [list $srcClk $dstClk]
    if {![info exists arr(${srcClk}:${dstClk}:${lvls})]} { set arr(${srcClk}:${dstClk}:${lvls}) 0 }
    incr arr(${srcClk}:${dstClk}:${lvls}) $num
  }
  set clockPairs [lsort -unique $clockPairs]
  foreach cp $clockPairs {
    set levels [list 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
    foreach {srcClk dstClk} $cp { break }
    foreach key [array names arr ${srcClk}:${dstClk}:*] {
      regsub "${srcClk}:${dstClk}:" $key {} level
      if {($level >=0)  && ($level <=10)} { lset levels $level $arr($key) }
      if {($level >=11) && ($level <=15)} { lset levels 11 [expr [lindex $levels $level] + $arr($key)] }
      if {($level >=16) && ($level <=20)} { lset levels 12 [expr [lindex $levels $level] + $arr($key)] }
      if {($level >=21) && ($level <=25)} { lset levels 13 [expr [lindex $levels $level] + $arr($key)] }
      if {($level >=26) && ($level <=30)} { lset levels 14 [expr [lindex $levels $level] + $arr($key)] }
      if {$level >=31}                    { lset levels 15 [expr [lindex $levels $level] + $arr($key)] }
    }
    $tbl addrow [concat $srcClk $dstClk $levels]
  }
  # Trim the table by the max number of rows
#   $tbl trim $params(maxrows)
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

  set tbl [::tb::prettyTable {Levels Distribution (by Clock Group)}]
  $tbl configure -indent 2
  $tbl header [list {Destination} 0 1 2 3 4 5 6 7 8 9 10 11-15 16-20 21-25 26-30 31+]
  set L [getFrequencyDistribution [getParam {dstClk lvls}]]
  catch {unset arr}
  set clocks [list]
  foreach el $L {
    foreach {name num} $el { break }
    foreach {dstClk lvls} $name { break }
    lappend clocks $dstClk
    if {![info exists arr(${dstClk}:${lvls})]} { set arr(${dstClk}:${lvls}) 0 }
    incr arr(${dstClk}:${lvls}) $num
  }
  set clocks [lsort -unique $clocks]
  foreach dstClk $clocks {
    set levels [list 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
    foreach key [array names arr ${dstClk}:*] {
      regsub "${dstClk}:" $key {} level
      if {($level >=0)  && ($level <=10)} { lset levels $level $arr($key) }
      if {($level >=11) && ($level <=15)} { lset levels 11 [expr [lindex $levels $level] + $arr($key)] }
      if {($level >=16) && ($level <=20)} { lset levels 12 [expr [lindex $levels $level] + $arr($key)] }
      if {($level >=21) && ($level <=25)} { lset levels 13 [expr [lindex $levels $level] + $arr($key)] }
      if {($level >=26) && ($level <=30)} { lset levels 14 [expr [lindex $levels $level] + $arr($key)] }
      if {$level >=31}                    { lset levels 15 [expr [lindex $levels $level] + $arr($key)] }
    }
    $tbl addrow [concat $dstClk $levels]
  }
  # Trim the table by the max number of rows
#   $tbl trim $params(maxrows)
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

#   set tbl [::tb::prettyTable {Hierarchical Modules Distribution}]
#   $tbl configure -indent 2
#   $tbl header [list {Module} {#} {%} {WNS} {TNS}]
#   set L [list]
#   catch { unset arr }
#   set skip 0
#   foreach el [getParam {spRefName epRefName slack}] {
#     foreach {sp ep slack} $el {break}
#     # Remove last elements of the lists since it is a primitive and not hierarchical module
#     # E.g: {obelix_100gtr_top__parameterized3 obelix_100gtr_otl_if_2637 reg_mc_otl_5272 FDCE}
#     # The list of hierarchical module is also uniquified for each path so that it is not
#     # counted twice if it happens in both the startpoint and endpoint
#     set modules [lsort -unique [concat [lrange $sp 0 end-1] [lrange $ep 0 end-1]] ]
#     foreach m $modules {
#       # Save slack so that worst slack per module can be retreived
#       lappend arr($m) $slack
#     }
#     lappend L $modules
#   }
#   set L [getFrequencyDistribution [lflatten $L]]
#   foreach el $L {
#     foreach {name num} $el { break }
#     set row [list $name $num]
#     set percent [format {%.2f} [expr 100 * $num / double($nPaths)]]
#     # DEBUG
# #     if {$percent < 1.0} { incr skip ; continue }
#     lappend row $percent
#     lappend row [expr min([join $arr($name) ,])]
#     lappend row [format {%.3f} [expr [join $arr($name) +] ] ]
#     $tbl addrow $row
#   }
# set tbl_ [$tbl clone]
# $tbl_ sort -real +3
#   if {$skip} {
#     $tbl addrow [list {...} {...} {...} {...}]
#   }
# #   puts [$tbl print]
# #   set output [concat $output [split [$tbl export -format $params(format)] \n] ]
#   set output [concat $output [split [sideBySide [$tbl export -format $params(format)] [$tbl_ export -format $params(format)]] \n] ]
#   catch {$tbl destroy}
# catch {$tbl_ destroy}

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

#   set tbl [::tb::prettyTable {Hierarchical Modules Distribution (OrigRefName)}]
#   $tbl configure -indent 2
#   $tbl header [list {Module} {#} {%} {WNS} {TNS}]
#   set L [list]
#   catch { unset arr }
#   set skip 0
#   foreach el [getParam {spOrigRefName epOrigRefName slack}] {
#     foreach {sp ep slack} $el {break}
#     # Remove last elements of the lists since it is a primitive and not hierarchical module
#     # E.g: {obelix_100gtr_top__parameterized3 obelix_100gtr_otl_if_2637 reg_mc_otl_5272 FDCE}
#     # The list of hierarchical module is also uniquified for each path so that it is not
#     # counted twice if it happens in both the startpoint and endpoint
#     set modules [lsort -unique [concat [lrange $sp 0 end-1] [lrange $ep 0 end-1]] ]
#     foreach m $modules {
#       # Save slack so that worst slack per module can be retreived
#       lappend arr($m) $slack
#     }
#     lappend L $modules
#   }
#   set L [getFrequencyDistribution [lflatten $L]]
#   foreach el $L {
#     foreach {name num} $el { break }
#     set row [list $name $num]
#     set percent [format {%.2f} [expr 100 * $num / double($nPaths)]]
#     # DEBUG
# #     if {$percent < 1.0} { incr skip ; continue }
#     lappend row $percent
#     lappend row [expr min([join $arr($name) ,])]
#     lappend row [format {%.3f} [expr [join $arr($name) +] ] ]
#     $tbl addrow $row
#   }
# set tbl_ [$tbl clone]
# $tbl_ sort -real +3
#   if {$skip} {
#     $tbl addrow [list {...} {...} {...} {...}]
#   }
# #   puts [$tbl print]
# #   set output [concat $output [split [$tbl export -format $params(format)] \n] ]
#   set output [concat $output [split [sideBySide [$tbl export -format $params(format)] [$tbl_ export -format $params(format)]] \n] ]
#   catch {$tbl destroy}
# catch {$tbl_ destroy}

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

if {$::DEBUG_SHOW_ALL_TABLES} {
  set tbl [::tb::prettyTable {Top-Level Modules Distribution}]
  $tbl configure -indent 2
  $tbl header [list {Module} {#} {%} {WNS} {TNS}]
  set L [list]
  catch { unset arr }
  set skip 0
  foreach el [getParam {spRefName epRefName slack}] {
    foreach {sp ep slack} $el {break}
    # Remove last elements of the lists since it is a primitive and not hierarchical module
    # E.g: {obelix_100gtr_top__parameterized3 obelix_100gtr_otl_if_2637 reg_mc_otl_5272 FDCE}
    # The list of hierarchical module is also uniquified for each path so that it is not
    # counted twice if it happens in both the startpoint and endpoint
    set modules [lsort -unique [concat [lindex $sp 0] [lindex $ep 0]] ]
    foreach m $modules {
      # Save slack so that worst slack per module can be retreived
      lappend arr($m) $slack
    }
    lappend L $modules
  }
  set L [getFrequencyDistribution [lflatten $L]]
  foreach el $L {
    foreach {name num} $el { break }
    set row [list $name $num]
    set percent [format {%.2f} [expr 100 * $num / double($nPaths)]]
    # DEBUG
#     if {$percent < 1.0} { incr skip ; continue }
    lappend row $percent
#     lappend row [expr min([join $arr($name) ,])]
#     lappend row [format {%.3f} [expr [join $arr($name) +] ] ]
    lappend row [getWNS $arr($name)]
    if {[catch {lappend row [format {%.3f} [getTNS $arr($name)] ]} errorstring]} {
#       lappend row [getTNS $arr($name)]
      lappend row {N/A}
    }
    $tbl addrow $row
  }
  switch $params(sortby) {
    0 {
      # count
      catch { $tbl sort -integer +1 }
    }
    1 {
      # wns
      catch { $tbl sort -real +3 }
    }
    2 {
      # tns
      catch { $tbl sort -real +4 }
    }
  }
# set tbl_ [$tbl clone]
# $tbl_ sort -real +3
  if {$skip} {
    $tbl addrow [list {...} {...} {...} {...}]
  }
#   puts [$tbl print]
#   set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  # Trim the table by the max number of rows
  $tbl trim $params(maxrows)
#   $tbl_ trim $params(maxrows)
#   set output [concat $output [split [sideBySide [$tbl export -format $params(format)] [$tbl_ export -format $params(format)]] \n] ]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}
# catch {$tbl_ destroy}
}

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

if {$::DEBUG_SHOW_ALL_TABLES} {
  set tbl [::tb::prettyTable {Top-Level Modules Distribution (OrigRefName)}]
  $tbl configure -indent 2
  $tbl header [list {Module} {#} {%} {WNS} {TNS}]
  set L [list]
  catch { unset arr }
  set skip 0
  foreach el [getParam {spOrigRefName epOrigRefName slack}] {
    foreach {sp ep slack} $el {break}
    # Remove last elements of the lists since it is a primitive and not hierarchical module
    # E.g: {obelix_100gtr_top__parameterized3 obelix_100gtr_otl_if_2637 reg_mc_otl_5272 FDCE}
    # The list of hierarchical module is also uniquified for each path so that it is not
    # counted twice if it happens in both the startpoint and endpoint
    set modules [lsort -unique [concat [lindex $sp 0] [lindex $ep 0]] ]
    foreach m $modules {
      # Save slack so that worst slack per module can be retreived
      lappend arr($m) $slack
    }
    lappend L $modules
  }
  set L [getFrequencyDistribution [lflatten $L]]
  foreach el $L {
    foreach {name num} $el { break }
    set row [list $name $num]
    set percent [format {%.2f} [expr 100 * $num / double($nPaths)]]
    # DEBUG
#     if {$percent < 1.0} { incr skip ; continue }
    lappend row $percent
#     lappend row [expr min([join $arr($name) ,])]
#     lappend row [format {%.3f} [expr [join $arr($name) +] ] ]
    lappend row [getWNS $arr($name)]
    if {[catch {lappend row [format {%.3f} [getTNS $arr($name)] ]} errorstring]} {
#       lappend row [getTNS $arr($name)]
      lappend row {N/A}
    }
    $tbl addrow $row
  }
  switch $params(sortby) {
    0 {
      # count
      catch { $tbl sort -integer +1 }
    }
    1 {
      # wns
      catch { $tbl sort -real +3 }
    }
    2 {
      # tns
      catch { $tbl sort -real +4 }
    }
  }
# set tbl_ [$tbl clone]
# $tbl_ sort -real +3
  if {$skip} {
    $tbl addrow [list {...} {...} {...} {...}]
  }
#   puts [$tbl print]
#   set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  # Trim the table by the max number of rows
  $tbl trim $params(maxrows)
#   $tbl_ trim $params(maxrows)
#   set output [concat $output [split [sideBySide [$tbl export -format $params(format)] [$tbl_ export -format $params(format)]] \n] ]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}
# catch {$tbl_ destroy}
}

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

if {$::DEBUG_SHOW_ALL_TABLES} {
  set tbl [::tb::prettyTable {Bottom-Level Modules Distribution}]
  $tbl configure -indent 2
  $tbl header [list {Module} {#} {%} {WNS} {TNS}]
  set L [list]
  catch { unset arr }
  set skip 0
  foreach el [getParam {spRefName epRefName slack}] {
    foreach {sp ep slack} $el {break}
    # Remove last elements of the lists since it is a primitive and not hierarchical module
    # E.g: {obelix_100gtr_top__parameterized3 obelix_100gtr_otl_if_2637 reg_mc_otl_5272 FDCE}
    # The list of hierarchical module is also uniquified for each path so that it is not
    # counted twice if it happens in both the startpoint and endpoint
    set modules [lsort -unique [concat [lindex $sp end-1] [lindex $ep end-1]] ]
    # If all the cells are at the top-level, then $modules is empty
    if {$modules == {}} { continue }
    foreach m $modules {
      # Save slack so that worst slack per module can be retreived
      lappend arr($m) $slack
    }
    lappend L $modules
  }
  set L [getFrequencyDistribution [lflatten $L]]
  foreach el $L {
    foreach {name num} $el { break }
    set row [list $name $num]
    set percent [format {%.2f} [expr 100 * $num / double($nPaths)]]
    # DEBUG
#     if {$percent < 1.0} { incr skip ; continue }
    lappend row $percent
#     lappend row [expr min([join $arr($name) ,])]
#     lappend row [format {%.3f} [expr [join $arr($name) +] ] ]
    lappend row [getWNS $arr($name)]
    if {[catch {lappend row [format {%.3f} [getTNS $arr($name)] ]} errorstring]} {
      lappend row [getTNS $arr($name)]
#       lappend row {N/A}
    }
    $tbl addrow $row
  }
  switch $params(sortby) {
    0 {
      # count
      catch { $tbl sort -integer +1 }
    }
    1 {
      # wns
      catch { $tbl sort -real +3 }
    }
    2 {
      # tns
      catch { $tbl sort -real +4 }
    }
  }
# set tbl_ [$tbl clone]
# $tbl_ sort -real +3
  if {$skip} {
    $tbl addrow [list {...} {...} {...} {...}]
  }
#   puts [$tbl print]
#   set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  # Trim the table by the max number of rows
  $tbl trim $params(maxrows)
#   $tbl_ trim $params(maxrows)
#   set output [concat $output [split [sideBySide [$tbl export -format $params(format)] [$tbl_ export -format $params(format)]] \n] ]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}
# catch {$tbl_ destroy}
}

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

if {$::DEBUG_SHOW_ALL_TABLES} {
  set tbl [::tb::prettyTable {Bottom-Level Modules Distribution (OrigRefName)}]
  $tbl configure -indent 2
  $tbl header [list {Module} {#} {%} {WNS} {TNS}]
  set L [list]
  catch { unset arr }
  set skip 0
  foreach el [getParam {spOrigRefName epOrigRefName slack}] {
    foreach {sp ep slack} $el {break}
    # Remove last elements of the lists since it is a primitive and not hierarchical module
    # E.g: {obelix_100gtr_top__parameterized3 obelix_100gtr_otl_if_2637 reg_mc_otl_5272 FDCE}
    # The list of hierarchical module is also uniquified for each path so that it is not
    # counted twice if it happens in both the startpoint and endpoint
    set modules [lsort -unique [concat [lindex $sp end-1] [lindex $ep end-1]] ]
    # If all the cells are at the top-level, then $modules is empty
    if {$modules == {}} { continue }
    foreach m $modules {
      # Save slack so that worst slack per module can be retreived
      lappend arr($m) $slack
    }
    lappend L $modules
  }
  set L [getFrequencyDistribution [lflatten $L]]
  foreach el $L {
    foreach {name num} $el { break }
    set row [list $name $num]
    set percent [format {%.2f} [expr 100 * $num / double($nPaths)]]
    # DEBUG
#     if {$percent < 1.0} { incr skip ; continue }
    lappend row $percent
#     lappend row [expr min([join $arr($name) ,])]
#     lappend row [format {%.3f} [expr [join $arr($name) +] ] ]
    lappend row [getWNS $arr($name)]
#     lappend row [format {%.3f} [getTNS $arr($name)] ]
    if {[catch {lappend row [format {%.3f} [getTNS $arr($name)] ]} errorstring]} {
      lappend row [getTNS $arr($name)]
#       lappend row {N/A}
    }
    $tbl addrow $row
  }
  switch $params(sortby) {
    0 {
      # count
      catch { $tbl sort -integer +1 }
    }
    1 {
      # wns
      catch { $tbl sort -real +3 }
    }
    2 {
      # tns
      catch { $tbl sort -real +4 }
    }
  }
# set tbl_ [$tbl clone]
# $tbl_ sort -real +3
  if {$skip} {
    $tbl addrow [list {...} {...} {...} {...}]
  }
#   puts [$tbl print]
#   set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  # Trim the table by the max number of rows
  $tbl trim $params(maxrows)
#   $tbl_ trim $params(maxrows)
#   set output [concat $output [split [sideBySide [$tbl export -format $params(format)] [$tbl_ export -format $params(format)]] \n] ]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}
# catch {$tbl_ destroy}
}

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

  proc filter args {
    return [lindex [lindex $args 0] 0]
  }

  set tbl [createTable -title {Top-Level Modules Distribution (Startpoint) (createTable)} \
                       -param {spRefName} \
                       -header [list {Startpoint}] \
                       -refparam {slack} \
                       -refheader {WNS} \
                       -refstats 1 \
                       -percentlimit 1.0 \
                       -maxvalues 10 \
                       -xform filter \
                       ]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

  set tbl [createTable -title {Top-Level Modules Distribution (Endpoint) (createTable)} \
                       -param {epRefName} \
                       -header [list {Endpoint}] \
                       -refparam {slack} \
                       -refheader {WNS} \
                       -refstats 1 \
                       -percentlimit 1.0 \
                       -maxvalues 10 \
                       -xform filter \
                       ]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

  set tbl [createTable -title {Top-Level Modules Distribution (OrigRefName) (Startpoint) (createTable)} \
                       -param {spOrigRefName} \
                       -header [list {Startpoint}] \
                       -refparam {slack} \
                       -refheader {WNS} \
                       -refstats 1 \
                       -percentlimit 1.0 \
                       -maxvalues 10 \
                       -xform filter \
                       ]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

  set tbl [createTable -title {Top-Level Modules Distribution (OrigRefName) (Endpoint) (createTable)} \
                       -param {epOrigRefName} \
                       -header [list {Endpoint}] \
                       -refparam {slack} \
                       -refheader {WNS} \
                       -refstats 1 \
                       -percentlimit 1.0 \
                       -maxvalues 10 \
                       -xform filter \
                       ]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

  proc filter args {
    return [list [lindex [lindex $args 0] 0] [lindex [lindex $args 1] 0]]
  }

  set tbl [createTable -title {Top-Level Modules Distribution (createTable)} \
                       -param {spRefName epRefName} \
                       -header [list {Startpoint} {Endpoint}] \
                       -refparam {slack} \
                       -refheader {WNS} \
                       -refstats 1 \
                       -percentlimit 1.0 \
                       -maxvalues 10 \
                       -xform filter \
                       ]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

  set tbl [createTable -title {Top-Level Modules Distribution (OrigRefName) (createTable)} \
                       -param {spOrigRefName epOrigRefName} \
                       -header [list {Startpoint} {Endpoint}] \
                       -refparam {slack} \
                       -refheader {WNS} \
                       -refstats 1 \
                       -percentlimit 1.0 \
                       -maxvalues 10 \
                       -xform filter \
                       ]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

  proc filter args {
    return [lindex [lindex $args 0] end-1]
  }

  set tbl [createTable -title {Bottom-Level Modules Distribution (Startpoint) (createTable)} \
                       -param {spRefName} \
                       -header [list {Startpoint}] \
                       -refparam {slack} \
                       -refheader {WNS} \
                       -refstats 1 \
                       -percentlimit 1.0 \
                       -maxvalues 10 \
                       -xform filter \
                       ]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

  set tbl [createTable -title {Bottom-Level Modules Distribution (Endpoint) (createTable)} \
                       -param {epRefName} \
                       -header [list {Endpoint}] \
                       -refparam {slack} \
                       -refheader {WNS} \
                       -refstats 1 \
                       -percentlimit 1.0 \
                       -maxvalues 10 \
                       -xform filter \
                       ]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

  set tbl [createTable -title {Bottom-Level Modules Distribution (Startpoint) (OrigRefName) (createTable)} \
                       -param {spOrigRefName} \
                       -header [list {Startpoint}] \
                       -refparam {slack} \
                       -refheader {WNS} \
                       -refstats 1 \
                       -percentlimit 1.0 \
                       -maxvalues 10 \
                       -xform filter \
                       ]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

  set tbl [createTable -title {Bottom-Level Modules Distribution (Endpoint) (OrigRefName) (createTable)} \
                       -param {epOrigRefName} \
                       -header [list {Endpoint}] \
                       -refparam {slack} \
                       -refheader {WNS} \
                       -refstats 1 \
                       -percentlimit 1.0 \
                       -maxvalues 10 \
                       -xform filter \
                       ]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

  proc filter args {
    return [list [lindex [lindex $args 0] end-1] [lindex [lindex $args 1] end-1]]
  }

  set tbl [createTable -title {Bottom-Level Modules Distribution (createTable)} \
                       -param {spRefName epRefName} \
                       -header [list {Startpoint} {Endpoint}] \
                       -refparam {slack} \
                       -refheader {WNS} \
                       -refstats 1 \
                       -percentlimit 1.0 \
                       -maxvalues 10 \
                       -xform filter \
                       ]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

  set tbl [createTable -title {Bottom-Level Modules Distribution (OrigRefName) (createTable)} \
                       -param {spOrigRefName epOrigRefName} \
                       -header [list {Startpoint} {Endpoint}] \
                       -refparam {slack} \
                       -refheader {WNS} \
                       -refstats 1 \
                       -percentlimit 1.0 \
                       -maxvalues 10 \
                       -xform filter \
                       ]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

  set tbl [createTable -title {Clock Region Pairs Distribution (createTable)} \
                       -param {spClockR epClockR} \
                       -header [list {Source} {Destination}] \
                       -refparam {slack} \
                       -refheader {WNS} \
                       -refstats 1 \
                       -percentlimit 1.0 \
                       -maxvalues 10 \
                       ]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

if {$::DEBUG_SHOW_ALL_TABLES} {
  set tbl [::tb::prettyTable {Clock Region Pairs Distribution}]
  $tbl configure -indent 2
  $tbl header [list {Source} {Destination} {#} {%} {WNS} {TNS} {WNS (mean)} {WNS (median)} {Slacks}]
  set L [list]
  catch { unset arr }
  set skip 0
  foreach el [getParam {spClockR epClockR slack}] {
    foreach {spClockR epClockR slack} $el {break}
    lappend arr(${spClockR}:${epClockR}) $slack
    lappend L [list $spClockR $epClockR]
  }
  set L [getFrequencyDistribution $L]
#   set L [getFrequencyDistribution [getParam {srcClk dstClk slack}]]
  foreach el $L {
    foreach {name num} $el { break }
    foreach {spClockR epClockR} $name { break }
    set row [list $spClockR $epClockR $num]
    set percent [format {%.2f} [expr 100 * $num / double($nPaths)]]
    # DEBUG
#     if {$percent < 1.0} { incr skip ; continue }
    lappend row $percent
#     lappend row [expr min([join $arr(${spClockR}:${epClockR}) ,])]
#     lappend row [format {%.3f} [expr [join $arr(${spClockR}:${epClockR}) +] ] ]
#     lappend row [format {%.3f} [mean $arr(${spClockR}:${epClockR})] ]
#     lappend row [format {%.3f} [median $arr(${spClockR}:${epClockR})] ]
#     lappend row [format {%.3f} [stddev $arr(${spClockR}:${epClockR})] ]
#     lappend row [format {%.3f} [sigma $arr(${spClockR}:${epClockR})] ]
#     if {[catch { lappend row [expr min([join $arr(${spClockR}:${epClockR}) ,])] } errorstring]} {}
    if {[catch { lappend row [getWNS $arr(${spClockR}:${epClockR})] } errorstring]} {
      lappend row {N/A}
    }
#     if {[catch { lappend row [format {%.3f} [expr [join $arr(${spClockR}:${epClockR}) +] ] ] } errorstring]} {}
    if {[catch { lappend row [format {%.3f} [getTNS $arr(${spClockR}:${epClockR})]] } errorstring]} {
      lappend row {N/A}
    }
    if {[catch { lappend row [format {%.3f} [mean $arr(${spClockR}:${epClockR})] ] } errorstring]} {
      lappend row {N/A}
    }
    if {[catch { lappend row [format {%.3f} [median $arr(${spClockR}:${epClockR})] ] } errorstring]} {
      lappend row {N/A}
    }
#     if {[catch {  lappend row [format {%.3f} [stddev $arr(${spClockR}:${epClockR})] ] } errorstring]} {
#       lappend row {N/A}
#     }
#     if {[catch { lappend row [format {%.3f} [sigma $arr(${spClockR}:${epClockR})] ] } errorstring]} {
#       lappend row {N/A}
#     }
    if {[catch { set slacks [lsort -real -increasing $arr(${spClockR}:${epClockR}) ] } errorstring]} {
#       set slacks $arr(${spClockR}:${epClockR})
      set slacks {N/A}
    }
#     set slacks [lsort -real -increasing [lslacks $arr(${spClockR}:${epClockR})] ]
    if {[llength $slacks] > 50} { set slacks [concat [lrange $slacks 0 49] {...}] }
    lappend row $slacks
#     lappend row [lsort -real -increasing $arr(${spClockR}:${epClockR}) ]
    $tbl addrow $row
  }
  switch $params(sortby) {
    0 {
      # count
      catch { $tbl sort -integer +2 }
    }
    1 {
      # wns
      catch { $tbl sort -real +4 }
    }
    2 {
      # tns
      catch { $tbl sort -real +5 }
    }
  }
# set tbl_ [$tbl clone]
# $tbl_ sort -real +4
  # Sort by WNS
#   $tbl sort -real +4
  if {$skip} {
    # DEBUG
    $tbl addrow [list {...} {...} {...} {...} {...}]
  }
#   puts [$tbl print]
#   set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  # Trim the table by the max number of rows
  $tbl trim $params(maxrows)
#   $tbl_ trim $params(maxrows)
#   set output [concat $output [split [sideBySide [$tbl export -format $params(format)] [$tbl_ export -format $params(format)]] \n] ]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}
# catch {$tbl_ destroy}
}

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

  if {[llength [get_pblocks -quiet]] > 0} {
    # Only show this table if there are pblocks in the design
    set tbl [createTable -title {PBlocks Pairs Distribution (createTable)} \
                       -param {spPblock epPblock} \
                       -header [list {Source} {Destination}] \
                       -refparam {slack} \
                       -refheader {WNS} \
                       -refstats 1 \
                       -percentlimit 1.0 \
                       -maxvalues 10 \
                       ]
    set output [concat $output [split [$tbl export -format $params(format)] \n] ]
    catch {$tbl destroy}
  }

if {$::DEBUG_SHOW_ALL_TABLES} {
  set tbl [::tb::prettyTable {PBlocks Pairs Distribution}]
  $tbl configure -indent 2
  $tbl header [list {Source} {Destination} {#} {%} {WNS} {TNS} {WNS (mean)} {WNS (median)} {Slacks}]
  set L [list]
  catch { unset arr }
  set skip 0
  foreach el [getParam {spPblock epPblock slack}] {
    foreach {spPblock epPblock slack} $el {break}
    lappend arr(${spPblock}:${epPblock}) $slack
    lappend L [list $spPblock $epPblock]
  }
  set L [getFrequencyDistribution $L]
#   set L [getFrequencyDistribution [getParam {spPblock epPblock slack}]]
  foreach el $L {
    foreach {name num} $el { break }
    foreach {spPblock epPblock} $name { break }
    set row [list $spPblock $epPblock $num]
    set percent [format {%.2f} [expr 100 * $num / double($nPaths)]]
    # DEBUG
#     if {$percent < 1.0} { incr skip ; continue }
    lappend row $percent
#     lappend row [expr min([join $arr(${spClockR}:${epClockR}) ,])]
#     lappend row [format {%.3f} [expr [join $arr(${spClockR}:${epClockR}) +] ] ]
#     lappend row [format {%.3f} [mean $arr(${spClockR}:${epClockR})] ]
#     lappend row [format {%.3f} [median $arr(${spClockR}:${epClockR})] ]
#     lappend row [format {%.3f} [stddev $arr(${spClockR}:${epClockR})] ]
#     lappend row [format {%.3f} [sigma $arr(${spClockR}:${epClockR})] ]
#     if {[catch { lappend row [expr min([join $arr(${spClockR}:${epClockR}) ,])] } errorstring]} {}
    if {[catch { lappend row [getWNS $arr(${spPblock}:${epPblock})] } errorstring]} {
      lappend row {N/A}
    }
#     if {[catch { lappend row [format {%.3f} [expr [join $arr(${spClockR}:${epClockR}) +] ] ] } errorstring]} {}
    if {[catch { lappend row [format {%.3f} [getTNS $arr(${spPblock}:${epPblock})]] } errorstring]} {
      lappend row {N/A}
    }
    if {[catch { lappend row [format {%.3f} [mean $arr(${spPblock}:${epPblock})] ] } errorstring]} {
      lappend row {N/A}
    }
    if {[catch { lappend row [format {%.3f} [median $arr(${spPblock}:${epPblock})] ] } errorstring]} {
      lappend row {N/A}
    }
#     if {[catch {  lappend row [format {%.3f} [stddev $arr(${spClockR}:${epClockR})] ] } errorstring]} {
#       lappend row {N/A}
#     }
#     if {[catch { lappend row [format {%.3f} [sigma $arr(${spClockR}:${epClockR})] ] } errorstring]} {
#       lappend row {N/A}
#     }
    if {[catch { set slacks [lsort -real -increasing $arr(${spPblock}:${epPblock}) ] } errorstring]} {
#       set slacks $arr(${spClockR}:${epClockR})
      set slacks {N/A}
    }
#     set slacks [lsort -real -increasing [lslacks $arr(${spClockR}:${epClockR})] ]
    if {[llength $slacks] > 50} { set slacks [concat [lrange $slacks 0 49] {...}] }
    lappend row $slacks
#     lappend row [lsort -real -increasing $arr(${spClockR}:${epClockR}) ]
    $tbl addrow $row
  }
  switch $params(sortby) {
    0 {
      # count
      catch { $tbl sort -integer +2 }
    }
    1 {
      # wns
      catch { $tbl sort -real +4 }
    }
    2 {
      # tns
      catch { $tbl sort -real +5 }
    }
  }
# set tbl_ [$tbl clone]
# $tbl_ sort -real +4
  # Sort by WNS
#   $tbl sort -real +4
  if {$skip} {
    # DEBUG
    $tbl addrow [list {...} {...} {...} {...} {...}]
  }
#   puts [$tbl print]
#   set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  # Trim the table by the max number of rows
  $tbl trim $params(maxrows)
#   $tbl_ trim $params(maxrows)
#   set output [concat $output [split [sideBySide [$tbl export -format $params(format)] [$tbl_ export -format $params(format)]] \n] ]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}
# catch {$tbl_ destroy}
}

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

#   set tbl [createTable -title {Paths Distribution (createTable)} \
#                        -param {spRefName epRefName} \
#                        -header [list {Startpoint} {Endpoint}] \
#                        -refparam {slack} \
#                        -refheader {WNS} \
#                        -refstats 1 \
#                        -percentlimit 1.0 \
#                        -maxvalues 10 \
#                        ]
#   set output [concat $output [split [$tbl export -format $params(format)] \n] ]
#   catch {$tbl destroy}

  set tbl [createTable -title {Paths Distribution (OrigRefName) (createTable)} \
                       -param {spOrigRefName epOrigRefName} \
                       -header [list {Startpoint} {Endpoint}] \
                       -refparam {slack} \
                       -refheader {WNS} \
                       -refstats 1 \
                       -percentlimit 1.0 \
                       -maxvalues 10 \
                       ]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

if {$::DEBUG_SHOW_ALL_TABLES} {
  set tbl [::tb::prettyTable {Paths Distribution}]
  $tbl configure -indent 2
  $tbl header [list {Path} {Cell} {#} {%} {WNS} {TNS}]
  set L [list]
  catch { unset arr }
  set skip 0
  foreach el [getParam {spRefName epRefName slack}] {
    foreach {sp ep slack} $el {break}
    # Remove last elements of the lists since it is a primitive and not hierarchical module
    # E.g: {obelix_100gtr_top__parameterized3 obelix_100gtr_otl_if_2637 reg_mc_otl_5272 FDCE}
    lappend arr([lrange $sp 0 end]) $slack
    lappend arr([lrange $ep 0 end]) $slack
    lappend L [lrange $sp 0 end]
    lappend L [lrange $ep 0 end]
  }
  set L [getFrequencyDistribution $L]
  foreach el $L {
    foreach {name num} $el { break }
    set row [list [lrange $name 0 end-1] [lindex $name end] $num ]
    # Since both startpoint and endpoint are being taken into account, the
    # number of paths that should be used to compute the percentage is doubled
    set percent [format {%.2f} [expr 100 * $num / (2 * double($nPaths))]]
    # DEBUG
#     if {$percent < 1.0} { incr skip ; continue }
    lappend row $percent
#     lappend row [expr min([join $arr($name) ,])]
#     lappend row [format {%.3f} [expr [join $arr($name) +] ] ]
    lappend row [getWNS $arr($name)]
#     lappend row [format {%.3f} [getTNS $arr($name)] ]
    if {[catch {lappend row [format {%.3f} [getTNS $arr($name)] ]} errorstring]} {
      lappend row [getTNS $arr($name)]
    }
    $tbl addrow $row
  }
  switch $params(sortby) {
    0 {
      # count
      catch { $tbl sort -integer +2 }
    }
    1 {
      # wns
      catch { $tbl sort -real +4 }
    }
    2 {
      # tns
      catch { $tbl sort -real +5 }
    }
  }
# set tbl_ [$tbl clone]
# $tbl_ sort -real +4
  if {$skip} {
    $tbl addrow [list {...} {...} {...} {...} {...}]
  }
#   puts [$tbl print]
#   set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  # Trim the table by the max number of rows
  $tbl trim $params(maxrows)
#   $tbl_ trim $params(maxrows)
#   set output [concat $output [split [sideBySide [$tbl export -format $params(format)] [$tbl_ export -format $params(format)]] \n] ]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}
# catch {$tbl_ destroy}
}

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

if {$::DEBUG_SHOW_ALL_TABLES} {
  set tbl [::tb::prettyTable {Paths Distribution (OrigRefName)}]
  $tbl configure -indent 2
  $tbl header [list {Path} {Cell} {#} {%} {WNS} {TNS}]
  set L [list]
  catch { unset arr }
  set skip 0
  foreach el [getParam {spOrigRefName epOrigRefName slack}] {
    foreach {sp ep slack} $el {break}
    # Remove last elements of the lists since it is a primitive and not hierarchical module
    # E.g: {obelix_100gtr_top__parameterized3 obelix_100gtr_otl_if_2637 reg_mc_otl_5272 FDCE}
    lappend arr([lrange $sp 0 end]) $slack
    lappend arr([lrange $ep 0 end]) $slack
    lappend L [lrange $sp 0 end]
    lappend L [lrange $ep 0 end]
  }
  set L [getFrequencyDistribution $L]
  foreach el $L {
    foreach {name num} $el { break }
    set row [list [lrange $name 0 end-1] [lindex $name end] $num ]
    # Since both startpoint and endpoint are being taken into account, the
    # number of paths that should be used to compute the percentage is doubled
    set percent [format {%.2f} [expr 100 * $num / (2 * double($nPaths))]]
    # DEBUG
#     if {$percent < 1.0} { incr skip ; continue }
    lappend row $percent
#     lappend row [expr min([join $arr($name) ,])]
#     lappend row [format {%.3f} [expr [join $arr($name) +] ] ]
    lappend row [getWNS $arr($name)]
#     lappend row [format {%.3f} [getTNS $arr($name)] ]
    if {[catch {lappend row [format {%.3f} [getTNS $arr($name)] ]} errorstring]} {
      lappend row [getTNS $arr($name)]
    }
    $tbl addrow $row
  }
  switch $params(sortby) {
    0 {
      # count
      catch { $tbl sort -integer +2 }
    }
    1 {
      # wns
      catch { $tbl sort -real +4 }
    }
    2 {
      # tns
      catch { $tbl sort -real +5 }
    }
  }
# set tbl_ [$tbl clone]
# $tbl_ sort -real +4
  if {$skip} {
    $tbl addrow [list {...} {...} {...} {...} {...}]
  }
#   puts [$tbl print]
#   set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  # Trim the table by the max number of rows
  $tbl trim $params(maxrows)
#   $tbl_ trim $params(maxrows)
#   set output [concat $output [split [sideBySide [$tbl export -format $params(format)] [$tbl_ export -format $params(format)]] \n] ]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}
# catch {$tbl_ destroy}
}

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

  set tbl [::tb::prettyTable {Instances Distribution}]
  $tbl configure -indent 2
  $tbl header [list {Instance} {Cell} {#} {%} {WNS} {TNS} {Slacks} ]
  set L1 [list]
  catch { unset arr }
  # Iterate for each path to prevent uniquification for same cells
  # by get_cells across all paths
  foreach path $paths slack [getParam {slack}] {
#     set L1 [concat $L1 [get_property -quiet NAME [get_cells -of $path]]]
    set cells [get_cells -of $path]
    set L1 [concat $L1 $cells]
    foreach cell $cells {
      lappend arr($cell) $slack
    }
  }
  set nPrimitives1 [llength $L1]
  set L1 [getFrequencyDistribution $L1]
  foreach el1 $L1 {
    foreach {name1 num1} $el1 { break }
    if {$num1 == 1} {
      # Do not report instances that appear only once across all the paths
      continue
    }
    set row [list $name1 [get_property -quiet REF_NAME $name1] ]
    lappend row $num1
    lappend row [format {%.2f} [expr 100 * $num1 / double($nPrimitives1)]]
#     lappend row [expr min([join $arr($name1) ,])]
#     lappend row [format {%.3f} [expr [join $arr($name1) +] ] ]
    lappend row [getWNS $arr($name1)]
#     lappend row [format {%.3f} [getTNS $arr($name1)] ]
    if {[catch {lappend row [format {%.3f} [getTNS $arr($name1)] ]} errorstring]} {
      lappend row [getTNS $arr($name1)]
    }
    set slacks [lsort -real -increasing $arr($name1) ]
    if {[llength $slacks] > 50} { set slacks [concat [lrange $slacks 0 49] {...}] }
    lappend row $slacks
    $tbl addrow $row
  }
  switch $params(sortby) {
    0 {
      # count
      catch { $tbl sort -integer +2 }
    }
    1 {
      # wns
      catch { $tbl sort -real +4 }
    }
    2 {
      # tns
      catch { $tbl sort -real +5 }
    }
  }
#   # Sort by WNS
#   $tbl sort -real +4
#   puts [$tbl print]
  # Trim the table by the max number of rows
  $tbl trim $params(maxrows)
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

  ########################################################################################
  ##
  ##
  ##
  ########################################################################################

  if {$params(debug)} {
    parray pathObj
    parray pathData
  }

  set stopTime [clock seconds]
  puts "  report_path_analysis done in [expr $stopTime - $startTime] seconds"

  if {$filename != {}} {
    set FH [open $filename {w}]
    puts $FH "# -------------------------------------------------------------------"
    puts $FH [format {# Created on %s with report_path_analysis} [clock format [clock seconds]] ]
    puts $FH "# -------------------------------------------------------------------\n"
    puts $FH [join $output \n]
    close $FH
    puts " -I- Generated file [file normalize $filename]"
    return -code ok
  }

  if {$returnstring} {
    return [join $output \n]
  } else {
    puts [join $output \n]
  }
  return -code ok
}

proc ::tb::utils::report_path_analysis::reportPathSummary { minPathNum maxPathNum } {
  variable pathObj
  variable pathData
  variable params
  variable output
  # Create table
  set tbl [::tb::prettyTable {Path Summary}]
  $tbl configure -indent 2
  $tbl header $pathData(HEADER)
  # Loop through all paths
  for {set idx $minPathNum} {$idx <= $maxPathNum} {incr idx} {
    catch {unset arr}
    set row [list]
    dputs "<$pathData($idx)>"
    array set arr $pathData($idx)
    array set arr $arr(primitive)
    array set arr $arr(ckRegion)
    catch { array set arr $arr(pblock) }
    catch { array set arr $arr(slr) }
    foreach el $pathData(COLS) {
      lappend row $arr($el)
    }
    set obj $pathObj($idx)
    set obj $arr(timing_path)
    dputs "<timing_path:[get_property -quiet ENDPOINT_CLOCK $obj]>"
    dputs "<row><$row>"
    $tbl addrow $row
  }

#   switch $params(sortby) {
#     0 {
#       # count
#       # There is no count column in this table. So keep the tab le as-is
#     }
#     1 {
#       # wns
#       catch { $tbl sort -real +2 }
#     }
#     2 {
#       # tns
#       # There is no tns column in this table. So keep the tab le as-is
#     }
#   }
  # Always sort by slack
  catch { $tbl sort -real +2 }

#   puts [$tbl print]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

  return -code ok
}

# Transfor proc that can be applied to all partial rows of a table
proc ::tb::utils::report_path_analysis::xform {args} { return $args }

# Transfor proc that can be applied to all partial rows of a table
# lflatten0: trick to convert strings "{lcpclk_pll[0]}" as "lcpclk_pll[0]"
# proc ::tb::utils::report_path_analysis::xform {args} { return [lflatten0 $args] }

proc ::tb::utils::report_path_analysis::createTable {args} {
  variable pathObj
  variable pathData
  variable params
  set defaults [list -title {} -header {} -param {} -percentlimit 1.0 -maxvalues 10 -divider $params(numpaths) -maxrows $params(maxrows) -refparam {} -refheader {} -sortbyref $params(sortby) -refstats 0 -xform {::tb::utils::report_path_analysis::xform}]
  array set options $defaults
  array set options $args

  if {$options(-refparam) == {}} {
    set tbl [::tb::prettyTable $options(-title)]
    $tbl configure -indent 2
    set options(-header) [linsert $options(-header) end {#} {%} ]
    $tbl header $options(-header)
    set L [list]
    foreach el [getParam $options(-param)] {
#       if {$el == {}} { continue }
      # Enable transformation to be applied to rows (only to the param section)
      if {$options(-xform) != {}} {
        set el [eval $options(-xform) $el]
      }
      lappend L $el
    }
    set L [getFrequencyDistribution $L]
#     set L [getFrequencyDistribution [getParam $options(-param)]]
    foreach el $L {
      foreach {name num} $el { break }
      set row $name
      lappend row $num
      lappend row [format {%.2f} [expr 100 * $num / double($options(-divider))]]
      $tbl addrow $row
    }
    $tbl trim $options(-maxrows)
    return $tbl
  }

  set tbl [::tb::prettyTable $options(-title)]
  $tbl configure -indent 2
  if {$options(-refheader) == {WNS}} {
    set options(-header) [linsert $options(-header) end {#} {%} {WNS} {TNS} ]
  } else {
    set options(-header) [linsert $options(-header) end {#} {%} $options(-refheader) "$options(-refheader) (sum)" ]
  }
#   set options(-header) [linsert $options(-header) end {#} {%} $options(-refheader) "$options(-refheader) (sum)" ]
  if {$options(-refstats)} {
#     set options(-header) [linsert $options(-header) end "$options(-refheader) (mean)" "$options(-refheader) (median)" "$options(-refheader) (stddev)" "$options(-refheader) (sigma)" "$options(-refheader) (values)" ]
    set options(-header) [linsert $options(-header) end "$options(-refheader) (mean)" "$options(-refheader) (median)" "$options(-refheader) (values)" ]
  }
  $tbl header $options(-header)
  set L [list]
  catch { unset arr }
  set skip 0
  foreach el [getParam [concat $options(-param) $options(-refparam)]] {
    # The values for the params are: [lrange $el 0 end-1]
    # The value for refparam is: [lindex $el end]
    if {$el == {}} { continue }
#     lappend arr([lrange $el 0 end-1]) [lindex $el end]
#     lappend L [lrange $el 0 end-1]
    # Enable transformation to be applied to rows (only to the param section)
    if {$options(-xform) != {}} {
      set key [eval $options(-xform) [lrange $el 0 end-1]]
    } else {
      set key [lrange $el 0 end-1]
    }
    lappend arr($key) [lindex $el end]
    lappend L $key
  }
  set L [getFrequencyDistribution $L]
  foreach el $L {
    foreach {name num} $el { break }
    set row $name
    lappend row $num
    set percent [format {%.2f} [expr 100 * $num / double($options(-divider))]]
    # DEBUG
#     if {$percent < $options(-percentlimit)} { incr skip ; continue }
    lappend row $percent
#     lappend row [expr min([join $arr($name) ,])]
#     if {[catch { lappend row [expr min([join $arr($name) ,])] } errorstring]} {}
    if {$options(-refheader) == {WNS}} {
      if {[catch { lappend row [getWNS $arr($name)] } errorstring]} {
        lappend row {N/A}
      }
    } else {
      if {[catch { lappend row [expr min([join $arr($name) ,])] } errorstring]} {
        lappend row {N/A}
      }
    }
    if {$options(-refheader) == {WNS}} {
#       if {[catch { lappend row [format {%.3f} [expr [join [-lslack $arr($name)] +] ] ] } errorstring]} {}
      if {[catch { lappend row [format {%.3f} [getTNS $arr($name)] ] } errorstring]} {
        lappend row {N/A}
      }
    } else {
      if {[catch { lappend row [format {%.3f} [expr [join $arr($name) +] ] ] } errorstring]} {
        lappend row {N/A}
      }
    }
#     if {[catch { lappend row [format {%.3f} [expr [join $arr($name) +] ] ] } errorstring]} {
#       lappend row {N/A}
#     }
    if {[catch { lappend row [format {%.3f} [mean $arr($name)] ] } errorstring]} {
      lappend row {N/A}
    }
    if {[catch { lappend row [format {%.3f} [median $arr($name)] ] } errorstring]} {
      lappend row {N/A}
    }
#     if {[catch {  lappend row [format {%.3f} [stddev $arr($name)] ] } errorstring]} {
#       lappend row {N/A}
#     }
#     if {[catch { lappend row [format {%.3f} [sigma $arr($name)] ] } errorstring]} {
#       lappend row {N/A}
#     }
#     lappend row [format {%.3f} [mean $arr($name)] ]
#     lappend row [format {%.3f} [median $arr($name)] ]
#     lappend row [format {%.3f} [stddev $arr($name)] ]
#     lappend row [format {%.3f} [sigma $arr($name)] ]
    if {[catch {set values [lsort -real -increasing $arr($name) ]} errorstring]} {
      # If the values are alphanumeric, just report the list as-is, without sorting
      set values $arr($name)
#       set values [lsort -dictionary -increasing $arr($name)
    }
    # Only report the '$options(-maxvalues)' first value(s)
    if {[llength $values] > $options(-maxvalues)} { set values [concat [lrange $values 0 [expr $options(-maxvalues) -1]] {...}] }
    lappend row $values
    $tbl addrow $row
  }
  switch $options(-sortbyref) {
    1 {
      # Sort by the reference param
      # '+2' to account for the "#' and '%' columns
      catch { $tbl sort -real +[expr [llength $options(-param)] +2] }
    }
    2 {
      # Sort by the reference param sum
      # '+3' to account for the "#' and '%' columns and reference param column
      catch { $tbl sort -real +[expr [llength $options(-param)] +3] }
    }
    default {
    }
  }
#   if {$options(-sortbyref)} {
#     # Sort by the reference param
#     # '+2' to account for the "#' and '%' columns
#     $tbl sort -real +[expr [llength $options(-param)] +2]
#   }
#   if {$skip} {
#     # DEBUG
#     set row [list]
#     # '+2' to account for the "#' and '%' columns
#     for {set i 0} {$i < [expr [llength $options(-param)] +2]} {incr i} {
#       lappend row {...}
#     }
#     # For the column of the refparam
#     lappend row {...}
#     if {$options(-refstats)} {
# #       set row [linsert $row end {...} {...} {...} {...} {...}]
#       set row [linsert $row end {...} {...} {...}]
#     }
#     $tbl addrow $row
#   }
  $tbl trim $options(-maxrows)
  return $tbl
}



proc ::tb::utils::report_path_analysis::buildPathData {paths {analysis {setup}}} {
  variable pathObj
  variable pathData
  variable params
  set checkSLR 0
  set checkPblock 0
#   set properties [list srcClk dstClk slack req skew dpDly dpReq c2q tsh uncertainty pessimism lvls maxFO accFO spType epType spPblock epPblock #pblocked #pblock primitive ckRegion path locs exception corner delay startPoint endPoint ]
  set properties [list srcClk dstClk slack req skew dpDly dpReq c2q tsh uncertainty pessimism lvls maxFO accFO spType epType spPinType epPinType primitive ckRegion path loc exception corner delay startPointPin endPointPin startPoint endPoint ]
  # Other properties to extract but not to add the the summary table
  set properties [concat $properties [list spRefName epRefName spOrigRefName epOrigRefName ]]
  set slrRef [get_slrs -quiet]
  if {[llength $slrRef] > 1} {
    lappend properties slr
    set checkSLR 1
  }
  set allPblocks [get_pblocks -quiet]
  if {[llength $allPblocks] > 0} {
    lappend properties pblock
    set checkPblock 1
  }
  # Build the header
  set header [list]
  set columns [list]
  foreach el [list srcClk dstClk slack req skew dpDly dpReq c2q tsh uncertainty pessimism lvls maxFO accFO spType epType ] {
    switch $el {
      tsh {
        if {$analysis == {setup}} {
          lappend header {setup}
        } else {
          lappend header {hold}
        }
      }
      default {
        lappend header $el
      }
    }
#     lappend header $el
    lappend columns $el
  }
  if {$checkPblock} {
    foreach el [list spPblock epPblock #pblocked #pblock ] {
      lappend header $el
      lappend columns $el
    }
  }
  if {$checkSLR} {
    foreach el [lsort $slrRef ] {
      lappend header $el
      lappend columns $el
    }
  }
  foreach el [list LUT CARRY MUX FD SRL LUTRAM RAMB DSP CLK GT PCIE IO ILKN OTHER] {
    lappend header $el
    lappend columns $el
  }
  foreach el [list spClockR epClockR #clockR clockR path startPointPin endPointPin loc exception corner delay startPoint endPoint ] {
    lappend header $el
    lappend columns $el
  }
  # Other properties to extract but not to add the the summary table
  foreach el [list spRefName epRefName spOrigRefName epOrigRefName ] {
#     lappend header $el
#     lappend columns $el
  }
  dputs "<header><$header>"
  # Loop through all paths
  catch {unset pathObj}
  catch {unset pathData}
  set pathData(HEADER) $header
  set pathData(COLS) $columns
  for {set idx 0} {$idx < [llength $paths]} {incr idx} {
    set path [lindex $paths $idx]
    set data [getPathInfo $path $properties]
    # Save timing path object
    lappend data {timing_path}
    lappend data $path
    set pathObj($idx) $path
    set pathData($idx) $data
    dputs "<$data>"
  }
  set pathData(@) [llength $paths]
  set pathData(OBJS) $paths
  return -code ok
}

proc ::tb::utils::report_path_analysis::getPathInfo {path props} {
  array set primTable [list BUFG CLK BUFGCTRL CLK BUFH CLK CARRY4 CARRY CARRY8 CARRY DSP48E1 DSP FDCE FD FDPE FD FDRE FD FDRS FD FDSE FD FIFO18E1 RAMB FIFO36E1 RAMB FRAME_ECCE2 OTHER GND OTHER GTHE2_COMMON GT GTHE2_CHANNEL GT GTXE2_CHANNEL GT GTXE2_COMMON GT GTPE2_CHANNEL GT IBUF IO IBUFDS IO IBUFDS_GTE2 IO ICAPE2 OTHER IDELAYCTRL IO IDELAYE2 IO IN_FIFO IO IOBUF CLK ISERDESE2 IO LUT1 LUT LUT2 LUT LUT3 LUT LUT4 LUT LUT5 LUT LUT6 LUT LUT6_2 LUT MMCME2_ADV CLK MUXF7 MUX MUXF8 MUX OBUF IO OBUFDS_DUAL_BUF IO IDDR IO ODDR IO OSERDESE2 IO OUT_FIFO IO PCIE_2_1 PCIE PCIE_3_0 PCIE PHASER_IN IO PHASER_OUT_PHY IO PHASER_REF IO PHY_CONTROL IO IBUFCTRL IO BITSLICE_CONTROL IO PLLE2_ADV CLK RAM128X1S LUTRAM RAM32M LUTRAM RAM32X1D LUTRAM RAM32X1S LUTRAM RAM64M LUTRAM RAM64X1D LUTRAM RAM64X1S LUTRAM RAMB18E1 RAMB RAMB36E1 RAMB ROM128X1 LUTRAM ROM256X1 LUTRAM SRLC16E SRL SRL16E SRL SRLC32E SRL VCC OTHER XADC OTHER RAMD64E LUTRAM RAMD64E LUTRAM RAMD32 LUTRAM RAMS32 LUTRAM RAMS64E LUTRAM ]
  # Some more entries for UltraScale
  array set primTable [list DSP48E2 DSP PCIE_3_1 PCIE FIFO18E2 RAMB FIFO36E2 RAMB RAMB18E2 RAMB RAMB36E2 RAMB GTHE3_CHANNEL GT GTXE3_CHANNEL GT GTXE3_COMMON GT GTPE3_CHANNEL GT RXTX_BITSLICE IO ILKN ILKN ]
  array set primTable [list CMAC OTHER ]
  array set primTable [list DSP_A_B_DATA DSP DSP_ALU DSP DSP_C_DATA DSP DSP_MULTIPLIER DSP DSP_M_DATA DSP DSP_OUTPUT DSP DSP_PREADD DSP DSP_PREADD_DATA DSP ]
  # Some more entries for UltraScale Plus
  array set primTable [list CMACE4 OTHER ILKNE4 ILKN PCIE40E4 PCIE ]
  array set primTable [list BUFGCE CLK INBUF CLK OBUFT CLK ISERDESE3 IO OSERDESE3 IO GTYE4_CHANNEL GT GTYE4_COMMON GT GTHE4_CHANNEL GT GTHE4_COMMON GT ]
  set primRef [list LUT CARRY MUX FD SRL LUTRAM RAMB DSP CLK GT PCIE IO ILKN OTHER]
  set slrRef  [get_slrs -quiet]

  set spPin [get_property -quiet STARTPOINT_PIN $path]
  set spCell [get_cells -quiet -of $spPin]
  set epPin [get_property -quiet ENDPOINT_PIN $path]
  set epCell [get_cells -quiet -of $epPin]


  if {([lsearch $props {maxFO}] != -1) || ([lsearch $props {accFO}] != -1)} {
    set netFanout {}
    foreach net [get_nets -quiet -of_objects $path] {
      lappend netFanout [expr [get_property -quiet FLAT_PIN_COUNT $net] - 1]
    }
  }

  if {[lsearch $props {pblock}] != -1} {
    set pblocks [list]
    foreach cell [get_cells -quiet -of $path] {
      set pb [get_pblocks -quiet -of $cell]
      if {$pb != {}} { lappend pblocks $pb }
    }
  }

  if {([lsearch $props {dpReq}] != -1) || ([lsearch $props {c2q}] != -1) || ([lsearch $props {tsh}] != -1)} {
    set analysisType [get_property -quiet DELAY_TYPE $path]
    set multipleCkToQArcsMatching 0
    set multipleSetupHoldArcsMatching 0
    # Extract the CLK->Q delay
# puts "<STARTPOINT_PIN:[get_property STARTPOINT_PIN $path]><ENDPOINT_PIN:[get_property ENDPOINT_PIN $path]>"
    set clkToQDly {}
    switch $analysisType {
      max {
        # Setup
        set arc [get_timing_arcs -quiet -from $spPin -to [lindex [get_pins -quiet -of $path] 0] -filter {TYPE == {Reg Clk to Q}}]
        if {[llength $arc] > 1} {
          incr multipleCkToQArcsMatching
          puts "Warning - [llength $arc] arcs matching for CLK->Q ([get_property -quiet STARTPOINT_PIN $path] -> [get_property -quiet ENDPOINT_PIN $path])"
        }
        # In the scenario of multiple arcs matching, keep highest delay. The 'catch' covers the case
        # when no arc is returned
        catch { set clkToQDly [expr max([join [get_property -quiet DELAY_MAX_RISE $arc] ,])] }
        if {$clkToQDly == {}} {
          # If no value for RISE, let's try with FALL
          catch { set clkToQDly [expr max([join [get_property -quiet DELAY_MAX_FALL $arc] ,])] }
        }
      }
      min {
        # Hold
        set arc [get_timing_arcs -quiet -from $spPin -to [lindex [get_pins -quiet -of $path] 0] -filter {TYPE == {Reg Clk to Q}}]
        if {[llength $arc] > 1} {
          incr multipleCkToQArcsMatching
          puts "Warning - [llength $arc] arcs matching for CLK->Q ([get_property -quiet STARTPOINT_PIN $path] -> [get_property -quiet ENDPOINT_PIN $path])"
        }
        # In the scenario of multiple arcs matching, keep highest delay. The 'catch' covers the case
        # when no arc is returned
        catch { set clkToQDly [expr max([join [get_property -quiet DELAY_MIN_RISE $arc] ,])] }
        if {$clkToQDly == {}} {
          # If no value for RISE, let's try with FALL
          catch { set clkToQDly [expr max([join [get_property -quiet DELAY_MIN_FALL $arc] ,])] }
        }
      }
      default {
      }
    }
    if {$clkToQDly == {}} {
# puts "<clkToQDly><STARTPOINT_PIN:[get_property STARTPOINT_PIN $path]><ENDPOINT_PIN:[get_property ENDPOINT_PIN $path]>"
    }
    # Safety net:
    if {$clkToQDly == {}} { set clkToQDly 0.0 }

    # Extract the setup/hold delay
    set setupHoldDly {}
    switch $analysisType {
      max {
        # Setup
        set arc [get_timing_arcs -quiet -to $epPin -filter {TYPE == setup || TYPE == SETUP || TYPE == recovery || TYPE == RECOVERY}]
        if {[llength $arc] > 1} {
          incr multipleSetupHoldArcsMatching
          puts "Warning - [llength $arc] arcs matching for Setup/Recovery ([get_property -quiet STARTPOINT_PIN $path] -> [get_property -quiet ENDPOINT_PIN $path])"
        }
        # In the scenario of multiple arcs matching, keep highest delay. The 'catch' covers the case
        # when no arc is returned
        catch { set setupHoldDly [expr max([join [get_property -quiet DELAY_MAX_RISE $arc] ,])] }
        if {$setupHoldDly == {}} {
          # If no value for RISE, let's try with FALL
          catch { set setupHoldDly [expr max([join [get_property -quiet DELAY_MAX_FALL $arc] ,])] }
        }
      }
      min {
        # Hold
        set arc [get_timing_arcs -to $epPin -filter {TYPE == hold || TYPE == HOLD || TYPE == removal || TYPE == REMOVAL}]
        if {[llength $arc] > 1} {
          incr multipleSetupHoldArcsMatching
          puts "Warning - [llength $arc] arcs matching for Hold/Removal ([get_property -quiet STARTPOINT_PIN $path] -> [get_property -quiet ENDPOINT_PIN $path])"
        }
        # In the scenario of multiple arcs matching, keep highest delay. The 'catch' covers the case
        # when no arc is returned
        catch { set setupHoldDly [expr max([join [get_property -quiet DELAY_MIN_RISE $arc] ,])] }
        if {$setupHoldDly == {}} {
          # If no value for RISE, let's try with FALL
          catch { set setupHoldDly [expr max([join [get_property -quiet DELAY_MIN_FALL $arc] ,])] }
        }
      }
      default {
      }
    }
    if {$setupHoldDly == {}} {
# puts "<setupHoldDly><STARTPOINT_PIN:[get_property STARTPOINT_PIN $path]><ENDPOINT_PIN:[get_property ENDPOINT_PIN $path]>"
    }
    # Safety net:
    if {$setupHoldDly == {}} { set setupHoldDly 0.0 }

    # Calculate the datapath requirement: REQUIREMENT + SKEW - CLK->Q - SETUP + HOLD
    switch $analysisType {
      max {
        # Setup
        set datapathRequirement [format {%.3f} [expr [get_property -quiet REQUIREMENT $path] + [get_property -quiet SKEW $path] - $clkToQDly - $setupHoldDly] ]
      }
      min {
        # Hold
        set datapathRequirement [format {%.3f} [expr [get_property -quiet REQUIREMENT $path] + [get_property -quiet SKEW $path] - $clkToQDly + $setupHoldDly] ]
      }
      default {
      }
    }
  }

  set result [list]

  foreach prop $props {
    lappend result $prop
    switch $prop {
      srcClk {
        lappend result [get_property -quiet STARTPOINT_CLOCK $path]
      }
      dstClk {
        lappend result [get_property -quiet ENDPOINT_CLOCK $path]
      }
      slack {
        lappend result [get_property -quiet SLACK $path]
      }
      req {
        lappend result [get_property -quiet REQUIREMENT $path]
      }
      skew {
        lappend result [get_property -quiet SKEW $path]
      }
      dpDly {
        lappend result [get_property -quiet DATAPATH_DELAY $path]
      }
      dpReq {
        if {$multipleCkToQArcsMatching || $multipleSetupHoldArcsMatching} {
          lappend result [format {%s (*)} $datapathRequirement]
        } else {
          lappend result $datapathRequirement
        }
      }
      c2q {
        if {$multipleCkToQArcsMatching} {
          lappend result [format {%s (*)} $clkToQDly]
        } else {
          lappend result $clkToQDly
        }
      }
      tsh {
        # Setup/Hold delay
        if {$multipleSetupHoldArcsMatching} {
          lappend result [format {%s (*)} $setupHoldDly]
        } else {
          lappend result $setupHoldDly
        }
      }
      uncertainty {
        lappend result [get_property -quiet UNCERTAINTY $path]
      }
      pessimism {
        lappend result [get_property -quiet CLOCK_PESSIMISM $path]
      }
      lvls {
        lappend result [get_property -quiet LOGIC_LEVELS $path]
      }
      maxFO {
        lappend result [lindex [lsort -increasing -integer $netFanout] end]
      }
      accFO {
        lappend result [expr [join $netFanout +]]
      }
      spType {
        set cellType [get_property -quiet REF_NAME $spCell ]
        if {$cellType == {}} { set cellType {<PORT>} }
        lappend result $cellType
      }
      epType {
        set cellType [get_property -quiet REF_NAME $epCell ]
        if {$cellType == {}} { set cellType {<PORT>} }
        lappend result $cellType
      }
      spPinType {
        set cellType [get_property -quiet REF_NAME $spCell ]
        if {$cellType == {}} {
          set pinType {<PORT>}
        } else {
          # Most likely a clock pin, so no need to check for a bus name
          set pinType [format {%s/%s} $cellType [get_property -quiet REF_PIN_NAME $spPin ] ]
        }
        lappend result $pinType
      }
      epPinType {
        set cellType [get_property -quiet REF_NAME $epCell ]
        if {$cellType == {}} {
          set pinType {<PORT>}
        } else {
          # Check whether enpoint pin is a bus or not
          set pinBusName [get_property -quiet BUS_NAME $epPin]
          if {$pinBusName == {}} {
            # The endpoint pin is not part of a bus
            set pinType [format {%s/%s} $cellType [get_property -quiet REF_PIN_NAME $epPin ] ]
          } else {
            # The endpoint pin is part of a bus
            set pinType [format {%s/%s[*]} $cellType $pinBusName]
          }
#           set pinType [format {%s/%s} $cellType [get_property -quiet REF_PIN_NAME $epPin ] ]
        }
        lappend result $pinType
      }
      prim -
      primitive {
        set L [list]
        foreach ref $primRef { set refCnt($ref) 0 }
        foreach cell [get_cells -quiet -of $path] {
          set cellRef [get_property -quiet REF_NAME $cell]
          if {![info exist primTable($cellRef)]} {
            puts "Warning - unsupported REF_NAME $cellRef for statistics purpose"
          } else {
            incr refCnt($primTable($cellRef))
          }
        }
        foreach ref $primRef {
          lappend L $ref
          lappend L $refCnt($ref)
        }
        lappend result $L
      }
      slr {
        set slrRef [lsort [get_slrs -quiet]]
        foreach slr $slrRef { set slrCnt($slr) 0 }
        foreach cell [get_cells -quiet -of $path] {
          set slr [get_slrs -quiet -of $cell]
          if {$slr != ""} { incr slrCnt($slr) }
        }
        set L [list]
        foreach slr $slrRef {
          lappend L $slr
          lappend L $slrCnt($slr)
        }
        lappend result $L
      }
      pblock {
        set L [list]
        lappend L {spPblock}
        lappend L [get_pblocks -quiet -of $spCell]
        lappend L {epPblock}
        lappend L [get_pblocks -quiet -of $epCell]
        lappend L {#pblocked}
        lappend L [llength $pblocks]
        lappend L {#pblock}
        set uniq [lsort -unique $pblocks]
        if {$uniq == {}} {
          lappend L 0
        } else {
          lappend L [llength $uniq]
        }
        lappend result $L
      }
      ckRegion {
        set L [list]
        lappend L {spClockR}
#         lappend L [get_property -quiet CLOCK_REGION [get_sites -quiet [get_property -quiet SITE $spCell] ] ]
        lappend L [get_clock_regions -quiet -of $spCell]
        lappend L {epClockR}
#         lappend L [get_property -quiet CLOCK_REGION [get_sites -quiet [get_property -quiet SITE $epCell] ] ]
        lappend L [get_clock_regions -quiet -of $epCell]
        lappend L {#clockR}
        set clockR [lsort [get_clock_regions -quiet -of [get_cells -quiet -of $path ]]]
#         lappend L [llength [lsort -unique [get_property -quiet CLOCK_REGION [get_sites -quiet [get_property -quiet SITE [get_cells -quiet -of $path ]] ] ] ] ]
        lappend L [llength $clockR ]
        lappend L {clockR}
        lappend L $clockR
        lappend result $L
      }
      spClockR {
        lappend result [get_property -quiet CLOCK_REGION [get_sites -quiet [get_property -quiet SITE $spCell] ] ]
      }
      epClockR {
        lappend result [get_property -quiet CLOCK_REGION [get_sites -quiet [get_property -quiet SITE $epCell] ] ]
      }
      #clockR {
#         lappend result [llength [lsort -unique [get_property -quiet CLOCK_REGION [get_sites -quiet [get_property -quiet SITE [get_cells -quiet -of $path ]] ] ] ] ]
        lappend result [llength [get_clock_regions -quiet -of [get_cells -quiet -of $path ]] ]
      }
      clockR {
        lappend result [lsort [get_clock_regions -quiet -of [get_cells -quiet -of $path ]] ]
      }
      path {
        lappend result [get_property -quiet REF_NAME [get_cells -quiet -of $path]]
      }
      loc -
      locs {
        lappend result [get_property -quiet LOC [get_cells -quiet -of $path]]
      }
      exception {
        lappend result [get_property -quiet EXCEPTION $path]
      }
      corner {
        lappend result [get_property -quiet CORNER $path]
      }
      delay {
        lappend result [get_property -quiet DELAY_TYPE $path]
      }
      spPin -
      startPoint {
        lappend result $spPin
      }
      epPin -
      endPoint {
        lappend result $epPin
      }
      startPointPin {
        # Format: <leafInstanceName>/<refPinName>
        lappend result [join [lrange [split $spPin \/] end-1 end] \/]
      }
      endPointPin {
        # Format: <leafInstanceName>/<refPinName>
        lappend result [join [lrange [split $epPin \/] end-1 end] \/]
      }
      spCell {
        lappend result $spCell
      }
      epCell {
        lappend result $epCell
      }
      spRefName {
        if {$spCell != {}} {
          lappend result [splitHierPath $spCell ref_name]
        } else {
          lappend result {<PORT>}
        }
      }
      epRefName {
        if {$epCell != {}} {
          lappend result [splitHierPath $epCell ref_name]
        } else {
          lappend result {<PORT>}
        }
      }
      spOrigRefName {
        if {$spCell != {}} {
          lappend result [splitHierPath $spCell orig_ref_name]
        } else {
          lappend result {<PORT>}
        }
      }
      epOrigRefName {
        if {$epCell != {}} {
          lappend result [splitHierPath $epCell orig_ref_name]
        } else {
          lappend result {<PORT>}
        }
      }
      default {
        puts "WARNING - unknown property $prop"
        lappend result {}
      }
    }
  }

  return $result
}

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

proc ::tb::utils::report_path_analysis::splitHierPath {name {mode {}}} {
  set name [lindex $name 0]
  set cell [get_cell -quiet $name]
  # Check cell before pin
  if {$cell == {}} {
    set pin [get_pins -quiet $name]
    if {$pin != {}} {
      # If a pin is specified as input, then keep track of the pin name
      # to build the first string that will be pushed on the lists
      set cell [get_cell -of $pin]
      set pin [get_property -quiet REF_PIN_NAME $pin]
    } else {
      set port [get_ports -quiet $name]
      if {$port != {}} {
        return {<PORT>}
      } else {
        puts " -E- $name does not match a cell, a pin or a port"
        return [list]
      }
    }
  } else {
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

# Example:
#   getFrequencyDistribution [list clk_out2_pll_clrx_2 clk_out2_pll_lnrx_3 clk_out2_pll_lnrx_3 ]
# => {clk_out2_pll_lnrx_3 2} {clk_out2_pll_clrx_2 1}
proc ::tb::utils::report_path_analysis::getFrequencyDistribution {L} {
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

proc ::tb::utils::report_path_analysis::getParam {props {idx -1}} {
  variable pathData
  variable params
  if {$idx == -1} {
    # Return the param from all the paths
    set res [list]
#     set nPaths [expr [llength [array names pathData]] -3]
    set nPaths $pathData(@)
    if {$nPaths == 0} {
      return {}
    }
    for {set idx 0} {$idx < $nPaths} {incr idx} {
      catch {unset arr}
      array set arr $pathData($idx)
      # Expand some property groups
      catch { array set arr $arr(primitive) }
      catch { array set arr $arr(ckRegion) }
      catch { array set arr $arr(pblock) }
      catch { array set arr $arr(slr) }
      set L [list]
      foreach prop $props {
        if {![info exists arr($prop)]} {
          puts " -W- invalid param '$prop' (idx=$idx)"
          lappend L {}
        } else {
          lappend L $arr($prop)
        }
      }
      lappend res $L
    }
    if {[llength $props] == 1} {
      # If only 1 parameter is requested, flatten 1st level to prevent a list-of-a-list
      set res [lflatten0 $res]
    }
    return $res
  } else {
    if {![info exists pathData($idx)]} {
      puts " -W- invalid index : idx = $idx"
      return {}
    }
    array set arr $pathData($idx)
    set L [list]
    foreach prop $props {
      if {![info exists arr($prop)]} {
        puts " -W- invalid param : param = $prop"
        lappend L {}
      } else {
        lappend L $arr($prop)
      }
    }
    lappend res $L
    if {[llength $props] == 1} {
      # If only 1 parameter is requested, flatten 1st level to prevent a list-of-a-list
      set res [lflatten0 $res]
    }
    return $res
  }
}

proc ::tb::utils::report_path_analysis::sideBySide {args} {
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

proc ::tb::utils::report_path_analysis::lfilter {L script} {
  set res {}
  foreach e $L {
    if {$e == {}} {
      # Filter infinite slacks
      continue
    }
    if {[uplevel 1 $script $e]} {lappend res $e}
  }
  set res
}

proc ::tb::utils::report_path_analysis::lslack {L} {
  # Return all the valid slacks in the list (exclude infinite slack)
  return [lfilter $L {regexp {^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$} } ]
}

proc ::tb::utils::report_path_analysis::+lslack {L} {
  # Return all the positive slacks in the list
  return [lfilter $L {regexp {^[+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$} } ]
}

proc ::tb::utils::report_path_analysis::-lslack {L} {
  # Return all the negative slacks in the list
  return [lfilter $L {regexp {^-[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$} } ]
}

proc ::tb::utils::report_path_analysis::filterNegSlacks {L} {
  set res [-lslack $L]
  if {$res == {}} { set res 0.0 }
  return $res
}

proc ::tb::utils::report_path_analysis::getTNS {L} {
  set res [-lslack $L]
#   if {$res == {}} { return 0.0 }
  if {$res == {}} { return {N/A} }
  # Return sum of all negative slacks
#   return [expr [join $res +] ]
  if {[catch { set res [expr [join $res +] ] } errorstring]} {
    dputs "::tb::utils::report_path_analysis::getTNS - $errorstring"
    return {N/A}
  }
  return $res
}

proc ::tb::utils::report_path_analysis::getWNS {L} {
  # Get all the slacks (filter out infinite slacks)
  set L [lslack $L]
  if {$L == {}} { return {N/A} }
  # Return the min value of all slacks
#   return [expr min([join $L ,])]
  if {[catch {set res [expr min([join $L ,])] } errorstring]} {
    dputs "::tb::utils::report_path_analysis::getWNS - $errorstring"
    return {N/A}
  }
  return $res
}

proc ::tb::utils::report_path_analysis::lflatten {data} {
  # Flatten all levels
  while { $data != [set data [join $data]] } { }
  return $data
}

proc ::tb::utils::report_path_analysis::lflatten0 {data} {
  # Flatten only 1st level
  return [set data [join $data]]
}

proc ::tb::utils::report_path_analysis::dputs {args} {
  variable params
  if {$params(debug)} {
    puts $args
  }
  return -code ok
}

proc ::tb::utils::report_path_analysis::sigma {L} {
  if {[catch {
    # More efficient to build list before using concat...
    foreach {sum sum2} [SumSum2 $L] {}
    set N [llength $L]
    set mean [expr $sum / $N]
    if {$N == 1} {
      return {-Inf}
    }
    set sigma2 [expr ($sum2 - $mean*$mean*$N) / ($N-1)]
    return [expr sqrt($sigma2) ]
  } errorstring]} {
#     return {-0.0}
    return {N/A}
  }
}

## A helper function...
## Note that this is the heart of why the improved versions are better
## since it allows you to only make a single pass through the data.
proc ::tb::utils::report_path_analysis::SumSum2 {L} {
  set sum  0.0
  set sum2 0.0
  foreach x $L {
    set sum  [expr $sum  + $x ]
    set sum2 [expr $sum2 + $x*$x ]
  }
  list $sum $sum2
}

proc ::tb::utils::report_path_analysis::median {l} {
  if {[set len [llength $l]] % 2} then {
    return [lindex [lsort -real $l] [expr {($len - 1) / 2}]]
  } else {
    return [expr {([lindex [set sl [lsort -real $l]] [expr {($len / 2) - 1}]] \
                   + [lindex $sl [expr {$len / 2}]]) / 2.0}]
  }
}

proc ::tb::utils::report_path_analysis::mean {L} {
  set sum 0.0
  set N [ llength $L ]
  foreach val $L {
    set sum [ expr $sum + $val ]
  }
  set mean [ expr $sum / $N ]
  set mean
}

proc ::tb::utils::report_path_analysis::lavg L {expr ([join $L +])/[llength $L].}

# mean square
proc ::tb::utils::report_path_analysis::mean2 L {
  set sum 0
  foreach i $L {set sum [expr {$sum+$i*$i}]}
  expr {double($sum)/[llength $L]}
}

# standard deviation
proc ::tb::utils::report_path_analysis::stddev L {
  if {[catch {
    set m [lavg $L]
    return [expr {sqrt([mean2 $L]-$m*$m)}]
  } errorstring]} {
    return {N/A}
#     return {-0.0}
  }
}

#------------------------------------------------------------------------
# ::tb::utils::report_path_analysis::debug
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
#------------------------------------------------------------------------
proc ::tb::utils::report_path_analysis::debug {body} {
  variable params
  if {$params(debug)} {
    uplevel 1 [list eval $body]
  }
  return -code ok
}

namespace eval ::tb::utils {
  namespace import -force ::tb::utils::report_path_analysis::report_path_analysis
}

namespace eval ::tb {
  namespace import -force ::tb::utils::report_path_analysis
}

#------------------------------------------------------------------------
# ::tb::prettyTable::method:trim
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Adding new method to prettyTable to trim a table by the number of rows
#------------------------------------------------------------------------
proc ::tb::prettyTable::method:trim {self max} {
  # Trim the table
  upvar #0 ${self}::header header
  upvar #0 ${self}::table table
  upvar #0 ${self}::params params
  if {[subst $${self}::numRows] <=  $max} {
    return 0
  }
  eval set ${self}::table [list [lrange [subst $${self}::table] 0 [expr $max -1] ] ]
  set row [list]
  foreach el [subst $${self}::header] {
    lappend row {...}
  }
  eval lappend ${self}::table [list $row]
  eval set ${self}::numRows $max
  return 0
}

  ########################################################################################
  ##
  ## EXAMPLE CODE
  ##
  ########################################################################################

if {0} {

  ########################################################################################
  ##
  ## Example 1
  ##
  ########################################################################################

  +-----------------------------+
  | Source Clock Distribution   |
  +---------------+-----+-------+
  | Source Clock  | #   | %     |
  +---------------+-----+-------+
  | pmarx_7_clock | 71  | 19.45 |
  | pmarx_8_clock | 45  | 12.33 |
  | pmarx_9_clock | 44  | 12.05 |
  | pmarx_1_clock | 35  | 9.59  |
  | pmarx_6_clock | 33  | 9.04  |
  | pmarx_4_clock | 24  | 6.58  |
  | pmarx_0_clock | 23  | 6.30  |
  | pmatx_9_clock | 15  | 4.11  |
  | xpl2_refclk   | 15  | 4.11  |
  | pmatx_2_clock | 14  | 3.84  |
  | ...           | ... | ...   |
  +---------------+-----+-------+

  set tbl [createTable -title {Source Clock Distribution} \
                       -param {srcClk} \
                       -header [list {Source Clock}] \
                       ]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

  ########################################################################################

  set tbl [::tb::prettyTable {Source Clock Distribution}]
  $tbl configure -indent 2
  $tbl header [list {Name} {#} {%}]
  set L [getFrequencyDistribution [getParam srcClk]]
  foreach el $L {
    foreach {name num} $el { break }
    set row [list $name $num]
    lappend row [format {%.2f} [expr 100 * $num / double($nPaths)]]
    $tbl addrow $row
  }
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

  ########################################################################################
  ##
  ## Example 2
  ##
  ########################################################################################

  +---------------------------------------------+
  | Clock Pair Distribution                     |
  +---------------+---------------+-----+-------+
  | Source        | Destination   | #   | %     |
  +---------------+---------------+-----+-------+
  | pmarx_7_clock | pmarx_7_clock | 71  | 19.45 |
  | pmarx_8_clock | pmarx_8_clock | 45  | 12.33 |
  | pmarx_9_clock | pmarx_9_clock | 44  | 12.05 |
  | pmarx_1_clock | pmarx_1_clock | 35  | 9.59  |
  | pmarx_6_clock | pmarx_6_clock | 33  | 9.04  |
  | pmarx_4_clock | pmarx_4_clock | 24  | 6.58  |
  | pmarx_0_clock | pmarx_0_clock | 23  | 6.30  |
  | pmatx_9_clock | pmatx_9_clock | 15  | 4.11  |
  | xpl2_refclk   | xpl2_refclk   | 15  | 4.11  |
  | pmatx_2_clock | pmatx_2_clock | 14  | 3.84  |
  | ...           | ...           | ... | ...   |
  +---------------+---------------+-----+-------+

  set tbl [createTable -title {Clock Pair Distribution} \
                       -param {srcClk dstClk} \
                       -header [list {Source} {Destination}] \
                       ]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

  ########################################################################################

  set tbl [::tb::prettyTable {Clock Pair Distribution}]
  $tbl configure -indent 2
  $tbl header [list {Source} {Destination} {#} {%}]
  set L [getFrequencyDistribution [getParam {srcClk dstClk}]]
  foreach el $L {
    foreach {name num} $el { break }
    foreach {srcClk dstClk} $name { break }
    set row [list $srcClk $dstClk $num]
    lappend row [format {%.2f} [expr 100 * $num / double($nPaths)]]
    $tbl addrow $row
  }
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

  ########################################################################################
  ##
  ## Example 3
  ##
  ########################################################################################

  +----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
  | Clock Pair Distribution                                                                                                                                                                            |
  +---------------+---------------+-----+-------+--------+--------+------------+--------------+--------------+-------------+---------------------------------------------------------------------------+
  | Source        | Destination   | #   | %     | WNS    | TNS    | WNS (mean) | WNS (median) | WNS (stddev) | WNS (sigma) | WNS (values)                                                              |
  +---------------+---------------+-----+-------+--------+--------+------------+--------------+--------------+-------------+---------------------------------------------------------------------------+
  | pmarx_7_clock | pmarx_7_clock | 71  | 19.45 | -0.545 | -6.854 | -0.097     | -0.072       | N/A          | N/A         | -0.545 -0.186 -0.183 -0.183 -0.182 -0.182 -0.180 -0.180 -0.180 -0.180 ... |
  | pmarx_6_clock | pmarx_6_clock | 33  | 9.04  | -0.204 | -2.953 | -0.089     | -0.044       | N/A          | N/A         | -0.204 -0.195 -0.191 -0.189 -0.185 -0.174 -0.174 -0.174 -0.174 -0.166 ... |
  | pmarx_4_clock | pmarx_4_clock | 24  | 6.58  | -0.211 | -2.918 | -0.122     | -0.117       | N/A          | N/A         | -0.211 -0.203 -0.202 -0.202 -0.202 -0.202 -0.199 -0.196 -0.171 -0.153 ... |
  | pmarx_8_clock | pmarx_8_clock | 45  | 12.33 | -0.218 | -2.534 | -0.056     | -0.035       | N/A          | N/A         | -0.218 -0.205 -0.205 -0.205 -0.189 -0.165 -0.139 -0.111 -0.072 -0.062 ... |
  | pmarx_1_clock | pmarx_1_clock | 35  | 9.59  | -0.228 | -2.147 | -0.061     | -0.054       | N/A          | N/A         | -0.228 -0.200 -0.198 -0.117 -0.099 -0.083 -0.083 -0.083 -0.083 -0.079 ... |
  | pmatx_9_clock | pmatx_9_clock | 15  | 4.11  | -0.197 | -1.638 | -0.109     | -0.078       | N/A          | N/A         | -0.197 -0.197 -0.197 -0.197 -0.172 -0.169 -0.117 -0.078 -0.071 -0.047 ... |
  | pmarx_9_clock | pmarx_9_clock | 44  | 12.05 | -0.175 | -1.537 | -0.035     | -0.027       | N/A          | N/A         | -0.175 -0.129 -0.103 -0.093 -0.074 -0.072 -0.056 -0.051 -0.045 -0.045 ... |
  | xpl2_refclk   | xpl2_refclk   | 15  | 4.11  | -0.195 | -1.369 | -0.091     | -0.081       | N/A          | N/A         | -0.195 -0.186 -0.185 -0.168 -0.139 -0.134 -0.105 -0.081 -0.065 -0.030 ... |
  | pmatx_2_clock | pmatx_2_clock | 14  | 3.84  | -0.206 | -0.908 | -0.065     | -0.050       | N/A          | N/A         | -0.206 -0.131 -0.111 -0.095 -0.085 -0.069 -0.067 -0.033 -0.024 -0.023 ... |
  | be2_0_refclk  | be2_0_refclk  | 8   | 2.19  | -0.155 | -0.756 | -0.094     | -0.072       | N/A          | N/A         | -0.155 -0.155 -0.146 -0.076 -0.068 -0.059 -0.055 -0.042                   |
  | ...           | ...           | ... | ...   | ...    | ...    | ...        | ...          | ...          | ...         | ...                                                                       |
  +---------------+---------------+-----+-------+--------+--------+------------+--------------+--------------+-------------+---------------------------------------------------------------------------+

  set tbl [createTable -title {Clock Pair Distribution} \
                       -param {srcClk dstClk} \
                       -header [list {Source} {Destination}] \
                       -refparam {slack} \
                       -refheader {WNS} \
                       -refstats 1 \
                       -percentlimit 1.0 \
                       -maxvalues 10 \
                      ]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

  ########################################################################################

  set tbl [::tb::prettyTable {Clock Pair Distribution}]
  $tbl configure -indent 2
  $tbl header [list {Source} {Destination} {#} {%} {WNS} {TNS}]
  set L [list]
  catch { unset arr }
  foreach el [getParam {srcClk dstClk slack}] {
    foreach {srcClk dstClk slack} $el {break}
    lappend arr(${srcClk}:${dstClk}) $slack
    lappend L [list $srcClk $dstClk]
  }
  set L [getFrequencyDistribution $L]
  foreach el $L {
    foreach {name num} $el { break }
    foreach {srcClk dstClk} $name { break }
    set row [list $srcClk $dstClk $num]
    lappend row [format {%.2f} [expr 100 * $num / double($nPaths)]]
    lappend row [expr min([join $arr(${srcClk}:${dstClk}) ,])]
    lappend row [format {%.3f} [expr [join $arr(${srcClk}:${dstClk}) +] ] ]
    $tbl addrow $row
  }
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

  ########################################################################################
  ##
  ## Example 4
  ##
  ########################################################################################

  +-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
  | Clock Region Pairs Distribution                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
  +--------+-------------+-----+-------+--------+--------+------------+--------------+--------------+-------------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
  | Source | Destination | #   | %     | WNS    | TNS    | WNS (mean) | WNS (median) | WNS (stddev) | WNS (sigma) | Slacks                                                                                                                                                                                                                                                                                                                                                            |
  +--------+-------------+-----+-------+--------+--------+------------+--------------+--------------+-------------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
  | X0Y3   | X0Y3        | 89  | 24.38 | -0.205 | -7.333 | -0.082     | -0.052       | N/A          | N/A         | -0.205 -0.205 -0.205 -0.191 -0.186 -0.185 -0.183 -0.183 -0.182 -0.180 -0.180 -0.180 -0.180 -0.167 -0.166 -0.166 -0.166 -0.165 -0.156 -0.155 -0.154 -0.146 -0.136 -0.133 -0.132 -0.131 -0.129 -0.126 -0.113 -0.106 -0.103 -0.093 -0.090 -0.085 -0.082 -0.075 -0.074 -0.072 -0.072 -0.067 -0.062 -0.057 -0.056 -0.056 -0.052 -0.052 -0.051 -0.045 -0.044 -0.040 ... |
  | X0Y5   | X0Y5        | 43  | 11.78 | -0.211 | -4.733 | -0.110     | -0.094       | N/A          | N/A         | -0.211 -0.203 -0.202 -0.202 -0.202 -0.202 -0.199 -0.197 -0.197 -0.197 -0.197 -0.196 -0.172 -0.171 -0.169 -0.153 -0.144 -0.139 -0.117 -0.116 -0.094 -0.094 -0.094 -0.094 -0.084 -0.078 -0.071 -0.058 -0.052 -0.049 -0.047 -0.047 -0.046 -0.046 -0.042 -0.038 -0.033 -0.020 -0.018 -0.015 -0.011 -0.010 -0.006                                                      |
  | X0Y7   | X0Y7        | 43  | 11.78 | -0.206 | -2.560 | -0.060     | -0.039       | N/A          | N/A         | -0.206 -0.157 -0.136 -0.136 -0.131 -0.119 -0.117 -0.115 -0.111 -0.099 -0.095 -0.085 -0.079 -0.078 -0.075 -0.072 -0.069 -0.067 -0.054 -0.054 -0.039 -0.039 -0.039 -0.038 -0.037 -0.036 -0.033 -0.032 -0.026 -0.024 -0.023 -0.021 -0.018 -0.014 -0.014 -0.013 -0.012 -0.012 -0.012 -0.011 -0.007 -0.004 -0.001                                                      |
  | X0Y2   | X0Y2        | 22  | 6.03  | -0.218 | -1.406 | -0.064     | -0.045       | N/A          | N/A         | -0.218 -0.189 -0.165 -0.139 -0.111 -0.062 -0.059 -0.058 -0.052 -0.049 -0.045 -0.045 -0.044 -0.042 -0.041 -0.031 -0.020 -0.016 -0.010 -0.006 -0.003 -0.001                                                                                                                                                                                                         |
  | X0Y8   | X0Y7        | 26  | 7.12  | -0.228 | -1.367 | -0.053     | -0.021       | N/A          | N/A         | -0.228 -0.200 -0.198 -0.083 -0.083 -0.083 -0.083 -0.056 -0.056 -0.056 -0.056 -0.041 -0.021 -0.021 -0.018 -0.013 -0.013 -0.013 -0.013 -0.005 -0.005 -0.005 -0.005 -0.005 -0.005 -0.002                                                                                                                                                                             |
  | X0Y9   | X0Y9        | 14  | 3.84  | -0.215 | -1.028 | -0.073     | -0.059       | N/A          | N/A         | -0.215 -0.163 -0.124 -0.123 -0.070 -0.065 -0.061 -0.057 -0.046 -0.034 -0.023 -0.018 -0.017 -0.012                                                                                                                                                                                                                                                                 |
  | X0Y4   | X0Y4        | 18  | 4.93  | -0.18  | -0.925 | -0.051     | -0.036       | N/A          | N/A         | -0.180 -0.153 -0.143 -0.091 -0.064 -0.044 -0.039 -0.039 -0.037 -0.035 -0.029 -0.026 -0.015 -0.009 -0.007 -0.006 -0.004 -0.004                                                                                                                                                                                                                                     |
  | X0Y2   | X0Y3        | 7   | 1.92  | -0.182 | -0.865 | -0.124     | -0.127       | N/A          | N/A         | -0.182 -0.175 -0.127 -0.127 -0.110 -0.072 -0.072                                                                                                                                                                                                                                                                                                                  |
  | X0Y6   | X0Y6        | 11  | 3.01  | -0.153 | -0.860 | -0.078     | -0.071       | N/A          | N/A         | -0.153 -0.141 -0.112 -0.092 -0.071 -0.071 -0.071 -0.071 -0.056 -0.019 -0.003                                                                                                                                                                                                                                                                                      |
  | X0Y3   | X0Y4        | 6   | 1.64  | -0.204 | -0.784 | -0.131     | -0.174       | N/A          | N/A         | -0.204 -0.195 -0.189 -0.159 -0.023 -0.014                                                                                                                                                                                                                                                                                                                         |
  | ...    | ...         | ... | ...   | ...    | ...    | ...        | ...          | ...          | ...         | ...                                                                                                                                                                                                                                                                                                                                                               |
  +--------+-------------+-----+-------+--------+--------+------------+--------------+--------------+-------------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+

  set tbl [createTable -title {Clock Region Pairs Distribution} \
                       -param {spClockR epClockR} \
                       -header [list {Source} {Destination}] \
                       -refparam {slack} \
                       -refheader {WNS} \
                       -refstats 1 \
                       -percentlimit 1.0 \
                       -maxvalues 10 \
                       ]
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

  ########################################################################################

  set tbl [::tb::prettyTable {Clock Region Pairs Distribution}]
  $tbl configure -indent 2
  $tbl header [list {Source} {Destination} {#} {%} {WNS} {TNS} {WNS (mean)} {WNS (median)} {WNS (stddev)} {WNS (sigma)} {Slacks}]
  set L [list]
  catch { unset arr }
  set skip 0
  foreach el [getParam {spClockR epClockR slack}] {
    foreach {spClockR epClockR slack} $el {break}
    lappend arr(${spClockR}:${epClockR}) $slack
    lappend L [list $spClockR $epClockR]
  }
  set L [getFrequencyDistribution $L]
  foreach el $L {
    foreach {name num} $el { break }
    foreach {spClockR epClockR} $name { break }
    set row [list $spClockR $epClockR $num]
    set percent [format {%.2f} [expr 100 * $num / double($nPaths)]]
    # DEBUG
#     if {$percent < 1.0} { incr skip ; continue }
    lappend row $percent
    if {[catch { lappend row [expr min([join $arr(${spClockR}:${epClockR}) ,])] } errorstring]} {
      lappend row {N/A}
    }
    if {[catch { lappend row [format {%.3f} [expr [join $arr(${spClockR}:${epClockR}) +] ] ] } errorstring]} {
      lappend row {N/A}
    }
    if {[catch { lappend row [format {%.3f} [mean $arr(${spClockR}:${epClockR})] ] } errorstring]} {
      lappend row {N/A}
    }
    if {[catch { lappend row [format {%.3f} [median $arr(${spClockR}:${epClockR})] ] } errorstring]} {
      lappend row {N/A}
    }
    if {[catch {  lappend row [format {%.3f} [stddev $arr(${spClockR}:${epClockR})] ] } errorstring]} {
      lappend row {N/A}
    }
    if {[catch { lappend row [format {%.3f} [sigma $arr(${spClockR}:${epClockR})] ] } errorstring]} {
      lappend row {N/A}
    }
    set slacks [lsort -real -increasing $arr(${spClockR}:${epClockR}) ]
    if {[llength $slacks] > 50} { set slacks [concat [lrange $slacks 0 49] {...}] }
    lappend row $slacks
#     lappend row [lsort -real -increasing $arr(${spClockR}:${epClockR}) ]
    $tbl addrow $row
  }
  switch $params(sortby) {
    0 {
      # count
      catch { $tbl sort -integer +2 }
    }
    1 {
      # wns
      catch { $tbl sort -real +4 }
    }
    2 {
      # tns
      catch { $tbl sort -real +5 }
    }
  }
  if {$skip} {
    # DEBUG
    $tbl addrow [list {...} {...} {...} {...} {...}]
  }
  # Trim the table by the max number of rows
  $tbl trim $params(maxrows)
  set output [concat $output [split [$tbl export -format $params(format)] \n] ]
  catch {$tbl destroy}

}

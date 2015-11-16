####################################################################################################
# HEADER_BEGIN
# COPYRIGHT NOTICE
# Copyright 2001-2013 Xilinx Inc. All Rights Reserved.
# http://www.xilinx.com/support
# HEADER_END
####################################################################################################

########################################################################################
##
## Company:        Xilinx, Inc.
## Created by:     David Pefourque
##
## Version:        05/23/2014
## Tool Version:   Vivado 2014.1
##
########################################################################################

########################################################################################
## 05/23/2014 - Initial release
########################################################################################

namespace eval ::report_net_loads {
  namespace export report_net_loads
}

namespace import ::report_net_loads::*

# Trick to silence the linter
eval [list namespace eval ::report_net_loads::report_net_loads {
  variable version {05/23/2014}
} ]

proc ::report_net_loads::report_net_loads { args } {
  # Summary :
  # Argument Usage:
  # Return Value:

  #-------------------------------------------------------
  # Process command line arguments
  #-------------------------------------------------------
  set error 0
  set verbose 0
  set filename {}
  set mode {w}
  set FH {}
  set netName {*}
  set netType {all}
  set summaryOnly 0
  set includeClockDomains 0
  set returnString 0
  set minFanout 0
  set maxFanout 1000000
  set thresholdFanout 250
  set help 0
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      -net -
      -{^-n(et?)?$} {
        set netName [lshift args]
      }
      -type -
      -{^-t(y(pe?)?)?$} {
        set netType [lshift args]
      }
      -summary -
      {^-s(u(m(m(a(ry?)?)?)?)?)?$} {
        set summaryOnly 1
      }
      -include_clock_domains -
      {^-i(n(c(l(u(d(e(_(c(l(o(c(k(_(d(o(m(a(i(ns?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?$} {
        set includeClockDomains 1
      }
      -min_fanout -
      {^-mi(n(_(f(a(n(o(ut?)?)?)?)?)?)?)?$} {
        set minFanout [lshift args]
      }
      -max_fanout -
      {^-ma(x(_(f(a(n(o(ut?)?)?)?)?)?)?)?$} {
        set maxFanout [lshift args]
      }
      -threshold -
      {^-t(h(r(e(s(h(o(ld?)?)?)?)?)?)?)?$} {
        set thresholdFanout [lshift args]
      }
      -file -
      {^-f(i(le?)?)?$} {
           set filename [lshift args]
           if {$filename == {}} {
             puts " -E- no filename specified."
             incr error
           }
      }
      -append -
      {^-a(p(p(e(nd?)?)?)?)?$} {
           set mode {a}
      }
      -verbose -
      {^-v(e(r(b(o(se?)?)?)?)?)?$} {
           set verbose 1
      }
      -return_string -
      {^-r(e(t(u(r(n(_(s(t(r(i(ng?)?)?)?)?)?)?)?)?)?)?)?$} {
           set returnString 1
      }
      -help -
      {^-h(e(lp?)?)?$} {
           set help 1
      }
      ^--version$ {
           variable version
           return $version
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
  Usage: report_net_loads
              [-net <net>]             - Net name
              [-type <name>]           - Net type (SIGNAL|CLOCK|ALL)
                                         Default: ALL
              [-summary]               - Generate net summary table only
              [-include_clock_domains] - Include the clock domains to the report
              [-max_fanout <int>]      - Max fanout limit for nets to be considered
                                         Default: 1000000
              [-min_fanout <int>]      - Min fanout limit for nets to be considered
                                         Default: 0
              [-threshold <int>]       - Max fanout limit for nets to get detailed report
                                         Default: 250
              [-file]                  - Report file name
              [-append]                - Append to file
              [-verbose]               - Verbose mode
              [-return_string]         - Return report as string
              [-help|-h]               - This help message

  Description: Generates a Net Loads Report

     This command creates a net load report. All nets matching a type or name pattern 
     are discovered. The fanout, driver and loads are captured. A unique list of load
     cells is generated. Each unique cell is searched for in the netload cells list.

  Example:
     report_net_loads -type clock
     report_net_loads -net [get_selected_objects] -verbose -include_clock_domains
     report_net_loads -net *reset* -summary -include_clock_domains -file my_report.rpt 
} ]
    # HELP -->
    return {}
  }

  if {![regexp {^[0-9]+$} $thresholdFanout]} {
    puts " -E- invalid -threshold value. Should be an integer"
    incr error
  }

  if {![regexp {^[0-9]+$} $maxFanout]} {
    puts " -E- invalid -max_fanout value. Should be an integer"
    incr error
  }

  if {![regexp {^[0-9]+$} $minFanout]} {
    puts " -E- invalid -min_fanout value. Should be an integer"
    incr error
  }
  switch [string toupper $netType] {
    SIGNAL -
    CLOCK -
    ALL {
      set netType [string toupper $netType]
    }
    default {
      puts " -E- invalid net type '$netType'. The valid values are: clock | signal | all"
      incr error
    }
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  set start [clock seconds]
  set systemTime [clock seconds]
  set netCount 0
  set allNets [list]
  set output [list]
  set tableSummary [Table::Create]
  set table [Table::Create]

  switch $netType {
    ALL {
      set allNets [lsort -dictionary [get_nets -quiet -top_net_of_hierarchical_group -hierarchical -filter "NAME=~$netName && (FLAT_PIN_COUNT>$minFanout && FLAT_PIN_COUNT<$maxFanout) && (TYPE!=POWER && TYPE!=GROUND)"]]
    }
    default {
      set allNets [lsort -dictionary [get_nets -quiet -top_net_of_hierarchical_group -hierarchical -filter "(NAME=~$netName) && (FLAT_PIN_COUNT>$minFanout && FLAT_PIN_COUNT<$maxFanout) && (TYPE=~*$netType*)"]]
    }
  }
  set allPinCounts [get_property -quiet FLAT_PIN_COUNT $allNets]

#   lappend output "There are [llength $allNets] nets"
  puts "Processing [llength $allNets] nets ..."

  # Define the summary table of all the nets
  $tableSummary reset
  $tableSummary title {Net(s) Summary}
  if {$includeClockDomains} {
    $tableSummary header [list {Index} {Net Name} {Driver Ref} {Fanout} {Driver Pin} {Unique Loads} {Clock Domain Driver Pin} {Clock Domain Load Pins} {Clock Domain Driver Cell} {Clock Domain Load Cells} ]
  } else {
    $tableSummary header [list {Index} {Net Name} {Driver Ref} {Fanout} {Driver Pin} {Unique Loads} ]
  }

  foreach net $allNets pinCount $allPinCounts {
    # Progress bar
#     progressBar $netCount [llength $allNets]

    set netPins [get_pins -quiet -of $net -leaf]
    set driverPin [filter -quiet $netPins {DIRECTION==OUT}]
    if {$driverPin == {}} {
      set driverPin [get_ports -quiet -of $net -filter {DIRECTION==IN}]
      set driverCell $driverPin
      set driverRef {<PORT>}
      # When the driver is a port, it is not included inside the FLAT_PIN_COUNT property, so
      # it should not be removed from the fanout calculation
      set netFan $pinCount
    } else {
      set driverCell [get_cells -quiet -of $driverPin]
      set driverRef [get_property -quiet REF_NAME $driverCell]
      # Remove the driver from the fanout calculation
      set netFan [expr $pinCount -1]
    }
    set netLoadPins [filter -quiet $netPins {DIRECTION==IN}]
    set netLoadCells [get_cells -quiet -of_objects $netLoadPins]

    if {$netLoadPins == {}} {
      # No leaf pin load (i.e. net connected to output port)
      continue
    }

    if {($netFan > $maxFanout) || ($netFan < $minFanout)} {
      # Skip nets that do not fit the fanout condition from the detailed report
      continue
    }

    incr netCount

    # Update the summary table
    if {$includeClockDomains} {
      $tableSummary addrow [list $netCount \
                             $net \
                             $driverRef \
                             $netFan \
                             $driverPin \
                             [lsort -unique [get_property -quiet REF_NAME $netLoadCells]] \
                             [lsort [get_clocks -quiet -of_objects $driverPin]] \
                             [lsort [get_clocks -quiet -of_objects $netLoadPins]] \
                             [lsort [get_clocks -quiet -of_objects $driverCell]] \
                             [lsort [get_clocks -quiet -of_objects $netLoadCells]] \
                       ]
    } else {
      $tableSummary addrow [list $netCount \
                             $net \
                             $driverRef \
                             $netFan \
                             $driverPin \
                             [lsort -unique [get_property -quiet REF_NAME $netLoadCells]] \
                       ]
    }

    if {$summaryOnly} {
      # Skip detailed reports and process next net
      continue
    }

    if {$netFan > $thresholdFanout} {
      # Skip nets that do not fit the fanout condition from the detailed report
      if {$verbose} {
        lappend output [format "\n(%-d) %-7s %-s **SKIPPED (fanout=$netFan)** " ${netCount} {Net:} $net]
      }
      continue
    }

    # Tcl list for the list of all the loads so that it can be sorted out
    set nonClockPinloads [list]
    set clockPinloads [list]
    # Tcl associative array to extract the list of count per unique load
    catch {unset uniqueClockPinLoads}
    catch {unset uniqueNonClockPinLoads}
    if {$verbose} {
      # In verbose mode, some extra processing is done to be able to generate the
      # detailed tables. Since this is runtime intensive, only run this code in
      # this mode
      foreach pin $netLoadPins isClock [get_property -quiet {IS_CLOCK} $netLoadPins] {
        set libcell [get_property -quiet REF_NAME [get_cells -quiet -of $pin] ]
        if {$isClock} {
          if {![info exists uniqueClockPinLoads($libcell)]} { set uniqueClockPinLoads($libcell) 0 }
          incr uniqueClockPinLoads($libcell) 1
          lappend clockPinloads [list $pin $libcell]
        } else {
          if {![info exists uniqueNonClockPinLoads($libcell)]} { set uniqueNonClockPinLoads($libcell) 0 }
          incr uniqueNonClockPinLoads($libcell) 1
          lappend nonClockPinloads [list $pin $libcell]
        }
      }
      # Sort 'clockPinloads' and 'nonClockPinloads' first on the cell name
      set clockPinloads [lsort -dictionary -index 0 $clockPinloads]
      set nonClockPinloads [lsort -dictionary -index 0 $nonClockPinloads]
      # ... then on the cell ref name
      set clockPinloads [lsort -dictionary -index 1 $clockPinloads]
      set nonClockPinloads [lsort -dictionary -index 1 $nonClockPinloads]
    } else {
      # In non-verbose mode, simplify the code so that only the 'uniqueLoads' array is
      # being built
      foreach pin $netLoadPins isClock [get_property -quiet {IS_CLOCK} $netLoadPins] {
        set libcell [get_property -quiet REF_NAME [get_cells -quiet -of $pin] ]
        if {$isClock} {
          if {![info exists uniqueClockPinLoads($libcell)]} { set uniqueClockPinLoads($libcell) 0 }
          incr uniqueClockPinLoads($libcell) 1
        } else {
          if {![info exists uniqueNonClockPinLoads($libcell)]} { set uniqueNonClockPinLoads($libcell) 0 }
          incr uniqueNonClockPinLoads($libcell) 1
        }
      }
    }

    switch $netType {
      CLOCK {
        lappend output [format "\n(%-d) %-7s %-s" ${netCount} {Clock Net:} $net]
      }
      SIGNAL {
        lappend output [format "\n(%-d) %-7s %-s" ${netCount} {Signal Net:} $net]
      }
      ALL {
        lappend output [format "\n(%-d) %-7s %-s" ${netCount} {Clock/Signal Net:} $net]
      }
    }
    lappend output [format " %-14s %-14d" Fanout: $netFan]
    if {$verbose == 1 }  {
      lappend output [format " %-14s %-s" {Source Pin:} $driverCell]
    }
    lappend output [format " %-14s %-s" Source: $driverRef]
    if {[info exists uniqueNonClockPinLoads]} {
      lappend output [format " %-14s %-s" {Unique Loads to Non-Clock Pin:} [lsort -unique [array names uniqueNonClockPinLoads]]]
    }
    if {[info exists uniqueClockPinLoads]} {
      lappend output [format " %-14s %-s" {Unique Loads to Clock Pin:} [lsort -unique [array names uniqueClockPinLoads]]]
    }

    if {[info exists uniqueNonClockPinLoads]} {
      $table reset
      $table title {Non-Clock Pin Loads}
      $table header [list {Cell Ref} {Number Used}]
      foreach elm [lsort [array names uniqueNonClockPinLoads]] {
        $table addrow [list $elm $uniqueNonClockPinLoads($elm)]
      }
      set output [concat $output [split [$table print] \n] ]
    }
    if {[info exists uniqueClockPinLoads]} {
      $table reset
      $table title {Clock Pin Loads}
      $table header [list {Cell Ref} {Number Used}]
      foreach elm [lsort [array names uniqueClockPinLoads]] {
        $table addrow [list $elm $uniqueClockPinLoads($elm)]
      }
      set output [concat $output [split [$table print] \n] ]
    }

    if {$verbose} {
      if {$nonClockPinloads != {}} {
        $table reset
        $table title {Detail of All Non-Clock Pins Loads}
        if {$includeClockDomains} {
          $table header [list {Cell Ref} {Pin Name} {Cell Clock Domain} ]
          foreach elm $nonClockPinloads {
            foreach {pin libcell} $elm { break }
            $table addrow [list $libcell $pin [get_clocks -quiet -of_objects [get_cells -quiet -of_objects $pin]] ]
          }
        } else {
          $table header [list {Cell Ref} {Pin Name} ]
          foreach elm $nonClockPinloads {
            foreach {pin libcell} $elm { break }
            $table addrow [list $libcell $pin ]
          }
        }
        set output [concat $output [split [$table print] \n] ]
      }
      if {$clockPinloads != {}} {
        $table reset
        $table title {Detail of All Clock Pins Loads}
        if {$includeClockDomains} {
          $table header [list {Cell Ref} {Pin Name} {Pin Clock Domain} ]
          foreach elm $clockPinloads {
            foreach {pin libcell} $elm { break }
            $table addrow [list $libcell $pin [get_clocks -quiet -of_objects $pin] ]
          }
        } else {
          $table header [list {Cell Ref} {Pin Name} ]
          foreach elm $clockPinloads {
            foreach {pin libcell} $elm { break }
            $table addrow [list $libcell $pin ]
          }
        }
        set output [concat $output [split [$table print] \n] ]
      }
    }

  }

  set end [clock seconds]
  set duration [expr $end - $start]
  switch $netType {
    CLOCK {
      lappend output "\nGenerated report on $netCount clock nets"
      lappend output "Date: [clock format $systemTime -format %D] Compile time: $duration seconds "
      puts "\nGenerated report on $netCount clock nets"
      puts "Date: [clock format $systemTime -format %D] Compile time: $duration seconds "
    }
    SIGNAL {
      lappend output "\nGenerated report on $netCount signal nets"
      lappend output "Date: [clock format $systemTime -format %D] Compile time: $duration seconds "
      puts "\nGenerated report on $netCount signal nets"
      puts "Date: [clock format $systemTime -format %D] Compile time: $duration seconds "
    }
    ALL {
      lappend output "\nGenerated report on $netCount clock/signal nets"
      lappend output "Date: [clock format $systemTime -format %D] Compile time: $duration seconds "
      puts "\nGenerated report on $netCount clock/signal nets"
      puts "Date: [clock format $systemTime -format %D] Compile time: $duration seconds "
    }
  }

  # Add the summary table at the very begining
  set output [concat [split [$tableSummary print] \n] $output ]

  if {$filename !={}} {
    set FH [open $filename $mode]
    puts $FH [::report_net_loads::generate_file_header {report_net_loads}]
    puts $FH [join $output \n]
    close $FH
    puts "\n Report file [file normalize $filename] has been generated\n"
  } else {
    puts [join $output \n]
  }

  # Destroy the objects
  catch {$tableSummary destroy}
  catch {$table destroy}

  # Return result as string?
  if {$returnString} {
    return [join $output \n]
  }

  return 0
}

proc ::report_net_loads::lshift {inputlist} {
  # Summary :
  # Argument Usage:
  # Return Value:

  upvar $inputlist argv
  set arg  [lindex $argv 0]
  set argv [lrange $argv 1 end]
  return $arg
}

# Alias to make lshift easy to find/use from other namespaces
# interp alias {} lshift {} ::report_net_loads::lshift

proc ::report_net_loads::progressBar {cur tot} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # http://wiki.tcl.tk/16939
  # if you don't want to redraw all the time, uncomment and change ferquency
  #if {$cur % ($tot/300)} { return }
  # set to total width of progress bar
  set total 76

  # Do not show the progress bar in GUI and Batch modes
  if {$rdi::mode != {tcl}} { return }

  set half [expr {$total/2}]
  set percent [expr {100.*$cur/$tot}]
  set val (\ [format "%6.2f%%" $percent]\ )
  set str "\r|[string repeat = [expr {round($percent*$total/100)}]][string repeat { } [expr {$total-round($percent*$total/100)}]]|"
  set str "[string range $str 0 $half]$val[string range $str [expr {$half+[string length $val]-1}] end]"
  puts -nonewline stderr $str
}

proc ::report_net_loads::generate_file_header {cmd} {
  # Summary :
  # Argument Usage:
  # Return Value:

  set version $::report_net_loads::report_net_loads::version

  set header [format {######################################################
##
## %s (%s)
##} $cmd $version]

  foreach line [split [version] \n] {
    append header "\n## $line"
  }

  append header [format {
##
## Generated on %s
##
######################################################
} [clock format [clock seconds]] ]
  return $header
}

##-----------------------------------------------------------------------
## duration
##-----------------------------------------------------------------------
## Convert a number of seconds in a human readable string.
## Example:
##      set startTime [clock seconds]
##      ...
##      set endTime [clock seconds]
##      puts "The runtime is: [duration [expr $endTime - $startTime]]"
##-----------------------------------------------------------------------

proc ::report_net_loads::duration { int_time } {
  # Summary :
  # Argument Usage:
  # Return Value:

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

# namespace eval ::report_net_loads::Table { set n 0 }

# Trick to silence the linter
eval [list namespace eval ::report_net_loads::Table {
  set n 0
} ]

proc ::report_net_loads::Table::Create { {title {}} } { #-- constructor
  # Summary :
  # Argument Usage:
  # Return Value:

  variable n
  set instance [namespace current]::[incr n]
  namespace eval $instance { variable tbl [list]; variable header [list]; variable indent 0; variable title {}; variable numrows 0 }
  interp alias {} $instance {} ::report_net_loads::Table::do $instance
  # Set the title
  $instance title $title
  set instance
}

proc ::report_net_loads::Table::do {self method args} { #-- Dispatcher with methods
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
        eval ::report_net_loads::Table::print $self
      }
      length {
        return $numrows
      }
      sort {
        # Each argument is a list of: <lsort arguments>
        set command {}
        while {[llength $args]} {
          if {$command == {}} {
            set command "lsort [lshift args] \$tbl"
          } else {
            set command "lsort [lshift args] \[$command\]"
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

proc ::report_net_loads::Table::print {self} {
  # Summary :
  # Argument Usage:
  # Return Value:

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
  foreach row [concat [list $header] $table] {
      if {$row eq {%%SEPARATOR%%}} {
        append res $head\n
        continue
      }
      append res " [string repeat " " [expr $indent * 4]]|"
      foreach item $row max $maxs {append res [format " %-${max}s |" $item]}
      append res \n
      if {$first} {
        append res $head\n
        set first 0
      }
  }
  append res $head
  set res
}



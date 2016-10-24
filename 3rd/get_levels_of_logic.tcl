# From Frank Mueller
# -------------------------------
# source ./get_levels_of_logic.tcl
# set maxPaths 1000000
# set nWorst 1000
# set all_paths [get_timing_paths -max_paths $maxPaths -nworst $nWorst ]
# get_levels_of_logic [get_timing_paths -max_paths $maxPaths -nworst $nWorst ]  path_histo.txt
# -------------------------------
# Total paths analyzed: 10000
# Number of paths with 0 levels of logic: 0
# Number of paths with 1 levels of logic: 0
# Number of paths with 2 levels of logic: 0
# Number of paths with 3 levels of logic: 22
# Number of paths with 4 levels of logic: 4192
# Number of paths with 5 levels of logic: 5176
# Number of paths with 6 levels of logic: 590
# Number of paths with 7 levels of logic: 20

#------------------------------------------------------------------------
# log
#------------------------------------------------------------------------
# This function sends text to a log file
#------------------------------------------------------------------------
proc log { logFile text } {
    # Summary : send text to a log file

    # Argument Usage:
    # text : the text to be written
    # logFile : the name of the log file

  set outFile [open $logFile "a"]
  puts $outFile $text
  close $outFile
}
proc get_levels_of_logic {timingPaths {logfile {}}} {
    # Summary : generate a histogram of path levels

    # Argument Usage:
    # timingPaths : the timing paths to be analyzed
    # logFile : the name of the log file
    unset -nocomplain path_histo
    set path_cnt 0
    set max_pathlen 0

    foreach path $timingPaths {
    set pathlen [get_property LOGIC_LEVELS $path]
    if {$pathlen > $max_pathlen} {set max_pathlen $pathlen}

    incr path_histo($pathlen)
    incr path_cnt
    }
    if {$logfile == {}} {
      puts "Total paths analyzed: $path_cnt"
    } else {
      log $logfile "Total paths analyzed: $path_cnt"
    }
    for {set i 0} {$i <= $max_pathlen} {incr i} {
      if {![info exists path_histo($i)]} {
        set path_histo($i) 0
      }
      if {$logfile == {}} {
        puts "Number of paths with $i levels of logic: $path_histo($i)"
      } else {
        log $logfile "Number of paths with $i levels of logic: $path_histo($i)"
      }
    }
}

puts "Examples:"
puts "get_levels_of_logic \[get_timing_paths -max_paths 100000 -nworst 1000\] logfile.txt"
puts "get_levels_of_logic \[get_timing_paths -from \[get_clocks core_clock\] -to \[get_clocks core_clock\] -max_paths 100000 -nworst 1000\]"

# From Fred

proc reportControSetSummary {{csFile ""} {minFO 0}} {
  if {$csFile == "" || [file exist $csFile]} {
    report_control_sets -verbose -file cs.rpt
    set csFile cs.rpt
  }
  set CS [open $csFile r]
  set tag 0
  set e 0
  foreach k {clk ena rst} {
    set sliceMinFONets($k) {}
    set belMinFONets($k)   {}
  }
#| Clock Signal | Enable Signal | Set/Reset Signal | Slice Load Count | Bel Load Count |
  while {[gets $CS line] >= 0} {
    if {$e > 10} { break }
    if {$line == "3. Detailed Control Set Information"} { incr tag }
    if {$tag < 2} { continue }
    set tmp {}
    foreach t [lrange [split $line \|] 1 end-1] {
      set t [regsub -all {\s+} $t {}]
      if {$t == ""} { set t 0 }
      lappend tmp $t
    }
    lassign $tmp clk ena rst sliceLoads belLoads
    if {![regexp {[0-9]+} $sliceLoads] || ![regexp {[0-9]+} $belLoads]} {
      #puts $line; puts $tmp; incr e
      continue
    }
    incr sliceCount($sliceLoads)
    incr belCount($belLoads)
    foreach k {clk ena rst} {
      if {$sliceLoads <= $minFO} {
        eval lappend sliceMinFONets($k) \$$k
      }
      if {$sliceLoads > 0} {
        eval incr slice${k}(\$$k) $sliceLoads
      }
      if {$belLoads <= $minFO} {
        eval lappend belMinFONets($k) \$$k
      }
      if {$belLoads > 0} {
        eval incr bel${k}(\$$k) $belLoads
      }
    }
  }
  close $CS
  if {0} {
  puts "\n### Control Sets per Slice Loads ###"
  foreach cnt [lsort -integer -decreasing [array names sliceCount]] {
    puts [format "%-6s = %s" $cnt $sliceCount($cnt)]
  }
  foreach k {clk ena rst} {
    puts "### $k involved in Slice Loads < $minFO ###"
    foreach n [lsort [eval array names slice$k]] {
      puts [eval format \"%-6s = %s\" \$slice${k}($n) \$n]
    }
  }
  }
  puts "\n### Control Sets per Bel Loads ###"
  foreach cnt [lsort -integer -decreasing [array names belCount]] {
    puts [format "%6s = %s" $cnt $belCount($cnt)]
  }
  foreach k {clk ena rst} {
    puts "### $k involved in Bel Loads < $minFO ###"
    foreach n [get_nets [lsort -unique $belMinFONets($k)]] {
      eval set ld \$bel${k}($n)
      if {$ld > $minFO} { continue }
      set fo [expr [get_property FLAT_PIN_COUNT $n] - 1]
      puts [format "%-6s - %-6s = %s" $ld $fo $n]
    }
  }
}

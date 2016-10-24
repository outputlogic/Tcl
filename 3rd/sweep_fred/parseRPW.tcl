proc parseRPW {csvFile} {
  set CSV [open $csvFile w]
  set N [llength [get_pins -hier -filter {REF_NAME==BITSLICE_CONTROL && REF_PIN_NAME==RIU_CLK}]]
  set N [expr $N * 4]
  set rpt [report_pulse_width -max_skew -limit $N -return_string]
  foreach line [split $rpt \n] {
    if {[regexp {^Max Skew\s+(\S+)\s+BITSLICE_CONTROL/(\S+)\s+BITSLICE_CONTROL/(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+BITSLICE_CONTROL_(\S+)\s+.*} $line all corner libPin refPin req actual slack site]} {
      puts $CSV [join [list $site $libPin $refPin $corner $req $actual $slack] ,]
    }
  }
  close $CSV
}

proc combineRPW {combCsvFile csvFiles} {
  set CSV [open $combCsvFile w]
  foreach f $csvFiles {
    set TMP [open $f r]
    set prevLine ""
    regexp {.*X([0-9]+)Y([0-9]+).*} $f all x y
    while {[gets $TMP line] >= 0} {
      if {$prevLine == $line} { continue }
      lassign [split $line ,] site libPin refPin corner req actual slack
      set pins [lsort [list $libPin $refPin]]
      set name ${site}_[join $pins _]
      switch "$corner_$refPin" {
        "Slow_RIU_CLK" { set maxSkew($name) [lreplace $maxSkew($name) 0 0 $slack] }
        "Slow_PLL_CLK" { set maxSkew($name) [lreplace $maxSkew($name) 1 1 $slack] }
        "Fast_RIU_CLK" { set maxSkew($name) [lreplace $maxSkew($name) 2 2 $slack] }
        "Fast_PLL_CLK" { set maxSkew($name) [lreplace $maxSkew($name) 3 3 $slack] }
      }
    }
    close $TMP
  }
  close $CSV
}

# From Fred

# Typical usage (from Vivado Tcl console/shell):
# vivadoQoR qor_2015_3.csv [glob ${rootDir}/2015.3_srlDSPLagunaOpt6*/*/vivado.log] 1

proc vivadoQoR {{csvFileName "vivadoQoR.csv"} {logFiles ""} {useInitialRouteTimingForPhysOpt 0} {columnMode 0} {logDirs ""}} {
  # columnMode
  # 0: (default) Runtime + timing + directives
  # 1: runtime + memory
  # 2: same as 0 + long/short router congestion columns
  if {$logFiles == "" && $logDirs == ""} {
    set logFiles [glob *.log]
  } elseif {$logFiles == "" && $logDirs != ""} {
    foreach dir $logDirs {
      set tmpLog ""
      catch {set tmpLog [glob $dir/*.vdi]}
      if {[llength $tmpLog] == 0} {
        catch {set tmpLog [glob $dir/*.log]}
      }
      set logFiles [concat $logFiles $tmpLog]
    }
  }
  if {[llength $logFiles] == 0} {
    puts "No log file found"
    return
  }
  set nbFiles [llength $logFiles]
  set rootDir ""
  while {1} {
    set newRootDir [regsub "^${rootDir}/(\[^/\]*).*" [lindex $logFiles 0] "$rootDir/\\1"]
    #puts "$rootDir - $newRootDir"
    set cnt 0
    foreach f $logFiles { incr cnt [regexp "$newRootDir/" $f] }
    if {$cnt != $nbFiles} { break }
    set rootDir $newRootDir
  }
  if {![regexp {.*\.csv} $csvFileName]} {
    puts "Error - Expecting a .csv extension for the argument"
    return 1
  }
  set CSV [open $csvFileName w]
  if {$columnMode == 2} {
    puts $CSV [join [list logFile status totalTime link optDir optTime \
                          placeDirective placeWNS placeCong placeTime \
                          physOptDirective physOptWNS physOptTNS physOptWHS physOptTHS physOptTime pOptIter \
                          routeDirective routeWNS routeTNS routeWHS routeTHS routeCong longCong shortCong routeTime \
                          prPOptDirective prPOptWNS prPOptTNS prPOptWHS prPOptTHS prPOptTime prPOptIter] ,]
  } elseif {$columnMode == 1} {
    puts $CSV [join [list logFile status totalTime \
                          placeDirective placeWNS placeTime placePeak placeGain \
                          routeDirective routeWNS routeTNS routeWHS routeTHS routeTime routePeak routeGain] ,]
  } else {
    if {$columnMode != 0} { puts "Warning - unsupported column layout ID - using default (0)" }
    puts $CSV [join [list logFile status totalTime link optDir optTime \
                          placeDirective placeWNS placeCong placeTime \
                          physOptDirective physOptWNS physOptTNS physOptWHS physOptTHS physOptTime pOptIter \
                          routeDirective routeWNS routeTNS routeWHS routeTHS routeCong routeTime \
                          prPOptDirective prPOptWNS prPOptTNS prPOptWHS prPOptTHS prPOptTime prPOptIter] ,]
  }
  set implCmds {link opt place phys_opt route pr_phys_opt power_opt}
  set met 0; set fail 0; set running 0; set error 0; set logCnt 0
  foreach logFile $logFiles {
    foreach k $implCmds { set runtime($k) {}; set timing($k) {}; set directive($k) {}; set nbIter($k) ""; set peakMem($k) ""; set gainMem($k) "" }
    set status ""
    set vivadoDone 0
    set overlaps 0
    set LOG [open $logFile r]
    incr logCnt
    puts -nonewline "Processing $logFile ..."
    set prevCmd ""
    set cmd ""
    set placeCong "u u u u"
    set routeCong "u u u u"
    set routeLongCong "1x1 0.0"
    set routeShortCong "1x1 0.0"
    while {[gets $LOG line] >= 0} {
      #puts $cmd
      if {[regexp {^Command: (\S+)\s*(.*)} $line foo cmd cmdArgs]} {
        #puts $line
        set cmd    [regsub {_design} $cmd {}]
        set curcmd [regsub {_design} $cmd {}]
        if {$curcmd == "phys_opt"} { continue }
        if {[regexp {\-directive\s+(\S+)} $cmdArgs foo tmp]} { set directive($curcmd) $tmp }
      } elseif {[regexp {^INFO: .* Physical synthesis in post route mode .*} $line]} {
        set curcmd pr_phys_opt
        #puts $line
      } elseif {[regexp {^INFO: .* Directive used for phys_opt_design is: (\S+)} $line foo tmp]} {
        set directive($curcmd) $tmp
        #puts $line
      } elseif {[regexp {^(\S+): Time \(s\): cpu = ([0-9:]+) ; elapsed = ([0-9:]+) .* Memory \(MB\): peak = ([0-9.]+) ; gain = ([0-9.]+)} $line foo cmd cpu elapsed peak gain]} {
        #puts $line
        #open_checkpoint: Time (s): cpu = 00:08:20 ; elapsed = 00:05:22 . Memory (MB): peak = 7658.938 ; gain = 6655.289 ; free physical = 18295 ; free virtual = 73298
        set cmd [regsub {_design} $cmd {}]
        if {$cmd == "phys_opt" && $curcmd == "pr_phys_opt"} { set cmd "pr_phys_opt" }
        if {$cmd == "open_checkpoint"} { set cmd "link" }
        if {[lsearch $implCmds $cmd] != -1 && $runtime($cmd) != {}} {
          set runtime($cmd) [clock format [expr [clock scan $runtime($cmd) -format {%H:%M:%S}] \
                                              + [clock scan $elapsed -format {%H:%M:%S}] \
                                              - [clock scan 00:00:00 -format {%H:%M:%S}]] \
                                          -format {%H:%M:%S}]
        } else {
          set runtime($cmd) $elapsed
        }
        if {($cmd == "phys_opt" && $prevCmd == "phys_opt") || ($cmd == "pr_phys_opt" && $prevCmd == "pr_phys_opt")} {
          incr nbIter($cmd)
        } else {
          if {[lsearch $implCmds $cmd] != -1} { set prevCmd $cmd }
          set nbIter($cmd) 1
        }
        set peakMem($cmd) $peak
        set gainMem($cmd) $gain
      } elseif {[regexp {^INFO: \[.*\] (.*) Timing Summary \| WNS=(\S+)\s*\| TNS=(\S+)\s*\| WHS=(\S+)\s*\| THS=(\S+)\s*.*} $line foo step wns tns whs ths]} {
        #puts $line
        set ths [regsub {\|} $ths {}]
        if {$useInitialRouteTimingForPhysOpt && $curcmd == "route" && $timing(route) == "" && [llength $timing(phys_opt)] == 2} {
          # Using first timing report from router as phys_top timing (or pre-route timing) => provides WHS/THS numbers
          set timing(phys_opt) [list [lindex $timing(phys_opt) 0] [lindex $timing(phys_opt) 1] $whs $ths]
        } elseif {$useInitialRouteTimingForPhysOpt && $curcmd == "route" && $timing(route) == "" && [llength $timing(phys_opt)] == 0} {
          # Using first timing report from router as phys_top timing (or pre-route timing) => provides WNS/TNS/WHS/THS numbers
          set timing(phys_opt) [list $wns $tns $whs $ths]
          set directive(phys_opt) NotRun
        } else {
          set timing($curcmd) [list $wns $tns $whs $ths]
        }
      } elseif {[regexp {^\|\s+(\S+)\s*\|\s+([0-9x]+)\s*\|\s+([0-9.]+)\s*\|\s+([0-9x]+)\s*\|\s+([0-9.]+)\s*\|\s+([0-9x]+)\s*\|\s+([0-9.]+)\s*\|} $line all card globCong globPc longCong longPc shortCong shortPc]} {
        set level [returnCongLevel $globCong]
        switch -exact $card {
          "NORTH" { set routeCong [lreplace $routeCong 0 0 $level] }
          "SOUTH" { set routeCong [lreplace $routeCong 1 1 $level] }
          "EAST"  { set routeCong [lreplace $routeCong 2 2 $level] }
          "WEST"  { set routeCong [lreplace $routeCong 3 3 $level] }
        }
        set longLevel [returnCongLevel $longCong]
        set longPrev  [returnCongLevel [lindex $routeLongCong 0]]
        if {$longLevel > $longPrev} {
          set routeLongCong [list $longCong $longPc]
        } elseif {$longLevel == $longPrev && $longPc > [lindex $routeLongCong 1]} {
          set routeLongCong [list $longCong $longPc]
        }
        #set longTmp [expr [regsub {x} $longCong {*}]]
        #set routeLongCong [expr $routeLongCong + $longTmp * $longPc]
        set shortLevel [returnCongLevel $shortCong]
        set shortPrev  [returnCongLevel [lindex $routeShortCong 0]]
        if {$shortLevel > $shortPrev} {
          set routeShortCong [list $shortCong $shortPc]
        } elseif {$shortLevel == $shortPrev && $shortPc > [lindex $routeShortCong 1]} {
          set routeShortCong [list $shortCong $shortPc]
        }
        #set shortTmp [expr [regsub {x} $shortCong {*}]]
        #set routeShortCong [expr $routeShortCong + $shortTmp * $shortPc]
      } elseif {[regexp {^INFO: \[.*\] Post Physical Optimization Timing Summary \| WNS=(\S+)\s*\| TNS=(\S+)\s*.*} $line foo wns tns]} {
        #puts $line
        set timing(phys_opt) [list $wns $tns]
      } elseif {[regexp {^INFO: .* Post Placement Timing Summary WNS=(\S+)\. .*} $line foo wns]} {
        #puts $line
        if {$cmd == "route"} { continue } ;# post-place optimization inside router when Explore directive is used
        set timing(place) $wns
      } elseif {[regexp {^ERROR: \[(\S+) (\d+)-(\d+)\] } $line foo a b c]} {
        if {$status == "" && [lsearch -glob -nocase $implCmds ${a}*] != -1} { set status "ERROR-$a-$b-$c" }
      } elseif {[regexp {^route_design failed\s*$} $line]} {
        if {$status == ""} { set status "ERROR-Router-Unknown" }
      } elseif {[regexp {^INFO: \[Common 17-206\] Exiting Vivado} $line]} {
        set vivadoDone 1
      } elseif {[regexp {^CRITICAL WARNING: \[Route 35-2\] Design is not legally routed. There are (\d+) node overlaps} $line foo overlaps]} {
        set status "FAILED-$overlaps overlaps"
      }
    }
    close $LOG
    set totTime 00:00:00
    foreach cmd $implCmds {
      if {$runtime($cmd) == ""} { continue }
      set totTime [clock format [expr [clock scan $totTime -format {%H:%M:%S}] \
                                    + [clock scan $runtime($cmd) -format {%H:%M:%S}] \
                                    - [clock scan 00:00:00 -format {%H:%M:%S}]] \
                                -format {%H:%M:%S}]
    }
    if {$status == ""} {
      if {[lindex $timing(route) 0] >= 0 && [lindex $timing(route) 2] >=0} {
        set status "MET-Route"
      } elseif {[lindex $timing(pr_phys_opt) 0] >= 0 && [lindex $timing(pr_phys_opt) 2] >=0} {
        set status "MET-prPOpt"
      } elseif {!$vivadoDone} {
        set status "RUNNING"
      } else {
        set status "FAILED-Timing"
      }
    }
    switch -glob $status {
      "MET*" { incr met }
      "FAIL*" { incr fail }
      "ERROR*" { incr error }
      "RUNNING" { incr running }
    }
    set rdaCongestion "[file dirname $logFile]/rda_congestion.rpt"
    if {![file exists $rdaCongestion]} {
      if {[catch {set rdaCongestion [glob [file dirname $logFile]/*congestion*]} foo]} { set rdaCongestion "" }
    }
    if {[file exists $rdaCongestion]} {
      lassign [parseRDACongestion $rdaCongestion] placeCong routeCongTmp
      if {$routeCong == "u u u u" && $routeCongTmp != "u-u-u-u"} { set routeCong $routeCongTmp } else { set routeCong [join $routeCong -] }
    } else {
      set placeCong [join $placeCong -]
      set routeCong [join $routeCong -]
    }
    if {$columnMode == 2} {
      set csvList [list [regsub "$rootDir/(.*)/.*\.log" $logFile {\1}] $status $totTime $runtime(link) $directive(opt) $runtime(opt) \
                          $directive(place) $timing(place) $placeCong $runtime(place) \
                          $directive(phys_opt) [lindex $timing(phys_opt) 0] [lindex $timing(phys_opt) 1] [lindex $timing(phys_opt) 2] [lindex $timing(phys_opt) 3] $runtime(phys_opt) $nbIter(phys_opt) \
                          $directive(route) [lindex $timing(route) 0] [lindex $timing(route) 1] [lindex $timing(route) 2] [lindex $timing(route) 3] $routeCong [join $routeLongCong (]%) [join $routeShortCong (]%) $runtime(route) \
                          $directive(pr_phys_opt) [lindex $timing(pr_phys_opt) 0] [lindex $timing(pr_phys_opt) 1] [lindex $timing(pr_phys_opt) 2] [lindex $timing(pr_phys_opt) 3] $runtime(pr_phys_opt) $nbIter(pr_phys_opt)]
    } elseif {$columnMode == 1} {
      set csvList [list [regsub "$rootDir/(.*)/.*\.log" $logFile {\1}] $status $totTime \
                          $directive(place) $timing(place) $runtime(place) $peakMem(place) $gainMem(place) \
                          $directive(route) [lindex $timing(route) 0] [lindex $timing(route) 1] [lindex $timing(route) 2] [lindex $timing(route) 3] $runtime(route) $peakMem(route) $gainMem(route)]
    } else {
      set csvList [list [regsub "$rootDir/(.*)/.*\.log" $logFile {\1}] $status $totTime $runtime(link) $directive(opt) $runtime(opt) \
                          $directive(place) $timing(place) $placeCong $runtime(place) \
                          $directive(phys_opt) [lindex $timing(phys_opt) 0] [lindex $timing(phys_opt) 1] [lindex $timing(phys_opt) 2] [lindex $timing(phys_opt) 3] $runtime(phys_opt) $nbIter(phys_opt) \
                          $directive(route) [lindex $timing(route) 0] [lindex $timing(route) 1] [lindex $timing(route) 2] [lindex $timing(route) 3] $routeCong $runtime(route) \
                          $directive(pr_phys_opt) [lindex $timing(pr_phys_opt) 0] [lindex $timing(pr_phys_opt) 1] [lindex $timing(pr_phys_opt) 2] [lindex $timing(pr_phys_opt) 3] $runtime(pr_phys_opt) $nbIter(pr_phys_opt)]
    }
    if {[llength [lsort -unique $csvList]] == 2} {
      puts " Nothing to report - skipping..."
      continue
    }
    puts $CSV [join $csvList ,]
    puts " $status"
  }
  puts "MET: $met - FAIL: $fail - ERROR: $error - RUNNING: $running"
  close $CSV
}

proc parseRDACongestion {rdaFile} {
  set RDA [open $rdaFile r]
  set section "other"
  set placeCong [list u u u u]
  set routeCong [list u u u u]
  while {[gets $RDA line] >= 0} {
    if {[regexp {^\d. (\S+) Maximum Level Congestion Reporting} $line foo step]} {
      switch -exact $step {
        "Placed" { set section "placer" }
        "Router" { set section "router" }
        default  { set section "other" }
      }
    } elseif {[regexp {^\| (\S+)\s*\| (\S+)\s*\| \S+\s*\| \S+\s*| \S+\s*\| \S+\s*\| \S+\s*\| \S+\s*\| \S+\s*\| \S+\s*\| \S+\s*\|} $line foo card cong] || \
              [regexp {^\| (\S+)\s*\| (\S+)\s*\| \S+\s*\| \s*\S+ -> \S+\s*\|\s*$} $line foo card cong]} {
      set level [returnCongLevel $cong]
      if {$section == "placer"} {
        switch -exact $card {
          "North" { set placeCong [lreplace $placeCong 0 0 $level] }
          "South" { set placeCong [lreplace $placeCong 1 1 $level] }
          "East"  { set placeCong [lreplace $placeCong 2 2 $level] }
          "West"  { set placeCong [lreplace $placeCong 3 3 $level] }
        }
      } elseif {$section == "router"} {
        switch -exact $card {
          "North" { set routeCong [lreplace $routeCong 0 0 $level] }
          "South" { set routeCong [lreplace $routeCong 1 1 $level] }
          "East"  { set routeCong [lreplace $routeCong 2 2 $level] }
          "West"  { set routeCong [lreplace $routeCong 3 3 $level] }
        }
      }
    } elseif {[regexp {^\d\. } $line]} {
      set section "other"
    }
  }
  close $RDA
  return [list [join $placeCong -] [join $routeCong -]]
}

proc returnCongLevel {cong} {
  switch -exact $cong {
    "1x1"     { return 0 }
    "2x2"     { return 1 }
    "4x4"     { return 2 }
    "8x8"     { return 3 }
    "16x16"   { return 4 }
    "32x32"   { return 5 }
    "64x64"   { return 6 }
    "128x128" { return 7 }
    "256x256" { return 8 }
    default   { return u }
  }
}

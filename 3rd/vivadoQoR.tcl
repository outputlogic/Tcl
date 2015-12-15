# Typical usage (from Vivado Tcl console/shell):
# vivadoQoR qor_2015_3.csv [glob ${rootDir}/2015.3_srlDSPLagunaOpt6*/*/vivado.log] 1


proc vivadoQoR {{csvFileName "vivadoQoR.csv"} {logFiles ""} {useInitialRouteTimingForPhysOpt 0} {logDirs ""}} {
  if {$logFiles == "" && $logDirs == ""} {
    set logFiles [glob *.vdi]
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
  puts $CSV [join [list logFile status totalTime link optDir optTime \
                        placeDirective placeWNS placeTime \
                        physOptDirective physOptWNS physOptTNS physOptWHS physOptTHS physOptTime pOptIter \
                        routeDirective routeWNS routeTNS routeWHS routeTHS routeCong routeTime \
                        prPOptDirective prPOptWNS prPOptTNS prPOptWHS prPOptTHS prPOptTime prPOptIter] ,]
  set implCmds {link opt place phys_opt route pr_phys_opt power_opt}
  set met 0; set fail 0; set running 0; set error 0; set logCnt 0
  foreach logFile $logFiles {
    foreach k $implCmds { set runtime($k) {}; set timing($k) {}; set directive($k) {}; set nbIter($k) "" }
    set status ""
    set vivadoDone 0
    set overlaps 0
    set LOG [open $logFile r]
    incr logCnt
    puts -nonewline "Processing $logFile ..."
    set prevCmd ""
    set cmd ""
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
      } elseif {[regexp {^(\S+): Time \(s\): cpu = ([0-9:]+) ; elapsed = ([0-9:]+) .*} $line foo cmd cpu elapsed]} {
        #puts $line
        set cmd [regsub {_design} $cmd {}]
        if {$cmd == "phys_opt" && $curcmd == "pr_phys_opt"} { set cmd "pr_phys_opt" }
        if {$cmd == "open_checkpoint"} { set cmd "link" }
        if {($cmd == "phys_opt" && $prevCmd == "phys_opt") || ($cmd == "pr_phys_opt" && $prevCmd == "pr_phys_opt")} {
          set runtime($cmd) [clock format [expr [clock scan $runtime($cmd) -format {%H:%M:%S}] \
                                              + [clock scan $elapsed -format {%H:%M:%S}] \
                                              - [clock scan 00:00:00 -format {%H:%M:%S}]] \
                                          -format {%H:%M:%S}]
          incr nbIter($cmd)
        } else {
          set runtime($cmd) $elapsed
          if {[lsearch $implCmds $cmd] != -1} { set prevCmd $cmd }
          set nbIter($cmd) 1
        }
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
      } elseif {[regexp {^INFO: \[.*\] Post Physical Optimization Timing Summary \| WNS=(\S+)\s*\| TNS=(\S+)\s*.*} $line foo wns tns]} {
        #puts $line
        set timing(phys_opt) [list $wns $tns]
      } elseif {[regexp {^INFO: .* Post Placement Timing Summary WNS=(\S+)\. .*} $line foo wns]} {
        #puts $line
        if {$cmd == "route"} { continue } ;# post-place optimization inside router when Explore directive is used
        set timing(place) $wns
      } elseif {[regexp {^ERROR: \[(\S+) (\d+)-(\d+)\] } $line foo a b c]} {
        if {$status == "" && [lsearch -glob -nocase $implCmds ${a}*] != -1} { set status "ERROR-$a-$b-$c" }
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
    lassign [parseRDACongestion $logFile] routeCong
    set csvList [list [regsub "$rootDir/(.*)/.*\.log" $logFile {\1}] $status $totTime $runtime(link) $directive(opt) $runtime(opt) \
                        $directive(place) $timing(place) $runtime(place) \
                        $directive(phys_opt) [lindex $timing(phys_opt) 0] [lindex $timing(phys_opt) 1] [lindex $timing(phys_opt) 2] [lindex $timing(phys_opt) 3] $runtime(phys_opt) $nbIter(phys_opt) \
                        $directive(route) [lindex $timing(route) 0] [lindex $timing(route) 1] [lindex $timing(route) 2] [lindex $timing(route) 3] $routeCong $runtime(route) \
                        $directive(pr_phys_opt) [lindex $timing(pr_phys_opt) 0] [lindex $timing(pr_phys_opt) 1] [lindex $timing(pr_phys_opt) 2] [lindex $timing(pr_phys_opt) 3] $runtime(pr_phys_opt) $nbIter(pr_phys_opt)]
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
  set routerCong [list u u u u]
  while {[gets $RDA line] >= 0} {
    if {[regexp {^\|\s*(\S+)\|\s*(\S+)\|\s*(\S+)\|\s*(\S+)\|\s*(\S+)\|\s*(\S+)\|\s*(\S+)\|} $line foo card foo foo foo foo cong]} {
      switch -exact $cong {
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
     switch -exact $card {
       "NORTH" { set routerCong [lreplace $routerCong 0 0 $level] }
       "SOUTH" { set routerCong [lreplace $routerCong 1 1 $level] }
       "EAST"  { set routerCong [lreplace $routerCong 2 2 $level] }
       "WEST"  { set routerCong [lreplace $routerCong 3 3 $level] }
      }
     if {$card == "WEST"} {
       close $RDA
       return [list [join $routerCong -]]
     }
    } 
  }
  close $RDA
  return [list [join $routerCong -]]
}

# findFiles
# basedir - the directory to start looking in
# pattern - A pattern, as defined by the glob command, that the files must match
proc findFiles { basedir pattern } {

    # Fix the directory name, this ensures the directory name is in the
    # native format for the platform and contains a final directory seperator
    set basedir [string trimright [file join [file normalize $basedir] { }]]
    set fileList {}

    # Look in the current directory for matching files, -type {f r}
    # means ony readable normal files are looked at, -nocomplain stops
    # an error being thrown if the returned list is empty
    foreach fileName [glob -nocomplain -type {f r} -path $basedir $pattern] {
        lappend fileList $fileName
    }

    # Now look for any sub direcories in the current directory
    foreach dirName [glob -nocomplain -type {d  r} -path $basedir *] {
        # Recusively call the routine on the sub directory and append any
        # new files to the results
        set subDirList [findFiles $dirName $pattern]
        if { [llength $subDirList] > 0 } {
            foreach subDirFile $subDirList {
                lappend fileList $subDirFile
            }
        }
    }
    return $fileList
 }
 
proc vivadoQoR_rec { basedir csvfile } {

   set logfiles [findFiles $basedir "*.vdi"]
   vivadoQoR $csvfile $logfiles
 }
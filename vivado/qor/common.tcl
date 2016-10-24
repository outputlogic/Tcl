
######################################################################
#
# Take a design snapshot
#
######################################################################

# proc snapit {db dir project version experiment step directive {duration 0}} {
#   set saveReport 0
#   if {[catch {
#     snapshot configure -db $db -project $project -version $version -experiment $experiment -step $step
#
#     set spaths [get_timing_paths -quiet -nworst 1 -max_path 1000 -slack_lesser_than 0.0 -setup]
#     catch { ::tb::report_path_analysis -of $spaths         -sort_by tns -setup -file $dir/report_path_analysis.setup.${step}.${directive}.rpt }
#     catch { ::tb::report_path_analysis -of $spaths -R -csv -sort_by tns -setup -file $dir/report_path_analysis.setup.${step}.${directive}.csv }
#     if {$saveReport} {
# #       catch { snapshot addfile report_path_analysis.setup.csv $dir/report_path_analysis.setup.${step}.${directive}.csv }
#       catch { snapshot addfile report_path_analysis.setup.rpt $dir/report_path_analysis.setup.${step}.${directive}.rpt }
#     }
#
#     set hpaths [get_timing_paths -quiet -nworst 1 -max_path 1000 -slack_lesser_than 0.0 -hold]
#     catch { ::tb::report_path_analysis -of $hpaths         -sort_by tns -hold -file $dir/report_path_analysis.hold.${step}.${directive}.rpt }
#     catch { ::tb::report_path_analysis -of $hpaths -R -csv -sort_by tns -hold -file $dir/report_path_analysis.hold.${step}.${directive}.csv }
#     if {$saveReport} {
# #       catch { snapshot addfile report_path_analysis.hold.csv $dir/report_path_analysis.hold.${step}.${directive}.csv }
#       catch { snapshot addfile report_path_analysis.hold.rpt $dir/report_path_analysis.hold.${step}.${directive}.rpt }
#     }
#
#     snapshot set directive $directive
#     snapshot set rundir $dir
#     snapshot extract -save -options [list -save_reports $saveReport]
#     # Save report_design_analysis report on file (from sql db)
#     catch {
#       set FH [open $dir/report_design_analysis.${step}.rpt {w}]
#       puts $FH [snapshot get report.design_analysis]
#       close $FH
#     }
#     # Reset snapshot
#     snapshot reset
#   } errorstring]} {
#     puts "ERROR - $errorstring"
#   }
# }

proc snapit {db dir project version experiment step directive {duration 0}} {
  # Save report_design_analysis
  report_design_analysis -max_paths 100 -timing -congestion -complexity -file $dir/report_design_analysis.${step}.rpt

  # Save 1000 worst Setup paths
  set spaths [get_timing_paths -quiet -nworst 1 -max_path 1000 -slack_lesser_than 0.0 -setup]
  catch { ::tb::report_path_analysis -of $spaths         -sort_by tns -setup -file $dir/report_path_analysis.setup.${step}.${directive}.rpt }
  catch { ::tb::report_path_analysis -of $spaths -R -csv -sort_by tns -setup -file $dir/report_path_analysis.setup.${step}.${directive}.csv }

  # Save 1000 worst Hold paths
  set hpaths [get_timing_paths -quiet -nworst 1 -max_path 1000 -slack_lesser_than 0.0 -hold]
  catch { ::tb::report_path_analysis -of $hpaths         -sort_by tns -hold -file $dir/report_path_analysis.hold.${step}.${directive}.rpt }
  catch { ::tb::report_path_analysis -of $hpaths -R -csv -sort_by tns -hold -file $dir/report_path_analysis.hold.${step}.${directive}.csv }

  # Design summary
  catch {
    tb::report_design_summary -project $project -version $version -experiment $experiment -step $step -directive $directive \
                              -runtime $duration \
                              -details -all -exclude {cdc drc} \
                              -vivadolog $dir/run.log \
                              -csv -file $dir/summary.${step}.${directive}.csv
#     tb::report_design_summary -project $project -version $version -experiment $experiment -step $step -directive $directive \
#                               -runtime $duration \
#                               -details -all -exclude {cdc drc} \
#                               -add_metrics [list \
#                                              [list design.slls {SLLs Connections} [tb::report_slls -return_summary]] \
#                                            ] \
#                               -csv -file $dir/summary.${step}.${directive}.csv
  }

}

######################################################################
#
#
#
######################################################################

# Export FIFO/RAM input/output timings
proc generate_RAM_FIFO_timing {dir tag} {

  # Generate RAM input/output timing
  set outpaths {}
  set inpaths {}
  foreach RAM [get_cells -quiet -hier -filter {REF_NAME=~RAMB*}] {
    set path [get_timing_paths -quiet -setup -to $RAM -max_paths 1]
    if {$path != {}} { lappend inpaths $path }
  }
  foreach RAM [get_cells -quiet -hier -filter {REF_NAME=~RAMB*}] {
    set path [get_timing_paths -setup -quiet -from $RAM -through [get_pins -of $RAM -filter REF_PIN_NAME=~*DOUT*] -max_paths 1]
    if {$path != {}} { lappend outpaths $path }
  }
  if {$inpaths != {}}  { catch { ::tb::report_path_analysis -of $inpaths          -setup -file $dir/RAM_input_timing_${tag}.rpt } }
  if {$inpaths != {}}  { catch { ::tb::report_path_analysis -of $inpaths  -R -csv -setup -file $dir/RAM_input_timing_${tag}.csv } }
  if {$outpaths != {}} { catch { ::tb::report_path_analysis -of $outpaths         -setup -file $dir/RAM_output_timing_${tag}.rpt } }
  if {$outpaths != {}} { catch { ::tb::report_path_analysis -of $outpaths -R -csv -setup -file $dir/RAM_output_timing_${tag}.csv } }
  if {$inpaths != {}}  { catch { export_timing_paths $inpaths RAM_input_timing_${tag} $dir } }
  if {$outpaths != {}} { catch { export_timing_paths $outpaths RAM_output_timing_${tag} $dir } }

  # Generate FIFO input/output timing
  set outpaths {}
  set inpaths {}
  foreach FIFO [get_cells -quiet -hier -filter {REF_NAME=~FIFO*}] {
    set path [get_timing_paths -setup -quiet -to $FIFO -max_paths 1]
    if {$path != {}} { lappend inpaths $path }
  }
  foreach FIFO [get_cells -quiet -hier -filter {REF_NAME=~FIFO*}] {
    set path [get_timing_paths -setup -quiet -from $FIFO -through [get_pins -of $FIFO -filter REF_PIN_NAME=~*DOUT*] -max_paths 1]
    if {$path != {}} { lappend outpaths $path }
  }
  if {$inpaths != {}}  { catch { ::tb::report_path_analysis -of $inpaths          -setup -file $dir/FIFO_input_timing_${tag}.rpt } }
  if {$inpaths != {}}  { catch { ::tb::report_path_analysis -of $inpaths  -R -csv -setup -file $dir/FIFO_input_timing_${tag}.csv } }
  if {$outpaths != {}} { catch { ::tb::report_path_analysis -of $outpaths         -setup -file $dir/FIFO_output_timing_${tag}.rpt } }
  if {$outpaths != {}} { catch { ::tb::report_path_analysis -of $outpaths -R -csv -setup -file $dir/FIFO_output_timing_${tag}.csv } }
  if {$inpaths != {}}  { catch { export_timing_paths $inpaths FIFO_input_timing_${tag} $dir } }
  if {$outpaths != {}} { catch { export_timing_paths $outpaths FIFO_output_timing_${tag} $dir } }

}

######################################################################
#
#
#
######################################################################

# export_timing_correlation
proc export_timing_correlation { stage {num 100} {margin 0.05} } {
  set spaths [get_timing_paths -setup -max $num -nworst 1 -slack_less_than 0]
  if {$spaths != {}} {
    catch { tb::report_net_correlation -of $spaths -margin $margin -file netcorr_${stage}.csv }
  }
}

######################################################################
#
#
#
######################################################################

# force_replication_on_nets
proc force_replication_on_nets { nets } {
  set nets [get_nets -quiet $nets]
  if {![llength $nets]} { return }
  if {[catch {
    foreach net $nets {
      puts "force_replication_on_nets : [get_property FLAT_PIN_COUNT $net] \t $net"
    }
    phys_opt_design -force_replication_on_nets $nets
  } errorstring]} {
    puts " ERROR (force_replication_on_nets): $errorstring"
  }
  return -code ok
}

proc force_replication_on_hfn { {maxfanout 2000} } {
  set nets [get_nets -quiet -hierarchical -top_net_of_hierarchical_group -filter "FLAT_PIN_COUNT > $maxfanout"]
  if {![llength $nets]} { return }
  if {[catch {
    set reg_hfn {}
    foreach net $nets {
      if { [get_property PRIMITIVE_GROUP [get_cells -filter {IS_PRIMITIVE == 1} [all_fanin -flat -levels 10 -only_cells $net]] ] == "REGISTER"  } {
        puts "force_replication_on_hfn : [get_property FLAT_PIN_COUNT $net] \t $net"
        lappend reg_hfn $net
      }
    }
    # Example of the phys_opt_design command that uses the "reg_hfn" variable with the value of the synchronously driven high fanout nets.
    phys_opt_design -force_replication_on_nets [get_nets -quiet ${reg_hfn}]
  } errorstring]} {
    puts " ERROR (force_replication_on_nets): $errorstring"
  }
  return -code ok
}

######################################################################
#
#
#
######################################################################

# export_unpblocked_cells
proc export_unpblocked_cells { filename } {

  set cells [lsort [get_cells -quiet -hier -filter {IS_PRIMITIVE && PRIMITIVE_LEVEL == {LEAF} && REF_NAME != VCC && REF_NAME != GND}]]
  set missing [list]
  foreach cell $cells {
    set pblock [get_pblocks -quiet -of $cell]
    if {$pblock == {}} {
      set slr [get_slrs -quiet -of $cell]
      lappend missing [list $cell $slr]
    }
  }
  llength $missing
  set FH [open $filename {w}]
  foreach el $missing {
    foreach {cell slr} $el { break }
    if {$slr == {}} { continue }
    puts $FH [format {add_cells_to_pblock [get_pblocks %s] [get_cells -quiet %s]} $slr $cell]

  }
  close $FH

}

######################################################################
#
#
#
######################################################################

# # Export timing paths (Setup only)
# set spaths [get_timing_paths -quiet -nworst 1 -max_path 1000 -slack_lesser_than 0.0 -setup]
# export_timing_paths $spaths postroute %{RUNDIR}

proc export_timing_paths { paths {name {default}} {root {.}} } {
  if {![llength $paths]} { return }
  if {[catch {
    # Order paths from most critical to least critical
    set L [list]
    foreach path $paths {
      set slack [get_property -quiet SLACK $path]
      lappend L [list $slack $path]
    }
    catch { set L [lsort -index 0 -increasing -real $L] }
    set objs [list]
    foreach el $L {
      foreach {- obj} $el { break }
      lappend objs $obj
    }
    tb::mac configure -repo $root
    tb::mac set $name $objs
    # Save LOC information of cells involved in those paths
    set info [dict create]
    foreach path $objs {
      set slack [get_property -quiet SLACK $path]
      foreach cell [get_cells -quiet -of $path] {
        if {[dict exists $info $cell]} { continue }
        set ref [get_property -quiet REF_NAME $cell]
        set loc [get_property -quiet LOC $cell]
        set level [get_property -quiet LOGIC_LEVELS $path]
        if {$loc == {}} { continue }
        dict set info $cell [dict create slack $slack ref $ref loc $loc level $level]
      }
    }
    # Dump cells location into file
    set FH [open ${name}.loc {w}]
    foreach key [dict keys $info] {
      set slack [dict get $info $key slack]
      set loc [dict get $info $key loc]
      set ref [dict get $info $key ref]
      set level [dict get $info $key level]
      puts $FH [format "set_property -quiet LOC %s \t \[get_cells -quiet {%s} \] ; \t # SLACK=%s \t REF_NAME=%s \t LOGIC_LEVELS=%s" $loc $key $slack $ref $level]
    }
    close $FH
  } errorstring]} {
    puts " ERROR (export_timing_paths): $errorstring"
  }
}

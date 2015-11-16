
######################################################################
#
# Take a design snapshot
#
######################################################################

proc snapit {db dir project version experiment step directive} {
  if {[catch {
    snapshot configure -db $db -project $project -version $version -experiment $experiment -step $step

    set spaths [get_timing_paths -quiet -nworst 1 -max_path 1000 -slack_lesser_than 0.0 -setup]
    catch { ::tb::report_path_analysis -of $spaths         -sort_by tns -setup -file $dir/report_path_analysis.setup.${step}.${directive}.rpt }
    catch { ::tb::report_path_analysis -of $spaths -R -csv -sort_by tns -setup -file $dir/report_path_analysis.setup.${step}.${directive}.csv }
#     catch { snapshot addfile report_path_analysis.setup.csv $dir/report_path_analysis.setup.${step}.${directive}.csv }
    catch { snapshot addfile report_path_analysis.setup.rpt $dir/report_path_analysis.setup.${step}.${directive}.rpt }

    set hpaths [get_timing_paths -quiet -nworst 1 -max_path 1000 -slack_lesser_than 0.0 -hold]
    catch { ::tb::report_path_analysis -of $hpaths         -sort_by tns -hold -file $dir/report_path_analysis.hold.${step}.${directive}.rpt }
    catch { ::tb::report_path_analysis -of $hpaths -R -csv -sort_by tns -hold -file $dir/report_path_analysis.hold.${step}.${directive}.csv }
#     catch { snapshot addfile report_path_analysis.hold.csv $dir/report_path_analysis.hold.${step}.${directive}.csv }
   catch { snapshot addfile report_path_analysis.hold.rpt $dir/report_path_analysis.hold.${step}.${directive}.rpt }

    snapshot set directive $directive
    snapshot set rundir $dir
    snapshot extract -save
    # Save report_design_analysis report
    catch {
      set FH [open $dir/report_design_analysis.${step}.rpt {w}]
      puts $FH [snapshot get report.design_analysis]
      close $FH
    }
    # Reset snapshot
    snapshot reset
  } errorstring]} {
    puts "ERROR - $errorstring"
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
         lappend inpaths [get_timing_paths -quiet -to $RAM -max_paths 1]
  }
  foreach RAM [get_cells -quiet -hier -filter {REF_NAME=~RAMB*}] {
         lappend outpaths [get_timing_paths -quiet -from $RAM -through [get_pins -of $RAM -filter REF_PIN_NAME=~*DOUT*] -max_paths 1]
  }
  catch { ::tb::report_path_analysis -of $inpaths         -setup -file $dir/RAM_input_timing_${tag}.rpt }
  catch { ::tb::report_path_analysis -of $inpaths -R -csv -setup -file $dir/RAM_input_timing_${tag}.csv }
  catch { ::tb::report_path_analysis -of $outpaths         -setup -file $dir/RAM_output_timing_${tag}.rpt }
  catch { ::tb::report_path_analysis -of $outpaths -R -csv -setup -file $dir/RAM_output_timing_${tag}.csv }
  catch { export_timing_paths $inpaths RAM_input_timing_${tag} $dir }
  catch { export_timing_paths $outpaths RAM_output_timing_${tag} $dir }

  # Generate FIFO input/output timing
  set outpaths {}
  set inpaths {}
  foreach FIFO [get_cells -quiet -hier -filter {REF_NAME=~FIFO*}] {
         lappend inpaths [get_timing_paths -quiet -to $FIFO -max_paths 1]
  }
  foreach FIFO [get_cells -quiet -hier -filter {REF_NAME=~FIFO*}] {
         lappend outpaths [get_timing_paths -quiet -from $FIFO -through [get_pins -of $FIFO -filter REF_PIN_NAME=~*DOUT*] -max_paths 1]
  }
  catch { ::tb::report_path_analysis -of $inpaths         -setup -file $dir/FIFO_input_timing_${tag}.rpt }
  catch { ::tb::report_path_analysis -of $inpaths -R -csv -setup -file $dir/FIFO_input_timing_${tag}.csv }
  catch { ::tb::report_path_analysis -of $outpaths         -setup -file $dir/FIFO_output_timing_${tag}.rpt }
  catch { ::tb::report_path_analysis -of $outpaths -R -csv -setup -file $dir/FIFO_output_timing_${tag}.csv }
  catch { export_timing_paths $inpaths FIFO_input_timing_${tag} $dir }
  catch { export_timing_paths $outpaths FIFO_output_timing_${tag} $dir }

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

proc export_timing_paths { objs {name {default}} {root {}} } {
  set cmds [o2c $objs]
  if {$cmds == {}} {
    puts " error - no primary Vivado object(s)"
    return {}
#     error " error - no primary Vivado object"
  }
#   puts $cmds
  set proc [format "proc %s {} \{ " $name]
  append proc "\n proc T obj { upvar 1 L L; if {\$obj != {}} { lappend L \$obj } else { error {} } } "
  append proc "\n set L \[list\]; set error 0 "
  foreach cmd $cmds {
    append proc [format "\n if {\[catch {T \[%s\]} errorstring\]} { incr error } " $cmd]
  }
  append proc [format "\n if {\$error} { puts \" Warning - \$error objects were not found\" } "]
  append proc [format "\n return \$L \n\} "]
#   puts "<$proc>"
  # create the proc inside the global namespace
  uplevel #0 [list eval $proc]
  puts -nonewline " Created proc $name"
  if {[catch {
  	if {$root == {}} {
      set FH [open ${name}.mac {w}]
  	} else {
      set FH [open ${root}/${name}.mac {w}]
  	}
    puts $FH $proc
    close $FH
  	if {$root == {}} {
      puts " ... saved ${name}.mac"
    } else {
      puts " ... saved ${root}/${name}.mac"
    }
  } errorstring]} {
    puts "\n$errorstring"
  }
#   puts $proc
}

# Generate commands from objects
proc o2c { objs } {
  set cmds [list]
  switch [llength [get_property -quiet CLASS $objs]] {
    0 {
      puts " error - no primary Vivado object(s)"
      return {}
#       error " error - no primary Vivado object"
    }
    1 {
      # A single object needs to be put in a Tcl list
      set objs [list $objs]
    }
    default {
    }
  }
  set CLASS [lsort -unique [get_property -quiet CLASS $objs]]
  set flag 1
  if {[llength $CLASS] == 1} {
    set flag 0
  }
  foreach obj $objs {
    set cmd {}
    if {$flag} { set CLASS [get_property -quiet CLASS $obj] }
# puts "<$obj><$CLASS>"
    switch $CLASS {
      cell {
        set cmd [format {get_cells -quiet {%s}} $obj]
      }
      pin {
        set cmd [format {get_pins -quiet {%s}} $obj]
      }
      port {
        set cmd [format {get_ports -quiet {%s}} $obj]
      }
      net {
        set cmd [format {get_nets -quiet {%s}} $obj]
      }
      site {
        set cmd [format {get_sites -quiet {%s}} $obj]
      }
      site_pin {
        set cmd [format {get_site_pins -quiet {%s}} $obj]
      }
      timing_path {
# puts "<obj:$obj>[report_property $obj]"
        set startpin [get_property -quiet STARTPOINT_PIN $obj]
        set endpin [get_property -quiet ENDPOINT_PIN $obj]
#         set nets [get_nets -quiet -of $obj]
        set nets [get_nets -quiet -of $obj -top_net_of_hierarchical_group -filter {TYPE == SIGNAL}]
# puts "<startpin:$startpin><endpin:$endpin><nets:$nets>"
        set cmd [format {get_timing_paths -quiet -from [get_pins -quiet {%s}] -to [get_pins -quiet {%s}] -through [get_nets -quiet [list %s]]} $startpin $endpin $nets]
      }
      default {
        puts " -W- skipping object $obj"
      }
    }
    # Convert {{->{ and }}->}
    regsub -all "{{" $cmd "{" cmd
    regsub -all "}}" $cmd "}" cmd
#     puts "<$cmd>"
    lappend cmds $cmd
  }
  return $cmds
}

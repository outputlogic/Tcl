
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


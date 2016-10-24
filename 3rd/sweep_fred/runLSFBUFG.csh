set curDir=`pwd`

source /wrk/xsjhdnobkup3/frederi/customers/baidu_xiphy/setupSandbox.csh

#  foreach crX (0 1 2 3 4 5)
#  foreach crY (0 1 2 3 4 5 6 7 8 9)
#  foreach riu (0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 18 19 20 21 22 23)

foreach release (2016.3)
 foreach placeDirective (Default)
  foreach routeDirective (Default)
   foreach crX (2)
    foreach crY (0)
     foreach div (0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 18 19 20 21 22 23)
       #set runDir="$curDir/${placeDirective}_route${routeDirective}_CRX${crX}Y${crY}_sandbox1010_${release}"
       set runDir="$curDir/bufg_sweep/CRX${crX}Y${crY}_div${div}_sandbox1210_${release}"
       mkdir -p $runDir
       cd $runDir
       set vivadoPath=/proj/xbuilds/${release}_daily_latest/installs/lin64/Vivado/${release}/bin
       bsub -P swapps_2013.x -app sil_rhel6 -o /dev/null -q long -R "rusage[mem=16000]" $vivadoPath/vivado -source $curDir/runLSFBUFG.tcl -mode batch -log $runDir/vivado.log -nojournal -tclargs $runDir -tclargs $placeDirective -tclargs $routeDirective -tclargs $crX -tclargs $crY -tclargs $div
       cd $curDir
      #end
     end
    end
   end
  end
 end
end

#   *  Explore - Run multiple passes of optimization to improve results.
#
#   *  ExploreArea - Run multiple passes of optimization, with an emphasis on
#      reducing area.
#
#   *  ExploreSequentialArea - Run multiple passes of optimization, with an
#      emphasis on reducing registers and related combinational logic.
#
#   *  AddRemap - Run the default optimization, and include LUT remapping to
#      reduce logic levels.

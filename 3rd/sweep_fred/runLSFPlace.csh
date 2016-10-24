set curDir=`pwd`

source /wrk/xsjhdnobkup3/frederi/customers/baidu_xiphy/setupSandbox.csh

foreach release (2016.3)
 foreach placeDirective (Default)
  foreach routeDirective (Default)
   foreach crX (0 1 2 3 4 5)
    foreach crY (0 1 2 3 4 5 6 7 8 9)
     set runDir="$curDir/clockroot_sweep/CRX${crX}Y${crY}_sandbox1210_${release}"
     mkdir -p $runDir
     cd $runDir
     set vivadoPath=/proj/xbuilds/${release}_daily_latest/installs/lin64/Vivado/${release}/bin
     bsub -P swapps_2013.x -app sil_rhel6 -o /dev/null -q short -R "rusage[mem=12000]" $vivadoPath/vivado -source $curDir/runLSFPlace.tcl -mode batch -log $runDir/vivado.log -nojournal -tclargs $runDir -tclargs $placeDirective -tclargs $routeDirective -tclargs $crX -tclargs $crY
     cd $curDir
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

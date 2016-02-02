#!/bin/csh -f

set release=2016.1
set vivadoPath=/proj/xbuilds/${release}_daily_latest/installs/lin64/Vivado/${release}/bin
set fisPath0=/proj/rdi-xco/fisusr/no_backup/ABELite/Results
set fisPath1=/proj/fisdata/fisusr/no_backup/RDI_fisusr_olympus1
set fisRun=20160128
set curDir=`pwd`

#foreach log ($fisPath0/DIET_MT8_VIVADO_PR_US/*/TEST_WORK_*_${fisRun}_*_lnx64.OUTPUT $fisPath0/DIET_MT8_VIVADO_NDA_PR_US/*/TEST_WORK_*_${fisRun}_*_lnx64.OUTPUT $fisPath0/DIET_MT8_VIVADO_NDA_PR_US_SSI/*/TEST_WORK_*_${fisRun}_*_lnx64.OUTPUT)
foreach log ($fisPath0/US_CUSTOMER/*/TEST_WORK_${fisRun}_*_lnx64.OUTPUT)
echo "<log:$log>"
  set suiteName=`echo $log | sed -r 's,.*/([^/]+)/([^/]+)/TEST_WORK_.*_lnx64.OUTPUT,\1,g'`
  set dsgName=`echo $log | sed -r 's,.*/([^/]+)/([^/]+)/TEST_WORK_.*_lnx64.OUTPUT,\2,g'`
  set runDir="$curDir/${suiteName}_${dsgName}_${release}"
echo "<suiteName><$suiteName>"
echo "<dsgName><$dsgName>"
echo "<runDir><$runDir>"
#   mkdir -p $runDir
#   cd $runDir
#   bsub -P swapps_2013.x -app sil_rhel5 -o /dev/null -q short -R "rusage[mem=16000]" $vivadoPath/vivado -source $curDir/runLSF.tcl -mode batch -tclargs $runDir -tclargs $log -tclargs $dsgName
#   cd $curDir
end


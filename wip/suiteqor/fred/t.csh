#!/bin/csh -f

set release=2016.1
set vivadoPath=/proj/xbuilds/${release}_daily_latest/installs/lin64/Vivado/${release}/bin
set fisPath0=/proj/rdi-xco/fisusr/no_backup/ABELite/Results
set fisPath1=/proj/fisdata/fisusr/no_backup/RDI_fisusr_olympus1
set fisRun=20160128
set curDir=`pwd`

foreach log ($fisPath0/US_CUSTOMER/*/TEST_WORK_${fisRun}_*_lnx64.OUTPUT)
  echo ""
  echo $log
  set dsgName=`echo $log | sed -r 's,.*/([^/]+)/TEST_WORK_.*_lnx64.OUTPUT,\1,g'`
  echo $dsgName
end



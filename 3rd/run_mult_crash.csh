#!/bin/csh -f

# USEAGE /proj/xirsqa/impflow/austino/bin/run_mult_crash.csh 3 irte2.zip tclexeclog.tcl 2015.1_0424_1

set no_to_loop = $1
set zip_file = $2
set runtcl = $3
set vivado_version = $4
foreach x (`seq $1`)
rm -rf run$x
echo "Running iteration $x in run$x"
mkdir run_${vivado_version}_$x
cd run_${vivado_version}_$x
cp ../$zip_file .
unzip $2
touch run.csh
echo "alias cadman 'eval /tools/xint/prod/bin/cad.pl \\!*'" | sed -e 's:eval :eval \`:' | sed -e 's:\*:\*\`:' >> run.csh
echo "cadman add -t xilinx -p ta -v $vivado_version" >> run.csh
echo "vivado -mode batch -source $runtcl" >> run.csh
bsub -q long -R 'rusage[mem=10000]' 'source run.csh'
cd ../
end

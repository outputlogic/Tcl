set rootDir /wrk/xsjhdnobkup3/frederi/customers/baidu_xiphy/mig_crsweep
set design mig_cdg_sweep
vivadoQoR ${rootDir}/${design}.csv [glob ${rootDir}/*_2016.3/vivado.log] 0 4

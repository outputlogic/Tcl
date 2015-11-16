proc get_levels_of_logic {num_paths num_per_endpoint clk_group} {
    unset -nocomplain path_histo
    set path_cnt 0
    foreach p [get_timing_paths -max_paths $num_paths -nworst $num_per_endpoint -group $clk_group] {
	set pathlen [get_property LOGIC_LEVELS $p]
	
	if { $pathlen > 10} {
	    set pathlen 10
	}
	
	incr path_histo($pathlen)
	incr path_cnt
    }
    puts "Total paths analyzed: $path_cnt"
    for {set i 0} {$i <= 10} {incr i} {
	if {![info exists path_histo($i)]} {
	    set path_histo($i) 0
	}
	if {$i < 10} {
	    puts "Number of paths with $i levels of logic: $path_histo($i)"
	} else {
	    puts "Number of paths with $i levels of logic or more: $path_histo($i)"
	}
    }
}

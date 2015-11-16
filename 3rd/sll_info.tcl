
# From John Bieker

proc sll_info {args} {

set option $args

if {$args == "-help" || $args == ""} {
  puts "sll_info"
  puts "Usage:"
  puts "  -columns: report sll usage by clock region column"
  puts "  -slrs:    report sll usage by slr"
} else {

  set rpt_filename sll_info.rpt
  set rpt_file [open $rpt_filename w]

  set num_cols [llength [get_clock_regions -quiet *Y0]]
  set num_slrs [llength [get_slrs -quiet]]

  ### sll_info_ary is an array of the number of slls going from the SLR to the next adjacent SLR to the north
  for {set slr 0} {$slr < $num_slrs-1} {incr slr} {
    for {set col 0} {$col < $num_cols} {incr col} {
      set sll_info_ary(${slr}_${col}) 0
    }
  }


  for {set fromSlr 0} {$fromSlr < $num_slrs} {incr fromSlr} {
    for {set toSlr 1} {$toSlr < $num_slrs} {incr toSlr} {
      if {$fromSlr < $toSlr} {
        puts "***************** FROM SLR${fromSlr} TO SLR${toSlr} ***********************"
        if {$option == "-columns"} {
          puts $rpt_file "***************** FROM SLR${fromSlr} TO SLR${toSlr} ***********************"
        }
        for {set col 0} {$col < $num_cols} {incr col} {

          set from_nets [get_nets -quiet -of [get_nodes -quiet -of [get_tiles LAGUNA_TILE_X*Y* -quiet -of [get_clock_regions -quiet X${col}* -of [get_slrs -quiet SLR${fromSlr}]]] -filter {NAME =~ *BUMP*}]]
          set from_nets [lsort -uniq [get_property -quiet parent $from_nets]]

          set to_nets [get_nets -quiet -of [get_nodes -quiet -of [get_tiles LAGUNA_TILE_X*Y* -quiet -of [get_clock_regions -quiet X${col}* -of [get_slrs -quiet SLR${toSlr}]]] -filter {NAME =~ *BUMP*}]]
          set to_nets [lsort -uniq [get_property -quiet parent $to_nets]]

          set xnets [list]

          foreach net $from_nets {
            if {[lsearch -sorted $to_nets $net] >= 0} {
              lappend xnets $net
            }
          }

          set xnets_ary(${fromSlr}_${toSlr}_${col}) [get_nets -quiet $xnets]
          puts "SLL xing from SLR${fromSlr} to SLR${toSlr} in ClockRegion Column X${col} number of nets [llength $xnets_ary(${fromSlr}_${toSlr}_${col})]"
          if {$option == "-columns"} {
            puts $rpt_file "***************************************************************************"
            puts $rpt_file "SLL xing from SLR${fromSlr} to SLR${toSlr} in ClockRegion Column X${col} number of nets [llength $xnets_ary(${fromSlr}_${toSlr}_${col})]"
	    puts $rpt_file "List of SLLs xing from SLR${fromSlr} to SLR${toSlr} in ClockRegion Column X${col}"
	    puts $rpt_file [join $xnets_ary(${fromSlr}_${toSlr}_${col}) \n]
	    show_objects -quiet $xnets_ary(${fromSlr}_${toSlr}_${col}) -name sll_from_SLR${fromSlr}_to_SLR${toSlr}_Col_X${col}
	  }

	  for {set slr 0} {$slr < $num_slrs-1} {incr slr} {
	    if {$fromSlr <= $slr && $toSlr > $slr} {
              set sll_info_ary(${slr}_${col}) [expr $sll_info_ary(${slr}_${col}) + [llength $xnets_ary(${fromSlr}_${toSlr}_${col})]]
              lappend sll_info_ary(nets_${slr}_${col}) $xnets_ary(${fromSlr}_${toSlr}_${col})
	    }
	  }

        }
      }
    }
  }

  for {set slr 0} {$slr < $num_slrs-1} {incr slr} {
      set next_slr [expr $slr + 1]
      puts "**** TOTAL CROSSINGS PER SLR BOUNDARY FROM SLR${slr} TO SLR${next_slr} ****"
    for {set col 0} {$col < $num_cols} {incr col} {
      if {$option == "-columns"} {
        puts "The total number of SLL crossings from SLR${slr} to SLR${next_slr} in ClockRegion Column X${col} is $sll_info_ary(${slr}_${col})"
        puts $rpt_file "***************************************************************************"
        puts $rpt_file "The total number of SLL crossings from SLR${slr} to SLR${next_slr} in ClockRegion Column X${col} is $sll_info_ary(${slr}_${col})"
        puts $rpt_file [join [lsort $sll_info_ary(nets_${slr}_${col})] \n]
        show_objects -quiet $sll_info_ary(nets_${slr}_${col}) -name sll_from_SLR${slr}_to_SLR${next_slr}_Col_X${col}
      } elseif {$option == "-slrs"} {
          lappend sll_info_ary(nets_${slr}) $sll_info_ary(nets_${slr}_${col})
          if {$col == $num_cols-1} {
            set sll_info_ary(${slr}) [llength $sll_info_ary(nets_${slr})]
            puts "The total number of SLL crossings from SLR${slr} to SLR${next_slr} is $sll_info_ary(${slr})"
            puts $rpt_file "***************************************************************************"
            puts $rpt_file "The total number of SLL crossings from SLR${slr} to SLR${next_slr} is $sll_info_ary(${slr})"
            puts $rpt_file [join [lsort $sll_info_ary(nets_${slr})] \n]
            show_objects -quiet $sll_info_ary(nets_${slr}) -name sll_from_SLR${slr}_to_SLR${next_slr}
          }
      }
    }
  }

  close $rpt_file
  }

}

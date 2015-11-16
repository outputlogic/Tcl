proc slr_xing {from to} {

  set fromSlr "SLR${from}"
  set toSlr "SLR${to}"
  set from_cells [get_cells -of [get_sites -of [get_slrs $fromSlr]]]
  set from_nets [get_nets -of $from_cells -filter {TYPE == SIGNAL && ROUTE_STATUS != INTRASITE}]
  set from_nets [lsort -uniq [get_property parent $from_nets]]

  set to_cells [get_cells -of [get_sites -of [get_slrs $toSlr]]]
  set to_nets [get_nets -of $to_cells -filter {TYPE == SIGNAL && ROUTE_STATUS != INTRASITE}]
  set to_nets [lsort -uniq [get_property parent $to_nets]]

  set xnets [list]
  foreach net $from_nets {
    if {[lsearch -sorted $to_nets $net] >= 0} {
      lappend xnets $net
    }
  }
  set xnets [get_nets $xnets]

  puts "number of nets [llength $xnets]"
  puts "[join $xnets \n]"

  #sel $xnets
  return $xnets
}


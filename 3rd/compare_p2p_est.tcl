# From Brendan
# Compare P2P delays vs estimated delays

# Input file should have format such as:
#   SLICE_X50Y300 AQ,SLICE_X50Y298 E5
#   SLICE_X82Y159 G_O,SLICE_X83Y159 B1
#   SLICE_X48Y180 DQ2,SLICE_X48Y184 E2
#   SLICE_X125Y330 BQ,SLICE_X126Y330 C1
#   SLICE_X107Y492 C_O,SLICE_X107Y492 D1
#   SLICE_X81Y408 DQ,SLICE_X81Y408 H1
#   SLICE_X33Y220 HQ2,SLICE_X33Y220 A2
#   SLICE_X48Y101 B_O,SLICE_X47Y101 C1
#   SLICE_X28Y253 D_O,SLICE_X28Y253 G2
#   SLICE_X38Y167 BQ,SLICE_X36Y167 C1
#   SLICE_X133Y116 E_O,SLICE_X133Y116 H2
#   SLICE_X103Y71 H_O,SLICE_X103Y71 E6
#   SLICE_X86Y340 BQ2,SLICE_X88Y340 G1
#   SLICE_X99Y402 A_O,SLICE_X96Y402 E1

# Output results are:
#   SLICE_X56Y212 F_O,SLICE_X56Y274 E6,1064,1163,0.91,99
#   SLICE_X86Y224 AQ2,SLICE_X79Y289 C6,1306,1422,0.92,116
#   SLICE_X82Y276 AMUX,SLICE_X83Y223 E5,1188,1271,0.93,83
#   SLICE_X49Y327 AQ2,SLICE_X74Y311 B6,1213,1274,0.95,61
#   SLICE_X59Y293 E_O,SLICE_X60Y224 HX,1251,1352,0.93,101
#   SLICE_X73Y275 E_O,SLICE_X61Y215 F_I,1345,1455,0.92,110
#   SLICE_X82Y184 DQ,SLICE_X79Y311 D5,2063,2020,1.02,43
#   SLICE_X91Y85 A_O,SLICE_X90Y140 B6,942,861,1.09,81
#   SLICE_X59Y237 AMUX,SLICE_X56Y303 HX,1227,1317,0.93,90
#   SLICE_X48Y323 EQ2,SLICE_X72Y307 F5,1231,1285,0.96,54


#
# proc to extract site-pin-pairs from timing-path tcl objects
#
proc print_path_site_pins {paths fout} {
    
    foreach path $paths {
        puts "next path"
        set pins [get_pins -of $path]
        set num_pairs [expr {[llength $pins] / 2} ]
        for {set i 0} {$i < $num_pairs} {incr i} {
            set double_i [expr {$i * 2}]
            set p1 [lindex $pins $double_i]
            set p2 [lindex $pins [expr {$double_i + 1}]]

            set sp1 [lindex [get_site_pins -of $p1] 0]
            set sp2 [lindex [get_site_pins -of $p2] 0]
            
            if {$sp1 != "" && $sp2 != ""} {
                set dir1 [get_property direction $sp1]
                set dir2 [get_property direction $sp2]
                if {$dir1 != "OUT"} {
                    error "$sp1 is direction $dir1, should be OUT";
                }
                if {$dir2 != "IN"} {
                    error "$sp2 is direction $dir1, should be IN";
                }
                puts "$sp1 to $sp2"
                set spaced1 [string map {/ " "} $sp1]
                set spaced2 [string map {/ " "} $sp2]
                puts $fout "$spaced1,$spaced2"
            } else {
                # we can have site pin for the driver of intra-site path 
                # since LUT output can come out on E_O e.g.
#                 if {$sp1 != ""} {
#                     error "site pin $sp1 for $p1, but no site pin for $p2";
#                 } 
#                 if {$sp2 != ""} {
#                     error "site pin $sp2 for $p2, but no site pin for $p1";
#                 } 
            }

        }
    }  
}

#
# parse arguments passed through -tclargs
#

#
# Phase 2 : call estimator and p2p on the site-pin-pairs
#
set targetPart xcvu160-flgb2104-2-e-es2

puts "open empty design on part $targetPart to test estimation"
link_design -part $targetPart

puts "parsing pairs.crit"

set dollar1 {$1}
set dollar2 {$2}
set data [exec cat pairs.crit | awk -F, "{print  $dollar1 \" \" $dollar2}"]

puts $data

set numTokens [llength $data]
set numLines [expr $numTokens/4]

set fout [open "compare.table" w]
puts $fout "from,to,estDly,p2pDly,ratio,absErr"

puts "call estimator and p2p router on each site-pin-pair"


for {set i 0} {$i < $numLines} {incr i} {

    set lineIdx [expr $i*4]
    set arg1 [lindex $data $lineIdx]
    set arg2 [lindex $data [expr $lineIdx+1]]
    set arg3 [lindex $data [expr $lineIdx+2]]
    set arg4 [lindex $data [expr $lineIdx+3]]
    puts "$arg1 $arg2 $arg3 $arg4"
    set from "$arg1 $arg2"
    set to   "$arg3 $arg4"
    set p2pDly [internal::route_dbg_p2p_route -removeLUTPinDelay -disableGlobals -from $from -to $to]

    set catchResult [catch {::internal::report_est_wire_delay -from $from -to $to} estResult]
    if {$catchResult} {        
        puts "ERROR: $result"
    } else {
        puts "delay from $from to $to is est: $estResult  p2p: $p2pDly"
        # avoid divide-by-zero
        if {$estResult == 0 || $estResult eq ""} {set estResult 1}
        if {$p2pDly == 0 || $p2pDly eq ""} {set p2pDly 1}
        set ratio [format %.2f [expr {(1.0*$estResult)/$p2pDly}]]
        set abs [expr {abs($estResult-$p2pDly)}]

        puts $fout "$from,$to,$estResult,$p2pDly,$ratio,$abs"
    }
}
close $fout

puts "wrote .csv data on estimation accuracy to file compare.table"

puts "compare.table may be imported to excel"

puts "or grep 'delay from' out of vivado.log to see only the estimated vs. p2p delays"


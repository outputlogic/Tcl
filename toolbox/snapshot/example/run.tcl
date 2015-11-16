
# catch {namespace delete ::tb::snapshot}

# lappend auto_path {C:\Xilinx\lib}
# source -notrace snapshot.tcl

proc ::tb::snapshot::extract::design {} {
  variable [namespace parent]::params
  variable [namespace parent]::verbose
  variable [namespace parent]::debug
  snapshot set design.numNets [llength [get_nets -quiet -hier]]
  snapshot set design.numCells [llength [get_cells -quiet -hier]]
}

    proc ::tb::snapshot::extract::metric1 {} {
      variable [namespace parent]::params
      variable [namespace parent]::verbose
      variable [namespace parent]::debug
#       print info "extracting metric1 (verbose:$verbose)"
      snapshot set metric1 foo1
      snapshot set metric2 foo2
#       parray params
    }
    proc ::tb::snapshot::extract::metric2 {} {
      variable [namespace parent]::verbose
      variable [namespace parent]::debug
#       print info "extracting metric2 (metric1:[snapshot get metric1])"
      snapshot set metric3 foo3
      snapshot set metric4 foo4
#       [namespace parent]::dump
    }

proc ::tb::snapshot::extract::metric3 {} {
  variable [namespace parent]::params
  variable [namespace parent]::verbose
  variable [namespace parent]::debug
  puts " -I- extracting metric3 (verbose:$verbose)"
  snapshot set metric5 foo5
  snapshot set metric6 foo6a foo6b foo6c
  snapshot set metric7 [list foo7a foo7b foo7c]
  snapshot set metric8 [report_timing -help]
#   parray params
}



snapshot reset
snapshot configure -verbose -log metrics.log -db ./foo.db
# snapshot configure -verbose -nodebug -newdb
snapshot set misc1 {this is ' , " metric1}
snapshot set misc2 [list a b c]
snapshot set misc3 {this is \{ , metric3}
snapshot set misc4 [info procs]
snapshot set misc5 [format {This is a \nmultiple \nlines metric value}]
snapshot set misc6 "This is another \"example\" , of \nmultiple \nlines metric value"
set str "This is another example of \nmultiple \nlines metric value"
snapshot set misc7 $str
snapshot set misc8 [list a b c] [list 1 2 3] [list ! @ , ^]
snapshot set misc9 [list [list a b c] [list 1 2 3] [list ! @ , ^ \"] ]
snapshot addfile file1 ./foo
# snapshot set metric2 [help -help]
# snapshot set metric3 [help report_timing]
snapshot extract -time [file atime calc.tcl] -desc {This is a new snapshot} -rel {2014.1} -step {mystep} -project {myproject} -run {} -experiment {myexpriment}
set id [snapshot save]

catch {unset foo}
# snapshot reset
snapshot db2array foo $id

::tb::snapshot::dbreport

snapshot configure -nolog




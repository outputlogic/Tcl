###  #!/usr/bin/tclsh


####################################################################################
####################################################################################
####################################################################################


set perform_phys_opt 1
set synth_flow {Vivado Synthesis 2013}
set impl_flow {Vivado Implementation 2013}


####################################################################################
####################################################################################
####################################################################################



#Vivado Synthesis 2013
#Vivado Implementation 2013
proc getFlow {type} {
   if {$type=="synth"} {
      set vv [version -short]
      regexp {^([0-9]+)} $vv year
      set flow "Vivado Synthesis ${year}"
      return $flow
   } elseif { $type=="impl" } {
      set vv [version -short]
      regexp {^([0-9]+)} $vv year
      set flow "Vivado Implementation ${year}"
      return $flow
   } else {
      puts "ERROR: Not a supported flow type"
      return "";
   }
}


proc create_dummy_runs {} {
   create_run -flow {Vivado Synthesis 2013} synth_dummy
   create_run -flow {Vivado Implementation 2013} -parent_run synth_dummy impl_dummy
   current_run [get_run synth_dummy]
   foreach run [get_runs -filter {NAME!~*dummy&&IS_SYNTHESIS}] {
      delete_run [get_run $run]
   }
}

proc delete_dummy_runs {} {
   foreach run [get_runs -filter {NAME=~*dummy&&IS_SYNTHESIS}] {
      delete_run [get_run $run]
    }
}




puts "Very Important Warning: This script is not a patch for poor RTL coding and/or poor XDC constraints"
set start_time [exec date]
puts "Start Time: $start_time"


create_dummy_runs

set synth_directives [list_property_value STEPS.SYNTH_DESIGN.ARGS.DIRECTIVE [get_runs synth_dummy]]

set place_directives [list_property_value STEPS.PLACE_DESIGN.ARGS.DIRECTIVE [get_runs impl_dummy]]
set place_directives [lsearch -all -inline -not -exact $place_directives Quick]

set phys_opt_directives [list_property_value STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE [get_runs impl_dummy]]

set route_directives [list_property_value STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE [get_runs impl_dummy]]
set route_directives [lsearch -all -inline -not -exact $route_directives Quick]


foreach synth $synth_directives {
	set run_name "synth_${synth}"
	create_run $run_name -flow [getFlow synth]
	puts "Created Synthesis run: $run_name"
}

foreach synth_run [get_runs -filter {NAME!~*dummy&&IS_SYNTHESIS} ] {
   puts "Creating Child Implementation Runs for Synthesis Run: $synth_run"
   foreach place $place_directives {
      if { $perform_phys_opt } {
         foreach phys_opt $phys_opt_directives {
            foreach route $route_directives {
               set run_name "${synth_run}.${place}.${phys_opt}.${route}"
               create_run $run_name -parent_run $synth_run -flow [getFlow impl]
               puts "\tCreated Child Implementation Run: $run_name"
            }
         }
      } else {
         foreach route $route_directives {
            set run_name "${synth_run}.${place}.${route}"
            create_run $run_name -parent_run $synth_run -flow [getFlow impl]
            puts "\tCreated Child Implementation Run: $run_name"
         }
      }
   }
}

delete_dummy_runs



set end_time [exec date]
puts "Start Time: $start_time"
puts "End Time: $end_time"


####
####
####
#STEPS.SYNTH_DESIGN.TCL.PRE                         file     false      true     
#STEPS.SYNTH_DESIGN.TCL.POST                        file     false      true     
#STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY          enum     false      true     rebuilt
#STEPS.SYNTH_DESIGN.ARGS.GATED_CLOCK_CONVERSION     enum     false      true     off
#STEPS.SYNTH_DESIGN.ARGS.BUFG                       int      false      true     12
#STEPS.SYNTH_DESIGN.ARGS.FANOUT_LIMIT               int      false      true     10000
#STEPS.SYNTH_DESIGN.ARGS.DIRECTIVE                  enum     false      true     Default
#STEPS.SYNTH_DESIGN.ARGS.FSM_EXTRACTION             enum     false      true     auto
#STEPS.SYNTH_DESIGN.ARGS.KEEP_EQUIVALENT_REGISTERS  bool     false      true     0
#STEPS.SYNTH_DESIGN.ARGS.RESOURCE_SHARING           enum     false      true     auto
#STEPS.SYNTH_DESIGN.ARGS.CONTROL_SET_OPT_THRESHOLD  int      false      true     1
#STEPS.SYNTH_DESIGN.ARGS.NO_LC                      bool     false      true     0
#STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS               string   false      true     




#STEPS.OPT_DESIGN.IS_ENABLED                          bool     false      true     0
#STEPS.OPT_DESIGN.TCL.PRE                             file     false      true     
#STEPS.OPT_DESIGN.TCL.POST                            file     false      true     
#STEPS.OPT_DESIGN.ARGS.VERBOSE                        bool     false      true     0
#STEPS.OPT_DESIGN.ARGS.DIRECTIVE                      enum     false      true     Explore
#STEPS.OPT_DESIGN.ARGS.MORE OPTIONS                   string   false      true     
#STEPS.POWER_OPT_DESIGN.IS_ENABLED                    bool     false      true     0
#STEPS.POWER_OPT_DESIGN.TCL.PRE                       file     false      true     
#STEPS.POWER_OPT_DESIGN.TCL.POST                      file     false      true     
#STEPS.POWER_OPT_DESIGN.ARGS.MORE OPTIONS             string   false      true     
#STEPS.PLACE_DESIGN.TCL.PRE                           file     false      true     
#STEPS.PLACE_DESIGN.TCL.POST                          file     false      true     
#STEPS.PLACE_DESIGN.ARGS.NO_TIMING_DRIVEN             bool     false      true     0
#STEPS.PLACE_DESIGN.ARGS.NO_DRC                       bool     false      true     0
#STEPS.PLACE_DESIGN.ARGS.DIRECTIVE                    enum     false      true     Default
#STEPS.PLACE_DESIGN.ARGS.MORE OPTIONS                 string   false      true     
#STEPS.POST_PLACE_POWER_OPT_DESIGN.IS_ENABLED         bool     false      true     0
#STEPS.POST_PLACE_POWER_OPT_DESIGN.TCL.PRE            file     false      true     
#STEPS.POST_PLACE_POWER_OPT_DESIGN.TCL.POST           file     false      true     
#STEPS.POST_PLACE_POWER_OPT_DESIGN.ARGS.MORE OPTIONS  string   false      true     
#STEPS.PHYS_OPT_DESIGN.IS_ENABLED                     bool     false      true     0
#STEPS.PHYS_OPT_DESIGN.TCL.PRE                        file     false      true     
#STEPS.PHYS_OPT_DESIGN.TCL.POST                       file     false      true     
#STEPS.PHYS_OPT_DESIGN.ARGS.DIRECTIVE                 enum     false      true     Default
#STEPS.PHYS_OPT_DESIGN.ARGS.MORE OPTIONS              string   false      true     
#STEPS.ROUTE_DESIGN.TCL.PRE                           file     false      true     
#STEPS.ROUTE_DESIGN.TCL.POST                          file     false      true     
#STEPS.ROUTE_DESIGN.ARGS.NO_TIMING_DRIVEN             bool     false      true     0
#STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE                    enum     false      true     Default
#STEPS.ROUTE_DESIGN.ARGS.MORE OPTIONS                 string   false      true     
#STEPS.WRITE_BITSTREAM.TCL.PRE                        file     false      true     
#STEPS.WRITE_BITSTREAM.TCL.POST                       file     false      true     
#STEPS.WRITE_BITSTREAM.ARGS.RAW_BITFILE               bool     false      true     0
#STEPS.WRITE_BITSTREAM.ARGS.MASK_FILE                 bool     false      true     0
#STEPS.WRITE_BITSTREAM.ARGS.NO_BINARY_BITFILE         bool     false      true     0
#STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE                  bool     false      true     0
#STEPS.WRITE_BITSTREAM.ARGS.LOGIC_LOCATION_FILE       bool     false      true     0
#STEPS.WRITE_BITSTREAM.ARGS.MORE OPTIONS              string   false      true   

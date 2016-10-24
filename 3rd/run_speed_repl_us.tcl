#! /usr/bin/tclsh
################################################################################
# $Source: /home/duthv/scripts/TclApps/RCS/run_speed_repl.tcl,v $         
# $Revision: 1.3 $
# $Date: 2013/12/09 03:50:16 $
# $Author: duthv $
#
# Purpose: Extract the speeddata for each of the different speed params
# 
# $Log: run_speed_repl.tcl,v $
# Revision 1.3  2013/12/09 03:50:16  duthv
# updated to 2013.4
#
# Revision 1.2  2013/08/13 03:10:35  duthv
# added benchmark
#
# Revision 1.1  2013/07/29 01:05:34  duthv
# Initial revision
#
# Revision 1.3  2012/11/19 18:44:34  duthv
# changed value to value_type
#
# Revision 1.2  2012/11/19 18:36:26  duthv
# updated version
#
###############################################################################

# Namespace apps - begin
namespace eval apps {

#set type_name ""
### Namespace variables declaration ###

   proc return_unique_values { } {
      foreach foo [get_speed_models] {
         set current_type [get_property TYPE [get_speed_models -patterns $foo]]
         lappend type_name $current_type
      }
         return $type_name
   }       


   proc return_delay_values_us {value_type} {
      if {$value_type eq "SLOW_MAX" || $value_type eq "SLOW_MIN" || $value_type eq "FAST_MAX" || $value_type eq "FAST_MIN"} {
         puts "Collecting Information for $value_type...."
         set run_start [clock seconds]
         foreach foo [get_speed_models -filter {TYPE == bel_delay}] {
            set current_delay [get_property $value_type [get_speed_models -patterns $foo]]
            set delay_table($foo) $current_delay
         }
         set run_stop [clock seconds]
      } else {
            puts "ERROR: argument must be either SLOW_MIN, SLOW_MAX, FAST_MIN or FAST_MAX. Your value is $value_type"
         } 
      foreach i [array name delay_table] {
         puts "\n$value_type for $i is $delay_table($i)"
      }
      set run_time [expr \$run_stop-\$run_start]
      puts "\nRuntime for gettings delays is $run_time"
   }
   proc write_unique_types {} {
      set typ_name [return_unique_values]
      foreach line [lsort -unique $typ_name] {
         puts "TYPE is $line"
      }
   }
} 
# Namespace apps - end

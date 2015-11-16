#!/usr/bin/tclsh

########################################################################################
########################################################################################
########################################################################################

set debug 0

# Set your LSF queue
set lsf_queue long
# set lsf_queue medium
##USE FOR SSI DEVICES## set lsf_queue long

# Set your LSF Project
# set lsf_proj tsr_zte
set lsf_proj swapps_2013.x

# Set your estimated memory requirement for LSF in MB
# example: 4000 = 4GB
set lsf_mem 12000

# Do you want to run phys_opt_design directives?
# 0 = do not run phys_opt_design
# 1 = yes, run phys_opt_design directives
set run_phys_opt_design 1

# Set the opt_design or synth_design checkpoint here:
set dcp ./M1C4Lx4_TOP_opt.dcp

# Set the place_design directive list here:
##USE FOR SSI DEVICES## set place_design_directive SSI_place_directives
set place_design_directive monolithic_place_directives

# Set the phys_opt_design directive list here:
set phys_opt_design_directive phys_opt_directives

# Set the route_design directive list here:
set route_design_directive route_directives


# The template file from which to do the switches
set tmplFile_place place.tmpl.tcl
set tmplFile_phys_opt phys_opt.tmpl.tcl
set tmplFile_route route.tmpl.tcl


########################################################################################
########################################################################################
########################################################################################


set pwd [exec pwd]
puts "Executing from Directory: $pwd"

set dcp "${pwd}/${dcp}"


set place_design_directive "${pwd}/${place_design_directive}"
set phys_opt_design_directive "${pwd}/${phys_opt_design_directive}"
set route_design_directive  "${pwd}/${route_design_directive}"
set tmplFile_place  "${pwd}/${tmplFile_place}"
set tmplFile_phys_opt  "${pwd}/${tmplFile_phys_opt}"
set tmplFile_route  "${pwd}/${tmplFile_route}"

set lsf_uniq_id [exec date]
regsub -all " " $lsf_uniq_id "_" lsf_uniq_id
regsub -all ":" $lsf_uniq_id "_" lsf_uniq_id



puts "\tDesign Checkpoint File: $dcp"
puts "\tLSF Unique Identifier: $lsf_uniq_id"
puts "\tPlace Design Directive File: $place_design_directive"
puts "\tPhys Opt Design Directive File: $phys_opt_design_directive"
puts "\tRoute Design Directive File: $route_design_directive"
puts "\tPlace Template File: $tmplFile_place"
puts "\tPhys Opt Design Directive File: $tmplFile_phys_opt"
puts "\tRoute Template File: $tmplFile_route"


##
## For some reason I was having trouble nesting the reading of the files
## So I will just build arrays and nest the foreach of the arrays
##
##

set place_list [list]
puts "Building Place Directive Data Structure:"
set placeIn [open $place_design_directive "r"]
while { [gets $placeIn line] >=0 } {
	lappend place_list $line
	puts "\t$line"
}
close $placeIn


if {$run_phys_opt_design} {
	set phys_opt_list [list]
	puts "Building Phys Opt Directive Data Structure"
	set physOptIn [open $phys_opt_design_directive "r"]
	while { [gets $physOptIn line] >= 0 } {
		lappend phys_opt_list $line
        	puts "\t$line"
	}
	close $physOptIn
}


set route_list [list]
puts "Building Route Directive Data Structure"
set routeIn [open $route_design_directive "r"]
while { [gets $routeIn line] >=0 } {
	lappend route_list $line
	puts "\t$line"
}
close $routeIn



# Launch all place runs
# Launch all route runs, but have them wait for place to finish
# Saves disk space and LSF for placement versus old algorithm


set count 0
foreach place $place_list {
	# Launch all place runs
	# Launch all route runs, but have them wait for place to finish

	puts "Processing Place Directive: $place"
	set jobname "${place}"
	set directory "${pwd}/${jobname}"
	set filename "${directory}/${jobname}.tcl"
	set logfile "${directory}/${jobname}.log"
	set journalfile "${directory}/${jobname}.jou"
        set jobname "${place}_${lsf_uniq_id}"


        puts "\tTarget Directory: $directory"
        puts "\tTarget TCL File: $filename"
        puts "\tTarget log File: $logfile"
        puts "\tTarget jou File: $journalfile"
        puts "\tTarget LSF Job Name: $jobname"

	catch { eval exec "mkdir $directory" }

        set inFile [open $tmplFile_place "r"]
        set outFile [open $filename "w"]
	while { [gets $inFile line] >=0 } {
		regsub -all CHECKPOINT $line $dcp line
                regsub -all PLACE_DIRECTIVE $line $place line
                regsub -all DIRECTORY $line $directory line
		puts $outFile $line
	}
	close $inFile
	close $outFile
	incr count

	set cmd [list bsub -P $lsf_proj -app sil_rhel5 -o /dev/null -q $lsf_queue -J $jobname -R \"rusage\[mem=$lsf_mem\]\" vivado -mode batch -source $filename -log $logfile -jou $journalfile]
	if {!$debug} { eval exec $cmd } else { puts "\tLSF Command: $cmd" }

	set place_jobname $jobname
	set place_directory $directory
	set place_dcp "${directory}/postplace.dcp"


	if {$run_phys_opt_design} {
		foreach phys_opt $phys_opt_list {
			puts "Processing Place-Phys_Opt Directive Pair: $place $phys_opt"
			set jobname "${place}.${phys_opt}"
			set directory "${pwd}/${jobname}"
			set filename "${directory}/${jobname}.tcl"
        		set logfile "${directory}/${jobname}.log"
			set journalfile "${directory}/${jobname}.jou"
			set jobname "${jobname}_${lsf_uniq_id}"

                        puts "\tTarget Directory: $directory"
                        puts "\tTarget TCL File: $filename"
                        puts "\tTarget log File: $logfile"
                        puts "\tTarget jou File: $journalfile"
                        puts "\tTarget LSF Job Name: $jobname"
			puts "\tWait on Job Name: $place_jobname"

                        catch { eval exec "mkdir $directory" }
                        catch { eval exec "ln -s $place_directory/postplace.dcp $directory/postplace.dcp" }

        		set inFile [open $tmplFile_phys_opt "r"]
        		set outFile [open $filename "w"]
			while { [gets $inFile line] >=0 } {
				regsub -all PLACE_CHECKPOINT $line $place_dcp line
				regsub -all CHECKPOINT $line $directory/postplace.dcp line
        regsub -all PLACE_DIRECTIVE $line $place line
				regsub -all PHYS_OPT_DIRECTIVE $line $phys_opt line
				regsub -all DIRECTORY $line $directory line
                               puts $outFile $line
                        }
                        close $inFile
                        close $outFile

                        set cmd [list bsub -P $lsf_proj -app sil_rhel5 -o /dev/null -w \"$place_jobname\" -q $lsf_queue -J $jobname -R \"rusage\[mem=$lsf_mem\]\" vivado -mode batch -source $filename -log $logfile -jou $journalfile]
    	if {!$debug} { eval exec $cmd } else { puts "\tLSF Command: $cmd" }


			set phys_opt_directory $directory
			set phys_opt_jobname $jobname
			set phys_opt_dcp "${directory}/postphysopt.dcp"


			foreach route $route_list {
				puts "Processing Place-Phys_Opt-Route Directive Combination: $place $phys_opt $route"
				set jobname "${place}.${phys_opt}.${route}"
	                        set directory "${pwd}/${jobname}"
       		                set filename "${directory}/${jobname}.tcl"
        			set logfile "${directory}/${jobname}.log"
                        	set journalfile "${directory}/${jobname}.jou"

				puts "\tTarget Directory: $directory"
                        	puts "\tTarget TCL File: $filename"
                        	puts "\tTarget log File: $logfile"
                        	puts "\tTarget jou File: $journalfile"
                        	puts "\tTarget LSF Job Name: $jobname"
				puts "\tWait on Job Name: $phys_opt_jobname"

       	                 	catch { eval exec "mkdir $directory" }
	                        catch { eval exec "ln -s $phys_opt_directory/postphysopt.dcp $directory/postphysopt.dcp" }

                        	set inFile [open $tmplFile_route "r"]
                        	set outFile [open $filename "w"]
                        	while { [gets $inFile line] >=0 } {
					regsub -all PREROUTE_CHECKPOINT $line $phys_opt_dcp line
					regsub -all CHECKPOINT $line $directory/postphysopt.dcp line
          regsub -all PLACE_DIRECTIVE $line $place line
  				regsub -all PHYS_OPT_DIRECTIVE $line $phys_opt line
					regsub -all ROUTE_DIRECTIVE $line $route line
					regsub -all DIRECTORY $line $directory line
					puts $outFile $line
                        	}
                        	close $inFile
                        	close $outFile
                        	incr count

                        	set cmd [list bsub -P $lsf_proj -app sil_rhel5 -o /dev/null -w \"$phys_opt_jobname\" -q $lsf_queue -J $jobname -R \"rusage\[mem=$lsf_mem\]\" vivado -mode batch -source $filename -log $logfile -jou $journalfile]
	        if {!$debug} { eval exec $cmd } else { puts "\tLSF Command: $cmd" }
			}
		}
       	} else {
		foreach route $route_list {
			puts "Processing Place-Route Directive Pair: $place $route"
			set jobname "${place}.${route}"
 	      		set directory "${pwd}/${jobname}"
       			set filename "${directory}/${jobname}.tcl"
       			set logfile "${directory}/${jobname}.log"
       			set journalfile "${directory}/${jobname}.jou"
       
       			puts "\tTarget Directory: $directory"
       			puts "\tTarget TCL File: $filename"
       			puts "\tTarget log File: $logfile"
       			puts "\tTarget jou File: $journalfile"
       			puts "\tTarget LSF Job Name: $jobname"
			puts "\tWait on Job Name: $place_jobname"

       			catch { eval exec "mkdir $directory" }
       			catch { eval exec "ln -s $place_directory/postplace.dcp $directory/postplace.dcp" }

			set inFile [open $tmplFile_route "r"]
                        set outFile [open $filename "w"]
                        while { [gets $inFile line] >=0 } {
                        	regsub -all PREROUTE_CHECKPOINT $line $place_dcp line
                        	regsub -all CHECKPOINT $line $directory/postplace.dcp line
                          regsub -all PLACE_DIRECTIVE $line $place line
                        	regsub -all ROUTE_DIRECTIVE $line $route line
                        	regsub -all DIRECTORY $line $directory line
                        	puts $outFile $line
                        }
       			incr count
       			
			set cmd [list bsub -P $lsf_proj -app sil_rhel5 -o /dev/null -w \"$place_jobname\" -q $lsf_queue -J $jobname -R \"rusage\[mem=$lsf_mem\]\" vivado -mode batch -source $filename -log $logfile -jou $journalfile]
    	if {!$debug} { eval exec $cmd } else { puts "\tLSF Command: $cmd" }
       		}
	}
}
puts "##################################"
puts "Tool processed $count combinations"
puts "##################################"




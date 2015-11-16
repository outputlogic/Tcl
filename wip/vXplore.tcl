##########################################################
# vXplore
##########################################################
proc vXplore {args} {
	## Set Default option values
	array set opts {-help 0 -out_dir "vXplore" -log "vXplore.log" -step_count 2 -wait 60 -memory 10000 -queue "medium" -no_opt_design 0}
	
	## Set the command line used for the script
	set commandLine "vXplore $args"
    
	## Parse arguments from option command line
	while {[string match -* [lindex $args 0]]} {
        switch -regexp -- [lindex $args 0] {
            {-c(h(e(c(k(p(o(i(n(t)?)?)?)?)?)?)?)?)?$}             { set opts(-checkpoint)    [lshift args 1]}
			{-l(o(g)?)?$}                                         { set opts(-log)           [lshift args 1]}
			{-m(e(m(o(r(y)?)?)?)?)?$}                             { set opts(-memory)        [lshift args 1]}
			{-n(o(_(o(p(t(_(d(e(s(i(g(n)?)?)?)?)?)?)?)?)?)?)?)?$} { set opts(-no_opt_design) 1}
			{-o(u(t(_(d(i(r)?)?)?)?)?)?$}                         { set opts(-out_dir)       [lshift args 1]}
			{-p(h(y(s(_(o(p(t)?)?)?)?)?)?)?$}		              { set opts(-phys_opt)      1}
			{-q(u(e(u(e)?)?)?)?$}                                 { set opts(-queue)         [lshift args 1]}
			{-s(t(e(p(_(c(o(u(n(t)?)?)?)?)?)?)?)?)?$}             { set opts(-step_count)    [lshift args 1]}
			{-v(e(r(b(o(s(e)?)?)?)?)?)?$}    	                  { set opts(-verbose)       1}
			{-w(a(i(t)?)?)?$}                                     { set opts(-wait)          [lshift args 1]}
			{-h(e(l(p)?)?)?$}                                     { set opts(-help)          1}
            default {
                return -code error "ERROR: \[vXplore\] Unknown option '[lindex $args 0]', please type 'vXplore -help' for usage info."
            }
        }
        lshift args
    }

	## Display help information
    if {$opts(-help) == 1} {
        puts "vXplore\n"
        puts "Description:"
        puts "  Vivado SmartXplorer Equivalent"
        puts ""
        puts "Syntax:"
        puts "  vXplore \[-checkpoint <arg>\] \[-log <arg>\] \[-out_dir <arg>\]"
		puts "          \[-memory <arg>\] \[-out_dir <arg>\] \[-phys_opt\]"
		puts "          \[-queue <arg>\] \[-step_count <arg>\] \[-verbose\] \[-help\]"
        puts ""
        puts "Usage:"
        puts "  Name              Description"
        puts "  ------------------------------"
        puts "  -checkpoint       Design checkpoint file."
		puts "  \[-log\]            Write the report log into the specified file."
		puts "                    Default: vXplore.log"
		puts "  \[-memory\]         Requested Memory requirement for LSF job."
		puts "                    Default: 10000 (10GB)"
		puts "  \[-no_opt_design\]  Disable opt_design implementation stage."
		puts "  \[-out_dir\]        Output directory for Implemenation runs."
		puts "                    Default: vXplore"
		puts "  \[-phys_opt\]       Enable phys_opt_design run stage for Implementation."
		puts "  \[-queue\]          Requested LSF job queue."
		puts "                    Default: medium"
		puts "  \[-step_count\]     Sets the numbers of runs to execute on the next Implementation stage"
		puts "                    Default: 2"
		puts "  \[-verbose\]        Display verbose LSF information."
		puts "  \[-wait\]           Wait time for monitoring LSF job status."
		puts "                    Default: 60 (seconds)"
        puts ""
        puts "Example:"
        puts "  The following example reads a post synthesis checkpoint and"
        puts "  produces multiple implementation runs using the tool directives."
        puts ""
        puts "  vXplore -checkpoint post_synth.dcp"
        puts ""
        return
    }
	
	## Check to ensure the checkpoint 
	if {![info exists opts(-checkpoint)]} {
		puts "ERROR: \[vXplore\] -checkpoint option required."
	} else {
		set opts(-checkpoint) [file join [pwd] $opts(-checkpoint)]
	}
	
	## Check if output directory exists
	if {![file exists $opts(-out_dir)]} {
		## Create Output Directory
		file mkdir $opts(-out_dir)
	} else {
		##		
		puts "ERROR: \[vXplore\] Output directory [file join [pwd] $opts(-out_dir)] already exists.  Please select a new directory location."
		return -code error
	}
	
	## Create absolute path for output file
	if {[info exists opts(-log)]} {
		set outputFile [file join [pwd] "$opts(-out_dir)/$opts(-log)"]
	}

	## Initialize report header variable
	set reportHeader ""
	
	## Initialize report content variable
	set reportContent ""
	
	## Append the report header information
	append reportHeader "+-----------------------------------------------------------------------------------------------\n"
	append reportHeader "| Report   :  vXplore\n"
	append reportHeader "| Version  :  [lindex [split [version] \n] 0] [lindex [split [version] \n] 1]\n"
	append reportHeader "| Date     :  [clock format [clock seconds]]\n"
	append reportHeader "| Command  :  $commandLine\n"
	append reportHeader "+-----------------------------------------------------------------------------------------------\n\n"
	
	## Print the report header to STDOUT
	puts $reportHeader	
	
	## Set output Tcl directory for run scripts
	set tclOutDirectory "$opts(-out_dir)/tcl"
		
	## Check if Tcl output directory exists
	if {![file exists $tclOutDirectory]} {
		## Create Tcl Ouptut Directory
		file mkdir $tclOutDirectory
	}
	
	## Set Tcl file path for place design run
	set placeTclFilePath "$tclOutDirectory/run_place_directive.tcl"
	
	## Create Place Tcl File Script
	set placeTclFileContent {
		##############################################
		## vXplore - place_design Tcl source script ##
		##############################################
		if {$argc!=4} {
			puts "ERROR: Invalid number of arguments.  Found $argc. Expects 3 Tcl Arguments from Command Line."
		} else {
			lassign $argv dcpFilePath directiveName outDir noOptDesignFlag
			open_checkpoint $dcpFilePath
			
			if {$noOptDesignFlag==0} {
				opt_design
			}
			
			place_design -directive $directiveName > $outDir/place_design.log
			report_timing_summary -file "$outDir/place_$directiveName\_timing_summary.rpt"
			write_checkpoint $outDir/[current_instance]_place_$directiveName\.dcp
		}
	}
	
	## open the filename for writing
	set fileHandle [open $placeTclFilePath "w"]
	## send the data to the file
	puts $fileHandle $placeTclFileContent
	## close the file, ensuring the data is written out before you continue with processing.
	close $fileHandle
	
	## Get place_design directive list
	set placeDirectiveList [get_implementation_directives -place_design]
	
	## Create a LSF Group Name to isolate BSUB runs
	set placeGroupName "/vXplore_place_$::tcl_platform(user)\_[clock format [clock seconds] -format "%Y%m%d%H%M%S"]"

	## Set the place_design runs output directory
	set placeOutDirectory "$opts(-out_dir)/place"
	
	## Loop through each of the place_design directives
	##  and execute the place_design directive on the
	##  input synthesized checkpoint.
	foreach placeDirectiveName $placeDirectiveList {
		## Set the placer directive output directory
		set directiveDirectory "$placeOutDirectory/$placeDirectiveName"
		
		## Check if placer directive directory exists
		if {![file exists $directiveDirectory]} {
			## Create Placer Directive Ouptut Directory
			file mkdir $directiveDirectory
		}
		
		## Create LSF bsub command
		set bsubCmd [list bsub -q $opts(-queue) -o /dev/null -app sil_rhel5 -g $placeGroupName -R \"rusage\[mem=$opts(-memory)\]\" vivado -mode tcl -source $placeTclFilePath -tclArgs $opts(-checkpoint) $placeDirectiveName $directiveDirectory $opts(-no_opt_design)]
		
		## Launch LSF Job for specified Placer Directive
		catch {eval [linsert $bsubCmd 0 exec]}
	}

	## Monitor LSF place_design Runs
	if {[info exists opts(-verbose)] && ($rdi::mode == {tcl})} {
		LSF::monitor_job_status -user $::tcl_platform(user) -wait $opts(-wait) -group $placeGroupName -display
	} else {
		LSF::monitor_job_status -user $::tcl_platform(user) -wait $opts(-wait) -group $placeGroupName
	}
	

	## Create Tsble for results display
	set tbl [Table::Create]
	## Create List of Header Strings
	set headerList [list "Placer Directive" "WNS (ns)" "TNS (ns)"]
	## Add header list as header to the table
	$tbl header $headerList
	
	## Parse and scan timing summary reports
	foreach directiveDirectory [lsort -index 0 [glob -type d $placeOutDirectory/*]] {
		## Get the timing summary file from the selected placer directive run
		set timingSummaryFile [glob -nocomplain $directiveDirectory/*_timing_summary.rpt]
		## Get Placer Directive Name from placer directive directory
		set directiveName [regsub {.*/} $directiveDirectory ""]
		
		## Check to ensure only one timing summary report file exists in the directory 
		if {[llength $timingSummaryFile]==1} {
			## Parse the timing summary report file found in the output directory
			array set timingSummaryArray [parse_report_timing_summary -file $timingSummaryFile]
			## Append to the list the directive directory and the overall run TNS
			lappend designTNSList [list $directiveDirectory $timingSummaryArray(TNS)]
			
			## Create list of data strings for table row
			set dataList [list $directiveName $timingSummaryArray(WNS) $timingSummaryArray(TNS)]
			
			## Add the data list to the table row
			$tbl addrow $dataList
			## Add a table separator
			$tbl separator
		} else {
			## This section is if a timing report was not found.
			##  No reason is returned for missing timing report.
			##  Please investigate place_design directive run
			##  to determine possible place_design error.
			
			## Create list data strings for table row
			set dataList [list $directiveName "N/A" "N/A"]
			
			## Add the data list to the table row
			$tbl addrow $dataList
			## Add a table separator
			$tbl separator
		}
	}
	
	## 
	append reportContent "INFO: \[vXplore\] The following table describes the results of the place_design runs of each of the placer directives.\n"
	
	## Print the Place Directive Timing Summary Table
	$tbl indent 0
	puts [$tbl print]
	
	## 
	append reportContent [$tbl print]
	
	## Sort the Place Design Directive Total TNS List by decreasing value
	set sortedTNSList [lsort -index 1 -real -decreasing $designTNSList]
	
	## Check if phys_opt_design directive is set
	if {[info exists opts(-phys_opt)]} {
		## Set Tcl file path for phys_opt_design run
		set physOptTclFilePath "$tclOutDirectory/run_phys_opt_directive.tcl"
		
		## Create PhysOpt Tcl File Script
		set physOptTclFileContent {
			##############################################
			## vXplore - phys_opt_design Tcl source script ##
			##############################################
			if {$argc!=3} {
				puts "ERROR: Invalid number of arguments.  Found $argc. Expects 3 Tcl Arguments from Command Line."
			} else {
				lassign $argv dcpFilePath directiveName outDir
				open_checkpoint $dcpFilePath
				phys_opt_design -directive $directiveName > $outDir/phys_opt_design.log
				report_timing_summary -file "$outDir/phys_opt_$directiveName\_timing_summary.rpt"
				write_checkpoint $outDir/[current_instance]_phys_opt_$directiveName\.dcp
			}
		}
		
		## open the filename for writing
		set fileHandle [open $physOptTclFilePath "w"]
		## send the data to the file
		puts $fileHandle $physOptTclFileContent
		## close the file, ensuring the data is written out before you continue with processing.
		close $fileHandle
		
		## Get phys_opt directive list
		set physOptDirectiveList [get_implementation_directives -phys_opt_design]
		
		## Create a LSF Group Name to isolate BSUB runs
		set physOptGroupName "/vXplore_phys_opt_$::tcl_platform(user)\_[clock format [clock seconds] -format "%Y%m%d%H%M%S"]"

		## Set the phys_opt runs output directory
		set physOptOutDirectory "$opts(-out_dir)/phys_opt"
		
		## Run though the total number of place design checkpoints specified
		for {set i 0} {$i<$opts(-step_count)} {incr i} {
			## Get the placer directive directory from the sorted TNS list
			set placeDirectiveDirectory [lindex [lindex $sortedTNSList $i] 0]
			## Get the path to the checkpoint in the placer directive directory
			set placeCheckpointPath [glob -nocomplain $placeDirectiveDirectory/*.dcp]
			## Get placer directive name
			set placeDirectiveName [regsub {.*/} $placeDirectiveDirectory ""]
			
			## Check to ensure that the checkpoint was found
			if {[llength $placeCheckpointPath]!=1} {
				puts "CRITICAL WARNING: \[vXplore\] Cannot find place_design checkpoint in directory $placeDirectiveDirectory for phys_opt_design run."
				continue
			} 
			
			## Loop through each of the phys_opt_design directives
			##  and execute the phys_opt_design directive on the
			##  input placed checkpoint.
			foreach physOptDirectiveName $physOptDirectiveList {
				## Set the PhysOpt directive output directory
				set directiveDirectory "$physOptOutDirectory/run_$placeDirectiveName\_$physOptDirectiveName"
				
				## Check if PhysOpt directive directory exists
				if {![file exists $directiveDirectory]} {
					## Create PhysOpt Directive Ouptut Directory
					file mkdir $directiveDirectory
				}
				
				## Create LSF bsub command
				set bsubCmd [list bsub -q $opts(-queue) -o /dev/null -app sil_rhel5 -g $physOptGroupName -R \"rusage\[mem=$opts(-memory)\]\" vivado -mode tcl -source $physOptTclFilePath -tclArgs $placeCheckpointPath $physOptDirectiveName $directiveDirectory]
				
				## Launch LSF Job for specified PhysOpt Directive
				catch {eval [linsert $bsubCmd 0 exec]}
			}
		}
	
		## Monitor LSF phys_opt_design Runs
		if {[info exists opts(-verbose)] && ($rdi::mode == {tcl})} {
			LSF::monitor_job_status -user $::tcl_platform(user) -wait $opts(-wait) -group $physOptGroupName -display
		} else {
			LSF::monitor_job_status -user $::tcl_platform(user) -wait $opts(-wait) -group $physOptGroupName
		}

		## Create Tsble for results display
		set tbl [Table::Create]
		## Create List of Header Strings
		set headerList [list "Phys Opt Directive" "WNS (ns)" "TNS (ns)"]
		## Add header list as header to the table
		$tbl header $headerList
		
		## Parse and scan summary reports
		foreach directiveDirectory [lsort -index 0 [glob -type d $physOptOutDirectory/*]] {
			## Get the timing summary file from the selected phys_opt directive run
			set timingSummaryFile [glob -nocomplain $directiveDirectory/*_timing_summary.rpt]
			## Get phys_opt Directive Name from placer directive directory
			set directiveName [regsub {.*/} $directiveDirectory ""]
			
			## Check to ensure only one timing summary report file exists in the directory 
			if {[llength $timingSummaryFile]==1} {
				## Parse the timing summary report file found in the output directory
				array set timingSummaryArray [parse_report_timing_summary -file $timingSummaryFile]
				## Append to the list the directive directory and the overall run TNS
				lappend physOptDesignTNSList [list $directiveDirectory $timingSummaryArray(TNS)]
				
				## Create list of data strings for table row
				set dataList [list $directiveName $timingSummaryArray(WNS) $timingSummaryArray(TNS)]
				
				## Add the data list to the table row
				$tbl addrow $dataList
				## Add a table separator
				$tbl separator
			} else {
				## This section is if a timing report was not found.
				##  No reason is returned for missing timing report.
				##  Please investigate place_design directive run
				##  to determine possible place_design error.
				
				## Create list data strings for table row
				set dataList [list $directiveName "N/A" "N/A"]
				
				## Add the data list to the table row
				$tbl addrow $dataList
				## Add a table separator
				$tbl separator
			}
		}

		## 
		append reportContent "\nINFO: \[vXplore\] The following table describes the results of the phys_opt_design runs of each of the phys_opt directives.\n"
	
		## Print the Place Directive Timing Summary Table
		$tbl indent 0
		puts [$tbl print]
	
		## 
		append reportContent [$tbl print]

		## Sort the phys_opt Design Directive Total TNS List by decreasing value
		set sortedTNSList [lsort -index 1 -real -decreasing $physOptDesignTNSList]
	}
	
	## Set Tcl file path for route_design run
	set routeTclFilePath "$tclOutDirectory/run_route_directive.tcl"
	
	## Create Route Tcl File Script
	set routeTclFileContent {
		##############################################
		## vXplore - route_design Tcl source script ##
		##############################################
		if {$argc!=3} {
			puts "ERROR: Invalid number of arguments.  Expects three Tcl Arguments from Command Line."
		} else {
			lassign $argv dcpFilePath directiveName outDir
			open_checkpoint $dcpFilePath
			route_design -directive $directiveName > $outDir/route_design.log
			report_timing_summary -file "$outDir/route_$directiveName\_timing_summary.rpt"
			write_checkpoint $outDir/[current_instance]_route_$directiveName\.dcp
		}
	}
	
	## open the filename for writing
	set fileHandle [open $routeTclFilePath "w"]
	## send the data to the file
	puts $fileHandle $routeTclFileContent
	## close the file, ensuring the data is written out before you continue with processing.
	close $fileHandle
	
	## Get route_design directive list
	set routeDirectiveList [get_implementation_directives -route_design]
	## Create a LSF Group Name to isolate BSUB runs
	set routeGroupName "/vXplore_route_$::tcl_platform(user)\_[clock format [clock seconds] -format "%Y%m%d%H%M%S"]"

	## Set the route_design runs output directory
	set routeOutDirectory "$opts(-out_dir)/route"
		
	## Run though the total number of previous design checkpoints specified
	for {set i 0} {$i<$opts(-step_count)} {incr i} {
		## Get the previous run directive directory from the sorted TNS list
		set previousRunDirectory [lindex [lindex $sortedTNSList $i] 0]
		## Get the path to the checkpoint in the previous run directive directory
		set previousRunCheckpointPath [glob -nocomplain $previousRunDirectory/*.dcp]
		## Get placer directive name
		set previousRunDirectiveName [regsub {.*/} $previousRunDirectory ""]		

		## Check to ensure that the checkpoint was found
		if {[llength $previousRunCheckpointPath]!=1} {
			puts "CRITICAL WARNING: \[vXplore\] Cannot find previous run checkpoint in directory $previousRunDirectory for route_design run."
			continue
		} 
			
		## Loop through each of the place_design directives
		##  and execute the place_design directive on the
		##  input synthesized checkpoint.
		foreach routeDirectiveName $routeDirectiveList {
			## Set the route_design directive output directory
			set directiveDirectory "$routeOutDirectory/$previousRunDirectiveName\_$routeDirectiveName"
				
			## Check if route directive directory exists
			if {![file exists $directiveDirectory]} {
				## Create route Directive Ouptut Directory
				file mkdir $directiveDirectory
			}
				
			## Create LSF bsub command
			set bsubCmd [list bsub -q $opts(-queue) -o /dev/null -app sil_rhel5 -g $routeGroupName -R \"rusage\[mem=$opts(-memory)\]\" vivado -mode tcl -source $routeTclFilePath -tclArgs $previousRunCheckpointPath $routeDirectiveName $directiveDirectory]
				
			## Launch LSF Job for specified route_design Directive
			catch {eval [linsert $bsubCmd 0 exec]}
		}
	}
	
	## Monitor LSF route_design Runs
	if {[info exists opts(-verbose)] && ($rdi::mode == {tcl})} {
		LSF::monitor_job_status -user $::tcl_platform(user) -wait $opts(-wait) -group $routeGroupName -display
	} else {
		LSF::monitor_job_status -user $::tcl_platform(user) -wait $opts(-wait) -group $routeGroupName
	}
	

	## Create Tsble for results display
	set tbl [Table::Create]
	## Create List of Header Strings
	set headerList [list "Router Directive" "WNS (ns)" "TNS (ns)"]
	## Add header list as header to the table
	$tbl header $headerList
	
	## Parse and scan summary reports
	foreach directiveDirectory [lsort -index 0 [glob -type d $routeOutDirectory/*]] {
		## Get the timing summary file from the selected route_design directive run
		set timingSummaryFile [glob -nocomplain $directiveDirectory/*_timing_summary.rpt]
		## Get route Directive Name from previous run directive directory
		set directiveName [regsub {.*/} $directiveDirectory ""]
			
		## Check to ensure only one timing summary report file exists in the directory 
		if {[llength $timingSummaryFile]==1} {
			## Parse the timing summary report file found in the output directory
			array set timingSummaryArray [parse_report_timing_summary -file $timingSummaryFile]
			## Append to the list the directive directory and the overall run TNS
			lappend routeDesignTNSList [list $directiveDirectory $timingSummaryArray(TNS)]
	
			## Create list of data strings for table row
			set dataList [list $directiveName $timingSummaryArray(WNS) $timingSummaryArray(TNS)]
			
			## Add the data list to the table row
			$tbl addrow $dataList
			## Add a table separator
			$tbl separator
		} else {
			## This section is if a timing report was not found.
			##  No reason is returned for missing timing report.
			##  Please investigate place_design directive run
			##  to determine possible place_design error.
			
			## Create list data strings for table row
			set dataList [list $directiveName "N/A" "N/A"]
			
			## Add the data list to the table row
			$tbl addrow $dataList
			## Add a table separator
			$tbl separator
		}
	}

	## 
	append reportContent "\nINFO: \[vXplore\] The following table describes the results of the route_design runs of each of the router directives.\n"
	
	## Print the Router Directive Timing Summary Table
	$tbl indent 0
	puts [$tbl print]
	
	## 
	append reportContent [$tbl print]
	
	##open the filename for writing
	set fileHandle [open $outputFile "w"]
	## send the report header to the file
	puts $fileHandle $reportHeader
	## send the data to the file
	puts $fileHandle $reportContent
	## close the file, ensuring the data is written out before you continue with processing.
	close $fileHandle
}

##########################################################
#                                                        #
##########################################################	
proc parse_report_timing_summary {args} {
	## Create Argument Array
	array set opts [concat {-report_string "" -file ""} $args]
	
	## Initialize Report Summary Section Flag
	set summaryFlag 0

	## Argument Parsing
	if {$opts(-report_string) ne ""} {
		set reportTimingSummaryString $opts(-report_string)
	} elseif {$opts(-file) ne ""} {
		## Read the size of the file for memory
		set fSize	[file size $opts(-file)]
		## Open the filehandle of the XDC file for reading
		set fHandle	[open $opts(-file) r]
		## Read the contents of the XDC file
		set fData	[read $fHandle $fSize]
		## Close the filehandle of the XDC
		close $fHandle
		
		set reportTimingSummaryString $fData
	} else {
		puts "ERROR: \[parse_report_timing_summary\] Missing -file and -return_string arguments.  One of these arguments are required."
		return -code error
	}
	
	##
	array set reportSummaryArray {}
	
	##
	foreach reportLine [split $reportTimingSummaryString '\n'] {
		##
		if {[regexp {^\| Design Timing Summary} $reportLine]} {
			set summaryFlag 1
		##
		} elseif {$summaryFlag && [regexp {^\s*(-*\d+(\.\d+))\s+(-*\d+(\.\d+))\s+(\d+)\s+(\d+)\s+(-*\d+(\.\d+))\s+(-*\d+(\.\d+))\s+(\d+)\s+(\d+)\s+(-*\d+(\.\d+))\s+(-*\d+(\.\d+))\s+(\d+)\s+(\d+)} $reportLine matchString wnsValue wnsTmp tnsValue tnsTmp tnsFailEndpoint tnsTotalEndpoint whsValue whsTmp thsValue thsTmp thsFailEndpoint thsTotalEndpoint wpwsValue wpwsTmp tpwsValue tpwsTmp tpwsFailEndpoint tpwsTotalEndpoint]} {
			set reportSummaryArray(WNS) $wnsValue
			set reportSummaryArray(TNS) $tnsValue
			set reportSummaryArray(TNS_Failing_Endpoints) $tnsFailEndpoint
			set reportSummaryArray(TNS_Total_Endpoints) $tnsTotalEndpoint
			set reportSummaryArray(WHS) $whsValue
			set reportSummaryArray(THS) $thsValue
			set reportSummaryArray(THS_Failing_Endpoints) $thsFailEndpoint
			set reportSummaryArray(THS_Total_Endpoints) $thsTotalEndpoint
			set reportSummaryArray(WPWS) $wpwsValue
			set reportSummaryArray(TPWS) $tpwsValue
			set reportSummaryArray(TPWS_Failing_Endpoints) $tpwsFailEndpoint
			set reportSummaryArray(TPWS_Total_Endpoints) $tpwsTotalEndpoint
		##
		} elseif {[regexp {^\| Clock Summary} $reportLine]} {
			set summaryFlag 0
		}
	}
	
	##
	return [array get reportSummaryArray]
}

###########################################################################
##
## Simple package to handle printing of tables
##
## %> set tbl [Table::Create]
## %> $tbl header [list "name" "#Pins" "case_value" "user_case_value"]
## %> $tbl addrow [list A/B/C/D/E/F 12 - -]
## %> $tbl addrow [list A/B/C/D/E/F 24 1 -]
## %> $tbl separator
## %> $tbl addrow [list A/B/C/D/E/F 48 0 1]
## %> $tbl indent 0
## %> $tbl print
## +-------------+-------+------------+-----------------+
## | name        | #Pins | case_value | user_case_value |
## +-------------+-------+------------+-----------------+
## | A/B/C/D/E/F | 12    | -          | -               |
## | A/B/C/D/E/F | 24    | 1          | -               |
## +-------------+-------+------------+-----------------+
## | A/B/C/D/E/F | 48    | 0          | 1               |
## +-------------+-------+------------+-----------------+
## %> $tbl indent 2
## %> $tbl print
##   +-------------+-------+------------+-----------------+
##   | name        | #Pins | case_value | user_case_value |
##   +-------------+-------+------------+-----------------+
##   | A/B/C/D/E/F | 12    | -          | -               |
##   | A/B/C/D/E/F | 24    | 1          | -               |
##   +-------------+-------+------------+-----------------+
##   | A/B/C/D/E/F | 48    | 0          | 1               |
##   +-------------+-------+------------+-----------------+
##
###########################################################################

namespace eval Table { set n 0 }

proc Table::Create {} { #-- constructor
  variable n
  set instance [namespace current]::[incr n]
  namespace eval $instance { variable tbl [list {}]; variable indent 0 }
  interp alias {} $instance {} ::Table::do $instance
  set instance
}

proc Table::do {self method args} { #-- Dispatcher with methods
  upvar #0 ${self}::tbl tbl
  switch -- $method {
      header {
        eval lset tbl 0 $args
        return 0
      }
      addrow {
        eval lappend tbl $args
        return 0
      }
      separator {
        eval lappend tbl {%%SEPARATOR%%}
        return 0
      }
      indent {
        set ${self}::indent $args
        return 0
      }
      print  {
        eval Table::print $self
      }
      reset  {
        set ${self}::tbl [list {}]
        set ${self}::indent 0
        return 0
      }
      default {error "unknown method $method"}
  }
}

proc Table::print {self} {
   upvar #0 ${self}::tbl table
   upvar #0 ${self}::indent indent
   set maxs {}
   foreach item [lindex $table 0] {
       lappend maxs [string length $item]
   }
   set numCols [llength [lindex $table 0]]
   foreach row [lrange $table 1 end] {
       if {$row eq {%%SEPARATOR%%}} { continue }
       for {set j 0} {$j<$numCols} {incr j} {
            set item [lindex $row $j]
            set max [lindex $maxs $j]
            if {[string length $item]>$max} {
               lset maxs $j [string length $item]
           }
       }
   }
   set head " [string repeat " " [expr $indent * 4]]+"
   foreach max $maxs {append head -[string repeat - $max]-+}
   set res $head\n
   set first 1
   foreach row $table {
       if {$row eq {%%SEPARATOR%%}} { 
         append res $head\n
         continue 
       }
       append res " [string repeat " " [expr $indent * 4]]|"
       foreach item $row max $maxs {append res [format " %-${max}s |" $item]}
       append res \n
       if {$first} {
         append res $head\n
         set first 0
       }
   }
   #append res $head
   set res
}

##########################################################
# lshift
##########################################################
proc lshift {varname {nth 0}} {
	upvar $varname args
	set r [lindex $args $nth]
	set args [lreplace $args $nth $nth]
	return $r
}

# #########################################################
#
# #########################################################
proc get_implementation_directives {args} {
	## Set Default option values
	array set opts {-help 0 -place_design 0 -phys_opt_design 0 -route_design 0}
	
	## Parse arguments from option command line
	while {[string match -* [lindex $args 0]]} {
        switch -glob -- [lindex $args 0] {
			-place_design    { set opts(-place_design)    1}
			-phys_opt_design { set opts(-phys_opt_design) 1}
			-route_design    { set opts(-route_design)    1}
            -help*           { set opts(-help)            1}
            default {
                return -code error "bad option [lindex $args 0]"
            }
        }
        lshift args
    }
	
	set selectedCommandName ""
	
	if {$opts(-place_design)==1} {
		set selectedCommandName "place_design"
	} elseif {$opts(-phys_opt_design)==1} {
		set selectedCommandName "phys_opt_design"
	} elseif {$opts(-route_design)==1} {
		set selectedCommandName "route_design"
	} else {
		puts "ERROR"
		return
	}
	
	set commandHelpReportString [help $selectedCommandName]
	set directiveFlag 0
	
	set directiveList {}
	
	foreach helpLine [split $commandHelpReportString '\n'] {
		if {[regexp {^\s+-directive \<arg\>} $helpLine]} {
			set directiveFlag 1
		} elseif {($directiveFlag==1) && [regexp {^\s+\*\s+(\w+)\s+-} $helpLine matchString directiveName]} {
			lappend directiveList $directiveName
		} elseif {[regexp {^\s+-\w+\s+\<arg\>} $helpLine]} {
			set directiveFlag 0
		}
	}
	
	return [lsort $directiveList]
}

# Trick to silence the linter
eval [list namespace eval ::LSF {
} ]

##########################################################
# LSF::report_job_status
##########################################################
proc ::LSF::report_job_status {args} {
	## Set Default option values
	array set opts {-help 0 -wait 30}
    
    ## Parse arguments from option command line
	while {[string match -* [lindex $args 0]]} {
        switch -regexp -- [lindex $args 0] {
            {-u(s(e(r)?)?)?$}             { set opts(-user)    [lshift args 1]}
			{-g(r(o(u(p)?)?)?)?$}         { set opts(-group)   [lshift args 1]}
			{-w(a(i(t)?)?)?$}             { set opts(-wait)    [lshift args 1]}
			{-d(i(s(p(l(a(y)?)?)?)?)?)?$} { set opts(-display) 1}
            {-h(e(l(p)?)?)?$}             { set opts(-help)    1}
            default {
                return -code error "ERROR: \[LSFUtils::report_job_status\] Unknown option '[lindex $args 0]', please type 'LSFUtils::report_job_status -help' for usage info."
            }
        }
        lshift args
    }
	
	## Check if the user command line option wasn't set, set the user based on the current Tcl platform user
	if {![info exists opts(-user)]} {
		set opts(-user) $::tcl_platform(user)
	}
	
	## If display option is set, report the requested wait time before monitoring the status of the LSF jobs
	if {[info exists opts(-display)]} {
		puts "INFO: \[report_job_status\] Wait for $opts(-wait) seconds before monitoring LSF jobs.";
    }
	
	## Wait for the requested wait time in seconds
	after [expr {int($opts(-wait) * 1000)}]

	## Clear the Vivado terminal screen 
	puts [exec clear]
		
	## Check if the group command line option was used
    if {[info exists opts(-group)] && $opts(-group) ne ""} {
		## If display option is set, report the user name and LSF group name that's being used to monitor the status of the LSF jobs
		if {[info exists opts(-display)]} {
			puts "\nINFO: \[report_job_status\] Monitoring LSF Job Status for user $opts(-user) and LSF group $opts(-group).\n";
        }
		
		## Set the temporary file name to store the LSF bjobs report 
		set fileName "[pwd]/$opts(-group)\_bjobs.tmp";
		## Set the LSF bsub command to report the current job status of the request LSF group name
        set bjobCmd  [list bjobs -u $opts(-user) -g $opts(-group) -a >& $fileName]
    } else {
		## If display option is set, report the user name that's being used to monitor the status of the LSF jobs
		if {[info exists opts(-display)]} {
			puts "\nINFO: \[report_job_status\] Monitoring LSF Job Status for user $opts(-user).\n";
        }
		
		## Set the temporary file name to store the LSF bjobs report 
		set fileName "[pwd]/$$opts(-user)\_bjobs.tmp";
		## Set the LSF bsub command to report the current job status of the request LSF user
        set bjobCmd [list bjobs -u $opts(-user) >& $fileName]
    }
	
	## Execute the LSF bsub command
    eval [linsert $bjobCmd 0 exec]

	## Set the file size of the temporary LSF bjobs report file
	set fSize	[file size $fileName]
	## Open the filehandle of the file for reading
	set fHandle	[open $fileName r]
	## Read the contents of the file
	set fData	[read $fHandle $fSize]
	## Close the filehandle
	close $fHandle
	
	## Initialize the job running count to 0
    set jobRunningCount 0

	# Loop through each line of the report file
    foreach fileLine [split $fData '\n'] {
		## Parse the line to check for the required LSF job information
        if {[regexp {(\d+)\s+(\S+)\s+(\S+)} $fileLine matchString jobID jobUserName jobStatus]} {
			## If display option is set, report job status of each specific job
			if {[info exists opts(-display)]} {
				puts "INFO: \[report_job_status\] LSF Job Status: $jobID = $jobStatus";
			}
			
			## If the job is currently running or pending, increment the job running count
            if {($jobStatus eq "RUN") || ($jobStatus eq "PEND")} {
                incr jobRunningCount
            }
        }
    }
	
	## Delete the temporary file created for bjobs monitoring
	file delete $fileName
	
	## Return the final job running count
    return $jobRunningCount
}

##########################################################
# LSF::monitor_job_status
##########################################################
proc ::LSF::monitor_job_status {args} {
	## Set Default option values
	array set opts {-help 0 -wait 30}
    
    ## Parse arguments from option command line
	while {[string match -* [lindex $args 0]]} {
        switch -regexp -- [lindex $args 0] {
            {-u(s(e(r)?)?)?$}             { set opts(-user)    [lshift args 1]}
			{-g(r(o(u(p)?)?)?)?$}         { set opts(-group)   [lshift args 1]}
			{-w(a(i(t)?)?)?$}             { set opts(-wait)    [lshift args 1]}
			{-d(i(s(p(l(a(y)?)?)?)?)?)?$} { set opts(-display) 1}
            {-h(e(l(p)?)?)?$}             { set opts(-help)    1}
            default {
                return -code error "ERROR: \[LSFUtils::monitor_job_status\] Unknown option '[lindex $args 0]', please type 'LSFUtils::monitor_job_status -help' for usage info."
            }
        }
        lshift args
    }
	
	## Check if the user command line option wasn't set, set the user based on the current Tcl platform user
	if {![info exists opts(-user)]} {
		set opts(-user) $::tcl_platform(user)
	}
	
	## Initialize the start time for monitoring the LSF jobs
	set batchStartTime [clock seconds]
	
	## If display option is set, and set the report_job_status command with the requested display option
	if {[info exists opts(-display)]} {
		set reportCmd "LSF::report_job_status -user $opts(-user) -wait $opts(-wait) -group $opts(-group) -display"
	} else {
		set reportCmd "LSF::report_job_status -user $opts(-user) -wait $opts(-wait) -group $opts(-group)"
	}
	
	## Clear the Vivado terminal screen 
	puts [exec clear]
	
	## While there are running jobs, monitor LSF Runs
	while {[eval $reportCmd]} {
		## Evaluate the time from the initial start time
		set cpu_time [expr {[clock seconds] - $batchStartTime}]
		
		## Calculate to total number of seconds
		set cpu_secs [expr { int(floor($cpu_time)) % 60 }]
		## Calculate to total number of minutes
		set cpu_mins [expr { int(floor($cpu_time / 60)) % 60 }]
		## Calculate to total number of hours
		set cpu_hrs  [expr { int(floor($cpu_time / 3600)) }]
		
		## If display option is set, report the current elapsed time of monitoring the LSF jobs
		if {[info exists opts(-display)]} {
			puts "INFO: \[LSF::monitor_job_status\] Elapsed Time: [format "%d:%02d:%02d" $cpu_hrs $cpu_mins $cpu_secs]\n"
		}
	}
}
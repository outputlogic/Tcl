package require yaml

# Create the namespace
namespace eval vXplore {}

##########################################################
# vXplore
##########################################################
proc vXplore {args} {
	## Set Default option values
	array set opts {-help 0 -log "vXplore.log" -memory 10000 -mode gui -out_dir "vXplore" -queue "medium" -step_count 2 -verbose 0 -wait 60}
	
	## Set the command line used for the script
	set commandLine "vXplore $args"
	
	##
	set cmdArgumentList $args
    
	## Parse arguments from option command line
	while {[string match -* [lindex $args 0]]} {
        switch -regexp -- [lindex $args 0] {
            {-ch(e(c(k(p(o(i(n(t)?)?)?)?)?)?)?)?$}             { set opts(-checkpoint)    [lshift args 1]}
			{-co(n(f(i(g(u(r(a(t(i(o(n)?)?)?)?)?)?)?)?)?)?)?$} { set opts(-configuration) [lshift args 1]}
			{-l(o(g)?)?$}                                      { set opts(-log)           [lshift args 1]}
			{-me(m(o(r(y)?)?)?)?$}                             { set opts(-memory)        [lshift args 1]}
			{-mo(d(e)?)?$}                                     { set opts(-mode)          [lshift args 1]}
			{-o(u(t(_(d(i(r)?)?)?)?)?)?$}                      { set opts(-out_dir)       [lshift args 1]}
			{-q(u(e(u(e)?)?)?)?$}                              { set opts(-queue)         [lshift args 1]}
			{-r(u(n(_(a(l(l)?)?)?)?)?)?$}                      { set opts(-run_all)       1}
			{-s(t(e(p(_(c(o(u(n(t)?)?)?)?)?)?)?)?)?$}          { set opts(-step_count)    [lshift args 1]}
			{-v(e(r(b(o(s(e)?)?)?)?)?)?$}    	               { set opts(-verbose)       1}
			{-w(a(i(t)?)?)?$}                                  { set opts(-wait)          [lshift args 1]}
			{-h(e(l(p)?)?)?$}                                  { set opts(-help)          1}
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
        puts "  vXplore -checkpoint <arg> \[-configuration <arg>\] \[-log <arg>\]"
		puts "          \[-memory <arg>\] \[-mode <arg>\] \[-out_dir <arg>\]"
		puts "          \[-queue <arg>\] \[-run_all\] \[-step_count <arg>\]"		
		puts "          \[-verbose\] \[-help\]"
        puts ""
        puts "Usage:"
        puts "  Name              Description"
        puts "  ------------------------------"
        puts "  -checkpoint       Design checkpoint file."
		puts "  \[-configuration\]  Configuration file for run directive information."
		puts "  \[-log\]            Write the report log into the specified file."
		puts "                    Default: vXplore.log"
		puts "  \[-memory\]         Requested Memory requirement for LSF job."
		puts "                    Default: 10000 (10GB)"
		puts "  \[-mode\]           Invocation mode, allowed values are 'gui' and 'tcl'"
		puts "                    Default: gui"
		puts "  \[-out_dir\]        Output directory for Implemenation runs."
		puts "                    Default: vXplore"
		puts "  \[-queue\]          Requested LSF job queue."
		puts "                    Default: medium"	
		puts "  \[-run_all\]        Runs all the completed designs after each step. Overrides -step_count option."
		puts "  \[-step_count\]     Sets the numbers of runs to execute on the next Implementation stage"
		puts "                    Default: 2"
		puts "  \[-verbose\]        Display verbose LSF information."
		puts "  \[-wait\]           Wait time for monitoring LSF job status."
		puts "                    Default: 60 (seconds)"
        puts ""
        #puts "Example:"
        #puts "  The following example reads a post synthesis checkpoint and produces"
        #puts "  multiple implementation runs (i.e. opt_design, place_design, route_design)"
		#puts "  using the tool directives on the LSF farm."
        #puts ""
        #puts "  vXplore -mode tcl -checkpoint post_synth.dcp"
        puts ""
        return
    }
	
	## Check if Vivado is being run in GUI mode, error due to script recommendation
	if {$rdi::mode eq "gui"} {
		return -code error "ERROR: \[vXplore\] Vivado currently invoked with the GUI. Enter Tcl by using 'stop_gui' to execute the vXplore script."
	}
	
	## Check the mode of the program
	if {$opts(-mode) eq "gui"} {
		## Execute the Tcl/Tk GUI for the program, return the options specified in the GUI
		set guiArgumentString [exec /wrk/hdstaff/joshg/tools/opt/ActiveTcl-8.5/bin/tclsh /wrk/hdstaff/joshg/tools/scripts/tcl/vXplore_Tk/src/vXplore_Tk.tcl $cmdArgumentList]

		## Ensure that options were returned by the GUI, cancel not selected
		if {[llength $guiArgumentString]!=0} {
			## Execute vXplore with the options specified in the GUI
			vXplore::vXplore $guiArgumentString
		}
	} elseif {$opts(-mode) eq "tcl"} {
		## Execute vXplore using the command line options
		vXplore::vXplore $cmdArgumentList
	} else {
		## If mode is not gui nor tcl, error
		return -code error "ERROR: \[vXplore\] Mode $opts(-mode) is not supported.  Supported modes are 'gui' or 'tcl'"
	}
	
	return
}

##########################################################
# vXplore
##########################################################
proc vXplore::vXplore {args} {
	## Flatten the list
	set args [concat {*}$args]

	## Set the command line used for the script
	set commandLine "vXplore $args"
	
	## Set Default option values
	array set opts {-help 0 -log "vXplore.log" -memory 10000 -mode gui -out_dir "vXplore" -queue "medium" -step_count 2 -verbose 0 -wait 60}
 
	## Parse arguments from option command line
	while {[string match -* [lindex $args 0]]} {
        switch -regexp -- [lindex $args 0] {
            {-ch(e(c(k(p(o(i(n(t)?)?)?)?)?)?)?)?$}             { set opts(-checkpoint)    [lshift args 1]}
			{-co(n(f(i(g(u(r(a(t(i(o(n)?)?)?)?)?)?)?)?)?)?)?$} { set opts(-configuration) [lshift args 1]}
			{-l(o(g)?)?$}                                      { set opts(-log)           [lshift args 1]}
			{-me(m(o(r(y)?)?)?)?$}                             { set opts(-memory)        [lshift args 1]}
			{-mo(d(e)?)?$}                                     { set opts(-mode)          [lshift args 1]}
			{-o(u(t(_(d(i(r)?)?)?)?)?)?$}                      { set opts(-out_dir)       [lshift args 1]}
			{-q(u(e(u(e)?)?)?)?$}                              { set opts(-queue)         [lshift args 1]}
			{-r(u(n(_(a(l(l)?)?)?)?)?)?$}                      { set opts(-run_all)       1}
			{-s(t(e(p(_(c(o(u(n(t)?)?)?)?)?)?)?)?)?$}          { set opts(-step_count)    [lshift args 1]}
			{-v(e(r(b(o(s(e)?)?)?)?)?)?$}    	               { set opts(-verbose)       1}
			{-w(a(i(t)?)?)?$}                                  { set opts(-wait)          [lshift args 1]}
			{-h(e(l(p)?)?)?$}                                  { set opts(-help)          1}
            default {
                return -code error "ERROR: \[vXplore\] Unknown option '[lindex $args 0]', please type 'vXplore -help' for usage info."
            }
        }
        lshift args
    }
	
	## Check to ensure the checkpoint, error if checkpoint option is not used
	if {![info exists opts(-checkpoint)]} {
		return -code error "ERROR: \[vXplore\] -checkpoint option required."
	} else {
		## Set the full absolute path to the checkpoint
		set opts(-checkpoint) [file join [pwd] $opts(-checkpoint)]
		## Check if the checkpoint file exists, error if the checkpoint file doesn't exist on disk
		if {![file exists $opts(-checkpoint)]} {
			return -code error "ERROR: \[vXplore\] Unable to find checkpoint file $opts(-checkpoint)."
		}
	}
	
	## Check if the configuration file was given
	if {[info exists opts(-configuration)]} {
		## Set the full absolute path to the configuration file
		set opts(-configuration) [file join [pwd] $opts(-configuration)]
		## Check if the configuration file exists, error if configuration file doesn't exist on disk
		if {![file exists $opts(-configuration)]} {
			return -code error "ERROR: \[vXplore\] Unable to find configuration file $opts(-configuration)."
		} else {
			## Read the configuration file into the Tcl dictionary
			set configurationDict [read_configuration_file -file  $opts(-configuration)]
		}
	} else {
		## Set default configuration for the dictionary
		set configurationDict [vXplore::get_default_vXplore_configuration]
	}	
	
	## Perform DRC checks on configuration dictionary

	## Append vXplore to the output directory path
	set outputDirectory [file normalize "$opts(-out_dir)/vXplore"]
	
	## Check if output directory exists, error if the directory exists
	if {[file exists $outputDirectory]} {
		return -code error "ERROR: \[vXplore\] Output directory $outputDirectory already exists.  Please select a new directory location."
	} else {
		## Create Output Directory since it doesn't exist
		file mkdir $outputDirectory
	}
	
	## Check if the log file option was used
	if {[info exists opts(-log)]} {
		## Create absolute path for output log file
		set outputLogFile [file join [pwd] "$outputDirectory/$opts(-log)"]
		
		## Open a file handle channel for the vXplore log file
		set logFileChannelID [open $outputLogFile w] 
	}

	## Initialize results dictionary
	set resultsDict [dict create]
	
	## Initialize report header variable
	set reportHeader ""
	
	## Append the report header information
	append reportHeader "+-----------------------------------------------------------------------------------------------\n"
	append reportHeader "| Report   :  vXplore\n"
	append reportHeader "| Version  :  [lindex [split [version] \n] 0] [lindex [split [version] \n] 1]\n"
	append reportHeader "| Date     :  [clock format [clock seconds]]\n"
	append reportHeader "| Command  :  $commandLine\n"
	append reportHeader "+-----------------------------------------------------------------------------------------------\n\n"
	
	## Print the report header to STDOUT and to the log
	puts $reportHeader	
	puts $logFileChannelID $reportHeader
	
	## Set output Tcl directory for run scripts
	set tclOutDirectory "$outputDirectory/tcl"
		
	## Check if Tcl output directory exists
	if {![file exists $tclOutDirectory]} {
		## Create Tcl Ouptut Directory
		file mkdir $tclOutDirectory
	}
	
	## Create a design dictionary for the input checkpoint
	dict set designDict 0 index 0
	dict set designDict 0 checkpoint $opts(-checkpoint)
	dict set designDict 0 directive ""
	dict set designDict 0 directory ""
	dict set designDict 0 WNS "0.000"
	
	## Loop through each stage index in the configuration dictionary
	foreach stageIndex [lsort -integer [dict keys [dict get $configurationDict index]]] {
		## Parse the design dictionary to determine the total number of designs to run
		if {[info exists opts(-run_all)]} {
			## Set the design run dictionary to the entire design dictionary since the run all option was specified
			set designRunDict $designDict
		} else {
			## Filter the design dictionary by the requested design step count
			set designRunDict [vXplore::filter_design_dict_by_step_count -dict $designDict -step_count $opts(-step_count)]
		}
		
		## Run the requested Vivado command 
		set stepDesignDict [vXplore::run_vivado_step -design_dict $designRunDict -stage_name [dict get $configurationDict index $stageIndex stage] -channel_id $logFileChannelID -config_dict [dict get $configurationDict index $stageIndex] -memory $opts(-memory) -out_dir "$outputDirectory/$stageIndex" -queue $opts(-queue) -wait $opts(-wait) -verbose $opts(-verbose)]
	
		## Sort the executed design dictionary by WNS value
		set designDict [vXplore::sort_design_dict_by_wns_then_tns -dict $stepDesignDict]
	}
}

##########################################################
# 
##########################################################
proc vXplore::run_vivado_step {args} {
	## Set Default option values
	array set opts {-help 0}
	
	## Set the command line used for the script
	set commandLine "run_vivado_step $args"
    
	## Parse arguments from option command line
	while {[string match -* [lindex $args 0]]} {
        switch -regexp -- [lindex $args 0] {
			{-ch(a(n(n(e(l(_(i(d)?)?)?)?)?)?)?)?$}              { set opts(-channel_id)  [lshift args 1]}                     
			{-co(n(f(i(g(_(d(i(c(t)?)?)?)?)?)?)?)?)?$}          { set opts(-config_dict) [lshift args 1]}
			{-d(e(s(i(g(n(_(d(i(c(t)?)?)?)?)?)?)?)?)?)?$}       { set opts(-design_dict) [lshift args 1]}
			{-m(e(m(o(r(y)?)?)?)?)?$}                           { set opts(-memory)      [lshift args 1]}
			{-o(u(t(_(d(i(r)?)?)?)?)?)?$}                       { set opts(-out_dir)     [lshift args 1]}
			{-q(u(e(u(e)?)?)?)?$}                               { set opts(-queue)       [lshift args 1]}
			{-stage_n(a(m(e)?)?)?$}                             { set opts(-stage_name)  [lshift args 1]}
			{-v(e(r(b(o(s(e)?)?)?)?)?)?$}    	                { set opts(-verbose)     [lshift args 1]}
			{-w(a(i(t)?)?)?$}                                   { set opts(-wait)        [lshift args 1]}
			{-h(e(l(p)?)?)?$}                                   { set opts(-help)        1}
            default {
                return -code error "ERROR: \[run_vivado_step\] Unknown option '[lindex $args 0]', please type 'run_vivado_step -help' for usage info."
            }
        }
        lshift args
    }
	
	## Check if output directory exists
	if {![file exists $opts(-out_dir)]} {
		## Create Output Directory since it doesn't exist
		file mkdir $opts(-out_dir)
	}
	
	## Set Tcl file path for run
	set tclFullFileName "$opts(-out_dir)/run_vXplore_$opts(-stage_name)\.tcl"
	
	## Initialize the stage argument list variable
	set stageArgList ""
	
	## Check if the argument option is set in the configuration dictionary
	if {[dict exists $opts(-config_dict) args]} {
		set stageArgList [dict get $opts(-config_dict) args]
	}
	##
	## ADD run directory locations 
	
	## Create a Tcl File for run based on the selected directives
	set tclFileContent    "##############################################\n"
	append tclFileContent "## vXplore - $opts(-stage_name) Tcl source script ##\n"
	append tclFileContent "##############################################\n"
	append tclFileContent "if {\$argc!=4} {\n"
	append tclFileContent "    puts \"ERROR: Invalid number of arguments.  Found \$argc. Expects 4 Tcl Arguments from Command Line.\"\n"
	append tclFileContent "} else {\n"
	append tclFileContent "    array set opts {}\n"
	append tclFileContent "    lassign \$argv opts(-checkpoint) opts(-directive) opts(-out_dir) opts(-run_dir)\n"
	append tclFileContent "    set opts(-stage) \"$opts(-stage_name)\"\n"
	append tclFileContent "    open_checkpoint \$opts(-checkpoint)\n"
		
	## Check if a pre-tcl file is desired
	if {[dict exists $opts(-config_dict) tcl pre]} {
		append tclFileContent "    catch {source [file normalize [dict get $opts(-config_dict) tcl pre]]}\n"
	}
	
	## Append the actual Vivado Implementation command
	append tclFileContent "    $opts(-stage_name) -directive \$opts(-directive) $stageArgList > \$opts(-out_dir)/$opts(-stage_name)\.log\n"
	
	## Check if a post-tcl file is desired
	if {[dict exists $opts(-config_dict) tcl post]} {
		append tclFileContent "    catch {source [file normalize [dict get $opts(-config_dict) tcl post]]}\n"
	}
	
	append tclFileContent "    report_timing_summary -file \"\$opts(-out_dir)/$opts(-stage_name)_\$opts(-directive)\\_timing_summary.rpt\"\n"
	append tclFileContent "    write_checkpoint \$opts(-out_dir)/\[get_property TOP \[current_design\]\]_$opts(-stage_name)\_\$opts(-directive)\\.dcp\n"
	
	append tclFileContent "}\n"
		
	## open the filename for writing
	set fileHandle [open $tclFullFileName "w"]
	## send the data to the file
	puts $fileHandle $tclFileContent
	## close the file, ensuring the data is written out before you continue with processing.
	close $fileHandle
		
	## Get stage directive list
	set directiveList [lmap [dict get $opts(-config_dict) directives] {lindex $0 1}]
		
	## Create a LSF Group Name to isolate BSUB runs
	set lsfGroupName "/vXplore_$opts(-stage_name)\_$::tcl_platform(user)\_[clock format [clock seconds] -format "%Y%m%d%H%M%S"]"

	## Set the place_design runs output directory
	set runOutputDirectoryFullName "$opts(-out_dir)/$opts(-stage_name)"

	## Initialize the valid WHS design dictionary
	set validDesignWNSDict [dict create]
	## Initialize the data list for the table row display
	set dataList ""
	## Initialize the error list for the table row display
	set errorDataList ""
		
	## Loop though each checkpoint in the list
	foreach dictIndex [dict keys $opts(-design_dict)] {
		## Loop through each of the directives and execute the directive on the input  checkpoint.
		foreach directiveName $directiveList {
			## Parse the directory from the dictionary to get previous run information, if applicable
			set prevDirectoryName [regsub {.*/} [dict get $opts(-design_dict) $dictIndex directory] ""]
			
			## Check if the previous directory name exists
			if {[llength $prevDirectoryName]!=0} {
				## Set the directive output directory based on the previous and current directive
				set directiveDirectory "$runOutputDirectoryFullName/$prevDirectoryName\__$directiveName"
				## Set the LSF job name
				set lsfJobName "$prevDirectoryName\__$directiveName"
			} else {
				## Set the directive output directory based on the current directive
				set directiveDirectory "$runOutputDirectoryFullName/$directiveName"
				## Set the LSF job name
				set lsfJobName "$directiveName"
			}
			
			## Check if directive directory exists
			if {![file exists $directiveDirectory]} {
				## Create Directive Output Directory
				file mkdir $directiveDirectory
			}
			
			## Create LSF bsub command
			set bsubCmd [list bsub -q $opts(-queue) -o $directiveDirectory/lsf.log -app sil_rhel5 -g $lsfGroupName -J $lsfJobName -R 'rusage\[mem=$opts(-memory)\]' vivado -log $directiveDirectory/vivado.log -journal $directiveDirectory/vivado.jou -mode batch -source $tclFullFileName -tclArgs [dict get $opts(-design_dict) $dictIndex checkpoint] $directiveName $directiveDirectory [file normalize "$opts(-out_dir)/../.."]]
			
			## Launch LSF Job for specified Placer Directive
			catch {eval [linsert $bsubCmd 0 exec]}
		}
	}

	## Monitor LSF Runs
	if {[info exists opts(-verbose)] && ($rdi::mode == {tcl})} {
		LSF::monitor_job_status -user $::tcl_platform(user) -wait $opts(-wait) -group $lsfGroupName -display
	} else {
		LSF::monitor_job_status -user $::tcl_platform(user) -wait $opts(-wait) -group $lsfGroupName
	}
	
	## Create Tsble for results display
	set tbl [Table::Create]
	## Create List of Header Strings
	set headerList [list "$opts(-stage_name) Directive" "WNS (ns)" "TNS (ns)"]
	## Add header list as header to the table
	$tbl header $headerList
	
	## Initialize run index
	set runIndex 0
	## Initialize WHS design dictionary
	set designWNSDict [dict create]
	
	## Parse and scan timing summary reports
	foreach directiveDirectory [lsort -index 0 [glob -type d $runOutputDirectoryFullName/*]] {
		## Get Directive Name from directive directory
		set directiveName [regsub {.*/} $directiveDirectory ""]
		## Get the Vivado log file from the selected directive run
		set vivadoLogFile [glob -nocomplain $directiveDirectory/vivado.log]
		
		## Check to ensure only one log file exists in the directory 
		if {[llength $vivadoLogFile]==1} {
			## Parse the timing summary report file found in the output directory
			set vivadoLogDict [parse_vivado_log_file -file $vivadoLogFile]
			
			## Add to the results dictionary
			#dict set resultsDict runs $runIndex $opts(-stage_name) $directiveName directive $directiveName
			#dict set resultsDict runs $runIndex $opts(-stage_name) $directiveName runtime cpu [dict get $vivadoLogDict $opts(-stage_name) cpu]
			#dict set resultsDict runs $runIndex $opts(-stage_name) $directiveName runtime elapsed [dict get $vivadoLogDict $opts(-stage_name) elapsed]
		}
		
		## Get the timing summary file from the selected directive run
		set timingSummaryFile [glob -nocomplain $directiveDirectory/*_timing_summary.rpt]
		
		## Check to ensure only one timing summary report file exists in the directory 
		if {[llength $timingSummaryFile]==1} {
			## Parse the timing summary report file found in the output directory
			array set timingSummaryArray [parse_report_timing_summary -file $timingSummaryFile]
			
			## Append to the list the directive directory and the overall run WNS
			dict set designWNSDict $runIndex index $runIndex
			dict set designWNSDict $runIndex directory $directiveDirectory
			dict set designWNSDict $runIndex checkpoint [glob -nocomplain $directiveDirectory/*.dcp] 
			dict set designWNSDict $runIndex directive $directiveName
			dict set designWNSDict $runIndex WNS $timingSummaryArray(WNS)
			dict set designWNSDict $runIndex TNS $timingSummaryArray(TNS)
			
			## Add to the results dictionary
			dict set resultsDict runs $runIndex $opts(-stage_name) $directiveName timing WNS $timingSummaryArray(WNS)
			dict set resultsDict runs $runIndex $opts(-stage_name) $directiveName timing TNS $timingSummaryArray(TNS)
			
			## Create list of data strings for table row
			lappend dataList [list $directiveName $timingSummaryArray(WNS) $timingSummaryArray(TNS)]
		} else {
			## This section is if a timing report was not found.
			##  No reason is returned for missing timing report.
			##  Please investigate directive run
			##  to determine possible error.
			
			## Create list data strings for table row
			lappend errorDataList [list $directiveName "N/A" "N/A"]
		}
		
		## Increment the run index
		## FIX IN FUTURE
		catch {incr runIndex}
	}
	
	##
	foreach dataRowList [lsort -real -decreasing -index 2 [lsort -real -decreasing -index 1 $dataList]] {
		## Add the data list to the table row
		$tbl addrow $dataRowList
		## Add a table separator
		$tbl separator
	}
	
	foreach dataRowList [lsort -index 0 $errorDataList] {
		## Add the data list to the table row
		$tbl addrow $dataRowList
		## Add a table separator
		$tbl separator
	}	
	
	##
	puts "\nINFO: \[vXplore\] The following table describes the results of the $opts(-stage_name) runs of each of the placer directives.\n"
	puts $opts(-channel_id) "INFO: \[vXplore\] The following table describes the results of the $opts(-stage_name) runs of each of the placer directives.\n"
	
	## Print the Place Directive Timing Summary Table
	$tbl indent 0
	puts [$tbl print]
	puts $opts(-channel_id) [$tbl print]
	
	#puts "DEBUG: \[vXplore::run_vivado_step\] designWNSDict - $designWNSDict"
	
	## Check if any designs completed the stage
	if {[llength $designWNSDict]==0} {
		return -code error "ERROR: \[vXplore\] No design successfully completed stage $opts(-stage_name). Exiting"
	}
	
	## Loop through the design WNS dictionary to remove invalid WNS runs
	foreach runIndex [dict keys $designWNSDict] {
		## Check if the string is of type double
		if {[string is double [dict get $designWNSDict $runIndex WNS]]} {
			dict set validDesignWNSDict $runIndex [dict get $designWNSDict $runIndex]
		}
	}

	## Return the valid designs dictionary 
	return $validDesignWNSDict
}

##########################################################
# 
##########################################################
proc vXplore::run_vivado_step_full {args} {
	## Set Default option values
	array set opts {-help 0}
	
	## Set the command line used for the script
	set commandLine "run_vivado_step_full $args"
    
	## Parse arguments from option command line
	while {[string match -* [lindex $args 0]]} {
        switch -regexp -- [lindex $args 0] {
			{-ch(a(n(n(e(l(_(i(d)?)?)?)?)?)?)?)?$}              { set opts(-channel_id)  [lshift args 1]}                     
			{-co(n(f(i(g(_(d(i(c(t)?)?)?)?)?)?)?)?)?$}          { set opts(-config_dict) [lshift args 1]}
			{-m(e(m(o(r(y)?)?)?)?)?$}                           { set opts(-memory)      [lshift args 1]}
			{-o(u(t(_(d(i(r)?)?)?)?)?)?$}                       { set opts(-out_dir)     [lshift args 1]}
			{-q(u(e(u(e)?)?)?)?$}                               { set opts(-queue)       [lshift args 1]}
			{-v(e(r(b(o(s(e)?)?)?)?)?)?$}    	                { set opts(-verbose)     [lshift args 1]}
			{-w(a(i(t)?)?)?$}                                   { set opts(-wait)        [lshift args 1]}
			{-h(e(l(p)?)?)?$}                                   { set opts(-help)        1}
            default {
                return -code error "ERROR: \[run_vivado_step_full\] Unknown option '[lindex $args 0]', please type 'run_vivado_step_full -help' for usage info."
            }
        }
        lshift args
    }
	
	## Check if output directory exists
	if {![file exists $opts(-out_dir)]} {
		## Create Output Directory since it doesn't exist
		file mkdir $opts(-out_dir)
	}
	
	## Set Tcl file path for run
	set tclFullFileName "$opts(-out_dir)/run_vXplore_$opts(-stage_name)\.tcl"
	
	## Create a Tcl File for run based on the selected directives
	set tclFileContent    "##############################################\n"
	append tclFileContent "## vXplore - $opts(-stage_name) Tcl source script ##\n"
	append tclFileContent "##############################################\n"
	append tclFileContent "if {\$argc!=3} {\n"
	append tclFileContent "    puts \"ERROR: Invalid number of arguments.  Found \$argc. Expects 3 Tcl Arguments from Command Line.\"\n"
	append tclFileContent "} else {\n"
	append tclFileContent "    lassign \$argv dcpFilePath directiveName outputDirectory\n"
	append tclFileContent "    open_checkpoint \$dcpFilePath\n"
		
	## Check if a pre-tcl file is desired
	if {[dict exists $opts(-config_dict) tcl pre]} {
		append tclFileContent "    source [dict get $opts(-config_dict) tcl pre]\n"
	}
	
	##
	append tclFileContent "    $opts(-stage_name) -directive \$directiveName > \$outputDirectory/$opts(-stage_name)\.log\n"
	append tclFileContent "    report_timing_summary -file \"\$outputDirectory/$opts(-stage_name)_\$directiveName\\_timing_summary.rpt\"\n"
	append tclFileContent "    write_checkpoint \$outputDirectory/\[get_property TOP \[current_design\]\]_$opts(-stage_name)\_\$directiveName\\.dcp\n"
		
	## Check if a post-tcl file is desired
	if {[dict exists $opts(-config_dict) tcl post]} {
		append tclFileContent "    source [dict get $opts(-config_dict) tcl post]\n"
	}
		
	append tclFileContent "}\n"
		
	## open the filename for writing
	set fileHandle [open $tclFullFileName "w"]
	## send the data to the file
	puts $fileHandle $tclFileContent
	## close the file, ensuring the data is written out before you continue with processing.
	close $fileHandle
		
	## Get stage directive list
	set directiveList [lmap [dict get $opts(-config_dict) directives] {lindex $0 1}]
		
	## Create a LSF Group Name to isolate BSUB runs
	set lsfGroupName "/vXplore_$::tcl_platform(user)\_[clock format [clock seconds] -format "%Y%m%d%H%M%S"]"

	## Set the place_design runs output directory
	set runOutputDirectoryFullName "$opts(-out_dir)/$opts(-stage_name)"

	## Initialize the valid WHS design dictionary
	set validDesignWNSDict [dict create]
		
	## Loop though each checkpoint in the list
	foreach dictIndex [dict keys $opts(-design_dict)] {
		## Loop through each of the directives and execute the directive on the input  checkpoint.
		foreach directiveName $directiveList {
			## Parse the directory from the dictionary to get previous run information, if applicable
			set prevDirectoryName [regsub {.*/} [dict get $opts(-design_dict) $dictIndex directory] ""]
			
			## Check if the previous directory name exists
			if {[llength $prevDirectoryName]!=0} {
				## Set the directive output directory based on the previous and current directive
				set directiveDirectory "$runOutputDirectoryFullName/$prevDirectoryName\__$directiveName"
				## Set the LSF job name
				set lsfJobName "$prevDirectoryName\__$directiveName"
			} else {
				## Set the directive output directory based on the current directive
				set directiveDirectory "$runOutputDirectoryFullName/$directiveName"
				## Set the LSF job name
				set lsfJobName "$directiveName"
			}
			
			## Check if directive directory exists
			if {![file exists $directiveDirectory]} {
				## Create Directive Output Directory
				file mkdir $directiveDirectory
			}
			
			## Create LSF bsub command
			set bsubCmd [list bsub -q $opts(-queue) -o $directiveDirectory/lsf.log -app sil_rhel5 -g $lsfGroupName -J $lsfJobName -R 'rusage\[mem=$opts(-memory)\]' vivado -log $directiveDirectory/vivado.log -journal $directiveDirectory/vivado.jou -mode batch -source $tclFullFileName -tclArgs [dict get $opts(-design_dict) $dictIndex checkpoint] $directiveName $directiveDirectory]
			
			## Launch LSF Job for specified Placer Directive
			catch {eval [linsert $bsubCmd 0 exec]}
		}
	}

	## Monitor LSF Runs
	if {[info exists opts(-verbose)] && ($rdi::mode == {tcl})} {
		LSF::monitor_job_status -user $::tcl_platform(user) -wait $opts(-wait) -group $lsfGroupName -display
	} else {
		LSF::monitor_job_status -user $::tcl_platform(user) -wait $opts(-wait) -group $lsfGroupName
	}
	
	## Create Tsble for results display
	set tbl [Table::Create]
	## Create List of Header Strings
	set headerList [list "$opts(-stage_name) Directive" "WNS (ns)" "TNS (ns)"]
	## Add header list as header to the table
	$tbl header $headerList
	
	## Initialize run index
	set runIndex 0
	## Initialize WHS design dictionary
	set designWNSDict [dict create]
	
	## Parse and scan timing summary reports
	foreach directiveDirectory [lsort -index 0 [glob -type d $runOutputDirectoryFullName/*]] {
		## Get Directive Name from directive directory
		set directiveName [regsub {.*/} $directiveDirectory ""]
		## Get the Vivado log file from the selected directive run
		set vivadoLogFile [glob -nocomplain $directiveDirectory/vivado.log]
		
		## Check to ensure only one log file exists in the directory 
		if {[llength $vivadoLogFile]==1} {
			## Parse the timing summary report file found in the output directory
			set vivadoLogDict [parse_vivado_log_file -file $vivadoLogFile]
			
			## Add to the results dictionary
			#dict set resultsDict runs $runIndex $opts(-stage_name) $directiveName directive $directiveName
			#dict set resultsDict runs $runIndex $opts(-stage_name) $directiveName runtime cpu [dict get $vivadoLogDict $opts(-stage_name) cpu]
			#dict set resultsDict runs $runIndex $opts(-stage_name) $directiveName runtime elapsed [dict get $vivadoLogDict $opts(-stage_name) elapsed]
		}
		
		## Get the timing summary file from the selected directive run
		set timingSummaryFile [glob -nocomplain $directiveDirectory/*_timing_summary.rpt]
		
		## Check to ensure only one timing summary report file exists in the directory 
		if {[llength $timingSummaryFile]==1} {
			## Parse the timing summary report file found in the output directory
			array set timingSummaryArray [parse_report_timing_summary -file $timingSummaryFile]
			
			## Append to the list the directive directory and the overall run WNS
			dict set designWNSDict $runIndex index $runIndex
			dict set designWNSDict $runIndex directory $directiveDirectory
			dict set designWNSDict $runIndex checkpoint [glob -nocomplain $directiveDirectory/*.dcp] 
			dict set designWNSDict $runIndex directive $directiveName
			dict set designWNSDict $runIndex WNS $timingSummaryArray(WNS)
			
			## Add to the results dictionary
			dict set resultsDict runs $runIndex $opts(-stage_name) $directiveName timing WNS $timingSummaryArray(WNS)
			dict set resultsDict runs $runIndex $opts(-stage_name) $directiveName timing TNS $timingSummaryArray(TNS)
			
			## Create list of data strings for table row
			set dataList [list $directiveName $timingSummaryArray(WNS) $timingSummaryArray(TNS)]
			
			## Add the data list to the table row
			$tbl addrow $dataList
			## Add a table separator
			$tbl separator
		} else {
			## This section is if a timing report was not found.
			##  No reason is returned for missing timing report.
			##  Please investigate directive run
			##  to determine possible error.
			
			## Create list data strings for table row
			set dataList [list $directiveName "N/A" "N/A"]
			
			## Add the data list to the table row
			$tbl addrow $dataList
			## Add a table separator
			$tbl separator
		}
		
		## Increment the run index
		## FIX IN FUTURE
		catch {incr runIndex}
	}
	
	##
	puts "\nINFO: \[vXplore\] The following table describes the results of the $opts(-stage_name) runs of each of the placer directives.\n"
	puts $opts(-channel_id) "INFO: \[vXplore\] The following table describes the results of the $opts(-stage_name) runs of each of the placer directives.\n"
	
	## Print the Place Directive Timing Summary Table
	$tbl indent 0
	puts [$tbl print]
	puts $opts(-channel_id) [$tbl print]
	
	#puts "DEBUG: \[vXplore::run_vivado_step\] designWNSDict - $designWNSDict"
	
	## Loop through the design WNS dictionary to remove invalid WNS runs
	foreach runIndex [dict keys $designWNSDict] {
		## Check if the string is of type double
		if {[string is double [dict get $designWNSDict $runIndex WNS]]} {
			dict set validDesignWNSDict $runIndex [dict get $designWNSDict $runIndex]
		}
	}

	## Return the valid designs dictionary 
	return $validDesignWNSDict
}

##########################################################
# 
##########################################################
proc vXplore::sort_design_dict_by_wns_then_tns {args} {
	## Set Default option values
	array set opts {-help 0}
	
	## Set the command line used for the script
	set commandLine "vXplore::sort_design_dict_by_wns $args"
    
	## Parse arguments from option command line
	while {[string match -* [lindex $args 0]]} {
        switch -regexp -- [lindex $args 0] {
			{-d(i(c(t)?)?)?$} { set opts(-dict) [lshift args 1]}
			{-h(e(l(p)?)?)?$} { set opts(-help) 1}
            default {
                return -code error "ERROR: \[vXplore::sort_design_dict_by_wns\] Unknown option '[lindex $args 0]', please type 'vXplore::sort_design_dict_by_wns -help' for usage info."
            }
        }
        lshift args
    }

	#puts "DEBUG: \[vXplore::sort_design_dict_by_wns\] opts(-dict) - $opts(-dict)"
	
	foreach dictIndex [dict keys $opts(-dict)] {
		lappend WNSList [list $dictIndex [dict get $opts(-dict) $dictIndex WNS] [dict get $opts(-dict) $dictIndex TNS]]
	}
	
	## Sort by WNS first, then by TNS
	set sortedList [lsort -real -decreasing -index 2 [lsort -real -decreasing -index 1 $WNSList]]
	## Create the sorted dictionary 
	set sortedDict [dict create]
	
	## Loop through each element of the sorted list
	foreach sortedElement $sortedList {
		dict set sortedDict [lindex $sortedElement 0] [dict get $opts(-dict) [lindex $sortedElement 0]]
	}
	
	## Return sorted dictionary
	return $sortedDict
}

##########################################################
# 
##########################################################
proc vXplore::filter_design_dict_by_step_count {args} {
	## Set Default option values
	array set opts {-help 0}
	
	## Set the command line used for the script
	set commandLine "vXplore::filter_design_dict_by_step_count $args"
    
	## Parse arguments from option command line
	while {[string match -* [lindex $args 0]]} {
        switch -regexp -- [lindex $args 0] {
			{-d(i(c(t)?)?)?$}                         { set opts(-dict) [lshift args 1]}
			{-s(t(e(p(_(c(o(u(n(t)?)?)?)?)?)?)?)?)?$} { set opts(-step_count)    [lshift args 1]}
			{-h(e(l(p)?)?)?$}                         { set opts(-help) 1}
            default {
                return -code error "ERROR: \[vXplore::filter_design_dict_by_step_count\] Unknown option '[lindex $args 0]', please type 'vXplore::filter_design_dict_by_step_count -help' for usage info."
            }
        }
        lshift args
    }

	set filteredDesignDict [dict create]

	set countIndex 0
	
	foreach dictIndex [dict keys $opts(-dict)] {
		if {$countIndex>=$opts(-step_count)} {
			break
		} else {
			dict set filteredDesignDict $dictIndex [dict get $opts(-dict) $dictIndex]
		}
		
		incr countIndex
	}
	
	return $filteredDesignDict
}

# #########################################################
#
# #########################################################
proc read_configuration_file {args} {
	## Set Default option values
	array set opts {-help 0 }
    
    ## Parse arguments from option command line
	while {[string match -* [lindex $args 0]]} {
        switch -regexp -- [lindex $args 0] {
            {-f(i(l(e)?)?)?$}             { set opts(-file)    [lshift args 1]}
            {-h(e(l(p)?)?)?$}             { set opts(-help)    1}
            default {
                return -code error "ERROR: \[read_configuration_file\] Unknown option '[lindex $args 0]', please type 'read_configuration_file -help' for usage info."
            }
        }
        lshift args
    }
	
	## Read the YAML File into Tcl Dictionary
	set fileDict [::yaml::yaml2dict -file $opts(-file)]
	
	## Return the Tcl dictionary
	return $fileDict
}

proc vXplore::get_default_vXplore_configuration {args} {
	## Set Default option values
	array set opts {-help 0 }
    
    ## Parse arguments from option command line
	while {[string match -* [lindex $args 0]]} {
        switch -regexp -- [lindex $args 0] {
            {-h(e(l(p)?)?)?$}             { set opts(-help)    1}
            default {
                return -code error "ERROR: \[vXplore::get_default_vXplore_configuration\] Unknown option '[lindex $args 0]', please type 'vXplore::get_default_vXplore_configuration -help' for usage info."
            }
        }
        lshift args
    }
	
	## Create the dictionary variable to store the default configuration
	set defaultDict [dict create]
	
	## Initialize the first stage (opt_design)
	dict set defaultDict index 0 stage opt_design
	dict set defaultDict index 0 directives {name Default name Explore}
	## Initialize the second stage (place_design)
	dict set defaultDict index 1 stage place_design
	dict set defaultDict index 1 directives {name Default name Explore}
	##
	dict set defaultDict index 2 stage phys_opt_design
	dict set defaultDict index 2 directives {name Default name Explore}
	##
	dict set defaultDict index 3 stage route_design
	dict set defaultDict index 3 directives {name Default name Explore}
	
	## Return the default configuration dictionary
	return $defaultDict
}

# #########################################################
#                                                         #
# #########################################################	
proc parse_vivado_log_file {args} {
	## Create Argument Array
	array set opts [concat {-report_string "" -file ""} $args]
	
	## Initialize Report Summary Section Flag
	set summaryFlag 0

	## Argument Parsing
	if {$opts(-report_string) ne ""} {
		set reportLogFileString $opts(-report_string)
	} elseif {$opts(-file) ne ""} {
		## Read the size of the file for memory
		set fSize	[file size $opts(-file)]
		## Open the filehandle of the XDC file for reading
		set fHandle	[open $opts(-file) r]
		## Read the contents of the XDC file
		set fData	[read $fHandle $fSize]
		## Close the filehandle of the XDC
		close $fHandle
		
		set reportLogFileString $fData
	} else {
		return -code error "ERROR: \[parse_vivado_log_file\] Missing -file and -return_string arguments.  One of these arguments are required."
	}
	
	##
	set reportLogDict [dict create]
	
	##
	foreach reportLine [split $reportLogFileString '\n'] {
		## Check status of place_design
		
		if {[regexp {^\s*place_design:\s+Time\s+\(s\)\s*:\s+cpu\s*=\s*(\d+:\d+:\d+)\s*;\s*elapsed\s*=\s*(\d+:\d+:\d+)\s*\.\s*Memory\s*\(MB\)\s*:\s*peak\s*=\s*(\d+\.\d+)\s*;\s*gain\s*=\s*(\d+\.\d+)} $reportLine matchString cpuTime elapsedTime memoryPeak memoryGain]} {
			dict set reportLogDict place_design cpu $cpuTime
			dict set reportLogDict place_design elapsed $cpuTime
		} elseif {[regexp {^\s*phys_opt_design:\s+Time\s+\(s\)\s*:\s+cpu\s*=\s*(\d+:\d+:\d+)\s*;\s*elapsed\s*=\s*(\d+:\d+:\d+)\s*\.\s*Memory\s*\(MB\)\s*:\s*peak\s*=\s*(\d+\.\d+)\s*;\s*gain\s*=\s*(\d+\.\d+)} $reportLine matchString cpuTime elapsedTime memoryPeak memoryGain]} {
			dict set reportLogDict phys_opt_design cpu $cpuTime
			dict set reportLogDict phys_opt_design elapsed $cpuTime			
		} elseif {[regexp {^\s*route_design:\s+Time\s+\(s\)\s*:\s+cpu\s*=\s*(\d+:\d+:\d+)\s*;\s*elapsed\s*=\s*(\d+:\d+:\d+)\s*\.\s*Memory\s*\(MB\)\s*:\s*peak\s*=\s*(\d+\.\d+)\s*;\s*gain\s*=\s*(\d+\.\d+)} $reportLine matchString cpuTime elapsedTime memoryPeak memoryGain]} {
			dict set reportLogDict route_design cpu $cpuTime
			dict set reportLogDict route_design elapsed $cpuTime			
		}
	}
	
	##
	return $reportLogDict
}

# #########################################################
#                                                         #
# #########################################################	
proc parse_report_timing_summary {args} {
	## Create Argument Array
	array set opts [concat {-report_string "" -file ""} $args]
	
	## Initialize Report Summary Section Flag
	set summaryFlag 0
	set dataFlag    0

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
			set dataFlag 1
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
	
	if {$dataFlag==0} {
		set reportSummaryArray(WNS) "N/A"
		set reportSummaryArray(TNS) "N/A"
		set reportSummaryArray(TNS_Failing_Endpoints) "N/A"
		set reportSummaryArray(TNS_Total_Endpoints) "N/A"
		set reportSummaryArray(WHS) "N/A"
		set reportSummaryArray(THS) "N/A"
		set reportSummaryArray(THS_Failing_Endpoints) "N/A"
		set reportSummaryArray(THS_Total_Endpoints) "N/A"
		set reportSummaryArray(WPWS) "N/A"
		set reportSummaryArray(TPWS) "N/A"
		set reportSummaryArray(TPWS_Failing_Endpoints) "N/A"
		set reportSummaryArray(TPWS_Total_Endpoints) "N/A"	
	}
	
	##
	return [array get reportSummaryArray]
}

# #########################################################
#
# #########################################################
proc lmap {list body} {
    upvar 1 0 var  ;# $0 will be available automatically!
    set res {}
    foreach var $list {lappend res [uplevel 1 $body]}
    set res
}

# #########################################################
# lshift
# #########################################################
proc lshift {varname {nth 0}} {
	upvar $varname args
	set r [lindex $args $nth]
	set args [lreplace $args $nth $nth]
	return $r
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

	if {[info exists opts(-display)]} {
		## Clear the Vivado terminal screen 
		puts [exec clear]
	}
	
	## Check if the group command line option was used
    if {[info exists opts(-group)] && $opts(-group) ne ""} {
		##
		if {[catch {upvar monitorStatusDict jobStatusDict} errorString]} {
			##
			puts "FAILED: $errorString"
			set jobStatusDict [dict create]
		}
		
		## If display option is set, report the user name and LSF group name that's being used to monitor the status of the LSF jobs
		if {[info exists opts(-display)]} {
			puts "\nINFO: \[report_job_status\] Monitoring LSF Job Status for user $opts(-user) and LSF group $opts(-group).\n";
        }
		
		## Set the temporary file name to store the LSF bjobs report 
		set fileName "[pwd]/$opts(-group)\_bjobs.tmp";
		## Set the LSF bsub command to report the current job status of the request LSF group name
        set bjobCmd  [list bjobs -W -u $opts(-user) -g $opts(-group) -a >& $fileName]
    } else {
		##
		set jobStatusDict [dict create]
		
		## If display option is set, report the user name that's being used to monitor the status of the LSF jobs
		if {[info exists opts(-display)]} {
			puts "\nINFO: \[report_job_status\] Monitoring LSF Job Status for user $opts(-user).\n";
        }
		
		## Set the temporary file name to store the LSF bjobs report 
		set fileName "[pwd]/$$opts(-user)\_bjobs.tmp";
		## Set the LSF bsub command to report the current job status of the request LSF user
        set bjobCmd [list bjobs -W -u $opts(-user) >& $fileName]
    }
	
	## Execute the LSF bsub command
    eval [linsert $bjobCmd 0 exec]

	## Set the file size of the temporary LSF bjobs report file
	set fSize	[file size $fileName]
	## Open the file handle of the file for reading
	set fHandle	[open $fileName r]
	## Read the contents of the file
	set fData	[read $fHandle $fSize]
	## Close the file handle
	close $fHandle
	
	## Initialize the job running count to 0
    set jobRunningCount 0

	# Loop through each line of the report file
    foreach fileLine [split $fData '\n'] {
		## Parse the line to check for the required LSF job information
        if {[regexp {(\d+)\s+(\S+)\s+(\S+)\s+\S+\s+\S+\s+\S+\s+(.+)\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+(\S+)\s+(\S+)} $fileLine matchString jobID jobUserName jobStatus jobName jobStartTime jobFinishTime]} {
			## Add the ID, User name, job name, and Job Status to the dictionary
			dict set jobStatusDict $jobID id $jobID
			dict set jobStatusDict $jobID user $jobUserName
			dict set jobStatusDict $jobID name $jobName
			dict set jobStatusDict $jobID status $jobStatus
			
			## Parse the start time and add to the dictionary
			if {[regexp {(\d+)\/(\d+)-(\S+)} $jobStartTime matchString startMonth startDay startTime]} {
				dict set jobStatusDict $jobID start_time time $startTime
				dict set jobStatusDict $jobID start_time base [clock scan "[clock format [clock seconds] -format "%Y"]-$startMonth-$startDay"]
			}
			
			## Parse the finish time and add to the dictionary
			if {[regexp {(\d+)\/(\d+)-(\S+)} $jobFinishTime matchString finishMonth finishDay finishTime]} {
				dict set jobStatusDict $jobID finish_time time $finishTime
				dict set jobStatusDict $jobID finish_time base [clock scan "[clock format [clock seconds] -format "%Y"]-$finishMonth-$finishDay"]
			}
			
			## If display option is set, report job status of each specific job
			if {[info exists opts(-display)]} {
				## Check if the Job is running
				if {$jobStatus eq "RUN"} {
					#puts "INFO: \[report_job_status\] LSF Job Status: $jobID = $jobStatus";
				}
			}
			
			## If the job is currently running or pending, increment the job running count
            if {($jobStatus eq "RUN") || ($jobStatus eq "PEND")} {
                incr jobRunningCount
            }
        }
    }
	
	## Delete the temporary file created for bjobs monitoring
	file delete $fileName
	
	## Display the Job information if option is set
	if {[info exists opts(-display)]} {
		## Set the format string length for the display table
		set formatStringLength 25
		set jobNameStringFormatLength 75
		
		## Display Header for Job Info Table
		puts "[format "%-$jobNameStringFormatLength\s" "Directive Name"][format "%-$formatStringLength\s" "Job ID"][format "%-$formatStringLength\s" "Job Status"][format "%-$formatStringLength\s" "Elapsed Time"]"
		##
		foreach jobID [dict keys $jobStatusDict] {
			## Check the status of the job
			if {[dict get $jobStatusDict $jobID status] eq "RUN"} {
				## Determine Elapsed Time
				set elapsedTime [expr ([clock seconds] - [clock scan [dict get $jobStatusDict $jobID start_time time] -base [dict get $jobStatusDict $jobID start_time base]])]
				## Display the Job Status and Elapsed Time in the correct format
				puts "[format "%-$jobNameStringFormatLength\s" [dict get $jobStatusDict $jobID name]][format "%-$formatStringLength\s" [dict get $jobStatusDict $jobID id]][format "%-$formatStringLength\s" [dict get $jobStatusDict $jobID status]][format "%-$formatStringLength\s" "[format "%02d" [expr $elapsedTime/3600]]:[format "%02d" [expr ($elapsedTime%3600)/60]]:[format "%02d" [expr $elapsedTime%60]]"]"
			} elseif {[dict get $jobStatusDict $jobID status] eq "PEND"} {
				## Display the Job Status and time as not started
				puts "[format "%-$jobNameStringFormatLength\s" [dict get $jobStatusDict $jobID name]][format "%-$formatStringLength\s" [dict get $jobStatusDict $jobID id]][format "%-$formatStringLength\s" [dict get $jobStatusDict $jobID status]][format "%-$formatStringLength\s" "-"]"
			} elseif {[dict get $jobStatusDict $jobID status] eq "EXIT" || [dict get $jobStatusDict $jobID status] eq "DONE"} {
				## Determine Elapsed Time
				set elapsedTime [expr ([clock scan [dict get $jobStatusDict $jobID finish_time time] -base [dict get $jobStatusDict $jobID finish_time base]]) - ([clock scan [dict get $jobStatusDict $jobID start_time time] -base [dict get $jobStatusDict $jobID start_time base]])]
				## Display the Job Status and Elapsed Time in the correct format
				puts "[format "%-$jobNameStringFormatLength\s" [dict get $jobStatusDict $jobID name]][format "%-$formatStringLength\s" [dict get $jobStatusDict $jobID id]][format "%-$formatStringLength\s" [dict get $jobStatusDict $jobID status]][format "%-$formatStringLength\s" "[format "%02d" [expr $elapsedTime/3600]]:[format "%02d" [expr ($elapsedTime%3600)/60]]:[format "%02d" [expr $elapsedTime%60]]"]"
			}
		}
	}
	
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
	#puts [exec clear]
	
	## Initialize global dictionary for monitoring the job list if group list is specified
	set	monitorStatusDict [dict create]
	
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
			puts ""
			puts "INFO: \[LSF::monitor_job_status\] Elapsed Time: [format "%d:%02d:%02d" $cpu_hrs $cpu_mins $cpu_secs]\n"
			puts ""
		}
	}
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
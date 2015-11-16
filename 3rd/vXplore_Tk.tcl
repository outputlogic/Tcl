set auto_path [linsert $auto_path 0 /proj/xbuilds/2015.1_INT_daily_latest/installs/lin64/Vivado/2015.1/tps/tcl/tcl8.5]
set auto_path [linsert $auto_path 0 /proj/xbuilds/2015.1_INT_daily_latest/installs/lin64/Vivado/2015.1/tps/tcl]
set auto_path [linsert $auto_path 0 /proj/xbuilds/2015.1_INT_daily_latest/installs/lin64/Vivado/2015.1/bin/unwrapped/lib]
set auto_path [linsert $auto_path 0 /tmp/pabuild/tcl8.5.14/rdi-lib/lnx64.o/lib /tmp/pabuild/tcl8.5.14/lib]

package require Tk
package require Img
package require yaml

# Create the namespace
namespace eval vXplore::tk {}
namespace eval vXplore::tk::configuration {}

# #########################################################
# lshift
# #########################################################
proc lshift {varname {nth 0}} {
	upvar $varname args
	set r [lindex $args $nth]
	set args [lreplace $args $nth $nth]
	return $r
}

# #########################################################
# 
# #########################################################
proc vXplore::tk::open_configuration_file_OnSelect {windowFrame varname} {
	## Get the variable from the passed variable reference
	upvar $varname var
	
	## Set the supported file types
	set fileTypeList {
		{"YAML Ain't Markup Language" {.yml .yaml}}
	}
	
	## Check the variable to get the current directory
	if {[regexp {(.*)/.*$} $var matchString dirName]} {
		## Get the file name from the dialog pop-up
		set fileName [tk_getOpenFile -initialdir $dirName -filetypes $fileTypeList -parent $windowFrame]
	} else {
		## Get the file name from the dialog pop-up
		set fileName [tk_getOpenFile -initialdir [pwd] -filetypes $fileTypeList -parent $windowFrame]	
	}
	
	## Check that a file was selected from the dialog pop-up
	if {[llength $fileName]!=0} {
		## Set the file name to the entry
		set var $fileName
	}
	
	return;
}

# #########################################################
# 
# #########################################################
proc vXplore::tk::open_checkpoint_OnSelect {windowFrame varname} {
	## Get the variable from the passed variable reference
	upvar $varname var
	
	## Set the supported file types
	set fileTypeList {
		{"Vivado Design Checkpoint" {.dcp}}
	}
	
	## Check the variable to get the current directory
	if {[regexp {(.*)/.*$} $var matchString dirName]} {
		## Get the file name from the dialog popup
		set fileName [tk_getOpenFile -initialdir $dirName -filetypes $fileTypeList -parent $windowFrame]
	} else {
		## Get the file name from the dialog popup
		set fileName [tk_getOpenFile -initialdir [pwd] -filetypes $fileTypeList -parent $windowFrame]	
	}	
	
	## Check that a file was selected from the dialog popup
	if {[llength $fileName]!=0} {
		## Set the file name to the entry
		set var $fileName
	}
	
	return;
}

# #########################################################
# 
# #########################################################
proc vXplore::tk::changeState_onSelect {entry} {
	if {[$entry instate disabled]} {
		$entry configure -state !disable
	} else {
		$entry configure -state disable
	}
	
	return;
}

# #########################################################
# 
# #########################################################
proc vXplore::tk::validateDirectory_onKey {entry text dirName} {
	set dirName "[$entry get]$text/$dirName"
	
	if {[file exists [file normalize $dirName]]} {
		$entry configure -foreground "#FF0000"
	} else {
		$entry configure -foreground "#000000"
	}
	
	return 1;
}

# #########################################################
# 
# #########################################################
proc vXplore::tk::validate_and_build_command_line {args} {
	## Set Default option values
	array set opts {}
	
	## Parse arguments from option command line
	while {[string match -* [lindex $args 0]]} {
        switch -regexp -- [lindex $args 0] {
            {-ch(e(c(k(p(o(i(n(t)?)?)?)?)?)?)?)?$}    { set opts(-checkpoint)    [lshift args 1]}
			{-configu(r(a(t(i(o(n)?)?)?)?)?)?$}       { set opts(-configuration) [lshift args 1]}
			{-config_(d(i(c(t)?)?)?)?$}               { set opts(-config_dict)   [lshift args 1]}
			{-l(o(g)?)?$}                             { set opts(-log)           [lshift args 1]}
			{-m(e(m(o(r(y)?)?)?)?)?$}                 { set opts(-memory)        [lshift args 1]}
			{-o(u(t(_(d(i(r)?)?)?)?)?)?$}             { set opts(-out_dir)       [lshift args 1]}
			{-q(u(e(u(e)?)?)?)?$}                     { set opts(-queue)         [lshift args 1]}
			{-r(u(n(_(a(l(l)?)?)?)?)?)?$}             { set opts(-run_all)       [lshift args 1]}
			{-s(t(e(p(_(c(o(u(n(t)?)?)?)?)?)?)?)?)?$} { set opts(-step_count)    [lshift args 1]}
			{-v(e(r(b(o(s(e)?)?)?)?)?)?$}    	      { set opts(-verbose)       [lshift args 1]}
			{-w(a(i(t)?)?)?$}                         { set opts(-wait)          [lshift args 1]}
            default {
                return -code error "ERROR: \[vXplore\] Unknown option '[lindex $args 0]', please type 'vXplore -help' for usage info."
            }
        }
        lshift args
    }
	
	## Set Command Line variable
	set commandLine ""
	
	## Validate that the checkpoint option is a checkpoint
	if {![regexp {.*\.dcp$} $opts(-checkpoint)]} {
		tk_messageBox -message "Vivado Checkpoint is required." -type ok -icon error
		return;
	} elseif {![file exists $opts(-checkpoint)]} {
		tk_messageBox -message "Unable to find Vivado Checkpoint file." -type ok -icon error
		return;
	} else {
		append commandLine "-checkpoint $opts(-checkpoint)"
	}
	
	if {![regexp {.*\.(yml|yaml)$} $opts(-configuration)]} {
		tk_messageBox -message "vXplore Configuration file is required." -type ok -icon error
		return
	} else {
		append commandLine " -configuration $opts(-configuration)"
	}
	
	if {[string is double $opts(-memory)]} {
		append commandLine " -memory $opts(-memory)"
	}
	
	if {$opts(-out_dir) ne ""} {
		append commandLine " -out_dir $opts(-out_dir)"
	}
	
	if {[string is alpha $opts(-queue)]} {
		append commandLine " -queue $opts(-queue)"
	}
	
	if {$opts(-run_all)} {
		append commandLine " -run_all"
	} elseif {[string is double $opts(-step_count)]} {
		append commandLine " -step_count $opts(-step_count)"
	} else {
		tk_messageBox -message "Please enter a Step Count for the number of runs to execute on the next Implementation stage" -type ok -icon error
		return
	}
	
	if {$opts(-verbose)} {
		append commandLine " -verbose"
	}
	
	if {[string is double $opts(-wait)]} {
		append commandLine " -wait $opts(-wait)"
	}
	
	return $commandLine
}

# #########################################################
# 
# #########################################################
proc vXplore::tk::configuration::tcl_OnSelect {label index type} {
	## Get the global variable for the configuration options
	global cOptions
	
	## Set the supported file types
	set fileTypeList {
		{"Tool Command Language file" {.tcl}}
		{"All Files" {*}}
	}
	
	## Check if the a Tcl file has already been set, to set the initial directory
	if {[info exists cOptions($index-tcl_script-$type)]} {
		set initialTclDirectory $cOptions($index-tcl_script-$type)
	} else {
		set initialTclDirectory ""
	}
	
	## Check the variable to get the current directory
	if {[regexp {(.*)/.*$} $initialTclDirectory matchString dirName]} {
		## Get the file name from the dialog pop-up
		set fileName [tk_getOpenFile -initialdir $dirName -filetypes $fileTypeList -parent .]
	} else {
		## Get the file name from the dialog pop-up
		set fileName [tk_getOpenFile -initialdir [pwd] -filetypes $fileTypeList -parent .]	
	}
	
	## Check that a file was selected from the dialog pop-up
	if {[llength $fileName]!=0} {
		## Set the file name to the entry
		set cOptions($index-tcl_script-$type) $fileName
	}
	
	return;
}

# #########################################################
# 
# #########################################################
proc vXplore::tk::configuration::add_configuration_index_widget {windowFrame} {
	## Get the global variable for the configuration index
	global index
	## Get the global variable for the configuration options
	global cOptions
	
	## Set the index value of the configuration index
	set cOptions($index-index) $index
	## Set the row value for the widget
	set rowIndex [expr $index+1]
	
	## Create an entry to display the index value 
	ttk::entry $windowFrame\.index_$index -textvar cOptions($index-index) -background white -width 5
	## Configure the index entry to be read only
	$windowFrame\.index_$index configure -state readonly
	## Place the index entry into the specified row and column 0
	grid $windowFrame\.index_$index -row $rowIndex -column 0 -padx 5 -pady 5

	## Create a combo box for each stage of Implementation
	ttk::combobox $windowFrame\.stage_$index -textvariable cOptions($index-stage) -values [list opt_design place_design phys_opt_design route_design] -width 13
	## Place the index entry into the specified row and column 1
	grid $windowFrame\.stage_$index -row $rowIndex -column 1 -padx 5 -pady 5

	## Create a button for opening the directive window for the selected Implementation stage
	button $windowFrame\.directives_$index -text "Directives" -command "vXplore::tk::configuration::create_directive_window_onButton $index"
	## Place the button into the specified row and column 2
	grid $windowFrame\.directives_$index -row $rowIndex -column 2 -padx 5 -pady 5
	
	## Create an entry to input arguments for the specified stage
	ttk::entry $windowFrame\.args_$index -textvar cOptions($index-args) -background white -width 20
	## Place the button into the specified row and column 3
	grid $windowFrame\.args_$index -row $rowIndex -column 3 -padx 5 -pady 5

	## Create a button for opening the Tcl window for the selected Implementation stage
	button $windowFrame\.tcl_$index -text "Tcl" -command "vXplore::tk::configuration::create_tcl_window_onButton $index"
	## Place the button into the specified row and column 3
	grid $windowFrame\.tcl_$index -row $rowIndex -column 4 -padx 5 -pady 5

	## Increment the global index variable
	incr index
}

# #########################################################
# 
# #########################################################
proc vXplore::tk::configuration::create_directive_window_onButton {index} {
	## Get the global variable for the configuration options
	global cOptions
	
	## Check if an Implementation stage was selected prior to directive window being created, error if not
	if {![info exists cOptions($index-stage)]} {
		tk_messageBox -message "Please enter a implementation stage prior to selecting directives" -type ok -icon error
	} else {
		## Check if Directive window exists
		if {![winfo exists .directiveWindow]} {
			## Create the top-level window for the directive list
			tk::toplevel .directiveWindow
			## Set the directive window as the top most window
			wm attributes .directiveWindow -topmost 1
			
			## Set the directives for each Implementation stage
			set directiveList(opt_design)      [list Default Explore]
			set directiveList(place_design)    [list Default Explore ExtraNetDelay_high ExtraNetDelay_medium ExtraNetDelay_low ExtraPostPlacementOpt LateBlockPlacement Quick RuntimeOptimized SpreadLogic_high SpreadLogic_medium SpreadLogic_low SSI_BalanceSLLs SSI_BalanceSLRs SSI_ExtraTimingOpt SSI_HighUtilSLRs SSI_SpreadSLLs WLDrivenBlockPlacement]
			set directiveList(phys_opt_design) [list AddRetime AggressiveExplore AlternateDelayModeling AlternateFlowWithRetiming AlternateReplication AggressiveFanoutOpt Default Explore ExploreWithHoldFix]
			set directiveList(route_design)    [list AdvancedSkewModeling Default Explore HigherDelayCost MoreGlobalIterations NoTimingRelaxation RuntimeOptimized]
			
			## Set the initial frame
			frame .directiveWindow.baseFrame
			## Expands the base frame both vertically and horizontally
			pack .directiveWindow.baseFrame -fill both -expand 1
			## Create a child frame within the base frame
			frame .directiveWindow.baseFrame.subFrame -relief raised -borderwidth 1
			## Expands the base frame both vertically and horizontally
			pack .directiveWindow.baseFrame.subFrame -fill both -expand 1

			## Loop through each directive based on the selected stage for the configuration index
			for {set i 0} {$i < [llength $directiveList($cOptions($index-stage))]} {incr i} {
				checkbutton .directiveWindow.baseFrame.subFrame.checkbox$index\_[lindex $directiveList($cOptions($index-stage)) $i] -variable cOptions($index-directives-[lindex $directiveList($cOptions($index-stage)) $i]) -text [lindex $directiveList($cOptions($index-stage)) $i]
				grid .directiveWindow.baseFrame.subFrame.checkbox$index\_[lindex $directiveList($cOptions($index-stage)) $i] -row $i -column 0 -padx 5 -pady 5 -sticky w
			}
			
			## Create a button to run the program
			ttk::button .directiveWindow.baseFrame.ok_button -text "OK" -command {destroy .directiveWindow}
			## Pack the run button on the bottom right next to the close button
			pack .directiveWindow.baseFrame.ok_button -side bottom
			
			## Update the window to ensure the winfo is correct
			update
	
			## Set the Width of the Window (this will be the minimum size)
			set width [winfo width .directiveWindow]
			## Set the height of the window (this will be the minimum size)
			set height [winfo height .directiveWindow]

			## Set the X & Y to the center of the screen
			set x [expr { ( [winfo vrootwidth  .] - $width  ) / 2 }]
			set y [expr { ( [winfo vrootheight .] - $height ) / 2 }]
			
			## Align the Directive window in the center of the screen
			wm geometry .directiveWindow +${x}+${y}

			## Set the title of the window
			wm title .directiveWindow "Set $cOptions($index-stage) Directives"			
		}
	}
	
	return
}

# #########################################################
# 
# #########################################################
proc vXplore::tk::configuration::create_tcl_window_onButton {index} {
	## Get the global variable for the configuration options
	global cOptions

	## Check if the Tcl window already exists
	if {![winfo exists .tclWindow]} {
		## Create the top-level window for the Tcl pre and post scripts
		tk::toplevel .tclWindow
		## Set the tcl window as the top most window
		wm attributes .tclWindow -topmost 1
		
		## Set the title of the window
		wm title .tclWindow "Set Tcl Files"
		
		## Set the initial frame
		frame .tclWindow.baseFrame
		## Expands the base frame both vertically and horizontally
		pack .tclWindow.baseFrame -fill both -expand 1
		## Create a child frame within the base frame
		frame .tclWindow.baseFrame.subFrame -relief raised -borderwidth 1
		## Expands the base frame both vertically and horizontally
		pack .tclWindow.baseFrame.subFrame -fill both -expand 1
		
		##
		label .tclWindow.baseFrame.subFrame.tcl_pre_label_$index -text "Tcl.pre"
		##
		grid .tclWindow.baseFrame.subFrame.tcl_pre_label_$index -row 0 -column 0 -padx 5 -pady 5 -sticky w
		##
		ttk::entry .tclWindow.baseFrame.subFrame.tcl_pre_$index -textvar cOptions($index-tcl_script-pre) -background white -width 50
		##
		grid .tclWindow.baseFrame.subFrame.tcl_pre_$index -row 0 -column 1 -padx 5 -pady 5 -sticky w
		##
		button .tclWindow.baseFrame.subFrame.tcl_pre_$index\_button -text "Select" -command "vXplore::tk::configuration::tcl_OnSelect %W $index pre"
		##
		grid .tclWindow.baseFrame.subFrame.tcl_pre_$index\_button -row 0 -column 2 -padx 5 -pady 5 -sticky w
		##
		label .tclWindow.baseFrame.subFrame.tcl_post_label_$index -text "Tcl.post"
		##
		grid .tclWindow.baseFrame.subFrame.tcl_post_label_$index -row 1 -column 0 -padx 5 -pady 5 -sticky w
		##
		ttk::entry .tclWindow.baseFrame.subFrame.tcl_post_$index -textvar cOptions($index-tcl_script-post) -background white -width 50
		##
		grid .tclWindow.baseFrame.subFrame.tcl_post_$index -row 1 -column 1 -padx 5 -pady 5 -sticky w
		##
		button .tclWindow.baseFrame.subFrame.tcl_post_$index\_button -text "Select" -command "vXplore::tk::configuration::tcl_OnSelect %W $index post"
		##
		grid .tclWindow.baseFrame.subFrame.tcl_post_$index\_button -row 1 -column 2 -padx 5 -pady 5 -sticky w
		
		## Create a button to run the program
		ttk::button .tclWindow.baseFrame.ok_button -text "OK" -command {destroy .tclWindow}
		## Pack the run button on the bottom right next to the close button
		pack .tclWindow.baseFrame.ok_button -side bottom
	}
	
	return
}

# #########################################################
# 
# #########################################################
proc vXplore::tk::configuration::build_configuration_dictionary {} {
	## Get the global variable for the configuration options
	global cOptions
	## Get the global variable for the configuration dictionary
	global configDict
	
	## Create the dictionary to store the configuration options
	set cDict [dict create]
	
	## Loop through each array key in the global Configuration options array
	foreach optionKey [lsort [array names cOptions]] {
		## Split the key by the separator character
		set optionKeyList [split $optionKey "-"]
		## Shift off the first value, the index
		set index [lshift optionKeyList]
		
		## Check if the index dictionary exists, create if not
		if {![dict exists $cDict index $index]} {
			dict set $cDict index $index
		}
		
		## Check if the option key is for a directive
		if {[regexp {directives} $optionKey]} {
			## Set the key name from the option list
			set keyName [lshift optionKeyList]
			## Set the directive name from the option list
			set directiveName [lshift optionKeyList]
			
			## Check if the directive was requested
			if {$cOptions($optionKey)} {
				## Check if the directive dictionary exists
				if {![dict exists $cDict index $index directives]} {
					## Set the initial directive as an list of lists
					dict set cDict index $index $keyName [list [list name $directiveName]]
				} else {
					## Get the directive list from the dictionary
					set directiveList [dict get $cDict index $index directives]
					## Append the selected directive to the list
					lappend directiveList [list name $directiveName]
					## Update the directive list in the configuration dictionary
					dict set cDict index $index $keyName $directiveList
				}
			}
		} elseif {[regexp {tcl_script} $optionKey]} {
			## Set the key name from the option list
			set keyName [lshift optionKeyList]
			## Set the Tcl key name from the option list
			set tclKeyName [lshift optionKeyList]
			
			## Set the tcl key value pair
			dict set cDict index $index tcl $tclKeyName $cOptions($optionKey)		
		} else {	
			## Set the key name from the option list
			set keyName [lshift optionKeyList]
			## Set the value for the specified key name
			dict set cDict index $index $keyName $cOptions($optionKey)
		}
	}

	## Set the configuration dictionary to the configuration options array
	set configDict $cDict
	
	return
}

# #########################################################
# 
# #########################################################
proc vXplore::tk::configuration::save_configuration {windowFrame} {
	## Get the global variable for the configuration options
	global configDict
	## Get the global variable for the vXplore options
	global opts
	
	## Set the supported file types
	set fileTypeList {
		{"YAML Ain't Markup Language" {.yml .yaml}}
	}
	
	## Create the configuration dictionary 
	vXplore::tk::configuration::build_configuration_dictionary
	
	## Write the YAML stream to string from the dictionary
	set fileData [vXplore::tk::configuration::write_yaml $configDict]
	
	## Save the configuration data to the file
	set opts(-configuration) [vXplore::tk::configuration::save_as $windowFrame $fileData $fileTypeList]
}

# #########################################################
# 
# #########################################################
proc vXplore::tk::configuration::save_as {windowFrame fData fileTypeList} {	
	## Get the save file path name
	set fileName [tk_getSaveFile -title "Save As" -filetypes $fileTypeList -parent $windowFrame]
	
	## Check if the file name was created, the user didn't click cancel
	if {$fileName != ""} {
		## Open the file channel
		set fileHandleError [catch {set fileHandle [open $fileName w+]}]
		## Write the data to the file channel
		set fileWriteError [catch {puts $fileHandle $fData}]
		## Close the file channel
		set fileCloseError [catch {close $fileHandle}]
   
		## Check that the file was written properly, error if issue
		if { $fileHandleError || $fileWriteError || $fileCloseError || ![file exists $fileName] || ![file isfile $fileName] || ![file readable $fileName] } {
			tk_messageBox -parent $windowFrame -icon error -message "An error occurred while saving to \"$fileName\""
		} else {
			tk_messageBox -parent $windowFrame -icon info -message "Save successful"
		}
	}
	
	## Return the file name
	return $fileName
}

# #########################################################
# 
# #########################################################
proc vXplore::tk::configuration::write_yaml {dict} {
	## Initialize YAML stream string variable
	set yamlStreamString ""
		
	## Loop through each key of the dictionary (index)
	foreach keyName [dict keys $dict] {
		set yamlStreamString "$keyName\:\n"
		
		foreach indexKey [dict keys [dict get $dict $keyName]] {
			append yamlStreamString "    $indexKey\:\n"
			
			foreach stageKey [dict keys [dict get $dict $keyName $indexKey]] {
				switch $stageKey {
					"directives" {
						append yamlStreamString "        $stageKey\:\n"
						
						foreach directiveList [dict get $dict $keyName $indexKey $stageKey] {
							append yamlStreamString "            - [lindex $directiveList 0]\: [lindex $directiveList 1]\n"
						}
					}
					"tcl" {
						append yamlStreamString "        $stageKey\:\n"
						
						foreach tclKey [dict keys [dict get $dict $keyName $indexKey $stageKey]] {
							## Check if value exists for Tcl key
							if {[llength [dict get $dict $keyName $indexKey $stageKey $tclKey]]!=0} {
								append yamlStreamString "            $tclKey\: [dict get $dict $keyName $indexKey $stageKey $tclKey]\n"
							}
						}						
					}
					"index" {
						continue
					}
					default {
						append yamlStreamString "        $stageKey\: [dict get $dict $keyName $indexKey $stageKey]\n"
					}
				}
			}
		}
	}
	
	return $yamlStreamString
}

# #########################################################
# 
# #########################################################
proc vXplore::tk::configuration::open_yaml_file_onSelect {windowFrame varName} {
	## Get the variable from the passed variable reference
	upvar $varName fileName
	
	## Get the global variable for the configuration options
	global configDict
	##
	vXplore::tk::open_configuration_file_OnSelect $windowFrame fileName
	
	## Check if the file name variable exists
	if {[llength $fileName]!=0} {
		## Load the yaml file into memory
		vXplore::tk::configuration::load_yaml_file $fileName
	}
	
	## Reload the Configuration window based on the updating of the configuration options array
	vXplore::tk::configuration::reload_configuration_window
}

# #########################################################
# 
# #########################################################
proc vXplore::tk::configuration::load_yaml_file {fileName} {
	## Get the global variable for the configuration options
	global configDict

	## Read the YAML File into Tcl Dictionary
	set configDict [::yaml::yaml2dict -file $fileName]
	##
	vXplore::tk::configuration::load_configuration_options_array $configDict
	##
	
}

# #########################################################
# 
# #########################################################
proc vXplore::tk::configuration::load_configuration_options_array {dict} {
	## Get the global variable for the configuration options
	global cOptions
	## Unset all the array values of the configuration options
	array unset cOptions
	
	## Loop through each key of the dictionary (index)
	foreach keyName [dict keys $dict] {
		##
		foreach indexKey [dict keys [dict get $dict $keyName]] {
			##
			foreach stageKey [dict keys [dict get $dict $keyName $indexKey]] {
				##
				switch $stageKey {
					"directives" {
						##
						foreach directiveList [dict get $dict $keyName $indexKey $stageKey] {
							set cOptions($indexKey\-directives-[lindex $directiveList 1]) 1
						}
					}
					"tcl" {
						## Check if the Tcl dictionary exists
						if {[dict exists $dict $keyName $indexKey $stageKey]} {
							## Loop through each key for the Tcl dictionary
							foreach tclKey [dict keys [dict get $dict $keyName $indexKey $stageKey]] {
								set cOptions($indexKey\-tcl_script-$tclKey) [dict get $dict $keyName $indexKey $stageKey $tclKey]
							}
						}
					}
					default {
						set cOptions($indexKey\-$stageKey) [dict get $dict $keyName $indexKey $stageKey]
					}	
				}
			}
		}
	}
	
	return
}

# #########################################################
# 
# #########################################################
proc vXplore::tk::configuration::reload_configuration_window {} {
	## Destroy the Configuration window 
	destroy .configuration
	## Destroy the Configuration Menu bar
	destroy .configurationMenuBar
	## Create the Configuration Window
	vXplore::tk::create_configuration_window_onButton
}

# #########################################################
# 
# #########################################################
proc vXplore::tk::create_configuration_window_onButton {} {
	## Get the global variable for the configuration options
	global configDict 
	## Get the global variable for the configuration options
	global cOptions
	## Get the global variable for the configuration index
	global index
	## Get the global variable for the vXplore options
	global opts
	
	## Check if configuration file has been set
	if {$opts(-configuration) ne ""} {
		## Check if the path to the file exists
		if {[file exists $opts(-configuration)] && [file isfile $opts(-configuration)] && [file readable $opts(-configuration)]} {
			## Load configuration file into memory
			vXplore::tk::configuration::load_yaml_file $opts(-configuration)	
		} else {
			## Reset the configuration dictionary
			set configDict [dict create]
			## Reset the configuration options array
			unset -nocomplain cOptions
		}		
	} else {
		## Reset the configuration dictionary
		set configDict [dict create]
		## Reset the configuration options array
		unset -nocomplain cOptions
	}
	
	## Reset the configuration index to 0
	set index 0
	## Create the top-level configuration window
	tk::toplevel .configuration
	## Set the configuration window as top-most window
	wm attributes .configuration -topmost 1
	## Create the menu bar for the configuration window
	menu .configurationMenuBar
	## Configure the menu bar for the configuration window
	.configuration configure -menu .configurationMenuBar

	## Add the file menu to the configuration menu
	menu .configurationMenuBar.file -tearoff 0
	## Add the File header to the configuration menu
	.configurationMenuBar add cascade -menu .configurationMenuBar.file -label "File" -underline 0
	## Add the Open option to the File Menu
	.configurationMenuBar.file add command -label "Open" -command {vXplore::tk::configuration::open_yaml_file_onSelect .configuration opts(-configuration)}
	## Add the Save As option to the File Menu
	.configurationMenuBar.file add command -label "Save As..." -command {vXplore::tk::configuration::save_configuration .configuration.baseFrame}
	## Add the Exit option to the File Menu
	.configurationMenuBar.file add command -label "Exit" -command {destroy .configuration; destroy .configurationMenuBar}
	
	## Add the file stage to the configuration menu
	menu .configurationMenuBar.stage -tearoff 0
	## Add the Stage header to the configuration menu
	.configurationMenuBar add cascade -menu .configurationMenuBar.stage -label Stage -underline 0
	## Add the Add Stage option to the Stage Menu
	.configurationMenuBar.stage add command -label "Add Stage" -command {vXplore::tk::configuration::add_configuration_index_widget .configuration.baseFrame.subFrame}

	# # Set the initial frame
	frame .configuration.baseFrame
	# # Expands the base frame both vertically and horizontally
	pack .configuration.baseFrame -fill both -expand 1
	# # Create a child frame within the base frame
	frame .configuration.baseFrame.subFrame -relief raised -borderwidth 1
	# # Expands the base frame both vertically and horizontally
	pack .configuration.baseFrame.subFrame -fill both -expand 1

	label .configuration.baseFrame.subFrame.index_label -text "Index"
	grid .configuration.baseFrame.subFrame.index_label -row 0 -column 0 -padx 5 -pady 5

	label .configuration.baseFrame.subFrame.stage_label -text "Stage Name"
	grid .configuration.baseFrame.subFrame.stage_label -row 0 -column 1 -padx 5 -pady 5

	label .configuration.baseFrame.subFrame.directives_label -text "Directives"
	grid .configuration.baseFrame.subFrame.directives_label -row 0 -column 2 -padx 5 -pady 5

	label .configuration.baseFrame.subFrame.args_label -text "Arguments"
	grid .configuration.baseFrame.subFrame.args_label -row 0 -column 3 -padx 5 -pady 5

	label .configuration.baseFrame.subFrame.tcl_label -text "Tcl"
	grid .configuration.baseFrame.subFrame.tcl_label -row 0 -column 4 -padx 5 -pady 5

	## Check if the configuration dictionary is set, reload with populated variable	
	if {$configDict ne ""} {
		## Loop through each index key in the configuration dictionary
		for {set i 0} {$i < [llength [dict keys [dict get $configDict index]]]} {incr i} {
			vXplore::tk::configuration::add_configuration_index_widget .configuration.baseFrame.subFrame
		}
	} else {
		## Add initial configuration index widget to the configuration window
		vXplore::tk::configuration::add_configuration_index_widget .configuration.baseFrame.subFrame
	}

	## Create a button to save the configuration into a YAML file
	ttk::button .configuration.baseFrame.save_button -text "Save As ..." -command {vXplore::tk::configuration::save_configuration .configuration.baseFrame; destroy .configuration; destroy .configurationMenuBar}
	##
	## Pack the Save button on the bottom left
	pack .configuration.baseFrame.save_button -padx 5 -pady 5 -side left
	## Create a button to close the program
	ttk::button .configuration.baseFrame.cancel_button -text "Close" -command {destroy .configuration; destroy .configurationMenuBar}
	## Pack the Close button on the bottom right
	pack .configuration.baseFrame.cancel_button -padx 5 -pady 5 -side right

	## Update the window to ensure the winfo is correct
	update

	## Set the Width of the Window
	set width [winfo width .configuration]
	## Set the height of the window
	set height [winfo height .configuration]

	## Set the X & Y to the center of the screen
	set x [expr { ( [winfo vrootwidth  .] - $width  ) / 2 }]
	set y [expr { ( [winfo vrootheight .] - $height ) / 2 }]

	## Set the size and location of the window
	wm geometry .configuration +${x}+${y}
	## Set the title of the window
	wm title .configuration "Create Configuration"
}

# #########################################################
# 
# #########################################################
## Flatten the list
set args [concat {*}$argv]
	
## Set Default option values
array set opts {-checkpoint "" -configuration "" -log "vXplore.log" -memory 10000 -out_dir "./" -queue "medium" -run_all 0 -step_count 2 -verbose 1 -wait 5}

## Parse arguments from option command line
while {[string match -* [lindex $args 0]]} {
	switch -regexp -- [lindex $args 0] {
		{-ch(e(c(k(p(o(i(n(t)?)?)?)?)?)?)?)?$}             { set opts(-checkpoint)    [lshift args 1]}
		{-co(n(f(i(g(u(r(a(t(i(o(n)?)?)?)?)?)?)?)?)?)?)?$} { set opts(-configuration) [lshift args 1]}
		{-l(o(g)?)?$}                                      { set opts(-log)           [lshift args 1]}
		{-m(e(m(o(r(y)?)?)?)?)?$}                          { set opts(-memory)        [lshift args 1]}
		{-o(u(t(_(d(i(r)?)?)?)?)?)?$}                      { set opts(-out_dir)       [lshift args 1]}
		{-q(u(e(u(e)?)?)?)?$}                              { set opts(-queue)         [lshift args 1]}
		{-r(u(n(_(a(l(l)?)?)?)?)?)?$}                      { set opts(-run_all)       1}
		{-s(t(e(p(_(c(o(u(n(t)?)?)?)?)?)?)?)?)?$}          { set opts(-step_count)    [lshift args 1]}
		{-v(e(r(b(o(s(e)?)?)?)?)?)?$}    	               { set opts(-verbose)       1}
		{-w(a(i(t)?)?)?$}                                  { set opts(-wait)          [lshift args 1]}
		default {
			return -code error "ERROR: \[vXplore_Tk\] Unknown option '[lindex $args 0]'."
		}
	}
	lshift args
}

# # Set the index to the start (0)
set index 0
# # Initialize the configuration array from the configuration window
array set cOptions {}
# # Initialize the configuration dictionary variable
set configDict ""

# # Set the Width of the Window (this will be the minimum size)
set width 565
# # Set the height of the window (this will be the minimum size)
set height 350

# # Normalize the output directory file path
set opts(-out_dir) [file normalize $opts(-out_dir)]

# # Set the initial frame
frame .baseFrame
# # Expands the base frame both vertically and horizontally
pack .baseFrame -fill both -expand 1
# # Create a child frame within the base frame
frame .baseFrame.subFrame -relief raised -borderwidth 1
# # Expands the base frame both vertically and horizontally
pack .baseFrame.subFrame -fill both -expand 1

# #
set folderImage [image create photo -format png -file "/wrk/hdstaff/joshg/tools/scripts/tcl/vXplore_Tk/image/open-file-icon.png"]
set settingsImage [image create photo -format png -file "/wrk/hdstaff/joshg/tools/scripts/tcl/vXplore_Tk/image/settings-icon.png"]

# # Create a child frame within the base frame for Options
frame .baseFrame.subFrame.fileFrame -relief flat -borderwidth 1
# # Put the Options panel in R3C0
grid .baseFrame.subFrame.fileFrame -row 0 -columnspan 2 -sticky new -padx 5 -pady 5

# # Create a Label for the checkpoint path
label .baseFrame.subFrame.fileFrame.checkpointLabel -text "Checkpoint"
# # Place the checkpoint label in R1C0
grid .baseFrame.subFrame.fileFrame.checkpointLabel -row 0 -column 0 -padx 5 -pady 5 -sticky w
# # Create an Entry field for the Checkpoint path
ttk::entry .baseFrame.subFrame.fileFrame.checkpointEntry -textvar opts(-checkpoint) -background white -width 47
# # Put the Checkpoint Entry on the on R0C0
grid .baseFrame.subFrame.fileFrame.checkpointEntry -row 0 -column 1 -padx 5 -pady 5
# # Create the Button to open the Checkpoint path file dialog
button .baseFrame.subFrame.fileFrame.openCheckpointButton -image $folderImage -command "vXplore::tk::open_checkpoint_OnSelect .baseFrame.subFrame opts(-checkpoint)"
# # Put the Checkpoint Button on the on R1C1
grid .baseFrame.subFrame.fileFrame.openCheckpointButton -row 0 -column 2 -padx 5 -pady 5

# # Create a Label for the Configuration path
label .baseFrame.subFrame.fileFrame.configLabel -text "Configuration"
# # Place the configuration label in R1C0
grid .baseFrame.subFrame.fileFrame.configLabel -row 1 -column 0 -padx 5 -pady 5 -sticky w
# # Create an Entry field for the Configuration path
ttk::entry .baseFrame.subFrame.fileFrame.configEntry -textvar opts(-configuration) -background white -width 47
# # Put the Configuration Entry on the on R2C0
grid .baseFrame.subFrame.fileFrame.configEntry -row 1 -column 1 -padx 5 -pady 5
# # Create the Button to open the configuration path file dialog
button .baseFrame.subFrame.fileFrame.openConfigButton -image $folderImage -command "vXplore::tk::open_configuration_file_OnSelect .baseFrame.subFrame opts(-configuration)"
# # Put the Configuration Button on the on R2C1
grid .baseFrame.subFrame.fileFrame.openConfigButton -row 1 -column 2 -padx 5 -pady 5

button .baseFrame.subFrame.fileFrame.editConfigurationButton -image $settingsImage -command "vXplore::tk::create_configuration_window_onButton"
# # Put the Configuration Button on the on R2C1
grid .baseFrame.subFrame.fileFrame.editConfigurationButton -row 1 -column 3 -padx 5 -pady 5

# # Create a child frame within the base frame for Options
labelframe .baseFrame.subFrame.optionsFrame -relief sunken -borderwidth 1 -width 200 -height 200 -text "Options"
# # Put the Options panel in R3C0
grid .baseFrame.subFrame.optionsFrame -row 3 -column 0 -sticky new -padx 5 -pady 5

# # 
label .baseFrame.subFrame.optionsFrame.outputDirLabel -text "Output Directory"
grid .baseFrame.subFrame.optionsFrame.outputDirLabel -row 0 -column 0 -padx 5 -pady 5 -sticky w
entry .baseFrame.subFrame.optionsFrame.outputDirEntry -textvar opts(-out_dir) -validate all -vcmd "vXplore::tk::validateDirectory_onKey %W %S vXplore" -background white -width 11
grid .baseFrame.subFrame.optionsFrame.outputDirEntry -row 0 -column 1 -padx 5 -pady 5 -sticky ew

## Validate the Initial Output Directory Condition
vXplore::tk::validateDirectory_onKey .baseFrame.subFrame.optionsFrame.outputDirEntry "" vXplore

##
label .baseFrame.subFrame.optionsFrame.logFileLabel -text "Log File Name"
grid .baseFrame.subFrame.optionsFrame.logFileLabel -row 1 -column 0 -padx 5 -pady 5 -sticky w
entry .baseFrame.subFrame.optionsFrame.logFileEntry -textvar opts(-log) -background white -width 11
grid .baseFrame.subFrame.optionsFrame.logFileEntry -row 1 -column 1 -padx 5 -pady 5 -sticky ew

ttk::separator .baseFrame.subFrame.optionsFrame.separator -orient horizontal
grid .baseFrame.subFrame.optionsFrame.separator -row 2 -columnspan 2 -sticky ew -padx 5 -pady 5

##
label .baseFrame.subFrame.optionsFrame.stepCountInfoLabel -wraplength 300 -text "The step count option sets the numbers of runs to execute on the next Implementation stage.  If the Run All option is set, this value is ignored."
grid .baseFrame.subFrame.optionsFrame.stepCountInfoLabel -row 3 -column 0 -padx 5 -pady 5 -columnspan 2

##
label .baseFrame.subFrame.optionsFrame.stepCountLabel -text "Step Count"
grid .baseFrame.subFrame.optionsFrame.stepCountLabel -row 4 -column 0 -padx 5 -pady 5 -sticky w
ttk::entry .baseFrame.subFrame.optionsFrame.stepCountEntry -textvar opts(-step_count) -background white -width 11
grid .baseFrame.subFrame.optionsFrame.stepCountEntry -row 4 -column 1 -padx 5 -pady 5 -sticky ew

checkbutton .baseFrame.subFrame.optionsFrame.runAllCheckButton -text "Run All" -variable opts(-run_all) -command "vXplore::tk::changeState_onSelect .baseFrame.subFrame.optionsFrame.stepCountEntry"
grid .baseFrame.subFrame.optionsFrame.runAllCheckButton -row 5 -column 0 -padx 5 -pady 5 -columnspan 2

## Create a child frame within the baseframe
labelframe .baseFrame.subFrame.lsfFrame -relief sunken -borderwidth 1 -width 200 -height 200 -text "LSF Options"
grid .baseFrame.subFrame.lsfFrame -row 3 -column 1 -sticky new -padx 5 -pady 5

label .baseFrame.subFrame.lsfFrame.queueLabel -text "Queue"
grid .baseFrame.subFrame.lsfFrame.queueLabel -row 0 -column 0 -padx 5 -pady 5
ttk::combobox .baseFrame.subFrame.lsfFrame.queueComboBox -textvariable opts(-queue) -values [list quick short medium long bigmem] -width 10
grid .baseFrame.subFrame.lsfFrame.queueComboBox -row 0 -column 1 -padx 5 -pady 5

label .baseFrame.subFrame.lsfFrame.memoryLabel -text "Memory Req"
grid .baseFrame.subFrame.lsfFrame.memoryLabel -row 1 -column 0 -padx 5 -pady 5
entry .baseFrame.subFrame.lsfFrame.memoryEntry -validate key -vcmd {expr {[string len %P] <= 6} && [string is double %P]} -textvar opts(-memory) -background white -width 11
grid .baseFrame.subFrame.lsfFrame.memoryEntry -row 1 -column 1 -padx 5 -pady 5

label .baseFrame.subFrame.lsfFrame.waitLabel -text "Wait Time"
grid .baseFrame.subFrame.lsfFrame.waitLabel -row 2 -column 0 -padx 5 -pady 5
entry .baseFrame.subFrame.lsfFrame.waitEntry -textvar opts(-wait) -background white -width 11
grid .baseFrame.subFrame.lsfFrame.waitEntry -row 2 -column 1 -padx 5 -pady 5

ttk::separator .baseFrame.subFrame.lsfFrame.separator -orient horizontal
grid .baseFrame.subFrame.lsfFrame.separator -columnspan 2 -sticky ew -padx 5 -pady 5

checkbutton .baseFrame.subFrame.lsfFrame.verboseCheckButton -text Verbose -variable opts(-verbose)
grid .baseFrame.subFrame.lsfFrame.verboseCheckButton -row 4 -column 0 -padx 5 -pady 5 -columnspan 2

# # Create a button to close the program
ttk::button .baseFrame.closeButton -text "Close" -command {exit}
# # Pack the Close button on the bottom right
pack .baseFrame.closeButton -padx 5 -pady 5 -side right
# # Create a button to run the program
ttk::button .baseFrame.okButton -text "Run" -command {set commandLine [vXplore::tk::validate_and_build_command_line -checkpoint $opts(-checkpoint) -configuration $opts(-configuration) -out_dir $opts(-out_dir) -log $opts(-log) -step_count $opts(-step_count) -queue $opts(-queue) -memory $opts(-memory) -wait $opts(-wait) -run_all $opts(-run_all) -verbose $opts(-verbose)]; if {[llength $commandLine]!=0} {puts $commandLine; exit}}
# # Pack the run button on the bottom right next to the close button
pack .baseFrame.okButton -side right

# # Set the X & Y to the center of the screen
set x [expr { ( [winfo vrootwidth  .] - $width  ) / 2 }]
set y [expr { ( [winfo vrootheight .] - $height ) / 2 }]

# # Set the Title of the window
wm title . "vXplore" 
# # Set the size and location of the window
wm geometry . ${width}x${height}+${x}+${y}
# # Set the minimum size of the window
wm minsize . $width $height

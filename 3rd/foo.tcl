package require Tk

# Create the namespace
namespace eval vXplore::tk {}

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
proc vXplore::tk::config_OnSelect {label varname} {
	upvar $varname var
	## Set the supported file types
	set fileTypeList {
		{"YAML Ain't Markup Language" {.yml .yaml}}
	}
	
	## Check the variable to get the current directory
	if {[regexp {(.*)/.*$} $var matchString dirName]} {
		## Get the file name from the dialog popup
		set fileName [tk_getOpenFile -initialdir $dirName -filetypes $fileTypeList -parent .]
	} else {
		## Get the file name from the dialog popup
		set fileName [tk_getOpenFile -initialdir [pwd] -filetypes $fileTypeList -parent .]	
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
proc vXplore::tk::checkpoint_OnSelect {label varname} {
	upvar $varname var
	## Set the supported file types
	set fileTypeList {
		{"Vivado Design Checkpoint" {.dcp}}
	}
	
	## Check the variable to get the current directory
	if {[regexp {(.*)/.*$} $var matchString dirName]} {
		## Get the file name from the dialog popup
		set fileName [tk_getOpenFile -initialdir $dirName -filetypes $fileTypeList -parent .]
	} else {
		## Get the file name from the dialog popup
		set fileName [tk_getOpenFile -initialdir [pwd] -filetypes $fileTypeList -parent .]	
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
proc vXplore::tk::validateDirectory_onKey {entry text} {
	set dirName "[$entry get]$text"
	
	if {[file exists $dirName]} {
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
            {-ch(e(c(k(p(o(i(n(t)?)?)?)?)?)?)?)?$}             { set opts(-checkpoint)    [lshift args 1]}
			{-co(n(f(i(g(u(r(a(t(i(o(n)?)?)?)?)?)?)?)?)?)?)?$} { set opts(-configuration) [lshift args 1]}
			{-l(o(g)?)?$}                                      { set opts(-log)           [lshift args 1]}
			{-m(e(m(o(r(y)?)?)?)?)?$}                          { set opts(-memory)        [lshift args 1]}
			{-o(u(t(_(d(i(r)?)?)?)?)?)?$}                      { set opts(-out_dir)       [lshift args 1]}
			{-q(u(e(u(e)?)?)?)?$}                              { set opts(-queue)         [lshift args 1]}
			{-r(u(n(_(a(l(l)?)?)?)?)?)?$}                      { set opts(-run_all)       [lshift args 1]}
			{-s(t(e(p(_(c(o(u(n(t)?)?)?)?)?)?)?)?)?$}          { set opts(-step_count)    [lshift args 1]}
			{-v(e(r(b(o(s(e)?)?)?)?)?)?$}    	               { set opts(-verbose)       [lshift args 1]}
			{-w(a(i(t)?)?)?$}                                  { set opts(-wait)          [lshift args 1]}
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
		return
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
		tk_messageBox -message "Please enter a Step Count for the numbers of runs to execute on the next Implementation stage" -type ok -icon error
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
## Set Default option values
array set opts {-checkpoint "" -configuration "" -log "vXplore.log" -memory 10000 -out_dir "[pwd]/vXplore" -queue "medium" -run_all 0 -step_count 2 -verbose 1 -wait 60}

## Parse arguments from option command line
while {[string match -* [lindex $argv 0]]} {
	switch -regexp -- [lindex $argv 0] {
		{-ch(e(c(k(p(o(i(n(t)?)?)?)?)?)?)?)?$}             { set opts(-checkpoint)    [lshift argv 1]}
		{-co(n(f(i(g(u(r(a(t(i(o(n)?)?)?)?)?)?)?)?)?)?)?$} { set opts(-configuration) [lshift argv 1]}
		{-l(o(g)?)?$}                                      { set opts(-log)           [lshift argv 1]}
		{-m(e(m(o(r(y)?)?)?)?)?$}                          { set opts(-memory)        [lshift argv 1]}
		{-o(u(t(_(d(i(r)?)?)?)?)?)?$}                      { set opts(-out_dir)       [lshift argv 1]}
		{-q(u(e(u(e)?)?)?)?$}                              { set opts(-queue)         [lshift argv 1]}
		{-r(u(n(_(a(l(l)?)?)?)?)?)?$}                      { set opts(-run_all)       1}
		{-s(t(e(p(_(c(o(u(n(t)?)?)?)?)?)?)?)?)?$}          { set opts(-step_count)    [lshift argv 1]}
		{-v(e(r(b(o(s(e)?)?)?)?)?)?$}    	               { set opts(-verbose)       1}
		{-w(a(i(t)?)?)?$}                                  { set opts(-wait)          [lshift argv 1]}
		default {
			return -code error "ERROR: \[vXplore\] Unknown option '[lindex $argv 0]', please type 'vXplore -help' for usage info."
		}
	}
	lshift argv
}

# # Set the initial frame
frame .baseFrame
# # Expands the base frame both vertically and horozontially
pack .baseFrame -fill both -expand 1
# # Create a child frame within the base frame
frame .baseFrame.pnl -relief raised -borderwidth 1
# # Expands the base frame both vertically and horozontially
pack .baseFrame.pnl -fill both -expand 1

# # Create an Entry field for the Checkpoint path
ttk::entry .baseFrame.pnl.checkpoint_e -textvar opts(-checkpoint) -background white -width 40
# # Put the Checkpoint Entry on the on R0C0
grid .baseFrame.pnl.checkpoint_e -row 1 -column 0 -padx 5 -pady 5
# # Create the Button to open the Checkpoint path file dialog
button .baseFrame.pnl.checkpoint_b -text "Select Checkpoint" -command "vXplore::tk::checkpoint_OnSelect .baseFrame.pnl.checkpoint_e opts(-checkpoint)"
# # Put the Checkpoint Button on the on R1C1
grid .baseFrame.pnl.checkpoint_b -row 1 -column 1 -padx 5 -pady 5

# # Create an Entry field for the Configuration path
entry .baseFrame.pnl.config_e -textvar opts(-configuration) -background white -width 40
# # Put the Configuration Entry on the on R2C0
grid .baseFrame.pnl.config_e -row 2 -column 0 -padx 5 -pady 5
# # Create the Button to open the configuration path file dialog
button .baseFrame.pnl.config_b -text "Select Configuration" -command "vXplore::tk::config_OnSelect .baseFrame.pnl.config_e opts(-configuration)"
# # Put the Configuration Button on the on R2C1
grid .baseFrame.pnl.config_b -row 2 -column 1 -padx 5 -pady 5

# # Create a child frame within the base frame
labelframe .baseFrame.pnl.vXplore_pnl -relief sunken -borderwidth 1 -width 200 -height 200 -text "Options"
grid .baseFrame.pnl.vXplore_pnl -row 3 -column 0 -sticky new -padx 5 -pady 5

##
label .baseFrame.pnl.vXplore_pnl.loutdir -text "Output Directory"
grid .baseFrame.pnl.vXplore_pnl.loutdir -row 0 -column 0 -padx 5 -pady 5 -sticky w
entry .baseFrame.pnl.vXplore_pnl.eoutdir -textvar opts(-out_dir) -validate all -vcmd "vXplore::tk::validateDirectory_onKey %W %S" -background white -width 11
grid .baseFrame.pnl.vXplore_pnl.eoutdir -row 0 -column 1 -padx 5 -pady 5 -sticky ew

## Validate the Initial Output Directory Condition
vXplore::tk::validateDirectory_onKey .baseFrame.pnl.vXplore_pnl.eoutdir ""

##
label .baseFrame.pnl.vXplore_pnl.llog -text "Log File Name"
grid .baseFrame.pnl.vXplore_pnl.llog -row 1 -column 0 -padx 5 -pady 5 -sticky w
entry .baseFrame.pnl.vXplore_pnl.elog -textvar opts(-log) -background white -width 11
grid .baseFrame.pnl.vXplore_pnl.elog -row 1 -column 1 -padx 5 -pady 5 -sticky ew

ttk::separator .baseFrame.pnl.vXplore_pnl.s -orient horizontal
grid .baseFrame.pnl.vXplore_pnl.s -row 2 -columnspan 2 -sticky ew -padx 5 -pady 5

##
label .baseFrame.pnl.vXplore_pnl.lsteptext -wraplength 300 -text "The step count option sets the numbers of runs to execute on the next Implementation stage.  If the Run All option is set, this value is ignored."
grid .baseFrame.pnl.vXplore_pnl.lsteptext -row 3 -column 0 -padx 5 -pady 5 -columnspan 2

##
label .baseFrame.pnl.vXplore_pnl.lstep -text "Step Count"
grid .baseFrame.pnl.vXplore_pnl.lstep -row 4 -column 0 -padx 5 -pady 5 -sticky w
ttk::entry .baseFrame.pnl.vXplore_pnl.estep -textvar opts(-step_count) -background white -width 11
grid .baseFrame.pnl.vXplore_pnl.estep -row 4 -column 1 -padx 5 -pady 5 -sticky ew

checkbutton .baseFrame.pnl.vXplore_pnl.crunall -text "Run All" -variable opts(-run_all) -command "vXplore::tk::changeState_onSelect .baseFrame.pnl.vXplore_pnl.estep"
grid .baseFrame.pnl.vXplore_pnl.crunall -row 5 -column 0 -padx 5 -pady 5 -columnspan 2

## Create a child frame within the baseframe
labelframe .baseFrame.pnl.lsf_pnl -relief sunken -borderwidth 1 -width 200 -height 200 -text "LSF Options"
grid .baseFrame.pnl.lsf_pnl -row 3 -column 1 -sticky new -padx 5 -pady 5

label .baseFrame.pnl.lsf_pnl.lqueue -text "Queue"
grid .baseFrame.pnl.lsf_pnl.lqueue -row 0 -column 0 -padx 5 -pady 5
ttk::combobox .baseFrame.pnl.lsf_pnl.c -textvariable opts(-queue) -values [list quick short medium long bigmem] -width 10
grid .baseFrame.pnl.lsf_pnl.c -row 0 -column 1 -padx 5 -pady 5

label .baseFrame.pnl.lsf_pnl.lmem -text "Memory Req"
grid .baseFrame.pnl.lsf_pnl.lmem -row 1 -column 0 -padx 5 -pady 5
entry .baseFrame.pnl.lsf_pnl.emem -validate key -vcmd {expr {[string len %P] <= 6} && [string is double %P]} -textvar opts(-memory) -background white -width 11
grid .baseFrame.pnl.lsf_pnl.emem -row 1 -column 1 -padx 5 -pady 5

label .baseFrame.pnl.lsf_pnl.lwait -text "Wait Time"
grid .baseFrame.pnl.lsf_pnl.lwait -row 2 -column 0 -padx 5 -pady 5
entry .baseFrame.pnl.lsf_pnl.ewait -textvar opts(-wait) -background white -width 11
grid .baseFrame.pnl.lsf_pnl.ewait -row 2 -column 1 -padx 5 -pady 5

ttk::separator .baseFrame.pnl.lsf_pnl.s -orient horizontal
grid .baseFrame.pnl.lsf_pnl.s -columnspan 2 -sticky ew -padx 5 -pady 5

checkbutton .baseFrame.pnl.lsf_pnl.cverbose -text Verbose -variable opts(-verbose)
grid .baseFrame.pnl.lsf_pnl.cverbose -row 4 -column 0 -padx 5 -pady 5 -columnspan 2


# # Create a button to close the program
ttk::button .baseFrame.cb -text "Close" -command {exit}
# # Pack the Close button on the bottom right
pack .baseFrame.cb -padx 5 -pady 5 -side right
# # Create a button to run the program
ttk::button .baseFrame.ok -text "Run" -command {set commandLine [vXplore::tk::validate_and_build_command_line -checkpoint $opts(-checkpoint) -configuration $opts(-configuration) -out_dir $opts(-out_dir) -log $opts(-log) -step_count $estep -queue $opts(-queue) -memory $opts(-memory) -wait $opts(-wait) -run_all $opts(-run_all) -verbose $opts(-verbose)]; if {[llength $commandLine]!=0} {puts $commandLine; exit}}
# # Pack the run button on the bottom right next to the close button
pack .baseFrame.ok -side right

# # Set the Width of the Window (this will be the minimum size)
set width 550
# # Set the height of the window (this will be the minimum size)
set height 350

# # Set the X & Y to the center of the screen
set x [expr { ( [winfo vrootwidth  .] - $width  ) / 2 }]
set y [expr { ( [winfo vrootheight .] - $height ) / 2 }]

# # Set the Title of the window
wm title . "vXplore" 
# # Set the size and location of the window
wm geometry . ${width}x${height}+${x}+${y}
# # Set the minimum size of the window
wm minsize . $width $height

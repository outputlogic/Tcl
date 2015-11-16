## Name: README.txt
## Description: Readme file
## Author: Josh Gold

Configuration File:
    The configuration file input is a YAML file for the run directive information.
	
	Example:
	
	index:
	    0:
            stage:
            args:
            tcl:
                pre:
                post:
            directives:
                - name:
				- name:
        1:
            stage:
            directives:
                - name:			
		
	Options:
		
		index      : Root node of the configuration file.  This is required.

        [\d+]      : The index number to determine the order of execution.  For the above example, 0 will execute, then 1.  The index number should increment
		             for each additional stage.
			   
	    stage      : This is the Vivado Implementation stage desired to run.  Acceptable options are opt_design, place_design, phys_opt_design, and route_design.
		             Running phys_opt_design in an index number after route_design has completed will run post-route phys_opt_design.
		
		args       : This is for any additional arguments needed to run for the Vivado Implementation stage.  This is a single string that should contain the entire
		             list of arguments you desire to pass to the command.
				
		tcl        : The tcl option supports a single script to be sourced before and after the associated Vivado Implementation stage.
		
		pre        : The path to the file that will be sourced before the associated Vivado Implementation stage.  Any relative path would be to the Vivado [pwd] directory.
		
		post       : The path to the file that will be sourced after the associated Vivado Implementation stage.  Any relative path would be to the Vivado [pwd] directory.
		
		directives : This contains the list of the directives to be run for the associated Vivado Implementation stage
		
		name       : This is the name of the directive

Tcl Scripts:
	The pre and post Tcl scripts have some variables for the specific run that can be useful, if desired.

	opts(-checkpoint) : The path to the Vivado Design Checkpoint that will be opened for the given run
	
	opts(-directive)  : The directive to be used for the given stage
	
	opts(-stage)      : The Vivado Implementation stage that is being executed for the run
	
	opts(-run_dir)    : The original output directory listed for the vXplore script 
	
	opts(-out_dir)    : The output directory where the current vXplore run is being executed
	


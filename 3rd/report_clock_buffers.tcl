proc report_clock_buffers {args} {
	## Set Default option values
	array set opts {-help 0}
	
	## Set the command line used
	set commandLine "report_clock_buffers $args"
	
    ## Parse arguments from option command line
	while {[string match -* [lindex $args 0]]} {
		## Set the name of the first level option
        set optionName [lshift args]
		## Check for the option name in the regular expression
		switch -regexp -- $optionName {
            {-f(i(l(e)?)?)?$}     { set opts(-file) [lshift args]}
            {-h(e(l(p)?)?)?$}     { set opts(-help) 1}
            {-u(s(a(g(e)?)?)?)?$} { set opts(-help) 1}			
            default {
                return -code error "ERROR: \[report_clock_buffers\] Unknown option '[lindex $args 0]', please type 'report_clock_buffers -help' for usage info."
            }
        }
    }
	
	## Display help information
    if {$opts(-help) == 1} {
        puts "report_clock_buffers\n"
        puts "Description:"
        puts "  Gathers clock buffer information and displays report"
        puts ""
        puts "Syntax:"
        puts "  report_clock_buffers \[-file\] \[-help\]"
        puts ""
        puts "Usage:"
        puts "  Name                Description"
        puts "  -------------------------------"
		puts "  \[-file\]             Filename to output results to. (send output to" 
        puts "                      console if -file is not used)"
        puts ""
        return
    }
	
	## Create header file for command and report file
    append reportHeader "+-----------------------------------------------------------------------------------------------\n"
    append reportHeader "| Report   :  report_clock_buffers\n"
    append reportHeader "| Design   :  [get_property -quiet TOP [current_design -quiet]]\n"
    append reportHeader "| Part     :  [get_property -quiet PART [current_project -quiet]]\n"
    append reportHeader "| Version  :  [lindex [split [version] \n] 0] [lindex [split [version] \n] 1]\n"
    append reportHeader "| Date     :  [clock format [clock seconds]]\n"
    append reportHeader "+-----------------------------------------------------------------------------------------------\n\n"
	
	## Initialize the Array for the Clock Buffer Type
	array set clockTypeArray {}
	## Initialize the buffer count for cells inside an IP instance
	set ipBufferCount 0
	## Initialize the report string
	set reportString ""
	
	## Get the list of clock buffers in the design
	set cellList   [get_cells -quiet -hierarchical -filter {PRIMITIVE_TYPE=~CLOCK.BUFFER.* || PRIMITIVE_TYPE=~CLOCK.MUX.* || PRIMITIVE_TYPE=~CLK.gclk.BUF*}]
	## Get all the IP cells in the design
	set ipCellList [get_cells -quiet -hierarchical -filter {core_generation_info!="" || CORE_GENERATION_INFO!="" || x_core_info!="" || X_CORE_INFO!=""}]
	
	## Check if any clock buffer cells were found in the design
	if {[llength $cellList]==0} {
		puts "CRITICAL WARNING: \[report_clock_buffers\] Unable to find any Clock Buffer primitives in the current design."
		puts "Unable to create report."
		return
	}
	
	## Create the Summary table
	set tableSummary [Table::Create]
	## Create the Clock Type table
	set tableClockType [Table::Create]
	## Create the Details table
	set tableDetails [Table::Create]
	## Create the Loads table
	set tableClockLoads [Table::Create]
	
	## Set the Header for the Summary Table
	$tableSummary header [list "Type" "Count"]
	## Set the Header for the Clock Type Table
	$tableClockType header [list "Ref Name" "Used"]
	## Set the Header for the Details Table
	$tableDetails header [list "Type" "Period (ns)" "Clock Loads" "Non-Clock Loads" "IP Instance" "Clock Name(s)" "Buffer Name"]
	## Set the Header for the Clock Load Table
	$tableClockLoads header [list "Period (ns)" "Frequency (MHz)" "Clock Loads" "Clock Loads (%)"]

	## Loop through each cell in the cell list
	foreach cellObj $cellList {
		## Get the output pins of the buffer cell
		set cellOutputPinList [get_pins -quiet -of_objects $cellObj -filter {DIRECTION==OUT}]
		## Get the cell name of the buffer
		set cellName        [get_property -quiet NAME $cellObj]
		## Get the cell type (reference cell) of the buffer
		set cellType        [get_property -quiet REF_NAME $cellObj]
		
		## Increment the cell type array for type counts
		incr clockTypeArray($cellType)
		## Initialize the IP instance variable
		set ipInstance ""
		
		## Loop through each IP cell from the design
		foreach ipCellObj [lreverse $ipCellList] {
			## Check if the buffer cell name contains the IP cell instance name
			if {[regexp "$ipCellObj/" $cellName]} {
				## Set the IP cell instance name
				set ipInstance "$ipCellObj"
				## Increment the IP cell buffer count
				incr ipBufferCount
				## Break the run to not count multiple IP instances
				break
			}
		}
		
		## Get the clock names from the cell buffer output pins
		set clockNameList   [get_clocks -quiet -of_objects $cellOutputPinList]
		
		## Check if any clocks exist for the cell buffer
		if {[llength $clockNameList]==0} {
			## Check the clock objects downstream from the cell buffer
			set clockNameList [lsort -uniq [get_clocks -quiet -of_objects [get_pins -quiet -leaf -of_objects [get_nets -of_objects $cellOutputPinList]]]]
		}

		## Check if any clocks exists for the cell buffer
		##   to check for the clock periods
		if {[llength $clockNameList]!=0} {
			## Get the clock periods from the clock objects
			set clockPeriodList [get_property -quiet PERIOD $clockNameList]
		} else {
			## Set the clock periods to N/A
			set clockPeriodList "N/A"
		}
		
		## Get all the clock loads  driven by the cell
		set clockLoadList   [get_pins -quiet -leaf -of_objects [get_nets -of_objects $cellOutputPinList] -filter {DIRECTION==IN && IS_CLOCK}]
		## Get all the non-clock loads driven by the cell
		set dataLoadList    [get_pins -quiet -leaf -of_objects [get_nets -of_objects $cellOutputPinList] -filter {DIRECTION==IN && !IS_CLOCK}]
		
		## Save number of loads per period
	 	if {$clockPeriodList != "N/A"} {
			## Return the smallest period from the list
			set smallestPeriod [lindex [lsort -real $clockPeriodList] 0]
			## Store the number of clock loads by the clock period
            lappend periodLoadArray($smallestPeriod) [llength $clockLoadList]
        } 
		
		## Add the buffer data to the Details Table
		$tableDetails addrow [list $cellType $clockPeriodList [llength $clockLoadList] [llength $dataLoadList] $ipInstance [concat {*}$clockNameList] $cellName]
		## Add the separator to the Details Table
		#$tableDetails separator
	}
	
	$tableDetails separator
	
	## Add the Total Clock buffer count to the Summary Table
	$tableSummary addrow [list "Total Clock Buffers" [llength $cellList]]	
	#$tableSummary separator
	## Add the Clock Buffers found in IP to the Summary Table
	$tableSummary addrow [list "  Clock Buffers from IP" $ipBufferCount]
	$tableSummary separator
	
	## Loop through each clock buffer type in the array
	foreach clockType [array names clockTypeArray] {
		## Add the clock buffer type to the Clock Type Table
		$tableClockType addrow [list $clockType $clockTypeArray($clockType)]
		## Add the separator to the Clock Type Table 
		#$tableClockType separator
	}
	
	$tableClockType separator
	
	## Initialize the total number of loads to zero
	set totalLoads 0
	
	## Loop through each period in the array
    foreach {period loads} [array get periodLoadArray] {
		## Add up each load element for the specified period
		set periodLoadArray($period) [expr [join $loads +]]
		## Increment the total number of loads for the specified period
        incr totalLoads $periodLoadArray($period)
	}
    
	## Loop through each period to add the clock period and respective loads to the table
	foreach period [lsort -real [array names periodLoadArray]] {
		$tableClockLoads addrow [list $period [format "%.3f" [expr 1000.0 * (1 / $period)]] $periodLoadArray($period) [format "%.2f" [expr 100.0 * $periodLoadArray($period) / $totalLoads]]]
		#$tableClockLoads separator
    }
	
	$tableClockLoads separator
	
	## Display the Clock Buffer Title
	append reportString "Clock Buffer Design Information\n"
	append reportString "\n"
	
	## Display the Summary Table
	append reportString "1. Summary Clock Table\n"
	append reportString "----------------------\n"
	append reportString "\n"
	append reportString "[$tableSummary print]\n"
	append reportString ""
	
	## Display the Clock Type Table
	append reportString "2. Summary of Clock Buffers by Type\n"
	append reportString "-----------------------------------\n"
	append reportString "\n"
	append reportString "[$tableClockType print]\n"
	append reportString "\n"

	## Display the Details Table
	append reportString "3. Detailed Clock Table\n"
	append reportString "-----------------------\n"
	append reportString "\n"
	append reportString "[$tableDetails print]\n"

	## Display the Clock Loads Table
	append reportString "4. Clock Loads Table\n"
	append reportString "-----------------------\n"
	append reportString "\n"
	append reportString "[$tableClockLoads print]\n"	
	
	## Check if the file option is used and write the report to the specified file
	if {[info exists opts(-file)]} {
		## open the filename for writing
		set fileHandle [open $opts(-file) "w"]
		## send the data to the file
		puts $fileHandle $reportHeader
		puts $fileHandle $reportString
		## close the file, ensuring the data is written out before you continue with processing.
		close $fileHandle
		
		## Return the name of the output file
		return [file join [pwd] $opts(-file)]
	} else {
		puts $reportHeader
		## Display the report string
		puts $reportString
	}
}

# #########################################################
# lshift
# #########################################################
proc lshift {varname} {
	upvar $varname argv
	set r [lindex $argv 0]
	set argv [lrange $argv 1 end]
	return $r
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



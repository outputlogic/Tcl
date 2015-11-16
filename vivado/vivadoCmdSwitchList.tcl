
# Proc to reload current script
proc [file tail [info script]] {} " source [info script]; puts \" [info script] reloaded\" "

# This script generates a file with all the Vivado commands and their switches
# The default filename is:
#    vivadoCmdSwitchList_<version>.csv

# The script can be run directly from the shell using the batch mode:
#    /proj/xbuilds/2013.2_daily_latest/installs/lin64/Vivado/2013.2/bin/vivado -nojournal -nolog -mode batch -source vivadoCmdSwitchList.tcl
#    /proj/xbuilds/HEAD_INT_daily_latest/installs/lin64/Vivado/HEAD/bin/vivado -nojournal -nolog -mode batch -source vivadoCmdSwitchList.tcl

proc getTclCmdSwitches { _cmd_ } {
    # set _cmd_ add_files
    # set _cmd_ export_simulation
    # set _cmd_ filter
    set _switches [help -syntax $_cmd_] ; # Get the help for a given tcl command and assign to a string _switches
    # Check that a syntax is found. There is, for instance, a problem with 'report_clock' that is not a Vivado command but that is returned by 'info command'
    if {![regexp {Syntax:} $_switches]} { return {} }
    
    set _switches [regsub -all "\[^\<\-\]$_cmd_" $_switches {}] ; # Remove the command name from the string when it is not precessed by a dash or a <. This is mainly for the 'filter' command
    set _switches [regsub -all "^$_cmd_" $_switches {}] ; # Remove the command name at the beginning of the string
    
    set _switches [regsub -all {[\n\r]} $_switches {}] ; # Remove the line endings from the switches string
    set _switches [regsub "Syntax:" $_switches {}] ; # Remove the word Syntax: from the string
    set _switches [regsub -all {:} $_switches {}] ;# Remove colons from the string
    set _switches [regsub -all {^\s+} $_switches {}] ; # Remove white spaces from the beginning of the string
#     set _switches [regsub -all { } $_switches {}] ; # Remove white spaces from the string

    # Fix bug for the syntax of some of the commands (e.g export_simulation):
    #   <-dir <name>> <-simulator <name>>
    set _switches [regsub -all {<-} $_switches {[-}]
    set _switches [regsub -all {>>} $_switches {>]}]
    
    # Remove arguments of command line options:
    # E.g:  [-relative_to <dir> ]   =>  [-relative_to]
    set _switches [regsub -all {\[([^\s]+)([^\[\]]*)?\]} $_switches {[\1]}]
    
    set _switches [regsub -all {\[} $_switches {}] ; # Remove open square brackets from the string
    set _switches [regsub -all {\]} $_switches { }] ; # Remove close square brackets from the string
    set _switches [regsub -all {<arg[^\s]*>} $_switches {}] ; # Remove <arg.*> from the string
    
    set _switches [regsub -all { -} $_switches {,-}] ; # Replace white spaces dash with a comma dash in the string
    set _switches [regsub -all { <} $_switches {,<}] ; # Replace white spaces < with a comma < in the string. This is for commands that have defaults arguments like <file>
    set _switches [regsub -all { } $_switches {}] ; # Remove white spaces from the string
#     set _switches [regsub -all {<.*?>} $_switches {}] ;# Remove all arguments from the string
    set _switches [regsub -all {\.\.\.} $_switches {}] ;# Remove triple dots from the string

    set _switches [join [lsort [split $_switches ,]] ,]
    set _switches [regsub -all -- {-} $_switches {}] ; # Remove all the dashes in the final string
    # return the string of arguments
    return "$_switches"
}


proc dumpVivadoCmdSwitchList { {filename {}} } {
  if {$filename == {}} {
    set _ver [version -short]
    set filename "vivadoCmdSwitchList_${_ver}.csv"
  }
  set FH [open $filename {w}]
  foreach el [split [version] \n] { puts $FH "# $el" }
  foreach cmd [lsort [info commands *]] {
    catch {
      set deprecated 0
      # Keep track of the number of 'Common 17-210' messages: WARNING: [Common 17-210] 'xxxx' is deprecated, Please use 'yyyy' instead. This command will no longer be available after zzzz.
      set count1 [get_msg_config -count -id {Common 17-210}]
      set help [help $cmd]
      set count2 [get_msg_config -count -id {Common 17-210}]
      if {$count2 != $count1} { set deprecated 1}
      # Skip Tcl built-in commands
      if {![regexp {Tcl Built-In Command} $help]} {
        set switches [getTclCmdSwitches $cmd]
        if {$switches == {}} { continue }
        if {$deprecated} {
#           puts $FH "$cmd<deprecated>,$switches"
          puts $FH "$cmd***deprecated***,$switches"
        } else {
          puts $FH "$cmd,$switches"
        }
      }
    }
  }
  close $FH
  puts " File $filename generated"
  return 0
}

# Generate the list of Vivado commands and their switches
dumpVivadoCmdSwitchList


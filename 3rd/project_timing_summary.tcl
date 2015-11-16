# =============================================================================
#                           SCRIPT DESCRIPTION
# =============================================================================
# 
# THIS PROGRAM SEARCHED THROUGH THE DIRECTORIES STARTING AT THE EXECUTED
# DIRECTORY SEARCHING FOR ANY FILES WITH A .RPT EXTENSION. IT THEN THEN 
# SEARCHES FOR THE LINE "DESIGN TIMING SUMMARY" AND THEN THEN LINE CONTAINING
# WNS(ns). IT THEN CAPTURES THE TIMING SUMMARY LINES OUTPUTING IT TO THE SCREEN
# AND GENERATES A CSV FILE WITH THIS INFORMATION.
# IT ALSO LOOKS FOR THE FILE NAME CONTAINING THE WORD "ROUTE" (CASE INSENSITIVE)
# CAPTURING THE WNS NUMBER AND FILE NAME. IT SORTS THIS INFORMATION LOOKING FOR
# THE BEST ROUTED RUN AND OUTPUTS THIS INFORMATION TO THE SCREEN.
# -----------------------------------------------------------------------------
# File Name: project_timing_summary.tcl
#
# SYNTAX:
# =======
#    tclsh project_timing_summary.tcl
#
#     Output file format is :
#       project_timing_summary.csv
# -----------------------------------------------------------------------------
# Author  : Tony Scarangella, Xilinx 
# Revison : 1.0 21-Dec-2012 - initial release
# =============================================================================
#..............................................................................#
#                                                                              #
#                              P R O C E D U R E S                             #
#                                                                              #
#..............................................................................#
set systemTime [clock seconds]      ; # capture current time
set start [clock seconds] 
set timeFormat [clock format $systemTime -format {%d-%b-%Y_%H_%M_%S}]  ; # format date/hour in a string
set path [exec pwd]
set proj_timing_sum_file  "project_timing_summary.csv"   

set outfile [open $proj_timing_sum_file w]     ; # open output file in write mode

proc reportDirectory {dirName} {
  global rptFile
# file join merges the existing directory path with
#    the * symbol to match all items in that directory.
  foreach item [glob -nocomplain [file join $dirName *]]  {
    if { [string match [file type $item] "directory"]} {
      reportDirectory $item
    } else {
      if { [string match {*.rpt} $item ] } {
        #puts "DEBUG: $item is a [file type $item]"
        #puts "DEBUG: Attributes are: [file attributes $item]"
        lappend rptFile $item
        #puts "DEBUG: $rptFile"
        file stat $item tmpArray
        set name [file tail $item]
        #puts "DEBUG: $name is: $tmpArray(size) bytes\n"
      }
    }
  }
}
puts "==> Looking for *.rpt files in all directories"

#..............................................................................#
#                                                                              #
#                         M A I N   P R O G A M                                #
#                                                                              #
#******************************************************************************#
# Start reporting from the current directory
reportDirectory {}

puts "==> Found [llength $rptFile] rpt files. Will on analyze timing reports \n"

puts "Design Timing Summary,"
puts "                      TNS                              THS"
puts "                      Failing                          Failing"
puts "WNS(ns)    TNS(ns)    Endpoints  WHS(ns)    THS(ns)    Endpoints  FILE NAME"
puts $outfile "Design Timing Summary,"
puts $outfile ",WNS(ns),TNS(ns),TNS_Failing_Endpoints,TNS_Total_Endpoints,WHS(ns),THS(ns),THS_Failing_Endpoints,THS_Total_Endpoints,WPWS(ns),TPWS(ns),TPWS_Failing_Endpoints,TPWS_Total_Endpoints"

set rptFile_sort [lsort $rptFile]
set all_WNS {}
set all_sort_WNS {}
set all_WNS_names {}
set best_WNS {}
 
foreach Fname $rptFile_sort  {
  set lineNumber 0
  set wnsHeader ""
  set sumLinenum ""
  set rptWNS_num ""
  set foundHeader 0
  
  if [catch {set readPltimrpt [open $Fname r] } msg ] {
        puts "Unable to read $Fname  \n"
        puts "exiting..... \n"
        return
   } 
   
           
   while { [gets $readPltimrpt line] >= 0 } {
     incr lineNumber
     if [regexp {Design Timing Summary} $line] {
       #puts "DEBUG: File $Fname: Found Summary header at line number= $lineNumber $line"
       set wnsHeader [expr {$lineNumber + 4}]
       set sumLinenum [expr {$lineNumber + 6}]
     } 
     if { $wnsHeader == $lineNumber && [string match {    WNS(ns)*} $line] } {
       #puts "DEBUG: File $Fname: Found WNS header at line number= $lineNumber"
       set foundHeader 1
     }
     if { $sumLinenum == $lineNumber &&  $foundHeader == 1 } {
       #puts "DEBUG: File $Fname: Found WNS header at line number= $lineNumber"
       set rptWNS    [lindex $line 0] ; set rptWNS_i [expr $rptWNS]
       set rptTNS    [lindex $line 1]
       set rptTNSFE  [lindex $line 2]
       set rptTNSTE  [lindex $line 3]
       set rptWHS    [lindex $line 4]
       set rptTHS    [lindex $line 5]
       set rptTHSFE  [lindex $line 6]
       set rptTHSTE  [lindex $line 7]
       set rptWPWS   [lindex $line 8]
       set rptTPWS   [lindex $line 9]
       set rptTPWSFE [lindex $line 10]
       set rptTPWSTE [lindex $line 11]
       puts [format "%-10s %-10s %-10s %-10s %-10s %-10s %-s" $rptWNS $rptTNS $rptTNSFE $rptWHS $rptTHS $rptTHSFE $Fname]
       #puts "DEBUG: $Fname $rptWNS $rptTNS $rptTNSFE $rptTNSTE $rptWHS $rptTHS $rptTHSFE $rptTHSTE $rptWPWS $rptTPWS $rptTPWSFE $rptTPWSTE"
       puts $outfile "$Fname,$rptWNS,$rptTNS,$rptTNSFE,$rptTNSTE,$rptWHS,$rptTHS,$rptTHSFE,$rptTHSTE,$rptWPWS,$rptTPWS,$rptTPWSFE,$rptTPWSTE"
     } 
   }       
   if {[string match -nocase "*route*" $Fname] &&  $foundHeader == 1} {
     #puts "==> File contains the word route $Fname"
     lappend all_WNS $rptWNS_i
     lappend all_WNS_names $rptWNS_i $Fname
   }
close $readPltimrpt
}       

close $outfile

# COMPILE TIME
set end [clock seconds] 
set duration [expr $end - $start] 
puts "==> Date: [clock format $systemTime -format %D] Compile time: $duration seconds "
puts "==> Open csv file $path\\$proj_timing_sum_file"

set all_sort_WNS [lsort -real -decreasing $all_WNS]
set best_WNS [lindex $all_sort_WNS 0]
set found_best [lsearch $all_WNS_names $best_WNS]
set found_name [lindex $all_WNS_names [expr $found_best+1]]
puts "\n==> Looking for best run with file name containing the word \"route\" \n"
puts "\n==> Best score: $best_WNS ns \n==> From run: $found_name"


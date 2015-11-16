package require cmdline
 
 
proc toto { args } {
 
# Show args before processing
puts "Before, args = '$args'"
 
# Process the command line
set parameters {
    {server.arg ""   "Which server to test"}
    {port.arg   5551 "Port to send test cmd"}
    {user.arg   ""   "Login name"}
    {debug           "Output extra debug info"}
}
array set arg [cmdline::getoptions args $parameters]
 
# Verify required parameters
set requiredParameters {server user}
foreach parameter $requiredParameters {
    if {$arg($parameter) == ""} {
        puts stderr "Missing required parameter: -$parameter"
#         exit 1
    }
}
 
# Displays the arguments
puts ""
parray arg
puts ""
 
# Show args after processing
puts "After, args = '$args'"

}



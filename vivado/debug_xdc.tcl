
# Proc to reload current script
proc [file tail [info script]] {} " source [info script]; puts \" [info script] reloaded\" "


#
# David Pefourque
# 03/18/2013
#
# Hack to execute unsupported commands inside XDC:
# The hack should work even when Vivado reads an XDC inside a checkpoint.
# 
# Usage:
#   source ~/scripts/debug_xdc.tcl
#   debug_xdc on
#   read_xdc <myXDC>
#   debug_xdc off
#
# Example of XDC:
#   set_units -help { puts [get_clocks] }
#   set_units -help puts [get_cells]
#   set_units -help puts "Current instance: [current_instance .]"
#   set clocks [get_clocks]
#   set_units -help {
#     puts "Current instance: [current_instance .]"
#     puts "The list of clocks is $clocks"
#   }
#
# Note: the -help as the first argument is optional but prevents Vivado from throwing errors when
# the hack mode is not enabled. In this case, all the code inside the 'set_units' commands is just
# skipped by Vivado.
#


proc exec_cmd { args } {
  # Skip -help if specified in first position
  if {[lsearch [list -h -he -hel -help] [lindex $args 0]] != -1} {
    set args [lrange $args 1 end]
  }
  switch [llength $args] {
    0 {
    }
    1 {
      uplevel 1 [concat eval $args]
    }
    default {
      uplevel 1 [list eval $args]
    }
  }
}

proc debug_xdc { { flag {} } } {
  if {[lsearch [list 1 on true] $flag] != -1} {
    if {[info command set_units.Vivado] == {}} {
      if {[info proc exec_cmd] == {}} {
        puts " debug_xdc: cannot activate XDC debugging. Missing 'exec_cmd' proc"
        return
      }
      puts " debug_xdc: 'set_units' command for XDC debugging has been activated"
      catch { rename set_units set_units.Vivado }
      catch { rename exec_cmd set_units }
    } else {
      puts " debug_xdc: already activated"
    }
  } elseif {[lsearch [list 0 off false] $flag] != -1} {
    if {[info command set_units.Vivado] != {}} {
      puts " debug_xdc: 'set_units' command for XDC debugging has been desactivated"
      if {[info proc exec_cmd] == {}} {
        catch { rename set_units exec_cmd }
      } else {
        catch { rename set_units {} }
      }
      catch { rename set_units.Vivado set_units }
    } else {
      puts " debug_xdc: already desactivated"
    }
  } else {
    if {[info command set_units.Vivado] == {}} {
      puts " debug_xdc: XDC debugging is desactivated"
    } else {
      puts " debug_xdc: XDC debugging is activated. Use 'set_units' inside XDC to execute commands"
    }
  }
}

# proc reload {} { source -notrace ~/scripts/debug_xdc.tcl; puts " debug_xdc.tcl reloaded" }



proc ::get_mig_pin_mapping {args} {
  # Convert the MIG's package pin information into constraints for MIG IP
  return [uplevel ::get_mig_pin_mapping::get_mig_pin_mapping $args]
}

eval [list namespace eval ::get_mig_pin_mapping {
   variable version {11-17-2014}
   variable debug 0
} ]


proc ::get_mig_pin_mapping::get_mig_pin_mapping {args} {
  variable debug
  #-------------------------------------------------------
  # Process command line arguments
  #-------------------------------------------------------
  set error 0
  set help 0
  set xdc {}
  set part {}
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      -xdc -
      {^-x(dc?)?$} {
           set xdc [lshift args]
           if {$xdc == {}} {
             puts " -E- no filename specified."
             incr error
           }
      }
      -part -
      {^-p(a(rt?)?)?$} {
           set part [lshift args]
      }
      -help -
      {^-h(e(lp?)?)?$} -
      -usage -
      {^-u(s(a(ge?)?)?)?$} {
           set help 1
      }
      -debug {
           set debug 1
      }
      default {
            if {[string match "-*" $name]} {
              puts " -E- option '$name' is not a valid option. Use the -help option for more details"
              incr error
            } else {
              puts " -E- option '$name' is not a valid option. Use the -help option for more details"
              incr error
            }
      }
    }
  }

  if {$help} {
    puts [format {
  Usage: get_mig_pin_mapping
              -xdc <XDC_file>|-x <XDC_file>  - MIG XDC package constraints
              [-part <part>|-p <part>]       - UltraScale part
              [-help|-h]                     - This help message

  Description: Generate a list of MIG IP properties based on an XDC package pin information

     This command returns the list of properties/values that need to be applied to
     the MIG IP to match the package pin information inside the XDC.

     The returned list can be applied to the MIG IP using the set_property command:
       set_property -dict [get_mig_pin_mapping -xdc <XDC_file>] [get_ips <MIG_IP>]

     The script only works for MIG XDC that use MIG IP generated port names.

     If no part is provided, the script uses the current part name.

     Note: This command is for UltraScale only

  Example:
     set properties [get_mig_pin_mapping -part xcvu095-ffvd1924-2-e-es1 -xdc <PATH_TO_MIG_IP>/ddr4.xdc]
     set_property -dict $properties [get_ips mig_0]
} ]
    # HELP -->
    return {}
  }

  if {$part == {}} {
    # If no part has been specified, extract the current part number
    set part [get_property -quiet PART [current_project -quiet]]
  }

  if {$part == {}} {
    puts " -E- no part specified"
    incr error
  } elseif {[get_parts -quiet $part] == {}} {
    puts " -E- invalid part '$part'"
    incr error
  } else {
    set family [get_property -quiet FAMILY [get_parts $part]]
    if {![regexp {^(virtex|kintex|artix)u} $family]} {
      puts " -E- part '$part' is not a valid UltraScale part"
      incr error
    }
  }

  if {$xdc == {}} {
    puts " -E- no XDC specified"
    incr error
  } elseif {![file exists $xdc]} {
    puts " -E- XDC script '$xdc' does not exist"
    incr error
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  create_project mapping -in_memory -part $part -force
  set_property design_mode PinPlanning [current_fileset]
  open_io_design -name io_1

  if {$xdc != {}} {
    if {$debug} { puts " -I- reading XDC [file normalize $xdc]" }
    read_xdc $xdc
  }

  set allPorts [lsort [get_ports]]
  set properties [list]
  set count 0

  if {[catch {

    foreach port $allPorts {
      set packagePin [get_property PACKAGE_PIN $port]
      if {$packagePin == {}} {
        puts " -I- no PACKAGE_PIN property for port $port. Skipped"
        continue
      }
      set bPin [ convert_package_to_mig_constraint $packagePin ]
      set param {}
      switch -regexp -- $port {
        {c(.*)_ddr[3-4](.*)\[(.*)\]} {
          regexp {c(.*)_ddr[3-4](.*)\[(.*)\]} $port - qa1 qa2 qa3
          set param [format {c%s%s_%s} $qa1 $qa2 $qa3]
        }
        {c(.*)_ddr[3-4](.*)} {
          regexp {c(.*)_ddr[3-4](.*)} $port - qa1 qa2
          set param c${qa1}${qa2}
        }
        {c(.*)_rld3(.*)\[(.*)\]} {
          regexp {c(.*)_rld3(.*)\[(.*)\]} $port - qa1 qa2 qa3
          set param [format {c%s%s_%s} $qa1 $qa2 $qa3]
        }
        {c(.*)_rld3(.*)} {
          regexp {c(.*)_rld3(.*)} $port - qa1 qa2
          set param c${qa1}${qa2}
        }
        {c(.*)_qdriip(.*)\[(.*)\]} {
          regexp {c(.*)_qdriip(.*)\[(.*)\]} $port - qa1 qa2 qa3
          set param [format {c%s%s_%s} $qa1 $qa2 $qa3]
        }
        {c(.*)_qdriip(.*)} {
          regexp {c(.*)_qdriip(.*)} $port - qa1 qa2
          set param c${qa1}${qa2}
        }
        {.*sys_rst.*} {
          set param $port
        }
        {c(.*)_sys_clk(.*)} {
          regexp {c(.*)_sys_clk(.*)} $port - qa1 qa2
          set param c${qa1}_sys_clk${qa2}
        }
        {.*data_compare_error.*} {
          set param c0_data_compare_error
        }
        {.*init_calib_complete.*} {
          set param c0_init_calib_complete
        }
        default {
        }
      }
      if {$param != {}} {
        lappend properties CONFIG.$param $bPin
        incr count
      }

    }

  } errorstring]} {
    puts $errorstring
  }

  close_project
  if {$debug} {
    puts " -I- # processed ports: [llength $allPorts]"
    puts " -I- # matches: $count"
  }
  puts " -I- get_mig_pin_mapping: $count MIG port constraints have been generated"
  return $properties
}

proc ::get_mig_pin_mapping::convert_package_to_mig_constraint {packagePinName} {
  if {$packagePinName == {}} {
    error "empty package pin name"
  }
  set pin [get_package_pins $packagePinName]
  if {$pin == ""} {
    error "invalid package pin name '$packagePinName'"
  }
  # E.g: IO_T1U_N12_49
  set pinFunc [get_property PIN_FUNC $pin]
  set pattern1 {_T(\d+)([UL])_N(\d+)_.*_(\d+)$}
  set pattern2 {_T(\d+)([UL])_N(\d+).*_(\d+)$}
  if [regexp $pattern1 $pinFunc - byteGroupId nibbleStr bitId bankId] {
    return bank${bankId}.byte${byteGroupId}.pin${bitId}
  } elseif [regexp $pattern2 $pinFunc - byteGroupId nibbleStr bitId bankId] {
    return bank${bankId}.byte${byteGroupId}.pin${bitId}
  } else {
    error "package pin '$packagePinName' has a PIN_FUNC '$pinFunc' that does not match any recognized pattern"
  }

}

proc ::get_mig_pin_mapping::lshift {inputlist} {
  upvar $inputlist argv
  set arg  [lindex $argv 0]
  set argv [lrange $argv 1 end]
  return $arg
}

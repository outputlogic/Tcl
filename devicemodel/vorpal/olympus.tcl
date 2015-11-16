
###########################################################################
##
## Procedures for Olympus
##
###########################################################################



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
   append res $head
   set res
}


###########################################################################
##
## Procedures for Olympus
##
###########################################################################

#------------------------------------------------------------------------
# show_case_value
#------------------------------------------------------------------------
# Report the case values on a cell or a pin
#------------------------------------------------------------------------
proc show_case_value { args } {
  upvar 1 staToolName staToolName
  if {![info exists staToolName]} {
    set staToolName pt
  }
  switch $staToolName {
    pt {
      eval PT::show_case_value $args
    }
    gt {
      eval PT::show_case_value $args
#       eval GT::show_case_value $args
    }
    default {
    }
  }
}

#------------------------------------------------------------------------
# show_arcs
#------------------------------------------------------------------------
# Report information about timing arcs
#------------------------------------------------------------------------
proc show_arcs { args } {
  upvar 1 staToolName staToolName
  if {![info exists staToolName]} {
    set staToolName pt
  }
  switch $staToolName {
    pt {
      eval PT::show_arcs $args
    }
    gt {
      eval PT::show_arcs $args
#       eval GT::show_arcs $args
    }
    default {
    }
  }
}

#------------------------------------------------------------------------
# show_info
#------------------------------------------------------------------------
# Report information on a net/cell/pin
#------------------------------------------------------------------------
proc show_info { args } {
  upvar 1 staToolName staToolName
  if {![info exists staToolName]} {
    set staToolName pt
  }
  switch $staToolName {
    pt {
      eval PT::show_info $args
    }
    gt {
      eval PT::show_info $args
#       eval GT::show_info $args
    }
    default {
    }
  }
}

#------------------------------------------------------------------------
# analyze_path
#------------------------------------------------------------------------
# Report information about a path defined through a list of pins
#------------------------------------------------------------------------
proc analyze_path { args } {
  upvar 1 staToolName staToolName
  if {![info exists staToolName]} {
    set staToolName pt
  }
  switch $staToolName {
    pt {
      eval PT::analyze_path $args
    }
    gt {
      eval PT::analyze_path $args
#       eval GT::analyze_path $args
    }
    default {
    }
  }
}

#------------------------------------------------------------------------
# trace_arcs
#------------------------------------------------------------------------
# Trace enabled timing arcs from/to a pin. If a timing arcs goes to multiple 
# pins, then the function stops
#------------------------------------------------------------------------
proc trace_arcs { args } {
  upvar 1 staToolName staToolName
  if {![info exists staToolName]} {
    set staToolName pt
  }
  switch $staToolName {
    pt {
      eval PT::trace_arcs $args
    }
    gt {
      eval PT::trace_arcs $args
#       eval GT::trace_arcs $args
    }
    default {
    }
  }
}



###########################################################################
##
## Main
##
###########################################################################

puts ""

set ROOT [file dirname [info script]]

# Create proc to reload current script
eval "proc reload {} { source [info script] }"

# Implementation for PrimeTime & GoldTime
if {[file exists $ROOT/olympus_pt.tcl]} {
  source $ROOT/olympus_pt.tcl
} else {
  puts " WARNING: file $ROOT/olympus_pt.tcl not found"
}

# # Implementation for GoldTime
# if {[file exists $ROOT/olympus_gt.tcl]} {
#   source $ROOT/olympus_gt.tcl
# } else {
#   puts " WARNING: file $ROOT/olympus_gt.tcl not found"
# }

puts "\n The following commands are available: (-help/-h for help)"
puts "   show_arcs"
puts "   show_case_value"
puts "   show_info"
puts "   trace_arcs"
puts "   analyze_path"
puts ""


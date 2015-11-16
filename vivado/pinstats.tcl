
# This script reports statistics regarding the properties IS_CLOCK IS_ENABLE IS_PRESET IS_RESET IS_CLEAR IS_SETRESET
# for all the primitive leaf pins in the design

# Set debug to 1 to generate intermediate results
set debug 0
# set debug 1

# Debug: set rebuildCache to 0 to prevent the script from re-building the cache
set rebuildCache 1
# set rebuildCache 0

# Debug: set destroyTables to 0 to prevent the prettyTables to be destroyed
set destroyTables 1
# set destroyTables 0

# Debug: set saveTableCSV to 1 to save the prettyTables as CSV format
set saveTableCSV 0
# set saveTableCSV 1

# Prefix for generated files (debug mode only): ${tbldebugFileName}.csv / ${tbldebugFileName}.rpt
set tbldebugFileName {stats}

# Default output channel
set channel {stdout}
set FH {}

# Output file for the reports
set filename {}
# set filename {pinstats.out}

if {$filename != {}} {
  set FH [open $filename w]
  set channel $FH
}

set ref_names [lsort -unique [get_property REF_NAME [get_cells -hier -filter {IS_PRIMITIVE}]]]
# For debug, work on a subset:
# set ref_names [lrange $ref_names 0 3]
# set ref_names [list FIFO36E1 IDELAYCTRL]
# set ref_names [list FIFO36E1 MMCME2_ADV PLLE2_ADV ISERDESE2 IDELAYCTRL OSERDESE2]
# set ref_names [lrange $ref_names 5 15]
# set ref_names [lrange $ref_names 10 15]

set primitives [get_cells -hier -filter {IS_PRIMITIVE}]
set cells [list]
foreach ref_name $ref_names {
  puts " Processing $ref_name"
  # Track only the first cell per REF_NAME
#   lappend cells [lindex [filter $primitives "REF_NAME == $ref_name"] 0]
  # Track all the cells for a particular REF_NAME
  set cells [concat $cells [filter $primitives "REF_NAME == $ref_name"]]
}
# To make sure the list is of a cell objects (due to 'concat' command)
set cells [get_cells $cells]


catch {unset data}

package require toolbox

# Cache the properties/pins to speed-up the code by reducing the number of calls to Vivado commands
if {$rebuildCache} {
  puts " Building cache on [clock format [clock seconds]]"
  catch {unset cachedProps}
  set pins [get_pins -of $cells]
  foreach p [list is_clock is_enable is_preset is_reset is_clear is_setreset ] {
    foreach pin $pins prop [get_property $p $pins] {
      set cachedProps($p,$pin) $prop
    }
  }
} else {
  # The array cachedProps is not rebuilt. Tihs assumes that it already exists
}

set tbl [::tb::prettyTable]
$tbl header {cell pin clock enable preset  reset  clear set/reset name}

# Generate the very detailed table for each cell of the design (debug = 1)
# +-----------------+-----------------------------------+-------+--------+--------+-------+-------+-----------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
# | cell            | pin                               | clock | enable | preset | reset | clear | set/reset | name                                                                                                                                                                                                                                            |
# +-----------------+-----------------------------------+-------+--------+--------+-------+-------+-----------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
# | BUFG            | I                                 | 0     | 0      | 0      | 0     | 0     | 0         | U00_CKG/clkf_buf/I                                                                                                                                                                                                                              |
# | BUFG            | O                                 | 0     | 0      | 0      | 0     | 0     | 0         | U00_CKG/clkf_buf/O                                                                                                                                                                                                                              |
# +-----------------+-----------------------------------+-------+--------+--------+-------+-------+-----------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
# | BUFGCTRL        | CE0                               | 0     | 1      | 0      | 0     | 0     | 0         | U00_PCW1TOP/ext_clk.pcie3_7x_0_pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/CE0                                                                                                                                                                        |
# | BUFGCTRL        | CE1                               | 0     | 1      | 0      | 0     | 0     | 0         | U00_PCW1TOP/ext_clk.pcie3_7x_0_pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/CE1                                                                                                                                                                        |
# | BUFGCTRL        | I0                                | 1     | 0      | 0      | 0     | 0     | 0         | U00_PCW1TOP/ext_clk.pcie3_7x_0_pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/I0                                                                                                                                                                         |
# | BUFGCTRL        | I1                                | 1     | 0      | 0      | 0     | 0     | 0         | U00_PCW1TOP/ext_clk.pcie3_7x_0_pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/I1                                                                                                                                                                         |
# | BUFGCTRL        | IGNORE0                           | 0     | 1      | 0      | 0     | 0     | 0         | U00_PCW1TOP/ext_clk.pcie3_7x_0_pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/IGNORE0                                                                                                                                                                    |
# | BUFGCTRL        | IGNORE1                           | 0     | 1      | 0      | 0     | 0     | 0         | U00_PCW1TOP/ext_clk.pcie3_7x_0_pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/IGNORE1                                                                                                                                                                    |
# | BUFGCTRL        | O                                 | 0     | 0      | 0      | 0     | 0     | 0         | U00_PCW1TOP/ext_clk.pcie3_7x_0_pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/O                                                                                                                                                                          |
# | BUFGCTRL        | S0                                | 0     | 1      | 0      | 0     | 0     | 0         | U00_PCW1TOP/ext_clk.pcie3_7x_0_pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S0                                                                                                                                                                         |
# | BUFGCTRL        | S1                                | 0     | 1      | 0      | 0     | 0     | 0         | U00_PCW1TOP/ext_clk.pcie3_7x_0_pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S1                                                                                                                                                                         |
# +-----------------+-----------------------------------+-------+--------+--------+-------+-------+-----------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
# | BUFMR           | I                                 | 0     | 0      | 0      | 0     | 0     | 0         | U00_QIF1TOP/U00_mig_7series_0/u_qdr_phy_top/u_qdr_rld_mc_phy/qdr_rld_phy_4lanes_0.u_qdr_rld_phy_4lanes/gen_ibuf_cq.bufmr_cq/I                                                                                                                   |
# | BUFMR           | O                                 | 0     | 0      | 0      | 0     | 0     | 0         | U00_QIF1TOP/U00_mig_7series_0/u_qdr_phy_top/u_qdr_rld_mc_phy/qdr_rld_phy_4lanes_0.u_qdr_rld_phy_4lanes/gen_ibuf_cq.bufmr_cq/O                                                                                                                   |
# +-----------------+-----------------------------------+-------+--------+--------+-------+-------+-----------+-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+

puts " Extracting stats on [clock format [clock seconds]]"
foreach c $cells cell_ref [get_property REF_NAME $cells] {
  set pins [lsort [get_pins -of $c]]
  foreach m $pins ref_pin [get_property REF_PIN_NAME $pins] {
    set row [list]
    lappend row $cell_ref
    lappend row $ref_pin
    foreach p [list is_clock is_enable is_preset is_reset is_clear is_setreset ] {
      # Use cache to retrieve property values
#       set prop [get_property $p $m]
      set prop $cachedProps($p,$m)
      lappend row $prop
      if {$prop} {
        if {![info exists data($p)]} { set data($p) [list] }
        lappend data($p) [list $cell_ref $ref_pin]
      }
    }
    lappend row $m
    if {$debug} {
      # Only add the row in debug mode since the table can quiclky become very large
      $tbl addrow $row
    }
#     puts ""
  }
  if {$debug} {
    # Only add the separator in debug mode since the table can quiclky become very large
    $tbl separator
  }
}

if {$debug} {
  # Uncomment the following line to print the table to stdout (very big table!)
#   puts [$tbl print]
  $tbl print -file ${tbldebugFileName}.rpt
  $tbl export -format csv -file ${tbldebugFileName}.csv
}
if {$destroyTables} { catch {$tbl destroy} }

####################################################################
# Extract statistics for each property based on the cell ref name and pin ref name
####################################################################

# Example of tables created for property IS_SETRESET :
#   +-----------------------------------------------------------------+
#   | IS_SETRESET                                                     |
#   +------------+---------------------------------------------+------+
#   | Cell Ref   | Pin Ref                                     | #    |
#   +------------+---------------------------------------------+------+
#   | FDPE       | PRE                                         | 8731 |
#   | FDSE       | S                                           | 5949 |
#   | FIFO36E1   | RST RSTREG                                  | 110  |
#   | IDDR       | S                                           | 4    |
#   | IDELAYCTRL | RST                                         | 1    |
#   | ODDR       | S                                           | 7    |
#   | OSERDESE2  | RST                                         | 61   |
#   | RAMB18E1   | RSTRAMARSTRAM RSTRAMB RSTREGARSTREG RSTREGB | 152  |
#   | RAMB36E1   | RSTRAMARSTRAM RSTRAMB RSTREGARSTREG RSTREGB | 3380 |
#   +------------+---------------------------------------------+------+
#   +------------------------------------------------------+
#   | IS_SETRESET                                          |
#   +---------------+-------------------------------+------+
#   | Pin Ref       | Cell Ref                      | #    |
#   +---------------+-------------------------------+------+
#   | PRE           | FDPE                          | 8731 |
#   | RST           | FIFO36E1 IDELAYCTRL OSERDESE2 | 117  |
#   | RSTRAMARSTRAM | RAMB18E1 RAMB36E1             | 883  |
#   | RSTRAMB       | RAMB18E1 RAMB36E1             | 883  |
#   | RSTREG        | FIFO36E1                      | 55   |
#   | RSTREGARSTREG | RAMB18E1 RAMB36E1             | 883  |
#   | RSTREGB       | RAMB18E1 RAMB36E1             | 883  |
#   | S             | FDSE IDDR ODDR                | 5960 |
#   +---------------+-------------------------------+------+

# This tables summarizes all the properties encountered for a particular lib pin name
# across all the cell ref names
set tblProps [::tb::prettyTable "Properties per Pin Ref"]
$tblProps header {{Pin Ref} {Properties} {Cell Ref}}
$tblProps config -indent 2
catch {unset propref}

puts " Generating summary tables on [clock format [clock seconds]]"
foreach p [list is_clock is_enable is_preset is_reset is_clear is_setreset ] {
  if {![info exists data($p)]} {
    puts " -W- skipping $p"
    continue
  }
  puts $channel ""
  set tblCells [::tb::prettyTable "[string toupper $p]"]
  $tblCells header {{Cell Ref} {Pin Ref} #}
  $tblCells config -indent 2
  set tblPins [::tb::prettyTable "[string toupper $p]"]
  $tblPins header {{Pin Ref} {Cell Ref} #}
  $tblPins config -indent 2
  catch {unset cellref}
  catch {unset pinref}
  foreach el $data($p) {
    foreach {cell_ref pin_ref} $el { break }
    if {![info exists cellref($cell_ref)]} { set cellref($cell_ref) [list] }
    if {![info exists pinref($pin_ref)]} { set pinref($pin_ref) [list] }
    lappend cellref($cell_ref) $pin_ref
    lappend pinref($pin_ref) $cell_ref
    if {![info exists propref($pin_ref)]} { set propref($pin_ref) [list] }
    lappend propref($pin_ref) [list $p $cell_ref]
  }
  foreach cell_ref [lsort [array names cellref]] {
    $tblCells addrow [list $cell_ref [lsort -unique $cellref($cell_ref)] [llength $cellref($cell_ref)] ]
  }
  foreach pin_ref [lsort [array names pinref]] {
    $tblPins addrow [list $pin_ref [lsort -unique $pinref($pin_ref)] [llength $pinref($pin_ref)] ]
  }
  puts $channel [$tblCells print]
  puts $channel [$tblPins print]
  if {$saveTableCSV} {
    $tblCells export -file pinstats.$p.by_cellref.csv -format csv
    $tblPins export -file pinstats.$p.by_pinref.csv -format csv
  }
  catch {$tblCells destroy}
  catch {$tblPins destroy}
}

# Fill-up and print the final tables
#    +-----------------------------------------------------------------------------------------------------+
#    | Properties per Pin Ref                                                                              |
#    +-----------+------------+--------------------------------------------------------------+
#    | Pin Ref   | Properties | Cell Ref                                                     |
#    +-----------+------------+--------------------------------------------------------------+
#    | BITSLIP   | is_enable  | ISERDESE2                                                    |
#    | C         | is_clock   | FDCE FDPE FDRE FDSE IDDR IDELAYE2 ODDR                       |
#    | CE        | is_enable  | BUFR FDCE FDPE FDRE FDSE IDDR IDELAYE2 ODDR SRL16E SRLC32E   |
#    | CE0       | is_enable  | BUFGCTRL                                                     |
#    | CE1       | is_enable  | BUFGCTRL ISERDESE2                                           |
#    | ...       | ...        | ...                                                          |
#    | WEBWE[7]  | is_enable  | RAMB36E1                                                     |
#    | WRCLK     | is_clock   | FIFO36E1 IN_FIFO OUT_FIFO                                    |
#    | WREN      | is_enable  | FIFO36E1 IN_FIFO OUT_FIFO                                    |
#    +-----------+------------+--------------------------------------------------------------+
#    +---------------------------------------------------------------+
#    | Properties per Cell Ref                                       |
#    +----------------+---------+-------------------+----------------+
#    | Cell Ref       | Pin Ref | Pin Properties    | Lib Properties |
#    +----------------+---------+-------------------+----------------+
#    | BUFGCTRL       | CE0     | is_enable         | is_enable      |
#    | BUFGCTRL       | CE1     | is_enable         | is_enable      |
#    | BUFGCTRL       | I0      | is_clock          | is_clock       |
#    | BUFGCTRL       | I1      | is_clock          | is_clock       |
#    | BUFGCTRL       | IGNORE0 | is_enable         | is_enable      |
#    | BUFGCTRL       | IGNORE1 | is_enable         | is_enable      |
#    | BUFGCTRL       | S0      | is_enable         | is_enable      |
#    | BUFGCTRL       | S1      | is_enable         | is_enable      |
#    +----------------+---------+-------------------+----------------+
#    | BUFR           | CE      | is_enable         | is_enable      |
#    | BUFR           | CLR     | is_clear is_reset | is_clear       |
#    +----------------+---------+-------------------+----------------+
#    ...
#    +----------------+---------+-------------------+----------------+
#    | SRLC32E        | CE      | is_enable         | is_enable      |
#    | SRLC32E        | CLK     | is_clock          | is_clock       |
#    +----------------+---------+-------------------+----------------+
#    | XADC           | DCLK    | is_clock          | is_clock       |
#    | XADC           | DEN     | is_enable         | is_enable      |
#    | XADC           | RESET   | is_reset          | is_clear       |
#    +----------------+---------+-------------------+----------------+
catch {unset allcellrefs}
foreach pin_ref [lsort [array names propref]] {
  set props [list]
  set cellrefs [list]
  foreach el [lsort -unique $propref($pin_ref)] {
    foreach {prop cell_ref} $el { break }
    lappend props $prop
    lappend cellrefs $cell_ref
    if {![info exists allcellrefs($cell_ref:$pin_ref)]} { set allcellrefs($cell_ref:$pin_ref) [list] }
    if {[lsearch $allcellrefs($cell_ref:$pin_ref) $prop] == -1} {
      lappend allcellrefs($cell_ref:$pin_ref) $prop
    }
  }
  set props [lsort -unique $props]
  set cellrefs [lsort -unique $cellrefs]
  $tblProps addrow [list $pin_ref $props $cellrefs]
}
puts $channel [$tblProps print]
if {$saveTableCSV} {
  $tblProps export -format csv -file pinstats.by_pinref.csv
}
if {$destroyTables} { catch {$tblProps destroy} }

set tblCells [::tb::prettyTable "Properties per Cell Ref"]
$tblCells header {{Cell Ref} {Pin Ref} {Pin Properties} {Pin Lib Properties}}
$tblCells config -indent 2
set prevCellRef {}
foreach el [lsort -dictionary [array names allcellrefs]] {
  foreach {cell_ref pin_ref} [split $el :] { break }
  set props [lsort -unique $allcellrefs($el)]
  # Now, extract properties from the pin of the lib ref
  set libprops [list]
  set libpin [get_lib_pins [get_libs]/$cell_ref/$pin_ref]
  foreach p [list is_clear is_clock is_data is_enable is_setreset] {
    if {[get_property -quiet $p $libpin] == 1} {
      lappend libprops $p
    }
  }
  if {($prevCellRef != {}) && ($prevCellRef != $cell_ref)} {
    $tblCells separator
  }
  $tblCells addrow [list $cell_ref $pin_ref $props $libprops]
  set prevCellRef $cell_ref
}
puts $channel [$tblCells print]
if {$saveTableCSV} {
  $tblCells export -format csv -file pinstats.by_cellref.csv
}
# $tblCells export -format csv -file tblCells.csv
if {$destroyTables} { catch {$tblCells destroy} }

if {$FH != {}} {
  close $FH
  set FH {}
  puts " Report file [file normalize $filename]"
}

if {0} {

  ###############################################
  ##
  ## Example of used data structures
  ##
  ###############################################
  
  
  Vivado% parray cellref
  cellref(BUFR) = CLR
  
  Vivado% parray pinref
  pinref(CLR) = BUFR
  
  Vivado% parray propref
  propref(CE)      = {is_enable BUFR}
  propref(CE0)     = {is_enable BUFGCTRL}
  propref(CE1)     = {is_enable BUFGCTRL}
  propref(CLR)     = {is_reset BUFR}
  propref(I0)      = {is_clock BUFGCTRL}
  propref(I1)      = {is_clock BUFGCTRL}
  propref(IGNORE0) = {is_enable BUFGCTRL}
  propref(IGNORE1) = {is_enable BUFGCTRL}
  propref(S0)      = {is_enable BUFGCTRL}
  propref(S1)      = {is_enable BUFGCTRL}
  
  Vivado% parray allcellrefs
  allcellrefs(BUFGCTRL:CE0)     = is_enable
  allcellrefs(BUFGCTRL:CE1)     = is_enable
  allcellrefs(BUFGCTRL:I0)      = is_clock
  allcellrefs(BUFGCTRL:I1)      = is_clock
  allcellrefs(BUFGCTRL:IGNORE0) = is_enable
  allcellrefs(BUFGCTRL:IGNORE1) = is_enable
  allcellrefs(BUFGCTRL:S0)      = is_enable
  allcellrefs(BUFGCTRL:S1)      = is_enable
  allcellrefs(BUFR:CE)          = is_enable
  allcellrefs(BUFR:CLR)         = is_reset

}

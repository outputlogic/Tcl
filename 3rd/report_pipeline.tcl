# From John Blaine

# Folks,
# 
# The script that I have written is enhanced now. I think I have extracted some useful information and I am interested in what you think we should do with this information. 
# 
# Let me explain what the information is:
# 
# Section 1 is just a summary. It indicates how long primitive to primitive chains are. Note some primitives will be SRLs of longer delay length. Here you can figure out how many FFs you are dealing with approximately.
# 1) Primitive chain length summary:
# ==================================
# ---------------------------------------------------------------------
# LENGTH      2      3      4     5     6     7    8    9   10   11  12
# ---------------------------------------------------------------------
# No.     73591  29082  17259  8698  1014  1648  512  420  240  192  64
# ---------------------------------------------------------------------
# 
# 
# After this section you need to cross reference between tables using the pipeline_idx column.
# 
# Section 2: is description by ref_name. In brackets I have a control set reference, the same number indicates the same control set. Also I print a * for ASYNC_REG.
#  
#  
# 
# 
# 
# Section 3: This is a bounding box information. I can figure out if this pipeline is required to move me around the chip or if these should be local.
# BOUNDING_BOX is the full box covered by the paths.
# FIRST_LAST_BOUNDING_BOX is just the first and last FFs. Differences here show that I am routing for the hell of it. Wahey!
#  
# 
# 
# 
# Section 4: Displays the cell names. Allows me to bring the paths up in a schematic
#  
# 
# 
# Section 5: Displays the utilization of specific slice control sets.
#  
#  
# 
# 
# Runtime wise I processed this design in 50 mins. Also in this is a control set extraction proc which is quick and could be useful in other scenarios.
# 
# What I am interested in is how you think we could reuse this information to our advantage.
# 
# I was hoping to see that where I could make out large buses I would be able to: 
# i)	condense the packing – this seems to be pretty reasonable based on limited analysis
# ii)	merge SRLs with the same control set but the tools seem ok at this (based on limited analysis). Potentially we could convert things to use other primitives.
# 
# Sort of things we could use this for:
# i)	avoiding congested regions – fred mentioned there is a new placer algorithm coming that should do this. Maybe this script could help verify that.
# ii)	Identifying control set differences and retime. E.g, if I can put my 10407s together I have a simpler design to route potentially
#  
# 
# Anyway Im interested to hear your ideas. I could make tweaks if it is useful.
# 
# Thanks
# John

    proc print_table {Table_To_Print} {
        upvar $Table_To_Print P_TABLE

        # ------------------
        # Format settings
        # ------------------
        set P_TABLE(Print_Line_Numbers)     No

        # `````````````````````````````````````````````````````
        # Row Separations Characters
        # `````````````````````````````````````````````````````
        set P_TABLE(Row_Separator_Pre_Header_Line_Char)   "-"   ; #"="
        set P_TABLE(Row_Separator_Post_Header_Line_Char)  "-"   ; #"="
        set P_TABLE(Row_Separator_Inter_Row_Line_Char)    ""    ; #"-"
        set P_TABLE(Row_Separator_Post_Table_Line_Char)   "-"   ; #"="

        # `````````````````````````````````````````````````````
        # Column Separations Characters
        # `````````````````````````````````````````````````````
        set P_TABLE(Column_Separator_Pre_First_Column_Char)     ""    ; #"|"
        set P_TABLE(Column_Separator_Pre_First_Column_Spaces)   ""    ; #" "
        set P_TABLE(Column_Separator_Post_Last_Column_Char)     ""    ; #"|"
        set P_TABLE(Column_Separator_Post_Last_Column_Spaces)   ""    ; #" "
                                                                            
        set P_TABLE(Column_Separator_Inter_Column_Char)         ""    ; #"|"
        set P_TABLE(Column_Separator_Pre_Column_Spaces)         " "   ; #" "
        set P_TABLE(Column_Separator_Post_Column_Spaces)        " "   ; #" "


        # --------------------------------------------------------------------------
        # Check if columns alignment  was defined: left (-) or right (+)
        #   check if P_TABLE(${column_name},alignment) element exist in the array
        # If not, define default (left) column alignment for missing definition: 
        # --------------------------------------------------------------------------
        set list_of_elements [array names P_TABLE "*,alignment"]
        foreach column_name $P_TABLE(List_Of_Columns) {
            if { [lsearch $list_of_elements "${column_name},alignment"] == -1 } {
                set P_TABLE(${column_name},alignment) {-}
            }
        }


        # --------------------------------------------------------------------------
        # Add Column Names as row=0 to the P_TABLE
        # --------------------------------------------------------------------------
        foreach column_name $P_TABLE(List_Of_Columns) {
            set P_TABLE(0,${column_name}) $column_name
        }

        # --------------------------------------------------------------------------
        # Calculate the min size (# char) necessary to present data in each column
        # Store this information in P_TABLE(${column_name},column_min_width)
        # --------------------------------------------------------------------------

        # Init all column_min_width = 0
        # `````````````````````````````````````````````````````
        foreach column_name $P_TABLE(List_Of_Columns) {
            set P_TABLE(${column_name},column_min_width) 0
        }

        # Scan the entire table and calculate column_min_width
        # `````````````````````````````````````````````````````
        for {set i 0} {$i <= $P_TABLE(Nb_Of_Elements)} {incr i} {
            foreach column_name $P_TABLE(List_Of_Columns) {
                set current_value $P_TABLE(${i},${column_name})
                set P_TABLE(${column_name},column_min_width) [expr {max($P_TABLE(${column_name},column_min_width),[string length $current_value])}]
            }
        }

        # ------------------------------------------------------------------------------------
        # Print the final table to the TABLE_OUT variable
        #   1) Print the entire table without Row Separators first to the TABLE_OUT_TMP variable
        #       o) It will allow to have a compact code and 
        #       o) help to identify the final length of the row separators
        #          This is done after the 1st row is printed
        #   2) Copy TABLE_OUT_TMP to TABLE_OUT with adding Row Separators
        # -----------------------------------------------------------------------------------
        set TABLE_OUT_TMP ""
        set TABLE_OUT     ""

        set Nb_Of_Columns [llength $P_TABLE(List_Of_Columns)]



        # ``````````````````````````````````````````````````````````````````````````````````
        # Print the entire table without Row Separators first to the TABLE_OUT_TMP variable
        # ``````````````````````````````````````````````````````````````````````````````````
        for {set row_nb 0} {$row_nb <= $P_TABLE(Nb_Of_Elements)} {incr row_nb} {
            set column_nb 0

            foreach column_name $P_TABLE(List_Of_Columns) {
                incr column_nb
                set current_value             $P_TABLE(${row_nb},${column_name})
                set current_column_width      $P_TABLE(${column_name},column_min_width)
                set current_column_allignment $P_TABLE(${column_name},alignment)

                if {$column_nb == 1} {

                    append TABLE_OUT_TMP $P_TABLE(Column_Separator_Pre_First_Column_Char)
                    append TABLE_OUT_TMP $P_TABLE(Column_Separator_Pre_First_Column_Spaces)
                    append TABLE_OUT_TMP [format "%${current_column_allignment}${current_column_width}s" $current_value]
                    append TABLE_OUT_TMP $P_TABLE(Column_Separator_Post_Column_Spaces)
                    append TABLE_OUT_TMP $P_TABLE(Column_Separator_Inter_Column_Char)

                } elseif {$column_nb == $Nb_Of_Columns} {

                    append TABLE_OUT_TMP $P_TABLE(Column_Separator_Pre_Column_Spaces)
                    append TABLE_OUT_TMP [format "%${current_column_allignment}${current_column_width}s" $current_value]
                    append TABLE_OUT_TMP $P_TABLE(Column_Separator_Post_Last_Column_Spaces)
                    append TABLE_OUT_TMP $P_TABLE(Column_Separator_Post_Last_Column_Char)

                } else {

                    append TABLE_OUT_TMP $P_TABLE(Column_Separator_Pre_Column_Spaces)
                    append TABLE_OUT_TMP [format "%${current_column_allignment}${current_column_width}s" $current_value]
                    append TABLE_OUT_TMP $P_TABLE(Column_Separator_Post_Column_Spaces)
                    append TABLE_OUT_TMP $P_TABLE(Column_Separator_Inter_Column_Char)

                }
            }
            # ``````````````````````````````````````````````````````````````````````````````````
            # Calculate the Line Width
            # ``````````````````````````````````````````````````````````````````````````````````
            if {$row_nb == 0} {
                set Row_Length [string length $TABLE_OUT_TMP]
            }

            if {$row_nb != $P_TABLE(Nb_Of_Elements)} { append TABLE_OUT_TMP "\n" }
        }

    #return $TABLE_OUT_TMP
        # ``````````````````````````````````````````````````````````````````````````````````
        # Copy TABLE_OUT_TMP to TABLE_OUT with adding Row Separators
        # ``````````````````````````````````````````````````````````````````````````````````
        set TABLE_OUT_TMP [split $TABLE_OUT_TMP "\n"]
        
        set row_nb 0
        foreach current_row $TABLE_OUT_TMP {
            incr row_nb

            if {$row_nb == 1} {

                set row_separator [string repeat $P_TABLE(Row_Separator_Pre_Header_Line_Char) $Row_Length]
                if {[string length $row_separator] > 0} { append TABLE_OUT "${row_separator}\n" }

                append TABLE_OUT "${current_row}\n"

                set row_separator [string repeat $P_TABLE(Row_Separator_Post_Header_Line_Char) $Row_Length]
                if {[string length $row_separator] > 0} { append TABLE_OUT "${row_separator}\n" }

            } elseif {$row_nb == [expr $P_TABLE(Nb_Of_Elements) + 1]} {

                append TABLE_OUT "${current_row}\n"

                set row_separator [string repeat $P_TABLE(Row_Separator_Post_Table_Line_Char) $Row_Length]
                if {[string length $row_separator] > 0} { append TABLE_OUT "${row_separator}\n" }

            } else {

                append TABLE_OUT "${current_row}\n"

                set row_separator [string repeat $P_TABLE(Row_Separator_Inter_Row_Line_Char) $Row_Length]
                if {[string length $row_separator] > 0} { append TABLE_OUT "${row_separator}\n" }
            }
        }

        # ========================================
        # Return text representation of the table
        # ========================================
        return $TABLE_OUT
    }

    # set TABLE(List_Of_Columns) [list process cpu_runtime elapsed_runtime total_memory memory_gain]
    # set TABLE(Nb_Of_Elements) [incr n -1]


    proc print_report_header {fid} {
        puts $fid "####################################################################################################"
        puts $fid "#                                                                                                   "
        puts $fid "# COPYRIGHT NOTICE                                                                                  "
        puts $fid "# Copyright 2001-2013 Xilinx Inc. All Rights Reserved.                                              "
        puts $fid "# http://www.xilinx.com/support                                                                     "
        puts $fid "#                                                                                                   "
        puts $fid "[version]  \n"
        puts $fid "Design Name: [current_design]"
        puts $fid "Top        : [get_property TOP [current_design]]"
        puts $fid "Part       : [get_property PART [current_design]]"
        puts $fid "\n \n "
        puts $fid "####################################################################################################\n"
    }
    
proc open_file {fn} {
    if [catch {open $fn w} fid] {
        error "ERROR: Can not open file $fn"
    }
    return $fid
}

proc convert_to_time_format {seconds} {
# takes a time value formatted in vivado typical speak xx:xx:xx
# then returns a value that is number of seconds

    set error 0
    # Check validity of the seconds argument:
    # =======================================
    
    if {$error == 1} {
        puts "ERROR: There is $error error. Please correct it before continuing"
        return
    } elseif {$error != 0} {
        puts "ERROR: There are $error errors. Please correct then before continuing"
        return
    }
    
    set h [expr {$seconds/3600}]
    incr seconds [expr {$h*-3600}]
    set m [expr {$seconds/60}]
    set s [expr {$seconds%60}]
    return [format "%02.2d:%02.2d:%02.2d" $h $m $s]
}
   
proc ultrascale_ff_site_sort {bel_data} {
    upvar $bel_data BEL_DATA

    # sort into control set groups 
    # control set 0 AFF  BFF  CFF  DFF
    # control set 1 AFF2 BFF2 CFF2 DFF2
    # control set 2 EFF  FFF  GFF  HFF
    # control set 3 EFF2 FFF2 GFF2 HFF2
    foreach site $BEL_DATA(used_sites) {
        for {set i 0} {$i < 4} {incr i} {
            set BEL_DATA($site,group${i},used%) 0.0
        }
        set BEL_DATA($site,all_groups,used%) 0.0
        set BEL_DATA($site,groups0_1,used%) 0.0
        set BEL_DATA($site,groups2_3,used%) 0.0
        foreach bel $BEL_DATA($site) {
            switch -exact --  $bel {
                AFF  {lappend BEL_DATA($site,group0) AFF ; set BEL_DATA($site,group0,used%) [expr $BEL_DATA($site,group0,used%) + 25.0]; set BEL_DATA($site,groups0_1,used%) [expr $BEL_DATA($site,groups0_1,used%) + 12.5]}
                AFF2 {lappend BEL_DATA($site,group1) AFF2; set BEL_DATA($site,group1,used%) [expr $BEL_DATA($site,group1,used%) + 25.0]; set BEL_DATA($site,groups0_1,used%) [expr $BEL_DATA($site,groups0_1,used%) + 12.5]}
                BFF  {lappend BEL_DATA($site,group0) BFF ; set BEL_DATA($site,group0,used%) [expr $BEL_DATA($site,group0,used%) + 25.0]; set BEL_DATA($site,groups0_1,used%) [expr $BEL_DATA($site,groups0_1,used%) + 12.5]}
                BFF2 {lappend BEL_DATA($site,group1) BFF2; set BEL_DATA($site,group1,used%) [expr $BEL_DATA($site,group1,used%) + 25.0]; set BEL_DATA($site,groups0_1,used%) [expr $BEL_DATA($site,groups0_1,used%) + 12.5]}
                CFF  {lappend BEL_DATA($site,group0) CFF ; set BEL_DATA($site,group0,used%) [expr $BEL_DATA($site,group0,used%) + 25.0]; set BEL_DATA($site,groups0_1,used%) [expr $BEL_DATA($site,groups0_1,used%) + 12.5]}
                CFF2 {lappend BEL_DATA($site,group1) CFF2; set BEL_DATA($site,group1,used%) [expr $BEL_DATA($site,group1,used%) + 25.0]; set BEL_DATA($site,groups0_1,used%) [expr $BEL_DATA($site,groups0_1,used%) + 12.5]}
                DFF  {lappend BEL_DATA($site,group0) DFF ; set BEL_DATA($site,group0,used%) [expr $BEL_DATA($site,group0,used%) + 25.0]; set BEL_DATA($site,groups0_1,used%) [expr $BEL_DATA($site,groups0_1,used%) + 12.5]}
                DFF2 {lappend BEL_DATA($site,group1) DFF2; set BEL_DATA($site,group1,used%) [expr $BEL_DATA($site,group1,used%) + 25.0]; set BEL_DATA($site,groups0_1,used%) [expr $BEL_DATA($site,groups0_1,used%) + 12.5]}
                EFF  {lappend BEL_DATA($site,group2) EFF ; set BEL_DATA($site,group2,used%) [expr $BEL_DATA($site,group2,used%) + 25.0]; set BEL_DATA($site,groups2_3,used%) [expr $BEL_DATA($site,groups2_3,used%) + 12.5]}
                EFF2 {lappend BEL_DATA($site,group3) EFF2; set BEL_DATA($site,group3,used%) [expr $BEL_DATA($site,group3,used%) + 25.0]; set BEL_DATA($site,groups2_3,used%) [expr $BEL_DATA($site,groups2_3,used%) + 12.5]}
                FFF  {lappend BEL_DATA($site,group2) FFF ; set BEL_DATA($site,group2,used%) [expr $BEL_DATA($site,group2,used%) + 25.0]; set BEL_DATA($site,groups2_3,used%) [expr $BEL_DATA($site,groups2_3,used%) + 12.5]}
                FFF2 {lappend BEL_DATA($site,group3) FFF2; set BEL_DATA($site,group3,used%) [expr $BEL_DATA($site,group3,used%) + 25.0]; set BEL_DATA($site,groups2_3,used%) [expr $BEL_DATA($site,groups2_3,used%) + 12.5]}
                GFF  {lappend BEL_DATA($site,group2) GFF ; set BEL_DATA($site,group2,used%) [expr $BEL_DATA($site,group2,used%) + 25.0]; set BEL_DATA($site,groups2_3,used%) [expr $BEL_DATA($site,groups2_3,used%) + 12.5]}
                GFF2 {lappend BEL_DATA($site,group3) GFF2; set BEL_DATA($site,group3,used%) [expr $BEL_DATA($site,group3,used%) + 25.0]; set BEL_DATA($site,groups2_3,used%) [expr $BEL_DATA($site,groups2_3,used%) + 12.5]}
                HFF  {lappend BEL_DATA($site,group2) HFF ; set BEL_DATA($site,group2,used%) [expr $BEL_DATA($site,group2,used%) + 25.0]; set BEL_DATA($site,groups2_3,used%) [expr $BEL_DATA($site,groups2_3,used%) + 12.5]}
                HFF2 {lappend BEL_DATA($site,group3) HFF2; set BEL_DATA($site,group3,used%) [expr $BEL_DATA($site,group3,used%) + 25.0]; set BEL_DATA($site,groups2_3,used%) [expr $BEL_DATA($site,groups2_3,used%) + 12.5]}
            }
            set BEL_DATA($site,all_groups,used%) [expr $BEL_DATA($site,all_groups,used%) + 6.25]
        }
    }
}



proc report_ff_site_usage {bel_data} {
    # ultrascale only:
    # ================
    # DATA RETURNED:
    # ==============
    # bel_data(used_sites)              - all used sites 
    # bel_data(SLICE_X0Y0)              - a list of bels in use at this site
    # bel_data($site,group0)            - A list of used sites at a give bel for a particular control set group. For ultrascale groups 0-3
    # bel_data($site,group0,used%)      - % of used sites in this group
    # bel_data($site,all_groups_used,%) - % of all FFs used at this site
    
    upvar $bel_data BEL_DATA
    set start [clock seconds]
    set all_used_ff_bels [get_property NAME [get_bels -quiet -filter {IS_USED&&NAME=~*FF*}]]
    foreach used_bel $all_used_ff_bels {
        set tmp [split $used_bel /]
        set site [lindex $tmp 0]
        set bel  [lindex $tmp 1]
        lappend BEL_DATA(used_sites) $site
        lappend BEL_DATA($site) $bel
    }    
    set BEL_DATA(used_sites) [lsort -unique $BEL_DATA(used_sites)]
    puts "INFO: There are [llength $BEL_DATA(used_sites)] used sites in this design."
    #parray BEL_DATA
    ultrascale_ff_site_sort BEL_DATA
    
    #parray BEL_DATA
    set stop [clock seconds]
    puts "report_ff_site_usage: Time(s): [convert_to_time_format [expr $stop-$start]]"
}

proc get_control_sets {dat {cells ""}} {
    set start [clock seconds]
    upvar $dat CONTROLSET
    if {$cells eq ""} {
        set control_set_info [report_control_sets -quiet -verbose -return_string]
    } else {
        set control_set_info [report_control_sets -quiet -verbose -return_string -cell $cells]
    }
    set control_set_info_lines [split $control_set_info \n]
    # line 51 is the first line with information we are looking for
    set searchable_text [lrange $control_set_info_lines 50 end]
    # initialize
    foreach item [list clk enable reset] {
        set CONTROLSET($item) ""
        set CONTROLSET($item,count) 0
    }
    set number_of_lines_processed 0
    set all_cells ""
    
    # Search through each control set in the control set report
    foreach info_line $searchable_text {
        # the last line that is in our searchable area starts with a +
        if {[string index $info_line 0] eq "+"} {
            break
        } 
        
        # for each group, remove leading space, anywhere where there is no signal, we create a 0
        set tmp ""
        foreach t [lrange [split $info_line \|] 1 end-1] {
            set t [regsub -all {\s+} $t {}]
            if {$t eq ""} { set t 0 }
            lappend tmp $t
        }
        
        
        set i 0
        # create an index for all control sets
        set CONTROLSET($number_of_lines_processed) [list [lindex $tmp 0] [lindex $tmp 1] [lindex $tmp 2]]
        # create a searchable space for all control sets
        # NOTE: Lists must be formed correctly for this search to work
        lappend CONTROLSET(all_control_sets) $CONTROLSET($number_of_lines_processed)
        # create a list to process the loads foreach net. This list is processed below.
        foreach item [list clk enable reset] {
            set net_name [lindex $tmp $i]
            if {$net_name != 0} {
                lappend CONTROLSET($item)  [lindex $tmp $i]
            }
            incr i
        }
        incr number_of_lines_processed
    }
    set CONTROLSET(total) $number_of_lines_processed
    #puts "INFO: Total number of lines $number_of_lines_processed"
  
    # foreach net we get the leaf cells that are connected to each input pin on that is a clock or enable net.
    # We then process this information to create a cell list that we can look up to determine the control set information.
    # If something is zero then it is not populated.
    # List of all cells is based on cells connected to clock nets.
    foreach item [list clk enable reset] {
      set CONTROLSET($item) [lsort -unique $CONTROLSET($item)]
      puts "INFO: There are [llength $CONTROLSET($item)] unique ${item}s"
      foreach net $CONTROLSET($item) {
        switch -exact -- $item {
            clk    {    if {[string index $net 0] eq "~"} {
                            set net_tmp [string range $net 1 end]; 
                            set cell_name [get_property NAME [get_cells -quiet -of [get_pins -quiet -leaf -of [get_nets -quiet $net_tmp] -filter {IS_CLOCK}] -filter {IS_C_INVERTED==1'b1} ]] 
                        }  else {
                            set cell_name [get_property NAME [get_cells -quiet -of [get_pins -quiet -leaf -of [get_nets -quiet $net] -filter {IS_CLOCK}]]]
                        }
                   }
            enable {set cell_name [get_property NAME [get_cells -quiet -of [get_pins -quiet -leaf -of [get_nets -quiet $net] -filter {IS_ENABLE}]]]} 
            reset  {set cell_name [get_property NAME [get_cells -quiet -of [get_pins -quiet -leaf -of [get_nets -quiet $net] -filter {IS_RESET||IS_CLEAR||IS_PRESET||IS_SET||IS_SETRESET}]]]}
        }
        foreach cell $cell_name {
            set CONTROLSET($cell,$item) $net
            incr CONTROLSET($item,count)
            if {$item eq "clk"} {
                lappend all_cells $cell
            }
        }
      }
    }
    
    # Insert here special case to deal with clocks that are grounded or tied to Vcc. These registers show up as errors when they are not seen by control sets.
    set grounded_ffs [get_cells -quiet -of [get_pins -quiet -of [get_nets -quiet -of [get_pins -quiet -hier -filter {IS_CLOCK}] -filter {TYPE==GROUND}] -filter {IS_CLOCK}]]
    set CONTROLSET(grounded_ffs) [llength $grounded_ffs]
    foreach cell $grounded_ffs {
        set CONTROLSET($cell,clk) 0
        incr CONTROLSET(clk,count)
        lappend all_cells $cell
    }
    
    # Next for each cell we need to assign a control set group number. We need to build the control set information from the information we have just gathered
    # Then where the reset and enable do not exist we search for 0's
    set CONTROLSET(all_control_sets) [lsort -unique $CONTROLSET(all_control_sets)]
    foreach cell $all_cells {
        set search $CONTROLSET($cell,clk)
        foreach item [list enable reset] {
            if {[info exists CONTROLSET($cell,$item)] == 1} {
                # debug
                # if {[string index $CONTROLSET($cell,$item) 0] eq "\{"} {
                #     set CONTROLSET($cell,$item) [string range $CONTROLSET($cell,$item) 1 end-1]
                # }
                lappend search $CONTROLSET($cell,$item)
            } else {
                #puts "DEBUG0: cell $cell: $item not found"
                lappend search 0
            }
        }
        # temp debug
        #if {[lsearch -exact $CONTROLSET(all_control_sets) $search] ==-1} {
            #puts "DEBUG1: $search"
            #puts "DEBUG2: $CONTROLSET(all_control_sets)"
        #}
        # end of temp debug
        set CONTROLSET($cell,control_set_group_num) [lsearch -sorted -exact $CONTROLSET(all_control_sets) $search] 
    }
  
    puts "INFO: Processed a total of $CONTROLSET(total) control sets"
    puts "INFO: Identified control sets for $CONTROLSET(clk,count) cells"
    puts "INFO: Identified $CONTROLSET(grounded_ffs) cells that have clock connected to ground"
    set stop [clock seconds]
    puts "get_control_sets: Time(s): [convert_to_time_format [expr $stop-$start]]"
}
    
proc find_backwards {dat idx} {
     upvar $dat DAT
     if {[lsearch -exact -integer $DAT(all_used_idxs) $idx] == -1} { 
        # this is a new chain or not yet recognised as part of an old one
        set DAT(existing_pipe) 0
        lappend DAT(all_used_idxs) $idx
        lappend DAT(all_ffs) [lindex $DAT(pipeFFs_dest) $idx]
        set pipe_idx $DAT(all_ffs,idx)
        set DAT(tmp_pipeline) "$pipe_idx $DAT(tmp_pipeline)"
        incr DAT(all_ffs,idx)
        # Next find the previous element in a chain
        set src_reg [lindex $DAT(pipeFFs_src) $idx]
        if {[set tmp_idx [lsearch -sorted -exact $DAT(pipeFFs_dest) $src_reg]] !=-1} {
            find_backwards DAT $tmp_idx
        } else {
            # This is the start of a chain
            lappend DAT(all_ffs) $src_reg
            set pipe_idx $DAT(all_ffs,idx)
            set DAT(tmp_pipeline) "$pipe_idx $DAT(tmp_pipeline)"
            incr DAT(all_ffs,idx)
        }
     } else {
        # pipe FF is already part of another chain
        set DAT(existing_pipe) 1
        #set DAT(tmp_pipe_idx) $idx
        set tmp_ff [lindex $DAT(pipeFFs_dest) $idx]
        set DAT(tmp_pipe_idx) [lsearch -exact $DAT(all_ffs) $tmp_ff]        
     }
     return
}

proc report_ff_chain_length {dat {fid stdout}} {
    upvar $dat DAT
    set num $DAT(number_of_pipechains)
    set pipe_num 1
    while {$pipe_num <= $num} {
        set length [llength $DAT($pipe_num,pipeline_idx)]
        if {[lsearch $DAT(pipeline_lengths) $length] == -1} {
            lappend DAT(pipeline_lengths) $length
        }
        incr DAT(pipeline_lengths,$length)
        lappend DAT(pipeline_lengths,$length,pipeline_num) $pipe_num
        incr TABLE(1,$length)
        incr pipe_num
    }
    # set TABLE(List_Of_Columns) [list process cpu_runtime elapsed_runtime total_memory memory_gain]
    # set TABLE(Nb_Of_Elements) [incr n -1]
    set TABLE(List_Of_Columns) "LENGTH [lsort -integer $DAT(pipeline_lengths)]"
    foreach tmp $DAT(pipeline_lengths) {
        set TABLE($tmp,alignment) "+"
    }
    set TABLE(1,LENGTH) "No."
    set TABLE(Nb_Of_Elements) 1
    # parray TABLE
    set tmp [print_table TABLE]
    puts $fid "\n1) Primitive chain length summary:"
    puts $fid "=================================="
    puts $fid $tmp
    return
} 


proc report_ff_chains_primitives {dat site min_chain_length {fid stdout}} {
    upvar $dat  DAT
    upvar $site SITE
    
    # get control set information
    set CS(tmp) ""
    get_control_sets CS
    
    set i 1
    foreach length [lsort -integer $DAT(pipeline_lengths)] {
        if {$length >= $min_chain_length} {
            foreach pipe_num $DAT(pipeline_lengths,$length,pipeline_num) {
                set TABLE1($i,PIPELINE_IDX) $pipe_num
                set TABLE2($i,PIPELINE_IDX) $pipe_num
                set TABLE3($i,PIPELINE_IDX) $pipe_num
                set TABLE4($i,PIPELINE_IDX) $pipe_num
                set TABLE1($i,LENGTH) $length
                set TABLE2($i,LENGTH) $length
                set TABLE3($i,LENGTH) $length
                set TABLE4($i,LENGTH) $length
                set idxs $DAT($pipe_num,pipeline_idx)
                set XRANGE ""
                set YRANGE ""
                foreach idx $idxs {
                    # First generate REF_NAME part for table 1
                    set ref_cell [lindex $DAT(all_ffs,REF_NAME) $idx]
                    set cell_name [lindex $DAT(all_ffs) $idx]                                        
                    set enable_group $CS($cell_name,control_set_group_num)
                    if {[lindex $DAT(all_ffs,ASYNC_REG) $idx] == 1} {
                        set ref_cell ${ref_cell}*
                    }
                    set ref_cell "${ref_cell}\(${enable_group}\)"                    
                    lappend DAT(pipeline,$pipe_num,REF_NAME) $ref_cell
                    
                    # Second generate location information for table 2
                    set loc [lindex $DAT(all_ffs,LOC) $idx]
                    set loc_temp [string range $loc 6 end]
                    set re [regexp {X([0-9]+)Y([0-9]+)} $loc_temp match X Y]
                    lappend XRANGE $X
                    lappend YRANGE $Y
                        # format is SLICEL.AFF. Just want last bel info
                    set bel [lindex [split [lindex $DAT(all_ffs,BEL) $idx] .] 1]
                    switch -exact -- $bel {
                        AFF  {set group group0}
                        AFF2 {set group group1}
                        BFF  {set group group0}
                        BFF2 {set group group1}
                        CFF  {set group group0}
                        CFF2 {set group group1}
                        DFF  {set group group0}
                        DFF2 {set group group1}
                        EFF  {set group group2}
                        EFF2 {set group group3}
                        FFF  {set group group2}
                        FFF2 {set group group3}
                        GFF  {set group group2}
                        GFF2 {set group group3}
                        HFF  {set group group2}
                        HFF2 {set group group3}
                        default {set group -1}
                    }
                    lappend DAT(pipeline,$pipe_num,LOCS) $loc_temp
                    if {$group != -1} {
                        set group_used $SITE($loc,$group,used%)
                        set total_used $SITE($loc,all_groups,used%)
                        set loc_temp "${loc_temp} \(${total_used}%,${group_used}%\)"
                    }
                    lappend DAT(pipeline,$pipe_num,LOCS_DETAIL) $loc_temp
                    # Third generate naming information for table 3
                    lappend DAT(pipeline,$pipe_num,NAME) [lindex $DAT(all_ffs) $idx]
                }
                set FIRST_XRANGE [lindex $XRANGE 0]
                set FIRST_YRANGE [lindex $YRANGE 0]
                set LAST_XRANGE [lindex $XRANGE end]
                set LAST_YRANGE [lindex $YRANGE end]                
                set XRANGE [lsort -integer $XRANGE]
                set YRANGE [lsort -integer $YRANGE]
                
                set TABLE1($i,REF_CELLS) [join $DAT(pipeline,$pipe_num,REF_NAME) " -> "]
                set TABLE2($i,LOCS) [join $DAT(pipeline,$pipe_num,LOCS) " -> "]
                set TABLE2($i,BOUNDING_BOX) "\[X[lindex $XRANGE 0]Y[lindex $YRANGE 0] -> X[lindex $XRANGE end]Y[lindex $YRANGE end]\]"
                set TABLE2($i,FIRST_LAST_BOX) "\[X${FIRST_XRANGE}Y${FIRST_YRANGE} -> X${LAST_XRANGE}Y${LAST_YRANGE}\]"
                set TABLE3($i,CELLS) "\[get_cells \[list $DAT(pipeline,$pipe_num,NAME) \]\]"
                set TABLE4($i,LOCS) [join $DAT(pipeline,$pipe_num,LOCS_DETAIL) " -> "]
                incr i
            }
        }
    }
    
    set TABLE1(List_Of_Columns) [list LENGTH PIPELINE_IDX REF_CELLS]
    set TABLE1(Nb_Of_Elements) [expr $i -1]
    set tmp [print_table TABLE1]
    puts $fid "\n2) Verbose chain description by ref_name:"
    puts $fid "==========================================="
    puts $fid "INFO: Min chain length reported here is $min_chain_length"
    puts -nonewline $fid $tmp
    puts $fid "*     - Indicates presence of ASYNC_REG constraint on cell"
    puts $fid "(num) - Indicates a unique control set identifier. -1 indicates an error with this feature.\n"
    
    set TABLE2(List_Of_Columns) [list LENGTH PIPELINE_IDX BOUNDING_BOX FIRST_LAST_BOX LOCS]
    set TABLE2(Nb_Of_Elements) [expr $i -1]
    set tmp [print_table TABLE2]
    puts $fid "\n3) Verbose chain description by site location:"
    puts $fid "==============================================="
    puts $fid "INFO: Min chain length reported here is $min_chain_length"
    puts $fid $tmp
    
    set TABLE3(List_Of_Columns) [list LENGTH PIPELINE_IDX CELLS]
    set TABLE3(Nb_Of_Elements) [expr $i -1]
    set tmp [print_table TABLE3]
    puts $fid "\n4) Verbose chain description by cell name:"
    puts $fid "============================================"
    puts $fid "INFO: Min chain length reported here is $min_chain_length"
    puts -nonewline $fid $tmp 
        
    set TABLE4(List_Of_Columns) [list LENGTH PIPELINE_IDX LOCS]
    set TABLE4(Nb_Of_Elements) [expr $i -1]
    set tmp [print_table TABLE4]
    puts $fid "\n5) Verbose chain description by site location including site usage stats:"
    puts $fid "========================================================================="
    puts $fid "INFO: Min chain length reported here is $min_chain_length"
    puts -nonewline $fid $tmp
    puts $fid "(<num1>%,<num2>%) - num1 indicates total FFs used in this slice. num2 indicates total used in this control set\n"
           
    return    
}

proc report_pipeline {args} {
  set start [clock seconds]
  set help_message {\
report_pipeline

Description: 
Analyses a post synthesis netlist to check for high number of FF->>FF chains.
This is useful for identifying if a design is over registered.

Syntax: 
report_pipeline [-file <arg>] [-verbose] [-min_chain_length <arg>]
 
 Returns:
 Report
    
 Usage:
  Name                         Description
  ----------------------------------------
  [-file]                      Filename to output results to. (send output to
                               console if -file is not used)
  [-verbose]                   Provide more detailed path information.
  [-min_chain_length]          Only report on chains as long as or longer than
                               min_chain_length. Default is 4
}
    
    # defaults
   set min_chain_length 4
   set fid stdout
   set op_file 0
   set verbose 0
   
   for {set i 0} {$i < [llength $args]} {incr i} {
      set switch_arg [lindex $args $i]
      switch -- $switch_arg {
         -file             { incr i; set fn [lindex $args $i]; set fid [open_file $fn]; set op_file 1} 
         -verbose          { set verbose 1}
         -min_chain_length { incr i; set min_chain_length [lindex $args $i]}
         -help             { puts $help_message; return }
      }
   }  
    
    set FF_D_pins_fed_by_Q [lsort [get_pins -quiet -leaf -of [get_nets -quiet -of [get_pins -quiet -hier -filter {REF_PIN_NAME==Q}] -filter {FLAT_PIN_COUNT==2}] -filter {REF_PIN_NAME==D}]]
    set FF_Q_pins_fed_by_D [get_pins -quiet -leaf -of [get_nets -quiet -of $FF_D_pins_fed_by_Q] -filter {DIRECTION==OUT}]

    set DAT(pipeFFs_dest)          [get_cells -quiet -of $FF_D_pins_fed_by_Q]
    set DAT(pipeFFs_src)           [get_cells -quiet -of $FF_Q_pins_fed_by_D]
    set DAT(pipeFFs_dest)          [get_property NAME $DAT(pipeFFs_dest)]
    set DAT(pipeFFs_src)           [get_property NAME $DAT(pipeFFs_src) ]
    
    set DAT(number_of_pipechains) 0; 
    set DAT(all_used_idxs) ""
    set DAT(pipeline_lengths) ""
    set idx 0
    set DAT(all_ffs,idx) 0 
    set SITE(tmp) ""    
    # DAT INFO:
    # =========
    # This describes the information of the DAT data array
    # DAT(number_of_pipechains)                     This is the total number of pipelines
    # DAT($idx,pipeline)                            This allows us to find out what pipeline the idx belongs to
    # DAT(all_ffs,REF_NAME)                         This is an index of REFs that is aligned with the DAT(all_ffs)
    # DAT($pipe_num,pipeline_idx)                   This is the indexes from DAT(all_ffs) in a given pipeline $pipe_num
    # DAT(pipeline_lengths)                         This is a list of the primitive lengths
    # DAT(pipeline_lengths,$length)                 Integer number showing the number of paths for a given $length e.g, 4 paths with 8 primitives ($length) in it
    # DAT(pipeline_lengths,$length,pipeline_num)    This is what pipelines have a primitive length of $length
    #

    foreach FF $DAT(pipeFFs_dest) {
        set DAT(tmp_pipeline) ""
        #set DAT(cell) $FF
        find_backwards DAT $idx
        if {$DAT(existing_pipe)==0} {
            # Generate data for a new pipeline
            incr DAT(number_of_pipechains)
            set pipe_num $DAT(number_of_pipechains)
            set DAT($pipe_num,pipeline_idx) $DAT(tmp_pipeline)
        } else {
            # Append data to an existing pipeline
            set idx_ff_to_connect_to $DAT(tmp_pipe_idx)
            set pipe_num $DAT($idx_ff_to_connect_to,pipeline)
            foreach tmp_idx $DAT(tmp_pipeline) {
                #puts "DEBUG: Appended pipelines $pipe_num"
                lappend DAT($pipe_num,pipeline_idx) $tmp_idx
            }
        }
        
        foreach tmp_idx $DAT(tmp_pipeline) {
           set DAT($tmp_idx,pipeline) $pipe_num
        }
        incr idx
     }
     
     puts "INFO: Register chain analysis is completed."
     puts "INFO: Total FFs in chains is [llength $DAT(all_ffs)]"

     print_report_header $fid
     report_ff_chain_length DAT $fid
     if {$verbose==1} {
        set DAT(all_ffs,REF_NAME)  [get_property REF_NAME [get_cells -quiet $DAT(all_ffs)]]
        set DAT(all_ffs,ASYNC_REG) [get_property ASYNC_REG [get_cells -quiet $DAT(all_ffs)]]
        set DAT(all_ffs,BEL)       [get_property BEL [get_cells -quiet $DAT(all_ffs)]]
        set DAT(all_ffs,LOC)       [get_property LOC [get_cells -quiet $DAT(all_ffs)]]
        report_ff_site_usage SITE
        report_ff_chains_primitives DAT SITE $min_chain_length $fid
     }
     #parray DAT
     
     # close a file if we have opened it.
     if {$op_file == 1} {
        close $fid
     }
     set stop [clock seconds]
     puts "report_pipeline: Time(s): [convert_to_time_format [expr $stop-$start]]"
}



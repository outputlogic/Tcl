####################################################################################################
# HEADER_BEGIN
# COPYRIGHT NOTICE
# Copyright 2001-2014 Xilinx Inc. All Rights Reserved.
# http://www.xilinx.com/support
# HEADER_END
####################################################################################################

########################################################################################
##
## Company:        Xilinx, Inc.
## Created by:     David Pefourque
##
## Version:        2014.07.11
## Tool Version:   Vivado 2014.1
## Description:    Plugin for snapshot_core.tcl to export database to directory
##
########################################################################################

########################################################################################
## 2014.07.11 - Reformated info message to number the snapshot being exported 
## 2014.06.24 - Added support to -top_metrics/-default_top_metrics to expose a 
##              list of snapshot metrics to the index page (-html only)
##            - Changed: snapshot HTML / metric files not overriden when already exist
##              on the file system unless -force is used
## 2014.06.03 - Splited from original snapshot.tcl
##            - Other enhancements and fixes
##            - Initial release
########################################################################################

if {[info exists DEBUG]} { puts " Sourcing [file normalize [info script]]" }

namespace eval ::tb::snapshot::db2dir {}

#------------------------------------------------------------------------
# ::tb::snapshot::method:db2dir
#------------------------------------------------------------------------
# Usage: snapshot db2dir [<options>]
#------------------------------------------------------------------------
# Export database to directory
#------------------------------------------------------------------------
proc ::tb::snapshot::method:db2dir { args } {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Export database to directory (-help)
  return [uplevel [concat ::tb::snapshot::db2dir $args]]
}

#------------------------------------------------------------------------
# ::tb::snapshot::db2dir
#------------------------------------------------------------------------
# Usage: ::tb::snapshot::db2dir [<options>]
#------------------------------------------------------------------------
# Export database to directory
#------------------------------------------------------------------------
proc ::tb::snapshot::db2dir {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable summary
  variable params
  variable verbose
  variable debug
  # Save current state of verbosity & debug
  set _verbose_ $verbose
  set _debug_ $debug
  set db [getDB]
  set allsnapshotids {}
  set project {%}
  set run {%}
  set version {%}
  set experiment {%}
  set step {%}
  set release {%}
  set exportDir {}
  set exportFormat {}
  set directoryExpr {}
  set filenameExpr {%id.%project.%version.%experiment.%step.%metricname}
  set metricExpr {%metricname}
  set saveHtml 0
  set saveFragment 0
  set writeMetricFiles 1
  set indexFH {}
  set snapshotFH {}
  set metrics {}
  set topMetrics {} ; # List of metrics to be exposed to the index.html page
  set force 0
  set reset 0
  set error 0
  set help 0
#   if {[llength $args] == 0} {
#     set help 1
#   }
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -db {
        set db [lshift args]
      }
      -dir -
      -directory {
#         set exportDir [lshift args]
        set exportDir [file normalize [lshift args]]
      }
      -force {
        set force 1
      }
      -fileexpr {
        set filenameExpr [lshift args]
      }
      -direxpr {
        set directoryExpr [lshift args]
      }
      -metricexpr {
        set metricExpr [lshift args]
      }
      -format {
        set exportFormat [lshift args]
      }
      -frag -
      -fragment {
        set saveFragment 1
      }
      -html {
        set saveHtml 1
      }
      -index -
      -index_only {
        set writeMetricFiles 0
      }
      -m -
      -metrics {
        set metrics [concat $metrics [lshift args]]
      }
      -top -
      -top_metric -
      -top_metrics {
        set topMetrics [concat $topMetrics [lshift args]]
      }
      -default_top -
      -default_top_metric -
      -default_top_metrics {
        set topMetrics [concat $topMetrics [list report.route_status.errors=#Overlaps \
                                                 report.timing_summary.wns=WNS \
                                                 report.timing_summary.tns=TNS \
                                                 report.timing_summary.tns.failing=#TNS \
                                                 report.timing_summary.whs=WHS \
                                                 report.timing_summary.ths=THS \
                                                 report.timing_summary.ths.failing=#THS ] ]
      }
      -id {
        set allsnapshotids [concat $allsnapshotids [split [lshift args] ,]]
      }
      -p -
      -project {
        set project [lshift args]
      }
      -r -
      -run {
        set run [lshift args]
      }
      -ver -
      -version {
        set version [lshift args]
      }
      -e -
      -experiment {
        set experiment [lshift args]
      }
      -s -
      -step {
        set step [lshift args]
      }
      -rel -
      -release -
      -vivado {
           set release [lshift args]
      }
      -verbose {
        ::tb::snapshot::method:configure -verbose
      }
      -quiet {
        ::tb::snapshot::method:configure -quiet
      }
      -debug {
        ::tb::snapshot::method:configure -debug
      }
      -nodebug {
        ::tb::snapshot::method:configure -nodebug
      }
      -h -
      -help {
           set help 1
      }
      default {
            if {[string match "-*" $name]} {
              print error "option '$name' is not a valid option."
              incr error
            } else {
              print error "option '$name' is not a valid option."
              incr error
            }
      }
    }
  }

  if {$help} {
    print stdout [format {
  Usage: ::tb::snapshot::db2dir
              -dir <directory>
              [-db <filename>]
              [-top_metrics <list_metrics>][-default_top_metrics]
              [-metrics <list_metrics>]
              [-id <list_snapshot_ids>]
              [-project|-p <string>]
              [-release|-rel <string>]
              [-version|-ver <string>]
              [-experiment|-e <string>]
              [-step|-s <string>]
              [-run|-r <string>]
              [-format flat|hier1|hier2|hier3]
              [-direxpr <string>]
              [-fileexpr <string>]
              [-metricexpr <string>]
              [-html|-fragment]
              [-index|-index_only]
              [-force]
              [-verbose|-quiet]
              [-help|-h]

  Description: Export a database to a directory

    Supported parameters for -fileexpr/-direxpr: %%id, %%project, %%version, %%experiment, %%step, %%release, %%metricname

    Option -format overrides options -fileexpr/-direxpr

  Example:
     snapshot db2dir
     snapshot db2dir -db ./metrics.db -dir /my/export/dir -force -metrics {metric1 metric2 ... metricN}
     snapshot db2dir -experiment {No%%Buffer%%} -dir .
} ]
    # HELP -->
    set verbose $_verbose_
    set debug $_debug_
    return -code ok
  }

  if {![file exists $db]} {
    print error "Database '$db' does not exist"
    incr error
  }

  if {$exportDir == {}} {
    print error "Use -dir to define the export directory"
    incr error
  }

  if {![file isdirectory $exportDir]} {
    if {!$force} {
      print error "Directory '$exportDir' does not exist (use -force to create directory)"
      incr error
    } else {
      file mkdir $exportDir
    }
  }

  if {!$saveHtml && [llength $topMetrics]} {
    print error "-top_metrics can only be used with -html"
    incr error
  }

  if {!$saveHtml && !$writeMetricFiles} {
    print error "-index_only can only be used with -html"
    incr error
  }

  if {$saveHtml && $saveFragment} {
    print error "-fragment & -html cannot be used together"
    incr error
  }

  switch $exportFormat {
    {} {
    }
    flat {
      set directoryExpr {}
      set filenameExpr {%id.%project.%version.%experiment.%step.%metricname}
    }
    hier1 {
      set directoryExpr {%project.%version.%experiment}
      set filenameExpr {%id.%step.%metricname}
    }
    hier2 {
      set directoryExpr {%project.%version.%experiment.%step}
      set filenameExpr {%id.%metricname}
    }
    hier3 {
      set directoryExpr {%project.%version.%experiment/%step}
      set filenameExpr {%id.%metricname}
    }
    hier4 {
      set directoryExpr {%project/%version/%experiment/%step}
      set filenameExpr {%metricname}
    }
    default {
      print error "Format '$exportFormat' is not valid"
      incr error
    }
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  if {$verbose} {
    print info "<<<<<<<<<<<<<<<< db2dir <<<<<<<<<<<<<<<<"
    print info "Database: $db"
  }
  sqlite3 SQL $db -readonly true
  execSQL SQL { pragma integrity_check }
  set dbVersion [execSQL SQL { SELECT value FROM param WHERE property='version' LIMIT 1; } ]
  if {$verbose} {
    print info "Database version: $dbVersion"
    print info "Export started on [clock format [clock seconds]]"
  }

  if {$allsnapshotids == {}} {
    set allsnapshotids [lsort [execSQL SQL "SELECT id FROM snapshot WHERE (enabled == 1)" ]]
#     puts "<allsnapshotids:$allsnapshotids>"
  } else {
    set L $allsnapshotids
    set allsnapshotids [list]
    foreach elm $L {
      if {[regexp {^[0-9]+$} $elm]} {
        lappend allsnapshotids $elm
      } elseif {[regexp {^([0-9]+)\-([0-9]+)$} $elm - n1 n2]} {
        if {$n1 > $n2} { foreach n1 $n2 n2 $n1 break }
        for { set i $n1 } { $i <= $n2 } { incr i } {
           lappend allsnapshotids $i
        }
      } else {
        error "invalid format for snapshot id: $elm"
      }
    }
    set allsnapshotids [lsort -unique $allsnapshotids]
    if {$debug} {
      print info "List of snapshot ids: $allsnapshotids"
    }
  }

  switch $dbVersion {
    1.5 {
      set CMD "SELECT id
          FROM snapshot
          WHERE id IN ('[join $allsnapshotids ',']')
                AND ( (project LIKE '$project') OR (project IS NULL) )
                AND ( (run LIKE '$run') OR (run IS NULL) )
                AND version LIKE '$version'
                AND experiment LIKE '$experiment'
                AND step LIKE '$step'
                AND ( (release LIKE '$release') OR (release IS NULL) )
          ;
         "
    }
    default {
      error "database version $dbVersion not supported"
    }
  }
  set snapshotids [lsort -integer [execSQL SQL $CMD]]

  if {$metrics == {}} {
    set CMD "SELECT DISTINCT name FROM metric WHERE snapshotid IN ('[join $snapshotids ',']') AND (enabled == 1)"
    set metrics [lsort [execSQL SQL $CMD]]
  }
#   puts "<metrics:$metrics>";

  set steps [lsort [execSQL SQL "SELECT DISTINCT step FROM snapshot WHERE id IN ('[join $snapshotids ',']')" ]]
#   puts "<steps:$steps>"
  set experiments [lsort [execSQL SQL "SELECT DISTINCT experiment FROM snapshot WHERE id IN ('[join $snapshotids ',']')" ]]
#   puts "<experiments:$experiments>"
  set versions [lsort [execSQL SQL "SELECT DISTINCT version FROM snapshot WHERE id IN ('[join $snapshotids ',']')" ]]
#   puts "<versions:$versions>"
  set releases [lsort [execSQL SQL "SELECT DISTINCT release FROM snapshot WHERE id IN ('[join $snapshotids ',']')" ]]
#   puts "<releases:$releases>"

  if {$saveHtml} {
#     catch {exec ln -s /wrk/hdstaff/dpefour/support/Olympus/assets/www/media $exportDir}
#     catch {
#       if {![file isdirectory [file join $exportDir media] ]} {
#         exec cp -r /wrk/hdstaff/dpefour/support/Olympus/assets/www/media $exportDir
#       }
#     }
    set indexFH [open [file join $exportDir "index.html"] {w}]
#     puts $indexFH "<head><body>"
    db2dir::htmlHeader $indexFH {Snapshots Summary}
    db2dir::htmlBody $indexFH -title {Snapshots Summary} -filters 1
    puts $indexFH "<div class='well'><h5>Database: [file normalize $db]</h5></div>"
    
    # Generate the HTML code for the modal dialog box for snapshots filtering
    puts $indexFH [format {
<div class="modal" id="filtersModal" tabindex="-1" role="dialog" aria-labelledby="filtersModalLabel" aria-hidden="true">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
        <h4 class="modal-title" id="filtersModalLabel">Snapshots Filtering</h4>
      </div>
      <div class="modal-body">
        <div>
          <button type="button" class="btn btn-link btn-xs" id='selectall'>Check all</button>
          <button type="button" class="btn btn-link btn-xs" id='unselectall'>Uncheck all</button>
        </div>
}]
    puts -nonewline $indexFH "<table class='table table-condensed table-bordered'><tr><td>"
    puts -nonewline $indexFH "Releases"
    puts -nonewline $indexFH "</td><td>"
    foreach r $releases {
      puts -nonewline $indexFH "<div style='float:left'><label><input type='checkbox' name='release' value='$r' class='filter' checked />$r</label></div>"
    }
    puts -nonewline $indexFH "</td></tr><tr><td>"
    puts -nonewline $indexFH "Versions"
    puts -nonewline $indexFH "</td><td>"
    foreach v $versions {
      puts -nonewline $indexFH "<div style='float:left'><label><input type='checkbox' name='version' value='$v' class='filter' checked />$v</label></div>"
    }
    puts -nonewline $indexFH "</td></tr><tr><td>"
    puts -nonewline $indexFH "Experiments"
    puts -nonewline $indexFH "</td><td>"
    foreach e $experiments {
      # Stack the expriments vertically instead of horizontaly
#       puts -nonewline $indexFH "<div style='float:left'><label><input type='checkbox' name='experiment' value='$e' class='filter' checked />$e</label></div>"
      puts -nonewline $indexFH "<div><label><input type='checkbox' name='experiment' value='$e' class='filter' checked />$e</label></div>"
    }
    puts -nonewline $indexFH "</td></tr><tr><td>"
    puts -nonewline $indexFH "Steps"
    puts -nonewline $indexFH "</td><td>"
    foreach s $steps {
      puts -nonewline $indexFH "<div style='float:left'><label><input type='checkbox' name='step' value='$s' class='filter' checked />$s</label></div>"
    }
    puts -nonewline $indexFH "</td></tr></table>"
    puts $indexFH "\n</div> <!-- Closing the class='well' -->"
    puts $indexFH [format {
      </div>
   <!--
      <div class="modal-footer">
        <button type="button" class="btn btn-xs btn-link" data-dismiss="modal">Close</button>
      </div>
   -->
    </div><!-- /.modal-content -->
  </div><!-- /.modal-dialog -->
</div><!-- /.modal -->
}]
    # end of HTML generation for modal dialog box
    
    # The list $topMetrics can have elements in the format <metricname>=<headername>. The code below
    # extract the column headers for the html table and rebuid the list $topMetrics with only the metric names
    set topMetricsHeader [list]
    set _topMetrics [list]
    foreach el $topMetrics {
      foreach {metricname headername} [split $el = ] { break }
      if {$headername == {}} { set headername $metricname }
      lappend topMetricsHeader $headername
      lappend _topMetrics $metricname
    }
    set topMetrics $_topMetrics
    
#     db2dir::htmlTableHeader $indexFH {Snapshots Summary :} [list {ID} {Project} {Release} {Version} {Experiment} {Step} {Run} {Date}]
    db2dir::htmlTableHeader $indexFH {Snapshots Summary :} [concat [list {ID} {Project} {Release} {Version} {Experiment} {Step} {Run} {Date}] $topMetricsHeader]
    if {$verbose} {
      print info "Creating HTML index file [file join $exportDir index.html]"
    }
  }

  set numrow 0
  foreach id $snapshotids {
    # rowTopMetrics: list of metrics showing on the index page. By default, initialize the list with empty values
    set rowTopMetrics [list] ; for {set i 0} {$i < [llength $topMetrics]} {incr i} {lappend rowTopMetrics {}}
    set CMD "SELECT project, run, version, experiment, step, release, description, date, time
           FROM snapshot
           WHERE id = $id
           ;
           "
    execSQL SQL { pragma integrity_check }
    SQL eval $CMD values {
  #     parray values
      incr numrow
      set project $values(project)
      set run $values(run)
      set version $values(version)
      set experiment $values(experiment)
      set step $values(step)
      set release $values(release)
      set description $values(description)
      set date $values(date)
      set time $values(time)
      foreach el {project run version experiment step release description date time} { set var($el) $values($el) }
      if {$verbose} {
        print info "Processing snapshot \[$numrow/[llength $snapshotids]\] ID=$id : project:$project version:$version experiment:$experiment step:$step release:$release run:$run date:$date time:$time"
      }
#       if {$debug} {
#         print debug "Snapshot ID=$id : project:$project run:$run version:$version experiment:$experiment step:$step date:$date time:$time"
#       }

      # When a duplicate metric name is found for a snapshot, keep the last one only. This is to support
      # the incremental flow when snapshot metric can be re-taken for a snapshot
      set CMD2 "SELECT name, value, binary, size, eol
             FROM metric
             WHERE snapshotid = $id
             AND (enabled == 1)
             AND ( name IN ('[join $metrics ',']') )
             AND id IN ( SELECT MAX(id)
                         FROM metric
                         WHERE snapshotid = $id
                         AND (enabled == 1)
                         GROUP BY snapshotid, name
                       )
             ORDER BY name ASC
             ;
             "
#       set CMD2 "SELECT name, value
#              FROM metric
#              WHERE snapshotid = $id
#                    AND (enabled == 1)
#                    AND ( name IN ('[join $metrics ',']') )
#              ;
#              "
      execSQL SQL { pragma integrity_check }
      set first 1
      set snapshotFH {}
      SQL eval $CMD2 metricinfo {
        set metricname $metricinfo(name)
        set metricvalue $metricinfo(value)
        set isbinary $metricinfo(binary)
        set size $metricinfo(size)
        set numlines $metricinfo(eol)
        regsub -all "%id" $filenameExpr $id filename
        regsub -all "%project" $filename $project filename
        regsub -all "%release" $filename $release filename
        regsub -all "%version" $filename $version filename
        regsub -all "%experiment" $filename $experiment filename
        regsub -all "%step" $filename $step filename
        regsub -all "%metricname" $filename $metricname filename
        regsub -all "%id" $directoryExpr $id dirname
        regsub -all "%project" $dirname $project dirname
        regsub -all "%release" $dirname $release dirname
        regsub -all "%version" $dirname $version dirname
        regsub -all "%experiment" $dirname $experiment dirname
        regsub -all "%step" $dirname $step dirname
        if {!$saveHtml} {
          # The metric name can be used in the directory name only if not saving as html.
          # Otherwise this is not allowed since the snapshot HTML must be at the same
          # directory level as the metrics HTML
          regsub -all "%metricname" $dirname $metricname dirname
        }
        # Is this metric one of those showing on the index page?
        if {[set i [lsearch [string tolower $topMetrics] [string tolower $metricname] ]] != -1} {
          # If so, then replace the metric value at the correct index of $rowTopMetrics
          if {$isbinary} {
            set rowTopMetrics [lreplace $rowTopMetrics $i $i "binary metric ($size bytes)"]
          } elseif {$numlines >= 2} {
            set rowTopMetrics [lreplace $rowTopMetrics $i $i "multi-lines metric ($numlines lines / $size bytes)"]
          } else {
            set rowTopMetrics [lreplace $rowTopMetrics $i $i [truncateText $metricvalue] ]
          }
        }
        if {$dirname != {}} {
          if {![file isdirectory [file join $exportDir $dirname]]} {
            if {$verbose} {
              print stdout "Creating directory [file join $exportDir $dirname]"
            }
            file mkdir [file join $exportDir $dirname]
          }
        }
        if {$saveHtml} {
          append filename {.html}
          if {![file exists [file join $exportDir $dirname "${id}.html"]] || $force} {
            if {$first} {
#               if {$indexFH != {}} {
# #                 puts $indexFH "<h5><a href='[file join $dirname ${id}.html]' target='_blank'>snapshot ID=$id : project:$project run:$run version:$version experiment:$experiment step:$step</a></h5>"
# #                 db2dir::htmlTableRow $indexFH [list release_$release version_$version experiment_$experiment step_$step] [list [format {<a href='%s' target='_blank'>%s</a>} [file join $dirname ${id}.html] $id] $project $run $version $experiment $step]
#                 db2dir::htmlTableRow $indexFH [list release_$release version_$version experiment_$experiment step_$step] [list [format {<a href='%s' target='_blank'>%s</a>} [file join $dirname ${id}.html] $id] $project $release $version $experiment $step $run $date]
#                 flush $indexFH
#               }
#               catch {
#                 if {![file isdirectory [file join $exportDir $dirname media]]} {
#                   exec cp -r /wrk/hdstaff/dpefour/support/Olympus/assets/www/media [file join $exportDir $dirname]
#                 }
#               }
              set snapshotFH [open [file join $exportDir $dirname "${id}.html"] {w}]
#               puts $snapshotFH "<head><body>"
#               puts $snapshotFH "<h1>snapshot ID=$id : project:$project run:$run version:$version experiment:$experiment step:$step date:$date time:$time</h1><hr>"
              db2dir::htmlHeader $snapshotFH {Metrics Summary}
              db2dir::htmlBody $snapshotFH -title {Metrics Summary}
              # Add additional div for bootstrap grid (center content)
              puts $snapshotFH "    <div class='container' role='main'> "
              # Calculate dir depth between index.html and snapshot HTML file
              set depth [expr [llength [file split [file join $exportDir $dirname "${id}.html"]]] - [llength [file split [file join $exportDir "index.html"]]] ]
              puts -nonewline $snapshotFH "<div class='well'>"
              puts -nonewline $snapshotFH [format {<a href='%s'>[Index page]</a>} "[string repeat ../ $depth]./index.html" ]
              puts -nonewline $snapshotFH [format {[%s]} [file join $exportDir $dirname ${id}.html] ]
              puts -nonewline $snapshotFH "</div>"
              puts -nonewline $snapshotFH "<div class='well'>"
#               puts $snapshotFH "<h2>Snapshot id=$id : project:$project run:$run version:$version experiment:$experiment step:$step date:$date time:$time</h2>"
#               puts $snapshotFH "<h4>Database: [file normalize $db]</h4>"
#               puts $snapshotFH "<h4>File: [file join $exportDir $dirname ${id}.html]</h4>"
              puts -nonewline $snapshotFH "<table class='table table-striped table-bordered table-condensed'"
              puts -nonewline $snapshotFH "<tr><td>ID</td><td>Project</td><td>Release</td><td>Version</td><td>Experiment</td><td>Step</td><td>Run</td><td>Date</td><td>Description</td></tr>"
              puts -nonewline $snapshotFH "<tr><td>$id</td><td>$project</td><td>$release</td><td>$version</td><td>$experiment</td><td>$step</td><td>$run</td><td>$date</td><td>$description</td></tr>"
              puts -nonewline $snapshotFH "</table>"
              puts -nonewline $snapshotFH "</div> <!-- Closing the class='well' -->"
              db2dir::htmlTableHeader $snapshotFH {Metrics Summary :} [list {Metric Name} {Metric Value}]
#               db2dir::htmlTableHeader $snapshotFH "Snapshot id=$id : project:$project run:$run version:$version experiment:$experiment step:$step date:$date time:$time" [list {Metric Name} {Metric Value}]
              if {$verbose} {
                print info "Creating snapshot HTML index file [file join $exportDir $dirname ${id}.html]"
              }
            }
          } else {
            if {$first} {
              if {$verbose} {
                print warning "Skipping snapshot HTML index file [file join $exportDir $dirname ${id}.html]"
              }
            }
          }
        }
        if {$writeMetricFiles} {
          if {![file exists [file join $exportDir $dirname $filename]] || $force} {
            if {$debug} {
              print debug "Writting metric file [file join $exportDir $dirname $filename] := [txt2html [truncateText $metricvalue]]"
            }
            # To test whether a file is "binary", in the sense that it contains NUL bytes
            set isMetricValueBinary [expr {[string first \x00 $metricvalue]>=0}]
            set metricFH [open [file join $exportDir $dirname $filename] {w}]
            # Support for binary files
            fconfigure $metricFH -encoding binary -translation binary
            if {$saveHtml} {
              if {$metricFH != {}} {
              }
              puts -nonewline $metricFH [format {<a href='%s'>[Snapshot page]</a>} ${id}.html ]
              puts -nonewline $metricFH [format {[%s]} [file join $exportDir $dirname $filename] ]
              puts -nonewline $metricFH "<table border='1' cellpadding='2' cellspacing='2' style='margin-top: 10px'>"
              puts -nonewline $metricFH "<tr><td>ID</td><td>Project</td><td>Release</td><td>Version</td><td>Experiment</td><td>Step</td><td>Run</td><td>Date</td><td>Description</td></tr>"
              puts -nonewline $metricFH "<tr><td>$id</td><td>$project</td><td>$release</td><td>$version</td><td>$experiment</td><td>$step</td><td>$run</td><td>$date</td><td>$description</td></tr>"
              puts -nonewline $metricFH "</table>"
              puts -nonewline $metricFH [format "<h2>%s</h2><hr><pre>\n%s\n</pre><hr>" $metricname [txt2html $metricvalue]]
              if {$isbinary} {
                db2dir::htmlTableRow $snapshotFH {} [list [format {<a href='%s' target='_blank'>%s</a>} $filename $metricname] "<i>binary metric ($size bytes)</i>" ]
              } elseif {$numlines >= 2} {
                db2dir::htmlTableRow $snapshotFH {} [list [format {<a href='%s' target='_blank'>%s</a>} $filename $metricname] "<i>multi-lines metric ($numlines lines / $size bytes)</i>" ]
              } else {
                db2dir::htmlTableRow $snapshotFH {} [list [format {<a href='%s' target='_blank'>%s</a>} $filename $metricname] [truncateText $metricvalue 100] ]
              }
#               db2dir::htmlTableRow $snapshotFH {} [list [format {<a href='%s' target='_blank'>%s</a>} $filename $metricname] [truncateText $metricvalue 100] ]
            } elseif {$saveFragment} {
              regsub -all "%id" $metricExpr $id metricname_
              regsub -all "%project" $metricname_ $project metricname_
              regsub -all "%release" $metricname_ $release metricname_
              regsub -all "%version" $metricname_ $version metricname_
              regsub -all "%experiment" $metricname_ $experiment metricname_
              regsub -all "%step" $metricname_ $step metricname_
              regsub -all "%metricname" $metricname_ $metricname metricname_
              # The metric is saved as a fragment file that can be imported with:  array set myarray [source ./<fragment_file>]
              puts $metricFH "# This file can be imported with:  array set myarray \[source [file join $exportDir $dirname $filename]\]"
              puts $metricFH "return {"
              puts $metricFH "  $metricname_ { $metricvalue }"
              puts $metricFH "}"
            } else {
              puts -nonewline $metricFH $metricvalue
            }
#             puts -nonewline $metricFH $metricvalue
            close $metricFH
#             if {$debug} {
#               print debug "snapshotid=$id / name=$metricname / value='[truncateText $metricvalue]'"
#             }
          } else {
            if {$debug} {
              print debug "Skipping metric file [file join $exportDir $dirname $filename] := [txt2html [truncateText $metricvalue]]"
            }
          }
        } else {
          if {$snapshotFH != {}} {
            if {$isbinary} {
              db2dir::htmlTableRow $snapshotFH {} [list [format {<a href='%s' target='_blank'>%s</a>} $filename $metricname] "<i>binary metric ($size bytes)</i>" ]
            } elseif {$numlines >= 2} {
              db2dir::htmlTableRow $snapshotFH {} [list [format {<a href='%s' target='_blank'>%s</a>} $filename $metricname] "<i>multi-lines metric ($numlines lines / $size bytes)</i>" ]
            } else {
              db2dir::htmlTableRow $snapshotFH {} [list [format {<a href='%s' target='_blank'>%s</a>} $filename $metricname] [truncateText $metricvalue 100] ]
            }
          }
        }
        set first 0
      }

      if {$snapshotFH != {}} {
#         puts $snapshotFH "</body></head>"
        db2dir::htmlTableFooter $snapshotFH
        # Close container div for bootstrap
       puts $snapshotFH "    </div> "
        db2dir::htmlFooter $snapshotFH
        close $snapshotFH
        set snapshotFH {}
      }


    }

    # Add the snapshot that was just created to the index page
    if {$saveHtml} {
      if {$indexFH != {}} {
#         puts $indexFH "<h5><a href='[file join $dirname ${id}.html]' target='_blank'>snapshot ID=$id : project:$project run:$run version:$version experiment:$experiment step:$step</a></h5>"
#         db2dir::htmlTableRow $indexFH [list release_$release version_$version experiment_$experiment step_$step] [list [format {<a href='%s' target='_blank'>%s</a>} [file join $dirname ${id}.html] $id] $project $release $version $experiment $step $run $date]
        db2dir::htmlTableRow $indexFH [list release_$release version_$version experiment_$experiment step_$step] [concat [list [format {<a href='%s' target='_blank'>%s</a>} [file join $dirname ${id}.html] $id] $project $release $version $experiment $step $run $date] $rowTopMetrics]
        flush $indexFH
      }
    }

  }

  if {$indexFH != {}} {
#     puts $indexFH "</body></head>"
    db2dir::htmlTableFooter $indexFH
    db2dir::htmlFooter $indexFH
    close $indexFH
    set indexFH {}
  }

  SQL close
  if {$verbose} {
    print info "Export completed on [clock format [clock seconds]]"
    print info ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
  }

  # Restore state of verbosity & debug
  set verbose $_verbose_
  set debug $_debug_

  return -code ok
}

#------------------------------------------------------------------------
# ::tb::snapshot::db2dir::htmlHeader
#------------------------------------------------------------------------
# Usage: ::tb::snapshot::db2dir::htmlHeader
#------------------------------------------------------------------------
# Generate HTML header
#------------------------------------------------------------------------
proc ::tb::snapshot::db2dir::htmlHeader {channel {title {Xilinx Snapshot}} } {
  # Summary :
  # Argument Usage:
  # Return Value:

  puts $channel [format {
<!DOCTYPE html>
<html lang="en">
<head>

    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="">
    <meta name="author" content="">

    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <link rel="shortcut icon" type="image/ico" href="http://www.xilinx.com/favicon.ico" />
    <title>%s</title>

    <style type="text/css" title="currentStyle">
      @import "http://cdn.datatables.net/1.10.0/css/jquery.dataTables.css";
      @import "http://netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css";
      /* @import "http://netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap-theme.min.css"; */
      @import "http://cdn.datatables.net/plug-ins/28e7751dbec/integration/bootstrap/3/dataTables.bootstrap.css";
    </style>
    <style type="text/css" title="currentStyle">
      body {
        padding-top: 70px;
        padding-bottom: 30px;
      }
      table.dataTable tr.even.row_selected td {
        background-color: #B0BED9;
      }
      table.dataTable tr.odd.row_selected td {
        background-color: #9FAFD1;
      }
       table.dataTable tr.even td {
        background-color: white;
      }
      table.dataTable tr.odd td {
        background-color: #E2E4FF;
      }
      /*
     table.dataTable tbody td {
        padding: 3px 10px;
      }
      */
    </style>

    <!-- HTML5 shim and Respond.js IE8 support of HTML5 elements and media queries -->
    <!--[if lt IE 9]>
      <script src="https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"></script>
      <script src="https://oss.maxcdn.com/libs/respond.js/1.4.2/respond.min.js"></script>
    <![endif]-->

    <script src="http://ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js"></script>
    <script src="http://netdna.bootstrapcdn.com/bootstrap/3.1.1/js/bootstrap.min.js"></script>
    <script src="http://cdn.datatables.net/1.10.0/js/jquery.dataTables.min.js"></script>
    <script src="http://cdn.datatables.net/plug-ins/28e7751dbec/integration/bootstrap/3/dataTables.bootstrap.js"></script>

    <script type="text/javascript" charset="utf-8">
      var oTable;
      $(document).ready(function() {

           /* Add a click handler for filtering rows based on the filtering checkboxes */
           $('.filter').click( function() {
               if ( !$(this).is(':checked') ) {
                   // Extract the class from the checkbox that has been clicked on: $(this).prop('name')+"_"+$(this).val()
                   $("#table tbody tr").filter("[class~='"+$(this).prop('name')+"_"+$(this).val()+"']").hide();
               } else {
                   // Extract the class from the checkbox that has been clicked on: $(this).prop('name')+"_"+$(this).val()
                   $("#table tbody tr").filter("[class~='"+$(this).prop('name')+"_"+$(this).val()+"']").show();
               }
           } );

           /* Add a click handler to check all the checkboxes and show all the rows */
           $('#selectall').click( function() {
               $("#table tbody tr").show();
               $(".filter").prop('checked',true);
           } );

           /* Add a click handler to uncheck all the checkboxes and hide all the rows */
           $('#unselectall').click( function() {
               $("#table tbody tr").hide();
               $(".filter").prop('checked',false);
           } );

          // /* Add a click handler to the rows - this could be used as a callback */
          $('#table tbody').on( 'click', 'tr', function () {
              // Comment out next line to allow multiple row selection
              // oTable.$('tr.row_selected').removeClass('row_selected');
              $(this).toggleClass('row_selected');
          } );

          /* Add a click handler to the anchor inside the table to prevent the row to be become selected when the link is clicked */
          $("#table tbody tr td a").click( function( e ) {
            // Prevent event bubbling
            e.stopPropagation();
          });

          $('#table').DataTable( {
               ordering: true,
               paging: false
          } );

          /* Init the table */
          oTable = $('#table').DataTable();

      } );
    </script>
</head>
} $title ]

}

#------------------------------------------------------------------------
# ::tb::snapshot::db2dir::htmlBody
#------------------------------------------------------------------------
# Usage: ::tb::snapshot::db2dir::htmlBody
#------------------------------------------------------------------------
# Generate HTML body
#------------------------------------------------------------------------
proc ::tb::snapshot::db2dir::htmlBody {channel args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # First assign default values...
  array set options {-title {Snapshots Summary} -filters 0}
  # ...then possibly override them with user choices
  array set options $args
  
  puts $channel [format {
  <body role="document">

    <!-- Fixed navbar -->
    <div class="navbar navbar-inverse navbar-fixed-top" role="navigation">
      <div class="container">
        <div class="navbar-header">
          <button type="button" class="navbar-toggle" data-toggle="collapse" data-target=".navbar-collapse">
            <span class="sr-only">Toggle navigation</span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </button>
          <a class="navbar-brand" href="#top">%s</a>
        </div>
} $options(-title) ]
  if {$options(-filters)} {
    puts $channel [format {
        <div class="navbar-collapse collapse">
          <ul class="nav navbar-nav">
            <li class="active"><a href="#" data-toggle="modal" data-target="#filtersModal">Filters</a></li>
      <!--
            <li><a href="#about">About</a></li>
            <li><a href="#contact">Contact</a></li>
            <li class="dropdown">
              <a href="#" class="dropdown-toggle" data-toggle="dropdown">Dropdown <b class="caret"></b></a>
              <ul class="dropdown-menu">
                <li><a href="#">Action</a></li>
                <li><a href="#">Another action</a></li>
                <li><a href="#">Something else here</a></li>
                <li class="divider"></li>
                <li class="dropdown-header">Nav header</li>
                <li><a href="#">Separated link</a></li>
                <li><a href="#">One more separated link</a></li>
              </ul>
      -->
            </li>
          </ul>
        </div>
} ]
  }
  puts $channel [format {
      </div>
    </div>

<!--    <div class="container" role="main"> -->
} ]

}

#------------------------------------------------------------------------
# ::tb::snapshot::db2dir::htmlTableHeader
#------------------------------------------------------------------------
# Usage: ::tb::snapshot::db2dir::htmlTableHeader
#------------------------------------------------------------------------
# Generate HTML table header
#------------------------------------------------------------------------
proc ::tb::snapshot::db2dir::htmlTableHeader {channel title header} {
  # Summary :
  # Argument Usage:
  # Return Value:

  if {$title != {}} {
    puts -nonewline $channel [format {
      <div class="container_wrapper well" id='top'>
        <div class="page-header">
          <h3>%s</h3>
        </div>} [[namespace parent]::txt2html $title] ]
  } else {
    puts -nonewline $channel [format {
      <div class="container_wrapper well">} ]
  }

  puts -nonewline $channel [format {
        <table class="table table-striped table-bordered table-condensed table-hover" id="table">
          <thead>
            <tr> }]

  foreach elm $header {
    puts -nonewline $channel [format {
              <th>%s</th> } [[namespace parent]::txt2html $elm] ]
  }

  puts -nonewline $channel [format {
            </tr>
          </thead>
          <tbody> }]

}

#------------------------------------------------------------------------
# ::tb::snapshot::db2dir::htmlTableRow
#------------------------------------------------------------------------
# Usage: ::tb::snapshot::db2dir::htmlTableRow
#------------------------------------------------------------------------
# Generate HTML table row
#------------------------------------------------------------------------
proc ::tb::snapshot::db2dir::htmlTableRow {channel class row} {
  # Summary :
  # Argument Usage:
  # Return Value:

    puts -nonewline $channel [format {
            <tr class="%s"> } $class]
    foreach elm $row {
      puts -nonewline $channel [format {
              <td>%s</td> } [[namespace parent]::txt2html $elm] ]
    }
    puts -nonewline $channel [format {
            </tr> }]

}

#------------------------------------------------------------------------
# ::tb::snapshot::db2dir::htmlTableFooter
#------------------------------------------------------------------------
# Usage: ::tb::snapshot::db2dir::htmlTableFooter
#------------------------------------------------------------------------
# Generate HTML table footer
#------------------------------------------------------------------------
proc ::tb::snapshot::db2dir::htmlTableFooter {channel} {
  # Summary :
  # Argument Usage:
  # Return Value:

  puts $channel [format {
          </tbody>
        </table>
      </div>
}]

}

#------------------------------------------------------------------------
# ::tb::snapshot::db2dir::htmlFooter
#------------------------------------------------------------------------
# Usage: ::tb::snapshot::db2dir::htmlFooter
#------------------------------------------------------------------------
# Generate HTML footer
#------------------------------------------------------------------------
proc ::tb::snapshot::db2dir::htmlFooter {channel} {
  # Summary :
  # Argument Usage:
  # Return Value:

  puts $channel [format {
<!--    </div> -->
  <hr>
  <div class='text-right'><h6 class 'small'><i>Page generated on %s</i></h6></div>
  </body>
</html>
} [clock format [clock seconds]] ]

}

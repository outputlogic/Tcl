########################################################################################
##
## Company:        Xilinx, Inc.
## Created by:     David Pefourque
## 
## Version:        2014.09.08
## Tool Version:   Vivado 2014.2
##
########################################################################################

########################################################################################
## 2014.09.08 - Restricted script to 2014.2 since catalog API changed for 2014.3
## 2014.07.01 - Catched setting parameter tclapp.sharedRepoPath (support removed from HEAD)
## 2014.05.05 - Fixed minor typo when sourcing tclstore_INT.tcl
## 2014.04.23 - Splitted tclstore.tcl in two scripts: tclstore.tcl & tclstore_INT.tcl
##            - Fixed issue how the minimum Vivado version was checked
## 2014.04.15 - Fixed bug in update_catalog that prevented the catalog from being correctly updated
##            - Minor tweaks
## 2014.04.11 - Updated sub-command update_catalog to remove some of the app properties
##              and added option -new_app
## 2014.04.09 - Added sub-command git
##            - Added sub-command git_pull_request
##            - Added sub-command git_commit_id
##            - Added sub-command git_changes
##            - Added sub-command git_rev_parse
##            - Misc enhancements
## 2014.04.08 - Added support for sub-command require_app
##            - Added command line arguments to update_catalog
##            - Added support for showing/hiding sub-commands
##            - Misc enhancements
## 2014.04.03 - Added support for sub-command clone_repo
## 2014.03.28 - Sort procs in alphabetic order inside tclIndex
## 2014.03.27 - Rename from package_app to tclstore
## 2014.03.26 - Initial release
########################################################################################

# Proc to reload current script
proc [file tail [info script]] {} " source [info script]; puts \" [info script] reloaded\" "
proc [file tail [info script]] {} " source ~/git/scripts/vivado/tclstore.tcl; puts \" [info script] reloaded\"; tclstore configure -repo /wrk/hdstaff/dpefour/support/TclApps/XilinxTclStore -app xilinx::designutils "
interp alias {} reload {} tclstore.tcl

# Contributor Flow:
# =================
# tclstore configure -app xilinx::designutils -repo <path_to_local_repo>
# tclstore write_pkgindex
# tclstore write_tclindex
# tclstore linter *.tcl
# tclstore regression test.tcl
# tclstore uninstall_app
# tclstore install_app
# # If this is a new app, use -new_app with update_catalog
# tclstore update_catalog -catalog 2014.1 -properties { revision_history {} }
# tclstore update_catalog -catalog 2014.2 -properties { revision_history {} }
# # Check all the files

# App Owner Flow:
# ===============
# tclstore configure -app xilinx::designutils -repo <path_to_local_repo>
# # The app version needs to be manually incremented
# tclstore write_pkgindex
# tclstore write_tclindex
# tclstore linter *.tcl
# tclstore regression test.tcl
# tclstore uninstall_app
# tclstore install_app
# # If this is a new app, use -new_app with update_catalog
# tclstore update_catalog -catalog 2014.1 -properties { revision_history {} }
# tclstore update_catalog -catalog 2014.2 -properties { revision_history {} }
# # Check all the files

# Gatekeeper Flow:
# ================
# tclstore configure -app xilinx::designutils -repo <path_to_local_repo>
# tclstore linter *.tcl
# tclstore regression test.tcl
# tclstore uninstall_app
# tclstore install_app
# # Get commit ID of Git Rev Parse
# set commit_id <commit_id>
# tclstore update_catalog -catalog 2014.1 -properties [list commit_id $commit_id]
# tclstore update_catalog -catalog 2014.2 -properties [list commit_id $commit_id]

# /wrk/hdstaff/alecw/rdi/work2/HEAD/hierdesign/util/updateTclStoreCatalog.pl 2014.1 -app=xilinx::designutils -v -tclstore=/home/dpefour/tmp/XilinxTclStore

namespace eval ::tclapp {
    namespace export tclstore
}
proc ::tclapp::tclstore { args } {
  # Summary : App packager for Xilinx Tcl Store

  # Argument Usage:
  # args : sub-command

  # Return Value:
  # returns the status or an error code

#   if {[catch {set res [uplevel [concat ::tclapp::tclstore::tclstore $args]]} errorstring]} {
#     error " -E- tclstore failed with the following error: $errorstring"
#   }
  return [uplevel [concat ::tclapp::tclstore::tclstore $args]]
}

###########################################################################
##
## Package for packaging apps for Tcl Store
##
###########################################################################

#------------------------------------------------------------------------
# Namespace for the package
#------------------------------------------------------------------------

# Trick to silence the linter
eval [list namespace eval ::tclapp::tclstore {
  variable showallcmd 0
  variable version {2014.09.08}
  variable params
  variable verbose 0
#   variable verbose 1
  variable debug 0
#   variable debug 1
  catch {unset params}
  array set params [list repository {} app {} catalog {} git {/tools/batonroot/rodin/devkits/lnx64/git-1.8.3/bin/git} ]
  # Set the default catalog version to the current Vivado version: <MAJOR>.<MINOR>
  set params(catalog) [join [lrange [split [version -short] {.}] 0 1] {.}]
} ]

#------------------------------------------------------------------------
# ::tclapp::tclstore::tclstore
#------------------------------------------------------------------------
# Main function
#------------------------------------------------------------------------
proc ::tclapp::tclstore::tclstore { args } {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable showallcmd
  
  # Due to API changes, let's restrict to 2014.2
  if {[package vcompare [version -short] 2014.2] != 0} {
    error " -E- need Vivado 2014.2"
  }
  
  #-------------------------------------------------------
  # Process command line arguments
  #-------------------------------------------------------
  set error 0
  set show_help 0
  set method [lshift args]
  switch -exact -- $method {
    dump {
      return [eval [concat ::tclapp::tclstore::dump] ]
    }
    \+ -
    showall {
      set showallcmd 1
      puts " -I- expose all sub-commands"
      return 0
    }
    \- {
      set showallcmd 0
      puts " -I- hide sub-commands not related to contributor flow"
      return 0
    }
    ? -
    -h -
    -help {
      incr show_help
    }
    default {
      return [eval [concat ::tclapp::tclstore::do ${method} $args] ]
    }
  }

  if {$show_help} {
    # <-- HELP
    puts ""
    ::tclapp::tclstore::method:?
    puts [format {
   Description: Utility to package apps for the Xilinx Tcl Store

   Example: Contributor Flow
      tclstore configure -repository /home/user/dev/XilinxTclStore -app xilinx::designutils
      # The app version needs to be manually incremented
      tclstore write_pkgindex
      tclstore write_tclindex
      tclstore linter *.tcl
      tclstore regression test.tcl
      tclstore uninstall_app
      tclstore install_app
      tclstore update_catalog -catalog 2014.1 -properties { revision_history {} }
      tclstore update_catalog -catalog 2014.2 -properties { revision_history {} }
      # Check all the files

   Example: App Owner Flow
      tclstore configure -repository /home/user/dev/XilinxTclStore -app xilinx::designutils
      # The app version needs to be manually incremented
      tclstore write_pkgindex
      tclstore write_tclindex
      tclstore linter *.tcl
      tclstore regression test.tcl
      tclstore uninstall_app
      tclstore install_app
      tclstore update_catalog -catalog 2014.1 -properties { revision_history {} }
      tclstore update_catalog -catalog 2014.2 -properties { revision_history {} }
      # Check all the files

    } ]

    if {$showallcmd} {
#       puts [format {
#    Example:
#       }]
    }
    
    # HELP -->
    return
  }

}

#------------------------------------------------------------------------
# ::tclapp::tclstore::lshift
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Stack function
#------------------------------------------------------------------------
proc ::tclapp::tclstore::lshift {inputlist} {
  # Summary :
  # Argument Usage:
  # Return Value:

  upvar $inputlist argv
  set arg  [lindex $argv 0]
  set argv [lrange $argv 1 end]
  return $arg
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::getBaseName
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Get base name of an app. The base name has the format <COMPANY>::<APP>
#------------------------------------------------------------------------
proc ::tclapp::tclstore::getBaseName {app} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Remove ::tclapp from app name
  regsub {^(::)?tclapp::} $app {} app
  regsub {^(::)?tclapp} $app {} app
  regsub {^::} $app {} app
  return $app
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::checkRepoValid
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Check whether the repository location is valid or not
#------------------------------------------------------------------------
proc ::tclapp::tclstore::checkRepoValid {} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable params
  set repo $params(repository)
  if {$repo == {}} {
    error " -E- repository location not set"
  }
  if {[lindex [file split $repo] end] != {XilinxTclStore}} {
    error " -E- the repo path does not end with 'XilinxTclStore'"
  }
  if {![file isdirectory $repo]} {
    error " -E- the repo path '$repo' is not a directory"
  }
  return 0
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::checkAppValid
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Check whether the app name is valid or not
#------------------------------------------------------------------------
proc ::tclapp::tclstore::checkAppValid {} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable params
  set app $params(app)
  if {$app == {}} {
    error " -E- app name not set"
  }
  if {![regexp {^[^:]+::[^:]+$} $app]} {
    error " -E- app '$app' does not match format <COMPANY>::<APP>"
  }
  return 0
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::checkCatalogValid
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Check whether the catalog version is valid or not
#------------------------------------------------------------------------
proc ::tclapp::tclstore::checkCatalogValid {} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable params
  set catalog $params(catalog)
  if {$catalog == {}} {
    error " -E- catalog version not set"
  }
  if {![regexp {^201[3-9]\.[1-4]$} $catalog]} {
    error " -E- catalog '$catalog' does not match a valid format <YEAR>.<QUARTER>"
  }
  switch -glob -- [version -short] {
    2013.4* {
      if {$catalog != {2013.4}} {
        error " -E- catalog version $catalog not supported with this version of Vivado"
      }
    }
    2014.1* {
      if {$catalog != {2014.1}} {
        error " -E- catalog version $catalog not supported with this version of Vivado"
      }
    }
    2014.2* {
    }
    default {
    }
  }
  return 0
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::getPkgVersion
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Get the current package path from the app
#------------------------------------------------------------------------
proc ::tclapp::tclstore::getPkgVersion { {name {}} } {
  # Summary :
  # Argument Usage:
  # Return Value:

  if {$name != {}} {
    # Force package to be retreived
    getPkgPath $name
    return [package version $name]
  }
  
  variable params
  variable verbose
  variable debug
  set repo $params(repository)
  set app $params(app)
#   set catalog $params(catalog)
  checkRepoValid
  checkAppValid
#   checkCatalogValid

  # Reformat app name
  set app "::tclapp::${app}"
  # What dir
  set dir [file join $repo {*}[regsub -all "::" $app " "]]
  package forget $app
  source [file join $dir pkgIndex.tcl]
  set pkgVersion [package version $app]
  package forget $app
  # If multiple versions are found, return the highest one
#   return $pkgVersion
  return [lindex [lsort -decreasing $pkgVersion] 0]
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::getPkgPath
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Get the current package path from the app
#------------------------------------------------------------------------
proc ::tclapp::tclstore::getPkgPath { {name {}} } {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable params
  variable verbose
  variable debug

  if {$name == {}} {
    set repo $params(repository)
    set app $params(app)
  #   set catalog $params(catalog)
    checkRepoValid
    checkAppValid
  #   checkCatalogValid
  
    # Reformat app name
#     set app "::tclapp::${app}"
    set name "::tclapp::${app}"
  }
#   set repo $params(repository)
#   set app $params(app)
# #   set catalog $params(catalog)
#   checkRepoValid
#   checkAppValid
# #   checkCatalogValid
# 
#   # Reformat app name
# #   set app "::tclapp::${app}"

  # Get the command to load a package without actually loading the package
  #
  # package ifneeded can return us the command to load a package but
  # it needs a version number. package versions will give us that
  set versions [package versions $name]
  if {[llength $versions] == 0} {
    # We do not know about this package yet. Invoke package unknown
    # to search
    {*}[package unknown] $name
    # Check again if we found anything
    set versions [package versions $name]
    if {[llength $versions] == 0} {
      error "Could not find package $name"
    }
  }
  return [package ifneeded $name [lindex $versions 0]]
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::metacomment
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Extract metacomment(s) from a proc name
#------------------------------------------------------------------------
proc ::tclapp::tclstore::metacomment {procName {sectionName {}} {&returnString {}}} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable params
  set app $params(app)

  upvar 1 ${&returnString} doc
  set doc {}

  checkAppValid

  # Build the proc name with the namespace qualifier
  set procName "::tclapp::${app}::${procName}"

  if {[info proc $procName] ne $procName} { return -1 }
  # reports a proc's args and leading comments.
  # Multiple documentation lines are allowed.
  set res {}
  set section {}
  catch {unset results}
  # This comment should not appear in the metacomment
  foreach line [split [uplevel 1 [list info body $procName]] \n] {
      if {[string trim $line] eq ""} continue
      # Skip comments that have been added to support rdi::register_proc command
      if {[regexp -nocase -- {^\s*#\s*(Summary|Argument Usage|Return Value|Categories)\s*\:\s*(.*)\s*$} $line -- match msg]} {
        if {$section != {}} {
          set results([string tolower $section]) $res
          set res {}
        }
        set section $match
        if {[regexp {^\s*$} $msg]} { set res {} } else { set res [list $msg] }
        continue
      }
     if {![regexp {^\s*#(.+)} $line -> line]} break
      lappend res [string trim $line]
  }
  if {$section != {}} {
    set results([string tolower $section]) $res
  }
  if {$sectionName != {}} {
    set sectionName [string tolower $sectionName]
    if {[info exists results($sectionName)]} {
      set doc $results($sectionName)
      return 0
    } else {
      set doc {}
      return 1
    }
  } else {
    set doc [array get results]
    return 0
  }
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::dump
#------------------------------------------------------------------------
# **HIDDEN**
#------------------------------------------------------------------------
# Usage: tclstore dump
#------------------------------------------------------------------------
# Dump packager info
#------------------------------------------------------------------------
proc ::tclapp::tclstore::dump {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Dump non-array variables
  foreach var [lsort [info var ::tclapp::tclstore::*]] {
    if {![info exists $var]} { continue }
    if {![array exists $var]} {
      puts "   $var: [subst $$var]"
    }
  }
  # Dump array variables
  foreach var [lsort [info var ::tclapp::tclstore::*]] {
    if {![info exists $var]} { continue }
    if {[array exists $var]} {
      puts "   === $var ==="
#       parray $var
      foreach key [lsort [array names $var]] {
        puts "     $key : [subst $${var}($key)]"
      }
    }
  }
  return -code ok
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::docstring
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Return the embedded help of a proc
#------------------------------------------------------------------------
proc ::tclapp::tclstore::docstring {procname} {
  # Summary :
  # Argument Usage:
  # Return Value:

  if {[info proc $procname] ne $procname} { return }
  # reports a proc's args and leading comments.
  # Multiple documentation lines are allowed.
  set res ""
  # This comment should not appear in the docstring
  foreach line [split [uplevel 1 [list info body $procname]] \n] {
      if {[string trim $line] eq ""} continue
      # Skip comments that have been added to support rdi::register_proc command
      if {[regexp -nocase -- {^\s*#\s*(Summary|Argument Usage|Return Value|Categories)\s*\:} $line]} continue
      if {![regexp {^\s*#(.+)} $line -> line]} break
      lappend res [string trim $line]
  }
  join $res \n
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::do
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Dispatcher with methods
#------------------------------------------------------------------------
proc ::tclapp::tclstore::do {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  if {[llength $args] == 0} {
#     error " -E- wrong number of parameters: tclstore <sub-command> \[<arguments>\]"
    set method {?}
  } else {
    # The first argument is the method
    set method [lshift args]
  }
  if {[info proc ::tclapp::tclstore::method:${method}] == "::tclapp::tclstore::method:${method}"} {
    eval ::tclapp::tclstore::method:${method} $args
  } else {
    # Search for a unique matching method among all the available methods
    set match [list]
    foreach procname [info proc ::tclapp::tclstore::method:*] {
      if {[string first $method [regsub {::tclapp::tclstore::method:} $procname {}]] == 0} {
        lappend match [regsub {::tclapp::tclstore::method:} $procname {}]
      }
    }
    switch [llength $match] {
      0 {
        error " -E- unknown sub-command $method"
      }
      1 {
        set method $match
        return [eval ::tclapp::tclstore::method:${method} $args]
      }
      default {
        error " -E- multiple sub-commands match '$method': $match"
      }
    }
  }
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::method:?
#------------------------------------------------------------------------
# Usage: tclstore ?
#------------------------------------------------------------------------
# Return all the available methods. The methods with no embedded help
# are not displayed (i.e hidden)
#------------------------------------------------------------------------
proc ::tclapp::tclstore::method:? {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Long help message
  variable showallcmd
  puts "   Usage: tclstore <sub-command> \[<arguments>\]"
  puts "   Where <sub-command> is:"
  foreach procname [lsort [info proc ::tclapp::tclstore::method:*]] {
    regsub {::tclapp::tclstore::method:} $procname {} method
    set help [::tclapp::tclstore::docstring $procname]
    if {$help ne ""} {
      if {[lsearch -exact [list clone_repo \
                                configure \
                                linter \
                                regression \
                                summary \
                                update_catalog \
                                write_pkgindex \
                                write_tclindex] $method] != -1} {
        if {$showallcmd} {
#           puts "         [format {%-15s%s- %s} $method \t $help]"
#           puts "     (*) [format {%-15s%s- %s} $method \t $help]"
          puts "         [format {%-15s%s- %s} $method \t $help] (*)"
        } else {
          puts "         [format {%-15s%s- %s} $method \t $help]"
        }
      } else {
        if {$showallcmd} {
          puts "         [format {%-15s%s- %s} $method \t $help]"
        } else {
#           puts "         [format {%-15s%s- %s} $method \t $help]"
        }
      }

#       if {$showallcmd} {
#         puts "         [format {%-15s%s- %s} $method \t $help]"
#       } elseif {[lsearch -exact [list clone_repo \
#                                       configure \
#                                       linter \
#                                       regression \
#                                       summary \
#                                       update_catalog \
#                                       write_pkgindex \
#                                       write_tclindex] $method] != -1} {
#         puts "         [format {%-15s%s- %s} $method \t $help]"
# #         puts "     (*) [format {%-15s%s- %s} $method \t $help]"
#       } else {
# #         puts "         [format {%-15s%s- %s} $method \t $help]"
#       }
    }
  }
  puts ""
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::method:get_procs
#------------------------------------------------------------------------
# Usage: tclstore get_procs
#------------------------------------------------------------------------
# Return the list of procs that have been exported from the app
#------------------------------------------------------------------------
proc ::tclapp::tclstore::method:get_procs {} {
  # Summary: Load the argument app in Vivado
  # Argument Usage:
  # Return Value:

  # List of procs exported by the app
  variable params
  set repo $params(repository)
  set app $params(app)
  set catalog $params(catalog)
  checkRepoValid
  checkAppValid

  # Reformat app name
  set app "::tclapp::[getBaseName $app]"

  set slave [interp create]

  $slave eval {

    # temporary variables
    namespace eval ::tcl {
      variable repo
      variable app
      variable procs
    }

  }

  $slave eval [list set ::tcl::repo $repo ]
  $slave eval [list set ::tcl::app $app ]

  $slave eval {

    set tcl::procs {}

    # Stub out package to avoid processing embedded package require
    rename package __package_orig
    proc package {what args} {
      switch -- $what {
        require { return }
        default { __package_orig $what {*}$args }
      }
    }

    # Stub out namespace to capture all 'namespace export'
    rename namespace __namespace_orig
    proc namespace {what args} {
      switch -- $what {
        export {
          foreach cmd $args {
            lappend ::tcl::procs $cmd
          }
        }
        default { __namespace_orig $what {*}$args }
      }
    }

    # Sbut out unknown
    proc tclPkgUnknown args {}
    package unknown tclPkgUnknown
    proc unknown {args} {}

    # Require the app
    package require $::tcl::app

    # What dir
    set dir [file join $::tcl::repo {*}[regsub -all "::" $::tcl::app " "]]

    foreach file [glob -nocomplain -directory $dir -tails -types {r f} *.tcl] {
      if {$file eq "pkgIndex.tcl"} {
        continue
      }
      if {$file eq "tclIndex.tcl"} {
        continue
      }

      # evaluate source in calling context otherwise procs would be
      # registered inside appinit namespace unless prefixed with "::"
      source [file join $dir $file]
    }
  }

  # The list of explicitly exported procs from $app
  set procs [$slave eval set ::tcl::procs]
  interp delete $slave

  return [lsort $procs]
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::method:reset
#------------------------------------------------------------------------
# Usage: tclstore reset
#------------------------------------------------------------------------
# Reset the repo/app/catalog
#------------------------------------------------------------------------
proc ::tclapp::tclstore::method:reset {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Reset the repo/app/catalog
  variable params
#   variable summary
#   variable verbose 0
#   variable debug 0
  catch {unset params}
  array set params [list repository {} app {} catalog {} git {/tools/batonroot/rodin/devkits/lnx64/git-1.8.3/bin/git}]
  # Set the default catalog version to the current Vivado version: <MAJOR>.<MINOR>
  set params(catalog) [join [lrange [split [version -short] {.}] 0 1] {.}]
  puts " -I- Resetting the packager"
  return -code ok
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::method:list_apps
#------------------------------------------------------------------------
# Usage: tclstore list_apps
#------------------------------------------------------------------------
# List all installed apps
#------------------------------------------------------------------------
proc ::tclapp::tclstore::method:list_apps {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # List all installed apps
  return [::tclapp::list_apps]
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::method:summary
#------------------------------------------------------------------------
# Usage: tclstore summary
#------------------------------------------------------------------------
# Report status of current repo/app
#------------------------------------------------------------------------
proc ::tclapp::tclstore::method:summary {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Status summary for the repo/app
  variable params
  set repo $params(repository)
  set app $params(app)
  set catalog $params(catalog)
  checkRepoValid
  checkAppValid
  checkCatalogValid

  puts "  Repository  : $repo"
  puts "  Catalog     : $catalog"
  puts "  App         : $app"
  puts "  App version : [getPkgVersion]"
  set procs [::tclapp::tclstore get_procs]
  if {[lsearch -exact [::tclapp::list_apps] $app] == -1} {
    puts "  App status  : not installed"
    puts "  Procs ([llength $procs]) : $procs"
    return -code ok
  }
  puts "  App status  : installed"
  puts "  Procs ([llength $procs]) : $procs"
  foreach proc $procs {
    puts "\n  $proc :"
    puts "     Summary        : [tclstore get_metacomment $proc {Summary}]"
    puts "     Argument Usage : [tclstore get_metacomment $proc {Argument Usage}]"
    puts "     Return Value   : [tclstore get_metacomment $proc {Return Value}]"
    puts "     Categories     : [tclstore get_metacomment $proc {Categories}]"
  }

  return -code ok
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::method:get_metacomment
#------------------------------------------------------------------------
# Usage: tclstore get_metacomment <procName> [<metacomment>]
#------------------------------------------------------------------------
# Return the metacomment(s) for the specified proc. The proc name should not
# include the namespace qualifier.
#------------------------------------------------------------------------
proc ::tclapp::tclstore::method:get_metacomment {procName {sectionName {}}} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Get metacomment for a proc
  variable params
  set repo $params(repository)
  set app $params(app)
#   set catalog $params(catalog)
  checkRepoValid
  checkAppValid
#   checkCatalogValid

  set result {}
  metacomment ${procName} $sectionName result

  return $result
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::method:configure
#------------------------------------------------------------------------
# Usage: tclstore configure [<options>]
#------------------------------------------------------------------------
# Configure some of the packager parameters such as repo/app/catalog
#------------------------------------------------------------------------
proc ::tclapp::tclstore::method:configure {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Configure the repo/app/catalog (-help)
  variable params
  variable verbose
  variable debug
  set error 0
  set help 0
  if {[llength $args] == 0} {
    set help 1
  }
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -r -
      -repo -
      -repository {
           set params(repository) [lshift args]
           # Remove last backslash to avoid any problem
           regsub {\/$} $params(repository) {} params(repository)
           checkRepoValid
           catch { set_param tclapp.sharedRepoPath $params(repository) }
           set_param tclapp.enableGitAccess 0
           puts " -I- List of installed apps: [lsort [::tclapp::list_apps]]"
           # Update all the installed apps
           foreach app [lsort [::tclapp::list_apps]] {
             puts " -I- Updating $app"
             ::tclapp::update $app
           }
      }
      -a -
      -app {
           set params(app) [getBaseName [lshift args]]
           checkAppValid
      }
      -c -
      -catalog {
           set params(catalog) [lshift args]
           checkCatalogValid
      }
      -verbose {
           set verbose 1
      }
      -quiet {
           set verbose 0
      }
      -debug {
           set debug 1
      }
      -nodebug {
           set debug 0
      }
      -h -
      -help {
           set help 1
      }
      default {
            if {[string match "-*" $name]} {
              puts " -E- option '$name' is not a valid option."
              incr error
            } else {
              puts " -E- option '$name' is not a valid option."
              incr error
            }
      }
    }
  }

  if {$help} {
    puts [format {
  Usage: tclstore configure
              [-r <path>|-repo <path>|-repository <path>]
              [-a <app>|-app <app>]
              [-c <catalog>|-catalog <catalog>]
              [-verbose|-quiet]
              [-help|-h]

  Description: Configuration

    Configure the location of the repository, the app name and catalog version

  Example:
     tclstore configure -repository /home/user/test/tclstore/XilinxTclStore -app xilinx::designutils -catalog 2014.2
} ]
    # HELP -->
    return -code ok
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  return -code ok
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::method:write_pkgindex
#------------------------------------------------------------------------
# Usage: tclstore write_pkgindex
#------------------------------------------------------------------------
# Write the pkgIndex.tcl file.
#------------------------------------------------------------------------
proc ::tclapp::tclstore::method:write_pkgindex {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Write pkgIndex.tcl
  variable params
  variable verbose
  variable debug
  set repo $params(repository)
  set app $params(app)
  set catalog $params(catalog)
  checkRepoValid
  checkAppValid
  checkCatalogValid

  # Reformat app name
  set app "::tclapp::${app}"
  # What dir
  set dir [file join $repo {*}[regsub -all "::" $app " "]]
  set oldPkgVersion [getPkgVersion]
  puts " -I- Rebuilding pkgIndex.tcl for $app ($dir)"
  pkg_mkIndex $dir
  set newPkgVersion [getPkgVersion]
  puts " -I- Package $app version: $newPkgVersion"
  if {$oldPkgVersion == $newPkgVersion} {
    puts " -W- The package version has not been updated"
  } elseif {$newPkgVersion < $oldPkgVersion} {
    puts " -E- The new package version ($newPkgVersion) is less than the previous version ($oldPkgVersion)"
  }
  return -code ok
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::method:write_tclindex
#------------------------------------------------------------------------
# Usage: tclstore write_tclindex
#------------------------------------------------------------------------
# Write the tclIndex file. Procs that are not being exported by the
# app are either removed from the file or commented out.
#------------------------------------------------------------------------
proc ::tclapp::tclstore::method:write_tclindex {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Write tclIndex
  variable params
  variable verbose
  variable debug
  set repo $params(repository)
  set app $params(app)
  set catalog $params(catalog)
  checkRepoValid
  checkAppValid
  checkCatalogValid

  # Reformat app name
  set app "::tclapp::${app}"
  # What dir
  set dir [file join $repo {*}[regsub -all "::" $app " "]]
  puts " -I- Rebuilding tclIndex for $app ($dir)"
  auto_mkindex $dir
  set tclIndexContent [list]
  set listProcs [::tclapp::tclstore get_procs]
  set FH [open [file join $dir tclIndex] {r}]
  set tclIndexProcs [list]
  foreach line [split [read $FH] \n] {
    if {[regexp [format {^(.+%s)\:\:([^\s\)]+)\)(.+)$} $app] $line -- prefix procname suffix]} {
      if {[lsearch -exact $listProcs $procname] != -1} {
#         lappend tclIndexContent $line
        lappend tclIndexProcs $line
      } else {
        switch -glob -- [version -short] {
          2013.* {
#             lappend tclIndexContent "# $line"
#             lappend tclIndexProcs "# $line"
          }
          2014.1* {
#             lappend tclIndexContent "# $line"
#             lappend tclIndexProcs "# $line"
          }
          2014.2* {
#             lappend tclIndexContent "# $line"
#             lappend tclIndexProcs "# $line"
          }
          default {
#             lappend tclIndexContent "# $line"
#             lappend tclIndexProcs "# $line"
          }
        }
      }
    } else {
      lappend tclIndexContent $line
    }
  }
  close $FH
  set FH [open [file join $dir tclIndex] {w}]
  puts $FH [join [concat $tclIndexContent [lsort $tclIndexProcs]] \n]
  close $FH
  return -code ok
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::method:linter
#------------------------------------------------------------------------
# Usage: tclstore linter <pattern>
#------------------------------------------------------------------------
# Run the linter on the file pattern.
#------------------------------------------------------------------------
proc ::tclapp::tclstore::method:linter {{pattern {*.tcl}}} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Run linter on file pattern
  variable params
  variable verbose
  variable debug
  set repo $params(repository)
  set app $params(app)
  set catalog $params(catalog)
  checkRepoValid
  checkAppValid
  checkCatalogValid

  # Reformat app name
  set app "::tclapp::${app}"
  # What dir
  set dir [file join $repo {*}[regsub -all "::" $app " "]]

  if {[glob -nocomplain [file join $dir $pattern]] == {}} {
    puts " -W- '$pattern' does not match any file under $dir"
    return -code error
  }
  puts " -I- Running linter on pattern: $pattern"
  foreach file [lsort [glob -nocomplain [file join $dir $pattern]]] {
    if {[regexp {^(pkgIndex.tcl|tclIndex)$} [file tail $file]]} {
      continue
    }
    if {[catch {lint_files $file} errorstring]} {
      puts " -I- Linter failed on $file: $errorstring"
    } else {
      puts " -I- Linter passed on $file"
    }
  }

  return -code ok
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::method:regression
#------------------------------------------------------------------------
# Usage: tclstore regression <pattern>
#------------------------------------------------------------------------
# Run the test regression on the file pattern.
#------------------------------------------------------------------------
proc ::tclapp::tclstore::method:regression {{pattern {test.tcl}}} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Run test regression on file pattern
  global auto_path
  variable params
  variable verbose
  variable debug
  set repo $params(repository)
  set app $params(app)
  set catalog $params(catalog)
  checkRepoValid
  checkAppValid
  checkCatalogValid

  # Reformat app name
  set app "::tclapp::${app}"
  # What dir
  set dir [file join $repo {*}[regsub -all "::" $app " "]]

  set BAK $auto_path
  puts " -I- Running regression on pattern: $pattern"
  foreach file [lsort [glob -nocomplain [file join $dir test $pattern]]] {
    if {[catch {uplevel #0 [list source -notrace $file]} errorstring]} {
      puts " -I- Regression failed on $file: $errorstring"
    } else {
      puts " -I- Regression passed on $file"
    }
  }
  set auto_path $BAK

  return -code ok
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::method:install_app
#------------------------------------------------------------------------
# Usage: tclstore install_app
#------------------------------------------------------------------------
# Update the app if already installed. Otherwise install the app.
#------------------------------------------------------------------------
proc ::tclapp::tclstore::method:install_app {} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Install or update the app
  variable params
  variable verbose
  variable debug
  set repo $params(repository)
  set app $params(app)
#   set catalog $params(catalog)
  checkRepoValid
  checkAppValid
#   checkCatalogValid

  if {[lsearch -exact [::tclapp::list_apps] $app] == -1} {
    puts " -I- Installing $app"
    package forget $app
    ::tclapp::install $app
  } else {
    puts " -I- Updating $app"
    package forget $app
    ::tclapp::update $app
  }
  puts " -I- App version : [getPkgVersion]"
  return -code ok
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::method:uninstall_app
#------------------------------------------------------------------------
# Usage: tclstore uninstall_app
#------------------------------------------------------------------------
# Uninstall the app if already installed.
#------------------------------------------------------------------------
proc ::tclapp::tclstore::method:uninstall_app {} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Uninstall the app
  variable params
  variable verbose
  variable debug
  set repo $params(repository)
  set app $params(app)
#   set catalog $params(catalog)
  checkRepoValid
  checkAppValid
#   checkCatalogValid

  if {[lsearch -exact [::tclapp::list_apps] $app] == -1} {
    puts " -W- $app is not installed"
  } else {
    puts " -I- Uninstalling $app"
    ::tclapp::uninstall $app
  }
  return -code ok
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::method:update_catalog
#------------------------------------------------------------------------
# Usage: tclstore update_catalog [<ListOfAppProperties>]
#------------------------------------------------------------------------
# Update the catalog
#------------------------------------------------------------------------
proc ::tclapp::tclstore::method:update_catalog {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Update catalog XML (-help)
  variable params
  variable verbose
  variable debug

  set xmlproperties {}
  set newapp 0
  set error 0
  set help 0
  if {[llength $args] == 0} {
    set help 1
  }
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -c -
      -catalog {
           set params(catalog) [lshift args]
           checkCatalogValid
      }
      -p -
      -prop -
      -properties {
           set xmlproperties [concat $xmlproperties [lshift args]]
      }
      -n -
      -new -
      -new_app {
           set newapp 1
      }
      -h -
      -help {
           set help 1
      }
      default {
            if {[string match "-*" $name]} {
              puts " -E- option '$name' is not a valid option."
              incr error
            } else {
              puts " -E- option '$name' is not a valid option."
              incr error
            }
      }
    }
  }

  if {$help} {
    puts [format {
  Usage: tclstore update_catalog
              [-p <xml_properties>|-prop <xml_properties>|-properties <xml_properties>]
              [-c <catalog>|-catalog <catalog>]
              [-n|-new|-new_app]
              [-help|-h]

  Description: Update the XML Catalog

    Update the XML catalog:
      - add app properties
      - add procs
    
    If this is a new app that does not exist yet inside the catalog, using the option -new_app let
    the following app properties get populated inside the catalog: pkg_require, company, name
    
    The list of supported properties is: name display company company_display summary author pkg_require revision revision_history commit_id

  Example:
     tclstore update_catalog -catalog 2014.2
     tclstore update_catalog -catalog 2014.2 -p [list pkg_require {Vivado 2014.1} ]
} ]
    # HELP -->
    return -code ok
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  set repo $params(repository)
  set app $params(app)
  set catalog $params(catalog)
  checkRepoValid
  checkAppValid
  checkCatalogValid

  # What dir
  set dir [file join $repo {*}[regsub -all "::" ::tclapp::${app} " "]]
  
  # Get the app's short name
  # For example:  xilinx::designutils -> designutils
  #                  (app)            -> (appShortName)
  set appShortName {}
  if {[regexp {^:?:?[^:]+::(.+)$} $app -- appShortName]} {
  } else {
    puts " -E- cannot extract the app's short name from '$app'"
  }

  # Reload all the scripts under the app to make sure that all the changes on file are
  # visible inside Vivado
  foreach file [glob -nocomplain [file join $dir *.tcl]] {
    if {[regexp {^(tclIndex|pkgIndex.tcl)$} [file tail $file]]} { continue }
    if {$verbose} {
      puts " -I- Sourcing $file"
    }
    source -notrace $file
  }

  # Load the catalog. Vivado automatically picks up the catalog that matches the version of the tool being run
  switch -glob -- [version -short] {
    2013.* {
      puts " -I- loading default catalog from '$repo'"
      tclapp::load_catalog $repo
    }
    2014.1* {
      puts " -I- loading default catalog from '$repo'"
      tclapp::load_catalog $repo
    }
    2014.2* {
      puts " -I- loading catalog '$catalog' from '$repo'"
      tclapp::load_catalog $repo $catalog
#       tclapp::load_catalog $repo $catalog
    }
    default {
      puts " -I- loading catalog '$catalog' from '$repo'"
      tclapp::load_catalog $repo $catalog
    }
  }
#   tclapp::load_catalog $repo

  # Add the full path to the app     
  tclapp::add_app_path $dir

  # Add some properties to the app
  array set properties [list revision [getPkgVersion]]
  if {$newapp} {
    array set properties [list pkg_require "Vivado $catalog"]
  }
  # Extract the company and app names from <COMPANY>::<APP>
  if {$newapp} {
    array set properties [list company [lindex [split [regsub -all "::" $app " "] { }] 0 ] ]
    array set properties [list name [lindex [split [regsub -all "::" $app " "] { }] 1 ] ]
  }
#   array set properties [list revision_history {} ]
  array set properties $xmlproperties
  foreach prop {name display company company_display summary author pkg_require revision revision_history commit_id} {
    if {[info exists properties($prop)]} {
      puts " -I- Setting app property: $prop = $properties($prop)"
      tclapp::add_property $app $prop $properties($prop)
    }
  }

  # Delete all procs (not supported by 2013.4, 2014.1)     
  switch -glob -- [version -short] {
    2013.* {
    }
    2014.1* {
    }
    default {
      puts " -I- Removing all procs for '$app'"
      tclapp::delete_proc $appShortName *
#       tclapp::delete_proc $app *
    }
  }

  foreach proc [::tclapp::tclstore get_procs] {
    # Define the proc(s) exported by the app. One call per proc
    tclapp::add_proc $appShortName $proc
#     tclapp::add_proc $app $proc
    # Add a summary for each proc
#     set summary {}
#     metacomment $proc {summary} summary
    set summary [::tclapp::tclstore get_metacomment $proc {summary}]
    set summary [join $summary " "]
    if {$verbose} {
      puts " -I- adding proc $proc: $summary"
    }
    tclapp::add_proc_property $appShortName $proc {summary} $summary
#     tclapp::add_proc_property $app $proc {summary} $summary
  }

  # Save the catalog directly under the correct location
#   if {$verbose} {
#     puts " -I- saving catalog $repo/catalog/catalog_${catalog}.xml"
#   }
  puts " -I- saving catalog $repo/catalog/catalog_${catalog}.xml"
  tclapp::save_catalog $repo/catalog/catalog_${catalog}.xml

  return -code ok
}

###########################################################################
##
## Main
##
###########################################################################

namespace import ::tclapp::tclstore

if {[file exists [file join [file dirname [info script]] tclstore_INT.2014_2.tcl]]} {
  puts "  Sourcing [file join [file dirname [info script]] tclstore_INT.2014_2.tcl]"
  source -notrace [file join [file dirname [info script]] tclstore_INT.2014_2.tcl]
}

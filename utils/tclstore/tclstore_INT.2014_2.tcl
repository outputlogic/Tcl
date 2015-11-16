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
## 2014.05.05 - Fixed minor typo in documentation
## 2014.04.23 - Splitted tclstore.tcl in two scripts: tclstore.tcl & tclstore_INT.tcl
##            - Fixed issue how the minimum Vivado version was checked
##            - Initial release for tclstore_INT.tcl
########################################################################################

# Contributor Flow:
# =================
# tclstore clone_repo -dir . -user dpefour
# cd XilinxTclStore
# tclstore configure -app xilinx::designutils
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
# tclstore git_changes
# tclstore git status
# tclstore git commit -a -m 'Added proc ...'
# tclstore git push origin master

# App Owner Flow:
# ===============
# tclstore clone_repo -dir . -user dpefour -pull 230
# cd XilinxTclStore
# tclstore git_changes
# tclstore configure -app xilinx::designutils
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
# tclstore git_changes
# tclstore git status
# tclstore git commit -a -m 'Merge pull request 230. Updated catalog to 1.6'
# tclstore git push origin master

# Gatekeeper Flow:
# ================
# tclstore clone_repo -dir . -user dpefour -pull 230
# cd XilinxTclStore
# tclstore git_changes
# tclstore configure -app xilinx::designutils
# tclstore linter *.tcl
# tclstore regression test.tcl
# tclstore uninstall_app
# tclstore install_app
# set commit_id [tclstore git_rev_parse]
# tclstore update_catalog -catalog 2014.1 -properties [list commit_id $commit_id]
# tclstore update_catalog -catalog 2014.2 -properties [list commit_id $commit_id]
# tclstore git status
# tclstore git commit -a -m 'Updated commit id inside 2014.1 and 2014.2 catalogs'
# tclstore git push upstream master
# tclstore git push origin master


# /wrk/hdstaff/alecw/rdi/work2/HEAD/hierdesign/util/updateTclStoreCatalog.pl 2014.1 -app=xilinx::designutils -v -tclstore=/home/dpefour/tmp/XilinxTclStore

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
      tclstore clone_repo -dir . -user dpefour
      cd XilinxTclStore
      # The following -repo is optional if the previous command has been executed
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
      tclstore clone_repo -dir . -user dpefour -pull 230
      cd XilinxTclStore
      # The following -repo is optional if the previous command has been executed
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

   Example: Gatekeeper Flow
      tclstore clone_repo -dir . -user dpefour -pull 230
      cd XilinxTclStore
      tclstore configure -app xilinx::designutils
      tclstore linter *.tcl
      tclstore regression test.tcl
      tclstore uninstall_app
      tclstore install_app
      set commit_id [tclstore git_rev_parse]
      tclstore update_catalog -catalog 2014.1 -properties [list commit_id $commit_id]
      tclstore update_catalog -catalog 2014.2 -properties [list commit_id $commit_id]
      # Check all the files
    } ]

    if {$showallcmd} {
      puts [format {
   Example:
      tclstore clone_repo -dir .
      cd XilinxTclStore
      set id [tclstore git_rev_parse]
      tclstore git_pull_request 230
      tclstore git_commit_id d665d803a749b2f10a9d05228894da7b0eb70595
      tclstore git_changes

   Example:
      tclstore clone_repo -dir .
      cd XilinxTclStore
      tclstore git rev-parse master
      tclstore git reset --hard e44d5e0bef613d50b7c6a54837ea597fda7ea51f
      tclstore git rev-parse master
      tclstore git pull upstream refs/pull/230/head
      tclstore git rev-parse master
      tclstore git pull upstream
      tclstore git rev-parse master
      tclstore git diff --name-status HEAD HEAD~1
      }]
    }
    
    # HELP -->
    return
  }

}

#------------------------------------------------------------------------
# ::tclapp::tclstore::system
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Execute a process under UNIX.
# Return a TCL list. The first element of the list is the exit code
# for the process. The second element of the list is the message
# returned by the process.
# The exit code is 0 if the process executed successfully.
# The exit code is 1, 2, 3, or 4 otherwise.
# Example:
#      foreach [list exitCode message] [::tclapp::tclstore::system ls -lrt] { break }
#------------------------------------------------------------------------
proc ::tclapp::tclstore::system { args } {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable verbose
  variable debug

  #-------------------------------------------------------
  # Save the command being executed inside the log file.
  #-------------------------------------------------------
  if {$debug} { puts " -D- Unix call: $args" }

  #-------------------------------------------------------
  # Execute the command inside the global namespace (level #0).
  #-------------------------------------------------------
  catch {set result [eval [list uplevel #0 exec $args]] } returnstring

  #-------------------------------------------------------
  # Check the status of the process.
  #-------------------------------------------------------
  if { [string equal $::errorCode NONE] } {

    # The command exited with a normal status, but wrote something
    # to stderr, which is included in $returnstring.
    set exitCode 0

    if {$debug} { puts " -D- ::errorCode = NONE" }

  } else {

    switch -exact -- [lindex $::errorCode 0] {

      CHILDKILLED {

        foreach { - pid sigName msg } $::errorCode { break }

        # A child process, whose process ID was $pid,
        # died on a signal named $sigName.  A human-
        # readable message appears in $msg.
        set exitCode 2

        if {$debug} { 
          puts " -D- ::errorCode = CHILDKILLED"
          puts " -D- Child process $pid died from signal named $sigName"
          puts " -D- Message: $msg"
        }

      }

      CHILDSTATUS {

        foreach { - pid code } $::errorCode { break }

        # A child process, whose process ID was $pid,
        # exited with a non-zero exit status, $code.
        set exitCode 1

        if {$debug} { 
          puts " -D- ::errorCode = CHILDSTATUS"
          puts " -D- Child process $pid exited with status $code"
        }

      }

      CHILDSUSP {

        foreach { - pid sigName msg } $::errorCode { break }

        # A child process, whose process ID was $pid,
        # has been suspended because of a signal named
        # $sigName.  A human-readable description of the
        # signal appears in $msg.
        set exitCode 3

        if {$debug} { 
          puts " -D- ::errorCode = CHILDSUSP"
          puts " -D- Child process $pid suspended because signal named $sigName"
          puts " -D- Message: $msg"
        }

      }

      POSIX {

        foreach { - errName msg } $::errorCode { break }

        # One of the kernel calls to launch the command
        # failed.  The error code is in $errName, and a
        # human-readable message is in $msg.
        set exitCode 4

        if {$debug} { 
          puts " -D- ::errorCode = POSIX"
          puts " -D- One of the kernel calls to launch the command failed. The error code is $errName"
          puts " -D- Message: $msg"
        }

      }

    }
    
  }
  
  if {$debug} { 
    puts " -D- returnstring=[join [split $returnstring \n] {\\}]"
    puts " -D- exitCode=$exitCode"
  }

  return [list $exitCode $returnstring]
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::getGitRevParseMaster
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Get the Git repo commit id returned by 'git rev-parse master' 
#------------------------------------------------------------------------
proc ::tclapp::tclstore::getGitRevParseMaster {} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Issue 'git rev-parse master'
  variable params
  variable verbose
  variable debug

  set sha1 {}
  if {$verbose} { puts " -I- rev-parse master" }
  foreach [list exitCode message] [runGitCmd rev-parse master] {break}
  if {[regexp {\W([0-9a-zA-Z]{40})\W} [join $message { }] -- sha1]} {
    if {$verbose} { puts " -I- SHA1: $sha1" }
  } else {
    if {$verbose} { puts " -E- could not extract SHA1 from '[join $message { }]'" }
  }
  return $sha1
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::runGitCmd
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Execute a Git command
#------------------------------------------------------------------------
proc ::tclapp::tclstore::runGitCmd {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  variable params
  variable verbose
  variable debug
  set dir [uplevel #0 pwd]
  if {$verbose} {
    puts " -I- Git command: $args"
  }
  foreach [list exitCode message] [ system ssh git-dev [format {cd %s ; %s %s} $dir $params(git) $args] ] { break }
  if {$debug} {
    puts " -D- exitCode: $exitCode"
    puts " -D- message: [join $message { }]"
  }
  if {$exitCode != 0} {
    puts " -E- Git command failed"
    error "$message"
  }
  return [list $exitCode $message]
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
      -g -
      -git {
           set params(git) [lshift args]
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
              [-g <path>|-git <path>]
              [-verbose|-quiet]
              [-help|-h]

  Description: Configuration

    Configure the location of the repository, the app name and catalog version

  Example:
     tclstore configure -repository /home/user/test/tclstore/XilinxTclStore -app xilinx::designutils -catalog 2014.2
     tclstore configure -git <PATH_TO_GIT_BINARY>
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
# ::tclapp::tclstore::method:forget_pkg
#------------------------------------------------------------------------
# Usage: tclstore forget_pkg
#------------------------------------------------------------------------
# Forget all apps packages
#------------------------------------------------------------------------
proc ::tclapp::tclstore::method:forget_pkg {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Forget all apps related Tcl packages
  variable params
#   variable summary
#   variable verbose 0
#   variable debug 0
  foreach pkg [package names] {
    if {![regexp {^::tclapp::} $pkg]} { continue }
    if {[regexp {^::tclapp::support::} $pkg]} { continue }
    puts " -I- Package forget $pkg version [package version $pkg]"
    package forget $pkg
  }
  return -code ok
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::method:list_pkg
#------------------------------------------------------------------------
# Usage: tclstore list_pkg
#------------------------------------------------------------------------
# List all apps packages
#------------------------------------------------------------------------
proc ::tclapp::tclstore::method:list_pkg {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # List all apps related Tcl packages
  variable params
#   variable summary
#   variable verbose 0
#   variable debug 0
  foreach pkg [package names] {
    if {![regexp {^::tclapp::} $pkg]} { continue }
    if {[regexp {^::tclapp::support::} $pkg]} { continue }
    puts " -I- Package $pkg version [package version $pkg] ([lindex [getPkgPath $pkg] 1])"
  }
  return -code ok
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::method:git
#------------------------------------------------------------------------
# Usage: tclstore git [<args>]
#------------------------------------------------------------------------
# Execute Git command
#------------------------------------------------------------------------
proc ::tclapp::tclstore::method:git {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Run Git command
  foreach [list exitCode message] [uplevel [concat ::tclapp::tclstore::runGitCmd $args]] {break}
  if {$exitCode != 0} {
    puts " -E- The Git command '$args' failed"
    error $message
  }
  puts " -I- $message"
  return 0
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::method:clone_repo
#------------------------------------------------------------------------
# Usage: tclstore clone_repo [<options>]
#------------------------------------------------------------------------
# Clone the GitHub repository and optionaly merge pull request
#------------------------------------------------------------------------
proc ::tclapp::tclstore::method:clone_repo {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Clone Xilinx GitHub repository (-help)
  variable params
  variable verbose
  variable debug
  set dir {}
  set pullRequest {}
  set gitUserID {}
  set commitSha1 {}
  set error 0
  set help 0
  if {[llength $args] == 0} {
    set help 1
  }
  while {[llength $args]} {
    set name [lshift args]
    switch -exact -- $name {
      -d -
      -dir -
      -directory {
           set dir [file normalize [lshift args]]
           # Remove last backslash to avoid any problem
           regsub {\/$} $dir {} dir
           if {[file isdirectory [file join $dir XilinxTclStore]] } {
             error " -E- directory XilinxTclStore already exists under '$dir'"
           } elseif {![file isdirectory $dir]} {
             puts " -W- directory '$dir' does not exist and will be created"
           }
      }
      -p -
      -pull -
      -pull_request {
           set pullRequest [lshift args]
           if {![regexp {^[0-9]+$} $pullRequest]} {
             error " -E- incorrect pull request format"
           }
      }
      -c -
      -co -
      -commit -
      -s -
      -sha -
      -sha1 {
           set commitSha1 [lshift args]
           if {![regexp {^([0-9a-zA-Z]{40}|[0-9a-zA-Z]{10}|[0-9a-zA-Z]{7})$} $commitSha1]} {
             error " -E- incorrect SHA1 format (7 or 40 alphanumeric characters)"
           }
      }
      -u -
      -user {
           set gitUserID [lshift args]
      }
      -g -
      -git {
           set params(git) [lshift args]
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
  Usage: tclstore clone_repo
              [-d <path>|-dir <path>|-directory <path>]
              [-p <pull_request_number>|-pull <pull_request_number>|-pull_request <pull_request_number>]
              [-c <sha1>|-co <sha1>|-commit <sha1>]
              [-s <sha1>|-sha <sha1>|-sha1 <sha1>]
              [-u <GitHubUserName>|-user <GitHubUserName>]
              [-g <path>|-git <path>]
              [-help|-h]

  Description: Clone Xilinx GitHub Repository

    Clone the Xilinx GitHub Repository and merge an optional pull request
    
    The -sha1/-commit are equivalent and clone the repo to the commit ID <SHA1>

  Example:
     tclstore clone_repo -directory /home/user/test -pull_request 216 -user joe
     tclstore clone_repo -directory /home/user/test -sha1 3d151a50b0718d7c4feaaeb55ccd024bcfe845e4 -user joe
     tclstore clone_repo -dir /home/user/test -pull 216 -user joe -git <PATH_TO_GIT_BINARY>
} ]
    # HELP -->
    return -code ok
  }
  
  if {$params(git) == {}} {
    puts " -E- use -git to specify the location to the 'git' command"
    incr error
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  if {![file isdirectory $dir]} {
    puts " -I- creating directory '$dir'"
    file mkdir $dir
  }

  set CWD [uplevel #0 pwd]
  cd $dir
  
  puts " -I- cloning Xilinx GitHub repository to [file normalize $dir]"
  if {$gitUserID == {}} {
    foreach [list exitCode message] [runGitCmd clone https://github.com/Xilinx/XilinxTclStore.git] {break}
  } else {
    foreach [list exitCode message] [runGitCmd clone https://$gitUserID@github.com/Xilinx/XilinxTclStore.git] {break}
  }
  
  if {$exitCode} {
    cd $CWD
    error " -E- $message"
  }
  
  # Add a little time to make sure the directory is registered by Tcl as being created
  # This avoid some race conditions I have experienced
  set count 0
  while {![file isdirectory [file join $dir XilinxTclStore]]} {
   exec sleep 1
   incr count
   if {$count > 50} { break }
   puts " -W- waiting for directory '[file join $dir XilinxTclStore]'"
  }
  
  if {![file isdirectory [file join $dir XilinxTclStore]]} {
    cd $CWD
    error " -E- directory '[file join $dir XilinxTclStore]' does no exist"
  }
  
  cd [file join $dir XilinxTclStore]
  
  puts " -I- configuring Git"
  foreach [list exitCode message] [runGitCmd config http.proxy http://proxy:80] {break}
  foreach [list exitCode message] [runGitCmd config https.proxy https://proxy:80] {break}
  foreach [list exitCode message] [runGitCmd config http.postBuffer 524288000] {break}
  foreach [list exitCode message] [runGitCmd config https.postBuffer 524288000] {break}

  puts " -I- renaming remote origin -> upstream"
  foreach [list exitCode message] [runGitCmd remote rename origin upstream] {break}

  if {$gitUserID != {}} {
    puts " -I- adding remote origin"
    foreach [list exitCode message] [runGitCmd remote add origin https://$gitUserID@github.com/$gitUserID/XilinxTclStore.git] {break}
  }

  if {$commitSha1 != {}} {
    ::tclapp::tclstore::method:git_commit_id $commitSha1
  }

  if {$pullRequest != {}} {
    ::tclapp::tclstore::method:git_pull_request $pullRequest
  }

  # Set Git directory as default repo
  puts " -I- setting repository to [uplevel #0 pwd]"
  tclstore configure -repository [uplevel #0 pwd]

  cd $CWD

  return -code ok
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::method:git_changes
#------------------------------------------------------------------------
# Usage: tclstore git_changes
#------------------------------------------------------------------------
# Print the list of changes between HEAD and HEAD~1
#------------------------------------------------------------------------
proc ::tclapp::tclstore::method:git_changes {} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Show changed files from previous commit
  foreach [list exitCode message] [runGitCmd diff --name-status HEAD HEAD~1] {break}
  puts $message
  return -code ok
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::method:git_rev_parse
#------------------------------------------------------------------------
# Usage: tclstore git_rev_parse
#------------------------------------------------------------------------
# Return the 'git rev-parse master'.
#------------------------------------------------------------------------
proc ::tclapp::tclstore::method:git_rev_parse {} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Return the repo commit id
  return [::tclapp::tclstore::getGitRevParseMaster]
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::method:git_pull_request
#------------------------------------------------------------------------
# Usage: tclstore git_pull_request <pull_request_number>
#------------------------------------------------------------------------
# Merge pull request inside repository if applicable. If the pull
# request is anterior to HEAD, then the Git repo is reverted to
# the commit when the pull request was merged.
#------------------------------------------------------------------------
proc ::tclapp::tclstore::method:git_pull_request {pullRequest} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Merge pull request inside Git repository
  variable params
  variable verbose
  variable debug
  set error 0

  if {$params(git) == {}} {
    puts " -E- use tclstore config -git to specify the location to the 'git' command"
    incr error
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  if {$pullRequest != {}} {
    ::tclapp::tclstore::getGitRevParseMaster

    puts " -I- resetting HEAD"
    foreach [list exitCode message] [runGitCmd reset --hard e44d5e0bef613d50b7c6a54837ea597fda7ea51f] {break}
    
    ::tclapp::tclstore::getGitRevParseMaster

    puts " -I- merging pull request refs/pull/$pullRequest/head"
    foreach [list exitCode message] [runGitCmd pull upstream refs/pull/$pullRequest/head] {break}

    ::tclapp::tclstore::getGitRevParseMaster

    puts " -I- Git status"
    foreach [list exitCode message] [runGitCmd diff --name-status HEAD HEAD~1] {break}
    puts " -I- Status: $message"

  }
  
  return -code ok
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::method:git_commit_id
#------------------------------------------------------------------------
# Usage: tclstore git_commit_id <sha1>
#------------------------------------------------------------------------
# Revert repository to commit ID <sha1>
#------------------------------------------------------------------------
proc ::tclapp::tclstore::method:git_commit_id {commitSha1} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Revert Git repository to commit ID
  variable params
  variable verbose
  variable debug
  set error 0
  
  if {$params(git) == {}} {
    puts " -E- use tclstore config -git to specify the location to the 'git' command"
    incr error
  }

  if {$error} {
    error " -E- some error(s) happened. Cannot continue"
  }

  if {$commitSha1 != {}} {
    ::tclapp::tclstore::getGitRevParseMaster

    puts " -I- resetting repository to commit '$commitSha1'"
    foreach [list exitCode message] [runGitCmd reset --hard $commitSha1] {break}
    
    ::tclapp::tclstore::getGitRevParseMaster

    puts " -I- Git status"
    foreach [list exitCode message] [runGitCmd diff --name-status HEAD HEAD~1] {break}
    puts " -I- Status: $message"

  }

  return -code ok
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::method:reinstall_apps
#------------------------------------------------------------------------
# Usage: tclstore reinstall_apps
#------------------------------------------------------------------------
# Reinstall all installed apps.
#------------------------------------------------------------------------
proc ::tclapp::tclstore::method:reinstall_apps {} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Reinstall all installed apps
  foreach app [lsort [::tclapp::list_apps]] {
#     package forget $app
    package forget ::tclapp::$app
    puts " -I- Reloading : $app"
#     puts " -I- Reloading : $app ([lindex [split [regsub -all "::" $app " "] { }] 1 ])"
#     ::tclapp::update $app
    ::tclapp::uninstall [lindex [split [regsub -all "::" $app " "] { }] 1 ]
    ::tclapp::install [lindex [split [regsub -all "::" $app " "] { }] 1 ]
#     ::tclapp::update [lindex [split [regsub -all "::" $app " "] { }] 1 ]
    set pkgVersion [package version ::tclapp::$app]
    puts " -I- App version : $pkgVersion"
    puts " -I- App location : [lindex [getPkgPath ::tclapp::$app] 1]"
  }
  return -code ok
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::method:update_apps
#------------------------------------------------------------------------
# Usage: tclstore update_apps
#------------------------------------------------------------------------
# Update all installed apps.
#------------------------------------------------------------------------
proc ::tclapp::tclstore::method:update_apps {} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Update all installed apps
  foreach app [lsort [::tclapp::list_apps]] {
#     package forget $app
    package forget ::tclapp::$app
    puts " -I- Updating : $app"
#     puts " -I- Reloading : $app ([lindex [split [regsub -all "::" $app " "] { }] 1 ])"
#     ::tclapp::update $app
#     ::tclapp::uninstall [lindex [split [regsub -all "::" $app " "] { }] 1 ]
#     ::tclapp::install [lindex [split [regsub -all "::" $app " "] { }] 1 ]
    ::tclapp::update [lindex [split [regsub -all "::" $app " "] { }] 1 ]
    set pkgVersion [package version ::tclapp::$app]
    puts " -I- App version : $pkgVersion"
    puts " -I- App location : [lindex [getPkgPath ::tclapp::$app] 1]"
  }
  return -code ok
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::method:require_app
#------------------------------------------------------------------------
# Usage: tclstore require_app <app> [<version>]
#------------------------------------------------------------------------
# Require a particular app version. The app is automatically loaded
# when found.
#------------------------------------------------------------------------
proc ::tclapp::tclstore::method:require_app { appName {appVersion {}} } {
  # Summary :
  # Argument Usage:
  # Return Value:

  # Require a particular app name/version
  variable params
  variable verbose
  variable debug
  set app [getBaseName $appName]
  
  if {[lsearch -exact [::tclapp::list_apps] $app] == -1} {
    if {[catch {::tclapp::install $app} errorstring]} {
      puts " -E- could not find app '$app'"
      error " -E- could not find app '$app'"
    } else {
      set ver [getPkgVersion ::tclapp::$app]
    }
  } else {
    set ver [getPkgVersion ::tclapp::$app]
  }
  
  if {$appVersion != {}} {
    if {[package vcompare $ver $appVersion] < 0} {
      puts " -I- App '$app' version $ver"
#       puts " -E- App '$app' does not satisfy minimum app version $appVersion"
      error " -E- App '$app' does not satisfy minimum app version $appVersion"
    } else {
      puts " -I- App '$app' version $ver"
    }
  } else {
    puts " -I- App '$app' version $ver"
  }

  return -code ok
}

##-----------------------------------------------------------------------
## update_repo
##-----------------------------------------------------------------------
## Apply a patch or merge a pull request.
##-----------------------------------------------------------------------
# amend, modify, adjust, rebuild, repair, reconcile
proc ::tclapp::tclstore::method:update_repo {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # patch a repository from a pull request (-h)
  variable SCRIPT_VERSION
  variable verbose
  variable debug
  variable params

  set verbose 0
  set debug 0

  set workingDir [uplevel #0 pwd]
  set repository {}
  set commit [list]
  set action [list]
  # Target Git branch where merge should happen
  set target_branch {}
  # Current Git branch
  set current_branch {}
  set create_patch 0
  set apply_patch 0
  set check_patch 0
  set force 0
  set error 0
  set show_help 0
  set app {}
  if {[llength $args] == 0} {
    incr show_help
  }
  #-------------------------------------------------------
  # Process command line arguments
  #-------------------------------------------------------
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-r$} -
      {^-repository$} -
      {^-r(e(p(o(s(i(t(o(ry?)?)?)?)?)?)?)?)?$} {
        set repository [lshift args]
      }
      {^-b$} -
      {^-branch$} -
      {^-b(r(a(n(ch?)?)?)?)?$} {
        set target_branch [lshift args]
      }
      {^-p$} -
      {^-patch$} -
      {^-p(a(t(ch?)?)?)?$} {
        lappend commit [lshift args]
        lappend action {patch}
      }
      {^-m$} -
      {^-merge$} -
      {^-m(e(r(ge?)?)?)?$} {
        lappend commit [lshift args]
        lappend action {merge}
      }
      {^-c$} -
      {^-cherry_pick$} -
      {^-c(h(e(r(r(y(_(p(i(ck?)?)?)?)?)?)?)?)?)?$} {
        lappend commit [lshift args]
        lappend action {cherry_pick}
      }
      {^-create_patch$} -
      {^-create_patch$} -
      {^-create(_(p(a(t(c(h?)?)?)?)?)?)?$} {
          set create_patch 1
      }
      {^-apply_patch$} -
      {^-apply_patch$} -
      {^-apply(_(p(a(t(c(h?)?)?)?)?)?)?$} {
          set apply_patch 1
      }
      {^-check_patch$} -
      {^-check_patch$} -
      {^-check(_(p(a(t(c(h?)?)?)?)?)?)?$} {
          set check_patch 1
      }
      {^-v$} -
      {^-verbose$} -
      {^-v(e(r(b(o(se?)?)?)?)?)?$} {
          set verbose 1
      }
      {^-d$} -
      {^-debug$} -
      {^-d(e(b(ug?)?)?)?$} {
          set debug 1
          set verbose 1
      }
      {^-h$} -
      {^-help$} -
      {^-h(e(lp?)?)?$} {
          incr show_help
      }
      default {
          if {[string match "-*" $name]} {
            print error "option '$name' is not a valid option"
            incr error
          } else {
            print error "option '$name' is not a valid option"
            incr error
          }
      }
    }
  }

  if {$show_help} {
    # <-- HELP
    print stdout [format {
      Usage: tclstore update_repo
                  [-repository <dir>|-r <dir>]
                  [-branch <branch>|-b <branch>]
                  [-cherry_pick <pull_request>|-c <pull_request>]
                  [-merge <commitid|pull_request>|-m <commitid|pull_request>]
                  [-patch <commitid|pull_request>|-p <commitid|pull_request>]
                  [-create_patch][-check_patch][-apply_patch]
                  [-verbose|-v]
                  [-help|-h]

      Description: Utility to apply a patch to a local XilinxTclStore repository

      Version: %s

        Multiple -patch/-merge/-check_pick can be used in the same call, but the
        command line options cannot be mixed together.

        Windows Support:
        ----------------
          For Windows, the path to vivado.bat must be specified with --vivado=C:\Xilinx\Vivado\2014.3\bin\vivado.bat
                                                                     ^^      ^

      Example:
         tclstore update_repo -repository /home/dev/XilinxTclStore -patch 354
         tclstore update_repo -repository /home/dev/XilinxTclStore -patch 354 -create_patch
         tclstore update_repo -repository /home/dev/XilinxTclStore -patch 354 -check_patch
         tclstore update_repo -repository /home/dev/XilinxTclStore -patch 354 -apply_patch
         tclstore update_repo -repository /home/dev/XilinxTclStore -merge 354
         tclstore update_repo -repository /home/dev/XilinxTclStore -merge b50788b
         tclstore update_repo -repository /home/dev/XilinxTclStore -cherry_pick b50788b
    } $SCRIPT_VERSION ]
    # HELP -->

    return -code ok
  }

  if {$repository == {}} {
    # No repository provided. Check the case when XilinxTclStore is in current directory
    if {[file isdirectory [file join $workingDir XilinxTclStore]]} {
      set repository [file normalize [file join $workingDir XilinxTclStore]]
      # OK?
      if {![file isdirectory [file join $repository .git]]} {
        print error "directory $repository is not a valid Git directory"
        incr error
      } else {
        # OK
        print warning "set repository from working directory ($repository)"
      }
    } else {
      print error "no repository provided (-repository)"
      incr error
    }
  } elseif {![file isdirectory $repository]} {
    print error "[file normalize $repository] is not a directory"
    incr error
  } else {
    set repository [file normalize $repository]
    if {[lindex [file split $repository] end] == {XilinxTclStore}} {
      # OK?
      if {![file isdirectory [file join $repository .git]]} {
        print error "directory [file normalize $repository] is not a valid Git directory"
        incr error
      } else {
        # OK
      }
    } elseif {[file isdirectory [file join $repository XilinxTclStore]]} {
      set repository [file join $repository XilinxTclStore]
      # OK?
      if {![file isdirectory [file join $repository .git]]} {
        print error "[file normalize $repository] is not a valid Git directory"
        incr error
      } else {
        # OK
      }
    } else {
      print error "[file normalize $repository] is not a valid XilinxTclStore repository"
      incr error
    }
  }

  if {[llength [lsort -unique $action]] > 1} {
    print error "cannot mix -patch/-merge/-cherry_pick in the same call"
    incr error
  }

  if {[llength $commit] == 0} {
    print error "no commit id or pull request number provided (-patch/-merge/-cherry_pick)"
    incr error
  }

  if {$error} {
    error "\n Some error(s) occured. Cannot continue.\n"
#     exit -1
  }

  # if reach this line, the $action should be filled with same value(s)
  set action [lsort -unique $action]
  if {($action == {cherry_pick}) && ![isSha1 $commit]} {
    print error "only a commit id can be specified with -cherry_pick. Pull request(s) number are not valid"
    incr error
  }

  if {$action != {patch} && ($create_patch || $apply_patch || $check_patch)} {
    print error "-create_patch/-apply_patch/-check_patch are only valid with -patch"
    incr error
  } elseif {[expr $create_patch + $apply_patch + $check_patch] > 1} {
    print error "cannot use -create_patch/-apply_patch/-check_patch together"
    incr error
  }

  if {$params(initialized) == 0} {
    # Initialize git & curl
    if {[catch {initialize {git|curl}} errorstring]} {
      incr error
    }
  }

  if {$error} {
    error "\n Some error(s) occured. Cannot continue.\n"
#     exit -1
  }

  set params(repository) $repository

  if {[catch {

    # Go to repository so that Git commands can be issued
    cd $params(repository)

    # Get current Git branch
    foreach [list exitCode message] [runGitCmd rev-parse --abbrev-ref HEAD] {break}
    set current_branch $message
    print info "current Git branch '$current_branch'"

    if {$target_branch != {}} {
      # Get the list of branches
      foreach [list exitCode message] [runGitCmd branch -a] {break}
      # Dirty way to extract the list of existing branches from 'git branch -a'
      regsub -all {remotes/upstream/} $message {} all_branches
# print stdout [indentString [join [split $existing_branches \n ]] [string repeat {->} 5]]
      if {[lsearch $all_branches  $target_branch] != -1} {
        # The target branch already exists, switch to it
        print info "switching to Git branch '$target_branch'"
        foreach [list exitCode message] [runGitCmd checkout $target_branch] {break}
      } else {
        # The target branch does not exist, create it and switch to it
        print info "unknown Git branch '$target_branch'"
        print info "creating Git branch '$target_branch'"
        print info "switching to Git branch '$target_branch'"
        foreach [list exitCode message] [runGitCmd checkout -b $target_branch] {break}
      }
#       print info "switching to Git branch '$target_branch'"
#       foreach [list exitCode message] [runGitCmd checkout $target_branch] {break}
    } else {
      set target_branch $current_branch
    }

    foreach id $commit {
      switch $action {
        merge {
          if {[isSha1 $id]} {
            print info "merging commit id $id on branch '$target_branch'"
#             foreach [list exitCode message] [runGitCmd merge $id] {break}
            if {[catch { foreach [list exitCode message] [runGitCmd merge $id] {break} } errorstring ]} {
              print stdout "     -------------------------------------------------------"
              print stdout [indentString $errorstring [string repeat { } 5]]
            } else {
              print stdout "     -------------------------------------------------------"
              print stdout [indentString $message [string repeat { } 5]]
            }
            print stdout "     -------------------------------------------------------"
          } else {
#             print error "merging a pull request ($id) is not yet supported"
            print info "merging a pull request ($id) on branch '$target_branch' (upstream::refs/pull/${id}/head)"
            if {[catch { foreach [list exitCode message] [runGitCmd pull upstream refs/pull/${id}/head] {break} } errorstring ]} {
              print stdout "     -------------------------------------------------------"
              print stdout [indentString $errorstring [string repeat { } 5]]
            } else {
              print stdout "     -------------------------------------------------------"
              print stdout [indentString $message [string repeat { } 5]]
            }
            print stdout "     -------------------------------------------------------"
          }
        }
        patch {
          if {[isSha1 $id]} {
            print error "patching a commit id ($id) is not yet supported"
            if {0} {
              print info "patching commit id $id on branch '$target_branch'"
              foreach [list exitCode message] [runGitCmd format-patch $id] {break}
              foreach line [split $message \n] {
                print stdout "     -> patch [file normalize $line]"
                print info "stats for patch [file normalize $line]"
                foreach [list exitCode message1] [runGitCmd apply --stat $line] {break}
                print stdout [indentString $message1 [string repeat { } 5]]
#                 foreach [list exitCode message] [runGitCmd apply --stat $line] {break}
#                 foreach [list exitCode message] [runGitCmd apply --check $line] {break}
#                 foreach [list exitCode message] [runGitCmd apply $line] {break}
              }
            }
          } else {
#             print error "patching a pull request ($id) is not yet supported"

            # Patch filename
            set filename [file normalize [file join $params(repository) ${id}.patch]]

            if {$check_patch == 1} {
              checkGitPatch $filename
              continue
            }
            # If $apply_patch=0 it means that either -create_patch was specified or neither -create_patch/-apply_patch was specified
            if {$apply_patch == 0} {
              print info "creating patch for pull request $id (https://github.com/Xilinx/XilinxTclStore/pull/${id}.patch)"
              foreach [list exitCode message] [runCurlCmd https://github.com/Xilinx/XilinxTclStore/pull/${id}.patch > $filename ] {break}
              print info "patch created [file normalize $filename]"
              if {$create_patch} {
                print info "#######################################################"
                print info "patch not applied. Apply patch with 'git am < $filename'"
                print info "or re-run command with -apply_patch"
                print info "#######################################################"
                # Check patch
                checkGitPatch $filename
              }
            }
            # If $create_patch=0 it means that either -apply_patch was specified or neither -create_patch/-apply_patch was specified
            if {$create_patch == 0} {
              if {![file exists $filename]} {
                print error "expected patch '$filename' does not exists"
              } else {
                print info "applying patch for pull request $id ($filename)"
#                 foreach [list exitCode message] [system ssh git-dev [format {cd %s ; cat %s | %s %s} $params(repository) $pullRequest.patch $params(git) {am} ] ] { break }
#                 foreach [list exitCode message] [system ssh git-dev [format {cd %s ; %s %s < %s} $params(repository) $params(git) {am --signoff} $pullRequest.patch ] ] { break }
#                 foreach [list exitCode message] [runGitCmd am < $params(repository)/${id}.patch ] ] { break }
#                 foreach [list exitCode message] [system $params(gitbin) am < $params(repository)/${id}.patch ] ] { break }

#                 foreach [list exitCode message] [runGitCmd am < $params(repository)/${id}.patch ] ] { break }
                if {[catch { foreach [list exitCode message] [runGitCmd am < $filename] {break} } errorstring ]} {
                  print stdout "     -------------------------------------------------------"
                  print stdout [indentString $errorstring [string repeat { } 5]]
                } else {
                  print stdout "     -------------------------------------------------------"
                  print stdout [indentString $message [string repeat { } 5]]
                }
                print stdout "     -------------------------------------------------------"

                print info "Git status"
                foreach [list exitCode message] [runGitCmd diff --name-status HEAD HEAD~1] {break}
                print stdout [indentString $message [string repeat { } 5]]
              }
            }


          }
        }
        cherry_pick {
          print info "cherry picking commit id $id on branch '$target_branch'"
          if {[catch { foreach [list exitCode message] [runGitCmd cherry-pick $id] {break} } errorstring ]} {
            print stdout "     -------------------------------------------------------"
            print stdout [indentString $errorstring [string repeat { } 5]]
          } else {
            print stdout "     -------------------------------------------------------"
            print stdout [indentString $message [string repeat { } 5]]
          }
          print stdout "     -------------------------------------------------------"
        }
        default {
         print error "unknown action '$action'"
       }
      }
    }

    print info "Git log for branch '$target_branch' (last [expr [llength $commit] +1] commits)"
#     foreach [list exitCode message] [runGitCmd log --pretty=oneline --abbrev-commit HEAD~[expr [llength $commit] +1]..HEAD] {break}
    foreach [list exitCode message] [runGitCmd log --pretty=oneline HEAD~[expr [llength $commit] +1]..HEAD] {break}
    print stdout [indentString $message [string repeat { } 5]]

    # Revert the Git branch
    print info "reverting to Git branch '$current_branch'"
    foreach [list exitCode message] [runGitCmd checkout $current_branch] {break}

    # Return to working directory
    cd $workingDir

#     set answer [ask {It's time to enter the revision history} {Revision history?} {%} {^.+$}]
#     print stdout "<answer:$answer>"

  } errorstring]} {
    # Revert the Git branch
    if {$current_branch != {}} {
      print info "reverting to Git branch '$current_branch'"
      foreach [list exitCode message] [runGitCmd checkout $current_branch] {break}
    }

    # Return to working directory
    cd $workingDir

    print stdout [ERROR]
    error $errorstring
  }

  return -code ok
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::method:checkGitPatch
#------------------------------------------------------------------------
# Usage: checkGitPatch <filename>
#------------------------------------------------------------------------
# Check that a patch can be pulled inside inside repository.
#------------------------------------------------------------------------
proc ::tclapp::tclstore::checkGitPatch {filename} {
  variable params
  variable verbose
  variable debug

  if {![file exists [file normalize $filename]]} {
    print error "patch $filename does not exist"
    return -code ok
  }

  print info "checking changes from patch [file normalize $filename]"
  foreach [list exitCode message] [runGitCmd apply --stat $filename] {break}
  print stdout [indentString $message [string repeat { } 5]]

  print info "testing patch [file normalize $filename]"
  if {[catch { foreach [list exitCode message] [runGitCmd apply --check $filename] {break} } errorstring ]} {
    print stdout "     -------------------------------------------------------"
    print stdout [indentString $errorstring [string repeat { } 5]]
  } else {
    print stdout "     -------------------------------------------------------"
    print stdout [indentString $message [string repeat { } 5]]
  }
  print stdout "     -------------------------------------------------------"

  return -code ok
}

#------------------------------------------------------------------------
# ::tclapp::tclstore::isSha1
#------------------------------------------------------------------------
# **INTERNAL**
#------------------------------------------------------------------------
# Return 1 if any of the commit(s) matches a SHA1 commit id
#------------------------------------------------------------------------
proc ::tclapp::tclstore::isSha1 {ids} {
  foreach id $ids {
    # SHA1 format (7 or 40 alphanumeric characters)?
    if {[regexp {^([0-9a-zA-Z]{40}|[0-9a-zA-Z]{10}|[0-9a-zA-Z]{7})$} $id]} {
      return 1
    }
  }
  return 0
}


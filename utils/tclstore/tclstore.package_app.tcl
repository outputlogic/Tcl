##-----------------------------------------------------------------------
## package_app
##-----------------------------------------------------------------------
## Package an app by updating/generating all system files. Vivado is
## run in the background.
##-----------------------------------------------------------------------
proc ::tclapp::tclstore::method:package_app {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # package an app (-h)
  variable SCRIPT_VERSION
  variable verbose
  variable debug
  variable params

  set verbose 0
  set debug 0

  set workingDir [uplevel #0 pwd]
  set repository {}
  set revision_history {}
  set shallow 0
  set rebuild_app 1
  set rebuild_app_xml 1
  set rebuild_release_xml 1
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
      {^-a$} -
      {^-app$} -
      {^-a(pp?)?$} {
        set app [getAppBaseName [lshift args] ]
      }
      {^-rev$} -
      {^-revision$} -
      {^-rev(i(s(i(o(n(_(h(i(s(t(o(ry?)?)?)?)?)?)?)?)?)?)?)?)?$} {
        set revision_history [lshift args]
      }
      {^-shallow$} -
      {^-shallow$} {
          set shallow 1
      }
      {^-no_release_xml$} -
      {^-n(o(_(r(e(l(e(a(s(e(_(x(ml?)?)?)?)?)?)?)?)?)?)?)?)?$} {
          set rebuild_app 1
          set rebuild_app_xml 1
          set rebuild_release_xml 0
      }
      {^-only_release_xml$} -
      {^-o(n(l(y(_(r(e(l(e(a(s(e(_(x(ml?)?)?)?)?)?)?)?)?)?)?)?)?)?)?$} {
          set rebuild_app 0
          set rebuild_app_xml 0
          set rebuild_release_xml 1
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
      Usage: tclstore package_app
                  -app <app>|-a <app>
                  -revision <revision_history>
                  [-repository <dir>|-r <dir>]
                  [-shallow]
                  [-no_release_xml][-only_release_xml]
                  [-verbose|-v]
                  [-help|-h]

      Description: Utility to package an app

      Version: %s

        This commands updates all the system files under the app area such as
        tclIndex, pkgIndex, and the app XML. To be able to test the app in the GUI, the
        release catalog XML is also updated.

        In addition, the command verifies that the doc/legal.txt and test/test.tcl files
        exist. However, the regression suite is not being executed.

        Use -no_release_xml to skip the update of the release catalog XML. This will
        prevent GUI testing.

        Use -only_release_xml to only update the release catalog XML. The catalog version
        is based on the Vivado release available on the system.

        Note: the release catalog XML should not be commited to Github and added to
        the pull request

        Use -shallow to exclude proc information from the app XML (uncommon).

        Windows Support:
        ----------------
          For Windows, the path to vivado.bat must be specified with --vivado=C:\Xilinx\Vivado\2014.3\bin\vivado.bat
                                                                     ^^      ^

      Example:
         tclstore package_app -app "xilinx::designutils" -repository /home/dev/XilinxTclStore -revision "Fixes issue ..."
         tclstore package_app -app "xilinx::modelsim" -shallow -repository /home/dev/XilinxTclStore -revision "Fixes issue ..."
         tclstore package_app -app "xilinx::modelsim" -shallow -repository /home/dev/XilinxTclStore -revision "Fixes issue ..." --vivado=C:\Xilinx\Vivado\2014.3\bin\vivado.bat
    } $SCRIPT_VERSION ]
    # HELP -->

    return -code ok
  }

  if {$app == {}} {
    print error "no app specified (-app)"
    incr error
  } else {
    if {![regexp {^[^:]+::[^:]+$} $app]} {
      print error "app '$app' does not match format <COMPANY>::<APP>"
      incr error
    }
  }

  # -app/-revision is only mandatory when -only_release_xml is _not_specified
  if {$revision_history == {} && ($rebuild_app) && ($rebuild_app_xml)} {
    print error "no revision history specified (-revision)"
    incr error
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

  if {$error} {
    error "\n Some error(s) occured. Cannot continue.\n"
#     exit -1
  }

  if {$params(initialized) == 0} {
    if {[catch {initialize} errorstring]} {
      incr error
    }
  }

  set githubCatalogXML [format {https://raw.githubusercontent.com/Xilinx/XilinxTclStore/master/catalog/catalog_%s.xml} $params(vivadoversion)]
  print info "Github catalog XML: $githubCatalogXML"
  foreach [list exitCode result]  [runCurlCmd $githubCatalogXML] {break}
  regexp {<remote>\s*(.+)\s*</remote>} $result - params(gitbranch)
  print info "Git branch from Github XML: $params(gitbranch)"
  if {$params(gitbranch) == {}} {
    print error "cannot extract branch from XML"
    incr error
  }

  if {$error} {
    error "\n Some error(s) occured. Cannot continue.\n"
#     exit -1
  }

  set params(app) $app
  set params(repository) $repository

  if {[catch {

    set script {}
    ########## Vivado run script <<<<<<<<<<<<<<<<
    append script [format {
  source -notrace {%s}
  set repository {%s}
  set app {::tclapp::%s}
  set appdir [file join $repository {*}[regsub -all "::" $app " "]]
  puts "<<APPDIR>>$appdir<</APPDIR>>"
} [info script] $params(repository) $params(app) ]
    ########## Vivado run script >>>>>>>>>>>>>>>>

    if {$rebuild_app} {
      ########## Vivado run script <<<<<<<<<<<<<<<<
      append script [format {

    # Forget packages
    puts "<<PACKAGEFORGET>>"
    foreach pkg [package names] {
      if {![regexp {^::tclapp::} $pkg]} { continue }
      if {[regexp {^::tclapp::support::} $pkg]} { continue }
      puts " -I- Package forget $pkg version [package version $pkg]"
      package forget $pkg
    }
    puts "<</PACKAGEFORGET>>"

    # Linter
    puts "<<LINTER>>"
    foreach file [lsort [glob -nocomplain [file join $appdir *.tcl]]] {
      if {[regexp {^(pkgIndex.tcl|tclIndex)$} [file tail $file]]} {
        continue
      }
      if {[catch {lint_files $file} errorstring]} {
        puts " -I- Linter failed on $file: $errorstring"
      } else {
        puts " -I- Linter passed on $file"
      }
    }
    puts "<</LINTER>>"

    # pkgIndex.tcl
    puts "<<PKGINDEX>>"
    puts " -I- Rebuilding pkgIndex.tcl for $app ($appdir)"
    pkg_mkIndex $appdir
    puts "<</PKGINDEX>>"

    # tclIndex
    puts "<<TCLINDEX>>"
    puts " -I- Rebuilding tclIndex for $app ($appdir)"
    auto_mkindex $appdir
    puts "<</TCLINDEX>>"
    set listProcs [::tclapp::support::appinit::get_app_procs $repository $app]
    puts -nonewline "<<PROCS>>"
    puts -nonewline $listProcs
    puts "<</PROCS>>"
    set FH [open [file join $appdir tclIndex] {r}]
    set tclIndexContent [list]
    set tclIndexProcs [list]
    foreach line [split [read $FH] \n] {
      if {[regexp [format {^(.+%%s)\:\:([^\s\)]+)\)(.+)$} $app] $line -- prefix procname suffix]} {
        if {[lsearch -exact $listProcs $procname] != -1} {
#           lappend tclIndexContent $line
          lappend tclIndexProcs $line
        } else {
          switch -glob -- [version -short] {
            2014.3* {
#               lappend tclIndexContent "# $line"
#               lappend tclIndexProcs "# $line"
            }
            default {
#               lappend tclIndexContent "# $line"
#               lappend tclIndexProcs "# $line"
            }
          }
        }
      } else {
        lappend tclIndexContent $line
      }
    }
    close $FH
    set FH [open [file join $appdir tclIndex] {w}]
    puts $FH [join [concat $tclIndexContent [lsort $tclIndexProcs]] \n]
    # Replace "source" -> "source -trace"
#     puts $FH [regsub -all {list source} [join [concat $tclIndexContent [lsort $tclIndexProcs]] \n] {list source -notrace}]
    close $FH

}]
      ########## Vivado run script >>>>>>>>>>>>>>>>
    }

    if {$rebuild_app_xml} {
      if {$shallow} {
        ########## Vivado run script <<<<<<<<<<<<<<<<
        append script [format {
    # App XML
    puts "<<APPXML>>"
    tclapp::update_app_catalog -shallow [regsub {::tclapp::} $app {}] {%s}
    puts "<</APPXML>>"
}   $revision_history ]
        ########## Vivado run script >>>>>>>>>>>>>>>>
      } else {
        ########## Vivado run script <<<<<<<<<<<<<<<<
        append script [format {
    # App XML
    puts "<<APPXML>>"
    tclapp::update_app_catalog [regsub {::tclapp::} $app {}] {%s}
    puts "<</APPXML>>"
}   $revision_history ]
        ########## Vivado run script >>>>>>>>>>>>>>>>
      }
    }

    if {$rebuild_release_xml} {
      ########## Vivado run script <<<<<<<<<<<<<<<<
      if {$params(app) != {}} {
        append script [format {
    # Release catalog XML
    puts "<<RELEASEXML>>"
    tclapp::update_catalog {%s}
    puts "<</RELEASEXML>>"
}   $params(app) ]
      } else {
        # If no app has been specified, do not add anything to tclapp::update_catalog
        append script [format {
    # Release catalog XML
    puts "<<RELEASEXML>>"
    tclapp::update_catalog
    puts "<</RELEASEXML>>"
}]
      }
    ########## Vivado run script >>>>>>>>>>>>>>>>
    }

    foreach [list exitCode vivadolog] [runVivadoCmd [split $script \n]] { break }

    set error $exitCode
    set warning 0
    set packageforgetlog {} ; set linterlog {} ; set pkgindexlog {} ; set tclindexlog {}
    set appxmlog {} ; set releasexmllog {} ; set errorlog {} ; set appdir {} ; set procs {}
    regexp {<<PACKAGEFORGET>>(.+)<</PACKAGEFORGET>>} $vivadolog - packageforgetlog
    regexp {<<LINTER>>(.+)<</LINTER>>} $vivadolog - linterlog
    regexp {<<PKGINDEX>>(.+)<</PKGINDEX>>} $vivadolog - pkgindexlog
    regexp {<<TCLINDEX>>(.+)<</TCLINDEX>>} $vivadolog - tclindexlog
    regexp {<<APPXML>>(.+)<</APPXML>>} $vivadolog - appxmlog
    regexp {<<RELEASEXML>>(.+)<</RELEASEXML>>} $vivadolog - releasexmllog
    regexp {<<VIVADOERROR>>(.+)<</VIVADOERROR>>} $vivadolog - errorlog
    regexp {<<APPDIR>>(.+)<</APPDIR>>} $vivadolog - appdir
    regexp {<<PROCS>>(.+)<</PROCS>>} $vivadolog - procs

    if {$rebuild_app} {
      if {$verbose} {
        print stdout "  ############################################"
        print stdout "  ## Package Forget"
        print stdout "  ############################################"
        print stdout [indentString $packageforgetlog [string repeat { } 2]]
      }

      print stdout "  ############################################"
      print stdout "  ## Linter Check"
      print stdout "  ############################################"
      print stdout [indentString $linterlog [string repeat { } 2]]
      if {[regexp -nocase {Errors were found} $linterlog]} {
        incr error
        print stdout [ERROR]
      }

      print stdout "  ############################################"
      print stdout "  ## pkgIndex Generation"
      print stdout "  ############################################"
      print stdout [indentString $pkgindexlog [string repeat { } 2]]

      print stdout "  ############################################"
      print stdout "  ## tclIndex Generation"
      print stdout "  ############################################"
      print stdout [indentString $tclindexlog [string repeat { } 2]]
    }

    if {$rebuild_app_xml} {
      print stdout "  ############################################"
      print stdout "  ## App XML Catalog"
      print stdout "  ############################################"
      print stdout [indentString $appxmlog [string repeat { } 2]]
    }

    if {$rebuild_release_xml} {
      print stdout "  ############################################"
      print stdout "  ## Release XML Catalog"
      print stdout "  ############################################"
      print stdout [indentString $releasexmllog [string repeat { } 2]]
    }

    if {$rebuild_app} {
      print stdout "  ############################################"
      print stdout "  ## Regression Suite"
      print stdout "  ############################################"
      if {$appdir != {}} {
        set testscript [file join $appdir test test.tcl]
        if {[file exists $testscript]} {
          print info "found test script [file normalize $testscript]"
        } else {
          print error "missing test script [file normalize $testscript]"
          print stdout [ERROR]
          incr error
        }
      } else {
      }
    }

    if {$rebuild_app} {
      print stdout "\n  ############################################"
      print stdout "  ## Legal Document"
      print stdout "  ############################################"
      if {$appdir != {}} {
        set legaldoc [file join $appdir doc legal.txt]
        if {[file exists $legaldoc]} {
          print info "found legal document [file normalize $legaldoc]"
        } else {
          print error "missing legal document [file normalize $legaldoc]"
          print stdout [ERROR]
          incr error
        }
      } else {
      }
    }

    if {$rebuild_app} {
      print stdout "\n  ############################################"
      print stdout "  ## Procs Long Help"
      print stdout "  ############################################"
      if {$appdir != {}} {
        set count 0
        set missing 0
        foreach proc [lsort $procs] {
          set procdoc [file join $appdir doc $proc]
          if {[file exists $procdoc]} {
            if {$verbose} {
              print info "found long help for '$proc' ([file normalize $procdoc])"
            }
            incr count
          } else {
            print warning "missing long help for '$proc' ([file normalize $procdoc])"
            incr missing
          }
        }
        print info "found $count procs with long help"
        if {$missing} {
          print warning "$missing procs have missing long help"
          incr warning
#           print stdout [WARNING]
          print stdout [MISSING]
        }
      } else {
      }
    }

    print stdout "\n  ############################################"
    print stdout "  ## GIT Summary"
    print stdout "  ############################################"
    if {$params(repository) != {}} {
      cd $params(repository)
      foreach [list exitCode message] [runGitCmd branch] {break}
      # Extract the branch from the line that has '*'
      # E.g:
      #  * 2014.4
      #    master
      regexp {\*\s+([^\s]+)(\s|$)} $message - params(gitbranch)
      print info "Git branch: $params(gitbranch)"
      foreach [list exitCode message] [runGitCmd status] {break}
      print info "Git status:"
      print stdout [indentString $message [string repeat { } 5]]
      cd $workingDir
    } else {
      print warning "empty Xilinx Tcl Store repository"
    }

    print stdout "\n  ########################################################################################\n"

    if {$error == 0} {
      if {$warning} {
#         print stdout [OKBUT]
        print stdout [CHECK]
        print stdout "  ... check whether above warning(s) need to be addressed"
      } else {
        print stdout [OK]
      }
      print stdout [show_message2 $revision_history]
    } else {
      print stdout [FAILED]
      if {$errorlog != {}} {
        print stdout "  ############################################"
        print stdout "  ## ERROR from Vivado Log"
        print stdout "  ############################################"
        print stdout [indentString $errorlog [string repeat { } 2]]
      }
    }

#     set answer [ask {It's time to enter the revision history} {Revision history?} {%} {^.+$}]
#     print stdout "<answer:$answer>"

  } errorstring]} {
    print stdout [ERROR]
    error $errorstring
  }

  # Some cleanup
  if {[file exists [file join $params(repository) tclstore.wpc]]} {
    catch { file delete [file join $params(repository) tclstore.wpc] }
  }

  return -code ok
}

##-----------------------------------------------------------------------
## show_message2
##-----------------------------------------------------------------------
## Instructions.
##-----------------------------------------------------------------------

proc ::tclapp::tclstore::show_message2 { revision_history } {
  variable params
  set appdir [file join {tclapp} [regsub -all "::" $params(app) [file separator] ] ]
  return [format {
  Instructions:
  =============
     1) All the files have been updated under the app area. If you are the app owner, make sure that
        the app version has been updated. If you need to modify the app version at this point, you
        will need to re-run 'tclstore package_app' command.
     2) Test the app in the GUI. Before running Vivado, set the following environment variables:
           setenv XILINX_TCLAPP_REPO %s
           setenv XILINX_LOCAL_USER_DATA NO
     3) Run the regression test (test/test.tcl)
     4) Check that doc/legal.txt has been digitally signed
     5) Once all the files have been verified, the changes should be commited to your Github repository.
        You won't be able to commit directly to the Xilinx's Github repository so you will have to
        commit through your Guthub repository
          cd %s
          git checkout %s
          git pull upstream %s
          git add %s
          git commit -m '%s'
          git push origin %s
     7) To revert changes made to the release catalog area
          git checkout -- catalog/catalog_%s.xml catalog/%s
     8) From Github.com, select the Git branch '%s' and send a pull request
} $params(repository) \
  $params(repository) \
  $params(gitbranch) \
  $params(gitbranch) \
  $appdir \
  $revision_history \
  $params(gitbranch) \
  $params(vivadoversion) \
  $params(vivadoversion) \
  $params(gitbranch) \
  ]
}

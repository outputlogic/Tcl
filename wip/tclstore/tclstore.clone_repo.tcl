##-----------------------------------------------------------------------
## clone_repo
##-----------------------------------------------------------------------
## Clone Xilinx Tcl Store repository from Github
##-----------------------------------------------------------------------
proc ::tclapp::tclstore::method:clone_repo {args} {
  # Summary :
  # Argument Usage:
  # Return Value:

  # clone the Xilinx Tcl Store repository (-h)
  variable SCRIPT_VERSION
  variable verbose
  variable debug
  variable params

  set verbose 0
  set debug 0

  set workingDir [uplevel #0 pwd]
  set force 0
  set gitcloning {single-branch}
  set error 0
  set show_help 0
  set localDirectory {}
  if {[llength $args] == 0} {
    incr show_help
  }
  #-------------------------------------------------------
  # Process command line arguments
  #-------------------------------------------------------
  while {[llength $args]} {
    set name [lshift args]
    switch -regexp -- $name {
      {^-d$} -
      {^-dir$} -
      {^-d(ir?)?$} {
        set localDirectory [lshift args]
      }
      {^-u$} -
      {^-user$} -
      {^-u(s(er?)?)?$} {
        set params(gituser) [lshift args]
      }
      {^-f$} -
      {^-force$} -
      {^-f(o(r(ce?)?)?)?$} {
          set force 1
      }
      {^-clone_all$} -
      {^-clone_all_branch$} -
      {^-clone_all_branches$} -
      {^-c(l(o(n(e(_(a(l(l(_(b(r(a(n(c(h(es?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?)?$} {
          set gitcloning {all-branches}
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
      Usage: tclstore clone_repo
                  -dir <path>|-d <path>
                  -user <github_username>|-u <github_username>
                  [-verbose|-v]
                  [-help|-h]

      Description: Utility to clone the Xilinx Tcl Store repository to local directory

      Version: %s

        This command clones the Xilinx Tcl Store repository to a local directory. The 'vivado' command,
        'git' and 'curl' binaries must be available in PATH. The command clones a single branch
        from the Git repository based on the Vivado release in PATH and the Git branch used by this
        specific release. The Git branch is extracted from the release catalog XML from Github.

        Note: The vivado release available from the shell must match the release you want to contribute to.
        In most case, you are only allowed to contribute to the latest Vivado release.

        The command automatically sets the proxy information and the origin/upstream remotes. The origin
        remotes points to the user's Github repository and the upstream remotes points to the Xilinx's Github
        repository.

        Windows Support:
        ----------------
          For Windows, the path to vivado.bat must be specified with --vivado=C:\Xilinx\Vivado\2014.3\bin\vivado.bat
                                                                     ^^      ^

      Example:
         tclstore clone_repo -dir . -user frank
         tclstore clone_repo -dir . -user frank --vivado=C:\Xilinx\Vivado\2014.3\bin\vivado.bat
    } $SCRIPT_VERSION ]
    # HELP -->

    return -code ok
  }

  if  {$params(gituser) == {}} {
    print error "no Github user name provided (-user)"
    incr error
  }

  if  {$localDirectory == {}} {
    print error "no directory provided (-dir)"
    incr error
  } elseif {![file isdirectory $localDirectory]} {
    if {!$force} {
      print error "directory '$localDirectory' does not exist"
      incr error
    } else {
      print info "creating directory '$localDirectory'"
      file mkdir $localDirectory
    }
  } else {
    if {[file isdirectory [file join $localDirectory XilinxTclStore]]} {
      print error "directory '[file normalize $localDirectory/XilinxTclStore]' already exists"
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

  if {$error} {
    error "\n Some error(s) occured. Cannot continue.\n"
#     exit -1
  }

  if {[catch {
    set localDirectory [file normalize $localDirectory]
    set params(repository) [file join $localDirectory XilinxTclStore]
  #   set vivadoBin [exec which vivado]
    set vivadoBin $params(vivadobin)
    set vivadoInstallDir [join [lrange [file split $vivadoBin] 0 end-2] [file separator] ]
    set vivadoTclStoreDir [file join $vivadoInstallDir data XilinxTclStore]
    print info "Vivado install dir: $vivadoInstallDir"
    print info "Vivado Tcl Store dir: $vivadoTclStoreDir"
    if {![file isdirectory $vivadoTclStoreDir]} {
      error " -E- directory $vivadoTclStoreDir does not exist"
    }
    set vivadoCatalogXML [file join $vivadoTclStoreDir catalog "catalog_$params(vivadoversion).xml"]
    print info "Vivado catalog XML: $vivadoCatalogXML"
    if {![file exists $vivadoCatalogXML]} {
      error " -E- file $vivadoCatalogXML does not exist"
    }

    # E.g:   <remote>master</remote>
    set result [read_file_regexp $vivadoCatalogXML {<remote>}]
    set vivadoRepoBranch {}
    regexp {<remote>\s*(.+)\s*</remote>} $result - vivadoRepoBranch
    print info "Git branch from Vivado XML: $vivadoRepoBranch"
    if {$vivadoRepoBranch == {}} {
      error " -E- cannot extract branch from XML"
    }

    set githubCatalogXML [format {https://raw.githubusercontent.com/Xilinx/XilinxTclStore/master/catalog/catalog_%s.xml} $params(vivadoversion)]
    print info "Github catalog XML: $githubCatalogXML"

#     foreach [list exitCode result]  [system $params(curlbin) $githubCatalogXML -x $params(proxy.https)] {break}
    foreach [list exitCode result]  [runCurlCmd $githubCatalogXML] {break}
    regexp {<remote>\s*(.+)\s*</remote>} $result - params(gitbranch)
    print info "Git branch from Github XML: $params(gitbranch)"
    if {$params(gitbranch) == {}} {
      error " -E- cannot extract branch from XML"
    }

    cd $localDirectory
    if {$gitcloning == {all-branches}} {
      print info "cloning Xilinx GitHub repository (all branches) to [file normalize $localDirectory]"
      if {$params(gituser) == {}} {
        foreach [list exitCode message] [runGitCmd clone https://github.com/Xilinx/XilinxTclStore.git] {break}
      } else {
        foreach [list exitCode message] [runGitCmd clone https://$params(gituser)@github.com/Xilinx/XilinxTclStore.git] {break}
      }
      cd $params(repository)
      print info "checking out branch $params(gitbranch)"
      foreach [list exitCode message] [runGitCmd checkout $params(gitbranch)] {break}
    } else {
      print info "cloning Xilinx GitHub repository (branch $params(gitbranch)) to [file normalize $localDirectory]"
      if {$params(gituser) == {}} {
        foreach [list exitCode message] [runGitCmd clone -b $params(gitbranch) --single-branch https://github.com/Xilinx/XilinxTclStore.git] {break}
      } else {
        foreach [list exitCode message] [runGitCmd clone -b $params(gitbranch) --single-branch https://$params(gituser)@github.com/Xilinx/XilinxTclStore.git] {break}
      }
    }
#     if {$params(gituser) == {}} {
#       foreach [list exitCode message] [runGitCmd clone -b $params(gitbranch) --single-branch https://github.com/Xilinx/XilinxTclStore.git] {break}
#     } else {
#       foreach [list exitCode message] [runGitCmd clone -b $params(gitbranch) --single-branch https://$params(gituser)@github.com/Xilinx/XilinxTclStore.git] {break}
#     }
    cd $workingDir

    if {$exitCode} {
      cd $workingDir
      error " -E- $message"
    }

    print info "configuring Git"
    cd $params(repository)
    if {$params(proxy.https) != {}} {
      foreach [list exitCode message] [runGitCmd config https.proxy $params(proxy.https)] {break}
    }
    if {$params(proxy.http) != {}} {
      foreach [list exitCode message] [runGitCmd config http.proxy $params(proxy.http)] {break}
    }
#     foreach [list exitCode message] [runGitCmd config http.proxy $params(proxy.http)] {break}
#     foreach [list exitCode message] [runGitCmd config https.proxy $params(proxy.https)] {break}
    foreach [list exitCode message] [runGitCmd config http.postBuffer 524288000] {break}
    foreach [list exitCode message] [runGitCmd config https.postBuffer 524288000] {break}
    cd $workingDir

    print info "renaming remote origin -> upstream"
    cd $params(repository)
    foreach [list exitCode message] [runGitCmd remote rename origin upstream] {break}
    cd $workingDir

    if {$params(gituser) != {}} {
      print info "adding remote origin to https://$params(gituser)@github.com/$params(gituser)/XilinxTclStore.git"
      cd $params(repository)
      foreach [list exitCode message] [runGitCmd remote add origin https://$params(gituser)@github.com/$params(gituser)/XilinxTclStore.git] {break}
      cd $workingDir
    }

    print stdout [OK]

    print info "set the following environment variables to point to the local repository:"
    print info "########################################################################"
    print info "setenv XILINX_TCLAPP_REPO $params(repository)"
    print info "setenv XILINX_LOCAL_USER_DATA NO"
    print info "########################################################################"

    print stdout [show_message1]

  } errorstring]} {
    print stdout [ERROR]
    error $errorstring
  }

#   set answer [ask {The flow between a app owner and a contributor is different} {Are you the apps owner or just a contributor? (Y/N)} {%} {^(y|Y|n|N)$}]
#   print stdout "<answer:$answer>"

  return -code ok
}

##-----------------------------------------------------------------------
## show_message1
##-----------------------------------------------------------------------
## Instructions.
##-----------------------------------------------------------------------

proc ::tclapp::tclstore::show_message1 {} {
  variable params
  return [format {
  Instructions:
  =============
     1) The Xilinx's Tcl Store repository has been cloned to the local directory.
        Only branch '%s' has been cloned has it matches the branch used by Vivado %s
     2) Modify app file(s) under the local repository %s
     3) Checklist:
         a) Update the app version only if you are the app owner
         b) Add a regression test for each new user proc that has been added
         c) Digitally sign the doc/legal.txt document
     4) Generate/update all the files used by the Tcl Store with 'tclstore package_app' command.
} $params(gitbranch) $params(vivadoversion) $params(repository) ]
}

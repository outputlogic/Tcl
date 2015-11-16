#!/bin/sh

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

help() {
  message=`cat <<EOF
  usage: summary.do [-f|-t|-force|-tmp][-h|-help]
    
  -tmp | -t    - Generate the summary on a copy of the database
                 Recommended when LSF jobs are still running
  -force | -f  - Generate the summary on the database 
                 Recommended when LSF jobs have all completed
EOF
`
  echo ""
  echo "$message"
}

#----------------------------------------
# parse command line arguments
#----------------------------------------
error=0
while [ $# -ne 0 ]; 
do
  arg="$1"
  case "$arg" in
    -t | --t | -tmp | --tmp )
       # Generate the summary on a copy of the database
       \cp ${DIR}/metrics.db ${DIR}/tmp.db
       # ~/git/scripts/wip/snapshot/snapshot_summary -db ${DIR}/tmp.db -save -show_hold -show_directive
       ~/git/scripts/wip/snapshot/snapshot_summary -db ${DIR}/tmp.db -save -show_hold
       echo ""
       exit 0
       ;;
    -f | --f | -force | --force )
       # Generate the summary of the database
       # ~/git/scripts/wip/snapshot/snapshot_summary -db ${DIR}/metrics.db -sort -save -runtime -show_hold -show_directive
       ~/git/scripts/wip/snapshot/snapshot_summary -db ${DIR}/metrics.db -save -show_hold
       echo ""
       exit 0
       ;;
    -h | -help )
       # Remove all the links
       help
       echo ""
       exit 0
       ;;
    *)
       echo "  ERROR: $arg is not a valid argument."
       let error++
       ;;
  esac
  shift
done

if [ $error -gt 0 ]
then
  echo ""
  exit 1
fi

# No command line argument - show help
help
echo ""

exit 0

# # ~/git/scripts/wip/snapshot/snapshot_summary -db ${DIR}/metrics.db -sort -save -runtime -show_all_hold
# # ~/git/scripts/wip/snapshot/snapshot_summary -db ${DIR}/metrics.db -save -show_all_hold
# # exit 0
# 
# \cp ${DIR}/metrics.db ${DIR}/tmp.db
# ~/git/scripts/wip/snapshot/snapshot_summary -db ${DIR}/tmp.db -save -show_all_hold

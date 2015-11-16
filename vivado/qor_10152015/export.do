#!/bin/sh

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

help() {
  message=`cat <<EOF
  usage: export.do [-f|-t|-force|-tmp][-h|-help]
    
  -tmp | -t    - Export the metrics on a copy of the database
                 Recommended when LSF jobs are still running
  -force | -f  - Export the metrics on the database 
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
       # Export the metrics on a copy of the database
       \cp ${DIR}/metrics.db ${DIR}/tmp.db
       snapshot db2dir -db ${DIR}/tmp.db -dir ${DIR}/export -html -force -default_top_metrics -top_metrics "directive=Directive duration=Runtime"
       echo ""
       exit 0
       ;;
    -f | --f | -force | --force )
       # Export the metrics of the database
       snapshot db2dir -db ${DIR}/metrics.db -dir ${DIR}/export -html -force -default_top_metrics -top_metrics "directive=Directive duration=Runtime"
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

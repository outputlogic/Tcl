#!/bin/sh

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
TS=$(stat -c '%Y' "$DIR")
TIMESTAMP=$(date -d @${TS} +'%d %b %Y %R')

help() {
  message=`cat <<EOF
  usage: export.do [-f|-tmp|-db <database(s)>][-h]

  -db      - List of database(s). Must be the last argument
             on the command line
  -tmp     - Export the metrics on a copy of the database
             Recommended when LSF jobs are still running
  -f       - Export the metrics on the database
EOF
`
  echo ""
  echo "$message"
}

#----------------------------------------
# parse command line arguments
#----------------------------------------
error=0
mode=0
# Default database name
databases="${CWD}/metrics.db"

if [ $# -eq 0 ];
then
  # No command line argument - show help
  help
  echo ""
  exit 0
fi

while [ $# -ne 0 ];
do
  arg="$1"
  case "$arg" in
    -tmp | --tmp )
       # Generate the summary on a copy of the database
       mode=1
       ;;
    -f | --f )
       # Generate the summary of the database
       mode=0
       ;;
    -d | -db )
       shift
       databases="$@"
       break
       echo ""
       ;;
    -h | -help )
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

# Iterate through all the databases
for file in $databases; do
  if [ ! -e $file ];
  then
    echo " File $file does not exist. Skipping."
    continue
  fi
  DIR=$( cd "$( dirname "$file" )" && pwd )
  BASENAME=$(basename "$file")
  TS=$(stat -c '%Y' "$DIR")
  TIMESTAMP=$(date -d @${TS} +'%d %b %Y %R')
#   echo "  $file / DIR=$DIR / BASENAME=$BASENAME / TS=$TS / TIMESTAMP=$TIMESTAMP"
  case "$mode" in
    0 )
       # Export the metrics of the database
       snapshot db2dir -db $file -dir ${DIR}/export -html -force -default_top_metrics -top_metrics "directive=Directive duration=Runtime"
       echo ""
       # Restore directory timestamp
       touch -d "$TIMESTAMP" "$DIR"
       ;;
    1 )
       # Export the metrics on a copy of the database
       \cp $file ${DIR}/tmp.db
       snapshot db2dir -db ${DIR}/tmp.db -dir ${DIR}/export -html -force -default_top_metrics -top_metrics "directive=Directive duration=Runtime"
       echo ""
       # Restore directory timestamp
       touch -d "$TIMESTAMP" "$DIR"
       ;;
    *)
       echo "  ERROR: $mode is not a valid mode."
       let error++
       ;;
  esac
done

exit 0

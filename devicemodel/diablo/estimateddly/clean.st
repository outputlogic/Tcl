#!/bin/sh

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
TS=$(stat -c '%Y' "$DIR")
TIMESTAMP=$(date -d @${TS} +'%d %b %Y %R')

help() {
  message=`cat <<EOF
  usage: clean.do [-force][-h]

  -force   - Clean directory
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
    -force | --force )
       # Clean directory
       cd $DIR
       \rm -f tmp.{db,csv,rpt}
       \rm -f lsf.pid
       \rm -rf %{DIRECTORIES}
       touch -d "$TIMESTAMP" "$DIR"
       echo " Directory $DIR cleaned"
       exit 0
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

# Restore directory timestamp
touch -d "$TIMESTAMP" "$DIR"

if [ $error -gt 0 ]
then
  echo ""
  exit 1
fi

# No command line argument - show help
help
echo ""

exit 0

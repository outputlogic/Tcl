#!/bin/sh

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

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
       \rm -f lst.start
       
       \rm -rf Default
       \rm -rf Explore
       \rm -rf ExtraNetDelay_high
       \rm -rf ExtraNetDelay_low
       \rm -rf ExtraNetDelay_medium
       \rm -rf ExtraPostPlacementOpt
       \rm -rf LateBlockPlacement
       # \rm -rf RuntimeOptimized
       \rm -rf SpreadLogic_high
       \rm -rf SpreadLogic_low
       \rm -rf SpreadLogic_medium
       \rm -rf SSI_HighUtilSLRs
       \rm -rf WLDrivenBlockPlacement
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

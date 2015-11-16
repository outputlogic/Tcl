#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

source ${DIR}/common.bash

echo "SCR = $SCR"
echo "DIR = $DIR"

LIB_NAME1=$1
LIB_NAME2=$2

COMPARE $LIB_NAME1 $LIB_NAME2

exit 0

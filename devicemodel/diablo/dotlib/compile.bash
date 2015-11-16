#!/bin/bash

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

source ${DIR}/common.bash

echo "SCR = $SCR"
echo "DIR = $DIR"

LIB_NAME=$1
LIB_PATH=$2

COMPILE $LIB_NAME $LIB_PATH

exit 0

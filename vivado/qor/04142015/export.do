#!/bin/sh

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# snapshot db2dir -db ${DIR}/metrics.db -dir ${DIR}/export -html -force -default_top_metrics -top_metrics "directive=Directive duration=Runtime"
# exit 0

\cp ${DIR}/metrics.db ${DIR}/tmp.db
snapshot db2dir -db ${DIR}/tmp.db -dir ${DIR}/export -html -force -default_top_metrics -top_metrics "directive=Directive duration=Runtime"

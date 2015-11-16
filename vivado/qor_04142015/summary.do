#!/bin/sh

DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# ~/git/scripts/wip/snapshot/snapshot_summary -db ${DIR}/metrics.db -sort -save -runtime -show_all_hold
# ~/git/scripts/wip/snapshot/snapshot_summary -db ${DIR}/metrics.db -save -show_all_hold
# exit 0

\cp ${DIR}/metrics.db ${DIR}/tmp.db
~/git/scripts/wip/snapshot/snapshot_summary -db ${DIR}/tmp.db -save -show_all_hold

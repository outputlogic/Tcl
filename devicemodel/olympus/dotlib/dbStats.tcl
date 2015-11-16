
# Sample script to return some stats from the SQLite DB from a list of cells

proc dbStats {cells} {
  package require sqlite3
#   set db {/wrk/hdstaff/dpefour/support/Olympus/dotlib/latest/kintex7.db}
  set db {/wrk/hdstaff/dpefour/support/Olympus/dotlib/latest/kintex8.db}
  sqlite3 SQL $db -readonly true
  set cellids [SQL eval " SELECT id FROM cell WHERE name IN ('[join $cells ',']') "]
  set pinnum [SQL eval " SELECT count(id) FROM pin WHERE cellid IN ('[join $cellids ',']') "]
  set timingnum [SQL eval " SELECT count(id) FROM timing WHERE cellid IN ('[join $cellids ',']') "]
  set arcnum [SQL eval " SELECT count(id) FROM arc WHERE cellid IN ('[join $cellids ',']') "]
  puts " Number of cells: [llength $cells]"
  puts " Number of pins: $pinnum"
  puts " Number of timing arcs: $timingnum"
  puts " Number of individual timing arcs: $arcnum"
  SQL close
  return 0
}

# Display stats for all the cells listed in k8_only.txt (1 cell name per line)
set FH [open k8_only.txt]
set cells [split [read $FH] \n]
close $FH
dbStats $cells


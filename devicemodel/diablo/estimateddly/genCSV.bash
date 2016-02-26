#!/bin/bash

echo '"Design","Part","Path #","Driver Tile","Receiver Tile","Driver Site","Receiver Site","Driver Pin","Receiver Pin","Path Slack","Routable Nets","Driver Incr Delay","Net Incr Delay","Delay Type","Estimated Delay","P2P Delay","Estimated vs. P2P","Error vs. P2P (%)","Absolute Error (ns)","Fanout","Tiles Distance (X+Y)","SLR Crossing","Driver INT","Receiver INT","Net","Driver","Receiver"' > net_corr_setup.csv
cat */net_corr_setup.csv | grep -v "#" | grep -v -e '^$' | grep -v "Driver Tile" >> net_corr_setup.csv
echo " Generated CSV file net_corr_setup.csv"
csv2tbl -csv net_corr_setup.csv -out net_corr_setup.rpt
echo " Generated RPT file net_corr_setup.rpt"

echo '"Design","Part","Path #","Driver Tile","Receiver Tile","Driver Site","Receiver Site","Driver Pin","Receiver Pin","Path Slack","Routable Nets","Driver Incr Delay","Net Incr Delay","Delay Type","Estimated Delay","P2P Delay","Estimated vs. P2P","Error vs. P2P (%)","Absolute Error (ns)","Fanout","Tiles Distance (X+Y)","SLR Crossing","Driver INT","Receiver INT","Net","Driver","Receiver"' > net_corr_hold.csv
cat */net_corr_hold.csv | grep -v "#" | grep -v -e '^$' | grep -v "Driver Tile" >> net_corr_hold.csv
echo " Generated CSV file net_corr_hold.csv"
csv2tbl -csv net_corr_hold.csv -out net_corr_hold.rpt
echo " Generated RPT file net_corr_hold.rpt"

exit 0

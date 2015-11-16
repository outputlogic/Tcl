#!/bin/csh -f

\rm -f kintex7_clock.csv
\rm -f kintexu_clock.csv
\rm -f virtex7_clock.csv
\rm -f virtex9_clock.csv
\rm -f virtexu_clock.csv

reportClockPins -db kintex7.db > kintex7_clock.csv
reportClockPins -db kintexu.db > kintexu_clock.csv
reportClockPins -db virtex7.db > virtex7_clock.csv
reportClockPins -db virtex9.db > virtex9_clock.csv
reportClockPins -db virtexu.db > virtexu_clock.csv

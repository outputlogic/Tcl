#!/bin/csh -f

\rm -f kintex7_intrinsic.csv
\rm -f kintexu_intrinsic.csv
\rm -f virtex7_intrinsic.csv
\rm -f virtex9_intrinsic.csv
\rm -f virtexu_intrinsic.csv

reportintrinsicPins -db kintex7.db > kintex7_intrinsic.csv
reportintrinsicPins -db kintexu.db > kintexu_intrinsic.csv
reportintrinsicPins -db virtex7.db > virtex7_intrinsic.csv
reportintrinsicPins -db virtex9.db > virtex9_intrinsic.csv
reportintrinsicPins -db virtexu.db > virtexu_intrinsic.csv

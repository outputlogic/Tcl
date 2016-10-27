#!/bin/bash

# SCR="/wrk/hdstaff/dpefour/support/Olympus/dotlib/scripts_DEV"

if [ -z "$SCR" ]; then
    # Environment variable SCR is not set. Point to default location
    echo " INFO - Environment variable SCR is not set. Setting default location"
    SCR="/wrk/hdstaff/dpefour/support/Olympus/dotlib/scripts_DEV"
    echo " INFO - SCR=$SCR"
fi 

##-----------------------------------------------------------------------
## Functions
##-----------------------------------------------------------------------

COMPILE() {
  LIB_NAME=$1
  LIB_PATH=$2
  echo "  LIB_NAME = $LIB_NAME"
  echo "  LIB_PATH = $LIB_PATH"
  echo "  SCR = $SCR"

  mkdir -p $LIB_NAME
  touch ${LIB_NAME}/start
  rm -f ${LIB_NAME}/stop
  cp $LIB_PATH $LIB_NAME

  ##-----------------------------------------------------------------------
  ## Convert Sitemape2.xml to Tcl fragments for Kintex 7 & kintex 8
  ##-----------------------------------------------------------------------
  # ${SCR}/sitemap2tcl -file ./virtex7/ftcl/sitemap2.ftcl -xml /proj/xbuilds/HEAD_INT_daily_latest/installs/lin64/Vivado/HEAD/data/parts/xilinx/virtex7/Sitemap2.xml

  ${SCR}/splitDotLib -dotlib $LIB_PATH -output-dir ./$LIB_NAME/lib -output-prefix $LIB_NAME

  # Skip GTZE2_OCTAL.lib as it takes ~30mns to be converted as Tcl fragment. It also results
  # in long runtime during databases comparaison
  #   virtex7_GTZE2_OCTAL.lib: 6.8MB / 230K lines
  for FILE in ./$LIB_NAME/lib/*GTZ*OCTAL*lib
  do
    mv $FILE ${FILE}_SKIP
  done

  ${SCR}/dotlib2tcl -dotlib "./$LIB_NAME/lib/*.lib" -output-dir ./$LIB_NAME/ftcl
  ${SCR}/reportDotLib -ftcl "./$LIB_NAME/ftcl/${LIB_NAME}*.ftcl" -file ./$LIB_NAME/report/${LIB_NAME}_reportDotLib.rpt
  ${SCR}/reportDotLib -ftcl "./$LIB_NAME/ftcl/${LIB_NAME}*.ftcl" -expand -file ./$LIB_NAME/report/${LIB_NAME}_reportDotLib.expand.rpt

  # Generate CSV per COE
  ${SCR}/splitCSVbyCOE -csv ./$LIB_NAME/report/${LIB_NAME}_reportDotLib.csv -output-dir ./$LIB_NAME/report

  # Generate SQLite3 database
  \rm -rf ./$LIB_NAME/log/createSQLiteDB_${LIB_NAME}.log
  mkdir ./$LIB_NAME/log/
  ${SCR}/createSQLiteDB -ftcl "./$LIB_NAME/ftcl/${LIB_NAME}*.ftcl" -db ./$LIB_NAME/${LIB_NAME}.db -verbose > ./$LIB_NAME/log/createSQLiteDB_${LIB_NAME}.log
  ${SCR}/dbStats -db ./$LIB_NAME/${LIB_NAME}.db -verbose > ./$LIB_NAME/${LIB_NAME}.stats
  ${SCR}/reportDRC -db "./$LIB_NAME/${LIB_NAME}.db" -output ./$LIB_NAME/report/${LIB_NAME}_DRC.rpt -no_violation_number
  ${SCR}/reportDRC -db "./$LIB_NAME/${LIB_NAME}.db" -output ./$LIB_NAME/report/${LIB_NAME}_DRC_sum.rpt -summary -no_violation_number

  # Convert CSVs to tabular format
  ${SCR}/csv2tbl -csv ./$LIB_NAME/report/${LIB_NAME}*csv

  # Convert the splitted by COE CSV
  for CSV in ./$LIB_NAME/report/${LIB_NAME}_reportDotLib*.csv
  do
      HTML=`echo -n $CSV | sed -e 's/\.csv/\.html/g'`
# HTML=$(echo $CSV | sed -e 's/\.csv/\.html/g')
      ${SCR}/csv2html -csv $CSV -out $HTML
  done
  /bin/rm -f ./$LIB_NAME/report/${LIB_NAME}_reportDotLib.expand.html
  # ${SCR}/csv2html -csv ./$LIB_NAME/report/${LIB_NAME}_reportDotLib.csv -out ./${LIB_NAME}/report/${LIB_NAME}_reportDotLib.html

  touch ${LIB_NAME}/stop
}

COMPARE() {
  REF=$1
  LIB=$2
  echo "  REF = $REF"
  echo "  LIB = $LIB"
  echo "  SCR = $SCR"

  mkdir -p ./${REF}_${LIB}
  touch ./${REF}_${LIB}/start
  rm -f ./${REF}_${LIB}/stop

  ##-----------------------------------------------------------------------
  ## Compare Virtex 7-Serie with Virtex UltraScale
  ##-----------------------------------------------------------------------

  ${SCR}/normalize -expand \
                   -csv1 ./${REF}/report/${REF}_reportDotLib.expand.csv \
                   -csv2 ./${LIB}/report/${LIB}_reportDotLib.expand.csv \
                   -name1 ${REF} \
                   -name2 ${LIB} \
                   -output-suffix .expand \
                   -output-dir ./${REF}_${LIB}/report \
                   -log ./${REF}_${LIB}/log/normalize.expand.log

  ${SCR}/normalize -split_by_coe \
                   -csv1 ./${REF}/report/${REF}_reportDotLib.expand.csv \
                   -csv2 ./${LIB}/report/${LIB}_reportDotLib.expand.csv \
                   -name1 ${REF} \
                   -name2 ${LIB} \
                   -output-dir ./${REF}_${LIB}/report \
                   -log ./${REF}_${LIB}/log/normalize.log

  # Convert CSVs to tabular format
  ${SCR}/csv2tbl -csv ./${REF}_${LIB}/report/${REF}_${LIB}_diff*csv

  ##-----------------------------------------------------------------------
  ## SQLite databases comparison Virtex 7-Serie with Virtex UltraScale
  ##-----------------------------------------------------------------------

  # Compare SQL databases
  ${SCR}/dbCmp -db1 ./${REF}/${REF}.db -db2 ./${LIB}/${LIB}.db -name1 ${REF} -name2 ${LIB} -split_by_coe -csv -file ./${REF}_${LIB}/report/${REF}_${LIB}_sum.csv -v > ./${REF}_${LIB}/log/${REF}_${LIB}_sum.log
  # Convert result to HTML
  ${SCR}/csv2html -csv ./${REF}_${LIB}/report/${REF}_${LIB}_sum.csv -out ./${REF}_${LIB}/report/${REF}_${LIB}_sum.html

  # Convert CSVs to tabular format
  ${SCR}/csv2tbl -csv ./${REF}_${LIB}/report/${REF}_${LIB}_sum*csv

  ##-----------------------------------------------------------------------
  ## Convert CSV to report & HTML
  ##-----------------------------------------------------------------------
  
  for CSV in ./${REF}_${LIB}/report/*diff*csv
  do
    HTML=`echo -n $CSV | sed -e 's/\.csv/\.html/g'`
# HTML=$(echo $CSV | sed -e 's/\.csv/\.html/g')
    ${SCR}/csv2html -diff -csv $CSV -out $HTML -name1 ${REF} -name2 ${LIB}
  done
  for CSV in ./${REF}_${LIB}/report/*sum*csv
  do
    HTML=`echo -n $CSV | sed -e 's/\.csv/\.html/g'`
# HTML=$(echo $CSV | sed -e 's/\.csv/\.html/g')
    ${SCR}/csv2html -sum -csv $CSV -out $HTML -name1 ${REF} -name2 ${LIB}
  done
  
  ##-----------------------------------------------------------------------
  ## Package files by COE
  ##-----------------------------------------------------------------------
  
  for coe in CLB CLOCK CMAC CONFIG DSP GT ILKN IO PCI RAMB XIPHY MISC UNKNOWN
  do
    # Format e.g: 10302013
    _date_=`date +"%m%d20%g"`
    echo " Creating package for COE '$coe'"
    # Removing of COE directory first
    \rm -rf ${REF}_${LIB}/package/$coe
    mkdir -p ${REF}_${LIB}/package/$coe
    cp ./${REF}/report/${REF}_reportDotLib.{csv,html} ${REF}_${LIB}/package/$coe
    cp ./${REF}/report/*.${coe}.{csv,rpt,html}        ${REF}_${LIB}/package/$coe
    cp ./${LIB}/report/${LIB}_reportDotLib.{csv,html} ${REF}_${LIB}/package/$coe
    cp ./${LIB}/report/*.${coe}.{csv,rpt,html}        ${REF}_${LIB}/package/$coe
    cp ./${REF}_${LIB}/report/*.${coe}.{csv,rpt,html} ${REF}_${LIB}/package/$coe
    cd ./${REF}_${LIB}/package/${coe}
    /bin/tar cvfh ./${REF}_${LIB}_${_date_}.${coe}.tar *.csv *.html *.rpt > /dev/null
  #   /bin/gzip ./${coe}/${LIB}_${_date_}.${coe}.tar
    cd ../../..
  done
  
  ##-----------------------------------------------------------------------
  ## Done
  ##-----------------------------------------------------------------------

  touch ./${REF}_${LIB}/stop
}

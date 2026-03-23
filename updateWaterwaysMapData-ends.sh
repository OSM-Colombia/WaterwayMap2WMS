#!/bin/bash

# Updates the Ends from WaterwaysMap.

DIR=/home/geoserver/data/waterways
LOG=Ends.log
date >> ${LOG}
mkdir -p "${DIR}"
cd "${DIR}"
rm -f *
wget -nv https://data.waterwaymap.org/planet-ends.geojson.gz >> ${LOG} 2>&1
gunzip planet-ends.geojson.gz
psql -d waterways <<< "drop table planet_ends" >> ${LOG}
ogr2ogr -f "PostgreSQL" PG:"dbname=waterways" "planet-ends.geojson" -nln planet_ends -append >> ${LOG}
rm *

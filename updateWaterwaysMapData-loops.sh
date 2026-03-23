#!/bin/bash

# Updates the Loops from WaterwaysMap.

DIR=/home/geoserver/data/waterways
LOG=Loops.log

date >> ${LOG}
mkdir -p "${DIR}"
cd "${DIR}"
rm -f *
wget -nv https://data.waterwaymap.org/planet-loops.geojson.gz >> ${LOG}
gunzip planet-loops.geojson.gz
psql -d waterways <<< "drop table planet_loops" >> ${LOG}
ogr2ogr -f "PostgreSQL" PG:"dbname=waterways" "planet-loops.geojson" -nln planet_loops -append
rm *

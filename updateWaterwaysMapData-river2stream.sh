#!/bin/bash

# Updates the Invalid transitions river2stream from WaterwaysMap.

DIR=/home/geoserver/data/waterways
LOG=river2stream.log

date >> ${LOG}
mkdir -p "${DIR}"
cd "${DIR}"
rm -f *
wget -nv https://data.waterwaymap.org/planet-waterway-stream-ends.geojson.gz >> ${LOG}
gunzip planet-waterway-stream-ends.geojson.gz
psql -d waterways <<< "drop table planet_rivers2streams" >> ${LOG}
ogr2ogr -f "PostgreSQL" PG:"dbname=waterways" "planet-waterway-stream-ends.geojson" -nln planet_rivers2streams -append
rm *

#!/bin/bash

# Updates the Invalid transitions river2stream from WaterwaysMap.

set -euo pipefail

DIR=/home/geoserver/data/waterways
LOG=river2stream.log
URL=https://data.waterwaymap.org/planet-waterway-stream-ends.geojson.gz
GZ_FILE=planet-waterway-stream-ends.geojson.gz
DATA_FILE=planet-waterway-stream-ends.geojson

mkdir -p "${DIR}"
cd -- "${DIR}" || exit 1
exec >> "${LOG}" 2>&1

date
shopt -s nullglob
rm -f -- ./*.geojson ./*.geojson.gz

wget -nv "${URL}" -O "${GZ_FILE}"
gunzip -f "${GZ_FILE}"
psql -v ON_ERROR_STOP=1 -d waterways -c "DROP TABLE IF EXISTS planet_rivers2streams"
ogr2ogr -f "PostgreSQL" PG:"dbname=waterways" "${DATA_FILE}" -nln planet_rivers2streams -append

rm -f -- "${DATA_FILE}"

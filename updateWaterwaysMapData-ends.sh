#!/bin/bash

# Updates the Ends from WaterwaysMap.

set -euo pipefail

DIR=/home/geoserver/data/waterways
LOG=Ends.log
URL=https://data.waterwaymap.org/planet-ends.geojson.gz
GZ_FILE=planet-ends.geojson.gz
DATA_FILE=planet-ends.geojson

mkdir -p "${DIR}"
cd -- "${DIR}" || exit 1
exec >> "${LOG}" 2>&1

date
shopt -s nullglob
rm -f -- ./*.geojson ./*.geojson.gz

wget -nv "${URL}" -O "${GZ_FILE}"
gunzip -f "${GZ_FILE}"
psql -v ON_ERROR_STOP=1 -d waterways -c "DROP TABLE IF EXISTS planet_ends"
ogr2ogr -f "PostgreSQL" PG:"dbname=waterways" "${DATA_FILE}" -nln planet_ends -append

rm -f -- "${DATA_FILE}"

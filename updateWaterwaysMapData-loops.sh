#!/bin/bash

# Updates the Loops from WaterwaysMap.

set -euo pipefail

DIR=/home/geoserver/data/waterways
LOG=Loops.log
URL=https://data.waterwaymap.org/planet-loops.geojson.gz
GZ_FILE=planet-loops.geojson.gz
DATA_FILE=planet-loops.geojson

mkdir -p "${DIR}"
cd -- "${DIR}" || exit 1
exec >> "${LOG}" 2>&1

date
mkdir -p "${DIR}"
shopt -s nullglob
rm -f -- ./*.geojson ./*.geojson.gz

wget -nv "${URL}" -O "${GZ_FILE}"
gunzip -f "${GZ_FILE}"
psql -v ON_ERROR_STOP=1 -d waterways -c "DROP TABLE IF EXISTS planet_loops"
ogr2ogr -f "PostgreSQL" PG:"dbname=waterways" "${DATA_FILE}" -nln planet_loops -append

rm -f -- "${DATA_FILE}"

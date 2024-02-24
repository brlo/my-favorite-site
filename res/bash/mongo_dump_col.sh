#!/bin/bash

# mongo_dump_col.sh mongo biblia_production lexemas
CONTAINER=$1 # mongo
DB=$2 # biblia_production
COLLECTION=$3 # lexemas

TODAY=`date +%Y-%d-%m`

# backup
# локально работает и без юзера-пароля
docker exec ${CONTAINER} mongodump --db=${DB} --collection=${COLLECTION} --archive > ./bib-${COLLECTION}.dump

exit 0

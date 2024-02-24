#!/bin/bash

# mongo_restore_db.sh mongo biblia_production ./bib_dump
CONTAINER=$1 # mongo
DB=$2 # biblia_production
DUMP=$3 # "./bib_dump"

TODAY=`date +%Y-%d-%m`

# backup
# локально работает и без юзера-пароля
# docker exec ${CONTAINER} mongodump --db=${DB} --archive | gzip -c > ./bib-${TODAY}.dump.gz

# restore
docker exec -i ${CONTAINER} mongorestore --db=${DB} --nsInclude="${DB}.*" --archive < ${DUMP}

exit 0

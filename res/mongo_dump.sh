#!/bin/bash

# mongo_dump.sh mongo biblia_development lexemas
CONTAINER=$1
BD=$2
COLLECTION=$3
TODAY=`date +%Y-%d-%m`

# backup
# локально работает и без юзера-пароля
docker exec ${CONTAINER} mongodump --db=${BD} --collection=${COLLECTION} --archive > ./bib-${COLLECTION}.dump


# restore
#docker exec -i ${CONTAINER} mongorestore --db=${BD} --collection=${COLLECTION} --archive < ./bib-${COLLECTION}.json

exit 0

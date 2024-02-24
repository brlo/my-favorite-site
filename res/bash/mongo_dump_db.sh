#!/bin/bash

# cron
#
# 0  1    * * *   root    /etc/scripts/backup.sh

# mongo_dump_db.sh mongo biblia_production ./bib
CONTAINER=$1 # mongo
DB=$2 # biblia_production
DUMP=$3 # "./bib_dump"

# backup
# локально работает и без юзера-пароля
docker exec ${CONTAINER} mongodump --db=${DB} --archive | gzip -c > ./${DUMP}-${TODAY}.dump.gz

# restore
#docker exec -i mongo-4.2 mongorestore --db=biblia_production --nsInclude="biblia_production.*" --archive < /home/brlo/backups/bib.dump

exit 0

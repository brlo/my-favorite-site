#!/bin/bash

# mongo_restore_col.sh mongo biblia_production lexemas
CONTAINER=$1 # mongo
DB=$2 # biblia_production
COLLECTION=$3 # lexemas

TODAY=`date +%Y-%d-%m`

# restore
docker exec -i ${CONTAINER} mongorestore --db=${DB} --collection=${COLLECTION} --archive < ./bib-${COLLECTION}.dump

# FAIL!
# Не получилось указать базу и коллекцию. Он просто развернул туда же, откуда взяли. В такие же имена.

# 2024-02-23T03:05:21.150+0000	the --db and --collection args should only be used when restoring from a BSON file. Other uses are deprecated and will not exist in the future; use --nsInclude instead
# 2024-02-23T03:05:21.609+0000	preparing collections to restore from
# 2024-02-23T03:05:21.852+0000	reading metadata for biblia_production.lexemas from archive on stdin
# 2024-02-23T03:05:21.899+0000	restoring biblia_production.lexemas from archive on stdin
# 2024-02-23T03:05:24.149+0000	biblia_production.lexemas  45.7MB
# 2024-02-23T03:05:25.190+0000	biblia_production.lexemas  76.3MB
# 2024-02-23T03:05:25.190+0000	restoring indexes for collection biblia_production.lexemas from metadata
# 2024-02-23T03:05:25.934+0000	finished restoring biblia_production.lexemas (54034 documents, 0 failures)
# 2024-02-23T03:05:25.934+0000	54034 document(s) restored successfully. 0 document(s) failed to restore.

exit 0

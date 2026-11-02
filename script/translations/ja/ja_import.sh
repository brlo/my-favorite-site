#!/bin/bash
# tmp/ja_import.sh q_god_1 — проверка ссылок, холостой и настоящий импорт японского файла
f=db/translations/ja/$1.yml
docker exec bibleox bash -lc "cd /app && bin/rails runner tmp/chk_ja.rb $f && bin/rails pages:import_translations FILE=$f PUBLISH=1 DRY_RUN=1 2>&1 | grep -v 'создано' ; bin/rails pages:import_translations FILE=$f PUBLISH=1 2>&1 | tail -30"

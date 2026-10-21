#!/bin/bash

ssh bibleox -t 'bash -ic "bib_update_code && bib_restart && bib_cache_clear"' || { echo "Deploy commands failed"; exit 1; }

is_deployed=false

for var in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
do
  echo "Starts $var try..."

  resp=`curl --max-time 10 --write-out "%{http_code}\n" --silent --output /dev/null "https://bibleox.com/ru/ru/gen/1/"`

  if [[ $resp == *"200"* ]]; then
    echo "Success response. Code: ${resp}"
    echo "Deployed!"
    is_deployed=true
    break
  else
    echo "Fail response. Code: ${resp}"
    echo
  fi

  sleep 5
done

if [[ $is_deployed != true ]]; then
  echo "Site did not answer 200. Check logs: ssh bibleox 'sudo docker logs --tail 50 bibleox'"
  exit 1
fi

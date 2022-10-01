#!/bin/bash

ssh bibleox -t 'bash -ic "bib_code_update && bib_restart"'

for var in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15
do
  echo "Starts $var try..."

  resp=`curl --write-out "%{http_code}\n" --silent --output /dev/null "https://bibleox.com/ru/gen/1/"`

  if [[ $resp == *"200"* ]]; then
    echo "Success response. Code: ${resp}"
    echo "Deployed!"
    break
  else
    echo "Fail response. Code: ${resp}"
    echo
  fi

  sleep 2
done

exit 0

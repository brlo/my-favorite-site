#!/bin/bash

print_help() {
  echo
  echo "$0: -i <input_file> -o <output_file>"
  echo
  echo "example: "
  echo "$0 -i /path/file.js -o /path/file.js.min"
  echo
  echo "Minify JS-file."
  exit 0
}

if [[ $# -eq 0 ]] ; then
    print_help
    exit 0
fi

while [ $# -gt 0 ]
do
  case $1 in
    -h) print_help ;;
    --help) print_help ;;
    -i) INPUT_PATH=$2 ; shift 2 ;;
    -o) OUTPUT_PATH=$2 ; shift 2 ;;
    *) shift 1 ;;
  esac
done

echo "Minify JS: ${INPUT_PATH}"
# удаляем коменты типа "// string"
# удаляем переносы строк
# заменяем множество пробелов на один
# удаляем комменты /* comment */
# удаляем пробелы[=;:,{}+-*&|><]пробелы

# sed 's,\([[:space:]]*\([=;:,{}\+\-\*\&\|\>\<]\)[[:space:]]*\),\2,g'
#  | ruby -ne 'print($_.gsub(/\/\*.*?\*\//i, ""))' | sed 's,\([[:space:]]*\([=:,{}]\)[[:space:]]*\),\2,g'
cat ${INPUT_PATH} | sed 's,\/\/.*,,g' | perl -pe 's/(\}|\))\s*;?\s*\R/\1;/g' | sed 's,[[:space:]]\{2\,\}, ,g' > ${OUTPUT_PATH}

echo "Done: ${OUTPUT_PATH}"

exit 0

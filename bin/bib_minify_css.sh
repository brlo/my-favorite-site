#!/bin/bash

print_help() {
  echo
  echo "$0: -i <input_file> -o <output_file>"
  echo
  echo "example: "
  echo "$0 -i /path/file.css -o /path/file.css.min"
  echo
  echo "Minify CSS-file."
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

echo "Minify CSS: ${INPUT_PATH}"
# удаляем переносы строк
# удаляем комменты /* comment */
# заменяем множество пробелов на один
# удаляем пробелы[;:,{}]пробелы
cat ${INPUT_PATH} | tr -d '\n' | ruby -ne 'print($_.gsub(/\/\*.*?\*\//i, ""))' | sed 's,[[:space:]]\{2\,\}, ,g' | sed 's,\([[:space:]]*\([;:,{}]\)[[:space:]]*\),\2,g' > ${OUTPUT_PATH}

echo "Done: ${OUTPUT_PATH}"

exit 0

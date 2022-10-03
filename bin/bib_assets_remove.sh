#!/bin/bash

# корневая директория приложения
cd "$( dirname -- "$0"; )"; cd ..

ASSETS_PATH='./public/assets/*'

echo "Remove assets in: ${ASSETS_PATH}"

rm -rf ${ASSETS_PATH}

echo "Done"

exit 0

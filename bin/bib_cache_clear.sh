#!/bin/bash

# корневая директория приложения
cd "$( dirname -- "$0"; )"; cd ..

rm db/cache_search/*/*/*.json

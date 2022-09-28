#!/bin/bash

# корневая директория приложения
cd "$( dirname -- "$0"; )"; cd ..

rm tmp/restart.txt && touch tmp/restart.txt

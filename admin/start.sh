#!/bin/bash

# start.sh dev
# start.sh prod

RUN_MOD=$1
LOCATION="`dirname "$0"`"
cd $LOCATION

# цветное эхо
function ecco () {
  echo -e "\e[1;33m$1\e[0m"
}

# установка node пакетов
function install_node_modules () {
  ecco "Building node modules ..."
  npm install
}

# запуск
function run_app () {
  ecco "Runing app. env: $1 ..."
  NODE_ENV_NAME=$1
  exec npm run ${NODE_ENV_NAME}
}


case "$RUN_MOD" in
"dev")
    install_node_modules
    run_app
    ;;
"prod")
    install_node_modules
    run_app
    ;;
*)
    install_node_modules
    run_app
    ;;
esac

exit 0

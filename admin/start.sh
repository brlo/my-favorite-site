#!/bin/sh

# Запустит сервер для разработки:
# start.sh dev

# Соберёт файлы для размещения в проде:
# start.sh build

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
  ecco "Runing app. ENV: $1 ..."
  # запустить можно только dev
  # exec npm run dev
  exec npx vite
}

# сборка
function build_app () {
  ecco "Building app. ENV: $1 ..."
  # собрать можно только prod
  # exec npm run build
  exec npx vite build
}

case "$RUN_MOD" in
"dev")
    # dev
    install_node_modules
    run_app
    ;;
"build")
    # prod
    install_node_modules
    build_app
    ;;
*)
    install_node_modules
    build_app
    ;;
esac

exit 0

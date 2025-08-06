#!/usr/bin/env bash

# $1 = prod || dev
RUN_MOD=$1
echo '================================================================='
echo "RUN MODE: ${RUN_MOD}"
echo '================================================================='

# Remove a potentially pre-existing server.pid for Rails.
rm -f /app/tmp/pids/server.pid

# exit on error
set -o errexit

mypath=`realpath $0`
cd `dirname $mypath`


case "$RUN_MOD" in
"prod")
    bundle install
    echo '=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-='
    ./bin/bib_assets_remove.sh
    echo '=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-='
    bundle exec rake assets:precompile
    echo '=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-='
    bundle exec rake assets:clean
    echo '=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-='
    # JS
    find public/assets/ -type f \
        -name "*.js" ! -name "*.min.*" \
        -exec echo {} \; \
        -exec ./bin/bib_minify_js.rb -i {} -o {}.min \; \
        -exec rm {} \; \
        -exec mv {}.min {} \;
    # CSS
    echo '=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-='
    find public/assets/ -type f \
        -name "*.css" ! -name "*.min.*" \
        -exec echo {} \; \
        -exec ./bin/bib_minify_css.sh -i {} -o {}.min \; \
        -exec rm {} \; \
        -exec mv {}.min {} \;
    echo '=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-='
    rm -rf public/assets/*.gz
    # для преобразования страниц в pdf
    # npx puppeteer browsers install chrome
    # bundle exec rake db:migrate
    exec bundle exec puma -C config/puma.rb -e production
    ;;
"dev")
    bundle install
    bundle exec rake tmp:clear
    bundle exec rake assets:clobber
    bundle exec rake assets:clean
    # для преобразования страниц в pdf
    # npx puppeteer browsers install chrome
    rm -f tmp/pids/server.pid
    echo "============ DEV ============="
    exec bundle exec rails s -p 3000 -b '0.0.0.0'
    ;;
*)
    echo "Need parameter: prod || dev"
    ;;
esac

exit 0

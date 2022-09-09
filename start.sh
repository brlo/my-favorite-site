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
    bundle exec rake assets:precompile
    bundle exec rake assets:clean
    # bundle exec rake db:migrate
    exec bundle exec puma -C config/puma.rb -e production
    ;;
"dev")
    bundle install
    bundle exec rake tmp:clear
    bundle exec rake assets:clobber
    bundle exec rake assets:clean
    rm -f tmp/pids/server.pid
    echo "============ DEV ============="
    exec bundle exec rails s -p 3000 -b '0.0.0.0'
    ;;
*)
    echo "Need parameter: prod || dev"
    ;;
esac

exit 0

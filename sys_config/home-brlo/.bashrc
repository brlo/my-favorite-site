# CUSTOM CODE

cd /projects/bibleox

alias nginxerrors='sudo tail -n 30 -f /var/log/nginx/error.log'
alias nginxlog='sudo tail -n 30 -f /var/log/nginx/access.log'
alias bib_update_code='git fetch && git reset --hard && git checkout origin/main'
alias bib_restart='sudo docker-compose restart -t 5'
alias bib_reload='sudo rm /projects/bibleox/tmp/restart.txt && touch /projects/bibleox/tmp/restart.txt'
alias bib_log='sudo docker logs -f bibleox'
alias bib_docker='sudo docker exec -it bibleox bash'
alias bib_cache_clear='sudo rm /projects/bibleox/db/cache_search/*/*/*.json'

. "/home/brlo/.acme.sh/acme.sh.env"

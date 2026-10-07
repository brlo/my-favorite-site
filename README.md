# README

Запуск для разработки:

Перед запуском, если ты собираешь собирать Dockerfile впервые в маке, раскоментируй там правильную строку для мака, FROM --platform

docker compose up -d

Консоль:

docker exec -it bibleox bundle exec rails c

Деплой в прод через:

./bin/bib_deploy.sh

Или удалённый вход на сервер и там:

bib_update_code

bib_restart

* Ruby version

3.1+

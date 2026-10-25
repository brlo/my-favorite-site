# Правила для Claude

## Коммиты и PR

В сообщения коммитов и описания PR не добавлять упоминания об ИИ: никаких `Co-Authored-By: Claude`, `Generated with Claude Code` и т.п.

## Именование

Методы и переменные, возвращающие boolean, называем либо с префиксом `is_` (`is_something`), либо с окончанием `?` (`email_confirmed?`).

## Запуск кода и тесты

Приложение запускается через docker compose up

Ruby и гемы есть только внутри докер-контейнера `bibleox` (код смонтирован в `/app`). На хосте `bundle`/`bin/rails` не работают (нет гемов, rmagick не собирается) — не пытаться ставить их локально, всё запускать так:

```
docker exec bibleox bash -lc 'cd /app && bin/rails test test/services/bible_linker_test.rb'
docker exec bibleox bash -lc 'cd /app && bin/rails runner "puts 1"'
```

Для тестов и `runner` нужны контейнеры `bibpostgres` и `bibredis`. Если они остановлены: `docker compose up -d postgres redis` и подождать несколько секунд.

Тесты ходят в Redis по адресу из `config/settings.yml` (раздел `test`, база 15 в `bibredis`, с паролем как у development; образец в `config/settings.yml.example`). Если адрес пустой, клиент стучится на localhost:6379 и десятки тестов падают с `Redis::CannotConnectError`.

Тесты лежат в `test/` (minitest). Новую логику покрывать тестами рядом с существующими (`test/services`, `test/models`).

## Прод и деплой

- Прод: `ssh bibleox`. Сайт: https://bibleox.com/
- Деплой: `bin/bib_deploy.sh`. На сервере он делает `git reset --hard origin/main`, поэтому сначала запушить в main. Алиасы `bib_*` лежат на сервере в `~/.bib_aliases.sh`, в репозитории их нет.
- Контейнер работает от uid 1000 / gid 1001. Если git на сервере запускается от root, файлы переходят к root, и `bundle install` падает с ошибкой записи в `Gemfile.lock`. Алиас `bib_update_code` сам возвращает владельца `1000:1001`; руками git на сервере лучше не гонять от root без `chown`.
- Статику (`/assets/...`) отдаёт отдельный хост `res.bibleox.com`

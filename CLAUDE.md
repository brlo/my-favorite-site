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

Тесты лежат в `test/` (minitest). Новую логику покрывать тестами рядом с существующими (`test/services`, `test/models`).

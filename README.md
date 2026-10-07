# Bibleox

[![CI](https://github.com/brlo/my-favorite-site/actions/workflows/ci.yml/badge.svg)](https://github.com/brlo/my-favorite-site/actions/workflows/ci.yml)

Библейский сайт [bibleox.com](https://bibleox.com): написание статей, библиотека с трудами святых отцов, чат и совместные переводы, параллельные переводы Писания, интерфейс на 25-ти языках, подстрочник с греческим и ивритом, словари. Есть оффлайн-приложение для Android.

## Стек

| Слой | Что используется |
|---|---|
| Бэкенд | Ruby 4.0, Rails 8.1, Puma |
| БД | PostgreSQL 18 + [PGroonga](https://pgroonga.github.io/) (полнотекстовый поиск по-русски, по-гречески, по-японски) и `tsvector` |
| Фоновые задачи | Solid Queue (отдельная БД `queue`), `config/recurring.yml` |
| Кэш, лимиты, счётчики | Redis (пул соединений: дневные лимиты писем, счётчики, лимиты чата) |
| Фронтенд | Hotwire: Turbo + Stimulus, importmap (без сборщика); редактор статей на Tiptap |
| Админка | Rails + Stimulus на `/admin` (раньше была на Vue.js) |
| Аутентификация | Sorcery (почта + Telegram-вход), привилегии в `users.privs` |
| Мобильное приложение | Capacitor + Vue 3 + SQLite, см. [mobile/README.md](mobile/README.md) |
| Тесты, CI | Minitest, GitHub Actions, Brakeman, bundler-audit |

## Запуск для разработки

Нужен Docker.

```bash
cp docker-compose.yml.example docker-compose.yml
cp config/database.yml.example config/database.yml
cp config/settings.yml.example config/settings.yml
cp res/docker-data/config/redis/redis.conf.example res/docker-data/config/redis/redis.conf
docker compose up -d
docker exec -it bibleox bin/rails db:create db:schema:load
```

Сайт откроется на http://localhost. На Mac при первой сборке образа раскомментируй в `Dockerfile` строку `FROM --platform=...`.

Консоль:

```bash
docker exec -it bibleox bundle exec rails c
```

## Тесты

Нужны PostgreSQL (с PGroonga) и Redis — те же контейнеры из `docker compose`.

```bash
docker exec -e RAILS_ENV=test bibleox bin/rails db:create db:schema:load
docker exec -e RAILS_ENV=test bibleox bin/rails test
```

Проверки безопасности (как в CI):

```bash
docker exec bibleox bundle exec brakeman --no-pager -w2
docker exec bibleox bundle exec bundle-audit check --update
```

Известные срабатывания Brakeman про `html_safe` в `pages/show` занесены в `config/brakeman.ignore`: HTML статей проходит через allowlist при сохранении (`Page.safe_html`).

## Деплой

```bash
./bin/bib_deploy.sh
```

Скрипт заходит на сервер по SSH, обновляет код, перезапускает приложение, чистит кэш и проверяет, что страница отвечает 200. Продакшн-режим собирает ассеты и минифицирует их (см. `start.sh prod`).

## Права доступа

Админка `/admin` доступна пользователям с хотя бы одной привилегией на чтение раздела (`pages_read`, `dict_read`, `gallery_read`), владельцам страниц и админам. Привилегии выдаются в админке (раздел «Пользователи») или из консоли:

```ruby
u = User.find_by(email: 'user@example.com')
u.can!('pages_read')   # доступ в раздел статей
u.cant!('pages_read')  # отозвать
u.update!(is_admin: true)
```

Полный список привилегий: `User::PRIVS` в [app/models/user.rb](app/models/user.rb).

## Структура

```
app/
  controllers/   публичная часть, admin/, api/, chat/
  models/        Page, Verse, DictWord, User, BibleReference, chat/, translation/
  services/      поиск, цитаты, оффлайн-экспорт, чат-бот, почта
  jobs/          Solid Queue: извлечение цитат, рассылки, чистка чата
  javascript/    Stimulus-контроллеры, Tiptap
config/          маршруты, i18n (25 локалей), настройки, recurring-задачи
db/              schema.rb, миграции, база одноразовых почтовых доменов
mobile/          оффлайн-приложение для Android
res/             Docker-данные, разовые скрипты импорта словарей
docs/            заметки
```

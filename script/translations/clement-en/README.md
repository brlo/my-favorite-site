# EN-страница Климента Римского (ru 418 → en 423)

Страница автора переведена заново с русского эталона (`Климент_Римский`, id 418).
Цитаты вырезаны дословно из уже опубликованных на сайте английских переводов:

- 1-е послание к Коринфянам — страница `ClemRm_Kor1` (ANF, ed. A. Roberts and J. Donaldson);
- Ириней Лионский, «Против ересей», кн. III — `irenaeus-against-heresies-b3`;
- Рим. 12:16 и Флп. 4:3 — `eng-nkjv`.

Итог: `db/translations/en/clement_author.yml` (`update: true`, адрес `Clement_of_Rome`).
Рабочие дампы и черновики — в `tmp/en_fathers/clement/` (в git не попадают).

## Что где

- `check_page.py` — приёмка уже импортированной страницы по dev-базе: дословность каждой
  цитаты в тексте главы (главы берутся из БД, `ClemRm_Kor1`), «…» внутри цитаты считается
  пропуском; парность тегов; кириллица; число сносок `[n]` против пунктов `<ol>`;
  живость всех ссылок и анкоров (страницы — по БД, анкоры и стихи — по отрендеренной
  странице сайта).
- `script/translations/clement-en/README.md` — этот файл.

Дампы для сверки (если понадобится заново):

```bash
docker exec bibpostgres psql -U bibleox bibleox_development -t -A -c "SELECT body FROM pages WHERE id=418" > tmp/en_fathers/clement/ru_body.html
docker exec bibpostgres psql -U bibleox bibleox_development -t -A -c "SELECT body FROM pages WHERE id=424" > tmp/en_fathers/clement/en_kor1.html
docker exec bibpostgres psql -U bibleox bibleox_development -t -A -c "SELECT body FROM pages WHERE id=545" > tmp/en_fathers/clement/en_irenaeus_b3.html
docker exec bibpostgres psql -U bibleox bibleox_development -t -A -c "SELECT body FROM pages WHERE id=429" > tmp/en_fathers/clement/grc_kor1.html
```

## Решения, которые стоит помнить

- Структура как в RU: 2 `h2` (Biography, Faith), 12 `h3`, 3 `hr`; порядок цитат сохранён.
- Цитаты — дословно; границы иногда шире русского (рубрикатор обрывает фразу), поэтому
  часть абзацев начинается со строчной буквы — как и в русском эталоне.
- Опечатки электронного текста ANF исправлены списком `FIXUPS` в `check_page.py`
  (`command-merits`, `neighhours`, `furnished. us`, `bishops s`, `blame-lessly`,
  `and there would be`, `fixed by faith rewards God`, `[has done sol`, `sin- offerings`,
  `preserved in, Christ Jesus`, `than to receive?`); тексты трудов при этом не менялись.
  Список продублирован в `references`.
- Главы 40–44 в RU идут одним блоком с заголовками-рубриками издания («Глава 40.
  Будем соблюдать порядок…»). В EN они цитируются пятью отдельными blockquote со своими
  ссылками: заголовки глав не часть текста Климента, их роль выполняют ссылки на главы.
  Об этом сказано в `references`.
- Композитные цитаты (несколько глав в одном blockquote) ссылаются на все главы сразу,
  каждый номер — отдельный анкор `#HH-<глава>`.
- Сноски `[1]`–`[3]`: «the aged among us» = πρεσβυτέρους (гл. 21); «faith rewards God» —
  порча издания, читается «faith towards God» (гл. 35); «our Saviour» = τὸ σωτήριον ἡμῶν,
  «наше спасение» (гл. 36).
- Выделения (`strong`/`mark`/`u`/`em`) перенесены по смыслу с русского; изолированные
  частицы (например «не» перед «своею мудростью») в английском сливаются с глаголом.

## Порядок

```bash
# 1. правка body/references в db/translations/en/clement_author.yml
# 2. холостой прогон и импорт на dev
docker exec bibleox bash -lc 'cd /app && bin/rails pages:import_translations FILE=db/translations/en/clement_author.yml DRY_RUN=1'
docker exec bibleox bash -lc 'cd /app && bin/rails pages:import_translations FILE=db/translations/en/clement_author.yml'
# 3. проверки
python3 script/translations/clement-en/check_page.py
curl -s -o /dev/null -w '%{http_code}\n' http://localhost/en/en/w/Clement_of_Rome
```

На прод — только по команде: `DRY_RUN=1`, затем `PUBLISH=1` (страница уже существует,
поэтому `PUBLISH` не обязателен; `update: true` обновляет её на месте).

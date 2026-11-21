# EN-страница Иустина Философа (ru 389 → en 407)

Страница автора переведена заново с русского эталона: тело собрано скриптами отсюда,
цитаты вырезаны дословно из уже опубликованных на сайте английских переводов (ANF:
`Justin_Philosopher-Apology_1`, `Apology_2`, `Justin_Martyr-Dialogue_with_Trypho`),
выделения перенесены по смыслу с русского.

## Что где

- `parse_blocks.py` — разбор ru-страницы на блоки (заголовки h2/h3, 13 подзаголовков h4,
  проза, 101 цитата со спанами выделений, строки-источники) → `blocks.json`;
- `make_packs.py` — пакеты разделов для агентов-переводчиков (`chunks/*.md`): ru-цитаты с
  разметкой `<b>/<m>/<bm>/<e>`, подсказка «труд, глава», тексты глав ANF;
- `check_quotes.py <chunk>` — приёмка ответов агентов: структура групп/абзацев, дословность
  каждого абзаца в тексте труда, паритет выделений, кириллица;
- `my_parts.py` — переводы заголовков, подзаголовков h4 и прозы (координатор);
- `review_quotes.py` — цитаты раздела «Отзывы» (Q96–Q101): Тертуллиан, Мефодий, Иероним —
  вырезка из EN-страниц сайта; Епифаний и Феодорит — свой перевод с русского;
- `build_en.py` — сборка `en_body.html`: структура как в ru, ссылки-источники с якорем
  `#HH-<глава>`, исправления явных опечаток электронного текста ANF (список `FIXUPS`);
- `check_links.py` — проверка всех ссылок и анкоров по dev-БД;
- `refs.py` — title/title_sub/meta_desc и принципы перевода (поле `references`);
- `make_yaml.py` — `db/translations/en/justin_author.yml`.

Исходники (дампы ru/en из dev-БД, `blocks.json`, `out/*.json` ответов агентов) лежат в
`tmp/justin_en/` — в git не попадают; при повторной сборке их нужно выгрузить заново:

```bash
docker exec bibpostgres psql -U bibleox bibleox_development -t -A -c "SELECT body FROM pages WHERE id=389" > tmp/justin_en/ru_389_bio.html
# так же en_ap1.html (416), en_ap2.html (417), en_dial.html (406)
```

## Порядок

```bash
python3 tmp/justin_en/parse_blocks.py
python3 tmp/justin_en/make_packs.py         # пакеты для агентов
# ответы агентов: tmp/justin_en/out/*.json, проверка: check_quotes.py <chunk>
python3 tmp/justin_en/build_en.py           # -> en_body.html, отчёт о проблемах
python3 tmp/justin_en/check_links.py
python3 tmp/justin_en/make_yaml.py          # -> db/translations/en/justin_author.yml
bin/rails pages:import_translations FILE=db/translations/en/justin_author.yml DRY_RUN=1
```

## Решения, которые стоит помнить

- Цитаты — дословно из ANF; границы иногда шире русского (рубрикатор обрывает фразу),
  поэтому часть абзацев начинается со строчной буквы — как и в русском эталоне.
- Явные опечатки электронного текста («suflcr», «by tire», «land will not», «hear yon» и т. п.)
  исправлены списком `FIXUPS`, о чём сказано в `references`; тексты трудов при этом не менялись.
- Русские переводческие вставки в скобках (греческие глоссы) из цитат убраны, пояснения —
  в `references`.
- Ссылка-источник ведёт на EN-труд с якорем `#HH-<глава>` (первая глава, где реально
  найден текст цитаты; у составных цитат это первая из глав).

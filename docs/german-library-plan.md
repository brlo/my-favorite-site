# Немецкая библиотека: наполнение по BKV (I — начало II в.)

План наполнения немецкого раздела святоотеческой библиотеки (`de`) текстами
в общественном достоянии. Партия 1 — апостольские мужи: I век и начало II.
**Пилот партии 1 сделан в dev** (Климент, Игнатий, Поликарп); ниже — инвентарь,
права, карта соответствий, конвейер и что осталось.

## 0. Статус

- Немецких страниц на сайте 22; раздел «Предание» (`links_de`, «Überlieferung»)
  уже имеет структуру 3/9/2/1.
- **Пилот сделан (dev, 25.11)**: страница-список `Kirchenvaeter`
  («Werke der alten heiligen Väter und Kirchenlehrer», id 7975) + папки
  «1. Jahrhundert» + три автора и 11 трудов, 15 страниц:
  Климент (автор, 1-е и 2-е послания), Игнатий (автор, 7 писем),
  Поликарп (автор, послание к Филиппийцам, мученичество). Все 200 на dev.
- Пункт меню «📚 Schriften der alten Christen» в `links_de` теперь ведёт на
  `Kirchenvaeter` (название пункта пока не меняли).
- Немецкий интерфейс (`config/locales/de.yml`) есть, Библия для автолинковки —
  `ge-sch` (`BibleLinker::BIBLE_BY_LANG`), но немецкие сокращения книг
  автолинкер **не распознаёт** — ссылки на Писание в немецких страницах
  ставим явными `<a>`.

## 1. Правило отбора

Берём только труды, у которых есть русская страница на сайте (эталон —
`church_writers`, id 363), и только немецкие переводы, находящиеся в
общественном достоянии. Рамка прав: переводчик умер не позже 1955 г.
(70 лет → PD в Германии/ЕС и в РФ), а для США — издание до 1931 г.

Современные немецкие переводы (Fischer, «Schriften des Urchristentums»,
Hennecke—Schneemelcher, BKV-переиздания XX в.) **не берём**.

## 2. Источник и права

Основной источник — **Bibliothek der Kirchenväter (BKV)**, Kösel, Kempten/München
1911–1938, оцифровка и вычитка Патристики Фрибурского университета:
<https://bkv.unifr.ch/>. Тома BKV — это научный католический перевод с
параллельной нумерацией страниц и сканами; для сайта берём только текст
перевода, аппарат — по решению (см. §7).

Правовое обоснование:

- **Franz Zeller (1879–1953)** — переводчик «Die Apostolischen Väter»
  (BKV, 1. Reihe, Bd. 35, München 1918): 70 лет с 1954 г. → PD в Германии/ЕС
  и в РФ с 01.01.2024; в США издание 1918 г. — PD.
  Год смерти: каталог LMU/GND 1055487204, каталог TU Darmstadt.
- **Gerhard Rauschen (1854–1917)** — «Brief an Diognet» и «Martyrium des
  Polykarp» (BKV, 1. Reihe, Bd. 12 и 14, München 1913): PD с 1988 г.
- **Kaspar Julius (1867–1940)** — «Apologie» Аристида (BKV, 1. Reihe, Bd. 12,
  München 1913): PD с 2011 г.
- Сам BKV-онлайн прямо разрешает свободное использование: «Die Texte der BKV
  unterstehen meines Wissens keinem Copyright mehr und dürfen daher frei
  verwendet werden. Bei einer Weiterverwendung wäre es nett, einen Hinweis zu
  geben, woher die Texte stammen»
  (<https://bkv.unifr.ch/about/copyrights>).

Атрибуция обязательна на каждой странице труда:

> Übersetzung: Franz Zeller, Die Apostolischen Väter (Bibliothek der
> Kirchenväter, 1. Reihe, Bd. 35), München 1918, S. 25–69. Text:
> <https://bkv.unifr.ch/works/cpg-1001/versions/clem-1clem-bkv>

## 3. Что уже есть по-немецки

| Русский труд | Немецкий текст BKV | Том, год | Переводчик | Права |
|---|---|---|---|---|
| 1-е послание Климента к Коринфянам (`КлРим_Кор1`) | Erster Brief an die Korinther | Bd. 35, 1918, S. 25–69 | F. Zeller | PD |
| 2-е послание Климента к Коринфянам (`КлРим_Кор2`) | Zweiter Brief des Klemens an die Korinther | Bd. 35, 1918, S. 294–307 | F. Zeller | PD |
| Послание к Ефесянам (`ИгнАн_Еф`) и ещё 6 писем Игнатия | Die sieben Briefe des Ignatius von Antiochien | Bd. 35, 1918, S. 117–156 | F. Zeller | PD |
| Послание Поликарпа к Филиппийцам (`ПлкСм_Фл`) | Der Brief des Polykarp … an die Gemeinde von Philippi | Bd. 35, 1918, S. 163–170 | F. Zeller | PD |
| Послание о мученичестве Поликарпа (`окружное-послание-…`) | Martyrium des Hl. Polykarp | Bd. 14, 1913 | G. Rauschen | PD, но онлайн-текст BKV обрезан (2 абзаца); на сайте — свой перевод с греческого |
| Дидахе (`Дидахе`) | Didache — Lehre der zwölf Apostel | Bd. 35, 1918, S. 6–16 | F. Zeller | PD |
| Послание апостола Варнавы (`Послание-апостола-Варнавы`) | Barnabasbrief | Bd. 35, 1918, S. 76–105 | F. Zeller | PD |
| Пастырь Ерма (`Пастырь_Ерма`) | Der Hirte des Hermas | Bd. 35, 1918, S. 179–289 | F. Zeller | PD |
| Послание к Диогнету (`Псл_Дгнт`) | Brief an Diognet | Bd. 12, 1913, S. 161–173 | G. Rauschen | PD |
| Апология Аристида (`Аристид-апология`) | Apologie | Bd. 12, 1913, S. 25–54 | K. Julius | PD |

Примечание: у мученичества Поликарпа в BKV-онлайн сохранились только приветствие
и первый абзац (проверено 25.11.2026: EPUB, RTF, PDF и страница divisions);
полный текст есть только в печатном томе (сканы/OCR). Поэтому страница
`PlkSm_Martyr` — собственный перевод с греческого, а не перевод Раушена.

Примечание: в метаданных BKV у «Hirt des Hermas» по ошибке стоит
библиографическая ссылка на «Brief des Polykarp» (S. 179–289); сам текст и
скан — Ерм, проверять по сканам.

## 4. Чего по-немецки нет (решение — своё)

- **Папий, фрагменты** — в BKV немецкого перевода нет (только английский).
  Фрагменты короткие (Eusebius, HE III, 39 и параллели); переводим сами с
  греческого, это 2–3 страницы.
- **Кодрат, фрагмент** — нет; одна цитата у Евсевия (HE IV, 3), переводим сами.
- **Мураториев канон** — латинский текст, немецкого PD-перевода не нашли;
  переводим сами с латыни (~1 страница).
- **«О девстве» Климента** (CPG 1004) — в BKV только английский; отложить или
  перевести с греческого/сирийского позже.
- **Страницы апостолов, Иоанна Предтечи, Анании** — это не переводы, а статьи
  сайта; писать по-немецки заново (по желанию, вне первой партии).
- «Дионисий Ареопагит (†~96)» — страница-ссылка на корпус псевдо-Дионисия,
  к I веку не относится; не трогаем.
- **Иустин, Татиан, Афинагор, Феофил, Ириней** — II век, в BKV есть немецкие
  переводы (Justin — Rauschen, 1913), но это следующая партия; переводчиков
  проверять по тому же правилу.

## 5. Как это ложится на сайт

1. **Страница-список.** Создать немецкую страницу `page_type 4` с
   `group_lang_id = 65bdfc1adba7720001ec3b95` (группа русского
   `church_writers`), родитель — `links_de`, путь например `Kirchenvaeter`,
   заголовок «Werke der alten heiligen Väter und Kirchenlehrer». После этого
   `script/translations/links_structure.rb` заполнит `path` у заготовки
   «📚 Schriften der alten Christen»; либо переименовать пункт в тот же
   заголовок.
2. **Папки веков** в меню списка — «1. Jahrhundert» (пустые папки не держим:
   «2. Jahrhundert» появится, когда в ней будет первый автор). Создаются
   импортом (`folders:`) или вручную.
3. **Страницы авторов** (`page_type 4`) — перевод русских страниц (RU-эталон):
   Климент (`Климент_Римский`, 31 КБ), Игнатий (`Игнатий_Антиохийский`,
   38 КБ), Поликарп (`Поликарп_Смирнский`, 19 КБ), Варнава
   (`Апостол_Варнава`, 5 КБ), Аристид (`Аристид_Афинский`, 3 КБ), Папий
   (`Папий_Иерапольский`, 6 КБ), Кодрат (`Кодрат`, 1 КБ). Это основной объём
   ручной работы; «Пастырь Ерма» в RU — сразу труд (`page_type 1`), поэтому
   отдельной страницы автора у Ерма нет.
4. **Труды** (`page_type 1`) — текст BKV, нумерация глав как в русском
   (главы — `<h2>`; якоря `#HH-n` HtmlRenderer строит сам).
5. **Импорт** — как в en/ja/la, на автора два YAML:
   `<author>_author.yml` — `list: Kirchenvaeter`, `menu.parent: "1. Jahrhundert"`;
   `<author>_works.yml` — `list: <path автора>`, `folders: [{path: "Briefe"}]`,
   у трудов `menu.parent: "Briefe"`. Тогда труды сразу дети автора и пункты —
   в меню автора. Загрузка:
   `bin/rails pages:import_translations FILE=... [DRY_RUN=1] [PUBLISH=1]`.
6. **Ссылки.** Греческий оригинал — `/de/grc/w/<путь>` (корпус `grc` уже
   есть для всех этих трудов), русский/английский параллельный текст —
   переключателем языков по `group_lang_id`.

## 6. Подготовка текста

- Скачиваем **EPUB** с bkv.unifr.ch (чистый XHTML, UTF-8, сноски и номера
  страниц отдельными элементами) — проще и точнее, чем OCR/RTF. RTF/PDF —
  для сверки.
- Убираем: ссылки на сканы (`https://bkv.unifr.ch/.../scans/bNNNN.jpg`),
  колонцифры «S. N», автоматическую шапку «Dieses Dokument wurde automatisch
  generiert».
- Заголовки глав (`1. Kap. …`) сводим к номеру главы в `<h2>` (как в RU/EN),
  чтобы якоря и оглавление совпадали: `<h2>1</h2>`, `<h2>2</h2>` …
- Сноски BKV: либо в `references` с пометой «Anmerkungen der Übersetzung»,
  либо выбросить (католический аппарат 1918 г. и полемика с протестантами;
  для православного сайта лучше выбросить, оставив только текст).
- Орфография 1918 г. (`daß`, `muß`, «Korinther») сохраняется: это исторический
  перевод; осовременивание — отдельная редактура, не при первом заливе.
- Внизу страницы — атрибуция (§2) и ссылка на скан/версию BKV.

## 7. Открытые вопросы

1. Название раздела и пункта меню: оставить «📚 Schriften der alten Christen»
   или переименовать в «Werke der heiligen Väter und Kirchenlehrer»?
2. Сноски BKV: сохранять (в `references`) или выбросить?
3. Авторские страницы: полный перевод русских статей или компактные немецкие
   (биография + цитаты из немецкого перевода)?
4. Орфография 1918 г.: оставить или осовременить?
5. Папий/Кодрат/Мураториев канон: свои переводы сразу или отложить?

Решения пилота: пункт меню переименован в перевод русского названия
(«📚 Werke der alten heiligen Väter und Kirchenlehrer»); сноски BKV выброшены
(внизу — только атрибуция); авторские страницы — **полный перевод русских
статей** (первая версия была компактной — это ошибка, исправлено); орфография
1918 г. сохранена; Папий/Кодрат/Мураториев канон отложены.

## 8. Порядок работ

**Партия 1 (I век):** Климент (2 послания) — готово; Игнатий (7 писем) —
готово; осталось: Варнава, Дидахе, Папий, Кодрат (свои переводы).
5 авторских страниц, из них 3 готовы.

**Партия 2 (начало II в.):** Поликарп (послание + мученичество) — готово,
в меню стоит в «1. Jahrhundert», как в русском эталоне; осталось: Диогнет, Ерм,
Аристид, Мураториев канон.

Объём: ~300–350 КБ немецкого текста (примерно пятая часть латинской
библиотеки), плюс ~100 КБ авторских страниц. Тексты собираются конвейером
быстро; основное время — авторские страницы и вычитка.

Для проекта нужен `docs/german-translations.md` (глоссарий и конвенции, как
`docs/japanese-translations.md`): термины (Bischof, Presbyter, Diakon,
Eucharistie, Überlieferung, Gottesgebärerin), имена (Klemens, Ignatios,
Polykarp, Hermas, Aristides), оформление ссылок.


## 9. Что сделано в пилоте (dev)

- Страница-список: `Kirchenvaeter` (id 7975), `page_type 4`, группа русского
  `church_writers`; меню: «1. Jahrhundert» (пустая папка «2. Jahrhundert» убрана,
  пока в ней нет авторов — иначе она висит серой над первым веком).
- Авторы: `Klemens_von_Rom`, `Ignatius_von_Antiochien`, `Polykarp_von_Smyrna`.
- Труды: `KlemRm_Kor1`, `KlemRm_Kor2`; `IgnAnt_Eph/Mag/Trall/Rom/Philad/Smyrn/Pol`;
  `PlkSm_Phil`, `PlkSm_Martyr`.
- Скрипты: `script/translations/de/bkv_epub.py` (EPUB → HTML),
  `build_pilot.py` (сборка YAML), `create_section.rb` (раздел и меню),
  `authors/*.html`, `section_intro.html`, `works/martyrdom.html`.
- YAML: `kl_author.yml` + `kl_works.yml`, `ig_author.yml` + `ig_works.yml`,
  `pl_author.yml` + `pl_works.yml` (у страниц `update: true`).
- Проверено на dev: все 15 страниц отдают 200, якоря `#HH-n` совпадают
  с ссылками авторских страниц, кириллицы в немецких текстах нет.
- Труды создаются с `list` = страница автора (два YAML, как в en/ja/la),
  поэтому они сразу дети автора (`parent_id = автор`) и их пункты — в меню
  автора; отдельный переносчик меню не нужен.
- «Прочие параметры» с эталона: обложки авторов — `copy_covers.rb de` (и
  `copy_cover: true` в YAML), `seo_kind=person` — `backfill_seo_kind.rb`,
  «золотые» пункты — `gold.rb de` (Климент, Игнатий, Поликарп в списке и
  1-е послание Климента в меню автора).
- Авторские страницы — полные переводы русского эталона: Климент 33 КБ,
  Игнатий 41 КБ, Поликарп 19 КБ (2/3/3 h2 и 12/17/12 h3, как в RU), ссылки
  переведены на немецкие страницы (`#HH-n`), греческие — на `/de/grc/`,
  библия — на `de/ge-sch`. Страница раздела `Kirchenvaeter` — перевод
  `church_writers` (вступление и карты).

- **Минуций Феликс** (`Minuzius_Felix`, `MinFl_Octavius`): «Octavius», BKV 1913,
  пер. Alfons Müller (BKV: тексты вне копирайта; издание 1913), 40 глав,
  116 КБ; страница автора — полный перевод RU (короткая), меню — в «3. Jahrhundert».
  Права: `db/bkv_translators.yml` (`free_bkv`).

- **Феофил Антиохийский** (`Theophilus_von_Antiochien`, `Theophilus_Autolykus`):
  «An Autolykus», BKV 1913, пер. J. Leitl (BKV: вне копирайта; издание 1913),
  3 книги; страница автора — полный перевод RU, меню — во «2. Jahrhundert».
  Права: `free_bkv`.

- **Ириней Лионский** (`Irenaeus_von_Lyon`): авторская страница 99 КБ (полный
  перевод RU, 5 разделов / 31 подраздел), обложка с RU; труды:
  `Irenaeus_Gegen_die_Haeresien_1…5` (BKV 1912, пер. E. Klebba, 31+35+25+41+36
  глав) и `Irenaeus_Demonstratio`; меню — во «2. Jahrhundert». Права: `pd`
  (Klebba 1871–1930).

- **Аристид Афинский** (`Aristides_von_Athen`, `Aristides_Apologie`):
  «Apologie», BKV 1913, пер. Kaspar Julius (BKV: вне копирайта; издание 1913),
  17 глав; страница автора — перевод RU, меню — во «2. Jahrhundert».
  Права: `free_bkv`.

- **Дидахе** (`Didache_Lehre_der_zwolf_Apostel`): «Lehre der zwölf Apostel»,
  BKV 1918, пер. Franz Zeller, 16 глав; страница-родитель «Werke unbekannter
  Autoren des 1. Jahrhunderts» — перевод RU. В меню: «Unterweisungen» внутри
  этой страницы и второй пункт в «Katechismus» — как в RU.
- **Варнава** (`Barnabas`, `Barnabasbrief`): автор — перевод RU (4,6 КБ),
  «Barnabasbrief» — BKV 1918, пер. Franz Zeller, 21 глава. Как в RU, авторство
  спорно: страница автора **без ссылки из библиотеки**, а послание лежит в
  «Werke unbekannter Autoren» → «Übriges» (прямая ссылка). Меню правит
  `script/translations/de/unknown_authors_menu.rb`. Права: `free_bkv`.

- **Диогнет** (`Diognetus_Brief`): «Brief an Diognet», BKV 1913, пер. Gerhard
  Rauschen, 12 глав; страница «Werke unbekannter Autoren des 2. Jahrhunderts»
  (перевод RU) с категориями «Briefe»/«Schriften». Как в RU, отдельного пункта
  в главном меню библиотеки нет. Права: `free_bkv`.

- **Ерм** (`Hirte_des_Hermas`): «Der Hirte des Hermas», BKV 1918, пер. Franz
  Zeller, 211 КБ; 28 разделов (предисловие + видения/заповеди/подобия);
  страница-труд под списком, пункт — в «Werke unbekannter Autoren» →
  «Übriges», как в RU. Права: `free_bkv`.

- **Афинагор Афинский** (`Athenagoras_von_Athen`, `Athenagoras_Bittschrift`,
  `Athenagoras_Auferstehung`): автор — с EN-страницы (RU-эталона нет);
  обе апологии BKV 1913, пер. Anselm Eberhard (96 КБ и 76 КБ), меню —
  во «2. Jahrhundert», труды в папке «Werke». Права: `free_bkv`.

- **Ипполит Римский** (`Hippolyt_von_Rom`, `Hippolyt_Antichrist`): автор —
  перевод RU (977 байт), обложка с RU; «Über Christus und den Antichrist»,
  BKV 1872, пер. Valentin Gröne, 73 КБ; меню — «3. Jahrhundert» →
  «Exegetische Werke». Права: `pd`.

- **Григорий Чудотворец** (`Gregor_der_Wundertäter`): автор — перевод RU,
  обложка с RU; «Glaubensbekenntnis» (BKV 1911, пер. Hermann Bourier) и
  «Lobrede auf Origenes» (19 глав); в «Werke» также заготовки
  «Übertragung des Ekklesiastes» и «An Theopompus…», как в RU. Права: `free_bkv`.

- **Киприан Карфагенский** (`Cyprian_von_Karthago`): автор — перевод RU
  (11 КБ), обложка с RU; три трактата BKV 1918, пер. Julius Baer:
  «Über die Einheit der katholischen Kirche» (48 КБ), «Über die Sterblichkeit»
  (37 КБ), «Über Eifersucht und Neid» (28 КБ), «Über die Gefallenen» (60 КБ),
  «Über das Gebet des Herrn» (55 КБ), «Über gute Werke und Almosen» (45 КБ),
  «An Demetrianus» (44 КБ), «Vom Segen der Geduld» (39 КБ), «Über die Haltung
  der Jungfrauen» (38 КБ); меню — «3. Jahrhundert» → «Briefe»/«Abhandlungen»,
  недостающие труды — заготовками, как в RU. Права: `free_bkv`.

- **Евсевий Кесарийский** (`Eusebius_von_Cäsarea`): автор — перевод RU
  (2,5 КБ); «Kirchengeschichte» BKV 1932, пер. Phil. Häuser, 10 книг
  (`Eusebius_Kirchengeschichte_1…10`); меню — «4. Jahrhundert» → «Geschichte»
  → «Kirchengeschichte» + заготовки «Chronik» и «Leben des Kaisers Konstantin».
  Права: `free_bkv`.
  Реестр источников (включая будущего Оригена): `db/bkv_sources.yml`.

- **Афанасий Великий** (`Athanasius_der_Große`): автор — перевод RU,
  обложка с RU; BKV 1917, пер. Anton Stegmann / Hans Mertel:
  «Gegen die Heiden» (132 КБ), «Über die Menschwerdung des Logos» (147 КБ),
  «Leben des heiligen Antonius» (139 КБ), «Geschichte der Arianer» (147 КБ),
  «Vier Briefe an Serapion» (177 КБ), «Schutzschrift gegen die Arianer»
  (222 КБ), «Über die Beschlüsse der Synode von Nizäa» (96 КБ), «Über die
  Synoden zu Rimini und Seleucia» (155 КБ), «Brief an die Bischöfe in Afrika»
  (28 КБ); меню — «4. Jahrhundert» → «Werke».
  Права: `free_bkv`.

- **Григорий Нисский** (`Gregor_von_Nyssa`): автор — перевод RU, обложка с RU;
  «Große Katechese» (41 гл., 167 КБ), «Abhandlung über die Ausstattung des
  Menschen» (31 гл., 193 КБ), «Das Gebet des Herrn» (5 гл., 127 КБ),
  «Acht Homilien über die acht Seligkeiten» (8 гл., 180 КБ), «Vita Macrinae»
  (66 КБ), «Gespräch mit Makrina» (186 КБ); меню — «4. Jahrhundert» → «Werke». Права: `free_bkv`/`pd`.

- **Тертуллиан** (`Tertullian`): автор — перевод RU (60 КБ), обложка с RU;
  BKV/Кельн 1882, пер. K. A. H. Kellner: «Über den Leib Christi» (25 гл.),
  «Über die Auferstehung des Fleisches» (63 гл.), «Über die Seele» (58 гл.),
  «Gegen Praxeas» (31 гл.), «Apologeticum» (48 гл.), «Über die Taufe» (20 гл.),
  «Die Prozesseinreden gegen die Häretiker» (44 гл.), «Vom Kranze des Soldaten»
  (15 гл.), «Über den Götzendienst» (24 гл.), «Über das Gebet» (29 гл.),
  «Über die Geduld» (16 гл.), «Über die Buße» (12 гл.), «An die Gattin»
  (19 гл.), «Gegen die Juden» (14 гл.), «Über die Schauspiele» (30 гл.),
  «An die Märtyrer» (6 гл.), «An Scapula» (5 гл.), «Das Zeugnis der Seele»
  (6 гл.); меню — «2. Jahrhundert» → «Werke». Права: `pd`.

Осталось из партии 1: Папий, Кодрат (свои переводы),
Папий и Кодрат (переводы с греческого), «О девстве» Климента (нет немецкого PD).

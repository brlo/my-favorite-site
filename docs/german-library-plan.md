# Немецкая библиотека: статус, конвейер и остаток

Рабочий документ по немецкому разделу святоотеческой библиотеки (`de`).
Ниже — актуальный статус, правила импорта, меню и список того, что осталось.
Исторические разделы о пилоте сохранены дальше и могут быть устаревшими.

## 0. Актуальный статус (26.11.2026)

- На проде и в dev: **31 автор, 241 труд**; `check_library_structure.rb de`
  — структура в порядке.
- Авторские меню верхнего уровня приведены к RU-эталону; части многотомных
  трудов сгруппированы под книгами.
- «Панарион» Епифания удалён: в BKV есть только пересказ
  (`Anakephalaiosis`) и 78-я ересь; полного текста нет.
- Труды без RU-страницы импортируются отдельным скриптом
  `script/translations/de/import_external_works.rb`; HTML-тела лежат в
  `db/translations/de/external/`. Это DE-only страницы без языкового
  переключателя; в `references` — BKV-источник.
- Реестр BKV-источников и переводчиков — `db/bkv_sources.yml`,
  `db/bkv_translators.yml`.
- Ссылки на Азбуку с авторских страниц убраны; где труд есть на сайте —
  внутренняя ссылка, где нет — текст без ссылки
  (`script/translations/de/retarget_author_links.rb`).

## 1. Правило отбора

Берём только труды, у которых есть русская страница на сайте (эталон —
`church_writers`, id 363), и только немецкие переводы, находящиеся в
общественном достоянии. Рамка прав: переводчик умер не позже 1955 г.
(70 лет → PD в Германии/ЕС и в РФ), а для США — издание до 1931 г.

Современные немецкие переводы (Fischer, «Schriften des Urchristentums»,
Hennecke—Schneemelcher, BKV-переиздания XX в.) **не берём**.

Исключение — труды, которых нет в RU, но которые пользователь явно попросил
перенести: они импортируются как DE-only через
`import_external_works.rb` и не притворяются переводом RU-страницы.

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
  (28 КБ), письма к Иовиану, Максиму, Драконтию, Руфиниану, Маркеллину,
  антиохийцам, окружное, к епископам Египта, четыре слова против ариан,
  защита перед Констанцием, оправдание бегства, о Дионисии, объяснение
  псалмов (3 части); меню — «4. Jahrhundert» →
  «Briefe».
  Права: `free_bkv`.

- **Григорий Нисский** (`Gregor_von_Nyssa`): автор — перевод RU, обложка с RU;
  «Große Katechese» (41 гл., 167 КБ), «Abhandlung über die Ausstattung des
  Menschen» (31 гл., 193 КБ), «Das Gebet des Herrn» (5 гл., 127 КБ),
  «Acht Homilien über die acht Seligkeiten» (8 гл., 180 КБ), «Vita Macrinae»
  (66 КБ), «Gespräch mit Makrina» (186 КБ), шесть проповедей из «Ausgewählte
  Reden» (всего 16 проповедей); меню — «4. Jahrhundert» → «Werke/Predigten». Права: `free_bkv`/`pd`.

- **Тертуллиан** (`Tertullian`): автор — перевод RU (60 КБ), обложка с RU;
  BKV/Кельн 1882, пер. K. A. H. Kellner: «Über den Leib Christi» (25 гл.),
  «Über die Auferstehung des Fleisches» (63 гл.), «Über die Seele» (58 гл.),
  «Gegen Praxeas» (31 гл.), «Apologeticum» (48 гл.), «Über die Taufe» (20 гл.),
  «Die Prozesseinreden gegen die Häretiker» (44 гл.), «Vom Kranze des Soldaten»
  (15 гл.), «Über den Götzendienst» (24 гл.), «Über das Gebet» (29 гл.),
  «Über die Geduld» (16 гл.), «Über die Buße» (12 гл.), «An die Gattin»
  (19 гл.), «Gegen die Juden» (14 гл.), «Über die Schauspiele» (30 гл.),
  «An die Märtyrer» (6 гл.), «An Scapula» (5 гл.), «Das Zeugnis der Seele»
  (6 гл.), «Gegen Hermogenes» (45 гл.), «Gegen die Valentinianer» (39 гл.),
  «Arznei gegen den Skorpionstich» (15 гл.), «Über das Pallium» (6 гл.),
  «Über das Fliehen in der Verfolgung» (11 гл.), «Über die einmalige Ehe»
  (17 гл.), «Über die Aufforderung zur Keuschheit» (13 гл.), «Über das Fasten
  gegen die Psychiker» (17 гл.), «Über die Verschleierung der Jungfrauen»
  (17 гл.), «Über die Ehrbarkeit» (22 гл.), «Über den weiblichen Putz»
  (2 книги, 9+13 гл.); меню — «2. Jahrhundert» → «Werke». Права: `pd`.

- **Василий Великий** (`Basilius_der_Große`): автор — перевод RU, обложка с RU;
  «Homilien über das Hexaemeron» BKV 1925, 9 бесед, 270 КБ, «Ausgewählte
  Briefe» (Auswahl, 111 писем), «Ausgewählte Predigten» (Auswahl, 20 бесед);
  меню — «4. Jahrhundert» → «Werke/Briefe/Predigten». Права: `free_bkv`.

- **Амвросий Медиоланский** (`Ambrosius_von_Mailand`): автор — перевод RU,
  обложка с RU; «Über die Mysterien» (41 КБ), «Exameron» (496 КБ, 6 частей),
  «Über die Buße» (148 КБ, 30 глав), «Der Tod ist ein Gut» (84 КБ),
  «Über den Tod seines Bruders Satyrus» (187 КБ), «Trauerrede auf Kaiser
  Theodosius» (49 КБ), «Die Flucht vor der Welt» (42 КБ), «Über die Witwen»
  (39 КБ), «Über die Jungfräulichkeit» (47 КБ), «Über die Jungfrauen» (71 КБ),
  «Über die Pflichten der Kirchendiener» (208 КБ); меню — «4. Jahrhundert» →
  «Dogmatische/Exegetische/Moralisch-asketische Werke». Права: `free_bkv`.

- **Иоанн Златоуст** (`Johannes_Chrysostomus`): автор — перевод RU (63 КБ),
  обложка с RU; «Über das Priestertum» (6 книг, 272 КБ), «Vom jungfräulichen
  Stande» (85 гл., 239 КБ), «Erster Brief an Theodor» (107 КБ),
  «Homilien über die Buße» (9 бесед, 246 КБ), «Homilien über die Bildsäulen»
  (2 части, 14+7 бесед, 514+251 КБ), «Homilien über das Matthäusevangelium»
  (6 частей, 12+12+15+16+16+19 бесед), «Homilien über den Römerbrief»
  (3 части, 13+11+9 бесед), «Homilien über den 1. Korintherbrief»
  (3 части, 16+14+14 бесед), «Homilien über den 2. Korintherbrief»
  (2 части, 12+18 бесед), «Kommentar zum Galaterbrief» (6 гл., 244 КБ),
  «Homilien über den Epheserbrief» (2 части, 17+7, 402+207 КБ),
  «Homilien über den Philipperbrief» (16 гл., 437 КБ), «Homilien über den
  Kolosserbrief» (12 гл., 363 КБ), «Homilien über den 1./2. Thessalonicherbrief»
  (11+5 гл., 299+121 КБ), «Timotheus/Titus/Philemon» (19+10+6+4 гл.),
  «Hebräerbrief» (2 части, 16+18 гл.), «Briefe an Olympias» (Auswahl, 283 КБ);
  меню —
  «4. Jahrhundert» → «Pastorale und katechetische/Moralisch-asketische Werke».
  Права: `free_bkv`/`pd`.

- **Иларий Пиктавийский** (`Hilarius_von_Poitiers`): автор — перевод RU,
  обложка с RU; «Gegen die Arianer, oder gegen Auxentius von Mailand» (21 КБ),
  «Zwölf Bücher über die Dreieinigkeit» (1,1 МБ), «Abhandlungen über die
  Psalmen»; меню — «4. Jahrhundert» → «Dogmatische/Exegetische Werke».
  Права: `pd`.

- **Кирилл Иерусалимский** (`Cyrill_von_Jerusalem`): автор — перевод RU,
  обложка с RU; «Katechesen an die Täuflinge» (19 гл., 580 КБ),
  «Mystagogische Katechesen» (5 гл., 42 КБ); меню — «4. Jahrhundert» →
  «Katechetische Werke». Права: `free_bkv`.

- **Кирилл Александрийский** (`Cyrill_von_Alexandrien`): автор — перевод RU,
  обложка с RU; «Über die Menschwerdung des Eingeborenen» (93 КБ),
  «Erklärung des nicäischen Glaubensbekenntnisses» (45 КБ), «Über den rechten
  Glauben an den Kaiser» (100 КБ), «Drei ökumenische Briefe» (48 КБ); меню —
  «5. Jahrhundert» → «Dogmatische Werke». Права: `free_bkv`.

- **Иероним Стридонский** (`Hieronymus`): автор — перевод RU, обложка с RU;
  «Dialog gegen die Pelagianer» (4 гл., 286 КБ), «Vita Pauli» (22 КБ),
  «Vita Hilarion» (69 КБ), «Gegen Helvidius» (61 КБ), «Vita Malchi» (20 КБ),
  «Ausgewählte Briefe» (Auswahl), «Gegen Vigilantius» (35 КБ); меню —
  «4. Jahrhundert» →
  «Dogmatische/Hagiographische Werke». Права: `free_bkv`.

- **Иоанн Кассиан** (`Johannes_Cassianus`): автор — перевод RU, обложка с RU;
  «Von den Einrichtungen der Klöster» (12 гл., 401 КБ), «Sieben Bücher über die
  Menschwerdung Christi» (8 гл., 333 КБ), «Vierundzwanzig Unterredungen»
  (2 части, 610+607 КБ); меню — «5. Jahrhundert» →
  «Asketische/Dogmatische Werke». Права: `free_bkv`.

- **Августин** (`Augustinus_von_Hippo`): автор — перевод RU, обложка с RU;
  «Enchiridion» (204 КБ), «Vier Bücher über die christliche Lehre» (400 КБ),
  «Vom ersten katechetischen Unterricht» (142 КБ), «Vier Bücher über das
  Symbolum» (181 КБ), «Bekenntnisse» (2 части, 299+424 КБ), «Fünfzehn Bücher
  über die Dreieinigkeit» (1,0 МБ), «Ausgewählte Briefe» (Auswahl),
  «Vorträge über das Johannesevangelium» (124 беседы, 2,2 МБ); меню —
  «5. Jahrhundert» →
  «Dogmatische/Exegetische/Pastorale Werke».
  Права: `free_bkv`.

- **Ефрем Сирин** (`Ephraem_der_Syrer`): автор — перевод RU, обложка с RU;
  «Rede über die Auferweckung des Lazarus» (23 КБ), «Hymnen gegen die
  Irrlehren» (56 гимнов, 298 КБ); меню — «4. Jahrhundert» →
  «Predigten/Werke». Права: `free_bkv`.

- **Епифаний Кипрский** (`Epiphanius_von_Salamis`): автор — перевод RU,
  обложка с RU; «Der Festgeankerte (Ancoratus)» (308 КБ); меню —
  «4. Jahrhundert» → «Dogmatische Werke». Права: `free_bkv`.

- **Иоанн Дамаскин** (`Johannes_von_Damaskus`): автор — перевод RU, обложка
  с RU; «Genaue Darlegung des orthodoxen Glaubens» в 4 книгах; меню —
  «8. Jahrhundert» → «Dogmatische Werke». Права: `free_bkv`.

- **Евсевий**: добавлены «Die Märtyrer in Palästina» (BKV, EN-оригинал);
  меню — «Märtyrer».

- **Григорий Богослов** (`Gregor_von_Nazianz`): автор — перевод RU, обложка
  с RU; «Ausgewählte Reden» (Auswahl, 20 слов); меню — «4. Jahrhundert» →
  «Reden». Права: `free_bkv`.

- Добавлены BKV-труды без RU-эталона: «Kommentar zum Matthäusevangelium»
  Илария, «Vita Constantini» Евсевия, «Sieben Gespräche» Кирилла
  Александрийского. «Панарион» Епифания убран (в BKV только пересказ/фрагмент).

Осталось из партии 1: Папий, Кодрат (свои переводы),
Папий и Кодрат (переводы с греческого), «О девстве» Климента (нет немецкого PD).

## 7. Труды без RU-страницы и меню

- **Не подставлять чужой `src`.** Если у труда нет RU-страницы, обычный
  `TranslationImporter` не использовать: он привяжет текст к неправильной
  группе. Вместо этого — `script/translations/de/import_external_works.rb`:
  страница создаётся напрямую (DE-only), тело — из
  `db/translations/de/external/*.html`, источник — в `references`.
- **Не путать с «пересказами».** «Панарион» Епифания убран: BKV даёт только
  `Anakephalaiosis` и Haer. 78, а не полный текст.
- **Меню авторов по RU.** `mirror_author_folders.rb` создаёт верхние
  категории и переносит труды по RU-родителю; `cleanup_duplicate_authors.rb`
  убирает заготовки, под которыми уже есть страница.
- **Части книг — под книгами.** `restructure_chrysostom_nt.rb` (Новый Завет
  Златоуста), `group_author_parts.rb` (Кассиан, Августин). Родитель-книга
  получает путь первой части, части — `1`, `2`, … как в RU.
- **Французские меню.** `script/translations/fr/fix_chrysostom_menu.rb` и
  `fix_tertullian_menu.rb`: в названиях пунктов оставляем только французскую
  часть; части книг Тертуллиана группируем под «Contre Marcion» и
  «De l’Ornement des Femmes».
- **Проверка:** `check_library_structure.rb de/fr`, все страницы 200, в меню
  нет кириллицы/латинских дублей, у трудов есть `references`.


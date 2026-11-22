# Латинская библиотека: наполнение по Patrologia Latina

План наполнения раздела `la` (латинские отцы) текстами Migne с azbyka.ru.
Инвентарь, конвейер, баты, риски. Конвейер реализован: `script/translations/pl/` (README там же).

## 0. Статус

- **Пилот сделан**: Киприан Карфагенский (PL 4) — 21 страница в dev: страница автора
  (`CpCr_Cyprianus_Carthaginensis`, память + биография на латыни) и 20 трудов в двух папках
  меню («Epistolae» — 4 части писем + «Ad Fortunatum», «Tractatus» — 15 трудов,
  включая 3 книги Testimonia), ~900 КБ латинского текста.
  Письма и «Testimonia» раздроблены (4 и 3 страницы), потому что длинные страницы тяжело
  читать с телефона; вторая и следующие части получили отдельные группы языков.
- **Киприан на проде** (деплой + импорт 22.11): 23 страницы, все 200.
- **Амвросий, бат 2**: PL 14 — автор (`Ambr_Ambrosius_Mediolanensis`) и **все 18 подлинных
  трудов тома** (34 страницы): Hexaemeron (6 книг), De Paradiso, De Cain et Abel (2 книги),
  De Noe et Arca, De Abraham (2), De Isaac et Anima, De Bono Mortis, De Fuga Saeculi,
  De Jacob et Vita Beata, De Joseph Patriarcha, De Benedictionibus Patriarcharum,
  De Elia et Jejunio, De Nabuthe, De Tobia, De Interpellatione Job et David (4 книги),
  Apologia David, Apologia Altera, Enarrationes in XII Psalmos (7 страниц по псалмам).
  Из них 6 совпадают с русскими трудами, остальные — подлинные, но без русского перевода.
- **Амвросий, PL 15 — готово и на проде**: Expositio in Psalmum CXVIII (7 страниц по
  «Sermones») и Expositio Evangelii secundum Lucam (12 страниц: книги I–X, Liber VII и X
  дополнительно поделены пополам). Всего у Амвросия 53 страницы трудов.
  Из тома PL 15 не берём: «Commentarius in Cantica Canticorum» — компиляция
  Гийома Сен-Тьеррийского из Амвросия, не его труд; «De Excidio urbis Hierosolymitanae» —
  Migne сам пишет, что бенедиктинцы его Амвросию не приписывают (авторство спорно).
- **Амвросий, PL 16 — готово (42 страницы)**: De Officiis (3 кн., Liber I поделён), De Virginibus,
  De Viduis, De Virginitate, De Institutione Virginis, Exhortatio Virginitatis, De Mysteriis,
  De Sacramentis, De Poenitentia (2 кн.), De Fide (5 кн., V поделена), De Spiritu Sancto (3),
  De Incarnationis Dominicae Sacramento (2), Epistolae (10 страниц по номерам писем),
  De Excessu Fratris (2), De Obitu Valentiniani, De Obitu Theodosii, Hymni (12 гимнов стихами).
  Не взято: «De Lapsu Virginis Consecratae» — Spuria; «Fragmentum ex Theodoretо» — греческий
  текст (место в греческой библиотеке).
  Мелкие редакторские резюме глав Migne (курсивные абзацы вроде «Episcopi proprium munus,
  docere…») вырезаются флагом `drop_em`; нумерованные абзацы и цитаты Писания сохраняются.
- **Амвросий, PL 17 — готово (2 страницы)**: Explanatio Symboli ad Initiandos (подлинный,
  есть русский перевод) и Sermo de Mysterio Paschae (Migne сам называет его «conciunculam»,
  Амвросию не принадлежит; взят только потому, что есть русская страница, — с пометкой
  в примечаниях). Остальное в PL 17 — приложение «Spuria»: комментарий на Послание к Римлянам
  (это Амброзиастер), «De XLII mansionibus», «In Symbolum», «De fide orthodoxa», сборник
  проповедей, «De Poenitentia» и «De Spiritu Sancto» (подложные), «Acta Sebastiani»,
  «De vocatione gentium», «De moribus Brachmanorum», «Hymni attributi» и др. — не берём.
- **Иларий — готово (4 страницы)**: Liber contra Auxentium (PL 10), Tractatus in Psalmum CXXX
  (PL 9), De Unitate Fidelium cum Deo (De Trinitate VIII, 13–16) и De Trinitate (fragmenta:
  I, 1–13 по нумерации русского перевода = Migne I, 1–12; XII, 52, 53, 57; I, 8).
  Фрагменты собираются `excerpt.py` по номерам книг и глав. Не взятo: «Изъяснение тайн.
  Книга 1» — Tractatus Mysteriorum найден только в 1887 г. и в Migne (PL 9–10) отсутствует.
  (Историческая заметка: раньше Иларий был отложен из-за фрагментов — теперь они собраны
  по номерам глав, см. выше.)
- **Иоанн Кассиан — готово (35 страниц)**: De Coenobiorum Institutis (3 страницы по книги:
  I–IV, V–VIII, IX–XII; книги I–IV поделены), все 24 Collationes отдельными страницами
  (Collatio I…XXIV по 17–70 КБ), De Incarnatione Christi contra Nestorium (7 книг + префаций
  к Льву; Liber I поделён). Русские своды «Собеседований» привязаны к первой конференции
  каждой группы: скитская #1 → Coll. I, скитская #2 → Coll. IX (она начинается с её главы 3),
  Фиваида → Coll. XI, Нижний Египет → Coll. XVIII. Из тома PL 50 не берём чужие труды
  (Vigilius, Fastidius, Coelestinus, Eucherius, Hilarius Arelatensis).
  Варианты чтения в квадратных скобках вида «[Lips. in marg. …]» вырезаются (`strip_apparatus`).
- **Августин, PL 45 — готово (32 страницы)**: De Dono Perseverantiae (2) и Contra Secundam
  Juliani Responsionem Opus Imperfectum (6 книг, Liber VI поделен на 8 частей).
  Русская пара: «О даре пребывания».
- **Августин, PL 43 — готово (31 страница)**: антидонатистские труды — Psalmus contra partem
  Donati (стихи), Contra Epistolam Parmeniani (2), De Baptismo contra Donatistas (4; первая
  часть — существующая страница `Mw8R_…`), Contra Litteras Petiliani (3), Contra Cresconium (4),
  De Unico Baptismo, Breviculus Collationis, Ad Donatistas post Collationem, Sermo ad
  Caesareensis plebem, De Gestis cum Emerito, Contra Gaudentium (2 книги, вторая поделена).
- **Августин, PL 44 — готово (30 страниц)**: антипелагианские — De Peccatorum Meritis (3),
  De Natura et Gratia, De Perfectione Justitiae, De Gestis Pelagii, De Gratia Christi,
  De Nuptiis et Concupiscentia (2), De Anima et ejus Origine (2), Contra Duas Epistolas
  Pelagianorum (2), Contra Julianum (6), De Gratia et Libero Arbitrio, De Correptione et
  Gratia, De Praedestinatione Sanctorum. Русские пары: «О супружестве и похоти»,
  «О благодати и свободном решении», «Об упреке и благодати», «О предопределении святых».
- **Августин, PL 35 — готово (25 страниц)**: Quaestiones Evangeliorum (2 книги; вторая часть
  привязана ко второму русскому переводу книги II), In Ioannis Evangelium Tractatus CXXIV
  (15 страниц по 8 трактатов), In Epistolam Ioannis ad Parthos (3), Expositio Propositionum
  ex Epistola ad Romanos, Epistolae ad Romanos Inchoata Expositio, Expositio Epistolae ad
  Galatas (2). Не взят «Quaestiones XVII in Matthaeum» — Migne сам считает его сомнительным
  (нет в Retractationes), русского перевода нет.
- **Августин, PL 36–37 — готово (31 + 26 страниц)**: Enarrationes in Psalmos, сгруппированы
  по ~110 КБ с заголовками-диапазонами («Enarrationes in Psalmos I–VII»); пути разделены по
  томам (`Aug_Enarr36_*`, `Aug_Enarr37_*`). Русские пары: Пс. 1 → `rAYR`, Пс. 125 → `G9ph`.
- **Августин, PL 38–39 — готово (41 + 28 страниц)**: Sermones (нумерация 1–340 и 341–396,
  плюс отдельная серия 270–317 в конце PL 39), по ~110 КБ с заголовками «Sermones 1–6» и т. п.
- **Августин, PL 40 — готово (30 страниц)**: De Diversis Quaestionibus LXXXIII (3),
  ad Simplicianum (2), De Octo Dulcitii Quaestionibus, De Fide Rerum quae non Videntur,
  De Fide et Symbolo, De Fide et Operibus, Enchiridion (2), De Agone Christiano,
  De Catechizandis Rudibus, De Continentia, De Bono Conjugali, De Sancta Virginitate,
  De Bono Viduitatis, De Conjugiis Adulterinis (2), De Mendacio, Contra Mendacium,
  De Opere Monachorum, De Divinatione Daemonum, De Cura pro Mortuis, De Patientia,
  De Symbolo (2), Sermo de Disciplina Christiana, De Cantico Novo (2), De Utilitate Jejunii,
  De Urbis Excidio. Приложение тома («Appendix… subdititia quaedam opuscula») не берём.
- **Августин, PL 41 — готово (22 страницы)**: De Civitate Dei, по книге на страницу;
  Liber I привязан к русскому «О граде Божием #1». Приложения (письма о перенесении мощей
  св. Стефана) не берём.
- **Августин, PL 42 — готово (40 страниц)**: De Trinitate (15 книг + проэмии), Contra Faustum
  (33 книги по 4 на страницу), Contra Maximinum (2), Contra Adversarium Legis (2),
  De Haeresibus, Tractatus adversus Judaeos, De Utilitate Credendi, De Duabus Animabus,
  Acta contra Fortunatum, Contra Adimantum (2), Contra Epistolam Manichaei, De Actis cum
  Felice, De Natura Boni, Contra Secundinum, Ad Orosium, Contra Sermonem Arianorum,
  Collatio cum Maximino. Приложения тома (списки подложных трактатов) не берём.
- **Августин, PL 34 — готово (42 страницы)**: De Doctrina Christiana (3), De Vera Religione
  (существующая страница обновлена), De Genesi contra Manichaeos (2), De Genesi ad Litteram
  Imperfectus, De Genesi ad Litteram (6 частей по 2 книги), Locutiones in Heptateuchum (2),
  Quaestiones in Heptateuchum (7 книг, большие поделены), Annotationes in Job (2),
  Speculum de Scriptura Sacra (4), De Consensu Evangelistarum (4 книги, II и III поделены),
  De Sermone Domini in Monte (2). Русские пары: Христианская наука, Об истинной религии,
  О книге Бытия, Зерцало, О согласии евангелистов.
- **Августин, PL 32 — готово (26 страниц)**: Retractationes (2), Confessiones (5 по книгам),
  Contra Academicos (2), De Beata Vita, De Ordine (2), Soliloquia, De Immortalitate Animae,
  De Quantitate Animae (2), De Musica (3), De Magistro, De Libero Arbitrio (3),
  De Moribus Ecclesiae Catholicae et de Moribus Manichaeorum (2), Regula ad Servos Dei.
  Существовавшая пустая авторская страница (`I3i4_…`) дозаполнена биографией; труды — в папках
  «Autobiographica», «Philosophica», «Dogmatica», «Monastica». Тома PL 35–47 скачаны и
  подготовлены (`prep.py` заменяет скрипты 1–3: gif→греческий, `<small>`, `[Col.]`, таблицы).
- Чего в PL 4 нет: тексты 14 писем (XLI, XLII, XLIII, XLV, XLVIII, XLIX, LII, LVII, LIX,
  LXVIII, LXX, LXXII, LXXIII, LXXVI). Migne сам отсылает их к тому III — в тексте стоят
  заглушки, номера перечислены в примечаниях. Достать их из PL 3 — следующая задача.
- Решения по пилоту: аппарат Migne (ARGUMENTUM/CAPITULA/MONITUM/ADMONITIO, курсивные резюме,
  ссылки на издания) **удаляется целиком**; для Dubia/Spuria — пометка в примечаниях
  («Hoc opusculum in Prolegomenis Patrologiae Latinae inter dubia … recensetur»);
  крупные труды **дробятся**; примечание к труду — `Patrologia Latina, t. N, coll. X-Y
  (J.-P. Migne, Parisiis 1844)` + ссылка на azbyka.

## 1. Правило отбора

1. Берём труд, если он **есть в русской библиотеке** (`church_writers`, id 363) **или**
   **достоверно принадлежит автору** (подлинность по Prolegomena Migne и современной
   науке). Spuria/Dubia — только при наличии русской страницы и с пометкой в примечаниях.
   Так в бат Амвросия вошли и труды без русского перевода (De Paradiso, De Cain et Abel,
   De Noe et Arca, De Abraham, De Benedictionibus, De Elia, De Nabuthe, De Tobia,
   De Interpellatione Job et David, Apologiae David, Enarrationes in XII Psalmos).
2. Текст труда — только Migne (Patrologia Latina) с azbyka.ru. Других изданий не подмешиваем;
   уже существующие `la`-страницы (Harvey для Иринея, CSEL для Викентия) не переписываем.
3. Страница автора на латыни — **только «дата памяти + биография»** с русской страницы
   (перевод биографии на латынь). Разделы «Вера» (цитаты), «Творческое наследие»,
   «Гимнография» в `la` не переносим.
4. Чего нет в PL — не добавляем, решение фиксируется в отчёте по агенту.

## 2. Что уже есть в латинском разделе

Меню латинской библиотеки (`church_writers_la`, id 1400) уже разведено по векам:
`Saeculum I–V`, `Saeculum XI`, внутри — пункты-заготовки на латыни почти для всех авторов
(у части уже проставлен `path`). Это готовая «сетка»: заготовку заполняет
`menu: { replace: "<старое название>" }` импортёра.

| Автор (la) | Трудов RU | Трудов la | Чего не хватает | Авторская страница la |
|---|---|---|---|---|
| Tertullianus | 37 | 36 | 1 (дубль RU «О женских украшениях — кн. 1») | есть, полная (8 КБ) |
| Irenaeus Lugdunensis | 7 | 5 | 2 — **вне PL** (см. §4) | есть, полная (9 КБ) |
| Marcus Minucius Felix | 1 | 1 | 0 | есть, краткая (0,3 КБ) |
| Cyprianus Carthaginensis | 15 | 0 | 15 | **нет** |
| Vincentius Lerinensis | 2 | 1 | 1 (проверить, есть ли в PL 50) | есть, краткая (0,9 КБ) |
| Hilarius Pictaviensis | 5 | 0 | 5 | **нет** |
| Ambrosius Mediolanensis | 48 | 0 | ~46 | **нет** |
| Ioannes Cassianus | 7 | 0 | 7 | **нет** |
| Hieronymus Stridonensis | 58 | 2 | ~52 (минус 4 «Вульгаты») | есть, полная |
| Aurelius Augustinus | 75 | 3 | ~72 | **есть, но пустая (8 байт)** |
| Constantinus Magnus | 1 | 0 | 1 (только если текст есть в PL 8) | нет |
| **Итого** | **256** | **48** | **~197** | 5 создать / 2 дозаполнить |

Объём: ~197 новых страниц, ~23 МБ латинского текста (оценка по соотношению
«латынь/русский перевод» на уже сделанных авторах: Тертуллиан 2,5 МБ против 2,9 МБ,
Ириней 0,98 против 1,04). Для сравнения: в RU-библиотеке сейчас 1711 трудов, вся база — 5 ГБ.

## 3. Источник: что реально есть на azbyka

- 221 том (`https://azbyka.ru/otechnik/Patrologija/PLn.html`), проверены выборочно (1, 7, 9–10,
  14–17, 22–34, 31, 35, 40, 49, 50) — текст есть, объём 4–14 МБ на том. Это полный Migne,
  а не оглавления.
- Один том = **одна HTML-страница** целиком: front matter, Elenchus, Praefatio, Vita,
  Admonitiones, тексты трудов, Appendices, Indices — всё подряд.
- Разметка: заголовки `<H2>/<H3>/<H4>` (в т.ч. `<H4><CENTER>…</CENTER></H4>`),
  номера столбцов — `<TR><TD><STRONG>[Col. 0123A]</STRONG></TD></TR>`, редакционные
  примечания и варианты чтений — `<SMALL>[Note: …]</SMALL>`, номера страниц издания — `<SUP>182</SUP>`.
- Греческие буквы — картинки `images/pldgreek/*.gif`, 198 файлов, до 170 тыс. вставок в томе.
- Качество распознавания: хорошее. Строки рвутся **по границам слов** (проверено на
  Hexaemeron PL 14 и De Lapsis PL 4: переносов по слогам нет), но есть мусор: одиночные номера
  страниц в тексте («547 Quod enim…»), двойные пробелы, потерянные символы на месте
  греческих вставок. Редакционный аппарат Migne (Baluze, Maran, Oxford notes) — в `<SMALL>`,
  то есть удаляется существующим скриптом 2.

Нужные тома: 1–2 (есть), 3 (есть), 4 (есть), 9–10 (есть), 14–17 (есть), 22–30 (есть),
32–34 (есть), 49–50 (есть); **скачать остаётся 35–47** (Августин, ~13 томов, ~65 МБ).

Готовые скрипты (`~/Desktop/Библеокс/PL/`) покрывают только первый этап чистки:
`1_replace_gif2greek.py` (gif → греческие буквы), `2_remove_notes.py` (удаление `<small>`),
`3_replace_cols.py` (`[Col. 0NNN` → `[PL<том>.NNN`). Нарезки на труды, вычистки аппарата
и сборки страниц в них нет.

## 4. Что заведомо вне PL (не берём)

- **Ириней**: «Против ересей» в PL нет (греческий оригинал + латинский перевод в PG 7;
  на сайте уже Harvey). «Доказательство апостольской проповеди» сохранилось по-армянски,
  «Фрагменты» — греческие. Оба труда в `la` не появятся.
- **Антоний Великий** — уже сделан (PG 40 + Vossius), не трогаем.
- **Иероним, «Вульгата на русском языке» (4 страницы)** — это библейский текст, не PL.
- **Амвросий, «Медиоланская Божественная Литургия»** — не сочинение Амвросия, в PL 14–17 нет.
- **Викентий, «О вероизложениях»** — проверить по PL 50 (вероятно, Excerpta/«Objectiones»,
  которых в PL нет).
- **Константин, «Миланский эдикт»** — проверить, есть ли текст в PL 8; скорее всего
  только у Лактанция (PL 7), тогда пропускаем.

## 5. Карта томов (для работы)

| Автор | Тома PL | Что в томах |
|---|---|---|
| Тертуллиан | 1–2 | всё, уже сделано |
| Минуций Феликс | 3 (стлб. 231–366) | Octavius, сделано |
| Киприан | 4 (основное), 3 и 5 (письма, dubia) | Epistolae 1–81, трактаты, Testimonia, dubia/supposita |
| Иларий | 9–10 | De Trinitate, In Psalmos, In Matthaeum, De Synodis, Contra Auxentium |
| Амвросий | 14–17 | Hexaemeron, De officiis, De fide, De Spiritu, письма, De sacramentis/mysteriis, гимны |
| Иероним | 22–30 | письма (22), толкования на пророков (24–25), Matthew (26), Иезекииль/Даниил (25), Хроника (27), Vulgata-прологи (28), «О знаменитых мужах» (23) |
| Августин | 32–47 | Retractationes/Confessiones (32), письма (33), De Genesi (34), In Ioannem (35), Enarrationes in Psalmos (36–37), Sermones (38–39), Enchiridion/De Trinitate/De Civitate Dei (40–41), Contra Faustum и др. (42), Quaestiones (43–44), Contra Iulianum (44–45), spuria (39–40, 46–47) |
| Кассиан | 49–50 | De institutis, Collationes, De Incarnatione |
| Викентий Леринский | 50 (Commonitorium) | Peregrini tractatus, сделано |

## 6. Конвейер

### Шаг 0. Манифест (главный документ работы)

На каждый том — YAML-манифест `tmp/pl/<том>.yml`, который перечисляет **только нужные труды**:

```yaml
volume: 4
author: Cyprianus_Carthaginensis          # path la-страницы автора
works:
  - pl: "LIBER DE LAPSIS"                 # как называется в Migne (для поиска)
    cols: "463-518"                       # диапазон столбцов, откуда начинается труд
    ru: 02jQL1xq_Книга_о_падших__Киприан_Карфагенский
    path: CpCr_De_Lapsis
    title: De Lapsis
    title_sub: ~
    menu: Tractatus                       # категория в меню автора (или null)
    priority: 3
  - pl: "EPISTOLAE"
    ru: tNaHSPT6_Письма_Киприана_Карфагенского
    path: CpCr_Epistolae
    title: Epistolae
    split: letter                         # один h2 на письмо: "EPISTOLA I", ...
```

Манифест — единственное место, где живёт соответствие «труд PL ↔ страница RU»; всё
остальное (нарезка, разметка, YAML для импорта) из него генерируется. Это позволяет
перепроверять и повторять импорт.

### Шаг 1. Скачивание

```bash
for i in 35 36 37 38 39 40 41 42 43 44 45 46 47; do
  wget --recursive --level=inf --no-clobber --page-requisites --convert-links \
       --adjust-extension --no-parent "https://azbyka.ru/otechnik/Patrologija/PL${i}.html"
done
```

(как в README.txt; тома 1–34, 49–50 уже лежат). Проверка: файл > 1 МБ и в нём есть `[Col. 0`.

### Шаг 2. Чистка тома (существующие скрипты + 2 новые)

1. `1_replace_gif2greek.py` — gif → греческие буквы (198 файлов, словарь полный;
   предупреждения «No replacement found» сохранять в лог и разбирать: новые имена добавлять в словарь).
2. `2_remove_notes.py` — удаление `<small>` (редакционный аппарат, варианты чтений).
3. `3_replace_cols.py` — `[Col. 0463A]` → `[PL4.463A]`.
4. **новый `4_unwrap_tables.py`** — `<TR><TD><STRONG>[PL4.463A]</STRONG></TD></TR>` →
   `<strong>[PL4.463A]</strong>`; убрать `<CENTER>`, `<SUP>NNN</SUP>`, `<BR>`-разрывы
   (в `<BR>`-стихах — в `<br>` нельзя: sanitizer его снимает, значит склеиваем с пробелом),
   схлопнуть двойные пробелы, убрать мусорные номера страниц (эвристика + ручной просмотр).
5. **новый `5_strip_apparatus.py`** — вырезать всё, что не текст трудов: front matter,
   `ELENCHUS`, `PRAEFATIO`, `VITA S. …`, `ADMONITIO`, `ARGUMENTUM`, `NOTAE`,
   `APPENDIX*`, `INDEX RERUM`, `SYLLABUS`, `CONSPECTUS`, `FINIS TOMI`.

### Шаг 3. Нарезка тома на труды

Скрипт `6_split_works.py` по манифесту: находит заголовок труда (по названию из Migne,
с допуском на переносы строк внутри `<H4>`), берёт диапазон до следующего труда из
манифеста и **обрезает** по границам столбцов (`cols:`), если название в Migne
встречается ещё и в Elenchus/индексе.

Проверка на каждом труде: первый абзац — начало текста (не «Vide», не «Cod.»), последний
абзац — не обрыв; в теле нет токенов редакции (`Voss.`, `Lam.`, `Edit.`, `Cod.`,
`pag.`, `Col.` вне маркеров). Всё найденное — в отчёт `tmp/pl/<том>.report.txt`.

### Шаг 4. Сборка разметки страницы

Правила (по образцу уже живущих `la`-страниц):

- `<h2>` — книга/глава (`LIBER I`, `CAPUT I`); для многокнижных трудов `h2` = книга,
  `h3` = глава. В `<h2>` не включать номера столбцов и «(C)»/«(G,S)».
- `<p>` — абзацы; маркеры столбцов остаются на своих местах: `<strong>[PL4.463A]</strong>`.
- `<blockquote><p><em>…</em></p></blockquote>` — только для стихов/цитат Писания,
  как в RU.
- Сноски не переносим: Migne-примечания удаляются на шаге 2. В `references` — источник.
- Кегль/заголовки Elenchus не переносим.
- Cap на размер страницы: если труд > ~450 КБ, делим по книгам на отдельные страницы
  (как RU «О граде Божием #1–7»); путь и группа — по книге.

### Шаг 5. Авторская страница

Тело (по образцу Иринея/Иеронима):

```html
<p><strong>Dies memoriae:</strong> 16 Septembris (29 Septembris)</p>
<h2>Biographia</h2>
<h3>…</h3><p>…</p>
```

Источник — только блок «Биография» (+ «День памяти») с RU-страницы автора: разобрать RU-body
на секции `<h2>`, взять `Биография`, сохранить порядок `<h3>`, перевести на латынь.
`title` — «Cyprianus Carthaginensis, saeculum III», `title_sub` — «hieromartyr (~200-258),
episcopus Carthaginensis» (по RU `title_sub`/первой строке биографии). `seo_kind: person`.

Уже существующие страницы Augustine (пустая) и Minucius/Vincent (краткие) — дозаполнить
по тому же правилу; Tertullianus и Irenaeus не трогать.

### Шаг 6. YAML + импорт

`TranslationImporter` подходит без правок: если `list` — это страница автора, труды
создаются как её дочерние страницы, а пункты меню попадают в **меню автора** (так и
устроены существующие авторы: у Тертуллиана меню висит на его странице, `page_id=4451`).

На автора — два YAML:

1. `db/translations/la/<author>_author.yml` — `list: church_writers_la`,
   `menu: { parent: "Saeculum III", replace: "Cyprianus Carthaginensis, hieromartyr (~200-258)" }`;
2. `db/translations/la/<author>_works.yml` — `list: <path автора>`,
   `folders: [{ path: "Tractatus", priority: 1 }, …]`, каждый труд с `menu: { parent: "Tractatus" }`.

Прогон: `DRY_RUN=1` → dev-импорт → просмотр 3–5 страниц и меню → отчёт → подтверждение → прод.

### Шаг 7. Постобработка

- `script/seo/mark_seo_kinds_pass2.rb` — `seo_kind` для новых страниц (`book`/`person`).
- Проверить поиск и офлайн-экспорт на одной большой странице (`body_rendered` — ещё +25 МБ).
- `Page#render_body` строит оглавление из `h2/h3`: у «О граде Божием» это 22 книги,
  у «Толкования на Исайю» — 30 глав, приемлемо; у писем Иеронима — 120+ пунктов, проверить вёрстку.

## 7. Автопроверки (обязательны до прода)

1. **Полнота**: число `h2` (книг/глав) в латинском труде сопоставимо с RU-трудом;
   последняя строка латинского текста — не обрыв (нет висящего «et», «in», «quod»).
2. **Чистота**: в body нет `<small>`, `[Note:`, `<sup>`, `<table`, `Voss.`, `Edit.`,
   `Cod.`, «Vide» в начале абзаца, «CONSPECTUS», «ELENCHUS».
3. **Маркеры**: `[PL<том>.NNN]` монотонно возрастают, том совпадает с манифестом.
4. **Ссылки**: все `href` на сайте — 200; якоря существуют.
5. **Паритет меню**: у автора в меню те же труды, что в RU, порядок соответствует RU
   (или осмысленно перегруппирован, с записью в отчёт).
6. **Кодировка**: нет `&amp;`-мусора, нет мягких переносов (U+00AD), нет двойных пробелов.

## 8. Баты (порядок и оценка)

| Бат | Состав | Трудов | Объём | Зачем |
|---|---|---|---|---|
| 1 (пилот) | **Киприан**, PL 4 (+3/5) | 15 | ~1 МБ | один том, есть трактаты, письма, dubia; нет ни одной la-страницы → проверяет весь конвейер, включая создание автора и меню |
| 2 | **Иларий** (PL 9–10) + Викентий | 6 | ~0,2 МБ | мелочь, проверка нескольких трудов в двух томах |
| 3 | **Кассиан** (PL 49–50) | 7 | ~1,4 МБ | два тома, крупные книги, «Собеседования» из нескольких RU-страниц |
| 4 | **Амвросий** (PL 14–17) | ~46 | ~3,6 МБ | 4 тома, много коротких трудов + гимны |
| 5 | **Августин** (PL 32–47) | ~73 | ~8 МБ | самый большой корпус, 16 томов (13 скачать), spuria в PL 39–40 |
| 6 | **Иероним** (PL 22–30) | ~52 | ~9 МБ | письма (нужна сверка нумерации Erasm./Pamel./Oxon. по каждой группе) и толкования на пророков |

Итого ~197 страниц. По темпу прошлых проектов — 1–3 рабочих сессии на бат, всего ~12–15.

Пилот — Киприан: он же самый дешёвый способ проверить, что конвейер и импортёр дают
страницу нужного вида. После пилота остальные баты идут по накатанному.

## 9. Риски и как снимаем

1. **Редакционный аппарат Migne вклинен в текст.** В PL 4 (Киприан) Baluze/Maran/Oxford
   notes идут в `<SMALL>` и в отдельных `ARGUMENTUM`/`NOTAE`-блоках. Первое снимает скрипт 2,
   второе — скрипт 5 и автопроверка по токенам. На пилоте выяснить, не остаётся ли аппарат
   в нормальном кегле — если да, дописать вырезание по «якорям» (заголовки NOTAE/ADMONITIO).
2. **Нумерация писем Иеронима** не совпадает между изданиями (Erasm./Pamel./Oxon./Lips.).
   Для групп «Письма 1–43 / 44–86 / 87–117» нужна таблица соответствия по каждой группе;
   делать отдельным подпроектом в бате 6, а не «в общем потоке».
3. **Многотомность одного труда** (De Civitate Dei; In Isaiam; Collationes): RU разбит на
   страницы по частям, la делаем 1:1 (по RU-странице), чтобы сохранить `group_lang_id`
   и паритет меню. Если том труда не влезает в 450 КБ — делим по книгам, но тогда
   в манифесте указываются «куски» с общим `ru` и отдельными `path`.
4. **Размер базы.** +23 МБ текста и ещё столько же `body_rendered`; для 5-гигабайтной базы
   некритично, но большие страницы (400+ КБ) дороже рендерить и экспортировать — следить
   на пилоте по времени ответа.
5. **Библейские ссылки в латыни** не линкуются: `BibleLinker` знает только ru/en/ja/de/zh/ko/el/hi,
   латинской Библии на сайте нет (`BIB_LANG_TO_LOCALE['la'] = 'eng-nkjv'`). Оставляем
   ссылки Migne текстом — как на существующих `la`-страницах. Не привязывать к английской Библии.
6. **OCR-мусор** (номера страниц, потерянные буквы в греческих вставках, двойные пробелы):
   чистка эвристиками + выборочная вычитка. Полную вычитку не обещаем — в `references`
   пишем «textus recognitione automata».
7. **Дубли RU-трудов** (например «О женских украшениях — кн. 1» у Тертуллиана двумя
   страницами): второй `la`-страницы не создаём, в отчёте фиксируем.
8. **Права**: Migne — общественное достояние, сканы/транскрипция azbyka — указывать источник
   в `references` обязательно.

## 10. Открытые вопросы

1. **Порядок батов** — принимаете предложенный (Киприан → Иларий → Кассиан → Амвросий →
   Августин → Иероним) или хотите начать с Августина/Иеронима, несмотря на объём?
2. **Издание в `references`**: писать ли `Patrologia Latina, t. 4, coll. 463-518 (Migne, 1844)`
   и ссылку на azbyka, или ещё и на `patrologia-lib.ru` (как у Минуция)?
3. **Редакционный аппарат** (ADMONITIO/ARGUMENTUM) — удалять целиком (предлагаю) или
   оставлять как вступление под `<h2>Admonitio</h2>` (так сделано на «De Vera Religione»)?
4. **Авторские страницы**: переводить только «Биография» (без «Гимнография»/«Вера»)?
   Для Амвросия и Кассиана в RU-биографии мало текста — устраивает краткая страница?
5. **Дробить ли большие труды** по книгам (Августин «О граде Божием», Иероним «На Исайю»)
   или держать один труд = одна страница, как в RU?
6. **Язык `title_sub` и названий трудов**: латинизированные формы («De Lapsis», «Collationes
   patrum») — да? Для писем — «Epistolae» одной страницей или по группам, как RU?

### Ответы (пилот)

1. Порядок: Киприан → дальше по плану. **Пилот выполнен.**
2. `references`: `Patrologia Latina, t. 4, coll. 463-492 (Migne, 1844)` + ссылка на azbyka. Принято.
3. Аппарат удаляется целиком, но для Dubia/Spuria — короткая пометка в примечаниях. Принято.
4. Авторская страница — только «Биография» (без «Гимнография»/«Вера»). Принято.
5. Крупные труды дробятся (письма — по группам, Testimonia — по книгам). Принято.
6. Названия трудов — латинизированные, как в Migne; письма — по группам внутри одной папки
   «Epistolae». Принято.

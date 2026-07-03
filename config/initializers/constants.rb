VOTE_PLUS = '❤️'
VOTE_MINUS = '🚧' # '🛟'
# # Локали, которые переименовали
# 'cn' => 'zh-Hans',  # Китайский
# 'gr' => 'el',  # Греческий
# 'il' => 'he',  # Иврит
# 'in' => 'hi',  # Хинди
# 'ir' => 'fa',  # Персидский
# 'jp' => 'ja',  # Японский
# 'ke' => 'sw',  # Суахили
# 'kr' => 'ko',  # Корейский
# 'rs' => 'sr',  # Сербский
# 'tm' => 'tk',  # Туркменский
# 'vn' => 'vi',  # Вьетнамский
# 'cp' => 'cop'  # Коптский

# old_to_new = {
#   'cn' => 'zh-Hans',
#   'gr' => 'el',
#   'il' => 'he',
#   'in' => 'hi',
#   'ir' => 'fa',
#   'jp' => 'ja',
#   'ke' => 'sw',
#   'kr' => 'ko',
#   'rs' => 'sr',
#   'tm' => 'tk',
#   'vn' => 'vi',
#   'cp' => 'cop'
# }.map do |o,n|
#   ::Page.where(lang: o).each { |pg| pg.update!(lang: n) }
# end

# old_to_new = {
#   'cn' => 'zh-Hans',
#   'gr' => 'el',
#   'il' => 'he',
#   'in' => 'hi',
#   'ir' => 'fa',
#   'jp' => 'ja',
#   'ke' => 'sw',
#   'kr' => 'ko',
#   'rs' => 'sr',
#   'tm' => 'tk',
#   'vn' => 'vi',
#   'cp' => 'cop'
# }.map do |o,n|
#   pg = ::Page.where(path: "links_#{o}").first
#   if pg
#     pg.update!(path: "links_#{n}")
#   end
# end

# При добавлении новых локалей, добавь их также и тут:
# app/assets/javascript/all_before.js
# admin/src/views/pages/Index.vue

# В url сначала указывается локаль для UI, а потом язык контента (текста статьи или перевода Библии)
# Здесь перечислены локали, которые могут быть как языков UI, так и языком контента (статьи).
# https://en.wikipedia.org/wiki/List_of_ISO_639_language_codes
ALL_LOCALES = {
  'ar' => true, # 🇸🇦 AR - Арабский
  'hy' => true, # 🇦🇲 AR - Армянский
  'vi' => true, # 🇻🇳 VN - Вьетнамский
  'de' => true, # 🇩🇪 DE - Немецкий
  'en' => true, # 🇺🇸 EN - Английский
  'es' => true, # 🇪🇸 ES - Испанский
  'fr' => true, # 🇫🇷 FR - Французский
  'el' => true, # 🇬🇷 GR - Греческий
  'he' => true, # 🇮🇱 IL - Иврит
  'hi' => true, # 🇮🇳 IN - Хинди
  'fa' => true, # 🇮🇷 IR - Персидский
  'it' => true, # 🇮🇹 IT - Итальянский
  'ja' => true, # 🇯🇵 JP - Японский
  'sw' => true, # 🇰🇪 KE - Суахили
  'ko' => true, # 🇰🇷 KR - Корейский
  'sr' => true, # 🇷🇸 RS - Сербский
  'ru' => true, # 🇷🇺 RU - Русский
  'tk' => true, # 🇹🇲 TM - Туркменский
  'tr' => true, # 🇹🇷 TR - Турецкий
  'uz' => true, # 🇺🇿 UZ - Узбекский
  'zh-Hans' => true, # 🇨🇳 CN - Китайский - Упрощённый
  'zh-Hant' => true, # 🇨🇳 CN - Китайский - Традиционный
  # древние
  'la'  => true, # Латынь (ISO 639-1/2)
  'grc' => true, # Древнегреческий (классический) (ISO 639-3)
}

# Доступные в PG языки:
# Verse.connection.execute('SELECT cfgname FROM pg_ts_config;').to_a
LANG_TO_PG_LANGUAGE = {
  'ar' => 'arabic',
  # '' => 'armenian',
  # '' => 'basque',
  # '' => 'catalan',
  # '' => 'danish',
  # '' => 'dutch',
  'en' => 'english',
  # '' => 'estonian',
  # '' => 'finnish',
  'fr' => 'french',
  'de' => 'german',
  'el' => 'greek',
  'grc' => 'greek',
  'hi' => 'hindi',
  # '' => 'hungarian',
  # '' => 'indonesian',
  # '' => 'irish',
  'it' => 'italian',
  # '' => 'lithuanian',
  # '' => 'nepali',
  # '' => 'norwegian',
  # '' => 'portuguese',
  # '' => 'romanian',
  'ru' => 'russian',
  'sr' => 'serbian',
  'es' => 'spanish',
  # '' => 'swedish',
  # '' => 'tamil',
  'tr' => 'turkish',
  # '' => 'yiddish',
}; LANG_TO_PG_LANGUAGE.default = 'simple'

# Эти языки не имеют локали для UI. На них может быть только контент (статьи).
LANGS_CONTENT_ONLY = {
  'frm' => true, # Средневековый французский (ISO 639-3, French, Medieval ~1400–1600)
  'fro' => true, # Старофранцузский (до XIV века) (ISO 639-3)
  'cop' => true, # Коптский (ISO 639-2/3)
  'cu'  => true, # Церковнославянский (ISO 639-1/2, код означает "Old Church Slavonic")
  'xcl' => true, # Древнеармянский (грабар)
}

# Когда нет перевода для какой-то локали, то падаем на соответствующую локаль
LANG_FALLBACKS = {
  :ar => :en,
  :hy => :ru,
  :'zh-Hans' => :en,
  :'zh-Hant' => :en,
  :de => :en,
  :en => :ru,
  :el => :en,
  :he => :en,
  :ja => :en,

  :es => :en,
  :fr => :en,
  :hi => :en,
  :fa => :en,
  :it => :en,
  :sw => :en,
  :ko => :en,
  :sr => :ru,
  :tk => :ru,
  :tr => :en,
  :uz => :ru,
  :vi => :en,

  # для этих древних языков всегда нет локали, поэтому всегда будем падать на другую локаль:
  :la  => :en,
  :grc => :el,
  :frm => :fr,
  :fro => :fr,
  :cop => :en,
  :cu  => :ru,
  :xcl => :hy,
}

FLAG_BY_LANG = {
  'ar' => '🇸🇦', # Арабский (ОАЭ)
  'hy' => '🇦🇲', # Армянский
  'de' => '🇩🇪', # Немецкий
  'en' => '🇺🇸', # Английский (Великобритания)
  'es' => '🇪🇸', # Испанский
  'el' => '🇬🇷', # Греческий
  'fa' => '🇮🇷', # Персидский
  'fr' => '🇫🇷', # Французский
  'he' => '🇮🇱', # Иврит
  'hi' => '🇮🇳', # Хинди
  'it' => '🇮🇹', # Итальянский
  'ja' => '🇯🇵', # Японский
  'ko' => '🇰🇷', # Корейский
  'ru' => '🇷🇺', # Русский
  'sr' => '🇷🇸', # Сербский
  'sw' => '🇰🇪', # Суахили
  'tr' => '🇹🇷', # Турецкий
  'tk' => '🇹🇲', # Туркменский
  'uz' => '🇺🇿', # Узбекский
  'vi' => '🇻🇳', # Вьетнамский
  'zh-Hans' => '🇨🇳', # Китайский
  'zh-Hant' => '🇨🇳', # Китайский
  # ---
  'cu' =>  '🇷🇺📜', # Церковнославянский
  'grc' => '🇬🇷📜', # Древнегреческий
  'la' =>  '🇻🇦📜', # Латынь
  'frm' => '🇫🇷📜', # Средневековый французский (Medieval ~1400–1600)
  'fro' => '🇫🇷📜', # Старофранцузский (до XIV века)
  'cop' => '🇪🇬📜', # Коптский
  'xcl' => '🇦🇲📜', # Древнеармянский (грабар)
  # ---
  # переводы Библии
  'arab-avd' => '🇸🇦',   # Китайский
  'cn-ccbs' => '🇨🇳',    # Китайский
  'csl-pnm' => '🇷🇺📜',    # Церковнославянский
  'csl-ru' => '🇷🇺📜',     # Церковнославянский
  'ge-sch' => '🇩🇪',     # Немецкий
  'gr-lxx-byz' => '🇬🇷📜', # Греческий (древний)
  'heb-osm' => '🇮🇱📜',    # Иврит (библейский)
  'jp-ni' => '🇯🇵',      # Японский
  'eng-nkjv' => '🇺🇸',   # Английский (подстрочник)
  'en-nrsv' => '🇺🇸' ,   # Английский (подстрочник)
  'gr-en' => '🇺🇸',      # Английский (подстрочник)
  'gr-jp' => '🇯🇵',      # Японский (подстрочник)
  'gr-ru' => '🇷🇺',      # Русский (подстрочник)
}

# Какую локаль включать для языков Библии
BIB_LANG_TO_LOCALE = {
  'ru'         => 'ru',
  'en-nrsv'    => 'en',
  'eng-nkjv'   => 'en',
  'csl-ru'     => 'ru',
  'csl-pnm'    => 'ru',
  'heb-osm'    => 'he',
  'gr-lxx-byz' => 'el',

  'gr-ru'      => 'ru',
  'gr-en'      => 'en',
  'gr-jp'      => 'ja',

  'jp-ni'      => 'ja',
  'cn-ccbs'    => 'zh-Hans',
  'ge-sch'     => 'de',
  'arab-avd'   => 'ar',
}

# Код языка, которому соответствует перевод Библии (для SEO)
LANG_FOR_BIB_LANG = {
  'ru'         => 'ru',
  # этот язык поисковикам не показываем
  # 'en-nrsv'    => nil,
  'eng-nkjv'   => 'en',
  'csl-ru'     => 'cu',
  # этот язык поисковикам не показываем
  # 'csl-pnm'    => nil,
  'heb-osm'    => 'he',
  'gr-lxx-byz' => 'grc',

  'jp-ni'      => 'ja',
  'cn-ccbs'    => 'zh-Hans',
  'ge-sch'     => 'de',
  'arab-avd'   => 'ar',
}

# Какой язык Библии включать для локали
LOCALE_TO_BIB_LANG = {
  ''   => 'ru',
  nil  => 'ru',
  'ru' => 'ru',
  'en' => 'eng-nkjv',
  'he' => 'heb-osm',
  'el' => 'gr-lxx-byz',
  'grc' => 'gr-lxx-byz',
  'ja' => 'jp-ni',
  'zh-Hans' => 'cn-ccbs',
  'zh-Hant' => 'cn-ccbs',
  'de' => 'ge-sch',
  'ar' => 'arab-avd',

  'la' => 'eng-nkjv',
  'es' => 'eng-nkjv',
  'fr' => 'eng-nkjv',
  'hi' => 'eng-nkjv',
  'fa' => 'eng-nkjv',
  'it' => 'eng-nkjv',
  'sw' => 'eng-nkjv',
  'ko' => 'eng-nkjv',
  'sr' => 'ru',
  'tk' => 'ru',
  'tr' => 'eng-nkjv',
  'uz' => 'ru',
  'vi' => 'eng-nkjv',
}

# Поисковик не должен индексировать эти переводы Библии
BIB_LANGS_NOT_INDEXED = {
  'csl-pnm' => true,
  'en-nrsv' => true,
}

# для routes.rb (редиректы со старого на новое)
# -----------------------
# Создаем хэш соответствия кодов стран кодам языков
COUNTRY_TO_LANG = {
  'cn' => 'zh-Hans',  # Китайский
  'eg' => 'ar',  # Египет (арабский)
  'gr' => 'el',  # Греческий
  'il' => 'he',  # Иврит
  'in' => 'hi',  # Хинди
  'ir' => 'fa',  # Персидский
  'jp' => 'ja',  # Японский
  'ke' => 'sw',  # Суахили
  'kr' => 'ko',  # Корейский
  'rs' => 'sr',  # Сербский
  'tm' => 'tk',  # Туркменский
  'vn' => 'vi',  # Вьетнамский
  'cp' => 'cop'  # Коптский
}

# доступные локали - позиции для 1-го path: /*/
R_LOCALES = ::ALL_LOCALES.keys.join('|')
# доступные языки контекста статей - позиции для 2-го path: /.../*
R_CONT_LANGS = (::ALL_LOCALES.keys + ::LANGS_CONTENT_ONLY.keys).join('|')
# доступные переводы Библии - позиции для 2-го path: /.../*
R_BIB_LANGS = ::BIB_LANG_TO_LOCALE.keys.join('|')
# -------------------------

# Универсальные названия для языков статей
# (локализованные версии смотри в I18n-файлах) (древние языки без локали, остаются nil)
PAGE_LANGS = {
  "ar" => 'العربية',
  "hy" => 'Հայերեն',
  "zh-Hans" => '简体中文',
  "zh-Hant" => '繁體中文',
  "de" => 'Deutsch',
  "en" => 'English',
  "es" => 'Español',
  "fr" => 'Français',
  "frm" => nil,
  "fro" => nil,
  "el" => 'Ελληνικά',
  "grc" => nil,
  "cop" => nil,
  "la" => nil,
  "he" => 'עברית',
  "hi" => 'हिन्दी',
  "fa" => 'فارسی',
  "it" => 'Italiano',
  "ja" => '日本語',
  "sw" => 'Kiswahili',
  "ko" => '한국어',
  "sr" => 'Српски',
  "ru" => 'Русский',
  "cu" => nil,
  "tk" => 'Türkmen dili',
  "tr" => 'Türkçe',
  "uz" => 'Oʻzbekcha',
  "vi" => 'Tiếng Việt',
  "xcl" => nil,
  # ---
}

TRANSLATE_LANGS = {
  "ar" => {name: 'العربية', flag: '🇸🇦'}, # Арабский
  "bg" => {name: 'Български', flag: '🇧🇬'}, # Болгарский
  "cs" => {name: 'Čeština', flag: '🇨🇿'}, # Чешский
  "de" => {name: 'Deutsch', flag: '🇩🇪'}, # Немецкий
  "el" => {name: 'Ελληνικά', flag: '🇬🇷'}, # Греческий
  "en" => {name: 'English', flag: '🇬🇧'}, # Английский
  "es" => {name: 'Español', flag: '🇪🇸'}, # Испанский
  "et" => {name: 'Eesti', flag: '🇪🇪'}, # Эстонский
  "fa" => {name: 'فارسی', flag: '🇮🇷'}, # Персидский
  "fi" => {name: 'Suomi', flag: '🇫🇮'}, # Финский
  "fr" => {name: 'Français', flag: '🇫🇷'}, # Французский
  "he" => {name: 'עברית', flag: '🇮🇱'}, # Иврит
  "hi" => {name: 'हिन्दी', flag: '🇮🇳'}, # Хинди
  "hu" => {name: 'Magyar', flag: '🇭🇺'}, # Венгерский
  "hy" => {name: 'Հայերեն', flag: '🇦🇲'}, # Армянский
  "id" => {name: 'Bahasa Indonesia', flag: '🇮🇩'}, # Индонезийский
  "it" => {name: 'Italiano', flag: '🇮🇹'}, # Итальянский
  "ja" => {name: '日本語', flag: '🇯🇵'}, # Японский
  "ka" => {name: 'ქართული', flag: '🇬🇪'}, # Грузинский
  "kk" => {name: 'Қазақша', flag: '🇰🇿'}, # Казахский
  "km" => {name: 'ភាសាខ្មែរ', flag: '🇰🇭'}, # Кхмерский
  "ko" => {name: '한국어', flag: '🇰🇷'}, # Корейский
  "lt" => {name: 'Lietuvių', flag: '🇱🇹'}, # Литовский
  "lv" => {name: 'Latviešu', flag: '🇱🇻'}, # Латышский
  "mk" => {name: 'Македонски', flag: '🇲🇰'}, # Македонский
  "ml" => {name: 'മലയാളം', flag: '🇮🇳'}, # Малаялам
  "ms" => {name: 'Bahasa Melayu', flag: '🇲🇾'}, # Малайский
  "nl" => {name: 'Nederlands', flag: '🇳🇱'}, # Нидерландский
  "pl" => {name: 'Polski', flag: '🇵🇱'}, # Польский
  "pt" => {name: 'Português', flag: '🇵🇹'}, # Португальский
  "ro" => {name: 'Română', flag: '🇷🇴'}, # Румынский
  "ru" => {name: 'Русский', flag: '🇷🇺'}, # Русский
  "sk" => {name: 'Slovenčina', flag: '🇸🇰'}, # Словацкий
  "sq" => {name: 'Shqip', flag: '🇦🇱'}, # Албанский
  "sr" => {name: 'Српски', flag: '🇷🇸'}, # Сербский
  "sv" => {name: 'Svenska', flag: '🇸🇪'}, # Шведский
  "sw" => {name: 'Kiswahili', flag: '🇹🇿'}, # Суахили
  "ta" => {name: 'தமிழ்', flag: '🇮🇳'}, # Тамильский
  "th" => {name: 'ไทย', flag: '🇹🇭'}, # Тайский
  "tk" => {name: 'Türkmençe', flag: '🇹🇲'}, # Туркменский
  "tr" => {name: 'Türkçe', flag: '🇹🇷'}, # Турецкий
  "ur" => {name: 'اردو', flag: '🇵🇰'}, # Урду
  "uz" => {name: 'Oʻzbekcha', flag: '🇺🇿'}, # Узбекский
  "vi" => {name: 'Tiếng Việt', flag: '🇻🇳'}, # Вьетнамский
  "zh-Hans" => {name: '简体中文', flag: '🇨🇳'}, # Китайский упрощенный
  "zh-Hant" => {name: '繁體中文', flag: '🇹🇼'}, # Китайский традиционный
  # --- old ---
  'cu' =>  {name: nil, flag: '🇷🇺📜', is_encient: true}, # Церковнославянский
  'grc' => {name: nil, flag: '🇬🇷📜', is_encient: true}, # Древнегреческий
  'la' =>  {name: nil, flag: '🇻🇦📜', is_encient: true}, # Латынь
  'cop' => {name: nil, flag: '🇪🇬📜', is_encient: true}, # Коптский
  'xcl' => {name: nil, flag: '🇦🇲📜', is_encient: true}, # Древнеармсянский (грабар)
}

# Универсальные названия языков для переводов Библии
# (локализованные версии смотри в I18n-файлах)
BIB_LANGS = {
  # --- Переводы
  "arab-avd" => 'العربية',
  "cn-ccbs" => '简体中文',
  "csl-pnm" => 'Церковнославянский',
  "csl-ru" => 'Церковнославянский',
  "el" => 'Νέα Ελληνική',
  "eng-nkjv" => 'English',
  "en-nrsv" => 'English',
  "es" => 'Español',
  "fa" => 'فارسی',
  "ge-sch" => 'Deutsch',
  "hi" => 'हिन्दी',
  "jp-ni" => '日本語',
  "ko" => '한국어',
  "ru" => 'Русский',
  "sr" => 'Српски',
  "tk" => 'Türkmen dili',
  "uz" => 'Oʻzbekcha',
  "vi" => 'Tiếng Việt',
  # --- Древние тексты
  "gr-lxx-byz" => 'Αρχαία Ελληνική',
  "heb-osm" => 'עברית',
  "syc" => 'Пешита',
  "cop" => 'Коптский',
  # --- Подстрочники
  "gr-en" => 'English (interlinear)',
  "gr-jp" => '日本語 (対訳)',
  "gr-ru" => 'Русский (подстрочник)',
}


BOOKS = {
  'gen' => {id: 10, chapters: 50, name: 'Бытие', zavet: 1, is_kanon: true, desc: 'Пятикнижие Моисея'},
  'ish' => {id: 20, chapters: 40, name: 'Исход', zavet: 1, is_kanon: true, desc: 'Пятикнижие Моисея'},
  'lev' => {id: 30, chapters: 27, name: 'Левит', zavet: 1, is_kanon: true, desc: 'Пятикнижие Моисея'},
  'chis' => {id: 40, chapters: 36, name: 'Числа', zavet: 1, is_kanon: true, desc: 'Пятикнижие Моисея'},
  'vtor' => {id: 50, chapters: 34, name: 'Второзаконие', zavet: 1, is_kanon: true, desc: 'Пятикнижие Моисея'},
  'nav' => {id: 60, chapters: 24, name: 'Иисус Навин', zavet: 1, is_kanon: true, desc: 'Книги исторические'},
  'sud' => {id: 70, chapters: 21, name: 'Судьи', zavet: 1, is_kanon: true, desc: 'Книги исторические'},
  'ruf' => {id: 80, chapters: 4, name: 'Руфь', zavet: 1, is_kanon: true, desc: 'Книги исторические'},
  '1ts' => {id: 90, chapters: 31, name: '1-я Царств', zavet: 1, is_kanon: true, desc: 'Книги исторические'},
  '2ts' => {id: 100, chapters: 24, name: '2-я Царств', zavet: 1, is_kanon: true, desc: 'Книги исторические'},
  '3ts' => {id: 110, chapters: 22, name: '3-я Царств', zavet: 1, is_kanon: true, desc: 'Книги исторические'},
  '4ts' => {id: 120, chapters: 25, name: '4-я Царств', zavet: 1, is_kanon: true, desc: 'Книги исторические'},
  '1par' => {id: 130, chapters: 29, name: '1-я Паралипоменон', zavet: 1, is_kanon: true, desc: 'Книги исторические'},
  '2par' => {id: 140, chapters: 36, name: '2-я Паралипоменон', zavet: 1, is_kanon: true, desc: 'Книги исторические'},
  'ezd' => {id: 150, chapters: 10, name: 'Ездра', zavet: 1, is_kanon: true, desc: 'Книги исторические'},
  'neem' => {id: 160, chapters: 13, name: 'Неемия', zavet: 1, is_kanon: true, desc: 'Книги исторические'},
  '2ezd' => {id: 165, chapters: 9, name: '2-я Ездры', zavet: 1, is_kanon: false, desc: 'Книги исторические'},
  'tov' => {id: 170, chapters: 14, name: 'Товит', zavet: 1, is_kanon: false, desc: 'Книги исторические'},
  'iudf' => {id: 180, chapters: 16, name: 'Иудифь', zavet: 1, is_kanon: false, desc: 'Книги исторические'},
  'esf' => {id: 190, chapters: 10, name: 'Есфирь', zavet: 1, is_kanon: true, desc: 'Книги исторические'},
  'pr' => {id: 240, chapters: 31, name: 'Притчи', zavet: 1, is_kanon: true, desc: 'Книги учительные'},
  'ekl' => {id: 250, chapters: 12, name: 'Екклесиаст', zavet: 1, is_kanon: true, desc: 'Книги учительные'},
  'pp' => {id: 260, chapters: 8, name: 'Песня Песней', zavet: 1, is_kanon: true, desc: 'Книги учительные'},
  'prs' => {id: 270, chapters: 19, name: 'Премудрость Соломона', zavet: 1, is_kanon: false, desc: 'Книги учительные'},
  'prsir' => {id: 280, chapters: 51, name: 'Сирах', zavet: 1, is_kanon: false, desc: 'Книги учительные'},
  'iov' => {id: 220, chapters: 42, name: 'Иов', zavet: 1, is_kanon: true, desc: 'Книги учительные'},
  'is' => {id: 290, chapters: 66, name: 'Исаия', zavet: 1, is_kanon: true, desc: 'Книги пророческие'},
  'ier' => {id: 300, chapters: 52, name: 'Иеремия', zavet: 1, is_kanon: true, desc: 'Книги пророческие'},
  'pier' => {id: 310, chapters: 5, name: 'Плач Иеремии', zavet: 1, is_kanon: true, desc: 'Книги пророческие'},
  'pos' => {id: 315, chapters: 1, name: 'Послание Иеремии', zavet: 1, is_kanon: false, desc: 'Книги пророческие'},
  'var' => {id: 320, chapters: 5, name: 'Варух', zavet: 1, is_kanon: false, desc: 'Книги пророческие'},
  'iez' => {id: 330, chapters: 48, name: 'Иезекииль', zavet: 1, is_kanon: true, desc: 'Книги пророческие'},
  'dan' => {id: 340, chapters: 14, name: 'Даниил', zavet: 1, is_kanon: true, desc: 'Книги пророческие'},
  'os' => {id: 350, chapters: 14, name: 'Осия', zavet: 1, is_kanon: true, desc: 'Книги пророческие'},
  'iol' => {id: 360, chapters: 3, name: 'Иоиль', zavet: 1, is_kanon: true, desc: 'Книги пророческие'},
  'am' => {id: 370, chapters: 9, name: 'Амос', zavet: 1, is_kanon: true, desc: 'Книги пророческие'},
  'av' => {id: 380, chapters: 1, name: 'Авдий', zavet: 1, is_kanon: true, desc: 'Книги пророческие'},
  'ion' => {id: 390, chapters: 4, name: 'Иона', zavet: 1, is_kanon: true, desc: 'Книги пророческие'},
  'mih' => {id: 400, chapters: 7, name: 'Михей', zavet: 1, is_kanon: true, desc: 'Книги пророческие'},
  'naum' => {id: 410, chapters: 3, name: 'Наум', zavet: 1, is_kanon: true, desc: 'Книги пророческие'},
  'avm' => {id: 420, chapters: 3, name: 'Аввакум', zavet: 1, is_kanon: true, desc: 'Книги пророческие'},
  'sof' => {id: 430, chapters: 3, name: 'Софония', zavet: 1, is_kanon: true, desc: 'Книги пророческие'},
  'ag' => {id: 440, chapters: 2, name: 'Аггей', zavet: 1, is_kanon: true, desc: 'Книги пророческие'},
  'zah' => {id: 450, chapters: 14, name: 'Захария', zavet: 1, is_kanon: true, desc: 'Книги пророческие'},
  'mal' => {id: 460, chapters: 4, name: 'Малахия', zavet: 1, is_kanon: true, desc: 'Книги пророческие'},
  '1mak' => {id: 462, chapters: 16, name: '1-я Маккавейская', zavet: 1, is_kanon: false, desc: 'Книги исторические'},
  '2mak' => {id: 464, chapters: 15, name: '2-я Маккавейская', zavet: 1, is_kanon: false, desc: 'Книги исторические'},
  '3mak' => {id: 466, chapters: 7, name: '3-я Маккавейская', zavet: 1, is_kanon: false, desc: 'Книги исторические'},
  '3ezd' => {id: 468, chapters: 16, name: '3-я Ездры', zavet: 1, is_kanon: false, desc: 'Книги пророческие'},
  'ps' => {id: 230, chapters: 151, name: 'Псалтирь', zavet: 1, is_kanon: true, desc: 'Книги учительные'},

  'mf' => {id: 470, chapters: 28, name: 'Евангелие от Матфея', zavet: 2, is_kanon: true, desc: 'Евангелие'},
  'mk' => {id: 480, chapters: 16, name: 'От Марка', zavet: 2, is_kanon: true, desc: 'Евангелие'},
  'lk' => {id: 490, chapters: 24, name: 'От Луки', zavet: 2, is_kanon: true, desc: 'Евангелие'},
  'in' => {id: 500, chapters: 21, name: 'От Иоанна', zavet: 2, is_kanon: true, desc: 'Евангелие'},
  'act' => {id: 510, chapters: 28, name: 'Деяния апостолов', zavet: 2, is_kanon: true, desc: 'Деяния святых апостолов'},
  'iak' => {id: 660, chapters: 5, name: 'Послание Иакова', zavet: 2, is_kanon: true, desc: 'Соборные послания'},
  '1pet' => {id: 670, chapters: 5, name: '1-е Петра', zavet: 2, is_kanon: true, desc: 'Соборные послания'},
  '2pet' => {id: 680, chapters: 3, name: '2-е Петра', zavet: 2, is_kanon: true, desc: 'Соборные послания'},
  '1in' => {id: 690, chapters: 5, name: '1-е Иоанна', zavet: 2, is_kanon: true, desc: 'Соборные послания'},
  '2in' => {id: 700, chapters: 1, name: '2-е Иоанна', zavet: 2, is_kanon: true, desc: 'Соборные послания'},
  '3in' => {id: 710, chapters: 1, name: '3-е Иоанна', zavet: 2, is_kanon: true, desc: 'Соборные послания'},
  'iud' => {id: 720, chapters: 1, name: 'Иуды', zavet: 2, is_kanon: true, desc: 'Соборные послания'},
  'rim' => {id: 520, chapters: 16, name: 'К Римлянам', zavet: 2, is_kanon: true, desc: 'Послания апостола Павла'},
  '1kor' => {id: 530, chapters: 16, name: '1-е Коринфянам', zavet: 2, is_kanon: true, desc: 'Послания апостола Павла'},
  '2kor' => {id: 540, chapters: 13, name: '2-е Коринфянам', zavet: 2, is_kanon: true, desc: 'Послания апостола Павла'},
  'gal' => {id: 550, chapters: 6, name: 'К Галатам', zavet: 2, is_kanon: true, desc: 'Послания апостола Павла'},
  'ef' => {id: 560, chapters: 6, name: 'К Ефесянам', zavet: 2, is_kanon: true, desc: 'Послания апостола Павла'},
  'fil' => {id: 570, chapters: 4, name: 'К Филиппийцам', zavet: 2, is_kanon: true, desc: 'Послания апостола Павла'},
  'kol' => {id: 580, chapters: 4, name: 'К Колосянам', zavet: 2, is_kanon: true, desc: 'Послания апостола Павла'},
  '1sol' => {id: 590, chapters: 5, name: '1-е Солунянам', zavet: 2, is_kanon: true, desc: 'Послания апостола Павла'},
  '2sol' => {id: 600, chapters: 3, name: '2-е Солунянам', zavet: 2, is_kanon: true, desc: 'Послания апостола Павла'},
  '1tim' => {id: 610, chapters: 6, name: '1-е Тимофею', zavet: 2, is_kanon: true, desc: 'Послания апостола Павла'},
  '2tim' => {id: 620, chapters: 4, name: '2-е Тимофею', zavet: 2, is_kanon: true, desc: 'Послания апостола Павла'},
  'tit' => {id: 630, chapters: 3, name: 'К Титу', zavet: 2, is_kanon: true, desc: 'Послания апостола Павла'},
  'fm' => {id: 640, chapters: 1, name: 'К Филимону', zavet: 2, is_kanon: true, desc: 'Послания апостола Павла'},
  'evr' => {id: 650, chapters: 13, name: 'К Евреям', zavet: 2, is_kanon: true, desc: 'Послания апостола Павла'},
  'otkr' => {id: 730, chapters: 22, name: 'Откровение', zavet: 2, is_kanon: true, desc: 'Книга пророческая'},
}

# ZAVET_VETH = BOOKS.select{ |book,params| params[:zavet] == 1 }.keys
# ZAVET_NOV = BOOKS.select{ |book,params| params[:zavet] == 2 }.keys

BOOK_TO_CODE = {
  'бт' => 'gen',
  'быт' => 'gen',
  'бытие' => 'gen',
  'gen' => 'gen',
  'genesis' => 'gen',

  'ид' => 'ish',
  'исх' => 'ish',
  'исход' => 'ish',
  'ex' => 'ish',
  'exodus' => 'ish',

  'лв' => 'lev',
  'лев' => 'lev',
  'левит' => 'lev',
  'lev' => 'lev',
  'leviticus' => 'lev',

  'чс' => 'chis',
  'чис' => 'chis',
  'числ' => 'chis',
  'числа' => 'chis',
  'num' => 'chis',
  'numbers' => 'chis',

  'вт' => 'vtor',
  'втор' => 'vtor',
  'deut' => 'vtor',
  'deuteronomy' => 'vtor',

  'нв' => 'nav',
  'нав' => 'nav',
  'иснав' => 'nav',
  'навина' => 'nav',
  'nav' => 'nav',
  'joshua' => 'nav',

  'сд' => 'sud',
  'суд' => 'sud',
  'судьи' => 'sud',
  'judg' => 'sud',
  'judges' => 'sud',

  'рф' => 'ruf',
  'руф' => 'ruf',
  'руфь' => 'ruf',
  'rth' => 'ruf',
  'ruth' => 'ruf',

  '1ц' => '1ts',
  '1цар' => '1ts',
  'iцар' => '1ts',
  '1-яцар' => '1ts',
  'iсам' => '1ts',
  '1царств' => '1ts',
  '1sam' => '1ts',
  'isam' => '1ts',
  '1samuel' => '1ts',
  'isamuel' => '1ts',

  '2ц' => '2ts',
  '2цар' => '2ts',
  'iiцар' => '2ts',
  '2-яцар' => '2ts',
  'iiсам' => '2ts',
  '2царств' => '2ts',
  '2самуила' => '2ts',
  '2sam' => '2ts',
  'iisam' => '2ts',
  '2samuel' => '2ts',
  'iisamuel' => '2ts',

  '3ц' => '3ts',
  '3цар' => '3ts',
  'iiiцар' => '3ts',
  '3-яцар' => '3ts',
  '3царств' => '3ts',
  '1king' => '3ts',
  'iking' => '3ts',
  '1kings' => '3ts',
  'ikings' => '3ts',

  '4ц' => '4ts',
  '4цар' => '4ts',
  '4-яцар' => '4ts',
  'ivцар' => '4ts',
  '4царств' => '4ts',
  '2king' => '4ts',
  'iiking' => '4ts',
  '2kings' => '4ts',
  'iikings' => '4ts',

  '1пар' => '1par',
  '1-япар' => '1par',
  '1паралипоменон' => '1par',
  '1chron' => '1par',
  'ichron' => '1par',
  '1chronicles' => '1par',
  'ichronicles' => '1par',

  '2пар' => '2par',
  '2-япар' => '2par',
  '2паралипоменон' => '2par',
  '2chron' => '2par',
  'iichron' => '2par',
  '2chronicles' => '2par',
  'iichronicles' => '2par',

  'ез' => 'ezd',
  'езд' => 'ezd',
  'ездр' => 'ezd',
  '1езд' => 'ezd',
  'ездра' => 'ezd',
  'ezr' => 'ezd',
  '1ezr' => 'ezd',
  'iezr' => 'ezd',
  '1esdras' => 'ezd',
  'iesdras' => 'ezd',

  'нм' => 'neem',
  'неем' => 'neem',
  'неемия' => 'neem',
  'nehem' => 'neem',
  'nehemiah' => 'neem',

  'ес' => 'esf',
  'есф' => 'esf',
  'эсф' => 'esf',
  'есфирь' => 'esf',
  'est' => 'esf',
  'esther' => 'esf',

  'ив' => 'iov',
  'иов' => 'iov',
  'job' => 'iov',

  'пс' => 'ps',
  'псал' => 'ps',
  'псалмы' => 'ps',
  'псалтирь' => 'ps',
  'псалом' => 'ps',
  'ps' => 'ps',
  'psalms' => 'ps',

  'пр' => 'pr',
  'прит' => 'pr',
  'притч' => 'pr',
  'притчи' => 'pr',
  'prov' => 'pr',
  'proverbs' => 'pr',

  'ек' => 'ekl',
  'еккл' => 'ekl',
  'екклезиаст' => 'ekl',
  'eccl' => 'ekl',
  'ecclesiastes' => 'ekl',

  'пн' => 'pp',
  'песн' => 'pp',
  'песн.п' => 'pp',
  'песнь' => 'pp',
  'song' => 'pp',
  'songofsolomon' => 'pp',

  'ис' => 'is',
  'исаи' => 'is',
  'исаия' => 'is',
  'is' => 'is',
  'isaiah' => 'is',

  'ир' => 'ier',
  'иер' => 'ier',
  'иеремия' => 'ier',
  'jer' => 'ier',
  'jeremiah' => 'ier',

  'пл' => 'pier',
  'плач' => 'pier',
  'lam' => 'pier',
  'lamentations' => 'pier',

  'из' => 'iez',
  'иез' => 'iez',
  'иезекииль' => 'iez',
  'ezek' => 'iez',
  'ezekiel' => 'iez',

  'дн' => 'dan',
  'дан' => 'dan',
  'даниил' => 'dan',
  'dan' => 'dan',
  'daniel' => 'dan',

  'ос' => 'os',
  'осия' => 'os',
  'hos' => 'os',
  'hosea' => 'os',

  'ил' => 'iol',
  'иоил' => 'iol',
  'joel' => 'iol',

  'ам' => 'am',
  'амос' => 'am',
  'am' => 'am',
  'amos' => 'am',

  'аи' => 'av',
  'авд' => 'av',
  'авдий' => 'av',
  'avd' => 'av',
  'obadiah' => 'av',

  'ио' => 'ion',
  'ион' => 'ion',
  'иона' => 'ion',
  'jona' => 'ion',
  'jonah' => 'ion',

  'мх' => 'mih',
  'мих' => 'mih',
  'михей' => 'mih',
  'mic' => 'mih',
  'micah' => 'mih',

  'на' => 'naum',
  'наум' => 'naum',
  'naum' => 'naum',
  'nahum' => 'naum',

  'ав' => 'avm',
  'авв' => 'avm',
  'аввакум' => 'avm',
  'habak' => 'avm',
  'habakkuk' => 'avm',

  'сф' => 'sof',
  'соф' => 'sof',
  'софония' => 'sof',
  'sofon' => 'sof',
  'zephaniah' => 'sof',

  'аг' => 'ag',
  'агг' => 'ag',
  'аггей' => 'ag',
  'hag' => 'ag',
  'haggai' => 'ag',

  'зр' => 'zah',
  'зах' => 'zah',
  'захария' => 'zah',
  'zah' => 'zah',
  'zachariah' => 'zah',

  'мл' => 'mal',
  'мал' => 'mal',
  'малахия' => 'mal',
  'mal' => 'mal',
  'malachi' => 'mal',

  '1м' => '1mak',
  '1мак' => '1mak',
  '1макк' => '1mak',
  '1-ямак' => '1mak',
  '1маккавей' => '1mak',
  '1маккавейская' => '1mak',
  '1mac' => '1mak',
  'imac' => '1mak',
  '1maccabees' => '1mak',
  'imaccabees' => '1mak',

  '2м' => '2mak',
  '2мак' => '2mak',
  '2макк' => '2mak',
  '2-ямак' => '2mak',
  '2маккавей' => '2mak',
  '2маккавейская' => '2mak',
  '2mac' => '2mak',
  'iimac' => '2mak',
  '2maccabees' => '2mak',
  'iimaccabees' => '2mak',

  '3м' => '3mak',
  '3мак' => '3mak',
  '3макк' => '3mak',
  '3-ямак' => '3mak',
  '3маккавей' => '3mak',
  '3маккавейская' => '3mak',
  '3mac' => '3mak',
  'iiimac' => '3mak',
  '3maccabees' => '3mak',
  'iiimaccabees' => '3mak',

  'вх' => 'var',
  'вар' => 'var',
  'варух' => 'var',
  'bar' => 'var',
  'baruch' => 'var',

  '2е' => '2ezd',
  '2езд' => '2ezd',
  '2ездр' => '2ezd',
  '2-яезд' => '2ezd',
  '2ездра' => '2ezd',
  '2ezr' => '2ezd',
  'iiezr' => '2ezd',
  '2esdras' => '2ezd',
  'iiesdras' => '2ezd',

  '3е' => '3ezd',
  '3езд' => '3ezd',
  '3ездр' => '3ezd',
  '3-яезд' => '3ezd',
  '3ездра' => '3ezd',
  '3ezr' => '3ezd',
  'iiiezr' => '3ezd',
  '3esdras' => '3ezd',
  'iiiesdras' => '3ezd',

  'иф' => 'iudf',
  'иудифь' => 'iudf',
  'judf' => 'iudf',
  'judith' => 'iudf',

  'по' => 'pos',
  'послиер' => 'pos',
  'посл.иер' => 'pos',
  'иеремии' => 'pos',
  'ljer' => 'pos',
  'letterofjeremiah' => 'pos',

  'пм' => 'prs',
  'прем' => 'prs',
  'прем.сол' => 'prs',
  'премудрости' => 'prs',
  'solom' => 'prs',
  'wisdom' => 'prs',

  'сх' => 'prsir',
  'сирах' => 'prsir',
  'сир' => 'prsir',
  'сирахов' => 'prsir',
  'sir' => 'prsir',
  'sirah' => 'prsir',

  'то' => 'tov',
  'тов' => 'tov',
  'товит' => 'tov',
  'tov' => 'tov',
  'tobit' => 'tov',

  'мф' => 'mf',
  'мат' => 'mf',
  'матф' => 'mf',
  'матфей' => 'mf',
  'mt' => 'mf',
  'matthew' => 'mf',

  'мк' => 'mk',
  'мр' => 'mk',
  'марк' => 'mk',
  'mk' => 'mk',
  'mark' => 'mk',

  'лк' => 'lk',
  'лук' => 'lk',
  'лука' => 'lk',
  'lk' => 'lk',
  'luke' => 'lk',

  'ин' => 'in',
  'иоан' => 'in',
  'иоанн' => 'in',
  'jn' => 'in',
  'john' => 'in',

  'де' => 'act',
  'деян' => 'act',
  'деяния' => 'act',
  'act' => 'act',
  'acts' => 'act',

  'ик' => 'iak',
  'иак' => 'iak',
  'иакова' => 'iak',
  'jas' => 'iak',
  'james' => 'iak',

  '1п' => '1pet',
  '1пет' => '1pet',
  '1петр' => '1pet',
  '1-епет' => '1pet',
  '1петра' => '1pet',
  '1pet' => '1pet',
  '1peter' => '1pet',

  '2п' => '2pet',
  '2пет' => '2pet',
  '2петр' => '2pet',
  '2-епет' => '2pet',
  '2петра' => '2pet',
  '2pet' => '2pet',
  '2peter' => '2pet',

  '1и' => '1in',
  '1ин' => '1in',
  '1иоан' => '1in',
  '1-еиоан' => '1in',
  '1иоанна' => '1in',
  '1jn' => '1in',
  '1john' => '1in',

  '2и' => '2in',
  '2ин' => '2in',
  '2иоан' => '2in',
  '2-еиоан' => '2in',
  '2иоанна' => '2in',
  '2jn' => '2in',
  '2john' => '2in',

  '3и' => '3in',
  '3ин' => '3in',
  '3иоан' => '3in',
  '3-еиоан' => '3in',
  '3иоанна' => '3in',
  '3jn' => '3in',
  '3john' => '3in',

  'иу' => 'iud',
  'иуд' => 'iud',
  'иуды' => 'iud',
  'juda' => 'iud',
  'jude' => 'iud',

  'рм' => 'rim',
  'рим' => 'rim',
  'римлянам' => 'rim',
  'rom' => 'rim',
  'romans' => 'rim',

  '1к' => '1kor',
  '1кор' => '1kor',
  '1-екор' => '1kor',
  '1коринфянам' => '1kor',
  '1cor' => '1kor',
  '1corinthians' => '1kor',

  '2к' => '2kor',
  '2кор' => '2kor',
  '2-екор' => '2kor',
  '2коринфянам' => '2kor',
  '2cor' => '2kor',
  '2corinthians' => '2kor',

  'гл' => 'gal',
  'гал' => 'gal',
  'галатам' => 'gal',
  'gal' => 'gal',
  'galatians' => 'gal',

  'еф' => 'ef',
  'ефес' => 'ef',
  'ефесянам' => 'ef',
  'eph' => 'ef',
  'ephesians' => 'ef',

  'фл' => 'fil',
  'фил' => 'fil',
  'флп' => 'fil',
  'филип' => 'fil',
  'филиппийцам' => 'fil',
  'phil' => 'fil',
  'philippians' => 'fil',

  'кл' => 'kol',
  'кол' => 'kol',
  'колоссянам' => 'kol',
  'col' => 'kol',
  'сolossians' => 'kol',

  '1ф' => '1sol',
  '1фес' => '1sol',
  '1-ефес' => '1sol',
  '1сол' => '1sol',
  '1солунянам' => '1sol',
  '1фессалоникийцам' => '1sol',
  '1thes' => '1sol',
  '1thessalonians' => '1sol',

  '2ф' => '2sol',
  '2фес' => '2sol',
  '2-ефес' => '2sol',
  '2сол' => '2sol',
  '2солунянам' => '2sol',
  '2фессалоникийцам' => '2sol',
  '2thes' => '2sol',
  '2thessalonians' => '2sol',

  '1т' => '1tim',
  '1тим' => '1tim',
  '1-етим' => '1tim',
  '1тимофею' => '1tim',
  '1tim' => '1tim',
  '1timothy' => '1tim',

  '2т' => '2tim',
  '2тим' => '2tim',
  '2-етим' => '2tim',
  '2тимофею' => '2tim',
  '2tim' => '2tim',
  '2timothy' => '2tim',

  'ти' => 'tit',
  'тит' => 'tit',
  'титу' => 'tit',
  'tit' => 'tit',
  'titus' => 'tit',

  'фм' => 'fm',
  'флм' => 'fm',
  'филим' => 'fm',
  'филимону' => 'fm',
  'phlm' => 'fm',
  'philemon' => 'fm',

  'ер' => 'evr',
  'евр' => 'evr',
  'евреям' => 'evr',
  'hebr' => 'evr',
  'hebrews' => 'evr',

  'от' => 'otkr',
  'откр' => 'otkr',
  'апок' => 'otkr',
  'откровение' => 'otkr',
  'апокалипсис' => 'otkr',
  'rev' => 'otkr',
  'revelation' => 'otkr',
}

require 'i18n'
require "i18n/backend/fallbacks"
I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)

# ar: '🇦🇪 Арабский'
# cn: '🇨🇳 Китайский'
# de: '🇩🇪 Немецкий'
# cp: '🇪🇬 Коптский'
# en: '🇬🇧 Английский'
# es: '🇪🇸 Испанский'
# fr: '🇫🇷 Французский'
# gr: '🇬🇷 Греческий'
# il: '🇮🇱 Иврит'
# in: '🇮🇳 Хинди'
# ir: '🇮🇷 Персидский'
# it: '🇮🇹 Итальянский'
# jp: '🇯🇵 Японский'
# ke: '🇰🇪 Суахили'
# kr: '🇰🇷 Корейский'
# rs: '🇷🇸 Сербский'
# ru: '🇷🇺 Русский'
# tm: '🇹🇲 Туркменский'
# tr: '🇹🇷 Турецкий'
# uz: '🇺🇿 Узбекский'
# vn: '🇻🇳 Вьетнамский'

I18n.available_locales = %i(
  ar cn de en gr il jp ru
  es fr in ir it ke kr rs tm tr uz vn cp
) # cp - коптский нет смысла добавлять как язык интерфейса, но я добавил,
# чтобы на него можно было переключаться в случае коптских статей (внутри файла всё равно предложена английская локализация)

# I18n.default_locale = :ru
::I18n.fallbacks.map(
  :ar => :en,
  :cn => :en,
  :de => :en,
  :en => :ru,
  :gr => :en,
  :il => :en,
  :jp => :en,

  :es => :en,
  :fr => :en,
  :in => :en,
  :ir => :en,
  :it => :en,
  :ke => :en,
  :kr => :en,
  :rs => :ru,
  :tm => :ru,
  :tr => :en,
  :uz => :ru,
  :vn => :en,
  :cp => :en,
)

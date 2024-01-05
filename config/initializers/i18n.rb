require 'i18n'
require "i18n/backend/fallbacks"
I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)

I18n.available_locales = %i(
  ar cn de en gr il jp ru
)
# I18n.default_locale = :ru
::I18n.fallbacks.map(
  :ar => :en,
  :cn => :en,
  :de => :en,
  :en => :ru,
  :gr => :en,
  :il => :en,
  :jp => :en,
)

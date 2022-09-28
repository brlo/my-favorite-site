require 'i18n'
require "i18n/backend/fallbacks"
I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)

I18n.available_locales = [
  :ru, :en, :il, :gr, :cs
]
# I18n.default_locale = :ru
::I18n.fallbacks.map(
  :en => :ru, :cs => :ru, :il => :en, :gr => :en
)

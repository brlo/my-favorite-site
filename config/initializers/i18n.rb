require 'i18n'
require "i18n/backend/fallbacks"
I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)

I18n.available_locales = ::ALL_LOCALES.keys
# %i(
#   ar cn de en gr il jp ru
#   es fr in ir it ke kr rs tm tr uz vn cp
#)

# I18n.default_locale = :ru
::I18n.default_locale = :en
# ::I18n.fallbacks.map(::LANG_FALLBACKS) # не работает
::I18n.fallbacks = ::LANG_FALLBACKS

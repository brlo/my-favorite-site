require 'i18n'
require "i18n/backend/fallbacks"
I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)

I18n.available_locales = ::ALL_LOCALES.keys

# ::I18n.default_locale = :ru

# ::I18n.fallbacks.map(::LANG_FALLBACKS)

Rails.application.configure do
  # fallbacks = ::LANG_FALLBACKS.each_with_object({}) do |(locale, fallback), result|
  #   result[locale] = [locale, fallback].compact
  #   result[locale] << :ru if fallback != :ru  # Добавляем :ru, если это не fallback
  # end
  # Задаём кастомные fallbacks
  # https://guides.rubyonrails.org/v8.0.0/configuring.html#config-i18n-fallbacks
  config.i18n.fallbacks.map = ::LANG_FALLBACKS
end

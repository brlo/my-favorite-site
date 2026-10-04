module Chat
  # Перевод сообщений через Яндекс.Переводчик (Yandex Cloud Translate API v2).
  #
  # Ключ задаётся в config/settings.yml:
  #   yandex_translate:
  #     api_key: "..."      # API-ключ сервисного аккаунта
  #     folder_id: "..."    # не обязателен для API-ключа
  # либо переменными окружения YANDEX_TRANSLATE_API_KEY / YANDEX_TRANSLATE_FOLDER_ID.
  # Если ключа нет, перевод в чате не предлагается.
  module Translator
    class Error < StandardError; end

    ENDPOINT = 'https://translate.api.cloud.yandex.net/translate/v2/translate'.freeze
    # Лимит переводов на одного участника
    LIMIT_PER_HOUR = 30

    # Языки интерфейса сайта -> коды Яндекса
    LANG_CODES = {
      'ar' => 'ar', 'hy' => 'hy', 'vi' => 'vi', 'de' => 'de', 'en' => 'en', 'es' => 'es',
      'fr' => 'fr', 'el' => 'el', 'he' => 'he', 'hi' => 'hi', 'fa' => 'fa', 'it' => 'it',
      'ja' => 'ja', 'sw' => 'sw', 'ko' => 'ko', 'sr' => 'sr', 'ru' => 'ru', 'tk' => 'tk',
      'tr' => 'tr', 'uz' => 'uz', 'zh-Hans' => 'zh', 'zh-Hant' => 'zh'
    }.freeze

    module_function

    def config
      cfg = (defined?(::SETTINGS) && ::SETTINGS.is_a?(Hash) && ::SETTINGS['yandex_translate']) || {}
      {
        api_key: ENV['YANDEX_TRANSLATE_API_KEY'].presence || cfg['api_key'].presence,
        folder_id: ENV['YANDEX_TRANSLATE_FOLDER_ID'].presence || cfg['folder_id'].presence
      }
    end

    def enabled?
      config[:api_key].present?
    end

    def supported?(lang)
      LANG_CODES.key?(lang.to_s)
    end

    # Нужен ли перевод с языка from на язык to
    def translatable?(from, to)
      enabled? && supported?(from) && supported?(to) && LANG_CODES[from.to_s] != LANG_CODES[to.to_s]
    end

    def translate_html(html, from:, to:)
      cfg = config
      raise Error, 'translator disabled' if cfg[:api_key].blank?

      body = {
        texts: [html],
        sourceLanguageCode: LANG_CODES.fetch(from.to_s),
        targetLanguageCode: LANG_CODES.fetch(to.to_s),
        format: 'HTML'
      }
      body[:folderId] = cfg[:folder_id] if cfg[:folder_id]

      response = HTTParty.post(
        ENDPOINT,
        body: body.to_json,
        headers: { 'Content-Type' => 'application/json', 'Authorization' => "Api-Key #{cfg[:api_key]}" },
        timeout: 10
      )
      raise Error, "yandex #{response.code}" unless response.success?

      response.parsed_response.dig('translations', 0, 'text').presence || raise(Error, 'empty translation')
    rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED => e
      raise Error, e.message
    end
  end
end

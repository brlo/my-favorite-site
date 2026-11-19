module Chat
  # Перевод сообщений: сначала DeepSeek (для коротких текстов и не чаще раза в 10 минут
  # на весь сайт — чтобы не тратить бюджет), иначе Яндекс.Переводчик.
  #
  # Яндекс: ключ задаётся в config/settings.yml:
  #   yandex_translate:
  #     api_key: "..."      # API-ключ сервисного аккаунта
  #     folder_id: "..."    # не обязателен для API-ключа
  # либо переменными окружения YANDEX_TRANSLATE_API_KEY / YANDEX_TRANSLATE_FOLDER_ID.
  #
  # DeepSeek:
  #   deepseek:
  #     api_key: "sk-..."
  # либо переменной окружения DEEPSEEK_API_KEY.
  # Если ключа DeepSeek нет, всё переводит Яндекс.
  module Translator
    class Error < StandardError; end
    class DeepSeekError < Error; end

    ENDPOINT = 'https://translate.api.cloud.yandex.net/translate/v2/translate'.freeze
    DEEPSEEK_ENDPOINT = 'https://api.deepseek.com/chat/completions'.freeze
    DEEPSEEK_MODEL = 'deepseek-chat'.freeze
    # Ограничения на обращение к DeepSeek: не чаще раза в 10 минут и не длиннее 1000 знаков
    DEEPSEEK_INTERVAL = 10.minutes
    DEEPSEEK_MAX_TEXT = 1000
    DEEPSEEK_SLOT_KEY = 'chat:tr:deepseek:slot'.freeze
    # Лимит переводов на одного участника (Яндекс)
    LIMIT_PER_HOUR = 30

    # Языки интерфейса сайта -> коды Яндекса
    LANG_CODES = {
      'ar' => 'ar', 'hy' => 'hy', 'vi' => 'vi', 'de' => 'de', 'en' => 'en', 'es' => 'es',
      'fr' => 'fr', 'el' => 'el', 'he' => 'he', 'hi' => 'hi', 'fa' => 'fa', 'it' => 'it',
      'ja' => 'ja', 'sw' => 'sw', 'ko' => 'ko', 'sr' => 'sr', 'ru' => 'ru', 'tk' => 'tk',
      'tr' => 'tr', 'uz' => 'uz', 'zh-Hans' => 'zh', 'zh-Hant' => 'zh'
    }.freeze

    # Названия языков для инструкции DeepSeek (коды Яндекса для zh не различают иероглифы)
    LANG_NAMES = {
      'ar' => 'Arabic', 'hy' => 'Armenian', 'vi' => 'Vietnamese', 'de' => 'German',
      'en' => 'English', 'es' => 'Spanish', 'fr' => 'French', 'el' => 'Greek',
      'he' => 'Hebrew', 'hi' => 'Hindi', 'fa' => 'Persian', 'it' => 'Italian',
      'ja' => 'Japanese', 'sw' => 'Swahili', 'ko' => 'Korean', 'sr' => 'Serbian',
      'ru' => 'Russian', 'tk' => 'Turkmen', 'tr' => 'Turkish', 'uz' => 'Uzbek',
      'zh-Hans' => 'Simplified Chinese', 'zh-Hant' => 'Traditional Chinese'
    }.freeze

    module_function

    def config
      cfg = (defined?(::SETTINGS) && ::SETTINGS.is_a?(Hash) && ::SETTINGS['yandex_translate']) || {}
      {
        api_key: ENV['YANDEX_TRANSLATE_API_KEY'].presence || cfg['api_key'].presence,
        folder_id: ENV['YANDEX_TRANSLATE_FOLDER_ID'].presence || cfg['folder_id'].presence
      }
    end

    def deepseek_config
      cfg = (defined?(::SETTINGS) && ::SETTINGS.is_a?(Hash) && ::SETTINGS['deepseek']) || {}
      { api_key: ENV['DEEPSEEK_API_KEY'].presence || cfg['api_key'].presence }
    end

    def enabled?
      config[:api_key].present? || deepseek_config[:api_key].present?
    end

    def supported?(lang)
      LANG_CODES.key?(lang.to_s)
    end

    # Нужен ли перевод с языка from на язык to
    def translatable?(from, to)
      enabled? && supported?(from) && supported?(to) && LANG_CODES[from.to_s] != LANG_CODES[to.to_s]
    end

    # plain_text — исходный текст без разметки: по его длине решаем, отдавать ли DeepSeek.
    def translate_html(html, from:, to:, plain_text: nil)
      if is_deepseek_eligible?(plain_text.presence || html)
        begin
          translated = deepseek_translate(html, from: from, to: to)
          Rails.logger.info("[chat] translate #{from}->#{to} via deepseek")
          return translated
        rescue DeepSeekError => e
          Rails.logger.warn("[chat] deepseek translate failed: #{e.message}")
        end
      end

      translated = yandex_translate(html, from: from, to: to)
      Rails.logger.info("[chat] translate #{from}->#{to} via yandex")
      translated
    end

    # DeepSeek только для коротких текстов и только если на сайте не было такого запроса
    # последние 10 минут. Слот занимаем до вызова: если DeepSeek упадёт, повторы в течение
    # 10 минут уже не будут тратить деньги, а пользователь всё равно получит перевод Яндекса.
    def is_deepseek_eligible?(text)
      return false if deepseek_config[:api_key].blank?
      return false if text.to_s.length > DEEPSEEK_MAX_TEXT

      reserve_deepseek_slot
    end

    def reserve_deepseek_slot
      ::RedisConnectionPool.set(DEEPSEEK_SLOT_KEY, 1, nx: true, ex: DEEPSEEK_INTERVAL.to_i)
    rescue StandardError => e
      Rails.logger.warn("[chat] deepseek slot unavailable: #{e.message}")
      false
    end

    def deepseek_translate(html, from:, to:)
      key = deepseek_config[:api_key]
      raise DeepSeekError, 'deepseek disabled' if key.blank?

      source_name = LANG_NAMES.fetch(from.to_s, from.to_s)
      target_name = LANG_NAMES.fetch(to.to_s, to.to_s)
      instruction = <<~PROMPT.squish
        You are a professional translator. Translate the HTML fragment from #{source_name} to #{target_name}.
        Preserve every HTML tag and attribute exactly as in the source; translate only human-readable text.
        Keep the original paragraph structure. Do not add explanations, Markdown or code fences.
        Return only the translated HTML fragment.
      PROMPT

      response = HTTParty.post(
        DEEPSEEK_ENDPOINT,
        body: {
          model: DEEPSEEK_MODEL,
          messages: [
            { role: 'system', content: instruction },
            { role: 'user', content: html.to_s }
          ],
          temperature: 0,
          max_tokens: 3000,
          stream: false
        }.to_json,
        headers: { 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{key}" },
        timeout: 30
      )
      raise DeepSeekError, "deepseek #{response.code}" unless response.success?

      data = response.parsed_response
      raise DeepSeekError, 'deepseek bad response' unless data.is_a?(Hash)

      content = strip_code_fence(data.dig('choices', 0, 'message', 'content').to_s)
      raise DeepSeekError, 'empty translation' if content.blank?

      content
    rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED => e
      raise DeepSeekError, e.message
    end

    def yandex_translate(html, from:, to:)
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

    # Некоторые модели всё же заворачивают ответ в ```html ... ``` (иногда с пояснением до/после)
    def strip_code_fence(text)
      source = text.to_s.strip
      fenced = source[/```(?:html)?\s*(.*?)\s*```/mi, 1]
      (fenced || source).strip
    end
  end
end

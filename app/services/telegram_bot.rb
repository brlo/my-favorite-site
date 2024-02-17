# Сервис для уведомлений в чат об изменениях на сервере
class TelegramBot
  include HTTParty

  # как получить chat_id: https://stackoverflow.com/a/38388851/1620799
  TG_CHAT_ID = ::SETTINGS.dig('telegram_bot', 'chat_id')
  TG_BOT_TOKEN = ::SETTINGS.dig('telegram_bot', 'token')

  base_uri "https://api.telegram.org/bot#{TG_BOT_TOKEN}"

  def create_post(path, params = {}, headers = {})
    response = self.class.post(
      # PATH
      ::Addressable::URI.escape(path),
      # PARAMS
      # https://core.telegram.org/bots/api#sendmessage
      body: params.to_h.merge(
        parse_mode: 'HTML',
        chat_id: TG_CHAT_ID,
        disable_notification: true,
      ).to_json,
      # HEADERS
      headers: headers.merge(
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      ),
      # debug_output: STDOUT,
    ).parsed_response
  end

  def self.say html_text
    if ::Rails.env.production?
      new.create_post('/sendMessage', {text: html_text})
    else
      puts '=========== Telegram stub msg ==========='
      puts html_text
      puts '========================================='
    end
  end
end

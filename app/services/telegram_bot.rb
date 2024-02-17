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

  # ========================== МЕТОДЫ УВЕДОМЛЕНИЯ =============================

  class Notifiers
    # Страница создана
    def self.page_create(u:, pg:)
      msg  = "🪨 #{u.name} (#{u.username}) создал(а)"
      msg += " статью: <b><a href=\"https://bibleox.com/ru/#{pg.lang}/w/#{pg.path}\">#{pg.title}</a></b>"
      ::TelegramBot.say(msg)
    end

    # Правки созданы
    def self.mr_create(mr:, u:, pg:)
      msg  = "🚀 <b>#{u.name} (#{u.username})</b> предложил(а) <b><a href=\"https://edit.bibleox.com/merge_requests/#{mr.id.to_s}\">правки</a></b>"
      msg += " к статье: <b><a href=\"https://bibleox.com/ru/#{pg.lang}/w/#{pg.path}\">#{pg.title}</a></b>"
      if mr.comment.present?
        msg += " Пояснение: <b>#{mr.comment}</b>."
      end
      ::TelegramBot.say(msg)
    end

    # Правки приняты
    def self.mr_merge(mr:, u:, pg:)
      msg  = "✅ Приняты <b><a href=\"https://edit.bibleox.com/merge_requests/#{mr.id.to_s}\">правки</a></b>"
      msg += " к статье: <b><a href=\"https://bibleox.com/ru/#{pg.lang}/w/#{pg.path}\">#{pg.title}</a></b>."
      msg += " Модератор: #{u.name} (#{u.username})."
      if mr.comment.present?
        msg += " Пояснение: <b>#{mr.comment}</b>."
      end
      ::TelegramBot.say(msg)
    end
  end

end

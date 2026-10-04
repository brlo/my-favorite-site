module Chat
  # Боты — обычные участники с kind: 'bot'. Пишут сразу для всех и без ограничения частоты.
  #   bot = Chat::Bot.find_or_create!(nickname: 'BibleoxBot', title: 'Bot')
  #   Chat::Bot.say(bot, 'Текст')
  module Bot
    module_function

    def find_or_create!(nickname:, title: nil, ui_lang: 'en')
      Member.find_or_create_by!(kind: 'bot', nickname: nickname) do |m|
        m.role = 'bot'
        m.title = title
        m.ui_lang = ui_lang
      end
    end

    def say(bot, text, room: Chat.default_room, reply_to: nil)
      doc = {
        'type' => 'doc',
        'content' => text.to_s.split(/\n{2,}/).map do |para|
          { 'type' => 'paragraph', 'content' => [{ 'type' => 'text', 'text' => para }] }
        end
      }
      message = room.messages.new(member: bot, reply_to: reply_to, kind: 'text', status: 'published', lang: bot.ui_lang)
      message.assign_body(doc, allow_links: false)
      message.save!
      Broadcaster.message(message)
      message
    end
  end
end

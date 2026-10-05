module Chat
  # Таблицы чата: chat_rooms, chat_members, chat_messages, chat_reactions
  def self.table_name_prefix
    'chat_'
  end

  # Фиксированный набор реакций
  REACTIONS = %w[👍 ❤️ 🙏 😊 🤔 😢].freeze

  # Гости и обычные участники: 1 сообщение в 5 минут (burst 1)
  POST_INTERVAL = 5.minutes
  # Редактировать можно в течение суток, не более 5 раз
  EDIT_WINDOW = 24.hours
  MAX_EDITS = 5
  # Длина текста сообщения
  MAX_TEXT_LENGTH = 4000
  # Сообщения хранятся год, затем удаляются
  RETENTION = 1.year
  # Сообщений на одну страницу ленты
  PAGE_SIZE = 50

  DEFAULT_ROOM_SLUG = 'general'.freeze

  def self.default_room
    Room.find_or_create_by!(slug: DEFAULT_ROOM_SLUG) { |r| r.title = 'Bibleox' }
  end
end

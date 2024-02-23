# Lexema.create_indexes

class Lexema < ApplicationMongoRecord
  include Mongoid::Document

  # Слово
  field :w,   as: :word, type: String
  # field :w_d, as: :word_downcased, type: String
  # Лексема
  field :l,   as: :lexema, type: String
  field :l_c, as: :lexema_clean, type: String
  # Транскрипция
  field :tr,  as: :transcription, type: String
  # Сколько раз встречается в тексте
  field :c,   as: :counts, type: Integer, default: 0
  # perseids morpheus doc with word analyzis
  field :xml, as: :xml_doc, type: String
  # время создания можно получать из _id во так: id.generation_time
  field :c_at, as: :created_at, type: DateTime, default: ->{ DateTime.now.utc.round }
  field :u_at, as: :updated_at, type: DateTime, default: ->{ DateTime.now.utc.round }

  # Lexema.remove_indexes
  # Lexema.create_indexes
  # Lexema.remove_undefined_indexes
  index({word: 1},                          {background: true})
  index({lexema: 1},                        {background: true})
  index({word: 1, lexema: 1}, {unique: true, background: true})

  before_validation :normalize_attributes

  validates :word, presence: true

  def normalize_attributes
    # .unicode_normalize(:nfd) -- убираем диакритические знаки
    self.word = self.word.to_s.unicode_normalize(:nfd).strip.presence
    # self.word_downcased = self.word.downcase
    self.lexema = self.lexema.to_s.strip.presence
    self.lexema_clean = self.lexema.to_s.unicode_normalize(:nfd).downcase.delete("\u0300-\u036F").presence
    # транслит латиницей
    self.transcription = ::GreeklishIso843::GreekText.to_greeklish(self.word)

    self.u_at = DateTime.now.utc.round
  end
end

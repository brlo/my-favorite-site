# BibWord.create_indexes

class BibWord < ApplicationMongoRecord
  include Mongoid::Document

  # идентификатор (порядковый номер)
  field :bw_id, type: Integer
  # Слово (downcased)
  field :w,   as: :word, type: String
  # Сколько раз встречается в тексте именно такой вариант слова
  field :c,   as: :counts, type: Integer, default: 0
  # Сколько раз встречается в тексте лексема этого слова
  field :c_by_l, as: :counts_by_l, type: Integer, default: 0
  # Лексема
  field :l,   as: :lexema, type: String
  # Морфология слова: часть речи (ch-r), падеж (pd), число (ch), род (r).
  field :info, type: Hash
  # Транскрипция
  # {'ru' => <>, 'en' => <>}
  field :trnscr,  as: :transcriptions, type: Hash
  # Варианты перевода, встречающиеся у нас в БД
  # {'ru' => <уникальный массив>, 'en' => <уникальный массив>, 'jp' => <уникальный массив>}
  field :trnsl, as: :translations, type: Hash
  # В каких стихах встречается лексема этого слова
  # ['gen:1:1', 'in:2:2']
  field :addrs, type: Array
  # Какое словое смотреть в словарях (куда перенаправлять)
  field :dict_word, type: String
  # время создания можно получать из _id во так: id.generation_time
  field :c_at, as: :created_at, type: DateTime, default: ->{ DateTime.now.utc.round }
  field :u_at, as: :updated_at, type: DateTime, default: ->{ DateTime.now.utc.round }

  attr_readonly :bw_id
  BW_ID_KEY_NAME = 'bw_id_cnt'.freeze

  # BibWord.remove_indexes
  # BibWord.create_indexes
  # BibWord.remove_undefined_indexes
  index({bw_id:    1}, {unique: true, background: true})
  index({word:   1}, {unique: true, background: true})
  index({lexema: 1},               {background: true})

  before_validation :normalize_attributes
  before_create :set_bw_id_if_nil

  validates :word, presence: true

  def set_bw_id_if_nil
    self.bw_id = self.class.allocate_bw_id! if self.bw_id.nil?
  end

  class << self
    # Для сброса счётчика
    # ::RedisConnectionPool.set('ntf_cnt', Notification.last.int_id+1)
    def allocate_bw_id!(count: nil)
      if count
        ::RedisConnectionPool.incrby(BW_ID_KEY_NAME, count)
      else
        ::RedisConnectionPool.incr(BW_ID_KEY_NAME)
      end.to_i
    end

    # Добавить новое слово.
    # Находит в базе уже существующее и дополняет его, или создаёт новое слово.
    def add_word word, addr:, lexema: nil, info: nil, translations: nil, transcriptions: nil
      word = word.to_s.unicode_normalize(:nfd)
      w = BibWord.where(word: word).first
      w = BibWord.where(word: word.downcase).first if w.nil?
      w = self.new(word: word) if w.nil?

      # добавляем адрес в котором встретилось слово
      w.addrs = w.addrs.to_a + [addr] if addr.present?

      # лексема
      w.lexema = lexema if lexema.present?

      # морфология слова
      w.info = info if info.present?

      # перевод ( {"ru": ..., "en": ..., "jp": ...} )
      if translations.present?
        w.translations ||= {}
        translations.each do |lang, tr|
          if lang.present? && tr.present?
            # собираем не один перевод, а все встречающиеся, оставляя на память только уникальные
            w.translations[lang] = (w.translations[lang].to_a + [tr]).uniq.compact
          end
        end
      end

      # транскрипция ( {"en": ...} )
      if transcriptions.present?
        w.transcriptions ||= {}
        transcriptions.each do |lang, tr|
          if lang.present? && tr.present?
            # собираем не один перевод, а все встречающиеся, оставляя на память только уникальные
            w.transcriptions[lang] = (w.transcriptions[lang].to_a + [tr]).uniq.compact
          end
        end
      end

      # TODO: надо бы ещё где-то определить слово, которе нужно смотреть в словаре
      # w.dict_word = ...

      w.save
      w
    end
  end

  def normalize_attributes
    # .unicode_normalize(:nfd) -- убираем диакритические знаки
    self.word = self.word.to_s.unicode_normalize(:nfd).strip.presence
    # self.word_downcased = self.word.downcase
    self.lexema = self.lexema.to_s.strip.presence

    # Только уникальные значения транскрипции
    self.transcriptions = self.transcriptions.to_h.map { |lang, trs| [lang, trs.to_a.map{ _1.to_s.strip.presence }.uniq.compact ] }.to_h
    # Только уникальные значения вариантов перевода
    self.translations = self.translations.to_h.map { |lang, trs| [lang, trs.to_a.map{ _1.to_s.strip.presence }.uniq.compact ] }.to_h

    # стихи в которых встречается слово
    self.addrs = self.addrs.to_a.uniq

    # количество таких слов в Библии
    self.counts = self.addrs.count

    # Количество слов по лексеме:
    # Если указана лексема, то можно посчитать сколько раз встречается слово во всех формах (по лексеме)
    if self.lexema.present?
      ::BibWord.where(lexema: self.lexema).pluck(:counts).sum
    end

    self.u_at = ::DateTime.now.utc.round
  end

  # пока не используется
  # def lexema_clean
  #   self.lexema.to_s.unicode_normalize(:nfd).downcase.delete("\u0300-\u036F").presence
  # end
end


class BibWord < ApplicationRecord
  self.table_name = 'bib_words'

  before_validation :normalize_attributes

  validates :word, presence: true

  class << self
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

      # TODO: надо бы ещё где-то определить слово, которое нужно смотреть в словаре
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
  end

  # пока не используется
  # def lexema_clean
  #   self.lexema.to_s.unicode_normalize(:nfd).downcase.delete("\u0300-\u036F").presence
  # end
end

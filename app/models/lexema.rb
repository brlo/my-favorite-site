class Lexema < ApplicationRecord
  self.table_name = 'lexemas'

  validates :word, presence: true

  before_validation :normalize_attributes

  private

  def normalize_attributes
    # .unicode_normalize(:nfd) -- убираем диакритические знаки
    self.word = self.word.to_s.unicode_normalize(:nfd).strip.presence
    # self.word_downcased = self.word.downcase
    self.lexema = self.lexema.to_s.strip.presence
    self.lexema_clean = self.lexema.to_s.unicode_normalize(:nfd).downcase.delete("\u0300-\u036F").presence
    # транслит латиницей
    self.transcription = ::GreeklishIso843::GreekText.to_greeklish(self.word)
  end
end

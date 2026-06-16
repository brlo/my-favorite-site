# class BibleReference < ApplicationRecord
#   belongs_to :patristic_text

#   validates :book_code, presence: true
#   validates :chapter, :start_verse, presence: true

#   # Для одного стиха
#   scope :exact_verse, ->(book, chapter, verse) {
#     where(book_code: book, chapter: chapter)
#       .where('start_verse <= ? AND end_verse >= ?', verse, verse)
#   }

#   # Для диапазона стихов
#   scope :within_range, ->(book, chapter, start_v, end_v) {
#     where(book_code: book, chapter: chapter)
#       .where('start_verse <= ? AND end_verse >= ?', end_v, start_v)
#   }

#   # Пересекается с диапазоном
#   scope :overlaps_range, ->(book, chapter, start_v, end_v) {
#     where(book_code: book, chapter: chapter)
#       .where('start_verse <= ? AND end_verse >= ?', end_v, start_v)
#   }
# end

class BibleReference < ApplicationRecord
  belongs_to :page
  validates :book_code, :chapter, :verse_start, :verse_end, presence: true

  scope :in_context, ->(book, chapter, verse) do
    where(book_code: book, chapter: chapter, verse_start: ..verse, verse_end: verse..)
  end
end

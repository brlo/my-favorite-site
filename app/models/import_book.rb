if Rails.env.development?
  class ImportBook < ApplicationRecord
    # Если хочешь взять названия книг на другом языке, то просто выдели столбик в SQLite и скопируй
    # а потом отнеси в config/locales
    self.table_name = 'books'
    has_many :verses, foreign_key: :book_number
  end
end

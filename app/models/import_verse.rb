if Rails.env.development?
  class ImportVerse < ApplicationRecord
    # к новой базе сначала надо в редакторе добавить id всем таблицам
    # (сначала добавляешь просто, потом заходишь ставишь автоинкремент)
    self.table_name = 'verses'

    belongs_to :book, foreign_key: :book_number
  end
end

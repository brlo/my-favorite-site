
class ImportBook < ApplicationRecord
  self.table_name = 'books'
  has_many :verses, foreign_key: :book_number
end

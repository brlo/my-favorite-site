class Tagging < ApplicationRecord
  # Связь «тег — статья». Строки создаются по одной на каждую языковую версию статьи (группу переводов).

  belongs_to :page
  belongs_to :tag

  validates :page_id, uniqueness: { scope: :tag_id }
end

class ImportDict < ApplicationRecord
  # к новой базе сначала надо в редакторе добавить id всем таблицам
  # (сначала добавляешь просто, потом заходишь ставишь автоинкремент)
  self.table_name = 'dictionary'
end

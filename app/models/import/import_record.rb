class ImportRecord < ActiveRecord::Base
  self.abstract_class = true
  # connects_to database: { writing: :import_source, reading: :import_source }
  establish_connection :import_source
end

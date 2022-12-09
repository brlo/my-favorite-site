# frozen_string_literal: true
if Rails.env.development?
  class ImportInfo < ApplicationRecord
    self.table_name = 'info'
  end
end

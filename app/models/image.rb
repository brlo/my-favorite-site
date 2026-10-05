class Image < ApplicationRecord
  self.table_name = 'images'

  mount_uploader :simple, SimpleUploader


  before_validation :normalize_attributes

  # validates :title, presence: true

  private

  def normalize_attributes
    self.title = title.to_s.strip
  end
end

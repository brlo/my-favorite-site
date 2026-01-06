class Image < ApplicationRecord
  self.table_name = 'images'

  mount_uploader :simple, SimpleUploader

  # belongs_to :user, foreign_key: 'u_id', primary_key: 'id', optional: true

  before_validation :normalize_attributes

  # validates :title, presence: true

  private

  def normalize_attributes
    self.title = title.to_s.strip
  end
end

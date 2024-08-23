# Image.create_indexes

class Image < ApplicationMongoRecord
  include Mongoid::Document

  mount_uploader :simple, SimpleUploader

  # meta-описание (через запятую ключевые слова)
  field :title, as: :title, type: String
  # время создания можно получать из _id во так: id.generation_time
  field :u_id
  field :c_at,       as: :created_at, type: DateTime, default: ->{ DateTime.now.utc.round }
  field :u_at,       as: :updated_at, type: DateTime, default: ->{ DateTime.now.utc.round }

  # rake db:mongoid:create_indexes
  # rake db:mongoid:remove_indexes
  # rake db:mongoid:remove_undefined_indexes
  # Image.remove_undefined_indexes
  # Image.remove_indexes
  # Image.create_indexes

  # belongs_to :user, foreign_key: 'u_id', primary_key: 'id'
end

require 'nokogiri'
# Menu.create_indexes

class Menu < ApplicationMongoRecord
  include Mongoid::Document

  field :parent_id, type: String
  # На какой странице отрисовывается этот список
  field :page_id, type: BSON::ObjectId
  # основной заголовок
  field :title, type: String
  # path (без него элемент меню будет обычным заголовком, без ссылки)
  field :path, type: String

  # приоритетность статьи
  field :priority, type: Integer
  # время создания можно получать из _id во так: id.generation_time
  field :c_at, as: :created_at, type: DateTime, default: ->{ DateTime.now.utc.round }
  field :u_at, as: :updated_at, type: DateTime, default: ->{ DateTime.now.utc.round }

  # rake db:mongoid:create_indexes
  # rake db:mongoid:remove_indexes
  # rake db:mongoid:remove_undefined_indexes
  # для поиска в нужной книге
  index({page_id: 1}, {background: true})

  before_validation :normalize_attributes
  validates :page_id, :title, presence: true

  def childs
    self.class.where(parent_id: self.id)
  end

  def normalize_attributes
    self.title = self.title.to_s.strip
    self.path = self.path.to_s.strip if self.path.present?
    self.priority = self.priority.to_i

    self.u_at = DateTime.now.utc.round
  end

  def attrs_for_render
    {
      id: self.id.to_s,
      parent_id: self.parent_id,
      page_id: self.page_id.to_s,
      title: self.title,
      path: self.path,
      priority: self.priority,
      created_at: self.c_at,
      updated_at: self.u_at,
    }
  end

  def self.tree(page_id)
    records = self.where(page_id: page_id).to_a
  end
end

require 'nokogiri'
# Menu.create_indexes

class Menu
  include Mongoid::Document

  # На какой странице отрисовывается этот список
  field :page_id, type: BSON::ObjectId
  # основной заголовок
  field :title, type: String
  # path
  field :path, type: String
  field :path_parent, type: String

  # приоритетность статьи
  field :priority, type: Integer
  # время создания можно получать из _id во так: id.generation_time
  field :c_at, as: :created_at, type: DateTime, default: ->{ DateTime.now.utc.round }
  field :u_at, as: :updated_at, type: DateTime, default: ->{ DateTime.now.utc.round }

  # rake db:mongoid:create_indexes
  # rake db:mongoid:remove_indexes
  # rake db:mongoid:remove_undefined_indexes
  # для поиска в нужной книге
  index({page_id: 1},                        {background: true})

  before_validation :normalize_attributes
  validates :page_id, :title, :path, :priority, presence: true

  def childs
    self.class.where(path_parent: self.path)
  end

  def normalize_attributes
    self.title = self.title.to_s.strip
    self.path = self.path.to_s.strip
    self.path_parent = self.path_parent.to_s.strip.presence
    self.priority = self.priority.to_i if self.priority.present?

    self.u_at = DateTime.now.utc.round
  end

  def attrs_for_render
    {
      id: self.id.to_s,
      page_id: self.page_id.to_s,
      title: self.title,
      path: self.path,
      path_parent: self.path_parent,
      priority: self.priority,
      created_at: self.c_at,
      updated_at: self.u_at,
    }
  end

  def self.tree(page_id)
    records = self.where(page_id: page_id).to_a
  end
end

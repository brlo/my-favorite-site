# db.createUser({ user: 'bibl_explorer', pwd: '123', roles: [ { role: "readWrite", db: "biblia_production" } ] });
# Verse.create_indexes

class Quote
  include Mongoid::Document

  # address    - zah:9:8
  # topic_id   - 10
  # is_yes     - true
  # created_at - дата-время-создания

  # адрес стиха
  field :a,    as: :address, type: String
  # id темы
  field :t_id, as: :topic_id, type: Integer
  # подтверждение или опровержение
  field :y,    as: :is_yes, type: Boolean
  # время создания можно получать из _id во так: id.generation_time
  field :c_at, as: :created_at, type: DateTime, default: ->{ DateTime.now.utc.round }

  # rake db:mongoid:create_indexes
  # rake db:mongoid:remove_indexes
  # rake db:mongoid:remove_undefined_indexes
  # для поиска в нужной книге
  index({t_id: 1}, {background: true})

  validates :address, :topic_id, :is_yes, presence: true
end


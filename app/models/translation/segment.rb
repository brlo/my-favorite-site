# app/models/segment.rb
class Segment
  include Mongoid::Document

  # УНИВЕРСАЛЬНАЯ АДРЕСАЦИЯ
  field :ch, as: :chapter, type: Integer, null: false # Номер главы
  field :p,  as: :paragraph, type: Integer, null: false # Номер параграфа внутри главы
  field :l,  as: :line, type: Integer # Опционально: номер строки внутри параграфа

  # Если line = nil, значит сегмент - это целый параграф.
  # Если line указан, значит сегмент - это строка/предложение.

  # СОДЕРЖАНИЕ И РАЗМЕТКА
  field :lg, as: :lang, type: String      # Язык сегмента ('la', 'ru', 'de')
  field :t,  as: :text, type: String      # Текст сегмента
  field :is_o,  as: :is_original, type: Boolean, default: false # Авторский ли это текст?

  # Массив тэгов, которые "активны" в начале этого сегмента.
  # Каждый тэг — это строка с именем и опционально атрибутами.
  field :ot, as: :open_tags, type: Array, default: []
  # Пример: ['p', 'strong', 'a[href=https://site.com]']

  # Массив тэгов, которые закрываются в конце этого сегмента.
  field :ct, as: :close_tags, type: Array, default: []
  # Пример: ['strong', 'a'] (закрываем жирность и ссылку, но параграф остаётся открыт)

  field :c_at, as: :created_at, type: DateTime, default: ->{ DateTime.now.utc.round }
  field :u_at, as: :updated_at, type: DateTime, default: ->{ DateTime.now.utc.round }

  # идентификаторы
  field :tp_id, as: :translation_project_id, type: BSON::ObjectId, null: false
  field :ss_id, as: :source_segment_id, type: BSON::ObjectId

  # СВЯЗИ
  belongs_to :translation_project_id, foreign_key: 'tp_id', primary_key: 'id'
  belongs_to :source_segment, foreign_key: 'ss_id', primary_key: 'id', class_name: 'Segment', optional: true # С какого сегмента переведён этот

  # Предложенные варианты перевода
  has_many :translations, dependent: :destroy
  # произошедшие от этого сегменты (посредством переводов)
  has_many :derived_segments, class_name: 'Segment', inverse_of: :source_segment, foreign_key: :source_segment_id

  # ВАЖНО: Индексы для быстрой выборки и сортировки
  index({ translation_project_id: 1, chapter: 1, paragraph: 1, line: 1 })
  index({ translation_project_id: 1, lang: 1 })
  index({ source_segment_id: 1 })

  # Валидация: для одного документа не может быть двух сегментов с одинаковым адресом и языком
  validates_uniqueness_of :line, scope: [:document_id, :chapter, :paragraph, :lang], allow_nil: true
end

# MergeRequest.create_indexes

class MergeRequest < ApplicationMongoRecord
  include Mongoid::Document

  # Тип страницы (для писания и тд)
  field :page_id,    as: :page_id, type: String
  field :is_m,       as: :is_merged, type: Boolean
  field :t_orig,     as: :text_original, type: String
  field :t_edited,   as: :text_edited, type: String
  # время создания можно получать из _id во так: id.generation_time
  field :c_at,       as: :created_at, type: DateTime, default: ->{ DateTime.now.utc.round }
  field :u_at,       as: :updated_at, type: DateTime, default: ->{ DateTime.now.utc.round }

  # rake db:mongoid:create_indexes
  # rake db:mongoid:remove_indexes
  # rake db:mongoid:remove_undefined_indexes
  index({page_id: 1}, { background: true })

  before_validation :normalize_attributes
  validates :page_id, :text_edited, presence: true

  def normalize_attributes
    self.text_original = self.text_original.to_s.strip if self.text_original.present?
    self.text_edited = self.text_edited.to_s.strip

    # избавяемся от лишних в тэгов
    self.text_original = sanitizer.sanitize(
      self.text_original,
      tags: %w(div ul ol li h1 h2 h3 blockquote b i em strike s u hr br p a mark img code)
    )
    self.text_edited = sanitizer.sanitize(
      self.text_edited,
      tags: %w(div ul ol li h1 h2 h3 blockquote b i em strike s u hr br p a mark img code)
    )

    # Заменяем неразрывные пробелы (&nbsp;) на обычные. Иначе строки не рвутся, выглядит очень странно
    # приходят эти пробелы, походу, через редактор Pell. В базе выглядит уже не как &nbsp;, а как обычный пробел,
    # поэтому сразу и не распознаешь, а вот в VSCode он выделяется жёлтым прямоугольником.
    self.text_original = self.text_original.gsub(' ', ' ') if self.text_original.present?
    self.text_original = self.text_original.gsub('&nbsp;', ' ') if self.text_original.present?
    self.text_edited = self.text_edited.to_s.gsub(' ', ' ')
    self.text_edited = self.text_edited.to_s.gsub('&nbsp;', ' ')

    self.u_at = DateTime.now.utc.round
  end
end

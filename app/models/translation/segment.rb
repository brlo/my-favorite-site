class Segment < ApplicationRecord
  belongs_to :translation_project
  belongs_to :source_segment, class_name: 'Segment', optional: true

  has_many :translations, dependent: :destroy
  has_many :derived_segments, class_name: 'Segment', foreign_key: :source_segment_id, inverse_of: :source_segment, dependent: :nullify

  validates :chapter, :paragraph, :lang, presence: true
  validates :line, uniqueness: { scope: [:translation_project_id, :part, :chapter, :paragraph, :lang], allow_nil: true }

  def is_user_already_make_translation(user:, lang:)
    self.translations.where(lang: lang, user_id: user.id).exists?
  end
end

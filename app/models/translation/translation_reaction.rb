class TranslationReaction < ApplicationRecord
  belongs_to :translation
  belongs_to :user

  enum :reaction, {
    like: 1,
    dislike: -1
  }

  # validates :user_id, uniqueness: { scope: :translation_id }

  after_destroy :remove_vote_from_translation

  # установить нужную реакцию
  def self.toggle_reaction(translation, user_id, new_reaction)
    upsert(
      {
        translation_id: translation.id,
        user_id: user_id,
        reaction: new_reaction,
        updated_at: Time.current
      },
      unique_by: [:user_id, :translation_id],
      returning: [:reaction]
    )
  end

  private

  def remove_vote_from_translation
    translation = self.translation
    if translation.votes.present? && translation.votes&.key?(user_id.to_s)
      translation.votes.delete(user_id.to_s)
      translation.update_column(:votes, translation.votes)
    end
  end
end

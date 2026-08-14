class Translation < ApplicationRecord
  belongs_to :translation_project
  belongs_to :segment
  belongs_to :user
  has_many :translation_reactions

  validates :text, :lang, :source_lang, presence: true
  # Разрешаем два перевода, а не 1:
  # validates :user_id, uniqueness: { scope: [:segment_id, :lang], message: :taken }
  validate :limit_two_per_segment_lang

  before_validation :normalize_attributes
  before_destroy :remove_downvotes_from_segment

  def normalize_attributes
    self.text = text.to_s.strip.gsub(/[\t\s\n\r]+/, ' ').presence
    self.text = sanitizer.sanitize(
      self.text.to_s,
      tags: ::Page::ALLOW_TAGS,
      attributes: ::Page::ALLOW_ATTRS,
    )
  end

  def upvotes
    votes.values.count { it['v'] == 1 }
  end

  def downvotes
    votes.values.count { it['v'] == -1 }
  end

  # Голосование
  def upvote(u_id)
    add_vote(u_id, 1)
  end

  def downvote(u_id)
    add_vote(u_id, -1)
  end

  def editable_by?(user)
    return true if user&.is_admin?
    return true if self.user_id == user&.id && self.created_at > 15.minutes.ago
    false
  end

  def user_vote(user)
    return nil unless user
    votes.dig(user.id.to_s, 'v')
  end

  # ---

  # Добавление голоса пользователя. Повторная передача такого же голоса приведёт к его удалению.
  def add_vote(u_id, value)
    return false if u_id == self.user_id # нельзя голосовать за свой перевод

    self.with_lock do
      self.reload
      user_key = u_id.to_s
      # Повторный клик на тот же голос, просто убирает этот голос (делает отмену голоса)
      # поэтому, старый голос в любом случае удаляем:
      old_vote = votes.delete(user_key)
      # новый голос добавляем в том случае, если старого не было, или был другой
      is_new_or_change_reaction = old_vote.nil? || old_vote['v'] != value
      votes[user_key] = {'v' => value, 't' => Time.now} if is_new_or_change_reaction
      # новая итоговая сумма голосов
      self.vote_score = votes.map { |k,v| v['v'] }.sum
      is_saved = self.save!

      # создаём также настоящую реакцию
      if is_new_or_change_reaction
        ::TranslationReaction.toggle_reaction(self, u_id, value)
      else
        ::TranslationReaction.find_by(translation_id: self.id, user_id: u_id)&.delete
      end

      is_saved
    end
  end

  # Удалить голос пользователя (конкретный или любой, если указан value)
  def remove_vote(user_id, value = nil)
    user_key = user_id.to_s

    self.with_lock do
      self.reload
      if value
        if self.votes.find { |k,v| k == user_key && v['v']== value }
          self.votes.delete(user_key)

          # удаляем настоящую реакцию
          r = self.translation_reactions.where(user_id:).first
          r.delete if r.reaction == value
        end
      else
        self.votes.delete(user_key)
        self.translation_reactions.where(user_id:).first&.delete
      end
      self.save!
    end
  end

  private

  # Когда удаляется перевод, то надо удалить с соседних переводов downvote,
  # который можно было сделать только после добавления своего перевода.
  def remove_downvotes_from_segment
    self.segment.translations.where(lang: self.lang).each do |tr|
      tr.remove_vote(self.user_id, -1)
    end
  end

  def limit_two_per_segment_lang
    return unless user_id.present? && segment_id.present? && lang.present?

    count = self.class.where(
      user_id: user_id,
      segment_id: segment_id,
      lang: lang
    ).count

    # Для обновления: исключаем текущую запись
    count -= 1 if persisted?

    if count >= 2
      errors.add(:user_id, "может создать максимум 2 варианта перевода")
    end
  end
end

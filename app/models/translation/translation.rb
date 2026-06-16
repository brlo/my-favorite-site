class Translation < ApplicationRecord
  belongs_to :translation_project
  belongs_to :segment
  belongs_to :user

  validates :text, :lang, :source_lang, presence: true
  # Разрешаем два перевода, а не 1
  # validates :user_id, uniqueness: { scope: [:segment_id, :lang], message: :taken }
  validate :limit_two_per_segment_lang

  after_save :update_segment_project_langs
  before_destroy :remove_downvotes_from_segment

  def upvotes
    votes.values.count { it['v'] == 1 }
  end

  def downvotes
    votes.values.count { it['v'] == -1 }
  end

  # Голосование
  def upvote(user)
    add_vote(user, 1)
  end

  def downvote(user)
    add_vote(user, -1)
  end

  def remove_vote(user)
    return false unless votes.key?(user.id.to_s)
    old_value = votes.delete(user.id.to_s)
    self.vote_score -= old_value
    save!
    true
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

  private

  def add_vote(user, value)
    return false if user.id == user_id # нельзя голосовать за свой перевод
    user_key = user.id.to_s
    # Повторный клик на тот же голос, просто убирает этот голос (делает отмену голоса)
    # поэтому, старый голос в любом случае удаляем:
    old_vote = votes.delete(user_key)
    # новый голос добавляем в том случае, если старого не было, или был другой
    votes[user_key] = {'v' => value, 't' => Time.now} if old_vote.nil? || old_vote['v'] != value
    # новая итоговая сумма голосов
    self.vote_score = votes.map { |k,v| v['v'] }.sum
    save!
  end

  def update_segment_project_langs
    project = segment.translation_project
    unless project.source_langs.include?(source_lang)
      project.source_langs << source_lang
      project.save!(validate: false)
    end
  end

  # Когда удаляется перевод, то надо удалить с соседних переводов downvote,
  # который можно было сделать только после добавления своего перевода.
  def remove_downvotes_from_segment
    user_key = self.user_id.to_s
    self.segment.translations.where(lang: self.lang).each do |tr|
      if tr.votes.find { |k,v| k == user_key && v['v']== -1 }
        tr.votes.delete(user_key)
        tr.save
      end
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

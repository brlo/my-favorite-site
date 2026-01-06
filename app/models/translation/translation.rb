# app/models/translation.rb
class Translation
  include Mongoid::Document

  field :t, as: :text, type: String
  field :l, as: :lang, type: String # На какой язык переведено
  field :sl, as: :source_lang, type: String # С какого языка переводил пользователь
  field :vs, as: :vote_score, type: Integer, default: 0
  field :v, as: :votes, type: Hash, default: {} # { "user_id_1" => 1, "user_id_2" => -1 }
  field :is_a, as: :is_approved, type: Boolean, default: false # админ одобрил как лучший перевод?

  field :c_at, as: :created_at, type: DateTime, default: ->{ DateTime.now.utc.round }
  field :u_at, as: :updated_at, type: DateTime, default: ->{ DateTime.now.utc.round }

  # идентификаторы
  field :s_id, as: :segment_id, type: BSON::ObjectId, null: false
  field :u_id, as: :user_id, type: BSON::ObjectId, null: false

  belongs_to :segment, foreign_key: 's_id', primary_key: 'id'
  belongs_to :user, foreign_key: 'u_id', primary_key: 'id'

  # Индексы для быстрого поиска популярных переводов для сегмента
  index({ segment_id: 1, lang: 1, vote_score: -1 })
  index({ user_id: 1 })

  def up_vote(user); add_vote(user, 1); end
  def down_vote(user); add_vote(user, -1); end

  private

  def add_vote(user, value)
    user_id_str = user.id.to_s
    # нельзя голосовать за свои переводы
    return false if user_id_str == self.user_id.to_s
    # не нужно ничего делать, если ранее это уже сделано
    return false if votes[user_id_str] == value

    self.votes[user_id_str] = value
    self.vote_score = votes.values.sum
    save
  end
end

# QuotesPage.create_indexes

class QuotesPage
  include Mongoid::Document

  # название
  field :title, type: String
  # путь в url
  field :path, type: String
  # язык
  field :lang, type: String
  # язык
  field :body, type: String
  # ссылки на использованные стихи
  field :addresses, type: Array
  # id темы
  field :s_id, as: :subject_id, type: String
  # время создания можно получать из _id во так: id.generation_time
  field :c_at, as: :created_at, type: DateTime, default: ->{ DateTime.now.utc.round }

  # rake db:mongoid:create_indexes
  # rake db:mongoid:remove_indexes
  # rake db:mongoid:remove_undefined_indexes
  # для поиска в нужной книге
  index({s_id: 1}, {background: true})

  before_validation :grab_quote_addresses
  validates :title, :lang, :s_id, presence: true

  # находит в тексте статьи цитаты в скобках, возвращает массив без скобок:
  # [
  #   "Зах. 1:2",
  #   "King 1:2"
  # ]
  def quotes
    regex = /\([[[:alnum:]]\s]{1,20}\.?\s*\d{1,3}:?[\d\,\-]{0,20}\)/i
    self.body.scan(regex).map{ |s| s.gsub(/[()]/, '') }
  end

  # находим и сохраняем цитаты из текста в спец. поле
  def grab_quote_addresses
    self.addresses = quotes().map { |q_human| [q_human, ::AddressConverter.human_to_link(q_human)] }
  end
end

# qs = QuotesSubject.create!(name_ru: 'Бог', name_en: 'God', p_id: nil)
# QuotesSubject.create!(name_ru: 'Бог один', name_en: 'God is one', p_id: qs._id.to_s)
# QuotesSubject.create!(name_ru: 'Бог троичен', name_en: 'Trinity', p_id: qs._id.to_s)
# QuotesSubject.create!(name_ru: 'Бог свойства', name_en: 'Trinity', p_id: qs._id.to_s)
# QuotesSubject.create!(name_ru: 'Бог титулы', name_en: 'Trinity', p_id: qs._id.to_s)
# QuotesSubject.create!(name_ru: 'Бог характер', name_en: 'Trinity', p_id: qs._id.to_s)

# qs = QuotesSubject.create!(name_ru: 'Христос', name_en: 'Christ', p_id: nil)
# QuotesSubject.create!(name_ru: 'Христос — Бог', name_en: 'Christ is God', p_id: qs._id.to_s)

# qs = QuotesSubject.create!(name_ru: 'Церковь', name_en: 'Christ', p_id: nil)
# qs = QuotesSubject.create!(name_ru: 'Спасение', name_en: 'Christ', p_id: nil)


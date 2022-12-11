# Раздел для цитат
# QuotesSubject.create_indexes

class QuotesSubject
  include Mongoid::Document

  # название
  field :title_ru, type: String
  field :title_en, type: String
  field :title_gr, type: String
  field :title_jp, type: String
  # описание
  field :desc_ru, type: String
  field :desc_en, type: String
  field :desc_gr, type: String
  field :desc_jp, type: String
  # место в списке (1 - первое, и тд)
  field :position, type: Integer
  # id старшей темы
  field :p_id, as: :parent_id, type: String
  # время создания можно получать из _id во так: id.generation_time
  field :c_at, as: :created_at, type: DateTime, default: ->{ DateTime.now.utc.round }

  # rake db:mongoid:create_indexes
  # rake db:mongoid:remove_indexes
  # rake db:mongoid:remove_undefined_indexes
  # для поиска в нужной книге
  index({p_id: 1}, {background: true})

  before_validation :normalize_attributes

  validates :title_ru, presence: true

  # построение дерева тем
  def self.tree_data
    # раскладываем элементы по полочкам с подписью parent_id
    # nil => [...] # корневые
    # 1 => [...] # вложения
    parent__els = ::Hash.new([].freeze)

    ::QuotesSubject.all.order(position: :asc).each do |s|
      parent__els[s.p_id] += [{
        id: s.id.to_s,
        p_id: s.p_id&.to_s,
        title: s.send("title_#{::I18n.locale}") || s.title_en,
      }]
    end

    # корневые темы
    root_el = {id: nil, p_id: nil, title: 'root'}

    # страницы, сгруппированные по {s_id => [page_path, ...]}
    pages = ::Hash.new([])
    ::QuotesPage.where(lang: ::I18n.locale).order(position: :asc).pluck(:s_id, :title, :path).to_a.map do |s_id, title, path|
      pages[s_id] += [[title, path]]
    end

    # конечное дерево элементов
    build_el(root_el, parent__els, pages)
  end

  # вспомогательный метод для #tree_data
  def self.build_el el, parent__els, pages
    el_id = el[:id]
    current_pages = pages[el_id]

    # потомки, хотя ещё не заполненные
    children = parent__els[el_id]
    if children
      # заполняем потомков их потомками
      children = children.map { |ch| build_el(ch, parent__els, pages) }

      el[:children] = children if children
      el[:pages] = current_pages if current_pages
    end

    el
  end

  private

  def normalize_attributes
    self.title_ru = self.title_ru.to_s.strip
    self.title_en = self.title_en.to_s.strip
    self.title_gr = self.title_gr.to_s.strip
    self.title_jp = self.title_jp.to_s.strip
    self.desc_ru = self.desc_ru.to_s.strip
    self.desc_en = self.desc_en.to_s.strip
    self.desc_gr = self.desc_gr.to_s.strip
    self.desc_jp = self.desc_jp.to_s.strip
    self.p_id = self.p_id.presence

    if self.position.blank?
      self.position = QuotesSubject.where(:position.nin => [nil, '']).order(position: :asc).last&.position.to_i + 1
    end
  end
end

# i=1;QuotesSubject.each{|s| s.update!(position: i); i+=1; }

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


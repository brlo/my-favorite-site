require 'nokogiri'
# Page.create_indexes

class Page < ApplicationMongoRecord
  PAGE_TYPES = {
    'статья'        => 1,
    'книга'         => 2,
    'библ. стих'    => 3,
    'список'        => 4,
    'книга стихами' => 5,
  }

  include Mongoid::Document

  attr_accessor :tags_str

  # Тип страницы (для писания и тд)
  field :pt,         as: :page_type, type: String, default: 1
  field :is_pub,     as: :is_published, type: Boolean, default: false
  # автор
  field :u_id,       as: :user_id, type: BSON::ObjectId
  # редакторы
  field :editors, type: Array
  # основной заголовок
  field :title, type: String
  # Название части книги (Том 1, или просто "1") или годы жизни автора
  field :ts,         as: :title_sub, type: String
  # meta-описание (через запятую ключевые слова)
  field :meta,       as: :meta_desc, type: String
  # path
  field :path, type: String
  field :path_low, type: String
  field :p_id,       as: :parent_id, type: BSON::ObjectId
  # старый путь к статье, с которого надо редиректить на текущий path
  field :r_from,     as: :redirect_from, type: String
  # аудио-файл
  field :au,         as: :audio, type: String
  # язык
  field :lg,         as: :lang, type: String
  # языковой идентификатор страницы для поиска таких же страниц на другом языке
  field :gli,        as: :group_lang_id, type: BSON::ObjectId
  # текст статьи
  field :bd,         as: :body, type: String
  # текст статьи с разбивкой на стихи
  field :vrs,        as: :verses, type: Array
  # ссылки и заметки
  field :rfs,        as: :references, type: String
  # id темы
  field :tags, type: Array
  # приоритетность статьи
  field :prior,      as: :priority, type: Integer
  # время создания можно получать из _id во так: id.generation_time
  field :c_at,       as: :created_at, type: DateTime, default: ->{ DateTime.now.utc.round }
  field :u_at,       as: :updated_at, type: DateTime, default: ->{ DateTime.now.utc.round }
  # Дата последнего мерджа. Служит идентификатором мерджа.
  field :m_at,       as: :merge_ver, type: DateTime, default: ->{ DateTime.now.utc.round }

  # rake db:mongoid:create_indexes
  # rake db:mongoid:remove_indexes
  # rake db:mongoid:remove_undefined_indexes
  # для поиска в нужной книге
  index({path_low: 1},      { unique: true, background: true })
  index({group_lang_id: 1},               { background: true })
  index({user_id: 1},                     { background: true })
  index({redirect_from: 1}, { sparse: true, background: true })

  has_many :merge_requests, foreign_key: 'p_id', primary_key: 'id', dependent: :destroy
  belongs_to :user, foreign_key: 'u_id', primary_key: 'id'

  scope :published, -> { where(is_published: true) }

  before_validation :normalize_attributes
  validates :page_type, :title, :lang, :path, presence: true

  def is_page_simple?; self.page_type.to_i == 1; end
  def is_page_book?; self.page_type.to_i == 2; end
  def is_page_bib_comment?; self.page_type.to_i == 3; end
  def is_page_menu?; self.page_type.to_i == 4; end
  def is_page_verses?; self.page_type.to_i == 5; end

  def menu
    if self.page_type.to_i == PAGE_TYPES['список']
      # отдаём элементы меню простым массивом, а дерево построит фронтенд
      ::Menu.where(page_id: self.id).to_a.map(&:attrs_for_render)
    end
  end

  def tree_menu
    if self.page_type.to_i == PAGE_TYPES['список']
      # строим меню-дерево из пунктов меню (Menu), принадлежащих этой странице (menu.page_id)
      ::TreeBuilder.build_tree_from_objects(
        ::Menu.where(page_id: self.id).to_a.map(&:attrs_for_render),
        field_id: :id,
        field_parent_id: :parent_id
      )
    end
  end

  # текст в виде строк в массиве
  def body_as_arr
    self.body.to_s.gsub('<p>', '').split('</p>')
  end

  def generate_string(cnt = 8)
    random_str = (('A'..'Z').to_a + ('a'..'z').to_a + (0..9).to_a).sample(cnt).join
  end

  def generate_path
    random_str = generate_string(8)
    clean_path = self.title.to_s.gsub(/\s+/, '_').gsub(/[^[[:alnum:]]_]/, '')
    "#{random_str}_#{clean_path}"
  end

  def normalize_attributes
    self.title = self.title.to_s.strip
    self.meta_desc = self.meta_desc.to_s.strip
    self.path = self.path.to_s.strip.presence || generate_path()
    self.path_low = self.path.downcase
    self.page_type = self.page_type.to_i

    # Доработки, если статья — комментарий на библейский стих
    if self.path.blank? && self.is_page_bib_comment?
      # 'Быт. 1:14' -> '/zah/1/#L6'
      self.path = ::AddressConverter.human_to_link(self.title).to_s
      # '/zah/1/#L1,2-3,8' -> 'zah:1:6'
      self.path = self.path.gsub('/#L', ':').gsub('/', ':')[1..-1]
      # ещё title надо обязательно валидировать, генерировать ошибку, если локализация стиха не совпадает с I18n.t
    end

    self.tags = self.tags_str.to_s.split(',').map(&:strip) if self.tags_str.present?
    self.lang = self.lang.to_s.strip.presence if self.lang.present?
    self.group_lang_id = self.group_lang_id || BSON::ObjectId.new

    self.body = self.body.to_s.strip
    self.references = self.references.to_s.strip if self.references.present?

    # избавяемся от лишних в тэгов
    self.body = sanitizer.sanitize(
      self.body,
      tags: %w(div ul ol li h1 h2 h3 blockquote strong b i em strike s u hr br p a mark img code)
    )
    self.references = sanitizer.sanitize(
      self.references,
      tags: %w(div ul ol li h1 h2 h3 blockquote strong b i em strike s u hr br p a mark img code)
    )

    # Заменяем неразрывные пробелы (&nbsp;) на обычные. Иначе строки не рвутся, выглядит очень странно
    # приходят эти пробелы, походу, через редактор Pell. В базе выглядит уже не как &nbsp;, а как обычный пробел,
    # поэтому сразу и не распознаешь, а вот в VSCode он выделяется жёлтым прямоугольником.
    self.body = self.body.to_s.gsub(' ', ' ')
    self.body = self.body.to_s.gsub('&nbsp;', ' ')
    self.references = self.references.gsub(' ', ' ') if self.references.present?
    self.references = self.references.gsub('&nbsp;', ' ') if self.references.present?

    # Обработка страниц, где запрошена разбивка на стихи как в Библии.
    if self.is_page_verses?
      if self.body.present?
        marker = '=%='
        # если есть =%= то действовать по одному алгоритму,
        # а если есть боди, но нет =%=, то действуем по-другому, как в первый раз.
        if self.body.include?(marker)
          self.verses = self.body.gsub('<p>', '').gsub('</p>', '').split(marker)
        else
          self.verses = split_to_verses(self.body)
        end

        self.body = self.verses.map { |v| "<p>#{v}</p>" }.join("<p>#{marker}</p>")
      end
    end

    self.u_at = DateTime.now.utc.round
  end

  # Разбивка сплошного текста на стихи с нумерацией, как в Библии.
  def split_to_verses text
    min_len = 85
    mid_len = 250
    max_len = 300

    _text = sanitizer.sanitize(
      text.to_s,
      tags: %w(b strong i em strike s u p a mark j e)
    )
    _verses = []

    _text = _text.gsub('<p></p>', '')
    _text = _text.gsub('<p>', '')
    _text = _text.split('</p>').select(&:present?)

    current_verse = ''
    _text.each do |t|
      t.split(' ').each do |word|
        current_verse += ' ' if current_verse.length > 0
        current_verse += word

        len = current_verse.length
        is_full =
        case len
        when min_len..mid_len
          # Если набрали минимальную длинну, то отрубаем по ближайшей точке
          true if word[-1] == '.'
        when mid_len..max_len
          # Если превысили средний размер, то отрубаем по любому знаку преминания (не букве)
          true if word[-1] =~ /[^[:alnum:]]/
        when max_len..nil
          # Если превысили максимум, то отрубаем по ближайшему пробелу
          true
        end

        # закидываем стих в массив и готовимся загружать следующий стих
        if is_full
          _verses.push(current_verse)
          current_verse = ''
        end
      end
    end

    # закидываем остаточный стих в массив
    if current_verse.present?
      _verses.push(current_verse)
    end

    _verses
  end
end

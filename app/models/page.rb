require 'nokogiri'
# Page.create_indexes

class Page < ApplicationMongoRecord
  ALLOW_TAGS = %w(ul ol li h1 h2 h3 blockquote strong b i em strike s u hr p a mark img code)

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
  # ids редакторов
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
  field :vrs,        as: :verses, type: Hash
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
  # Page.remove_undefined_indexes
  # Page.remove_indexes
  # Page.create_indexes
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
    self.class.html_to_arr(self.body)
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
    self.title = self.title.to_s.strip.gsub(/[\t\s\n\r]+/, ' ')
    self.meta_desc = self.meta_desc.to_s.strip.gsub(/[\t\s\n\r]+/, ' ')
    self.path = self.path.to_s.strip.gsub(/[\t\s\n\r]+/, '_').presence || generate_path()
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

    self.body = self.class.safe_body(self.body).strip

    # Обработка страниц, где запрошена разбивка на стихи как в Библии.
    if self.is_page_verses?
      # избавяемся от лишних в тэгов и пустых строк
      self.body = sanitizer.sanitize(
        self.body,
        tags: %w(b strong i em strike s u a mark j e h1 h2 h3 h4)
      )

      if self.body.present?
        verse_marker = '=%='
        # если есть =%= то действовать по одному алгоритму (правим деление по стихам),
        if self.body.include?(verse_marker)
          # разница только в скобочках
          chap_find_regex  = /<h[1-4]>\s*([[[:alnum:]]\s\-\.\+\—]+)\s*<\/h[1-4]>/i
          chap_split_regex = /<h[1-4]>\s*[[[:alnum:]]\s\-\.\+\—]+\s*<\/h[1-4]>/i
          # делим по маркерку глав (даже если его нет в тексте, будет массив с одной главой)
          titles = self.body.scan(chap_find_regex)
          texts_arr = self.body.split(chap_split_regex)
          # делим главы по маркерам стихов
          chapter_verses = texts_arr.map { |ch| ch.split(verse_marker) }
          chapter_verses.map{ |vs| [titles.shift, vs]}
        else
        # а если есть боди, но нет =%=, то действуем по-другому, как в первый раз (образуем стихи).
          self.verses = split_to_verses(self.body)
        end

        self.body =
        self.verses.map do |k,v|
          t=titles.shift
          t = (t ? "<h2>#{ t }</h2>" : '')
          t + v.join("<p>#{verse_marker}</p>")
        end
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
      tags: %w(b strong i em strike s u a mark j e h1 h2 h3 h4)
    )

    # разница только в скобочках
    chap_find_regex  = /<h[1-4]>\s*([[[:alnum:]]\s\-\.\+\—]+)\s*<\/h[1-4]>/i
    chap_split_regex = /<h[1-4]>\s*[[[:alnum:]]\s\-\.\+\—]+\s*<\/h[1-4]>/i
    # достаём все заголовки в тэгах h1,h2,h3,h4
    titles = _text.scan(chap_find_regex).map { |m| m.first.strip }

    # делим текст по этим главам
    chapters_texts = _text.split(chap_split_regex)

    # делим тексты на строки
    chapter__verses = chapters_texts.map do |_t|
      _t = _t.gsub('<p></p>', '')
      _t = _t.gsub('<p>', '')
      _t = _t.gsub('</p>', ' ')

      _verses = []

      current_verse = ''
      _t.split(' ').each do |word|
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

      # закидываем остаточный стих в массив
      if current_verse.present?
        _verses.push(current_verse)
      end

      [
        titles.shift,
        _verses
      ]
    end

    chapter__verses&.to_h
  end

  # текст в виде строк в массиве
  def self.html_to_arr html_text
    # добавляем после каждого тэга, который приводит к переносу строки, символ "=%=",
    # чтобы по нему потом разделить на строки
    html_text = safe_body(html_text)
    html_text = html_text.to_s.gsub(/<\/(p|h1|h2|h3|h4|blockquote|ol|ul|hr)>/, '\0=%=').split('=%=')
    html_text
  end

  def self.safe_body html_text
    # Заменяем неразрывные пробелы (&nbsp;) на обычные. Иначе строки не рвутся, выглядит очень странно
    # приходят эти пробелы, походу, через редактор Pell. В базе выглядит уже не как &nbsp;, а как обычный пробел,
    # поэтому сразу и не распознаешь, а вот в VSCode он выделяется жёлтым прямоугольником.

    # tiptap в пустой строке внутрь <p></p> засовывает вот этот странный br:
    html_text = html_text.to_s.gsub('<br class="ProseMirror-trailingBreak">', '')
    html_text = html_text.to_s.gsub('<p></p>', '')
    html_text = html_text.to_s.gsub(' ', ' ')
    html_text = html_text.to_s.gsub('&nbsp;', ' ')

    # избавяемся от лишних в тэгов, аттрибут и пустых строк
    html_text = sanitizer.sanitize(
      html_text,
      tags: ALLOW_TAGS
    ).gsub('<p></p>', '')
  end
end

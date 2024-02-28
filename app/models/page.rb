require 'nokogiri'
# Page.create_indexes

class Page < ApplicationMongoRecord
  ALLOW_TAGS = %w(ul ol li h1 h2 h3 h4 blockquote strong b i em strike sup s u hr p a mark img code)

  PAGE_TYPES = {
    'статья'        => 1,
    'книга'         => 2,
    'библ. стих'    => 3,
    'список'        => 4,
    'книга стихами' => 5,
  }

  EDIT_MODES = {
    'admins'       => 1,
    'moderators'   => 2,
    'contributors' => 3,
  }

  include Mongoid::Document

  attr_accessor :tags_str

  # Тип страницы (для писания и тд)
  field :pt,         as: :page_type, type: String, default: 1
  field :is_pub,     as: :is_published, type: Boolean, default: false
  field :is_del,     as: :is_deleted, type: Boolean
  field :e_md,       as: :edit_mode, type: Integer, default: 1
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
  # текст статьи (для редактирования)
  field :bd,         as: :body, type: String
  # текст статьи (для показа ползьователю)
  field :bdr,        as: :body_rendered, type: String
  # текст статьи с разбивкой на стихи
  field :vrs,        as: :verses, type: Array
  # ссылки и заметки (для релактирования)
  field :rfs,        as: :references, type: String
  # ссылки и заметки (для показа пользователю)
  field :rfsr,       as: :references_rendered, type: String
  # меню, построенное из распарсенных заголовков body (h2, h3, h4)
  field :bd_menu,    as: :body_menu, type: Array
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

  # почему-то dependent: :destroy не работает
  has_many :merge_requests, foreign_key: 'p_id', primary_key: 'id', dependent: :destroy
  belongs_to :user, foreign_key: 'u_id', primary_key: 'id'

  scope :published, -> { where(is_published: true) }
  scope :deleted, -> { where(is_deleted: true) }

  before_validation :normalize_attributes

  validates :page_type, :title, :lang, :path, presence: true

  after_create :chat_notify_create

  # у статьи есть автор и редакторы
  # тут добавляем редактора
  def add_editor _user
    return self.editors.to_a if _user.id == self.user_id
    # добавляем user_id к текущему списку, если его там ещё нет,
    # а потом убираем от туда автора статьи (вдруг случайно попал)
    self.editors = (self.editors.to_a | [_user.id]) - [self.user_id]
  end

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

  # текст в виде строк в массиве
  def references_as_arr
    self.class.html_to_arr(self.references)
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
    if self.path_low_changed?
      self.redirect_from = self.path_low_was
    end

    self.page_type = self.page_type.to_i

    self.edit_mode = self.edit_mode.to_i

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

    if self.references_changed?
      self.references = self.class.safe_html(self.references).strip
      self.references_rendered = render_references_footnotes(self.references)
    end

    if self.body_changed?
      # приводим в порядок body
      self.body = self.class.safe_html(self.body).strip
      # body мы будем редактировать в админке, а отображать для клиента body_rendered,
      # поэтому чтоб в админке не мешать админку, мы сноски не будем ему показыват как ссылки,
      # сделаем их обычным текстом:
      self.body = remove_footnote_links(self.body)

      # построение перекрестных ссылок на сноски
      self.body_rendered = render_body_footnotes(self.body)

      # построение оглавления и необходимых ссылок
      rendered_data = render_body_and_menu(self.body_rendered)
      self.body_rendered = rendered_data[:text]
      self.body_menu = rendered_data[:menu]

      # Обработка страниц, где запрошена разбивка на стихи как в Библии.
      if self.is_page_verses?

        # избавяемся от лишних тэгов и пустых строк
        _text = self.body_rendered.to_s.gsub('<p></p>', ' ')
        _text = sanitizer.sanitize(
          _text,
          tags: %w(h2 a sup),
          attributes: %w(id href class)
        )

        if _text.present?

          verse_marker = '=%='

          # если есть =%=, значит стихи в отдельном поле уже построены и нам опять прислали новый сплошной текст
          # в котором уже есть деление с помощью =%=, и теперь надо тольк по этому маркеру заново собрать verses
          if _text.include?(verse_marker)
            # ------------------ ЕСТЬ BODY с маркером строк, делаем VERSES -------------------------

            # главы
            # [ [ЗАГОЛОВОК, ТЕКСТ], ...]
            chapters = []

            doc = ::Nokogiri.HTML(_text)
            current_title = ''
            current_chapter_text = ''
            doc.at_css('body').children.each do |el|
              if el.name == 'h2'
                # встретился заголовок главы
                # значит старая глава закончилась
                if current_chapter_text.present?
                  chapters << [
                    current_title,
                    current_chapter_text.gsub('\n', '')
                  ]
                end

                # начинаем новый набор главы
                current_title = el.inner_html
                current_chapter_text = ''
              else
                current_chapter_text += el.to_s
              end
            end
            # Забираем остатки
            if current_chapter_text.present?
              chapters << [
                current_title,
                current_chapter_text.gsub('\n', '')
              ]
            end

            # строим результат, по пути делим тексты глав на строки по маркерам_chapter_title, _chapter_text
            self.verses =
            chapters.map do |(_chapter_title, _chapter_text)|
              { title: _chapter_title, lines: _chapter_text.split(verse_marker)}
            end
          else
            # --------------------- НЕТ BODY с маркером строк, делаем VERSES из простого body, и из verses -- BODY с маркерами строк ---------
            # а если есть боди, но нет =%=, то действуем по-другому, как в первый раз (образуем стихи).
            self.verses = split_to_verses(_text)

            self.body =
            self.verses.map do |data|
              title = data[:title]
              t = title.present? ? "<h2>#{ title }</h2>" : ''

              t + data[:lines].join("<p>#{verse_marker}</p>")
            end.join("<p>#{verse_marker}</p>")
          end
        end
      end
    end

    self.u_at = DateTime.now.utc.round
  end

  # ПЕРВИЧНАЯ Разбивка сплошного текста на стихи с нумерацией, когда =%= ещё нет
  def split_to_verses text
    min_len = 85
    mid_len = 250
    max_len = 300

    _text = sanitizer.sanitize(
      text.to_s,
      tags: %w(h2 a sup),
      attributes: %w(id href class)
    )
    _text = _text.gsub("\n", '')

    # главы
    # [ [ЗАГОЛОВОК, ТЕКСТ], ...]
    chapters = []

    doc = ::Nokogiri.HTML(text)
    current_title = ''
    current_chapter_text = ''
    doc.at_css('body').children.each do |el|
      if el.name == 'h2'
        # встретился заголовок главы
        # значит старая глава закончилась
        if current_chapter_text.present?
          chapters << [
            current_title,
            current_chapter_text.gsub('\n', '')
          ]
        end

        # начинаем новый набор главы
        current_title = el.inner_html
        current_chapter_text = ''
      else
        current_chapter_text += el.to_s
      end
    end
    # Забираем остатки
    if current_chapter_text.present?
      chapters << [
        current_title,
        current_chapter_text.gsub('\n', '')
      ]
    end

    # делим тексты на строки
    chapter__verses =
    chapters.map.with_index do |(_chapter_title, _chapter_text), i|
      _verses = []

      current_verse = ''
      # разделяем строку по пробелам, которые не находятся внутри тегов
      _chapter_text.split(/\s(?![^<]*>)/).each do |word|
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

      {
        title: _chapter_title,
        lines: _verses,
      }
    end

    chapter__verses
  end

  # текст в виде строк в массиве
  def self.html_to_arr html_text
    # добавляем после каждого тэга, который приводит к переносу строки, символ "=%=",
    # чтобы по нему потом разделить на строки
    html_text = safe_html(html_text)
    html_text = html_text.to_s.gsub(/<\/(p|h1|h2|h3|h4|hr)>/, '\0=%=').split('=%=')
    html_text
  end

  def self.safe_html html_text
    # Заменяем неразрывные пробелы (&nbsp;) на обычные. Иначе строки не рвутся, выглядит очень странно
    # приходят эти пробелы, походу, через редактор Pell. В базе выглядит уже не как &nbsp;, а как обычный пробел,
    # поэтому сразу и не распознаешь, а вот в VSCode он выделяется жёлтым прямоугольником.

    # tiptap в пустой строке внутрь <p></p> засовывает вот этот странный br:
    html_text = html_text.to_s.gsub('<br class="ProseMirror-trailingBreak">', '')
    html_text = html_text.to_s.gsub('<p></p>', '')
    html_text = html_text.to_s.gsub(' ', ' ')
    html_text = html_text.to_s.gsub('&nbsp;', ' ')

    # избавяемся от лишних тэгов, аттрибут и пустых строк
    html_text = sanitizer.sanitize(
      html_text,
      tags: ALLOW_TAGS,
      attributes: %w(id href class)
    ).gsub('<p></p>', '')
  end

  # Строим из body меню, заголовки текста body делаем якорями
  def render_body_and_menu text
    text = text.to_s

    doc = ::Nokogiri.HTML(text)

    _menu = []
    doc.css('h2, h3, h4').each do |el|
      # из текста удаляем всё, кроме букв, цифр, пробела и "-". Меняем " " на "-"
      anchor = 'HH-' + el.text.gsub(/[^[[:alnum:]]\s\-]/, '').gsub(' ', '-')
      el['id'] = anchor

      _menu.push([el.name, anchor, el.text])
    end

    {
      # nokogiri добавляем html, body, которые нам не нужны
      text: doc.at_css('body').inner_html.gsub("\n", ""),
      menu: _menu,
    }
  end

  # ищем сноски в body, делаем якоря
  def render_body_footnotes text
    # мы будем считать ссылкой только ту цифру после слова и какого-то одного любого символа,
    # которая соответствует порядку, начиная с 1:
    i = 1
    # НЕ_ЦИФРА? СКОЛЬКО-ТО-ЦИФР НЕ_ЦИФРА?
    text =
    text.to_s.gsub(/(?<=[^\s])(\[)?(\d+)(\])?(?=[^>])/i) do |match|
      # $1 - квадратная скобка [
      # $2 - номер сноски
      # $3 - закрывающая скобка ]
      if $2.to_i == i
        # если встреченная цифра соответствует порядку, то делаем ссылку
        s = "<sup>#{$1}<a id='cite_ref-#{i}' class='foot-ref' href='#cite_note-#{i}'>#{i}</a>#{$3}</sup>"
        i+=1
        s
      else
        # иначе ничего не меняем
        match
      end
    end

    text
  end

  # продолжение render_body_footnotes
  # теперь делаем обратные ссылки из references к прежнему месту в тексте
  def render_references_footnotes text
    text = text.to_s

    return '' if text.blank?

    doc = ::Nokogiri.HTML(text)

    ol = doc.css('ol').first
    if ol
      i = 1
      ol.css('li').each do |li|
        par = li.css('p').first
        if par
          # в начале каждого элемента ставим символ-ссылку для возвращения назад
          par['id'] = "cite_note-#{i}"
          back_link = "<a class='foot-note' href='#cite_ref-#{i}'>↑</a>"
          par.inner_html = back_link + ' ' + par.inner_html
        end
        i+=1
      end
    end

    # nokogiri добавляем html, body, которые нам не нужны
    doc.at_css('body').inner_html.gsub("\n", "")
  end

  def remove_footnote_links text
    text = text.to_s

    return '' if text.blank?

    doc = ::Nokogiri.HTML(text)

    # Находим все ссылки, у которых href начинается с "cite_note"
    links_footnote = doc.css("a[href^='#cite_note']")
    # links_back = doc.css("a[href^='#cite_ref']")

    # Удаляем их из документа ссылки
    links_footnote.each { |l| l.replace(l.content) }
    # links_back.each { |l| l.replace(l.content) }

    # nokogiri добавляем html, body, которые нам не нужны
    doc.at_css('body').inner_html.gsub("\n", "")
  end

  private

  # уведомить чат:
  def chat_notify_create
    ::TelegramBot::Notifiers.page_create(u: self.user, pg: self)
  end
end

require 'nokogiri'
# Page.create_indexes

class Page < ApplicationMongoRecord
  ALLOW_TAGS = %w(
    ul ol li h1 h2 h3 h4 blockquote strong b i em strike sup s u hr p a mark
    img code table tbody colgroup tr td th
  )
  ALLOW_ATTRS = %w(id href class start src loading)

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

  mount_uploader :cover, CoverUploader

  attr_accessor :tags_str

  # Тип страницы (для писания и тд)
  field :pt,         as: :page_type, type: String, default: 1
  field :is_bbx,     as: :is_bibleox, type: Boolean, default: false # текст-перевод подготовлен нами?
  field :is_mi,      as: :is_menu_icons, type: Boolean, default: false # показывать ли мини-иконки рядом с пунктами меню
  field :is_pub,     as: :is_published, type: Boolean, default: false
  field :is_del,     as: :is_deleted, type: Boolean
  field :is_srch,    as: :is_search, type: Boolean, default: true
  field :is_sh_p,    as: :is_show_parent, type: Boolean, default: true
  field :e_md,       as: :edit_mode, type: Integer, default: 1
  # автор
  field :u_id,       as: :user_id, type: BSON::ObjectId
  # ids редакторов
  field :editors, type: Array
  field :links,   type: Array
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
  # текст статьи (для поиска)
  field :bds,        as: :body_search, type: Array
  # текст статьи (для показа пользователю)
  field :bdr,        as: :body_rendered, type: String
  # текст статьи с разбивкой на стихи
  field :vrs,        as: :verses, type: Array
  # ссылки и заметки (для редактирования)
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
  index({ title: 1},                      { background: true })
  index({path_low: 1},      { unique: true, background: true })
  index({group_lang_id: 1},               { background: true })
  index({user_id: 1},                     { background: true })
  index({redirect_from: 1}, { sparse: true, background: true })
  # для списка последний статей в админке
  index({ updated_at: -1},                { background: true })
  # для поиска картинок для пунктов Menu на страницах типа "Труды святых отцов"
  index({ lg: 1, path: 1},                { background: true })
  # полнотекстовый поиск по названию
  index({ title: 'text' }, { default_language: 'none', language_override: 'lang' })

  # почему-то dependent: :destroy не работает
  has_many :merge_requests, foreign_key: 'p_id', primary_key: 'id', dependent: :destroy
  belongs_to :user, foreign_key: 'u_id', primary_key: 'id'

  # Связь с родителем (использует p_id)
  belongs_to :parent,
             class_name: 'Page',
             foreign_key: :p_id,
             optional: true,
             inverse_of: :children
  # Обратная связь на дочерние страницы
  has_many :children,
           class_name: 'Page',
           foreign_key: :p_id,
           inverse_of: :parent

  scope :published, -> { where(is_published: true) }
  scope :deleted, -> { where(is_deleted: true) }

  before_validation :normalize_attributes

  validates :page_type, :title, :lang, :path, presence: true

  after_create :chat_notify_create
  before_update :update_menus_params

  # Получить комментарии к библейским стихам
  def self.comments_for_verses(verses)
    lang = ::BIB_LANG_TO_LOCALE[verses.first&.lang]
    paths = verses.map { |v| "#{lang}-#{v.a}" }
    self.where(:path_low.in => paths)
  end

  # Если это статья-комментарий на библейский стих, то надо собрать ссылку на стих
  def link_to_bible_verse
    # "ru-vtor:1:2" -> ["ru", "vtor:1:2"]
    lang, addr = self.path_low.split('-')
    # "vtor:1:2" -> ["vtor", "1", "2"]
    book_code, chapter, line = addr.split(':')
    # -> "mf/1/#L2"
    "#{book_code}/#{chapter}/#L#{line}"
  end

  # у статьи есть автор и редакторы
  # тут добавляем редактора
  def add_editor _user
    return self.editors.to_a if _user.id == self.user_id
    # добавляем user_id к текущему списку, если его там ещё нет,
    # а потом убираем от туда автора статьи (вдруг случайно попал)
    self.editors = (self.editors.to_a | [_user.id]) - [self.user_id]
  end

  # просто текст
  def is_page_simple?; self.page_type.to_i == 1; end
  # книга
  def is_page_book?; self.page_type.to_i == 2; end
  # комментарий на библейский стих
  def is_page_bib_comment?; self.page_type.to_i == 3; end
  # страница с меню
  def is_page_menu?; self.page_type.to_i == 4; end
  # страница с разбивкой на стихи
  def is_page_verses?; self.page_type.to_i == 5; end

  def self.fulltext_search(term, lang: nil)
    query = where(:$text => { :$search => term })
    query = query.where(lang: lang) if lang
    query.with_score.order_by(_text_score: :desc)
  end

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
    random_str = generate_string(4)
    clean_path = self.title.to_s.gsub(/\s+/, '_').gsub(/[^[[:alnum:]]_]/, '')
    "#{random_str}_#{clean_path}"
  end

  def normalize_attributes
    self.title = self.title.to_s.strip.gsub(/[\t\s\n\r]+/, ' ')
    self.meta_desc = self.meta_desc.to_s.strip.gsub(/[\t\s\n\r]+/, ' ')

    # Доработки, если статья — комментарий на библейский стих
    if self.path.blank? && self.is_page_bib_comment?
      # 'Быт. 1:14' -> '/zah/1/#L6'
      self.path = ::AddressConverter.human_to_link(self.title).to_s
      # '/zah/1/#L1,2-3,8' -> 'zah:1:6'
      self.path = self.path.gsub('/#L', ':').gsub('/', ':')[1..-1]
      # 'zah:1:6' -> 'ru-zah:1:6'
      self.path = "#{self.lang}-#{self.path}"
      # ещё title надо обязательно валидировать, генерировать ошибку, если локализация стиха не совпадает с I18n.t
    else
      self.path = self.path.to_s.strip.gsub(/[\t\s\n\r]+/, '_').presence || generate_path()
    end

    self.path_low = self.path.downcase
    if self.path_low_changed?
      self.redirect_from = self.path_low_was
    end

    # раз изменился title, значит изменилась превьюшка
    # а если изменился путь, значит изменилось имя картинки
    if self.title_changed?
      self.generate_img()
    end

    self.page_type = self.page_type.to_i

    self.edit_mode = self.edit_mode.to_i

    self.tags = self.tags_str.to_s.split(',').map(&:strip) if self.tags_str.present?
    self.lang = self.lang.to_s.strip.presence if self.lang.present?
    self.group_lang_id = self.group_lang_id || BSON::ObjectId.new

    if self.references_changed?
      self.references = self.class.safe_html(self.references).strip
      self.references_rendered = render_references_footnotes(self.references)
    end

    # Удаляем пдф-версию страницы, если изменился заголовок или текст страницы
    # if self.title_changed? || self.body_changed?
    #   ::PdfGenerator.page_pdf_remove(self)
    # end

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

      # найти источники под цитатами
      self.body_rendered = render_body_quotes_sources(self.body_rendered)

      # добавляем картинкам параметр отложенной загрузки: loading='lazy'
      self.body_rendered = add_lazy_to_img_tags(self.body_rendered)

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

    # Заполняем поле для поиска по тексту статьи (там должден остаться только текст, без тэгов)
    #
    # вручную запустить так:
    # # sanitizer=::Rails::Html::SafeListSanitizer.new; Page.each {|p| p.body_search = sanitizer.sanitize(p.body_rendered.to_s.gsub(/<\/(h|p)[0-9]?>/, '.'), tags: []).split(/\s?\.+\s?/); p.save }
    if self.body_rendered_changed?
      # заменяем тэги <p> и <h1,2,3> <blockquote> на пробел (иначе слова сливаются на этих тэгах, если тэги убрать)
      simple_text = self.body_rendered.to_s.gsub(/<\/(h|p|blockquote)[0-9]?>/, '.')
      # убираем из получившихся строк все html-тэги
      simple_text = sanitizer.sanitize(simple_text.to_s, tags: [])
      # разбиваем по предложениям и храним в массиве (чтобы легче было искать в рамках предложения)
      self.body_search = sanitizer.sanitize(simple_text).split(/\s?\.+\s?/).reject(&:blank?)
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
      attributes: ALLOW_ATTRS,
    ).gsub('<p></p>', '')
  end

  # Строим из body меню, заголовки текста body делаем якорями
  def render_body_and_menu text
    text = text.to_s
    doc = ::Nokogiri.HTML(text)

    # счётчик индексов для повторяющихся заголовков
    counters = Hash.new(0)

    _menu = []
    doc.css('h2, h3, h4').each do |el|
      # Удаляем теги strong из текста перед обработкой
      el.css('strong').each { |e| e.replace(e.content) }
      # из текста удаляем всё, кроме букв, цифр, пробела и "-". Меняем " " на "-"
      title = el.text.gsub(/[^[[:alnum:]]\s\-]/, '').gsub(' ', '-')
      # добываем порядковый номер повторяющегося заголовка
      idx = (counters[title] += 1)
      # если такой заголовок встречается первый раз - номер не указываем
      idx = nil if idx == 1
      anchor = "HH#{idx}-#{title}"
      el['id'] = anchor
      el['name'] = anchor

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
    # Для поисков нельзя допускать, чтобы в документе были элементы с одинаковым id,
    # поэтому для повторяющихся сносок, добавляем индекс, чтобы id отличались.
    indexes = Hash.new(0)

    # более точное нахождение сносок:
    # (?<=[[[:alpha:]]»\)\]\"])(\[)(\d+)(\])(?=[^>])
    #
    # Сейчас используем простой способ:
    # Цифра в квадратных скобках: [1]
    text =
    text.to_s.gsub(/(\[)(\d+)(\])/i) do |match|
      # который раз встречается номер такой сноски?
      i = (indexes[$2] += 1)
      # какой индекс мы добавим к id? Если первая сноска, то индекс не добавляем
      ix = (i == 1) ? '' : "-#{i}"
      # $1 - квадратная скобка [
      # $2 - номер сноски
      # $3 - закрывающая скобка ]
      "<sup class='foot-ref'><a id='cite_ref-#{$2}#{ix}' href='#cite_note-#{$2}'>#{$1}#{$2}#{$3}</a></sup>"
    end

    text
  end

  # находим источники под цитатами:
  # ищем под blockquote параграфы, в которых на первом месте стоит три элемента:
  # - (
  # - ссылка
  # - )
  def render_body_quotes_sources(text)
    text = text.to_s
    doc = ::Nokogiri.HTML(text)

    doc.css('blockquote + p').each do |par|
      is_ch1_ok = par.children[0]&.text? && par.children[0].text.strip == '('
      is_ch2_ok = par.children[1]&.name == 'a'
      is_ch3_ok = par.children[2]&.text? && par.children[2].text.strip[0] == ')'

      # Если в найенном параграфе есть только тэги a, то добавить параграфу класс source-link
      if is_ch1_ok && is_ch2_ok && is_ch3_ok
        par['class'] = 'source-link'
      end
    end

    doc.at_css('body').inner_html.gsub("\n", "")
  end

  # продолжение render_body_footnotes
  # теперь делаем обратные ссылки из references к прежнему месту в тексте
  def render_references_footnotes text
    text = text.to_s

    return '' if text.blank?

    doc = ::Nokogiri.HTML(text)

    ol = doc.css('ol').first
    if ol
      # указано начальная цифра списка?
      i = ol['start'].present? ? ol['start'].to_i : 1
      ol.css('li').each do |li|
        par = li.css('p').first
        if par
          # в начале каждого элемента ставим символ-ссылку для возвращения назад
          par['id'] = "cite_note-#{i}"
          back_link = "<a class='foot-note' href='#cite_ref-#{i}'>↑ </a>"
          par.inner_html = back_link + par.inner_html
        end
        i+=1
      end
    end

    # nokogiri убираем html, body, которые нам не нужны
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

    # nokogiri убираем html, body, которые нам не нужны
    doc.at_css('body').inner_html.gsub("\n", "")
  end

  # IN:
  # "<img src='a'>"
  # OUT:
  # "<img src='a' loading='lazy'>
  def add_lazy_to_img_tags html_content
    doc = Nokogiri::HTML(html_content)
    doc.css('img').each do |img|
      unless img['loading']
        img['loading'] = 'lazy'
      end
    end

    # nokogiri убираем html, body, которые нам не нужны
    doc.at_css('body').inner_html.gsub("\n", "")
  end

  # Ссылка на превьюшку страницы, для использования в html-meta
  # TODO: Перед удалением page, обязательно удали и картинку
  def img_preview_file_path
    page_img_path = "/s/page_previews/#{self.id.to_s}.jpeg"
    if ::File.exist?("public/#{page_img_path}")
      # Или автоматически сгенерированная картинка (название статьи на зелёном фоне)
      page_img_path
    else
      # Или логотип сайта
      "/favicons/bibleox-for-social-#{ ::I18n.locale == :ru ? 'ru' : 'en' }.png"
    end
  end

  def generate_img
    ::ImgTextWrap.page_generate_img(self)
  end

  def pdf_path
    "s/page_pdfs/#{self.id}.pdf"
  end

  def pdf_exists?
    full_path = Rails.root.join('public', pdf_path)
    File.exist?(full_path)
  end

  def remove_pdf!
    if pdf_exists?
      full_path = Rails.root.join('public', pdf_path)
      ::File.delete(full_path)
    end
  end

  private

  # уведомить чат:
  def chat_notify_create
    ::TelegramBot::Notifiers.page_create(u: self.user, pg: self)
  end

  # Запускается в колбэке:
  # update_menus_params
  #
  # Вручную запускать:
  # Page.each {|p| p.send(:update_menus_params, is_force: true) }
  def update_menus_params(is_force: false)
    # Если тело статьи меньше 100 символов, то считаем его пустым (какая-то заглушка написана)
    is_body_was_empty = self.body_was.to_s.length < 40
    is_body_empty = self.body.to_s.length < 40

    # если текст остался коротким, или наоборот остался длинным, то ничего не делаем,
    # а вот если состояние изменилось, то надо в менюшка обновить состояние страницы
    return if (is_body_was_empty == is_body_empty) && is_force != true

    # обновляем параметры в связанных меню
    ::Menu.where(path: self.path).each do |m|
      # перед стираением адреса в меню, надо убедиться, что мы работаем в той же языковой области.
      # делаем это, сравнивая язык страницы с отрисованым меню, и удаляемой страницы:
      _page = Page.where(id: m.page_id).only(:id, :title, :lang).first
      if _page&.lang == self.lang
        m.update(is_empty: is_body_empty)
      end
    end
  end
end

require_relative '../../lib/tools/string_utils/date_to_int'

class Page < ApplicationRecord
  self.table_name = 'pages'

  include Paragraphs
  include Permissions
  include Files

  mount_uploader :cover, CoverUploader

  # period_start
  # period_end
  # is_past

  ALLOW_TAGS = %w(
    ul ol li h1 h2 h3 h4 blockquote strong b i em strike sup s u hr p a mark
    img code table tbody colgroup tr td th
    ruby rp rt small
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

  # === Ассоциации ===
  belongs_to :user, optional: true
  belongs_to :parent, class_name: 'Page', optional: true, inverse_of: :children
  # For preload
  belongs_to :parent_for_preview, -> {
    select(:id, :h_id, :title, :cover, :parent_id, :path)
  }, class_name: 'Page', optional: true, foreign_key: :parent_id
  has_many :children, class_name: 'Page', foreign_key: :parent_id, inverse_of: :parent
  has_many :bible_references, dependent: :destroy

  # === Валидации ===
  validates :page_type, :title, :lang, :path, presence: true

  # === Скоупы ===
  scope :published, -> { where(is_published: true) }
  scope :deleted, -> { where(is_deleted: true) }

  before_validation :normalize_attributes

  before_update :update_menus_params
  before_save :calc_date_int, if: -> { period_start_changed? || period_end_changed? }
  # Карта цитирования: ссылки на Писание ищем только в трудах святых отцов (is_past)
  after_commit :sync_bible_references, on: %i[create update], if: :bible_references_stale?
  # after_save :notify_search_engines

  # Разметка текста — в Page::HtmlRenderer
  def self.safe_html(html_text)
    ::Page::HtmlRenderer.safe_html(html_text)
  end

  def notify_search_engines
    if Rails.env.production?
      ::IndexNowService.notify_about_page(self)
    end
  end

  # Получить комментарии к библейским стихам
  def self.comments_for_verses(verses)
    lang = ::BIB_LANG_TO_LOCALE[verses.first&.lang]
    paths = verses.map { |v| "#{lang}-#{v.address}" }
    self.where(path_low: paths)
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

  def is_page_simple?; self.page_type.to_i == 1; end
  # книга
  def is_page_book?; self.page_type.to_i == 2; end
  # комментарий на библейский стих
  def is_page_bib_comment?; self.page_type.to_i == 3; end
  # страница с меню
  def is_page_menu?; self.page_type.to_i == 4; end
  # страница с разбивкой на стихи
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

  # Иконки и счётчики посещений для пунктов меню страницы-списка: {path => {icon:, visits:}}.
  # Тяжёлый запрос (около 300 мс даже с индексом), поэтому кэшируем.
  def menus_info
    ::Rails.cache.fetch("pg_m_inf_#{id}", expires_in: 24.hours) do
      pages = ::Page.where(lang: lang, path: ::Menu.where(page_id: id).pluck(:path)).select(:id, :h_id, :path, :cover).to_a
      if pages.any?
        visits = ::PageVisits.visits(pages.map { |p| p.id.to_s })
        pages.to_h do |p|
          info = { visits: visits[p.id.to_s] }
          info[:icon] = p.cover.micro.url if is_menu_icons
          [p.path, info]
        end
      end
    end
  end

  def generate_string(cnt = 8)
    (('A'..'Z').to_a + ('a'..'z').to_a + (0..9).to_a).sample(cnt).join
  end

  def generate_path
    random_str = generate_string(4)
    clean_path = self.title.to_s.gsub(/\s+/, '_').gsub(/[^[[:alnum:]]_]/, '')
    "#{random_str}_#{clean_path}"
  end

  def is_body_empty?
    body.to_s.length < 40
  end

  private

  def normalize_attributes
    self.title = self.title.to_s.strip.gsub(/[\t\s\n\r]+/, ' ')
    self.meta_desc = self.meta_desc.to_s.strip.gsub(/[\t\s\n\r]+/, ' ')

    normalize_path

    # раз изменился title, значит изменилась превьюшка
    # а если изменился путь, значит изменилось имя картинки
    self.generate_img() if self.title_changed?

    self.page_type = self.page_type.to_i
    self.edit_mode = self.edit_mode.to_i

    self.lang = self.lang.to_s.strip.presence if self.lang.present?
    # из формы админки приходит пустая строка, а она не должна объединять страницы в одну группу переводов
    self.group_lang_id = self.group_lang_id.presence || generate_string(10)

    render_references if self.references_changed?
    render_body if self.body_changed?
  end

  def normalize_path
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
    self.redirect_from = self.path_low_was if self.path_low_changed?
  end

  def render_references
    self.references, self.references_rendered = ::Page::HtmlRenderer.render_references(self.references)
  end

  # body редактируется в админке, а читателю показываем body_rendered
  def render_body
    result = ::Page::HtmlRenderer.render_body(self.body)
    self.body = result.body
    self.body_rendered = result.rendered
    self.body_menu = result.menu
  end

  # Запускается в колбэке:
  # update_menus_params
  #
  # Вручную запускать:
  # Page.each {|p| p.send(:update_menus_params, is_force: true) }
  def update_menus_params(is_force: false)
    # Если тело статьи меньше 100 символов, то считаем его пустым (какая-то заглушка написана)
    is_body_was_empty = self.body_was.to_s.length < 40
    is_body_empty = self.is_body_empty?

    # если текст остался коротким, или наоборот остался длинным, то ничего не делаем,
    # а вот если состояние изменилось, то надо в менюшка обновить состояние страницы
    return if (is_body_was_empty == is_body_empty) && is_force != true

    # обновляем параметры в связанных меню
    ::Menu.where(path: self.path).each do |m|
      # перед стираением адреса в меню, надо убедиться, что мы работаем в той же языковой области.
      # делаем это, сравнивая язык страницы с отрисованым меню, и удаляемой страницы:
      _page = Page.where(id: m.page_id).select(:id, :title, :lang).first
      if _page&.lang == self.lang
        m.update(is_empty: is_body_empty)
      end
    end
  end

  def bible_references_stale?
    saved_change_to_body? || saved_change_to_is_past? || saved_change_to_is_published? || saved_change_to_is_deleted?
  end

  def sync_bible_references
    # без труда в is_past и без ссылок в БД делать нечего
    return if !is_past && !bible_references.exists?
    ::BibleCitationsJob.perform_later(id)
  end

  def calc_date_int
    self.date_start_int = ::Tools::StringUtils::DateToInt.call(period_start) if period_start.present?
    self.date_end_int = ::Tools::StringUtils::DateToInt.call(period_end) if period_end.present?
  end
end

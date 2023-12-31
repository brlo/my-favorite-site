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
  field :pt, as: :page_type, type: String
  field :pub, as: :published, type: Boolean
  # основной заголовок
  field :title, type: String
  # годы жизни, например
  field :ts, as: :title_sub, type: String
  # meta-описание (через запятую ключевые слова)
  field :meta, as: :meta_desc, type: String
  # path
  field :path, type: String
  field :path_low, type: String
  field :path_p,     as: :parent_id, type: String
  field :n_id,       as: :next_id, type: String
  field :n_t,        as: :next_title, type: String
  field :pr_id,      as: :prev_id, type: String
  field :pr_t,       as: :prev_title, type: String
  # старый путь к статье, с которого надо редиректить на текущий path
  field :r_from,     as: :redirect_from, type: String
  # аудио-файл
  field :au,         as: :audio, type: String
  # язык
  field :lg,         as: :lang, type: String
  # языковой идентификатор страницы для поиска таких же страниц на другом языке
  field :gli,        as: :group_lang_id, type: String
  # текст статьи
  field :bd,         as: :body, type: String
  # текст статьи
  field :bd_arr,     as: :body_as_array, type: String
  # ссылки и заметки
  field :rfs,        as: :references, type: String
  # id темы
  field :tags, type: Array
  # приоритетность статьи
  field :prior,      as: :priority, type: Integer
  # время создания можно получать из _id во так: id.generation_time
  field :c_at,       as: :created_at, type: DateTime, default: ->{ DateTime.now.utc.round }
  field :u_at,       as: :updated_at, type: DateTime, default: ->{ DateTime.now.utc.round }

  # rake db:mongoid:create_indexes
  # rake db:mongoid:remove_indexes
  # rake db:mongoid:remove_undefined_indexes
  # для поиска в нужной книге
  index({path_low: 1},      { unique: true, background: true })
  index({group_lang_id: 1},               { background: true })

  before_validation :normalize_attributes
  validates :page_type, :title, :lang, :path, presence: true

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

  def normalize_attributes
    self.title = self.title.to_s.strip
    self.meta_desc = self.meta_desc.to_s.strip
    self.path = self.path.to_s.strip
    self.path_low = self.path.downcase
    self.page_type = self.page_type.to_i

    # page_type:
    # 1 - статья
    # 2 - книга
    # 3 - апология на стих Библии
    if self.path.blank? && self.page_type == 3
      # 'Быт. 1:14' -> '/zah/1/#L6'
      self.path = ::AddressConverter.human_to_link('Быт. 1:14').to_s
      # '/zah/1/#L1,2-3,8' -> 'zah:1:6'
      self.path = self.path.gsub('/#L', ':').gsub('/', ':')[1..-1]
    end

    self.next_id = self.next_id.to_s.strip if self.next_id
    self.next_title = self.next_title.to_s.strip if self.next_title
    self.prev_id = self.prev_id.to_s.strip if self.prev_id
    self.prev_title = self.prev_title.to_s.strip if self.prev_title
    self.tags = self.tags_str.to_s.split(',').map(&:strip) if self.tags_str.present?
    self.lang = self.lang.to_s.strip.presence if self.lang.present?
    self.group_lang_id = self.group_lang_id.to_s.strip if self.group_lang_id.present?

    self.body = self.body.to_s.strip
    self.references = self.references.to_s.strip if self.references.present?

    # избавяемся от лишних в тэгов
    self.body = sanitizer.sanitize(
      self.body,
      tags: %w(div ul ol li h1 h2 h3 blockquote b i em strike s u hr br p a mark img code)
    )
    self.references = sanitizer.sanitize(
      self.references,
      tags: %w(div ul ol li h1 h2 h3 blockquote b i em strike s u hr br p a mark img code)
    )

    # Заменяем неразрывные пробелы (&nbsp;) на обычные. Иначе строки не рвутся, выглядит очень странно
    # приходят эти пробелы, походу, через редактор Pell. В базе выглядит уже не как &nbsp;, а как обычный пробел,
    # поэтому сразу и не распознаешь, а вот в VSCode он выделяется жёлтым прямоугольником.
    self.body = self.body.to_s.gsub(' ', ' ')
    self.body = self.body.to_s.gsub('&nbsp;', ' ')
    self.references = self.references.gsub(' ', ' ') if self.references.present?
    self.references = self.references.gsub('&nbsp;', ' ') if self.references.present?

    self.u_at = DateTime.now.utc.round
  end
end

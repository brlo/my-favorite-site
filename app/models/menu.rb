class Menu < ApplicationRecord
  self.table_name = 'menus'

  before_validation :normalize_attributes
  validates :page_id, :title, presence: true

  # достаёт только ближайших детей, но не внуков и тд.
  def childs
    self.class.where(parent_id: self.id)
  end

  def normalize_attributes
    self.title = self.title.to_s.strip
    self.path = self.path.to_s.strip if self.path.present?
    self.priority = self.priority.to_i
  end

  def attrs_for_render
    {
      id: self.id,
      parent_id: self.parent_id,
      page_id: self.page_id,
      title: self.title,
      path: self.path,
      priority: self.priority,
      is_gold: self.is_gold,
      is_empty: self.is_empty,
      created_at: self.created_at&.strftime("%Y-%m-%d %H:%M:%S"),
      updated_at: self.updated_at&.strftime("%Y-%m-%d %H:%M:%S"),
    }
  end

  # Пункты меню страницы, проиндексированные для быстрого доступа:
  #   by_id           - {id => пункт}
  #   by_path         - {path => пункт}
  #   linked_children - {id родителя => дочерние пункты со ссылкой, по приоритету}
  Index = Struct.new(:by_id, :by_path, :linked_children, keyword_init: true)

  def self.index_for(page_id)
    by_id = {}
    by_path = {}
    linked_children = ::Hash.new([].freeze)

    where(page_id: page_id).each do |menu|
      by_id[menu.id] = menu
      by_path[menu.path] = menu
      # родители, имеющие детей с path
      linked_children[menu.parent_id] += [menu] if menu.path.present? && menu.parent_id.present?
    end
    linked_children.transform_values! { |group| group.sort_by { |m| m.priority.to_i } }

    Index.new(by_id: by_id, by_path: by_path, linked_children: linked_children)
  end

  def self.tree(page_id)
    records = self.where(page_id: page_id).to_a
  end

  def self.subpages_ids_of_page(page)
    # если у страницы нет родителя, то она сама и есть родитель, надо просто отдать все её менюшки
    if page.page_type.to_i == ::Page::PAGE_TYPES['список']
      return subpages_ids_through_menus(page)
    end

    # РОДИТЕЛЬ: и всё, что мы можем построить, имея родителя
    return [] if page.parent_id.blank?
    parent_page = ::Page.select(:id, :h_id, :parent_id, :title, :path, :page_type).find_by!(id: page.parent_id)

    # элементы меню родительской страницы
    index = index_for(parent_page.id)
    # пункт этой страницы в меню родителя; все его потомки — подстраницы
    page_item = index.by_path[page.path]
    return [] unless page_item

    menus = collect_all_children(index.linked_children, page_item.id)

    sub_pages_paths = menus.pluck(:path).compact
    ::Page.where(path_low: sub_pages_paths.map(&:downcase), lang: page.lang).ids
  end

  # Страницы из меню страницы, потом из меню этих страниц и ещё раз (всего три уровня вложенности)
  def self.subpages_ids_through_menus(page, levels: 3)
    all_ids = []
    current_ids = [page.id]

    levels.times do
      paths = where(page_id: current_ids).pluck(:path).compact
      break if paths.empty?

      current_ids = ::Page.where(path_low: paths.map(&:downcase), lang: page.lang).ids
      break if current_ids.empty?

      all_ids += current_ids
    end

    all_ids
  end

  private

  # рекурсивный метод для построения глубокого дерева потомков в одном (одноуровневом) массиве
  def self.collect_all_children(parent_ids_with_links, parent_id)
    # Начинаем с непосредственных детей
    children = parent_ids_with_links[parent_id] || []

    # Рекурсивно добавляем детей детей
    children.each do |child|
      children += collect_all_children(parent_ids_with_links, child.id)
    end

    children
  end
end











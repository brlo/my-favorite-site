require 'nokogiri'
# Menu.create_indexes

class Menu < ApplicationMongoRecord
  include Mongoid::Document

  # родительский элемент меню
  field :parent_id, type: BSON::ObjectId
  # На какой странице отрисовывается этот список (страница-владелец меню)
  field :page_id, type: BSON::ObjectId
  # основной заголовок
  field :title, type: String
  # path (без него элемент меню будет обычным заголовком, без ссылки)
  field :path, type: String
  # выделяется золотым цветом в списке (привлекает внимание)
  field :is_gold, type: Boolean

  # приоритетность ссылки
  field :priority, type: Integer
  # время создания можно получать из _id во так: id.generation_time
  field :c_at, as: :created_at, type: DateTime, default: ->{ DateTime.now.utc.round }
  field :u_at, as: :updated_at, type: DateTime, default: ->{ DateTime.now.utc.round }

  # rake db:mongoid:create_indexes
  # rake db:mongoid:remove_indexes
  # rake db:mongoid:remove_undefined_indexes
  # для поиска в нужной книге
  # Menu.create_indexes
  # Menu.remove_indexes
  # Menu.remove_undefined_indexes
  index({page_id: 1}, {background: true})

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

    self.u_at = DateTime.now.utc.round
  end

  def attrs_for_render
    {
      id: self.id.to_s,
      parent_id: self.parent_id.to_s,
      page_id: self.page_id.to_s,
      title: self.title,
      path: self.path,
      priority: self.priority,
      is_gold: self.is_gold,
      created_at: self.c_at&.strftime("%Y-%m-%d %H:%M:%S"),
      updated_at: self.u_at&.strftime("%Y-%m-%d %H:%M:%S"),
    }
  end

  def self.tree(page_id)
    records = self.where(page_id: page_id).to_a
  end

  def self.subpages_of_page(page, limit: 3000)
    # если у страницы нет родителя, то она сама и есть родитель, надо просто отдать все её менюшки
    if page.page_type.to_i == ::Page::PAGE_TYPES['список']
      # 1. Достаём все страницы из меню текущей страницы
      menus = ::Menu.where(page_id: page.id).to_a.compact
      if menus.any?
        sub_pages_paths = menus.pluck(:path).compact
        if sub_pages_paths.any?
          sub_pages_1lvl = ::Page.where(:path_low.in => sub_pages_paths.map(&:downcase), lang: page.lang).limit(count).to_a
        end
      end

      # 2. Достаём все страницы из меню полученных страниц (если у них есть меню)
      if sub_pages_1lvl&.any?
        menus = ::Menu.where(:page_id.in => sub_pages_1lvl.pluck(:id)).to_a.compact
        if menus.any?
          sub_pages_paths = menus.pluck(:path).compact
          if sub_pages_paths.any?
            sub_pages_2lvl = ::Page.where(:path_low.in => sub_pages_paths.map(&:downcase), lang: page.lang).limit(count).to_a
          end
        end
      end

      # 3. Достаём все страницы из меню дважды вложенных страниц
      if sub_pages_2lvl&.any?
        menus = ::Menu.where(:page_id.in => sub_pages_2lvl.pluck(:id)).to_a.compact
        if menus.any?
          sub_pages_paths = menus.pluck(:path).compact
          if sub_pages_paths.any?
            sub_pages_3lvl = ::Page.where(:path_low.in => sub_pages_paths.map(&:downcase), lang: page.lang).limit(count).to_a
          end
        end
      end

      return sub_pages_1lvl.to_a + sub_pages_2lvl.to_a + sub_pages_3lvl.to_a
    end

    # РОДИТЕЛЬ: и всё, что мы можем построить, имея родителя
    parent_page = ::Page.only(:id, :p_id, :title, :path, :page_type).find_by!(id: page.parent_id)

    # =========================================================================
    # сначала добываем все элементы меню родительской страницы,
    # необходимым образом их сортируем и индексируем в разных списках
    # чтобы потом быстро доставать нужные наборы менюшек
    menus = ::Menu.where(page_id: parent_page.id).to_a
    # индекс по id
    menus_by_id = {}
    # индекс по path
    menus_by_path = {}
    # группировка менюшек по родителю (в списке будут только те родители, у которых есть дочерние элементы)
    parent_ids_with_links = ::Hash.new([])

    menus.each do |menu|
      # индексация по ID
      menus_by_id[menu.id] = menu
      # индексация по PATH
      menus_by_path[menu.path] = menu
      # поиск всех parent_id, имеющих детей с path
      if menu.path.present? && menu.parent_id.present?
        parent_ids_with_links[menu.parent_id] += [menu]
      end
    end

    # сортируем
    parent_ids_with_links.each do |p_id, group|
      parent_ids_with_links[p_id] =
      parent_ids_with_links[p_id].sort_by { |m| m.priority.to_i }
    end

    # =========================================================================
    menus = collect_all_children(parent_ids_with_links, page.id)

    sub_pages_paths = menus.pluck(:path).compact
    sub_pages = ::Page.where(:path_low.in => sub_pages_paths.map(&:downcase), lang: lang).limit(count).to_a
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

# Где страница находится в иерархии: родитель, предки для хлебных крошек
# и соседние главы из меню родителя (когда родитель — страница-список).
class PageNavigation
  # Главы: пункт этой страницы в меню, [[название, путь, is_gold], ...] и номер текущей (с 1)
  Chapters = Struct.new(:page_in_menu, :items, :current, keyword_init: true)

  ANCESTOR_COLUMNS = %i[id h_id parent_id title path lang].freeze

  def initialize(page)
    @page = page
  end

  def parent_page
    return unless @page.parent_id
    @parent_page ||= ::Page.select(*ANCESTOR_COLUMNS, :page_type).find_by!(id: @page.parent_id)
  end

  # Предки сверху вниз, до родителя включительно (не больше трёх уровней)
  def ancestors
    return [] unless parent_page

    chain = [parent_page]
    2.times do
      above = chain.first
      break unless above.parent_id
      chain.unshift(::Page.select(*ANCESTOR_COLUMNS).find_by!(id: above.parent_id))
    end
    chain
  end

  # Соседи страницы в меню родителя без пустых пунктов (будем считать, что это главы)
  def chapters
    return unless parent_page && parent_page.page_type.to_i == ::Page::PAGE_TYPES['список']

    index = ::Menu.index_for(parent_page.id)
    page_in_menu = index.by_path[@page.path]
    return unless page_in_menu

    siblings_and_me = index.linked_children[page_in_menu.parent_id].select { |m| m.is_empty != true }
    position = siblings_and_me.index(page_in_menu)

    Chapters.new(
      page_in_menu: page_in_menu,
      items: siblings_and_me.map { |m| [m.title, m.path, m.is_gold] },
      current: position && position + 1,
    )
  end
end

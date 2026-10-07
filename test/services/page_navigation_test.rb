require "test_helper"

class PageNavigationTest < ActiveSupport::TestCase
  test "page without a parent has no ancestors and no chapters" do
    navigation = PageNavigation.new(create_page)
    assert_nil navigation.parent_page
    assert_empty navigation.ancestors
    assert_nil navigation.chapters
  end

  test "ancestors go from the top down to the parent and stop after three levels" do
    root = create_page(title: 'Корень')
    a = create_page(title: 'A', parent_id: root.id)
    b = create_page(title: 'B', parent_id: a.id)
    c = create_page(title: 'C', parent_id: b.id)
    leaf = create_page(title: 'Лист', parent_id: c.id)

    assert_equal %w[A B C], PageNavigation.new(leaf).ancestors.map(&:title)
    assert_equal ['Корень'], PageNavigation.new(a).ancestors.map(&:title)
  end

  test "chapters are the non-empty siblings in the parent list menu, numbered from one" do
    list = create_page(page_type: 4, path: 'nav_list')
    [%w[c1 Первая], %w[c2 Вторая], %w[c3 Третья]].each { |path, _| create_page(path: path, parent_id: list.id) }
    root = Menu.create!(page_id: list.id, title: 'Раздел')
    Menu.create!(page_id: list.id, parent_id: root.id, title: 'Первая', path: 'c1', priority: 2)
    Menu.create!(page_id: list.id, parent_id: root.id, title: 'Вторая', path: 'c2', priority: 1, is_gold: true)
    Menu.create!(page_id: list.id, parent_id: root.id, title: 'Пустая', path: 'c3', priority: 3, is_empty: true)

    chapters = PageNavigation.new(Page.find_by(path: 'c1')).chapters
    assert_equal [['Вторая', 'c2', true], ['Первая', 'c1', false]], chapters.items
    assert_equal 2, chapters.current
    assert_equal 'c1', chapters.page_in_menu.path
  end

  test "no chapters when the parent is not a list or the page is not in its menu" do
    parent = create_page(page_type: 1)
    assert_nil PageNavigation.new(create_page(parent_id: parent.id)).chapters

    list = create_page(page_type: 4)
    assert_nil PageNavigation.new(create_page(parent_id: list.id, path: 'not_in_menu')).chapters
  end
end

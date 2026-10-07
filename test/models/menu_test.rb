require "test_helper"

class MenuTest < ActiveSupport::TestCase
  test "attrs_for_render exposes fields for the frontend" do
    menu = Menu.create!(page_id: create_page.id, title: ' Пункт ', path: ' p ', priority: '3')
    attrs = menu.attrs_for_render
    assert_equal ['Пункт', 'p', 3], attrs.values_at(:title, :path, :priority)
  end

  test "title and page are required" do
    assert_not Menu.new(title: 'x').valid?
    assert_not Menu.new(page_id: 1).valid?
  end

  test "childs returns only direct children" do
    page = create_page
    root = Menu.create!(page_id: page.id, title: 'root')
    child = Menu.create!(page_id: page.id, parent_id: root.id, title: 'child')
    Menu.create!(page_id: page.id, parent_id: child.id, title: 'grandchild')
    assert_equal [child], root.childs.to_a
  end

  test "subpages of a list page are collected through three levels of menus" do
    top = create_page(page_type: 4, path: 'top_list')
    level1 = create_page(page_type: 4, path: 'level1')
    level2 = create_page(page_type: 4, path: 'level2')
    level3 = create_page(path: 'level3')
    Menu.create!(page_id: top.id, title: 'a', path: 'level1')
    Menu.create!(page_id: level1.id, title: 'b', path: 'level2')
    Menu.create!(page_id: level2.id, title: 'c', path: 'level3')

    assert_equal [level1.id, level2.id, level3.id].sort, Menu.subpages_ids_of_page(top).sort
  end

  test "subpages of a list page are limited to its language" do
    top = create_page(page_type: 4, lang: 'ru')
    create_page(path: 'same_path', lang: 'en')
    Menu.create!(page_id: top.id, title: 'a', path: 'same_path')
    assert_empty Menu.subpages_ids_of_page(top)
  end

  test "subpages of an ordinary page come from its position in the parent menu" do
    parent = create_page(page_type: 4, path: 'parent_list')
    page = create_page(parent_id: parent.id, path: 'section')
    leaf = create_page(path: 'leaf_page')
    root = Menu.create!(page_id: parent.id, title: 'root')
    section_item = Menu.create!(page_id: parent.id, parent_id: root.id, title: 'section', path: 'section')
    Menu.create!(page_id: parent.id, parent_id: section_item.id, title: 'leaf', path: 'leaf_page')

    assert_equal [leaf.id], Menu.subpages_ids_of_page(page)
  end

  test "an ordinary page without a parent has no subpages" do
    assert_empty Menu.subpages_ids_of_page(create_page)
  end
end

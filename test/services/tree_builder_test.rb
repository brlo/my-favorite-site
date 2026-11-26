require 'test_helper'

class TreeBuilderTest < ActiveSupport::TestCase
  def tree_for(page)
    items = ::Menu.where(page_id: page.id).to_a.map(&:attrs_for_render)
    ::TreeBuilder.build_tree_from_objects(items)
  end

  test 'без position сохраняется прежний порядок: сначала пункты без подпунктов' do
    page = create_page
    section = ::Menu.create!(page_id: page.id, title: 'Раздел', priority: 0)
    ::Menu.create!(page_id: page.id, title: 'Внутри', parent_id: section.id, priority: 0)
    ::Menu.create!(page_id: page.id, title: 'Статья', priority: 5)

    assert_equal %w[Статья Раздел], tree_for(page).map { _1[:title] }
  end

  test 'явная position даёт свободный порядок: раздел может стоять перед статьёй' do
    page = create_page
    section = ::Menu.create!(page_id: page.id, title: 'Раздел', priority: 0, position: 0)
    ::Menu.create!(page_id: page.id, title: 'Внутри', parent_id: section.id, priority: 0, position: 0)
    ::Menu.create!(page_id: page.id, title: 'Статья', priority: 5, position: 1)

    assert_equal %w[Раздел Статья], tree_for(page).map { _1[:title] }
  end

  test 'порядок сортируется на любой глубине вложенности' do
    page = create_page
    root = ::Menu.create!(page_id: page.id, title: 'Корень', position: 0)
    level1 = ::Menu.create!(page_id: page.id, title: 'Уровень 1', parent_id: root.id, position: 0)
    level2 = ::Menu.create!(page_id: page.id, title: 'Уровень 2', parent_id: level1.id, position: 0)
    ::Menu.create!(page_id: page.id, title: 'Глубоко', parent_id: level2.id, position: 0)
    ::Menu.create!(page_id: page.id, title: 'Глубоко раньше', parent_id: level2.id, position: -1)

    deep = tree_for(page).first[:childs].first[:childs].first[:childs]
    assert_equal ['Глубоко раньше', 'Глубоко'], deep.map { _1[:title] }
  end
end

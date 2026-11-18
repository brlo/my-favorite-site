require "test_helper"

class PagesHelperTest < ActionView::TestCase
  test "only chapter numbers are short table of contents items" do
    assert toc_item_short?('3')
    assert toc_item_short?(' 12 ')
    assert toc_item_short?('150')
    refute toc_item_short?('1000')
    refute toc_item_short?('Пс')
    refute toc_item_short?('IV')
    refute toc_item_short?('序')
    refute toc_item_short?('3а')
    refute toc_item_short?('')
  end

  test "similar materials are parts when every title has no letters" do
    assert similar_materials_part?([['#1', 'one', false], ['2', 'two', false], ['— 3 —', 'three', false]])
    refute similar_materials_part?([['#1', 'one', false], ['Глава 2', 'two', false]])
    refute similar_materials_part?([['IV', 'four', false]])
    refute similar_materials_part?([])
  end
end

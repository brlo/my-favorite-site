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

  test "similar materials are parts when every title starts with the same word and a number" do
    assert similar_materials_part?([['Глава 1', 'one', false], ['Глава 2', 'two', false]])
    assert similar_materials_part?([['Книга — 1', 'one', false], ['Книга — 2', 'two', false]])
    assert similar_materials_part?([['Книга I', 'one', false], ['Книга II', 'two', false], ['Книга III', 'three', false]])
    assert similar_materials_part?([['Liber 7 (1/2)', 'one', false], ['Liber 7 (2/2)', 'two', false]])
    assert similar_materials_part?([['Слово 1-е, о законе', 'one', false], ['Слово 2-е, о молитве', 'two', false]])
    assert similar_materials_part?([['глава 1', 'one', false], ['Глава 2', 'two', false]])

    assert similar_materials_worded_part?([['Глава 1', 'one', false], ['Глава 2', 'two', false]])
    refute similar_materials_worded_part?([['#1', 'one', false], ['2', 'two', false]])
  end

  test "similar materials are not parts when a common word is not followed by a number" do
    refute similar_materials_part?([['Глава первая', 'one', false], ['Глава вторая', 'two', false]])
    refute similar_materials_part?([['The Didache', 'one', false], ['The Life of Paulus', 'two', false]])
    refute similar_materials_part?([['Глава 1', 'one', false], ['Глава вторая', 'two', false]])
    refute similar_materials_part?([['Глава 1', 'one', false], ['Предисловие', 'two', false]])
  end

  test "parts label is shown only when titles have no common word" do
    assert similar_materials_title_needed?([['#1', 'one', false], ['2', 'two', false]])
    assert similar_materials_title_needed?([['Введение', 'one', false], ['Обзор', 'two', false]])
    refute similar_materials_title_needed?([['Глава 1', 'one', false], ['Глава 2', 'two', false]])
    refute similar_materials_title_needed?([['Книга I', 'one', false], ['Книга II', 'two', false]])
  end
end

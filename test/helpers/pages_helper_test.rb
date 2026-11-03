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
end

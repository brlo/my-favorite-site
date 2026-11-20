require "test_helper"

class NewsHelperTest < ActionView::TestCase
  include ApplicationHelper
  test "news_lead_html rewrites anchors to the article and removes duplicate ids" do
    page = create_page(path: 'news_helper', lang: 'ru',
                       body_lead: '<p>См. сноску <a href="#fn1">1</a>.</p><p id="fn1">Текст сноски</p>')

    html = news_lead_html(page)

    assert_includes html, 'href="/ru/ru/w/news_helper#fn1"'
    assert_not_includes html, 'id="fn1"'
    assert_includes html, 'Текст сноски'
  end
end

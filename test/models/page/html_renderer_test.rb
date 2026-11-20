require "test_helper"

class Page::HtmlRendererTest < ActiveSupport::TestCase
  R = Page::HtmlRenderer

  test "safe_html keeps allowed tags and drops the rest" do
    assert_equal '<p>a <b>b</b></p>', R.safe_html('<p>a <b>b</b></p><iframe></iframe>')
    assert_equal '<a href="/x">l</a>', R.safe_html('<a href="/x" onclick="y()">l</a>')
  end

  test "safe_html replaces non-breaking spaces and drops empty paragraphs" do
    assert_equal 'a b c', R.safe_html("a b&nbsp;c")
    assert_equal '<p>x</p>', R.safe_html('<p></p><p>x</p>')
  end

  test "footnote_anchors numbers repeated footnotes" do
    html = R.footnote_anchors('a[1] b[1] c[2]')
    assert_equal 1, html.scan("id='cite_ref-1'").size
    assert_includes html, "id='cite_ref-1-2'"
    assert_includes html, "href='#cite_note-2'"
  end

  test "remove_footnote_links keeps the text of the link" do
    assert_equal '<p>a [1]</p>', R.remove_footnote_links('<p>a <a href="#cite_note-1">[1]</a></p>')
    assert_equal '', R.remove_footnote_links(nil)
  end

  test "menu_and_anchors skips levels other than h2-h4 and strips markup from titles" do
    html, menu = R.menu_and_anchors('<h1>Заглавие</h1><h2><strong>Глава</strong> 1</h2>')
    assert_equal [['h2', 'HH-Глава-1', 'Глава 1']], menu
    assert_includes html, '<h1>Заглавие</h1>'
  end

  test "references_back_links numbers items from the start attribute" do
    html = R.references_back_links('<ol start="5"><li><p>x</p></li></ol>')
    assert_includes html, 'id="cite_note-5"'
    assert_includes html, "href=\"#cite_ref-5\""
    assert_equal '', R.references_back_links('')
  end

  test "lazy_images does not override an explicit loading attribute" do
    html = R.lazy_images('<img src="a"><img src="b" loading="eager">')
    assert_equal 1, html.scan('loading="lazy"').size
    assert_includes html, 'loading="eager"'
  end

  test "render_body returns editor html, reader html and menu" do
    result = R.render_body("<h2>Глава</h2><p>Текст[1]</p>")
    assert_not_includes result.body, 'cite_ref'
    assert_includes result.rendered, 'cite_ref-1'
    assert_equal [['h2', 'HH-Глава', 'Глава']], result.menu
  end

  test "render_body splits off the lead at the cut marker" do
    result = R.render_body('<p>Эпиграф</p><hr class="article-cut"><h2>Глава</h2><p>Текст</p>')
    assert_equal '<p>Эпиграф</p>', result.lead
    assert_not_includes result.rendered, 'Эпиграф'
    assert_includes result.rendered, '<h2 id="HH-Глава"'
    assert_equal [['h2', 'HH-Глава', 'Глава']], result.menu
    # в редакторском html метка остаётся, чтобы её можно было убрать
    assert_includes result.body, '<hr class="article-cut">'
  end

  test "render_body without the cut marker has no lead" do
    result = R.render_body('<p>Эпиграф</p><h2>Глава</h2>')
    assert_nil result.lead
    assert_includes result.rendered, 'Эпиграф'
  end

  test "render_body numbers footnotes across the cut so their ids do not repeat" do
    result = R.render_body('<p>a[1]</p><hr class="article-cut"><p>b[1]</p>')
    assert_includes result.lead, 'cite_ref-1'
    assert_includes result.rendered, 'cite_ref-1-2'
    assert_not_includes result.rendered, 'cite_ref-1"'
  end

  test "split_at_cut moves a block with a nested marker to the rest whole" do
    lead, rest = R.split_at_cut('<p>a</p><blockquote><p>b</p><hr class="article-cut"><p>c</p></blockquote>')
    assert_equal '<p>a</p>', lead
    assert_includes rest, '<p>b</p>'
    assert_includes rest, '<p>c</p>'
    assert_not_includes rest, 'article-cut'
  end

  test "render_references returns sanitized source and rendered html" do
    source, rendered = R.render_references('<ol><li><p>x</p></li></ol><script>1</script>')
    assert_not_includes source, 'script'
    assert_includes rendered, 'cite_note-1'
  end
end

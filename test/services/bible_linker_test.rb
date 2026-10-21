require "test_helper"

class BibleLinkerTest < ActiveSupport::TestCase
  def link(html, lang = 'ru') = BibleLinker.link_html(html, lang)

  test "links a single verse in the Russian Synodal Bible" do
    assert_equal '<p>(<a href="/ru/ru/mf/20#L13">Мф. 20:13</a>)</p>', link('<p>(Мф. 20:13)</p>')
  end

  test "links ranges and lists of verses" do
    assert_includes link('<p>(Мф. 20:13-15)</p>'), 'href="/ru/ru/mf/20#L13-15"'
    assert_includes link('<p>(Мф. 20:13-17,19)</p>'), 'href="/ru/ru/mf/20#L13-17,19"'
    assert_includes link('<p>(Мф. 20:13–15)</p>'), 'href="/ru/ru/mf/20#L13-15"'
  end

  test "understands numbered books" do
    assert_includes link('<p>(1 Кор. 13:4)</p>'), 'href="/ru/ru/1kor/13#L4"'
  end

  test "English articles link to NRSV" do
    assert_includes link('<p>(Matt. 20:13-15)</p>', 'en'), 'href="/en/en-nrsv/mf/20#L13-15"'
    assert_includes link('<p>(1 Thess. 5:17)</p>', 'en'), 'href="/en/en-nrsv/1sol/5#L17"'
    assert_includes link('<p>(Heb. 11:1)</p>', 'en'), 'href="/en/en-nrsv/evr/11#L1"'
  end

  test "Japanese articles link to the Japanese Bible" do
    assert_includes link('<p>（マタ 20:13-15）</p>', 'ja'), 'href="/ja/jp-ni/mf/20#L13-15"'
    assert_includes link('<p>（１コリ13：4）</p>', 'ja'), 'href="/ja/jp-ni/1kor/13#L4"'
  end

  test "does not touch existing links, headings or unknown text" do
    html = '<p><a href="/x">Мф. 20:13</a></p><h2>Ин. 3:16</h2><p>в 10:30 на 5, 3 раза</p>'
    assert_equal html, link(html)
    assert_equal '<p>Ин. 99:1</p>', link('<p>Ин. 99:1</p>')
  end

  test "leaves text of languages without a Bible as is" do
    assert_equal '<p>Мф. 20:13</p>', link('<p>Мф. 20:13</p>', 'fr')
  end

  test "page body_rendered gets the links while body stays clean" do
    result = Page::HtmlRenderer.render_body('<p>См. (Ин. 3:16).</p>', 'ru')
    assert_includes result.rendered, '<a href="/ru/ru/in/3#L16">Ин. 3:16</a>'
    assert_not_includes result.body, '<a'
  end
end

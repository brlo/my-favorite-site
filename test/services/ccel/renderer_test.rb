require "test_helper"

class Ccel::RendererTest < ActiveSupport::TestCase
  def render(inner, **opts)
    xml = %(<ThML><ThML.body><div1 id="w" title="The Work">#{inner}</div1></ThML.body></ThML>)
    Ccel::Renderer.call(Nokogiri::XML(xml).at_xpath('//div1'), **opts)
  end

  def ref(parsed, text = 'x')
    %(<scripRef parsed="#{parsed}" passage="#{text}">#{text}</scripRef>)
  end

  test "subsections become headings and the leading title heading is dropped" do
    r = render(<<~XML)
      <h2>The Work</h2>
      <div2 id="w.i" title="Chapter I.—Beginning."><h3>Chapter I.—Beginning.</h3><p>Text one.</p>
        <div3 id="w.i.i" title="Section 1"><p>Deep.</p></div3>
      </div2>
    XML
    assert_equal '<h2>1. Beginning.</h2><p>Text one.</p><h3>Section 1</h3><p>Deep.</p>', r.body
  end

  test "chapter titles are shortened to arabic numbers" do
    assert_equal '4. Praise of the Ephesians.', Ccel::Renderer.short_title('Chapter IV.—Praise of the Ephesians.')
    assert_equal '12', Ccel::Renderer.short_title('Chap. XII.')
    assert_equal '49. The argument', Ccel::Renderer.short_title('Chapter XLIX. The argument')
    assert_equal '1999', Ccel::Renderer.short_title('Chapter MCMXCIX')
    assert_equal 'Book I.', Ccel::Renderer.short_title('Book I.')
    assert_equal 'Chaplain', Ccel::Renderer.short_title('Chaplain')
  end

  test "a paragraph repeating the section title at its start is dropped" do
    r = render('<div2 id="w.i" title="Canon I."><p><span class="c4">The Work</span></p><p>Canon I.<note n="1"><p>A note.</p></note></p><p>If any one.</p></div2>')
    assert_equal '<h2>Canon I.</h2><p>If any one.</p>', r.body
  end

  test "a title page typed as short paragraphs at the start of the work is dropped" do
    r = render('<p>the homilies of st. john,</p><p>on the</p><p>romans</p><div2 id="w.i" title="Homily I"><p>Text.</p></div2>')
    assert_equal '<h2>Homily I</h2><p>Text.</p>', r.body
  end

  test "a title block ending with a rule line at the start of a section is dropped" do
    r = render('<div2 id="w.i" title="Prologue."><p>The Book of Pastoral Rule</p><p>of</p><p>————————————</p><p>Text.</p></div2>')
    assert_equal '<h2>Prologue.</h2><p>Text.</p>', r.body
  end

  test "short opening lines of a letter are kept" do
    r = render('<div2 id="w.i" title="To Hermogenianus"><p>Letter I.</p><p>(a.d. 386.)</p><p>To Hermogenianus Augustin Sends Greeting.</p></div2>')
    assert_equal '<h2>To Hermogenianus</h2><p>Letter I.</p><p>(a.d. 386.)</p><p>To Hermogenianus Augustin Sends Greeting.</p>', r.body
  end

  test "a short lead paragraph that is not a title page is kept" do
    r = render('<p>From Book II.</p><p>A real fragment of the text.</p>')
    assert_equal '<p>From Book II.</p><p>A real fragment of the text.</p>', r.body
  end

  test "a summary paragraph repeating the chapter title without the number is dropped" do
    r = render('<div2 id="w.i" title="Chapter I. A Bishop teaches."><p>A Bishop teaches.</p><p>1. I think.</p></div2>')
    assert_equal '<h2>1. A Bishop teaches.</h2><p>1. I think.</p>', r.body
  end

  test "scripture references are rewritten from the parsed attribute" do
    r = render("<p>See #{ref('|1Pet|5|1|5|5', '1 Pet. v. 1–5')}, #{ref('|Gen|37|0|0|0')} and #{ref('|Prov|9|14|0|0;|Prov|9|17|0|0')}.</p>")
    assert_equal '<p>See 1 Pet. 5:1–5, Gen. 37 and Prov. 9:14; Prov. 9:17.</p>', r.body
  end

  test "rewritten references are understood by the citation extractor" do
    Ccel::Renderer::BOOK_ABBR.each do |osis, abbr|
      assert BibleCitationExtractor.book_code_for(abbr), "#{osis} -> #{abbr} не распознаётся"
    end
  end

  test "a note with only scripture references is put inline" do
    r = render(%(<p>He said it.<note n="5"><p class="endnote">Comp. #{ref('|Eph|5|2|0|0')}, etc.</p></note> Next.</p>))
    assert_equal '<p>He said it. (comp. Eph. 5:2) Next.</p>', r.body
    assert_empty r.notes
  end

  test "a note with commentary becomes a numbered footnote" do
    r = render(%(<p>One<note n="12"><p>Literally, “before the ages.”</p></note> two<note n="13"><p>#{ref('|Gen|4|3|4|8')}. The writer follows the Septuagint.</p></note>.</p>))
    assert_equal '<p>One[1] two[2].</p>', r.body
    assert_equal ['Literally, “before the ages.”', 'Gen. 4:3–8. The writer follows the Septuagint.'], r.notes
  end

  test "index entries and page breaks are dropped, page range is kept" do
    r = render(%(<pb n="49"/><p><index subject1="X"/>Te<span class="sc">xt</span> <i>here</i>.</p><pb n="50"/>))
    assert_equal '<p>Text <i>here</i>.</p>', r.body
    assert_equal %w[49 50], r.pages
  end

  test "verses become a blockquote" do
    r = render('<verse><l>Line one,</l><l>line two.</l></verse>')
    assert_equal '<blockquote><p>Line one,</p><p>line two.</p></blockquote>', r.body
  end

  test "sections by the editors and translators are skipped" do
    r = render(<<~XML)
      <div2 id="w.i" title="Translator's Introduction."><p>Editor.</p></div2>
      <div2 id="w.ii" title="Preface."><p>Author preface.</p></div2>
      <div2 id="w.iii" title="Elucidations"><p>Coxe.</p></div2>
      <div2 id="w.iv" title="Note by the Edinburgh Translator."><p>Edinburgh.</p></div2>
      <div2 id="w.v" title="Title Page."><p>A SELECT LIBRARY</p></div2>
      <div2 id="w.vi" title="Contents of Christian Doctrine"><p>Book I...</p></div2>
    XML
    assert_equal "<h2>Preface.</h2><p>Author preface.</p>", r.body
  end

  test "sections with titles from skip_titles are skipped" do
    r = render('<div2 id="w.i" title="Introduction."><p>Translator.</p></div2><div2 id="w.ii" title="Argument."><p>Author.</p></div2>',
               skip_titles: ['Introduction'])
    assert_equal '<h2>Argument.</h2><p>Author.</p>', r.body
  end

  test "text after the cut_after marker is dropped up to the end of the section" do
    r = render(<<~XML, cut_after: 'Notes.')
      <div2 id="w.i" title="Canon I."><p>Canon text.</p><p>Notes.</p><p>Balsamon says.</p></div2>
      <div2 id="w.ii" title="Canon II."><p>Second canon.</p></div2>
    XML
    assert_equal '<h2>Canon I.</h2><p>Canon text.</p><h2>Canon II.</h2><p>Second canon.</p>', r.body
  end

  test "sections listed in skip_ids are skipped" do
    r = render('<div2 id="w.i" title="One"><p>1</p></div2><div2 id="w.ii" title="Two"><p>2</p></div2>', skip_ids: ['w.i'])
    assert_equal '<h2>Two</h2><p>2</p>', r.body
  end
end

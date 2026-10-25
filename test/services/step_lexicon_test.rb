require "test_helper"

class StepLexiconTest < ActiveSupport::TestCase
  def convert(html) = StepLexicon.convert_html(html)

  test "parses an entry line and skips the header" do
    line = "G5438\tG5438G =\tG5438G\tφυλακή\tphulakē\tG:N-F\tprison/watch: prison\t <b>φυλακή</b>, -ῆς, ἡ\n"
    row = StepLexicon.parse_line(line)
    assert_equal 'G5438', row[:strong]
    assert_equal ['φυλακή'], row[:forms]
    assert_equal 'phulakē', row[:translit]
    assert_equal 'prison/watch: prison', row[:gloss]

    assert_nil StepLexicon.parse_line("eStrong\tdStrong\tuStrong\tGreek\tTransliteration\tMorph\tGloss\tMeaning\n")
    assert_equal ['α', 'Ἀλφα'], StepLexicon.parse_line("G0001\tG0001G =\tG0001G\tα, Ἀλφα\tAlpha\tG:N-LI\tAlpha\tx")[:forms]
  end

  test "turns Bible references into chapter links without language" do
    assert_equal '<a href="/mf/1#L1">Mat.1:1</a>', convert("<ref='Mat.1.1'>Mat.1:1</ref>")
    assert_equal '<a href="/evr/5#L4">Heb.5:4</a>; <a href="/evr/7#L11">7:11</a>',
                 convert("<ref='Heb.5.4; 7.11'>Heb.5:4, 7:11</ref>")
    assert_equal '<a href="/lk/6#L33,35">Luk.6:33, 35</a>', convert("<ref='Luk.6.33, 35'>Luk.6:33, 35</ref>")
    # в книге одна глава - номер главы не пишут
    assert_equal '<a href="/iud/1#L24">Jude.1:24</a>', convert("<ref='Jude.24'>Jude.24</ref>")
  end

  test "keeps the text of a reference it cannot place" do
    assert_equal 'Xyz.1:1', convert("<ref='Xyz.1.1'>Xyz.1:1</ref>")
    # в Евангелии от Матфея 28 глав
    assert_equal 'Mat.40:1', convert("<ref='Mat.40.1'>Mat.40:1</ref>")
    # непонятный хвост - ведём на первую главу и стих, текст оставляем как был
    assert_equal '<a href="/otkr/1#L20">Rev.1:20-2:1</a>', convert("<ref='Rev.1.20-2:1'>Rev.1:20-2:1</ref>")
    assert_equal '<a href="/1in/1#L5">1Jo.1:5, 3:11 (</a>', convert("<ref='1Jo.1.5, 3:11 ('>1Jo.1:5, 3:11 (</ref>")
  end

  test "turns source tooltips into abbr and cleans LSJ layout markup" do
    html = '<b> φῠλᾰκ-ή</b>, ἡ, <br /> <b>watching,</b> [<a href="javascript:void(0)" title=" 8th c.BC: Ilias  7.371 ">Refs 8th c.BC+</a>]' \
           '<br /><Level2><b>__II</b></Level2> see {ἄγνυμι} <BR />__(a) guard'
    assert_equal '<b> φῠλᾰκ-ή</b>, ἡ, <br> <b>watching,</b> [<abbr title="8th c.BC: Ilias 7.371">Refs 8th c.BC+</abbr>]' \
                 '<br><b>II</b> see ἄγνυμι <br>(a) guard', convert(html)
  end

  test "converted entry survives DictWord sanitizing" do
    word = DictWord.new(dict: 'lsj', word: 'φυλακή',
                        desc: convert("<b>φυλακή</b> [<a href=\"javascript:void(0)\" title=\"Hdt. 1.24\">Refs</a>] <ref='Luk.2.8'>Luk.2:8</ref><br />x"))
    word.validate
    assert_includes word.desc, '<abbr title="Hdt. 1.24">Refs</abbr>'
    assert_includes word.desc, '<a href="/lk/2#L8">Luk.2:8</a>'
    assert_includes word.desc, '<br>'
  end
end

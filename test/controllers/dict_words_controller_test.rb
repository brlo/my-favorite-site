require "test_helper"

class DictWordsControllerTest < ActionDispatch::IntegrationTest
  def create_bib_word(word, lexema, addrs)
    BibWord.create!(word:, lexema:, addrs:, bw_id: SecureRandom.random_number(1_000_000_000), counts: addrs.size)
  end

  setup do
    @logos = create_bib_word('λόγος', 'λόγος', ['in:1:1'])
    create_bib_word('λόγου', 'λόγος', ['mf:5:37', 'in:1:1'])
    create_verse(tr_code: 'gr-ru', book: 'in', book_id: 500, chapter: 1, line: 1, address: 'in:1:1', text: 'Ἐν ἀρχῇ ἦν ὁ λόγος')
    create_verse(tr_code: 'gr-ru', book: 'mf', book_id: 470, chapter: 5, line: 37, address: 'mf:5:37', text: 'ἔστω δὲ ὁ λόγος ὑμῶν')
  end

  test "lexeme page lists every verse with any form of the lexeme in Bible order" do
    get "/en/lexemas/#{ERB::Util.url_encode('λόγος')}"
    assert_response :success
    assert_includes response.body, 'Verses: 2'
    # Матфей раньше Иоанна, стих Ин 1:1 - один раз
    assert_operator response.body.index('/mf/5/#L37'), :<, response.body.index('/in/1/#L1')
    assert_equal 1, response.body.scan('/in/1/#L1').size
  end

  test "lexeme page finds a lexeme written with other accents and 404s for unknown" do
    get "/en/lexemas/#{ERB::Util.url_encode('λογος')}"
    assert_response :success

    get "/en/lexemas/#{ERB::Util.url_encode('ἄγνωστος')}"
    assert_response :not_found
  end

  test "word page links the lexeme and shows STEP dictionaries in every locale" do
    DictWord.create!(dict: 'as', word: 'λόγος', translation_short: 'word', tag: 'G3056', desc: 'a word <a href="/mf/5#L37">Mat.5:37</a>')
    DictWord.create!(dict: 'd', word: 'λόγος', desc: 'слово')

    get "/ja/words/bw-#{@logos.id}"
    assert_response :success
    assert_includes response.body, "/ja/lexemas/#{ERB::Util.url_encode('λόγος')}"
    assert_includes response.body, 'Abbott-Smith'
    assert_includes response.body, 'STEPBible.org (Tyndale House, Cambridge), CC BY 4.0'
    assert_not_includes response.body, 'G3056'
    assert_not_includes response.body, 'слово'

    get "/ru/words/bw-#{@logos.id}"
    assert_includes response.body, 'слово'
    # словари - после блоков с информацией о слове
    assert_operator response.body.index('word-section'), :<, response.body.index('dict-words')
  end
end

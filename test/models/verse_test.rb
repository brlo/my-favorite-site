require "test_helper"

class VerseTest < ActiveSupport::TestCase
  test "address is built from book, chapter and line" do
    assert_equal 'gen:1:1', create_verse.address
  end

  test "text_search has no html and no soft hyphens" do
    verse = create_verse(text: "<i>Бо­г</i> есть [あ]любовь")
    assert_equal 'Бог есть любовь', verse.text_search.squish.gsub('[あ]', '')
  end

  test "update_interlinear_word! fills an empty interlinear from the words and saves the translation" do
    verse = create_verse(data: { 'w' => %w[Ἐν ἀρχῇ] })
    assert verse.update_interlinear_word!('ru', 1, ' в начале ')

    data = verse.reload.data
    assert_equal %w[Ἐν ἀρχῇ], data['wi'].map { _1['raw'] }
    assert_equal 'в начале', data['wi'][1]['trl']['ru']
    assert_equal({}, data['wi'][0]['trl'])
    assert_equal 1, data['ok_ru']
  end

  test "update_interlinear_word! keeps translations in other languages" do
    verse = create_verse(data: { 'w' => ['a'], 'wi' => [{ 'raw' => 'a', 'trl' => { 'en' => 'one' } }] })
    verse.update_interlinear_word!('ru', 0, 'один')
    assert_equal({ 'en' => 'one', 'ru' => 'один' }, verse.reload.data['wi'][0]['trl'])
  end

  test "update_interlinear_word! clears the translation when the word is blank" do
    verse = create_verse(data: { 'w' => ['a'], 'wi' => [{ 'raw' => 'a', 'trl' => { 'ru' => 'x' } }] })
    verse.update_interlinear_word!('ru', 0, '  ')
    assert_nil verse.reload.data['wi'][0]['trl']['ru']
  end

  test "update_interlinear_word! returns false for a missing word and does not mark the verse as checked" do
    verse = create_verse(data: { 'w' => ['a'], 'wi' => [{ 'raw' => 'a', 'trl' => {} }] })
    assert_equal false, verse.update_interlinear_word!('ru', 7, 'x')
    assert_equal false, verse.update_interlinear_word!('ru', nil, 'x')
    assert_nil verse.reload.data['ok_ru']
  end

  test "update_interlinear_word! requires a language" do
    assert_raises(ArgumentError) { create_verse(data: { 'w' => ['a'] }).update_interlinear_word!(nil, 0, 'x') }
  end
end

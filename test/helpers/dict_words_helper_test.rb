require "test_helper"

class DictWordsHelperTest < ActionView::TestCase
  def marks(text, patterns) = highlight(text, patterns).scan(%r{<mark>(.*?)</mark>}).flatten

  def greek_verse(wi) = Verse.new(text: wi.map { _1['w'] }.join(' '), data: { 'wi' => wi })

  test "highlights the interlinear occurrence in Greek and its declined translation" do
    greek = greek_verse([
      { 'w' => 'καὶ', 'bw_id' => 1, 'lex' => 'καί', 'trl' => { 'ru' => 'и' } },
      { 'w' => 'εἰς', 'bw_id' => 2, 'lex' => 'εἰς', 'trl' => { 'ru' => 'в' } },
      { 'w' => 'φυλακὴν', 'bw_id' => 3, 'lex' => 'φυλακή', 'trl' => { 'ru' => 'в темницу', 'en' => 'prison' } },
    ])
    ru = Verse.new(lang: 'ru', text: 'и ввергнут тебя в темницу; в темнице сидел')
    en = Verse.new(lang: 'en', text: 'and you will be thrown into prison')

    greek_re, ru_re = verse_pair_highlights(greek, ru) { _1['lex'] == 'φυλακή' }
    assert_equal ['φυλακὴν'], marks(greek.text, greek_re)
    # предлог "в" не подсвечиваем, падеж может быть другим
    assert_equal %w[темницу темнице], marks(ru.text, ru_re)
    assert_equal ['prison'], marks(en.text, verse_pair_highlights(greek, en) { _1['bw_id'] == 3 }.last)

    # короткое слово - только целиком
    assert_equal %w[и], marks(ru.text, verse_pair_highlights(greek, ru) { _1['bw_id'] == 1 }.last)
  end

  test "matches Greek written with oxia in the interlinear and decomposed accents in the text" do
    oxia = "λόγος"                              # ό - oxia, как в data['wi']
    text = "ὁ λόγος ὑμῶν"                  # ο + U+0301, как в тексте стиха
    greek = Verse.new(text:, data: { 'wi' => [{ 'w' => oxia, 'lex' => oxia }] })
    greek_re, = verse_pair_highlights(greek, nil) { true }
    assert_equal ['λόγος'], marks(text.unicode_normalize(:nfc), greek_re)

    # с флагом /i Onigmo здесь ничего не находил
    greek = Verse.new(text: 'ἐὰν εἴπῃ λόγον κατὰ', data: { 'wi' => [{ 'w' => 'λόγον' }] })
    assert_equal ['λόγον'], marks(greek.text, verse_pair_highlights(greek, nil) { true }.first)
  end

  test "falls back to word forms when the verse has no interlinear yet" do
    greek = Verse.new(text: 'καὶ εἰς φυλακὴν βληθήσῃ', data: {})
    greek_re, translated_re = verse_pair_highlights(greek, nil, greek_fallback: ['φυλακὴν']) { true }
    assert_equal ['φυλακὴν'], marks(greek.text, greek_re)
    assert_empty translated_re
  end

  test "Japanese gloss is matched without the kana ending" do
    greek = greek_verse([{ 'w' => 'φυλακὴν', 'bw_id' => 3, 'trl' => { 'ja' => '牢に' } }])
    ja = Verse.new(lang: 'ja', text: 'あなたは牢に入れられる')
    assert_equal ['牢'], marks(ja.text, verse_pair_highlights(greek, ja) { true }.last)
  end
end

require "test_helper"

class StepLexiconImporterTest < ActiveSupport::TestCase
  HEADER = "eStrong\tdStrong\tuStrong\tGreek\tTransliteration\tMorph\tGloss\tMeaning\n"

  def lexicon_file(rows)
    file = Tempfile.new(['step', '.txt'])
    file.write(HEADER + rows.map { _1.join("\t") + "\n" }.join)
    file.close
    @files = (@files || []) << file
    file.path
  end

  teardown { @files&.each(&:unlink) }

  test "imports only interlinear words and merges rows of one headword" do
    as = lexicon_file([
      ['G5438', 'G5438G =', 'G5438G', 'φυλακή', 'phulakē', 'G:N-F', 'prison/watch: prison', '<b>φυλακή</b> <ref=\'Luk.2.8\'>Luk.2:8</ref>'],
      ['G5438', 'G5438H = a Meaning of', 'G5438G', 'φυλακή', 'phulakē', 'G:N-F', 'prison/watch: watch', '<b>φυλακή</b> <ref=\'Luk.2.8\'>Luk.2:8</ref>'],
      ['G0611', 'G0611 =', 'G0611', 'ἀποκρίνω', 'apokrinō', 'G:V', 'to answer', '<b>ἀποκρίνω</b>'],
      ['G9999', 'G9999 =', 'G9999', 'σμαραγδίτης', 'smaragditēs', 'G:N', 'emerald', 'not in the Bible'],
    ])
    lsj = lexicon_file([
      ['G5438', 'G5438G =', 'G5438G', 'φυλακή', 'phulakē', 'G:N-F', 'prison', '<b>φῠλᾰκ-ή</b>'],
      ['G0002', 'G0002 =', 'H0175', 'Ἀαρών', 'Aarōn', 'N:N-M-P', 'Aaron', '<b>Ἀαρών</b> (From Abbott-Smith. LSJ has no entry)'],
    ])
    DictWord.create!(dict: 'lsj', word: 'παλαιόν', desc: 'old import')
    DictWord.create!(dict: 'd', word: 'φυλακή', desc: 'Дворецкий')

    # ἀποκρίνομαι в подстрочнике, в словаре - ἀποκρίνω
    stats = StepLexiconImporter.call({ 'as' => [as], 'lsj' => [lsj] }, words: %w[φυλακῇ φυλακή ἀποκρίνομαι Ἀαρών])
    assert_equal({ 'as' => 2, 'lsj' => 1 }, stats)

    phulake = DictWord.find_by!(dict: 'as', word_simple: 'φυλακη')
    assert_equal 'prison/watch: prison, watch', phulake.translation_short
    assert_equal 'G5438', phulake.tag
    assert_equal 'phulakē', phulake.transcription_lat
    assert_equal '<b>φυλακή</b> <a href="/lk/2#L8">Luk.2:8</a>', phulake.desc
    assert DictWord.exists?(dict: 'as', word_simple: 'αποκρινω')
    assert_not DictWord.exists?(dict: 'as', word_simple: 'σμαραγδιτης')

    # старые статьи lsj заменены, чужие словари не тронуты, LSJ без своей статьи не берём
    assert_equal ['φυλακη'], DictWord.where(dict: 'lsj').pluck(:word_simple)
    assert DictWord.exists?(dict: 'd', word_simple: 'φυλακη')
  end

  test "lookup falls back to other spellings only for dictionaries without an exact hit" do
    DictWord.create!(dict: 'd', word: 'ἀποκρίνομαι', desc: 'отвечать')
    DictWord.create!(dict: 'as', word: 'ἀποκρίνω', desc: 'to answer')
    DictWord.create!(dict: 'lsj', word: 'γιγνώσκω', desc: 'know')

    assert_equal %w[d as], DictWord.lookup(%w[ἀποκρίνομαι]).map(&:dict)
    assert_equal %w[as], DictWord.lookup(%w[ἀποκρίνομαι], dicts: DictWord::STEP_DICTS).map(&:dict)
    assert_equal ['γιγνωσκω'], DictWord.lookup(%w[γινώσκω]).map(&:word_simple)
  end
end

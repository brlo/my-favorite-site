require "test_helper"

class VerseSearchPgroongaTest < ActiveSupport::TestCase
  test "finds arabic verses typed without harakat" do
    verse = create_verse(tr_code: 'arab-avd', lang: 'ar', text: 'ٱلْمَسِيحُ هُوَ ٱلرَّبُّ')

    results = VerseSearchPgroonga.new(text: 'المسيح', tr_code: 'arab-avd').fetch_objects(10)

    assert_includes results.map(&:id), verse.id
    assert_includes results.find { |v| v.id == verse.id }.snippet, '<span class="keyword">ٱلْمَسِيحُ</span>'
  end

  test "counts arabic verses" do
    create_verse(tr_code: 'arab-avd', lang: 'ar', text: 'ٱلْمَسِيحُ هُوَ ٱلرَّبُّ')

    assert_equal 1, VerseSearchPgroonga.new(text: 'المسيح', tr_code: 'arab-avd').count
  end

  test "arabic search ignores alef wasla and ta marbuta differences" do
    verse = create_verse(tr_code: 'arab-avd', lang: 'ar', text: 'ٱلْحِكْمَةُ نَافِعَةٌ', line: 2)

    assert_includes VerseSearchPgroonga.new(text: 'الحكمة', tr_code: 'arab-avd').fetch_objects(10).map(&:id), verse.id
  end

  test "does not find arabic verses by unrelated words" do
    create_verse(tr_code: 'arab-avd', lang: 'ar', text: 'ٱلْمَسِيحُ هُوَ ٱلرَّبُّ')

    assert_empty VerseSearchPgroonga.new(text: 'الرحمة', tr_code: 'arab-avd').fetch_objects(10)
  end
end

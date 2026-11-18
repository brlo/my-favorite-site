require "test_helper"

class ArabicSearchNormalizerTest < ActiveSupport::TestCase
  test "removes harakat and tatweel" do
    assert_equal 'المسيح', ArabicSearchNormalizer.normalize('ٱلْمَسِيحُ')
    assert_equal 'حكمه', ArabicSearchNormalizer.normalize('حِكْمَة')
    assert_equal 'الكتاب', ArabicSearchNormalizer.normalize('الكتـــاب')
  end

  test "unifies letter variants" do
    assert_equal 'الله', ArabicSearchNormalizer.normalize('ٱللَّه')
    assert_equal 'الي', ArabicSearchNormalizer.normalize('إلى')
    assert_equal 'صلاه', ArabicSearchNormalizer.normalize('صلاة')
  end

  test "keeps other languages untouched" do
    assert_equal 'В начале сотворил', ArabicSearchNormalizer.normalize('В начале сотворил')
  end

  test "highlights matches in the original vocalized text" do
    html = ArabicSearchNormalizer.highlight('ٱلْمَسِيحُ هُوَ ٱلرَّبُّ', ['المسيح'])

    assert_includes html, '<span class="keyword">ٱلْمَسِيحُ</span>'
    assert_includes html, 'هُوَ'
    assert_not_includes html, '<span class="keyword">ٱلرَّبُّ</span>'
  end

  test "escapes html in the snippet" do
    assert_equal '&lt;b&gt;', ArabicSearchNormalizer.highlight('<b>', ['المسيح'])
  end

  test "returns escaped text when there are no keywords" do
    assert_equal 'текст', ArabicSearchNormalizer.highlight('текст', [])
  end
end

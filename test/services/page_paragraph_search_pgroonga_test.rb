require "test_helper"

class PageParagraphSearchPgroongaTest < ActiveSupport::TestCase
  test "finds arabic paragraphs typed without harakat" do
    page = create_page(lang: 'ar', path: "ar_page_#{SecureRandom.hex(3)}")
    paragraph = PageParagraph.create!(
      page: page, position: 1, lang: 'ar',
      content: '<p>ٱلصَّلَاةُ هِيَ حَدِيثُ ٱلْإِنْسَانِ مَعَ ٱللَّهِ</p>'
    )

    stubbing(Menu, :subpages_ids_of_page, [page.id]) do
      searcher = PageParagraphSearchPgroonga.new(start_page: page, text: 'الصلاة')

      assert_equal 1, searcher.count

      results = searcher.fetch_objects(limit: 10)
      assert_equal [paragraph.id], results.map(&:id)
      assert_includes results.first.highlighted_snippets.first, '<span class="keyword">'
    end
  end

  test "does not find arabic paragraphs by unrelated words" do
    page = create_page(lang: 'ar', path: "ar_page_#{SecureRandom.hex(3)}")
    PageParagraph.create!(
      page: page, position: 1, lang: 'ar',
      content: '<p>ٱلصَّلَاةُ هِيَ حَدِيثُ ٱلْإِنْسَانِ مَعَ ٱللَّهِ</p>'
    )

    stubbing(Menu, :subpages_ids_of_page, [page.id]) do
      searcher = PageParagraphSearchPgroonga.new(start_page: page, text: 'الرحمة')

      assert_equal 0, searcher.count
      assert_empty searcher.fetch_objects(limit: 10)
    end
  end
end

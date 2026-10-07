require "test_helper"

class BibleCitationExtractorTest < ActiveSupport::TestCase
  def build_page(body, **attrs)
    path = "work-#{SecureRandom.hex(4)}"
    Page.new({
      title: 'Труд', lang: 'ru', group_lang_id: SecureRandom.hex(4), path: path, path_low: path, page_type: 1,
      is_past: true, is_published: true, is_deleted: false, body: body,
    }.merge(attrs)).tap { |p| p.save!(validate: false) }
  end

  def extract(body, **attrs)
    page = build_page(body, **attrs)
    BibleCitationExtractor.call(page)
    page.bible_references.order(:position_in_page).to_a
  end

  test "finds a verse reference with a colon" do
    ref = extract('<p>Как сказано в Ин. 3:16, Бог так возлюбил мир.</p>').first
    assert_equal ['in', 3, 16, 16], [ref.book_code, ref.chapter, ref.verse_start, ref.verse_end]
    assert_includes ref.snippet, 'Бог так возлюбил'
    assert_equal 'ru', ref.lang
  end

  test "finds ranges and lists of verses" do
    refs = extract('<p>См. Рим. 8:28-30, 32.</p>')
    assert_equal [[28, 30], [32, 32]], refs.map { |r| [r.verse_start, r.verse_end] }
    assert_equal ['rim'], refs.map(&:book_code).uniq
  end

  test "understands numbered books and comma as chapter separator" do
    ref = extract('<p>Апостол пишет: 1 Кор. 13, 4 — любовь долготерпит.</p>').first
    assert_equal ['1kor', 13, 4], [ref.book_code, ref.chapter, ref.verse_start]
  end

  test "ignores lower-case words and chapters beyond the book" do
    assert_empty extract('<p>Было это на 5, 3 раза, а также по 2, 3 штуки.</p>')
    assert_empty extract('<p>Ин. 99:1</p>')
  end

  test "stores the same reference once per page" do
    refs = extract('<p>Ин. 3:16 здесь, и снова Ин. 3:16 там.</p>')
    assert_equal 1, refs.size
  end

  test "does nothing for pages that are not published past works" do
    assert_empty extract('<p>Ин. 3:16</p>', is_past: false)
    assert_empty extract('<p>Ин. 3:16</p>', is_published: false)
    assert_empty extract('<p>Ин. 3:16</p>', is_deleted: true)
  end

  test "re-running replaces earlier references" do
    page = build_page('<p>Ин. 3:16</p>')
    BibleCitationExtractor.call(page)
    page.update_columns(body: '<p>Мф. 5:3</p>')
    assert_equal 1, BibleCitationExtractor.call(page)
    assert_equal ['mf'], BibleReference.where(page_id: page.id).pluck(:book_code)
  end
end

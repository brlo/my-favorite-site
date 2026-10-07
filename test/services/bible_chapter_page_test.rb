require "test_helper"

class BibleChapterPageTest < ActiveSupport::TestCase
  def chapter_page(content_lang: 'ru', book_code: 'gen', chapter: 1, ui_locale: 'ru')
    BibleChapterPage.new(content_lang: content_lang, book_code: book_code, chapter: chapter, ui_locale: ui_locale)
  end

  test "interlinear languages read the main text from the paired translation" do
    page = chapter_page(content_lang: 'gr-en')
    assert page.is_interliner?
    assert_equal 'eng-nkjv', page.interliner_tr_code
    assert_not chapter_page.is_interliner?
    assert_nil chapter_page.interliner_tr_code
  end

  test "verses are ordered by line and limited to the chapter" do
    create_verse(line: 2, text: 'второй')
    create_verse(line: 1, text: 'первый')
    create_verse(chapter: 2, line: 1, text: 'другая глава')
    assert_equal %w[первый второй], chapter_page.verses.map(&:text)
  end

  test "greek verses are loaded only for interlinear" do
    create_verse(tr_code: 'gr-ru', lang: 'gr', text: 'Ἐν ἀρχῇ')
    assert_nil chapter_page.verses_gr
    assert_equal ['Ἐν ἀρχῇ'], chapter_page(content_lang: 'gr-ru').verses_gr.map(&:text)
  end

  test "no_index when the UI language differs from the content language" do
    assert_not chapter_page(content_lang: 'ru', ui_locale: 'ru').no_index?
    assert chapter_page(content_lang: 'ru', ui_locale: 'en').no_index?
  end

  test "no_index for translations that are not indexed" do
    assert chapter_page(content_lang: 'csl-pnm', ui_locale: 'ru').no_index?
  end

  test "title mentions book, chapter and psalm wording" do
    assert_includes chapter_page.title, I18n.t('chapter')
    assert_includes chapter_page(book_code: 'ps').title, I18n.t('psalm')
    assert_includes chapter_page(content_lang: 'csl-ru').title, 'ЦСЯ'
  end

  test "meta description starts with the book and quotes the first verses" do
    create_verse(line: 1, text: 'Первый стих.')
    assert_equal "#{I18n.t('books.full.gen')}: Первый стих.", chapter_page.meta_description
  end

  test "breadcrumbs depend on the testament" do
    assert_includes chapter_page(book_code: 'gen').breadcrumbs, I18n.t('breadcrumbs.VZ')
    assert_includes chapter_page(book_code: 'in').breadcrumbs, I18n.t('breadcrumbs.NZ')
  end

  test "cite counts are zero for an uncited chapter" do
    Rails.cache.clear
    page = chapter_page
    assert_equal 0, page.cite_max
    assert_equal 0, page.cite_min
  end

  test "comments are indexed by verse number" do
    create_verse(line: 6)
    comment = create_page(title: 'Быт. 1:6', path: '', page_type: 3)
    assert_equal 'ru-gen:1:6', comment.path
    assert_equal({ 6 => comment }, chapter_page.comments)
  end

  test "cache_key identifies language, book and chapter" do
    assert_equal 'ru--gen--3', chapter_page(chapter: '3').cache_key
  end
end

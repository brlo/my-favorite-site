require "test_helper"

class BibleCitationsTest < ActiveSupport::TestCase
  def cite(work, author, from, to, snippet, digest: SecureRandom.hex(4), lang: 'ru')
    BibleReference.create!(page_id: work.id, author_page_id: author.id, lang: lang, book_code: 'gen', chapter: 1,
                           verse_start: from, verse_end: to, position_in_page: 0, snippet: snippet, digest: digest)
  end

  def authors(line, lang: 'ru')
    BibleCitations.new(lang: lang, book_code: 'gen', chapter: 1, line: line).authors
  end

  test "groups references by author and work, older authors first" do
    late = create_page(title: 'Феофан', date_start_int: 1800)
    early = create_page(title: 'Августин', date_start_int: 400)
    undated = create_page(title: 'Аноним')
    [late, early, undated].each { |a| cite(create_page(parent_id: a.id), a, 1, 1, "о #{a.title}") }

    assert_equal %w[Августин Феофан Аноним], authors(1).map { _1.author.title }
  end

  test "only references covering the line are returned, in the requested language" do
    author = create_page(title: 'Автор')
    work = create_page
    cite(work, author, 1, 3, 'подходит')
    cite(work, author, 5, 6, 'не подходит')
    cite(create_page(lang: 'en'), author, 1, 3, 'другой язык', lang: 'en')

    result = authors(2)
    assert_equal 1, result.size
    assert_equal ['подходит'], result.first.works.first.refs.map(&:snippet)
  end

  test "the same snippet in two copies of a work counts once" do
    author = create_page(title: 'Автор')
    2.times { cite(create_page, author, 1, 1, 'одинаковый фрагмент', digest: 'same') }
    assert_equal 1, authors(1).first.total
  end

  test "shows at most three snippets per work" do
    author = create_page(title: 'Автор')
    work = create_page
    5.times { |i| cite(work, author, 1, 1 + i, "фрагмент #{i}") }
    result = authors(1).first
    assert_equal 5, result.total
    assert_equal 3, result.works.first.refs.size
  end

  test "result can be read like a hash by the view" do
    author = create_page(title: 'Автор')
    cite(create_page, author, 1, 1, 'x')
    entry = authors(1).first
    assert_equal entry.author, entry[:author]
    assert_equal 1, entry[:total]
  end

  test "no references means no authors" do
    assert_empty authors(1)
  end
end

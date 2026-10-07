# Кто из святых отцов цитирует стих: авторы и фрагменты их трудов для панели справа от текста
class BibleCitations
  MAX_REFS = 600
  MAX_UNIQUE_REFS = 400
  REFS_PER_WORK = 3

  Author = Struct.new(:author, :works, :total, keyword_init: true)
  Work = Struct.new(:page, :refs, keyword_init: true)

  # lang - язык трудов (локаль контента)
  def initialize(lang:, book_code:, chapter:, line:)
    @lang = lang
    @book_code = book_code
    @chapter = chapter
    @line = line
  end

  # Авторы по порядку эпох (без даты — в конце)
  def authors
    refs = ::BibleReference.for_lang(@lang).in_context(@book_code, @chapter, @line).order(:id).limit(MAX_REFS).to_a
    refs = ::BibleReference.uniq_by_digest(refs).first(MAX_UNIQUE_REFS)
    pages = ::Page.where(id: refs.flat_map { [_1.page_id, _1.author_page_id] }.compact.uniq)
                  .select(:id, :title, :path, :lang, :date_start_int).index_by(&:id)

    result = refs.group_by(&:author_page_id).filter_map do |author_id, list|
      author = pages[author_id]
      next unless author

      works = list.group_by(&:page_id).filter_map do |page_id, rs|
        pages[page_id] && Work.new(page: pages[page_id], refs: rs.first(REFS_PER_WORK))
      end
      Author.new(author: author, works: works, total: list.size)
    end
    result.sort_by { |a| [a.author.date_start_int || 99_999, a.author.title] }
  end
end

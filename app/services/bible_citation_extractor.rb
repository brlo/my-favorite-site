# Ищет ссылки на Писание ("Ин. 3:16-17", "1 Кор. 13, 4", "Rom 8:28") в тексте страницы
# и сохраняет их в bible_references. Вызывается только для страниц с is_past (труды святых отцов).
class BibleCitationExtractor
  SNIPPET_BEFORE = 160
  SNIPPET_AFTER = 120
  MAX_RANGE = 60 # длиннее — скорее всего, это не цитата, а ссылка на целую главу

  # "1-е Кор" -> "1екор"; ключи без пробелов, точек и дефисов
  BOOKS = ::BOOK_TO_CODE.each_with_object({}) { |(k, v), h| h[k.gsub(/[^\p{L}\d]/, '')] = v }.freeze
  ROMAN_PREFIX = { 'I' => '1', 'II' => '2', 'III' => '3' }.freeze

  # Книга (с необязательным номером: 1, 2-е, II) начинается с заглавной — так отсекаем "на 5, 3", "по 2, 3".
  # Глава отделяется от стихов ":" или запятой, стихи: 16, 16-17, 16,18, 16а.
  PATTERN = /
    (?<![\p{L}\d])
    (?<book>(?:(?:[1-4]|I{1,3})[\s.\-]*(?:[ея]\b[\s.\-]*)?)?\p{Lu}\p{L}{0,24}\.?)
    \s*(?<chapter>\d{1,3})\s*(?::\s*|,\s+)
    (?<verses>\d{1,3}[а-гa-d]?(?:\s*[–—\-]\s*\d{1,3}[а-гa-d]?)?(?:\s*,\s*\d{1,3}[а-гa-d]?(?:\s*[–—\-]\s*\d{1,3}[а-гa-d]?)?)*)
    (?![\p{L}\d:])
  /x

  def self.call(page)
    new(page).perform
  end

  # Корневые страницы со списками авторов (ru и en)
  def self.root_ids
    @root_ids = nil if Rails.env.development?
    @root_ids ||= ::Page.where(path_low: ::PAST_ROOT_PATHS).pluck(:id)
  end

  def initialize(page)
    @page = page
  end

  def perform
    @page.bible_references.delete_all
    return 0 unless @page.is_past && @page.is_published && !@page.is_deleted

    text = plain_text(@page.body)
    author_id = find_author_id
    now = Time.current
    records = {}

    text.to_enum(:scan, PATTERN).each do
      m = Regexp.last_match
      book_code = book_code_for(m[:book])
      next unless book_code
      chapter = m[:chapter].to_i
      next unless chapter.between?(1, ::BOOKS[book_code][:chapters])

      ranges = parse_ranges(m[:verses])
      next if ranges.empty?

      snippet = snippet_for(text, m.begin(0), m.end(0))
      digest = ::BibleReference.digest_for(snippet)
      ranges.each do |from, to|
        # одну и ту же ссылку в одном труде запоминаем один раз (первое упоминание)
        key = [book_code, chapter, from, to]
        records[key] ||= {
          page_id: @page.id, author_page_id: author_id, lang: @page.lang,
          book_code: book_code, chapter: chapter, verse_start: from, verse_end: to,
          snippet: snippet, digest: digest, context_before: snippet[0, 500], position_in_page: m.begin(0),
          created_at: now, updated_at: now,
        }
      end
    end

    return 0 if records.empty?
    ::BibleReference.insert_all(records.values)
    records.size
  end

  private

  def book_code_for(raw)
    key = raw.downcase.gsub(/[^\p{L}\d]/, '')
    BOOKS[key] || begin
      # "II Кор" -> "2Кор"
      roman = raw[/\A(I{1,3})(?=[\s.\-]*\p{Lu})/, 1]
      roman && BOOKS[(ROMAN_PREFIX[roman] + raw.sub(/\AI{1,3}/, '')).downcase.gsub(/[^\p{L}\d]/, '')]
    end
  end

  def parse_ranges(str)
    str.split(',').filter_map do |part|
      from, to = part.scan(/\d+/).map(&:to_i)
      to ||= from
      next unless from.between?(1, 200) && to.between?(from, from + MAX_RANGE)
      [from, to]
    end
  end

  # HTML -> текст; концы блоков превращаем в перевод строки, чтобы фрагмент не склеивал абзацы
  def plain_text(html)
    t = html.to_s.gsub(%r{</(?:p|h[1-6]|li|blockquote|tr|div)>|<br\s*/?>}i, "\n")
    t = ::ActionController::Base.helpers.strip_tags(t)
    CGI.unescapeHTML(t).gsub(/[ \t ]+/, ' ')
  end

  def snippet_for(text, from, to)
    s = text.rindex("\n", from)
    s = s ? s + 1 : 0
    e = text.index("\n", to) || text.length
    a = [from - SNIPPET_BEFORE, s].max
    b = [to + SNIPPET_AFTER, e].min
    a = text.index(/\s/, a).to_i + 1 if a > s && text[a - 1] =~ /\S/ && text.index(/\s/, a)
    b = text.rindex(/\s/, b) || b if b < e && text[b] =~ /\S/ && text.rindex(/\s/, b).to_i > to
    out = text[a...b].to_s.strip
    out = "…#{out}" if a > s
    out = "#{out}…" if b < e
    out
  end

  # Автор — предок страницы, чей родитель — корень списка авторов (church_writers / q-saints-en)
  def find_author_id
    roots = self.class.root_ids
    node = @page
    8.times do
      return node.id if roots.include?(node.parent_id)
      return node.id unless node.parent_id
      node = ::Page.select(:id, :parent_id).find_by(id: node.parent_id) or return @page.id
    end
    @page.id
  end
end

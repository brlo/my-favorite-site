# Превращает ссылки на Писание в тексте статьи ("Мф. 20:13-17,19") в гиперссылки на Библию
# этого же сайта, на переводе, который соответствует языку статьи.
class BibleLinker
  # язык статьи -> перевод Библии
  BIBLE_BY_LANG = {
    'ru'      => 'ru',
    'en'      => 'en-nrsv',
    'ja'      => 'jp-ni',
    'de'      => 'ge-sch',
    'zh-Hans' => 'cn-ccbs',
  }.freeze

  DASH = '[–—−\-－]'
  VERSE = "\\d{1,3}(?:#{DASH}\\d{1,3})?"
  JA_VERSES = "(?<verses>#{VERSE}(?:\\s*[,、]\\s*#{VERSE})*)"

  # Внутри этих тегов ссылки не ставим
  SKIP_TAGS = %w[a h1 h2 h3 h4 h5 h6 code script style].freeze

  # Результат поиска ссылки в тексте: [начало, конец, адрес]
  Match = Struct.new(:from, :to, :href)

  # Японские названия книг: "マタ", "マタイ", "１コリ" -> код книги. Берём из локали, длинные названия первыми.
  def self.ja_books
    @ja_books = nil if Rails.env.development?
    @ja_books ||= begin
      names = %i[short mid full].flat_map do |kind|
        (::I18n.t("books.#{kind}", locale: :ja, default: {}) || {}).map { |code, name| [name.to_s, code.to_s] }
      end
      names.reject { |name, code| name.empty? || !::BOOKS.key?(code) }.to_h.sort_by { |name, _| -name.length }.to_h
    end
  end

  def self.ja_pattern
    @ja_pattern = nil if Rails.env.development?
    @ja_pattern ||= /(?<book>#{ja_books.keys.map { Regexp.escape(_1) }.join('|')})\s*(?<chapter>[0-9０-９]{1,3})\s*[:：]\s*(?<verses>[0-9０-９]{1,3}(?:#{DASH}[0-9０-９]{1,3})?(?:\s*[,、]\s*[0-9０-９]{1,3}(?:#{DASH}[0-9０-９]{1,3})?)*)/
  end

  # HTML-фрагмент -> HTML, где найденные ссылки на Писание стали гиперссылками
  def self.link_html(html, lang)
    return html.to_s unless BIBLE_BY_LANG.key?(lang) && html.present?

    doc = ::Nokogiri.HTML(html.to_s)
    doc.xpath('//body//text()').each do |node|
      next if node.ancestors.any? { SKIP_TAGS.include?(_1.name) }

      replaced = link_text(node.text, lang)
      node.replace(replaced) if replaced
    end
    doc.at_css('body').inner_html.gsub("\n", "")
  end

  # Простой текст -> HTML со ссылками или nil, если ссылок в тексте нет
  def self.link_text(text, lang)
    matches = find(text, lang)
    return if matches.empty?

    pos = 0
    out = +''
    matches.each do |m|
      out << ::ERB::Util.html_escape(text[pos...m.from])
      out << %(<a href="#{::ERB::Util.html_escape(m.href)}">#{::ERB::Util.html_escape(text[m.from...m.to])}</a>)
      pos = m.to
    end
    out << ::ERB::Util.html_escape(text[pos..])
  end

  def self.find(text, lang)
    bible = BIBLE_BY_LANG[lang] or return []
    locale = ::BIB_LANG_TO_LOCALE[bible]
    pattern = lang == 'ja' ? ja_pattern : ::BibleCitationExtractor::PATTERN

    text.to_enum(:scan, pattern).filter_map do
      m = ::Regexp.last_match
      href = href_for(m, lang, bible, locale)
      Match.new(m.begin(0), m.end(0), href) if href
    end
  end

  def self.href_for(m, lang, bible, locale)
    book_code = lang == 'ja' ? ja_books[m[:book]] : ::BibleCitationExtractor.book_code_for(m[:book])
    return unless book_code

    chapter = to_ascii(m[:chapter]).to_i
    return unless chapter.between?(1, ::BOOKS[book_code][:chapters])

    ranges = ::BibleCitationExtractor.parse_ranges(to_ascii(m[:verses]).gsub(/#{DASH}/, '-').gsub('、', ','))
    return if ranges.empty?

    lines = ranges.map { |from, to| from == to ? from : "#{from}-#{to}" }.join(',')
    "/#{locale}/#{bible}/#{book_code}/#{chapter}#L#{lines}"
  end

  # Полноширинные цифры -> обычные
  def self.to_ascii(str)
    str.tr('０-９', '0-9')
  end

  private_class_method :href_for, :to_ascii
end

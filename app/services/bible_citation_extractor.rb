class BibleCitationExtractor
  # Допустимые символы до и после ссылки для снижения ложных срабатываний
  ALLOWED_PREV_CHARS = ['(', '[', '«', "\n", "\t", ' ', ';', ',', '.', nil].freeze
  ALLOWED_NEXT_CHARS = [')', ']', '»', "\n", "\t", ' ', ';', ',', '.', nil].freeze

  def self.call(page)
    new(page).perform
  end

  def initialize(page)
    @page = page
    @content = page.content.to_s
    # Загружаем коды книг из вашей БД. Сортируем по длине, чтобы длинные аббревиатуры матчились раньше
    @book_codes = Verse.pluck(:code).uniq.compact.sort_by(&:length).reverse
    @books_regex = @book_codes.map { |b| Regexp.escape(b) }.join('|')

    # Регулярка: Книга(опц. точка/пробел) + Глава(араб/рим) + разделитель + Стихи
    @pattern = /(?<book>#{@books_regex})\s*\.?\s*(?<chapter>\d+|[IVXLCDM]+)\s*[:,]\s*(?<verses>\d+(?:\s*[–—-]\s*\d+)?(?:\s*,\s*\d+(?:\s*[–—-]\s*\d+)?)*))/i
  end

  def perform
    inserted = 0
    match_start = 0

    while (match = @content.match(@pattern, match_start))
      match_start = match.end(0)

      next unless valid_boundaries?(match)
      next unless plausible_values?(match)

      book_code = normalize_book(match[:book])
      chapter   = to_arabic(match[:chapter])
      verses    = parse_verse_ranges(match[:verses])

      context   = extract_context(match.begin(0))
      position  = match.begin(0)

      records = verses.map do |v|
        {
          page_id: @page.id,
          book_code: book_code,
          chapter: chapter,
          verse_start: v[:start],
          verse_end: v[:end],
          context_before: context,
          position_in_page: position,
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      # PostgreSQL upsert: пропускаем дубликаты по уникальному индексу
      result = BibleReference.upsert_all(records, unique_by: :idx_unique_bible_ref_on_page)
      inserted += result.rows.count
    end

    Rails.logger.info("[BibleCitationExtractor] Page ##{@page.id}: found #{inserted} unique references.")
    inserted
  end

  private

  def valid_boundaries?(match)
    prev_char = @content[match.begin(0) - 1]
    next_char = @content[match.end(0)]
    ALLOWED_PREV_CHARS.include?(prev_char) && ALLOWED_NEXT_CHARS.include?(next_char)
  end

  def plausible_values?(match)
    chapter = to_arabic(match[:chapter])
    # В Библии не бывает глав > 150 и стихов > 200. Отсекает даты, номера телефонов и т.п.
    return false if chapter <= 0 || chapter > 150

    match[:verses].scan(/\d+/).all? { |v| v.to_i.between?(1, 200) }
  end

  def normalize_book(raw)
    # Убираем лишние пробелы: "2 Кор" -> "2Кор", если такой код есть в БД
    cleaned = raw.gsub(/\s+/, '')
    @book_codes.include?(cleaned) ? cleaned : raw
  end

  def to_arabic(num_str)
    return num_str.to_i if num_str.match?(/\A\d+\z/)

    roman_map = { 'I'=>1, 'V'=>5, 'X'=>10, 'L'=>50, 'C'=>100, 'D'=>500, 'M'=>1000 }
    total = 0
    prev = 0
    num_str.upcase.reverse.each_char do |char|
      val = roman_map[char] || 0
      total += (val < prev ? -val : val)
      prev = val
    end
    total
  end

  def parse_verse_ranges(verses_str)
    segments = []
    verses_str.split(',').each do |part|
      part = part.strip
      if part =~ /\d+\s*[–—-]\s*\d+/
        start_s, end_s = part.split(/[-–—]/)
        segments << { start: start_s.to_i, end: end_s.to_i }
      else
        segments << { start: part.to_i, end: part.to_i } if part.match?(/\A\d+\z/)
      end
    end
    segments
  end

  def extract_context(match_begin)
    before_text = @content[0...match_begin]
    words = before_text.scan(/\S+/).filter(&:present?)
    words.last(20).join(' ')
  end
end

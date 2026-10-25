# Загружает перевод Библии из модуля MyBible (*.SQLite3, таблица verses) в таблицу verses.
# Номера книг MyBible совпадают с id в BOOKS, нумерация глав и стихов остаётся как в модуле.
# Исходная разметка стиха сохраняется в data['orig'], в text — очищенный текст.
#
#   MybibleImporter.call('tmp/HIND.SQLite3', tr_code: 'hi-ov', lang: 'hi') -> {imported:, skipped:}
class MybibleImporter
  BATCH = 2_000
  BOOK_BY_ID = ::BOOKS.to_h { |code, b| [b[:id], code] }.freeze

  def self.call(...) = new(...).perform

  # fixes - замены в тексте модуля, например {'침례' => '세례'}, если составитель модуля исказил перевод
  def initialize(file, tr_code:, lang:, is_replace: false, fixes: {})
    @file = file
    @fixes = fixes
    @tr_code = tr_code
    @lang = lang
    @is_replace = is_replace
  end

  def perform
    raise ArgumentError, "перевод #{@tr_code} уже загружен (REPLACE=1 - заменить)" if !@is_replace && ::Verse.exists?(tr_code: @tr_code)

    rows, skipped = build_rows
    ::Verse.transaction do
      ::Verse.where(tr_code: @tr_code).delete_all
      rows.each_slice(BATCH) { ::Verse.insert_all!(_1) }
      update_tsvectors
    end
    { imported: rows.size, skipped: skipped }
  end

  # Разметка MyBible -> текст для показа: сноски и служебные номера убираем, курсив и слова Христа оставляем
  def self.clean(text)
    s = text.to_s.dup
    s.gsub!(%r{<(f|n|S|m)>.*?</\1>}m, '')
    # заголовок, у которого потерялось начало "<n>[" (бывает в корейском модуле)
    s.sub!(%r{\A[^<]*\]</n>}, '')
    s.gsub!(%r{<(/?)J>}, '<\1j>')
    s.gsub!(%r{</?(?!(?:i|j)>)[a-zA-Z]+\s*/?>}, '')
    # корейский "공동번역": метки сносок "ㄱ)" в тексте и сами сноски "(ㄱ. ...)" в конце стиха
    s.sub!(/\s*\([ㄱ-ㅎ]\..*\z/m, '')
    s.gsub!(/[ㄱ-ㅎ]\)\s?/, '')
    s.gsub(/[ \t\r\n]+/, ' ').gsub(/\s+([,.;:!?，。；：！？、।])/, '\1').strip
  end

  private

  def build_rows
    db = ::SQLite3::Database.new(@file, readonly: true)
    now = Time.current
    skipped = 0
    rows = db.execute('SELECT book_number, chapter, verse, text FROM verses ORDER BY book_number, chapter, verse').filter_map do |book_id, chapter, verse, orig|
      book = BOOK_BY_ID[book_id.to_i]
      orig = @fixes.reduce(orig.to_s) { |t, (from, to)| t.gsub(from, to) }
      text = self.class.clean(orig)
      if book.nil? || text.blank? || chapter.to_i < 1
        skipped += 1
        next
      end

      {
        tr_code: @tr_code, lang: @lang, book_id: book_id.to_i, book: book, zavet: ::BOOKS[book][:zavet] == 2,
        chapter: chapter.to_i, line: verse.to_i, address: "#{book}:#{chapter.to_i}:#{verse.to_i}",
        text: text, text_search: sanitizer.sanitize(text).gsub("\u00AD", ''), data: { 'orig' => orig },
        created_at: now, updated_at: now,
      }
    end
    [rows, skipped]
  ensure
    db&.close
  end

  def update_tsvectors
    pg_dict = ::LANG_TO_PG_LANGUAGE[@lang] || 'simple'
    ::Verse.where(tr_code: @tr_code).update_all(::Verse.sanitize_sql(["text_tsvector = to_tsvector(?, text_search)", pg_dict]))
  end

  def sanitizer = @sanitizer ||= ::Rails::Html::FullSanitizer.new
end

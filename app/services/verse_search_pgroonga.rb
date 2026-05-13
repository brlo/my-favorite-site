class VerseSearchPgroonga
  # Конфигурация
  MAX_TEXT_LENGTH = 250
  MIN_LEN_BY_LANG = { 'jp-ni' => 2, 'cn-ccbs' => 2 }.freeze
  DEFAULT_MIN_LEN = 3

  # Настройки PGroonga
  PROXIMITY_DISTANCE = 8 # *N: кол-во токенов МЕЖДУ первым и последним словом
  SNIPPET_WIDTH = 150
  SNIPPET_MAX_FRAGMENTS = 5

  attr_reader :text, :tr_code, :book, :accuracy, :lang

  def initialize text:, tr_code: 'ru', book: nil, accuracy: nil
    @text = text.to_s    # текст для поиска
    @tr_code = tr_code   # код перевода Библии
    @book = book         # конкретная книга для поиска
    @accuracy = accuracy # точность: similar, exact

    @zavet = nil
    @search_books = nil

    # в каких книгах в итоге будем искать
    if @book.present?
      if @book == 'z1'
        @zavet = false
      elsif @book == 'z2'
        @zavet = true
      elsif @book == 'e4'
        @search_books = %w(mf mk lk in)
      else
        @search_books = [@book]
      end
    end

    # язык, основываясь на навании перевода Библии
    @lang = ::BIB_LANG_TO_LOCALE[@tr_code.to_s]
  end

  def count
    return 0 unless valid_search_term?
    words = sanitize_and_tokenize
    return 0 if words.empty?

    conn = ActiveRecord::Base.connection
    relation = base_relation

    build_groonga_queries(words).each do |groonga_query|
      count = relation.where("body_search &@~ #{groonga_query}").count
      return count if count.positive?
    end
    0
  end

  # def fetch_objects(offset: 0, limit: 20)
  def fetch_objects(limit)
    return [] unless valid_search_term?
    words = sanitize_and_tokenize
    return [] if words.empty?

    relation = base_relation.limit(limit) # .offset(offset)
    conn = ActiveRecord::Base.connection

    build_groonga_queries(words).each do |groonga_query|
      results = execute_search(relation, conn, groonga_query, words)
      return process_snippets(results, words) if results.any?
    end
    []
  end

  private

  # === Валидация и Токенизация ===

  def valid_search_term?
    # не ищем меньше 3 символов и больше 120
    return false if @text.blank?
    return false if @text.length > MAX_TEXT_LENGTH
    return false if @text.length < min_length

    # названия книг валидны?
    if @search_books.present?
      return false if !@search_books.all? { |b| ::BOOKS.has_key?(b) }
    end

    # названия переводом Библии валидны?
    if ::CacheSearch::SEARCH_LANGS.exclude?(@tr_code)
      return []
    end

    true
  end

  def min_length
    MIN_LEN_BY_LANG.fetch(lang, DEFAULT_MIN_LEN)
  end

  def sanitize_and_tokenize
    # Оставляем буквы, цифры, пробелы, дефисы и плюсы (синтаксис Groonga)
    clean = text.strip.gsub(/[^\p{L}\p{N}\s\-+]/u, ' ').gsub(/\s+/, ' ').strip
    return [] if clean.length < min_length

    # Для CJK допускаем слова от 1 символа, для латиницы/кириллицы от 2
    cjk = ['jp-ni', 'cn-ccbs', 'zh', 'ja', 'ko'].include?(lang)
    min_word_len = cjk ? 1 : 2
    clean.split.select { |w| w.length >= min_word_len }
  end

  # === Логика Поиска (Стратегии) ===

  def escape_groonga(str)
    # Экранируем спецсимволы Groonga, чтобы не ломать синтаксис запроса
    # str.gsub(/([\\\"*+!(){}[\]<>\-])/, '\\\\\1')
    str
  end

  def build_groonga_queries(words)
    queries = []
    escaped = words.map { |w| escape_groonga(w) }
    joined  = escaped.join(' ')

    queries << "'*N#{PROXIMITY_DISTANCE}\"#{joined}\"'"

    queries
  end

  # === Работа с БД ===

  def base_relation
    relation = ::Verse
    relation = relation.where(tr_code: @tr_code) if @tr_code.present?
    relation = relation.where(book: @search_books) if @search_books.present?
    relation = relation.where(zavet: @zavet) if !@zavet.nil?
    relation = relation.order(%i[tr_code book_id chapter line])
    # relation = relation.limit(@limit) if @limit.present?
  end

  def execute_search(relation, conn, groonga_query, keywords)
    # Безопасная подстановка массива для сниппетов и строки для поиска
    keywords_sql = "ARRAY[#{keywords.map { |w| "'#{w}'" }.join(',')}]::text[]"
    query_sql    = groonga_query # conn.quote(groonga_query)

    relation
      .select(
        :id, :text, :book, :chapter, :line, :lang,
        "pgroonga_snippet_html(text_search, #{keywords_sql}) AS snippets_raw"
      )
      .where("text_search &@~ #{query_sql}")
      .order("id ASC") # Детерминированная пагинация. Релевантность обеспечивается стратегиями + Ruby-ранжированием
      .to_a
  end

  # === Пост-обработка: Сниппеты ===

  def process_snippets(results, keywords)
    return [] if results.empty?

    results.each do |verse|
      # raw = verse.snippets_raw || []
      # ranked = rank_snippets(raw, keywords)
      ranked = verse.snippets_raw

      verse.instance_variable_set(:@search_snippets, ranked)
      verse.define_singleton_method(:snippet) { @search_snippets&.first }
    end
    results
  end
end

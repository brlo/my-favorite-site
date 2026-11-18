class VerseSearchPgroonga
  MAX_TEXT_LENGTH = 250
  MIN_LEN_BY_LANG = { 'jp-ni' => 1, 'cn-sb' => 1, 'cn-sbt' => 1, 'cn-cuv' => 1, 'cn-cuvt' => 1, 'ko-nkrv' => 1 }.freeze
  DEFAULT_MIN_LEN = 3

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
      count = relation.where("#{search_column} &@~ ?", groonga_query).count
      return count if count.positive?
    end
    0
  end

  # def fetch_objects(offset: 0, limit: 20)
  def fetch_objects(limit)
    return [] unless valid_search_term?
    keywords = sanitize_and_tokenize
    return [] if keywords.empty?

    relation = base_relation.limit(limit) # .offset(offset)
    conn = ActiveRecord::Base.connection

    build_groonga_queries(keywords).each do |groonga_query|
      results = execute_search(relation, conn, groonga_query, keywords)
      return process_snippets(results, keywords) if results.any?
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
    return false if ::CacheSearch::SEARCH_LANGS.exclude?(@tr_code)

    true
  end

  def min_length
    MIN_LEN_BY_LANG.fetch(tr_code, DEFAULT_MIN_LEN)
  end

  def sanitize_and_tokenize
    # Оставляем буквы, цифры, пробелы, дефисы и плюсы (синтаксис Groonga)
    clean = text.strip.gsub(/[^\p{L}\p{N}\s\-+]/u, ' ').gsub(/\s+/, ' ').strip
    clean = ::ArabicSearchNormalizer.normalize(clean) if arabic?
    return [] if clean.length < min_length

    # Для CJK допускаем слова от 1 символа, для латиницы/кириллицы от 2
    cjk = ['jp-ni', 'cn-sb', 'cn-sbt', 'cn-cuv', 'cn-cuvt', 'ko-nkrv', 'zh', 'ja', 'ko'].include?(lang)
    min_word_len = cjk ? 1 : 2
    clean.split(' ').select { |w| w.length >= min_word_len }
  end

  # === Логика Поиска (Стратегии) ===

  def build_groonga_queries(keywords)
    queries = []
    joined  = keywords.join(' ')

    if accuracy == 'exact'
      # тут учитывается близость слов друг ко другу
      queries << "*N#{PROXIMITY_DISTANCE}\"#{joined}\""
    else
      # здесь произвольный порядок и удалённость слов
      # (но в рамках библейского стиха это не критично, а вот при поиске по статьям - очень критично, чтобы слова были рядом)
      queries << "#{joined}"
    end

    queries
  end

  # === Работа с БД ===

  def base_relation
    relation = ::Verse
    relation = relation.where(tr_code: @tr_code) if @tr_code.present?
    relation = relation.where(lang: @lang) if arabic? && @lang.present?
    relation = relation.where(book: @search_books) if @search_books.present?
    relation = relation.where(zavet: @zavet) if !@zavet.nil?
    # relation = relation.limit(@limit) if @limit.present?
    relation
  end

  def execute_search(relation, conn, groonga_query, keywords)
    # Для арабского подсветку делаем в Ruby (см. process_snippets): в text_search_ar
    # огласовки сняты, а показать хочется исходный текст стиха.
    if arabic?
      return relation
        .select(:id, :text, :text_search, :book, :chapter, :line, :lang)
        .where("text_search_ar &@~ ?", groonga_query)
        .order(%i[tr_code book_id chapter line])
        .to_a
    end

    # TIP!!!: после того как функции pgroonga_highlight_html добавил имя индекса (таким образом подключается нормализатор из этого индекса)
    # заработала подсветка синтаксиса с разным регистром. Хотя, всё это дело очень мутно работает.
    relation
      .select(
        :id, :text, :book, :chapter, :line, :lang,
        "pgroonga_highlight_html(text_search, pgroonga_query_extract_keywords('#{keywords.join(' ')}'), '#{index_name}') AS snippets_raw"
      )
      .where("text_search &@~ ?", groonga_query)
      .order(%i[tr_code book_id chapter line])
      .to_a
  end

  def index_name
    # @tr_code == 'jp-ni' ? 'idx_verses_text_search_mecab' : 'idx_verses_text_search_default'
    'idx_verses_text_search_default'
  end

  # === Пост-обработка: Сниппеты ===

  def process_snippets(results, keywords)
    return [] if results.empty?

    results.each do |verse|
      snippet =
        if arabic?
          ::ArabicSearchNormalizer.highlight(verse.text_search, keywords)
        else
          verse.snippets_raw
        end

      verse.instance_variable_set(:@search_snippets, snippet)
      verse.define_singleton_method(:snippet) { @search_snippets }
    end
    results
  end

  def arabic?
    @lang.to_s == 'ar'
  end

  # Колонка, по которой ищем: для арабского — нормализованная копия текста
  def search_column
    arabic? ? 'text_search_ar' : 'text_search'
  end
end

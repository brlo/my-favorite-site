class PageParagraphSearchPgroonga
  MAX_TEXT_LENGTH = 250
  MIN_LEN_BY_LANG = { 'jp-ni' => 1, 'cn-ccbs' => 1 }.freeze
  DEFAULT_MIN_LEN = 3

  PROXIMITY_DISTANCE = 8 # *N: кол-во токенов МЕЖДУ первым и последним словом
  SNIPPET_WIDTH = 150
  SNIPPET_MAX_FRAGMENTS = 5

  PAGE_PARAGRAPH_MODEL = ::PageParagraph
  MENU_SERVICE = ::Menu

  attr_reader :start_page, :text, :lang

  def initialize(start_page:, text:)
    @start_page = start_page
    @text = text
    @lang = start_page.lang
  end

  def count
    return 0 unless valid_search_term?
    words = sanitize_and_tokenize
    return 0 if words.empty?

    conn = ActiveRecord::Base.connection
    relation = base_relation

    build_groonga_queries(words).each do |groonga_query|
      count = relation.where("content &@~ ?", groonga_query).count
      return count if count.positive?
    end
    0
  end

  def fetch_objects(offset: 0, limit: 20)
    return [] unless valid_search_term?
    words = sanitize_and_tokenize
    return [] if words.empty?

    relation = base_relation.limit(limit).offset(offset)
    conn = ActiveRecord::Base.connection

    build_groonga_queries(words).each do |groonga_query|
      results = execute_search(relation, conn, groonga_query, words)
      return populate_snippets(results, words) if results.any?
    end
    []
  end

  private

  # === Валидация и Токенизация ===

  def valid_search_term?
    return false if text.blank?
    return false if text.length > MAX_TEXT_LENGTH
    return false if text.length < min_length
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
    cjk = %w[jp-ni cn-ccbs zh ja ko].include?(lang)
    min_word_len = cjk ? 1 : 2
    clean.split(' ').select { |w| w.length >= min_word_len }
  end

  # === Логика Поиска (Стратегии) ===

  def build_groonga_queries(keywords)
    queries = []
    joined = keywords.join(' ')

    if true
      # тут учитывается близость слов друг ко другу на удалении N-слов
      queries << "*N#{PROXIMITY_DISTANCE}\"#{joined}\""
    else
      # слова не обязательно рядом другом с другом
      queries << "#{joined}"
    end

    queries
  end

  # === Работа с БД ===

  def base_relation
    sub_pages_ids = MENU_SERVICE.subpages_ids_of_page(start_page)

    rel = PAGE_PARAGRAPH_MODEL.preload(page_for_preview: :parent_for_preview)
    rel = rel.where(page_id: sub_pages_ids) if sub_pages_ids.present?
    rel = rel.where(lang: lang) if lang.present?
    rel
  end

  def execute_search(relation, conn, groonga_query, keywords)
    relation
      .select(
        :id, :page_id, :content,
        "pgroonga_score(tableoid, ctid) AS rank"
        # Подсветку вынес в отдельный запрос, чтобы не подсвечивать все совпадения в БД, а только совпадения для страницы
        # "pgroonga_highlight_html(content, pgroonga_query_extract_keywords('#{keywords.join(' ')}'), '#{index_name}') AS snippets_raw"
      )
      .where("content &@~ ?", groonga_query)
      .where(lang: start_page.lang) # чтобы подключился нужный индекс, так как добавили индексы условные
      .order("rank DESC")
      .to_a
  end

  def index_name
    # @tr_code == 'jp-ni' ? 'idx_page_paragraphs_content_mecab' : 'idx_page_paragraphs_content_default'
    'idx_page_paragraphs_content_default'
  end

  # === Пост-обработка: Сниппеты ===

  def populate_snippets(results, keywords)
    return results if results.blank?

    ids = results.map(&:id)
    # Один запрос на все сниппеты
    snippets_map = PAGE_PARAGRAPH_MODEL
      .where(id: ids)
      .select(
        :id,
        "pgroonga_highlight_html(content, pgroonga_query_extract_keywords('#{keywords.join(' ')}'), '#{index_name}') AS snippets_raw"
        # Сниппет, размером 1000 символов
        # "pgroonga_snippet_html(content, pgroonga_query_extract_keywords('#{keywords.join(' ')}'), 1000) AS snippets_raw"
      )
      .index_by(&:id)
      .transform_values(&:snippets_raw)

    results.each do |par|
      # Используем instance_variable вместо singleton_method для чистоты
      par.instance_variable_set(:@search_snippets, snippet_split_and_sort(snippets_map[par.id]) )
      par.define_singleton_method(:highlighted_snippets) { @search_snippets }
    end

    results
  end

  def snippet_split_and_sort highlighted_snippet
    return unless highlighted_snippet.present?

    snippets = [highlighted_snippet]
  end
end

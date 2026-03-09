class PageSearch
  # Конфигурация
  MAX_TEXT_LENGTH = 250
  MIN_LEN_BY_LANG = { 'jp-ni' => 2, 'cn-ccbs' => 2 }.freeze
  DEFAULT_MIN_LEN = 3

  PAGE_MODEL = ::Page
  MENU_SERVICE = ::Menu

  attr_reader :start_page, :text, :lang

  def initialize(start_page:, text:)
    @start_page = start_page
    @text = text
    @lang = start_page.lang
  end

  def count
    return 0 unless valid_search_term?

    relation = base_relation
    pg_dict = pg_dictionary
    safe_term = sanitize_term

    strategies(pg_dict, safe_term).each do |ts_query_sql|
      count = relation.where("body_tsvector @@ #{ts_query_sql}").count
      return count if count.positive?
    end

    0
  end

  def fetch_objects(offset: 0, limit: 20)
    return [] unless valid_search_term?

    relation = base_relation.limit(limit).offset(offset)
    pg_dict = pg_dictionary
    safe_term = sanitize_term

    strategies(pg_dict, safe_term).each do |ts_query_sql|
      results = execute_search(relation, pg_dict, ts_query_sql)
      return populate_snippets(results, pg_dict, ts_query_sql) if results.any?
    end

    []
  end

  private

  # === Валидация и Подготовка ===

  def valid_search_term?
    return false if text.blank?
    return false if text.length > MAX_TEXT_LENGTH
    return false if text.length < min_length
    true
  end

  def min_length
    MIN_LEN_BY_LANG.fetch(lang, DEFAULT_MIN_LEN)
  end

  def sanitize_term
    text.strip.gsub(/[^[[:alpha:]]\s\-\+]/, '').gsub(/\s+/, ' ').strip
  end

  def pg_dictionary
    ::LANG_TO_PG_LANGUAGE[lang.to_s.downcase] || 'simple'
  end

  # === Логика Поиска (Стратегии) ===

  # Возвращает массив SQL-выражений tsquery в порядке приоритета
  def strategies(pg_dict, term)
    words = term.split(' ')
    queries = []

    # 1. Exact (Phrase) - если слов много
    if words.size > 3
      queries << build_ts_query(pg_dict, words.join(' <-> '))
    end

    # 2. And (All words)
    queries << build_ts_query(pg_dict, words.join(' & '))

    # 3. Prefix (Fallback) - если слов мало
    if words.size < 3
      queries << build_ts_query(pg_dict, words.map { "#{_1}:*" }.join(' & '))
    end

    queries
  end

  def build_ts_query(pg_dict, query_text)
    # Безопасная санитизация SQL
    PAGE_MODEL.sanitize_sql_array(["to_tsquery(?, ?)", pg_dict, query_text])
  end

  # === Работа с БД ===

  def base_relation
    sub_pages_ids = MENU_SERVICE.subpages_ids_of_page(start_page)

    PAGE_MODEL
      .where(is_published: true, is_deleted: [nil, false])
      .tap { |r| r.where!(id: sub_pages_ids) if sub_pages_ids.present? }
      .tap { |r| r.where!(lang: lang) if lang.present? }
      .preload(:parent_for_preview)
  end

  def execute_search(relation, pg_dict, ts_query_sql)
    relation
      .select(
        :id, :h_id, :title, :path, :cover, :parent_id,
        "ts_rank(body_tsvector, #{ts_query_sql}) AS rank"
      )
      .where("body_tsvector @@ #{ts_query_sql}")
      .order("rank DESC")
      .to_a
  end

  # === Пост-обработка ===

  def populate_snippets(results, pg_dict, ts_query_sql)
    return results if results.blank?

    ids = results.map(&:id)
    # Один запрос на все сниппеты
    snippets_map = PAGE_MODEL
      .where(id: ids)
      .select("id", snippet_sql(pg_dict, ts_query_sql))
      .index_by(&:id)
      .transform_values(&:snippet)

    results.each do |page|
      # Используем instance_variable вместо singleton_method для чистоты
      page.instance_variable_set(:@search_snippet, snippets_map[page.id])
      page.define_singleton_method(:highlighted_snippet) { @search_snippet }
    end

    results
  end

  def snippet_sql(pg_dict, ts_query_sql)
    # Выносим конфигурацию сниппета в константу или метод
    <<-SQL.squish
      ts_headline(
        '#{pg_dict}',
        body_search,
        #{ts_query_sql},
        'StartSel=<strong>, StopSel=</strong>, MaxFragments=1, FragmentDelimiter=-%-, MinWords=10, MaxWords=30'
      ) AS snippet
    SQL
  end
end

class PageParagraphSearch
  # Конфигурация
  MAX_TEXT_LENGTH = 250
  MIN_LEN_BY_LANG = { 'jp-ni' => 2, 'cn-ccbs' => 2 }.freeze
  DEFAULT_MIN_LEN = 3

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

    relation = base_relation
    pg_dict = pg_dictionary
    safe_term = sanitize_term

    strategies(pg_dict, safe_term).each do |ts_query_sql|
      count = relation.where("content_tsvector @@ #{ts_query_sql}").count
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
      queries << build_ts_phrase(pg_dict, words.join(' '))
    end

    # 2. And (All words)
    queries << build_ts_query(pg_dict, words.join(' & '))

    # 3. Prefix (Fallback) - если слов мало
    if words.size.between?(1, 3)
      queries << build_ts_query(pg_dict, words.map { "#{_1}:*" }.join(' & '))
    end

    queries
  end

  def build_ts_query(pg_dict, query_text)
    # Безопасная санитизация SQL
    PAGE_PARAGRAPH_MODEL.sanitize_sql_array(["to_tsquery(?, ?)", pg_dict, query_text])
  end

  def build_ts_phrase(pg_dict, query_text)
    # https://www.postgresql.org/docs/current/textsearch-controls.html
    PAGE_PARAGRAPH_MODEL.sanitize_sql_array(["phraseto_tsquery(?, ?)", pg_dict, query_text])
  end

  # === Работа с БД ===

  def base_relation
    sub_pages_ids = MENU_SERVICE.subpages_ids_of_page(start_page)

    rel = PAGE_PARAGRAPH_MODEL.preload(page_for_preview: :parent_for_preview)
    rel = rel.where(page_id: sub_pages_ids) if sub_pages_ids.present?
    rel = rel.where(lang: lang) if lang.present?
    rel
  end

  def execute_search(relation, pg_dict, ts_query_sql)
    relation
      .select(
        :id, :page_id, :content,
        "ts_rank(content_tsvector, #{ts_query_sql}) AS rank"
      )
      .where("content_tsvector @@ #{ts_query_sql}")
      .order("rank DESC")
      .to_a
  end

  # === Пост-обработка ===

  def populate_snippets(results, pg_dict, ts_query_sql)
    return results if results.blank?

    ids = results.map(&:id)
    # Один запрос на все сниппеты
    snippets_map = PAGE_PARAGRAPH_MODEL
      .where(id: ids)
      .select(:id, snippet_sql(pg_dict, ts_query_sql))
      .index_by(&:id)
      .transform_values(&:snippet)

    results.each do |par|
      # Используем instance_variable вместо singleton_method для чистоты
      par.instance_variable_set(:@search_snippets, snippet_split_and_sort(snippets_map[par.id]) )
      par.define_singleton_method(:highlighted_snippets) { @search_snippets }
    end

    results
  end

  def snippet_sql(pg_dict, ts_query_sql)
    # Выносим конфигурацию сниппета в константу или метод
    <<-SQL.squish
      ts_headline(
        '#{pg_dict}',
        content,
        #{ts_query_sql},
        'StartSel=<strong>, StopSel=</strong>, MaxFragments=1, FragmentDelimiter=-%-, MinWords=10, MaxWords=100'
      ) AS snippet
    SQL
  end

  # принимает строку от БД, с разделителями "-%-" и поддсветкой тэгами <strong> (см. метод snippet_sql)
  # отдаёт массив (делит строку по "-%-"), осортированный по наиболее хорошим совпадениям (считает strong)
  def snippet_split_and_sort highlighted_snippet
    return unless highlighted_snippet.present?

    snippets = [highlighted_snippet]

    # snippets = highlighted_snippet.to_s.split('-%-')

    # # считаем только разные слова (uniq)
    # snippets_with_rank = snippets.map { |s| [s, s.scan(/<strong>(.*?)<\/strong>/).flatten.uniq.count] }

    # if snippets.count > 1
    #   # сколько слов в поисковой фразе
    #   search_words_count = @text.split(' ').count
    #   min_words_in_snippet = case search_words_count
    #   when ..2
    #     search_words_count
    #   when 3..4
    #     search_words_count - 1
    #   when 5..7
    #     search_words_count - 2
    #   else
    #     search_words_count - 3
    #   end

    #   filtered = snippets_with_rank.select { |_, rank| rank >= min_words_in_snippet }
    #   snippets_with_rank = filtered if filtered.any?
    # end

    # snippets_with_rank.sort_by { |_, rank| rank }
    # snippets_with_rank.map(&:first)
  end
end

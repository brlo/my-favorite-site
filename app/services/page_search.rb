class PageSearch
  # возвращает минимальную длинную слова для поиска, с учётом языка
  def self.min_len(lang)
    # японские иероглифы разрешаем искать в кол-ве 2 шт.
    (lang == 'jp-ni' || lang == 'cn-ccbs') ? 2 : 3
  end

  attr_reader :start_page, :text

  def initialize start_page:, text:
    @start_page = start_page
    @text = text
    @lang = @start_page.lang
  end

  # === Кастомный метод поиска с поддержкой языка и сниппетами ===
  # PageSearch.new(text: 'православная', start_page: @page).fetch_objects(10).to_a.first.snippet
  # PageSearch.new(text: 'святая православная церковь', start_page: @page).fetch_objects(10).to_a.last.snippet
  # PageSearch.new(text: 'ορθοδ', start_page: @page).fetch_objects(10).to_a.last.snippet
  def fetch_objects(count)
    # не ищем меньше 3 символов и больше 120
    min_len = ::PageSearch.min_len(@lang)
    return [] if @text.blank? || @text.length < min_len || @text.length > 250

    # словарь (язык), который должен использовать PG при организации поиска
    pg_dict = ::LANG_TO_PG_LANGUAGE[@lang.to_s.downcase]

    # оставляем только допустимые символы, экранируем
    safe_term = @text.strip.gsub(/[^[[:alpha:]]\s\-\+]/, '').gsub(/\s+/, ' ').strip

    # начальная страница
    # sub_pages = [@start_page]
    # плюс все дочерние
    sub_pages_ids = ::Menu.subpages_ids_of_page(@start_page)

    # ПОИСК
    relation = ::Page.where(is_published: true, is_deleted: [nil, false])
    relation = relation.select(:id, :h_id, :title, :cover, :parent_id)
    relation = relation.preload(:parent_for_preview)
    relation = relation.where(id: sub_pages_ids) if sub_pages_ids.present?
    relation = relation.where(lang: @lang) if @lang.present?
    relation = relation.limit(count)

    pages = search_with_snippet(safe_term, pg_dict: pg_dict, relation: relation)
    pages
  end

  private

  def search_with_snippet(term, pg_dict: nil, relation: nil)
    if term.split(' ').size > 3
      results = exact_query(term, pg_dict, relation)
      return results if results.any?
    end

    results = and_query(term, pg_dict, relation)
    # return results if results.any?

    # results = websearch_query(term, pg_dict, relation)
    # return results if results.any?

    # # Если это был сложный поиск по лексемам и он не дал результата, то попытаемся
    # # воспользоваться простым поиском по префиксу, ведь, возможно, ввели неполное слово "православ",
    # # от которого не получилось взять лексему.
    # if results.blank? && pg_dict != 'simple'
    #   # раз результатов нет по сложному алгоритму (лексемы), то попробуем простой алгоритм (simple)
    #   ts_query_sql = simple_algo(term, 'simple')
    #   results = make_a_fulltext_query(relation, pg_dict, ts_query_sql)
    # else
    #   results
    # end
  end

  def exact_query term, pg_dict, relation
    query_term = term.split(' ').map { "#{_1}" }.join(' <-> ')
    ts_query_sql = "to_tsquery('#{pg_dict}', #{quoted(query_term)})"

    results = make_a_fulltext_query(relation, pg_dict, ts_query_sql)
    results
  end

  def and_query term, pg_dict, relation
    query_term = term.split(' ').map { "#{_1}:*" }.join(' & ')
    ts_query_sql = "to_tsquery('#{pg_dict}', #{quoted(query_term)})"

    results = make_a_fulltext_query(relation, pg_dict, ts_query_sql)
    results
  end

  def websearch_query term, pg_dict, relation
    # unquoted text: text not inside quote marks will be converted to terms separated by & operators, as if processed by plainto_tsquery.
    # "quoted text": text inside quote marks will be converted to terms separated by <-> operators, as if processed by phraseto_tsquery.
    # OR:            the word “or” will be converted to the | operator.
    # -:             a dash will be converted to the ! operator.
    ts_query_sql = "websearch_to_tsquery('#{pg_dict}', #{quoted(term)})"

    # if pg_dict == 'simple'
    #   # поиск по префиксу
    #   # tsquery operators & (AND), | (OR), ! (NOT), and <-> (FOLLOWED BY)
    #   "to_tsquery(#{pg_dict}, #{quoted_term})"
    # else
    #   # поиск по лексемам
    #   "plainto_tsquery(#{pg_dict}, #{quoted_term})"
    # end

    results = make_a_fulltext_query(relation, pg_dict, ts_query_sql)
    results
  end

  # - Параметры форматирования:
  #   * StartSel=<mark>, StopSel=</mark> - оборачивание совпадений в HTML-теги
  #   * MaxFragments=100 - максимальное количество фрагментов
  #   * FragmentDelimiter=... - разделитель между фрагментами (многоточие)
  #   * MaxWords=60, MinWords=20 - ограничения длины фрагментов
  def make_a_fulltext_query relation, pg_dict, ts_query_sql
    relation ||= ::Page
    relation
      .select(
        "pages.*",
        "ts_rank_cd(body_tsvector, #{ts_query_sql}) AS rank",
        "ts_headline('#{pg_dict}', body_search, #{ts_query_sql}, " \
          "'StartSel=<strong>, StopSel=</strong>, MaxFragments=1, " \
          "FragmentDelimiter=-%-, MinWords=10, MaxWords=30') AS snippet"
      )
      .where("body_tsvector @@ #{ts_query_sql}")
      .order("rank DESC")
  end

  def quoted term
    ::Page.connection.quote(term)
  end
end

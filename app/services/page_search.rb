class PageSearch
  # возвращает минимальную длинную слова для поиска, с учётом языка
  def self.min_len(lang)
    # японские иероглифы разрешаем искать в кол-ве 2 шт.
    (lang == 'jp-ni' || lang == 'cn-ccbs') ? 2 : 3
  end

  attr_reader :page, :text

  def initialize page:, text:
    @page = page
    @text = text
    @lang = @page.lang
  end

  def fetch_objects(count)
    # не ищем меньше 3 символов и больше 120
    min_len = ::PageSearch.min_len(@lang)
    return [] if @text.blank? || @text.length < min_len || @text.length > 120

    # начальная страница
    # sub_pages = [@page]
    # плюс все дочерние
    sub_pages_ids = ::Menu.subpages_ids_of_page(@page)

    # ПОИСК
    relation = ::Page.where(is_published: true, is_deleted: [nil, false])
    relation = relation.where(id: sub_pages_ids) if sub_pages_ids.present?
    relation = relation.where(lang: @lang) if @lang.present?
    relation = relation.limit(count)

    # оставляем только буквы, пробелы, тире (кто-то, что-то)
    clean_text = @text.gsub(/[^[[:alpha:]]\s\-]/, '').gsub(/\s+/, ' ').strip

    pages = search_with_snippet(clean_text, lang: @lang, relation: relation)
    pages
  end

  private

  # === Кастомный метод поиска с поддержкой языка и сниппетами ===
  # NewPage.search_with_snippet('православная', lang: 'ru').to_a.first.snippet
  # NewPage.search_with_snippet('святая православная церковь', lang: 'ru').to_a.last.snippet
  # NewPage.search_with_snippet('ορθοδ', lang: 'grc').to_a.last.snippet
  def search_with_snippet(term, lang: nil, relation: nil)
    pg_dict = ::LANG_TO_PG_LANGUAGE[lang.to_s.downcase]

    quoted_dict, ts_query_sql = algo_for_fulltext_search(term, pg_dict)
    results = make_a_fulltext_query(relation, quoted_dict, ts_query_sql)

    # Если это был сложный поиск по лексемам и он не дал результата, то попытаемся
    # воспользоваться простым поиском по префиксу, ведь, возможно, ввели неполное слово "православ",
    # от которого не получилось взять лексему.
    if results.blank? && pg_dict != 'simple'
      # раз результатов нет по сложному алгоритму (лексемы), то попробуем простой алгоритм (simple)
      quoted_dict, ts_query_sql = algo_for_fulltext_search(term, 'simple')
      results = make_a_fulltext_query(relation, quoted_dict, ts_query_sql)
    else
      results
    end
  end


  def algo_for_fulltext_search term, pg_dict
    safe_term = pg_dict == 'simple' ? "#{term}:*" : term

    quoted_dict = ::Page.connection.quote(pg_dict)
    quoted_term = ::Page.connection.quote(safe_term)

    ts_query_sql =
    if pg_dict == 'simple'
      # поиск по префиксу
      "to_tsquery(#{quoted_dict}, #{quoted_term})"
    else
      # поиск по лексемам
      "plainto_tsquery(#{quoted_dict}, #{quoted_term})"
    end

    [quoted_dict, ts_query_sql]
  end

  #    - Параметры форматирования:
  #      * StartSel=<mark>, StopSel=</mark> - оборачивание совпадений в HTML-теги
  #      * MaxFragments=100 - максимальное количество фрагментов
  #      * FragmentDelimiter=... - разделитель между фрагментами (многоточие)
  #      * MaxWords=60, MinWords=20 - ограничения длины фрагментов
  def make_a_fulltext_query relation, quoted_dict, ts_query_sql
    relation ||= ::Page
    relation
      .select(
        "pages.*",
        "ts_rank_cd(body_tsvector, #{ts_query_sql}) AS rank",
        "ts_headline(#{quoted_dict}, body_search, #{ts_query_sql}, " \
          "'StartSel=<mark>, StopSel=</mark>, MaxFragments=100, " \
          "FragmentDelimiter=-%-, MaxWords=30, MinWords=10') AS snippet"
      )
      .where("body_tsvector @@ #{ts_query_sql}")
      .order("rank DESC")
  end
end

class VerseSearch
  # возвращает минимальную длинную слова для поиска, с учётом языка
  def self.min_len(tr_code)
    # японские иероглифы разрешаем искать в кол-ве 2 шт.
    (tr_code == 'jp-ni' || tr_code == 'cn-ccbs') ? 2 : 3
  end

  attr_reader :text, :tr_code, :book, :accuracy

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
  end

  # === Кастомный метод поиска с поддержкой языка и сниппетами ===
  # VerseSearch.new(text: 'православная', tr_code: 'ru').fetch_objects(10).to_a.first.snippet
  # VerseSearch.new(text: 'ορθοδ', tr_code: 'ru').fetch_objects(10).to_a.last.snippet
  def fetch_objects(count)
    # названия книг валидны?
    if @search_books.present?
      return [] unless @search_books.all? { |b| ::BOOKS.has_key?(b) }
    end

    # названия переводом Библии валидны?
    if ::CacheSearch::SEARCH_LANGS.exclude?(tr_code)
      return []
    end

    # не ищем меньше 3 символов и больше 120
    min_len = ::VerseSearch.min_len(@lang)
    return [] if @text.blank? || @text.length < min_len || @text.length > 250

    # язык, основываясь на навании перевода Библии
    lang = ::BIB_LANG_TO_LOCALE[tr_code.to_s]

    # словарь (язык), который должен использовать PG при организации поиска
    pg_dict = ::LANG_TO_PG_LANGUAGE[lang.to_s.downcase]


    # оставляем только допустимые символы, экранируем
    safe_term = @text.strip.gsub(/[^[[:alpha:]]\s\-\+]/, '').gsub(/\s+/, ' ').strip

    # ПОИСК
    relation = ::Verse.select(:id)
    relation = relation.where(tr_code: @tr_code) if @tr_code.present?
    relation = relation.where(book: @search_books) if @search_books.present?
    relation = relation.where(zavet: @zavet) if !@zavet.nil?
    relation = relation.limit(count)

    verses = search_with_snippet(safe_term, pg_dict: pg_dict, relation: relation)
    verses
  end

  private

  def search_with_snippet(term, pg_dict: nil, relation: nil)
    if term.split(' ').size > 3 || @accuracy == 'exact'
      results = exact_query(term, pg_dict, relation)
      return results if results.any?
    end

    results = and_query(term, pg_dict, relation)
    # return results if results.any?

    # results = websearch_query(term, pg_dict, relation)
    # return results if results.any?
  end

  def exact_query term, pg_dict, relation
    query_term = term.split(' ').join(' <-> ')
    ts_query_sql = "to_tsquery('#{pg_dict}', #{quoted(query_term)})"

    results = make_a_fulltext_query(relation, pg_dict, ts_query_sql)
    results
  end

  def and_query term, pg_dict, relation
    query_term = term.split(' ').join(' & ')
    ts_query_sql = "to_tsquery('#{pg_dict}', #{quoted(query_term)})"
    results = make_a_fulltext_query(relation, pg_dict, ts_query_sql)

    # попробум поискать через префиксы, вдруг пользователь ввёл неполное слово, для которого не получается подобрать лексему
    if results.empty? && term.split(' ').size < 3
      query_term = term.split(' ').map { "#{_1}:*" }.join(' & ')
      ts_query_sql = "to_tsquery('#{pg_dict}', #{quoted(query_term)})"
      results = make_a_fulltext_query(relation, pg_dict, ts_query_sql).to_a
    end

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
    relation ||= ::Verse
    relation
      .select(
        "verses.*",
        "ts_headline('#{pg_dict}', text_search, #{ts_query_sql}, " \
          "'StartSel=<strong>, StopSel=</strong>, MaxFragments=1, " \
          "FragmentDelimiter=-%-, MinWords=3, MaxWords=60') AS snippet"
      )
      .where("text_tsvector @@ #{ts_query_sql}")
      .order("id ASC")
      .to_a

    # puts "Поиск совпадений среди:"
    # puts relation.count
    # puts

    # С РАССЧЕТОМ И СОРТИРОВКОЙ ПО РАНГУ (колву совпавших слов)
    # relation = relation
    #   .select(
    #     "verses.*",
    #     "ts_rank_cd(text_tsvector, #{ts_query_sql}) AS rank",
    #     "ts_headline(#{pg_dict}, text_search, #{ts_query_sql}, " \
    #       "'StartSel=<mark>, StopSel=</mark>, MaxFragments=100, " \
    #       "FragmentDelimiter=..., MaxWords=60, MinWords=20') AS snippet"
    #   )
    #   .where("text_tsvector @@ #{ts_query_sql}")
    #   .order("rank DESC")
  end

  def quoted term
    ::Verse.connection.quote(term)
  end
end

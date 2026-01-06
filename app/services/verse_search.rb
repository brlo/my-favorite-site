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
    @accuracy = accuracy # точность

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

  def fetch_objects(count)
    # названия книг валидны?
    if @search_books.present?
      return [] unless @search_books.all? { |b| ::BOOKS.has_key?(b) }
    end

    # названия переводом Библии валидны?
    if ::CacheSearch::SEARCH_LANGS.exclude?(tr_code)
      return []
    end

    # не ищем меньше 3 символов и больше 100
    min_len = ::VerseSearch.min_len(tr_code)
    return [] if @text.blank? || @text.length < min_len

    # добываем
    relation = ::Verse
    relation = relation.where(tr_code: @tr_code) if @tr_code.present?
    relation = relation.where(book: @search_books) if @search_books.present?
    relation = relation.where(zavet: @zavet) if !@zavet.nil?
    relation = relation.limit(count)

    # оставляем только буквы, пробелы, тире (кто-то, что-то)
    clean_text = @text.gsub(/[^[[:alpha:]]\s\-]/, '').gsub(/\s+/, ' ').strip
    lang = ::BIB_LANG_TO_LOCALE[tr_code.to_s]

    verses = search_with_snippet(clean_text, lang: lang, relation: relation)
    verses
  end

  private

  # === Кастомный метод поиска с поддержкой языка и сниппетами ===
  # VerseSearch.search_with_snippet('православная', tr_code: 'ru').to_a.first.snippet
  # VerseSearch.search_with_snippet('святая православная церковь', tr_code: 'ru').to_a.last.snippet
  # VerseSearch.search_with_snippet('ορθοδ', tr_code: '...').to_a.last.snippet
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

    quoted_dict = ::Verse.connection.quote(pg_dict)
    quoted_term = ::Verse.connection.quote(safe_term)

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
    relation ||= ::Verse
    relation
      .select(
        "verses.*",
        "ts_headline(#{quoted_dict}, text_search, #{ts_query_sql}, " \
          "'StartSel=<mark>, StopSel=</mark>, MaxFragments=100, " \
          "FragmentDelimiter=-%-, MaxWords=30, MinWords=10') AS snippet"
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
    #     "ts_headline(#{quoted_dict}, text_search, #{ts_query_sql}, " \
    #       "'StartSel=<mark>, StopSel=</mark>, MaxFragments=100, " \
    #       "FragmentDelimiter=..., MaxWords=60, MinWords=20') AS snippet"
    #   )
    #   .where("text_tsvector @@ #{ts_query_sql}")
    #   .order("rank DESC")
  end
end

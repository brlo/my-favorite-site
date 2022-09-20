class VerseSearch
  attr_reader :params
  # params: {
  #   text: @search_text,
  #   book: @search_books,
  #   accuracy: @search_accuracy,
  #   lang: 'ru'
  # }
  def initialize params
    @params = params
  end

  def fetch_objects(count)
    # инициализация
    text = params[:text].to_s
    accuracy = params[:accuracy]
    lang = params[:lang]
    zavet = nil
    book = nil

    _book = params[:book]
    if _book.present?
      if _book == 'z1'
        zavet = 1
      elsif _book == 'z2'
        zavet = 2
      else
        book = _book
      end
    end

    # валидации
    if book.present?
      return [] unless ::BOOKS.has_key?(book)
    end

    return [] unless lang == 'ru'

    # фильтрация
    text = ::CacheSearch.safe_term(text)

    # не ищем меньше 3 символов и больше 100
    return [] unless text.present? && text.length > 2

    # подготовка запроса с предварительной проверкой результата в кэше
    verses_json =
    begin
    # ::CacheSearch.get(text, accuracy, lang) do
      # готовим запрос
      search_params = prepare_search_params(text, accuracy, lang)

      # https://www.mongodb.com/docs/mongoid/master/reference/text-search/
      # https://www.mongodb.com/docs/manual/core/link-text-indexes/

      # добываем
      verses = ::Verse.where(
        **search_params
      ).limit(count).order_by(book_id: 1, chapter: 1, line: 1).to_a

      # переводим в json (для однообразности, потому что из кэша получаем тоже в json)
      verses.map { |v| v.as_json(only: %i(a bc bid ch l lang t z)) }
    end

    # в кэш положили поиск по всем книгам, но клиенту может быть нужен фильтр
    verses_json = verses_json.select { |v| v['z'] == zavet } if zavet
    verses_json = verses_json.select { |v| v['bc'] == book } if book

    verses_json
  end

  def prepare_search_params text, accuracy, lang
    search_params = {lang: lang}
    # оставляем только буквы и пробелы (кто-то, что-то)
    clean_text = text.gsub(/[^[[:alpha:]]\s\-]/, '').gsub(/\s+/, ' ').strip

    if accuracy == 'exact'
      # точное совпадение (пишем в кавычках)
      search_params['$text'] = {'$search' => "\"#{ text }\""}
    elsif accuracy == 'similar'
      # похожая фраза (когда будет готово отдельное поле, перейти на него)
      arr = clean_text.split(' ').first(5)
      regex = arr.map { |w| len = [2, w.length-3].max; w[0..len] }.join('[A-ZА-ЯΑ-Ωא-ת\,\.\-\s\!\?\:\;]+')
      search_params['text'] = /#{regex}/i
    elsif accuracy == 'partial'
      # часть слова
      regex = text.gsub(/[^[[:alpha:]]\s]/, '').gsub(/\s+/, ' ').strip
      search_params['text'] = /#{regex}/i
    end

    puts "==="
    puts "search_params: #{search_params}"
    puts "==="
    search_params
  end
end

class VerseSearch
  RU_WORD_ENDS_REGEXP = /(ими|ыми|ами|ями|ому|ему|ого|его|ешь|ишь|ете|ите|их|ых|ий|ый|ая|яя|ое|ую|юю|ее|ие|ые|ой|ей|им|ым|ом|ос|ем|ик|ек|ок|ть|ет|ут|ют|ит|ат|ят|о|а|у|и|е|ы|ю|я|ь)$/i
  EN_WORD_ENDS_REGEXP = /(ing|er|ed|es|s)$/i

  # возвращает минимальную длинную слова для поиска, с учётом языка
  def self.min_len(lang)
    # японские иероглифы разрешаем искать в кол-ве 2 шт.
    (lang == 'jp-ni' || lang == 'cn-ccbs') ? 2 : 3
  end

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
    books = nil

    _book = params[:book]
    if _book.present?
      if _book == 'z1'
        zavet = 1
      elsif _book == 'z2'
        zavet = 2
      elsif _book == 'e4'
        books = %w(mf mk lk in)
      else
        books = [_book]
      end
    end

    # валидации
    if books.present?
      return [] unless books.all? { |b| ::BOOKS.has_key?(b) }
    end

    if ::CacheSearch::SEARCH_LANGS.exclude?(lang)
      return []
    end

    cache_search_service = ::CacheSearch.new
    # фильтрация
    text = cache_search_service.safe_term(text)

    # не ищем меньше 3 символов и больше 100
    min_len = ::VerseSearch.min_len(lang)
    return [] unless text.present? && text.length >= min_len

    # подготовка запроса с предварительной проверкой результата в кэше
    verses_json =
    # begin
    cache_search_service.get(text, accuracy, lang) do
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
    verses_json = verses_json.select { |v| books.include?(v['bc']) } if books.present?

    verses_json
  end

  def prepare_search_params text, accuracy, lang
    search_params = {lang: lang}

    # меняем Ё на Е
    text = text.gsub(/ё/i, 'е')
    # оставляем только буквы и пробелы (кто-то, что-то)
    clean_text = text.gsub(/[^[[:alpha:]]\s\-]/, '').gsub(/\s+/, ' ').strip

    # с этими языками никаких манипуляций не предпринимаем.
    # Там пробелов нет, иероглифы, что там с окончаниями я вообще не знаю
    if %w(jp-ni cn-ccbs arab-avd).include?(lang)
      clean_text = clean_text.to_s.first(150)
      search_params['text'] = /#{clean_text}/i
      return search_params
    end

    if accuracy == 'exact'
      # точное совпадение (пишем в кавычках)
      arr = clean_text.split(' ').first(5)
      regex = arr.join('[\,\.\-\s\!\?\:\;]+')
    elsif accuracy == 'similar'
      # похожая фраза (когда будет готово отдельное поле, перейти на него)
      arr = clean_text.split(' ').first(5)

      regex =
      case lang()
      when 'ru'
        arr.map do |w|
          # убираем окончание если оно есть И от слова остаётся больше 3-х букв
          _w = w.sub(RU_WORD_ENDS_REGEXP, '')
          _w.length > 3 ? _w : w
        end.join('[А-ЯЁ\,\.\-\s\!\?\:\;]+')
      when 'en-nrsv', 'eng-nkjv'
        arr.map do |w|
          # убираем окончание если оно есть И от слова остаётся больше 3-х букв
          _w = w.sub(EN_WORD_ENDS_REGEXP, '')
          _w.length > 3 ? _w : w
        end.join('[A-Z\,\.\-\s\!\?\:\;]+')
      when 'csl-pnm', 'csl-ru'
        arr.map { |w| len = [4, w.length-2].max; w[0..len-1] }.join('[А-ЯЁ\,\.\-\s\!\?\:\;]+')
      when 'heb-osm'
        arr.map { |w| len = [4, w.length-2].max; w[0..len-1] }.join('[א-ת\,\.\-\s\!\?\:\;]+')
      when 'gr-lxx-byz'
        arr.map { |w| len = [4, w.length-2].max; w[0..len-1] }.join('[Α-Ω\,\.\-\s\!\?\:\;]+')
      else
        arr.map { |w| len = [4, w.length-2].max; w[0..len-1] }.join('[\p{Alnum}\,\.\-\s\!\?\:\;]+')
      end
    end

    search_params['text'] = /#{regex}/i

    # puts "==="
    # puts "search_params: #{search_params}"
    # puts "==="
    search_params
  end

  private

  def lang
    @params[:lang]
  end
end

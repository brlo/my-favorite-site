class PageSearch
  RU_WORD_ENDS_REGEXP = /(ими|ыми|ами|ями|ому|ему|ого|его|ешь|ишь|ете|ите|их|ых|ий|ый|ая|яя|ое|ую|юю|ее|ие|ые|ой|ей|им|ым|ом|ос|ем|ик|ек|ок|ть|ет|ут|ют|ит|ат|ят|о|а|у|и|е|ы|ю|я|ь)$/i
  EN_WORD_ENDS_REGEXP = /(ing|er|ed|es|s)$/i

  # возвращает минимальную длинную слова для поиска, с учётом языка
  def self.min_len(lang)
    # японские иероглифы разрешаем искать в кол-ве 2 шт.
    (lang == 'jp-ni' || lang == 'cn-ccbs') ? 2 : 3
  end

  attr_reader :params
  # params: {
  #   page: @page,
  #   text: @search_text
  # }
  def initialize params
    @params = params
  end

  def fetch_objects(count)
    @page = params[:page]

    # инициализация
    text = params[:text].to_s
    lang = @page.lang

    # не ищем меньше 3 символов и больше 120
    min_len = ::PageSearch.min_len(lang)
    return [[], nil] if text.blank?
    return [[], nil] if text.length < min_len
    return [[], nil] if text.length > 120

    # готовим регулярки для запроса (там на каждое слово запроса будет регулярка, и мы каждую из них будем искать в предложениях)
    regexes_arr = prepare_search_regexp(text, lang)

    # начальная страница
    sub_pages = [@page]
    # плюс все дочерние
    sub_pages += ::Menu.subpages_of_page(@page, limit: count)

    # ПОИСК
    matches = []
    sub_pages.each do |pg|
      matches += find_in_page(pg, regexes_arr)
    end

    [matches, regexes_arr]
  end

  def prepare_search_regexp(text, lang)
    # меняем Ё на Е
    text = text.gsub(/ё/i, 'е')
    # оставляем только буквы и пробелы (кто-то, что-то)
    clean_text = text.gsub(/[^[[:alpha:]]\s\-]/, '').gsub(/\s+/, ' ').strip

    # с этими языками никаких манипуляций не предпринимаем.
    # Там пробелов нет, иероглифы, что там с окончаниями я вообще не знаю
    if %w(jp-ni cn-ccbs arab-avd).include?(lang)
      clean_text = clean_text.to_s.first(150)
      regexes = [/#{clean_text}/i]
      return regexes
    end

    if 'accuracy' == 'exact'
      # точное совпадение (пишем в кавычках)
      arr = clean_text.split(' ').first(5)
      regexes = arr.map { _1.to_s + '[\,\.\-\s\!\?\:\;]+' }
    else
      # похожая фраза (когда будет готово отдельное поле, перейти на него)
      arr = clean_text.split(' ').first(10)

      regexes =
      case lang()
      when 'ru'
        arr.map do |w|
          # убираем окончание если оно есть И от слова остаётся больше 3-х букв
          _w = w.sub(RU_WORD_ENDS_REGEXP, '')
          _w = _w.length > 3 ? _w : w
          '\b' + _w + '[\p{Alnum}]{0,4}\b'
        end
      when 'eng-nkjv'
        arr.map do |w|
          # убираем окончание если оно есть И от слова остаётся больше 3-х букв
          _w = w.sub(EN_WORD_ENDS_REGEXP, '')
          _w = _w.length > 3 ? _w : w
          _w + '[A-Z\,\.\-\s\!\?\:\;]+'
        end
      when 'csl-pnm', 'csl-ru'
        arr.map { |w| len = [4, w.length-2].max; w[0..len-1] }.map { _1 + '[А-ЯЁ\,\.\-\s\!\?\:\;]+' }
      when 'heb-osm'
        arr.map { |w| len = [4, w.length-2].max; w[0..len-1] }.map { _1 + '[א-ת\,\.\-\s\!\?\:\;]+' }
      when 'gr-lxx-byz'
        arr.map { |w| len = [4, w.length-2].max; w[0..len-1] }.map { _1 + '[Α-Ω\,\.\-\s\!\?\:\;]+' }
      else
        arr.map { |w| len = [4, w.length-2].max; w[0..len-1] }.map { _1 + '[\p{Alnum}\,\.\-\s\!\?\:\;]+' }
      end
    end

    search_regexes = regexes.map { /#{_1}/i }

    # puts "==="
    # puts "search_params: #{search_params}"
    # puts "==="
    search_regexes
  end

  private

  def find_in_page(page, regexes_arr)
    return [] if page.body_search.blank?

    matches = []

    # ищем в названии страницы
    if regexes_arr.all? { |reg| page.title =~ reg }
      matches << {
        path: page.path,
        title: page.title,
        text: page.title,
      }
    end

    # ищем в содержимом тексте
    page.body_search.each do |sentence|
      if regexes_arr.all? { |reg| sentence =~ reg }
        matches << {
          path: page.path,
          title: page.title,
          text: sentence,
        }
      end
    end
    matches
  end

  def lang
    @page.lang
  end
end

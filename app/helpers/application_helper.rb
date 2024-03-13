module ApplicationHelper
  # размеры текста для пользователя (выбирается в шапке)
  TEXT_SIZES = {
    '1' => 'small',
    '2' => 'medium',
    '3' => 'large',
    nil => 'small'
  }

  PAGES_LANGS = {
    'ru' => true,
    'en' => true,
    'gr' => true,
    'il' => true,
    'ar' => true,
    'jp' => true,
    'cn' => true,
    'de' => true,
  }

  # Название перевода Библии переводим в I18n.locale
  LANG_CONTENT_TO_LANG_UI = {
    'ru'         => 'ru',
    'eng-nkjv'   => 'en',
    'csl-ru'     => 'ru',
    'csl-pnm'    => 'ru',
    'heb-osm'    => 'il',
    'gr-lxx-byz' => 'gr',
    'gr-ru'      => 'ru',
    'jp-ni'      => 'jp',
    'cn-ccbs'    => 'cn',
    'ge-sch'     => 'de',
    'arab-avd'   => 'ar',
  }

  # I18n.locale переводим в название перевода Библии
  LANG_UI_TO_LANG_CONTENT = {
    # 'cs' => 'csl-ru',
    ''   => 'ru',
    nil  => 'ru',
    'ru' => 'ru',
    'en' => 'eng-nkjv',
    'il' => 'heb-osm',
    'gr' => 'gr-lxx-byz',
    'jp' => 'jp-ni',
    'cn' => 'cn-ccbs',
    'de' => 'ge-sch',
    'ar' => 'arab-avd',
  }

  # ПОЯСНЕНИЕ:
  #
  # В Билейской части сайта у нас всегда указано в path локаль и язык текста Библии:
  # /ru/en-nkjv/...
  # Первое определяем с помощью I18n.locale, а второе с помощью current_bib_lang()
  #
  # В страницах (pages) не так. Там нет перевода Библии,
  # поэтому и локаль и язык статьи указываются одинаково:
  # /en/en/w/название_статьи
  # Первое определяем с помощью I18n.locale, а второе с помощью current_lang()
  #

  # Подобрать ЯЗЫК UI подходящий к текущему преводу Библии
  def locale_for_content_lang content_lang = nil
    LANG_CONTENT_TO_LANG_UI[content_lang || params[:content_lang]]
  end

  # НАЗВАНИЕ ПЕРЕВОДА БИБЛИИ (язык интерфейса определяй просто по I18n.locale)
  #
  # Алгоритм, коротко:
  # 1) Прямо указан известный язык Библии в params[:content_lang]
  # 2) Смогли подобрать подходящий язык Библии по неизвестному params[:content_lang]
  # 3) Смогли подобрать подходящий язык Библии по языку UI params[:locale]
  def current_bib_lang
    # Если указанный для контента язык известен как один из переводов Библии, используем его.
    # Иначе определяем язык Библии по локали.
    @current_bib_lang ||= begin
      if params[:content_lang].present?
        # Язык контента указан и такой язык есть в Библии
        if LANG_CONTENT_TO_LANG_UI.has_key?(params[:content_lang])
          params[:content_lang]
        else
          # Если смотрим Page, то язык контента не совпадает с языками Библии.
          # Вот так подбираем подходящий язык Библии:
          LANG_UI_TO_LANG_CONTENT[params[:content_lang]]
        end
      elsif params[:locale].present?
        # Если язык контента совсем не указан, то определяем язык контента по языку интерфейса
        LANG_UI_TO_LANG_CONTENT[params[:locale]]
      end
    end
  end

  # Язык контента для Page (язык интерфейса определяй просто по I18n.locale)
  def current_lang
    # Если явно указан язык контента и он валиден — берём его — params[:content_lang],
    # а иначе берём одноимённое название локали (языка интерфейса).
    @current_lang ||=
    if PAGES_LANGS[params[:content_lang]]
      params[:content_lang]
    else
      params[:locale]
    end
  end

  # Очистка одного стиха от спец. символов в конце (для поисковой страницы)
  def verse_alone_clean text
    if text[-1] =~ /[\.\,\-\;\:]/
      text[0..-2]
    else
      text
    end
  end

  # Пользовательский размер текста из кук
  def text_size_from_cookies
    # Определяем размер текста по кукам.
    # Если в куках пусто или непонятно что, то берём значение по-умолчанию
    @text_size_from_cookies ||= TEXT_SIZES[cookies[:textSize]] || TEXT_SIZES[nil]
  end

  # Делает ссылку с указанной локалью (текущей)
  def my_link_to(path)
    "/#{I18n.locale}#{path}"
  end

  # А КАК ЖЕ КАНОНИКАЛ ЮРЛ?

  # Делает ссылку с указанной локалью (текущей)
  def my_bib_link_to(path)
    "/#{I18n.locale}/#{current_bib_lang()}#{path}"
  end

  # Делает ссылку с указанной локалью (текущей)
  def my_page_link_to(path)
    "/#{I18n.locale}/#{current_lang()}/w#{path}"
  end

  # ссылка на ресурс
  if Rails.env.production?
    def my_res_link_to(path)
      "https://res.bibleox.com#{path}"
    end
  else
    def my_res_link_to(path)
      path
    end
  end

  def flag_by_lang lang
    case lang.to_s.downcase
    when 'ru'; '🇷🇺'
    when 'en'; '🇺🇸'
    when 'gr'; '🇬🇷'
    when 'jp'; '🇯🇵'
    end
  end

  def day_visit
    @count_visit ||= ::PageVisits.day_visit(browser: browser)
  end

  def page_visit(id)
    @page_visit ||= ::PageVisits.visit(id, browser: browser)
  end

  def interliner_helper(words, dict)
    translate = dict[:dict]
    translate_simple = dict[:dict_simple]
    translate_simple_no_endings = dict[:dict_simple_no_endings]
    transcript = dict[:dict_transcriptions]

    words.map do |w|
      # перевод
      _w = w.unicode_normalize(:nfd).downcase.strip
      trnsl = translate[_w]
      trsc = transcript[_w]

      # перевод при поиске упрощённого слова
      ws = ::DictWord.word_clean_gr(w)
      trnsl_simple = translate_simple[ws]

      # перевод при поиске упрощённого слова без окончаний
      wse = ::DictWord.remove_greek_ending(ws)
      data_simple_no_endings = translate_simple_no_endings[wse]

      s  = "<ruby>#{ w }"
      if trnsl
        w_link = w.unicode_normalize(:nfd).downcase.delete("\u0300-\u036F")
        s += "<rt><a href='/#{I18n.locale}/words/#{ w_link }'>#{ trnsl }</a></rt>"
      elsif trnsl_simple
        w_link = w.unicode_normalize(:nfd).downcase.delete("\u0300-\u036F")
        s += "<rt><a href='/#{I18n.locale}/words/#{ w_link }'>#{ trnsl_simple }</a></rt>"
      elsif data_simple_no_endings
        trnsl_simple_no_endings = data_simple_no_endings[0]
        word_full = data_simple_no_endings[1]
        w_link = word_full.unicode_normalize(:nfd).downcase.delete("\u0300-\u036F")
        s += "<rt><a href='/#{I18n.locale}/words/#{ w_link }'>[#{ trnsl_simple_no_endings }]</a></rt>"
      elsif trsc
        s += "<rt>#{ trsc }</rt>"
      end
      s += "</ruby>"
    end.join
  end
end

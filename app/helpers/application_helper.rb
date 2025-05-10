module ApplicationHelper
  # размеры текста для пользователя (выбирается в шапке)
  TEXT_SIZES = {
    '1' => 'small',
    '2' => 'medium',
    '3' => 'large',
    nil => 'small'
  }

  PAGES_LANGS = {
    'ar' => true, # 🇦🇪 AR - Арабский
    'cn' => true, # 🇨🇳 CN - Китайский
    'de' => true, # 🇩🇪 DE - Немецкий
    'cp' => true, # 🇪🇬 CP - Коптский
    'en' => true, # 🇬🇧 EN - Английский (или 🇺🇸)
    'es' => true, # 🇪🇸 ES - Испанский
    'fr' => true, # 🇫🇷 FR - Французский
    'gr' => true, # 🇬🇷 GR - Греческий
    'il' => true, # 🇮🇱 IL - Иврит
    'in' => true, # 🇮🇳 IN - Хинди
    'ir' => true, # 🇮🇷 IR - Персидский
    'it' => true, # 🇮🇹 IT - Итальянский
    'jp' => true, # 🇯🇵 JP - Японский
    'ke' => true, # 🇰🇪 KE - Суахили
    'kr' => true, # 🇰🇷 KR - Корейский
    'rs' => true, # 🇷🇸 RS - Сербский
    'ru' => true, # 🇷🇺 RU - Русский
    'tm' => true, # 🇹🇲 TM - Туркменский
    'tr' => true, # 🇹🇷 TR - Турецкий
    'uz' => true, # 🇺🇿 UZ - Узбекский
    'vn' => true, # 🇻🇳 VN - Вьетнамский
  }

  # Название перевода Библии переводим в I18n.locale
  LANG_CONTENT_TO_LANG_UI = {
    'ru'         => 'ru',
    'en-nrsv'    => 'en',
    'eng-nkjv'   => 'en',
    'csl-ru'     => 'ru',
    'csl-pnm'    => 'ru',
    'heb-osm'    => 'il',
    'gr-lxx-byz' => 'gr',

    'gr-ru'      => 'ru',
    'gr-en'      => 'en',
    'gr-jp'      => 'jp',

    'jp-ni'      => 'jp',
    'cn-ccbs'    => 'cn',
    'ge-sch'     => 'de',
    'arab-avd'   => 'ar',
  }

  # поисковик не должен это индексировать.
  NOT_INDEXED_LANGS = [
    'csl-pnm',
    'en-nrsv',
  ]

  # %w().map { ::Page.create(title: "Tradition #{_1}", path: "links_#{_1}") }

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

    'es' => 'eng-nkjv',
    'fr' => 'eng-nkjv',
    'in' => 'eng-nkjv',
    'ir' => 'eng-nkjv',
    'it' => 'eng-nkjv',
    'ke' => 'eng-nkjv',
    'kr' => 'eng-nkjv',
    'rs' => 'ru',
    'tm' => 'ru',
    'tr' => 'eng-nkjv',
    'uz' => 'ru',
    'vn' => 'eng-nkjv',
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
  def my_page_link_to(path, page_lang: nil)
    "/#{I18n.locale}/#{ page_lang ? page_lang : current_lang()}/w#{path}"
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

  def flag_by_lang(lang)
    case lang.to_s.downcase
    when 'ar'; '🇦🇪'  # Арабский
    when 'cn'; '🇨🇳'  # Китайский
    when 'de'; '🇩🇪'  # Немецкий
    when 'cp'; '🇪🇬'  # Коптский
    when 'en'; '🇬🇧'  # Английский
    when 'es'; '🇪🇸'  # Испанский
    when 'fr'; '🇫🇷'  # Французский
    when 'gr'; '🇬🇷'  # Греческий
    when 'il'; '🇮🇱'  # Иврит
    when 'in'; '🇮🇳'  # Хинди
    when 'ir'; '🇮🇷'  # Персидский
    when 'it'; '🇮🇹'  # Итальянский
    when 'jp'; '🇯🇵'  # Японский
    when 'ke'; '🇰🇪'  # Суахили
    when 'kr'; '🇰🇷'  # Корейский
    when 'rs'; '🇷🇸'  # Сербский
    when 'ru'; '🇷🇺'  # Русский
    when 'tm'; '🇹🇲'  # Туркменский
    when 'tr'; '🇹🇷'  # Турецкий
    when 'uz'; '🇺🇿'  # Узбекский
    when 'vn'; '🇻🇳'  # Вьетнамский
    else; ''         # Возвращает пустую строку для неизвестных языков
    end
  end

  def day_visit
    @count_visit ||= ::PageVisits.day_visit(browser: browser)
  end

  def page_visit(id)
    @page_visit ||= ::PageVisits.visit(id, browser: browser)
  end

  def text_content_direction
    @text_content_direction ||= ['heb-osm', 'arab-avd', 'il', 'ar'].include?(params[:content_lang]) ? 'rtl' : 'ltr'
  end

  def text_ui_direction
    @text_ui_direction ||= ['il', 'ar'].include?(::I18n.locale.to_s) ? 'rtl' : 'ltr'
  end

  def interliner_helper(verse_data)
    words = verse_data['w']
    words_with_info = verse_data['wi']

    # Если есть полная информация для построения подстрочника, то выстраиваем html целиком
    # А иначе проставим просто заглушки "-"
    if words_with_info
      words_with_info.map do |wi|
        # Структура wi:
        # {
        #   raw: w, # слово, где сохранены большие буквы как было в тексте
        #   w: word_info_json['w'], # тут самое правильное слово. Я просил ИИ оставить заглавные буквы только у названий и имен
        #   bw_id: bib_word.id,
        #   lex: word_info_json['l'], # lexema
        #   inf: word_info_json['i'], # info: часть речи, падеж, число, род.
        #   trl: word_info_json['tr'], # подстрочный перевод
        #   trc: {'en': word_info_json['zv']} # транскрипция
        # }

        # ИНФОРМАЦИЯ ПОД СТРОКОЙ
        if wi['trl']
          # ЕСТЬ ПЕРЕВОД, СТРОИМ ПОДСТРОЧНИК ПО ПОЛНОЙ ПРОГРАММЕ
          # слово
          s  = "<ruby>#{ wi['raw'] }"
          # перевод
          s += "<rt><a class='word-link' href='/#{I18n.locale}/words/#{ wi['bw_id'] }'>#{ wi.dig('trl', locale_for_content_lang()) }</a>"

          # ИНФОРМАЦИЯ ВО ВСПЛЫВАЮЩЕМ БАРЕ
          s += "<div class='word-info'><div class='word-content'>"
          # слово
          s += "<b>#{ wi['raw'] } [#{ wi.dig('trc', 'en') }]</b> "
          # лексема
          s += " (#{ I18n.t('bib_word_info.lexema') }: #{ wi['lex'] })"
          # перевод
          s += ", перевод в контексте: <b>#{ wi.dig('trl', locale_for_content_lang()) }</b>. "
          # морфология (часть речи и проч.)
          s += wi['inf'].to_h.map { |k,v| "#{ I18n.t("bib_word_info.morph")[v.to_s.downcase.to_sym].presence || v.presence }" }.reject(&:blank?).join(', ')

          # ссылка на подробности
          s += "<br><a href='/#{I18n.locale}/words/#{ wi['bw_id'] }'>#{ I18n.t('bib_word_info.more') }</a>"
          s += "</div></div>"
          s += "</rt></ruby>"
        else
          # ПЕРЕВОД НЕТ, СКОРЕЕ ВСЕГО ЭТО ЗНАК ПРЕПИНАНИЯ
          # ";" заменяем на "?"
          # остальное оставляем "как есть"
          w =
          case wi['raw']
          when '.'; '.' # точка
          when '˙'; ',' # запятая
          when ','; ',' # запятая
          when '·'; ';' # точка с запятой
          when ';'; '?' # вопросительный знак
          when '⸎'; '—' # тире
          when '-'; '-' # дефис
          else
            wi['raw']
          end
          "<ruby>#{ wi['raw'] }<rt>#{ w }</rt></ruby>"
        end
      end.join

    else
      words.map do |w|
        "<ruby>#{ w }<rt>-</rt></ruby>"
      end.join
    end
  end

  # OLD VERSION
  #
  # def interliner_helper(words, dict)
  #   translate = dict[:dict]
  #   translate_simple = dict[:dict_simple]
  #   translate_simple_no_endings = dict[:dict_simple_no_endings]
  #   transcript = dict[:dict_transcriptions]

  #   words.map do |w|
  #     # перевод
  #     _w = w.unicode_normalize(:nfd).downcase.strip
  #     trnsl = translate[_w]

  #     # перевод при поиске упрощённого слова
  #     ws = ::DictWord.word_clean_gr(_w)
  #     trsc = transcript[ws]
  #     trnsl_simple = translate_simple[ws]

  #     # перевод при поиске упрощённого слова без окончаний
  #     wse = ::DictWord.remove_greek_ending(ws)
  #     data_simple_no_endings = translate_simple_no_endings[wse]

  #     s  = "<ruby>#{ w }"
  #     if trnsl
  #       w_link = w.unicode_normalize(:nfd).downcase.delete("\u0300-\u036F")
  #       s += "<rt><a href='/#{I18n.locale}/words/#{ w_link }'>#{ trnsl }!</a></rt>"
  #     elsif trnsl_simple
  #       w_link = w.unicode_normalize(:nfd).downcase.delete("\u0300-\u036F")
  #       s += "<rt><a href='/#{I18n.locale}/words/#{ w_link }'>#{ trnsl_simple }</a></rt>"
  #     elsif data_simple_no_endings
  #       trnsl_simple_no_endings = data_simple_no_endings[0]
  #       word_full = data_simple_no_endings[1]
  #       w_link = word_full.unicode_normalize(:nfd).downcase.delete("\u0300-\u036F")
  #       s += "<rt><a href='/#{I18n.locale}/words/#{ w_link }'>#{ trnsl_simple_no_endings }~</a></rt>"
  #     elsif trsc
  #       s += "<rt>#{ trsc }</rt>"
  #     end
  #     s += "</ruby>"
  #   end.join
  # end
end

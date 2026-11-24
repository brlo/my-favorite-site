module ApplicationHelper

  # размер шрифта, выбранный пользователем
  # карта цитирования отключена пользователем (кнопка в text-bar)
  def cite_map_off?
    cookies[:citeMap] == '0'
  end

  def text_size_class
    text_size = cookies[:textSize] || '2' # default
    case text_size
    when '1' then 'text-small'
    when '3' then 'text-large'
    else 'text-medium'
    end
  end

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
    ::BIB_LANG_TO_LOCALE[content_lang || params[:content_lang]]
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
        if ::BIB_LANG_TO_LOCALE.has_key?(params[:content_lang])
          params[:content_lang]
        else
          # Если смотрим Page, то язык контента не совпадает с языками Библии.
          # Вот так подбираем подходящий язык Библии:
          ::LOCALE_TO_BIB_LANG[params[:content_lang]]
        end
      elsif params[:locale].present?
        # Если язык контента совсем не указан, то определяем язык контента по языку интерфейса
        ::LOCALE_TO_BIB_LANG[params[:locale]]
      end
    end
  end

  # Язык контента для Page (язык интерфейса определяй просто по I18n.locale)
  def current_lang
    # Если явно указан язык контента и он валиден — берём его — params[:content_lang],
    # а иначе берём одноимённое название локали (языка интерфейса).
    # Проверяем по ALL_CONTENT_LANGS: языки вроде xcl (грабар) есть только как язык статьи,
    # в ALL_LOCALES их нет, но в адресе /en/xcl/w/... они всё равно должны сохраняться.
    @current_lang ||=
    if ::ALL_CONTENT_LANGS[params[:content_lang]]
      params[:content_lang]
    else
      params[:locale]
    end
  end

  # строка языка для выпадающего меню "выбор языка Библии"
  def bib_lang_string_full translation_code, short: '', is_translate: false
    l_flag = ::FLAG_BY_LANG[translation_code]
    # название языка локализованное (все названия в текущей локали)
    l_name_tr = I18n.t("bib_translations.#{translation_code}")
    # название языка универсальное (на том языке, именем которого называется)
    l_name_uni = ::BIB_LANGS[translation_code]
    if is_translate
      "#{l_flag} #{l_name_tr} — #{l_name_uni} (#{short})"
    else
      "#{l_flag} #{l_name_uni} (#{short})"
    end
  end

  # строка языка для выпадающего меню "выбор языка статьи"
  def page_lang_string_full lang_code, is_translate: false
    l_flag = ::FLAG_BY_LANG[lang_code]
    # название языка локализованное (все названия в текущей локали)
    l_name_tr = I18n.t("page_translations.#{lang_code}")
    # название языка универсальное (на том языке, именем которого называется)
    l_name_uni = ::PAGE_LANGS[lang_code]
    if is_translate
      "#{l_flag} #{l_name_tr} — #{l_name_uni}"
    else
      # когда универсального названия нет (так делаем для подстрочников), то берём перевод
      "#{l_flag} #{l_name_uni || l_name_tr}"
    end
  end

  # Название языка интерфейса на нём самом (для списка языков в шапке),
  # а если универсального названия нет — локализованное.
  def ui_lang_name(lang_code)
    ::PAGE_LANGS[lang_code.to_s] || I18n.t("page_translations.#{lang_code}")
  end

  # Код текущего языка интерфейса для иконки в шапке: zh-Hans -> ZH
  def ui_lang_code(lang_code = I18n.locale)
    lang_code.to_s.split('-').first.upcase
  end

  # Адрес текущей страницы с другим языком интерфейса: меняем только первый
  # сегмент пути (локаль), страница/стих/якорь остаются те же.
  # PATH_INFO роутер нормализует и срезает хвостовой слэш, поэтому берём
  # исходный адрес запроса: канонические адреса сайта заканчиваются на "/".
  def ui_lang_switch_path(lang_code)
    path = request.get_header('REQUEST_URI').presence || request.original_fullpath
    path = path.to_s.sub(%r{\Ahttps?://[^/]+}, '').split('?', 2).first
    rest = path.sub(%r{\A/[^/]+}, '')
    result = "/#{lang_code}#{rest}"
    request.query_string.present? ? "#{result}?#{request.query_string}" : result
  end

  # # <%= bbx_select_tag :locale,
  # #   [['English', 'en', { data: { progress: 100 } }],
  # #    ['Русский', 'ru', { data: { progress: 45 } }]],
  # #   I18n.locale %>
  # def bbx_select_tag(name, options, selected = nil, html_options = {})
  #   content_tag(:div, data: { controller: 'bbx-select' }) do
  #     select_tag(name, options_for_select(options, selected),
  #               html_options.merge(data: { bbx_select_target: 'select' })) +
  #     content_tag(:div, '', data: { bbx_select_target: 'custom' })
  #   end
  # end

  # Очистка одного стиха от спец. символов в конце (для поисковой страницы)
  def verse_alone_clean text
    if text[-1] =~ /[\.\,\-\;\:]/
      text[0..-2]
    else
      text
    end
  end

  # Ссылка на труд святого отца с подсветкой места, где упоминается стих (text fragment)
  def citation_page_link(page, snippet)
    words = snippet.to_s.delete('…').split.first(6).join(' ').gsub(/[\[\]()«»]/, '')
    link = my_page_link_to("/#{CGI.escape(page.path)}", page_lang: page.lang)
    words.present? ? "#{link}#:~:text=#{ERB::Util.url_encode(words)}" : link
  end

  # Делает ссылку с указанной локалью (текущей)
  def my_link_to(path)
    "/#{I18n.locale}#{path}"
  end

  # Статья «Православная Церковь» для выпадающего меню «Писание» в хэдере:
  # ставится на первое место, если есть перевод на текущий язык интерфейса.
  def header_church_page
    Rails.cache.fetch("header_church_page/#{I18n.locale}", expires_in: 1.hour) do
      ru = Page.find_by(lang: 'ru', path_low: 'православная-церковь')
      next nil unless ru
      Page.find_by(lang: I18n.locale.to_s, group_lang_id: ru.group_lang_id)
    end
  end

  # А КАК ЖЕ КАНОНИКАЛ ЮРЛ?

  # Делает ссылку с указанной локалью (текущей)
  def my_bib_link_to(path)
    "/#{I18n.locale}/#{current_bib_lang()}#{path}"
  end

  # Ссылка на главу Библии в том переводе, который сейчас читают (блок «Читают сейчас»)
  def bible_chapter_link(book_code, content_lang)
    "/#{I18n.locale}/#{content_lang}/#{book_code}/1/"
  end

  # Делает ссылку с указанной локалью (текущей)
  def my_page_link_to(path, page_lang: nil)
    path = path.gsub(/\A\/+/, '')  # убираем слэши вначале
    path = path.gsub(/\/+\z/, '')  # убираем слэши вконце
    "/#{I18n.locale}/#{ page_lang ? page_lang : current_lang()}/w/#{path}"
  end

  # Ссылка на служебную страницу языка (links_xx, help_xx).
  # Если для этого языка такой страницы нет (например, её нет для грабара xcl),
  # ведём на английскую версию — её поймёт больше людей, чем любую другую.
  def my_lang_page_link_to(kind, lang = current_lang())
    page = ::Page.find_by(path_low: "#{kind}_#{lang}".downcase) ||
           ::Page.find_by(path_low: "#{kind}_en")
    page_lang = page&.lang || 'en'
    my_page_link_to("/#{page&.path || "#{kind}_en"}", page_lang: page_lang)
  end

  # ссылка на ресурс
  if Rails.env.production?
    def my_res_link_to(path)
      ActionController::Base.helpers.asset_path(path)
    end
  else
    def my_res_link_to(path)
      ActionController::Base.helpers.asset_path(path)
    end
  end

  def flag_by_lang(lang)
    ::FLAG_BY_LANG[lang.to_s.downcase].to_s
  end

  # просмотры людей за сегодня (сам подсчёт делает JS-маячок, здесь только чтение)
  def day_count
    @count_visit ||= ::PageVisits.day_count
  end

  # счётчик просмотров статьи (сам подсчёт делает JS-маячок, здесь только чтение)
  def page_visit(page)
    @page_visit ||= ::PageVisits.page_count(page.id)
  end

  def font_classes
    @font_custom_classes ||= begin
      case @current_bib_lang
      when 'csl-pnm'
        'csl'
      when 'jp-ni', 'jp-joc', 'jp-box', 'gr-jp', 'arab-avd', 'cn-sb', 'cn-sbt', 'cn-cuv', 'cn-cuvt', 'ko-nkrv', 'heb-osm'
        'text-detailed'
      else
        ''
      end
    end
  end

  # Направление письма интерфейса: ставится на <html dir="...">
  def ui_direction
    ::RTL_LOCALES.include?(::I18n.locale.to_s) ? 'rtl' : 'ltr'
  end

  # Направление письма контента (статьи, стихи). Оно может не совпадать с интерфейсом:
  # арабская статья в английском интерфейсе — rtl, английская в арабском — ltr.
  def content_direction
    lang = (@content_lang.presence || params[:content_lang]).to_s
    return ui_direction if lang.blank?

    direction_for_lang(lang)
  end

  # Направление для конкретного языка контента: локали статей (ar, he)
  # и коды переводов Библии (arab-avd, heb-osm)
  def direction_for_lang(lang)
    locale = ::BIB_LANG_TO_LOCALE[lang.to_s] || lang.to_s
    ::RTL_LOCALES.include?(locale) ? 'rtl' : 'ltr'
  end

  def interliner_helper(verse)
    verse_data = verse.data
    words = verse_data['w']
    words_with_info = verse_data['wi']

    # Изменились названия локалей, поэтому когда обращаемся к переводу внутри стиха,
    # ключи en и ru оставляем как есть, а ja подменяем на старый jp:
    interliner_lang = locale_for_content_lang()

    label_of_verify = "ok_#{interliner_lang}"
    is_verse_verified = verse_data[label_of_verify]

    # Если есть полная информация для построения подстрочника, то выстраиваем html целиком
    # А иначе проставим просто заглушки "-"
    if (is_verse_verified || current_user&.is_admin?) && words_with_info
      words_with_info.map.with_index do |wi, index|
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
          word_translation = wi.dig('trl', interliner_lang)
          attrs = ''
          if current_user&.is_admin?
            attrs = "class='#{ 'verified' if is_verse_verified }' data-controller='interlinear-editor' data-verse-id='#{verse.id}' data-word-index='#{index}' data-action='dblclick->interlinear-editor#edit'"
          end

          # слово
          s  = "<ruby #{attrs} data-word='#{word_translation}'>&nbsp;#{ wi['raw'] }&nbsp;"
          # перевод
          s += "<rt>" +
            "<v>[</v>"

          if wi['bw_id'].present?
            s += "<a class='word-link' href='/#{I18n.locale}/words/bw-#{ wi['bw_id'] }'>#{ word_translation }</a>"
          else
            s += word_translation.to_s
          end

          s += "<v>]</v>"

          # # ИНФОРМАЦИЯ ВО ВСПЛЫВАЮЩЕМ БАРЕ
          # s += "<div class='word-info'><div class='word-content'>"
          # # слово
          # s += "<b>#{ wi['raw'] } [#{ wi.dig('trc', 'en') }]</b> "
          # # лексема
          # s += " (#{ I18n.t('bib_word_info.lexema') }: #{ wi['lex'] })"
          # # перевод
          # s += ", перевод в контексте: <b>#{ wi.dig('trl', interliner_lang) }</b>. "
          # # морфология (часть речи и проч.)
          # s += wi['inf'].to_h.map { |k,v| "#{ I18n.t("bib_word_info.morph")[v.to_s.downcase.to_sym].presence || v.presence }" }.reject(&:blank?).join(', ')

          # # ссылка на подробности
          # s += "<br><a href='/#{I18n.locale}/words/#{ wi['bw_id'] }'>#{ I18n.t('bib_word_info.more') }</a>"
          # s += "</div></div>"

          s += "</rt></ruby>"
        else
          # ПЕРЕВОДА НЕТ, СКОРЕЕ ВСЕГО ЭТО ЗНАК ПРЕПИНАНИЯ
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
      words.map.with_index do |w, index|
        attrs = ''
        if current_user&.is_admin?
          attrs = "data-controller='interlinear-editor' data-verse-id='#{verse.id}' data-word-index='#{index}' data-action='dblclick->interlinear-editor#edit'"
        end

        "<ruby #{attrs}>#{ w }<rt>-</rt></ruby>"
      end.join
    end
  end

  # --- jp-box: калька {общепринятое|православное} -------------------------
  # По умолчанию рендерится левый (общепринятый) вариант; кука calque=orthodox
  # включает православный (伝統表記).
  def calque_orthodox?
    cookies[:calque].to_s == 'orthodox'
  end

  # Термины в {A|B} — попарно, там где важен контекст (恵み/恩寵 и т.п.).
  # Имена Христа и Святого Духа подставляются автоматически: они однозначны.
  JP_BOX_ORTHODOX_NAMES = {
    '聖霊[せいれい]' => '聖神[せいしん]',
    '聖霊' => '聖神',
    'イエス' => 'イイスス',
    'ダビデ' => 'ダワィド',
    'モーセ' => 'モイセイ',
    'ヨハネ' => 'イオアン',
    'ペトロ' => 'ペトル',
    'ヤコブ' => 'イアコフ',
    'アンデレ' => 'アンドレイ',
    'ヘロデ' => 'イロド',
    'マリア' => 'マリヤ',
    'サタン' => 'サタナ',
    'パウロ' => 'パワェル',
    'テモテ' => 'ティモフェイ',
    'ヨセフ' => 'イオシフ',
    'インマヌエル' => 'エムマヌイル',
    'テトス' => 'ティト',
    'ピレモン' => 'フィリモン',
    'ステファノ' => 'ステファン',
    'ピリポ' => 'フィリップ',
    'サウロ' => 'サウル',
    'バルナバ' => 'ワルナワ',
    'アブラハム' => 'アウラアム',
    'アブラム' => 'アウラム',
    'ファラオ' => 'ファラオン',
    'ハガル' => 'アガリ',
    'セム' => 'シム',
    'イサク' => 'イサアク',
    'アロン' => 'アアロン',
    'エリヤ' => 'イリヤ',
    'イザヤ' => 'イサイヤ',
    'エレミヤ' => 'イエレミヤ',
    'ダニエル' => 'ダニイル',
    'ヨブ' => 'イオフ',
    'ノア' => 'ノイ',
    'エノク' => 'エノフ',
    'アベル' => 'アワェリ',
    'ラハブ' => 'ラアフ',
    'サムエル' => 'サムイル',
    'サムソン' => 'サムプソン',
    'メルキセデク' => 'メルヒセデク',
    'ザカリヤ' => 'ザハリヤ',
    'エリサベト' => 'エリサワェタ',
    'トマス' => 'フォマ',
    'マルタ' => 'マルファ',
    'ラザロ' => 'ラザリ',
    'アサフ' => 'イサフ',
    'ニコデモ' => 'ニコディム',
    'マタイ' => 'マトフェイ',
    'バルトロマイ' => 'ワルフォロメイ',
    'ゼベダイ' => 'ゼワェデイ',
    'アルファイ' => 'アルフェイ',
    'アナニア' => 'アナニヤ',
    'コラ' => 'コレイ',
    'レビ' => 'レワィ',
    'シラス' => 'シラ',
  }.freeze

  def jp_box_text(text, orthodox = calque_orthodox?)
    s = text.to_s
    s = s.gsub(/\{([^{}|]*)\|([^{}|]*)\}/) { orthodox ? $2 : $1 } if s.include?('{')
    return s unless orthodox

    JP_BOX_ORTHODOX_NAMES.each { |from, to| s = s.gsub(from, to) }
    s = s.gsub(/アポロ(?!ニア)/, 'アポロス') # アポロニア не трогаем
    s = s.gsub(/ヨナ(?!タン)/, 'イオナ')      # ヨナタン не трогаем
    s = s.gsub(/(?<!反)キリスト/, 'ハリストス') # 反キリスト не трогаем
    s.gsub(/ユダ(?!ヤ)/, 'イウダ')              # ユダヤ не трогаем
  end

  # Статья «О переводе» jp-box на языке читателя: исходная — ru, есть ja.
  # Для языков без перевода отдаём ru (как было раньше).
  def jp_box_about_page
    ru = ::Page.find_by(lang: 'ru', path_low: ::JP_BOX_ABOUT_PATH.downcase)
    return nil unless ru

    ::Page.find_by(lang: I18n.locale.to_s, group_lang_id: ru.group_lang_id) || ru
  end

  # Текст стиха для показа: у jp-box раскрываем кальку, у прочих переводов — как есть
  def verse_text_for_display(verse)
    verse.tr_code == 'jp-box' ? jp_box_text(verse.text) : verse.text
  end

  # Сноски-звёздочки jp-box: в тексте стоят маркеры {{1}}, {{2}},
  # пояснения — в data['notes'] стиха (там же, где подстрочник).
  def wrap_bible_notes(html, notes)
    return html if html.blank? || notes.blank?

    html.to_s.gsub(/\{\{(\d+)\}\}/) do
      tip = notes[Regexp.last_match(1)].to_s
      next '' if tip.blank?

      %(<span class="bib-note" tabindex="0" role="note" data-tip="#{ERB::Util.html_escape(tip)}">＊</span>)
    end.html_safe
  end

  # Ссылка-переключатель кальки для text-bar.
  # На главной перевода (и других страницах без главы) @book_code/@chapter пустые —
  # тогда возвращаемся на текущий адрес, иначе получалось /ja/jp-box///?calque=…
  def calque_toggle_path
    base = if @book_code.present? && @chapter.present?
             my_bib_link_to("/#{@book_code}/#{@chapter}/")
           else
             request.path
           end
    "#{base}?calque=#{calque_orthodox? ? 'common' : 'orthodox'}"
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

  def time_ago_in_words(created_at)
    return "" unless created_at
    created_at = Time.parse(created_at) if created_at.is_a?(String)

    seconds = Time.current - created_at

    case seconds
    when 0...60
      ::I18n.t('time_ago.just_now')
    when 60...3_600
      minutes = (seconds / 60).round
      "#{minutes} #{::I18n.t('time_ago.minute')}"
    when 3_600...86_400
      hours = (seconds / 3_600).round
      "#{hours} #{::I18n.t('time_ago.hour')}"
    when 86_400...2_592_000 # 604_800
      days = (seconds / 86_400).round
      "#{days} #{::I18n.t('time_ago.day')}"
    # when 604_800...2_592_000
    #   weeks = (seconds / 604800).round
    #   "#{weeks} #{::I18n.t('time_ago.week')}"
    when 2_592_000...31_536_000
      months = (seconds / 2_592_000).round
      "#{months} #{::I18n.t('time_ago.month')}"
    else
      years = (seconds / 31_536_000).round
      "#{years} #{::I18n.t('time_ago.year')}"
    end
  end
end

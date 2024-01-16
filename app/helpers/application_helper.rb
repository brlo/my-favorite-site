module ApplicationHelper
  # размеры текста для пользователя (выбирается в шапке)
  TEXT_SIZES = {
    '1' => 'small',
    '2' => 'medium',
    '3' => 'large',
    nil => 'small'
  }

  # Название перевода Библии переводим в I18n.locale
  LANG_CONTENT_TO_LANG_UI = {
    'ru'         => 'ru',
    'eng-nkjv'   => 'en',
    'csl-ru'     => 'ru',
    'csl-pnm'    => 'ru',
    'heb-osm'    => 'il',
    'gr-lxx-byz' => 'gr',
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

  # Определить язык контента Библии по названию локали
  def locale_for_content_lang content_lang
    LANG_CONTENT_TO_LANG_UI[params[:content_lang]]
  end

  # Язык библейского контента (язык интерфейса определяй просто по I18n.locale)
  def current_bib_lang
    @current_bib_lang ||= begin
      if params[:content_lang].present?
        params[:content_lang]
      elsif params[:locale].present?
        LANG_UI_TO_LANG_CONTENT[params[:locale]]
      end
    end
  end

  # Язык контента (язык интерфейса определяй просто по I18n.locale)
  def current_lang
    # Если явно указан язык контента — берём его — params[:content_lang],
    # а иначе берём одноимённое название локали (языка интерфейса).
    @current_lang ||= params[:content_lang].presence || params[:locale].presence
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
end

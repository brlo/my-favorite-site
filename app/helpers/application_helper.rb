module ApplicationHelper
  # размеры текста для пользователя (выбирается в шапке)
  TEXT_SIZES = {
    '1' => 'small',
    '2' => 'medium',
    '3' => 'large',
    nil => 'small'
  }

  def locale_for_content_lang content_lang
    case params[:content_lang]
    when 'ru';         'ru'
    when 'eng-nkjv';   'en'
    when 'csl-ru';     'ru'
    when 'csl-pnm';     'ru'
    when 'heb-osm';    'il'
    when 'gr-lxx-byz'; 'gr'
    when 'jp-ni';      'jp'
    when 'cn-ccbs';    'cn'
    when 'ge-sch';     'de'
    when 'arab-avd';   'ar'
    end
  end

  # Язык библейского контента (язык интерфейса определяй просто по I18n.locale)
  def current_bib_lang
    @current_bib_lang ||= begin
      _lang =
      if params[:content_lang].present?
        params[:content_lang]
      elsif params[:locale].present?
        case params[:locale]
        when 'ru' ; 'ru'
        when 'en' ; 'eng-nkjv'
        # when 'cs' ; 'csl-ru'
        when 'il' ; 'heb-osm'
        when 'gr' ; 'gr-lxx-byz'
        when 'jp' ; 'jp-ni'
        when 'cn' ; 'cn-ccbs'
        when 'de' ; 'ge-sch'
        when 'ar' ; 'arab-avd'
        else      ; 'ru'
        end
      end

      # пока что смотрим в стороннем файле, есть ли такой язык
      if ::CacheSearch::SEARCH_LANGS.include?(_lang)
        _lang
      else
        'ru'
      end
    end
  end

  # Язык контента (язык интерфейса определяй просто по I18n.locale)
  def current_lang
    # Если явно указан язык контента — берём его,
    # а иначе берём одноимённое название локали (языка интерфейса)
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
    @count_visit ||= ::PageVisits.day_visit()
  end

  def page_visit(id)
    @page_visit ||= ::PageVisits.visit(id)
  end
end

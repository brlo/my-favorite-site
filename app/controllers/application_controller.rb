class ApplicationController < ActionController::Base
  before_action :set_is_night_mode
  before_action :set_locale

  def current_lang
    lang = cookies[:'b-lang']

    if %w(ru csl-pnm csl-ru eng-nkjv heb-osm gr-lxx-byz).include?(lang)
      lang
    else
      'ru'
    end
  end

  def set_is_night_mode
    @is_night_mode = cookies[:isNightMode] == '1'
  end

  def set_locale
    I18n.locale =
    case current_lang()
    when 'ru', 'csl-pnm', 'csl-ru'
      :ru
    when 'eng-nkjv', 'heb-osm', 'gr-lxx-byz'
      :en
    else
      :ru
    end
  end
end

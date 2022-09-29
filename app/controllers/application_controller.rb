class ApplicationController < ActionController::Base
  before_action :set_is_night_mode
  before_action :set_locale

  def current_lang
    # если поисковик не умеет куки, то хоть через локаль (которая в url) установит перевод
    @current_lang ||= begin
      _lang =
      if cookies[:'b-lang'].present?
        cookies[:'b-lang']
      elsif params[:locale].present?
        case params[:locale]
        when 'ru' ; 'ru'
        when 'en' ; 'eng-nkjv'
        when 'cs' ; 'csl-ru'
        when 'il' ; 'heb-osm'
        when 'gr' ; 'gr-lxx-byz'
        else      ; 'ru'
        end
      end

      if ::CacheSearch::SEARCH_LANGS.include?(_lang)
        _lang
      else
        'ru'
      end
    end
  end

  def set_is_night_mode
    @is_night_mode = cookies[:isNightMode] == '1'
  end

  def set_locale
    # params[:locale] - заполняется в routes
    I18n.locale = params[:locale]
    # case current_lang()
    # when 'ru', 'csl-pnm', 'csl-ru'
    #   :ru
    # when 'eng-nkjv', 'heb-osm', 'gr-lxx-byz'
    #   :en
    # else
    #   :ru
    # end
  end

  def build_canonical_url(path)
    "https://bibleox.com/#{I18n.locale}#{path}"
  end
end

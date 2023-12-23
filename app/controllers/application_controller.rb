class ApplicationController < ActionController::Base
  helper_method :logged_in?

  around_action :set_current_user
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
        when 'jp' ; 'jp-ni'
        when 'cn' ; 'cn-ccbs'
        when 'de' ; 'ge-sch'
        when 'ar' ; 'arab-avd'
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
    ::I18n.locale = params[:locale] || 'ru'
    # case current_lang()
    # when 'ru', 'csl-pnm', 'csl-ru'
    #   :ru
    # when 'eng-nkjv', 'heb-osm', 'gr-lxx-byz'
    #   :en
    # else
    #   :ru
    # end
  end

  def logged_in?
    ::Current.user.logged_in?()
  end

  def authorized
    redirect to login_path unless logged_in?()
  end

  def set_current_user
    user =
    if request.headers['API_TOKEN'].present?
      ::User.find_by(api_token: request.headers['API_TOKEN'])
    elsif session[:user_id].present?
      ::User.find_by(id: session[:user_id])
    else
      nil
    end

    ::Current.user = ::CurrentUser.new(user)
    yield # тут выполниться весь наш запрос
  ensure
    # to address the thread variable leak issues in Puma/Thin webserver
    ::Current.user = nil
  end

  def build_canonical_url(path)
    "https://bibleox.com/#{I18n.locale}#{path}"
  end
end

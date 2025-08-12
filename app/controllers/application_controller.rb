class ApplicationController < ActionController::Base
  include ApplicationHelper

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  helper_method :logged_in?

  around_action :set_current_user
  before_action :set_is_night_mode
  before_action :set_locale

  def not_found!
    raise ActionController::RoutingError.new("Not Found")
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
    redirect_to login_path unless logged_in?()
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
    canon_path = "https://bibleox.com"
    if params[:content_lang].present?
      canon_locale = locale_for_content_lang(params[:content_lang])
      canon_path += "/#{canon_locale}/#{params[:content_lang]}"
    else
      canon_path += "/#{::I18n.locale}"
    end
    "#{canon_path}#{path}"
  end

  private

  def render_not_found
    render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false
  end
end

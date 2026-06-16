class ApplicationController < ActionController::Base
  include ApplicationHelper

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  before_action :set_is_night_mode
  before_action :set_locale

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

  def not_authenticated
    redirect_to login_path, alert: "Please login first", status: :see_other
  end

  def require_admin
    return if logged_in? && current_user.is_admin?

    redirect_to root_path, alert: "You are not an admin", status: :see_other
  end
end

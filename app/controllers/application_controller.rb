class ApplicationController < ActionController::Base
  include ApplicationHelper

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  before_action :set_is_night_mode
  before_action :set_locale
  before_action :require_login_and_activation

  def require_login_and_activation
    if !logged_in?
      return_error t('users.errors.login_required')
    end

    if !current_user.activated?
      return_error t('users.errors.activation_required')
    end

    if current_user.is_blocked
      return_error t('users.errors.account_blocked')
    end
  end

  def require_login_and_not_blocked
    if !logged_in?
      return_error t('users.errors.login_required')
    end

    if current_user.is_blocked
      return_error t('users.errors.account_blocked')
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

  # Без этого url-хелперы (translation_project_path и т.п.) подставляют locale из defaults
  # в routes (:ru), а не текущую локаль интерфейса.
  def default_url_options
    { locale: I18n.locale }
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
    redirect_to login_path, alert: t('users.errors.login_required'), status: :see_other
  end

  def require_admin
    return if logged_in? && current_user.is_admin?

    redirect_to root_path, alert: t('users.errors.not_admin'), status: :see_other
  end

  def redirect_if_logged_in
    if logged_in?
      redirect_to profile_path, notice: t('users.notices.already_logged_in')
    end
  end

  def return_error(msg)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "flash-container",
          partial: "shared/toast",
          locals: { type: "alert", message: msg }
        )
      end
      format.html { redirect_back fallback_location: root_path, alert: msg }
    end
  end

  def too_many_requests
    return_error(t('users.errors.too_many_requests'))
  end
end

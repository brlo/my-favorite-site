module Admin
  # Общая логика админки: вход через обычную сессию сайта (sorcery), доступ по привилегиям.
  class BaseController < ApplicationController
    layout 'admin'

    skip_before_action :require_login_and_activation
    before_action :require_admin_area_access

    helper_method :can?, :super_user?, :page_owner?

    private

    # админка живёт вне локали (/admin), поэтому не подставляем locale в url-хелперы
    def default_url_options
      {}
    end

    def set_locale
      ::I18n.locale = :ru
    end

    def require_admin_area_access
      unless logged_in?
        session[:return_to_url] = request.url if request.get?
        redirect_to login_path(locale: :ru), alert: t('users.errors.login_required')
        return
      end

      # Если у пользователя прописаны IP, пускаем в админку только с них
      unless current_user.admin_area_access? && current_user.allow_ip?(request.ip)
        redirect_to "/ru", alert: 'Нет доступа к админке. Чтобы получить доступ, напишите нам: https://t.me/bibleox_live'
      end
    end

    def require_is_admin
      deny_access unless current_user.is_admin?
    end

    def can?(priv)
      current_user.ability?(priv)
    end

    # привилегия super открывает служебные поля в формах
    def super_user?
      current_user.privs_list['super'] == true
    end

    def require_priv(priv)
      deny_access unless can?(priv)
    end

    def deny_access(msg = 'У вас нет доступа к этому действию.')
      respond_to do |format|
        format.turbo_stream { render turbo_stream: toast_stream(msg, type: 'alert'), status: :forbidden }
        format.html { redirect_to admin_root_path, alert: msg }
        format.json { render json: { error: msg }, status: :forbidden }
      end
    end

    def toast_stream(message, type: 'notice')
      turbo_stream.append('flash-container', partial: 'shared/toast', locals: { type:, message: })
    end

    def page_owner?(page)
      page.present? && page.owned_by?(current_user)
    end

    # сбрасываем закешированные html-страницы статьи (actionpack-page_caching)
    def expire_page_cache(page_path, lang)
      ::I18n.available_locales.each { |l| expire_page("/#{l}/#{lang}/w/#{page_path}") }
    end
  end
end

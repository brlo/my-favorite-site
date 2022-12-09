class UsersController < ApplicationController
  # Страница входа
  def login
    @page_title = ::I18n.t('login_page.title')
    @current_menu_item = 'login'
    @no_index = true

    # для всех показываем вход через Телеграм, а вот админу доступен скрытый вход
    # если передан любой параметр в поле site (то есть авторизация через наш сайт)
    @is_site_auth_enabled = params[:site] # 1 - поставь, чтобы временно включить для всех
  end

  # Вход через сайт
  def handle_login_site
    @user =
    if params[:username].present?
      ::User.by_site.where(username: params[:username]).first
    end

    if @user && @user.authenticate(params[:password]) && @user.allow_ip?(request.ip)
      session[:user_id] = @user._id.to_s
      redirect_to chapter_path(locale: ::I18n.locale, book_code: 'gen', chapter: 1)
    else
      redirect_to login_path(locale: ::I18n.locale)
    end
  end

  # Вход через Телеграм
  def handle_telegram_login
    # хэш, с которым мы сравниваем наши рассчёты
    attrs = params.permit(:hash, :auth_date, :first_name, :id, :last_name, :photo_url, :username)
    auth_service = ::AuthTelegram.new(attrs)

    if auth_service.valid?
      user = auth_service.find_or_create_user!
      session[:user_id] = user._id.to_s
      render json: {'success': 'ok', url: chapter_path(locale: ::I18n.locale, book_code: 'gen', chapter: 1)}
    else
      render json: {'success': 'fail', params: params}
      # redirect_to login_path(locale: ::I18n.locale)
    end
  end

  # Выход
  def logout
    session[:user_id] = nil
    render json: {'success': 'ok'}
    # redirect_to chapter_path(locale: ::I18n.locale, book_code: 'gen', chapter: 1)
  end

  # Страница профиля
  def profile
    @page_title = ::I18n.t('profile_page.title')
    @current_menu_item = 'profile'
    @no_index = true

    if logged_in?()
      @user = ::Current.user
    else
      redirect_to login_path(locale: ::I18n.locale)
    end
  end

  # Обновление профиля
  def profile_update
    @user = ::Current.user.instance
    attrs = params.require(:user).permit(:name, :new_password, :new_password_confirmation, allow_ips: [])

    if attrs[:new_password].present?
      attrs[:password] = attrs.delete(:new_password)
      attrs[:password_confirmation] = attrs.delete(:new_password_confirmation)
    else
      attrs.delete(:new_password)
      attrs.delete(:new_password_confirmation)
    end

    if attrs[:allow_ips]
      attrs[:allow_ips] = attrs[:allow_ips].select { |ip| ip.present? }
    end

    @user.update(attrs)

    redirect_to profile_path(locale: ::I18n.locale)
  end
end

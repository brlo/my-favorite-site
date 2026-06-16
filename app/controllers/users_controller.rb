class UsersController < ApplicationController
  skip_before_action :require_login_and_activation
  before_action :require_login_and_not_blocked, except: %w[new create activate]
  before_action :require_admin, only: %w[block]

  before_action :set_user, only: %w[show edit_main_info edit_password update_main_info update_password]
  before_action :set_active_menu_item

  rate_limit to: 20, within: 1.day, by: -> { request.ip }, only: %w[create update_main_info update_password]

  # Регистрация
  def new
    @user = User.new

    @page_title = t('users.titles.signup')
    # @meta_description = ::I18n.t("books.full.#{@book_code}")
    # @canonical_url = build_canonical_url("/#{@book_code}/#{@chapter}/")
  end

  # Профиль
  def show
    @breadcrumbs = [[t('bc.profile')]]
    @user = current_user

    @page_title = t('users.titles.signup')
  end

  # Редактирование профиля
  def edit_main_info
    @breadcrumbs = [[t('bc.profile'), profile_path], [t('bc.edit_password')]]
    @user = current_user
  end

  # Редактирование пароля
  def edit_password
    @breadcrumbs = [[t('bc.profile'), profile_path], [t('bc.change_password')]]
    @user = current_user
  end

  def create
    @user = User.new(user_params)

    if @user.save
      auto_login(@user)
      redirect_to root_path, notice: t('users.notices.registration_successful')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update_main_info
    attrs = params.expect(user: %w[email name username])
    if @user.update(attrs)
      redirect_to edit_main_info_users_path, notice: t('users.notices.profile_is_updated')
    else
      @breadcrumbs = [[t('bc.profile'), profile_path], [t('bc.edit_password')]]
      render :edit_main_info, status: :unprocessable_entity
    end
  end

  def update_password
    if @user.valid_password?(params[:current_password])
      if params[:new_password].present? && params[:new_password] == params[:new_password_confirmation]
        @user.password_confirmation = params[:new_password_confirmation]
        if @user.change_password(params[:new_password])
          redirect_to profile_path, notice: t('users.notices.password_is_changed')
        else
          redirect_to edit_password_users_path, alert: "#{t('users.notices.error')}: #{@user.errors.full_messages.join(', ')}"
        end
      else
        redirect_to edit_password_users_path, alert: t('users.notices.password_confirm_is_wrong')
      end
    else
      redirect_to edit_password_users_path, alert: t('users.notices.current_password_is_wrong')
    end
  end

  def activate
    if @user = User.load_from_activation_token(params[:id])
      @user.activate!
      redirect_to login_path, notice: t('users.notices.user_is_activated'), status: :see_other
    else
      not_authenticated
    end
  end

  def unlock_account
    # находим аккаунт сначала по токену, а потом убеждаемся,
    # что свой аккаунт активирует тот, кто сейчас авторизован
    if @user = User.load_from_unlock_token(params[:token]) && @user.id == current_user.id
      @user.login_unlock!
      redirect_to login_path, notice: t('users.notices.update_your_password_if_you_forgotten_it')
    else
      not_authenticated
    end
  end

  def block
    user = User.find(params[:id])
    translation = Translation.find(params[:translation_id]) if params[:translation_id]
    if user.update!(is_blocked: !user.is_blocked)
      render partial: 'translations/translation_card',
        locals: { translation: translation }
    else
      head :unprocessable_entity
    end
  end

  private

  def user_params
    # params.require(:user).permit(:username, :password, :password_confirmation, :name)
    params.expect(user: %w[email name password password_confirmation])
  end

  def set_user
    @user = current_user
  end

  def set_active_menu_item
    @current_menu_item = 'users'
  end
end

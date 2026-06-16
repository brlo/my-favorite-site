class SessionsController < ApplicationController
  skip_before_action :require_login_and_activation, only: [:new, :create]
  before_action :redirect_if_logged_in, only: [:new, :create]

  rate_limit to: 30, within: 12.hours, by: -> { request.ip }, only: %w[create]

  def new
    @session = Session.new
  end

  def create
    # создаём объект только ради накопления и последующго отображения ошибок
    @session = Session.new(session_params)

    # предварительные проверки. Делаем это, чтобы подробнее отобразить ошибки в интерфейсе
    u = User.find_by(email: session_params[:email])
    @session.errors.add(:base, :invalid_credentials) if u.nil? || !u.valid_password?(session_params[:password])
    @session.errors.add(:base, :account_activation_pending) if u && u.activation_state != 'active'

    if @session.errors.none?
      # тут происходит реальная авторизация
      remember_me = session_params[:remember_me] == '1'
      login(session_params[:email], session_params[:password], remember_me) do |user, failure|
        if failure
          if failure == :locked
            flash.now[:alert] = t('users.notices.loggin_failed_account_is_locked')
          else
            flash.now[:alert] = t('users.notices.loggin_failed')
          end
          render :new, status: :unprocessable_entity
        else
          redirect_back_or_to root_path, notice: t('users.notices.logged_in')
        end
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    logout
    redirect_to login_path, notice: t('users.notices.logged_out')
  end

  private

  def session_params
    params.expect(session: %w[email password remember_me])
  end

  def redirect_if_logged_in
    if logged_in?
      redirect_to profile_path, notice: t('users.notices.already_logged_in')
    end
  end
end

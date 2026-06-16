class PasswordResetsController < ApplicationController
  skip_before_action :require_login_and_activation

  rate_limit to: 20, within: 1.day, by: -> { request.ip }, only: %w[create]
  rate_limit to: 20, within: 1.day, by: -> { params[:email] }, only: %w[create]

  # просим указать email для сброса пароля
  def new
  end

  # сюда отправляем email для сброса пароля
  # you get here when the user entered their email in the reset password form and submitted it.
  def create
    @user = User.find_by_email(params[:email])

    # This line sends an email to the user with instructions on how to reset their password (a url with a random token)
    @user.deliver_reset_password_instructions! if @user

    # Tell the user instructions have been sent whether or not email was found.
    # This is to not leak information to attackers about which emails exist in the system.
    redirect_to(login_path, :notice => t('helpers.label.session.password_reset_alert'))
  end

  # Форма для установки нового пароля
  def edit
    @token = params[:id]
    @user = User.load_from_reset_password_token(params[:id])

    if @user.blank?
      not_authenticated
      return
    end
  end

  # Сюда отправляем новый пароль
  def update
    @token = params[:id]
    @user = User.load_from_reset_password_token(params[:id])

    if @user.blank?
      not_authenticated
      return
    end

    # the next line makes the password confirmation validation work
    @user.password_confirmation = params[:user][:password_confirmation]
    # the next line clears the temporary token and updates the password
    if @user.change_password(params[:user][:password])
      redirect_to(login_path, :notice => t('helpers.label.session.password_reset_ok'))
    else
      render :action => "edit", status: 422
    end
  end
end

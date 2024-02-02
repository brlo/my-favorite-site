module Api
  class UsersController < ApiApplicationController
    # skip_before_action :reject_not_admins, only: [:psw_login, :telegram_login]

    def me
      user = ::Current.user
      if ::Current.user
        render json: {
          id: user.id,
          username: user.username,
          name: user.name,
          privs: user.privs_list
        }.merge(success_response)
      else
        render json: {errors: 'access denied'}.merge(fail_response), status: 401
      end
    end

    # Вход через сайт
    def psw_login
      @attrs = params.permit(:username, :password)

      @user =
      if @attrs[:username].present?
        ::User.by_site.where(username: @attrs[:username]).first
      end

      if @user && @user.authenticate(@attrs[:password]) && @user.allow_ip?(request.ip)
        render json: {api_token: @user.get_api_token()}.merge(success_response)
      else
        render json: {errors: 'access denied'}.merge(fail_response), status: 422
      end
    end

    # Вход через Телеграм
    def telegram_login
      # хэш, с которым мы сравниваем наши рассчёты
      auth_service = ::AuthTelegram.new(params[:tg_data])

      if auth_service.valid?
        user = auth_service.find_or_create_user!
        render json: {api_token: user.get_api_token()}.merge(success_response)
      else
        render json: {params: params}.merge(fail_response)
      end
    end

    private

    def success_response
      {'success': 'ok'}
    end

    def fail_response
      {'success': 'fail'}
    end
  end
end

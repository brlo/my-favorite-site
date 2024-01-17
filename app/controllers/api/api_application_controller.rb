# ВЗЯТО ТУТ: https://www.thegreatcodeadventure.com/rails-api-painless-error-handling-and-rendering-2/
# class ApiExceptionSerializer < ActiveModel::Serializers
#   attributes :status, :code, :message
# end
module Api
  class ApiApplicationController < ActionController::Base
    helper_method :logged_in?

    # skip CSRF-token checking
    skip_forgery_protection

    # skip_before_action :verify_authenticity_token
    before_action :set_current_user
    before_action :reject_not_admins
    around_action :delete_current_user
    before_action :set_locale

    rescue_from ::ActiveRecord::RecordNotFound, with: :record_not_found
    rescue_from ::NameError, with: :error_occurred
    rescue_from ::ActionController::RoutingError, with: :route_not_found

    def route_not_found(error)
      log_error(error)
      render json: {success: 'fail', error: 'route not found'}, status: 404
    end

    def record_not_found(error)
      log_error(error)
      render json: {success: 'fail', error: 'record not found'}, status: 404
    end

    def error_occurred(error)
      log_error(error)
      render json: {success: 'fail', error: error.message}, status: 500
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

    def set_current_user
      api_token = request.headers['HTTP_X_API_TOKEN']
      # puts '-----------api_token----------------'
      # puts api_token
      user =
      if api_token.present?
        ::User.find_by(api_token: api_token)
      elsif session[:user_id].present?
        ::User.find_by(id: session[:user_id])
      else
        nil
      end

      ::Current.user = ::CurrentUser.new(user)
    end

    def reject_not_admins
      # puts '-------------reject_not_admins----------------'
      # puts ::Current.user.inspect
      if ::Current.user.is_admin != true
        render json: {success: 'fail', errors: 'access denied'}, status: 401
      end
    end

    def delete_current_user
      begin
        yield # тут выполнится весь наш запрос
      rescue => e
        logger.error e.message
        logger.error e.backtrace.join("\n")
        raise(e)
      end
    ensure
      # to address the thread variable leak issues in Puma/Thin webserver
      ::Current.user = nil
    end

    def log_error(error)
      logger.error(error.message)
      logger.error(error.backtrace.join("\n"))
    end

    def ability?(action)
      if !::Current.user.ability?(action)
        render json: {success: 'fail', errors: 'access to action is denied'}, status: 401
      end
    end
  end
end

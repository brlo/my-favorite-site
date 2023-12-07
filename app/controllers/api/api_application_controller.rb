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
    around_action :set_current_user
    before_action :set_locale

    rescue_from ::ActiveRecord::RecordNotFound, with: :record_not_found
    rescue_from ::NameError, with: :error_occurred
    rescue_from ::ActionController::RoutingError, with: :route_not_found

    def route_not_found(error)
      render json: {success: 'fail', error: 'route not found'}, status: 404
    end

    def record_not_found(error)
      render json: {success: 'fail', error: 'record not found'}, status: 404
    end

    def error_occurred(error)
      render json: {success: 'fail', error: error.message}, status: 500
    end

    def current_lang
      # если поисковик не умеет куки, то хоть через локаль (которая в url) установит перевод
      @current_lang ||= begin
        _lang =
        if cookies[:'b-lang'].present?
          cookies[:'b-lang']
        elsif params[:locale].present?
          case params[:locale]
          when 'ru' ; 'ru'
          when 'en' ; 'eng-nkjv'
          when 'cs' ; 'csl-ru'
          when 'il' ; 'heb-osm'
          when 'gr' ; 'gr-lxx-byz'
          when 'jp' ; 'jp-ni'
          when 'cn' ; 'cn-ccbs'
          when 'de' ; 'ge-sch'
          when 'ar' ; 'arab-avd'
          else      ; 'ru'
          end
        end

        if ::CacheSearch::SEARCH_LANGS.include?(_lang)
          _lang
        else
          'ru'
        end
      end
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
      user =
      if request.headers['API_TOKEN'].present?
        ::User.find_by(id: request.headers['API_TOKEN'])
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
  end
end

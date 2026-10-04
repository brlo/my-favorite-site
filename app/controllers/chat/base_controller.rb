module Chat
  class BaseController < ::ApplicationController
    # Чат открыт и для гостей
    skip_before_action :require_login_and_activation

    helper_method :current_chat_member

    private

    def chat_identity
      @chat_identity ||= Chat::Identity.new(
        request: request, cookies: cookies, user: (current_user if logged_in?), locale: I18n.locale
      )
    end

    def current_chat_member
      @current_chat_member ||= chat_identity.member
    end

    def render_json_error(key, status:, i18n: {}, **extra)
      render json: { error: I18n.t("chat.errors.#{key}", **i18n), **extra }, status: status
    end

    def require_member!
      render_json_error(:forbidden, status: :forbidden) unless current_chat_member
    end

    def require_staff!
      render_json_error(:forbidden, status: :forbidden) unless current_chat_member&.staff?
    end

    def render_message_html(message)
      render_to_string(partial: 'chat/message', formats: [:html], locals: { message: message })
    end
  end
end

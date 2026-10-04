module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :chat_member_id

    def connect
      self.chat_member_id = find_chat_member&.id
    end

    private

    # Тот же порядок, что и в Chat::Identity: сначала пользователь по сессии, затем гость по cookie
    def find_chat_member
      if (user_id = session_user_id)
        Chat::Member.find_by(user_id: user_id)
      elsif (token = cookies.signed[Chat::Identity::GUEST_COOKIE]).present?
        Chat::Member.find_by(guest_token_digest: Chat::Member.digest_token(token))
      end
    end

    def session_user_id
      key = Rails.application.config.session_options[:key]
      cookies.encrypted[key]&.dig('user_id')
    end
  end
end

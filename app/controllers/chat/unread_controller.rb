module Chat
  # Счётчик непрочитанных для бейджа в шапке сайта.
  # Отдельный лёгкий эндпоинт: опрашивается со страниц, а не через ActionCable.
  class UnreadController < BaseController
    def show
      member = lookup_chat_member
      render json: member ? member.unread_summary : { count: 0, replies: 0 }
    end

    # Клиент отмечает прочитанным всё до последнего видимого ему сообщения.
    def mark
      member = current_chat_member
      return head :no_content if member.nil?

      room = Chat.default_room
      upto = room.messages.visible_to(member).where('id <= ?', params[:id].to_i).maximum(:id)
      member.mark_chat_read!(upto) if upto

      head :no_content
    end

    private

    # Поиск без побочных эффектов: опрос не должен обновлять last_seen_at и писать в БД.
    def lookup_chat_member
      Chat::Identity.new(
        request: request, cookies: cookies, user: (current_user if logged_in?), locale: I18n.locale
      ).lookup
    end
  end
end

module Chat
  # Общий рубильник чата (только для админов)
  class RoomsController < BaseController
    def update
      return render_json_error(:forbidden, status: :forbidden) unless current_chat_member&.admin?

      room = Chat.default_room
      room.posting_closed!(ActiveModel::Type::Boolean.new.cast(params[:posting_closed]) == true)
      Chat::Broadcaster.room(room)
      render json: { posting_closed: room.posting_closed? }
    end
  end
end

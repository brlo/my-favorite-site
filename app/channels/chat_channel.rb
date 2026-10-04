class ChatChannel < ApplicationCable::Channel
  def subscribed
    room = Chat::Room.find_by(id: params[:room_id])
    return reject unless room

    member = chat_member_id.present? ? Chat::Member.find_by(id: chat_member_id) : nil
    if member&.staff?
      stream_from room.staff_stream
    else
      stream_from room.public_stream
      stream_from member.personal_stream if member
    end
  end
end

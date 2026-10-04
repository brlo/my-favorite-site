module Chat
  # Рассылка изменений по ActionCable.
  #  - staff-стрим: все сообщения, включая скрытые;
  #  - public-стрим: только сообщения, видимые всем;
  #  - личные стримы автора и адресата: их скрытые/личные сообщения.
  # Админы подписаны только на staff-стрим, остальные — на public + личный.
  module Broadcaster
    module_function

    def message(msg)
      room = msg.room
      audience = personal_streams(msg)

      if msg.deleted?
        payload = { type: 'remove', id: msg.id }
        [room.staff_stream, room.public_stream, *audience].each { |s| send_to(s, payload) }
        return
      end

      payload = { type: 'upsert', id: msg.id, html: render(msg) }
      send_to(room.staff_stream, payload)
      send_to(room.public_stream, msg.public? ? payload : { type: 'remove', id: msg.id })
      audience.each { |s| send_to(s, payload) }
    end

    def reactions(msg)
      payload = { type: 'reactions', id: msg.id, reactions: msg.reactions_summary }
      streams = [msg.room.staff_stream, *personal_streams(msg)]
      streams << msg.room.public_stream if msg.public?
      streams.each { |s| send_to(s, payload) }
    end

    # Состояние комнаты (закрыт ли чат для сообщений)
    def room(room)
      payload = { type: 'room', posting_closed: room.posting_closed? }
      [room.staff_stream, room.public_stream].each { |s| send_to(s, payload) }
    end

    def render(msg)
      ::ChatController.render(partial: 'chat/message', locals: { message: msg })
    end

    def personal_streams(msg)
      [msg.member, msg.recipient_member].compact.uniq.reject(&:staff?).map(&:personal_stream)
    end

    def send_to(stream, payload)
      ActionCable.server.broadcast(stream, payload)
    end
  end
end

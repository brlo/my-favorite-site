module Chat
  class Room < ApplicationRecord
    has_many :messages, class_name: 'Chat::Message', dependent: :destroy

    validates :slug, presence: true, uniqueness: true

    # Общий рубильник: когда чат закрыт, писать могут только админы и модераторы
    def posting_closed?
      settings['posting_closed'] == true
    end

    def posting_closed!(closed)
      update!(settings: settings.merge('posting_closed' => closed))
    end

    def posting_allowed_for?(member)
      !posting_closed? || member&.staff? == true
    end

    # Стримы ActionCable
    def public_stream = "chat:room:#{id}:public"
    def staff_stream = "chat:room:#{id}:staff"
  end
end

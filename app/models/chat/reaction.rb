module Chat
  class Reaction < ApplicationRecord
    belongs_to :message, class_name: 'Chat::Message'
    belongs_to :member, class_name: 'Chat::Member'

    validates :emoji, inclusion: { in: Chat::REACTIONS }
  end
end

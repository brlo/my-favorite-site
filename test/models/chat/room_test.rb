require "test_helper"

class Chat::RoomTest < ActiveSupport::TestCase
  test "closed chat allows posting only to staff" do
    room = Chat.default_room
    guest = Chat::Member.create!(kind: 'guest', role: 'guest', nickname: Chat::Member.generate_guest_nickname)
    moderator = Chat::Member.create!(kind: 'user', role: 'moderator', nickname: Chat::Member.generate_guest_nickname)

    assert room.posting_allowed_for?(guest)
    room.posting_closed!(true)
    refute room.reload.posting_allowed_for?(guest)
    refute room.posting_allowed_for?(nil)
    assert room.posting_allowed_for?(moderator)
    room.posting_closed!(false)
    assert room.reload.posting_allowed_for?(guest)
  end
end

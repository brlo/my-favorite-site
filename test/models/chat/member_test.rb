require "test_helper"

class Chat::MemberTest < ActiveSupport::TestCase
  BODY = { 'type' => 'doc', 'content' => [{ 'type' => 'paragraph', 'content' => [{ 'type' => 'text', 'text' => 'hi' }] }] }.freeze

  setup do
    @room = Chat.default_room
    @member = member('guest', 'guest')
    @admin = member('user', 'admin')
  end

  def member(kind, role)
    Chat::Member.create!(kind: kind, role: role, nickname: Chat::Member.generate_guest_nickname)
  end

  def post(m, **attrs)
    msg = @room.messages.new(member: m, kind: 'text', lang: m.ui_lang, status: m.verified? ? 'published' : 'pending', **attrs)
    msg.assign_body(BODY, allow_links: false)
    msg.save!
    msg
  end

  test "unread counts only messages after joining and ignores own" do
    post(@admin) # история до прихода участника
    joiner = member('guest', 'guest')
    fresh = post(@admin)

    assert_equal 1, joiner.unread_summary[:count]
    assert_equal fresh.id, @room.messages.visible_to(joiner).where('id > ?', joiner.last_read_message_id).maximum(:id)
    post(joiner) # своё сообщение не считается
    assert_equal 1, joiner.unread_summary[:count]
  end

  test "unread marks replies and direct messages" do
    question = post(@member)
    reply = post(@admin, reply_to: question)
    direct = post(@admin, visibility: 'direct', recipient_member: @member)

    summary = @member.unread_summary
    assert_equal 2, summary[:count]
    assert_equal 2, summary[:replies]

    assert @member.mark_chat_read!(reply.id)
    assert_equal({ count: 1, replies: 1 }, @member.unread_summary)

    refute @member.mark_chat_read!(reply.id - 1)
    assert_equal reply.id, @member.reload.last_read_message_id
    assert direct.id > reply.id
  end

  test "pending messages of other members are not unread" do
    post(@admin, status: 'pending')

    assert_equal 0, @member.unread_summary[:count]
  end
end

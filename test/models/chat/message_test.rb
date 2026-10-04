require "test_helper"

class Chat::MessageTest < ActiveSupport::TestCase
  BODY = { 'type' => 'doc', 'content' => [{ 'type' => 'paragraph', 'content' => [{ 'type' => 'text', 'text' => 'hi' }] }] }.freeze

  setup do
    @room = Chat.default_room
    @guest = member('guest', 'guest')
    @other = member('guest', 'guest')
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

  test "guest messages are visible only to the author and staff" do
    q = post(@guest)
    assert q.pending?
    assert @room.messages.visible_to(@guest).exists?(q.id)
    assert @room.messages.visible_to(@admin).exists?(q.id)
    refute @room.messages.visible_to(@other).exists?(q.id)
    refute @room.messages.visible_to(nil).exists?(q.id)
  end

  test "approving publishes the message and private staff replies" do
    q = post(@guest)
    reply = post(@admin, reply_to: q, visibility: 'direct', recipient_member: @guest)
    refute @room.messages.visible_to(@other).exists?(reply.id)

    assert_equal [reply.id], q.approve!(by: @admin).map(&:id)
    assert q.reload.public?
    assert reply.reload.public?
  end

  test "guest edit of an approved message sends it back to moderation" do
    q = post(@guest)
    q.approve!(by: @admin)
    q.apply_edit!(BODY, editor: @guest)
    assert q.reload.pending?
  end

  test "edits are limited by count and time" do
    q = post(@guest)
    Chat::MAX_EDITS.times { q.apply_edit!(BODY, editor: @guest) }
    refute q.editable_by?(@guest)

    q2 = post(@guest)
    q2.update_column(:created_at, (Chat::EDIT_WINDOW + 1.minute).ago)
    refute q2.reload.editable_by?(@guest)
    refute post(@guest).editable_by?(@other)
  end

  test "translation cache ignores stale versions" do
    q = post(@admin)
    q.store_translation!('en', '<p>a</p>', version: q.edits_count)
    q.store_translation!('de', '<p>b</p>', version: q.edits_count + 1)
    q.reload
    assert_equal '<p>a</p>', q.cached_translation('en')
    assert_nil q.cached_translation('de')
  end

  test "retention job removes messages older than a year" do
    old = post(@admin)
    old.update_column(:created_at, (Chat::RETENTION + 1.day).ago)
    fresh = post(@admin)
    ChatRetentionJob.perform_now
    refute Chat::Message.exists?(old.id)
    assert Chat::Message.exists?(fresh.id)
  end
end

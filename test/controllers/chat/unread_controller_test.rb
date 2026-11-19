require "test_helper"

class Chat::UnreadControllerTest < ActionDispatch::IntegrationTest
  BODY = { 'type' => 'doc', 'content' => [{ 'type' => 'paragraph', 'content' => [{ 'type' => 'text', 'text' => 'hi' }] }] }.freeze

  setup do
    @room = Chat.default_room
    @user = create_user
    @guest = Chat::Member.create!(
      kind: 'user', role: 'member', user: @user, nickname: Chat::Member.generate_guest_nickname
    )
    @admin = Chat::Member.create!(kind: 'user', role: 'admin', nickname: Chat::Member.generate_guest_nickname)
    sign_in(@user)
  end

  def post_message(member, **attrs)
    msg = @room.messages.new(member: member, kind: 'text', lang: member.ui_lang, status: 'published', **attrs)
    msg.assign_body(BODY, allow_links: false)
    msg.save!
    msg
  end

  test "returns unread count and reply flag for the chat member" do
    question = post_message(@guest)
    reply = post_message(@admin, reply_to: question)

    get '/ru/chat/unread'
    assert_response :success
    assert_equal({ 'count' => 1, 'replies' => 1 }, response.parsed_body)
    assert_equal 1, @guest.reload.unread_summary[:count]
    assert reply.id > question.id
  end

  test "marking read resets the counter" do
    post_message(@admin)

    post '/ru/chat/read', params: { id: @room.messages.maximum(:id) }
    assert_response :no_content

    get '/ru/chat/unread'
    assert_equal({ 'count' => 0, 'replies' => 0 }, response.parsed_body)
  end

  test "anonymous visitor gets an empty counter" do
    reset!

    get '/ru/chat/unread'
    assert_response :success
    assert_equal({ 'count' => 0, 'replies' => 0 }, response.parsed_body)
  end

  test "header badge shows the unread count" do
    post_message(@admin, reply_to: post_message(@guest))

    get '/ru/tags'
    assert_response :success
    assert_select '#more-btn .chat-unread', text: '1'
    assert_select '#more-btn .chat-unread--reply', count: 1
  end
end

class ChatController < Chat::BaseController
  def show
    remember_entry_page
    @room = Chat.default_room
    @member = current_chat_member
    @messages = @room.messages.visible_to(@member)
                     .includes(:member, reply_to: :member)
                     .order(id: :desc).limit(Chat::PAGE_SIZE).to_a.reverse
    @has_more = @messages.size == Chat::PAGE_SIZE
    @my_reactions = my_reactions(@messages)
    @wait_seconds = Chat::RateLimiter.wait_seconds(@member)

    @page_title = t('chat.title')
    @meta_description = t('chat.description')
    @current_menu_item = 'chat'
    @no_index = true
  end

  private

  # Запоминаем страницу сайта, с которой человек пришёл в чат
  def remember_entry_page
    ref = URI.parse(request.referer.to_s) rescue nil
    return unless ref&.host == request.host && ref.path.present? && !ref.path.match?(%r{\A/[^/]+/chat(/|\z)})

    cookies[Chat::Identity::ENTRY_COOKIE] = { value: ref.request_uri.to_s[0, 500], expires: 1.day, same_site: :lax }
  end

  def my_reactions(messages)
    return {} unless @member

    Chat::Reaction.where(member: @member, message_id: messages.map(&:id))
                  .pluck(:message_id, :emoji)
                  .group_by(&:first).transform_values { |v| v.map(&:last) }
  end
end

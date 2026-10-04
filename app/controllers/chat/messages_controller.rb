module Chat
  class MessagesController < BaseController
    before_action :set_message, only: %i[show update destroy approve react translate]
    before_action :require_member!, only: %i[update destroy approve react]

    rescue_from Chat::RichText::Invalid do |e|
      key = e.message == 'too long' ? :too_long : :invalid_body
      render_json_error(key, status: :unprocessable_entity, i18n: { count: Chat::MAX_TEXT_LENGTH })
    end

    # Более старые сообщения (подгрузка при прокрутке вверх)
    def index
      room = Chat.default_room
      scope = room.messages.visible_to(current_chat_member).includes(:member, reply_to: :member)
      scope = scope.where(id: ...params[:before].to_i) if params[:before].present?
      messages = scope.order(id: :desc).limit(Chat::PAGE_SIZE).to_a.reverse

      reactions = if current_chat_member
                    Chat::Reaction.where(member: current_chat_member, message_id: messages.map(&:id))
                                  .pluck(:message_id, :emoji)
                                  .group_by(&:first).transform_values { |v| v.map(&:last) }
                  else
                    {}
                  end

      render json: {
        html: messages.map { |m| render_message_html(m) }.join,
        has_more: messages.size == Chat::PAGE_SIZE,
        my_reactions: reactions
      }
    end

    # Документ для редактора (при редактировании)
    def show
      return render_json_error(:forbidden, status: :forbidden) unless @message.editable_by?(current_chat_member)

      render json: { id: @message.id, body: @message.body_json }
    end

    def create
      room = Chat.default_room
      existing = current_chat_member
      return render_json_error(:banned, status: :forbidden) if existing&.banned?
      return render_json_error(:muted, status: :forbidden) if existing&.muted?
      return render_json_error(:closed, status: :forbidden) unless room.posting_allowed_for?(existing)

      # тело проверяем до создания гостя, чтобы не плодить участников на пустых запросах
      rich = Chat::RichText.new(params.require(:body), allow_links: existing&.staff? == true).call

      member = existing || chat_identity.member(create: true)
      reply_to = params[:reply_to_id].present? ? room.messages.find_by(id: params[:reply_to_id]) : nil
      reply_to = nil unless reply_to&.visible_to?(member)

      message = room.messages.new(
        member: member, reply_to: reply_to, kind: 'text', lang: member.ui_lang,
        status: member.verified? ? 'published' : 'pending',
        body_json: rich.json, body_html: rich.html, body_text: rich.text
      )
      direct_recipient(member, reply_to)&.then do |recipient|
        message.visibility = 'direct'
        message.recipient_member = recipient
      end

      if (wait = Chat::RateLimiter.acquire(member))
        return render_json_error(:rate_limited, status: :too_many_requests, retry_after: wait, member_id: member.id)
      end

      begin
        message.save!
      rescue ActiveRecord::RecordInvalid
        Chat::RateLimiter.release(member)
        return render_json_error(:invalid_body, status: :unprocessable_entity)
      end

      Chat::Broadcaster.message(message)
      render json: {
        id: message.id,
        html: render_message_html(message),
        member_id: member.id,
        retry_after: member.rate_limited? ? Chat::POST_INTERVAL.to_i : 0
      }, status: :created
    end

    def update
      return render_json_error(:cant_edit, status: :forbidden) unless @message.editable_by?(current_chat_member)
      return render_json_error(:closed, status: :forbidden) unless @message.room.posting_allowed_for?(current_chat_member)

      @message.apply_edit!(params.require(:body), editor: current_chat_member)
      Chat::Broadcaster.message(@message)
      render json: { id: @message.id, html: render_message_html(@message) }
    end

    def destroy
      return render_json_error(:forbidden, status: :forbidden) unless @message.deletable_by?(current_chat_member)

      @message.soft_delete!(by: current_chat_member)
      Chat::Broadcaster.message(@message)
      render json: { id: @message.id, deleted: true }
    end

    # Сделать сообщение гостя видимым для всех
    def approve
      return render_json_error(:forbidden, status: :forbidden) unless @message.approvable_by?(current_chat_member)

      replies = @message.approve!(by: current_chat_member)
      Chat::Broadcaster.message(@message)
      replies.each { |reply| Chat::Broadcaster.message(reply) }
      render json: { id: @message.id, html: render_message_html(@message) }
    end

    # Поставить/снять реакцию
    def react
      member = current_chat_member
      emoji = params[:emoji].to_s
      return render_json_error(:forbidden, status: :forbidden) unless member.verified? && !member.banned? && @message.visible_to?(member)
      return render_json_error(:invalid_body, status: :unprocessable_entity) unless Chat::REACTIONS.include?(emoji)
      unless Chat::RateLimiter.allow?("chat:react:#{member.id}", limit: 30, period: 1.minute)
        return render_json_error(:too_many_requests, status: :too_many_requests)
      end

      existing = @message.reactions.find_by(member: member, emoji: emoji)
      if existing
        existing.destroy!
        active = false
      else
        begin
          @message.reactions.create!(member: member, emoji: emoji)
        rescue ActiveRecord::RecordNotUnique
          nil
        end
        active = true
      end
      @message.recount_reactions!
      Chat::Broadcaster.reactions(@message)
      render json: { id: @message.id, reactions: @message.reactions_summary, emoji: emoji, active: active }
    end

    # Перевести сообщение на язык интерфейса зрителя. Перевод кэшируется в самом сообщении.
    def translate
      to = params[:to].presence || I18n.locale.to_s
      return render_json_error(:forbidden, status: :forbidden) unless @message.visible_to?(current_chat_member) || @message.public?
      return render_json_error(:cant_translate, status: :unprocessable_entity) unless Chat::Translator.translatable?(@message.lang, to)

      if (html = @message.cached_translation(to))
        return render json: { id: @message.id, lang: to, html: html }
      end

      limiter_key = "chat:tr:#{current_chat_member&.id || Chat::Member.hash_ip(request.remote_ip)}"
      unless Chat::RateLimiter.allow?(limiter_key, limit: Chat::Translator::LIMIT_PER_HOUR, period: 1.hour)
        return render_json_error(:too_many_requests, status: :too_many_requests)
      end

      html = translate_once(@message, to)
      render json: { id: @message.id, lang: to, html: html }
    rescue Chat::Translator::Error => e
      Rails.logger.warn("[chat] translate failed: #{e.message}")
      render_json_error(:translate_failed, status: :bad_gateway)
    end

    private

    def set_message
      @message = Chat.default_room.messages.alive.find(params[:id])
    end

    # Ответ админа на скрытое (неодобренное/личное) сообщение по умолчанию тоже личный:
    # его видят только собеседник и админы.
    def direct_recipient(member, reply_to)
      return nil unless member.staff? && reply_to && !reply_to.public?

      target = reply_to.member.staff? ? reply_to.recipient_member : reply_to.member
      target unless target.nil? || target.staff?
    end

    # Одновременные запросы одного перевода не должны дважды идти в Яндекс
    def translate_once(message, to)
      lock_key = "chat:tr:lock:#{message.id}:#{to}"
      locked = ::RedisConnectionPool.set(lock_key, 1, nx: true, ex: 20)
      unless locked
        10.times do
          sleep 0.5
          cached = message.reload.cached_translation(to)
          return cached if cached
        end
      end

      version = message.edits_count
      raw = Chat::Translator.translate_html(message.body_html, from: message.lang, to: to)
      html = sanitize_translation(raw)
      message.store_translation!(to, html, version: version)
      html
    ensure
      ::RedisConnectionPool.del(lock_key) if locked
    end

    # Ответ внешнего сервиса тоже чистим: разрешаем только те теги, что строит Chat::RichText
    def sanitize_translation(html)
      Sanitize.fragment(
        html,
        elements: %w[p blockquote br strong u s a],
        attributes: { 'a' => %w[href] },
        protocols: { 'a' => { 'href' => %w[http https] } },
        add_attributes: { 'a' => { 'rel' => 'nofollow ugc noopener noreferrer', 'target' => '_blank' } }
      )
    end
  end
end

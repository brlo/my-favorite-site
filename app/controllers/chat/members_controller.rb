module Chat
  class MembersController < BaseController
    before_action :set_member
    before_action :require_staff!, only: :update

    # Карточка участника: ник, флажок, титул, описание.
    # Админы дополнительно видят, откуда человек пришёл, и управляют титулом/блокировкой.
    def show
      @staff = current_chat_member&.staff? == true
      @messages_count = @member.messages.alive.count
      @page_title = @member.nickname
      @no_index = true
    end

    def update
      viewer = current_chat_member
      # админа чата меняют только в админке сайта (users.is_admin / привилегия chat_admin), модератор не может трогать модератора
      if @member.admin? || (@member.staff? && !viewer.admin?)
        return render_json_error(:forbidden, status: :forbidden)
      end

      attrs = {}
      attrs[:title] = params[:title].to_s.strip.presence if params.key?(:title)
      if params.key?(:role) && viewer.admin? && !@member.guest? && !@member.bot?
        attrs[:role] = params[:role] == 'moderator' ? 'moderator' : 'member'
      end
      attrs[:muted_until] = params[:mute_hours].to_i.hours.from_now if params[:mute_hours].to_i > 0
      attrs[:banned_until] = params[:ban_days].to_i.days.from_now if params[:ban_days].to_i > 0
      attrs.merge!(muted_until: nil, banned_until: nil) if params[:unban].present?

      if @member.update(attrs)
        render json: { id: @member.id, title: @member.title, role: @member.role,
                       muted_until: @member.muted_until, banned_until: @member.banned_until }
      else
        render json: { error: @member.errors.full_messages.to_sentence }, status: :unprocessable_entity
      end
    end

    private

    def set_member
      @member = Chat::Member.find(params[:id])
    end
  end
end

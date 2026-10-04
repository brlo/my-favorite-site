module Chat
  # Профиль в чате доступен только зарегистрированным пользователям с подтверждённой почтой
  class ProfilesController < BaseController
    before_action :require_verified_user

    def edit
      @page_title = t('chat.profile.title')
      @no_index = true
    end

    def update
      if @member.update(profile_params)
        redirect_to chat_member_path(@member), notice: t('chat.profile.saved')
      else
        @page_title = t('chat.profile.title')
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def require_verified_user
      if !logged_in?
        redirect_to login_path, alert: t('chat.errors.login_required')
        return
      end

      @member = chat_identity.member(create: true)
      return if @member.verified?

      redirect_to chat_path, alert: t('chat.errors.activation_required')
    end

    def profile_params
      params.expect(chat_member: %i[nickname bio avatar remove_avatar])
    end
  end
end

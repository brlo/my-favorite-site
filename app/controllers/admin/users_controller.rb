module Admin
  # Модерация пользователей (только для админов)
  class UsersController < BaseController
    CHAT_ROLES = {
      'member'    => 'Участник',
      'moderator' => 'Модератор',
      'admin'     => 'Администратор чата',
    }.freeze

    FILTERS = {
      'all'           => 'Все',
      'not_activated' => 'Почта не подтверждена',
      'stale'         => 'Не подтвердили почту за 3 дня (часто боты)',
      'blocked'       => 'Заблокированные',
      'locked'        => 'Вход заморожен',
      'staff'         => 'С привилегиями',
      'admins'        => 'Админы',
    }.freeze

    before_action :require_is_admin
    before_action :set_user, except: %i[index bulk_destroy]
    before_action :protect_self, only: %i[toggle_block destroy]

    def index
      @term = params[:term].to_s.strip
      @filter = params[:filter].presence_in(FILTERS.keys) || 'all'

      @users = ::User.order(created_at: :desc)
      if @term.present?
        t = "%#{::User.sanitize_sql_like(@term)}%"
        @users = @users.where('email ILIKE :t OR username ILIKE :t OR name ILIKE :t OR CAST(id AS text) = :id', t:, id: @term)
      end

      @users =
        case @filter
        when 'not_activated' then @users.where(activation_state: [nil, 'pending']).where.not(email: [nil, ''])
        when 'stale'         then @users.where(activation_state: [nil, 'pending']).where.not(email: [nil, ''])
                                        .where(is_admin: false, created_at: ...3.days.ago)
        when 'blocked'       then @users.where(is_blocked: true)
        when 'locked'        then @users.where.not(lock_expires_at: nil)
        when 'staff'         then @users.where("privs <> '{}'::jsonb OR cardinality(pages_owner) > 0 OR is_admin")
        when 'admins'        then @users.where(is_admin: true)
        else @users
        end

      @users = @users.page(params[:page]).per(50)
    end

    def edit
    end

    def update
      was_chat_admin = @user.privs.to_h['chat_admin'] == true
      @user.assign_attributes(user_params)
      chat_role = params.dig(:user, :chat_role).presence_in(CHAT_ROLES.keys)
      # privs собираются из чекбоксов заново, поэтому chat_admin выставляем по выбранной роли
      @user.privs = @user.privs.merge('chat_admin' => true) if chat_role == 'admin' || (chat_role.nil? && was_chat_admin)

      # себе нельзя снять права админа или заблокировать себя
      if @user == current_user && (!@user.is_admin || @user.is_blocked)
        @user.errors.add(:base, 'Нельзя снять с себя права админа или заблокировать себя')
        render :edit, status: :unprocessable_entity
        return
      end

      if @user.save
        apply_chat_role(chat_role) if chat_role
        notice = 'Пользователь сохранён'
        notice += '. На новую почту отправлено письмо для подтверждения' if @user.previous_changes.key?('email')
        redirect_to edit_admin_user_path(@user), notice:
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # Повторно отправить письмо со ссылкой на подтверждение почты
    def resend_activation
      return back_with(alert: 'У пользователя нет почты') if @user.email.blank?
      return back_with(alert: 'Почта уже подтверждена') if @user.activated?
      if ::SendUserEmailJob.sent_count('activation_needed_email', @user.id) >= ::SendUserEmailJob::DAILY_LIMIT
        return back_with(alert: 'Достигнут суточный лимит писем подтверждения для этого пользователя')
      end

      # у старых пользователей токена активации может не быть — создаём
      if @user.activation_token.blank?
        @user.setup_activation
        @user.save!(validate: false)
      end

      ::I18n.with_locale(email_locale) { ::UserMailer.activation_needed_email(@user) }
      back_with(notice: "Письмо для подтверждения почты поставлено в очередь (#{@user.email})")
    end

    # Подтвердить почту вручную, без письма
    def activate
      @user.activate!
      back_with(notice: 'Почта отмечена как подтверждённая')
    end

    def send_password_reset
      return back_with(alert: 'У пользователя нет почты') if @user.email.blank?

      # sorcery не шлёт письмо повторно чаще, чем раз в reset_password_time_between_emails.
      # Результат deliver_reset_password_instructions! для этого не годится: UserMailer ставит задание в очередь и возвращает nil.
      pause = ::User.sorcery_config.reset_password_time_between_emails
      if pause && @user.reset_password_email_sent_at&.after?(pause.seconds.ago)
        return back_with(alert: 'Письмо для сброса пароля уже отправлялось несколько минут назад, попробуйте позже')
      end

      ::I18n.with_locale(email_locale) { @user.deliver_reset_password_instructions! }
      back_with(notice: "Письмо для сброса пароля поставлено в очередь (#{@user.email})")
    end

    # Снять заморозку входа после множества неверных паролей
    def unlock
      @user.login_unlock!
      back_with(notice: 'Вход разморожен, счётчик неудачных попыток сброшен')
    end

    def destroy
      if (reason = undeletable_reason(@user))
        return back_with(alert: "Нельзя удалить: #{reason}")
      end

      @user.destroy!
      redirect_to admin_users_path, notice: "Пользователь #{@user.email || @user.username} удалён", status: :see_other
    end

    # Массовое удаление отмеченных в списке (обычно ботов)
    def bulk_destroy
      users = ::User.where(id: Array(params[:ids]).map(&:to_i)).to_a
      deleted, skipped = users.partition { undeletable_reason(_1).nil? }
      ::User.transaction { deleted.each(&:destroy!) }

      msg = "Удалено пользователей: #{deleted.size}"
      msg += ". Пропущено (админы, вы сами или авторы статей): #{skipped.map(&:username).join(', ')}" if skipped.any?
      redirect_to return_to_path || admin_users_path, notice: msg, status: :see_other
    end

    def toggle_block
      @user.update_column(:is_blocked, !@user.is_blocked)
      back_with(notice: @user.is_blocked ? 'Пользователь заблокирован' : 'Пользователь разблокирован')
    end

    private

    def set_user
      @user = ::User.find(params[:id])
    end

    def protect_self
      back_with(alert: 'Это действие нельзя применить к себе') if @user == current_user
    end

    # возвращаемся туда, откуда нажали кнопку: список передаёт свой адрес в return_to, иначе — в карточку
    def back_with(**messages)
      redirect_to return_to_path || edit_admin_user_path(@user), **messages, status: :see_other
    end

    def return_to_path
      path = params[:return_to].to_s
      path if path.start_with?('/admin/') && !path.start_with?('//')
    end

    def undeletable_reason(user)
      return 'это вы' if user == current_user
      return 'это админ' if user.is_admin
      # статьи при удалении автора остались бы без автора — пусть это будет осознанное решение
      return "у пользователя есть статьи (#{user.pages.count})" if user.pages.exists?
    end
    helper_method :undeletable_reason

    # Роль в чате: админ хранится в привилегии chat_admin (см. update), модератор — в профиле участника чата
    def apply_chat_role(role)
      member = @user.chat_member
      if member.nil?
        return if role == 'member' # профиль в чате создастся сам при первом заходе
        member = ::Chat::Member.create!(kind: 'user', role: 'member', user: @user, ui_lang: 'ru',
                                        nickname: ::Chat::Member.generate_user_nickname(@user))
      end
      member_role = @user.chat_admin? ? 'admin' : role
      member.update_column(:role, member_role) if member.role != member_role
    end

    def chat_role_of(user)
      return 'admin' if user.chat_admin?
      user.chat_member&.role == 'moderator' ? 'moderator' : 'member'
    end
    helper_method :chat_role_of

    # язык письма (ссылки в письме ведут на сайт с этой локалью)
    def email_locale
      params[:email_locale].presence_in(::I18n.available_locales.map(&:to_s)) || 'ru'
    end

    def user_params
      attrs = params.require(:user).permit(:name, :username, :email, :is_admin, :is_blocked, :pages_owner, :allow_ips, privs: {})

      # чекбоксы привилегий → { 'pages_read' => true, ... } (неизвестные ключи отбрасываем,
      # chat_admin выставляется отдельно через роль в чате)
      attrs[:privs] = ::User::PRIVS.keys.select { attrs.dig(:privs, _1) == '1' }.index_with { true }
      attrs[:pages_owner] = attrs[:pages_owner].to_s.scan(/\d+/).map(&:to_i).uniq if attrs.key?(:pages_owner)
      attrs[:allow_ips] = attrs[:allow_ips].to_s.split(/[\s,]+/).compact_blank.uniq if attrs.key?(:allow_ips)
      attrs[:email] = attrs[:email].presence if attrs.key?(:email)
      attrs
    end
  end
end

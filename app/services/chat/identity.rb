module Chat
  # Определяет участника чата по текущему запросу.
  # Зарегистрированный пользователь — по сессии, гость — по подписанной cookie.
  # Гость создаётся лениво (при первом сообщении), чтобы не плодить записи на каждого зашедшего.
  class Identity
    GUEST_COOKIE = :chat_gid
    LANDING_COOKIE = 'bx_landing'.freeze      # пишет JS (landing_controller) при первом заходе на сайт
    ENTRY_COOKIE = :bx_chat_entry             # страница, с которой открыли чат

    def initialize(request:, cookies:, user:, locale:)
      @request = request
      @cookies = cookies
      @user = user
      @locale = locale.to_s
    end

    # Найти участника. С create: true — создать, если его ещё нет.
    def member(create: false)
      @member ||= @user ? member_for_user(create) : member_for_guest(create)
      touch!(@member) if @member
      @member
    end

    private

    def member_for_user(create)
      m = Member.find_by(user_id: @user.id)
      # гость зарегистрировался: его гостевой профиль (и история) переходит к пользователю
      if m.nil? && (guest = guest_from_cookie) && guest.user_id.nil?
        guest.update!(kind: 'user', role: 'member', user: @user, guest_token_digest: nil,
                      nickname: Member.generate_user_nickname(@user))
        @cookies.delete(GUEST_COOKIE)
        m = guest
      end
      if m.nil? && create
        m = Member.create!(kind: 'user', role: 'member', user: @user,
                           nickname: Member.generate_user_nickname(@user), **origin_attrs)
      end
      if m
        # роль админа берётся из пользователя (users.is_admin или привилегия chat_admin)
        role = @user.chat_admin? ? 'admin' : (m.role == 'admin' ? 'member' : m.role)
        m.update_column(:role, role) if m.role != role
      end
      m
    end

    def member_for_guest(create)
      m = guest_from_cookie
      return m if m || !create

      token = SecureRandom.urlsafe_base64(32)
      m = Member.create!(kind: 'guest', role: 'guest', guest_token_digest: Member.digest_token(token),
                         nickname: Member.generate_guest_nickname, **origin_attrs)
      @cookies.permanent.signed[GUEST_COOKIE] = { value: token, httponly: true, same_site: :lax }
      m
    end

    def guest_from_cookie
      token = @cookies.signed[GUEST_COOKIE]
      token.present? ? Member.find_by(guest_token_digest: Member.digest_token(token)) : nil
    end

    def origin_attrs
      landing = landing_cookie
      {
        ui_lang: @locale,
        landing_url: safe_path(landing['u']),
        landing_referrer: landing['r'],
        landing_at: (Time.zone.at(landing['t'].to_i / 1000) if landing['t'].to_i > 0),
        chat_entry_url: safe_path(@cookies[ENTRY_COOKIE])
      }
    end

    def landing_cookie
      data = JSON.parse(@cookies[LANDING_COOKIE].to_s) # Rack уже раскодировал значение
      data.is_a?(Hash) ? data.transform_values { |v| v.to_s[0, 500] } : {}
    rescue JSON::ParserError
      {}
    end

    # Cookie может подделать кто угодно, а ссылки потом видит админ:
    # принимаем только относительные пути этого сайта.
    def safe_path(value)
      path = value.to_s[0, 500]
      path if path.match?(%r{\A/(?![/\\])[^\s<>"]*\z})
    end

    # Обновляем язык интерфейса (по нему флажок), IP и время последнего визита
    def touch!(m)
      attrs = { ui_lang: @locale, ip_hash: Member.hash_ip(@request.remote_ip) }
      entry = safe_path(@cookies[ENTRY_COOKIE])
      attrs[:chat_entry_url] = entry if entry
      attrs[:last_seen_at] = Time.current if m.last_seen_at.nil? || m.last_seen_at < 5.minutes.ago
      attrs.select! { |k, v| m.public_send(k) != v }
      m.update_columns(attrs) if attrs.any?
    end
  end
end

class UserMailer
  class << self
    include Rails.application.routes.url_helpers

    # письмо со ссылкой на подтверждение почты
    def activation_needed_email(user)
      user = User.find(user.id)
      url  = activate_user_url(id: user.activation_token, protocol: 'https', host: 'bibleox.com')

      send_with_limits(
        type: 'activation_needed_email',
        user_id: user.id,
        email: user.email,
        subject: ::I18n.t('users.letters.activation_needed.subject'),
        body: ::I18n.t('users.letters.activation_needed.body', name: user&.name, url:)
      )
    end

    # Это кажется лишним раздражающим фактором. Решил не отправлять пользователю это письмо.
    def activation_success_email(user)
      # user = User.find(user.id)
      # url  = login_url(protocol: 'https', host: 'bibleox.com')

      # send_with_limits(
      #   type: 'activation_success_email',
      #   user_id: user.id,
      #   email: user.email,
      #   subject: ::I18n.t('users.letters.email_is_activated.subject'),
      #   body: ::I18n.t('users.letters.email_is_activated.body', name: user&.name, url:)
      # )
    end

    # письмо со ссылкой на сброс пароля
    def reset_password_email(user)
      user = User.find(user.id)
      url  = edit_password_reset_url(id: user.reset_password_token, protocol: 'https', host: 'bibleox.com')

      send_with_limits(
        type: 'reset_password_email',
        user_id: user.id,
        email: user.email,
        subject: ::I18n.t('users.letters.password_reset.subject'),
        body: ::I18n.t('users.letters.password_reset.body', name: user&.name, url:)
      )
    end

    # письмо со ссылкой на разблокировку аккаунта после большого количества ввода неправильных паролей
    def send_unlock_token_email(user_id)
      user = User.find(user_id)
      url  = unlock_account_users_url(token: user.unlock_token, protocol: 'https', host: 'bibleox.com')

      send_with_limits(
        type: 'send_unlock_token_email',
        user_id: user.id,
        email: user.email,
        subject: ::I18n.t('users.letters.account_unlock.subject'),
        body: ::I18n.t('users.letters.account_unlock.body', name: user&.name, url:)
      )
    end

    private

    # отправка письма с учётом ограничений (два письма одного типа в сутки)
    def send_with_limits(type:, user_id:, email:, subject:, body:)
      raise('There is no type') if type.blank?
      raise('There is no user id') if user_id.blank?
      raise('There is no email') if email.blank?
      raise('There is no subject') if subject.blank?
      raise('There is no body') if body.blank?

      # только для "activation_needed_email" настроена валидация в модели, которая воспрепятствует самому действию.
      # в остальных же случаях действие произойдёт, но письмо не будет отправлено (просто пропускаем, без ошибок)
      if can_fire?(type, user_id)
        result = ::MyMailer.send_mail(email: , subject:, body:)
        fired(type, user_id)
        result
      end
    end

    # запоминаем в редисе, что письмо отправлено
    def fired(type, user_id)
      ttls = Hash.new(1.day.to_i)
      ttls['activation_needed_email'] = 1.day.to_i # письмо со ссылкой на подтверждение почты
      ttls['reset_password_email']    = 1.day.to_i # письмо со ссылкой на сброс пароля
      ttls['send_unlock_token_email'] = 1.day.to_i # письмо со ссылкой на разблокировку аккаунта после большого количества ввода неправильных паролей

      redis_key = mailer_redis_key(type, user_id)
      count = ::RedisConnectionPool.incr(redis_key)
      if count == 1
        ::RedisConnectionPool.expire(redis_key, ttls[type.to_s])
      end
    end

    # можеим отправлять письмо?
    def can_fire?(type, user_id)
      count = ::RedisConnectionPool.get(mailer_redis_key(type, user_id))
      count.to_i < 2
    end

    def mailer_redis_key(type, user_id)
      "mail:#{type}:#{user_id}"
    end
  end
end

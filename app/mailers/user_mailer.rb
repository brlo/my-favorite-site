class UserMailer
  # Тест почты:
  # ::MyMailer.send_mail(email: 'r.mk834@ya.ru', subject: 'test', body: 'TEST IT')
  #
  # Повторная отправка письма для активации:
  # user = User.find(20); user
  # SendUserEmailJob.perform("activation_needed_email", user.id)
  #
  # или в фоне:
  # UserMailer.activation_needed_email(user) # в фоне

  class << self
    def activation_needed_email(user)
      SendUserEmailJob.perform_later("activation_needed_email", user.id)
    end

    def reset_password_email(user)
      SendUserEmailJob.perform_later("reset_password_email", user.id)
    end

    def send_unlock_token_email(user_id)
      SendUserEmailJob.perform_later("unlock_token_email", user_id)
    end

    def activation_success_email(user)
      # Отключено
    end
  end
end

# Собственный почтовый сервер

# # отправка письма
# ::MyMailer.send_mail(email: 'r.mk834@ya.ru', body: 'test', subject: 'Bibleox')

# # отправка письма на разные email
# ::MyMailer.send_mail_bulk(emails: ['a+1@ya.ru', 'a+2@ya.ru', 'a+3@ya.ru', 'a+4@ya.ru', 'a+5@ya.ru'], body: '<h1>Test</h1><br><br>a<b>b</b> '*2, subject: 'Bibleox')

# # отправка письма в фоне
# ::MyMailer.send_mail_async(email: 'a@ya.ru', body: '<h1>Test</h1><br><br>a<b>b</b> '*2, subject: 'Bibleox').join

class MyMailer
  THROTTLE_RATE = 5
  THROTTLER = ::Concurrent::Throttle.new(THROTTLE_RATE)
  FROM_EMAIL = 'Bibleox <noreply@bibleox.com>'
  DEFAULT_SUBJECT = "Bibleox / уведомление"

  # Параметры SMTP для домена bibleox.com
  OPTIONS = {
    :address              => ::SETTINGS.dig('mailer', 'address'),
    :port                 => ::SETTINGS.dig('mailer', 'port'),
    :user_name            => ::SETTINGS.dig('mailer', 'user_name'),
    :password             => ::SETTINGS.dig('mailer', 'password'),
  }

  # рабочий код только если есть настройки И не_тест
  if !::Rails.env.test? && ::SETTINGS.fetch('mailer', nil)

    # конечный метод для отправки подготовленного Message-объекта
    #
    # !!! ЕДИНСТВЕННАЯ ВО ВСЕЙ СИСТЕМЕ ТОЧКА, КУДА ДОЛЖНЫ СХОДИТЬСЯ ВСЕ ПОПЫТКИ ОТПРАВИТЬ ПОЧТУ
    #
    def send_obj(msg_obj)
      msg_obj.from = FROM_EMAIL
      msg_obj.delivery_method(:smtp, OPTIONS)
      msg_obj.deliver!
    end

    # конечный метод для подготовки Message-объекта к отправке
    def send_mail(email:, html_body:, subject:, headers: nil, msg_obj: nil)
      mail =
      ::Mail.new do
        to       email
        subject  subject

        # # Простой текст можно отправить тут
        # body     txt

        # # и тут
        # text_part do
        #   body 'This is plain text'
        # end

        html_part do
          content_type 'text/html; charset=UTF-8'
          body html_body # '<h1>Funky Title</h1>'
        end
      end

      headers&.each do |key, value|
        mail.header[key] = value
      end

      send_obj(mail)
    end

    # отправка письма по шаблону
    def send_mail_by_template(email:, subject:, template:, variables: nil, headers: nil)
      html_body = template.dup

      if variables.present?
        variables.each do |key, value|
          html_body.gsub!("%-#{key}-%", value)
        end
      end

      self.send_mail(email: email, html_body: html_body, subject: subject, headers: headers)
    end

    class << self
      # отправка подготовленного объекта-письма из ActionMailer
      def send_obj(msg_obj)
        new.send_obj(msg_obj)
      end

      # отправка письма
      def send_mail(email:, body: nil, html_body: nil, subject: DEFAULT_SUBJECT)
        html_body = html_body || text_to_simple_html(body, subject: subject)

        new.send_mail(email: email, html_body: html_body, subject: subject)
      end

      # асинхронная отправка одного письма (возвращает thread)
      def send_mail_async(email:, body: nil, html_body: nil, subject: DEFAULT_SUBJECT)
        html_body = html_body || text_to_simple_html(body, subject: subject)

        ::Thread.new do
          THROTTLER.acquire do
            new.send_mail(email: email, html_body: html_body, subject: subject)
          end
        end
      end

      # массовая отправка одинаковых писем асинхронно
      def send_mail_bulk(emails:, body: nil, html_body: nil, subject: DEFAULT_SUBJECT)
        return unless emails&.any?

        # чтобы сэкономить ресурсы на отправке одинаковых писем,
        # конвертируем текст в html только один раз
        html_body ||= text_to_simple_html(body, subject: subject)

        emails.each_slice(100) do |emails|
          emails.map do |e|
            send_mail_async(email: e, html_body: html_body, subject: subject)
          end.map(&:join)
        end
      end

      # массовая отправка писем по шалону с подставлением переменных
      def send_bulk_by_template(template:, recipients:, subject: DEFAULT_SUBJECT, headers: nil)
        recipients.each_slice(100) do |_recipients|
          _recipients.map do |recipient|
            ::Thread.new do
              THROTTLER.acquire do
                new.send_mail_by_template(
                  email: recipient[:email],
                  subject: subject,
                  template: template,
                  variables: recipient[:variables],
                  headers: headers,
                )

                print '.'
              end
            end
          end.each(&:join)
        end
      end

      # Оформляет текст в примитивный html-шаблон
      def text_to_simple_html text, subject: DEFAULT_SUBJECT
        html =
        "<html>" +
          "<div style='background-color: #f3f3f3; padding: 40px 20px 60px 20px;'>" +
            "<h1>#{ subject }</h1><br/>" +
            text +
          "</div>" +
        "</html>"

        ::Sanitize.fragment(html, ::Sanitize::Config::RELAXED)
      end
    end

  else
    def send_mail(...); end
    def send_mail_by_template(...); end
    def self.send_mail(...); end
    def self.send_mail_async(...); end
    def self.send_mail_bulk(...); end
    def self.send_bulk_by_template(...); end
  end
end

# ВОТ ТАК ПОТЕСТИТЬ:
#
# sudo gem install concurrent-ruby
# sudo gem install concurrent-ruby-edge
#
# require 'concurrent'
# require 'concurrent-edge'
#
# $a = 0
# def test n
#   $a = $a + 1
#   puts("##{n}: #{$a}")
# end
#
# throttler = ::Concurrent::Throttle.new(3)
# (1..10).map do |n|
#   Thread.new do
#     throttler.acquire { sleep(3); test(n) }
#   end
# end.each(&:join)

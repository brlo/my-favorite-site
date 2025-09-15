# Сервис для уведомления поисковиков об изменениях на странице по протоколу IndexNow
require 'net/http'
require 'uri'

# Yandex doc: https://yandex.ru/support/webmaster/ru/indexnow/reference/get-url
# Common doc: https://www.indexnow.org/index

# IndexNowService.notify("https://bibleox.com/ru/ru/w/древние-иконы")
# IndexNowService.notify_about_page(page)

class IndexNowService
  YANDEX_ENDPOINT = 'https://yandex.com/indexnow'.freeze
  INDEXNOW_KEY = ::SETTINGS.dig('index_now', 'key')

  # Уведомление Яндекс об изменении URL
  def self.notify(url)
    uri = URI(YANDEX_ENDPOINT)
    params = {
      url: url,
      key: INDEXNOW_KEY,
    }

    uri.query = URI.encode_www_form(params)

    begin
      response = Net::HTTP.get_response(uri)
      parse_response(response)
    rescue => e
      { success: false, error: e.message }
    end
  end

  def self.notify_about_page(page)
    canon_url = "https://bibleox.com/#{page.lang}/#{page.lang}/w/#{page.path}"
    notify(canon_url)
  end

  private

  def self.parse_response(response)
    case response.code.to_i
    when 200
      { success: true, message: 'URL успешно отправлен в Яндекс', code: 200 }
    when 202
      { success: true, message: 'Ключ проходит проверку', code: 202 }
    when 403
      { success: false, error: 'Неверный ключ', code: 403 }
    when 422
      { success: false, error: response.body, code: 422 }
    when 429
      { success: false, error: 'Слишком много запросов', code: 429 }
    when 500..599
      { success: false, error: "Ошибка сервера: #{response.code}", code: response.code.to_i }
    else
      { success: false, error: "Неожиданный ответ: #{response.code}", code: response.code.to_i }
    end
  end
end

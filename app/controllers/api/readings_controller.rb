# Heartbeat «читает сейчас» из мобильного приложения: пока статья или глава
# Библии открыта, приложение раз в 45 секунд подтверждает, что её читают.
module Api
  class ReadingsController < ActionController::API
    def create
      book = params[:book].to_s
      return create_bible_reading(book) if book.present?

      page_id = params[:page_id].to_i
      return head :unprocessable_entity unless page_id.positive? && ::PageVisits.valid_visit_token?(page_id, params[:t])

      if params[:leave].present?
        ::PageVisits.clear_reading(page_id, ip: request.ip)
      elsif !::BotDetector.bot?(Browser.new(request.user_agent))
        ::PageVisits.touch_reading(page_id, ip: request.ip)
      end
      head :ok
    end

    private

    # Глава Библии из оффлайн-приложения: книга без главы
    def create_bible_reading(book)
      return head :unprocessable_entity unless ::PageVisits.valid_bible_visit_token?(book, params[:t])

      if params[:leave].present?
        ::PageVisits.clear_bible_reading(book, ip: request.ip, content_lang: params[:lang])
      elsif !::BotDetector.bot?(Browser.new(request.user_agent))
        ::PageVisits.touch_bible_reading(book, ip: request.ip, content_lang: params[:lang])
      end
      head :ok
    end
  end
end

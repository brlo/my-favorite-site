# Маячок посещаемости из мобильного приложения. Токен приходит вместе
# с текстом страницы (или отдельным запросом для уже скачанных страниц)
# и подтверждает, что клиент действительно открывал материалы.
module Api
  class VisitsController < ActionController::API
    def create
      page_id = params[:page_id].to_i
      return head :unprocessable_entity unless ::PageVisits.valid_visit_token?(page_id, params[:t])

      ::PageVisits.beacon_visit(
        page_id: page_id,
        browser: Browser.new(request.user_agent),
        ip: request.ip,
        lang: params[:lang],
      )
      head :ok
    end
  end
end

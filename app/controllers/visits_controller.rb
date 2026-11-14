# Приёмник JS-маячка посещаемости: срабатывает только у клиентов,
# исполнивших JS на странице, чем отсекает скрейперы голого HTML.
class VisitsController < ApplicationController
  skip_before_action :require_login_and_activation
  skip_forgery_protection

  def create
    page_id = params[:page_id].to_i
    return head :unprocessable_entity unless ::PageVisits.valid_visit_token?(page_id, params[:t])

    ::PageVisits.beacon_visit(page_id: page_id, browser: browser, ip: request.ip, lang: params[:lang])
    head :ok
  end
end

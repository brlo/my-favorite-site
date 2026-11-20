# Приёмник heartbeat «читает сейчас». Браузер шлёт его, пока вкладка открыта,
# чтобы блок «Читают сейчас» показывал живых читателей, а не только заходы.
class ReadingsController < ApplicationController
  skip_before_action :require_login_and_activation
  skip_forgery_protection

  def create
    page_id = params[:page_id].to_i
    return head :unprocessable_entity unless page_id.positive? && ::PageVisits.valid_visit_token?(page_id, params[:t])

    if params[:leave].present?
      ::PageVisits.clear_reading(page_id, ip: request.ip)
    elsif !::BotDetector.bot?(browser)
      ::PageVisits.touch_reading(page_id, ip: request.ip)
    end
    head :ok
  end
end

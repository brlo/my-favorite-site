# Приёмник heartbeat «читает сейчас». Браузер шлёт его, пока вкладка открыта,
# чтобы блок «Читают сейчас» показывал живых читателей, а не только заходы.
class ReadingsController < ApplicationController
  skip_before_action :require_login_and_activation
  skip_forgery_protection

  def create
    book = params[:book].to_s
    return create_bible_reading(book) if book.present?

    page_id = params[:page_id].to_i
    return head :unprocessable_entity unless page_id.positive? && ::PageVisits.valid_visit_token?(page_id, params[:t])

    if params[:leave].present?
      ::PageVisits.clear_reading(page_id, ip: request.ip)
    elsif !::BotDetector.bot?(browser)
      ::PageVisits.touch_reading(page_id, ip: request.ip)
    end
    head :ok
  end

  private

  # Глава Библии: книга подписана отдельным токеном, глава не передаётся
  def create_bible_reading(book)
    return head :unprocessable_entity unless ::PageVisits.valid_bible_visit_token?(book, params[:t])

    if params[:leave].present?
      ::PageVisits.clear_bible_reading(book, ip: request.ip)
    elsif !::BotDetector.bot?(browser)
      ::PageVisits.touch_bible_reading(book, ip: request.ip)
    end
    head :ok
  end
end

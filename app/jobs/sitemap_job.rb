# Ежедневная пересборка карты сайта (расписание — config/recurring.yml)
class SitemapJob < ApplicationJob
  queue_as :default

  def perform
    count = ::SitemapBuilder.call
    Rails.logger.info("[sitemap] built: #{count} urls")
  end
end

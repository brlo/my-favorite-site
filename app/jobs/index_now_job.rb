# Сообщает поисковикам (IndexNow) об изменённых адресах; в фоне, чтобы не тормозить сохранение статьи
class IndexNowJob < ApplicationJob
  queue_as :default

  def perform(urls)
    ::IndexNowService.notify_batch(urls).each do |result|
      Rails.logger.info("[index_now] #{urls.size} url(s): #{result}")
    end
  end
end

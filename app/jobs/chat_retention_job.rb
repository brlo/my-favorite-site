# Сообщения чата хранятся Chat::RETENTION (год), затем удаляются.
# Реакции удаляются каскадом, у ответов на удалённые сообщения reply_to_id обнуляется (FK).
class ChatRetentionJob < ApplicationJob
  queue_as :default

  BATCH = 1000

  def perform
    deleted = 0
    loop do
      ids = Chat::Message.expired.limit(BATCH).pluck(:id)
      break if ids.empty?

      deleted += Chat::Message.where(id: ids).delete_all
    end

    # Гости без сообщений, не заходившие дольше срока хранения
    stale_guests = Chat::Member.guests
                               .where('COALESCE(last_seen_at, created_at) < ?', Chat::RETENTION.ago)
                               .where.not(id: Chat::Message.select(:member_id))
    guests = 0
    stale_guests.in_batches(of: BATCH) { |batch| guests += batch.delete_all }

    Rails.logger.info("[chat] retention: messages=#{deleted} guests=#{guests}")
  end
end

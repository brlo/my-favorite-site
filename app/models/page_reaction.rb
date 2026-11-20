require 'openssl'

# Положительная реакция читателя на статью. Авторизация не нужна: одна реакция
# на IP (для защиты от накрутки), поэтому в базе лежит только HMAC-дайджест адреса.
# Пользователь выбирает вид лайка; смена вида заменяет прежний, а не добавляет второй.
class PageReaction < ApplicationRecord
  # kind => emoji. Порядок задаёт порядок кнопок в интерфейсе.
  KINDS = {
    'like' => '❤️',
    'useful' => '👍',
    'thanks' => '🙏',
    'interesting' => '⚡️',
    'hundred' => '💯',
  }.freeze

  belongs_to :page

  validates :kind, inclusion: {in: KINDS.keys}
  validates :ip_digest, presence: true
  validates :page_id, uniqueness: {scope: :ip_digest}

  class << self
    # Дайджест IP, чтобы не хранить адрес читателя в открытом виде.
    # Соль — секрет приложения, поэтому по таблице нельзя восстановить IP перебором.
    def digest_ip(ip)
      OpenSSL::HMAC.hexdigest('SHA256', Rails.application.secret_key_base, "page-reaction:#{ip}")
    end

    # {kind => количество} для одной статьи; все виды присутствуют, даже с нулём
    def counts_by_kind(page_id)
      counts = where(page_id: page_id).group(:kind).count
      KINDS.keys.index_with { |kind| counts[kind].to_i }
    end

    # {page_id => {kind => количество}} для карточек ленты
    def counts_for(page_ids)
      ids = Array(page_ids).compact
      return {} if ids.empty?

      raw = where(page_id: ids).group(:page_id, :kind).count
      ids.index_with do |page_id|
        KINDS.keys.index_with { |kind| raw[[page_id, kind]].to_i }
      end
    end

    # {page_id => kind} — какой вид реакции выбрал этот IP на каждой статье
    def kinds_for(ip, page_ids)
      ids = Array(page_ids).compact
      return {} if ids.empty?

      where(page_id: ids, ip_digest: digest_ip(ip)).pluck(:page_id, :kind).to_h
    end

    # Вид реакции этого IP на статью или nil
    def kind_for(page_id, ip)
      where(page_id: page_id, ip_digest: digest_ip(ip)).pick(:kind)
    end
  end
end

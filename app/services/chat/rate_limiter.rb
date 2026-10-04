module Chat
  # Ограничение частоты сообщений: 1 сообщение в Chat::POST_INTERVAL (burst 1).
  # Для неподтверждённых участников дополнительно ограничиваем по IP,
  # иначе гость обходит лимит, просто очистив cookie.
  module RateLimiter
    module_function

    # Занять слот. nil — можно писать, иначе — сколько секунд ждать.
    def acquire(member)
      return nil unless member.rate_limited?

      interval = Chat::POST_INTERVAL.to_i
      member_key = "chat:rl:m:#{member.id}"
      unless redis.set(member_key, 1, nx: true, ex: interval)
        return [redis.ttl(member_key), 1].max
      end

      if !member.verified? && member.ip_hash.present?
        ip_key = "chat:rl:ip:#{member.ip_hash}"
        unless redis.set(ip_key, 1, nx: true, ex: interval)
          redis.del(member_key)
          return [redis.ttl(ip_key), 1].max
        end
      end

      nil
    end

    # Вернуть слот, если сообщение так и не сохранилось
    def release(member)
      redis.del("chat:rl:m:#{member.id}")
      redis.del("chat:rl:ip:#{member.ip_hash}") if member.ip_hash.present?
    end

    # Сколько секунд осталось до следующего сообщения (для отображения в редакторе)
    def wait_seconds(member)
      return 0 if member.nil? || !member.rate_limited?

      [redis.ttl("chat:rl:m:#{member.id}"), 0].max
    end

    # Простой счётчик в окне: не больше limit действий за period
    def allow?(key, limit:, period:)
      count = redis.incr(key)
      redis.expire(key, period.to_i) if count == 1
      count <= limit
    end

    def redis
      ::RedisConnectionPool
    end
  end
end

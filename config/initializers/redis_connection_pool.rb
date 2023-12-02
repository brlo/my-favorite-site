require 'connection_pool'
require 'forwardable'

module RedisConnectionPool
  class << self
    extend Forwardable

    # для короткой памяти (около 30 сек)
    @@cache = {}

    # перенаправляем только используемые методы (при необходимости добавить)
    def_delegators :connection_pool, # <- сюда делегируются все следующие методы (get, set, ...)
                   :get,
                   :mget,
                   :set,
                   :exists,
                   :exists?,
                   :setex,
                   :del,
                   :incr,
                   :incrby,
                   :decr,
                   :decrby,
                   :flushall,
                   :ttl, # узнать оставшееся время жизни https://redis.io/commands/TTL
                   :expire # задать TTL (время до удаления) https://redis.io/commands/expire

    # создать пул соединений
    def create_pool!
      size = 5

      @@pool = ConnectionPool.new(size: size, timeout: 2) { create_connection! }
    end

    def pool
      @@pool
    end

    # обычный get с небольшой памятью
    def fetch key, expires_in_sec = 30
      if @@cache.key?(key) && (@@cache[key][:expiration_time] > Time.now.to_i)
        # puts "#{key} -> Считали из кэша. Он проживёт ещё #{@@cache[key][:expiration_time] - Time.now.to_i} сек"
        @@cache[key][:value]
      else
        # puts "#{key} -> Делаем запрос, так как в кэше пусто или он устарел..."
        @@cache[key] = {value: get(key), expiration_time: Time.now.to_i + expires_in_sec}
        @@cache[key][:value]
      end
    rescue Redis::BaseConnectionError => error
      puts " ❌ Ошибка подключения: невозможно запросить значение из Redis"
      # если пропала связь с редисом, продолжаем отдавать из кэша, если там что-то есть
      @@cache[key][:value] if @@cache.key?(key)
    end

    private

    def create_connection!
      Redis.new(
        url: SETTINGS['redis']['url'],
        connect_timeout: 2.0,
        read_timeout: 2.0,
        write_timeout: 2.0
      )
    end

    def connection_pool
      @@pool.with { |connection| connection }
    end
  end
end

# сразу создаем пул соединений
RedisConnectionPool.create_pool!

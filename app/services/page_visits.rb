class PageVisits
  class << self
    def day_visit browser: nil
      bot_marker = browser&.bot? ? 'b-' : ''
      redis_key = "#{bot_marker}vis#{Date.today}"
      count = ::RedisConnectionPool.incr(redis_key)
      if count == 1
        # метка хранится неделю, чтобы смотреть статистику за неделю
        ::RedisConnectionPool.expire(redis_key, 60*60*24*7)
      end
      int_to_human_s(count)
    end

    def week_visits
      hash = {}
      {
        'Пользователи': '',
        'Поисковые боты': 'b-'
      }.each do |name,prefix|
        days = (6.days.ago.to_date..Date.today).to_a.map(&:to_s)
        redis_keys = days.map{ |d| "#{prefix}vis#{d}" }
        vals = ::RedisConnectionPool.mget(redis_keys)
        vals = vals.map{|v| int_to_human_s(v) }
        hash[name] = days.zip(vals).to_h
      end

      hash
    end

    def visit(page, browser: nil)
      redis_key = "vis:#{page.id}"
      count = ::RedisConnectionPool.incr(redis_key)
      int_to_human_s(count)
    end

    # Добывает просмотры всех страниц, отдаёт хэш:
    # {p_id => 142, ...}
    def visits(p_ids)
      redis_keys = p_ids.map{|id| "vis:#{id}" }
      vals = ::RedisConnectionPool.mget(redis_keys)
      vals = vals.map{|v| int_to_human_s(v) }
      p_ids.zip(vals).to_h
    end

    def int_to_human_s(numb)
      numb = numb.to_f
      if numb >= 1_000_000
        i = (numb / 1_000_000.0).floor(1)
        i = i.to_i if (i >= 10) || (i - i.to_i) == 0 # выкидываем .0 для больших или круглых чисел
        "#{i}M"
      elsif numb >= 1_000
        i = (numb / 1_000.0).floor(1)
        i = i.to_i if (i >= 10) || (i - i.to_i) == 0 # выкидываем .0 для больших или круглых чисел
        "#{i}K"
      else
        numb.to_i.to_s
      end
    end
  end
end

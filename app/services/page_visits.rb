class PageVisits
  def self.day_visit
    redis_key = "vis#{Date.today}"
    count = ::RedisConnectionPool.incr(redis_key)
    if count == 1
      ::RedisConnectionPool.expire(redis_key, 60*60*24)
    end
    int_to_human_s(count)
  end

  def self.day_visits
    redis_key = "vis#{Date.today}"
    count = ::RedisConnectionPool.fetch(redis_key).to_i
    int_to_human_s(count)
  end

  def self.visit(page)
    redis_key = "vis:#{page.lang}-#{page.id}"
    count = ::RedisConnectionPool.incr(redis_key)
    int_to_human_s(count)
  end

  # Добывает просмотры всех страниц, отдаёт хэш:
  # {p_id => 142, ...}
  def self.visits(p_ids, lang: ::I18n.locale)
    redis_keys = p_ids.map{|id| "vis:#{lang}-#{id}" }
    vals = ::RedisConnectionPool.mget(redis_keys)
    vals = vals.map{|v| int_to_human_s(v) }
    p_ids.zip(vals).to_h
  end

  def self.int_to_human_s(numb)
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

class PageVisits
  # Ключи дневной статистики живут неделю: столько же показывает сводка админки
  TTL = 60 * 60 * 24 * 7

  # После стольких HTML-просмотров с одного IP за день запросы этого IP
  # учитываются отдельно, как «подозрительные»: живой читатель за день делает
  # заметно меньше, а скрейперы с браузерными User-Agent ловятся только так.
  SUSPICIOUS_DAY_LIMIT = 150

  class << self
    # увеличить счётчики дневной посещаемости (вызывается из макета на каждый HTML-запрос)
    # browser — объект Browser (гем browser), ip — адрес клиента, lang — локаль интерфейса
    def day_visit browser: nil, ip: nil, lang: nil
      day = Date.today.to_s
      ip_count = incr_ip(day, ip)

      if BotDetector.bot?(browser)
        prefix = 'b-'
        hincr("bots#{day}", BotDetector.bot_name(browser) || 'другие')
      else
        # все не-боты попадают в топ IP (в том числе подозрительные)
        ::RedisConnectionPool.zincrby("zips#{day}", 1, ip.to_s) if ip.present?
        if ip_count > SUSPICIOUS_DAY_LIMIT
          prefix = 's-'
        else
          prefix = ''
          ::RedisConnectionPool.pfadd("uip#{day}", ip.to_s) if ip.present?
          hincr("langs#{day}", lang.to_s.presence || '?') if lang.present?
        end
      end

      redis_key = "#{prefix}vis#{day}"
      count = ::RedisConnectionPool.incr(redis_key)
      ::RedisConnectionPool.expire(redis_key, TTL) if count == 1
      int_to_human_s(count)
    end

    # счётчики общих посещений за последнюю неделю
    def week_visits
      days = (6.days.ago.to_date..Date.today).to_a.map(&:to_s)
      hash = {}
      {
        'Люди': '',
        'Уникальные IP': nil,
        'Подозрительные': 's-',
        'Поисковые боты': 'b-'
      }.each do |name, prefix|
        if prefix.nil?
          vals = days.map { |d| ::RedisConnectionPool.pfcount("uip#{d}") }
        else
          redis_keys = days.map { |d| "#{prefix}vis#{d}" }
          vals = ::RedisConnectionPool.mget(redis_keys)
        end
        vals = vals.map { |v| int_to_human_s(v) }
        hash[name] = days.zip(vals).to_h
      end

      hash
    end

    # Увеличивает счётчик посещения страницы,
    # если пользователь сегодня ещё не посещал эту страницу.
    # Отдаёт итоговый счётчик просмотров страницы
    def visit(page, user_ip:, browser: nil)
      # метка для защиты от накрутов: пока она существует, следующий просмотр не защитается
      redis_user_key = "vis:#{page.id}=#{user_ip}"
      # счётчик просмотров страницы
      redis_page_key = "vis:#{page.id}"

      # Метка для защиты от накруток ещё существует?
      if ::RedisConnectionPool.exists?(redis_user_key)
        # если уже посещал, просто вернуть текущий счётчик просмотров страницы
        count = ::RedisConnectionPool.get(redis_page_key)
      else
        # Создать метку для защиты от накруток на 12 часов
        ::RedisConnectionPool.setex(redis_user_key, 12 * 60 * 60, nil)
        # увеличить счётчик посещений страницы
        count = ::RedisConnectionPool.incr(redis_page_key)
        # и ежедневный топ статей (без ботов)
        hincr("top#{Date.today}", page.id) unless BotDetector.bot?(browser)
      end

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

    # имя бота => запросы за дату
    def day_bots(date)
      stat_hash("bots#{date}")
    end

    # локаль интерфейса => запросы людей за дату
    def day_langs(date)
      stat_hash("langs#{date}")
    end

    # id страницы => просмотры не-ботами за дату
    def day_top_pages(date)
      stat_hash("top#{date}")
    end

    # топ IP не-ботов за дату: [[ip, запросы], ...]
    def day_top_ips(date, limit = 10)
      ::RedisConnectionPool.zrevrange("zips#{date}", 0, limit - 1, withscores: true)
        .map { |ip, count| [ip, count.to_i] }
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

    private

    # суточный счётчик запросов с IP
    def incr_ip(day, ip)
      return 0 if ip.blank?

      redis_key = "ipvis#{day}:#{ip}"
      count = ::RedisConnectionPool.incr(redis_key)
      ::RedisConnectionPool.expire(redis_key, TTL) if count == 1
      count
    end

    # прибавить единицу к полю хэша и освежить время жизни
    def hincr(key, field)
      ::RedisConnectionPool.hincrby(key, field, 1)
      ::RedisConnectionPool.expire(key, TTL)
    end

    # прочитать хэш статистики, отсортировать по убыванию; счётчики -> числа
    def stat_hash(key)
      ::RedisConnectionPool.hgetall(key)
        .sort_by { |_field, count| -count.to_i }
        .to_h { |field, count| [field, count.to_i] }
    end
  end
end

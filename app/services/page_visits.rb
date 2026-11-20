require 'openssl'

class PageVisits
  # Ключи дневной статистики живут неделю: столько же показывает сводка админки
  TTL = 60 * 60 * 24 * 7

  # После стольких HTML-просмотров с одного IP за день запросы этого IP
  # учитываются отдельно, как «подозрительные»: живой читатель за день делает
  # заметно меньше, а скрейперы с браузерными User-Agent ловятся только так.
  SUSPICIOUS_DAY_LIMIT = 150

  # «Читают сейчас»: отметка живёт READING_WINDOW секунд после последнего heartbeat.
  # 15 минут — чтобы статья не пропадала сразу, если вкладка ушла в фон или
  # heartbeat задержался; один читатель (IP) на странице считается один раз.
  READING_KEY = 'reading'.freeze
  READING_WINDOW = 15 * 60
  READING_TTL = 60 * 60

  # Член zset для главы Библии: 'b:<код перевода>:<код книги>:<хэш читателя>'.
  # Глава не хранится — в блоке показываем только книгу, но язык перевода нужен
  # для пометки языка и ссылки на главу.
  BIBLE_MEMBER_PREFIX = 'b:'.freeze

  # total_readers — сколько разных читателей сейчас на сайте,
  # pages — [[page_id, читателей], ...] по убыванию,
  # bibles — [[код перевода, код книги, читателей], ...] по убыванию
  ReadingNow = Struct.new(:total_readers, :pages, :bibles, keyword_init: true)

  class << self
    # Точка входа для JS-маячка (VisitsController): дневная статистика
    # и счётчик просмотров статьи. Сюда попадают только запросы от браузеров,
    # исполнивших JS, — скрейперы, тянущие голый HTML, статистику не двигают.
    def beacon_visit(page_id:, browser:, ip:, lang:)
      day_visit(browser: browser, ip: ip, lang: lang)
      return if page_id.to_i <= 0 || BotDetector.bot?(browser)

      register_visit(page_id, user_ip: ip)
      touch_reading(page_id, ip: ip)
    end

    # увеличить счётчики дневной посещаемости (вызывается из JS-маячка)
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

    # просмотры людей за сегодня (для подсказки в футере, без увеличения счётчиков)
    def day_count
      int_to_human_s(::RedisConnectionPool.get("vis#{Date.today}"))
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
    # Вызывается только из JS-маячка (beacon_visit) и только для не-ботов.
    def register_visit(page_id, user_ip:)
      # метка для защиты от накруток: пока она существует, следующий просмотр не защитается
      redis_user_key = "vis:#{page_id}=#{user_ip}"
      # счётчик просмотров страницы
      redis_page_key = "vis:#{page_id}"

      # Метка для защиты от накруток ещё существует?
      return if ::RedisConnectionPool.exists?(redis_user_key)

      # Создать метку для защиты от накруток на 12 часов
      ::RedisConnectionPool.setex(redis_user_key, 12 * 60 * 60, nil)
      # увеличить счётчик посещений страницы
      ::RedisConnectionPool.incr(redis_page_key)
      # и ежедневный топ статей
      hincr("top#{Date.today}", page_id)
    end

    # счётчик просмотров страницы без увеличения (для вывода на странице)
    def page_count(page_id)
      int_to_human_s(::RedisConnectionPool.get("vis:#{page_id}"))
    end

    # Отметка «читает прямо сейчас»: heartbeat со страницы статьи.
    # score — время последнего сигнала; старые отметки вычищаем при каждом визите.
    def touch_reading(page_id, ip:)
      id = page_id.to_i
      return if id <= 0

      now = Time.now.to_f
      ::RedisConnectionPool.zremrangebyscore(READING_KEY, 0, now - READING_WINDOW)
      ::RedisConnectionPool.zadd(READING_KEY, now, "#{id}:#{reader_digest(ip)}")
      ::RedisConnectionPool.expire(READING_KEY, READING_TTL)
    end

    # Читатель ушёл со страницы (переход или закрытие вкладки): убираем отметку,
    # чтобы он не висел в «Читают сейчас» до истечения окна.
    def clear_reading(page_id, ip:)
      id = page_id.to_i
      return if id <= 0

      ::RedisConnectionPool.zrem(READING_KEY, "#{id}:#{reader_digest(ip)}")
    end

    # Отметка «читает главу Библии»: запоминаем книгу и язык перевода, без главы.
    def touch_bible_reading(book_code, ip:, content_lang: nil)
      book = book_code.to_s
      return unless ::BOOKS.key?(book)

      lang = bible_content_lang(content_lang)
      now = Time.now.to_f
      ::RedisConnectionPool.zremrangebyscore(READING_KEY, 0, now - READING_WINDOW)
      ::RedisConnectionPool.zadd(READING_KEY, now, "#{BIBLE_MEMBER_PREFIX}#{lang}:#{book}:#{reader_digest(ip)}")
      ::RedisConnectionPool.expire(READING_KEY, READING_TTL)
    end

    # Читатель ушёл с главы Библии
    def clear_bible_reading(book_code, ip:, content_lang: nil)
      book = book_code.to_s
      return unless ::BOOKS.key?(book)

      lang = bible_content_lang(content_lang)
      ::RedisConnectionPool.zrem(READING_KEY, "#{BIBLE_MEMBER_PREFIX}#{lang}:#{book}:#{reader_digest(ip)}")
    end

    # Код перевода для отметки чтения Библии. Неизвестный код (старая вкладка,
    # запрос без языка) заменяем основным переводом текущего интерфейса.
    def bible_content_lang(content_lang)
      lang = content_lang.to_s
      return lang if ::BIB_LANG_TO_LOCALE.key?(lang)

      ::LOCALE_TO_BIB_LANG[::I18n.locale.to_s] || 'ru'
    end

    # Кто читает сейчас: общее число читателей, топ страниц и книг Библии
    def reading_now(limit: 5)
      now = Time.now.to_f
      from = now - READING_WINDOW
      ::RedisConnectionPool.zremrangebyscore(READING_KEY, 0, from)

      readers = {}
      counts = Hash.new(0)
      bible_counts = Hash.new(0)
      ::RedisConnectionPool.zrangebyscore(READING_KEY, from, '+inf').each do |member|
        if member.start_with?(BIBLE_MEMBER_PREFIX)
          content_lang, book_code, digest = member.delete_prefix(BIBLE_MEMBER_PREFIX).split(':', 3)
          next if content_lang.blank? || book_code.blank? || digest.blank? ||
                  !::BIB_LANG_TO_LOCALE.key?(content_lang) || !::BOOKS.key?(book_code)

          readers[digest] = true
          bible_counts[[content_lang, book_code]] += 1
        else
          page_id, digest = member.split(':', 2)
          next if page_id.blank? || digest.blank?

          readers[digest] = true
          counts[page_id.to_i] += 1
        end
      end

      pages = counts.sort_by { |id, count| [-count, id] }.first(limit)
      bibles = bible_counts
        .sort_by { |(content_lang, book_code), count| [-count, book_code, content_lang] }
        .first(limit)
        .map { |(content_lang, book_code), count| [content_lang, book_code, count] }
      ReadingNow.new(total_readers: readers.size, pages: pages, bibles: bibles)
    end

    # Сколько человек читают конкретную статью прямо сейчас
    def readers_count(page_id)
      id = page_id.to_i
      return 0 if id <= 0

      now = Time.now.to_f
      prefix = "#{id}:"
      ::RedisConnectionPool.zrangebyscore(READING_KEY, now - READING_WINDOW, '+inf')
        .count { |member| member.start_with?(prefix) }
    end

    # Токен для JS-маячка: подтверждает, что отправитель получил страницу сайта.
    # Привязан к id статьи (0 — для нестатейных страниц), но не к дате и IP,
    # чтобы не ломаться о страничный кеш и смену адреса.
    def visit_token(page_id)
      OpenSSL::HMAC.hexdigest('SHA256', Rails.application.secret_key_base, "visit:#{page_id}")[0, 32]
    end

    def valid_visit_token?(page_id, token)
      visit_token(page_id) == token.to_s
    end

    # Токен heartbeat'а главы Библии: у главы нет page_id, поэтому подписываем книгу.
    def bible_visit_token(book_code)
      OpenSSL::HMAC.hexdigest('SHA256', Rails.application.secret_key_base, "visit:bible:#{book_code}")[0, 32]
    end

    def valid_bible_visit_token?(book_code, token)
      book = book_code.to_s
      ::BOOKS.key?(book) && bible_visit_token(book) == token.to_s
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

    # Читатель для «Читают сейчас»: хэш IP, чтобы не хранить адрес в Redis.
    def reader_digest(ip)
      OpenSSL::HMAC.hexdigest('SHA256', Rails.application.secret_key_base, "reading:#{ip}")[0, 32]
    end

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

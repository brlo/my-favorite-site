require 'test_helper'

class PageVisitsTest < ActiveSupport::TestCase
  CHROME = Browser.new('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36')
  GPTBOT = Browser.new('Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; GPTBot/1.4; +https://openai.com/gptbot)')

  setup do
    @day = Date.today.to_s
    clean_stats
  end

  teardown { clean_stats }

  test 'запрос человека попадает в строку «Люди», пишется язык и IP' do
    PageVisits.day_visit(browser: CHROME, ip: '10.0.0.1', lang: :ru)

    assert_equal '1', week_visits['Люди']
    assert_equal '0', week_visits['Подозрительные']
    assert_equal '0', week_visits['Поисковые боты']
    assert_equal '1', week_visits['Уникальные IP']
    assert_equal({ 'ru' => 1 }, PageVisits.day_langs(@day))
    assert_equal [['10.0.0.1', 1]], PageVisits.day_top_ips(@day)
  end

  test 'day_count возвращает просмотры людей за сегодня, ничего не увеличивая' do
    assert_equal '0', PageVisits.day_count

    PageVisits.day_visit(browser: CHROME, ip: '10.0.0.1', lang: :ru)
    assert_equal '1', PageVisits.day_count

    # повторное чтение не двигает счётчики
    PageVisits.day_count
    assert_equal '1', week_visits['Люди']
  end

  test 'запрос бота попадает в строку ботов и в топ ботов с именем' do
    PageVisits.day_visit(browser: GPTBOT, ip: '10.0.0.9', lang: :ru)

    assert_equal '0', week_visits['Люди']
    assert_equal '1', week_visits['Поисковые боты']
    assert_equal({ 'ChatGPT' => 1 }, PageVisits.day_bots(@day))
    # боты не попадают ни в уникальные IP, ни в топ IP
    assert_equal '0', week_visits['Уникальные IP']
    assert_empty PageVisits.day_top_ips(@day)
  end

  test 'IP, превысивший дневной порог, уходит в «Подозрительные»' do
    limit = PageVisits::SUSPICIOUS_DAY_LIMIT
    (limit + 1).times { PageVisits.day_visit(browser: CHROME, ip: '10.0.0.2', lang: :ru) }

    assert_equal limit.to_s, week_visits['Люди']
    assert_equal '1', week_visits['Подозрительные']
    # уникальных адресов один, как ни крути счётчик запросов
    assert_equal '1', week_visits['Уникальные IP']
    # все не-боты видны в топ IP, включая подозрительных
    assert_equal [['10.0.0.2', limit + 1]], PageVisits.day_top_ips(@day)
  end

  test 'уникальные IP считаются по людям' do
    3.times { |i| PageVisits.day_visit(browser: CHROME, ip: "10.0.1.#{i}", lang: :en) }

    assert_equal '3', week_visits['Люди']
    assert_equal '3', week_visits['Уникальные IP']
    assert_equal({ 'en' => 3 }, PageVisits.day_langs(@day))
  end

  test 'маячок со статьёй двигает счётчик статьи и дневную статистику, бот — только ботов' do
    PageVisits.beacon_visit(page_id: 42, browser: CHROME, ip: '10.0.2.1', lang: :ru)
    PageVisits.beacon_visit(page_id: 42, browser: CHROME, ip: '10.0.2.2', lang: :ru)
    # повтор с того же IP в течение 12 часов не защитается
    PageVisits.beacon_visit(page_id: 42, browser: CHROME, ip: '10.0.2.1', lang: :ru)
    # бот счётчик статьи не двигает, в дневной статистике помечается ботом
    PageVisits.beacon_visit(page_id: 42, browser: GPTBOT, ip: '10.0.2.3', lang: :ru)

    assert_equal '2', PageVisits.page_count(42)
    assert_equal({ '42' => 2 }, PageVisits.day_top_pages(@day))
    assert_equal '3', week_visits['Люди']
    assert_equal '1', week_visits['Поисковые боты']
  end

  test 'маячок без статьи (page_id = 0) трогает только дневную статистику' do
    PageVisits.beacon_visit(page_id: 0, browser: CHROME, ip: '10.0.2.1', lang: :ru)

    assert_equal '1', week_visits['Люди']
    assert_empty PageVisits.day_top_pages(@day)
  end

  test 'токен маячка привязан к id страницы' do
    token = PageVisits.visit_token(42)

    assert PageVisits.valid_visit_token?(42, token)
    assert_not PageVisits.valid_visit_token?(43, token)
    assert_not PageVisits.valid_visit_token?(42, 'forged')
    assert_not PageVisits.valid_visit_token?(42, nil)
  end

  test 'отметка чтения считает уникальных читателей по IP и страницам' do
    PageVisits.touch_reading(42, ip: '10.0.3.1')
    PageVisits.touch_reading(42, ip: '10.0.3.1') # тот же читатель — не второй
    PageVisits.touch_reading(42, ip: '10.0.3.2')
    PageVisits.touch_reading(43, ip: '10.0.3.1')

    reading = PageVisits.reading_now

    assert_equal 2, reading.total_readers
    assert_equal [[42, 2], [43, 1]], reading.pages
    assert_equal 2, PageVisits.readers_count(42)
    assert_equal 1, PageVisits.readers_count(43)
  end

  test 'старые отметки чтения не попадают в «Читают сейчас»' do
    old = Time.now.to_f - PageVisits::READING_WINDOW - 5
    ::RedisConnectionPool.zadd(PageVisits::READING_KEY, old, '42:old')

    assert_empty PageVisits.reading_now.pages
  end

  test 'маячок статьи отмечает чтение, а бот — нет' do
    PageVisits.beacon_visit(page_id: 42, browser: CHROME, ip: '10.0.3.3', lang: :ru)
    assert_equal [[42, 1]], PageVisits.reading_now.pages

    PageVisits.beacon_visit(page_id: 43, browser: GPTBOT, ip: '10.0.3.4', lang: :ru)
    assert_equal 1, PageVisits.reading_now.total_readers
  end

  test 'чтение книг Библии считается без главы' do
    PageVisits.touch_bible_reading('gen', ip: '10.0.4.1')
    PageVisits.touch_bible_reading('gen', ip: '10.0.4.2')
    PageVisits.touch_bible_reading('in', ip: '10.0.4.1')

    reading = PageVisits.reading_now

    assert_equal 2, reading.total_readers
    assert_equal [['gen', 2], ['in', 1]], reading.bibles
    assert_empty reading.pages
  end

  test 'один читатель статьи и Библии считается в общем счётчике один раз' do
    PageVisits.touch_reading(42, ip: '10.0.4.3')
    PageVisits.touch_bible_reading('gen', ip: '10.0.4.3')

    reading = PageVisits.reading_now

    assert_equal 1, reading.total_readers
    assert_equal [[42, 1]], reading.pages
    assert_equal [['gen', 1]], reading.bibles
  end

  test 'несуществующая книга Библии не попадает в «Читают сейчас»' do
    PageVisits.touch_bible_reading('nope', ip: '10.0.4.4')

    assert_empty PageVisits.reading_now.bibles
    assert_equal 0, PageVisits.reading_now.total_readers
  end

  test 'leave снимает отметку чтения книги' do
    PageVisits.touch_bible_reading('gen', ip: '10.0.4.5')
    assert_equal [['gen', 1]], PageVisits.reading_now.bibles

    PageVisits.clear_bible_reading('gen', ip: '10.0.4.5')
    assert_empty PageVisits.reading_now.bibles
  end

  private

  # значения строк сегодняшнего дня, ключи строками:
  # { 'Люди' => '5', 'Уникальные IP' => '5', ... }
  def week_visits
    PageVisits.week_visits
      .transform_keys(&:to_s)
      .transform_values { |by_day| by_day[@day] }
  end

  # стирает ключи статистики за сегодня, чтобы тесты не влияли друг на друга
  def clean_stats
    keys = %w[vis o-vis s-vis b-vis uip bots zips langs top].map { |name| "#{name}#{@day}" }
    keys << "ipvis#{@day}:10.0.0.1" << "ipvis#{@day}:10.0.0.2" << "ipvis#{@day}:10.0.0.9"
    keys << "vis:42" << "vis:42=10.0.2.1" << "vis:42=10.0.2.2" << "vis:42=10.0.2.3"
    keys << ::PageVisits::READING_KEY
    (0..2).each { |i| keys << "ipvis#{@day}:10.0.1.#{i}" }
    (1..3).each { |i| keys << "ipvis#{@day}:10.0.2.#{i}" }
    ::RedisConnectionPool.del(keys)
  end
end

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

  test 'просмотры статей считаются в ежедневный топ без ботов' do
    page = Struct.new(:id).new(42)
    PageVisits.visit(page, user_ip: '10.0.2.1', browser: CHROME)
    PageVisits.visit(page, user_ip: '10.0.2.2', browser: CHROME)
    # повтор с того же IP в течение 12 часов не защитается
    PageVisits.visit(page, user_ip: '10.0.2.1', browser: CHROME)
    PageVisits.visit(page, user_ip: '10.0.2.3', browser: GPTBOT)

    assert_equal({ '42' => 2 }, PageVisits.day_top_pages(@day))
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
    keys = %w[vis s-vis b-vis uip bots zips langs top].map { |name| "#{name}#{@day}" }
    keys << "ipvis#{@day}:10.0.0.1" << "ipvis#{@day}:10.0.0.2" << "ipvis#{@day}:10.0.0.9"
    keys << "vis:42" << "vis:42=10.0.2.1" << "vis:42=10.0.2.2" << "vis:42=10.0.2.3"
    (0..2).each { |i| keys << "ipvis#{@day}:10.0.1.#{i}" }
    ::RedisConnectionPool.del(keys)
  end
end

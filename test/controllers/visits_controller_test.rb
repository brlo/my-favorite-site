require "test_helper"

class VisitsControllerTest < ActionDispatch::IntegrationTest
  CHROME_UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36'
  GPTBOT_UA = 'Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; GPTBot/1.4; +https://openai.com/gptbot)'
  TEST_IP = '127.0.0.1'

  setup do
    @day = Date.today.to_s
    clean_stats
  end

  teardown { clean_stats }

  test 'маячок с валидным токеном увеличивает дневную статистику и счётчик статьи' do
    post '/visit', params: { page_id: 42, lang: 'ru', t: PageVisits.visit_token(42) },
                   headers: { 'HTTP_USER_AGENT' => CHROME_UA }

    assert_response :ok
    assert_equal '1', PageVisits.day_count
    assert_equal '1', PageVisits.page_count(42)
    assert_equal({ 'ru' => 1 }, PageVisits.day_langs(@day))
  end

  test 'маячок с чужим токеном отклоняется и ничего не считает' do
    post '/visit', params: { page_id: 42, lang: 'ru', t: 'forged' },
                   headers: { 'HTTP_USER_AGENT' => CHROME_UA }

    assert_response :unprocessable_entity
    assert_equal '0', PageVisits.day_count
    assert_equal '0', PageVisits.page_count(42)
  end

  test 'маячок без токена отклоняется' do
    post '/visit', params: { page_id: 42, lang: 'ru' },
                   headers: { 'HTTP_USER_AGENT' => CHROME_UA }

    assert_response :unprocessable_entity
    assert_equal '0', PageVisits.day_count
  end

  test 'бот не двигает счётчик статьи, но попадает в статистику ботов' do
    post '/visit', params: { page_id: 42, lang: 'ru', t: PageVisits.visit_token(42) },
                   headers: { 'HTTP_USER_AGENT' => GPTBOT_UA }

    assert_response :ok
    assert_equal '0', PageVisits.page_count(42)
    assert_equal({ 'ChatGPT' => 1 }, PageVisits.day_bots(@day))
  end

  private

  def clean_stats
    keys = %w[vis o-vis s-vis b-vis uip bots zips langs top].map { |name| "#{name}#{@day}" }
    keys << "vis:42" << "vis:42=#{TEST_IP}" << "ipvis#{@day}:#{TEST_IP}"
    ::RedisConnectionPool.del(keys)
  end
end

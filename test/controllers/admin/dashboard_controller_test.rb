require 'test_helper'

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @editor = create_user(privs: { 'pages_read' => true })
    sign_in(@editor)
    @yday = Date.yesterday.to_s
  end

  teardown { clean_stats }

  test 'сводка рендерится с новыми блоками вчерашней статистики' do
    page = create_page(title: 'Иконы и почитание')
    seed_stats(page.id)

    get '/admin'
    assert_response :success

    # недельная таблица + вчерашние блоки: два блока .stats по четыре столбца
    assert_select 'div.stats > div', count: 8
    assert_match(/Подозрительные/, response.body)
    assert_match(/Уникальные IP/, response.body)

    # вчерашние блоки
    assert_match(%r{Топ ботов}, response.body)
    assert_match(/ChatGPT.*5/m, response.body)
    assert_match(/Языки интерфейса/, response.body)
    assert_match(/Топ IP/, response.body)
    assert_match(/10\.9\.9\.9/, response.body)
    assert_match(/Популярные статьи/, response.body)
    assert_match(/Иконы и почитание/, response.body)
    assert_match(/3<\/td>/, response.body)
  end

  test 'у пользователей без pages_read блоки статей не выводятся' do
    get '/admin'
    assert_response :success
    assert_no_match(/Популярные статьи/, response.body)
  end

  private

  def seed_stats(page_id)
    pool = ::RedisConnectionPool
    pool.hincrby("bots#{@yday}", 'ChatGPT', 5)
    pool.expire("bots#{@yday}", 3600)
    pool.hincrby("langs#{@yday}", 'ru', 7)
    pool.expire("langs#{@yday}", 3600)
    pool.zincrby("zips#{@yday}", 1, '10.9.9.9')
    pool.expire("zips#{@yday}", 3600)
    pool.hincrby("top#{@yday}", page_id, 3)
    pool.expire("top#{@yday}", 3600)
  end

  def clean_stats
    ::RedisConnectionPool.del(["bots#{@yday}", "langs#{@yday}", "zips#{@yday}", "top#{@yday}"])
  end
end

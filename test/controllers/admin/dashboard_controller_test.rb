require 'test_helper'

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    clean_reading
    @editor = create_user(privs: { 'pages_read' => true })
    sign_in(@editor)
    @yday = Date.yesterday.to_s
  end

  teardown do
    clean_stats
    clean_reading
  end

  test 'сводка рендерится с новыми блоками вчерашней статистики' do
    page = create_page(title: 'Иконы и почитание')
    seed_stats(page.id)

    get '/admin'
    assert_response :success

    # пять недельных карточек и три вчерашних
    assert_select 'div.dash-stat', count: 8
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
    assert_select '.dash-stat__value', text: '3'
  end

  test 'у пользователей без pages_read блоки статей не выводятся' do
    get '/admin'
    assert_response :success
    assert_no_match(/Популярные статьи/, response.body)
  end

  test 'сводка показывает последние реакции с видом, статьёй и временем' do
    page = create_page(title: 'Про сборник библейских цитат', is_published: true)
    PageReaction.create!(page: page, kind: 'like', ip_digest: 'digest-1', created_at: 2.hours.ago)
    PageReaction.create!(page: page, kind: 'useful', ip_digest: 'digest-2', created_at: 1.hour.ago)

    get '/admin'
    assert_response :success

    assert_select '#reactions' do
      assert_select '.dash-card__total', text: /Всего: 2.*за 7 дней: 2/m
      assert_select '.dash-list__row', count: 2
      assert_select '.dash-list__main a', text: 'Про сборник библейских цитат'
      # свежая реакция сверху
      assert_select '.dash-list__row:first-child .dash-reaction__label', text: 'Полезно'
      assert_select '.dash-list__row:first-child .dash-list__meta', text: /\d{4}-\d{2}-\d{2} \d{2}:\d{2}/
      assert_select '.dash-reaction-summary', text: /👍 1/
      assert_select '.dash-reaction-summary', text: /❤️ 1/
    end
  end

  test 'без реакций сводка показывает пустое состояние' do
    get '/admin'
    assert_response :success
    assert_select '#reactions .dash-card__empty', text: 'Пока никто не отреагировал.'
    assert_select '#reactions .dash-list', count: 0
  end

  test 'реакция на скрытую статью выводится с бейджем скрытой' do
    page = create_page(title: 'Черновик', is_published: false)
    PageReaction.create!(page: page, kind: 'thanks', ip_digest: 'digest-3')

    get '/admin'
    assert_response :success

    assert_select '#reactions .dash-list__main a', text: 'Черновик'
    assert_select '#reactions .dash-list__row', text: /скрыта/
  end

  test 'сводка показывает читаемые сейчас страницы на всех языках и книги Библии' do
    ru = create_page(title: 'Русская читаемая', lang: 'ru', is_published: true)
    en = create_page(title: 'English read now', lang: 'en', is_published: true)
    draft = create_page(title: 'Скрытая', is_published: false)
    list = create_page(title: 'Список', page_type: 4, is_published: true)

    PageVisits.touch_reading(ru.id, ip: '10.0.8.1')
    PageVisits.touch_reading(en.id, ip: '10.0.8.2')
    PageVisits.touch_reading(en.id, ip: '10.0.8.3')
    PageVisits.touch_reading(draft.id, ip: '10.0.8.4')
    PageVisits.touch_reading(list.id, ip: '10.0.8.5')
    PageVisits.touch_bible_reading('gen', ip: '10.0.8.6')

    get '/admin'
    assert_response :success

    assert_select '#reading-now' do
      assert_select '.dash-list__main a', text: 'Русская читаемая'
      assert_select '.dash-list__main a', text: 'English read now'
      assert_select '.dash-list__main a', text: 'Список'
      assert_select '.dash-count', text: '2'
      assert_select '.dash-list__title', text: 'Библия · Бытие'
      assert_select '.dash-list__row', text: /Скрытая/, count: 0
    end
  end

  test 'без pages_read блока «Читают сейчас» нет' do
    delete logout_path(locale: 'ru')
    other = create_user(privs: { 'dict_read' => true })
    sign_in(other)

    get '/admin'
    assert_response :success
    assert_select '#reading-now', count: 0
    assert_select '#reactions', count: 0
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

  def clean_reading
    ::RedisConnectionPool.del(::PageVisits::READING_KEY)
  end
end

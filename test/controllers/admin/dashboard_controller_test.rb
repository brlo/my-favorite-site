require 'test_helper'

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    clean_reading
    @editor = create_user(privs: { 'pages_read' => true })
    sign_in(@editor)
    @today = Date.today.to_s
    @yday = Date.yesterday.to_s
    clean_stats
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

    # четыре недельных карточки и четыре вчерашних; за сегодня данных нет — заглушка
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

  test 'сегодняшняя статистика выводится рядом с вчерашней' do
    today_page = create_page(title: 'Сегодняшняя статья')
    yday_page = create_page(title: 'Вчерашняя статья')
    seed_stats(today_page.id, day: @today, bot: 'ClaudeBot', bot_hits: 2, lang: 'en',
               lang_hits: 4, ip: '10.7.7.7', top_hits: 1)
    seed_stats(yday_page.id, day: @yday, bot: 'ChatGPT', bot_hits: 5, lang: 'ru',
               lang_hits: 7, ip: '10.9.9.9', top_hits: 3)

    get '/admin'
    assert_response :success

    assert_select "#day-stats-#{@today}" do
      assert_select 'h2', text: "Сегодня, #{Date.today.strftime('%d.%m.%Y')}"
      assert_select '.dash-stat', count: 4
      assert_select '.dash-stat__label', text: 'ClaudeBot'
      assert_select '.dash-stat__label', text: '10.7.7.7'
      assert_select '.dash-stat__label', text: 'Сегодняшняя статья'
      assert_select '.dash-stat__label', text: '10.9.9.9', count: 0
    end

    assert_select "#day-stats-#{@yday}" do
      assert_select 'h2', text: "Вчера, #{Date.yesterday.strftime('%d.%m.%Y')}"
      assert_select '.dash-stat', count: 4
      assert_select '.dash-stat__label', text: 'ChatGPT'
      assert_select '.dash-stat__label', text: '10.9.9.9'
      assert_select '.dash-stat__label', text: 'Вчерашняя статья'
      assert_select '.dash-stat__label', text: '10.7.7.7', count: 0
    end
  end

  test 'за сегодня без визитов показывается заглушка' do
    seed_stats(create_page(title: 'Иконы и почитание').id)

    get '/admin'
    assert_response :success

    assert_select "#day-stats-#{@today} .dash-card__empty", text: 'Данных за эти сутки нет.'
    assert_select "#day-stats-#{@today} .dash-stat", count: 0
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
    assert_select '#bible-visits', count: 0
  end

  test 'сводка показывает читателей переводов Библии' do
    PageVisits.touch_bible_reading('gen', ip: '10.0.8.20', content_lang: 'eng-nkjv')
    PageVisits.touch_bible_reading('in', ip: '10.0.8.21', content_lang: 'eng-nkjv')
    PageVisits.touch_bible_reading('gen', ip: '10.0.8.20', content_lang: 'ru')

    get '/admin'
    assert_response :success

    assert_select '#bible-visits .dash-list__row:first-child' do
      assert_select '.dash-list__title', text: 'Английский'
      assert_select '.dash-badge', text: 'NKJV'
      assert_select '.dash-count', text: '2'
      assert_select '.dash-list__meta', text: /сегодня 2 · вчера 0/
    end
    assert_select '#bible-visits .dash-list__row', count: 2
  end

  private

  def seed_stats(page_id, day: @yday, bot: 'ChatGPT', bot_hits: 5, lang: 'ru',
                 lang_hits: 7, ip: '10.9.9.9', top_hits: 3)
    pool = ::RedisConnectionPool
    pool.hincrby("bots#{day}", bot, bot_hits)
    pool.expire("bots#{day}", 3600)
    pool.hincrby("langs#{day}", lang, lang_hits)
    pool.expire("langs#{day}", 3600)
    pool.zincrby("zips#{day}", 1, ip)
    pool.expire("zips#{day}", 3600)
    pool.hincrby("top#{day}", page_id, top_hits)
    pool.expire("top#{day}", 3600)
  end

  def clean_stats
    keys = %w[bots langs zips top].flat_map { |name| ["#{name}#{@today}", "#{name}#{@yday}"] }
    keys.concat(::RedisConnectionPool.pool.with do |redis|
      redis.keys('vis:b:*') + redis.keys('bvis:*')
    end)
    keys.concat(["#{::PageVisits::BIBLE_VISITS_DAY_PREFIX}#{@today}",
                 "#{::PageVisits::BIBLE_VISITS_DAY_PREFIX}#{@yday}"])
    ::RedisConnectionPool.del(keys)
  end

  def clean_reading
    ::RedisConnectionPool.del(::PageVisits::READING_KEY)
  end
end

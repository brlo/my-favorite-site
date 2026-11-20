require 'test_helper'

class NewsControllerTest < ActionDispatch::IntegrationTest
  LONG_BODY = '<p>' + 'Достаточно длинный текст страницы. ' * 3 + '</p>'
  CUT_BODY = '<p>Анонс новости</p><hr class="article-cut"><p>Продолжение новости</p>' + LONG_BODY

  setup { clean_reading }
  teardown { clean_reading }

  test 'лента показывает только опубликованные статьи с флагом на текущем языке' do
    create_page(is_published: true, is_news: true, title: 'Новость дня', path: 'news_today', body: CUT_BODY)
    create_page(is_published: true, is_news: false, title: 'Обычная статья', path: 'regular_article', body: LONG_BODY)
    create_page(is_published: false, is_news: true, title: 'Черновик', path: 'news_draft', body: LONG_BODY)
    create_page(is_published: true, is_news: true, title: 'Удалённая', path: 'news_deleted', body: LONG_BODY, is_deleted: true)
    create_page(is_published: true, is_news: true, title: 'English news', path: 'news_en', lang: 'en', body: LONG_BODY)
    create_page(is_published: true, is_news: true, title: 'Список в ленте', path: 'news_list', page_type: 4, body: LONG_BODY)
    create_page(is_published: true, is_news: true, title: 'Слишком короткая', path: 'news_short', body: '<p>Коротко</p>')

    get '/ru/news'
    assert_response :success

    assert_includes response.body, 'Новость дня'
    assert_select '.news-feed .news-card__title', text: 'Обычная статья', count: 0
    assert_not_includes response.body, 'Черновик'
    assert_not_includes response.body, 'Удалённая'
    assert_not_includes response.body, 'English news'
    assert_not_includes response.body, 'Список в ленте'
    assert_not_includes response.body, 'Слишком короткая'

    # до метки деления, затем кнопка «Читать далее»
    assert_includes response.body, 'Анонс новости'
    assert_not_includes response.body, 'Продолжение новости'
    assert_includes response.body, 'Читать далее'
    assert_includes response.body, '/ru/ru/w/news_today'
  end

  test 'у статьи без метки деления в ленте текстовый анонс' do
    create_page(is_published: true, is_news: true, title: 'Без ката', path: 'news_no_cut', body: LONG_BODY)

    get '/ru/news'
    assert_response :success
    assert_includes response.body, 'Достаточно длинный текст страницы'
    assert_includes response.body, 'Читать далее'
  end

  test 'в карточке есть автор, теги, кнопка копирования ссылки и приглашение в чат' do
    author = create_user(name: 'Иван Автор')
    page = create_page(is_published: true, is_news: true, title: 'Новость с автором', path: 'news_author',
                       body: CUT_BODY, user_id: author.id)
    page.sync_tag_list!(['Новости'])

    get '/ru/news'
    assert_response :success

    assert_includes response.body, 'Иван Автор'
    assert_select 'a.tag-chip', text: 'Новости'
    assert_select 'button[data-share-btn-url-value="https://bibleox.com/ru/ru/w/news_author"]'
    assert_select '.news-card__actions a[href="/ru/chat"]'
  end

  test 'реакция с этого IP подсвечена в ленте' do
    page = create_page(is_published: true, is_news: true, title: 'С реакцией', path: 'news_reacted', body: LONG_BODY)
    PageReaction.create!(page: page, kind: 'like', ip_digest: PageReaction.digest_ip('127.0.0.1'))

    get '/ru/news'
    assert_response :success
    assert_select '.page-reaction__choice[data-kind="like"].is-active'
    assert_select '.page-reaction__choice[data-kind="like"] .page-reaction__count', text: '1'
    # у реакций с нулём нет цифры «0», а сама кнопка приглушена
    assert_select '.page-reaction__choice[data-kind="useful"].is-empty'
    assert_select '.page-reaction__choice[data-kind="useful"] .page-reaction__count[hidden]'
    assert_select '.page-reaction__choice[data-kind="like"].is-empty', count: 0
  end

  test 'ссылка на ленту спрятана в выпадающее меню' do
    get '/ru/news'
    assert_response :success

    assert_select 'header nav > a#news-link', count: 0
    assert_select '#more-area a#news-link[href="/ru/news"]', text: 'Лента'
  end

  test 'справа показывает недавно обновлённые статьи без повторов с лентой' do
    feed_page = create_page(is_published: true, is_news: true, title: 'Новость в ленте',
                            path: 'news_feed_item', body: LONG_BODY)
    feed_page.update_column(:updated_at, 10.minutes.ago)

    newer = create_page(is_published: true, title: 'Обновлена недавно', path: 'updated_new', body: LONG_BODY)
    newer.update_column(:updated_at, 1.hour.ago)

    older = create_page(is_published: true, title: 'Обновлена давно', path: 'updated_old', body: LONG_BODY)
    older.update_column(:updated_at, 2.days.ago)

    create_page(is_published: false, title: 'Черновик обновлён', path: 'updated_draft', body: LONG_BODY)
    create_page(is_published: true, title: 'English update', path: 'updated_en', lang: 'en', body: LONG_BODY)

    get '/ru/news'
    assert_response :success

    assert_select '.news-updates__title', text: 'Недавно обновились'
    assert_select '.news-updates__list a', text: 'Обновлена недавно'
    assert_select '.news-updates__list a', text: 'Обновлена давно'
    assert_select '.news-updates__list a', text: 'Новость в ленте', count: 0
    assert_select '.news-updates__list a', text: 'Черновик обновлён', count: 0
    assert_select '.news-updates__list a', text: 'English update', count: 0
    assert_operator response.body.index('Обновлена недавно'), :<, response.body.index('Обновлена давно')
  end

  test 'блок «Читают сейчас» показывает статьи с читателями' do
    page = create_page(is_published: true, is_news: true, title: 'Сейчас читают', path: 'news_reading', body: LONG_BODY)
    PageVisits.touch_reading(page.id, ip: '10.0.9.1')
    PageVisits.touch_reading(page.id, ip: '10.0.9.2')

    get '/ru/news'
    assert_response :success

    assert_select '.reading-now__list li a', text: 'Сейчас читают'
    assert_select '.reading-now__count', text: '2'
  end

  test 'endpoint живого блока отдаёт обновлённую разметку' do
    page = create_page(is_published: true, is_news: true, title: 'Живой блок', path: 'news_live', body: LONG_BODY)
    PageVisits.touch_reading(page.id, ip: '10.0.9.3')

    get '/ru/news/reading'
    assert_response :success
    assert_includes response.body, 'Живой блок'
    assert_equal 'no-store', response.headers['Cache-Control']
  end

  test 'пустая лента показывает подсказку' do
    get '/ru/news'
    assert_response :success
    assert_includes response.body, 'В ленте пока нет статей'
  end

  private

  def clean_reading
    ::RedisConnectionPool.del(::PageVisits::READING_KEY)
  end
end

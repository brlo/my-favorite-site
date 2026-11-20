require 'test_helper'

# API мобильного приложения: скелет с тегами и лидом, тексты страниц,
# лента, токены маячка, реакции и посещения.
class Api::OfflineControllerTest < ActionDispatch::IntegrationTest
  LONG_BODY = '<p>' + 'Достаточно длинный текст страницы. ' * 3 + '</p>'
  CUT_BODY = '<p>Анонс новости</p><hr class="article-cut"><p>Продолжение новости</p>' + LONG_BODY
  CHROME_UA = 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/120.0.0.0 Mobile Safari/537.36'
  IP_ONE = '10.0.7.1'
  IP_TWO = '10.0.7.2'

  setup do
    clean_visits
  end

  teardown do
    clean_visits
  end

  test 'манифест отдаёт токен heartbeat для книги Библии' do
    get '/api/offline/manifest', params: {locale: 'ru'}
    assert_response :success

    gen = json_body['books'].find { |book| book['code'] == 'gen' }
    assert_equal ::PageVisits.bible_visit_token('gen'), gen['reading_token']
  end

  test 'скелет отдаёт лид, цвета подложки и теги страницы' do
    page = create_page(is_published: true, title: 'Статья с лидом', path: 'skeleton_lead',
                       body: CUT_BODY, cover_overlay_bg: '#123456', cover_overlay_text: '#abcdef')
    page.sync_tag_list!(['Новости', 'Молитва'])

    get '/api/offline/skeleton', params: {lang: 'ru', since: 0}
    assert_response :success
    assert_equal ::Offline::Export::SKELETON_VERSION, json_body['data_version']

    card = json_body['pages'].find { |p| p['id'] == page.id }
    assert card
    assert_equal true, card['has_lead']
    assert_equal '#123456', card['cover_overlay_bg']
    assert_equal '#abcdef', card['cover_overlay_text']
    assert_equal ['Молитва', 'Новости'], json_body['tags'].map { |t| t['name'] }.sort
    assert json_body['tags'].all? { |t| t['slug'].present? && t['id'].present? }
    assert_includes json_body['page_tags'], [page.id, Tag.find_by!(name: 'Молитва').id]
    assert_operator card['body_size'], :>, 0
  end

  test 'снимок тегов обновляется в дельте скелета' do
    page = create_page(is_published: true, title: 'Статья с тегами', path: 'skeleton_tags', body: LONG_BODY)

    get '/api/offline/skeleton', params: {lang: 'ru', since: 0}
    since = json_body['next_since']
    assert_empty json_body['tags']

    page.sync_tag_list!(['Новости'])
    tag = Tag.find_by!(name: 'Новости')

    get '/api/offline/skeleton', params: {lang: 'ru', since: since}
    assert_equal ['Новости'], json_body['tags'].map { |t| t['name'] }
    assert_includes json_body['page_tags'], [page.id, tag.id]

    since = json_body['next_since']
    tag.update!(name: 'Весть')

    get '/api/offline/skeleton', params: {lang: 'ru', since: since}
    assert_equal ['Весть'], json_body['tags'].map { |t| t['name'] }

    page.sync_tag_list!([])

    get '/api/offline/skeleton', params: {lang: 'ru', since: since}
    assert_empty json_body['tags']
    assert_empty json_body['page_tags']
  end

  test 'имя тега в скелете локализовано на язык выгрузки' do
    page = create_page(is_published: true, title: 'English tagged', path: 'skeleton_en_tag', lang: 'en', body: LONG_BODY)
    page.sync_tag_list!(['Новости'])
    Tag.find_by!(name: 'Новости').update!(names: {'en' => 'News'})

    get '/api/offline/skeleton', params: {lang: 'en', since: 0}
    assert_equal ['News'], json_body['tags'].map { |t| t['name'] }
  end

  test 'текст страницы отдаёт lead, body_main, body и токен маячка' do
    page = create_page(is_published: true, title: 'Статья с лидом', path: 'pages_lead', body: CUT_BODY)

    get '/api/offline/pages', params: {lang: 'ru', ids: page.id.to_s}
    assert_response :success

    data = json_body['pages'].first
    assert_includes data['lead'], 'Анонс новости'
    assert_not_includes data['body_main'], 'Анонс новости'
    assert_includes data['body_main'], 'Продолжение новости'
    assert_includes data['body'], 'Анонс новости'
    assert_includes data['body'], 'Продолжение новости'
    assert_equal ::PageVisits.visit_token(page.id), data['visit_token']
  end

  test 'без метки деления lead пустой, body_main совпадает с body' do
    page = create_page(is_published: true, title: 'Обычная статья', path: 'pages_no_lead', body: LONG_BODY)

    get '/api/offline/pages', params: {lang: 'ru', ids: page.id.to_s}
    data = json_body['pages'].first
    assert_nil data['lead']
    assert_equal data['body_main'], data['body']
  end

  test 'отдельный запрос токенов для уже скачанных страниц' do
    page = create_page(is_published: true, title: 'Скачанная статья', path: 'pages_token', body: LONG_BODY)

    get '/api/offline/tokens', params: {ids: page.id.to_s}
    assert_response :success
    assert_equal ::PageVisits.visit_token(page.id), json_body['tokens'][page.id.to_s]
  end

  test 'лента отдаёт карточки с обложкой, тегами, автором и реакциями' do
    author = create_user(name: 'Иван Автор')
    parent = create_page(is_published: true, title: 'Раздел новостей', path: 'feed_parent')
    page = create_page(is_published: true, is_news: true, title: 'Новость дня', path: 'feed_news',
                       body: CUT_BODY, user_id: author.id, parent_id: parent.id,
                       cover_overlay_bg: '#001122')
    page.sync_tag_list!(['Новости'])
    create_page(is_published: true, is_news: false, title: 'Обычная статья', path: 'feed_regular', body: LONG_BODY)
    create_page(is_published: true, is_news: true, title: 'English news', path: 'feed_en', lang: 'en', body: LONG_BODY)
    create_page(is_published: false, is_news: true, title: 'Черновик', path: 'feed_draft', body: LONG_BODY)

    ::PageReaction.create!(page: page, kind: 'like', ip_digest: ::PageReaction.digest_ip(IP_ONE))

    get '/api/offline/feed', params: {lang: 'ru', page: 1}, headers: {'REMOTE_ADDR' => IP_ONE, 'HTTP_USER_AGENT' => CHROME_UA}
    assert_response :success

    card = json_body['pages'].find { |p| p['id'] == page.id }
    assert card
    assert_equal 'Новость дня', card['title']
    assert_equal 'Иван Автор', card['author']
    assert_equal 'Раздел новостей', card['parent']['title']
    assert_equal '#001122', card['cover_overlay_bg']
    assert_equal ['Новости'], card['tags'].map { |t| t['name'] }
    assert_includes card['preview'], 'Анонс новости'
    assert_not_includes card['preview'], 'Продолжение новости'
    assert_equal 1, card['reactions']['counts']['like']
    assert_equal 'like', card['reactions']['active']
    assert_equal 1, json_body['total_pages']
    assert_equal 1, json_body['pages'].size
  end

  test 'в ленте работает постраничная выдача' do
    12.times do |i|
      create_page(is_published: true, is_news: true, title: "Новость #{i}", path: "feed_page_#{i}", body: LONG_BODY)
    end

    get '/api/offline/feed', params: {lang: 'ru', page: 1}
    assert_equal 10, json_body['pages'].size
    assert_equal 2, json_body['total_pages']

    get '/api/offline/feed', params: {lang: 'ru', page: 2}
    assert_equal 2, json_body['pages'].size
  end

  test 'реакции: показать, поставить, сменить и снять' do
    page = create_page(is_published: true, title: 'Статья для реакций', path: 'reactions_api', body: LONG_BODY)

    get '/api/offline/reactions', params: {page_id: page.id}, headers: {'REMOTE_ADDR' => IP_ONE, 'HTTP_USER_AGENT' => CHROME_UA}
    assert_response :success
    assert_equal 0, json_body['counts']['like']
    assert_nil json_body['active']

    post '/api/offline/reactions', params: {page_id: page.id, kind: 'like'}, as: :json,
                                   headers: {'REMOTE_ADDR' => IP_ONE, 'HTTP_USER_AGENT' => CHROME_UA}
    assert_response :success
    assert_equal 1, json_body['counts']['like']
    assert_equal 'like', json_body['active']

    post '/api/offline/reactions', params: {page_id: page.id, kind: 'useful'}, as: :json,
                                   headers: {'REMOTE_ADDR' => IP_ONE, 'HTTP_USER_AGENT' => CHROME_UA}
    assert_response :success
    assert_equal 0, json_body['counts']['like']
    assert_equal 1, json_body['counts']['useful']
    assert_equal 'useful', json_body['active']

    get '/api/offline/reactions', params: {page_id: page.id}, headers: {'REMOTE_ADDR' => IP_ONE, 'HTTP_USER_AGENT' => CHROME_UA}
    assert_equal 'useful', json_body['active']
    assert_equal 1, json_body['counts']['useful']

    post '/api/offline/reactions', params: {page_id: page.id, kind: 'useful'}, as: :json,
                                   headers: {'REMOTE_ADDR' => IP_ONE, 'HTTP_USER_AGENT' => CHROME_UA}
    assert_equal 0, json_body['counts']['useful']
    assert_nil json_body['active']
  end

  test 'реакции: неизвестный вид, черновик и не-статья отклоняются' do
    page = create_page(is_published: true, title: 'Статья', path: 'reactions_api_bad', body: LONG_BODY)
    draft = create_page(is_published: false, title: 'Черновик', path: 'reactions_api_draft', body: LONG_BODY)
    list = create_page(is_published: true, title: 'Список', path: 'reactions_api_list', page_type: 4, body: LONG_BODY)

    post '/api/offline/reactions', params: {page_id: page.id, kind: 'superlike'}, as: :json,
                                   headers: {'REMOTE_ADDR' => IP_ONE, 'HTTP_USER_AGENT' => CHROME_UA}
    assert_response :unprocessable_entity
    assert_equal 0, ::PageReaction.count

    post '/api/offline/reactions', params: {page_id: draft.id, kind: 'like'}, as: :json,
                                   headers: {'REMOTE_ADDR' => IP_ONE, 'HTTP_USER_AGENT' => CHROME_UA}
    assert_response :not_found

    post '/api/offline/reactions', params: {page_id: list.id, kind: 'like'}, as: :json,
                                   headers: {'REMOTE_ADDR' => IP_ONE, 'HTTP_USER_AGENT' => CHROME_UA}
    assert_response :not_found
  end

  test 'маячок посещения требует токен и увеличивает счётчик статьи' do
    page = create_page(is_published: true, title: 'Посещаемая статья', path: 'visit_api', body: LONG_BODY)
    ::RedisConnectionPool.del("vis:#{page.id}", "vis:#{page.id}=#{IP_ONE}")
    token = ::PageVisits.visit_token(page.id)

    post '/api/offline/visit', params: {page_id: page.id, lang: 'ru', t: 'bad'}, as: :json,
                               headers: {'REMOTE_ADDR' => IP_ONE, 'HTTP_USER_AGENT' => CHROME_UA}
    assert_response :unprocessable_entity
    assert_nil ::RedisConnectionPool.get("vis:#{page.id}")

    post '/api/offline/visit', params: {page_id: page.id, lang: 'ru', t: token}, as: :json,
                               headers: {'REMOTE_ADDR' => IP_ONE, 'HTTP_USER_AGENT' => CHROME_UA}
    assert_response :success
    assert_equal '1', ::RedisConnectionPool.get("vis:#{page.id}")

    # повторный визит с того же IP в течение 12 часов не засчитывается
    post '/api/offline/visit', params: {page_id: page.id, lang: 'ru', t: token}, as: :json,
                               headers: {'REMOTE_ADDR' => IP_ONE, 'HTTP_USER_AGENT' => CHROME_UA}
    assert_equal '1', ::RedisConnectionPool.get("vis:#{page.id}")
  end

  test 'heartbeat главы Библии ставит и снимает отметку книги' do
    token = ::PageVisits.bible_visit_token('gen')

    post '/api/offline/reading', params: {book: 'gen', t: token}, as: :json,
                                 headers: {'REMOTE_ADDR' => IP_TWO, 'HTTP_USER_AGENT' => CHROME_UA}
    assert_response :success
    assert_equal [['gen', 1]], ::PageVisits.reading_now.bibles

    post '/api/offline/reading', params: {book: 'gen', t: token, leave: 1}, as: :json,
                                 headers: {'REMOTE_ADDR' => IP_TWO, 'HTTP_USER_AGENT' => CHROME_UA}
    assert_response :success
    assert_empty ::PageVisits.reading_now.bibles
  end

  test 'heartbeat главы Библии с чужим токеном отклоняется' do
    post '/api/offline/reading', params: {book: 'gen', t: 'forged'}, as: :json,
                                 headers: {'REMOTE_ADDR' => IP_TWO, 'HTTP_USER_AGENT' => CHROME_UA}
    assert_response :unprocessable_entity
    assert_empty ::PageVisits.reading_now.bibles
  end

  test 'heartbeat «читает сейчас» ставит и снимает отметку' do
    page = create_page(is_published: true, title: 'Читаемая статья', path: 'reading_api', body: LONG_BODY)
    token = ::PageVisits.visit_token(page.id)

    post '/api/offline/reading', params: {page_id: page.id, t: token}, as: :json,
                                 headers: {'REMOTE_ADDR' => IP_TWO, 'HTTP_USER_AGENT' => CHROME_UA}
    assert_response :success
    assert_equal 1, ::PageVisits.readers_count(page.id)

    post '/api/offline/reading', params: {page_id: page.id, t: token, leave: 1}, as: :json,
                                 headers: {'REMOTE_ADDR' => IP_TWO, 'HTTP_USER_AGENT' => CHROME_UA}
    assert_response :success
    assert_equal 0, ::PageVisits.readers_count(page.id)
  end

  private

  def json_body
    JSON.parse(response.body)
  end

  def clean_visits
    day = Date.today.to_s
    ids = ::Page.order(:id).pluck(:id)
    keys = ids.flat_map do |id|
      ["vis:#{id}", "vis:#{id}=#{IP_ONE}", "vis:#{id}=#{IP_TWO}", "vis:#{id}=#{"127.0.0.1"}"]
    end
    keys += %w[vis o-vis s-vis b-vis uip bots zips langs top].map { |name| "#{name}#{day}" }
    keys << "ipvis#{day}:#{IP_ONE}" << "ipvis#{day}:#{IP_TWO}" << "ipvis#{day}:127.0.0.1"
    keys << ::PageVisits::READING_KEY
    ::RedisConnectionPool.del(*keys)
  end
end

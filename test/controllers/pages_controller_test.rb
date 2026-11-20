require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  LONG_BODY = '<p>' + 'Достаточно длинный текст страницы. ' * 3 + '</p>'
  CHAT_INVITE_BODY = '<p>' + 'Достаточно длинный текст статьи. ' * 80 + '</p>'

  def create_published(overrides = {})
    create_page({ is_published: true, body: LONG_BODY }.merge(overrides))
  end

  # --- show: найдена ---

  test "published page is rendered with title, body and canonical url" do
    page = create_published(title: 'Беседа о любви', path: 'beseda')
    get '/ru/ru/w/beseda'
    assert_response :success
    assert_includes response.body, 'Беседа о любви'
    assert_includes response.body, 'Достаточно длинный текст'
    assert_includes response.body, 'https://bibleox.com/ru/ru/w/beseda'
    assert_select '#page-body[data-controller~="section-collapse"]'
    assert_select '#page-body[data-controller~="auto-collapse"]', count: 0
    assert page.persisted?
  end

  test "html lang is the interface language and article body keeps its own language" do
    create_published(title: '中文文章', path: 'zh_article', lang: 'zh-Hans', body: '<p>' + '这是足够长的中文正文。' * 3 + '</p>')
    get '/en/zh-Hans/w/zh_article'
    assert_response :success
    assert_select 'html[lang="en"]'
    assert_select '#page-body[lang="zh-Hans"]'
    assert_select '#h1-title[lang="zh-Hans"]'
  end

  test "root redirects to language home with 301" do
    get '/'
    assert_response :moved_permanently
    assert_redirected_to '/ru/'
    assert_includes response.headers['Vary'].to_s, 'Accept-Language'
  end

  test "root redirects japanese browser to japanese home" do
    get '/', headers: { 'Accept-Language' => 'ja-JP,ja;q=0.9' }
    assert_response :found
    assert_redirected_to '/ja/'
    assert_includes response.headers['Vary'].to_s, 'Accept-Language'
  end

  test "root redirects simplified and traditional chinese browsers to their home" do
    get '/', headers: { 'Accept-Language' => 'zh-CN,zh;q=0.9' }
    assert_response :found
    assert_redirected_to '/zh-Hans/'

    get '/', headers: { 'Accept-Language' => 'zh-TW,zh;q=0.9' }
    assert_response :found
    assert_redirected_to '/zh-Hant/'
  end

  test "root ignores unsupported browser languages" do
    get '/', headers: { 'Accept-Language' => 'pt-BR,pt;q=0.9' }
    assert_response :moved_permanently
    assert_redirected_to '/ru/'
  end

  test "article page has x-default hreflang and Article JSON-LD" do
    create_published(path: 'seo_marks')
    get '/ru/ru/w/seo_marks'
    assert_response :success
    assert_includes response.body, 'hreflang="x-default"'
    assert_select 'link[rel="alternate"][hreflang="ru"][href="https://bibleox.com/ru/ru/w/seo_marks"]', count: 1
    assert_includes response.body, '"@type":"Article"'
    assert_includes response.body, '"dateModified"'
    assert_includes response.body, 'property="og:type" content="article"'
  end

  test "person page has Person JSON-LD with life dates from title_sub and profile og:type" do
    page = create_published(path: 'author_page', title: 'Иоанн Златоуст, IV век', title_sub: 'святитель (~347-407), архиепископ Константинопольский')
    page.update_column(:seo_kind, 'person')
    get '/ru/ru/w/author_page'
    assert_response :success
    assert_includes response.body, '"@type":"Person"'
    assert_includes response.body, '"birthDate":"347"'
    assert_includes response.body, '"deathDate":"407"'
    assert_includes response.body, 'property="og:type" content="profile"'
  end

  test "book page has Book JSON-LD with author from a person menu and book og:type" do
    author = create_published(page_type: 4, title: 'Священник Евгений Веселов')
    author.update_column(:seo_kind, 'person')
    book = create_published(title: 'Вне Церкви нет спасения', title_sub: '(Издание второе, исправленное)')
    book.update_column(:seo_kind, 'book')
    Menu.create!(page_id: author.id, title: book.title, path: book.path)

    get "/ru/ru/w/#{book.path}"
    assert_response :success
    assert_includes response.body, '"@type":"Book"'
    assert_includes response.body, '"author":{"@type":"Person","name":"Священник Евгений Веселов"'
    assert_includes response.body, 'property="og:type" content="book"'
  end

  test "author and editors are shown" do
    author = create_user(name: 'Автор Статьи')
    editor = create_user(name: 'Редактор Правок')
    create_published(path: 'with_authors', user_id: author.id, editors: [editor.id])
    get '/ru/ru/w/with_authors'
    assert_includes response.body, 'Автор Статьи'
    assert_includes response.body, 'Редактор Правок'
  end

  test "chat invitation is shown at the end of the article before the notes" do
    create_published(path: 'with_notes', body: CHAT_INVITE_BODY, references: '<p>Примечание первое</p>')
    get '/ru/ru/w/with_notes'

    assert_response :success
    assert_select '[data-controller="chat-invite"]'
    assert_select '[data-chat-invite-target="sentinel"]'
    assert_select '.chat-invite-float[hidden]'
    assert_select '.chat-invite-float .page-chat-invite[href="/ru/chat"]'
    assert_select '.chat-invite-float .page-chat-invite__cta', text: 'Перейти в чат'
    assert_select '.chat-invite-float__close[aria-label="Закрыть"]'
    invite_pos = response.body.index('page-chat-invite')
    notes_pos = response.body.index('page-references')
    assert invite_pos && notes_pos
    assert_operator invite_pos, :<, notes_pos
  end

  test "chat invitation is hidden for short articles" do
    create_published(path: 'short_article', body: '<p>' + 'а' * 1999 + '</p>')
    get '/ru/ru/w/short_article'

    assert_response :success
    assert_select '.page-chat-invite', count: 0
  end

  test "chat invitation is shown for articles with at least 2000 characters" do
    create_published(path: 'long_article', body: '<p>' + 'а' * 2000 + '</p>')
    get '/ru/ru/w/long_article'

    assert_response :success
    assert_select '.page-chat-invite', count: 1
  end

  test "bibleox translation badge is an accessible tooltip trigger" do
    create_published(path: 'bibleox_text', is_bibleox: true)
    get '/ru/ru/w/bibleox_text'

    assert_response :success
    assert_select 'button.translation-icon[aria-expanded="false"]'
    assert_select 'button.translation-icon[aria-describedby="translation-tooltip"]'
    assert_select 'button.translation-icon[aria-controls="translation-tooltip"]'
    assert_select '#translation-tooltip[role="tooltip"]'
  end

  test "table of contents uses height-based auto-collapse" do
    body = (1..22).map { |i| "<h2>Раздел #{i}</h2><p>Текст раздела #{i}.</p>" }.join
    create_published(path: 'long_toc', body: body)
    get '/ru/ru/w/long_toc'

    assert_response :success
    assert_select '#article-menu[data-controller="auto-collapse"][data-auto-collapse-max-height-value="900"][data-auto-collapse-always-toggle-value="true"]'
    assert_select '#article-menu.collapsed'
    assert_select '#article-menu button.menu-toggle[aria-expanded="false"]'
    assert_select '#article-menu .menu-toggle span', text: 'Содержание'
    assert_select '#article-menu .menu-toggle-chevron'
    assert_select '#article-menu .menu-list .nav-h2', count: 22
  end

  test "short table of contents is rendered for the same height-based controller" do
    body = (1..3).map { |i| "<h2>Раздел #{i}</h2><p>Текст раздела #{i}.</p>" }.join
    create_published(path: 'short_toc', body: body)
    get '/ru/ru/w/short_toc'

    assert_response :success
    assert_select '#article-menu[data-controller="auto-collapse"]'
    assert_select '#article-menu button.menu-toggle'
    assert_select '#article-menu .menu-toggle-chevron'
    assert_select '#article-menu .menu-list .nav-h2', count: 3
  end

  test "part before the cut is rendered before the table of contents" do
    body = '<p>Эпиграф статьи</p><hr class="article-cut"><h2>Начало</h2>' + LONG_BODY
    create_published(path: 'cut_article', body: body)
    get '/ru/ru/w/cut_article'

    assert_response :success
    assert_select '#page-body .page-lead p', text: 'Эпиграф статьи'
    # в оглавление попадают только заголовки после деления
    assert_select '#article-menu .nav-h2', count: 1
    # и первая часть идёт в разметке раньше меню-оглавления
    assert_operator response.body.index('page-lead'), :<, response.body.index('id="article-menu"')
  end

  test "page whose ui language differs from the content language is not indexed" do
    create_published(path: 'en_page', lang: 'en')
    get '/ru/en/w/en_page'
    assert_response :success
    assert_match(/noindex/, response.body)
  end

  test "path in a different case redirects to the canonical path" do
    create_published(path: 'CamelCase')
    get '/ru/ru/w/camelcase'
    assert_response :found
    assert_match %r{/ru/ru/w/CamelCase\z}, response.location
  end

  test "page with a short body is shown with 404 status" do
    create_published(path: 'stub', body: '<p>коротко</p>')
    get '/ru/ru/w/stub'
    assert_response :not_found
    assert_includes response.body, 'коротко'
  end

  # --- show: не найдена ---

  test "unknown page gives 404 with a link to create it" do
    get '/ru/ru/w/no_such_page', params: { parent_id: 5 }
    assert_response :not_found
    assert_includes response.body, '/admin/pages/new'
    assert_includes response.body, 'page_title=no_such_page'
    assert_includes response.body, 'parent_id=5'
  end

  test "old address redirects to the page that remembers it" do
    page = create_published(path: 'old_path')
    page.update!(path: 'new_path')
    get '/ru/ru/w/old_path'
    assert_response :redirect
    assert_match %r{/ru/ru/w/new_path\z}, response.location
  end

  test "unpublished and deleted pages give 404" do
    create_page(path: 'draft', is_published: false, body: LONG_BODY)
    get '/ru/ru/w/draft'
    assert_response :not_found

    create_published(path: 'gone', is_deleted: true)
    get '/ru/ru/w/gone'
    assert_response :not_found
  end

  test "page in another language redirects to its translation" do
    ru = create_published(path: 'rus_version', lang: 'ru')
    create_published(path: 'eng_version', lang: 'en', group_lang_id: ru.group_lang_id)
    get '/ru/en/w/rus_version'
    assert_response :redirect
    assert_match %r{/ru/en/w/eng_version\z}, response.location
  end

  test "switch to a content-only language keeps that language in the address" do
    ru = create_published(path: 'grabar_source', lang: 'ru')
    create_published(path: 'grabar_xcl', lang: 'xcl', group_lang_id: ru.group_lang_id)
    get '/en/xcl/w/grabar_source'
    assert_response :redirect
    assert_match %r{/en/xcl/w/grabar_xcl\z}, response.location
  end

  test "page in a content-only language opens and keeps its language on the page" do
    create_published(path: 'grabar_page', lang: 'xcl')
    get '/en/xcl/w/grabar_page'
    assert_response :success
    assert_match(/<meta property="og:locale" content=\s*"xcl"/, response.body)
  end

  test "service page links fall back to english when the language has no such page" do
    create_published(path: 'links_en', lang: 'en')
    create_published(path: 'help_en', lang: 'en')
    create_published(path: 'xcl_without_links', lang: 'xcl')
    get '/en/xcl/w/xcl_without_links'
    assert_response :success
    assert_includes response.body, 'href="/en/en/w/links_en"'
    assert_includes response.body, 'href="/en/en/w/help_en"'
  end

  test "service page links stay in the article language when such a page exists" do
    create_published(path: 'links_ru', lang: 'ru')
    create_published(path: 'help_ru', lang: 'ru')
    create_published(path: 'rus_with_links', lang: 'ru')
    get '/ru/ru/w/rus_with_links'
    assert_response :success
    assert_includes response.body, 'href="/ru/ru/w/links_ru"'
    assert_includes response.body, 'href="/ru/ru/w/help_ru"'
  end

  test "other language versions are listed" do
    ru = create_published(path: 'rus_v2', lang: 'ru')
    create_published(path: 'eng_v2', lang: 'en', group_lang_id: ru.group_lang_id)
    get '/ru/ru/w/rus_v2'
    assert_response :success
    assert_includes response.body, 'eng_v2'
  end

  # --- родитель, меню, главы, хлебные крошки ---

  test "breadcrumbs include the whole chain of parents" do
    top = create_published(title: 'Верхний раздел', path: 'top')
    mid = create_published(title: 'Средний раздел', path: 'mid', parent_id: top.id)
    leaf = create_published(title: 'Лист', path: 'leaf', parent_id: mid.id)
    get "/ru/ru/w/#{leaf.path}"
    assert_response :success
    %w[Верхний Средний].each { assert_includes response.body, _1 }
    assert_includes response.body, '/ru/ru/w/mid'
    assert_includes response.body, '/ru/ru/w/top'
  end

  test "title gets a few words of the parent title when it is short" do
    parent = create_published(title: 'Родительский раздел для проверки', path: 'par')
    create_published(title: 'Коротко', path: 'child', parent_id: parent.id)
    get '/ru/ru/w/child'
    assert_match %r{<title>[^<]*Коротко[^<]* / [^<]*Родительский}, response.body
  end

  test "chapters navigation lists siblings from the parent menu without empty ones" do
    list = create_published(title: 'Книга', path: 'book_list', page_type: 4)
    first = create_published(title: 'Глава первая', path: 'ch1', parent_id: list.id)
    create_published(title: 'Глава вторая', path: 'ch2', parent_id: list.id)
    create_published(title: 'Глава пустая', path: 'ch3', parent_id: list.id)
    root = Menu.create!(page_id: list.id, title: 'Раздел меню')
    Menu.create!(page_id: list.id, parent_id: root.id, title: 'Глава первая', path: 'ch1', priority: 1)
    Menu.create!(page_id: list.id, parent_id: root.id, title: 'Глава вторая', path: 'ch2', priority: 2)
    Menu.create!(page_id: list.id, parent_id: root.id, title: 'Глава пустая', path: 'ch3', priority: 3, is_empty: true)

    get "/ru/ru/w/#{first.path}"
    assert_response :success
    assert_includes response.body, 'Глава вторая'
    assert_not_includes response.body, 'Глава пустая'
  end

  test "similar pages use row-based auto-collapse" do
    list = create_published(title: 'Книга', path: 'similar_long_list', page_type: 4)
    root = Menu.create!(page_id: list.id, title: 'Раздел меню')
    first = nil

    11.times do |i|
      title = "Глава #{i + 1}"
      path = "similar_long_ch#{i + 1}"
      first ||= create_published(title: title, path: path, parent_id: list.id)
      Menu.create!(page_id: list.id, parent_id: root.id, title: title, path: path, priority: i + 1)
    end

    get "/ru/ru/w/#{first.path}"

    assert_response :success
    assert_select '.menu-tree[data-controller="auto-collapse"][data-auto-collapse-max-rows-value="2"]'
    assert_select '.menu-tree.collapsed'
    assert_select 'button.same-subject-toggle[aria-expanded="false"][hidden]'
    assert_select '.same-subject-static', text: 'Похожие материалы:'
    assert_select '.menu-tree .items .menu-link', count: 11
  end

  test "short similar list is rendered for the same row-based controller" do
    list = create_published(title: 'Книга', path: 'similar_short_list', page_type: 4)
    root = Menu.create!(page_id: list.id, title: 'Раздел меню')
    first = nil

    3.times do |i|
      title = "Глава #{i + 1}"
      path = "similar_short_ch#{i + 1}"
      first ||= create_published(title: title, path: path, parent_id: list.id)
      Menu.create!(page_id: list.id, parent_id: root.id, title: title, path: path, priority: i + 1)
    end

    get "/ru/ru/w/#{first.path}"

    assert_response :success
    assert_select '.menu-tree[data-controller="auto-collapse"][data-auto-collapse-max-rows-value="2"]'
    assert_select '.menu-tree .items .menu-link', count: 3
  end

  test "regular similar materials are rendered below the page text bar" do
    list = create_published(title: 'Книга', path: 'links_list', page_type: 4)
    root = Menu.create!(page_id: list.id, title: 'Раздел меню')
    first = create_published(title: 'Глава 1', path: 'links_ch1', parent_id: list.id,
                             links: { 'Другое' => '/other' })
    create_published(title: 'Глава 2', path: 'links_ch2', parent_id: list.id)
    Menu.create!(page_id: list.id, parent_id: root.id, title: 'Глава 1', path: 'links_ch1', priority: 1)
    Menu.create!(page_id: list.id, parent_id: root.id, title: 'Глава 2', path: 'links_ch2', priority: 2)

    get "/ru/ru/w/#{first.path}"

    assert_response :success
    assert_select '#links-sub'
    assert_select '#chapter-header #text-bar-wrapper ~ .menu-tree'
    assert_select '#links-sub ~ .similar-materials', count: 0
  end

  test "numeric chapter titles are rendered as parts under page links" do
    list = create_published(title: 'Книга', path: 'parts_list', page_type: 4)
    root = Menu.create!(page_id: list.id, title: 'Раздел меню')
    first = nil

    3.times do |i|
      title = "##{i + 1}"
      path = "part_ch#{i + 1}"
      first ||= create_published(title: title, path: path, parent_id: list.id,
                                 links: { 'Другое' => '/other' })
      Menu.create!(page_id: list.id, parent_id: root.id, title: title, path: path, priority: i + 1)
    end

    get "/ru/ru/w/#{first.path}"

    assert_response :success
    assert_select '#chapter-header #links-sub ~ .similar-materials'
    assert_select '.same-subject-static', text: 'Часть'
    assert_select '.same-subject-toggle span', text: 'Часть'
  end

  test "list page shows its tree menu with visit counters" do
    list = create_published(title: 'Список', path: 'a_list', page_type: 4)
    create_published(title: 'Пункт', path: 'item_page', parent_id: list.id)
    Menu.create!(page_id: list.id, title: 'Пункт меню', path: 'item_page')
    Rails.cache.clear
    get '/ru/ru/w/a_list'
    assert_response :success
    assert_includes response.body, 'Пункт меню'
  end

  test "on a list page the part before the cut is rendered before the tree menu" do
    body = '<p>Эпиграф списка</p><hr class="article-cut"><p>Текст списка</p>'
    list = create_published(title: 'Список с катом', path: 'cut_list', page_type: 4, body: body)
    create_published(title: 'Пункт', path: 'cut_list_item', parent_id: list.id)
    Menu.create!(page_id: list.id, title: 'Пункт меню', path: 'cut_list_item')
    Rails.cache.clear

    get '/ru/ru/w/cut_list'
    assert_response :success
    assert_select '#chapter-header .page-lead p', text: 'Эпиграф списка'
    # в самом тексте статьи лида уже нет; он под панелью текста, но раньше меню-дерева
    assert_select '#page-body .page-lead', count: 0
    assert_operator response.body.index("id='text-bar'"), :<, response.body.index('page-lead')
    assert_operator response.body.index('page-lead'), :<, response.body.index('data-menu-filter-target="tree"')
  end

  test "grey menu items look the same for everyone but are links only for an admin" do
    list = create_published(title: 'Список', path: 'grey_list', page_type: 4)
    create_published(title: 'Заглушка', path: 'grey_stub', parent_id: list.id)
    Menu.create!(page_id: list.id, title: 'Ненаписанная')
    Menu.create!(page_id: list.id, title: 'Заглушка', path: 'grey_stub', is_empty: true)
    Rails.cache.clear

    get '/ru/ru/w/grey_list'
    assert_response :success
    assert_select '.menu-link.not-exist', 2
    assert_select '.menu-link.not-exist a', 2
    assert_select '.menu-link.not-exist a[href]', 0

    sign_in(create_user(is_admin: true))
    get '/ru/ru/w/grey_list'
    assert_select '.menu-link.not-exist a[href]', 2
    assert_select '.menu-link.not-exist a[href*="menu_id="]', 1
  end

  test "bible comment page lives under the bible menu" do
    comment = create_published(title: 'Быт. 1:1', path: '', page_type: 3)
    get "/ru/ru/w/#{ERB::Util.url_encode(comment.path)}"
    assert_response :success
    assert_includes response.body, I18n.t('bible_page.comment_title')
  end

  test "page with several verse chapters shows them and disables chapter numbers" do
    create_published(path: 'verse_page', page_type: 5, verses: [{ 'title' => 'Глава A', 'lines' => ['Строка 1'] }, { 'title' => 'Глава B', 'lines' => ['Строка 2'] }])
    get '/ru/ru/w/verse_page'
    assert_response :success
    assert_includes response.body, 'Строка 2'
    assert_includes response.body, 'data-disable-chapters="1"'
  end

  # --- поиск по странице ---

  test "search page renders without a query" do
    create_published(path: 'searchable')
    get '/ru/ru/w/searchable/search'
    assert_response :success
  end

  test "search page finds paragraphs" do
    page = create_published(path: 'searchable2', body: '<p>' + 'Любовь долготерпит, милосердствует. ' * 4 + '</p>')
    get '/ru/ru/w/searchable2/search', params: { t: 'долготерпит' }
    assert_response :success
    assert_includes response.body, 'долготерпит'
    assert page.page_paragraphs.any?
  end

  test "search page answers turbo stream requests" do
    create_published(path: 'searchable3')
    get '/ru/ru/w/searchable3/search', params: { t: 'нетакогослова' },
        headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
    assert_response :success
    assert_equal 'text/vnd.turbo-stream.html', response.media_type
    assert_includes response.body, 'infinite-scroll-trigger'
  end

  # --- pdf ---

  test "pdf of a missing page or without a file gives 404" do
    get '/ru/ru/w/nothing/as_pdf'
    assert_response :not_found
    create_published(path: 'no_pdf')
    get '/ru/ru/w/no_pdf/as_pdf'
    assert_response :not_found
  end

  test "existing pdf is served by redirect" do
    page = create_published(path: 'with_pdf')
    file = Rails.root.join('public', page.pdf_path)
    FileUtils.mkdir_p(file.dirname)
    File.write(file, '%PDF-1.4')
    begin
      get '/ru/ru/w/with_pdf/as_pdf'
      assert_response :found
      assert_includes response.location, "/#{page.pdf_path}"
    ensure
      File.delete(file)
    end
  end

  # --- прочее ---

  test "about page renders" do
    get '/ru/about'
    assert_response :success
  end

  test "root redirects to the locale root" do
    get '/'
    assert_redirected_to '/ru/'
  end

  test "english page has a canonical url and hreflang links that open" do
    ru = create_published(path: 'lyubov')
    create_published(path: 'Love_en', lang: 'en', group_lang_id: ru.group_lang_id)
    get '/en/en/w/Love_en'
    assert_response :success
    assert_includes response.body, '<link rel="canonical" href="https://bibleox.com/en/en/w/Love_en">'
    assert_includes response.body, 'hreflang="ru" href="https://bibleox.com/ru/ru/w/lyubov"'
  end

  # --- теги статьи ---

  test "article page shows tag chips, keywords and links to the tag page" do
    page = create_published(path: 's_tegami')
    page.sync_tag_list!(['Молитва', 'Вера'])

    get '/ru/ru/w/s_tegami'
    assert_response :success
    assert_select '#page-tags a.tag-chip', count: 2
    assert_includes response.body, '/ru/tags/molitva'
    assert_match(/name="keywords" content="[^"]*Молитва/, response.body)
    assert_match(/property="og:book:tag" content="Молитва"/, response.body)
  end

  test "tag chip shows the translated name for the article language" do
    Tag.create!(name: 'Покаяние', names: { 'en' => 'Repentance' })
    ru = create_published(path: 's_tegami_i18n')
    create_published(path: 's_tegami_i18n_en', lang: 'en', group_lang_id: ru.group_lang_id)
    ru.sync_tag_list!(['Покаяние'])

    get '/en/en/w/s_tegami_i18n_en'
    assert_response :success
    assert_select '#page-tags a.tag-chip', text: 'Repentance'
  end

  test "page without tags renders no tag block" do
    create_published(path: 'bez_tegov')
    get '/ru/ru/w/bez_tegov'
    assert_response :success
    assert_select '#page-tags', count: 0
  end

end

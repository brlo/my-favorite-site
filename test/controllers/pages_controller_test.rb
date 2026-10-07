require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  LONG_BODY = '<p>' + 'Достаточно длинный текст страницы. ' * 3 + '</p>'

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
    assert page.persisted?
  end

  test "author and editors are shown" do
    author = create_user(name: 'Автор Статьи')
    editor = create_user(name: 'Редактор Правок')
    create_published(path: 'with_authors', user_id: author.id, editors: [editor.id])
    get '/ru/ru/w/with_authors'
    assert_includes response.body, 'Автор Статьи'
    assert_includes response.body, 'Редактор Правок'
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

  test "list page shows its tree menu with visit counters" do
    list = create_published(title: 'Список', path: 'a_list', page_type: 4)
    create_published(title: 'Пункт', path: 'item_page', parent_id: list.id)
    Menu.create!(page_id: list.id, title: 'Пункт меню', path: 'item_page')
    Rails.cache.clear
    get '/ru/ru/w/a_list'
    assert_response :success
    assert_includes response.body, 'Пункт меню'
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
end

require "test_helper"

class VersesControllerTest < ActionDispatch::IntegrationTest
  # --- страница главы ---

  test "chapter page shows verses, title and breadcrumbs" do
    create_verse(line: 1, text: 'В начале сотворил Бог небо и землю.')
    create_verse(line: 2, text: 'Земля же была безвидна и пуста.')

    get '/ru/ru/gen/1/'
    assert_response :success
    assert_includes response.body, 'В начале сотворил Бог'
    assert_includes response.body, 'Земля же была безвидна'
    assert_includes response.body, "<title>#{I18n.t('books.mid.gen', locale: :ru)}"
    assert_includes response.body, %(name="description")
  end

  test "chapter page of an empty chapter still renders" do
    get '/ru/ru/ish/2/'
    assert_response :success
  end

  test "chapter in a language other than the UI is not indexed" do
    create_verse(tr_code: 'eng-nkjv', lang: 'en')
    get '/ru/eng-nkjv/gen/1/'
    assert_response :success
    assert_match(/noindex/, response.body)
  end

  test "interlinear chapter renders with greek verses" do
    create_verse(tr_code: 'gr-ru', lang: 'gr', book: 'in', book_id: 43, chapter: 1, line: 1, zavet: false,
                 text: 'Ἐν ἀρχῇ ἦν ὁ λόγος', data: { 'w' => %w[Ἐν ἀρχῇ] })
    get '/ru/gr-ru/in/1/'
    assert_response :success
  end

  test "psalm chapter uses psalm wording" do
    get '/ru/ru/ps/1/'
    assert_response :success
    assert_includes response.body, I18n.t('psalm', locale: :ru)
  end

  test "citation map marks verses cited by the church fathers" do
    verse = create_verse(line: 3, text: 'И сказал Бог: да будет свет.')
    page = create_page(is_past: true, is_published: true, body: '<p>x</p>')
    BibleReference.create!(page_id: page.id, author_page_id: page.id, lang: 'ru', book_code: 'gen', chapter: 1,
                           verse_start: 3, verse_end: 3, position_in_page: 0, snippet: 'Бог сказал', digest: 'abc')
    Rails.cache.clear
    get '/ru/ru/gen/1/'
    assert_response :success
    assert_includes response.body, 'cite'
    assert verse.persisted?
  end

  # --- главная ---

  test "main page renders" do
    create_verse(book: '1in', book_id: 62, line: 1, text: 'Бог есть любовь.')
    get '/ru/'
    assert_response :success
    assert_includes response.body, 'Бог есть любовь.'
  end

  # --- редиректы ---

  test "old url without content language redirects to the current one" do
    get '/ru/gen/1'
    assert_redirected_to '/ru/ru/gen/1/'
    assert_response :found
  end

  test "url without any locale redirects permanently" do
    get '/gen/1'
    assert_response :moved_permanently
    assert_match %r{/ru/ru/gen/1/\z}, response.location
  end

  test "q redirect keeps the page path and query string" do
    get '/ru/q/Some%20Page?x=1'
    assert_response :found
    assert_match %r{/ru/ru/w/Some\+Page\?x=1\z}, response.location
    get '/ru/q'
    assert_match %r{/ru/ru/w/q/\z}, response.location
  end

  test "goto by human address redirects to the verse" do
    get "/ru/f/#{ERB::Util.url_encode('Дан. 1:2')}"
    assert_redirected_to '/ru/ru/dan/1/#L2'
  end

  test "goto by unknown human address redirects to the root" do
    get "/ru/f/#{ERB::Util.url_encode('Нет. 1:2')}"
    assert_redirected_to '/'
  end

  # --- поиск ---

  test "search by address redirects to the verse" do
    get '/ru/search', params: { t: 'Быт 1 1' }
    assert_redirected_to '/ru/ru/gen/1/#L1'
  end

  test "search by address understands long dashes" do
    get '/ru/search', params: { t: 'Быт. 1:1–3' }
    assert_redirected_to '/ru/ru/gen/1/#L1-3'
  end

  test "full text search finds a verse" do
    create_verse(line: 5, text: 'И увидел Бог свет, что он хорош.')
    get '/ru/search', params: { t: 'свет хорош', l: 'ru' }
    assert_response :success
    assert_includes response.body, 'увидел Бог свет'
  end

  test "empty search renders the form" do
    get '/ru/search'
    assert_response :success
  end

  test "search with no matches renders" do
    get '/ru/search', params: { t: 'слово которого нет нигде', l: 'ru' }
    assert_response :success
  end

  # --- кто цитирует стих ---

  test "citations fragment lists authors with snippets" do
    author = create_page(title: 'Иоанн Златоуст', is_past: true, is_published: true)
    work = create_page(title: 'Беседа 1', is_past: true, is_published: true, parent_id: author.id)
    BibleReference.create!(page_id: work.id, author_page_id: author.id, lang: 'ru', book_code: 'gen', chapter: 1,
                           verse_start: 1, verse_end: 2, position_in_page: 0, snippet: 'Сказано: в начале сотворил Бог', digest: 'd1')
    get '/ru/ru/citations/gen/1/2'
    assert_response :success
    assert_includes response.body, 'Иоанн Златоуст'
    assert_includes response.body, 'Беседа 1'
    assert_includes response.body, 'в начале сотворил Бог'
  end

  test "citations fragment for a verse nobody cites is empty but successful" do
    get '/ru/ru/citations/gen/1/9'
    assert_response :success
  end

  # --- правка стихов (админ) ---

  test "verse update requires an admin" do
    verse = create_verse
    patch "/ru/ru/verses/#{verse.id}", params: { verse: { text: 'x' } }
    assert_response :see_other
    assert_equal 'В начале сотворил Бог небо и землю.', verse.reload.text
  end

  test "admin can update verse text" do
    verse = create_verse
    sign_in(create_user(is_admin: true))
    patch "/ru/ru/verses/#{verse.id}", params: { verse: { text: 'Новый текст' } }
    assert_response :success
    assert_equal 'Новый текст', JSON.parse(response.body)['text']
    assert_equal 'Новый текст', verse.reload.text
  end

  test "admin cannot save an empty verse text" do
    verse = create_verse
    sign_in(create_user(is_admin: true))
    patch "/ru/ru/verses/#{verse.id}", params: { verse: { text: '' } }
    assert_response :unprocessable_entity
  end

  test "interlinear word is saved into the verse data and the verse is marked checked" do
    verse = create_verse(tr_code: 'gr-ru', lang: 'gr', data: { 'w' => %w[Ἐν ἀρχῇ] })
    sign_in(create_user(is_admin: true))

    patch "/ru/ru/verses/#{verse.id}/update_interlinear_word", params: { word_index: 1, word: ' в начале ' }
    assert_response :success

    data = verse.reload.data
    assert_equal 'в начале', data['wi'][1]['trl']['ru']
    assert_equal 'Ἐν', data['wi'][0]['raw']
    assert_equal 1, data['ok_ru']
  end

  test "interlinear word with a wrong index is rejected when the verse already has an interlinear" do
    verse = create_verse(tr_code: 'gr-ru', lang: 'gr', data: { 'w' => ['a'], 'wi' => [{ 'raw' => 'a', 'trl' => {} }] })
    sign_in(create_user(is_admin: true))
    patch "/ru/ru/verses/#{verse.id}/update_interlinear_word", params: { word_index: 5, word: 'x' }
    assert_response :unprocessable_entity
  end
end

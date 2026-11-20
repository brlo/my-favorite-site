require 'test_helper'

class ReadingsControllerTest < ActionDispatch::IntegrationTest
  CHROME_UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36'
  GPTBOT_UA = 'Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; GPTBot/1.4; +https://openai.com/gptbot)'

  setup { clean_reading }
  teardown { clean_reading }

  test 'heartbeat с валидным токеном отмечает чтение' do
    post '/reading', params: {page_id: 42, t: PageVisits.visit_token(42)},
                     headers: {'HTTP_USER_AGENT' => CHROME_UA}

    assert_response :ok
    assert_equal [[42, 1]], PageVisits.reading_now.pages
  end

  test 'heartbeat с чужим токеном отклоняется' do
    post '/reading', params: {page_id: 42, t: 'forged'},
                     headers: {'HTTP_USER_AGENT' => CHROME_UA}

    assert_response :unprocessable_entity
    assert_empty PageVisits.reading_now.pages
  end

  test 'бот не попадает в «Читают сейчас»' do
    post '/reading', params: {page_id: 42, t: PageVisits.visit_token(42)},
                     headers: {'HTTP_USER_AGENT' => GPTBOT_UA}

    assert_response :ok
    assert_empty PageVisits.reading_now.pages
  end

  test 'сигнал leave снимает отметку чтения' do
    post '/reading', params: {page_id: 42, t: PageVisits.visit_token(42)},
                     headers: {'HTTP_USER_AGENT' => CHROME_UA}
    assert_equal [[42, 1]], PageVisits.reading_now.pages

    post '/reading', params: {page_id: 42, t: PageVisits.visit_token(42), leave: '1'},
                     headers: {'HTTP_USER_AGENT' => CHROME_UA}
    assert_response :ok
    assert_empty PageVisits.reading_now.pages
  end

  test 'heartbeat главы Библии отмечает книгу без главы' do
    post '/reading', params: {book: 'gen', t: PageVisits.bible_visit_token('gen')},
                     headers: {'HTTP_USER_AGENT' => CHROME_UA}

    assert_response :ok
    reading = PageVisits.reading_now
    assert_equal [['gen', 1]], reading.bibles
    assert_empty reading.pages
  end

  test 'heartbeat Библии с чужим токеном отклоняется' do
    post '/reading', params: {book: 'gen', t: PageVisits.visit_token(0)},
                     headers: {'HTTP_USER_AGENT' => CHROME_UA}

    assert_response :unprocessable_entity
    assert_empty PageVisits.reading_now.bibles
  end

  test 'leave снимает отметку чтения книги' do
    post '/reading', params: {book: 'gen', t: PageVisits.bible_visit_token('gen')},
                     headers: {'HTTP_USER_AGENT' => CHROME_UA}
    assert_equal [['gen', 1]], PageVisits.reading_now.bibles

    post '/reading', params: {book: 'gen', t: PageVisits.bible_visit_token('gen'), leave: '1'},
                     headers: {'HTTP_USER_AGENT' => CHROME_UA}
    assert_response :ok
    assert_empty PageVisits.reading_now.bibles
  end

  private

  def clean_reading
    ::RedisConnectionPool.del(::PageVisits::READING_KEY)
  end
end

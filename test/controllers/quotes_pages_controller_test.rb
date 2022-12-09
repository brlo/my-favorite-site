require "test_helper"

class QuotesPagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @quotes_page = quotes_pages(:one)
  end

  test "should get index" do
    get quotes_pages_url
    assert_response :success
  end

  test "should get new" do
    get new_quotes_page_url
    assert_response :success
  end

  test "should create quotes_page" do
    assert_difference("QuotesPage.count") do
      post quotes_pages_url, params: { quotes_page: { body: @quotes_page.body, lang: @quotes_page.lang, s_id: @quotes_page.s_id, title: @quotes_page.title } }
    end

    assert_redirected_to quotes_page_url(QuotesPage.last)
  end

  test "should show quotes_page" do
    get quotes_page_url(@quotes_page)
    assert_response :success
  end

  test "should get edit" do
    get edit_quotes_page_url(@quotes_page)
    assert_response :success
  end

  test "should update quotes_page" do
    patch quotes_page_url(@quotes_page), params: { quotes_page: { body: @quotes_page.body, lang: @quotes_page.lang, s_id: @quotes_page.s_id, title: @quotes_page.title } }
    assert_redirected_to quotes_page_url(@quotes_page)
  end

  test "should destroy quotes_page" do
    assert_difference("QuotesPage.count", -1) do
      delete quotes_page_url(@quotes_page)
    end

    assert_redirected_to quotes_pages_url
  end
end

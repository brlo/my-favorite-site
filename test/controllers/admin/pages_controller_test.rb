require 'test_helper'

class Admin::PagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create_user(is_admin: true)
    @page = create_page(body: '<p>Текст статьи</p>')
  end

  test 'в редакторе текста статьи есть кнопка места деления' do
    sign_in(@admin)
    get "/admin/pages/#{@page.id}/edit"

    assert_response :success
    assert_select '.editor-body button.tiptap-cut-btn[data-action="tiptap#toggleArticleCut"]'
    # расширение редактора подключается через importmap
    assert_includes response.body, 'tiptap/article_cut'
  end

  test 'в редакторе примечаний кнопки места деления нет' do
    sign_in(@admin)
    get "/admin/pages/#{@page.id}/edit"

    assert_select '.editor-body button.tiptap-cut-btn', count: 1
    assert_select '.editor-refs button.tiptap-cut-btn', count: 0
  end

  test 'флаг новостной ленты есть в форме и применяется ко всем переводам' do
    en = create_page(lang: 'en', group_lang_id: @page.group_lang_id)

    sign_in(@admin)
    get "/admin/pages/#{@page.id}/edit"
    assert_select 'input#page_is_news[type="checkbox"]'
    assert_select 'label[for="page_is_news"]', text: 'В новостной ленте'

    patch "/admin/pages/#{@page.id}", params: {page: {is_news: '1'}}

    assert_redirected_to edit_admin_page_path(@page)
    assert @page.reload.is_news
    assert en.reload.is_news
  end
end

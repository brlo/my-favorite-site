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
end

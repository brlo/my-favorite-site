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

class Admin::PagesOwnerMenuTitleTest < ActionDispatch::IntegrationTest
  setup do
    @owner = create_user(privs: {'pages_create' => true, 'pages_read' => true})
    @author = create_page(title: 'Автор', path: 'author_title_page', page_type: 4,
                          body: '<p>' + 'Текст страницы. ' * 10 + '</p>', is_published: true)
    @owner.update!(pages_owner: [@author.id])
    @article = create_page(title: 'Старое название', parent_id: @author.id, lang: 'ru',
                           path: 'article_title_page', is_published: true)
    @menu = ::Menu.create!(page_id: @author.id, title: 'Старое название', path: @article.path, priority: 0)
  end

  test 'переименование статьи в редакторе обновляет пункт меню автора' do
    sign_in(@owner)
    patch "/admin/pages/#{@article.id}", params: {page: {title: 'Новое название'}}

    assert_response :redirect
    assert_equal 'Новое название', @menu.reload.title
    assert_equal 'Новое название', @article.reload.title
  end
end

class Admin::PagesOwnerAuthorPageTitleTest < ActionDispatch::IntegrationTest
  setup do
    @owner = create_user(privs: {'pages_create' => true, 'pages_read' => true})
    @authors = create_page(title: 'Авторские публикации', path: 'authors_title_section', page_type: 4,
                           body: '<p>' + 'Текст раздела. ' * 10 + '</p>', is_published: true)
    @author_page = create_page(title: 'Старое имя', parent_id: @authors.id, page_type: 4,
                               body: '<p>' + 'Текст автора. ' * 10 + '</p>', is_published: true)
    @owner.update!(pages_owner: [@author_page.id])
    @menu = ::Menu.create!(page_id: @authors.id, title: 'Старое имя', path: @author_page.path, priority: 0)
  end

  test 'автор может переименовать свою страницу в редакторе, пункт меню обновится' do
    sign_in(@owner)
    patch "/admin/pages/#{@author_page.id}", params: {page: {title: 'Новое имя'}}

    assert_equal 'Новое имя', @menu.reload.title
    assert_equal 'Новое имя', @author_page.reload.title
  end
end

class Admin::PagesAdminAuthorPageTest < ActionDispatch::IntegrationTest
  test 'админ видит Готово на статье под авторской страницей' do
    admin = create_user(is_admin: true)
    author_page = create_page(title: 'Моя страница', path: 'admin_author_page_edit', page_type: 4,
                              seo_kind: 'person', user_id: admin.id,
                              body: '<p>' + 'Текст страницы. ' * 10 + '</p>', is_published: true)
    article = create_page(title: 'Статья', parent_id: author_page.id, lang: 'ru',
                          body: '<p>' + 'Текст статьи. ' * 10 + '</p>', is_published: true)
    sign_in(admin)

    get "/admin/pages/#{article.id}/edit"

    assert_response :success
    assert_select 'button[name="return_to"][value="parent"]', text: 'Готово', minimum: 1
    assert_select 'input[type="submit"][value="Сохранить"]', count: 0
    assert_select 'button', text: 'Сохранить', count: 0
    assert_select '.crumbs a', text: '← К странице автора'
  end
end

class Admin::PagesMenuEditorRemovedTest < ActionDispatch::IntegrationTest
  test 'в редакторе страницы больше нет блока меню' do
    admin = create_user(is_admin: true)
    list = create_page(page_type: 4, body: '<p>' + 'Текст. ' * 10 + '</p>')
    sign_in(admin)

    get "/admin/pages/#{list.id}/edit"

    assert_response :success
    assert_select '#page_menu', count: 0
    assert_select '.menu-editor', count: 0
    assert_select '.author-menu-callout', text: /настраивается прямо на странице/
  end
end

require 'test_helper'

class AuthorInlineMenuTest < ActionDispatch::IntegrationTest
  LONG_BODY = '<p>' + 'Достаточно длинный текст авторской страницы. ' * 3 + '</p>'

  setup do
    @owner = create_user(privs: {'pages_create' => true, 'pages_read' => true})
    @author = create_page(title: 'Автор', path: 'inline_author_page', page_type: 4,
                          body: LONG_BODY, is_published: true)
    @owner.update!(pages_owner: [@author.id])
    @article = create_page(title: 'Статья', parent_id: @author.id, lang: 'ru',
                           path: 'inline_article_page', is_published: true)
    @menu = ::Menu.create!(page_id: @author.id, title: 'Статья', path: @article.path, priority: 0)
  end

  def public_path
    '/ru/ru/w/inline_author_page'
  end

  test 'хозяин видит кнопку редактирования меню прямо на странице' do
    sign_in(@owner)
    get public_path

    assert_response :success
    assert_select '.author-menu-edit-bar', count: 1
    assert_select '.author-menu-edit-btn', text: /Редактировать меню на странице/
    assert_select '.menu-tree[data-menu-filter-target="tree"]', count: 1
    assert_select '.author-menu-inline', count: 0

    # ссылка «Редактировать страницу» идёт перед кнопкой «Новая статья»
    actions = css_select('.author-menu-edit-actions').first.to_s
    assert_operator actions.index('author-menu-edit-link'), :<, actions.index('<button')
  end

  test 'режим редактирования меню открывается на месте публичного меню' do
    sign_in(@owner)
    get public_path, params: {author_menu: 'edit'}

    assert_response :success
    assert_select '.author-menu-inline', count: 1
    assert_select 'turbo-frame#author_menu_inline', count: 1
    assert_select '.author-menu-inline .aw-tree', count: 1
    assert_select '.author-menu-inline .aw-title', text: 'Статья'
    assert_includes response.body, 'Режим редактирования меню'
    assert_select '.author-menu-inline .aw-head a', text: 'Готово'
    assert_select '.menu-tree[data-menu-filter-target="tree"]', count: 0
    assert_select '.author-menu-edit-bar', count: 0
    assert_select 'a[href*="mode=inline"]', minimum: 1
    assert_select 'form[action*="mode=inline"]', minimum: 1
  end

  test 'обычный читатель не видит ни кнопку, ни режим редактирования' do
    get public_path, params: {author_menu: 'edit'}

    assert_response :success
    assert_select '.author-menu-edit-bar', count: 0
    assert_select '.author-menu-inline', count: 0
    assert_select '.menu-tree[data-menu-filter-target="tree"]', count: 1
  end

  test 'создание раздела в режиме на странице обновляет inline-рамку' do
    sign_in(@owner)

    post admin_author_items_path(@author, mode: 'inline'),
         params: {title: 'Новый раздел', kind: 'section'}

    assert_response :success
    assert_select 'turbo-stream[action="replace"][target="author_menu_inline"]'
    assert_select 'turbo-stream[action="replace"][target="author_workspace"]', count: 0
    assert_includes response.body, 'Новый раздел'
  end
end

class AuthorInlineMenuCreateOnlyTest < ActionDispatch::IntegrationTest
  LONG_BODY = '<p>' + 'Достаточно длинный текст авторской страницы. ' * 3 + '</p>'

  setup do
    @owner = create_user(privs: {'pages_create' => true, 'pages_read' => true})
    @author = create_page(title: 'Автор', path: 'create_only_author_page', page_type: 4,
                          body: LONG_BODY, is_published: true)
    @owner.update!(pages_owner: [@author.id])
    @article = create_page(title: 'Статья', parent_id: @author.id, lang: 'ru',
                           path: 'create_only_article', is_published: true)
    ::Menu.create!(page_id: @author.id, title: 'Статья', path: @article.path, priority: 0)
  end

  test 'кнопка Новая статья открывает только форму создания, без меню' do
    sign_in(@owner)
    get "/admin/author/#{@author.id}", params: {create: '1'}, headers: {'Turbo-Frame' => 'author_workspace'}

    assert_response :success
    assert_select 'turbo-frame#author_workspace'
    assert_select '.aw-tree', count: 0
    assert_select '.aw-create', count: 1
    assert_select 'input[name="title"]'
    assert_select 'select[name="parent_id"]', count: 1
    assert_select '.aw-section-create', count: 0
    assert_includes response.body, 'Новая статья'
  end

  test 'на странице автора больше нет кнопки Настроить меню' do
    sign_in(@owner)
    get '/ru/ru/w/create_only_author_page'

    assert_response :success
    assert_select '.author-menu-edit-bar', count: 1
    assert_select 'button.author-menu-edit-btn', text: /Новая статья/
    assert_select 'button', text: /Настроить меню/, count: 0
  end
end

class AdminInlineMenuOnLibraryPageTest < ActionDispatch::IntegrationTest
  LONG_BODY = '<p>' + 'Достаточно длинный текст раздела. ' * 3 + '</p>'

  test 'админ может включить редактирование меню на обычной странице-списке' do
    admin = create_user(is_admin: true)
    list = create_page(title: 'Раздел библиотеки', path: 'admin_library_list', page_type: 4,
                       body: LONG_BODY, is_published: true)
    sign_in(admin)

    get '/ru/ru/w/admin_library_list'
    assert_response :success
    assert_select '.author-menu-edit-bar', count: 1
    assert_select '.author-hub', count: 0

    get '/ru/ru/w/admin_library_list', params: {author_menu: 'edit'}
    assert_response :success
    assert_select '.author-menu-inline', count: 1
    assert_select 'turbo-frame#author_menu_inline', count: 1
  end
end

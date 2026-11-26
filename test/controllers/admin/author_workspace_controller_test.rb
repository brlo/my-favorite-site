require 'test_helper'

class Admin::AuthorWorkspaceControllerTest < ActionDispatch::IntegrationTest
  LONG_BODY = '<p>' + 'Достаточно длинный текст авторской страницы. ' * 3 + '</p>'

  setup do
    @owner = create_user(privs: {'pages_create' => true, 'pages_read' => true})
    @author = create_page(
      title: 'Автор', path: 'author_page', page_type: 4,
      body: LONG_BODY, is_published: true,
    )
    @owner.update!(pages_owner: [@author.id])
  end

  def frame_headers
    {'Turbo-Frame' => 'author_workspace'}
  end

  def create_menu(title, parent_id: nil, path: nil, priority: 0)
    ::Menu.create!(page_id: @author.id, title:, parent_id:, path:, priority:)
  end

  def create_author_page(title)
    create_page(title:, parent_id: @author.id, lang: @author.lang, is_published: true)
  end

  # --- доступ ---

  test 'кабинет отдаёт содержимое в turbo-frame' do
    sign_in(@owner)
    get "/admin/author/#{@author.id}", headers: frame_headers

    assert_response :success
    assert_select 'turbo-frame#author_workspace'
    assert_includes response.body, 'Мои статьи'
  end

  test 'прямой заход в кабинет возвращает на публичную страницу автора' do
    sign_in(@owner)
    get "/admin/author/#{@author.id}"

    assert_redirected_to '/ru/ru/w/author_page'
  end

  test 'чужой пользователь не может открыть кабинет' do
    stranger = create_user(privs: {'pages_read' => true})
    sign_in(stranger)
    get "/admin/author/#{@author.id}", headers: frame_headers

    assert_redirected_to admin_root_path
  end

  # --- создание ---

  test 'новый раздел создаёт пункт меню без страницы' do
    sign_in(@owner)

    assert_difference -> { ::Menu.count }, 1 do
      post "/admin/author/#{@author.id}/items", params: {title: 'Новый раздел', kind: 'section'}
    end

    assert_response :success
    menu = ::Menu.last
    assert_equal @author.id, menu.page_id
    assert_equal 'Новый раздел', menu.title
    assert_nil menu.path
  end

  test 'существующую статью можно вернуть в меню' do
    sign_in(@owner)
    page = create_author_page('Возвращаемая')

    assert_difference -> { ::Menu.count }, 1 do
      post "/admin/author/#{@author.id}/items/attach", params: {article_page_id: page.id}
    end

    assert_response :success
    menu = ::Menu.order(:id).last
    assert_equal page.path, menu.path
    assert_equal 'Возвращаемая', menu.title
  end

  test 'удалённый из меню пункт можно вернуть на место' do
    sign_in(@owner)
    page = create_author_page('Возврат')
    menu = create_menu('Возврат', path: page.path)

    delete "/admin/author/#{@author.id}/items/#{menu.id}"
    assert ::Page.exists?(page.id)

    assert_no_difference -> { ::Page.count } do
      assert_difference -> { ::Menu.count }, 1 do
        post "/admin/author/#{@author.id}/items/attach", params: {article_page_id: page.id}
      end
    end

    assert_response :success
    assert_equal page.path, ::Menu.order(:id).last.path
  end

  test 'нельзя добавить в меню статью с чужой страницы' do
    sign_in(@owner)
    foreign = create_page(title: 'Чужая', path: 'foreign_attach_check', parent_id: nil, lang: @author.lang)

    assert_no_difference -> { ::Menu.count } do
      post "/admin/author/#{@author.id}/items/attach", params: {article_page_id: foreign.id}
    end

    assert_response :unprocessable_entity
  end

  test 'нельзя добавить одну статью в меню дважды' do
    sign_in(@owner)
    page = create_author_page('Дубликат')
    create_menu('Дубликат', path: page.path)

    assert_no_difference -> { ::Menu.count } do
      post "/admin/author/#{@author.id}/items/attach", params: {article_page_id: page.id}
    end

    assert_response :unprocessable_entity
  end

  test 'новая статья создаёт страницу, пункт меню и ведёт в редактор' do
    sign_in(@owner)

    assert_difference -> { ::Page.count }, 1 do
      assert_difference -> { ::Menu.count }, 1 do
        post "/admin/author/#{@author.id}/items", params: {title: 'Моя новая статья'}
      end
    end

    page = ::Page.order(:id).last
    menu = ::Menu.order(:id).last
    assert_equal @author.id, page.parent_id
    assert_equal @author.lang, page.lang
    assert_equal @owner.id, page.user_id
    assert_equal page.path, menu.path
    assert_redirected_to edit_admin_page_path(page, welcome: 'author')
  end

  test 'статью можно сразу вложить в выбранный раздел' do
    sign_in(@owner)
    section = create_menu('Раздел')

    post "/admin/author/#{@author.id}/items", params: {title: 'Внутри раздела', parent_id: section.id}

    assert_equal section.id, ::Menu.order(:id).last.parent_id
  end

  test 'для старого пункта без статьи можно создать статью с тем же адресом' do
    sign_in(@owner)
    menu = create_menu('Старое название', path: 'old_missing_page')

    assert_difference -> { ::Page.count }, 1 do
      post "/admin/author/#{@author.id}/items/#{menu.id}/page"
    end

    page = ::Page.order(:id).last
    assert_equal 'old_missing_page', page.path
    assert_equal @author.id, page.parent_id
    assert_equal page.path, menu.reload.path
  end

  # --- порядок и вложенность ---

  test 'кнопка выше меняет порядок пунктов' do
    sign_in(@owner)
    first = create_menu('Первый', priority: 0)
    second = create_menu('Второй', priority: 1)
    third = create_menu('Третий', priority: 2)

    patch "/admin/author/#{@author.id}/items/#{second.id}/move", params: {direction: 'up'}

    assert_response :success
    assert_equal %w[Второй Первый Третий],
                 ::Menu.where(page_id: @author.id).order(:priority, :id).pluck(:title)
    assert_equal [0, 1, 2], ::Menu.where(page_id: @author.id).pluck(:priority).sort
  end

  test 'пункт можно вложить в предыдущий и вынести обратно' do
    sign_in(@owner)
    first = create_menu('Первый', priority: 0)
    second = create_menu('Второй', priority: 1)

    patch "/admin/author/#{@author.id}/items/#{second.id}/move", params: {direction: 'in'}
    assert_equal first.id, second.reload.parent_id

    patch "/admin/author/#{@author.id}/items/#{second.id}/move", params: {direction: 'out'}
    assert_nil second.reload.parent_id
    assert_equal %w[Первый Второй],
                 ::Menu.where(page_id: @author.id).order(:priority, :id).pluck(:title)
  end

  test 'перетаскивание ставит пункт перед или после указанного' do
    sign_in(@owner)
    first = create_menu('Первый', priority: 0)
    second = create_menu('Второй', priority: 1)
    third = create_menu('Третий', priority: 2)

    patch "/admin/author/#{@author.id}/items/#{third.id}/move",
          params: {target_id: first.id, position: 'before'}

    assert_equal %w[Третий Первый Второй],
                 ::Menu.where(page_id: @author.id).order(:priority, :id).pluck(:title)
  end

  test 'нельзя вложить раздел в собственный подпункт' do
    sign_in(@owner)
    parent = create_menu('Родитель', priority: 0)
    child = create_menu('Ребёнок', parent_id: parent.id, priority: 0)

    patch "/admin/author/#{@author.id}/items/#{parent.id}/move",
          params: {target_id: child.id, position: 'after'}

    assert_response :unprocessable_entity
    assert_nil parent.reload.parent_id
  end

  # --- переименование и удаление ---

  test 'переименование меняет название пункта меню и статьи' do
    sign_in(@owner)
    page = create_author_page('Старое имя')
    menu = create_menu('Старое имя', path: page.path)

    patch "/admin/author/#{@author.id}/items/#{menu.id}", params: {title: 'Новое имя'}

    assert_response :success
    assert_equal 'Новое имя', menu.reload.title
    assert_equal 'Новое имя', page.reload.title
  end

  test 'удаление пункта из меню оставляет статью на сайте' do
    sign_in(@owner)
    page = create_author_page('Остаётся')
    menu = create_menu('Остаётся', path: page.path)

    assert_no_difference -> { ::Page.count } do
      assert_difference -> { ::Menu.count }, -1 do
        delete "/admin/author/#{@author.id}/items/#{menu.id}"
      end
    end

    assert_response :success
    assert ::Page.exists?(page.id)
  end

  test 'удаление статьи удаляет и страницу, и пункт меню' do
    sign_in(@owner)
    page = create_author_page('Удаляемая')
    menu = create_menu('Удаляемая', path: page.path)

    assert_difference -> { ::Page.count }, -1 do
      assert_difference -> { ::Menu.count }, -1 do
        delete "/admin/author/#{@author.id}/items/#{menu.id}/page"
      end
    end

    assert_response :success
    assert_not ::Page.exists?(page.id)
  end

  test 'нельзя удалить статью, у которой есть вложенные страницы' do
    sign_in(@owner)
    page = create_author_page('Родитель')
    menu = create_menu('Родитель', path: page.path)
    create_page(title: 'Вложенная', parent_id: page.id, path: 'nested_destroy_check')

    assert_no_difference -> { ::Page.count } do
      assert_no_difference -> { ::Menu.count } do
        delete "/admin/author/#{@author.id}/items/#{menu.id}/page"
      end
    end

    assert_response :unprocessable_entity
    assert ::Page.exists?(page.id)
  end

  test 'пункт с подпунктами удалить нельзя' do
    sign_in(@owner)
    parent = create_menu('Раздел')
    create_menu('Подпункт', parent_id: parent.id)

    assert_no_difference -> { ::Menu.count } do
      delete "/admin/author/#{@author.id}/items/#{parent.id}"
    end

    assert_response :unprocessable_entity
  end

  # --- панель на публичной странице ---

  test 'хозяин видит панель меню на своей публичной странице' do
    sign_in(@owner)
    get '/ru/ru/w/author_page'

    assert_response :success
    assert_select '.author-menu-edit-bar', count: 1
    assert_select 'turbo-frame#author_workspace', count: 1
    assert_select 'button.author-menu-edit-btn', text: /Новая статья/
    assert_includes response.body, 'Редактировать меню на странице'
  end

  test 'обычный читатель не видит панель меню' do
    get '/ru/ru/w/author_page'

    assert_select '.author-menu-edit-bar', count: 0
  end

  test 'админ на чужой обычной странице-списке видит только редактирование меню' do
    admin = create_user(is_admin: true)
    sign_in(admin)
    get '/ru/ru/w/author_page'

    assert_select '.author-menu-edit-bar', count: 1
    assert_select 'button.author-menu-edit-btn', count: 0
    assert_includes response.body, 'Редактировать меню на странице'
  end
end

class Admin::AuthorWorkspaceRenderingTest < ActionDispatch::IntegrationTest
  LONG_BODY = '<p>' + 'Достаточно длинный текст авторской страницы. ' * 3 + '</p>'

  setup do
    @owner = create_user(privs: {'pages_create' => true, 'pages_read' => true})
    @author = create_page(title: 'Автор', path: 'author_page_render', page_type: 4,
                          body: LONG_BODY, is_published: true)
    @owner.update!(pages_owner: [@author.id])
    @article = create_page(title: 'Статья', parent_id: @author.id, lang: 'ru', is_published: true,
                           path: 'author_article_render')
    @section = ::Menu.create!(page_id: @author.id, title: 'Раздел', priority: 0)
    @menu = ::Menu.create!(page_id: @author.id, title: 'Статья', path: @article.path, priority: 1)
    @unlinked = create_page(title: 'Свободная', parent_id: @author.id, lang: @author.lang,
                            path: 'author_free_article', is_published: true)
  end

  test 'кабинет показывает статьи, разделы и кнопки управления' do
    sign_in(@owner)
    get "/admin/author/#{@author.id}", headers: {'Turbo-Frame' => 'author_workspace'}

    assert_response :success
    assert_select '.aw-row', count: 2
    assert_select '.aw-title', text: 'Статья'
    assert_select '.aw-badge-section', text: 'раздел'
    assert_select 'a[href="/admin/pages/%d/edit"][data-turbo-frame="_top"]' % @article.id
    assert_select 'form[action="/admin/author/%d/items/%d"][method="post"]' % [@author.id, @menu.id]
    assert_select 'button[name="return_to"]', count: 0
  end

  test 'в форме раздела название идёт перед выбором родителя' do
    sign_in(@owner)
    get "/admin/author/#{@author.id}", headers: {'Turbo-Frame' => 'author_workspace'}

    form = Nokogiri::HTML(response.body).at_css('.aw-section-create form')
    html = form.to_html
    assert_operator html.index('name="title"'), :<, html.index('name="parent_id"')
  end

  test 'в редакторе можно вернуть в меню существующую статью' do
    sign_in(@owner)
    get "/admin/author/#{@author.id}", headers: {'Turbo-Frame' => 'author_workspace'}

    assert_response :success
    assert_select '.aw-attach-existing', minimum: 1
    assert_select 'select[name="article_page_id"] option', text: /Свободная/
  end

  test 'в меню отдельно убрать из меню и отдельно удалить статью' do
    sign_in(@owner)
    get "/admin/author/#{@author.id}", headers: {'Turbo-Frame' => 'author_workspace'}

    assert_response :success
    assert_select 'a[title*="Убрать из меню"]', minimum: 1
    assert_select '.aw-danger-zone', count: 1
    assert_select '.aw-danger-zone a', text: /Удалить статью навсегда/
    assert_select "a[href='/admin/author/#{@author.id}/items/#{@menu.id}/page'][data-turbo-method='delete']"
  end

  test 'в редакторе статьи автора есть кнопка Готово с возвратом на страницу' do
    sign_in(@owner)
    get "/admin/pages/#{@article.id}/edit"

    assert_response :success
    assert_select 'button[name="return_to"][value="parent"]', text: 'Готово', minimum: 1
  end

  test 'Готово сохраняет статью и возвращает на страницу автора' do
    sign_in(@owner)
    patch "/admin/pages/#{@article.id}", params: {page: {title: 'Статья'}, return_to: 'parent'}

    assert_redirected_to '/ru/ru/w/author_page_render'
  end

  test 'после создания статьи автор видит подсказку в редакторе' do
    sign_in(@owner)
    get "/admin/pages/#{@article.id}/edit", params: {welcome: 'author'}

    assert_select '.author-editor-welcome', count: 1
  end
end

class Admin::AuthorWorkspaceOrderTest < ActionDispatch::IntegrationTest
  setup do
    @owner = create_user(privs: {'pages_create' => true, 'pages_read' => true})
    @author = create_page(title: 'Автор', path: 'author_order_page', page_type: 4,
                          body: '<p>' + 'Текст страницы. ' * 10 + '</p>', is_published: true)
    @owner.update!(pages_owner: [@author.id])
  end

  test 'раздел можно переставить выше статьи, и это меняет публичное меню' do
    sign_in(@owner)
    section = ::Menu.create!(page_id: @author.id, title: 'Раздел', priority: 0)
    ::Menu.create!(page_id: @author.id, title: 'Внутри', parent_id: section.id, priority: 0)
    ::Menu.create!(page_id: @author.id, title: 'Статья', priority: 5)

    # до правки: сначала пункт без подпунктов, потом раздел
    assert_equal %w[Статья Раздел], @author.tree_menu.map { _1[:title] }

    patch "/admin/author/#{@author.id}/items/#{section.id}/move", params: {direction: 'up'}

    assert_response :success
    assert_equal %w[Раздел Статья], @author.reload.tree_menu.map { _1[:title] }
    assert_not_nil section.reload.position
  end
end

class Admin::AuthorWorkspaceFeedbackTest < ActionDispatch::IntegrationTest
  setup do
    @owner = create_user(privs: {'pages_create' => true, 'pages_read' => true})
    @author = create_page(title: 'Автор', path: 'author_feedback_page', page_type: 4,
                          body: '<p>' + 'Текст страницы. ' * 10 + '</p>', is_published: true)
    @owner.update!(pages_owner: [@author.id])
  end

  test 'сообщение об успехе видно внутри окна кабинета' do
    sign_in(@owner)
    post "/admin/author/#{@author.id}/items", params: {title: 'Новый раздел', kind: 'section'}

    assert_response :success
    assert_select 'turbo-stream[action="append"][target="author_workspace_flash"]'
    assert_includes response.body, 'Новый раздел'
  end

  test 'ошибка видна внутри окна кабинета' do
    sign_in(@owner)
    post "/admin/author/#{@author.id}/items", params: {title: '  ', kind: 'section'}

    assert_response :unprocessable_entity
    assert_select 'turbo-stream[action="append"][target="author_workspace_flash"]'
    assert_includes response.body, 'Введите название'
  end
end

class Admin::AuthorWorkspaceMoveByEditTest < ActionDispatch::IntegrationTest
  setup do
    @owner = create_user(privs: {'pages_create' => true, 'pages_read' => true})
    @author = create_page(title: 'Автор', path: 'author_move_page', page_type: 4,
                          body: '<p>' + 'Текст страницы. ' * 10 + '</p>', is_published: true)
    @owner.update!(pages_owner: [@author.id])
  end

  test 'в форме переименования можно сразу перенести пункт в другой раздел' do
    sign_in(@owner)
    section = ::Menu.create!(page_id: @author.id, title: 'Раздел', priority: 0)
    item = ::Menu.create!(page_id: @author.id, title: 'Пункт', priority: 1)

    patch "/admin/author/#{@author.id}/items/#{item.id}", params: {title: 'Пункт', parent_id: section.id}

    assert_response :success
    assert_equal section.id, item.reload.parent_id
    assert_not_nil item.position
  end

  test 'нельзя перенести пункт в собственный подпункт' do
    sign_in(@owner)
    item = ::Menu.create!(page_id: @author.id, title: 'Родитель', priority: 0)
    child = ::Menu.create!(page_id: @author.id, title: 'Ребёнок', parent_id: item.id, priority: 0)

    patch "/admin/author/#{@author.id}/items/#{item.id}", params: {title: 'Родитель', parent_id: child.id}

    assert_response :unprocessable_entity
    assert_nil item.reload.parent_id
  end
end

class Admin::AuthorWorkspaceAdminOwnPageTest < ActionDispatch::IntegrationTest
  LONG_BODY = '<p>' + 'Достаточно длинный текст авторской страницы. ' * 3 + '</p>'

  test 'админ видит панель меню на собственной авторской странице без параметра' do
    admin = create_user(is_admin: true)
    page = create_page(title: 'Моя страница', path: 'admin_own_author_page', page_type: 4,
                       seo_kind: 'person', user_id: admin.id, body: LONG_BODY, is_published: true)
    sign_in(admin)

    get "/ru/ru/w/#{page.path}"

    assert_response :success
    assert_select '.author-menu-edit-bar', count: 1
    assert_select 'button.author-menu-edit-btn', text: /Новая статья/
  end

  test 'админ видит панель меню на чужой авторской странице' do
    admin = create_user(is_admin: true)
    author = create_user
    page = create_page(title: 'Чужая страница', path: 'admin_other_author_page', page_type: 4,
                       seo_kind: 'person', user_id: author.id, body: LONG_BODY, is_published: true)
    sign_in(admin)

    get "/ru/ru/w/#{page.path}"

    assert_response :success
    assert_select '.author-menu-edit-bar', count: 1
    assert_select 'button.author-menu-edit-btn', text: /Новая статья/
  end
end

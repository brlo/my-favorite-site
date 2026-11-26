require 'test_helper'

class Admin::UsersAuthorPageTest < ActionDispatch::IntegrationTest
  LONG_BODY = '<p>' + 'Текст раздела авторов. ' * 5 + '</p>'

  setup do
    @admin = create_user(is_admin: true)
    @user = create_user(name: 'Новый Автор')
    @authors = create_page(title: 'Авторские публикации', path: 'authors', page_type: 4,
                           body: LONG_BODY, is_published: true)
    sign_in(@admin)
  end

  test 'админ создаёт авторскую страницу и пользователь получает кабинет' do
    assert_difference -> { ::Page.count }, 1 do
      assert_difference -> { ::Menu.count }, 1 do
        post create_author_page_admin_user_path(@user), params: {title: 'Новый Автор', lang: 'ru', parent_id: @authors.id}
      end
    end

    assert_redirected_to edit_admin_user_path(@user)
    page = ::Page.order(:id).last
    menu = ::Menu.order(:id).last

    assert_equal 'Новый Автор', page.title
    assert_equal 4, page.page_type
    assert_equal 'person', page.seo_kind
    assert_equal @authors.id, page.parent_id
    assert_equal @admin.id, page.user_id
    assert page.is_published
    assert_includes page.body, 'Страница автора'

    assert_equal @authors.id, menu.page_id
    assert_equal page.path, menu.path
    assert_equal page.title, menu.title

    @user.reload
    assert_includes @user.pages_owner, page.id
    assert_equal true, @user.privs.to_h['pages_create']
  end

  test 'новая авторская страница добавляется в конец меню раздела' do
    ::Menu.create!(page_id: @authors.id, title: 'Старый автор', priority: 0)

    post create_author_page_admin_user_path(@user), params: {title: 'Новый Автор', parent_id: @authors.id}

    titles = ::Menu.where(page_id: @authors.id).order(:position, :id).pluck(:title)
    assert_equal %w[Старый\ автор Новый\ Автор], titles
  end

  test 'по умолчанию страница создаётся в разделе authors' do
    post create_author_page_admin_user_path(@user), params: {title: 'Автор без раздела'}

    page = ::Page.order(:id).last
    assert_equal @authors.id, page.parent_id
  end

  test 'нельзя создать авторскую страницу в обычной статье' do
    article = create_page(page_type: 1, body: LONG_BODY)

    assert_no_difference -> { ::Page.count } do
      post create_author_page_admin_user_path(@user), params: {title: 'Автор', parent_id: article.id}
    end

    assert_redirected_to edit_admin_user_path(@user)
    assert_equal 'Раздел должен быть страницей-списком (например, «Авторские публикации»)', flash[:alert]
  end

  test 'существующую страницу-список можно привязать к пользователю' do
    list = create_page(title: 'Готовая авторская', page_type: 4, body: LONG_BODY)

    assert_no_difference -> { ::Page.count } do
      post attach_author_page_admin_user_path(@user), params: {page_id: list.id}
    end

    @user.reload
    assert_includes @user.pages_owner, list.id
    assert_equal true, @user.privs.to_h['pages_create']
  end

  test 'обычную статью привязать нельзя' do
    article = create_page(page_type: 1, body: LONG_BODY)

    post attach_author_page_admin_user_path(@user), params: {page_id: article.id}

    assert_not_includes @user.reload.pages_owner, article.id
    assert_equal 'Привязать можно только страницу-список', flash[:alert]
  end

  test 'страницу можно отвязать, она остаётся на сайте' do
    @user.update!(pages_owner: [@authors.id])

    assert_no_difference -> { ::Page.count } do
      delete detach_author_page_admin_user_path(@user, page_id: @authors.id)
    end

    assert_not_includes @user.reload.pages_owner, @authors.id
    assert ::Page.exists?(@authors.id)
  end

  test 'ручная правка ID заменяет список и оставляет право создавать статьи' do
    patch update_author_pages_admin_user_path(@user), params: {pages_owner: "#{@authors.id}, #{@authors.id + 1}"}

    @user.reload
    assert_equal [@authors.id, @authors.id + 1], @user.pages_owner
    assert_equal true, @user.privs.to_h['pages_create']
  end

  test 'фильтр авторов и бейдж показывают пользователей с личной страницей' do
    @user.update!(pages_owner: [@authors.id])
    other = create_user(name: 'Без страницы')

    get admin_users_path(filter: 'authors')

    assert_response :success
    assert_includes response.body, @user.name
    assert_not_includes response.body, other.name
    assert_select '.badge.green', text: 'автор', minimum: 1
  end

  test 'в карточке пользователя есть блок авторской страницы' do
    @user.update!(pages_owner: [@authors.id])
    get edit_admin_user_path(@user)

    assert_response :success
    assert_select '.author-page-admin', count: 1
    assert_select '.author-page-list li', count: 1
    assert_select "a[href='/ru/ru/w/authors?author_workspace=1']"
    assert_select "form[action='/admin/users/#{@user.id}/create_author_page']"
    assert_select "form[action='/admin/users/#{@user.id}/attach_author_page']"
    assert_select "form[action='/admin/users/#{@user.id}/update_author_pages']"
    assert_select 'input[name="user[pages_owner]"]', count: 0
    assert_select 'input[name="pages_owner"]'
  end
end

class Admin::UsersAuthorPageNoSectionTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create_user(is_admin: true)
    @user = create_user
    sign_in(@admin)
  end

  test 'без раздела authors и без выбранного раздела страница не создаётся' do
    assert_no_difference -> { ::Page.count } do
      post create_author_page_admin_user_path(@user), params: {title: 'Автор'}
    end

    assert_equal 'Выберите раздел, где появится авторская страница', flash[:alert]
  end
end

class Admin::UsersAuthorPageAccessTest < ActionDispatch::IntegrationTest
  test 'не-админ не может создавать авторские страницы' do
    list = create_page(page_type: 4, body: '<p>' + 'Текст. ' * 10 + '</p>')
    regular = create_user(pages_owner: [list.id])
    other = create_user
    sign_in(regular)

    assert_no_difference -> { ::Page.count } do
      post create_author_page_admin_user_path(other), params: {title: 'Нельзя', parent_id: list.id}
    end

    assert_redirected_to admin_root_path
  end
end

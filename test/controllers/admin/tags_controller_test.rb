require 'test_helper'

class Admin::TagsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create_user(privs: { 'super' => true })
    @tag = Tag.create!(name: 'Молитва')
  end

  test 'список тегов рендерится' do
    sign_in(@admin)
    page = create_page(path: 'adm_tag_page')
    page.sync_tag_list!(['Молитва'])

    get '/admin/tags'
    assert_response :success
    assert_includes response.body, 'Молитва'
    assert_includes response.body, '/tags/molitva'
  end

  test 'редактор тега: имя, слаг и переводы' do
    sign_in(@admin)
    patch "/admin/tags/#{@tag.id}", params: { tag: { name: 'Молитва', slug: 'prayer', names: { 'en' => 'Prayer', 'ja' => '' } } }
    assert_redirected_to admin_tags_path

    @tag.reload
    assert_equal 'prayer', @tag.slug
    assert_equal 'Prayer', @tag.name_for('en')
    # пустой перевод убран — показывается каноническое имя
    assert_not @tag.names.key?('ja')
  end

  test 'пустой slug генерируется из имени' do
    sign_in(@admin)
    patch "/admin/tags/#{@tag.id}", params: { tag: { name: 'Покаяние', slug: '', names: {} } }
    @tag.reload
    assert_equal 'pokayanie', @tag.slug
  end

  test 'редактор статей без tags_manage не попадает в управление тегами' do
    editor = create_user(privs: { 'pages_read' => true })
    sign_in(editor)

    get '/admin/tags'
    assert_redirected_to admin_root_path
  end

  test 'удаление тега убирает и связи со статьями' do
    sign_in(@admin)
    page = create_page(path: 'adm_tag_page2')
    page.sync_tag_list!(['Молитва'])

    delete "/admin/tags/#{@tag.id}"
    assert_redirected_to admin_tags_path

    assert_not Tag.exists?(@tag.id)
    assert_equal 0, Tagging.count
    assert_equal [], page.reload.tag_list
  end

  test 'теги статьи назначаются из формы статьи' do
    editor = create_user(privs: { 'pages_read' => true, 'pages_update' => true })
    page = create_page(path: 'adm_tag_form', title: 'Форма тегов', edit_mode: 2)
    sign_in(editor)

    patch "/admin/pages/#{page.id}", params: { page: { title: 'Форма тегов', tag_names: ['Новый тег', '  '] } }
    assert_redirected_to edit_admin_page_path(page)

    assert_equal ['Новый тег'], page.reload.tag_list
  end

  test 'форма статьи содержит поле тегов с уже назначенными' do
    # edit_mode «Модераторы»: супер-привилегия открывает pages_update
    page = create_page(path: 'adm_tag_field', title: 'Поле тегов', edit_mode: 2)
    page.sync_tag_list!(['Молитва'])
    sign_in(@admin)

    get "/admin/pages/#{page.id}/edit"
    assert_response :success
    assert_select "input[name='page[tag_names][]'][value=?]", 'Молитва', count: 1
    assert_includes response.body, 'admin/autocomplete/tags'
  end
end

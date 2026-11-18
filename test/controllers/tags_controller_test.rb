require 'test_helper'

class TagsControllerTest < ActionDispatch::IntegrationTest
  LONG_BODY = '<p>' + 'Достаточно длинный текст страницы. ' * 3 + '</p>'

  setup do
    @tag = Tag.create!(name: 'Молитва')
    @page = create_page(is_published: true, title: 'О молитве', path: 'o_molitve_test', body: LONG_BODY)
    @page.sync_tag_list!(['Молитва'])
  end

  test 'каталог тегов показывает теги с опубликованными статьями языка локали' do
    get '/ru/tags'
    assert_response :success
    assert_select 'a.tag-chip', text: /Молитва/, count: 1
    assert_select 'a.tag-chip .tag-count', text: '1'
  end

  test 'каталог не показывает теги неопубликованных статей' do
    @page.update!(is_published: false)
    get '/ru/tags'
    assert_response :success
    assert_select 'a.tag-chip', count: 0
  end

  test 'каталог не показывает теги статей на других языках' do
    @page.update!(lang: 'en')
    get '/ru/tags'
    assert_select 'a.tag-chip', count: 0
  end

  test 'страница тега показывает опубликованные статьи языка локали' do
    get '/ru/tags/molitva'
    assert_response :success
    assert_includes response.body, 'О молитве'
    assert_includes response.body, '/ru/ru/w/o_molitve_test'
  end

  test 'страница тега не показывает неопубликованные статьи' do
    @page.update!(is_published: false)
    get '/ru/tags/molitva'
    assert_response :success
    assert_no_match(/О молитве/, response.body)
  end

  test 'страница тега предлагает другие языки со своей локалью' do
    en = create_page(is_published: true, title: 'On prayer', path: 'on_prayer_test', lang: 'en',
                     body: LONG_BODY, group_lang_id: @page.group_lang_id)
    Tagging.create!(page: en, tag: @tag)
    grc = create_page(is_published: true, title: 'Περὶ προσευχῆς', path: 'grc_prayer_test', lang: 'grc', body: LONG_BODY)
    Tagging.create!(page: grc, tag: @tag)
    xcl = create_page(is_published: true, title: 'Աղօթք', path: 'xcl_prayer_test', lang: 'xcl', body: LONG_BODY)
    Tagging.create!(page: xcl, tag: @tag)

    get '/ru/tags/molitva'
    assert_response :success
    assert_includes response.body, '/en/tags/molitva'
    # у la/grc есть своя локаль в адресе (греческая и латинская библиотеки)
    assert_includes response.body, '/grc/tags/molitva'
    # а у языков только с контентом (xcl, cop...) локали /{locale}/tags нет
    assert_not_includes response.body, '/xcl/tags/molitva'
  end

  test 'неизвестный slug отдаёт 404' do
    get '/ru/tags/net-takogo-tega'
    assert_response :not_found
  end
end

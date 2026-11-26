require 'test_helper'

class Admin::AutocompleteControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create_user(is_admin: true)
    sign_in(@admin)
  end

  test 'подсказки страниц-списков не показывают обычные статьи' do
    list = create_page(title: 'Список авторов', page_type: 4)
    article = create_page(title: 'Список статей', page_type: 1)

    get admin_autocomplete_pages_path(term: 'Список', kind: 'list'), as: :json

    assert_response :success
    ids = JSON.parse(response.body).map { _1['id'] }
    assert_includes ids, list.id
    assert_not_includes ids, article.id
  end
end

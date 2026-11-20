require 'test_helper'

class PageReactionsControllerTest < ActionDispatch::IntegrationTest
  LONG_BODY = '<p>' + 'Достаточно длинный текст страницы. ' * 3 + '</p>'
  IP_ONE = '10.0.5.1'
  IP_TWO = '10.0.5.2'

  setup do
    @page = create_page(is_published: true, body: LONG_BODY)
  end

  test 'реакция ставится один раз с одного IP и снимается повторным нажатием' do
    post_reaction('like', IP_ONE)

    assert_response :success
    assert_equal 1, PageReaction.where(page_id: @page.id).count
    assert_equal({'like' => 1, 'useful' => 0, 'thanks' => 0, 'interesting' => 0, 'hundred' => 0}, json_counts)
    assert_equal 'like', json_body['active']

    post_reaction('like', IP_ONE)

    assert_response :success
    assert_equal 0, PageReaction.where(page_id: @page.id).count
    assert_equal({'like' => 0, 'useful' => 0, 'thanks' => 0, 'interesting' => 0, 'hundred' => 0}, json_counts)
    assert_nil json_body['active']
  end

  test 'выбор другого вида меняет реакцию, а не добавляет вторую' do
    post_reaction('like', IP_ONE)
    post_reaction('useful', IP_ONE)

    assert_response :success
    assert_equal 1, PageReaction.where(page_id: @page.id).count
    assert_equal 'useful', PageReaction.find_by(page_id: @page.id).kind
    assert_equal({'like' => 0, 'useful' => 1, 'thanks' => 0, 'interesting' => 0, 'hundred' => 0}, json_counts)
    assert_equal 'useful', json_body['active']
  end

  test 'реакции с разных IP суммируются по видам' do
    post_reaction('like', IP_ONE)
    post_reaction('useful', IP_TWO)

    assert_equal({'like' => 1, 'useful' => 1, 'thanks' => 0, 'interesting' => 0, 'hundred' => 0}, json_counts)
    assert_equal 'useful', json_body['active']
    assert_equal 2, PageReaction.where(page_id: @page.id).count
  end

  test 'реакция 100% ставится' do
    post_reaction('hundred', IP_ONE)

    assert_response :success
    assert_equal({'like' => 0, 'useful' => 0, 'thanks' => 0, 'interesting' => 0, 'hundred' => 1}, json_counts)
    assert_equal 'hundred', json_body['active']
  end

  test 'неизвестный вид реакции отклоняется' do
    post_reaction('superlike', IP_ONE)

    assert_response :unprocessable_entity
    assert_equal 0, PageReaction.count
  end

  test 'в базе хранится только дайджест IP' do
    post_reaction('like', '10.0.5.9')

    reaction = PageReaction.last
    assert_equal PageReaction.digest_ip('10.0.5.9'), reaction.ip_digest
    assert_not_equal '10.0.5.9', reaction.ip_digest
  end

  test 'неопубликованная статья не принимает реакции' do
    @page.update!(is_published: false)

    post_reaction('like', IP_ONE)

    assert_response :not_found
    assert_equal 0, PageReaction.count
  end

  test 'не-статья не принимает реакции' do
    list = create_page(is_published: true, page_type: 4, body: LONG_BODY)

    post "/ru/pages/#{list.id}/reaction", params: {kind: 'like'},
         headers: {'REMOTE_ADDR' => IP_ONE, 'Accept' => 'application/json'}

    assert_response :not_found
    assert_equal 0, PageReaction.count
  end

  test 'HTML-ответ без Accept: json возвращает на страницу статьи' do
    post "/ru/pages/#{@page.id}/reaction", params: {kind: 'like'}, headers: {'REMOTE_ADDR' => IP_ONE}

    assert_response :redirect
    assert_redirected_to Page.path_for(@page.lang, @page.path)
    assert_equal 'like', PageReaction.last.kind
  end

  private

  def post_reaction(kind, ip)
    post "/ru/pages/#{@page.id}/reaction", params: {kind: kind},
         headers: {'REMOTE_ADDR' => ip, 'Accept' => 'application/json'}
  end

  def json_body
    JSON.parse(response.body)
  end

  def json_counts
    json_body['counts']
  end
end

require "test_helper"

class BibleMapControllerTest < ActionDispatch::IntegrationTest
  test "page is rendered without the site layout and loads the globe module" do
    get '/ru/bible-map'
    assert_response :success
    assert_includes response.body, 'Библейская история на глобусе'
    assert_includes response.body, 'https://bibleox.com/ru/bible-map/'
    assert_match(/<script type="importmap"/, response.body)
    assert_match(/import "bible_map\/app"/, response.body)
    assert_no_match(/noindex/, response.body)
    assert_no_match(/id="settings-btn"/, response.body)
  end

  test "importmap points three.js to the vendored copy" do
    get '/ru/bible-map'
    importmap = JSON.parse(response.body[%r{<script type="importmap"[^>]*>(.*?)</script>}m, 1])
    assert_match(%r{/three-[0-9a-f]+\.js\z}, importmap['imports']['three'])
    assert importmap['imports'].key?('three/addons/lines/Line2.js')
    assert importmap['imports'].key?('bible_map/events')
  end

  test "textures and verse links come from data attributes" do
    get '/ru/bible-map'
    %w[earth_day.jpg earth_relief.jpg clouds.jpg moon.jpg].each do |file|
      assert_includes response.body, "/bible_map/#{file}"
      assert File.exist?(Rails.root.join('public', 'bible_map', file)), "нет текстуры #{file}"
    end
    assert_includes response.body, 'data-bible-url="/ru/ru/"'
  end

  test "other interface languages are not indexed" do
    get '/en/bible-map'
    assert_response :success
    assert_match(/noindex/, response.body)
    assert_includes response.body, 'data-bible-url="/en/ru/"'
  end
end

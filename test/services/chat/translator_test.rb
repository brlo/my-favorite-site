require "test_helper"

class Chat::TranslatorTest < ActiveSupport::TestCase
  setup do
    ::RedisConnectionPool.del(Chat::Translator::DEEPSEEK_SLOT_KEY)
  end

  teardown do
    ::RedisConnectionPool.del(Chat::Translator::DEEPSEEK_SLOT_KEY)
  end

  def with_keys(deepseek_key: 'sk-test', yandex_key: 'ya-test')
    stubbing(Chat::Translator, :deepseek_config, { api_key: deepseek_key }) do
      stubbing(Chat::Translator, :config, { api_key: yandex_key, folder_id: nil }) do
        yield
      end
    end
  end

  def with_providers(deepseek: ->(*) { '<p>ds</p>' }, yandex: ->(*) { '<p>ya</p>' })
    stubbing(Chat::Translator, :deepseek_translate, deepseek) do
      stubbing(Chat::Translator, :yandex_translate, yandex) do
        yield
      end
    end
  end

  test "short message goes to deepseek once per ten minutes" do
    calls = []
    with_keys do
      with_providers(
        deepseek: ->(html, from:, to:) { calls << :deepseek; '<p>ds</p>' },
        yandex: ->(*) { calls << :yandex; '<p>ya</p>' }
      ) do
        assert_equal '<p>ds</p>', Chat::Translator.translate_html('<p>hi</p>', from: 'en', to: 'ru', plain_text: 'hi')
        assert_equal '<p>ya</p>', Chat::Translator.translate_html('<p>hi</p>', from: 'en', to: 'ru', plain_text: 'hi')
      end
    end

    assert_equal %i[deepseek yandex], calls
  end

  test "long message goes to yandex and does not consume deepseek slot" do
    calls = []
    with_keys do
      with_providers(
        deepseek: ->(*) { calls << :deepseek; '<p>ds</p>' },
        yandex: ->(*) { calls << :yandex; '<p>ya</p>' }
      ) do
        assert_equal '<p>ya</p>', Chat::Translator.translate_html('<p>long</p>', from: 'en', to: 'ru', plain_text: 'a' * 1001)
        assert_equal '<p>ds</p>', Chat::Translator.translate_html('<p>short</p>', from: 'en', to: 'ru', plain_text: 'a')
      end
    end

    assert_equal %i[yandex deepseek], calls
  end

  test "deepseek failure falls back to yandex and keeps the slot closed" do
    calls = []
    failing = ->(*) { raise Chat::Translator::DeepSeekError, 'no money' }
    with_keys do
      with_providers(
        deepseek: failing,
        yandex: ->(*) { calls << :yandex; '<p>ya</p>' }
      ) do
        assert_equal '<p>ya</p>', Chat::Translator.translate_html('<p>hi</p>', from: 'en', to: 'ru', plain_text: 'hi')
        assert_equal '<p>ya</p>', Chat::Translator.translate_html('<p>hi</p>', from: 'en', to: 'ru', plain_text: 'hi')
      end
    end

    assert_equal %i[yandex yandex], calls
  end

  test "without deepseek key everything goes to yandex" do
    calls = []
    with_keys(deepseek_key: nil) do
      with_providers(
        deepseek: ->(*) { calls << :deepseek; '<p>ds</p>' },
        yandex: ->(*) { calls << :yandex; '<p>ya</p>' }
      ) do
        assert_equal '<p>ya</p>', Chat::Translator.translate_html('<p>hi</p>', from: 'en', to: 'ru', plain_text: 'hi')
      end
    end

    assert_equal %i[yandex], calls
  end

  test "code fences are stripped from deepseek output" do
    assert_equal '<p>Привет</p>', Chat::Translator.strip_code_fence("```html\n<p>Привет</p>\n```")
    assert_equal '<p>Привет</p>', Chat::Translator.strip_code_fence("Вот перевод:\n```html\n<p>Привет</p>\n```")
  end
end

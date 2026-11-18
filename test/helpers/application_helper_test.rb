require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "interface direction follows the locale" do
    I18n.with_locale('ar') { assert_equal 'rtl', ui_direction }
    I18n.with_locale('he') { assert_equal 'rtl', ui_direction }
    I18n.with_locale('en') { assert_equal 'ltr', ui_direction }
    I18n.with_locale('ru') { assert_equal 'ltr', ui_direction }
  end

  test "content direction follows the content language, not the interface" do
    I18n.with_locale('ar') do
      @content_lang = 'ru'
      assert_equal 'ltr', content_direction
    end

    I18n.with_locale('en') do
      @content_lang = 'ar'
      assert_equal 'rtl', content_direction

      @content_lang = 'arab-avd'
      assert_equal 'rtl', content_direction
    end
  end

  test "content direction falls back to the interface when the language is unknown" do
    I18n.with_locale('ar') do
      @content_lang = nil
      assert_equal 'rtl', content_direction
    end
  end

  test "direction_for_lang understands page locales and bible codes" do
    assert_equal 'rtl', direction_for_lang('heb-osm')
    assert_equal 'rtl', direction_for_lang('fa')
    assert_equal 'ltr', direction_for_lang('gr-lxx-byz')
    assert_equal 'ltr', direction_for_lang('ru')
  end
end

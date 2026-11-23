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

  test "jp_box_text applies the orthodox calque to names" do
    text = "パウロとテモテは、イエス・キリストの僕である。ヨセフとマリア、インマヌエル。"
    assert_equal(
      "パワェルとティモフェイは、イイスス・ハリストスの僕である。イオシフとマリヤ、エムマヌイル。",
      jp_box_text(text, true)
    )
    assert_equal text, jp_box_text(text, false)
  end

  test "jp_box_text calques the Old Testament names" do
    assert_equal "アウラムとサライ、ファラオン", jp_box_text("アブラムとサライ、ファラオ", true)
    assert_equal "アウラアムとイサアク、イオシフ", jp_box_text("アブラハムとイサク、ヨセフ", true)
  end

  test "jp_box_text keeps words that only look like names" do
    assert_equal(
      "反キリストとユダヤ人、ヨナタン、アポロニア、アポロス",
      jp_box_text("反キリストとユダヤ人、ヨナタン、アポロニア、アポロ", true)
    )
  end

  test "jp_box_text resolves the paired calque markers" do
    assert_equal "聖神[せいしん]", jp_box_text("{聖霊[せいれい]|聖神[せいしん]}", true)
    assert_equal "聖霊[せいれい]", jp_box_text("{聖霊[せいれい]|聖神[せいしん]}", false)
  end
end

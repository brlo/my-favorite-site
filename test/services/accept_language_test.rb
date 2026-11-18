require "test_helper"

class AcceptLanguageTest < ActiveSupport::TestCase
  test "japanese browser gets ja" do
    assert_equal 'ja', AcceptLanguage.best_locale('ja-JP,ja;q=0.9,en-US;q=0.8')
  end

  test "simplified chinese browser gets zh-Hans" do
    assert_equal 'zh-Hans', AcceptLanguage.best_locale('zh-CN,zh;q=0.9')
    assert_equal 'zh-Hans', AcceptLanguage.best_locale('zh-SG')
  end

  test "traditional chinese browser gets zh-Hant" do
    assert_equal 'zh-Hant', AcceptLanguage.best_locale('zh-TW,zh;q=0.8')
    assert_equal 'zh-Hant', AcceptLanguage.best_locale('zh-HK')
    assert_equal 'zh-Hant', AcceptLanguage.best_locale('zh-Hant-TW')
  end

  test "respects q values" do
    assert_equal 'en', AcceptLanguage.best_locale('ru;q=0.2,en;q=0.9')
    assert_equal 'ja', AcceptLanguage.best_locale('en;q=0.5,ja;q=0.7')
  end

  test "accepts any interface locale" do
    assert_equal 'de', AcceptLanguage.best_locale('de-DE,de;q=0.9')
    assert_equal 'ko', AcceptLanguage.best_locale('ko-KR')
    assert_equal 'el', AcceptLanguage.best_locale('el-GR')
  end

  test "falls back to russian" do
    assert_equal 'ru', AcceptLanguage.best_locale(nil)
    assert_equal 'ru', AcceptLanguage.best_locale('')
    assert_equal 'ru', AcceptLanguage.best_locale('*')
    assert_equal 'ru', AcceptLanguage.best_locale('pt-BR,pt;q=0.9')
  end

  test "ignores zero quality and malformed parts" do
    assert_equal 'en', AcceptLanguage.best_locale('ja;q=0,en;q=0.5')
    assert_equal 'ru', AcceptLanguage.best_locale(',,;q=0.5')
  end
end

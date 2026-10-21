require "test_helper"

class LangLinkerTest < ActiveSupport::TestCase
  test "moves the page with its whole group, except pages in the target language" do
    ru = create_page(lang: 'ru')
    en = create_page(lang: 'en')
    fr = create_page(lang: 'fr', group_lang_id: en.group_lang_id)

    LangLinker.call({ en.path => ru.path })
    assert_equal [ru.group_lang_id] * 2, [en.reload.group_lang_id, fr.reload.group_lang_id]
  end

  test "pages can swap their groups within one list" do
    ru1, ru2 = create_page(lang: 'ru'), create_page(lang: 'ru')
    en1 = create_page(lang: 'en', group_lang_id: ru2.group_lang_id) # связана не с той ru-страницей
    en2 = create_page(lang: 'en')

    LangLinker.call({ en1.path => ru1.path, en2.path => ru2.path })
    assert_equal ru1.group_lang_id, en1.reload.group_lang_id
    assert_equal ru2.group_lang_id, en2.reload.group_lang_id
  end

  test "skips a pair when the target group already has a page in this language" do
    ru = create_page(lang: 'ru')
    create_page(lang: 'en', group_lang_id: ru.group_lang_id)
    en = create_page(lang: 'en')

    log = LangLinker.call({ en.path => ru.path })
    assert_match(/пропуск/, log.first)
    assert_not_equal ru.group_lang_id, en.reload.group_lang_id
  end

  test "dry run changes nothing" do
    ru, en = create_page(lang: 'ru'), create_page(lang: 'en')
    LangLinker.call({ en.path => ru.path }, is_dry_run: true)
    assert_not_equal ru.group_lang_id, en.reload.group_lang_id
  end
end

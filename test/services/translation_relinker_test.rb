require "test_helper"

class TranslationRelinkerTest < ActiveSupport::TestCase
  setup do
    @list = create_page(lang: 'en', path: "en-q-#{SecureRandom.hex(3)}", page_type: 4)
    @ru = create_page(lang: 'ru', path: "Таинство-#{SecureRandom.hex(3)}")
    @en = create_page(lang: 'en', group_lang_id: @ru.group_lang_id)
    @ru_only = create_page(lang: 'ru', path: "Святыня-#{SecureRandom.hex(3)}")
  end

  def link(path, anchor = '') = %(<p><a href="https://bibleox.com/ru/ru/w/#{CGI.escape(path)}#{anchor}">x</a></p>)

  test "replaces a link to a translated original, drops the anchor and keeps links to untranslated pages" do
    page = create_page(lang: 'en', parent_id: @list.id, body: link(@ru.path, '#HH-Заголовок') + link(@ru_only.path))
    TranslationRelinker.call(lang: 'en', list: @list.path)

    body = page.reload.body
    assert_includes body, %(href="https://bibleox.com/en/en/w/#{@en.path}/")
    assert_includes body, CGI.escape(@ru_only.path)
  end

  test "also handles references and the old /ru/q/ form" do
    page = create_page(lang: 'en', parent_id: @list.id, references: %(<p><a href="https://bibleox.com/ru/q/#{CGI.escape(@ru.path)}">x</a></p>))
    TranslationRelinker.call(lang: 'en', list: @list.path)
    assert_includes page.reload.references, "/en/en/w/#{@en.path}/"
  end

  test "does not touch pages outside the list, and dry run changes nothing" do
    outside = create_page(lang: 'en', body: link(@ru.path))
    inside = create_page(lang: 'en', parent_id: @list.id, body: link(@ru.path))

    log = TranslationRelinker.call(lang: 'en', list: @list.path, is_dry_run: true)
    assert_equal 1, log.size
    assert_includes inside.reload.body, CGI.escape(@ru.path)
    TranslationRelinker.call(lang: 'en', list: @list.path)
    assert_includes outside.reload.body, CGI.escape(@ru.path)
  end
end

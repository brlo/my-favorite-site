require "test_helper"

class TranslationImporterTest < ActiveSupport::TestCase
  setup do
    @list = create_page(lang: 'en', path: "en-q-#{SecureRandom.hex(3)}", page_type: 4)
    god = Menu.create!(page_id: @list.id, title: 'God')
    @son = Menu.create!(page_id: @list.id, parent_id: god.id, title: 'Son')
    @ru = create_page(lang: 'ru')
  end

  def data(item = {})
    {
      'lang' => 'en', 'list' => @list.path,
      'pages' => [{
        'src' => @ru.path, 'path' => "x_#{SecureRandom.hex(3)}", 'title' => 'Christ in Heaven',
        'body' => '<blockquote><p>“text”</p></blockquote>', 'references' => '<p>note</p>',
        'menu' => { 'parent' => 'God/Son', 'title' => 'In Heaven', 'priority' => 6 },
      }.merge(item)],
    }
  end

  test "creates a draft page in the original's language group and a menu item" do
    d = data
    TranslationImporter.call(d)

    page = Page.find_by!(path: d['pages'][0]['path'])
    assert_equal ['en', @ru.group_lang_id, @list.id, false], [page.lang, page.group_lang_id, page.parent_id, page.is_published]
    assert_equal '<p>note</p>', page.references
    menu = Menu.find_by!(page_id: @list.id, path: page.path)
    assert_equal [@son.id, 'In Heaven', 6], [menu.parent_id, menu.title, menu.priority]
  end

  test "skips the original that already has a translation, so the file can be run again" do
    d = data
    TranslationImporter.call(d)
    log = TranslationImporter.call(d)
    assert_match(/перевод уже есть/, log.first)
    assert_equal 1, Menu.where(page_id: @list.id, path: d['pages'][0]['path']).count
  end

  test "skips the page when the menu section is missing" do
    log = TranslationImporter.call(data('menu' => { 'parent' => 'God/Nope' }))
    assert_match(/нет раздела/, log.first)
    assert_not Page.exists?(lang: 'en', group_lang_id: @ru.group_lang_id)
  end

  test "creates a missing menu folder once and puts the page into it" do
    d = data('menu' => { 'parent' => 'God/Son/Titles', 'priority' => 1 })
    d['folders'] = [{ 'path' => 'God/Son/Titles', 'priority' => 4 }]
    TranslationImporter.call(d)
    TranslationImporter.call(d)

    folders = Menu.where(page_id: @list.id, parent_id: @son.id, title: 'Titles')
    assert_equal [4], folders.pluck(:priority)
    assert Menu.exists?(page_id: @list.id, parent_id: folders.first.id, path: d['pages'][0]['path'])
  end

  test "dry run reports pages for a folder it would create" do
    d = data('menu' => { 'parent' => 'God/Son/Titles' })
    d['folders'] = [{ 'path' => 'God/Son/Titles' }]
    log = TranslationImporter.call(d, is_dry_run: true)
    assert_match(/\[DRY RUN\] создано/, log.last)
    assert_not Menu.exists?(page_id: @list.id, title: 'Titles')
  end

  test "dry run changes nothing" do
    TranslationImporter.call(data, is_dry_run: true)
    assert_not Page.exists?(lang: 'en', group_lang_id: @ru.group_lang_id)
  end

  test "published import notifies search engines once, with all created pages" do
    sent = []
    stubbing(Page, :index_now_enabled?, true) do
      stubbing(IndexNowJob, :perform_later, ->(urls) { sent << urls }) do
        d = data
        TranslationImporter.call(d, is_published: true)
        assert_equal [[Page.find_by!(path: d['pages'][0]['path']).canonical_url]], sent
      end
    end
  end


  test "fills an empty menu item with the same title instead of adding a second one" do
    stub = Menu.create!(page_id: @list.id, parent_id: @son.id, title: 'In Heaven', priority: 3)
    d = data
    TranslationImporter.call(d)
    assert_equal d['pages'][0]['path'], stub.reload.path
    assert_equal 3, stub.priority
    assert_equal 1, Menu.where(page_id: @list.id, parent_id: @son.id, title: 'In Heaven').count
  end

end

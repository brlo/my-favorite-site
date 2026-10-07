require "test_helper"

class PageTest < ActiveSupport::TestCase
  # --- нормализация при сохранении ---

  test "title and path are normalized and path_low is downcased" do
    page = create_page(title: "  Вечер \n  в  Назарете ", path: " My  Path ")
    assert_equal 'Вечер в Назарете', page.title
    assert_equal 'My_Path', page.path
    assert_equal 'my_path', page.path_low
  end

  test "blank path is generated from the title" do
    page = create_page(title: 'Две строки', path: '')
    assert_match(/\A\w{4}_Две_строки\z/, page.path)
    assert_equal page.path.downcase, page.path_low
  end

  test "group_lang_id is generated once" do
    page = create_page
    assert_equal 10, page.group_lang_id.length
    assert_equal page.group_lang_id, Page.find(page.id).group_lang_id
  end

  test "blank group_lang_id from a form does not join pages into one group of translations" do
    a = create_page(group_lang_id: '')
    b = create_page(group_lang_id: '')
    assert_equal 10, a.group_lang_id.length
    assert_not_equal a.group_lang_id, b.group_lang_id
  end

  test "an explicit group_lang_id makes pages translations of each other" do
    a = create_page(lang: 'ru')
    b = create_page(lang: 'en', group_lang_id: a.group_lang_id)
    assert_equal a.group_lang_id, b.group_lang_id
  end

  test "changing the path remembers the old one in redirect_from" do
    page = create_page(path: 'old_path')
    page.update!(path: 'new_path')
    assert_equal 'old_path', page.redirect_from
  end

  test "page_type and edit_mode are cast to integers" do
    page = create_page(page_type: '2', edit_mode: '3')
    assert_equal [2, 3], [page.page_type, page.edit_mode]
  end

  test "bible comment page builds its path from the title" do
    page = create_page(title: 'Зах. 1:6', path: '', page_type: 3)
    assert_equal 'ru-zah:1:6', page.path
    assert_equal 'zah/1/#L6', page.link_to_bible_verse
  end

  test "title and path are required" do
    assert_not Page.new(lang: 'ru', page_type: 1).valid?
  end

  # --- body: чистка и рендеринг ---

  test "body is sanitized with an allowlist" do
    page = create_page(body: "<p>Текст</p><script>alert(1)</script><p onclick='x()'>Ещё</p>")
    assert_not_includes page.body, 'script'
    assert_not_includes page.body, 'onclick'
    assert_includes page.body, '<p>Текст</p>'
  end

  test "soft hyphens and nbsp are removed from body" do
    page = create_page(body: "<p>сло­во&nbsp;и слово</p>")
    assert_equal '<p>слово и слово</p>', page.body
  end

  test "empty paragraphs and tiptap trailing breaks are dropped" do
    page = create_page(body: '<p></p><p>Текст<br class="ProseMirror-trailingBreak"></p>')
    assert_equal '<p>Текст</p>', page.body
  end

  test "footnote markers become anchored links in body_rendered only" do
    page = create_page(body: '<p>Текст[1] и ещё[2], снова[1].</p>')
    assert_includes page.body_rendered, "<sup class=\"foot-ref\"><a id=\"cite_ref-1\" href=\"#cite_note-1\">[1]</a></sup>"
    assert_includes page.body_rendered, 'id="cite_ref-2"'
    # повторная сноска получает суффикс, чтобы id были уникальны
    assert_includes page.body_rendered, 'id="cite_ref-1-2"'
    # в body (для редактора) сноски остаются обычным текстом
    assert_includes page.body, '[1]'
    assert_not_includes page.body, 'cite_ref'
  end

  test "links to footnotes are turned into plain text in body" do
    page = create_page(body: '<p>Текст <a href="#cite_note-1">[1]</a></p>')
    assert_not_includes page.body, 'cite_note'
    assert_includes page.body, '[1]'
  end

  test "headings become menu items with anchors" do
    page = create_page(body: '<h2>Первая глава</h2><p>а</p><h3>Раздел</h3><h2>Первая глава</h2>')
    assert_equal [
      ['h2', 'HH-Первая-глава', 'Первая глава'],
      ['h3', 'HH-Раздел', 'Раздел'],
      ['h2', 'HH2-Первая-глава', 'Первая глава'],
    ], page.body_menu
    assert_includes page.body_rendered, '<h2 id="HH-Первая-глава" name="HH-Первая-глава">'
  end

  test "source paragraph after a quote gets source-link class" do
    page = create_page(body: '<blockquote><p>Цитата</p></blockquote><p>(<a href="/x">Источник</a>)</p><p>(обычный)</p>')
    assert_includes page.body_rendered, '<p class="source-link">('
    assert_equal 1, page.body_rendered.scan('source-link').size
  end

  test "images get lazy loading unless it is already set" do
    page = create_page(body: '<p><img src="/a.png"><img src="/b.png" loading="eager"></p>')
    assert_includes page.body_rendered, '<img src="/a.png" loading="lazy">'
    assert_includes page.body_rendered, 'loading="eager"'
  end

  test "furigana markup is converted to ruby tags" do
    page = create_page(body: '<p>私[わたし]</p>')
    assert_includes page.body_rendered, '<ruby>'
  end

  # --- references (сноски внизу) ---

  test "references get back links and numbering" do
    page = create_page(references: '<ol start="3"><li><p>Первая</p></li><li><p>Вторая</p></li></ol>')
    assert_includes page.references_rendered, 'id="cite_note-3"'
    assert_includes page.references_rendered, "<a class=\"foot-note\" href=\"#cite_ref-4\">"
  end

  # --- меню страницы типа «список» ---

  test "menu is available only for list pages" do
    assert_nil create_page(page_type: 1).menu
    list = create_page(page_type: 4)
    Menu.create!(page_id: list.id, title: 'Пункт', path: 'x')
    assert_equal ['Пункт'], list.menu.map { _1[:title] }
    assert_equal 1, list.tree_menu.size
  end

  test "menu item is marked empty when the page body becomes short, and back" do
    page = create_page(path: 'target', body: '<p>' + 'x' * 100 + '</p>')
    owner = create_page(page_type: 4)
    item = Menu.create!(page_id: owner.id, title: 'Пункт', path: 'target', is_empty: false)

    page.update!(body: '<p>коротко</p>')
    assert item.reload.is_empty

    page.update!(body: '<p>' + 'y' * 100 + '</p>')
    assert_not item.reload.is_empty
  end

  # --- абзацы для поиска ---

  test "published page is split into searchable paragraphs" do
    page = create_page(is_published: true, body: '<h2>Заголовок раздела</h2><p>' + 'а' * 200 + '</p><p>' + 'б' * 200 + '</p>')
    contents = page.page_paragraphs.order(:position).pluck(:content)
    assert_operator contents.size, :>=, 2
    assert contents.all? { _1.length > 10 }
    assert_equal [0, 1], page.page_paragraphs.order(:position).pluck(:position).first(2)
  end

  test "paragraphs are removed when the page is unpublished" do
    page = create_page(is_published: true, body: '<p>' + 'а' * 200 + '</p>')
    assert page.page_paragraphs.any?
    page.update!(is_published: false)
    assert_empty page.page_paragraphs.reload
  end

  test "paragraphs are not rebuilt when body_rendered did not change" do
    page = create_page(is_published: true, body: '<p>' + 'а' * 200 + '</p>')
    ids = page.page_paragraphs.pluck(:id)
    page.update!(priority: 5)
    assert_equal ids, page.page_paragraphs.reload.pluck(:id)
  end

  # --- даты периода ---

  test "period dates are converted to integers" do
    page = create_page(period_start: '1200', period_end: '1300')
    assert page.date_start_int.present?
    assert page.date_end_int.present?
    assert_operator page.date_start_int, :<, page.date_end_int
  end

  # --- права ---

  test "owner of a page or of its parent can edit it" do
    parent = create_page
    child = create_page(parent_id: parent.id)
    owner = create_user(pages_owner: [parent.id])
    assert child.owned_by?(owner)
    assert child.editable_by?(owner)
    assert_not child.owned_by?(create_user)
    assert_not child.owned_by?(nil)
  end

  test "editable_by? follows edit_mode" do
    admin = create_user(is_admin: true)
    moderator = create_user.tap { _1.can!('pages_update') }
    stranger = create_user

    admins_only = create_page(edit_mode: Page::EDIT_MODES['admins'])
    assert admins_only.editable_by?(admin)
    assert_not admins_only.editable_by?(moderator)

    for_moderators = create_page(edit_mode: Page::EDIT_MODES['moderators'])
    assert for_moderators.editable_by?(moderator)
    assert_not for_moderators.editable_by?(stranger)

    for_contributors = create_page(edit_mode: Page::EDIT_MODES['contributors'])
    assert_not for_contributors.editable_by?(stranger)
  end

  test "blocked users and guests cannot edit" do
    page = create_page(edit_mode: Page::EDIT_MODES['admins'])
    blocked = create_user(is_admin: true, is_blocked: true)
    assert_not page.editable_by?(blocked)
    assert_not page.editable_by?(nil)
  end

  test "add_editor skips the author and duplicates" do
    author = create_user
    other = create_user
    page = create_page(user_id: author.id)
    page.add_editor(author)
    assert_equal [], page.editors.to_a
    page.add_editor(other)
    page.add_editor(other)
    assert_equal [other.id], page.editors
  end

  # --- прочее ---

  test "is_body_empty? treats short bodies as empty" do
    assert create_page(body: '<p>коротко</p>').is_body_empty?
    assert_not create_page(body: '<p>' + 'z' * 60 + '</p>').is_body_empty?
  end

  test "comments_for_verses finds comment pages by address" do
    comment = create_page(title: 'Зах. 1:6', path: '', page_type: 3)
    verse = Verse.new(book: 'zah', chapter: 1, line: 6, tr_code: 'ru')
    verse.define_singleton_method(:address) { 'zah:1:6' }
    verse.define_singleton_method(:lang) { 'ru' }
    assert_includes Page.comments_for_verses([verse]).to_a, comment
  end

  test "pdf helpers point to files in public/s/page_pdfs" do
    page = create_page
    assert_equal "s/page_pdfs/#{page.id}.pdf", page.pdf_path
    assert_not page.pdf_exists?
  end

  test "img_preview_file_path falls back to the site logo" do
    # id заведомо без файла превью (в public/s у разработчика могут лежать файлы от реальных страниц)
    page = Page.new(id: 2_000_000_000)
    assert_match(%r{\A/favicons/bibleox-for-social-(ru|en)\.png\z}, page.img_preview_file_path)
  end

  test "Page.safe_html is the shared allowlist sanitizer" do
    assert_equal '<p>a</p>', Page.safe_html('<p>a</p><iframe></iframe>')
    assert_equal 'a b', Page.safe_html("a b")
  end

  test "menus_info is nil when menu items have no pages" do
    list = create_page(page_type: 4)
    Menu.create!(page_id: list.id, title: 'x', path: 'missing_page')
    Rails.cache.clear
    assert_nil list.menus_info
  end

  test "menus_info collects visits per menu path" do
    list = create_page(page_type: 4)
    target = create_page(path: 'menu_target')
    Menu.create!(page_id: list.id, title: 'x', path: 'menu_target')
    Rails.cache.clear
    info = list.menus_info
    assert_equal ['menu_target'], info.keys
    assert info['menu_target'].key?(:visits)
    assert_not info['menu_target'].key?(:icon)
    assert target.persisted?
  end

  test "audio_link is present only when the mp3 exists" do
    page = create_page(audio: 'tests/no_such_file')
    assert_nil page.audio_link('ru')
  end
end

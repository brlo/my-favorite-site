require "test_helper"

class Ccel::ImporterTest < ActiveSupport::TestCase
  XML = <<~XML.freeze
    <?xml version="1.0" encoding="UTF-8"?>
    <ThML><ThML.head><DC><DC.Title>ANF99. Test Fathers</DC.Title>
      <DC.Creator scheme="short-form" sub="Editor">Philip Schaff</DC.Creator></DC></ThML.head>
    <ThML.body>
      <div1 id="ii" title="AUTHOR">
        <div2 id="ii.ii" title="The Treatise"><pb n="10"/>
          <div3 id="ii.ii.i" title="Book I."><p>First<note n="1"><p>A real note.</p></note> book.</p></div3>
          <div3 id="ii.ii.ii" title="Book II."><pb n="11"/><p>Second book.</p></div3>
          <div3 id="ii.ii.iii" title="Elucidations"><p>Editor speaks.</p></div3>
        </div2>
        <div2 id="ii.iii" title="A Letter"><p>Dear friend, <scripRef parsed="|John|3|16|0|0">John iii. 16</scripRef>.</p></div2>
      </div1>
    </ThML.body></ThML>
  XML

  setup do
    @dir = Dir.mktmpdir
    File.write(File.join(@dir, 'anf99.xml'), XML)
    @root = create_page(path: 'q-saints-en', lang: 'en', page_type: 4)
    @century = Menu.create!(page_id: @root.id, title: '2nd century')
    @ru_author = create_page(path: 'Автор', lang: 'ru', page_type: 4)
    @ru_letter = create_page(path: 'Письмо', lang: 'ru')
  end

  teardown { FileUtils.remove_entry(@dir) }

  def write_map(works, authors)
    map = File.join(@dir, 'map.yml')
    File.write(map, { 'authors' => authors, 'works' => works }.to_yaml)
    map
  end

  def import(works, authors: nil)
    authors ||= {
      'auth' => {
        'path' => 'Test_Author', 'ru' => 'Автор', 'title' => 'Test Author, 2nd c.', 'century' => '2nd century',
        'categories' => %w[Works Epistles],
      },
    }
    map = File.join(@dir, 'map.yml')
    File.write(map, { 'authors' => authors, 'works' => works }.to_yaml)
    Ccel::Importer.new(map, dir: @dir, log: StringIO.new).run
  end

  test "creates the author, work pages split into parts and menus" do
    stats = import([
      { 'src' => 'anf99 ii.ii', 'author' => 'auth', 'title' => 'The Treatise', 'parts' => 'each' },
      { 'src' => 'anf99 ii.iii', 'author' => 'auth', 'title' => 'A Letter', 'category' => 'Epistles', 'ru' => 'Письмо' },
    ])
    assert_equal([3, 0, 1], stats.values_at(:created, :updated, :authors))

    author = Page.find_by!(path: 'Test_Author')
    assert_equal [@root.id, 'en', @ru_author.group_lang_id], [author.parent_id, author.lang, author.group_lang_id]
    assert Menu.exists?(page_id: @root.id, parent_id: @century.id, path: 'Test_Author')

    part1 = Page.find_by!(path: 'auth-the-treatise-1')
    assert_equal 'The Treatise / Book I', part1.title
    assert_equal author.id, part1.parent_id
    assert part1.is_published && part1.is_past
    assert_not Page.where("body LIKE '%Editor speaks%'").exists?
    assert_includes part1.body, 'First[1] book.'
    assert_match %r{<ol><li><p>A real note.</p></li></ol><p>Source: <em>Ante-Nicene Fathers</em>, vol. 99: <em>Test Fathers</em>, ed. Philip Schaff, pp. 10.}, part1.references
    assert_equal 'The Treatise / Book II', Page.find_by!(path: 'auth-the-treatise-2').title

    letter = Page.find_by!(path: 'auth-a-letter')
    assert_equal @ru_letter.group_lang_id, letter.group_lang_id
    assert_includes letter.body, 'John 3:16'

    menus = Menu.where(page_id: author.id)
    assert_equal %w[Works Epistles], menus.where(parent_id: nil).order(:priority).pluck(:title)
    work = menus.find_by!(title: 'The Treatise')
    assert_equal %w[Book\ I Book\ II], menus.where(parent_id: work.id).order(:priority).pluck(:title)
  end

  test "fills an existing placeholder menu item instead of adding a new one" do
    author = create_page(path: 'Ready_Author', lang: 'en', page_type: 4, parent_id: @root.id)
    period = Menu.create!(page_id: author.id, title: 'Early period')
    placeholder = Menu.create!(page_id: author.id, parent_id: period.id, title: 'A Letter (197)')
    import([{ 'src' => 'anf99 ii.iii', 'author' => 'ready', 'title' => 'A Letter', 'menu' => 'A Letter (197)' }],
           authors: { 'ready' => { 'path' => 'Ready_Author' } })
    assert_equal 'ready-a-letter', placeholder.reload.path
    assert_equal 2, Menu.where(page_id: author.id).count
  end

  test "an unknown key in a work stops the import" do
    error = assert_raises(RuntimeError) { import([{ 'src' => 'anf99 ii.iii', 'author' => 'auth', 'title' => 'A', 'B' => nil }]) }
    assert_match(/неизвестные ключи/, error.message)
  end

  test "second run updates pages instead of creating duplicates" do
    works = [{ 'src' => 'anf99 ii.iii', 'author' => 'auth', 'title' => 'A Letter', 'ru' => 'Письмо' }]
    import(works)
    stats = import(works)
    assert_equal([0, 1, 0], stats.values_at(:created, :updated, :authors))
    assert_equal 1, Page.where(path: 'auth-a-letter').count
    assert_equal 1, Menu.where(path: 'auth-a-letter').count
  end

  test "skips a work whose ru page already has a hand-made English version" do
    create_page(lang: 'en', group_lang_id: @ru_letter.group_lang_id)
    stats = import([{ 'src' => 'anf99 ii.iii', 'author' => 'auth', 'title' => 'A Letter', 'ru' => 'Письмо' }])
    assert_equal 1, stats[:skipped]
    assert_not Page.exists?(path: 'auth-a-letter')
  end

  test "refuses to overwrite a page that was not created by the import" do
    create_page(path: 'auth-a-letter', lang: 'en', body: '<p>Hand-made.</p>')
    assert_raises(RuntimeError) { import([{ 'src' => 'anf99 ii.iii', 'author' => 'auth', 'title' => 'A Letter' }]) }
    assert_equal '<p>Hand-made.</p>', Page.find_by!(path: 'auth-a-letter').body
  end

  test "prune removes pages that left the map, their menus and the author created by the import" do
    letter = { 'src' => 'anf99 ii.iii', 'author' => 'auth', 'title' => 'A Letter', 'category' => 'Epistles' }
    treatise = { 'src' => 'anf99 ii.ii', 'author' => 'auth', 'title' => 'The Treatise', 'parts' => 'each' }
    import([letter, treatise])
    author = Page.find_by!(path: 'Test_Author')

    authors = { 'auth' => { 'path' => 'Test_Author' } }
    log = Ccel::Importer.new(write_map([letter], authors), dir: @dir, log: StringIO.new).prune
    assert_equal 2, log.grep(/страница/).size
    assert_not Page.exists?(path: 'auth-the-treatise-1')
    assert Page.exists?(path: 'auth-a-letter')
    assert_equal %w[Epistles A\ Letter], Menu.where(page_id: author.id).order(:id).pluck(:title)

    log = Ccel::Importer.new(write_map([], {}), dir: @dir, log: StringIO.new).prune
    assert_includes log, 'автор Test_Author'
    assert_not Page.exists?(author.id)
    assert_not Menu.exists?(page_id: @root.id, path: 'Test_Author')
  end

  test "prune keeps a placeholder menu item and only clears its link" do
    author = create_page(path: 'Ready_Author', lang: 'en', page_type: 4, parent_id: @root.id)
    placeholder = Menu.create!(page_id: author.id, title: 'A Letter (197)')
    authors = { 'ready' => { 'path' => 'Ready_Author' } }
    import([{ 'src' => 'anf99 ii.iii', 'author' => 'ready', 'title' => 'A Letter', 'menu' => 'A Letter (197)' }], authors:)

    Ccel::Importer.new(write_map([], authors), dir: @dir, log: StringIO.new).prune
    assert_nil placeholder.reload.path
    assert Page.exists?(author.id)
  end
end

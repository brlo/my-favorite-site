require 'yaml'

# Загрузка трудов из томов CCEL в английскую библиотеку святых отцов (q-saints-en) по карте db/ccel_map.yml.
# Повторный запуск обновляет уже загруженные страницы (ищем их по path), чужие страницы не трогаем.
module Ccel
  class Importer
    ROOT_PATH = 'q-saints-en'
    LANG = 'en'
    # По этой ссылке в references отличаем свои страницы от написанных вручную
    SOURCE_MARK = 'Christian Classics Ethereal Library: <a href="https://ccel.org/ccel/schaff/'
    DEFAULT_PART_KB = 300
    WORK_KEYS = %w[src author title category menu parts part_titles ru path skip].freeze

    attr_reader :stats, :paths

    def initialize(map_path, dir:, only: nil, is_dry_run: false, log: $stdout)
      @map_path = map_path
      @map = ::YAML.load_file(map_path)
      @dir = dir
      @only = only
      @is_dry_run = is_dry_run
      @log = log
      @stats = ::Hash.new(0)
      @paths = [] # адреса страниц трудов по карте
    end

    def run
      works = @map.fetch('works').select { @only.nil? || @only.include?(_1['src'].split.first) }
      if @is_dry_run
        ::ActiveRecord::Base.transaction do
          works.each { import_work(_1) }
          raise ::ActiveRecord::Rollback
        end
      else
        works.each { |w| ::ActiveRecord::Base.transaction { import_work(w) } }
      end
      @stats
    end

    # Удалить загруженные импортом страницы, которых больше нет в карте, их пункты меню, опустевшие из-за этого
    # категории и созданных импортом авторов, у которых не осталось трудов. Возвращает [сообщения]
    def prune(is_dry_run: false)
      expected = ::Ccel::Importer.new(@map_path, dir: @dir, is_dry_run: true, log: ::StringIO.new).tap(&:run).paths
      stale = ::Page.where('"references" LIKE ?', "%#{SOURCE_MARK}%").where.not(path: expected).to_a
      log = stale.map { "страница #{_1.path}" }

      ::ActiveRecord::Base.transaction do
        parent_ids = prune_menu_items(stale)
        stale.each(&:destroy!)
        log += prune_empty_parents(parent_ids)
        log += prune_authors(stale.map(&:parent_id).uniq)
        raise ::ActiveRecord::Rollback if is_dry_run
      end
      log
    end

    private

    # Пункты, созданные импортом (их название - это название страницы или её части), удаляем,
    # а в готовых заготовках меню (параметр menu в карте) только стираем адрес. Возвращает id родителей удалённых
    def prune_menu_items(pages)
      by_path = pages.index_by(&:path)
      ::Menu.where(path: by_path.keys).filter_map do |m|
        title = by_path[m.path].title
        is_own = title == m.title || title.start_with?("#{m.title} / ") || title.end_with?(" / #{m.title}")
        unless is_own
          m.update_columns(path: nil, is_empty: true)
          next
        end
        m.delete
        m.parent_id
      end.uniq
    end

    # Родители удалённых пунктов, оставшиеся без детей и без ссылки (категории), - и так вверх по дереву
    def prune_empty_parents(ids)
      log = []
      while ids.any?
        empty = ::Menu.where(id: ids, path: [nil, '']).where.not(id: ::Menu.where(parent_id: ids).select(:parent_id)).to_a
        log += empty.map { "пустая категория «#{_1.title}»" }
        ::Menu.where(id: empty.map(&:id)).delete_all
        ids = empty.map(&:parent_id).compact.uniq
      end
      log
    end

    # Автор, созданный импортом: en-страница-список без текста, без трудов и без пунктов меню со ссылками
    def prune_authors(author_ids)
      keep = @map.fetch('authors', {}).values.map { _1['path'].to_s.downcase }
      authors = ::Page.where(id: author_ids, lang: LANG, page_type: ::Page::PAGE_TYPES['список']).where.not(path_low: keep).select do |a|
        a.body.blank? && !::Page.exists?(parent_id: a.id) && !::Menu.where(page_id: a.id).where.not(path: [nil, '']).exists?
      end
      ::Menu.where(page_id: authors.map(&:id)).delete_all
      parent_items = ::Menu.where(page_id: authors.map(&:parent_id), path: authors.map(&:path)).to_a
      ::Menu.where(id: parent_items.map(&:id)).delete_all
      authors.each(&:destroy!)
      authors.map { "автор #{_1.path}" } + prune_empty_parents(parent_items.map(&:parent_id).compact.uniq)
    end

    def import_work(w)
      # лишний ключ - обычно след запятой без кавычек в YAML: "title: A, B" превращается в title: A и ключ B
      unknown = w.keys - WORK_KEYS
      raise "#{w['src']}: неизвестные ключи #{unknown.inspect} - возьмите название в кавычки" if unknown.any?
      code, node_id = w.fetch('src').split
      if (existing = existing_translation(Array(w['ru']).first))
        @stats[:skipped] += 1
        @log.puts "#{code} #{node_id} пропущен: уже есть en-страница #{existing}"
        return
      end
      vol = volume(code)
      div = vol.node(node_id)
      author = author_page(w.fetch('author'))
      base_path = w['path'] || "#{w['author']}-#{slug(w.fetch('title'))}"

      skip = { skip_ids: Array(w['skip']), skip_titles: Array(@map.dig('skip_titles', code)), cut_after: @map.dig('cut_after', code) }
      parts = split(div, w['parts'], **skip)
      # свои названия частей вместо заголовков из CCEL
      Array(w['part_titles']).each_with_index { |t, i| parts[i][0] = t if parts[i] }
      ru_paths = Array(w['ru'])
      pages = parts.each_with_index.map do |(subtitle, el), i|
        title = subtitle ? "#{w['title']} / #{subtitle}" : w['title']
        path = parts.size > 1 ? "#{base_path}-#{i + 1}" : base_path
        save_work_page(vol, el, title: title, path: path, author: author, ru_path: ru_paths[i],
                       skip: skip, src: "#{code} #{node_id}")
      end

      add_to_menu(author, w, pages, parts.map(&:first))
      @log.puts "#{code} #{node_id} -> #{pages.map(&:path).join(', ')}"
    end

    # Делим труд на страницы:
    #   nil      - труд целиком
    #   'each'   - каждый подраздел первого уровня отдельно
    #   число    - подразделы подряд, пока не наберётся столько килобайт
    # Возвращает [[подзаголовок или nil, элемент для рендера], ...]
    def split(div, mode, **skip)
      return [[nil, div]] if mode.nil?

      renderer = ::Ccel::Renderer.new(**skip.slice(:skip_ids, :skip_titles))
      children = ::Ccel::Volume.children_divs(div).reject { renderer.skip?(_1) }
      raise ArgumentError, "#{div['id']}: нет подразделов для parts" if children.empty?
      # текст до первого подраздела присоединяем к первой части
      lead = div.children.take_while { !::Ccel::Volume.div?(_1) }

      groups = if mode == 'each'
        children.map { [_1] }
      else
        group_by_size(children, (mode.to_i.nonzero? || DEFAULT_PART_KB) * 1024)
      end

      groups.each_with_index.map do |group, i|
        el = mode == 'each' ? group.first.dup : wrap(div, group)
        lead.reverse_each { el.prepend_child(_1.dup) } if i.zero?
        subtitle = mode == 'each' ? clean_title(::Ccel::Volume.title_of(group.first)) : (i + 1).to_s
        [subtitle, el]
      end
    end

    def group_by_size(children, limit)
      groups = []
      size = 0
      children.each do |el|
        if groups.empty? || size + el.text.size > limit
          groups << [el]
          size = 0
        else
          groups.last << el
        end
        size += el.text.size
      end
      groups
    end

    def wrap(div, group)
      el = ::Nokogiri::XML::Node.new(div.name, div.document)
      group.each { el.add_child(_1.dup) }
      el
    end

    def save_work_page(vol, el, title:, path:, author:, ru_path:, skip:, src:)
      result = ::Ccel::Renderer.call(el, **skip)
      page = ::Page.find_by(path_low: path.downcase)
      if page && !page.references.to_s.include?(SOURCE_MARK)
        raise "#{src}: путь #{path} уже занят страницей ##{page.id}, которая создана не импортом"
      end

      ru = ru_path && ::Page.find_by(path_low: ru_path.downcase, lang: 'ru')
      @log.puts "  ! #{src}: ru-страница #{ru_path} не найдена" if ru_path && !ru

      page ||= ::Page.new(path: path, lang: LANG, page_type: ::Page::PAGE_TYPES['статья'])
      @stats[page.new_record? ? :created : :updated] += 1
      page.assign_attributes(
        parent_id: author.id, title: title, is_published: true, is_deleted: false, is_search: true, is_past: true,
        body: result.body, references: references(vol, el, result),
        group_lang_id: group_for(page, ru, src),
      )
      page.assign_attributes(period_start: ru.period_start, period_end: ru.period_end) if ru&.period_start.present?
      page.save!
      @paths << page.path
      page
    end

    # Английская страница этого ru-труда, сделанная вручную (не импортом): тогда второй вариант не нужен
    def existing_translation(ru_path)
      ru = ru_path && ::Page.find_by(path_low: ru_path.downcase, lang: 'ru') or return
      ::Page.where(group_lang_id: ru.group_lang_id, lang: LANG).where("\"references\" IS NULL OR \"references\" NOT LIKE ?", "%#{SOURCE_MARK}%").pick(:path)
    end

    # С ru-страницей связываем, только если у неё ещё нет английской: у группы одна страница на язык
    def group_for(page, ru, src)
      return page.group_lang_id.presence || generate_id unless ru
      busy = ::Page.where(group_lang_id: ru.group_lang_id, lang: LANG).where.not(id: page.id).pick(:path)
      return ru.group_lang_id unless busy

      @log.puts "  ~ #{src}: у #{ru.path} уже есть en-страница #{busy}, связь языков не ставим"
      page.group_lang_id == ru.group_lang_id || page.group_lang_id.blank? ? generate_id : page.group_lang_id
    end

    def references(vol, el, result)
      notes = result.notes.map { "<li><p>#{_1}</p></li>" }.join
      pages = result.pages.join('–')
      vol_title = @map.dig('volumes', vol.code) || vol.title.sub(/\A[\w-]+\.\s*/, '')
      url = vol.url(el['id'])
      source = "Source: <em>#{vol.series}</em>, vol. #{vol.number}: <em>#{::ERB::Util.html_escape(vol_title)}</em>" \
               "#{", ed. #{vol.editors.join(', ')}" if vol.editors.any?}#{", pp. #{pages}" if pages.present?}. " \
               "Christian Classics Ethereal Library: <a href=\"#{url}\">#{url}</a>"
      "#{"<ol>#{notes}</ol>" if notes.present?}<p>#{source}</p>"
    end

    # Пункты меню на странице автора: категория -> труд (-> части)
    def add_to_menu(author, w, pages, subtitles)
      item = if w['menu']
        # готовый пункт меню автора (заготовка без ссылки): только вписываем в него адрес
        ::Menu.find_by(page_id: author.id, title: w['menu']).tap do |m|
          raise "#{w['src']}: у #{author.path} нет пункта меню «#{w['menu']}»" unless m
          m.update!(path: pages.first.path, is_empty: false)
        end
      else
        category = menu_item(author, nil, w['category'] || 'Works', nil)
        menu_item(author, category, w['title'], pages.first.path)
      end
      return if pages.size == 1

      pages.zip(subtitles).each { |page, subtitle| menu_item(author, item, subtitle, page.path) }
    end

    def menu_item(page, parent, title, path)
      scope = ::Menu.where(page_id: page.id, parent_id: parent&.id)
      menu = path ? scope.find_by(path: path) : scope.find_by(title: title, path: [nil, ''])
      return menu.tap { _1.update!(title: title) } if menu

      ::Menu.create!(page_id: page.id, parent_id: parent&.id, title: title, path: path, is_empty: false,
                     priority: scope.maximum(:priority).to_i + 1)
    end

    # en-страница автора: существующая (path) или новая по образцу ru-страницы (ru)
    def author_page(key)
      @authors ||= {}
      @authors[key] ||= begin
        a = @map.dig('authors', key) or raise "Автор #{key} не описан в карте"
        page = ::Page.find_by(path_low: a.fetch('path').downcase)
        if page
          raise "#{a['path']}: это не en-страница" unless page.lang == LANG
          page
        else
          create_author(key, a)
        end
      end
    end

    # Новая en-страница-список: автор в q-saints-en (в категории века) или раздел в другом списке (parent, parent_menu)
    def create_author(key, a)
      ru = a['ru'] && (::Page.find_by(path_low: a['ru'].downcase, lang: 'ru') or raise "#{key}: нет ru-страницы #{a['ru']}")
      parent = ::Page.find_by!(path_low: (a['parent'] || ROOT_PATH).downcase)
      is_group_free = ru && !::Page.exists?(group_lang_id: ru.group_lang_id, lang: LANG)
      page = ::Page.create!(
        path: a['path'], lang: LANG, page_type: ::Page::PAGE_TYPES['список'], parent_id: parent.id,
        title: a.fetch('title'), title_sub: a['title_sub'], is_published: true, is_search: true,
        group_lang_id: is_group_free ? ru.group_lang_id : generate_id,
      )
      @stats[:authors] += 1
      # категории трудов в том же порядке, что у ru-автора
      Array(a['categories']).each { menu_item(page, nil, _1, nil) }
      menu_item(parent, parent_category(parent, a), a['menu_title'] || a['title'], page.path)
      @log.puts "+ автор #{page.path}"
      page
    end

    def parent_category(parent, a)
      return menu_item(parent, nil, a['parent_menu'], nil) if a['parent_menu']

      ::Menu.find_by(page_id: parent.id, parent_id: nil, title: a.fetch('century')) ||
        # новый век встаёт по порядку: у категорий веков priority = номер века
        ::Menu.create!(page_id: parent.id, title: a['century'], is_empty: false, priority: a['century'][/\d+/].to_i)
    end

    def volume(code)
      @volume = nil if @volume && @volume.code != code
      @volume ||= ::Ccel::Volume.load(@dir, code)
    end

    # "Book I. Wherein is described..." -> "Book I"; "Chapter IV.—Text." -> "4. Text"
    def clean_title(title)
      return "Book #{title.strip.delete('.')}" if title.strip.match?(/\A[IVXLC]+\.?\z/)
      title[/\A(?:Book|Part)\s+[IVXLC\d]+\b/i] || ::Ccel::Renderer.short_title(title).sub(/[.\s]+\z/, '')
    end

    def slug(str)
      ::I18n.transliterate(str.to_s).downcase.gsub(/[^a-z0-9]+/, '-').gsub(/\A-|-\z/, '')[0, 80].sub(/-\z/, '')
    end

    def generate_id = ::SecureRandom.alphanumeric(10)
  end
end

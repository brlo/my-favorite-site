# Загружает переводы статей из YAML: создаёт страницу на новом языке в языковой группе оригинала
# и добавляет её в меню страницы-списка (например, en-q). Существующие страницы не трогает,
# поэтому один и тот же файл можно безопасно прогнать и локально, и в проде, и повторно.
#
#   TranslationImporter.call(::YAML.load_file('db/translations/en/q_pilot.yml')) -> [сообщения]
#
# Формат файла:
#   lang: en
#   list: en-q                  # страница-список, в меню которой добавляем пункты
#   folders:                    # разделы меню без ссылки; недостающие создаём (необязательно)
#     - { path: Church/Scripture, priority: 1 }
#   pages:
#     - src: Христос-на-небе    # path оригинала (язык оригинала - src_lang, по умолчанию ru)
#       path: k3Fz_Christ_in_Heaven
#       title: Christ in Heaven
#       title_sub:
#       meta_desc: ...
#       menu: { parent: God/Son, title: Christ in Heaven, priority: 6 }
#       body: <html>
#       references: <html>      # примечания внизу статьи (необязательно)
class TranslationImporter
  def self.call(data, is_dry_run: false, is_published: false) = new(data, is_dry_run:, is_published:).perform

  def initialize(data, is_dry_run: false, is_published: false)
    @data = data
    @lang = data.fetch('lang')
    @src_lang = data.fetch('src_lang', 'ru')
    @is_dry_run = is_dry_run
    @is_published = is_published
  end

  def perform
    list = ::Page.find_by(path_low: @data.fetch('list').downcase, lang: @lang)
    return ["нет страницы-списка: #{@data['list']}"] unless list

    log = @data.fetch('folders', []).filter_map { ensure_folder(list, _1) }
    @created = []
    log += ::Page.without_index_now { @data.fetch('pages').map { import_page(_1, list) } }
    # поисковикам — одной пачкой, а не запросом на каждую статью
    ::Page.notify_search_engines_about(@created)
    log
  end

  private

  # "Church/Scripture" -> пункт меню "Scripture" (без ссылки) внутри "Church"; родитель должен уже быть
  def ensure_folder(list, folder)
    *parents, title = folder.fetch('path').split('/')
    parent = find_menu_parent(list, parents.join('/'))
    return "нет раздела для папки: #{folder['path']}" if parent == false
    return if ::Menu.exists?(page_id: list.id, parent_id: parent&.id, title: title)
    if @is_dry_run
      (@planned_folders ||= []) << folder['path']
      return "[DRY RUN] папка меню: #{folder['path']}"
    end

    ::Menu.create!(page_id: list.id, parent_id: parent&.id, title: title, priority: folder['priority'])
    "папка меню: #{folder['path']}"
  end

  def import_page(item, list)
    src = ::Page.find_by(lang: @src_lang, path: item.fetch('src'))
    return "нет оригинала: #{item['src']}" unless src

    existing = ::Page.find_by(lang: @lang, group_lang_id: src.group_lang_id)
    return "пропуск #{item['src']}: перевод уже есть (#{existing.path})" if existing
    return "пропуск #{item['src']}: путь занят (#{item['path']})" if ::Page.exists?(path_low: item.fetch('path').downcase)

    menu_parent = find_menu_parent(list, item.dig('menu', 'parent'))
    # в холостом прогоне папки не создаются, но будут созданы при настоящем
    is_planned = @planned_folders&.include?(item.dig('menu', 'parent'))
    if menu_parent == false && !is_planned
      return "пропуск #{item['src']}: в меню #{list.path} нет раздела #{item.dig('menu', 'parent')}"
    end

    return "[DRY RUN] создано: #{@lang}:#{item['path']} (#{item['title']})" if @is_dry_run

    ::Page.transaction do
      page = ::Page.create!(
        lang: @lang, group_lang_id: src.group_lang_id, parent_id: list.id,
        path: item['path'], title: item['title'], title_sub: item['title_sub'], meta_desc: item['meta_desc'],
        body: item['body'], references: item['references'], page_type: src.page_type, edit_mode: src.edit_mode, user_id: src.user_id,
        is_published: @is_published,
      )
      @created << page
      if item['menu']
        title = item.dig('menu', 'title') || page.title
        # пункт-заготовка без ссылки с тем же названием (так готовят меню заранее) — заполняем его
        stub = ::Menu.where(page_id: list.id, parent_id: menu_parent&.id, title: title, path: [nil, '']).first
        if stub
          stub.update!(path: page.path)
        else
          ::Menu.create!(
            page_id: list.id, parent_id: menu_parent&.id, path: page.path,
            title: title, priority: item.dig('menu', 'priority'),
          )
        end
      end
    end
    "создано: #{@lang}:#{item['path']} (#{item['title']})"
  end

  # "God/Son" -> пункт меню "Son" внутри "God"; nil - корень меню; false - раздел не найден
  def find_menu_parent(list, titles)
    return nil if titles.blank?

    titles.split('/').reduce(nil) do |parent, title|
      ::Menu.find_by(page_id: list.id, parent_id: parent&.id, title: title) || (return false)
    end
  end
end

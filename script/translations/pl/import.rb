# Импорт латинских страниц (автор + труды) из плана, который собирает build.py.
#
#   bin/rails runner script/translations/pl/import.rb tmp/pl/4/plan.json [DRY_RUN=1] [UPDATE=1] [PUBLISH=1]
#
# План (JSON): lang, list (путь страницы-списка), author {path,title,title_sub,ru,menu_folder,
# menu_replace,menu_title,body,references,page_type,seo_kind}, folders [{title,priority}],
# pages [{path,title,ru,folder,priority,body,references,page_type,seo_kind}].
#
# Что делает:
#  - создаёт страницу автора (page_type 4) в списке, ставит пункт меню в папку века
#    (заготовку с тем же названием заполняет);
#  - на странице автора создаёт папки (folders) и пункты трудов;
#  - страницы трудов — дочерние к странице автора, пункт меню — в папке автора;
#  - группу языков берёт у ru-страницы, если она ещё не занята другим la-переводом,
#    иначе выдаёт новую (у группы одна страница на язык — см. pages_controller).
#
# Повторный прогон безопасен: существующие страницы пропускаются (с --update — обновляются).
require 'json'
require_relative 'menu_tidy'

path = ARGV[0] or abort 'usage: import.rb PLAN.json [DRY_RUN=1] [UPDATE=1] [PUBLISH=1]'
is_dry_run = ENV['DRY_RUN'].present?
is_update = ENV['UPDATE'].present?
is_published = ENV['PUBLISH'].present?
is_prune = ENV['PRUNE'].present?
plan = JSON.parse(File.read(path))

LANG = plan.fetch('lang').freeze
list = ::Page.find_by(lang: LANG, path_low: plan.fetch('list').downcase) or abort "нет списка #{plan['list']}"
log = []

def new_group_id = ::SecureRandom.alphanumeric(10)

def group_for(page, ru)
  # группа «один перевод на язык»: если у ru-страницы уже есть la-перевод, даём новую
  return page.group_lang_id.presence || new_group_id unless ru
  if page.group_lang_id.blank? && !::Page.exists?(lang: LANG, group_lang_id: ru.group_lang_id)
    ru.group_lang_id
  else
    page.group_lang_id.presence || new_group_id
  end
end

ru_page = ::Page.find_by(lang: 'ru', path_low: plan.dig('author', 'ru').to_s.downcase)
log << "! нет ru-страницы автора #{plan.dig('author', 'ru')}" unless ru_page

def menu_item(page_id, parent_id, title, path, priority)
  scope = ::Menu.where(page_id: page_id, parent_id: parent_id)
  found = path ? scope.find_by(path: path) : scope.find_by(title: title, path: [nil, ''])
  if found
    found.update!(title: title)
    found.update!(priority: priority) if priority
    return found
  end

  ::Menu.create!(page_id: page_id, parent_id: parent_id, title: title, path: path,
                 priority: priority || (scope.maximum(:priority).to_i + 1), is_empty: false)
end

a = plan.fetch('author')
author = ::Page.find_by(lang: LANG, path_low: a.fetch('path').downcase)
if author && !is_update
  log << "пропуск автора #{a['path']}: уже есть"
else
  attrs = {
    title: a['title'], title_sub: a['title_sub'], body: a['body'], references: a['references'],
    page_type: a['page_type'], seo_kind: a['seo_kind'], is_published: is_published, parent_id: list.id,
  }
  if is_dry_run
    log << "[DRY RUN] автор #{author ? 'обновление' : 'создание'}: #{a['path']} (#{a['title']})"
  else
    author ||= ::Page.new(lang: LANG, path: a['path'], user_id: 1)
    author.assign_attributes(attrs)
    author.group_lang_id = group_for(author, ru_page)
    author.save!
    log << "#{attrs[:page_type] == 1 ? '' : ''}автор #{author.previously_new_record? ? 'создан' : 'обновлён'}: #{author.path}"
  end
end

# --- меню: автор в папке века списка
folder_menu = ::Menu.find_by(page_id: list.id, parent_id: nil, title: a['menu_folder'])
log << "! в меню #{list.path} нет папки «#{a['menu_folder']}»" unless folder_menu
if author && folder_menu && !is_dry_run
  stub = ::Menu.where(page_id: list.id, parent_id: folder_menu.id, title: a['menu_replace'], path: [nil, '']).first
  if stub
    stub.update!(path: author.path, title: a['menu_title'] || stub.title)
  else
    menu_item(list.id, folder_menu.id, a['menu_title'] || a['title'], author.path, nil)
  end
elsif author && folder_menu
  log << "[DRY RUN] пункт меню автора: #{a['menu_folder']} / #{a['menu_title']}"
end

# --- меню автора: папки и труды
folders = {}
plan.fetch('folders', []).each do |f|
  if author && !is_dry_run
    folders[f['title']] = menu_item(author.id, nil, f['title'], nil, f['priority'])
  else
    log << "[DRY RUN] папка меню автора: #{f['title']}"
  end
end

plan.fetch('pages').each do |w|
  # ru-страница необязательна: труд может быть взят по подлинности (без русского перевода)
  ru = w['ru'].presence && ::Page.find_by(lang: 'ru', path_low: w['ru'].downcase)
  log << "! #{w['path']}: нет ru-страницы #{w['ru']}" if w['ru'].present? && !ru
  page = ::Page.find_by(lang: LANG, path_low: w['path'].downcase)
  next log << "пропуск #{w['path']}: уже есть" if page && !is_update

  if is_dry_run
    log << "[DRY RUN] труд #{page ? 'обновление' : 'создание'}: #{w['path']} (#{w['title']}), #{w['body'].bytesize / 1024} КБ"
    next
  end

  page ||= ::Page.new(lang: LANG, path: w['path'], user_id: 1)
  page.assign_attributes(
    title: w['title'], body: w['body'], references: w['references'], page_type: w['page_type'],
    seo_kind: w['seo_kind'], is_published: is_published, parent_id: author.id,
    is_past: true,   # «значимый текст из прошлого», как у ru-трудов
  )
  page.group_lang_id = group_for(page, ru)
  page.parent_id = author.id      # при обновлении переносим труд к нужному автору
  page.page_type = w['page_type']
  page.seo_kind = w['seo_kind']
  page.save!
  folder = folders[w['folder']]
  menu_item(author.id, folder&.id, w['title'], page.path, w['priority'])
  log << "труд #{page.previously_new_record? ? 'создан' : 'обновлён'}: #{page.path} (#{w['title']})"
end

if is_prune && author
  planned = plan['pages'].map { _1['path'].downcase }
  extra = ::Page.where(lang: LANG, parent_id: author.id, page_type: 1)
                .where.not(path_low: planned).to_a
  extra.each do |page|
    ::Menu.where(page_id: author.id, path: page.path).delete_all
    ::Menu.where(page_id: list.id, path: page.path).delete_all
    page.destroy!
    log << "удалена лишняя страница: #{page.path} (#{page.title})"
  end
  stale = ::Menu.where(page_id: author.id).where.not(path: [nil, ''])
                .where.not(path: plan['pages'].map { _1['path'] }).to_a
  if stale.any?
    stale.each { |m| m.destroy! }
    log << "удалено лишних пунктов меню: #{stale.size}"
  end
end

::MenuTidy.tidy_author(author) if author && !is_dry_run

puts log
puts "страниц: #{plan['pages'].size}, автор: #{a['path']}"

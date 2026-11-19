# Инвентарь долгосрочного перевода раздела цитат: дерево папок RU-списка и готовность перевода.
#
#   bin/rails runner script/translations/q_inventory.rb LANG TARGET_LIST [--folders|--todo|--all]
#
# LANG        — язык перевода (en, ja, ko, …)
# TARGET_LIST — путь страницы-списка перевода (en-saints-q, jp_q, …)
# RU-эталон   — страница q-saints и её меню (папки/статьи, порядок priority).
#
# Печатает по каждой папке: сколько статей, сколько готово/осталось, объём
# оставшихся; по каждой статье: [x] готово, [ ] нет, [—] заглушка в RU
# (body < 40 символов — страница отдаёт 404), размер и число цитат.
#
# --folders — только сводка по папкам; --todo — только неготовые статьи; --all — всё (по умолчанию).
# Удобно для планирования партии: обходить папки в порядке меню, за партию брать
# одну папку (или часть, если статьи большие) и после партии обновлять статус
# в docs/english-quotes-project.md.
require 'json'

lang, target, *flags = ARGV
abort 'usage: q_inventory.rb LANG TARGET_LIST [--folders|--todo|--all]' unless lang && target
mode = flags.find { |f| f.start_with?('--') }&.delete_prefix('--') || 'all'

RU_LIST = 'q-saints'
ru_list = Page.find_by(lang: 'ru', path_low: RU_LIST) or abort "нет RU-списка #{RU_LIST}"
target_list = Page.find_by(lang: lang, path_low: target.downcase) or abort "нет списка #{target} (#{lang})"

menus = Menu.where(page_id: ru_list.id).to_a
by_parent = menus.group_by(&:parent_id)
items = menus.select { |m| m.path.present? }
ru_pages = Page.where(lang: 'ru', path: items.map(&:path)).index_by(&:path)
groups = ru_pages.values.filter_map(&:group_lang_id).uniq
targets = Page.where(lang: lang, group_lang_id: groups).index_by(&:group_lang_id)
stub = ->(ru) { ru.nil? || ru.body.to_s.strip.length < 40 }
size_kb = ->(bytes) { (bytes / 1024.0).round }
quotes = ->(body) { body.to_s.scan(/<blockquote/).size }

# Дерево: папки — меню без path, статьи — с path; рекурсия по parent_id.
stat = lambda do |parent_id|
  result = { total: 0, done: 0, todo: 0, stub: 0, todo_bytes: 0, articles: [], folders: [] }
  (by_parent[parent_id] || []).sort_by { |m| [m.priority.to_i, m.id] }.each do |m|
    if m.path.present?
      ru = ru_pages[m.path]
      next result[:stub] += 1 if stub.(ru)

      tg = ru && targets[ru.group_lang_id]
      is_done = tg && tg.body.to_s.strip.length >= 40
      n = ru.body.to_s.size
      qn = quotes.(ru.body)
      result[:total] += 1
      is_done ? result[:done] += 1 : (result[:todo] += 1; result[:todo_bytes] += n)
      result[:articles] << { menu: m, ru: ru, done: is_done, kb: size_kb.(n), quotes: qn }
    else
      sub = stat.(m.id)
      %i[total done todo stub todo_bytes].each { |k| result[k] += sub[k] }
      result[:folders] << { menu: m, stat: sub }
      result[:articles].concat(sub[:articles])
    end
  end
  result
end
tree = stat.(nil)
folders = tree[:folders]

fmt = ->(s) { "#{s[:done]}/#{s[:total]} готово, осталось #{s[:todo]} (~#{(s[:todo_bytes] / 1024.0).round} КБ)#{s[:stub].positive? ? ", пустых заготовок #{s[:stub]}" : ''}" }
case mode
when 'folders'
  folders.each { |f| puts "#{f[:menu].title} — #{fmt.(f[:stat])}" }
when 'todo'
  folders.each do |f|
    todo = f[:stat][:articles].reject { |a| a[:done] }
    next if todo.empty?
    puts "== #{f[:menu].title}"
    todo.each { |a| puts "  [ ] #{a[:ru].path} — #{a[:ru].title} (#{a[:kb]} КБ, цитат #{a[:quotes]})" }
  end
when 'all'
  folders.each do |f|
    puts "== #{f[:menu].title} — #{fmt.(f[:stat])}"
    f[:stat][:articles].each do |a|
      puts "  #{a[:done] ? '[x]' : '[ ]'} #{a[:ru].path} — #{a[:ru].title} (#{a[:kb]} КБ, цитат #{a[:quotes]})"
    end
  end
when 'next'
  f = folders.find { |x| x[:stat][:todo].positive? }
  abort 'всё готово' unless f
  puts "Следующая партия: #{f[:menu].title} — #{fmt.(f[:stat])}"
  f[:stat][:articles].reject { |a| a[:done] }.each do |a|
    puts "  [ ] #{a[:ru].path} — #{a[:ru].title} (#{a[:kb]} КБ, цитат #{a[:quotes]})"
  end
end
puts "ИТОГО: #{tree[:done]}/#{tree[:total]} готово, осталось #{tree[:todo]} (~#{(tree[:todo_bytes] / 1024.0).round} КБ)#{tree[:stub].positive? ? ", пустых заготовок #{tree[:stub]}" : ''}"

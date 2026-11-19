# Инвентарь святоотеческой библиотеки: авторы/труды RU-эталона и покрытие переводом.
#
#   bin/rails runner script/translations/library_status.rb LANG [--folders|--authors|--gaps|--works AUTHOR]
#
# LANG        — язык перевода (en, ja, ko, …)
# RU-эталон   — страница church_writers (список библиотеки) и её меню веков;
#               авторы — пункты меню (page_type 4), труды — дочерние страницы автора.
#
# Печатает по векам: авторов, трудов RU, переведено, не хватает, объём RU;
# в режиме --authors — каждого автора с числами; --gaps — только неполные;
# --works AUTHOR — список трудов одного автора (путь или часть названия).
require 'json'


lang, *args = ARGV
abort 'usage: library_status.rb LANG [--folders|--authors|--gaps|--works AUTHOR]' unless lang
mode = args.find { |a| a.start_with?('--') }&.delete_prefix('--') || 'folders'
author_query = (mode == 'works' ? args[(args.index('--works') || 0) + 1] : nil)

ru_list = Page.find_by(lang: 'ru', path_low: 'church_writers') or abort 'нет RU-списка church_writers'
menus = Menu.where(page_id: ru_list.id).to_a
by_parent = menus.group_by(&:parent_id)

def body_size(p) = p&.body.to_s.size
def big?(p) = p && p.body.to_s.strip.length >= 40

# Авторы — дочерние страницы списка (page_type 4); век берём из цепочки меню списка,
# если автор в меню размечен (часть авторов в меню не выведена — это допустимо).
all_menus = Menu.where(page_id: ru_list.id).to_a
menu_by_id = all_menus.index_by(&:id)
menu_by_path = all_menus.select(&:path).index_by(&:path)
century_of = lambda do |menu|
  chain = []
  x = menu&.parent_id
  while x && (pm = menu_by_id[x])
    chain.unshift(pm.title)
    x = pm.parent_id
  end
  chain.empty? ? '—' : chain.join(' / ')
end
authors = Page.where(lang: 'ru', parent_id: ru_list.id, page_type: 4).order(:id).map do |ru|
  menu = menu_by_path[ru.path]
  { menu: menu, ru: ru, century: menu ? century_of.(menu) : '—' }
end

# Покрытие: по каждой группе трудов — есть ли страница перевода/греч./лат.
ru_authors = authors.map { _1[:ru] }
ru_works = Page.where(lang: 'ru', parent_id: ru_authors.map(&:id)).to_a
groups = ru_works.filter_map(&:group_lang_id).uniq
pages = Page.where(lang: %w[ru en grc la] + ([lang] - %w[ru en]).to_a).where(group_lang_id: groups).to_a
by_group = pages.group_by(&:group_lang_id)
works_by_author = ru_works.group_by(&:parent_id)
en_authors = Page.where(lang: lang, group_lang_id: ru_authors.map(&:group_lang_id)).index_by(&:group_lang_id)

rows = authors.map do |a|
  works = works_by_author[a[:ru].id] || []
  en_author = en_authors[a[:ru].group_lang_id]
  # Надёжнее считать труды EN по дочерним страницам EN-автора: членение трудов
  # на части у языков разное, group_lang_id даёт лишь пересечение.
  en_children = en_author ? Page.where(lang: lang, parent_id: en_author.id).to_a : []
  en = big?(en_author) ? en_children.count { big?(_1) } : works.count { |w| by_group[w.group_lang_id].to_a.any? { |pp| pp.lang == lang && big?(pp) } }
  grc = works.count { |w| by_group[w.group_lang_id].to_a.any? { |pp| pp.lang == 'grc' && big?(pp) } }
  la = works.count { |w| by_group[w.group_lang_id].to_a.any? { |pp| pp.lang == 'la' && big?(pp) } }
  a.merge(works: works, en: en, grc: grc, la: la,
          missing: [works.size - en, 0].max, kb: (works.sum { body_size(_1) } / 1024.0).round,
          en_author: big?(en_author))
end

case mode
when 'works'
  q = author_query.to_s.downcase
  row = rows.find { |r| r[:ru].path.downcase.include?(q) || r[:ru].title.downcase.include?(q) }
  abort "автор не найден: #{author_query}" unless row
  puts "#{row[:ru].title} (#{row[:ru].path}) — #{row[:century]}, трудов #{row[:works].size}, EN #{row[:en]}, grc #{row[:grc]}, la #{row[:la]}"
  row[:works].each do |w|
    langs = by_group[w.group_lang_id].to_a.map(&:lang).uniq.sort.join(',')
    puts format('  %-60s %7d байт  [%s]', w.path, body_size(w), langs)
  end
else
  folder_priority = Menu.where(page_id: ru_list.id).where(path: nil).to_a.to_h { |m| [m.title, m.priority.to_i] }
  centuries = rows.group_by { _1[:century] }.sort_by { |c, _| [c == '—' ? 9999 : (folder_priority[c] || 500), c] }
  centuries.each do |century, list|
    total = list.sum { _1[:works].size }
    en = list.sum { _1[:en] }
    kb = list.sum { _1[:kb] }
    next if mode == 'gaps' && list.empty?
    puts "== #{century}: авторов #{list.size} (#{list.count { _1[:en_author] }}/#{list.size} с EN-страницей), трудов RU #{total}, EN #{en}, не хватает #{total - en} (~#{kb} КБ)"
    list.each do |r|
      next if mode == 'gaps' && r[:missing].zero?
      next if mode == 'folders'
      puts format('  %-52s работ RU %3d | EN %3d | grc %3d | la %3d | не хватает %3d | %5d КБ%s',
                  r[:ru].title[0, 52], r[:works].size, r[:en], r[:grc], r[:la], r[:missing], r[:kb],
                  r[:en_author] ? '' : '  [нет EN-страницы автора]')
    end
  end
  total_works = rows.sum { _1[:works].size }
  total_en = rows.sum { _1[:en] }
  puts "ИТОГО: авторов #{rows.size} (#{rows.count { _1[:en_author] }} с EN-страницей), трудов RU #{total_works}, EN #{total_en}, не хватает #{total_works - total_en}"
end

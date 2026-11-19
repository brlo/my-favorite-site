# Инвентарь RU-раздела q для el-проекта (списка el ещё нет, всё = "осталось").
#   docker exec bibleox bash -lc 'cd /app && bin/rails runner tmp/el_quotes/inventory.rb [--all]'
# Иначе — только сводка по папкам (и проекты партий).
ru_list = Page.find_by(lang: 'ru', path_low: 'q') or abort 'нет ru списка q'

menus = Menu.where(page_id: ru_list.id).to_a
by_parent = menus.group_by(&:parent_id)
items = menus.select { |m| m.path.present? }
ru_pages = Page.where(lang: 'ru', path: items.map(&:path)).index_by(&:path)
stub = ->(p) { p.nil? || p.body.to_s.strip.length < 40 }
kb = ->(n) { (n / 1024.0).round }
quotes = ->(body) { body.to_s.scan(/<blockquote/).size }

stat = lambda do |parent_id|
  r = { total: 0, stub: 0, bytes: 0, q: 0, articles: [], folders: [] }
  (by_parent[parent_id] || []).sort_by { |m| [m.priority.to_i, m.id] }.each do |m|
    if m.path.present?
      p = ru_pages[m.path]
      next r[:stub] += 1 if stub.(p)

      n = p.body.to_s.size
      r[:total] += 1
      r[:bytes] += n
      r[:q] += quotes.(p.body)
      r[:articles] << { menu: m, p: p, kb: kb.(n), q: quotes.(p.body) }
    else
      sub = stat.(m.id)
      %i[total stub bytes q].each { |k| r[k] += sub[k] }
      r[:folders] << { menu: m, stat: sub }
      r[:articles].concat(sub[:articles])
    end
  end
  r
end
tree = stat.(nil)

mode = ARGV[0].to_s.delete_prefix('--')
if mode == 'all'
  tree[:folders].each do |f|
    puts "== #{f[:menu].title} — #{f[:stat][:total]} ст., ~#{kb.(f[:stat][:bytes])} КБ, цитат #{f[:stat][:q]}"
    f[:stat][:articles].each { |a| puts "  #{a[:p].path} — #{a[:p].title} (#{a[:kb]} КБ, цитат #{a[:q]})" }
  end
else
  tree[:folders].each do |f|
    s = f[:stat]
    puts "#{f[:menu].title.ljust(60)} #{s[:total].to_s.rjust(3)} ст. #{kb.(s[:bytes]).to_s.rjust(5)} КБ #{s[:q].to_s.rjust(4)} цит."
  end
  # подпапки-наследники (папки внутри папок, без статей напрямую)
  puts
  puts '== Папки верхнего уровня (детально):'
  tree[:folders].each { |f| puts "#{f[:menu].title}: подпапок #{f[:stat][:folders].size}" }
end
puts
puts "ИТОГО: #{tree[:total]} ст., ~#{kb.(tree[:bytes])} КБ, цитат #{tree[:q]}, пустых заготовок #{tree[:stub]}"

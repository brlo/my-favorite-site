# Печатает дерево меню jp_q: путь-папки, приоритет, path (пусто = папка)
list = Page.find_by!(lang: 'ja', path_low: 'jp_q')
all = Menu.where(page_id: list.id).to_a
walk = lambda do |pid, prefix|
  all.select { _1.parent_id == pid }.sort_by { [_1.priority.to_i, _1.id] }.each do |m|
    full = [prefix, m.title].compact.join('/')
    puts "#{m.path.blank? ? 'F' : 'P'}\t#{full}\t#{m.priority}\t#{m.path}"
    walk.(m.id, full)
  end
end
walk.(nil, nil)

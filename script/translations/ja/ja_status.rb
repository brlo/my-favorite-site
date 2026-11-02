require 'yaml'
ja_groups = Page.where(lang: 'ja').pluck(:group_lang_id).to_set
todo = []; done = []
Dir['db/translations/en/*.yml'].sort.each do |f|
  y = YAML.load_file(f)
  folders = (y['folders'] || []).map { _1['path'] }
  items = y['pages'].map do |it|
    src = Page.find_by(lang: 'ru', path: it['src'])
    has = src && ja_groups.include?(src.group_lang_id)
    (has ? done : todo) << it['src']
    "#{has ? 'JA ' : '   '}#{it['src']} -> #{it.dig('menu','parent')} / #{it.dig('menu','title')} [#{it['body'].to_s.size}]"
  end
  puts "== #{File.basename(f)} folders=#{folders}"
  puts items
end
puts "todo=#{todo.size} done=#{done.size}"

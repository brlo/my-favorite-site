# Обновить body/references/title уже импортированных японских статей из YAML
# bin/rails runner tmp/ja_sync.rb db/translations/ja/FILE.yml [path ...]
require 'yaml'
file, *only = ARGV
YAML.load_file(file)['pages'].each do |it|
  next if only.any? && !only.include?(it['path'])
  pg = Page.find_by!(lang: 'ja', path: it['path'])
  attrs = { body: it['body'], title: it['title'] }
  attrs[:references] = it['references'] if it.key?('references')
  attrs[:title_sub] = it['title_sub'] if it.key?('title_sub')
  attrs[:meta_desc] = it['meta_desc'] if it.key?('meta_desc')
  pg.update!(attrs)
  puts "обновлено: #{pg.path}"
end

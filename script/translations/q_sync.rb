# bin/rails runner script/translations/q_sync.rb LANG FILE [path...] — обновить уже импортированные страницы из YAML
require 'yaml'
lang, file, *only = ARGV
YAML.load_file(file)['pages'].each do |it|
  next if only.any? && !only.include?(it['path'])
  pg = Page.find_by!(lang: lang, path: it['path'])
  pg.update!(it.slice('title', 'title_sub', 'meta_desc', 'references', 'body'))
  puts "обновлено: #{pg.path}"
end

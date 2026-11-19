# Сборка партии раздела цитат: применить черновики тел из каталога в YAML.
#
#   bin/rails runner script/translations/q_apply.rb LANG YAML DIR [--only path1,path2]
#
# Для каждой страницы YAML, у которой есть DIR/out/<EN path>.html, тело заменяется
# черновиком и ставится update: true (для импорта на прод/обновления). YAML пишется
# целиком (YAML.dump) — это нормально: дифф большой из-за переносов строк.
#
# После сборки: q_parity.rb LANG YAML (должен быть чист), затем q_sync.rb на dev.
require 'yaml'

lang, file, dir, *flags = ARGV
abort 'usage: q_apply.rb LANG YAML DIR [--only path1,path2]' unless lang && file && dir
only = nil
if (i = flags.index('--only'))
  only = flags[i + 1].to_s.split(',')
end
data = YAML.load_file(file)
applied = []
missing = []
data.fetch('pages').each do |p|
  path = p['path']
  next if only && !only.include?(path)

  draft = File.join(dir, 'out', "#{path}.html")
  if File.exist?(draft)
    body = File.read(draft)
    raise "пустой черновик: #{draft}" if body.strip.length < 40
    p['body'] = body
    p['update'] = true
    applied << path
  elsif p['body'].to_s.strip.length < 40
    missing << path
  end
end
File.write(file, YAML.dump(data))
puts "применено: #{applied.size} (#{applied.join(', ')})" if applied.any?
puts "без черновика: #{missing.join(', ')}" if missing.any?
puts 'ничего не применено' if applied.empty?

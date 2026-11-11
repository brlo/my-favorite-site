# Шаг 5: унификация католических имён к формам 和合本 (伯多禄→彼得, 保禄→保罗, 梅瑟→摩西).
# Авторские страницы (Тихон, раздел 祈祷文) не трогаются никогда.
# bin/rails runner script/translations/bible/unify_names_zh.rb [APPLY=1]
REPL = { '伯多禄' => '彼得', '保禄' => '保罗', '梅瑟' => '摩西' }.freeze
AUTHOR_RE = /(祈祷|吉洪|舍夫库诺夫)/
total = 0
::Page.where(lang: 'zh-Hans').find_each do |page|
  next if AUTHOR_RE.match?(page.path)
  new_body = REPL.reduce(page.body.to_s) { |t, (from, to)| t.gsub(from, to) }
  new_refs = REPL.reduce(page.references.to_s) { |t, (from, to)| t.gsub(from, to) }
  changed = REPL.sum { |from, _| page.body.to_s.scan(from).size + page.references.to_s.scan(from).size }
  next if changed.zero?
  puts "#{page.path}: #{changed} (#{REPL.filter_map { |f, t| "#{f}→#{t}:#{page.body.to_s.scan(f).size}" }.join(', ')})"
  if ENV['APPLY'] == '1'
    page.update!(body: new_body, references: new_refs)
  else
    puts '  (DRY RUN)'
  end
  total += changed
end
puts "итого: #{total}#{ENV['APPLY'] == '1' ? '' : ' (DRY RUN - ничего не изменено; APPLY=1 чтобы применить)'}"

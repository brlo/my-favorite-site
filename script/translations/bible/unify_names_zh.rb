# Шаг 5: унификация католических имён 思高 к формам 和合本.
# Авторские страницы и молитвы не трогаются никогда: Тихон, раздел 祈祷文,
# каноны/弗坐词/信经/时课/礼仪, Житие Марии Египетской (там авторская помета
# «人名按天主教译法译出») и стр. Sophronius (玛利亚 — в названии книги).
# bin/rails runner script/translations/bible/unify_names_zh.rb [APPLY=1]
REPL = {
  # длинные формы раньше коротких
  '巴尔多禄茂' => '巴多罗买', '玛弟亚' => '马提亚', '雅各伯' => '雅各',
  '马尔谷' => '马可', '斐理伯' => '腓力', '伯多禄' => '彼得',
  '保禄' => '保罗', '梅瑟' => '摩西', '多默' => '多马',
  '玛窦' => '马太', '若望' => '约翰', '玛利亚' => '马利亚',
}.freeze
AUTHOR_RE = /(祈祷|吉洪|舍夫库诺夫|颂典|弗坐词|信经|时课|圣体血礼仪|聖瑪麗|索弗罗尼乌斯)/
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

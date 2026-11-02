# После смены перевода Библии: какие цитаты исходника больше не находятся и как теперь звучат их стихи.
#   bin/rails runner script/translations/q_rephrase.rb LANG db/translations/LANG/src/NAME.txt
# Печатает: номер строки, ссылку, старые фразы, которых нет в новом тексте, и сам новый текст первой ссылки.
lang, file = ARGV
tr = BibleLinker::BIBLE_BY_LANG.fetch(lang)
expand = ->(ls) { ls.split(',').flat_map { |x| a, z = x.split('-').map(&:to_i); (a..(z || a)).to_a } }
norm = ->(t) { t.to_s.gsub(/\[[^\]]*\]/, '').gsub(/<[^>]+>/, '').gsub(/[\s‘’'"“”]/, '') }
File.readlines(file, chomp: true).each_with_index do |l, i|
  next unless l.start_with?('> ')
  head = l[2..].split(/\s*~~\s*/, 2).first
  ref, *phs = head.split(/\s*::\s*/)
  bk, rest = ref.split(';').first.strip.split(/\s+/)
  ch, ls = rest.split(':')
  text = Verse.where(tr_code: tr, book: bk, chapter: ch.to_i, line: expand.(ls)).order(:line).map { "[#{_1.line}]#{_1.text}" }.join(' ')
  bad = phs.map(&:strip).reject(&:empty?).reject { norm.(text).include?(norm.(_1.sub(/\A(!|<<|>>)/, ''))) }
  next if bad.empty?

  puts "#{i + 1}| #{ref} | #{bad.join(' :: ')}", "   #{text}"
end

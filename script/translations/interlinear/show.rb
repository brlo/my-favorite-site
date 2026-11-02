# show.rb FILE BOOK CH : первые слова каждой json-строки и текст стихов
require 'json'
file, book, ch = ARGV[0], ARGV[1], ARGV[2].to_i
lines = File.readlines(file, chomp: true)
s = lines.index { _1 =~ /^# \w+ ch#{ch}\z/i }
e = lines.index.with_index { |l, i| i > s && l.include?("chapter: #{ch},") }
(s..e).each do |i|
  l = lines[i].strip
  next unless l.start_with?('{')
  ws = l.scan(/"w"\s*:\s*"([^"]*)"/).flatten
  puts "L#{i + 1} (#{ws.size}w): #{ws.first(6).join(' ')} ... #{ws.last(4).join(' ')}"
end
::Verse.where(tr_code: 'gr-ru', book: book, chapter: ch).order(:line).each { |v| puts "#{v.line}: #{v.data['w'].join(' ')}" }

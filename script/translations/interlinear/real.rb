# real.rb FILE ch1,ch2@from,... — импорт выбранных глав; "3@14" — начать с 14-го стиха
require 'json'
file = ARGV[0]
plan = ARGV[1].split(',').to_h { |s| c, f = s.split('@'); [c.to_i, (f || 1).to_i] }
clean = ->(w) { ::DictWord.word_clean_diacritic_only_gr(w.to_s.tr('армкнvгфет', 'αρμκννγφετ')) }
lines = File.readlines(file, chomp: true); cur = nil; pending = nil
lines.each do |l|
  if l =~ /^json = \[/ then cur = []
  elsif l.start_with?(']; nil') then pending = cur; cur = nil
  elsif l =~ /add_interliner\(book: '(\w+)', chapter: (\d+), start_line: (\d+)/ && pending
    book, ch = $1, $2.to_i
    if (from = plan[ch])
      data = pending.select { clean.(_1['w']).present? }
      # пропускаем слова стихов до from
      Verse.where(tr_code: 'gr-ru', book: book, chapter: ch).where('line < ?', from).order(:line).each do |v|
        v.data['w'].each do |w|
          next if clean.(w).blank?
          raise "skip mismatch #{v.line}: #{w} / #{data.first['w']}" unless clean.(w) == clean.(data.first['w']) || (w == 'δι᾿' && data.first['w'] == 'διὰ')
          data.shift
        end
      end
      ::InterlinerCreator.add_interliner(book: book, chapter: ch, start_line: from, interliner_json_data: data)
      vs = Verse.where(tr_code: 'gr-ru', book: book, chapter: ch).order(:line).to_a
      puts "#{book} #{ch}: #{vs.count { |v| Array(v.data['wi']).any? { _1['lex'] } }}/#{vs.size}"
    end
    pending = nil
  elsif cur && l.strip.start_with?('{')
    cur.concat(JSON.parse("[#{l.strip.sub(/,\z/, '')}]"))
  end
end

# Dry-run: эмулирует InterlinerCreator.add_interliner без сохранения, построчный разбор JSON
require 'json'
module DryIL
  def self.clean(w) = ::DictWord.word_clean_diacritic_only_gr(w.to_s.tr('армкнvгфет', 'αρμκννγφετ'))
  def self.run(book:, chapter:, start_line:, data:)
    data = data.select { clean(_1['w']).present? }
    verses = ::Verse.where(tr_code: 'gr-ru', book: book, chapter: chapter).where('line >= ?', start_line).order(:line).to_a
    return puts("#{book} #{chapter}: EMPTY (#{verses.last&.line} verses)") if data.empty?
    done = nil; err = nil
    verses.each do |v|
      break if data.empty?
      v.data['w'].each do |w|
        break if data.empty?
        if clean(w) == clean(data.first['w']) || (w == 'δι᾿' && data.first['w'] == 'διὰ')
          data.shift
        elsif w.length <= 1 || (w.chars - "][.·,;".chars).empty?
        else
          err = "v#{v.line}: text=#{w} json=#{data.first['w']}"; break
        end
      end
      break if err
      done = v.line
    end
    puts "#{book} #{chapter}: start=#{start_line} ok_through=#{done}/#{verses.last&.line} #{err ? 'ERR ' + err : ''} left_json=#{data.size}"
  end
end
lines = File.readlines(ARGV[0], chomp: true)
cur = nil
lines.each_with_index do |l, idx|
  if l =~ /^json = \[/ then cur = []
  elsif l.start_with?(']; nil') then (@pending = cur; cur = nil)
  elsif l =~ /add_interliner\(book: '(\w+)', chapter: (\d+), start_line: (\d+)/ && @pending
    DryIL.run(book: $1, chapter: $2.to_i, start_line: $3.to_i, data: @pending); @pending = nil
  elsif cur && l.strip.present? && !l.strip.start_with?('#')
    s = l.strip.sub(/,\z/, '')
    begin
      cur.concat(JSON.parse("[#{s}]"))
    rescue JSON::ParserError => e
      puts "  JSON ERROR line #{idx + 1}: #{e.message[0, 150]}"
      cur << {'w' => '<<BROKEN>>'}
    end
  end
end

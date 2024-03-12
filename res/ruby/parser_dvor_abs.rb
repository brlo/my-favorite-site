# ПАРСЕР СЛОВАРЯ ДВОРЕЦКОГО

# load 'res/ruby/parser_dvor.rb'
#
# DOC https://www.rubyguides.com/2012/01/parsing-html-in-ruby/
#
require 'open-uri'
require 'nokogiri'

dict = 'd'
word = ''
desc = ''

File.readlines('db/dict_greek_russian_dvoretsky.ads').each do |line|
  puts("--------------------------------")
  puts(line)
  html = Nokogiri::HTML5.fragment(line)
  word_new_el = html.css('word').first
  # попалось новое слово?
  if word_new_el.present?
    # перед этим уже обрабатывали какое то слово? значит надо его сохранить
    if word.present?
      puts "############# CREATE WORD"
      puts "word: #{word}"
      puts "desc: #{desc}"
      # удаляем какие-то странные $F0020 с пробелами по сторонам, если есть
      # desc = desc.gsub(/\s?\$F[0-9]+\s?/, '').strip
      # DictWord.create!(dict: dict, w: word, desc: desc)

      # чистим греч. слово от ударений
      word_gr = word.to_s.gsub(/[\t\s\n\r]+/, ' ').unicode_normalize(:nfd).downcase.delete('-').delete("\u0300-\u036F").strip
      # иногда, греч. слово в словаре начинается с "О". Нам это "О" мешает. Убираем.
      word_gr = word_gr.gsub(/\p{Greek}\s(\p{Greek}+)/, '\1')
      word_ru = desc.scan(/\p{Cyrillic}[\(\)\p{Cyrillic}0-9\s]+/i).first

      # Это слово уже сохранено в словаре?
      d = ::DictWord.find_by(dict: dict, word_simple: word_gr, translation_short: word_ru)
      d_desc = DictWord.find_by(dict: dict, desc: desc)
      if d.nil? && d_desc.nil?
        words_miss << [word_gr, word_ru]
        puts "============= CREATE: #{word_gr} -- #{word_ru} ==="
        ::DictWord.create!(
          dict: dict,
          word: word_gr,
          translation_short: word_ru,
          desc: desc,
        )
        i+=1
        puts " ---------- #{ i } ----------"
      end
    end
    puts "=== WORD: #{word_new_el.content}"
    word = word_new_el.content
    desc = ""
  else
    desc += "<p>" + line.strip + "</p>"
  end
end

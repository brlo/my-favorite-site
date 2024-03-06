# ПАРСЕР СЛОВАРЯ Дьячка

# load 'res/ruby/parser_djachok.rb'
#
# DOC https://www.rubyguides.com/2012/01/parsing-html-in-ruby/
#
require 'open-uri'
require 'nokogiri'

# Словарь: Дьячок
dict = 'dmt'
word = ''
desc = ''

i = 0
File.readlines('db/gr-dyachok.txt', chomp: true).each do |line|
  word_gr = line.scan(/^\p{Greek}+/).first
  word_ru, rest = line.scan(/(\p{Cyrillic}[\p{Cyrillic}\s]+),?\s?(.+)/i).first
  if word_gr && word_ru
    word_gr = word_gr.to_s.unicode_normalize(:nfd).downcase.delete("\u0300-\u036F").presence
    if Lexema.find_by(lexema_clean: word_gr)
      puts "============= #{word_gr} - #{word_ru}"
      i+=1
    end
  end
end; i # 2755 слов есть в словаре для Библии

  # puts("--------------------------------")
  # puts(line)
  # html = Nokogiri::HTML5.fragment(line)
  # word_new_el = html.css('word').first
  # # попалось новое слово?
  # puts "word_new_el.present?: #{word_new_el.present?}"
  # if word_new_el.present?
  #   puts "word_new_el.content: #{word_new_el.content}"
  #   # старое уже было?
  #   if word.present?
  #     puts "CREATE!"
  #     puts "word: #{word}"
  #     puts "desc: #{desc}"
  #     # удаляем какие-то странные $F0020 с пробелами по сторонам, если есть
  #     desc = desc.gsub(/\s?\$F[0-9]+\s?/, '').strip
  #     DictWord.create!(dict: dict, w: word, desc: desc)
  #   end
  #   word = word_new_el.content
  #   desc = ""
  # else
  #   desc += line.strip + "\n"
  # end
# end

# ПАРСЕР СЛОВАРЯ ДВОРЕЦКОГО

# DOC https://www.rubyguides.com/2012/01/parsing-html-in-ruby/
# load 'parser_dict.rb'
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
  puts "word_new_el.present?: #{word_new_el.present?}"
  if word_new_el.present?
    puts "word_new_el.content: #{word_new_el.content}"
    # старое уже было?
    if word.present?
      puts "CREATE!"
      puts "word: #{word}"
      puts "desc: #{desc}"
      # удаляем какие-то странные $F0020 с пробелами по сторонам, если есть
      desc = desc.gsub(/\s?\$F[0-9]+\s?/, '').strip
      DictWord.create!(dict: dict, w: word, desc: desc)
    end
    word = word_new_el.content
    desc = ""
  else
    desc += line.strip + "\n"
  end
end

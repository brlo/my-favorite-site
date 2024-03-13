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
  # puts("--------------------------------")
  # puts(line)
  html = Nokogiri::HTML5.fragment(line)
  word_new_el = html.css('word').first
  # попалось новое слово?
  if word_new_el.present?
    # перед этим уже обрабатывали какое то слово? значит надо его сохранить
    if word.present?
      puts "## create:"
      # удаляем какие-то странные $F0020 с пробелами по сторонам, если есть
      # desc = desc.gsub(/\s?\$F[0-9]+\s?/, '').strip
      # DictWord.create!(dict: dict, w: word, desc: desc)

      # чистим греч. слово от ударений
      word_gr = word.to_s.gsub(/[\t\s\n\r]+/, ' ').unicode_normalize(:nfd).downcase.delete('-').delete("\u0300-\u036F").strip
      # иногда, греч. слово в словаре начинается с "О". Нам это "О" мешает. Убираем.
      word_gr = word_gr.gsub(/\p{Greek}\s(\p{Greek}+)/, '\1')
      desc_text = Nokogiri::HTML5.fragment(desc).css('p').map { |par| par.children.select { |ch| ch.text? } }.flatten.map(&:text).map(&:strip).reject { |s| s =~ /^\(.+\)$/}
      word_ru = desc_text.join(' ').scan(/\p{Cyrillic}[\(\)\p{Cyrillic}0-9\s\-]+/i).first
      # убираем пустые скобки
      word_ru = word_ru.gsub(/\(\s+\)/, '').strip if word_ru
      word_ru = word_ru.gsub(/\(\s*$/, '').strip if word_ru
      puts "## word: #{word}  | word_simple: #{word_gr}  | translate: #{word_ru}"
      puts "## desc: #{desc}"

      # Это слово ещё не сохранено в словаре?
      d = ::DictWord.find_by(dict: dict, word_simple: word_gr, translation_short: word_ru)
      d_desc = DictWord.find_by(dict: dict, desc: desc)
      if d.nil? && d_desc.nil?
        ::DictWord.create!(
          dict: dict,
          word: word,
          word_simple: word_gr,
          translation_short: word_ru,
          desc: desc,
        )
        puts "!!!!!!!!!!!!!!!!created!!!!!!!!!!!!!!!!"
      end

    end
    puts "=========================================="
    puts "=== NEXT WORD: #{word_new_el.content}"
    word = word_new_el.content
    word_gr = ""; word_ru = ""; desc = ""
  else
    l = line.strip
    if l.present?
      desc += "<p>#{l}</p>"
    end
  end
end

# последнее слова ТОЖЕ надо сохранить после всего







# выкинуть из текста все html-элементы вместе с содержимым, оставив только текст,
# да и то, если он не начинается и не заканчивается скобкой

# [
#   "делающий невидимым,",
#   "губительный (πῦρ, Ἄρης, ἀνήρ",
#   ");",
#   "невидимый, неведомый, таинственный (ἱερά",
#   ");",
#   "мрачный (Ἅιδης",
#   ")."
# ]
Nokogiri::HTML5.fragment(s).css('p').map { |par| par.children.select { |ch| ch.text? } }.flatten.map(&:text).map
(&:strip).reject { |s| s =~ /^\(.+\)$/}


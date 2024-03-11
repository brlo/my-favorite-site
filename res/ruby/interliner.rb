
# =============================================================================
# ------------------------ создание подстрочника ------------------------------
# =============================================================================
# Из обычного греческого, создаём новый язык в Библии для подстрочнкиа
Verse.where(lang: 'gr-lxx-byz').each { v=_1.dup;v.lang='gr-ru';v.save }

# В новом языке добавляем в data стих, раздробленный на слова, без диакр. знаков
# \u0300 - косое ударение
# \u0301 - косое ударение
# \u0342 - ~ волнистое длинное ударение над буквой
# "\u0302-\u0341\u0343-\u036F" - все диакритические знакие, кроме ударений
Verse.where(lang: 'gr-ru').each do |v|
  # строим из строки массив:
  # ["Εἰς", "τὸ", "τέλος", ",", "ὑπὲρ", "τῶν", "κρυφίων", "τοῦ", "υἱοῦ", "·", "ψαλμὸς", "τῷ", "Δαυιδ", "."]
  #
  # тут в delete пропускаем прямое и обратное ударение u0300-u0301, а также волнистое (долгое) ударение u0342
  v.data['w'] = v.text.split(/(\p{Greek}+)/).map{|w| w.unicode_normalize(:nfd).delete("\u0302-\u0341\u0343-\u036F").strip.split("\s").map(&:strip) }.flatten.reject(&:blank?)
  v.save
end

# Массив, где собраны все греч слова из Библии, без повторений
words = Verse.where(lang: 'gr-ru').map { |v| v.data['w'].map { |w| w.unicode_normalize(:nfd).downcase.delete("\u0300-\u036F") } }.flatten.sort.compact.uniq

# Не все слова есть в словарях, поэтому для всех слов мы стараемся найти лексемы - превоначальные формы,
# которые и будем искать в словарях, если не найдём слово.
# Лексемы находим с помощью локального сервиса https://github.com/perseids-tools/morpheus-perseids-api
require 'nokogiri'
words.each.with_index do |word, i|
  next unless word =~ /[[:alpha:]]+/

  word = word.unicode_normalize(:nfd).downcase.delete("\u0302-\u036F")
  word_clean = word.delete("\u0300-\u036F")

  # Открываем XML-документ по указанному адресу
  url = "http://172.17.0.1:1500/analysis/word?lang=grc&engine=morpheusgrc&word=#{word}"
  uri = url.gsub(/[^[:ascii:]]/) { CGI.escape _1 }

  xml_doc = HTTParty.get(
    uri,
    headers: { "Accept" => "application/xml" }
  ).body

  doc = Nokogiri::XML(xml_doc)

  # Ищем все тэги <hdwd> в документе
  hdwds = doc.xpath("//hdwd")
  puts "i: #{i}, word: #{word}, hdwds: #{hdwds}"

  # Выводим содержимое каждого тэга <hdwd>
  # Иногда лексемы повторяются, вконце лишь добавляются цифры, убираем их
  lexemas = hdwds.map { |h| h.text.to_s.gsub(/\d+$/, '') }.sort.uniq{|w| w.downcase}.compact
  if lexemas.present?
    lexemas.each do |l|
      puts '===========================', l
      ::Lexema.create!(word: word_clean.downcase, lexema: l.downcase, xml: xml_doc)
    end
  else
    puts '---', word
    ::Lexema.create!(word: word_clean.downcase, lexema: nil, xml: xml_doc)
  end
end

# Указываем количество повторений каждого слова в Библии
words = Verse.where(lang: 'gr-ru').map { |v| v.data['w'].map { |w| w.unicode_normalize(:nfd).downcase.delete("\u0300-\u036F") } }.flatten.sort.compact; nil
words_count = Hash.new(0)
words.each { |w| words_count[w] += 1 }; nil
Lexema.each { |l| l.update!(counts: words_count[l.word_downcased]) }

# # На всякий случай:
# # как узнать unicode-код символа. Этот символ, кстати, последний из неудалённых из греч слов
# > "᾿".ord.to_s(16)
# "1fbf"
# > "\u1fbf"
# "᾿"

# ДОБАВЛЯЕМ ТРАНСЛИТ (ГРИКЛИШЬ) (ДОБАВЛЯЕТСЯ АВТОМАТИЧЕСКИ В МОДЕЛИ)
# Lexema.each do |lexema|
#   greeklish = GreeklishIso843::GreekText.to_greeklish("Ἐλιακὶμ".unicode_normalize(:nfd)) # => "Evangelos"
#   lexema.update!(transcription: greeklish)
# end




# ----------------------- СТАРЫЙ СПОСОБ -----------------------
# # ПОИСК НАИБОЛЕЕ ВСТРЕЧАЮЩИХСЯ СЛОВ
# # regex doc: https://www.php.net/manual/fr/function.preg-match.php#105324

# # # GREEK - regexp: a-zA-Z\p{Greek}
# h=Hash.new(0);Verse.where(lang: :'gr-lxx-byz').each{|v| v.t.to_s.gsub(/[^A-Za-zΑ-Ωα-ωίϊΐόάέύϋΰήώ\s]/i, '').split(' ').each {|w| puts(w); w.length > 2 ? h[w] += 1 : nil}};nil
# h=Hash.new(0);Verse.where(lang: :'gr-lxx-byz').each{|v| v.t.to_s.gsub(/[^\p{Alpha}\s]/i, '').split(' ').each {|w| w.length > 2 ? h[w] += 1 : nil}};nil

# h.select{|k,v| k.length > 4}.sort_by{|k,v| v}.last(40).reverse.to_h

# # RU - regexp: a-zA-Z\p{Cyrilic}
# h=Hash.new(0);Verse.where(lang: :'ru').each{|v| v.t.to_s.gsub(/[^\p{Alpha}\s]/i, '').split(' ').each {|w| w.length > 3 ? h[w] += 1 : nil}};h.select{|k,v| k.length > 4}.sort_by{|k,v| v}.last(40).reverse.to_h

# =>
# {
#   "αὐτοῦ"      => 9770,
#   "αὐτῶν"      => 5303,
#   "κύριος"     => 3564,
#   "εἶπεν"      => 3225,
#   "Ισραηλ"     => 2702,
#   "κυρίου"     => 2638,
#   "αὐτὸν"      => 2461,
#   "αὐτῆς"      => 2064,
#   "αὐτοῖς"     => 1914,
#   "αὐτοὺς"     => 1617,
#   "πάντα"      => 1520,
#   "ἐστιν"      => 1489,
#   "ἔσται"      => 1367,
#   "τοῦτο"      => 1089,
#   "Δαυιδ"      => 1083,
#   "αὐτόν"      => 1081,
#   "λέγει"      => 1068,
#   "λέγων"      => 970,
#   "βασιλεὺς"   => 936,
#   "ἐγένετο"    => 921,
#   "κυρίῳ"      => 894,
#   "ἡμέρας"     => 890,
#   "οὕτως"      => 849,
#   "αὐτούς"     => 849,
#   "βασιλέως"   => 825,
#   "Ιερουσαλημ" => 815,
#   "ταῦτα"      => 798,
#   "πάντες"     => 795,
#   "ἐποίησεν"   => 773,
#   "ἡμέρᾳ"      => 771,
#   "αὐτὴν"      => 755,
#   "ἔστιν"      => 740,
#   "κύριον"     => 715,
#   "Ιουδα"      => 677,
#   "οἶκον"      => 656,
#   "αὐτὸς"      => 641,
#   "Ἰησοῦς"     => 629,
#   "ὄνομα"      => 590,
#   "κύριε"      => 585,
#   "προσώπου"   => 571
# }
